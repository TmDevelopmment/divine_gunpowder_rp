local ox_inventory = GetResourceState('ox_inventory') == 'started'
local qb_core = GetResourceState('qb-core') == 'started'
local qbx_core = GetResourceState('qbx-core') == 'started'
local esx = GetResourceState('es_extended') == 'started'

function GiveItem(src, item, amount)
    if ox_inventory then
        return exports.ox_inventory:AddItem(src, item, amount)
    elseif qbx_core or qb_core then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
            return true
        end
    elseif esx then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(item, amount)
            return true
        end
    else
        print(('FALLBACK: Give %s x%d to player %d'):format(item, amount, src))
        return false
    end
end

function RemoveItem(src, item, amount)
    if ox_inventory then
        return exports.ox_inventory:RemoveItem(src, item, amount)
    elseif qbx_core or qb_core then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')
            return true
        end
    elseif esx then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeInventoryItem(item, amount)
            return true
        end
    else
        -- Fallback: debug print
        print(('FALLBACK: Remove %s x%d from player %d'):format(item, amount, src))
        -- TODO: Wire your custom inventory API here
        return false
    end
end

function HasItems(src, requiredItems)
    if ox_inventory then
        for item, count in pairs(requiredItems) do
            if exports.ox_inventory:GetItemCount(src, item) < count then
                return false
            end
        end
        return true
    elseif qbx_core or qb_core then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            for item, count in pairs(requiredItems) do
                if Player.Functions.GetItemByName(item).amount < count then
                    return false
                end
            end
            return true
        end
    elseif esx then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            for item, count in pairs(requiredItems) do
                if xPlayer.getInventoryItem(item).count < count then
                    return false
                end
            end
            return true
        end
    else
        -- Fallback: assume has items
        print(('FALLBACK: Check items for player %d'):format(src))
        -- TODO: Wire your custom inventory API here
        return true
    end
end

function Notify(src, message, type)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Chemical Job', description = message, type = type or 'info' })
    elseif qbx_core or qb_core then
        TriggerClientEvent('QBCore:Notify', src, message, type or 'primary')
    elseif esx then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Chemical Job', message } })
    end
end

if qb_core or qbx_core then
    QBCore = exports['qb-core']:GetCoreObject()
elseif esx then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end