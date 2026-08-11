fx_version 'cerulean'
game 'gta5'

author 'Lopestorm'
description 'Trabalho de Investigador de casos - ARG'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/items.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'

dependency 'ox_lib'
