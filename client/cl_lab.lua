local missionBarrel = nil

RegisterNetEvent('chem:sync:mixingProgress')
AddEventHandler('chem:sync:mixingProgress', function()
    local ped = PlayerPedId()

    ------------------------------------------------
    -- MAIN MIXING ANIMATION
    ------------------------------------------------
    local dict = "amb@world_human_bum_wash@male@low@idle_a"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    TaskPlayAnim(
        ped,
        dict,
        "idle_a",
        8.0, -8.0,
        Config.Cooldowns.mix,
        1,
        0,
        false, false, false
    )

    ------------------------------------------------
    -- 🔥 SMOKE PARTICLE
    ------------------------------------------------
    local ptfxDict = "core"
    local ptfxName = "exp_grd_bzgas_smoke"

    RequestNamedPtfxAsset(ptfxDict)
    while not HasNamedPtfxAssetLoaded(ptfxDict) do Wait(0) end

    UseParticleFxAssetNextCall(ptfxDict)
    local smoke = StartParticleFxLoopedAtCoord(
        ptfxName,
        Config.LabLocation.x,
        Config.LabLocation.y,
        Config.LabLocation.z + 0.9,
        0.0, 0.0, 0.0,
        1.3,
        false, false, false, false
    )

    ------------------------------------------------
    -- 🔊 SOUND LOOP
    ------------------------------------------------
    local soundId = GetSoundId()
    PlaySoundFromCoord(
        soundId,
        "FIRE_LOOP",
        Config.LabLocation.x,
        Config.LabLocation.y,
        Config.LabLocation.z,
        "DLC_HEISTS_BIOLAB_FINALE_SOUNDS",
        false, 0, false
    )

    ------------------------------------------------
    -- 😷 RANDOM COUGH THREAD
    ------------------------------------------------
    local mixing = true
    CreateThread(function()
        local coughDict = "timetable@ron@ig_3_cough"
        RequestAnimDict(coughDict)
        while not HasAnimDictLoaded(coughDict) do Wait(0) end

        while mixing do
            Wait(math.random(3500, 8000))

            if not mixing then break end

            -- 40% probability to cough
            if math.random() < 0.40 then
                TaskPlayAnim(ped, coughDict, "cough", 8.0, -8.0, 2000, 48, 0, false, false, false)
                Wait(1800)

                -- return to mixing animation
                TaskPlayAnim(
                    ped,
                    dict,
                    "idle_a",
                    8.0, -8.0,
                    Config.Cooldowns.mix,
                    1,
                    0,
                    false, false, false
                )
            end
        end
    end)

    ------------------------------------------------
    -- STEP-BASED PROGRESS UI
    ------------------------------------------------
    local steps = {
        { label = "Combining chemicals...", time = 3000 },
        { label = "Heating mixture...",     time = 4000 },
        { label = "Cooling reaction...",    time = 3000 },
        { label = "Grinding powder...",     time = 3000 },
    }

    for _, step in ipairs(steps) do
        if IsOxLibAvailable() and lib and lib.progress then
            lib.progressCircle({
                duration = step.time,
                label = step.label,
                position = 'bottom',
                canCancel = false,
                disable = { move = true, combat = true, car = true }
            })
        else
            ShowProgressBar(step.time / 1000)
        end
    end


    ------------------------------------------------
    -- CLEANUP
    ------------------------------------------------
    print("[CHEM][DEBUG] Cleaning up mixing")
    mixing = false
    ClearPedTasks(ped)

    if smoke then
        StopParticleFxLooped(smoke, 0)
    end
    
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end

    TriggerServerEvent('chem:mix:complete')
end)

RegisterNetEvent('chem:spawnMissionBarrel')
AddEventHandler('chem:spawnMissionBarrel', function(coords)
    SpawnMissionBarrel(coords)
end)

-- Fallback progress
function ShowProgressBar(duration)
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < duration * 1000 do
        Wait(0)
        local progress = (GetGameTimer() - startTime) / (duration * 1000)
        DrawRect(0.5, 0.9, 0.2, 0.02, 0, 0, 0, 200)
        DrawRect(0.5 - 0.1 + (progress * 0.1), 0.9, progress * 0.2, 0.02, 0, 255, 0, 200)
    end
end

-- Helpers
function IsOxLibAvailable()
    return GetResourceState('ox_lib') == 'started'
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

function SpawnMissionBarrel(coords)
    local model = `prop_barrel_02a`

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    if missionBarrel and DoesEntityExist(missionBarrel) then
        DeleteObject(missionBarrel)
    end

    missionBarrel = CreateObject(
        model,
        coords.x, coords.y, coords.z - 1.0,
        true, false, false
    )

    FreezeEntityPosition(missionBarrel, true)
    SetEntityInvincible(missionBarrel, true)

    -- 🔹 attach ox_target
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(missionBarrel, {
            {
                name = 'chem_mix_barrel',
                label = 'Mix Gunpowder',
                icon = 'fas fa-flask',
                distance = 2.0,
                onSelect = function()
                    TriggerServerEvent('chem:request:mixGunpowder')
                end
            }
        })
    end

    return missionBarrel
end
