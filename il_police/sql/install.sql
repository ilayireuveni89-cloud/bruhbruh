-- =============================================
-- Israeli Police Resource - Database Schema
-- MariaDB / MySQL
-- =============================================

-- טבלת דרגות משטרה
CREATE TABLE IF NOT EXISTS `il_police_ranks` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `grade` INT(11) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `department` VARCHAR(50) NOT NULL DEFAULT 'patrol',
    `salary` INT(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת שוטרים
CREATE TABLE IF NOT EXISTS `il_police_officers` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100) NOT NULL DEFAULT '',
    `grade` INT(11) NOT NULL DEFAULT 0,
    `badge_number` VARCHAR(20) NOT NULL DEFAULT '',
    `callsign` VARCHAR(20) NOT NULL DEFAULT '',
    `on_duty` TINYINT(1) NOT NULL DEFAULT 0,
    `last_login` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת דוחות תנועה
CREATE TABLE IF NOT EXISTS `il_police_traffic_reports` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `report_id` VARCHAR(20) NOT NULL,
    `officer_identifier` VARCHAR(60) NOT NULL,
    `officer_name` VARCHAR(100) NOT NULL DEFAULT '',
    `officer_badge` VARCHAR(20) NOT NULL DEFAULT '',
    `citizen_name` VARCHAR(100) NOT NULL DEFAULT '',
    `citizen_id` VARCHAR(60) NOT NULL DEFAULT '',
    `vehicle_plate` VARCHAR(20) NOT NULL DEFAULT '',
    `vehicle_model` VARCHAR(50) NOT NULL DEFAULT '',
    `violation` VARCHAR(255) NOT NULL DEFAULT '',
    `fine_amount` INT(11) NOT NULL DEFAULT 0,
    `location` VARCHAR(255) NOT NULL DEFAULT '',
    `notes` TEXT,
    `status` ENUM('active','paid','cancelled') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת דוחות פליליים
CREATE TABLE IF NOT EXISTS `il_police_criminal_reports` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `report_id` VARCHAR(20) NOT NULL,
    `officer_identifier` VARCHAR(60) NOT NULL,
    `officer_name` VARCHAR(100) NOT NULL DEFAULT '',
    `officer_badge` VARCHAR(20) NOT NULL DEFAULT '',
    `suspect_name` VARCHAR(100) NOT NULL DEFAULT '',
    `suspect_id` VARCHAR(60) NOT NULL DEFAULT '',
    `charges` TEXT,
    `description` TEXT,
    `location` VARCHAR(255) NOT NULL DEFAULT '',
    `arrest` TINYINT(1) NOT NULL DEFAULT 0,
    `bail_amount` INT(11) NOT NULL DEFAULT 0,
    `status` ENUM('open','closed','investigation') NOT NULL DEFAULT 'open',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת מעצרים
CREATE TABLE IF NOT EXISTS `il_police_arrests` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `arrest_id` VARCHAR(20) NOT NULL,
    `officer_identifier` VARCHAR(60) NOT NULL,
    `officer_name` VARCHAR(100) NOT NULL DEFAULT '',
    `suspect_name` VARCHAR(100) NOT NULL DEFAULT '',
    `suspect_id` VARCHAR(60) NOT NULL DEFAULT '',
    `charges` TEXT,
    `jail_time` INT(11) NOT NULL DEFAULT 0,
    `bail_amount` INT(11) NOT NULL DEFAULT 0,
    `status` ENUM('detained','released','jailed','bailed') NOT NULL DEFAULT 'detained',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `arrest_id` (`arrest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת חיפושי רכב
CREATE TABLE IF NOT EXISTS `il_police_vehicle_searches` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(20) NOT NULL,
    `owner_name` VARCHAR(100) NOT NULL DEFAULT '',
    `owner_id` VARCHAR(60) NOT NULL DEFAULT '',
    `vehicle_model` VARCHAR(50) NOT NULL DEFAULT '',
    `wanted` TINYINT(1) NOT NULL DEFAULT 0,
    `stolen` TINYINT(1) NOT NULL DEFAULT 0,
    `notes` TEXT,
    `searched_by` VARCHAR(60) NOT NULL,
    `searched_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- טבלת BOLO (Be On the Lookout)
CREATE TABLE IF NOT EXISTS `il_police_bolo` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `type` ENUM('person','vehicle') NOT NULL DEFAULT 'person',
    `description` TEXT NOT NULL,
    `suspect_name` VARCHAR(100) DEFAULT '',
    `vehicle_plate` VARCHAR(20) DEFAULT '',
    `vehicle_model` VARCHAR(50) DEFAULT '',
    `reason` VARCHAR(255) NOT NULL DEFAULT '',
    `officer_identifier` VARCHAR(60) NOT NULL,
    `officer_name` VARCHAR(100) NOT NULL DEFAULT '',
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- הכנסת דרגות ברירת מחדל
INSERT INTO `il_police_ranks` (`grade`, `name`, `label`, `department`, `salary`) VALUES
(0,  'academy',          'אקדמאי',              'academy',  0),
(1,  'patrol_officer',   'שוטר סיור',           'patrol',   2500),
(2,  'patrol_senior',    'רב שוטר סיור',        'patrol',   3000),
(3,  'patrol_deputy',    'ע.קצין סיור',         'patrol',   3500),
(4,  'patrol_lt',        'קצין סיור',           'patrol',   4000),
(5,  'patrol_deputy_cmd','סגן מפקד סיור',       'patrol',   4500),
(6,  'patrol_commander', 'מפקד סיור',           'patrol',   5000),
(7,  'yasam_trainee',    'יס"מ מתלמד',          'yasam',    3000),
(8,  'yasam_fighter',    'לוחם יס"מ',           'yasam',    3500),
(9,  'yasam_senior',     'יס"מ רב לוחם',        'yasam',    4000),
(10, 'yasam_deputy_cmd', 'סגן מפקד יס"מ',       'yasam',    4500),
(11, 'yasam_commander',  'מפקד יס"מ',           'yasam',    5500),
(12, 'magav_trainee',    'מג"ב מתלמד',          'magav',    3000),
(13, 'magav_fighter',    'מג"ב לוחם',           'magav',    3500),
(14, 'magav_senior',     'מג"ב רב לוחם',        'magav',    4000),
(15, 'magav_deputy_cmd', 'סגן מפקד מג"ב',       'magav',    4500),
(16, 'magav_commander',  'מפקד מג"ב',           'magav',    5500),
(17, 'yamam_trainee',    'ימ"מ מתלמד',          'yamam',    4000),
(18, 'yamam_fighter',    'ימ"מ לוחם',           'yamam',    4500),
(19, 'yamam_senior',     'ימ"מ רב לוחם',        'yamam',    5000),
(20, 'yamam_deputy_cmd', 'סגן מפקד ימ"מ',       'yamam',    5500),
(21, 'yamam_commander',  'מפקד ימ"מ',           'yamam',    6500),
(22, 'discipline_officer','קצין משמעת',          'command',  6000),
(23, 'district_deputy',  'סגן מפקד מחוז',       'command',  7000),
(24, 'district_commander','מפקד מחוז',           'command',  8000),
(25, 'deputy_commissioner','סמפכ"ל',            'command',  9000),
(26, 'commissioner',     'מפכ"ל',               'command', 10000)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `label`=VALUES(`label`);
