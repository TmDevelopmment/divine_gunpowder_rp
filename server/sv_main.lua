local activeMissions = {}
local cooldowns = {}
local runs = {}

local function createPlate()
    local prefix = 'CHEM'
    local plate = ('%s%04d'):format(prefix, math.random(0, 9999))
    if Config.Debug then print('[DEBUG] Generated plate:', plate) end
    return plate
end

local function getDeliveryTypeAtCoords(coords)
    for zoneName, zoneData in pairs(Config.DeliveryZone) do
        for _, loc in ipairs(zoneData.locations) do
            if #(coords - loc) <= zoneData.radius then
                return zoneName
            end
        end
    end
    return nil
end

local function missionBarrelsRemaining(src)
    for id, data in pairs(barrelStates) do
        if data.state == 'spawned' then
            return true
        end

        if data.state == 'picked' and data.player == src then
            return true
        end
    end

    return false
end

local function syncLoadedTypes(src)
    local data = activeMissions[src]
    if not data then return end
    TriggerClientEvent('chem:updateLoadedTypes', src, data.loadedTypes)
end

local function clearMission(src, reason)
    if Config.Debug then print(("[CHEM DEBUG] CLEARING MISSION FOR %s | reason: %s"):format(src, reason or "unknown")) end
    activeMissions[src] = nil
end

function tryFinishMission(src)
    local mission = activeMissions[src]
    if not mission then return end

    local lt = mission.loadedTypes

    local truckEmpty =
        lt.barrel_a == 0 and
        lt.barrel_b == 0 and
        lt.barrel_c == 0

    local worldEmpty = not missionBarrelsRemaining(src)

    if Config.Debug then print('[CHEM DEBUG] tryFinishMission | truckEmpty =',
        truckEmpty, '| worldEmpty =', worldEmpty) end

    if truckEmpty and worldEmpty then
        if Config.Debug then print('[CHEM DEBUG] FINISH STAGE 1 — deliveries done (WAIT FOR PARK)') end

        TriggerClientEvent('chem:sync:endDelivery', src)

        Notify(
            src,
            'All deliveries completed — please return the truck to the parking area.',
            'success'
        )
    end
end

