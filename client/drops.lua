-- MZ world-drop presentation.
-- The inventory owns the local presentation and exact drop-to-entity mapping.
local DropConfig = Config.Inventory.worldDropPresentation

MZInventoryDrops = MZInventoryDrops or {}

local DROP_MODEL = joaat(DropConfig.prop_model)
local DROP_FALLBACK_MODEL = joaat(DropConfig.fallback_prop_model)
local DropEntries = {}
local DropUidByEntity = {}
local DropSyncInFlight = false
local PlayerPedId = PlayerPedId

local function trim(value)
  return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function getDistance(left, right)
  local dx = (tonumber(left.x) or 0) - (tonumber(right.x) or 0)
  local dy = (tonumber(left.y) or 0) - (tonumber(right.y) or 0)
  local dz = (tonumber(left.z) or 0) - (tonumber(right.z) or 0)
  return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function requestModel(modelHash)
  if not IsModelInCdimage(modelHash) then return false end
  RequestModel(modelHash)
  local deadline = GetGameTimer() + 5000
  while not HasModelLoaded(modelHash) do
    if GetGameTimer() >= deadline then return false end
    Wait(0)
  end
  return true
end

local function destroyDropEntity(entry)
  if type(entry) ~= 'table' then return end
  local entity = entry.entity
  if entity and DoesEntityExist(entity) then
    DropUidByEntity[entity] = nil
    DeleteEntity(entity)
  end
  entry.entity = nil
end

local function resolveDropSpawnCoords(entry)
  local x = tonumber(entry.x) or 0
  local y = tonumber(entry.y) or 0
  local z = tonumber(entry.z) or 0
  local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 3.0, false)

  if foundGround == true then
    z = tonumber(groundZ) or z
  end

  return x, y, z
end

local function ensureDropEntity(entry)
  if type(entry) ~= 'table' then return false end

  local spawnX, spawnY, spawnZ = resolveDropSpawnCoords(entry)

  if entry.entity and DoesEntityExist(entry.entity) then
    DropUidByEntity[entry.entity] = entry.drop_uid
    return true
  end

  local preferred = entry.prop_model and joaat(entry.prop_model) or DROP_MODEL
  local model = requestModel(preferred) and preferred or nil
  if not model and preferred ~= DROP_MODEL then
    model = requestModel(DROP_MODEL) and DROP_MODEL or nil
  end
  if not model and DROP_FALLBACK_MODEL ~= DROP_MODEL and requestModel(DROP_FALLBACK_MODEL) then
    model = DROP_FALLBACK_MODEL
  end
  if not model then return false end

  local isWeapon = entry.prop_model ~= nil and model == preferred
  local entity = CreateObjectNoOffset(model, spawnX, spawnY, spawnZ + (isWeapon and 0.25 or 0.0), false, false, false)
  if not entity or entity == 0 then return false end

  SetEntityAsMissionEntity(entity, true, true)
  SetEntityCollision(entity, true, true)
  SetEntityCanBeDamaged(entity, false)
  SetEntityInvincible(entity, true)
  SetEntityHeading(entity, tonumber(DropConfig.heading_offset) or 0.0)
  entry.entity = entity
  entry.entityModel = model
  entry.weaponProp = isWeapon
  DropUidByEntity[entity] = entry.drop_uid
  if isWeapon then
    SetEntityDynamic(entity, true)
    ActivatePhysics(entity)
    CreateThread(function()
      for attempt = 1, 20 do
        Wait(100)
        if entry.entity ~= entity or not DoesEntityExist(entity) then return end
        if attempt >= 5 and GetEntitySpeed(entity) < 0.04 then break end
      end
      if entry.entity == entity and DoesEntityExist(entity) then
        FreezeEntityPosition(entity, true)
      end
    end)
  else
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
  end
  SetModelAsNoLongerNeeded(model)
  return true
end

local function updateDropStreaming(entry, playerCoords)
  if type(entry) ~= 'table' then return end

  local streamDistance = tonumber(DropConfig.stream_distance) or 120.0
  local dropCoords = vec3(tonumber(entry.x) or 0, tonumber(entry.y) or 0, tonumber(entry.z) or 0)

  if getDistance(playerCoords, dropCoords) <= streamDistance then
    ensureDropEntity(entry)
  else
    destroyDropEntity(entry)
  end
end

local function sanitizeDrop(drop)
  if type(drop) ~= 'table' then return nil end
  local dropUid = trim(drop.drop_uid)
  if dropUid == '' then return nil end

  return {
    drop_uid = dropUid,
    label = trim(drop.label) ~= '' and trim(drop.label) or 'Drop',
    x = tonumber(drop.x) or 0,
    y = tonumber(drop.y) or 0,
    z = tonumber(drop.z) or 0,
    backpack_uid = type(drop.metadata) == 'table' and trim(drop.metadata.backpack_instance_uid) or '',
    prop_model = type(drop.prop_model) == 'string' and drop.prop_model:match('^[%w_]+$') or nil
  }
end

