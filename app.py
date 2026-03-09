"""
Verification Server + Discord Bot in one file.
Deploy to Render as a Web Service.
Start command: python app.py
"""

import os, json, time, secrets, threading
from pathlib import Path
from functools import wraps

import aiohttp, discord
from discord import app_commands
from discord.ext import commands
from flask import Flask, request, jsonify, redirect, render_template_string, session

# ══════════════════════════════════════════
# CONFIG — fill these in
# ══════════════════════════════════════════
DISCORD_CLIENT_ID     = "1083705317336039435"
DISCORD_CLIENT_SECRET = "4nriOlJfo5OBjRgq7VfyLDkhGlLgpSg9"
DISCORD_GUILD_ID      = 1398735885595316257
DISCORD_VERIFIED_ROLE = "1480607816866861187"
BOT_API_SECRET        = "1234"
ADMIN_PASSWORD        = "admin123"
SITE_URL              = "https://bruhbruh.onrender.com"
SITE_NAME             = "CHOP Bot Verification"
FLASK_SECRET          = secrets.token_hex(32)
# ══════════════════════════════════════════

REDIRECT_URI = f"{SITE_URL}/callback"

# ── JSON storage
DATA_DIR = Path("data"); DATA_DIR.mkdir(exist_ok=True)
F = {k: DATA_DIR / f"{k}.json" for k in ["tokens","users","iplogs","bans"]}

def jread(k): return json.loads(F[k].read_text()) if F[k].exists() else []
def jwrite(k, d): F[k].write_text(json.dumps(d, indent=2))

def get_ip():
    for h in ["CF-Connecting-IP","X-Forwarded-For","X-Real-IP"]:
        v = request.headers.get(h)
        if v: return v.split(",")[0].strip()
    return request.remote_addr

def is_banned(ip, did):
    for b in jread("bans"):
        if (b["type"]=="ip" and b["value"]==ip) or (b["type"]=="discord_id" and b["value"]==did):
            return True
    return False

def assign_role(did):
    import urllib.request
    req = urllib.request.Request(
        f"https://discord.com/api/v10/guilds/{DISCORD_GUILD_ID}/members/{did}/roles/{DISCORD_VERIFIED_ROLE}",
        method="PUT", headers={"Authorization": f"Bot {DISCORD_BOT_TOKEN}", "Content-Length": "0"}
    )
    try: urllib.request.urlopen(req)
    except: pass

def do_ban(did, reason, by):
    iplogs = jread("iplogs"); bans = jread("bans")
    ips = list(set(l["ip"] for l in iplogs if l["discord_id"]==did))
    banned = {"ips":[], "discord_ids":[]}
    for ip in ips:
        if not any(b["type"]=="ip" and b["value"]==ip for b in bans):
            bans.append({"type":"ip","value":ip,"reason":reason,"banned_by":by,"banned_at":time.strftime("%Y-%m-%dT%H:%M:%S")})
            banned["ips"].append(ip)
    all_ids = list(set([did]+[l["discord_id"] for l in iplogs if l["ip"] in ips]))
    for i in all_ids:
        if not any(b["type"]=="discord_id" and b["value"]==i for b in bans):
            bans.append({"type":"discord_id","value":i,"reason":reason,"banned_by":by,"banned_at":time.strftime("%Y-%m-%dT%H:%M:%S")})
            banned["discord_ids"].append(i)
    jwrite("bans", bans)
    return banned

# ══════════════════════════════════════════
# FLASK APP
# ══════════════════════════════════════════
app = Flask(__name__)
app.secret_key = FLASK_SECRET

def require_api_secret(f):
    @wraps(f)
    def wrapper(*a, **kw):
        if request.headers.get("X-API-Secret") != BOT_API_SECRET:
            return jsonify({"error":"Unauthorized"}), 401
        return f(*a, **kw)
    return wrapper

