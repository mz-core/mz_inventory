fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mz_inventory'
author 'Mazus'
description 'Canonical Inventory domain resource'
version '1.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/constants.lua',
  'shared/equipment.lua',
  'shared/utils.lua',
  'shared/items.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/owner_contract.lua',
  'server/core_bridge.lua',
  'server/schema.lua',
  'server/repository.lua',
  'server/world_repository.lua',
  'server/service.lua',
  'server/money.lua',
  'server/police_access.lua',
  'server/exports.lua',
  'server/events.lua',
  'server/commands.lua',
  'server/main.lua'
}

client_scripts {
  'client/state.lua',
  'client/helpers.lua',
  'client/bridge.lua',
  'client/nui.lua',
  'client/third_party.lua',
  'client/exports.lua',
  'client/main.lua',
  'client/target.lua',
  'client/weapons.lua'
}

ui_page 'web/index.html'

files {
  'README.md',
  'web/index.html',
  'web/style.css',
  'web/script.js',
  'web/assets/icons/equipment/*.svg',
  'locales/*.json'
}

dependencies {
  'oxmysql',
  'ox_lib',
  'mz_core',
  'mz_assets'
}
