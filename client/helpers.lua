MZInventoryClientHelpers = MZInventoryClientHelpers or {}

local function normalizeNotifyType(notifyType)
  local key = tostring(notifyType or 'info'):lower()

  if key == 'success' or key == 'error' or key == 'warning' or key == 'info' then
    return key
  end

  if key == 'inform' then
    return 'info'
  end

  return 'info'
end

function MZInventoryClientHelpers.notify(message, notifyType, title, duration)
  local normalizedType = normalizeNotifyType(notifyType)
  local payload = {
    type = normalizedType,
    title = tostring(title or 'Inventario'),
    description = tostring(message or 'Unknown'),
    duration = duration or 5000
  }

  if GetResourceState('mz_lib') == 'started' then
    local ok = pcall(function() exports['mz_lib']:notify(payload) end)
    if ok then return end
  end

  print(('[mz_inventory][%s] %s - %s'):format(payload.type, payload.title, payload.description))
end
