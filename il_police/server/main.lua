ESX = exports['es_extended']:getSharedObject()

local onDutyOfficers = {}

-- =============================================
-- אתחול הריסורס
-- =============================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('^2[IL-POLICE]^0 Israeli Police resource started successfully!')
end)

-- =============================================
-- פונקציות עזר
-- =============================================

local function GenerateReportId(prefix)
    return prefix .. '-' .. math.random(100000, 999999)
end

local function GetOfficerData(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.getJob().name ~= Config.PoliceJob then return nil end

    local grade = xPlayer.getJob().grade
    local rankData = Config.Ranks[grade]

    return {
        identifier = xPlayer.getIdentifier(),
        name = xPlayer.getName(),
        grade = grade,
        rankLabel = rankData and rankData.label or 'לא ידוע',
        rankName = rankData and rankData.name or 'unknown',
        department = rankData and rankData.department or 'patrol',
        source = source
    }
end

local function IsPolice(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.getJob().name == Config.PoliceJob
end

local function HasMinGrade(source, minGrade)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    if xPlayer.getJob().name ~= Config.PoliceJob then return false end
    return xPlayer.getJob().grade >= minGrade
end

local function GetOnlineCops()
    local cops = {}
    local xPlayers = ESX.GetExtendedPlayers('job', Config.PoliceJob)
    for _, xPlayer in pairs(xPlayers) do
        local grade = xPlayer.getJob().grade
        local rankData = Config.Ranks[grade]
        table.insert(cops, {
            source = xPlayer.source,
            name = xPlayer.getName(),
            identifier = xPlayer.getIdentifier(),
            grade = grade,
            rankLabel = rankData and rankData.label or 'לא ידוע',
            department = rankData and rankData.department or 'patrol',
            onDuty = onDutyOfficers[xPlayer.source] or false
        })
    end
    return cops
end

-- =============================================
-- כניסה / יציאה מתורנות
-- =============================================
RegisterNetEvent('il_police:server:toggleDuty', function()
    local source = source
    if not IsPolice(source) then return end

    onDutyOfficers[source] = not (onDutyOfficers[source] or false)
    local officer = GetOfficerData(source)
    if not officer then return end

    if onDutyOfficers[source] then
        MySQL.update('UPDATE il_police_officers SET on_duty = 1, last_login = NOW() WHERE identifier = ?', { officer.identifier })
        TriggerClientEvent('il_police:client:notify', source, 'success', 'נכנסת לתורנות')
        TriggerClientEvent('il_police:client:setDuty', source, true)
    else
        MySQL.update('UPDATE il_police_officers SET on_duty = 0 WHERE identifier = ?', { officer.identifier })
        TriggerClientEvent('il_police:client:notify', source, 'info', 'יצאת מתורנות')
        TriggerClientEvent('il_police:client:setDuty', source, false)
    end
end)

-- =============================================
-- דוח תנועה
-- =============================================
RegisterNetEvent('il_police:server:createTrafficReport', function(data)
    local source = source
    local officer = GetOfficerData(source)
    if not officer then return end

    local reportId = GenerateReportId('TR')

    MySQL.insert('INSERT INTO il_police_traffic_reports (report_id, officer_identifier, officer_name, officer_badge, citizen_name, citizen_id, vehicle_plate, vehicle_model, violation, fine_amount, location, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        reportId,
        officer.identifier,
        officer.name,
        data.badge or Config.DefaultBadge,
        data.citizenName or '',
        data.citizenId or '',
        data.vehiclePlate or '',
        data.vehicleModel or '',
        data.violation or '',
        data.fineAmount or 0,
        data.location or '',
        data.notes or ''
    }, function(insertId)
        if insertId then
            TriggerClientEvent('il_police:client:notify', source, 'success', 'דוח תנועה #' .. reportId .. ' הונפק בהצלחה')

            -- גביית קנס מהאזרח
            if data.targetSource and data.fineAmount > 0 then
                local xTarget = ESX.GetPlayerFromId(data.targetSource)
                if xTarget then
                    xTarget.removeMoney(data.fineAmount, 'קנס תנועה - ' .. reportId)
                    TriggerClientEvent('il_police:client:notify', data.targetSource, 'error', 'קיבלת דוח תנועה על סך ' .. data.fineAmount .. '₪')
                end
            end
        end
    end)
end)

-- =============================================
-- דוח פלילי
-- =============================================
RegisterNetEvent('il_police:server:createCriminalReport', function(data)
    local source = source
    local officer = GetOfficerData(source)
    if not officer then return end
    if not HasMinGrade(source, 1) then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'אין לך הרשאה להנפיק דוחות פליליים')
        return
    end

    local reportId = GenerateReportId('CR')

    MySQL.insert('INSERT INTO il_police_criminal_reports (report_id, officer_identifier, officer_name, officer_badge, suspect_name, suspect_id, charges, description, location, arrest, bail_amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        reportId,
        officer.identifier,
        officer.name,
        data.badge or Config.DefaultBadge,
        data.suspectName or '',
        data.suspectId or '',
        data.charges or '',
        data.description or '',
        data.location or '',
        data.arrest and 1 or 0,
        data.bailAmount or 0
    }, function(insertId)
        if insertId then
            TriggerClientEvent('il_police:client:notify', source, 'success', 'דוח פלילי #' .. reportId .. ' נוצר בהצלחה')
        end
    end)
