MZInventoryOwnerContract = {}

MZInventoryOwnerContract.VERSION = '2.0.0'

local OWNER_TYPES = {
  character = true,
  vehicle = true,
  property = true,
  organization = true,
  world_drop = true,
  temporary = true
}

local function trim(value)
  return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function positiveInteger(value)
  value = tonumber(value)
  if not value or value <= 0 or value % 1 ~= 0 then return nil end
  return value
end

local function copy(input)
  local output = {}
  for key, value in pairs(input or {}) do output[key] = value end
  return output
end

local function normalizeContainerType(value)
  value = trim(value):lower()
  if value == '' then return nil end
  if #value > 64 or not value:match('^[a-z0-9_%-]+$') then return nil end
  return value
end

local function normalizeOwnerId(value)
  value = trim(value)
  if value == '' or #value > 96 then return nil end
  if value:find('[%z\r\n]') then return nil end
  return value
end

function MZInventoryOwnerContract.getOwnerTypes()
  return copy(OWNER_TYPES)
end

function MZInventoryOwnerContract.normalize(descriptor)
  if type(descriptor) ~= 'table' then return nil, 'invalid_owner_descriptor' end

  local rawOwnerType = trim(descriptor.ownerType or descriptor.owner_type):lower()
  local rawOwnerId = normalizeOwnerId(descriptor.ownerId or descriptor.owner_id)
  local inventoryType = normalizeContainerType(
    descriptor.containerType or descriptor.container_type or descriptor.inventoryType or descriptor.inventory_type
  )
  local containerId = normalizeOwnerId(descriptor.containerId or descriptor.container_id)
  local persistent = descriptor.persistent ~= false

  if rawOwnerType == '' or not rawOwnerId then return nil, 'invalid_owner' end

  local ownerType = rawOwnerType
  local ownerId = rawOwnerId

  if not ownerId or not OWNER_TYPES[ownerType] then return nil, 'invalid_owner_type' end
  if not inventoryType then return nil, 'invalid_container_type' end
  if ownerType == 'temporary' and persistent then return nil, 'temporary_owner_not_persistable' end
  if ownerType ~= 'temporary' and not persistent then return nil, 'persistent_owner_required' end

  if ownerType == 'character' then
    if ownerId:lower():sub(1, 9) == 'personal:' then return nil, 'invalid_character_owner' end
    if #ownerId > 64 then return nil, 'invalid_character_owner' end
  end

  return {
    contractVersion = MZInventoryOwnerContract.VERSION,
    ownerType = ownerType,
    ownerId = ownerId,
    containerType = inventoryType,
    containerId = containerId,
    persistent = persistent
  }
end

function MZInventoryOwnerContract.toCurrentStorage(descriptor)
  local normalized, err = MZInventoryOwnerContract.normalize(descriptor)
  if not normalized then return nil, err end

  if normalized.ownerType == 'temporary' then return nil, 'temporary_owner_not_persistable' end

  return {
    ownerType = normalized.ownerType,
    ownerId = normalized.ownerId,
    inventoryType = normalized.containerType
  }
end

function MZInventoryOwnerContract.resolveCharacterRuntime(source, identity, session, expectedOwnerId)
  source = positiveInteger(source)
  if not source then return nil, 'invalid_source' end
  if type(identity) ~= 'table' or identity.ok ~= true then
    return nil, identity and identity.error or 'identity_unavailable'
  end
  if type(session) ~= 'table' or session.isActive ~= true then return nil, 'session_unavailable' end
  if identity.active ~= true or tostring(session.lifecycle or '') ~= 'CHARACTER_ACTIVE' then
    return nil, 'character_not_active'
  end
  if tonumber(identity.source) ~= source or tonumber(session.source) ~= source then return nil, 'stale_session' end
  if tonumber(identity.sessionId) ~= tonumber(session.sessionId or session.id) then return nil, 'stale_session' end
  if tostring(identity.accountId or '') == ''
      or tostring(identity.accountId) ~= tostring(session.accountId or '') then
    return nil, 'stale_session'
  end
  if not positiveInteger(identity.characterId)
      or tonumber(identity.characterId) ~= tonumber(session.activeCharacterId) then
    return nil, 'stale_session'
  end

  local citizenid = normalizeOwnerId(identity.citizenid)
  if not citizenid then return nil, 'character_identity_unavailable' end
  if session.citizenid ~= nil and trim(session.citizenid) ~= ''
      and trim(session.citizenid) ~= citizenid then
    return nil, 'stale_session'
  end
  if expectedOwnerId ~= nil and trim(expectedOwnerId) ~= citizenid then return nil, 'foreign_owner' end

  return {
    contractVersion = MZInventoryOwnerContract.VERSION,
    ownerType = 'character',
    ownerId = citizenid,
    containerType = 'main',
    persistent = true,
    runtime = {
      source = source,
      sessionId = tonumber(identity.sessionId),
      accountId = identity.accountId,
      characterRowId = tonumber(identity.characterId),
      sessionRevision = tonumber(session.revision)
    }
  }
end
