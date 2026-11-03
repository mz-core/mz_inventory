MZInventoryMoney = {}

local function settings()
  return Config and Config.Inventory and Config.Inventory.moneyItems or {}
end

local function listed(resourceName, key)
  if type(resourceName) ~= 'string' or resourceName == '' then return false end
  for _, candidate in ipairs(type(settings()[key]) == 'table' and settings()[key] or {}) do
    if candidate == resourceName then return true end
  end
  return false
end

local function canWrite(resourceName)
  if listed(resourceName, 'writers') or listed(resourceName, 'administrators') then return true end
  return Config and Config.Debug == true and listed(resourceName, 'debugWriters')
end

local function canRead(resourceName)
  return canWrite(resourceName) or listed(resourceName, 'readers')
end

local function operationOptions(options)
  options = type(options) == 'table' and options or {}
  return tostring(options.operationKey or options.operation_key or ''),
    tostring(options.fingerprint or '')
end

function MZInventoryMoney.isSourceEnabled()
  return settings().sourceEnabled == true
end

function MZInventoryMoney.getAmount(citizenid, itemName, inventoryType, invokingResource)
  if not canRead(invokingResource) then return false, 'resource_not_authorized' end
  return MZInventoryService.getCharacterMoneyAmount(citizenid, itemName, inventoryType)
end

function MZInventoryMoney.mutate(operation, citizenid, itemName, amount, options, invokingResource)
  if not canWrite(invokingResource) then return false, 'resource_not_authorized' end
  local operationKey, fingerprint = operationOptions(options)
  local ok, result = MZInventoryService.applyProtectedMoneyOperation({
    operation = operation,
    citizenid = citizenid,
    item = itemName,
    amount = amount,
    operationKey = operationKey,
    fingerprint = fingerprint,
    callerResource = invokingResource
  })
  if ok then
    MZInventoryCoreBridge.log('money_item_' .. tostring(operation), {
      actor = { type = 'resource', id = tostring(invokingResource or '') },
      target = { type = 'character', id = tostring(citizenid or ''), citizenid = tostring(citizenid or '') },
      context = { operationKey = operationKey, fingerprint = fingerprint },
      meta = result
    })
  end
  return ok, result
end

function MZInventoryMoney.getReceipt(operationKey, invokingResource)
  if not canRead(invokingResource) then return false, 'resource_not_authorized' end
  operationKey = tostring(operationKey or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if operationKey == '' then return false, 'invalid_operation_key' end
  local receipt = MZInventoryRepository.getMoneyReceipt(invokingResource, operationKey)
  if not receipt then return false, 'operation_not_found' end
  return true, receipt.result
end

