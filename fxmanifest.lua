fx_version 'cerulean'
game 'gta5'

author 'Fabio'
description 'Criminal Investigator ARG Job'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'
