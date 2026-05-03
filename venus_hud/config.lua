Config = {}

Config.ServerName = 'VenusZone'
Config.ServerTagline = 'RolePlay IL'

-- עדכון HUD (מילישניות)
Config.UpdateInterval = 150
Config.MoneyUpdateInterval = 2000

-- מפתח פתיחת הגדרות HUD
Config.SettingsKey = 'F9' -- 56 = F9
Config.SettingsCommand = 'hud'

-- מקש חגורת בטיחות
Config.SeatbeltKey = 'K'

-- יחידת מהירות ברירת מחדל
Config.DefaultSpeedUnit = 'kmh' -- 'kmh' | 'mph'

-- סגנון מד מהירות ברירת מחדל
Config.DefaultSpeedoStyle = 'arc' -- 'arc' | 'digital' | 'minimal'

-- צבעי ברירת מחדל
Config.DefaultColors = {
    health = '#e74c3c',
    armor = '#3498db',
    hunger = '#f39c12',
    thirst = '#00bcd4',
    stamina = '#2ecc71',
    oxygen = '#9b59b6',
    stress = '#e91e63',
}

-- הצגת אלמנטים ברירת מחדל
Config.DefaultVisible = {
    health = true,
    armor = true,
    hunger = true,
    thirst = true,
    stamina = false,
    oxygen = false,
    money = true,
    job = true,
    serverId = true,
    clock = true,
    mic = true,
    speedometer = true,
    compass = true,
    seatbelt = true,
    fuel = true,
    serverLogo = true,
    streetName = true,
}

-- חגורת בטיחות
Config.Seatbelt = {
    enabled = true,
    ejectSpeed = 80, -- מהירות מינימלית לזריקה מרכב
    ejectChance = 70, -- אחוז סיכוי לזריקה
}

-- סטטוס (esx_status)
Config.UseStatus = true

-- רחוב
Config.ShowStreetName = true
