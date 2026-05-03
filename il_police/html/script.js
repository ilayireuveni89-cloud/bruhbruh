/* =============================================
   Main Script - Israeli Police NUI
   ============================================= */

// =============================================
// NUI Message Handler
// =============================================
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'notification':
            showNotification(data.notifyType, data.message);
            break;
        case 'updateHUD':
            updateHUD(data.data);
            break;
        case 'dispatch':
            showDispatchNotification(data.data);
            break;
        case 'openDispatchPanel':
            openDispatchPanel();
            break;
        case 'showSearchResults':
            showPlayerSearchResults(data.data);
            break;
        case 'vehicleOptions':
            showVehicleOptions(data.data);
            break;
    }
});

// =============================================
// Notifications
// =============================================
function showNotification(type, message) {
    const container = document.getElementById('notification-container');
    const notif = document.createElement('div');
    notif.className = 'notification ' + type;

    let icon = 'fa-info-circle';
    if (type === 'success') icon = 'fa-check-circle';
    else if (type === 'error') icon = 'fa-exclamation-circle';
    else if (type === 'warning') icon = 'fa-exclamation-triangle';

    notif.innerHTML = '<i class="fas ' + icon + '"></i><span>' + message + '</span>';
    container.appendChild(notif);

    setTimeout(() => {
        notif.classList.add('fade-out');
        setTimeout(() => notif.remove(), 300);
    }, 4000);
}

// =============================================
// HUD
// =============================================
function updateHUD(data) {
    const hud = document.getElementById('police-hud');
    if (data.onDuty) {
        hud.style.display = 'block';
        document.getElementById('hud-rank').textContent = data.rank;
        document.getElementById('hud-department').textContent = '| ' + (data.department || '');
    } else {
        hud.style.display = 'none';
    }
}

// =============================================
// Dispatch
// =============================================
function openDispatchPanel() {
    document.getElementById('dispatch-panel').style.display = 'flex';
}

function closeDispatch() {
    document.getElementById('dispatch-panel').style.display = 'none';
    fetch('https://il_police/closeDispatch', { method: 'POST', body: JSON.stringify({}) });
}

function sendDispatch() {
    const message = document.getElementById('dispatch-message').value;
    const code = document.getElementById('dispatch-code').value;

    if (!message.trim()) {
        showNotification('error', 'הקלד הודעה');
        return;
    }

    fetch('https://il_police/sendDispatch', {
        method: 'POST',
        body: JSON.stringify({ message: message, code: code })
    });

    document.getElementById('dispatch-message').value = '';
    document.getElementById('dispatch-panel').style.display = 'none';
}

function showDispatchNotification(data) {
    const existing = document.querySelectorAll('.dispatch-notification');
    existing.forEach(el => el.remove());

    const notif = document.createElement('div');
    notif.className = 'dispatch-notification';
    notif.innerHTML = `
        <div class="dispatch-title">
            <i class="fas fa-broadcast-tower"></i>
            מוקד משטרתי - ${data.code || ''}
        </div>
        <div class="dispatch-info">
            <i class="fas fa-user"></i> ${data.rank} ${data.sender} | ${data.time}
        </div>
        <div class="dispatch-msg">${data.message}</div>
    `;
    document.body.appendChild(notif);

    setTimeout(() => {
        notif.style.animation = 'slideUp 0.3s ease-in forwards';
        setTimeout(() => notif.remove(), 300);
    }, 8000);
}

// =============================================
// Player Search Results
// =============================================
function showPlayerSearchResults(data) {
    const panel = document.getElementById('search-results-panel');
    const body = document.getElementById('search-results-body');
    panel.style.display = 'flex';

    let html = '<h3 style="color:#6495ED;margin-bottom:12px;">תוצאות חיפוש שחקן</h3>';

    html += '<div class="search-item">';
    html += '<div class="name"><i class="fas fa-user"></i> ' + data.name + '</div>';
    html += '<div class="detail"><i class="fas fa-money-bill"></i> מזומן: $' + (data.money || 0).toLocaleString() + '</div>';
    html += '<div class="detail"><i class="fas fa-university"></i> בנק: $' + (data.bank || 0).toLocaleString() + '</div>';
    html += '<div class="detail"><i class="fas fa-money-bill-wave"></i> כסף שחור: $' + (data.black_money || 0).toLocaleString() + '</div>';

    if (data.items && data.items.length > 0) {
        html += '<div style="margin-top:10px;"><strong style="color:#f39c12;">פריטים:</strong></div>';
        data.items.forEach(item => {
            html += '<div class="detail">• ' + item.label + ' x' + item.count + '</div>';
        });
    }

    if (data.weapons && data.weapons.length > 0) {
        html += '<div style="margin-top:10px;"><strong style="color:#e74c3c;">נשקים:</strong></div>';
        data.weapons.forEach(weapon => {
            html += '<div class="detail">• ' + weapon.label + ' (תחמושת: ' + weapon.ammo + ')</div>';
        });
    }

    html += '</div>';
    body.innerHTML = html;
}

function closeSearchResults() {
    document.getElementById('search-results-panel').style.display = 'none';
    fetch('https://il_police/closeF6', { method: 'POST', body: JSON.stringify({}) });
}

// =============================================
// Vehicle Options
// =============================================
function showVehicleOptions(data) {
    const panel = document.getElementById('search-results-panel');
    const body = document.getElementById('search-results-body');
    panel.style.display = 'flex';

    body.innerHTML = `
        <h3 style="color:#6495ED;margin-bottom:12px;"><i class="fas fa-car"></i> פרטי רכב</h3>
        <div class="search-item">
            <div class="name">לוחית: ${data.plate}</div>
            <div class="detail">דגם: ${data.model}</div>
            <div class="detail">מהירות: ${Math.round(data.speed)} קמ"ש</div>
        </div>
    `;
}

// =============================================
// ESC key handler
// =============================================
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        document.getElementById('dispatch-panel').style.display = 'none';
        document.getElementById('search-results-panel').style.display = 'none';

        fetch('https://il_police/closeRadial', { method: 'POST', body: JSON.stringify({}) });
        fetch('https://il_police/closeF6', { method: 'POST', body: JSON.stringify({}) });
        fetch('https://il_police/closeMDT', { method: 'POST', body: JSON.stringify({}) });
    }
});
