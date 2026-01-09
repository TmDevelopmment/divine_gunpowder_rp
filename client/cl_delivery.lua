local dropoffCoords = nil
local truckParkZone = nil
local selectedDropoffs = {}
loadedTypes = { barrel_a = 0, barrel_b = 0, barrel_c = 0 }
local deliveryBlips = {}
local showMarker = false
local glowActive = false
local deliveryLabels = {
    barrel_a_delivery = "~INPUT_CONTEXT~ Deliver Barrel A",
    barrel_b_delivery = "~INPUT_CONTEXT~ Deliver Barrel B",
    barrel_c_delivery = "~INPUT_CONTEXT~ Deliver Barrel C"
}

function getDeliveryTypeAtCoords(coords)
    for zoneName, zoneData in pairs(Config.DeliveryZone) do
        for _, loc in ipairs(zoneData.locations) do
            if #(coords - vector3(loc.x, loc.y, loc.z)) <= zoneData.radius then
                return zoneName
            end
        end
    end

    return nil
end

function refreshDeliveryBlips()
    for _, blip in ipairs(deliveryBlips) do
        RemoveBlip(blip)
    end
    deliveryBlips = {}

    for zoneName, loc in pairs(selectedDropoffs) do
        local barrelType =
            zoneName == "barrel_a_delivery" and "barrel_a" or
            zoneName == "barrel_b_delivery" and "barrel_b" or
            "barrel_c"

        if loadedTypes[barrelType] and loadedTypes[barrelType] > 0 then
            local blip = AddBlipForCoord(loc.x, loc.y, loc.z)

            SetBlipSprite(blip, 501)
            SetBlipScale(blip, 0.9)
            SetBlipAsShortRange(blip, false)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Deliver: " .. barrelType)
            EndTextCommandSetBlipName(blip)

            table.insert(deliveryBlips, blip)
        end
    end
end

function setNextWaypoint()
    local closest, closestDist

    for zoneName, loc in pairs(selectedDropoffs) do
        local barrelType =
            zoneName == "barrel_a_delivery" and "barrel_a" or
            zoneName == "barrel_b_delivery" and "barrel_b" or
            "barrel_c"

        if loadedTypes[barrelType] and loadedTypes[barrelType] > 0 then
            local p = GetEntityCoords(PlayerPedId())
            local dist = #(p - vector3(loc.x, loc.y, loc.z))

            if not closest or dist < closestDist then
                closest = loc
                closestDist = dist
            end
        end
    end

    if closest then
        SetNewWaypoint(closest.x, closest.y)
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