# ── API routes (called by bot)
@app.route("/api/create_token", methods=["POST"])
@require_api_secret
def api_create_token():
    b = request.json
    did, du, gid = b.get("discord_id",""), b.get("discord_username",""), b.get("guild_id", str(DISCORD_GUILD_ID))
    if not did or not du: return jsonify({"error":"Missing fields"}), 400
    if any(u["discord_id"]==did and u["guild_id"]==gid for u in jread("users")):
        return jsonify({"status":"already_verified"})
    tokens = jread("tokens")
    for t in tokens:
        if t["discord_id"]==did and t["guild_id"]==gid: t["used"]=True
    token = secrets.token_hex(24)
    tokens.append({"token":token,"discord_id":did,"discord_username":du,"guild_id":gid,"used":False,"expires":int(time.time())+600})
    jwrite("tokens", tokens)
    return jsonify({"status":"ok","token":token,"url":f"{SITE_URL}/verify?token={token}"})

@app.route("/api/ban", methods=["POST"])
@require_api_secret
def api_ban():
    b = request.json
    did = b.get("discord_id","")
    if not did: return jsonify({"error":"Missing discord_id"}), 400
    banned = do_ban(did, b.get("reason","Banned"), b.get("banned_by","Bot"))
    return jsonify({"status":"ok","banned":banned})

@app.route("/api/is_banned")
@require_api_secret
def api_is_banned():
    did = request.args.get("discord_id","")
    return jsonify({"banned": any(b["type"]=="discord_id" and b["value"]==did for b in jread("bans"))})

@app.route("/api/user_info")
@require_api_secret
def api_user_info():
    did = request.args.get("discord_id","")
    users = jread("users"); iplogs = jread("iplogs")
    user = next((u for u in users if u["discord_id"]==did), None)
    ips = list(set(l["ip"] for l in iplogs if l["discord_id"]==did))
    seen = set()
    alts = []
    for l in iplogs:
        if l["discord_id"]!=did and l["ip"] in ips and l["discord_id"] not in seen:
            seen.add(l["discord_id"])
            alt = next((u for u in users if u["discord_id"]==l["discord_id"]), None)
            if alt: alts.append(alt)
    return jsonify({"user":user,"ips":ips,"alts":alts})

# ── Verify page
@app.route("/verify")
def verify_page():
    token = request.args.get("token","")
    ip = get_ip()
    if any(b["type"]=="ip" and b["value"]==ip for b in jread("bans")):
        return render_template_string(BANNED_HTML)
    row = next((t for t in jread("tokens") if t["token"]==token and not t["used"] and t["expires"]>time.time()), None)
    if not row:
        return render_template_string(ERROR_HTML, msg="Link is invalid or expired. Use /verify in Discord.")
    state = secrets.token_hex(16)
    session["oauth_state"] = state
    session["token"] = token
    oauth_url = (f"https://discord.com/oauth2/authorize?client_id={DISCORD_CLIENT_ID}"
                 f"&redirect_uri={REDIRECT_URI}&response_type=code&scope=identify&state={state}")
    return render_template_string(VERIFY_HTML, user=row["discord_username"], uid=row["discord_id"], oauth_url=oauth_url, site_name=SITE_NAME)

