local isMDTOpen = false

-- =============================================
-- פתיחת MDT
-- =============================================
RegisterNetEvent('il_police:client:openMDT', function()
    if not IsPolice() then return end
    if isMDTOpen then
        CloseMDT()
        return
    end

    isMDTOpen = true
    SetNuiFocus(true, true)

    TriggerServerEvent('il_police:server:getOfficerInfo')
    TriggerServerEvent('il_police:server:getStats')

    SendNUIMessage({
        type = 'openMDT',
        rank = GetGradeLabel(),
        grade = GetPlayerGrade(),
        department = Config.Ranks[GetPlayerGrade()] and Config.Ranks[GetPlayerGrade()].department or 'patrol',
        departmentLabel = Config.Ranks[GetPlayerGrade()] and Config.Departments[Config.Ranks[GetPlayerGrade()].department] and Config.Departments[Config.Ranks[GetPlayerGrade()].department].label or 'סיור',
        violations = Config.TrafficViolations,
        charges = Config.CriminalCharges,
        ranks = Config.Ranks,
        departments = Config.Departments
    })
end)

function CloseMDT()
    isMDTOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMDT' })
end

-- =============================================
-- קבלת מידע
-- =============================================
RegisterNetEvent('il_police:client:receiveOfficerInfo', function(data)
    SendNUIMessage({
        type = 'officerInfo',
        data = data
    })
end)

RegisterNetEvent('il_police:client:receiveStats', function(stats)
    SendNUIMessage({
        type = 'stats',
        data = stats
    })
end)

RegisterNetEvent('il_police:client:searchResults', function(searchType, results)
    SendNUIMessage({
        type = 'searchResults',
        searchType = searchType,
        results = results
    })
end)

RegisterNetEvent('il_police:client:receiveReports', function(reportType, reports, total)
    SendNUIMessage({
        type = 'reports',
        reportType = reportType,
        reports = reports,
        total = total
    })
end)

RegisterNetEvent('il_police:client:receiveOnlineCops', function(cops)
    SendNUIMessage({
        type = 'onlineCops',
        cops = cops
    })
end)

-- =============================================
-- MDT NUI Callbacks
-- =============================================
RegisterNUICallback('closeMDT', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('mdtSearchCitizen', function(data, cb)
    TriggerServerEvent('il_police:server:searchCitizen', data.name)
    cb('ok')
end)

RegisterNUICallback('mdtSearchVehicle', function(data, cb)
    TriggerServerEvent('il_police:server:searchVehicle', data.plate)
    cb('ok')
end)

RegisterNUICallback('mdtGetReports', function(data, cb)
    TriggerServerEvent('il_police:server:getReports', data.reportType, data.page or 1)
    cb('ok')
end)

RegisterNUICallback('mdtGetOnlineCops', function(data, cb)
    TriggerServerEvent('il_police:server:getOnlineCops')
    cb('ok')
end)

RegisterNUICallback('mdtGetStats', function(data, cb)
    TriggerServerEvent('il_police:server:getStats')
    cb('ok')
end)

RegisterNUICallback('mdtCreateTrafficReport', function(data, cb)
    data.location = GetStreetName()
    TriggerServerEvent('il_police:server:createTrafficReport', data)
    cb('ok')
end)

RegisterNUICallback('mdtCreateCriminalReport', function(data, cb)
    data.location = GetStreetName()
    TriggerServerEvent('il_police:server:createCriminalReport', data)
    cb('ok')
end)

RegisterNUICallback('mdtCreateArrest', function(data, cb)
    TriggerServerEvent('il_police:server:createArrest', data)
    cb('ok')
end)

RegisterNUICallback('mdtCreateBOLO', function(data, cb)
    TriggerServerEvent('il_police:server:createBOLO', data)
    cb('ok')
end)

RegisterNUICallback('mdtCancelBOLO', function(data, cb)
    TriggerServerEvent('il_police:server:cancelBOLO', data.boloId)
    cb('ok')
end)

RegisterNUICallback('mdtSetGrade', function(data, cb)
    TriggerServerEvent('il_police:server:setGrade', tonumber(data.targetSource), tonumber(data.newGrade))
    cb('ok')
end)

RegisterNUICallback('mdtDispatch', function(data, cb)
    TriggerServerEvent('il_police:server:dispatchMessage', data.message, data.code)
    cb('ok')
end)
