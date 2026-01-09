-- Sync barrel states
barrelStates = {} -- id -> { state = 'spawned'|'picked'|'loaded', player, vehicleNetId, slot }

-- Initialize barrels
Citizen.CreateThread(function()
    for i = 1, 9 do -- 9 barrels total
        barrelStates[i] = { state = 'spawned' }
    end
end)

-- Sync to all clients on join
AddEventHandler('playerJoining', function()
    for id, data in pairs(barrelStates) do
        TriggerClientEvent('chem:sync:barrelState', -1, id, data.state, data.player, data.vehicleNetId, data.slot)
    end
end)

-- Reset barrels on mission end or disconnect
function ResetBarrelsForPlayer(src)
    for id, data in pairs(barrelStates) do
        if data.player == src then
            barrelStates[id] = { state = 'spawned' }
            TriggerClientEvent('chem:sync:barrelState', -1, id, 'reset')
        end
    end
end

-- Get barrel state
function GetBarrelState(id)
    return barrelStates[id]
end

-- Set barrel state
function SetBarrelState(id, state, player, vehicleNetId, slot)
    barrelStates[id] = barrelStates[id] or {}

    barrelStates[id].state      = state
    barrelStates[id].player     = player or nil
    barrelStates[id].vehicle    = vehicleNetId or nil
    barrelStates[id].truckSlot  = slot or nil

    -- ensure the barrel type exists
    if not barrelStates[id].type then
        if id <= 3 then
            barrelStates[id].type = 'barrel_a'
        elseif id <= 6 then
            barrelStates[id].type = 'barrel_b'
        else
            barrelStates[id].type = 'barrel_c'
        end
    end

    TriggerClientEvent('chem:sync:barrelState', -1, id, state, player, vehicleNetId, slot)
end