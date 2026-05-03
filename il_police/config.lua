Config = {}

-- =============================================
-- הגדרות כלליות
-- =============================================
Config.Locale = 'he'
Config.PoliceJob = 'police'
Config.RequiredCops = 0 -- מספר שוטרים מינימלי בשביל פעולות מסוימות

-- =============================================
-- דרגות משטרה ישראלית
-- =============================================
Config.Ranks = {
    [0]  = { name = 'academy',           label = 'אקדמאי',              department = 'academy' },
    [1]  = { name = 'patrol_officer',    label = 'שוטר סיור',           department = 'patrol' },
    [2]  = { name = 'patrol_senior',     label = 'רב שוטר סיור',        department = 'patrol' },
    [3]  = { name = 'patrol_deputy',     label = 'ע.קצין סיור',         department = 'patrol' },
    [4]  = { name = 'patrol_lt',         label = 'קצין סיור',           department = 'patrol' },
    [5]  = { name = 'patrol_deputy_cmd', label = 'סגן מפקד סיור',       department = 'patrol' },
    [6]  = { name = 'patrol_commander',  label = 'מפקד סיור',           department = 'patrol' },
    [7]  = { name = 'yasam_trainee',     label = 'יס"מ מתלמד',          department = 'yasam' },
    [8]  = { name = 'yasam_fighter',     label = 'לוחם יס"מ',           department = 'yasam' },
    [9]  = { name = 'yasam_senior',      label = 'יס"מ רב לוחם',        department = 'yasam' },
    [10] = { name = 'yasam_deputy_cmd',  label = 'סגן מפקד יס"מ',       department = 'yasam' },
    [11] = { name = 'yasam_commander',   label = 'מפקד יס"מ',           department = 'yasam' },
    [12] = { name = 'magav_trainee',     label = 'מג"ב מתלמד',          department = 'magav' },
    [13] = { name = 'magav_fighter',     label = 'מג"ב לוחם',           department = 'magav' },
    [14] = { name = 'magav_senior',      label = 'מג"ב רב לוחם',        department = 'magav' },
    [15] = { name = 'magav_deputy_cmd',  label = 'סגן מפקד מג"ב',       department = 'magav' },
    [16] = { name = 'magav_commander',   label = 'מפכ"ב',               department = 'magav' },
    [17] = { name = 'yamam_trainee',     label = 'ימ"מ מתלמד',          department = 'yamam' },
    [18] = { name = 'yamam_fighter',     label = 'ימ"מ לוחם',           department = 'yamam' },
    [19] = { name = 'yamam_senior',      label = 'ימ"מ רב לוחם',        department = 'yamam' },
    [20] = { name = 'yamam_deputy_cmd',  label = 'סגן מפקד ימ"מ',       department = 'yamam' },
    [21] = { name = 'yamam_commander',   label = 'מפקד ימ"מ',           department = 'yamam' },
    [22] = { name = 'discipline_officer',label = 'קצין משמעת',          department = 'command' },
    [23] = { name = 'district_deputy',   label = 'סגן מפקד מחוז',       department = 'command' },
    [24] = { name = 'district_commander',label = 'מפקד מחוז',           department = 'command' },
    [25] = { name = 'deputy_commissioner',label = 'סמפכ"ל',            department = 'command' },
    [26] = { name = 'commissioner',      label = 'מפכ"ל',               department = 'command' },
}

-- =============================================
-- מחלקות
-- =============================================
Config.Departments = {
    ['academy'] = { label = 'אקדמיה', color = '#888888' },
    ['patrol']  = { label = 'סיור', color = '#3498db' },
    ['yasam']   = { label = 'יס"מ', color = '#e74c3c' },
    ['magav']   = { label = 'מג"ב', color = '#2ecc71' },
    ['yamam']   = { label = 'ימ"מ', color = '#9b59b6' },
    ['command'] = { label = 'מפקדה', color = '#f39c12' },
}

-- =============================================
-- הגדרות F6 תפריט
-- =============================================
Config.F6Menu = {
    key = 'F6',
    minGrade = 0, -- דרגה מינימלית לשימוש בתפריט
}

-- =============================================
-- הגדרות MDT
-- =============================================
Config.MDT = {
    key = 'F7',
    minGrade = 1, -- דרגה מינימלית לשימוש ב-MDT
}