RegisterNetEvent('chem:request:startMission')
AddEventHandler('chem:request:startMission', function()
    local src = source
    if Config.Debug then print('[CHEM DEBUG] startMission requested by src:', src) end
    if activeMissions[src] then
        Notify(src, 'You already have an active job.', 'error')
        return
    end
    if cooldowns[src] and cooldowns[src].mission then
        local elapsed = GetGameTimer() - cooldowns[src].mission

        if elapsed < Config.Cooldowns.mission then
            local remaining = Config.Cooldowns.mission - elapsed
            local hours = math.floor(remaining / 3600000)
            local minutes = math.floor((remaining % 3600000) / 60000)

            Notify(src, 'Mission cooldown active. Wait '..hours..'h '..minutes..'m.', 'error')
            return
        end
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - Config.StartBot.coords) > 5.0 then
        Notify(src, 'Too far from start bot.', 'error')
        return
    end

    local runId = tostring(os.time()) .. ':' .. tostring(src)
    local participants = { [src] = true }

    local allDeliveryLocs = {}
    for _, zoneData in pairs(Config.DeliveryZone) do
        for _, loc in ipairs(zoneData.locations) do
            table.insert(allDeliveryLocs, loc)
        end
    end

    local chosenDropoff = allDeliveryLocs[math.random(#allDeliveryLocs)]

    runs[runId] = {
        participants = participants,
        stage = 'vehicle_spawned',
        vehicleNetId = nil,
        vehiclePlate = createPlate(),
        parked = false,
        docsCollected = {},
        dropoff = { x = chosenDropoff.x, y = chosenDropoff.y, z = chosenDropoff.z }
    }

    activeMissions[src] = {
        startTime = GetGameTimer(),
        barrelsLoaded = 0,
        loadedTypes = { barrel_a = 0, barrel_b = 0, barrel_c = 0 },
        runId = runId
    }

    cooldowns[src] = cooldowns[src] or {}
    cooldowns[src].mission = GetGameTimer()

    if Config.Debug then print('[CHEM DEBUG] Mission started for src:', src, 'runId:', runId) end
    Notify(src, 'Mission started! Collect barrels and load them into your truck.', 'success')
    TriggerClientEvent('chem:spawnMissionBarrel', src, Config.LabLocation)
    TriggerClientEvent('chem:sync:startMission', src, runs[runId].dropoff)
end)

RegisterNetEvent("chem:request:finishAtPark")
AddEventHandler("chem:request:finishAtPark", function()

    if Config.Debug then print('[CHEM DEBUG] finishAtPark') end

    local src = source
    local mission = activeMissions[src]

    if not mission then
        if Config.Debug then print("[CHEM DEBUG] STOP — no mission at finish") end
        return
    end

    local ped   = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local lt = mission.loadedTypes

    if lt.barrel_a > 0 or lt.barrel_b > 0 or lt.barrel_c > 0 then
        if Config.Debug then print("[CHEM DEBUG] STOP — truck still has barrels") end
        return Notify(src, "You still have barrels in the truck!", "error")
    end

    if missionBarrelsRemaining(src) then
        if Config.Debug then print("[CHEM DEBUG] STOP — barrels still in world") end
        return Notify(src, "Finish all barrels before returning.", "error")
    end

    if Config.Debug then print("[CHEM DEBUG] PASS — finishing mission and deleting truck") end

    TriggerClientEvent("chem:sync:endMission", src)
    if Config.Debug then print("[CHEM DEBUG] -> sent endMission to client:", src) end

    clearMission(src, "park finished")

    Notify(src, "Truck returned — mission complete!", "success")
end)

RegisterNetEvent('chem:request:pickupBarrel')
AddEventHandler('chem:request:pickupBarrel', function(id)
    local src = source
    if Config.Debug then print('[CHEM DEBUG] pickupBarrel requested by src:', src, 'id:', id) end
    if not activeMissions[src] then
        Notify(src, 'You need to start the mission first.', 'error')
        return
    end
    if cooldowns[src] and cooldowns[src].pickup and GetGameTimer() - cooldowns[src].pickup < Config.Cooldowns.pickup then
        return
    end
    local state = GetBarrelState(id)
    if state.state ~= 'spawned' then
        Notify(src, 'Barrel not available.', 'error')
        return
    end

    cooldowns[src].pickup = GetGameTimer()
    SetBarrelState(id, 'picked', src)
    if Config.Debug then print('[CHEM DEBUG] Barrel picked up: id', id, 'by src:', src) end
    Notify(src, 'Picked up barrel. Load it into your truck.', 'success')
end)

RegisterNetEvent('chem:request:loadBarrel')
AddEventHandler('chem:request:loadBarrel', function(vehicleNetId)
    local src = source
    if Config.Debug then print('[DEBUG] chem:request:loadBarrel triggered by src:', src, 'vehicleNetId:', vehicleNetId) end

    if not activeMissions[src] then
        Notify(src, 'You need to start the mission first.', 'error')
        return
    end

    if cooldowns[src] and cooldowns[src].load and GetGameTimer() - cooldowns[src].load < Config.Cooldowns.load then
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local expectedModel = GetHashKey(Config.TruckSpawn.model)

    if not DoesEntityExist(vehicle) or GetEntityModel(vehicle) ~= expectedModel then
        Notify(src, 'Not near a valid truck.', 'error')
        return
    end

    local carriedId
    for id, data in pairs(barrelStates) do
        if data.state == 'picked' and data.player == src then
            carriedId = id
            break
        end
    end

    if not carriedId then
        Notify(src, 'You are not carrying a barrel.', 'error')
        return
    end

    local barrelType
    if carriedId <= 3 then
        barrelType = 'barrel_a'
    elseif carriedId <= 6 then
        barrelType = 'barrel_b'
    else
        barrelType = 'barrel_c'
    end

    if activeMissions[src].loadedTypes[barrelType] >= 3 then
        Notify(src, 'You have already loaded 3 barrels of this type.', 'error')
        return
    end

    if activeMissions[src].barrelsLoaded >= Config.MaxBarrels then
        Notify(src, 'Truck is full.', 'error')
        return
    end

    activeMissions[src].barrelsLoaded = activeMissions[src].barrelsLoaded + 1
    activeMissions[src].loadedTypes[barrelType] = activeMissions[src].loadedTypes[barrelType] + 1
    syncLoadedTypes(src)
    local slot = activeMissions[src].barrelsLoaded

    SetBarrelState(carriedId, 'loaded', nil, vehicleNetId, slot)
    barrelStates[carriedId].truckSlot = slot
    if Config.Debug then print('[DEBUG] Barrel id:', carriedId, 'loaded into truck slot:', slot) end
    cooldowns[src].load = GetGameTimer()

    TriggerClientEvent('chem:sync:openTruckDoors', -1, vehicleNetId)

    if Config.AutoCloseDoors then
        Citizen.SetTimeout(2000, function()
            TriggerClientEvent('chem:sync:closeTruckDoors', -1, vehicleNetId)
        end)
    end

    local typeCount = activeMissions[src].loadedTypes[barrelType]
    Notify(src, 'Barrel loaded (' .. barrelType .. ': ' .. typeCount .. '/3, Total: ' ..
        activeMissions[src].barrelsLoaded .. '/' .. Config.MaxBarrels .. ')', 'success')
end)

RegisterNetEvent('chem:request:deliver')
AddEventHandler('chem:request:deliver', function()
    local src = source
    if Config.Debug then print('[CHEM DEBUG] deliver requested by src:', src) end

    if not activeMissions[src] then
        return Notify(src, 'You need to start the mission first.', 'error')
    end

    if cooldowns[src] and cooldowns[src].deliver and GetGameTimer() - cooldowns[src].deliver < Config.Cooldowns.deliver then
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))

    ------------------------------------------------
    -- 🔎 which zone is the player in?
    ------------------------------------------------
    local zoneName = getDeliveryTypeAtCoords(playerCoords)
    if not zoneName then
        return Notify(src, 'Not in a delivery zone.', 'error')
    end

    ------------------------------------------------
    -- map zone → barrel type
    ------------------------------------------------
    local zoneMap = {
        barrel_a_delivery = "barrel_a",
        barrel_b_delivery = "barrel_b",
        barrel_c_delivery = "barrel_c"
    }

    local barrelType = zoneMap[zoneName]
    if not barrelType then return end

    local mission = activeMissions[src]
    local have = mission.loadedTypes[barrelType]

    if have <= 0 then
        return Notify(src, 'No barrels of this type on the truck.', 'error')
    end

    mission.loadedTypes[barrelType] = 0
    mission.barrelsLoaded = mission.barrelsLoaded - have

    local reward = Config.DeliveryZone[zoneName].reward
    GiveItem(src, reward, have)

    ResetBarrelsForPlayer(src)
    cooldowns[src].deliver = GetGameTimer()

    if Config.Debug then print('[CHEM DEBUG] Delivered', have, 'barrels of', barrelType, 'for', reward) end
    Notify(src,
        ('Delivered %d barrels → received %d x %s'):format(have, have, reward),
        'success'
    )

    syncLoadedTypes(src)
    tryFinishMission(src)
