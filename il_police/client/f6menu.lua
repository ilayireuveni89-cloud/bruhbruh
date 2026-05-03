local isF6Open = false

-- =============================================
-- פתיחת תפריט F6
-- =============================================
RegisterNetEvent('il_police:client:openF6Menu', function()
    if not IsPolice() then return end
    if isF6Open then
        CloseF6Menu()
        return
    end

    isF6Open = true
    SetNuiFocus(true, true)

    local grade = GetPlayerGrade()

    -- בניית התפריט לפי דרגה
    local menuItems = {
        {
            id = 'duty',
            label = isOnDuty and 'יציאה מתורנות' or 'כניסה לתורנות',
            icon = 'fa-briefcase',
            category = 'general',
            minGrade = 0
        },
        {
            id = 'traffic_report',
            label = 'הנפקת דוח תנועה',
            icon = 'fa-file-alt',
            category = 'reports',
            minGrade = 0
        },
        {
            id = 'criminal_report',
            label = 'הנפקת דוח פלילי',
            icon = 'fa-gavel',
            category = 'reports',
            minGrade = 1
        },
        {
            id = 'arrest',
            label = 'ביצוע מעצר',
            icon = 'fa-lock',
            category = 'actions',
            minGrade = 1
        },
        {
            id = 'cuff',
            label = 'אזיקים',
            icon = 'fa-link',
            category = 'actions',
            minGrade = 0
        },
        {
            id = 'uncuff',
            label = 'שחרור אזיקים',
            icon = 'fa-unlock',
            category = 'actions',
            minGrade = 0
        },
        {
            id = 'search',
            label = 'חיפוש אזרח',
            icon = 'fa-search',
            category = 'actions',
            minGrade = 0
        },
        {
            id = 'escort',
            label = 'ליווי אזרח',
            icon = 'fa-walking',
            category = 'actions',
            minGrade = 0
        },
        {
            id = 'confiscate_weapons',
            label = 'החרמת נשקים',
            icon = 'fa-ban',
            category = 'actions',
            minGrade = 1
        },
        {
            id = 'fine',
            label = 'קנס כספי',
            icon = 'fa-money-bill',
            category = 'reports',
            minGrade = 0
        },
        {
            id = 'vehicle_search',
            label = 'חיפוש רכב',
            icon = 'fa-car',
            category = 'vehicle',
            minGrade = 0
        },
        {
            id = 'impound',
            label = 'החרמת רכב',
            icon = 'fa-truck-loading',
            category = 'vehicle',
            minGrade = 1
        },
        {
            id = 'spike_strip',
            label = 'פריסת מסמרים',
            icon = 'fa-exclamation-triangle',
            category = 'tactical',
            minGrade = 1
        },
        {
            id = 'barrier',
            label = 'הצבת מחסום',
            icon = 'fa-road',
            category = 'tactical',
            minGrade = 1
        },
        {
            id = 'dispatch',
            label = 'הודעה למוקד',
            icon = 'fa-headset',
            category = 'communication',
            minGrade = 0
        },
        {
            id = 'bolo',
            label = 'יצירת BOLO',
            icon = 'fa-bullhorn',
            category = 'communication',
            minGrade = 3
        },
        {
            id = 'mdt',
            label = 'פתיחת MDT',
            icon = 'fa-laptop',
            category = 'general',
            minGrade = 1
        },
        {
            id = 'set_grade',
            label = 'שינוי דרגת שוטר',
            icon = 'fa-star',
            category = 'command',
            minGrade = 22
        },
        {
            id = 'id_check',
            label = 'בדיקת תעודת זהות',
            icon = 'fa-id-card',
            category = 'actions',
            minGrade = 0
        },
        {
            id = 'breathalyzer',
            label = 'בדיקת ינשוף',
            icon = 'fa-wine-bottle',
            category = 'actions',
            minGrade = 0
        },
    }

    -- סינון לפי דרגה
    local filteredItems = {}
    for _, item in ipairs(menuItems) do
        if grade >= item.minGrade then
            table.insert(filteredItems, item)
        end
    end

    SendNUIMessage({
        type = 'openF6',
        items = filteredItems,
        rank = GetGradeLabel(),
        grade = grade,
        department = Config.Ranks[grade] and Config.Ranks[grade].department or 'patrol',
        departmentLabel = Config.Ranks[grade] and Config.Departments[Config.Ranks[grade].department] and Config.Departments[Config.Ranks[grade].department].label or 'סיור',
        onDuty = isOnDuty,
        categories = {
            { id = 'general', label = 'כללי', icon = 'fa-home' },
            { id = 'reports', label = 'דוחות', icon = 'fa-file-alt' },
            { id = 'actions', label = 'פעולות', icon = 'fa-bolt' },
            { id = 'vehicle', label = 'רכב', icon = 'fa-car' },
            { id = 'tactical', label = 'טקטי', icon = 'fa-shield-alt' },
            { id = 'communication', label = 'תקשורת', icon = 'fa-broadcast-tower' },
            { id = 'command', label = 'מפקדה', icon = 'fa-crown' },
        }
    })
end)

function CloseF6Menu()
    isF6Open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeF6' })
end

