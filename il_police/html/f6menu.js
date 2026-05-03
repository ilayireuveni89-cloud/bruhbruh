/* =============================================
   F6 Menu Script
   ============================================= */

(function() {
    let currentCategory = 'general';
    let allItems = [];
    let allCategories = [];

    // Create F6 menu container
    const f6HTML = `
    <div id="f6-menu">
        <div class="f6-container">
            <div class="f6-header">
                <div class="f6-header-info">
                    <div class="f6-header-badge"><i class="fas fa-shield-alt"></i></div>
                    <div class="f6-header-text">
                        <h2>תפריט משטרתי</h2>
                        <div class="f6-rank" id="f6-rank">שוטר</div>
                        <div class="f6-dept" id="f6-dept">סיור</div>
                    </div>
                </div>
                <div style="display:flex;align-items:center;gap:10px;">
                    <div class="f6-duty-badge off-duty" id="f6-duty">לא בתורנות</div>
                    <button class="close-btn" onclick="closeF6Menu()"><i class="fas fa-times"></i></button>
                </div>
            </div>
            <div class="f6-body">
                <div class="f6-categories" id="f6-categories"></div>
                <div class="f6-items" id="f6-items"></div>
            </div>
        </div>
        <div id="f6-form-overlay"></div>
    </div>`;

    document.body.insertAdjacentHTML('beforeend', f6HTML);

    // Listen for F6 messages
    window.addEventListener('message', function(event) {
        const data = event.data;

        switch(data.type) {
            case 'openF6':
                openF6(data);
                break;
            case 'closeF6':
                hideF6();
                break;
            case 'openTrafficReportForm':
                showTrafficReportForm(data.violations);
                break;
            case 'openCriminalReportForm':
                showCriminalReportForm(data.charges);
                break;
            case 'openArrestForm':
                showArrestForm(data.charges, data.targetSource);
                break;
            case 'openFineForm':
                showFineForm(data.targetSource);
                break;
            case 'openBOLOForm':
                showBOLOForm();
                break;
            case 'openGradeForm':
                showGradeForm(data.ranks);
                break;
        }
    });

    function openF6(data) {
        allItems = data.items || [];
        allCategories = data.categories || [];
        currentCategory = 'general';

        document.getElementById('f6-rank').textContent = data.rank || '';
        document.getElementById('f6-dept').textContent = data.departmentLabel || '';

        const dutyBadge = document.getElementById('f6-duty');
        if (data.onDuty) {
            dutyBadge.className = 'f6-duty-badge on-duty';
            dutyBadge.textContent = 'בתורנות';
        } else {
            dutyBadge.className = 'f6-duty-badge off-duty';
            dutyBadge.textContent = 'לא בתורנות';
        }

        renderCategories();
        renderItems();

        document.getElementById('f6-menu').style.display = 'flex';
    }

    function renderCategories() {
        const container = document.getElementById('f6-categories');
        container.innerHTML = '';

        allCategories.forEach(cat => {
            const hasItems = allItems.some(item => item.category === cat.id);
            if (!hasItems) return;

            const el = document.createElement('div');
            el.className = 'f6-category' + (currentCategory === cat.id ? ' active' : '');
            el.innerHTML = `<i class="fas ${cat.icon}"></i>${cat.label}`;
            el.onclick = function() {
                currentCategory = cat.id;
                renderCategories();
                renderItems();
            };
            container.appendChild(el);
        });
    }

    function renderItems() {
        const container = document.getElementById('f6-items');
        container.innerHTML = '';

        const filtered = allItems.filter(item => item.category === currentCategory);

        filtered.forEach(item => {
            const el = document.createElement('div');
            el.className = 'f6-item';
            el.innerHTML = `
                <div class="f6-item-icon"><i class="fas ${item.icon}"></i></div>
                <div class="f6-item-label">${item.label}</div>
            `;
            el.onclick = function() {
                fetch('https://il_police/f6Action', {
                    method: 'POST',
                    body: JSON.stringify({ action: item.id })
                });
            };
            container.appendChild(el);
        });
    }

    window.hideF6 = function() {
        document.getElementById('f6-menu').style.display = 'none';
        document.getElementById('f6-form-overlay').style.display = 'none';
    };

    window.closeF6Menu = function() {
        hideF6();
        fetch('https://il_police/closeF6', { method: 'POST', body: JSON.stringify({}) });
    };

    function closeFormOverlay() {
        document.getElementById('f6-form-overlay').style.display = 'none';
    }

    // =============================================
    // Traffic Report Form
    // =============================================
    window.showTrafficReportForm = function(violations) {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';
        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-file-alt"></i> הנפקת דוח תנועה</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם האזרח</label>
                        <input type="text" id="tr-citizen-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>ת.ז. / מזהה</label>
                        <input type="text" id="tr-citizen-id" placeholder="מספר מזהה">
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>לוחית רכב</label>
                        <input type="text" id="tr-plate" placeholder="מספר לוחית">
                    </div>
                    <div class="form-group">
                        <label>דגם רכב</label>
                        <input type="text" id="tr-model" placeholder="דגם">
                    </div>
                </div>
                <div class="form-group">
                    <label>עבירה</label>
                    <div class="checkbox-group" id="tr-violations">
                        ${violations.map((v, i) => `
                            <label class="checkbox-item">
                                <input type="checkbox" value="${i}" data-fine="${v.fine}" onchange="updateTrafficFine()">
                                ${v.label}
                                <span class="fine-amount">${v.fine}₪</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
                <div class="form-group">
                    <label>סכום קנס כולל</label>
                    <input type="number" id="tr-fine" value="0" min="0">
                </div>
                <div class="form-group">
                    <label>הערות</label>
                    <textarea id="tr-notes" placeholder="הערות נוספות..." rows="2"></textarea>
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-primary" onclick="submitTrafficReportForm()"><i class="fas fa-paper-plane"></i> הנפק דוח</button>
            </div>
        </div>`;
    };

    window.updateTrafficFine = function() {
        let total = 0;
        document.querySelectorAll('#tr-violations input[type="checkbox"]:checked').forEach(cb => {
            total += parseInt(cb.dataset.fine) || 0;
        });
        document.getElementById('tr-fine').value = total;
    };

    window.submitTrafficReportForm = function() {
        const violations = [];
        document.querySelectorAll('#tr-violations input[type="checkbox"]:checked').forEach(cb => {
            violations.push(cb.parentElement.textContent.trim().split('\n')[0].trim());
        });

        fetch('https://il_police/submitTrafficReport', {
            method: 'POST',
            body: JSON.stringify({
                citizenName: document.getElementById('tr-citizen-name').value,
                citizenId: document.getElementById('tr-citizen-id').value,
                vehiclePlate: document.getElementById('tr-plate').value,
                vehicleModel: document.getElementById('tr-model').value,
                violation: violations.join(', '),
                fineAmount: parseInt(document.getElementById('tr-fine').value) || 0,
                notes: document.getElementById('tr-notes').value
            })
        });
    };

    // =============================================
    // Criminal Report Form
    // =============================================
    window.showCriminalReportForm = function(charges) {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';
        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-gavel"></i> הנפקת דוח פלילי</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם החשוד</label>
                        <input type="text" id="cr-suspect-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>ת.ז. / מזהה</label>
                        <input type="text" id="cr-suspect-id" placeholder="מספר מזהה">
                    </div>
                </div>
                <div class="form-group">
                    <label>אישומים</label>
                    <div class="checkbox-group">
                        ${charges.map((c, i) => `
                            <label class="checkbox-item">
                                <input type="checkbox" value="${i}" class="cr-charge" data-jail="${c.jailTime}" data-bail="${c.bail}">
                                ${c.label}
                                <span class="fine-amount">${c.jailTime} דק' | ${c.bail}₪</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
                <div class="form-group">
                    <label>תיאור האירוע</label>
                    <textarea id="cr-description" placeholder="תאר את האירוע בפירוט..." rows="3"></textarea>
                </div>
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="cr-arrest" style="accent-color:#6495ED;"> בוצע מעצר
                    </label>
                </div>
                <div class="form-group">
                    <label>סכום ערבות</label>
                    <input type="number" id="cr-bail" value="0" min="0">
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-primary" onclick="submitCriminalReportForm()"><i class="fas fa-paper-plane"></i> צור דוח</button>
            </div>
        </div>`;
    };

    window.submitCriminalReportForm = function() {
        const charges = [];
        document.querySelectorAll('.cr-charge:checked').forEach(cb => {
            charges.push(cb.parentElement.textContent.trim().split('\n')[0].trim());
        });

        fetch('https://il_police/submitCriminalReport', {
            method: 'POST',
            body: JSON.stringify({
                suspectName: document.getElementById('cr-suspect-name').value,
                suspectId: document.getElementById('cr-suspect-id').value,
                charges: charges.join(', '),
                description: document.getElementById('cr-description').value,
                arrest: document.getElementById('cr-arrest').checked,
                bailAmount: parseInt(document.getElementById('cr-bail').value) || 0
            })
        });
    };

    // =============================================
    // Arrest Form
    // =============================================
    window.showArrestForm = function(charges, targetSource) {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';
        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-lock"></i> ביצוע מעצר</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <input type="hidden" id="ar-target" value="${targetSource}">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם החשוד</label>
                        <input type="text" id="ar-suspect-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>ת.ז. / מזהה</label>
                        <input type="text" id="ar-suspect-id" placeholder="מספר מזהה">
                    </div>
                </div>
                <div class="form-group">
                    <label>אישומים</label>
                    <div class="checkbox-group">
                        ${charges.map((c, i) => `
                            <label class="checkbox-item">
                                <input type="checkbox" value="${i}" class="ar-charge" data-jail="${c.jailTime}" data-bail="${c.bail}" onchange="updateArrestTotals()">
                                ${c.label}
                                <span class="fine-amount">${c.jailTime} דק'</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>זמן מאסר (דקות)</label>
                        <input type="number" id="ar-jail" value="0" min="0" max="240">
                    </div>
                    <div class="form-group">
                        <label>סכום ערבות</label>
                        <input type="number" id="ar-bail" value="0" min="0">
                    </div>
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-warning" onclick="submitArrestForm()"><i class="fas fa-lock"></i> בצע מעצר</button>
            </div>
        </div>`;
    };

    window.updateArrestTotals = function() {
        let totalJail = 0;
        let totalBail = 0;
        document.querySelectorAll('.ar-charge:checked').forEach(cb => {
            totalJail += parseInt(cb.dataset.jail) || 0;
            totalBail += parseInt(cb.dataset.bail) || 0;
        });
        document.getElementById('ar-jail').value = totalJail;
        document.getElementById('ar-bail').value = totalBail;
    };

    window.submitArrestForm = function() {
        const charges = [];
        document.querySelectorAll('.ar-charge:checked').forEach(cb => {
            charges.push(cb.parentElement.textContent.trim().split('\n')[0].trim());
        });

        fetch('https://il_police/submitArrest', {
            method: 'POST',
            body: JSON.stringify({
                targetSource: parseInt(document.getElementById('ar-target').value),
                suspectName: document.getElementById('ar-suspect-name').value,
                suspectId: document.getElementById('ar-suspect-id').value,
                charges: charges.join(', '),
                jailTime: parseInt(document.getElementById('ar-jail').value) || 0,
                bailAmount: parseInt(document.getElementById('ar-bail').value) || 0
            })
        });
    };

    // =============================================
    // Fine Form
    // =============================================
    window.showFineForm = function(targetSource) {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';
        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-money-bill"></i> קנס כספי</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <input type="hidden" id="fine-target" value="${targetSource}">
                <div class="form-row">
                    <div class="form-group">
                        <label>שם האזרח</label>
                        <input type="text" id="fine-citizen-name" placeholder="שם מלא">
                    </div>
                    <div class="form-group">
                        <label>סכום קנס</label>
                        <input type="number" id="fine-amount" value="500" min="0" max="100000">
                    </div>
                </div>
                <div class="form-group">
                    <label>סיבת הקנס</label>
                    <input type="text" id="fine-reason" placeholder="סיבה">
                </div>
                <div class="form-group">
                    <label>הערות</label>
                    <textarea id="fine-notes" placeholder="הערות נוספות..." rows="2"></textarea>
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-warning" onclick="submitFineForm()"><i class="fas fa-money-bill"></i> הנפק קנס</button>
            </div>
        </div>`;
    };

    window.submitFineForm = function() {
        fetch('https://il_police/submitFine', {
            method: 'POST',
            body: JSON.stringify({
                targetSource: parseInt(document.getElementById('fine-target').value),
                citizenName: document.getElementById('fine-citizen-name').value,
                violation: document.getElementById('fine-reason').value,
                fineAmount: parseInt(document.getElementById('fine-amount').value) || 0,
                notes: document.getElementById('fine-notes').value
            })
        });
    };

    // =============================================
    // BOLO Form
    // =============================================
    window.showBOLOForm = function() {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';
        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-bullhorn"></i> יצירת BOLO</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <div class="form-group">
                    <label>סוג</label>
                    <select id="bolo-type">
                        <option value="person">אדם חשוד</option>
                        <option value="vehicle">רכב חשוד</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>שם חשוד</label>
                    <input type="text" id="bolo-suspect" placeholder="שם (אם ידוע)">
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>לוחית רכב</label>
                        <input type="text" id="bolo-plate" placeholder="לוחית (אם רלוונטי)">
                    </div>
                    <div class="form-group">
                        <label>דגם רכב</label>
                        <input type="text" id="bolo-model" placeholder="דגם">
                    </div>
                </div>
                <div class="form-group">
                    <label>סיבה</label>
                    <input type="text" id="bolo-reason" placeholder="סיבת ה-BOLO">
                </div>
                <div class="form-group">
                    <label>תיאור</label>
                    <textarea id="bolo-desc" placeholder="תיאור מפורט..." rows="3"></textarea>
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-warning" onclick="submitBOLOForm()"><i class="fas fa-bullhorn"></i> שלח BOLO</button>
            </div>
        </div>`;
    };

    window.submitBOLOForm = function() {
        fetch('https://il_police/submitBOLO', {
            method: 'POST',
            body: JSON.stringify({
                type: document.getElementById('bolo-type').value,
                suspectName: document.getElementById('bolo-suspect').value,
                vehiclePlate: document.getElementById('bolo-plate').value,
                vehicleModel: document.getElementById('bolo-model').value,
                reason: document.getElementById('bolo-reason').value,
                description: document.getElementById('bolo-desc').value
            })
        });
    };

    // =============================================
    // Grade Change Form
    // =============================================
    window.showGradeForm = function(ranks) {
        const overlay = document.getElementById('f6-form-overlay');
        overlay.style.display = 'flex';

        let ranksHTML = '';
        for (const [grade, data] of Object.entries(ranks)) {
            ranksHTML += `<option value="${grade}">${grade} - ${data.label}</option>`;
        }

        overlay.innerHTML = `
        <div class="f6-form-container">
            <div class="f6-form-header">
                <h3><i class="fas fa-star"></i> שינוי דרגת שוטר</h3>
                <button class="close-btn" onclick="document.getElementById('f6-form-overlay').style.display='none'"><i class="fas fa-times"></i></button>
            </div>
            <div class="f6-form-body">
                <div class="form-group">
                    <label>מזהה שרת (Server ID) של השוטר</label>
                    <input type="number" id="grade-target" placeholder="Server ID" min="1">
                </div>
                <div class="form-group">
                    <label>דרגה חדשה</label>
                    <select id="grade-new">${ranksHTML}</select>
                </div>
            </div>
            <div class="f6-form-footer">
                <button class="btn btn-danger" onclick="document.getElementById('f6-form-overlay').style.display='none'">ביטול</button>
                <button class="btn btn-primary" onclick="submitGradeChangeForm()"><i class="fas fa-star"></i> שנה דרגה</button>
            </div>
        </div>`;
    };

    window.submitGradeChangeForm = function() {
        fetch('https://il_police/submitGradeChange', {
            method: 'POST',
            body: JSON.stringify({
                targetSource: document.getElementById('grade-target').value,
                newGrade: document.getElementById('grade-new').value
            })
        });
    };
})();