end)

RegisterNetEvent('chem:request:takeFromTruck')
AddEventHandler('chem:request:takeFromTruck', function(barrelType)
    local src     = source
    local mission = activeMissions[src]

    if Config.Debug then print('[CHEM DEBUG] takeFromTruck triggered | src:', src, '| type:', barrelType) end

    if not mission then
        if Config.Debug then print('[CHEM DEBUG]  -> NO mission for player') end
        return
    end

    if mission.loadedTypes[barrelType] <= 0 then
        if Config.Debug then print('[CHEM DEBUG]  -> mission.loadedTypes shows ZERO for this type') end
        return Notify(src, 'No barrels of this type left in the truck.', 'error')
    end

    local barrelId, slot

    for id, data in pairs(barrelStates) do
        if data.state == 'loaded' and data.type == barrelType then
            barrelId = id
            slot     = data.truckSlot
            break
        end
    end


    if Config.Debug then print('[CHEM DEBUG]  -> found barrelId:', barrelId, '| slot:', slot) end

    if not barrelId or not slot then
        if Config.Debug then print('[CHEM DEBUG]  -> FAILED to find a matching barrel slot!') end
        return Notify(src, 'Could not find that barrel slot.', 'error')
    end

    mission.loadedTypes[barrelType] = mission.loadedTypes[barrelType] - 1
    mission.barrelsLoaded = mission.barrelsLoaded - 1
    syncLoadedTypes(src)

    if Config.Debug then print(string.format(
        '[CHEM DEBUG]  -> updated counts | A:%d B:%d C:%d | total:%d',
        mission.loadedTypes.barrel_a,
        mission.loadedTypes.barrel_b,
        mission.loadedTypes.barrel_c,
        mission.barrelsLoaded
    )) end

    if Config.Debug then print('[CHEM DEBUG]  -> telling client to remove slot:', slot) end
    TriggerClientEvent('chem:sync:removeTruckBarrel', src, slot)

    TriggerClientEvent('chem:sync:carryBarrel', src, barrelType)

    if Config.Debug then print('[CHEM DEBUG]  -> converting barrel to "carried" and resetting world state') end

    SetBarrelState(barrelId, 'reset')
end)



