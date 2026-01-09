local barrels = {}
carryingBarrel = false
carriedBarrelId = nil

local function IsOxTargetAvailable()
    return GetResourceState('ox_target') == 'started'
end

Citizen.CreateThread(function()
    local barrelTypes = {'barrel_a', 'barrel_b', 'barrel_c'}
    barrels = {}

    for i, typeKey in ipairs(barrelTypes) do
        local typeData = Config.BarrelLocations[typeKey]

        local subKeys = {}
        for key,_ in pairs(typeData.locations) do
            subKeys[#subKeys+1] = key
        end

        for j = 1, 3 do
            local subKey = subKeys[math.random(#subKeys)]
            local subLocs = typeData.locations[subKey]
            local randomLoc = subLocs[math.random(#subLocs)]

            RequestModel(Config.PropModels.barrel)
            while not HasModelLoaded(Config.PropModels.barrel) do
                Wait(100)
            end

            local prop = CreateObject(
                Config.PropModels.barrel,
                randomLoc.x, randomLoc.y, randomLoc.z,
                false, false, false
            )

            PlaceObjectOnGroundProperly(prop)

            local barrelId = (i-1)*3 + j
            barrels[barrelId] = prop

            if IsOxTargetAvailable() then
                exports.ox_target:addLocalEntity(prop, {{
                    name = 'pickup_barrel_' .. barrelId,
                    label = 'Pick up Barrel',
                    icon = 'fas fa-hand-paper',
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent('chem:request:pickupBarrel', barrelId)
                    end
                }})
            end
        end
    end
end)

RegisterNetEvent('chem:sync:barrelState')
AddEventHandler('chem:sync:barrelState', function(id, state, playerId, vehicleNetId, slot)
    if state == 'picked' then
        if playerId == GetPlayerServerId(PlayerId()) then
            AttachBarrelToPlayer(barrels[id])
            carryingBarrel = true
            carriedBarrelId = id
            if IsOxTargetAvailable() then
                exports.ox_target:removeLocalEntity(barrels[id])
            end
        else
            if DoesEntityExist(barrels[id]) then
                SetEntityVisible(barrels[id], false, false)
            end
        end
    elseif state == 'loaded' then
        print('[DEBUG] Attaching barrel id:', id, 'to vehicleNetId:', vehicleNetId, 'slot:', slot)
        local vehicle = NetToVeh(vehicleNetId)
        if DoesEntityExist(vehicle) then
            print('[DEBUG] Vehicle exists, attaching barrel')
            AttachBarrelToTruck(barrels[id], vehicle, slot)
        else
            print('[DEBUG] Vehicle does not exist for barrel id:', id)
        end
        carryingBarrel = false
        carriedBarrelId = nil
        ClearPedTasks(PlayerPedId())
    elseif state == 'reset' then
        if DoesEntityExist(barrels[id]) then
            SetEntityVisible(barrels[id], true, false)
            DetachEntity(barrels[id], true, true)
            PlaceObjectOnGroundProperly(barrels[id])
        end
        if carriedBarrelId == id then
            carryingBarrel = false
            carriedBarrelId = nil
            ClearPedTasks(PlayerPedId())
        end
        if IsOxTargetAvailable() then
            exports.ox_target:addLocalEntity(barrels[id], {
                {
                    name = 'pickup_barrel_' .. id,
                    label = 'Pick up Barrel',
                    icon = 'fas fa-hand-paper',
                    onSelect = function()
                        TriggerServerEvent('chem:request:pickupBarrel', id)
                    end
                }
            })
        end
    end
end)

function AttachBarrelToPlayer(prop)
    RequestAnimDict(Config.AnimDicts.carry)
    while not HasAnimDictLoaded(Config.AnimDicts.carry) do
        Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), Config.AnimDicts.carry, 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.0, 0.3, 0.0, 0.0, 0.0, 90.0, true, true, false, true, 1, true)
end

function AttachBarrelToTruck(prop, vehicle, slot)
    print('[DEBUG] AttachBarrelToTruck called for prop:', prop, 'vehicle:', vehicle, 'slot:', slot)
    local slotData = Config.TruckSlots[slot]
    if slotData then
        print('[DEBUG] Slot data found, attaching with offset:', slotData.offset.x, slotData.offset.y, slotData.offset.z)
        AttachEntityToEntity(prop, vehicle, -1, slotData.offset.x, slotData.offset.y, slotData.offset.z, slotData.rot.x, slotData.rot.y, slotData.rot.z, false, false, false, false, 2, true)
        print('[DEBUG] Barrel attached successfully')
    else
        print('[DEBUG] No slot data for slot:', slot)
    end
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