end)

-- =============================================
-- מעצר
-- =============================================
RegisterNetEvent('il_police:server:createArrest', function(data)
    local source = source
    local officer = GetOfficerData(source)
    if not officer then return end

    local arrestId = GenerateReportId('AR')

    MySQL.insert('INSERT INTO il_police_arrests (arrest_id, officer_identifier, officer_name, suspect_name, suspect_id, charges, jail_time, bail_amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        arrestId,
        officer.identifier,
        officer.name,
        data.suspectName or '',
        data.suspectId or '',
        data.charges or '',
        data.jailTime or 0,
        data.bailAmount or 0
    }, function(insertId)
        if insertId then
            TriggerClientEvent('il_police:client:notify', source, 'success', 'מעצר #' .. arrestId .. ' בוצע בהצלחה')

            -- שליחת האזרח לכלא
            if data.targetSource and data.jailTime > 0 then
                TriggerClientEvent('il_police:client:sendToJail', data.targetSource, data.jailTime)
            end
        end
    end)
end)

-- =============================================
-- BOLO - הודעה לכלל השוטרים
-- =============================================
RegisterNetEvent('il_police:server:createBOLO', function(data)
    local source = source
    local officer = GetOfficerData(source)
    if not officer then return end
    if not HasMinGrade(source, 3) then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'אין לך הרשאה ליצור BOLO')
        return
    end

    MySQL.insert('INSERT INTO il_police_bolo (type, description, suspect_name, vehicle_plate, vehicle_model, reason, officer_identifier, officer_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        data.type or 'person',
        data.description or '',
        data.suspectName or '',
        data.vehiclePlate or '',
        data.vehicleModel or '',
        data.reason or '',
        officer.identifier,
        officer.name
    }, function(insertId)
        if insertId then
            TriggerClientEvent('il_police:client:notify', source, 'success', 'BOLO נוצר בהצלחה')
            -- שליחת הודעה לכלל השוטרים
            local cops = GetOnlineCops()
            for _, cop in pairs(cops) do
                TriggerClientEvent('il_police:client:notify', cop.source, 'warning', '📢 BOLO חדש: ' .. (data.reason or 'לא צוין'))
            end
        end
    end)
end)

-- =============================================
-- MDT - חיפושים ושליפת מידע
-- =============================================

-- חיפוש אזרח
RegisterNetEvent('il_police:server:searchCitizen', function(searchName)
    local source = source
    if not IsPolice(source) then return end

    local xPlayers = ESX.GetExtendedPlayers()
    local results = {}

    for _, xPlayer in pairs(xPlayers) do
        local name = xPlayer.getName()
        if string.find(string.lower(name), string.lower(searchName)) then
            table.insert(results, {
                name = name,
                identifier = xPlayer.getIdentifier(),
                source = xPlayer.source,
                job = xPlayer.getJob().label,
            })
        end
    end

    -- חיפוש גם בדוחות קיימים
    MySQL.query('SELECT DISTINCT citizen_name, citizen_id FROM il_police_traffic_reports WHERE citizen_name LIKE ? LIMIT 20', { '%' .. searchName .. '%' }, function(dbResults)
        if dbResults then
            for _, row in ipairs(dbResults) do
                local found = false
                for _, r in ipairs(results) do
                    if r.name == row.citizen_name then found = true break end
                end
                if not found then
                    table.insert(results, {
                        name = row.citizen_name,
                        identifier = row.citizen_id,
                        source = nil,
                        job = 'לא מקוון',
                    })
                end
            end
        end
        TriggerClientEvent('il_police:client:searchResults', source, 'citizen', results)
    end)
end)