# ── OAuth callback
@app.route("/callback")
def callback():
    import urllib.request, urllib.parse
    if request.args.get("state") != session.get("oauth_state"):
        return render_template_string(ERROR_HTML, msg="Invalid state. Please try again.")
    token = session.get("token","")
    row = next((t for t in jread("tokens") if t["token"]==token and not t["used"] and t["expires"]>time.time()), None)
    if not row:
        return render_template_string(ERROR_HTML, msg="Token expired. Use /verify in Discord.")
    # Exchange code
    data = urllib.parse.urlencode({"client_id":DISCORD_CLIENT_ID,"client_secret":DISCORD_CLIENT_SECRET,
        "grant_type":"authorization_code","code":request.args.get("code",""),"redirect_uri":REDIRECT_URI}).encode()
    req = urllib.request.Request("https://discord.com/api/oauth2/token", data=data,
        headers={"Content-Type":"application/x-www-form-urlencoded"})
    try:
        tr = json.loads(urllib.request.urlopen(req).read())
    except:
        return render_template_string(ERROR_HTML, msg="Discord auth failed. Try again.")
    # Get user
    req2 = urllib.request.Request("https://discord.com/api/users/@me",
        headers={"Authorization": f"Bearer {tr['access_token']}"})
    u = json.loads(urllib.request.urlopen(req2).read())
    did = u["id"]; username = u.get("global_name") or u.get("username","Unknown")
    if did != row["discord_id"]:
        return render_template_string(ERROR_HTML, msg="Wrong Discord account.")
    ip = get_ip()
    if is_banned(ip, did):
        return render_template_string(BANNED_HTML)
    # Save user
    users = jread("users")
    existing = next((x for x in users if x["discord_id"]==did), None)
    if existing:
        existing.update({"ip":ip,"verified_at":time.strftime("%Y-%m-%dT%H:%M:%S")})
    else:
        users.append({"discord_id":did,"discord_username":username,"ip":ip,"guild_id":row["guild_id"],"verified_at":time.strftime("%Y-%m-%dT%H:%M:%S"),"user_agent":request.headers.get("User-Agent","")})
    jwrite("users", users)
    # Log IP
    iplogs = jread("iplogs")
    if not any(l["discord_id"]==did and l["ip"]==ip for l in iplogs):
        iplogs.append({"discord_id":did,"ip":ip,"seen_at":time.strftime("%Y-%m-%dT%H:%M:%S")})
        jwrite("iplogs", iplogs)
    # Mark token used
    tokens = jread("tokens")
    for t in tokens:
        if t["token"]==token: t["used"]=True
    jwrite("tokens", tokens)
    assign_role(did)
    return render_template_string(SUCCESS_HTML, username=username, site_name=SITE_NAME)

# ── Admin panel
@app.route("/admin", methods=["GET","POST"])
def admin():
    if request.method=="POST":
        action = request.form.get("action")
        if action=="login":
            if request.form.get("password")==ADMIN_PASSWORD:
                session["admin"]=True
            return redirect("/admin")
        if action=="logout":
            session.pop("admin",None); return redirect("/admin")
        if not session.get("admin"): return redirect("/admin")
        if action=="ban":
            did = request.form.get("discord_id","")
            if did: do_ban(did, request.form.get("reason","Admin ban"), "Admin")
            return redirect("/admin?msg=banned")
        if action=="unban":
            val = request.form.get("ban_value","")
            bans = [b for b in jread("bans") if b["value"]!=val]
            jwrite("bans", bans)
            return redirect("/admin?msg=unbanned")
    if not session.get("admin"):
        return render_template_string(ADMIN_LOGIN_HTML, site_name=SITE_NAME)
    users = jread("users"); bans = jread("bans"); iplogs = jread("iplogs")
    today = time.strftime("%Y-%m-%d")
    stats = {"total":len(users),"today":sum(1 for u in users if u["verified_at"][:10]==today),
             "bans":len(bans),"ip_bans":sum(1 for b in bans if b["type"]=="ip")}
    for u in users:
        u["ip_count"] = len(set(l["ip"] for l in iplogs if l["discord_id"]==u["discord_id"]))
    msg = request.args.get("msg","")
    return render_template_string(ADMIN_HTML, users=users, bans=bans, stats=stats, site_name=SITE_NAME, msg=msg)

# ══════════════════════════════════════════
# HTML TEMPLATES
# ══════════════════════════════════════════
_BASE_STYLE = """<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>:root{--bg:#0a0b0f;--s:#111318;--s2:#181b22;--b:#ffffff0f;--a:#5865F2;--ag:#5865F255;--t:#e8eaf0;--tm:#6b7280;--g:#23d18b;--r:#f04747}*{box-sizing:border-box;margin:0;padding:0}body{font-family:Syne,sans-serif;background:var(--bg);color:var(--t);min-height:100vh;display:flex;align-items:center;justify-content:center;overflow:hidden}body::before{content:'';position:fixed;inset:0;background:radial-gradient(ellipse 80% 50% at 50% -10%,#5865F218 0%,transparent 60%);pointer-events:none}body::after{content:'';position:fixed;inset:0;background-image:linear-gradient(var(--b) 1px,transparent 1px),linear-gradient(90deg,var(--b) 1px,transparent 1px);background-size:60px 60px;pointer-events:none;opacity:.4}.card{position:relative;z-index:10;background:var(--s);border:1px solid var(--b);border-radius:20px;padding:48px 40px;width:100%;max-width:460px;margin:20px;box-shadow:0 0 80px #5865F215,0 32px 64px #00000060;animation:slideUp .5s cubic-bezier(.16,1,.3,1) both}@keyframes slideUp{from{opacity:0;transform:translateY(24px) scale(.97)}to{opacity:1;transform:translateY(0) scale(1)}}</style>"""

