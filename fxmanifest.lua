fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name "rzw-jobnotif"
description "rzw-jobnotif adalah notif untuk pekerja whitelist"
author "Rozir Wobari"
version "1.0.0"

ui_page 'ui/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'@rzw-protect/client/cl_guard.lua',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@rzw-protect/server/sv_guard.lua',
	'server/*.lua'
}

files {
    'ui/index.html',
    'ui/*.js',
    'ui/*.css',
    'ui/img/*.png',
}