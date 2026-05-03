# 🚔 IL Police - ריסורס משטרת ישראל ל-FiveM ESX

ריסורס מלא למשטרת ישראל לשרתי FiveM ESX הכולל מערכת דרגות, MDT, תפריט רדיאלי, תפריט F6, ומערכת דוחות.

## 📋 תכונות

### 🎖️ מערכת דרגות (27 דרגות)
- **אקדמיה** (Police 0)
- **סיור** (Police 1-6): שוטר סיור, רב שוטר, ע.קצין, קצין, סגן מפקד, מפקד
- **יס"מ** (Police 7-11): מתלמד, לוחם, רב לוחם, סגן מפקד, מפקד
- **מג"ב** (Police 12-16): מתלמד, לוחם, רב לוחם, סגן מפקד, מפקד
- **ימ"מ** (Police 17-21): מתלמד, לוחם, רב לוחם, סגן מפקד, מפקד
- **מפקדה** (Police 22-26): קצין משמעת, סגן מפקד מחוז, מפקד מחוז, סמפכ"ל, מפכ"ל

### 📻 תפריט רדיאלי (מקש Z)
- מוקד משטרתי
- פתיחת MDT
- אזיקים
- חיפוש אזרח
- ליווי אזרח
- תפריט רכב
- פריסת מסמרים
- הצבת מחסום

### 📋 תפריט F6
- כניסה/יציאה מתורנות
- הנפקת דוח תנועה
- הנפקת דוח פלילי
- ביצוע מעצר
- אזיקים / שחרור
- חיפוש אזרח
- ליווי אזרח
- החרמת נשקים
- קנס כספי
- חיפוש רכב
- החרמת רכב
- פריסת מסמרים
- הצבת מחסום
- הודעה למוקד
- יצירת BOLO
- פתיחת MDT
- שינוי דרגת שוטר (מפקדים בלבד)
- בדיקת תעודת זהות
- בדיקת ינשוף

### 💻 MDT - מסוף משטרתי (מקש F7)
- לוח בקרה עם סטטיסטיקות
- חיפוש אזרחים
- חיפוש רכבים לפי לוחית
- צפייה בדוחות תנועה
- צפייה בדוחות פליליים
- צפייה במעצרים
- ניהול BOLO
- רשימת שוטרים מחוברים
- יצירת דוחות ישירות מה-MDT
- מוקד משטרתי

## 📦 דרישות

