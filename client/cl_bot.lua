local startBot, exchangeBot
local startBlip, exchangeBlip
missionTruck = nil
local dropoffCoords = nil

Citizen.CreateThread(function()
    RequestModel(Config.StartBot.model)
    while not HasModelLoaded(Config.StartBot.model) do
        Wait(100)
    end
    startBot = CreatePed(4, Config.StartBot.model, Config.StartBot.coords.x, Config.StartBot.coords.y,
        Config.StartBot.coords.z - 1.0, Config.StartBot.heading, false, true)
    FreezeEntityPosition(startBot, true)
    SetEntityInvincible(startBot, true)
    SetBlockingOfNonTemporaryEvents(startBot, true)

    RequestModel(Config.ExchangeBot.model)
    while not HasModelLoaded(Config.ExchangeBot.model) do
        Wait(100)
    end
    exchangeBot = CreatePed(4, Config.ExchangeBot.model, Config.ExchangeBot.coords.x, Config.ExchangeBot.coords.y,
        Config.ExchangeBot.coords.z - 1.0, Config.ExchangeBot.heading, false, true)
    FreezeEntityPosition(exchangeBot, true)
    SetEntityInvincible(exchangeBot, true)
    SetBlockingOfNonTemporaryEvents(exchangeBot, true)

    if IsOxTargetAvailable() then
        exports.ox_target:addLocalEntity(startBot, {
            {
                name = 'start_chemical_job',
                label = 'Start Chemical Job',
                icon = 'fas fa-flask',
                onSelect = function()
                    TriggerServerEvent('chem:request:startMission')
                end
            }
        })
        exports.ox_target:addLocalEntity(exchangeBot, {
            {
                name = 'exchange_chemicals',
                label = 'Exchange Chemicals',
                icon = 'fas fa-exchange-alt',
                onSelect = function()
                    TriggerServerEvent('chem:request:exchange')
                end
            }
        })
    end

    startBlip = AddBlipForCoord(Config.StartBot.coords.x, Config.StartBot.coords.y, Config.StartBot.coords.z)
    SetBlipSprite(startBlip, 280)
    SetBlipColour(startBlip, 1)
    SetBlipScale(startBlip, 0.8)
    SetBlipAsShortRange(startBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Chemical Job Start")
    EndTextCommandSetBlipName(startBlip)

    exchangeBlip = AddBlipForCoord(Config.ExchangeBot.coords.x, Config.ExchangeBot.coords.y, Config.ExchangeBot.coords.z)
    SetBlipSprite(exchangeBlip, 280)
    SetBlipColour(exchangeBlip, 1)
    SetBlipScale(exchangeBlip, 0.8)
    SetBlipAsShortRange(exchangeBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Chemical Exchange")
    EndTextCommandSetBlipName(exchangeBlip)
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, Config.StartBot.coords.x, Config.StartBot.coords.y, Config.StartBot.coords.z) < 3.0 then
            if not IsOxTargetAvailable() then
                DrawMarker(1, Config.StartBot.coords.x, Config.StartBot.coords.y, Config.StartBot.coords.z - 1.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                Draw3DText(Config.StartBot.coords.x, Config.StartBot.coords.y, Config.StartBot.coords.z + 1.0,
                    Config.StartBot.prompt)
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('chem:request:startMission')
                end
            end
        end

        if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, Config.ExchangeBot.coords.x, Config.ExchangeBot.coords.y, Config.ExchangeBot.coords.z) < 3.0 then
            if not IsOxTargetAvailable() then
                DrawMarker(1, Config.ExchangeBot.coords.x, Config.ExchangeBot.coords.y, Config.ExchangeBot.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil,
                    false)
                Draw3DText(Config.ExchangeBot.coords.x, Config.ExchangeBot.coords.y, Config.ExchangeBot.coords.z + 1.0,
                    Config.ExchangeBot.prompt)
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('chem:request:exchange')
                end
            end
        end
    end
end)

function IsOxTargetAvailable()
    return GetResourceState('ox_target') == 'started'
end

function Draw3DText(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent('chem:sync:startMission')
AddEventHandler('chem:sync:startMission', function()
    selectedDropoffs = {}

    for zoneName, zone in pairs(Config.DeliveryZone) do
        local loc = zone.locations[math.random(#zone.locations)]
        selectedDropoffs[zoneName] = loc
    end

    TriggerEvent('chem:setSelectedDropoffs', selectedDropoffs)
    TriggerEvent('chem:refreshDeliveryBlips')

    if not missionTruck or not DoesEntityExist(missionTruck) then
        RequestModel(Config.TruckSpawn.model)
        while not HasModelLoaded(Config.TruckSpawn.model) do
            Wait(100)
        end

        missionTruck = CreateVehicle(
            Config.TruckSpawn.model,
            Config.TruckSpawn.coords.x,
            Config.TruckSpawn.coords.y,
            Config.TruckSpawn.coords.z,
            Config.TruckSpawn.heading,
            true,
            false
        )

        SetVehicleOnGroundProperly(missionTruck)
        SetVehicleDoorsLocked(missionTruck, 1)

        local plate = GetVehicleNumberPlateText(missionTruck)
        TriggerServerEvent('chem:giveKeys', plate)

        if IsOxTargetAvailable() then
            exports.ox_target:addLocalEntity(missionTruck, {
                {
                    name = 'load_barrel',
                    label = 'Load Barrel',
                    icon = 'fas fa-truck-loading',
                    canInteract = function()
                        return carryingBarrel
                    end,
                    onSelect = function()
                        local netId = VehToNet(missionTruck)
                        TriggerServerEvent('chem:request:loadBarrel', netId)
                    end
                }
            })
        end
        if IsOxTargetAvailable() then
            exports.ox_target:addLocalEntity(missionTruck, {
                {
                    name = 'truck_take_barrel',
                    label = 'Take Barrel',
                    icon = 'fas fa-box',
                    distance = 2.5,
                    canInteract = function()
                        return not carryingBarrel
                    end,
                    onSelect = function()
                        local opts = {}

                        if loadedTypes then
                            if loadedTypes.barrel_a and loadedTypes.barrel_a > 0 then
                                opts[#opts + 1] = {
                                    title = 'Barrel A',
                                    onSelect = function()
                                        TriggerServerEvent('chem:request:takeFromTruck', 'barrel_a')
                                    end
                                }
                            end

                            if loadedTypes.barrel_b and loadedTypes.barrel_b > 0 then
                                opts[#opts + 1] = {
                                    title = 'Barrel B',
                                    onSelect = function()
                                        TriggerServerEvent('chem:request:takeFromTruck', 'barrel_b')
                                    end
                                }
                            end

                            if loadedTypes.barrel_c and loadedTypes.barrel_c > 0 then
                                opts[#opts + 1] = {
                                    title = 'Barrel C',
                                    onSelect = function()
                                        TriggerServerEvent('chem:request:takeFromTruck', 'barrel_c')
                                    end
                                }
                            end
                        end

                        if #opts == 0 then
                            if GetResourceState('ox_lib') == 'started' and lib and lib.notify then
                                lib.notify({
                                    description = 'No barrels left in the truck.',
                                    type = 'error'
                                })
                            else
                                print('[CHEM] No barrels left in the truck.')
                            end
                            return
                        end

                        if GetResourceState('ox_lib') == 'started' and lib and lib.registerContext then
                            lib.registerContext({
                                id = 'unload_barrel_menu',
                                title = 'Unload From Truck',
                                options = opts
                            })

                            lib.showContext('unload_barrel_menu')
                        end
                    end
                }
            })
        end
    end
end)

RegisterNetEvent('chem:setWaypointForBarrel')
AddEventHandler('chem:setWaypointForBarrel', function(barrelType)
    local zoneMap = {
        barrel_a = "barrel_a_delivery",
        barrel_b = "barrel_b_delivery",
        barrel_c = "barrel_c_delivery"
    }

    local zoneName = zoneMap[barrelType]
    local loc = selectedDropoffs[zoneName]
    if loc then
        SetNewWaypoint(loc.x, loc.y)
    end
end)

RegisterNetEvent('chem:sync:endDelivery')
AddEventHandler('chem:sync:endDelivery', function()

    print('[CHEM DEBUG] Delivery complete, setting waypoint to truck park')

    if Config.TruckPark then
        SetNewWaypoint(Config.TruckPark.x, Config.TruckPark.y)
    end
    TriggerEvent('chem:request:showParkingLocation')
end)


RegisterNetEvent('chem:sync:endMission')
AddEventHandler('chem:sync:endMission', function()

    print('[CHEM DEBUG] Mission complete, deleting mission truck')

    if truckParkZone then
        truckParkZone:remove()
        truckParkZone = nil
    end

    if missionTruck and DoesEntityExist(missionTruck) then
        if IsOxTargetAvailable() then
            exports.ox_target:removeLocalEntity(missionTruck)
        end
        DeleteVehicle(missionTruck)
        missionTruck = nil
    end

    dropoffCoords = nil
    TriggerEvent('chem:clearDropoff')
end)




