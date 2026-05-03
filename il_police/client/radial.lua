local isRadialOpen = false

-- =============================================
-- פתיחת תפריט רדיאלי
-- =============================================
function OpenRadialMenu()
    if not IsPolice() then return end
    if isRadialOpen then return end

    isRadialOpen = true
    SetNuiFocus(true, true)

    local items = {}
    for _, item in ipairs(Config.RadialMenu.items) do
        table.insert(items, {
            id = item.id,
            label = item.label,
            icon = item.icon,
            action = item.action
        })
    end

    SendNUIMessage({
        type = 'openRadial',
        items = items,
        rank = GetGradeLabel(),
        department = Config.Ranks[GetPlayerGrade()] and Config.Departments[Config.Ranks[GetPlayerGrade()].department] or nil
    })
end

function CloseRadialMenu()
    isRadialOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeRadial' })
end

-- =============================================
-- מקש Z לפתיחת רדיאל
-- =============================================
CreateThread(function()
    while true do
        Wait(0)
        if IsPolice() and isOnDuty then
            if IsControlJustPressed(0, 20) then -- Z key
                if isRadialOpen then
                    CloseRadialMenu()
                else
                    OpenRadialMenu()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- =============================================
-- טיפול בפעולות מהרדיאל
-- =============================================
RegisterNUICallback('radialAction', function(data, cb)
    CloseRadialMenu()

    local action = data.action

    if action == 'openDispatch' then
        -- פתיחת מוקד
        SendNUIMessage({
            type = 'openDispatchPanel',
            rank = GetGradeLabel()
        })
        SetNuiFocus(true, true)

    elseif action == 'openMDT' then
        TriggerEvent('il_police:client:openMDT')

    elseif action == 'toggleCuffs' then
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

    elseif action == 'searchPlayer' then
        local target = GetClosestPlayer(3.0)
        if target ~= -1 then
            TriggerServerEvent('il_police:server:searchPlayer', target)
            SetNuiFocus(true, true)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין שחקן בקרבת מקום'
            })
        end

    elseif action == 'escortPlayer' then
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

    elseif action == 'vehicleMenu' then
        TriggerEvent('il_police:client:openVehicleMenu')

    elseif action == 'deploySpikeStrip' then
        TriggerEvent('il_police:client:deploySpikeStrip')

    elseif action == 'deployBarrier' then
        TriggerEvent('il_police:client:deployBarrier')
    end

    cb('ok')
end)

RegisterNUICallback('closeRadial', function(data, cb)
    CloseRadialMenu()
    cb('ok')
end)

-- =============================================
-- פריסת מסמרים
-- =============================================
RegisterNetEvent('il_police:client:deploySpikeStrip', function()
    if not IsPolice() then return end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local model = GetHashKey('p_ld_stinger_s')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local spike = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, false, false)
    SetEntityHeading(spike, heading)
    PlaceObjectOnGroundProperly(spike)

    SendNUIMessage({
        type = 'notification',
        notifyType = 'success',
        message = 'מסמרים נפרסו'
    })

    -- מחיקה אחרי 60 שניות
    SetTimeout(60000, function()
        DeleteObject(spike)
        SendNUIMessage({
            type = 'notification',
            notifyType = 'info',
            message = 'מסמרים הוסרו'
        })
    end)
end)

-- =============================================
-- מחסום
-- =============================================
RegisterNetEvent('il_police:client:deployBarrier', function()
    if not IsPolice() then return end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local model = GetHashKey('prop_barrier_work06a')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local barrier = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, false, false)
    SetEntityHeading(barrier, heading)
    PlaceObjectOnGroundProperly(barrier)

    SendNUIMessage({
        type = 'notification',
        notifyType = 'success',
        message = 'מחסום הוצב'
    })
end)

-- =============================================
-- תפריט רכב
-- =============================================
RegisterNetEvent('il_police:client:openVehicleMenu', function()
    if not IsPolice() then return end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        -- לא ברכב - חיפוש רכב קרוב
        local closestVehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 71)
        if closestVehicle ~= 0 then
            local plate = GetVehicleNumberPlateText(closestVehicle)
            TriggerServerEvent('il_police:server:searchVehicle', plate)
            SetNuiFocus(true, true)
        else
            SendNUIMessage({
                type = 'notification',
                notifyType = 'error',
                message = 'אין רכב בקרבת מקום'
            })
        end
    else
        -- ברכב - אפשרויות רכב
        SendNUIMessage({
            type = 'vehicleOptions',
            data = {
                plate = GetVehicleNumberPlateText(vehicle),
                model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                speed = GetEntitySpeed(vehicle) * 3.6
            }
        })
        SetNuiFocus(true, true)
    end
end)

-- =============================================
-- Dispatch Panel Callbacks
-- =============================================
RegisterNUICallback('sendDispatch', function(data, cb)
    TriggerServerEvent('il_police:server:dispatchMessage', data.message, data.code)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeDispatch', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
