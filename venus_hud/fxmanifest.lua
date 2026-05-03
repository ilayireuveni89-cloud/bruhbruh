fx_version 'cerulean'
game 'gta5'

author 'VenusZone'
description 'VenusZone | RolePlay IL - Premium Custom HUD'
version '2.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/seatbelt.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/hud.js',
    'html/settings.js'
}

dependencies {
    'es_extended'
}
