/* =============================================
   VenusZone | RolePlay IL - HUD Script
   ============================================= */

(function() {
    const hud = document.getElementById('venus-hud');
    let config = {};
    let prevMoney = { cash: 0, bank: 0, black: 0 };

    window.addEventListener('message', function(event) {
        const data = event.data;

        switch(data.type) {
            case 'init':
                initHud(data);
                break;
            case 'showHud':
                toggleHud(data.show);
                break;
            case 'updateHud':
                updateHud(data);
                break;
            case 'updateMoney':
                updateMoney(data);
                break;
            case 'updateClock':
                updateClock(data);
                break;
            case 'updateStatus':
                updateStatus(data);
                break;
            case 'updateJob':
                updateJob(data);
                break;
            case 'updateServerId':
                document.getElementById('server-id').textContent = data.id;
                break;
        }
    });

    function initHud(data) {
        config = data;

        if (data.serverName) {
            document.getElementById('brand-name').textContent = data.serverName;
        }
        if (data.serverSubtitle) {
            document.getElementById('brand-sub').textContent = data.serverSubtitle;
        }

        if (data.primaryColor) {
            document.documentElement.style.setProperty('--primary', data.primaryColor);
        }

        if (!data.showMicrophone) {
            document.getElementById('mic-indicator').style.display = 'none';
        }
        if (!data.showMoney) {
            document.getElementById('money-display').style.display = 'none';
        }
        if (!data.showClock) {
            document.getElementById('clock-box').style.display = 'none';
        }
        if (!data.showJob) {
            document.getElementById('job-box').style.display = 'none';
        }
        if (!data.showServerId) {
            document.getElementById('server-id-box').style.display = 'none';
        }
        if (!data.showStatus) {
            document.getElementById('hunger-bar-container').style.display = 'none';
            document.getElementById('thirst-bar-container').style.display = 'none';
        }
        if (data.speedUnit === 'mph') {
            document.getElementById('speedo-unit').textContent = 'MPH';
        }
    }

    function toggleHud(show) {
        if (show) {
            hud.classList.add('visible');
        } else {
            hud.classList.remove('visible');
        }
    }

    function updateHud(data) {
        // בריאות
        if (data.health !== undefined) {
            const healthBar = document.getElementById('health-bar');
            const healthValue = document.getElementById('health-value');
            const healthContainer = document.getElementById('health-bar-container');

            healthBar.style.width = data.health + '%';
            healthValue.textContent = data.health;

            if (data.health <= 25) {
                healthContainer.classList.add('critical');
            } else {
                healthContainer.classList.remove('critical');
            }
        }

        // שריון
        if (data.armor !== undefined) {
            const armorBar = document.getElementById('armor-bar');
            const armorValue = document.getElementById('armor-value');
            const armorContainer = document.getElementById('armor-bar-container');

            armorBar.style.width = data.armor + '%';
            armorValue.textContent = data.armor;

            if (data.armor <= 0) {
                armorContainer.style.opacity = '0.4';
            } else {
                armorContainer.style.opacity = '1';
            }
        }

        // מיקרופון
        if (data.talking !== undefined) {
            const mic = document.getElementById('mic-indicator');
            if (data.talking) {
                mic.classList.add('talking');
            } else {
                mic.classList.remove('talking');
            }
        }

        // רכב
        const speedo = document.getElementById('speedometer');
        if (data.inVehicle) {
            speedo.style.display = 'flex';
            updateSpeedometer(data);
        } else {
            speedo.style.display = 'none';
        }
    }

    function updateSpeedometer(data) {
        if (data.speed !== undefined) {
            const speedEl = document.getElementById('speedo-speed');
            const arcEl = document.getElementById('speedo-arc');

            speedEl.textContent = data.speed;

            // עדכון arc - מקסימום 250 קמש
            const maxSpeed = 250;
            const circumference = 326.73;
            const percent = Math.min(data.speed / maxSpeed, 1);
            const offset = circumference * (1 - percent);
            arcEl.style.strokeDashoffset = offset;

            // צבע לפי מהירות
            if (data.speed > 180) {
                arcEl.style.stroke = 'var(--accent)';
            } else if (data.speed > 120) {
                arcEl.style.stroke = 'var(--warning)';
            } else {
                arcEl.style.stroke = 'var(--primary)';
            }
        }

        if (data.gear !== undefined) {
            const gearEl = document.getElementById('speedo-gear');
            gearEl.textContent = data.gear === 0 ? 'R' : data.gear;
        }

        if (data.fuel !== undefined) {
            const fuelBar = document.getElementById('fuel-bar');
            fuelBar.style.width = Math.max(0, Math.min(100, data.fuel)) + '%';

            if (data.fuel < 20) {
                fuelBar.style.background = 'var(--accent)';
            } else {
                fuelBar.style.background = 'linear-gradient(90deg, var(--accent), var(--warning), var(--success))';
            }
        }

        // מצפן
        if (data.heading !== undefined) {
            const compassEl = document.getElementById('compass');
            const arrowEl = document.getElementById('compass-arrow');
            const headingEl = document.getElementById('compass-heading');

            if (config.showCompass) {
                compassEl.style.display = 'block';
                arrowEl.style.transform = `rotate(${360 - data.heading}deg)`;
                headingEl.textContent = getCompassDirection(data.heading);
            }
        }
    }

    function getCompassDirection(heading) {
        const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        const index = Math.round(heading / 45) % 8;
        return directions[index];
    }

    function updateMoney(data) {
        animateMoneyChange('cash-amount', data.cash, prevMoney.cash, '.money-item.cash');
        animateMoneyChange('bank-amount', data.bank, prevMoney.bank, '.money-item.bank');
        animateMoneyChange('black-amount', data.black, prevMoney.black, '.money-item.black');

        // הסתרת כסף שחור אם 0
        const blackBox = document.getElementById('black-money-box');
        if (data.black <= 0) {
            blackBox.style.display = 'none';
        } else {
            blackBox.style.display = 'flex';
        }

        prevMoney = { cash: data.cash, bank: data.bank, black: data.black };
    }

    function animateMoneyChange(elementId, newValue, oldValue, containerSelector) {
        const el = document.getElementById(elementId);
        el.textContent = '$' + formatNumber(newValue);

        if (newValue !== oldValue) {
            const container = document.querySelector(containerSelector);
            container.classList.remove('money-up', 'money-down');
            void container.offsetWidth;

            if (newValue > oldValue) {
                container.classList.add('money-up');
            } else {
                container.classList.add('money-down');
            }

            setTimeout(() => {
                container.classList.remove('money-up', 'money-down');
            }, 600);
        }
    }

    function formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    function updateClock(data) {
        const hour = String(data.hour).padStart(2, '0');
        const minute = String(data.minute).padStart(2, '0');
        document.getElementById('clock-label').textContent = hour + ':' + minute;
    }

    function updateStatus(data) {
        if (data.hunger !== undefined) {
            document.getElementById('hunger-bar').style.width = data.hunger + '%';
            document.getElementById('hunger-value').textContent = data.hunger;
        }
        if (data.thirst !== undefined) {
            document.getElementById('thirst-bar').style.width = data.thirst + '%';
            document.getElementById('thirst-value').textContent = data.thirst;
        }
    }

    function updateJob(data) {
        const jobLabel = document.getElementById('job-label');
        if (data.grade) {
            jobLabel.textContent = data.job + ' | ' + data.grade;
        } else {
            jobLabel.textContent = data.job || 'אזרח';
        }
    }
})();