-- חיפוש רכב
RegisterNetEvent('il_police:server:searchVehicle', function(plate)
    local source = source
    if not IsPolice(source) then return end

    MySQL.query('SELECT * FROM owned_vehicles WHERE plate = ?', { plate }, function(vehicles)
        local results = {}
        if vehicles and #vehicles > 0 then
            for _, v in ipairs(vehicles) do
                table.insert(results, {
                    plate = v.plate,
                    owner = v.owner,
                    model = v.vehicle,
                    stored = v.stored,
                })
            end
        end

        -- בדיקת דוחות קודמים על הרכב
        MySQL.query('SELECT * FROM il_police_traffic_reports WHERE vehicle_plate = ? ORDER BY created_at DESC LIMIT 10', { plate }, function(reports)
            TriggerClientEvent('il_police:client:searchResults', source, 'vehicle', {
                vehicles = results,
                reports = reports or {}
            })
        end)
    end)
end)

-- שליפת כל הדוחות
RegisterNetEvent('il_police:server:getReports', function(reportType, page)
    local source = source
    if not IsPolice(source) then return end

    local limit = 20
    local offset = ((page or 1) - 1) * limit

    if reportType == 'traffic' then
        MySQL.query('SELECT * FROM il_police_traffic_reports ORDER BY created_at DESC LIMIT ? OFFSET ?', { limit, offset }, function(results)
            MySQL.scalar('SELECT COUNT(*) FROM il_police_traffic_reports', {}, function(total)
                TriggerClientEvent('il_police:client:receiveReports', source, 'traffic', results or {}, total or 0)
            end)
        end)
    elseif reportType == 'criminal' then
        MySQL.query('SELECT * FROM il_police_criminal_reports ORDER BY created_at DESC LIMIT ? OFFSET ?', { limit, offset }, function(results)
            MySQL.scalar('SELECT COUNT(*) FROM il_police_criminal_reports', {}, function(total)
                TriggerClientEvent('il_police:client:receiveReports', source, 'criminal', results or {}, total or 0)
            end)
        end)
    elseif reportType == 'arrests' then
        MySQL.query('SELECT * FROM il_police_arrests ORDER BY created_at DESC LIMIT ? OFFSET ?', { limit, offset }, function(results)
            MySQL.scalar('SELECT COUNT(*) FROM il_police_arrests', {}, function(total)
                TriggerClientEvent('il_police:client:receiveReports', source, 'arrests', results or {}, total or 0)
            end)
        end)
    elseif reportType == 'bolo' then
        MySQL.query('SELECT * FROM il_police_bolo WHERE active = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?', { limit, offset }, function(results)
            MySQL.scalar('SELECT COUNT(*) FROM il_police_bolo WHERE active = 1', {}, function(total)
                TriggerClientEvent('il_police:client:receiveReports', source, 'bolo', results or {}, total or 0)
            end)
        end)
    end
end)

-- שליפת שוטרים מחוברים
RegisterNetEvent('il_police:server:getOnlineCops', function()
    local source = source
    if not IsPolice(source) then return end
    local cops = GetOnlineCops()
    TriggerClientEvent('il_police:client:receiveOnlineCops', source, cops)
end)

-- =============================================
-- ניהול דרגות (מפקדים בלבד)
-- =============================================
RegisterNetEvent('il_police:server:setGrade', function(targetSource, newGrade)
    local source = source
    if not HasMinGrade(source, 22) then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'אין לך הרשאה לשנות דרגות')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'שחקן לא נמצא')
        return
    end

    if xTarget.getJob().name ~= Config.PoliceJob then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'השחקן אינו שוטר')
        return
    end

    local rankData = Config.Ranks[newGrade]
    if not rankData then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'דרגה לא חוקית')
        return
    end

    xTarget.setJob(Config.PoliceJob, newGrade)
    TriggerClientEvent('il_police:client:notify', source, 'success', 'דרגת ' .. xTarget.getName() .. ' שונתה ל-' .. rankData.label)
    TriggerClientEvent('il_police:client:notify', targetSource, 'info', 'דרגתך שונתה ל-' .. rankData.label)
end)

-- =============================================
-- הודעה למוקד
-- =============================================
RegisterNetEvent('il_police:server:dispatchMessage', function(message, code)
    local source = source
    if not IsPolice(source) then return end
    local officer = GetOfficerData(source)
    if not officer then return end

    local cops = GetOnlineCops()
    for _, cop in pairs(cops) do
        TriggerClientEvent('il_police:client:dispatchNotification', cop.source, {
            sender = officer.name,
            rank = officer.rankLabel,
            message = message,
            code = code or '',
            time = os.date('%H:%M')
        })
    end
end)

-- =============================================
-- פעולות שוטר על אזרח
-- =============================================