-- =============================================
-- NUI Callbacks מתפריט F6
-- =============================================
RegisterNUICallback('f6Action', function(data, cb)
    local action = data.action

    if action == 'duty' then
        TriggerServerEvent('il_police:server:toggleDuty')
        CloseF6Menu()

    elseif action == 'traffic_report' then
        -- פתיחת טופס דוח תנועה
        SendNUIMessage({
            type = 'openTrafficReportForm',
            violations = Config.TrafficViolations,
            rank = GetGradeLabel()
        })

    elseif action == 'criminal_report' then
        SendNUIMessage({
            type = 'openCriminalReportForm',
            charges = Config.CriminalCharges,
            rank = GetGradeLabel()
        })

    elseif action == 'arrest' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            SendNUIMessage({
                type = 'openArrestForm',
                charges = Config.CriminalCharges,
                targetSource = target,
                rank = GetGradeLabel()
            })
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
            CloseF6Menu()
        end

    elseif action == 'cuff' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:cuffPlayer', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end
        CloseF6Menu()

    elseif action == 'uncuff' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:cuffPlayer', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end
        CloseF6Menu()

    elseif action == 'search' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:searchPlayer', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
            CloseF6Menu()
        end

    elseif action == 'escort' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:escortPlayer', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end
        CloseF6Menu()

    elseif action == 'confiscate_weapons' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:confiscateWeapons', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end
        CloseF6Menu()

    elseif action == 'fine' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            SendNUIMessage({
                type = 'openFineForm',
                targetSource = target,
                rank = GetGradeLabel()
            })
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
            CloseF6Menu()
        end

    elseif action == 'vehicle_search' then
        TriggerEvent('il_police:client:openVehicleMenu')
        CloseF6Menu()

    elseif action == 'impound' then
        local playerPed = PlayerPedId()
        local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 71)
        if vehicle ~= 0 then
            local plate = GetVehicleNumberPlateText(vehicle)
            DeleteEntity(vehicle)
            SendNUIMessage({
                type = 'notification',
                notifyType = 'success',
                message = 'רכב ' .. plate .. ' הוחרם'
            })
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין רכב בקרבת מקום'
            })
        end
        CloseF6Menu()

    elseif action == 'spike_strip' then
        TriggerEvent('il_police:client:deploySpikeStrip')
        CloseF6Menu()

    elseif action == 'barrier' then
        TriggerEvent('il_police:client:deployBarrier')
        CloseF6Menu()

    elseif action == 'dispatch' then
        SendNUIMessage({
            type = 'openDispatchPanel',
            rank = GetGradeLabel()
        })

    elseif action == 'bolo' then
        SendNUIMessage({
            type = 'openBOLOForm',
            rank = GetGradeLabel()
        })

    elseif action == 'mdt' then
        CloseF6Menu()
        TriggerEvent('il_police:client:openMDT')

    elseif action == 'set_grade' then
        SendNUIMessage({
            type = 'openGradeForm',
            ranks = Config.Ranks,
            rank = GetGradeLabel()
        })

    elseif action == 'id_check' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:searchPlayer', target)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
            CloseF6Menu()
        end

    elseif action == 'breathalyzer' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            local result = math.random(0, 100) / 100
            local msg = result > 0.05 and ('תוצאה חיובית: ' .. string.format('%.2f', result)) or ('תוצאה שלילית: ' .. string.format('%.2f', result))
            SendNUIMessage({
                type = 'notification',
                notifyType = result > 0.05 and 'error' or 'success',
                message = 'בדיקת ינשוף - ' .. msg
            })
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end
        CloseF6Menu()
    end

    cb('ok')
end)

RegisterNUICallback('closeF6', function(data, cb)
    CloseF6Menu()
    cb('ok')
end)

-- =============================================
-- NUI Callbacks לטפסים
-- =============================================

-- שליחת דוח תנועה
RegisterNUICallback('submitTrafficReport', function(data, cb)
    local target = GetClosestPlayer(5.0)
    data.targetSource = target ~= -1 and target or nil
    data.location = GetStreetName()
    TriggerServerEvent('il_police:server:createTrafficReport', data)
    CloseF6Menu()
    cb('ok')
end)

-- שליחת דוח פלילי
RegisterNUICallback('submitCriminalReport', function(data, cb)
    data.location = GetStreetName()
    TriggerServerEvent('il_police:server:createCriminalReport', data)
    CloseF6Menu()
    cb('ok')
end)

-- שליחת מעצר
RegisterNUICallback('submitArrest', function(data, cb)
    TriggerServerEvent('il_police:server:createArrest', data)
    CloseF6Menu()
    cb('ok')
end)

-- שליחת קנס
RegisterNUICallback('submitFine', function(data, cb)
    data.location = GetStreetName()
    TriggerServerEvent('il_police:server:createTrafficReport', data)
    CloseF6Menu()
    cb('ok')
end)

-- שליחת BOLO
RegisterNUICallback('submitBOLO', function(data, cb)
    TriggerServerEvent('il_police:server:createBOLO', data)
    CloseF6Menu()
    cb('ok')
end)

-- שינוי דרגה
RegisterNUICallback('submitGradeChange', function(data, cb)
    TriggerServerEvent('il_police:server:setGrade', tonumber(data.targetSource), tonumber(data.newGrade))
    CloseF6Menu()
    cb('ok')
end)

-- =============================================
-- פונקציית עזר - שם רחוב
-- =============================================
function GetStreetName()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local cross = GetStreetNameFromHashKey(crossHash)
    if cross and cross ~= '' then
        return street .. ' / ' .. cross
    end
    return street
end
