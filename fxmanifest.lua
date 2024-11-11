fx_version 'cerulean'
games { 'gta5' }

author 'Stausi'
description 'Stausi Billing'
version '1.0.0'
lua54 'yes'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

client_scripts {
	'client/main.lua',
}

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
}

dependencies {
	'es_extended'
}

escrow_ignore {
    'config.lua',
    'server/*.lua',
}

files {
    "web/build/**/*",
}

ui_page 'web/build/index.html'
