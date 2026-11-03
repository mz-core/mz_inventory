MZInventoryPoliceAccess = {}

local grants = {}
local readSessions = {}
local readSequence = 0
local terminals = {}
local stackLocators = {}
local PURPOSES = { search = true, seizure = true }
local DESTINATION_KEYS = { type = true, orgCode = true, containerId = true }

local function settings()
  return Config and Config.Inventory and Config.Inventory.policeAccess or {}
end

local function trim(value)
  return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function copy(value)
  if type(value) ~= 'table' then return value end
  local out = {}
  for key, item in pairs(value) do out[key] = copy(item) end
  return out
end

local function allowedResource(resource)
  for _, candidate in ipairs(type(settings().writers) == 'table' and settings().writers or {}) do
    if candidate == resource then return true end
  end
  return false
end

local function coordsFor(source)
  if type(GetPlayerPed) ~= 'function' or type(GetEntityCoords) ~= 'function' then return nil end
  local ped = GetPlayerPed(source)
  if not ped or ped == 0 or (type(DoesEntityExist) == 'function' and not DoesEntityExist(ped)) then return nil end
  local coords = GetEntityCoords(ped)
  if not coords then return nil end
  local x, y, z = tonumber(coords.x or coords[1]), tonumber(coords.y or coords[2]), tonumber(coords.z or coords[3])
  if not x or not y or not z then return nil end
  return { x = x, y = y, z = z }
end

local function near(leftSource, rightSource)
  if type(GetPlayerRoutingBucket) == 'function'
    and tonumber(GetPlayerRoutingBucket(leftSource)) ~= tonumber(GetPlayerRoutingBucket(rightSource)) then
    return false, 'routing_bucket_mismatch'
  end
  local left, right = coordsFor(leftSource), coordsFor(rightSource)
  if not left or not right then return false, 'position_unavailable' end
  local dx, dy, dz = left.x - right.x, left.y - right.y, left.z - right.z
  local maximum = tonumber(settings().maximumDistance) or 3.0
  if dx * dx + dy * dy + dz * dz > maximum * maximum then return false, 'target_too_far' end
  return true
end

local function identitySnapshot(source)
  local identity, err = MZInventoryCoreBridge.resolveIdentity(source)
  if not identity then return nil, err end
  local snapshot = {
    source = tonumber(identity.source),
    accountId = tonumber(identity.accountId or identity.account_id),
    characterId = tonumber(identity.characterId or identity.character_id),
    sessionId = tonumber(identity.sessionId or identity.session_id),
    citizenid = tostring(identity.citizenid or '')
  }
  if snapshot.source ~= tonumber(source) or not snapshot.accountId or snapshot.accountId <= 0
    or not snapshot.characterId or snapshot.characterId <= 0
    or not snapshot.sessionId or snapshot.sessionId <= 0 or snapshot.citizenid == '' then
    return nil, 'identity_inconsistent'
  end
  return snapshot
end

local function sameIdentity(expected)
  local current = identitySnapshot(expected.source)
  return current and current.source == expected.source
    and current.accountId == expected.accountId
    and current.characterId == expected.characterId
    and current.sessionId == expected.sessionId
    and current.citizenid == expected.citizenid
end

local function cleanup()
  local now = os.time()
  for token, session in pairs(readSessions) do
    if now >= session.expiresAt then readSessions[token] = nil end
  end
  for token, grant in pairs(grants) do
    if now >= grant.expiresAt then grants[token] = nil end
  end
  for operationId, terminal in pairs(terminals) do
    if now >= terminal.expiresAt then terminals[operationId] = nil end
  end
  for locator, entry in pairs(stackLocators) do
    if now >= entry.expiresAt then stackLocators[locator] = nil end
  end
end

local function authorizeRead(actorSource, targetSource, mode)
  if GetResourceState('mz_police') ~= 'started' then return nil, 'police_unavailable' end
  local ok, allowed, context = pcall(function()
    return exports['mz_police']:AuthorizeThirdPartyInventoryRead(actorSource, targetSource, mode)
  end)
  if not ok then return nil, 'authorization_unavailable' end
  if allowed ~= true then return nil, context or 'access_denied' end
  return context
end

