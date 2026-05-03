ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local isHudVisible = true
local hudReady = false
local hasSeatbelt = false

-- =============================================
-- אתחול
-- =============================================
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    initHud()
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    SendNUIMessage({ type = 'updateJob', job = job.label or '', grade = job.grade_label or '' })
end)

function initHud()
    -- טעינת הגדרות שמורות
    local savedSettings = GetResourceKvpString('venus_hud_settings')
    
    SendNUIMessage({
        type = 'init',
        serverName = Config.ServerName,
        serverTagline = Config.ServerTagline,
        defaultColors = Config.DefaultColors,
        defaultVisible = Config.DefaultVisible,
        defaultSpeedUnit = Config.DefaultSpeedUnit,
        defaultSpeedoStyle = Config.DefaultSpeedoStyle,
        savedSettings = savedSettings,
        serverId = GetPlayerServerId(PlayerId()),
        job = PlayerData.job and PlayerData.job.label or '',
        grade = PlayerData.job and PlayerData.job.grade_label or '',
    })

    SendNUIMessage({ type = 'showHud', show = true })
    hudReady = true
end

Citizen.CreateThread(function()
    while not ESX.IsPlayerLoaded() do Citizen.Wait(100) end
    PlayerData = ESX.GetPlayerData()
    initHud()
end)

-- =============================================
-- שמירת הגדרות (NUI Callback)
-- =============================================
RegisterNUICallback('saveSettings', function(data, cb)
    SetResourceKvp('venus_hud_settings', data.settings)
    cb('ok')
end)

RegisterNUICallback('closeSettings', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- =============================================
-- לולאת עדכון ראשית
-- =============================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.UpdateInterval)

        if hudReady and isHudVisible then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local armor = GetPedArmour(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
            local oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId())

            local healthPercent = math.max(0, math.floor(((health - 100) / (maxHealth - 100)) * 100))

            local hudData = {
                type = 'updateHud',
                health = healthPercent,
                armor = armor,
                stamina = math.floor(100 - stamina),
                oxygen = math.floor(oxygen / 10 * 100),
                inVehicle = inVehicle,
                talking = NetworkIsPlayerTalking(PlayerId()),
            }

            if inVehicle then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle)

                hudData.speed = math.floor(speed * 3.6)
                hudData.speedMph = math.floor(speed * 2.236936)
                hudData.rpm = GetVehicleCurrentRpm(vehicle)
                hudData.gear = GetVehicleCurrentGear(vehicle)
                hudData.fuel = GetVehicleFuelLevel(vehicle)
                hudData.heading = math.floor(GetEntityHeading(ped))
                hudData.seatbelt = hasSeatbelt

                local engineHealth = GetVehicleEngineHealth(vehicle)
                hudData.engineHealth = math.floor(engineHealth / 10)
            end

            -- רחוב
            if Config.ShowStreetName then
                local pos = GetEntityCoords(ped)
                local streetHash, crossHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
                local streetName = GetStreetNameFromHashKey(streetHash)
                local crossName = GetStreetNameFromHashKey(crossHash)
                if crossName and crossName ~= '' then
                    hudData.street = streetName .. ' / ' .. crossName
                else
                    hudData.street = streetName
                end
            end

            SendNUIMessage(hudData)
        end
    end
end)

-- =============================================
-- עדכון כסף
-- =============================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.MoneyUpdateInterval)

        if hudReady and isHudVisible then
            local accounts = ESX.GetPlayerData().accounts or {}
            local cash, bank, black = 0, 0, 0

            for _, account in pairs(accounts) do
                if account.name == 'money' then cash = account.money end
                if account.name == 'bank' then bank = account.money end
                if account.name == 'black_money' then black = account.money end
            end

            SendNUIMessage({ type = 'updateMoney', cash = cash, bank = bank, black = black })
        end
    end
end)

-- =============================================
-- עדכון שעון
-- =============================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        if hudReady and isHudVisible then
            SendNUIMessage({ type = 'updateClock', hour = GetClockHours(), minute = GetClockMinutes() })
        end
    end
end)

-- =============================================
-- סטטוס (רעב/צמא)
-- =============================================
if Config.UseStatus then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)
            if hudReady and isHudVisible then
                TriggerEvent('esx_status:getStatus', function(status)
                    if status then
                        local hunger, thirst = 100, 100
                        for _, s in pairs(status) do
                            if s.name == 'hunger' then hunger = math.floor(s.percent) end
                            if s.name == 'thirst' then thirst = math.floor(s.percent) end
                        end
                        SendNUIMessage({ type = 'updateStatus', hunger = hunger, thirst = thirst })
                    end
                end)
            end
        end
    end)
end

-- =============================================
-- הסתרת HUD בתפריט
-- =============================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local isPaused = IsPauseMenuActive()
        if isPaused and isHudVisible then
            isHudVisible = false
            SendNUIMessage({ type = 'showHud', show = false })
        elseif not isPaused and not isHudVisible then
            isHudVisible = true
            SendNUIMessage({ type = 'showHud', show = true })
        end
    end
end)

-- =============================================
-- פקודות ומקשים
-- =============================================
RegisterCommand(Config.SettingsCommand, function()
    SendNUIMessage({ type = 'openSettings' })
    SetNuiFocus(true, true)
end, false)

RegisterKeyMapping(Config.SettingsCommand, 'הגדרות HUD', 'keyboard', Config.SettingsKey)

-- Export לחגורת בטיחות
function SetSeatbelt(state)
    hasSeatbelt = state
end

exports('SetSeatbelt', SetSeatbelt)
exports('HasSeatbelt', function() return hasSeatbelt end)