-- =============================================
-- סוגי עבירות תנועה
-- =============================================
Config.TrafficViolations = {
    { label = 'נהיגה מעל המהירות המותרת', fine = 500 },
    { label = 'עבירת רמזור אדום', fine = 1000 },
    { label = 'נהיגה ללא רישיון', fine = 2000 },
    { label = 'נהיגה בשכרות', fine = 3000 },
    { label = 'נהיגה בפסילה', fine = 5000 },
    { label = 'חניה במקום אסור', fine = 250 },
    { label = 'נהיגה מסוכנת', fine = 2500 },
    { label = 'אי ציות להוראות שוטר', fine = 1500 },
    { label = 'נהיגה ללא ביטוח', fine = 1000 },
    { label = 'נהיגה ללא טסט', fine = 500 },
    { label = 'שימוש בטלפון בזמן נהיגה', fine = 750 },
    { label = 'אי חגירת חגורת בטיחות', fine = 250 },
    { label = 'עקיפה מסוכנת', fine = 1500 },
    { label = 'הפרעה לתנועה', fine = 500 },
}

-- =============================================
-- סוגי עבירות פליליות
-- =============================================
Config.CriminalCharges = {
    { label = 'תקיפה', jailTime = 10, bail = 5000 },
    { label = 'תקיפת שוטר', jailTime = 20, bail = 10000 },
    { label = 'שוד', jailTime = 30, bail = 15000 },
    { label = 'שוד מזוין', jailTime = 60, bail = 30000 },
    { label = 'רצח', jailTime = 120, bail = 0 },
    { label = 'ניסיון רצח', jailTime = 90, bail = 50000 },
    { label = 'החזקת סמים', jailTime = 15, bail = 3000 },
    { label = 'סחר בסמים', jailTime = 45, bail = 20000 },
    { label = 'החזקת נשק לא חוקי', jailTime = 30, bail = 15000 },
    { label = 'סחר בנשק', jailTime = 60, bail = 0 },
    { label = 'גניבת רכב', jailTime = 20, bail = 8000 },
    { label = 'פריצה', jailTime = 25, bail = 10000 },
    { label = 'הימורים לא חוקיים', jailTime = 10, bail = 5000 },
    { label = 'הלבנת הון', jailTime = 40, bail = 25000 },
    { label = 'התנגדות למעצר', jailTime = 15, bail = 5000 },
    { label = 'בריחה ממעצר', jailTime = 25, bail = 10000 },
    { label = 'הטרדה', jailTime = 5, bail = 2000 },
    { label = 'איומים', jailTime = 10, bail = 5000 },
    { label = 'הסתה', jailTime = 15, bail = 7000 },
    { label = 'זיוף מסמכים', jailTime = 20, bail = 8000 },
}

-- =============================================
-- הגדרות רדיאל מניו
-- =============================================
Config.RadialMenu = {
    enabled = true,
    key = 'Z', -- מקש לפתיחת הרדיאל
    items = {
        { id = 'dispatch',   label = 'מוקד',        icon = 'fa-headset',       action = 'openDispatch' },
        { id = 'mdt',        label = 'MDT',          icon = 'fa-laptop',        action = 'openMDT' },
        { id = 'cuffs',      label = 'אזיקים',       icon = 'fa-lock',          action = 'toggleCuffs' },
        { id = 'search',     label = 'חיפוש',        icon = 'fa-search',        action = 'searchPlayer' },
        { id = 'escort',     label = 'ליווי',         icon = 'fa-walking',       action = 'escortPlayer' },
        { id = 'vehicle',    label = 'רכב',          icon = 'fa-car',           action = 'vehicleMenu' },
        { id = 'spike',      label = 'מסמרים',       icon = 'fa-exclamation-triangle', action = 'deploySpikeStrip' },
        { id = 'barrier',    label = 'מחסום',        icon = 'fa-road',          action = 'deployBarrier' },
    }
}

-- =============================================
-- מיקומי תחנות משטרה
-- =============================================
Config.PoliceStations = {
    {
        name = 'תחנת משטרה מרכזית',
        coords = vector3(440.085, -974.924, 30.689),
        blip = { sprite = 60, color = 29, scale = 1.0 },
        armory = vector3(452.42, -980.01, 30.69),
        garage = vector3(447.58, -1017.21, 28.55),
        locker = vector3(449.81, -985.07, 30.69),
    },
    {
        name = 'תחנת משטרה דרומית',
        coords = vector3(360.96, -1584.25, 29.29),
        blip = { sprite = 60, color = 29, scale = 0.8 },
    },
}

-- =============================================
-- הגדרות כלליות נוספות
-- =============================================
Config.HandcuffItem = 'handcuffs'
Config.DefaultBadge = '0000'
Config.MaxFine = 100000
Config.MaxJailTime = 240 -- דקות
