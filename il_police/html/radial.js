/* =============================================
   Radial Menu Script
   ============================================= */

(function() {
    // Create radial menu container
    const radialHTML = `
    <div id="radial-menu">
        <div class="radial-overlay" onclick="closeRadialMenu()"></div>
        <div class="radial-container" id="radial-container">
            <div class="radial-center">
                <i class="fas fa-shield-alt"></i>
                <div class="center-text" id="radial-rank">משטרה</div>
            </div>
        </div>
    </div>`;

    document.body.insertAdjacentHTML('beforeend', radialHTML);

    // Listen for radial messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        if (data.type === 'openRadial') {
            openRadialMenu(data.items, data.rank, data.department);
        } else if (data.type === 'closeRadial') {
            hideRadialMenu();
        }
    });

    window.openRadialMenu = function(items, rank, department) {
        const menu = document.getElementById('radial-menu');
        const container = document.getElementById('radial-container');
        const centerText = document.getElementById('radial-rank');

        // Clear old items
        container.querySelectorAll('.radial-item, .radial-dept-badge').forEach(el => el.remove());

        centerText.textContent = rank || 'משטרה';

        // Calculate positions in a circle
        const radius = 140;
        const centerX = 200;
        const centerY = 200;
        const itemSize = 70;
        const angleStep = (2 * Math.PI) / items.length;
        const startAngle = -Math.PI / 2; // Start from top

        items.forEach((item, index) => {
            const angle = startAngle + (angleStep * index);
            const x = centerX + radius * Math.cos(angle) - itemSize / 2;
            const y = centerY + radius * Math.sin(angle) - itemSize / 2;

            const el = document.createElement('div');
            el.className = 'radial-item';
            el.style.left = x + 'px';
            el.style.top = y + 'px';
            el.style.animationDelay = (index * 0.05) + 's';
            el.innerHTML = `
                <i class="fas ${item.icon}"></i>
                <div class="radial-label">${item.label}</div>
            `;
            el.onclick = function() {
                fetch('https://il_police/radialAction', {
                    method: 'POST',
                    body: JSON.stringify({ action: item.action })
                });
            };
            container.appendChild(el);
        });

        // Department badge
        if (department) {
            const badge = document.createElement('div');
            badge.className = 'radial-dept-badge';
            badge.innerHTML = '<i class="fas fa-building"></i> ' + (department.label || '');
            container.querySelector('.radial-center').appendChild(badge);
        }

        container.classList.add('opening');
        menu.style.display = 'flex';

        setTimeout(() => container.classList.remove('opening'), 500);
    };

    window.hideRadialMenu = function() {
        document.getElementById('radial-menu').style.display = 'none';
    };

    window.closeRadialMenu = function() {
        hideRadialMenu();
        fetch('https://il_police/closeRadial', { method: 'POST', body: JSON.stringify({}) });
    };
})();