function MZInventoryPoliceAccess.createReadSession(actorSource, targetSource, mode, invokingResource)
  if invokingResource ~= 'mz_police' or not allowedResource(invokingResource) then
    return false, 'resource_not_authorized'
  end
  actorSource, targetSource = tonumber(actorSource), tonumber(targetSource)
  if not actorSource or not targetSource or actorSource <= 0 or targetSource <= 0
    or actorSource == targetSource then return false, 'invalid_source' end
  if mode ~= 'police_search' and mode ~= 'civil_robbery' then return false, 'invalid_mode' end
  cleanup()
  local actor, actorError = identitySnapshot(actorSource)
  if not actor then return false, actorError end
  local target, targetError = identitySnapshot(targetSource)
  if not target then return false, targetError end
  local close, distanceError = near(actorSource, targetSource)
  if not close then return false, distanceError end
  local actorAllowed, actorState = MZInventoryCoreBridge.canPerformAction(actorSource, 'inventory.open')
  if not actorAllowed or type(actorState) ~= 'table' or actorState.allowed ~= true then
    return false, 'player_state_blocked'
  end
  local context, authorizationError = authorizeRead(actorSource, targetSource, mode)
  if not context then return false, authorizationError end
  readSequence = readSequence + 1
  local sessionToken = ('read:%08x%08x%08x%08x:%x'):format(
    math.random(0, 0x7fffffff), math.random(0, 0x7fffffff),
    math.random(0, 0x7fffffff), math.random(0, 0x7fffffff), readSequence)
  readSessions[sessionToken] = {
    actor = actor, target = target, mode = mode, context = copy(context),
    permissions = { read = true, transfer = false },
    expiresAt = os.time() + 30
  }
  MZInventoryCoreBridge.log('third_party_inventory_read_created', {
    actor = { type = 'character', id = actor.citizenid },
    target = { type = 'character', id = target.citizenid },
    meta = { mode = mode, condition = context.condition, expiresAt = readSessions[sessionToken].expiresAt }
  })
  return true, { token = sessionToken, mode = mode,
    permissions = copy(readSessions[sessionToken].permissions), expiresAt = readSessions[sessionToken].expiresAt }
end

local function validateReadSession(actorSource, sessionToken, invokingResource)
  cleanup()
  sessionToken = trim(sessionToken)
  if invokingResource ~= 'mz_police' or not allowedResource(invokingResource) then
    return nil, 'resource_not_authorized'
  end
  local session = readSessions[trim(sessionToken)]
  if not session then return nil, 'session_not_found' end
  if tonumber(actorSource) ~= session.actor.source then return nil, 'session_actor_mismatch' end
  if not sameIdentity(session.actor) or not sameIdentity(session.target) then
    readSessions[sessionToken] = nil
    return nil, 'session_identity_changed'
  end
  local close, distanceError = near(session.actor.source, session.target.source)
  if not close then readSessions[sessionToken] = nil; return nil, distanceError end
  local actorAllowed, actorState = MZInventoryCoreBridge.canPerformAction(actorSource, 'inventory.open')
  if not actorAllowed or type(actorState) ~= 'table' or actorState.allowed ~= true then
    readSessions[sessionToken] = nil
    return nil, 'player_state_blocked'
  end
  local context, authorizationError = authorizeRead(actorSource, session.target.source, session.mode)
  if not context then readSessions[sessionToken] = nil; return nil, authorizationError end
  if context.condition ~= session.context.condition
    or context.organization ~= session.context.organization then
    readSessions[sessionToken] = nil
    return nil, 'session_context_changed'
  end
  return session
end

function MZInventoryPoliceAccess.readSessionSnapshot(actorSource, sessionToken, invokingResource)
  local session, err = validateReadSession(actorSource, sessionToken, invokingResource)
  if not session then return false, err end
  if session.permissions.read ~= true then return false, 'read_not_authorized' end
  local ok, snapshot = MZInventoryService.getRestrictedPlayerInventorySnapshot(session.target.source)
  if not ok then return false, snapshot end
  local stillValid, validationError = validateReadSession(actorSource, sessionToken, invokingResource)
  if not stillValid then return false, validationError end
  return true, { mode = session.mode, targetSource = session.target.source,
    targetCitizenid = session.target.citizenid, inventory = snapshot }
end