-- אזיקים
RegisterNetEvent('il_police:server:cuffPlayer', function(targetId)
    local source = source
    if not IsPolice(source) then return end
    TriggerClientEvent('il_police:client:getCuffed', targetId)
    TriggerClientEvent('il_police:client:notify', source, 'info', 'השחקן נאזק')
end)

-- חיפוש שחקן
RegisterNetEvent('il_police:server:searchPlayer', function(targetId)
    local source = source
    if not IsPolice(source) then return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local inventory = xTarget.getInventory()
    local weapons = xTarget.getLoadout()
    local money = xTarget.getMoney()
    local bank = xTarget.getAccount('bank').money
    local black = xTarget.getAccount('black_money').money

    local items = {}
    for _, item in pairs(inventory) do
        if item.count > 0 then
            table.insert(items, { label = item.label, count = item.count })
        end
    end

    local weaponsList = {}
    for _, weapon in pairs(weapons) do
        table.insert(weaponsList, { label = weapon.label, ammo = weapon.ammo })
    end

    TriggerClientEvent('il_police:client:showSearchResults', source, {
        name = xTarget.getName(),
        money = money,
        bank = bank,
        black_money = black,
        items = items,
        weapons = weaponsList
    })
end)

-- ליווי שחקן
RegisterNetEvent('il_police:server:escortPlayer', function(targetId)
    local source = source
    if not IsPolice(source) then return end
    TriggerClientEvent('il_police:client:getEscorted', targetId, source)
end)

-- החרמת נשק
RegisterNetEvent('il_police:server:confiscateWeapons', function(targetId)
    local source = source
    if not IsPolice(source) then return end
    if not HasMinGrade(source, 1) then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'אין לך הרשאה')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local weapons = xTarget.getLoadout()
    for _, weapon in pairs(weapons) do
        xTarget.removeWeapon(weapon.name)
    end

    TriggerClientEvent('il_police:client:notify', source, 'success', 'כל הנשקים הוחרמו')
    TriggerClientEvent('il_police:client:notify', targetId, 'error', 'הנשקים שלך הוחרמו')
end)

-- החרמת פריט
RegisterNetEvent('il_police:server:confiscateItem', function(targetId, itemName, itemCount)
    local source = source
    if not IsPolice(source) then return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    xTarget.removeInventoryItem(itemName, itemCount)
    TriggerClientEvent('il_police:client:notify', source, 'success', 'פריט הוחרם בהצלחה')
end)

-- =============================================
-- ניקוי בעת יציאה
-- =============================================
AddEventHandler('playerDropped', function()
    onDutyOfficers[source] = nil
end)

-- =============================================
-- קבלת מידע על דרגה
-- =============================================
RegisterNetEvent('il_police:server:getOfficerInfo', function()
    local source = source
    local officer = GetOfficerData(source)
    if officer then
        TriggerClientEvent('il_police:client:receiveOfficerInfo', source, officer)
    end
end)

-- =============================================
-- ביטול BOLO
-- =============================================
RegisterNetEvent('il_police:server:cancelBOLO', function(boloId)
    local source = source
    if not IsPolice(source) then return end
    if not HasMinGrade(source, 3) then
        TriggerClientEvent('il_police:client:notify', source, 'error', 'אין לך הרשאה לבטל BOLO')
        return
    end

    MySQL.update('UPDATE il_police_bolo SET active = 0 WHERE id = ?', { boloId }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('il_police:client:notify', source, 'success', 'BOLO בוטל בהצלחה')
        end
    end)
end)

-- =============================================
-- קבלת סטטיסטיקות
-- =============================================
RegisterNetEvent('il_police:server:getStats', function()
    local source = source
    if not IsPolice(source) then return end

    local stats = {}

    MySQL.scalar('SELECT COUNT(*) FROM il_police_traffic_reports', {}, function(trafficCount)
        stats.trafficReports = trafficCount or 0
        MySQL.scalar('SELECT COUNT(*) FROM il_police_criminal_reports', {}, function(criminalCount)
            stats.criminalReports = criminalCount or 0
            MySQL.scalar('SELECT COUNT(*) FROM il_police_arrests', {}, function(arrestCount)
                stats.arrests = arrestCount or 0
                MySQL.scalar('SELECT COUNT(*) FROM il_police_bolo WHERE active = 1', {}, function(boloCount)
                    stats.activeBolo = boloCount or 0
                    stats.onlineCops = #GetOnlineCops()
                    TriggerClientEvent('il_police:client:receiveStats', source, stats)
                end)
            end)
        end)
    end)
end)
