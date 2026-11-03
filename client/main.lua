MZInventoryClient = MZInventoryClient or {}

local TOGGLE_COMMAND = 'mz_inventory_toggle'
local DEFAULT_KEY = 'I'
local TRUNK_COMMAND = 'mz_inventory_trunk'
local GLOVEBOX_COMMAND = 'mz_inventory_glovebox'

local function canLocalAction(action)
  local ok, allowed = pcall(function()
    return exports['mz_core']:CanLocalPlayerPerformAction(action)
  end)
  return ok and allowed == true
end

local function getCommandPlate(args)
  local rawPlate = type(args) == 'table' and table.concat(args, ' ') or ''
  rawPlate = tostring(rawPlate or ''):gsub('^%s+', ''):gsub('%s+$', '')

  if rawPlate == '' then
    return nil
  end

  return rawPlate
end

local function toggleInventoryView()
  print(('[mz_inventory][client][toggle] is_open=%s'):format(tostring(MZInventoryState.isOpen() == true)))
  if MZInventoryState.isOpen() then
    MZInventoryBridge.closeView()
    return
  end

  if not canLocalAction('inventory.open') then
    MZInventoryClientHelpers.notify('Inventario indisponivel no estado atual.', 'error')
    return
  end

  MZInventoryBridge.openPlayerView()
end

function MZInventoryClient.openVehicleTrunkView(plate)
  if not canLocalAction('storage.use') then return false, 'player_state_blocked' end
  return MZInventoryBridge.openVehicleTrunkView(plate)
end

function MZInventoryClient.openVehicleGloveboxView(plate)
  if not canLocalAction('storage.use') then return false, 'player_state_blocked' end
  return MZInventoryBridge.openVehicleGloveboxView(plate)
end

RegisterCommand(TOGGLE_COMMAND, function()
  toggleInventoryView()
end, false)

RegisterCommand(TRUNK_COMMAND, function(_, args)
  local plate = getCommandPlate(args)
  if not plate then
    MZInventoryClientHelpers.notify('Informe a placa para abrir o porta-malas.', 'error')
    return
  end

  MZInventoryClient.openVehicleTrunkView(plate)
end, false)

RegisterCommand(GLOVEBOX_COMMAND, function(_, args)
  local plate = getCommandPlate(args)
  if not plate then
    MZInventoryClientHelpers.notify('Informe a placa para abrir o porta-luvas.', 'error')
    return
  end

  MZInventoryClient.openVehicleGloveboxView(plate)
end, false)

RegisterKeyMapping(
  TOGGLE_COMMAND,
  'Abrir ou fechar inventario',
  'keyboard',
  DEFAULT_KEY
)

RegisterNetEvent('mz_inventory:client:openVehicleTrunk', function(plate)
  MZInventoryClient.openVehicleTrunkView(plate)
end)

RegisterNetEvent('mz_inventory:client:openVehicleGlovebox', function(plate)
  MZInventoryClient.openVehicleGloveboxView(plate)
end)

RegisterNetEvent('mz_core:client:playerStateSync', function(payload)
  if type(payload) ~= 'table' or type(payload.permissions) ~= 'table' then return end
  if payload.permissions.inventoryBlocked == true and MZInventoryState.isOpen() then
    MZInventoryNUI.forceClose()
  end
end)

RegisterNetEvent('mz_core:client:characterSelectionRequired', function()
  MZInventoryNUI.forceClose()
end)

RegisterNetEvent('mz_core:client:playerLoaded', function()
  if MZInventoryState.isOpen() then MZInventoryNUI.forceClose() end
end)

RegisterNetEvent('mz_inventory:client:itemReceived', function(payload)
  payload = type(payload) == 'table' and payload or {}
  local amount = math.max(tonumber(payload.amount) or 1, 1)
  local itemLabel = tostring(payload.item_label or payload.item or 'item')
  local sourceName = tostring(payload.source_name or 'jogador proximo')

  MZInventoryClientHelpers.notify(
    ('Voce recebeu %sx %s de %s.'):format(amount, itemLabel, sourceName),
    'success'
  )

  if MZInventoryState.isOpen() then
    MZInventoryBridge.refreshCurrentView()
  end
end)

RegisterNetEvent('mz_inventory:client:equipmentChanged', function(payload)
  if MZClient and MZClient.InventoryWeapons and type(MZClient.InventoryWeapons.applyEquipmentSnapshot) == 'function' then
    MZClient.InventoryWeapons.applyEquipmentSnapshot(type(payload) == 'table' and payload.snapshot or nil)
  end
  if MZInventoryState.isOpen() then
    MZInventoryBridge.refreshCurrentView()
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end

  if MZInventoryNUI and MZInventoryNUI.forceClose then
    MZInventoryNUI.forceClose()
  end
end)

local securityPresenceSequence = 0
CreateThread(function()
  while true do
    Wait(15000)
    if GetResourceState('mz_banguard') == 'started' then
      securityPresenceSequence = (securityPresenceSequence + 1) % 2147483647
      TriggerServerEvent(
        'mz_banguard:server:resourceHeartbeat',
        GetCurrentResourceName(),
        'inventory-1',
        securityPresenceSequence
      )
    end
  end
end)
