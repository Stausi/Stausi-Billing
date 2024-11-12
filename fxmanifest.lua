fx_version 'cerulean'
games { 'gta5' }

author 'Stausi'
description 'Stausi Billing'
version 'v1.0.3'
lua54 'yes'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

client_scripts {
	'client/main.lua',
}

shared_scripts {
	'@es_extended/imports.lua',
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
	'locales/*.json',
}

ui_page 'web/build/index.html'
