ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local isHudVisible = true
local lastHealth = 200
local lastArmor = 0

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    SendNUIMessage({ type = 'showHud', show = true })
    SendNUIMessage({
        type = 'updateJob',
        job = PlayerData.job and PlayerData.job.label or '',
        grade = PlayerData.job and PlayerData.job.grade_label or ''
    })
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    SendNUIMessage({
        type = 'updateJob',
        job = job.label or '',
        grade = job.grade_label or ''
    })
end)

-- שליחת הגדרות לNUI
Citizen.CreateThread(function()
    while not ESX do
        Citizen.Wait(100)
    end

    while not ESX.IsPlayerLoaded() do
        Citizen.Wait(100)
    end

    PlayerData = ESX.GetPlayerData()

    SendNUIMessage({
        type = 'init',
        serverName = Config.ServerName,
        serverSubtitle = Config.ServerSubtitle,
        showSpeedometer = Config.ShowSpeedometer,
        showCompass = Config.ShowCompass,
        showMicrophone = Config.ShowMicrophone,
        showMoney = Config.ShowMoney,
        showClock = Config.ShowClock,
        showJob = Config.ShowJob,
        showStatus = Config.ShowStatus,
        showServerId = Config.ShowServerId,
        speedUnit = Config.SpeedUnit,
        primaryColor = Config.PrimaryColor,
        accentColor = Config.AccentColor,
    })

    SendNUIMessage({ type = 'showHud', show = true })

    SendNUIMessage({
        type = 'updateJob',
        job = PlayerData.job and PlayerData.job.label or '',
        grade = PlayerData.job and PlayerData.job.grade_label or ''
    })

    SendNUIMessage({
        type = 'updateServerId',
        id = GetPlayerServerId(PlayerId())
    })
end)

-- לולאה ראשית - עדכון נתונים
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.UpdateInterval)

        if isHudVisible then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local armor = GetPedArmour(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)

            -- בריאות (0-100)
            local healthPercent = math.floor(((health - 100) / (maxHealth - 100)) * 100)
            if healthPercent < 0 then healthPercent = 0 end
            if healthPercent > 100 then healthPercent = 100 end

            local hudData = {
                type = 'updateHud',
                health = healthPercent,
                armor = armor,
                inVehicle = inVehicle,
            }

            -- מהירות ומצפן ברכב
            if inVehicle then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle)

                if Config.SpeedUnit == 'kmh' then
                    hudData.speed = math.floor(speed * 3.6)
                else
                    hudData.speed = math.floor(speed * 2.236936)
                end

                hudData.rpm = GetVehicleCurrentRpm(vehicle)
                hudData.gear = GetVehicleCurrentGear(vehicle)
                hudData.fuel = GetVehicleFuelLevel(vehicle)

                if Config.ShowCompass then
                    local heading = GetEntityHeading(ped)
                    hudData.heading = math.floor(heading)
                end
            end

            -- מיקרופון
            if Config.ShowMicrophone then
                hudData.talking = NetworkIsPlayerTalking(PlayerId())
            end

            SendNUIMessage(hudData)
        end
    end
end)

-- עדכון כסף
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)

        if isHudVisible and Config.ShowMoney then
            local accounts = ESX.GetPlayerData().accounts or {}
            local cash = 0
            local bank = 0
            local black = 0

            for _, account in pairs(accounts) do
                if account.name == 'money' then cash = account.money end
                if account.name == 'bank' then bank = account.money end
                if account.name == 'black_money' then black = account.money end
            end

            SendNUIMessage({
                type = 'updateMoney',
                cash = cash,
                bank = bank,
                black = black
            })
        end
    end
end)

-- עדכון שעון
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)

        if isHudVisible and Config.ShowClock then
            local hour = GetClockHours()
            local minute = GetClockMinutes()
            SendNUIMessage({
                type = 'updateClock',
                hour = hour,
                minute = minute
            })
        end
    end
end)

-- עדכון סטטוס (רעב/צמא)
if Config.ShowStatus then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)

            if isHudVisible then
                TriggerEvent('esx_status:getStatus', function(status)
                    if status then
                        local hunger = 100
                        local thirst = 100

                        for _, s in pairs(status) do
                            if s.name == 'hunger' then
                                hunger = math.floor(s.percent)
                            elseif s.name == 'thirst' then
                                thirst = math.floor(s.percent)
                            end
                        end

                        SendNUIMessage({
                            type = 'updateStatus',
                            hunger = hunger,
                            thirst = thirst
                        })
                    end
                end)
            end
        end
    end)
end

-- הסתרת HUD בתפריט
if Config.HideOnPause then
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
end

-- פקודה להסתרת/הצגת HUD
RegisterCommand('hud', function()
    isHudVisible = not isHudVisible
    SendNUIMessage({ type = 'showHud', show = isHudVisible })
end, false)