function MZInventoryPoliceAccess.transferReadSessionItem(actorSource, sessionToken, fromSlot, amount, toSlot, invokingResource)
  local session, err = validateReadSession(actorSource, sessionToken, invokingResource)
  if not session then return false, err end
  if session.mode ~= 'civil_robbery' then return false, 'session_mode_denied' end
  local ok, result = MZInventoryService.transferThirdPartyPlayerItem(
    session.actor.source, session.target.source, fromSlot, amount, toSlot, function()
      local current, validationError = validateReadSession(actorSource, sessionToken, invokingResource)
      if not current then return false, validationError end
      if current.mode ~= 'civil_robbery' then return false, 'session_mode_denied' end
      return true
    end
  )
  if ok then
    MZInventoryCoreBridge.log('civil_robbery_item_transferred', {
      actor = { type = 'character', id = session.actor.citizenid },
      target = { type = 'character', id = session.target.citizenid },
      meta = { fromSlot = tonumber(fromSlot), toSlot = tonumber(toSlot), amount = tonumber(amount),
        transfer = result and result.transfer }
    })
  end
  return ok, result
end

function MZInventoryPoliceAccess.revokeReadSession(actorSource, sessionToken, invokingResource)
  cleanup()
  if invokingResource ~= 'mz_police' or not allowedResource(invokingResource) then
    return false, 'resource_not_authorized'
  end
  local session = readSessions[trim(sessionToken)]
  if not session then return false, 'session_not_found' end
  if tonumber(actorSource) ~= session.actor.source then return false, 'session_actor_mismatch' end
  readSessions[trim(sessionToken)] = nil
  MZInventoryCoreBridge.log('third_party_inventory_read_revoked', {
    actor = { type = 'character', id = session.actor.citizenid },
    target = { type = 'character', id = session.target.citizenid },
    meta = { mode = session.mode }
  })
  return true, 'revoked'
end

local function token(actor, target)
  return ('police:%s:%s:%s:%s'):format(
    actor.sessionId, target.sessionId, os.time(), math.random(100000, 999999)
  )
end

local function stackLocatorToken(grant, row)
  return ('moneyloc:%s:%s:%s:%s'):format(
    grant.actor.sessionId,
    grant.target.sessionId,
    tostring(row.id or row.slot or 0),
    math.random(100000, 999999)
  )
end

local function attachMoneyStackLocators(grant, snapshot)
  local slots = type(snapshot) == 'table' and type(snapshot.main) == 'table' and snapshot.main.slots or {}
  for _, slot in ipairs(type(slots) == 'table' and slots or {}) do
    if slot.occupied == true and MZConstants.MoneyItems[tostring(slot.item_id or '')] == true then
      local row = MZInventoryRepository.getSlot(
        'character', grant.target.citizenid, MZConstants.InventoryTypes.MAIN, slot.slot
      )
      if row and MZConstants.MoneyItems[tostring(row.item or '')] == true then
        local locator = stackLocatorToken(grant, row)
        stackLocators[locator] = {
          token = locator,
          grantToken = grant.token,
          invokingResource = grant.invokingResource,
          citizenid = grant.target.citizenid,
          inventoryType = MZConstants.InventoryTypes.MAIN,
          rowId = tonumber(row.id),
          slot = tonumber(row.slot),
          item = tostring(row.item or ''),
          amount = tonumber(row.amount) or 0,
          updatedAt = tostring(row.updated_at or ''),
          expiresAt = grant.expiresAt
        }
        slot.stack_locator = locator
      end
    end
  end
end

local function validate(actorSource, grantToken, invokingResource)
  cleanup()
  if not allowedResource(invokingResource) then return nil, 'resource_not_authorized' end
  local grant = grants[trim(grantToken)]
  if not grant or grant.invokingResource ~= invokingResource then return nil, 'grant_not_found' end
  if tonumber(actorSource) ~= grant.actor.source then return nil, 'grant_actor_mismatch' end
  if not sameIdentity(grant.actor) or not sameIdentity(grant.target) then
    grants[grant.token] = nil
    return nil, 'grant_session_changed'
  end
  local close, err = near(grant.actor.source, grant.target.source)
  if not close then return nil, err end
  return grant
end

local function normalizeDestination(value)
  if type(value) ~= 'table' then return nil, 'invalid_destination' end
  for key in pairs(value) do
    if not DESTINATION_KEYS[key] then return nil, 'invalid_destination' end
  end
  local destinationType = tostring(value.type or ''):lower()
  local orgCode = tostring(value.orgCode or ''):lower()
  local containerId = tostring(value.containerId or ''):lower()
  if destinationType ~= 'police_evidence' then return nil, 'invalid_destination' end
  local organizations = type(settings().organizations) == 'table' and settings().organizations or {}
  if organizations[orgCode] ~= true then return nil, 'organization_not_authorized' end
  if #containerId < 2 or #containerId > 48 or not containerId:match('^[a-z0-9_-]+$') then
    return nil, 'invalid_destination'
  end
  return { type = destinationType, orgCode = orgCode, containerId = containerId }
