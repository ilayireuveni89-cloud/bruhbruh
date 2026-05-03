/* =============================================
   VenusZone HUD v2.0 - Main Script
   ============================================= */
(function(){
    const CIRC = 113.1; // 2 * PI * 18
    const SPEEDO_CIRC = 427.26; // 2 * PI * 68
    const MAX_SPEED = 260;

    let settings = {};
    let prevMoney = {cash:0,bank:0,black:0};

    window.addEventListener('message', function(e){
        const d = e.data;
        switch(d.type){
            case 'init': onInit(d); break;
            case 'showHud': toggleHud(d.show); break;
            case 'updateHud': onUpdate(d); break;
            case 'updateMoney': onMoney(d); break;
            case 'updateClock': onClock(d); break;
            case 'updateStatus': onStatus(d); break;
            case 'updateJob': onJob(d); break;
            case 'openSettings': openSettingsPanel(); break;
            case 'notify': showNotif(d.style, d.text); break;
        }
    });

    function onInit(d){
        document.getElementById('logo-name').textContent = d.serverName || 'VenusZone';
        document.getElementById('logo-tag').textContent = d.serverTagline || 'RolePlay IL';
        document.getElementById('pi-id-val').textContent = d.serverId || '0';

        settings = {
            visible: Object.assign({}, d.defaultVisible),
            colors: Object.assign({}, d.defaultColors),
            speedUnit: d.defaultSpeedUnit || 'kmh',
            speedoStyle: d.defaultSpeedoStyle || 'arc',
            scale: 100,
        };

        if(d.savedSettings){
            try {
                const saved = JSON.parse(d.savedSettings);
                if(saved.visible) Object.assign(settings.visible, saved.visible);
                if(saved.colors) Object.assign(settings.colors, saved.colors);
                if(saved.speedUnit) settings.speedUnit = saved.speedUnit;
                if(saved.speedoStyle) settings.speedoStyle = saved.speedoStyle;
                if(saved.scale) settings.scale = saved.scale;
            } catch(e){}
        }

        applySettings();
        onJob({job: d.job, grade: d.grade});
    }

    function toggleHud(show){
        document.getElementById('venus-hud').classList.toggle('visible', show);
    }

    // ============ UPDATE ============
    function onUpdate(d){
        // Circles
        setArc('health', d.health);
        setArc('armor', d.armor);

        const hc = document.getElementById('ci-health');
        if(d.health <= 20) hc.classList.add('critical');
        else hc.classList.remove('critical');

        // Armor visibility
        const ac = document.getElementById('ci-armor');
        if(d.armor <= 0 && settings.visible.armor) ac.style.opacity = '.35';
        else ac.style.opacity = '1';

        // Mic
        const mic = document.getElementById('ci-mic');
        mic.classList.toggle('talking', !!d.talking);

        // Stamina/Oxygen
        if(d.stamina !== undefined) setArc('stamina', d.stamina);
        if(d.oxygen !== undefined) setArc('oxygen', Math.min(100, d.oxygen));

        // Street
        if(d.street){
            document.getElementById('street-name').textContent = d.street;
        }

        // Vehicle
        const vhud = document.getElementById('hud-vehicle');
        if(d.inVehicle && settings.visible.speedometer){
            vhud.style.display = 'flex';
            updateVehicle(d);
        } else {
            vhud.style.display = 'none';
        }
    }

    function setArc(type, value){
        const el = document.getElementById('arc-' + type);
        if(!el) return;
        const v = Math.max(0, Math.min(100, value || 0));
        const offset = CIRC * (1 - v / 100);
        el.style.strokeDashoffset = offset;
    }

    function updateVehicle(d){
        const speed = settings.speedUnit === 'mph' ? (d.speedMph || 0) : (d.speed || 0);
        const unit = settings.speedUnit === 'mph' ? 'MPH' : 'KM/H';

        // Arc style
        if(settings.speedoStyle === 'arc'){
            document.getElementById('speedo-val').textContent = speed;
            document.getElementById('speedo-label').textContent = unit;
            const ring = document.getElementById('speedo-ring');
            const pct = Math.min(speed / MAX_SPEED, 1);
            ring.style.strokeDashoffset = SPEEDO_CIRC * (1 - pct);

            if(speed > 180) ring.style.stroke = 'var(--red)';
            else if(speed > 120) ring.style.stroke = 'var(--hunger)';
            else ring.style.stroke = 'var(--accent)';

            document.getElementById('speedo-gear').textContent = d.gear === 0 ? 'R' : (d.gear || 'N');
        }

        // Digital style
        if(settings.speedoStyle === 'digital'){
            document.getElementById('digi-speed').textContent = speed;
            document.getElementById('digi-unit').textContent = unit;
            document.getElementById('digi-gear').textContent = d.gear === 0 ? 'R' : (d.gear || 'N');
        }

        // Minimal
        if(settings.speedoStyle === 'minimal'){
            document.getElementById('mini-speed').textContent = speed;
            document.getElementById('mini-unit').textContent = unit;
        }

        // Fuel
        if(d.fuel !== undefined){
            const fuelPct = Math.max(0, Math.min(100, d.fuel)) + '%';
            const f1 = document.getElementById('speedo-fuel');
            const f2 = document.getElementById('digi-fuel');
            if(f1) f1.style.width = fuelPct;
            if(f2) f2.style.width = fuelPct;
        }

        // Seatbelt
        const sbIcon = document.getElementById('seatbelt-icon');
        if(sbIcon){
            if(d.seatbelt){
                sbIcon.classList.add('buckled');
                sbIcon.classList.remove('unbuckled');
            } else {
                sbIcon.classList.remove('buckled');
                sbIcon.classList.add('unbuckled');
            }
        }

        // Compass
        if(d.heading !== undefined && settings.visible.compass){
            document.getElementById('hud-compass').style.display = 'flex';
            document.getElementById('compass-deg').textContent = d.heading + '°';
            const bar = document.getElementById('compass-bar');
            const offset = -(d.heading / 360) * 360;
            bar.style.left = 'calc(50% + ' + offset + 'px)';
        } else {
            document.getElementById('hud-compass').style.display = 'none';
        }
    }

    // ============ MONEY ============
    function onMoney(d){
        animMoney('money-cash', d.cash, prevMoney.cash, '.cash-pill');
        animMoney('money-bank', d.bank, prevMoney.bank, '.bank-pill');
        animMoney('money-black', d.black, prevMoney.black, '.black-pill');

        const bp = document.getElementById('money-black-pill');
        bp.style.display = d.black > 0 ? 'flex' : 'none';

        prevMoney = {cash:d.cash, bank:d.bank, black:d.black};
    }

    function animMoney(id, val, prev, sel){
        document.getElementById(id).textContent = '$' + fmt(val);
        if(val !== prev){
            const el = document.querySelector(sel);
            el.classList.remove('pop-up','pop-down');
            void el.offsetWidth;
            el.classList.add(val > prev ? 'pop-up' : 'pop-down');
            setTimeout(()=> el.classList.remove('pop-up','pop-down'), 500);
        }
    }

    function fmt(n){ return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','); }

    function onClock(d){
        const h = String(d.hour).padStart(2,'0');
        const m = String(d.minute).padStart(2,'0');
        document.getElementById('pi-clock-val').textContent = h + ':' + m;
    }

    function onStatus(d){
        if(d.hunger !== undefined) setArc('hunger', d.hunger);
        if(d.thirst !== undefined) setArc('thirst', d.thirst);
    }

    function onJob(d){
        const el = document.getElementById('pi-job-val');
        el.textContent = d.grade ? (d.job + ' | ' + d.grade) : (d.job || 'אזרח');
    }

    // ============ NOTIFICATIONS ============
    function showNotif(style, text){
        const container = document.getElementById('hud-notifications');
        const el = document.createElement('div');
        el.className = 'hud-notif ' + (style || 'info');
        el.textContent = text;
        container.appendChild(el);
        setTimeout(()=>{ el.classList.add('fade-out'); setTimeout(()=>el.remove(), 300); }, 3000);
    }

    // ============ SETTINGS APPLICATION ============
    window.applySettings = function(){
        // Visibility
        const vis = settings.visible;
        document.getElementById('ci-health').classList.toggle('hidden', !vis.health);
        document.getElementById('ci-armor').classList.toggle('hidden', !vis.armor);
        document.getElementById('ci-hunger').classList.toggle('hidden', !vis.hunger);
        document.getElementById('ci-thirst').classList.toggle('hidden', !vis.thirst);
        document.getElementById('ci-stamina').classList.toggle('hidden', !vis.stamina);
        document.getElementById('ci-oxygen').classList.toggle('hidden', !vis.oxygen);
        document.getElementById('ci-mic').classList.toggle('hidden', !vis.mic);
        document.getElementById('hud-money').style.display = vis.money ? 'flex' : 'none';
        document.getElementById('pi-job').style.display = vis.job ? 'flex' : 'none';
        document.getElementById('pi-id').style.display = vis.serverId ? 'flex' : 'none';
        document.getElementById('pi-clock').style.display = vis.clock ? 'flex' : 'none';
        document.getElementById('hud-logo').style.display = vis.serverLogo ? 'block' : 'none';
        document.getElementById('hud-street').style.display = vis.streetName ? 'block' : 'none';

        // Colors
        const cols = settings.colors;
        Object.keys(cols).forEach(k => {
            document.documentElement.style.setProperty('--' + k, cols[k]);
        });

        // Scale
        document.documentElement.style.setProperty('--hud-scale', settings.scale / 100);

        // Speedo style
        document.querySelectorAll('.speedo-style').forEach(e => e.style.display = 'none');
        const activeStyle = document.getElementById('speedo-' + settings.speedoStyle);
        if(activeStyle) activeStyle.style.display = 'block';

        // Speed unit labels
        const unitText = settings.speedUnit === 'mph' ? 'MPH' : 'KM/H';
        document.getElementById('speedo-label').textContent = unitText;
        document.getElementById('digi-unit').textContent = unitText;
        document.getElementById('mini-unit').textContent = unitText;

        // Seatbelt pill
        const sbp = document.getElementById('seatbelt-pill');
        if(sbp) sbp.style.display = vis.seatbelt ? 'flex' : 'none';

        saveSettings();
    };

    function saveSettings(){
        fetch('https://venus_hud/saveSettings', {
            method: 'POST',
            body: JSON.stringify({ settings: JSON.stringify(settings) })
        }).catch(()=>{});
    }

    window.getHudSettings = function(){ return settings; };
})();
