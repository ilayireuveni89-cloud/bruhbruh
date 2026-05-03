/* =============================================
   MDT (Mobile Data Terminal) Script
   ============================================= */

(function() {
    let currentPage = 'dashboard';
    let mdtData = {};
    let reportPages = { traffic: 1, criminal: 1, arrests: 1, bolo: 1 };

    // Create MDT container
    const mdtHTML = `
    <div id="mdt-panel">
        <div class="mdt-container">
            <div class="mdt-header">
                <div class="mdt-header-left">
                    <div class="mdt-logo"><i class="fas fa-shield-alt"></i></div>
                    <div>
                        <div class="mdt-title">מסוף משטרתי - MDT</div>
                        <div class="mdt-subtitle">משטרת ישראל | Israel Police</div>
                    </div>
                </div>
                <div class="mdt-header-right">
                    <div class="mdt-officer-info">
                        <div class="mdt-officer-name" id="mdt-officer-name">שוטר</div>
                        <div class="mdt-officer-rank" id="mdt-officer-rank">דרגה</div>
                    </div>
                    <button class="close-btn" onclick="closeMDTPanel()" style="font-size:20px;"><i class="fas fa-times"></i></button>
                </div>
            </div>
            <div class="mdt-body">
                <div class="mdt-sidebar">
                    <div class="mdt-nav">
                        <div class="mdt-nav-item active" data-page="dashboard" onclick="mdtNav('dashboard')">
                            <i class="fas fa-home"></i> לוח בקרה
                        </div>
                        <div class="mdt-nav-divider"></div>
                        <div class="mdt-nav-item" data-page="search-citizen" onclick="mdtNav('search-citizen')">
                            <i class="fas fa-user-search"></i> חיפוש אזרח
                        </div>
                        <div class="mdt-nav-item" data-page="search-vehicle" onclick="mdtNav('search-vehicle')">
                            <i class="fas fa-car"></i> חיפוש רכב
                        </div>
                        <div class="mdt-nav-divider"></div>
                        <div class="mdt-nav-item" data-page="traffic-reports" onclick="mdtNav('traffic-reports')">
                            <i class="fas fa-file-alt"></i> דוחות תנועה
                        </div>
                        <div class="mdt-nav-item" data-page="criminal-reports" onclick="mdtNav('criminal-reports')">
                            <i class="fas fa-gavel"></i> דוחות פליליים
                        </div>
                        <div class="mdt-nav-item" data-page="arrests" onclick="mdtNav('arrests')">
                            <i class="fas fa-lock"></i> מעצרים
                        </div>
                        <div class="mdt-nav-divider"></div>
                        <div class="mdt-nav-item" data-page="bolo" onclick="mdtNav('bolo')">
                            <i class="fas fa-bullhorn"></i> BOLO
                        </div>
                        <div class="mdt-nav-item" data-page="officers" onclick="mdtNav('officers')">
                            <i class="fas fa-users"></i> שוטרים מחוברים
                        </div>
                        <div class="mdt-nav-divider"></div>
                        <div class="mdt-nav-item" data-page="new-traffic" onclick="mdtNav('new-traffic')">
                            <i class="fas fa-plus-circle"></i> דוח תנועה חדש
                        </div>
                        <div class="mdt-nav-item" data-page="new-criminal" onclick="mdtNav('new-criminal')">
                            <i class="fas fa-plus-circle"></i> דוח פלילי חדש
                        </div>
                        <div class="mdt-nav-item" data-page="new-bolo" onclick="mdtNav('new-bolo')">
                            <i class="fas fa-plus-circle"></i> BOLO חדש
                        </div>
                        <div class="mdt-nav-divider"></div>
                        <div class="mdt-nav-item" data-page="dispatch" onclick="mdtNav('dispatch')">
                            <i class="fas fa-headset"></i> מוקד
                        </div>
                    </div>
                </div>
                <div class="mdt-content" id="mdt-content"></div>
            </div>
        </div>
    </div>`;

    document.body.insertAdjacentHTML('beforeend', mdtHTML);

    // Listen for MDT messages
    window.addEventListener('message', function(event) {
        const data = event.data;

        switch(data.type) {
            case 'openMDT':
                mdtData = data;
                openMDTPanel(data);
                break;
            case 'closeMDT':
                hideMDT();
                break;
            case 'officerInfo':
                document.getElementById('mdt-officer-name').textContent = data.data.name || '';
                document.getElementById('mdt-officer-rank').textContent = data.data.rankLabel || '';
                break;
            case 'stats':
                mdtData.stats = data.data;
                if (currentPage === 'dashboard') renderDashboard();
                break;
            case 'searchResults':
                renderSearchResults(data.searchType, data.results);
                break;
            case 'reports':
                renderReports(data.reportType, data.reports, data.total);
                break;
            case 'onlineCops':
                renderOfficers(data.cops);
                break;
        }
    });

    function openMDTPanel(data) {
        document.getElementById('mdt-officer-rank').textContent = data.rank || '';
        currentPage = 'dashboard';
        updateNavActive();
        renderDashboard();
        document.getElementById('mdt-panel').style.display = 'flex';
    }

    window.hideMDT = function() {
        document.getElementById('mdt-panel').style.display = 'none';
    };

    window.closeMDTPanel = function() {
        hideMDT();
        fetch('https://il_police/closeMDT', { method: 'POST', body: JSON.stringify({}) });
    };

    window.mdtNav = function(page) {
        currentPage = page;
        updateNavActive();

        switch(page) {
            case 'dashboard':
                fetch('https://il_police/mdtGetStats', { method: 'POST', body: JSON.stringify({}) });
                renderDashboard();
                break;
            case 'search-citizen':
                renderCitizenSearch();
                break;
            case 'search-vehicle':
                renderVehicleSearch();
                break;
            case 'traffic-reports':
                reportPages.traffic = 1;
                fetch('https://il_police/mdtGetReports', { method: 'POST', body: JSON.stringify({ reportType: 'traffic', page: 1 }) });
                renderLoading();
                break;
            case 'criminal-reports':
                reportPages.criminal = 1;
                fetch('https://il_police/mdtGetReports', { method: 'POST', body: JSON.stringify({ reportType: 'criminal', page: 1 }) });
                renderLoading();
                break;
            case 'arrests':
                reportPages.arrests = 1;
                fetch('https://il_police/mdtGetReports', { method: 'POST', body: JSON.stringify({ reportType: 'arrests', page: 1 }) });
                renderLoading();
                break;
            case 'bolo':
                reportPages.bolo = 1;
                fetch('https://il_police/mdtGetReports', { method: 'POST', body: JSON.stringify({ reportType: 'bolo', page: 1 }) });
                renderLoading();
                break;
            case 'officers':
                fetch('https://il_police/mdtGetOnlineCops', { method: 'POST', body: JSON.stringify({}) });
                renderLoading();
                break;
            case 'new-traffic':
                renderNewTrafficForm();
                break;
            case 'new-criminal':
                renderNewCriminalForm();
                break;
            case 'new-bolo':
                renderNewBOLOForm();
                break;
            case 'dispatch':
                renderDispatchPage();
                break;
        }
    };

    function updateNavActive() {
        document.querySelectorAll('.mdt-nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.page === currentPage);
        });
    }

    function renderLoading() {
        document.getElementById('mdt-content').innerHTML = `
            <div class="mdt-no-results">
                <i class="fas fa-spinner fa-spin"></i>
                <div>טוען נתונים...</div>
            </div>`;
    }

    // =============================================
    // Dashboard
    // =============================================
    function renderDashboard() {
        const stats = mdtData.stats || {};
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-tachometer-alt"></i> לוח בקרה</div>
            <div class="mdt-stats-grid">
                <div class="mdt-stat-card">
                    <div class="mdt-stat-value">${stats.trafficReports || 0}</div>
                    <div class="mdt-stat-label">דוחות תנועה</div>
                </div>
                <div class="mdt-stat-card">
                    <div class="mdt-stat-value">${stats.criminalReports || 0}</div>
                    <div class="mdt-stat-label">דוחות פליליים</div>
                </div>
                <div class="mdt-stat-card">
                    <div class="mdt-stat-value">${stats.arrests || 0}</div>
                    <div class="mdt-stat-label">מעצרים</div>
                </div>
                <div class="mdt-stat-card">
                    <div class="mdt-stat-value">${stats.activeBolo || 0}</div>
                    <div class="mdt-stat-label">BOLO פעילים</div>
                </div>
                <div class="mdt-stat-card">
                    <div class="mdt-stat-value">${stats.onlineCops || 0}</div>
                    <div class="mdt-stat-label">שוטרים מחוברים</div>
                </div>
            </div>
            <div class="mdt-section-title"><i class="fas fa-bolt"></i> פעולות מהירות</div>
            <div class="mdt-quick-actions">
                <div class="mdt-quick-action" onclick="mdtNav('search-citizen')">
                    <i class="fas fa-user-search"></i>
                    <div class="label">חיפוש אזרח</div>
                </div>
                <div class="mdt-quick-action" onclick="mdtNav('search-vehicle')">
                    <i class="fas fa-car"></i>
                    <div class="label">חיפוש רכב</div>
                </div>
                <div class="mdt-quick-action" onclick="mdtNav('new-traffic')">
                    <i class="fas fa-file-alt"></i>
                    <div class="label">דוח תנועה חדש</div>
                </div>
                <div class="mdt-quick-action" onclick="mdtNav('new-criminal')">
                    <i class="fas fa-gavel"></i>
                    <div class="label">דוח פלילי חדש</div>
                </div>
            </div>
        `;
    }

    // =============================================
    // Citizen Search
    // =============================================
    function renderCitizenSearch() {
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-user-search"></i> חיפוש אזרח</div>
            <div class="mdt-search-bar">
                <input type="text" id="mdt-citizen-search" placeholder="הקלד שם אזרח..." onkeypress="if(event.key==='Enter')mdtSearchCitizen()">
                <button onclick="mdtSearchCitizen()"><i class="fas fa-search"></i> חפש</button>
            </div>
            <div id="mdt-citizen-results"></div>
        `;
    }

    window.mdtSearchCitizen = function() {
        const name = document.getElementById('mdt-citizen-search').value;
        if (!name.trim()) return;
        document.getElementById('mdt-citizen-results').innerHTML = '<div class="mdt-no-results"><i class="fas fa-spinner fa-spin"></i><div>מחפש...</div></div>';
        fetch('https://il_police/mdtSearchCitizen', { method: 'POST', body: JSON.stringify({ name: name }) });
    };

    // =============================================
    // Vehicle Search
    // =============================================
    function renderVehicleSearch() {
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-car"></i> חיפוש רכב</div>
            <div class="mdt-search-bar">
                <input type="text" id="mdt-vehicle-search" placeholder="הקלד מספר לוחית..." onkeypress="if(event.key==='Enter')mdtSearchVehicle()">
                <button onclick="mdtSearchVehicle()"><i class="fas fa-search"></i> חפש</button>
            </div>
            <div id="mdt-vehicle-results"></div>
        `;
    }

    window.mdtSearchVehicle = function() {
        const plate = document.getElementById('mdt-vehicle-search').value;
        if (!plate.trim()) return;
        document.getElementById('mdt-vehicle-results').innerHTML = '<div class="mdt-no-results"><i class="fas fa-spinner fa-spin"></i><div>מחפש...</div></div>';
        fetch('https://il_police/mdtSearchVehicle', { method: 'POST', body: JSON.stringify({ plate: plate }) });
    };

    // =============================================
    // Search Results Renderer
    // =============================================
    function renderSearchResults(searchType, results) {
        if (searchType === 'citizen') {
            const container = document.getElementById('mdt-citizen-results');
            if (!container) return;
            if (!results || results.length === 0) {
                container.innerHTML = '<div class="mdt-no-results"><i class="fas fa-user-slash"></i><div>לא נמצאו תוצאות</div></div>';
                return;
            }
            let html = '<table class="mdt-table"><tr><th>שם</th><th>מזהה</th><th>עבודה</th><th>סטטוס</th></tr>';
            results.forEach(r => {
                html += `<tr>
                    <td>${r.name}</td>
                    <td style="font-size:11px;color:rgba(255,255,255,0.5);">${r.identifier || ''}</td>
                    <td>${r.job || ''}</td>
                    <td>${r.source ? '<span class="status-badge status-active">מקוון</span>' : '<span class="status-badge status-cancelled">לא מקוון</span>'}</td>
                </tr>`;
            });
            html += '</table>';
            container.innerHTML = html;
        } else if (searchType === 'vehicle') {
            const container = document.getElementById('mdt-vehicle-results');
            if (!container) return;
            if ((!results.vehicles || results.vehicles.length === 0) && (!results.reports || results.reports.length === 0)) {
                container.innerHTML = '<div class="mdt-no-results"><i class="fas fa-car-crash"></i><div>לא נמצאו תוצאות</div></div>';
                return;
            }
            let html = '';
            if (results.vehicles && results.vehicles.length > 0) {
                html += '<h3 style="color:#6495ED;margin-bottom:10px;"><i class="fas fa-car"></i> פרטי רכב</h3>';
                html += '<table class="mdt-table"><tr><th>לוחית</th><th>בעלים</th><th>דגם</th><th>מצב</th></tr>';
                results.vehicles.forEach(v => {
                    html += `<tr>
                        <td>${v.plate}</td>
                        <td>${v.owner || ''}</td>
                        <td>${v.model || ''}</td>
                        <td>${v.stored ? 'מאוחסן' : 'ברחוב'}</td>
                    </tr>`;
                });
                html += '</table>';
            }
            if (results.reports && results.reports.length > 0) {
                html += '<h3 style="color:#f39c12;margin:20px 0 10px;"><i class="fas fa-file-alt"></i> דוחות קודמים</h3>';
                html += '<table class="mdt-table"><tr><th>מס\' דוח</th><th>עבירה</th><th>קנס</th><th>תאריך</th></tr>';
                results.reports.forEach(r => {
                    html += `<tr>
                        <td>${r.report_id}</td>
                        <td>${r.violation || ''}</td>
                        <td>${r.fine_amount || 0}₪</td>
                        <td>${r.created_at || ''}</td>
                    </tr>`;
                });
                html += '</table>';
            }
            container.innerHTML = html;
        }
    }

    // =============================================
    // Reports Renderer
    // =============================================
    function renderReports(reportType, reports, total) {
        const content = document.getElementById('mdt-content');

        if (!reports || reports.length === 0) {
            content.innerHTML = `
                <div class="mdt-section-title"><i class="fas fa-file-alt"></i> ${getReportTitle(reportType)}</div>
                <div class="mdt-no-results"><i class="fas fa-folder-open"></i><div>אין דוחות להצגה</div></div>`;
            return;
        }

        let html = `<div class="mdt-section-title"><i class="fas fa-file-alt"></i> ${getReportTitle(reportType)} (${total})</div>`;

        if (reportType === 'traffic') {
            html += '<table class="mdt-table"><tr><th>מס\' דוח</th><th>אזרח</th><th>לוחית</th><th>עבירה</th><th>קנס</th><th>סטטוס</th><th>תאריך</th></tr>';
            reports.forEach(r => {
                html += `<tr>
                    <td>${r.report_id}</td>
                    <td>${r.citizen_name || ''}</td>
                    <td>${r.vehicle_plate || ''}</td>
                    <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;">${r.violation || ''}</td>
                    <td>${r.fine_amount || 0}₪</td>
                    <td><span class="status-badge status-${r.status}">${getStatusLabel(r.status)}</span></td>
                    <td style="font-size:11px;">${r.created_at || ''}</td>
                </tr>`;
            });
            html += '</table>';
        } else if (reportType === 'criminal') {
            html += '<table class="mdt-table"><tr><th>מס\' דוח</th><th>חשוד</th><th>אישומים</th><th>מעצר</th><th>ערבות</th><th>סטטוס</th><th>תאריך</th></tr>';
            reports.forEach(r => {
                html += `<tr>
                    <td>${r.report_id}</td>
                    <td>${r.suspect_name || ''}</td>
                    <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;">${r.charges || ''}</td>
                    <td>${r.arrest ? 'כן' : 'לא'}</td>
                    <td>${r.bail_amount || 0}₪</td>
                    <td><span class="status-badge status-${r.status}">${getStatusLabel(r.status)}</span></td>
                    <td style="font-size:11px;">${r.created_at || ''}</td>
                </tr>`;
            });
            html += '</table>';
        } else if (reportType === 'arrests') {
            html += '<table class="mdt-table"><tr><th>מס\' מעצר</th><th>חשוד</th><th>אישומים</th><th>זמן כלא</th><th>ערבות</th><th>סטטוס</th><th>תאריך</th></tr>';
            reports.forEach(r => {
                html += `<tr>
                    <td>${r.arrest_id}</td>
                    <td>${r.suspect_name || ''}</td>
                    <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;">${r.charges || ''}</td>
                    <td>${r.jail_time || 0} דק'</td>
                    <td>${r.bail_amount || 0}₪</td>
                    <td><span class="status-badge status-${r.status === 'detained' ? 'open' : r.status === 'released' ? 'active' : 'closed'}">${getArrestStatusLabel(r.status)}</span></td>
                    <td style="font-size:11px;">${r.created_at || ''}</td>
                </tr>`;
            });
            html += '</table>';
        } else if (reportType === 'bolo') {
            reports.forEach(r => {
                html += `
                <div class="mdt-bolo-card">
                    <div class="bolo-header">
                        <span class="bolo-type">${r.type === 'person' ? 'אדם' : 'רכב'}</span>
                        <button class="bolo-cancel" onclick="cancelBOLO(${r.id})"><i class="fas fa-times"></i> בטל</button>
                    </div>
                    <div class="bolo-reason">${r.reason || ''}</div>
                    <div class="bolo-desc">${r.description || ''}</div>
                    ${r.suspect_name ? '<div class="bolo-info"><i class="fas fa-user"></i> ' + r.suspect_name + '</div>' : ''}
                    ${r.vehicle_plate ? '<div class="bolo-info"><i class="fas fa-car"></i> ' + r.vehicle_plate + ' ' + (r.vehicle_model || '') + '</div>' : ''}
                    <div class="bolo-info"><i class="fas fa-user-shield"></i> ${r.officer_name || ''} | ${r.created_at || ''}</div>
                </div>`;
            });
        }

        // Pagination
        const totalPages = Math.ceil(total / 20);
        if (totalPages > 1) {
            html += '<div class="mdt-pagination">';
            for (let i = 1; i <= Math.min(totalPages, 10); i++) {
                html += `<button class="${reportPages[reportType] === i ? 'active' : ''}" onclick="mdtLoadPage('${reportType}', ${i})">${i}</button>`;
            }
            html += '</div>';
        }

        content.innerHTML = html;
    }

    window.mdtLoadPage = function(reportType, page) {
        reportPages[reportType] = page;
        fetch('https://il_police/mdtGetReports', { method: 'POST', body: JSON.stringify({ reportType: reportType, page: page }) });
        renderLoading();
    };

    window.cancelBOLO = function(boloId) {
        fetch('https://il_police/mdtCancelBOLO', { method: 'POST', body: JSON.stringify({ boloId: boloId }) });
        setTimeout(() => mdtNav('bolo'), 500);
    };

    // =============================================
    // Officers
    // =============================================
    function renderOfficers(cops) {
        const content = document.getElementById('mdt-content');
        let html = `<div class="mdt-section-title"><i class="fas fa-users"></i> שוטרים מחוברים (${cops.length})</div>`;

        if (cops.length === 0) {
            html += '<div class="mdt-no-results"><i class="fas fa-user-slash"></i><div>אין שוטרים מחוברים</div></div>';
        } else {
            cops.forEach(cop => {
                html += `
                <div class="mdt-officer-card">
                    <div class="mdt-officer-avatar"><i class="fas fa-user-shield"></i></div>
                    <div class="mdt-officer-details">
                        <div class="name">${cop.name}</div>
                        <span class="rank-badge">${cop.rankLabel} | ${cop.department || ''}</span>
                    </div>
                    <div class="mdt-officer-status ${cop.onDuty ? 'online' : 'offline'}">
                        ${cop.onDuty ? 'בתורנות' : 'לא בתורנות'}
                    </div>
                </div>`;
            });
        }

        content.innerHTML = html;
    }

    // =============================================
    // New Traffic Report (inside MDT)
    // =============================================
    function renderNewTrafficForm() {
        const violations = mdtData.violations || [];
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-plus-circle"></i> דוח תנועה חדש</div>
            <div class="mdt-form">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם האזרח</label>
                        <input type="text" id="mdt-tr-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>ת.ז. / מזהה</label>
                        <input type="text" id="mdt-tr-id" placeholder="מספר מזהה">
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>לוחית רכב</label>
                        <input type="text" id="mdt-tr-plate" placeholder="מספר לוחית">
                    </div>
                    <div class="form-group">
                        <label>דגם רכב</label>
                        <input type="text" id="mdt-tr-model" placeholder="דגם">
                    </div>
                </div>
                <div class="form-group">
                    <label>עבירות</label>
                    <div class="checkbox-group">
                        ${violations.map((v, i) => `
                            <label class="checkbox-item">
                                <input type="checkbox" class="mdt-tr-violation" data-fine="${v.fine}" onchange="mdtUpdateTrafficFine()">
                                ${v.label}
                                <span class="fine-amount">${v.fine}₪</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
                <div class="form-group">
                    <label>סכום קנס</label>
                    <input type="number" id="mdt-tr-fine" value="0" min="0">
                </div>
                <div class="form-group">
                    <label>הערות</label>
                    <textarea id="mdt-tr-notes" placeholder="הערות..." rows="2"></textarea>
                </div>
                <button class="btn btn-primary" onclick="mdtSubmitTrafficReport()"><i class="fas fa-paper-plane"></i> הנפק דוח</button>
            </div>
        `;
    }

    window.mdtUpdateTrafficFine = function() {
        let total = 0;
        document.querySelectorAll('.mdt-tr-violation:checked').forEach(cb => {
            total += parseInt(cb.dataset.fine) || 0;
        });
        document.getElementById('mdt-tr-fine').value = total;
    };

    window.mdtSubmitTrafficReport = function() {
        const violations = [];
        document.querySelectorAll('.mdt-tr-violation:checked').forEach(cb => {
            violations.push(cb.parentElement.textContent.trim().split('\n')[0].trim());
        });

        fetch('https://il_police/mdtCreateTrafficReport', {
            method: 'POST',
            body: JSON.stringify({
                citizenName: document.getElementById('mdt-tr-name').value,
                citizenId: document.getElementById('mdt-tr-id').value,
                vehiclePlate: document.getElementById('mdt-tr-plate').value,
                vehicleModel: document.getElementById('mdt-tr-model').value,
                violation: violations.join(', '),
                fineAmount: parseInt(document.getElementById('mdt-tr-fine').value) || 0,
                notes: document.getElementById('mdt-tr-notes').value
            })
        });

        showNotification('success', 'דוח תנועה הונפק');
        setTimeout(() => mdtNav('traffic-reports'), 1000);
    };

    // =============================================
    // New Criminal Report (inside MDT)
    // =============================================
    function renderNewCriminalForm() {
        const charges = mdtData.charges || [];
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-plus-circle"></i> דוח פלילי חדש</div>
            <div class="mdt-form">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם החשוד</label>
                        <input type="text" id="mdt-cr-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>ת.ז. / מזהה</label>
                        <input type="text" id="mdt-cr-id" placeholder="מספר מזהה">
                    </div>
                </div>
                <div class="form-group">
                    <label>אישומים</label>
                    <div class="checkbox-group">
                        ${charges.map((c, i) => `
                            <label class="checkbox-item">
                                <input type="checkbox" class="mdt-cr-charge" data-jail="${c.jailTime}" data-bail="${c.bail}">
                                ${c.label}
                                <span class="fine-amount">${c.jailTime} דק' | ${c.bail}₪</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
                <div class="form-group">
                    <label>תיאור האירוע</label>
                    <textarea id="mdt-cr-desc" placeholder="תיאור מפורט..." rows="3"></textarea>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label><input type="checkbox" id="mdt-cr-arrest" style="accent-color:#6495ED;"> בוצע מעצר</label>
                    </div>
                    <div class="form-group">
                        <label>סכום ערבות</label>
                        <input type="number" id="mdt-cr-bail" value="0" min="0">
                    </div>
                </div>
                <button class="btn btn-primary" onclick="mdtSubmitCriminalReport()"><i class="fas fa-paper-plane"></i> צור דוח</button>
            </div>
        `;
    }

    window.mdtSubmitCriminalReport = function() {
        const charges = [];
        document.querySelectorAll('.mdt-cr-charge:checked').forEach(cb => {
            charges.push(cb.parentElement.textContent.trim().split('\n')[0].trim());
        });

        fetch('https://il_police/mdtCreateCriminalReport', {
            method: 'POST',
            body: JSON.stringify({
                suspectName: document.getElementById('mdt-cr-name').value,
                suspectId: document.getElementById('mdt-cr-id').value,
                charges: charges.join(', '),
                description: document.getElementById('mdt-cr-desc').value,
                arrest: document.getElementById('mdt-cr-arrest').checked,
                bailAmount: parseInt(document.getElementById('mdt-cr-bail').value) || 0
            })
        });

        showNotification('success', 'דוח פלילי נוצר');
        setTimeout(() => mdtNav('criminal-reports'), 1000);
    };

    // =============================================
    // New BOLO (inside MDT)
    // =============================================
    function renderNewBOLOForm() {
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-plus-circle"></i> BOLO חדש</div>
            <div class="mdt-form">
                <div class="form-group">
                    <label>סוג</label>
                    <select id="mdt-bolo-type">
                        <option value="person">אדם חשוד</option>
                        <option value="vehicle">רכב חשוד</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>שם חשוד</label>
                    <input type="text" id="mdt-bolo-suspect" placeholder="שם (אם ידוע)">
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>לוחית רכב</label>
                        <input type="text" id="mdt-bolo-plate" placeholder="לוחית">
                    </div>
                    <div class="form-group">
                        <label>דגם רכב</label>
                        <input type="text" id="mdt-bolo-model" placeholder="דגם">
                    </div>
                </div>
                <div class="form-group">
                    <label>סיבה</label>
                    <input type="text" id="mdt-bolo-reason" placeholder="סיבת ה-BOLO">
                </div>
                <div class="form-group">
                    <label>תיאור</label>
                    <textarea id="mdt-bolo-desc" placeholder="תיאור מפורט..." rows="3"></textarea>
                </div>
                <button class="btn btn-warning" onclick="mdtSubmitBOLO()"><i class="fas fa-bullhorn"></i> שלח BOLO</button>
            </div>
        `;
    }

    window.mdtSubmitBOLO = function() {
        fetch('https://il_police/mdtCreateBOLO', {
            method: 'POST',
            body: JSON.stringify({
                type: document.getElementById('mdt-bolo-type').value,
                suspectName: document.getElementById('mdt-bolo-suspect').value,
                vehiclePlate: document.getElementById('mdt-bolo-plate').value,
                vehicleModel: document.getElementById('mdt-bolo-model').value,
                reason: document.getElementById('mdt-bolo-reason').value,
                description: document.getElementById('mdt-bolo-desc').value
            })
        });

        showNotification('warning', 'BOLO נשלח לכלל השוטרים');
        setTimeout(() => mdtNav('bolo'), 1000);
    };

    // =============================================
    // Dispatch Page (inside MDT)
    // =============================================
    function renderDispatchPage() {
        const content = document.getElementById('mdt-content');
        content.innerHTML = `
            <div class="mdt-section-title"><i class="fas fa-headset"></i> מוקד משטרתי</div>
            <div class="mdt-form">
                <div class="form-group">
                    <label>קוד אירוע</label>
                    <select id="mdt-dispatch-code">
                        <option value="10-4">10-4 - הבנתי</option>
                        <option value="10-8">10-8 - בשירות</option>
                        <option value="10-20">10-20 - מיקום</option>
                        <option value="10-31">10-31 - פשע בביצוע</option>
                        <option value="10-32">10-32 - נשק חם</option>
                        <option value="10-50">10-50 - תאונת דרכים</option>
                        <option value="10-71">10-71 - ירי</option>
                        <option value="10-80">10-80 - מרדף</option>
                        <option value="10-99">10-99 - שוטר בסכנה</option>
                        <option value="code-3">קוד 3 - חירום</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>הודעה למוקד</label>
                    <textarea id="mdt-dispatch-msg" placeholder="הקלד הודעה..." rows="3"></textarea>
                </div>
                <button class="btn btn-primary" onclick="mdtSendDispatch()"><i class="fas fa-paper-plane"></i> שלח הודעה</button>
            </div>
        `;
    }

    window.mdtSendDispatch = function() {
        const message = document.getElementById('mdt-dispatch-msg').value;
        const code = document.getElementById('mdt-dispatch-code').value;
        if (!message.trim()) return;

        fetch('https://il_police/mdtDispatch', {
            method: 'POST',
            body: JSON.stringify({ message: message, code: code })
        });

        document.getElementById('mdt-dispatch-msg').value = '';
        showNotification('success', 'הודעה נשלחה למוקד');
    };

    // =============================================
    // Helper Functions
    // =============================================
    function getReportTitle(type) {
        switch(type) {
            case 'traffic': return 'דוחות תנועה';
            case 'criminal': return 'דוחות פליליים';
            case 'arrests': return 'מעצרים';
            case 'bolo': return 'BOLO פעילים';
            default: return 'דוחות';
        }
    }

    function getStatusLabel(status) {
        switch(status) {
            case 'active': return 'פעיל';
            case 'paid': return 'שולם';
            case 'cancelled': return 'בוטל';
            case 'open': return 'פתוח';
            case 'closed': return 'סגור';
            case 'investigation': return 'בחקירה';
            default: return status || '';
        }
    }

    function getArrestStatusLabel(status) {
        switch(status) {
            case 'detained': return 'עצור';
            case 'released': return 'שוחרר';
            case 'jailed': return 'בכלא';
            case 'bailed': return 'ערבות';
            default: return status || '';
        }
    }
})();