end

local function normalizeArmoryKey(value, maximum)
  value = trim(value):lower()
  if #value < 2 or #value > maximum or not value:match('^[a-z0-9_-]+$') then return nil end
  return value
end

local function armoryContext(source, orgCode, stationId, invokingResource)
  if not allowedResource(invokingResource) then return nil, 'resource_not_authorized' end
  source = tonumber(source)
  orgCode = normalizeArmoryKey(orgCode, 64)
  stationId = normalizeArmoryKey(stationId, 48)
  if not source or source <= 0 or not orgCode or not stationId then return nil, 'invalid_request' end
  if type(settings().organizations) ~= 'table' or settings().organizations[orgCode] ~= true then
    return nil, 'organization_not_authorized'
  end
  local identity, err = identitySnapshot(source)
  if not identity then return nil, err end
  return { source = source, orgCode = orgCode, stationId = stationId, identity = identity }
end

local function armoryTerminal(invokingResource, operationId, fingerprint, execute)
  cleanup()
  operationId = trim(operationId)
  if #operationId < 8 or #operationId > 96 or not operationId:match('^[%w:_-]+$') then
    return false, 'invalid_operation_id'
  end
  local key = ('%s:armory:%s'):format(invokingResource, operationId)
  local terminal = terminals[key]
  if terminal then
    if terminal.fingerprint ~= fingerprint then return false, 'operation_id_conflict' end
    return terminal.ok, copy(terminal.result)
  end
  local ok, result = execute(operationId)
  terminals[key] = {
    fingerprint = fingerprint,
    ok = ok == true,
    result = copy(result),
    expiresAt = os.time() + (tonumber(settings().terminalRetentionSeconds) or 900)
  }
  return ok, copy(result)
end

function MZInventoryPoliceAccess.create(actorSource, targetSource, purpose, ttlSeconds, invokingResource)
  actorSource, targetSource = tonumber(actorSource), tonumber(targetSource)
  purpose = tostring(purpose or ''):lower()
  if not allowedResource(invokingResource) then return false, 'resource_not_authorized' end
  if not actorSource or not targetSource or actorSource <= 0 or targetSource <= 0 or actorSource == targetSource then
    return false, 'invalid_source'
  end
  if not PURPOSES[purpose] then return false, 'invalid_purpose' end
  local actor, actorErr = identitySnapshot(actorSource)
  if not actor then return false, actorErr end
  local target, targetErr = identitySnapshot(targetSource)
  if not target then return false, targetErr end
  local close, proximityErr = near(actorSource, targetSource)
  if not close then return false, proximityErr end
  local actorAllowed, actorState = MZInventoryCoreBridge.canPerformAction(actorSource, 'inventory.open')
  local targetAllowed, targetState = MZInventoryCoreBridge.canPerformAction(targetSource, 'inventory.open')
  if not actorAllowed or type(actorState) ~= 'table' or actorState.allowed ~= true
    or not targetAllowed or type(targetState) ~= 'table' or targetState.allowed ~= true then
    return false, 'player_state_blocked'
  end

  ttlSeconds = math.floor(tonumber(ttlSeconds) or 15)
  ttlSeconds = math.max(5, math.min(ttlSeconds, tonumber(settings().maximumTtlSeconds) or 30))
  local grantToken = token(actor, target)
  grants[grantToken] = {
    token = grantToken,
    actor = actor,
    target = target,
    purpose = purpose,
    invokingResource = invokingResource,
    expiresAt = os.time() + ttlSeconds
  }
  MZInventoryCoreBridge.log('police_access_grant_created', {
    actor = { type = 'character', id = actor.citizenid, citizenid = actor.citizenid },
    target = { type = 'character', id = target.citizenid, citizenid = target.citizenid },
    meta = { purpose = purpose, expiresAt = grants[grantToken].expiresAt }
  })
  return true, { grantToken = grantToken, purpose = purpose, expiresAt = grants[grantToken].expiresAt }
end

function MZInventoryPoliceAccess.snapshot(actorSource, grantToken, invokingResource)
  local grant, err = validate(actorSource, grantToken, invokingResource)
  if not grant then return false, err end
  local ok, snapshot = MZInventoryService.getRestrictedPlayerInventorySnapshot(grant.target.source)
  if not ok then return false, snapshot end
  attachMoneyStackLocators(grant, snapshot)
  return true, { targetCitizenid = grant.target.citizenid, purpose = grant.purpose, inventory = snapshot }
