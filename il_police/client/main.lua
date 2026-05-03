ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local isOnDuty = false
local isCuffed = false
local isEscorted = false
local escortingPlayer = nil

-- =============================================
-- אתחול
-- =============================================
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)

-- =============================================
-- פונקציות עזר
-- =============================================
function IsPolice()
    return PlayerData.job and PlayerData.job.name == Config.PoliceJob
end

function GetPlayerGrade()
    if not PlayerData.job then return 0 end
    return PlayerData.job.grade or 0
end

function GetGradeLabel()
    local grade = GetPlayerGrade()
    local rankData = Config.Ranks[grade]
    return rankData and rankData.label or 'לא ידוע'
end

function GetClosestPlayer(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = -1
    local closestDistance = radius or 3.0

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = GetPlayerServerId(playerId)
            end
        end
    end

    return closestPlayer
end

-- =============================================
-- הודעות
-- =============================================
RegisterNetEvent('il_police:client:notify', function(notifyType, message)
    SendNUIMessage({
        type = 'notification',
        notifyType = notifyType,
        message = message
    })
end)

-- =============================================
-- תורנות
-- =============================================
RegisterNetEvent('il_police:client:setDuty', function(duty)
    isOnDuty = duty
end)

-- =============================================
-- אזיקים
-- =============================================
RegisterNetEvent('il_police:client:getCuffed', function()
    isCuffed = not isCuffed
    local playerPed = PlayerPedId()

    if isCuffed then
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do Wait(10) end
        TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(playerPed, true)
        DisablePlayerFiring(playerPed, true)
        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
        FreezeEntityPosition(playerPed, false)
    else
        ClearPedTasks(playerPed)
        SetEnableHandcuffs(playerPed, false)
        DisablePlayerFiring(playerPed, false)
    end
end)

-- =============================================
-- ליווי
-- =============================================
RegisterNetEvent('il_police:client:getEscorted', function(officerSource)
    isEscorted = not isEscorted

    if isEscorted then
        escortingPlayer = officerSource
    else
        escortingPlayer = nil
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isEscorted and escortingPlayer then
            local officerPed = GetPlayerPed(GetPlayerFromServerId(escortingPlayer))
            if DoesEntityExist(officerPed) then
                local officerCoords = GetEntityCoords(officerPed)
                local heading = GetEntityHeading(officerPed)
                local behindX = officerCoords.x - math.sin(math.rad(heading)) * 1.0
                local behindY = officerCoords.y + math.cos(math.rad(heading)) * 1.0

                local playerPed = PlayerPedId()
                SetEntityCoords(playerPed, behindX, behindY, officerCoords.z, false, false, false, false)
            end
        else
            Wait(500)
        end
    end
end)

-- =============================================
-- שליחה לכלא (ESX compatible)
-- =============================================
RegisterNetEvent('il_police:client:sendToJail', function(jailTime)
    -- אינטגרציה עם מערכת כלא (esx_jail או דומה)
    TriggerEvent('esx_jail:sendToJail', jailTime)
    SendNUIMessage({
        type = 'notification',
        notifyType = 'error',
        message = 'נשלחת לכלא ל-' .. jailTime .. ' דקות'
    })
end)

-- =============================================
-- תוצאות חיפוש שחקן
-- =============================================
RegisterNetEvent('il_police:client:showSearchResults', function(data)
    SendNUIMessage({
        type = 'showSearchResults',
        data = data
    })
end)

-- =============================================
-- Dispatch הודעות מוקד
-- =============================================
RegisterNetEvent('il_police:client:dispatchNotification', function(data)
    SendNUIMessage({
        type = 'dispatch',
        data = data
    })
end)

-- =============================================
-- בליפים לתחנות משטרה
-- =============================================
CreateThread(function()
    for _, station in pairs(Config.PoliceStations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, station.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, station.blip.scale)
        SetBlipColour(blip, station.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(station.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- =============================================
-- HUD
-- =============================================
CreateThread(function()
    while true do
        Wait(1000)
        if IsPolice() and isOnDuty then
            SendNUIMessage({
                type = 'updateHUD',
                data = {
                    rank = GetGradeLabel(),
                    grade = GetPlayerGrade(),
                    department = Config.Ranks[GetPlayerGrade()] and Config.Ranks[GetPlayerGrade()].department or 'patrol',
                    onDuty = isOnDuty
                }
            })
        end
    end
end)

-- =============================================
-- מקשים
-- =============================================
CreateThread(function()
    while true do
        Wait(0)
        if IsPolice() then
            -- F6 - תפריט משטרה
            if IsControlJustReleased(0, 167) then -- F6
                TriggerEvent('il_police:client:openF6Menu')
            end

            -- F7 - MDT
            if IsControlJustReleased(0, 168) then -- F7
                if GetPlayerGrade() >= Config.MDT.minGrade then
                    TriggerEvent('il_police:client:openMDT')
                else
                    SendNUIMessage({
                        type = 'notification',
                        notifyType = 'error',
                        message = 'אין לך הרשאה לגשת ל-MDT'
                    })
                end
            end
        else
            Wait(500)
        end
    end
end)
