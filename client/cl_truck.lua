local function IsOxTargetAvailable()
    return GetResourceState('ox_target') == 'started'
end

-- Helper
function Draw3DText(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end