end

function MZInventoryPoliceAccess.transfer(
  actorSource, grantToken, instanceUid, amount, destination, operationId, invokingResource
)
  operationId = trim(operationId)
  instanceUid = trim(instanceUid)
  if #operationId < 8 or #operationId > 96 or not operationId:match('^[%w:_-]+$') then
    return false, 'invalid_operation_id'
  end
  local grant, err = validate(actorSource, grantToken, invokingResource)
  if not grant then return false, err end
  if grant.purpose ~= 'seizure' then return false, 'grant_purpose_denied' end
  local normalized, destinationErr = normalizeDestination(destination)
  if not normalized then return false, destinationErr end
  local locator = stackLocators[instanceUid]
  if locator and (locator.grantToken ~= grant.token or locator.invokingResource ~= invokingResource
    or locator.citizenid ~= grant.target.citizenid) then
    return false, 'stack_locator_invalid'
  end

  local terminalKey = ('%s:%s'):format(invokingResource, operationId)
  local fingerprint = table.concat({ grant.target.citizenid, instanceUid, tostring(amount), normalized.orgCode, normalized.containerId }, ':')
  local terminal = terminals[terminalKey]
  if terminal then
    if terminal.fingerprint ~= fingerprint then return false, 'operation_id_conflict' end
    return terminal.ok, copy(terminal.result)
  end

  local ok, transferOrErr = MZInventoryService.transferPlayerItemToPoliceContainer(
    grant.actor.source, grant.target.source, locator and '' or instanceUid, amount, normalized, locator,
    function()
      local current, validationError = validate(actorSource, grantToken, invokingResource)
      if not current then return false, validationError end
      if current.purpose ~= 'seizure' then return false, 'grant_purpose_denied' end
      local context, authorizationError = authorizeRead(current.actor.source, current.target.source, 'police_seizure')
      if not context then return false, authorizationError end
      if context.organization ~= normalized.orgCode then return false, 'organization_changed' end
      return true
    end
  )
  if locator and ok then stackLocators[instanceUid] = nil end
  terminals[terminalKey] = {
    fingerprint = fingerprint,
    ok = ok == true,
    result = copy(transferOrErr),
    expiresAt = os.time() + (tonumber(settings().terminalRetentionSeconds) or 900)
  }
  if ok then
    MZInventoryCoreBridge.log('police_item_seized', {
      actor = { type = 'character', id = grant.actor.citizenid, citizenid = grant.actor.citizenid },
      target = { type = 'character', id = grant.target.citizenid, citizenid = grant.target.citizenid },
      context = { orgCode = normalized.orgCode, operationId = operationId },
      meta = {
        instanceUid = transferOrErr and transferOrErr.instanceUid or instanceUid,
        stackLocator = locator and instanceUid or nil,
        amount = tonumber(amount),
        containerId = normalized.containerId
      }
    })
  end
  return ok, copy(transferOrErr)
end

function MZInventoryPoliceAccess.revoke(actorSource, grantToken, invokingResource)
  cleanup()
  if not allowedResource(invokingResource) then return false, 'resource_not_authorized' end
  local grant = grants[trim(grantToken)]
  if not grant or grant.invokingResource ~= invokingResource then return false, 'grant_not_found' end
  if tonumber(actorSource) ~= grant.actor.source then return false, 'grant_actor_mismatch' end
  if not sameIdentity(grant.actor) then return false, 'grant_session_changed' end
  grants[grant.token] = nil
  for locator, entry in pairs(stackLocators) do
    if entry.grantToken == grant.token then stackLocators[locator] = nil end
  end
  return true, 'revoked'
end

function MZInventoryPoliceAccess.listIssued(source, orgCode, stationId, invokingResource)
  local context, err = armoryContext(source, orgCode, stationId, invokingResource)
  if not context then return false, err end
  return MZInventoryService.listPoliceIssuedEquipment(context.source, context.orgCode, context.stationId)
end