VERIFY_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verify</title>"""+_BASE_STYLE+"""<style>.badge{display:inline-flex;align-items:center;gap:6px;background:var(--s2);border:1px solid var(--b);border-radius:999px;padding:4px 12px;font-family:'DM Mono',monospace;font-size:11px;color:var(--tm);letter-spacing:.08em;text-transform:uppercase;margin-bottom:24px}.badge::before{content:'';width:6px;height:6px;border-radius:50%;background:var(--g);box-shadow:0 0 6px var(--g);animation:pulse 2s infinite}@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}h1{font-size:32px;font-weight:800;line-height:1.1;margin-bottom:12px;background:linear-gradient(135deg,#fff 30%,#8b93ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.sub{color:var(--tm);font-size:14px;line-height:1.6;margin-bottom:32px}.up{display:flex;align-items:center;gap:14px;background:var(--s2);border:1px solid var(--b);border-radius:12px;padding:14px 16px;margin-bottom:28px}.av{width:44px;height:44px;border-radius:50%;background:var(--a);display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:800;flex-shrink:0}.warn{background:#f0474710;border:1px solid #f0474730;border-radius:10px;padding:12px 16px;font-size:13px;color:#f5a3a3;line-height:1.5;margin-bottom:28px;display:flex;gap:10px}.btn{display:flex;align-items:center;justify-content:center;gap:10px;width:100%;padding:16px;background:var(--a);color:#fff;border:none;border-radius:12px;font-family:Syne,sans-serif;font-size:16px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s;box-shadow:0 0 24px var(--ag)}.btn:hover{transform:translateY(-2px)}.footer{text-align:center;margin-top:24px;font-size:12px;color:var(--tm);font-family:'DM Mono',monospace}</style></head>
<body><div class="card"><div class="badge">Identity Verification</div><h1>Verify your<br>identity</h1><p class="sub">To access <strong>{{site_name}}</strong>, verify your Discord account below.</p><div class="up"><div class="av">{{user[0]|upper}}</div><div><div style="font-weight:600;font-size:15px">{{user}}</div><div style="font-family:'DM Mono',monospace;font-size:12px;color:var(--tm)">ID: {{uid}}</div></div></div><div class="warn">⚠️ Your IP is collected for security. Ban evasion results in permanent removal.</div><a href="{{oauth_url}}" class="btn"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03z"/></svg>Continue with Discord</a><p class="footer">{{site_name}}</p></div></body></html>"""

SUCCESS_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Verified!</title>"""+_BASE_STYLE+"""<style>body::before{background:radial-gradient(ellipse 60% 40% at 50% 0%,#23d18b18 0%,transparent 60%)!important}.card{border-color:#23d18b20;text-align:center}.icon{font-size:56px;margin-bottom:24px}h1{font-size:28px;color:#23d18b;margin-bottom:12px}p{color:#6b7280;font-size:14px;line-height:1.6}a{display:inline-flex;align-items:center;gap:8px;margin-top:28px;padding:12px 24px;background:#5865F2;color:#fff;border-radius:10px;text-decoration:none;font-weight:600;font-size:14px}</style></head>
<body><div class="card"><div class="icon">✓</div><h1>Verified!</h1><p>Welcome to <strong>{{site_name}}</strong>! Head back to Discord — your role has been assigned.</p><a href="https://discord.com">Open Discord</a></div></body></html>"""

ERROR_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Error</title>"""+_BASE_STYLE+"""<style>body::before{background:radial-gradient(ellipse 60% 40% at 50% 0%,#f0474718 0%,transparent 60%)!important}.card{border-color:#f0474720;text-align:center}.icon{font-size:56px;margin-bottom:24px}h1{font-size:28px;color:#f04747;margin-bottom:12px}p{color:#6b7280;font-size:14px;line-height:1.6}code{background:#ffffff10;padding:2px 6px;border-radius:4px;font-family:'DM Mono',monospace}</style></head>
<body><div class="card"><div class="icon">✕</div><h1>Error</h1><p>{{msg}}</p></div></body></html>"""

BANNED_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Banned</title>"""+_BASE_STYLE+"""<style>body::before{background:radial-gradient(ellipse 60% 40% at 50% 0%,#f0474718 0%,transparent 60%)!important}.card{border-color:#f0474720;text-align:center}h1{font-size:28px;color:#f04747;margin-bottom:12px}p{color:#6b7280;font-size:14px;line-height:1.6}</style></head>
<body><div class="card"><div style="font-size:56px;margin-bottom:24px">🔨</div><h1>You are banned</h1><p>Your IP has been banned from this server. Contact an admin if you believe this is a mistake.</p></div></body></html>"""

ADMIN_LOGIN_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Admin</title><link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;800&display=swap" rel="stylesheet"><style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:Syne,sans-serif;background:#080a0f;color:#d4d8e8;min-height:100vh;display:flex;align-items:center;justify-content:center}.c{background:#0e1117;border:1px solid #ffffff18;border-radius:20px;padding:44px 36px;width:360px}h1{font-size:26px;font-weight:800;margin-bottom:6px}p{color:#555d78;font-size:13px;margin-bottom:28px}label{display:block;font-size:12px;color:#555d78;margin-bottom:6px;font-family:'DM Mono',monospace}input{width:100%;background:#151820;border:1px solid #ffffff18;border-radius:10px;padding:12px 14px;color:#d4d8e8;font-family:Syne,sans-serif;font-size:14px;outline:none;margin-bottom:16px}button{width:100%;padding:13px;background:#5865F2;border:none;border-radius:10px;color:#fff;font-family:Syne,sans-serif;font-size:15px;font-weight:600;cursor:pointer}</style></head>
<body><div class="c"><h1>Admin Panel</h1><p>{{site_name}}</p><form method="POST"><input type="hidden" name="action" value="login"><label>PASSWORD</label><input type="password" name="password" autofocus><button>Sign In</button></form></div></body></html>"""

ADMIN_HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Admin</title><link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>:root{--bg:#080a0f;--s:#0e1117;--s2:#151820;--b:#ffffff0c;--b2:#ffffff18;--a:#5865F2;--g:#23d18b;--r:#f04747;--y:#faa61a;--t:#d4d8e8;--tm:#555d78}*{box-sizing:border-box;margin:0;padding:0}body{font-family:Syne,sans-serif;background:var(--bg);color:var(--t)}a{color:var(--a);text-decoration:none}.sb{position:fixed;top:0;left:0;bottom:0;width:220px;background:var(--s);border-right:1px solid var(--b);padding:28px 18px;display:flex;flex-direction:column;gap:4px}.logo{font-size:17px;font-weight:800;margin-bottom:28px;color:#fff;display:flex;align-items:center;gap:8px}.dot{width:8px;height:8px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g)}.nav{display:flex;align-items:center;gap:10px;padding:9px 12px;border-radius:8px;font-size:14px;font-weight:600;color:var(--tm)}.main{margin-left:220px;padding:36px;max-width:1100px}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:32px}.stat{background:var(--s);border:1px solid var(--b);border-radius:14px;padding:20px 22px}.sl{font-size:11px;font-family:'DM Mono',monospace;color:var(--tm);text-transform:uppercase;letter-spacing:.08em;margin-bottom:8px}.sv{font-size:32px;font-weight:800}.sec{margin-bottom:40px}.sh{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px}.sh h2{font-size:18px;font-weight:700}.tw{background:var(--s);border:1px solid var(--b);border-radius:14px;overflow:hidden}table{width:100%;border-collapse:collapse;font-size:13px}thead{background:var(--s2)}th{padding:12px 16px;text-align:left;font-size:11px;font-family:'DM Mono',monospace;color:var(--tm);text-transform:uppercase;letter-spacing:.06em;font-weight:500;border-bottom:1px solid var(--b)}td{padding:12px 16px;border-bottom:1px solid var(--b);vertical-align:middle}tr:last-child td{border-bottom:none}tr:hover td{background:var(--s2)}.mono{font-family:'DM Mono',monospace;font-size:12px}.tag{display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-family:'DM Mono',monospace}.tip{background:#f0474718;color:#f08a8a;border:1px solid #f0474730}.tid{background:#faa61a18;color:#fac96a;border:1px solid #faa61a30}.tv{background:#23d18b18;color:#23d18b;border:1px solid #23d18b30}.bb{background:#f0474720;border:1px solid #f0474740;color:#f04747;border-radius:6px;padding:5px 12px;font-size:12px;font-family:Syne,sans-serif;font-weight:600;cursor:pointer}.ub{background:#23d18b20;border:1px solid #23d18b40;color:#23d18b;border-radius:6px;padding:5px 12px;font-size:12px;font-family:Syne,sans-serif;font-weight:600;cursor:pointer}.si{background:var(--s);border:1px solid var(--b2);border-radius:8px;padding:8px 14px;color:var(--t);font-family:Syne,sans-serif;font-size:13px;outline:none;width:220px}.msg{background:#23d18b18;border:1px solid #23d18b30;border-radius:8px;padding:10px 16px;color:#23d18b;font-size:13px;margin-bottom:24px}.mb{display:none;position:fixed;inset:0;background:#000000a0;z-index:100;align-items:center;justify-content:center}.mb.show{display:flex}.md{background:var(--s);border:1px solid var(--b2);border-radius:16px;padding:28px;width:400px}.md h3{font-size:18px;margin-bottom:8px}.md p{color:var(--tm);font-size:13px;margin-bottom:20px}.md textarea{width:100%;background:var(--s2);border:1px solid var(--b2);border-radius:8px;padding:10px 12px;color:var(--t);font-family:Syne,sans-serif;font-size:13px;resize:vertical;min-height:80px;outline:none;margin-bottom:16px}.mbs{display:flex;gap:10px;justify-content:flex-end}.bc{background:var(--s2);border:1px solid var(--b2);color:var(--t);border-radius:8px;padding:9px 18px;font-family:Syne,sans-serif;font-weight:600;font-size:13px;cursor:pointer}</style></head><body>
<nav class="sb"><div class="logo"><span class="dot"></span>{{site_name}}</div><div class="nav">📋 Dashboard</div><div style="flex:1"></div><form method="POST"><input type="hidden" name="action" value="logout"><button class="nav" type="submit" style="background:none;border:none;cursor:pointer;width:100%">🚪 Logout</button></form></nav>
<main class="main">
{% if msg %}<div class="msg">✓ {% if msg=='banned' %}User and all alts banned.{% else %}Ban removed.{% endif %}</div>{% endif %}
<div class="stats">
<div class="stat"><div class="sl">Total Verified</div><div class="sv" style="color:var(--g)">{{stats.total}}</div></div>
<div class="stat"><div class="sl">Today</div><div class="sv" style="color:var(--a)">{{stats.today}}</div></div>
<div class="stat"><div class="sl">Total Bans</div><div class="sv" style="color:var(--r)">{{stats.bans}}</div></div>
<div class="stat"><div class="sl">IP Bans</div><div class="sv" style="color:var(--y)">{{stats.ip_bans}}</div></div>
</div>
<div class="sec"><div class="sh"><h2>Verified Users</h2><input class="si" placeholder="Search…" oninput="fil('ut',this.value)"></div>
<div class="tw"><table id="ut"><thead><tr><th>Username</th><th>Discord ID</th><th>IP</th><th>IPs Seen</th><th>Verified</th><th>Action</th></tr></thead><tbody>
{% for u in users %}<tr><td>{{u.discord_username}} <span class="tag tv">✓</span></td><td class="mono">{{u.discord_id}}</td><td class="mono">{{u.ip}}</td><td class="mono">{{u.ip_count}}</td><td class="mono" style="color:var(--tm)">{{u.verified_at[:16]}}</td><td><button class="bb" onclick="ob('{{u.discord_id}}','{{u.discord_username}}')">Ban + IP</button></td></tr>{% endfor %}
</tbody></table></div></div>
<div class="sec"><div class="sh"><h2>Bans</h2><input class="si" placeholder="Search…" oninput="fil('bt',this.value)"></div>
<div class="tw"><table id="bt"><thead><tr><th>Type</th><th>Value</th><th>Reason</th><th>Date</th><th>Action</th></tr></thead><tbody>
{% for b in bans %}<tr><td><span class="tag {% if b.type=='ip' %}tip{% else %}tid{% endif %}">{{b.type|upper}}</span></td><td class="mono">{{b.value}}</td><td style="color:var(--tm);font-size:12px">{{b.reason}}</td><td class="mono" style="color:var(--tm)">{{b.banned_at[:10]}}</td><td><form method="POST" style="display:inline"><input type="hidden" name="action" value="unban"><input type="hidden" name="ban_value" value="{{b.value}}"><button type="submit" class="ub">Unban</button></form></td></tr>{% endfor %}
</tbody></table></div></div>
</main>
<div class="mb" id="bm"><div class="md"><h3 id="bmt">🔨 Ban User</h3><p>Bans the user + all IPs and alt accounts.</p><form method="POST"><input type="hidden" name="action" value="ban"><input type="hidden" name="discord_id" id="bid"><textarea name="reason" placeholder="Reason…"></textarea><div class="mbs"><button type="button" class="bc" onclick="cb()">Cancel</button><button type="submit" class="bb" style="padding:9px 18px;font-size:13px">Confirm Ban</button></div></form></div></div>
<script>function ob(id,n){document.getElementById('bid').value=id;document.getElementById('bmt').textContent='🔨 Ban '+n;document.getElementById('bm').classList.add('show')}function cb(){document.getElementById('bm').classList.remove('show')}function fil(id,q){document.querySelectorAll('#'+id+' tbody tr').forEach(r=>r.style.display=r.textContent.toLowerCase().includes(q.toLowerCase())?'':'none')}</script>
</body></html>"""

# ══════════════════════════════════════════
# DISCORD BOT (runs in background thread)
# ══════════════════════════════════════════
HEADERS_BOT = {"X-API-Secret": BOT_API_SECRET, "Content-Type": "application/json"}

intents = discord.Intents.default()
intents.members = True
bot = commands.Bot(command_prefix="!", intents=intents)
guild_obj = discord.Object(id=DISCORD_GUILD_ID)

async def api_post_bot(action, data):
    import json as _j
    async with aiohttp.ClientSession() as s:
        async with s.post(f"{SITE_URL}/api/{action}", json=data, headers=HEADERS_BOT) as r:
            text = await r.text()
            print(f"[BOT API] {action} {r.status}: {text[:200]}")
            return _j.loads(text)

async def api_get_bot(action, params={}):
    import json as _j
    qs = "&".join(f"{k}={v}" for k,v in params.items())
    async with aiohttp.ClientSession() as s:
        async with s.get(f"{SITE_URL}/api/{action}?{qs}", headers=HEADERS_BOT) as r:
            return _j.loads(await r.text())

@bot.event
async def on_ready():
    bot.tree.copy_global_to(guild=guild_obj)
    await bot.tree.sync(guild=guild_obj)
    print(f"✓ Bot ready: {bot.user}")

@bot.event
async def on_member_join(member):
    if member.guild.id != DISCORD_GUILD_ID: return
    data = await api_post_bot("create_token", {"discord_id":str(member.id),"discord_username":member.name,"guild_id":str(member.guild.id)})
    if data.get("status")=="already_verified": return
    embed = discord.Embed(title=f"Welcome to {member.guild.name}!", description="Click below to verify your account.", color=0x5865F2).set_footer(text="Expires in 10 minutes.")
    view = discord.ui.View()
    view.add_item(discord.ui.Button(label="Verify Now", url=data["url"], emoji="🔐"))
    try: await member.send(embed=embed, view=view)
    except discord.Forbidden: pass

@bot.tree.command(guild=guild_obj, name="verify", description="Get your verification link")
async def cmd_verify(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    data = await api_post_bot("create_token", {"discord_id":str(interaction.user.id),"discord_username":interaction.user.name,"guild_id":str(interaction.guild_id)})
    if data.get("status")=="already_verified":
        return await interaction.followup.send("✅ Already verified!", ephemeral=True)
    view = discord.ui.View()
    view.add_item(discord.ui.Button(label="Verify Now", url=data["url"], emoji="🔐"))
    await interaction.followup.send("Click to verify (expires in 10 min):", view=view, ephemeral=True)

@bot.tree.command(guild=guild_obj, name="ban", description="Ban a user + all IPs and alts")
@app_commands.describe(user="User to ban", reason="Reason")
@app_commands.checks.has_permissions(ban_members=True)
async def cmd_ban(interaction: discord.Interaction, user: discord.Member, reason: str="No reason provided"):
    await interaction.response.defer(ephemeral=True)
    data = await api_post_bot("ban", {"discord_id":str(user.id),"reason":reason,"banned_by":str(interaction.user)})
    banned = data.get("banned",{}); ips=banned.get("ips",[]); all_ids=banned.get("discord_ids",[])
    for uid in all_ids:
        try: await interaction.guild.ban(discord.Object(id=int(uid)), reason=reason)
        except: pass
    embed = discord.Embed(title="🔨 Ban Executed", color=0xF04747)
    embed.add_field(name="Target", value=f"{user} (`{user.id}`)", inline=True)
    embed.add_field(name="Reason", value=reason, inline=True)
    embed.add_field(name="IPs Banned", value="`"+"`, `".join(ips)+"`" if ips else "none", inline=False)
    embed.add_field(name="Alt IDs", value="`"+"`, `".join(i for i in all_ids if i!=str(user.id))+"`" if any(i!=str(user.id) for i in all_ids) else "none", inline=False)
    await interaction.followup.send(embed=embed, ephemeral=True)

@bot.tree.command(guild=guild_obj, name="lookup", description="Look up a user's IPs and alts")
@app_commands.describe(user="User to look up")
@app_commands.checks.has_permissions(manage_guild=True)
async def cmd_lookup(interaction: discord.Interaction, user: discord.Member):
    await interaction.response.defer(ephemeral=True)
    data = await api_get_bot("user_info", {"discord_id":str(user.id)})
    if not data.get("user"):
        return await interaction.followup.send(f"ℹ️ {user} has not verified.", ephemeral=True)
    u=data["user"]; ips=data.get("ips",[]); alts=data.get("alts",[])
    embed = discord.Embed(title=f"🔍 {u['discord_username']}", color=0x5865F2)
    embed.add_field(name="Discord ID", value=f"`{u['discord_id']}`", inline=True)
    embed.add_field(name="Verified At", value=u["verified_at"][:16], inline=True)
    embed.add_field(name="IPs Seen", value="\n".join(f"`{ip}`" for ip in ips) or "none", inline=False)
    embed.add_field(name=f"Alts ({len(alts)})", value="\n".join(f"{a['discord_username']} (`{a['discord_id']}`)" for a in alts) or "None", inline=False)
    await interaction.followup.send(embed=embed, ephemeral=True)

@bot.tree.command(guild=guild_obj, name="checkban", description="Check if a user is banned")
@app_commands.describe(user="User to check")
@app_commands.checks.has_permissions(manage_guild=True)
async def cmd_checkban(interaction: discord.Interaction, user: discord.Member):
    await interaction.response.defer(ephemeral=True)
    data = await api_get_bot("is_banned", {"discord_id":str(user.id)})
    await interaction.followup.send(f"🔴 **{user}** is banned." if data.get("banned") else f"🟢 **{user}** is NOT banned.", ephemeral=True)

@cmd_ban.error
@cmd_lookup.error
@cmd_checkban.error
async def perm_error(interaction, error):
    if isinstance(error, app_commands.MissingPermissions):
        await interaction.response.send_message("❌ No permission.", ephemeral=True)

def run_bot():
    import asyncio
    asyncio.run(bot.start(DISCORD_BOT_TOKEN))

# ══════════════════════════════════════════
# STARTUP
# ══════════════════════════════════════════
if __name__ == "__main__":
    t = threading.Thread(target=run_bot, daemon=True)
    t.start()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
