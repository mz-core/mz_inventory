-- Registro das interacoes de target owned pelo mz_inventory.
-- O mz_target apenas detecta e despacha. Drops, itens, UID/metadata e as
-- validacoes de transferencia continuam no service server-side do inventory.
local localeName = tostring(GetConvar('ox:locale', '')):lower()
if localeName == '' or localeName == 'pt' then localeName = 'pt-br' end
if type(lib) == 'table' and type(lib.locale) == 'function' then
  lib.locale(localeName)
end

local function L(key)
  if type(locale) == 'function' then
    local value = locale(key)
    if type(value) == 'string' and value ~= key then return value end
  end
  return key
end

local BAG_OPEN_DISTANCE = 3.0
local VEHICLE_OPEN_DISTANCE = 3.0
local GLOVEBOX_BONES = { 'door_dside_f', 'door_pside_f', 'seat_dside_f', 'seat_pside_f' }
local FALLBACK_BAG_MODELS = { 'bkr_prop_duffel_bag_01a', 'prop_cs_heist_bag_02' }

local bagModels = {}
local registerGeneration = 0

local function trim(value)
  return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function getDistance(left, right)
  local dx = (tonumber(left.x) or 0) - (tonumber(right.x) or 0)
  local dy = (tonumber(left.y) or 0) - (tonumber(right.y) or 0)
  local dz = (tonumber(left.z) or 0) - (tonumber(right.z) or 0)
  return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function targetStarted()
  return GetResourceState('mz_target') == 'started'
end

local function isEntityOfType(entity, expectedType)
  entity = tonumber(entity)
  if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
  if GetEntityType(entity) ~= expectedType then return nil end
  return entity
end

local function playerDistance(entity)
  local ped = PlayerPedId()
  if not ped or ped == 0 then return math.huge end
  return getDistance(GetEntityCoords(ped), GetEntityCoords(entity))
end

-- The lookup is read-only and only succeeds for the exact prop that mz_target
-- created for a real drop record. A map prop with the same model returns nil.
local function dropUidFor(entity)
  if not targetStarted() then return nil end
  local ok, dropUid = pcall(function()
    return exports['mz_target']:GetWorldDropByEntity(entity)
  end)
  if not ok or type(dropUid) ~= 'string' or dropUid == '' then return nil end
  return dropUid
end

local function bagCanInteract(entity, distance)
  if not isEntityOfType(entity, 3) then return false end
  if (tonumber(distance) or playerDistance(entity)) > BAG_OPEN_DISTANCE then return false end
  return dropUidFor(entity) ~= nil
end

local function openBag(entity)
  if not bagCanInteract(entity) then return false end
  local dropUid = dropUidFor(entity)
  if not dropUid then return false end

  local ok, opened = pcall(function()
    return MZInventoryBridge.openTargetView({
      type = 'drop',
      drop_uid = dropUid
    })
  end)
  return ok and opened ~= false
end

local function vehiclePlate(entity)
  entity = isEntityOfType(entity, 2)
  if not entity then return nil end
  local plate = trim(GetVehicleNumberPlateText(entity)):upper()
  return plate ~= '' and plate or nil
end

local function vehicleCanInteract(entity, distance)
  if not vehiclePlate(entity) then return false end
  return (tonumber(distance) or playerDistance(entity)) <= VEHICLE_OPEN_DISTANCE
end

local function openVehicleSection(section, entity)
  -- The target option already gated the distance. The inventory server keeps
  -- validating plate/vehicle access for the container itself.
  local plate = vehiclePlate(entity)
  if not plate then return false end

  local ok, opened = pcall(function()
    if section == 'trunk' then
      return MZInventoryClient.openVehicleTrunkView(plate)
    end
    return MZInventoryClient.openVehicleGloveboxView(plate)
  end)
  return ok and opened ~= false
end

local function getBagModels()
  if not targetStarted() then return {} end
  local ok, models = pcall(function()
    return exports['mz_target']:GetWorldDropModels()
  end)
  if ok and type(models) == 'table' and #models > 0 then return models end
  return FALLBACK_BAG_MODELS
end

local function removeTargetOptions()
  if not targetStarted() then return end

  local bagLabel = L('target.open_bag')
  local trunkLabel = L('target.open_trunk')
  local gloveboxLabel = L('target.open_glovebox')

  pcall(function()
    exports['mz_target']:RemoveTargetModel(bagModels, bagLabel)
  end)
  pcall(function()
    exports['mz_target']:RemoveTargetBone('boot', trunkLabel)
  end)
  pcall(function()
    exports['mz_target']:RemoveTargetBone(GLOVEBOX_BONES, gloveboxLabel)
  end)
end

local function registerTarget()
  if not targetStarted() then return false end
  if type(MZInventoryBridge) ~= 'table' or type(MZInventoryClient) ~= 'table' then return false end

  bagModels = getBagModels()
  removeTargetOptions()

  local bagOk, bagErr = pcall(function()
    exports['mz_target']:AddTargetModel(bagModels, {
      distance = BAG_OPEN_DISTANCE,
      options = {
        {
          label = L('target.open_bag'),
          icon = 'package-open',
          distance = BAG_OPEN_DISTANCE,
          canInteract = bagCanInteract,
          action = openBag
        }
      }
    })
  end)

  local trunkOk, trunkErr = pcall(function()
    exports['mz_target']:AddTargetBone('boot', {
      distance = VEHICLE_OPEN_DISTANCE,
      options = {
        {
          label = L('target.open_trunk'),
          icon = 'briefcase',
          distance = VEHICLE_OPEN_DISTANCE,
          canInteract = vehicleCanInteract,
          action = function(entity) return openVehicleSection('trunk', entity) end
        }
      }
    })
  end)

  local gloveboxOk, gloveboxErr = pcall(function()
    exports['mz_target']:AddTargetBone(GLOVEBOX_BONES, {
      distance = VEHICLE_OPEN_DISTANCE,
      options = {
        {
          label = L('target.open_glovebox'),
          icon = 'archive',
          distance = VEHICLE_OPEN_DISTANCE,
          canInteract = vehicleCanInteract,
          action = function(entity) return openVehicleSection('glovebox', entity) end
        }
      }
    })
  end)

  if not bagOk or not trunkOk or not gloveboxOk then
    print(('[mz_inventory][target] register failed bag=%s trunk=%s glovebox=%s'):format(
      tostring(bagOk and 'ok' or bagErr),
      tostring(trunkOk and 'ok' or trunkErr),
      tostring(gloveboxOk and 'ok' or gloveboxErr)
    ))
  end

  return bagOk and trunkOk and gloveboxOk
end

local function requestRegister(delay)
  registerGeneration = registerGeneration + 1
  local generation = registerGeneration

  CreateThread(function()
    Wait(delay or 500)
    if generation ~= registerGeneration then return end

    if registerTarget() then return end

    Wait(1000)
    if generation == registerGeneration then
      registerTarget()
    end
  end)
end

MZInventoryTarget = {
  Register = registerTarget,
  Unregister = function()
    registerGeneration = registerGeneration + 1
    removeTargetOptions()
  end
}

requestRegister(1000)

AddEventHandler('onClientResourceStart', function(resourceName)
  if resourceName == 'mz_target' or resourceName == GetCurrentResourceName() then
    requestRegister(500)
  end
end)

AddEventHandler('mz_target:client:ready', function()
  requestRegister(0)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
  if resourceName == 'mz_target' then
    bagModels = {}
    return
  end

  if resourceName == GetCurrentResourceName() then
    registerGeneration = registerGeneration + 1
    removeTargetOptions()
  end
end)
