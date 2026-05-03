local hasSeatbelt = false
local wasSeatbelted = false

-- מקש חגורת בטיחות
RegisterCommand('seatbelt', function()
    if not IsPedInAnyVehicle(PlayerPedId(), false) then return end

    hasSeatbelt = not hasSeatbelt
    exports['venus_hud']:SetSeatbelt(hasSeatbelt)

    if hasSeatbelt then
        SendNUIMessage({ type = 'notify', style = 'success', text = 'חגורת בטיחות חגורה' })
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    else
        SendNUIMessage({ type = 'notify', style = 'warning', text = 'חגורת בטיחות שוחררה' })
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
end, false)

RegisterKeyMapping('seatbelt', 'חגורת בטיחות', 'keyboard', Config.SeatbeltKey)

-- זריקה מרכב
if Config.Seatbelt.enabled then
    Citizen.CreateThread(function()
        local prevSpeed = 0

        while true do
            Citizen.Wait(100)

            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)

                -- בדיקת התנגשות - ירידה חדה במהירות
                if not exports['venus_hud']:HasSeatbelt() then
                    if prevSpeed > Config.Seatbelt.ejectSpeed and (prevSpeed - speed) > 40 then
                        if math.random(100) <= Config.Seatbelt.ejectChance then
                            -- זריקה מהרכב
                            local coords = GetEntityCoords(ped)
                            SetEntityCoords(ped, coords.x, coords.y, coords.z + 1.0)
                            SetEntityVelocity(ped,
                                math.random(-10, 10) + 0.0,
                                math.random(-10, 10) + 0.0,
                                5.0
                            )
                            SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)
                            SendNUIMessage({ type = 'notify', style = 'error', text = 'נזרקת מהרכב!' })
                            ApplyDamageToPed(ped, math.random(20, 40), false)
                        end
                    end
                end

                prevSpeed = speed
            else
                prevSpeed = 0
                if hasSeatbelt then
                    hasSeatbelt = false
                    exports['venus_hud']:SetSeatbelt(false)
                end
            end
        end
    end)
end