local function upsertDrop(drop)
  local sanitized = sanitizeDrop(drop)
  if not sanitized then return end

  local existing = DropEntries[sanitized.drop_uid] or {}
  if existing.prop_model ~= sanitized.prop_model or existing.x ~= sanitized.x
    or existing.y ~= sanitized.y or existing.z ~= sanitized.z then destroyDropEntity(existing) end
  existing.drop_uid = sanitized.drop_uid
  existing.label = sanitized.label
  existing.x = sanitized.x
  existing.y = sanitized.y
  existing.z = sanitized.z
  existing.backpack_uid = sanitized.backpack_uid
  existing.prop_model = sanitized.prop_model
  DropEntries[sanitized.drop_uid] = existing
  updateDropStreaming(existing, GetEntityCoords(PlayerPedId()))
end

local function removeDrop(dropUid)
  dropUid = trim(dropUid)
  if dropUid == '' then return end
  local entry = DropEntries[dropUid]
  if not entry then return end
  destroyDropEntity(entry)
  DropEntries[dropUid] = nil
end

local function syncWorldDrops()
  if type(lib) ~= 'table' or type(lib.callback) ~= 'table' or type(lib.callback.await) ~= 'function' then
    return false
  end

  local response = lib.callback.await('mz_inventory:server:getWorldDrops', false)
  if type(response) ~= 'table' or response.ok ~= true then return false end

  local seen = {}
  for _, drop in ipairs(response.drops or {}) do
    local dropUid = trim(type(drop) == 'table' and drop.drop_uid or '')
    if dropUid ~= '' then
      seen[dropUid] = true
      upsertDrop(drop)
    end
  end

  for dropUid in pairs(DropEntries) do
    if not seen[dropUid] then removeDrop(dropUid) end
  end

  return true
end

local function requestWorldDropSync()
  if DropSyncInFlight then return false end
  DropSyncInFlight = true
  local ok, synced = pcall(syncWorldDrops)
  DropSyncInFlight = false
  return ok == true and synced == true
end

-- Public read-only lookup used by mz_inventory/client/target.lua. It only
-- returns a UID when the exact entity is the prop mz_inventory created for that
-- real drop record.
function MZInventoryDrops.GetDropUid(entity)
  entity = tonumber(entity)
  if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end

  local dropUid = DropUidByEntity[entity]
  if not dropUid then return nil end

  local entry = DropEntries[dropUid]
  if not entry or entry.entity ~= entity then
    DropUidByEntity[entity] = nil
    return nil
  end

  local model = GetEntityModel(entity)
  if model ~= entry.entityModel then
    DropUidByEntity[entity] = nil
    return nil
  end

  return dropUid
end

function MZInventoryDrops.GetDrop(entity)
  local dropUid = MZInventoryDrops.GetDropUid(entity)
  if not dropUid then return nil end
  return DropEntries[dropUid]
end

function MZInventoryDrops.GetModels()
  return { DropConfig.prop_model, DropConfig.fallback_prop_model }
end

function MZInventoryDrops.GetBackpackUid(entity)
  local entry = MZInventoryDrops.GetDrop(entity)
  return entry and entry.backpack_uid ~= '' and entry.backpack_uid or nil
end

function MZInventoryDrops.GetStreamedDrops()
  local drops = {}
  for uid, entry in pairs(DropEntries) do
    if entry.entity and MZInventoryDrops.GetDropUid(entry.entity) == uid then
      drops[#drops + 1] = { drop_uid = uid, entity = entry.entity, backpack_uid = entry.backpack_uid }
    end
  end
  return drops
end

exports('GetWorldDropByEntity', MZInventoryDrops.GetDropUid)
exports('GetWorldDropModels', MZInventoryDrops.GetModels)
exports('GetWorldDropBackpack', MZInventoryDrops.GetBackpackUid)
exports('GetStreamedWorldDrops', MZInventoryDrops.GetStreamedDrops)

RegisterNetEvent('mz_inventory:client:worldDropUpserted', upsertDrop)
RegisterNetEvent('mz_inventory:client:worldDropRemoved', removeDrop)

CreateThread(function()
  local attempts = 0
  while attempts < 10 do
    Wait(attempts == 0 and 500 or 1500)
    if requestWorldDropSync() then return end
    attempts = attempts + 1
  end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
  if resourceName ~= 'mz_inventory' then return end
  CreateThread(function()
    Wait(1000)
    for _ = 1, 5 do
      if requestWorldDropSync() then return end
      Wait(1500)
    end
  end)
end)

RegisterNetEvent('mz_core:client:playerLoaded', function()
  CreateThread(function()
    Wait(1500)
    requestWorldDropSync()
  end)
end)

CreateThread(function()
  while true do
    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, entry in pairs(DropEntries) do
      updateDropStreaming(entry, playerCoords)
    end
    Wait(1000)
  end
end)

CreateThread(function()
  while true do
    local phase = GetGameTimer() % 6500
    local intensity = phase < 450 and math.sin(phase / 450 * math.pi) or 0
    local active = false
    if intensity > 0 and not IsPauseMenuActive() then
      local playerCoords = GetEntityCoords(PlayerPedId())
      for _, entry in pairs(DropEntries) do
        if entry.weaponProp and entry.entity and DoesEntityExist(entry.entity) then
          local coords = GetEntityCoords(entry.entity)
          if getDistance(playerCoords, coords) <= 8.0 then
            DrawLightWithRange(coords.x, coords.y, coords.z + 0.05, 235, 245, 255, 0.35, intensity * 0.15)
            active = true
          end
        end
      end
    end
    Wait(active and 0 or 100)
  end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  for dropUid in pairs(DropEntries) do
    removeDrop(dropUid)
  end
end)