- [ESX Framework](https://github.com/esx-framework)
- [oxmysql](https://github.com/overextended/oxmysql)
- MariaDB / MySQL

## 🔧 התקנה

### 1. העתקת הקבצים
העתק את תיקיית `il_police` לתיקיית `resources` בשרת שלך.

### 2. התקנת מסד הנתונים
הרץ את הקובץ `sql/install.sql` במסד הנתונים שלך:

```sql
source /path/to/il_police/sql/install.sql;
```

### 3. הגדרת ESX
וודא שה-Job `police` מוגדר ב-ESX עם 27 דרגות (0-26).

ב-`jobs` table:
```sql
INSERT INTO `jobs` (`name`, `label`) VALUES ('police', 'משטרת ישראל') ON DUPLICATE KEY UPDATE label='משטרת ישראל';
```

ב-`job_grades` table, הרץ:
```sql
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('police', 0, 'academy', 'אקדמאי', 0, '{}', '{}'),
('police', 1, 'patrol_officer', 'שוטר סיור', 2500, '{}', '{}'),
('police', 2, 'patrol_senior', 'רב שוטר סיור', 3000, '{}', '{}'),
('police', 3, 'patrol_deputy', 'ע.קצין סיור', 3500, '{}', '{}'),
('police', 4, 'patrol_lt', 'קצין סיור', 4000, '{}', '{}'),
('police', 5, 'patrol_deputy_cmd', 'סגן מפקד סיור', 4500, '{}', '{}'),
('police', 6, 'patrol_commander', 'מפקד סיור', 5000, '{}', '{}'),
('police', 7, 'yasam_trainee', 'יס"מ מתלמד', 3000, '{}', '{}'),
('police', 8, 'yasam_fighter', 'לוחם יס"מ', 3500, '{}', '{}'),
('police', 9, 'yasam_senior', 'יס"מ רב לוחם', 4000, '{}', '{}'),
('police', 10, 'yasam_deputy_cmd', 'סגן מפקד יס"מ', 4500, '{}', '{}'),
('police', 11, 'yasam_commander', 'מפקד יס"מ', 5500, '{}', '{}'),
('police', 12, 'magav_trainee', 'מג"ב מתלמד', 3000, '{}', '{}'),
('police', 13, 'magav_fighter', 'מג"ב לוחם', 3500, '{}', '{}'),
('police', 14, 'magav_senior', 'מג"ב רב לוחם', 4000, '{}', '{}'),
('police', 15, 'magav_deputy_cmd', 'סגן מפקד מג"ב', 4500, '{}', '{}'),
('police', 16, 'magav_commander', 'מפכ"ב', 5500, '{}', '{}'),
('police', 17, 'yamam_trainee', 'ימ"מ מתלמד', 4000, '{}', '{}'),
('police', 18, 'yamam_fighter', 'ימ"מ לוחם', 4500, '{}', '{}'),
('police', 19, 'yamam_senior', 'ימ"מ רב לוחם', 5000, '{}', '{}'),
('police', 20, 'yamam_deputy_cmd', 'סגן מפקד ימ"מ', 5500, '{}', '{}'),
('police', 21, 'yamam_commander', 'מפקד ימ"מ', 6500, '{}', '{}'),
('police', 22, 'discipline_officer', 'קצין משמעת', 6000, '{}', '{}'),
('police', 23, 'district_deputy', 'סגן מפקד מחוז', 7000, '{}', '{}'),
('police', 24, 'district_commander', 'מפקד מחוז', 8000, '{}', '{}'),
('police', 25, 'deputy_commissioner', 'סמפכ"ל', 9000, '{}', '{}'),
('police', 26, 'commissioner', 'מפכ"ל', 10000, '{}', '{}')
ON DUPLICATE KEY UPDATE label=VALUES(label), salary=VALUES(salary);
```

### 4. הוספה ל-server.cfg
```
ensure il_police
```

## ⌨️ מקשים

| מקש | פעולה |
|-----|-------|
| `Z` | פתיחת תפריט רדיאלי |
| `F6` | פתיחת תפריט משטרתי |
| `F7` | פתיחת MDT |
| `ESC` | סגירת כל התפריטים |

## ⚙️ הגדרות

ניתן לשנות את כל ההגדרות בקובץ `config.lua`:
- דרגות ומחלקות
- עבירות תנועה וקנסות
- אישומים פליליים
- מיקומי תחנות משטרה
- הגדרות מקשים

## 📁 מבנה הקבצים

```
il_police/
├── fxmanifest.lua          # מניפסט הריסורס
├── config.lua              # הגדרות
├── README.md               # תיעוד
├── server/
│   └── main.lua            # סקריפט צד שרת
├── client/
│   ├── main.lua            # סקריפט ראשי צד לקוח
│   ├── radial.lua          # תפריט רדיאלי
│   ├── f6menu.lua          # תפריט F6
│   └── mdt.lua             # MDT
├── html/
│   ├── index.html          # דף ראשי NUI
│   ├── style.css           # סגנונות כלליים
│   ├── script.js           # סקריפט ראשי
│   ├── radial.css          # סגנונות רדיאל
│   ├── radial.js           # סקריפט רדיאל
│   ├── f6menu.css          # סגנונות F6
│   ├── f6menu.js           # סקריפט F6
│   ├── mdt.css             # סגנונות MDT
│   └── mdt.js              # סקריפט MDT
└── sql/
    └── install.sql          # סכמת מסד נתונים
```

## 📝 רישיון

חופשי לשימוש בשרתים פרטיים.