RegisterNetEvent('chem:request:deliverCarry')
AddEventHandler('chem:request:deliverCarry', function(barrelType)
    local src = source
    local mission = activeMissions[src]
    if not mission then return end
    if Config.Debug then print('[CHEM DEBUG] deliverCarry requested by src:', src, 'type:', barrelType) end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local zoneName = getDeliveryTypeAtCoords(playerCoords)
    if not zoneName then
        return Notify(src, 'Not in delivery zone.', 'error')
    end

    local zoneMap = {
        barrel_a_delivery = "barrel_a",
        barrel_b_delivery = "barrel_b",
        barrel_c_delivery = "barrel_c"
    }

    local expected = zoneMap[zoneName]

    if barrelType ~= expected then
        return Notify(src, 'Wrong delivery location for this barrel.', 'error')
    end

    local reward = Config.DeliveryZone[zoneName].reward
    GiveItem(src, reward, 1)

    if Config.Debug then print('[CHEM DEBUG] Delivered carried barrel of', barrelType, 'for', reward) end
    Notify(src, 'Delivered barrel successfully.', 'success')

    tryFinishMission(src)
end)

RegisterNetEvent('chem:request:exchange')
AddEventHandler('chem:request:exchange', function()
    local src = source
    if Config.Debug then print('[CHEM DEBUG] exchange requested by src:', src) end
    if cooldowns[src] and cooldowns[src].exchange and GetGameTimer() - cooldowns[src].exchange < Config.Cooldowns.exchange then
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - Config.ExchangeBot.coords) > 5.0 then
        Notify(src, 'Too far from exchange bot.', 'error')
        return
    end

    local required = {
        [Config.Items.chem_a] = 1,
        [Config.Items.chem_b] = 1,
        [Config.Items.chem_c] = 1
    }

    if not HasItems(src, required) then
        Notify(src, 'Missing required chemicals.', 'error')
        return
    end

    RemoveItem(src, Config.Items.chem_a, 1)
    RemoveItem(src, Config.Items.chem_b, 1)
    RemoveItem(src, Config.Items.chem_c, 1)

    GiveItem(src, Config.Items.proc_a, 1)
    GiveItem(src, Config.Items.proc_b, 1)
    GiveItem(src, Config.Items.proc_c, 1)

    cooldowns[src].exchange = GetGameTimer()
    if Config.Debug then print('[CHEM DEBUG] Exchanged chemicals for processed materials for src:', src) end
    Notify(src, 'Exchanged chemicals for processed materials.', 'success')
