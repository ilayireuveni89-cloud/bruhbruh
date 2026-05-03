/* =============================================
   VenusZone HUD v2.0 - Settings Panel
   ============================================= */

function openSettingsPanel(){
    const panel = document.getElementById('settings-panel');
    panel.style.display = 'block';
    loadSettingsUI();
}

function closeSettings(){
    document.getElementById('settings-panel').style.display = 'none';
    fetch('https://venus_hud/closeSettings', { method:'POST', body:'{}' }).catch(()=>{});
}

function switchTab(name){
    document.querySelectorAll('.settings-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelector(`.settings-tab[data-tab="${name}"]`).classList.add('active');
    document.getElementById('tab-' + name).classList.add('active');
}

function loadSettingsUI(){
    const s = window.getHudSettings();
    if(!s) return;

    // Toggles
    Object.keys(s.visible).forEach(k => {
        const el = document.getElementById('tog-' + k);
        if(el) el.checked = s.visible[k];
    });

    // Colors
    Object.keys(s.colors).forEach(k => {
        const el = document.getElementById('col-' + k);
        if(el) el.value = s.colors[k];
    });

    // Scale
    document.getElementById('hud-scale').value = s.scale;
    document.getElementById('scale-val').textContent = s.scale + '%';

    // Speed unit
    document.querySelectorAll('input[name="speed-unit"]').forEach(r => {
        r.checked = (r.value === s.speedUnit);
    });

    // Speedo style
    document.querySelectorAll('.style-card').forEach(c => {
        c.classList.toggle('active', c.dataset.style === s.speedoStyle);
    });
}

function toggleElement(key){
    const s = window.getHudSettings();
    const el = document.getElementById('tog-' + key);
    s.visible[key] = el.checked;
    window.applySettings();
}

function setColor(key, value){
    const s = window.getHudSettings();
    s.colors[key] = value;
    window.applySettings();
}

function resetColors(){
    const s = window.getHudSettings();
    s.colors = {
        health: '#e74c3c',
        armor: '#3498db',
        hunger: '#f39c12',
        thirst: '#00bcd4',
        stamina: '#2ecc71',
        oxygen: '#9b59b6',
    };
    window.applySettings();
    loadSettingsUI();
}

function setScale(val){
    const s = window.getHudSettings();
    s.scale = parseInt(val);
    document.getElementById('scale-val').textContent = val + '%';
    window.applySettings();
}

function setSpeedoStyle(style){
    const s = window.getHudSettings();
    s.speedoStyle = style;
    document.querySelectorAll('.style-card').forEach(c => {
        c.classList.toggle('active', c.dataset.style === style);
    });
    window.applySettings();
}

function setSpeedUnit(unit){
    const s = window.getHudSettings();
    s.speedUnit = unit;
    window.applySettings();
}

function resetAll(){
    if(!confirm('לאפס את כל ההגדרות?')) return;
    const s = window.getHudSettings();
    s.visible = {
        health:true, armor:true, hunger:true, thirst:true,
        stamina:false, oxygen:false, money:true, job:true,
        serverId:true, clock:true, mic:true, speedometer:true,
        compass:true, seatbelt:true, fuel:true, serverLogo:true, streetName:true
    };
    s.colors = {
        health:'#e74c3c', armor:'#3498db', hunger:'#f39c12',
        thirst:'#00bcd4', stamina:'#2ecc71', oxygen:'#9b59b6',
    };
    s.speedUnit = 'kmh';
    s.speedoStyle = 'arc';
    s.scale = 100;
    window.applySettings();
    loadSettingsUI();
}

// ESC key
document.addEventListener('keydown', function(e){
    if(e.key === 'Escape'){
        const panel = document.getElementById('settings-panel');
        if(panel.style.display !== 'none'){
            closeSettings();
        }
    }
});
