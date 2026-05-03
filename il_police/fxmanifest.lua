fx_version 'cerulean'
game 'gta5'

author 'IL Police Resource'
description 'משטרת ישראל - Israeli Police Resource for ESX'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/radial.lua',
    'client/f6menu.lua',
    'client/mdt.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/mdt.css',
    'html/mdt.js',
    'html/radial.css',
    'html/radial.js',
    'html/f6menu.css',
    'html/f6menu.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}

lua54 'yes'