end)

RegisterNetEvent('chem:request:mixGunpowder')
AddEventHandler('chem:request:mixGunpowder', function()
    local src = source
    if Config.Debug then print('[CHEM DEBUG] mixGunpowder requested by src:', src) end

    if cooldowns[src] and cooldowns[src].mix and GetGameTimer() - cooldowns[src].mix < Config.Cooldowns.mix then
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))

    if #(playerCoords - Config.LabLocation) > 3.0 then
        Notify(src, 'Not at the lab.', 'error')
        return
    end

    local required = {
        [Config.Items.proc_a] = 1,
        [Config.Items.proc_b] = 1,
        [Config.Items.proc_c] = 1
    }

    if not HasItems(src, required) then
        Notify(src, 'Missing processed materials.', 'error')
        return
    end

    RemoveItem(src, Config.Items.proc_a, 1)
    RemoveItem(src, Config.Items.proc_b, 1)
    RemoveItem(src, Config.Items.proc_c, 1)

    cooldowns[src].mix = GetGameTimer()
    TriggerClientEvent('chem:sync:mixingProgress', src)
    if Config.Debug then print('[CHEM DEBUG] Started mixing gunpowder for src:', src) end
    Notify(src, 'Mixed ' .. amount .. ' gunpowder!', 'success')
end)

RegisterNetEvent('chem:mix:complete')
AddEventHandler('chem:mix:complete', function()
    local src = source

    if not cooldowns[src] then return end

    local amount = Config.LastRewardCount or 3

    GiveItem(src, Config.Items.gunpowder, amount)

    if Config.Debug then print('[CHEM DEBUG] Mixing complete, gave', amount, 'gunpowder to src:', src) end
    Notify(src, 'You finished mixing and received ' .. amount .. ' gunpowder!', 'success')
end)


AddEventHandler('playerDropped', function()
    local src = source
    if activeMissions[src] then
        ResetBarrelsForPlayer(src)
        TriggerClientEvent('chem:sync:endMission', src)
        clearMission(src, "player dropped")
    end
end)

RegisterNetEvent('chem:sync:openTruckDoors')
AddEventHandler('chem:sync:openTruckDoors', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorOpen(vehicle, 2, false, false)
        SetVehicleDoorOpen(vehicle, 3, false, false)
    end
end)

RegisterNetEvent('chem:sync:closeTruckDoors')
AddEventHandler('chem:sync:closeTruckDoors', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, 2, false)
        SetVehicleDoorShut(vehicle, 3, false)
    end
end)

local function tryGiveVehicleKeys(src, plate)
    if type(plate) ~= 'string' or plate == '' then return end
    if Config.Debug then print(('[chem_gunpowder] giving keys %s -> %s'):format(plate, src)) end

    if GetResourceState('qbx_vehiclekeys') == 'started' then
        TriggerClientEvent('qbx_vehiclekeys:client:GiveKeys', src, plate)
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        return
    end

    local candidates = { 'qb-vehiclekeys', 'vehiclekeys' }
    for _, res in ipairs(candidates) do
        if GetResourceState(res) == 'started' then
            local ok = pcall(function()
                exports[res]:GiveKeys(src, plate)
            end)
            if ok then return end
        end
    end
end

RegisterNetEvent('chem:giveKeys')
AddEventHandler('chem:giveKeys', function(plate)
    local src = source
    tryGiveVehicleKeys(src, plate)
end)


RegisterCommand("chemtryfinish", function(source)
    if Config.Debug then print("[CHEM TEST] Running tryFinishMission()") end
    tryFinishMission(source)
end, false)
