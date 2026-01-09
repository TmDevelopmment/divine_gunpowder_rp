fx_version 'cerulean'
game 'gta5'

author 'DivineRP'
description 'Chemical Gunpowder Mission Resource'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/items.lua',
    'config/config.lua'
}

client_scripts {
    'client/cl_*.lua'
}

server_scripts {
    'server/sv_*.lua'
}

dependencies {
    'ox_lib',
    'ox_target'
    -- Auto-detects frameworks: ESX, QBCore, QBX, ox_inventory, ox_lib
}