function MZInventoryPoliceAccess.issue(
  source, orgCode, stationId, catalogKey, itemName, operationId, invokingResource
)
  local context, err = armoryContext(source, orgCode, stationId, invokingResource)
  if not context then return false, err end
  catalogKey = normalizeArmoryKey(catalogKey, 48)
  itemName = normalizeArmoryKey(itemName, 64)
  if not catalogKey or not itemName then return false, 'invalid_request' end
  local fingerprint = table.concat({ context.identity.citizenid, orgCode, stationId, catalogKey, itemName }, ':')
  return armoryTerminal(invokingResource, operationId, fingerprint, function(normalizedOperationId)
    local ok, result = MZInventoryService.issuePoliceEquipment(
      context.source, context.orgCode, context.stationId, catalogKey, itemName,
      { operationId = normalizedOperationId }
    )
    if ok then
      MZInventoryCoreBridge.log('police_armory_equipment_issued', {
        actor = { type = 'character', id = context.identity.citizenid, citizenid = context.identity.citizenid },
        context = { orgCode = context.orgCode, stationId = context.stationId, operationId = normalizedOperationId },
        meta = { catalogKey = catalogKey, item = itemName, result = copy(result) }
      })
    end
    return ok, result
  end)
end

function MZInventoryPoliceAccess.returnIssued(
  source, orgCode, stationId, instanceUid, operationId, invokingResource
)
  local context, err = armoryContext(source, orgCode, stationId, invokingResource)
  if not context then return false, err end
  instanceUid = trim(instanceUid)
  if instanceUid == '' or #instanceUid > 64 or not instanceUid:match('^[%w:_-]+$') then
    return false, 'invalid_instance_uid'
  end
  local fingerprint = table.concat({ context.identity.citizenid, orgCode, stationId, instanceUid }, ':')
  return armoryTerminal(invokingResource, operationId, fingerprint, function(normalizedOperationId)
    local ok, result = MZInventoryService.returnPoliceEquipment(
      context.source, context.orgCode, context.stationId, instanceUid
    )
    if ok then
      MZInventoryCoreBridge.log('police_armory_equipment_returned', {
        actor = { type = 'character', id = context.identity.citizenid, citizenid = context.identity.citizenid },
        context = { orgCode = context.orgCode, stationId = context.stationId, operationId = normalizedOperationId },
        meta = { instanceUid = instanceUid, result = copy(result) }
      })
    end
    return ok, result
  end)
end

function MZInventoryPoliceAccess.listEvidence(source, orgCode, containerId, invokingResource)
  local context, err = armoryContext(source, orgCode, containerId, invokingResource)
  if not context then return false, err end
  return MZInventoryService.listPoliceEvidence(context.source, context.orgCode, context.stationId)
end

function MZInventoryPoliceAccess.transferEvidence(
  source, orgCode, fromContainer, toContainer, instanceUid, operationId, invokingResource
)
  local context, err = armoryContext(source, orgCode, fromContainer, invokingResource)
  if not context then return false, err end
  toContainer = normalizeArmoryKey(toContainer, 48)
  instanceUid = trim(instanceUid)
  if not toContainer or toContainer == context.stationId or instanceUid == '' or #instanceUid > 64
    or not instanceUid:match('^[%w:_-]+$') then return false, 'invalid_evidence_transfer' end
  local fingerprint = table.concat({ context.identity.citizenid, orgCode, context.stationId, toContainer, instanceUid }, ':')
  return armoryTerminal(invokingResource, operationId, fingerprint, function(normalizedOperationId)
    local ok, result = MZInventoryService.transferPoliceEvidence(
      context.source, context.orgCode, context.stationId, toContainer, instanceUid
    )
    if ok then
      MZInventoryCoreBridge.log('police_evidence_transferred', {
        actor = { type = 'character', id = context.identity.citizenid, citizenid = context.identity.citizenid },
        target = { type = 'item', id = instanceUid },
        context = { orgCode = context.orgCode, operationId = normalizedOperationId },
        before = { containerId = context.stationId }, after = { containerId = toContainer },
        meta = { evidence = copy(result.evidence) }
      })
    end
    return ok, result
  end)
end

function MZInventoryPoliceAccess.cleanupSource(source)
  source = tonumber(source)
  for token, session in pairs(readSessions) do
    if session.actor.source == source or session.target.source == source then readSessions[token] = nil end
  end
  for token, grant in pairs(grants) do
    if grant.actor.source == source or grant.target.source == source then
      grants[token] = nil
      for locator, entry in pairs(stackLocators) do
        if entry.grantToken == token then stackLocators[locator] = nil end
      end
    end
  end
end

if type(AddEventHandler) == 'function' then
  AddEventHandler('playerDropped', function() MZInventoryPoliceAccess.cleanupSource(source) end)
  AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() and resourceName ~= 'mz_police' then return end
    for token in pairs(grants) do grants[token] = nil end
    for token in pairs(readSessions) do readSessions[token] = nil end
    for locator in pairs(stackLocators) do stackLocators[locator] = nil end
  end)
end