function Draw3DTextModern(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz       = table.unpack(GetGameplayCamCoords())

    if onScreen then
        local dist  = #(vector3(px, py, pz) - vector3(x, y, z))
        local scale = (1 / dist) * 1.6
        local fov   = (1 / GetGameplayCamFov()) * 100
        scale       = scale * fov

        SetTextScale(0.0, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextOutline()
        SetTextCentre(true)

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

AddEventHandler('chem:setDropoff', function(coords)
    dropoffCoords = coords
end)

AddEventHandler('chem:clearDropoff', function()
    dropoffCoords = nil
end)

RegisterNetEvent('chem:setSelectedDropoffs')
AddEventHandler('chem:setSelectedDropoffs', function(data)
    selectedDropoffs = data or {}
end)

RegisterNetEvent('chem:refreshDeliveryBlips')
AddEventHandler('chem:refreshDeliveryBlips', function()
    refreshDeliveryBlips()
    setNextWaypoint()
end)

RegisterNetEvent('chem:clearWaypoint')
AddEventHandler('chem:clearWaypoint', function()
    SetWaypointOff()
    ClearGpsMultiRoute()

    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("Waypoint cleared.")
    EndTextCommandDisplayHelp(0, false, true, 3000)
end)

RegisterNetEvent('chem:updateLoadedTypes')
AddEventHandler('chem:updateLoadedTypes', function(data)
    loadedTypes = data or loadedTypes

    if Config.Debug then print('[CHEM DEBUG] client loadedTypes = A:',
        loadedTypes.barrel_a,
        'B:', loadedTypes.barrel_b,
        'C:', loadedTypes.barrel_c
    ) end

    refreshDeliveryBlips()
    setNextWaypoint()
end)


RegisterNetEvent('chem:sync:carryBarrel')
AddEventHandler('chem:sync:carryBarrel', function(barrelType)
    carryingBarrel = true
    carriedType = barrelType

    local ped = PlayerPedId()
    local model = `prop_barrel_01a`

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    carriedObj = CreateObject(model, 0, 0, 0, true, true, false)

    AttachEntityToEntity(
        carriedObj, ped,
        GetPedBoneIndex(ped, 28422),
        0.1, -0.25, -0.05,
        10.0, 10.0, 180.0,
        true, true, false, true, 1, true
    )

    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(0) end
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 51, 0, false, false, false)
end)

RegisterNetEvent('chem:sync:removeTruckBarrel')
AddEventHandler('chem:sync:removeTruckBarrel', function(slot)
    if Config.Debug then print('[CHEM DEBUG] CLIENT removeTruckBarrel | slot:', slot) end

    if not slot then
        if Config.Debug then print('[CHEM DEBUG]  -> slot is NIL, cannot delete') end
        return
    end

    if not TruckBarrels then
        if Config.Debug then print('[CHEM DEBUG]  -> TruckBarrels table missing') end
        return
    end

    local obj = TruckBarrels[slot]

    if Config.Debug then print('[CHEM DEBUG]  -> object at slot:', obj) end

    if obj and DoesEntityExist(obj) then
        if Config.Debug then print('[CHEM DEBUG]  -> deleting object now') end
        DeleteObject(obj)
    else
        if Config.Debug then print('[CHEM DEBUG]  -> object does NOT exist') end
    end

    TruckBarrels[slot] = nil
end)

RegisterNetEvent("chem:request:showParkingLocation")
AddEventHandler("chem:request:showParkingLocation", function()
    if Config.Debug then print("[CHEM] Showing truck park zone") end

    if truckParkZone then return end

    local function shouldReturnTruck(ped, veh)
        return veh
            and veh == missionTruck
            and GetPedInVehicleSeat(veh, -1) == ped
    end

    truckParkZone = lib.zones.box({
        coords   = Config.TruckPark,
        size     = vec3(6.0, 10.0, 4.0),
        rotation = Config.TruckParkHeading or 0,

        debug    = false,

        inside   = function()
            showMarker = true
            glowActive = false


            if not missionTruck or not DoesEntityExist(missionTruck) then
                lib.hideTextUI()
                return
            end

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if shouldReturnTruck(ped, veh) then
                glowActive = true

                lib.showTextUI("[E] Return Truck", {
                    position = "center-right",
                    icon     = "truck",
                })

                if IsControlJustPressed(0, 38) then

                    local success = lib.progressCircle({
                        duration = 5000,
                        label = "Returning truck...",
                        position = "center",
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true
                        }
                    })

                    if success then
                        TriggerServerEvent("chem:request:finishAtPark")
                    else
                        lib.notify({
                            title = "Cancelled",
                            description = "Truck return cancelled",
                            type = "error"
                        })
                    end
                end
            else
                lib.hideTextUI()
            end
        end,

        onExit   = function()
            showMarker = false
            lib.hideTextUI()
        end
    })
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local time   = GetGameTimer() / 1000.0

        for zoneName, loc in pairs(selectedDropoffs) do
            local dist = #(coords - loc)

            -- 🔵 soft animated marker (pulsing)
            if dist < 25.0 then
                local pulse = (math.sin(time * 2.0) + 1.0) * 0.5 -- 0 → 1
                local alpha = 90 + (pulse * 70)                  -- 90–160

                DrawMarker(
                    25, loc.x, loc.y, loc.z - 0.95,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    3.5, 3.5, 1.2,
                    60, 170, 255, 80,
                    false, true, 2, false, nil, nil, false
                )
            end

            if dist < 3.0 then
                -- 📦 zone label (clean floating text)
                local label = deliveryLabels[zoneName]
                if label then
                    Draw3DText(loc.x, loc.y, loc.z + 1.2, ("~b~%s~s~"):format(label))
                end

                -- 🚶 delivery interaction
                if carryingBarrel then
                    local dropType = getDeliveryTypeAtCoords(coords)

                    if dropType then
                        Draw3DText(
                            coords.x,
                            coords.y,
                            coords.z + 1.0,
                            "~INPUT_CONTEXT~ ~g~Deliver Barrel~s~"
                        )

                        if IsControlJustPressed(0, 38) then
                            DeleteObject(carriedObj)
                            carryingBarrel = false
                            ClearPedTasks(ped)

                            TriggerServerEvent("chem:request:deliverCarry", carriedType)
                            carriedType = nil
                        end
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if showMarker and Config.TruckPark then
            local padZ = (Config.TruckPark.z - 0.80)
            local size = vec3(6.0, 10.0, 0.5)

            local min = vector3(
                Config.TruckPark.x - (size.x / 2),
                Config.TruckPark.y - (size.y / 2),
                padZ
            )

            local max = vector3(
                Config.TruckPark.x + (size.x / 2),
                Config.TruckPark.y + (size.y / 2),
                padZ + size.z
            )

            ----------------------------------------------------------------
            -- 🟨 1) YELLOW PAINTED OUTLINE (warehouse-style)
            ----------------------------------------------------------------
            local corners = {
                vector3(min.x, min.y, padZ),
                vector3(max.x, min.y, padZ),
                vector3(max.x, max.y, padZ),
                vector3(min.x, max.y, padZ),
            }

            for i = 1, #corners do
                local a = corners[i]
                local b = corners[(i % #corners) + 1]
                DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 255, 200, 50, 255) -- 🟨 yellow
            end

            ----------------------------------------------------------------
            -- ◢◣ 2) CORNER L-MARKS
            ----------------------------------------------------------------
            local offset = 0.7

            local function cornerLines(x, y)
                DrawLine(x, y, padZ, x + offset, y, padZ, 255, 200, 50, 255)
                DrawLine(x, y, padZ, x, y + offset, padZ, 255, 200, 50, 255)
            end

            cornerLines(min.x, min.y)
            cornerLines(max.x - offset, min.y)
            cornerLines(max.x - offset, max.y - offset)
            cornerLines(min.x, max.y - offset)

            ----------------------------------------------------------------
            -- ▬▬ 3) DASHED CENTER LINE (alignment aid)
            ----------------------------------------------------------------
            local segments = 6
            for i = 1, segments do
                local startY = min.y + ((i - 1) / segments) * (max.y - min.y)
                local endY   = startY + ((max.y - min.y) / segments) * 0.5

                DrawLine(
                    Config.TruckPark.x, startY, padZ,
                    Config.TruckPark.x, endY, padZ,
                    255, 255, 255, 180
                )
            end

            ----------------------------------------------------------------
            -- ✨ 4) SUBTLE GLOW — ONLY if the correct truck is positioned
            ----------------------------------------------------------------
            if glowActive then
                local t = GetGameTimer() / 900.0
                local pulse = (math.sin(t) + 1.0) / 2.0
                local alpha = math.floor(40 + (pulse * 80)) -- gentle 40–120

                DrawBox(
                    min.x, min.y, padZ,
                    max.x, max.y, padZ + size.z,
                    120, 200, 100, alpha -- soft industrial green
                )
            end
        end
    end
end)