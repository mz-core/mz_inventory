lib.callback.register('mz_inventory:server:openPlayer', function(source)
  return MZInventoryService.openPlayerInventory(source)
end)

lib.callback.register('mz_inventory:server:openContainer', function(source, descriptor)
  return MZInventoryService.openInventoryContainer(source, descriptor)
end)

lib.callback.register('mz_inventory:server:snapshot', function(source, descriptor)
  return MZInventoryService.getInventorySnapshot(source, descriptor)
end)

lib.callback.register('mz_inventory:server:view', function(source, request)
  local handler = MZInventoryService and MZInventoryService.getInventoryViewSnapshot
  if type(handler) ~= 'function' then
    print(('[mz_inventory][view_unavailable] source=%s'):format(tostring(source)))
    return {
      ok = false,
      error = {
        code = 'unknown_error',
        message = 'Backend do inventario indisponivel.',
        internal_code = 'view_handler_unavailable'
      }
    }
  end

  local ok, response = pcall(handler, source, request)
  if not ok then
    print(('[mz_inventory][view_failed] source=%s error=%s'):format(
      tostring(source),
      tostring(response)
    ))
    return {
      ok = false,
      error = {
        code = 'unknown_error',
        message = 'Falha ao carregar o inventario.',
        internal_code = 'view_callback_failed'
      }
    }
  end

  return response
end)

lib.callback.register('mz_inventory:server:move', function(source, request)
  return MZInventoryService.moveInventoryItem(source, request)
end)

lib.callback.register('mz_inventory:server:split', function(source, request)
  return MZInventoryService.splitInventoryStack(source, request)
end)

lib.callback.register('mz_inventory:server:merge', function(source, request)
  return MZInventoryService.mergeInventorySlots(source, request)
end)

lib.callback.register('mz_inventory:server:swap', function(source, request)
  return MZInventoryService.swapInventorySlots(source, request)
end)

lib.callback.register('mz_inventory:server:use', function(source, request)
  return MZInventoryService.useInventoryItemAction(source, request)
end)

lib.callback.register('mz_inventory:server:drop', function(source, request)
  return MZInventoryService.dropInventoryItemAction(source, request)
end)

lib.callback.register('mz_inventory:server:give', function(source, request)
  return MZInventoryService.giveInventoryItemAction(source, request)
end)

lib.callback.register('mz_inventory:server:errors', function()
  return MZInventoryService.getPublicInventoryErrorCatalog()
end)

local function buildHotbarCallbackResponse(ok, resultOrErr)
  if ok then
    return {
      ok = true,
      data = resultOrErr or {}
    }
  end

  local internalCode = tostring(resultOrErr or 'unknown_error')
  local publicError = MZInventoryService.getPublicInventoryError(internalCode)

  return {
    ok = false,
    error = {
      code = publicError.code,
      message = publicError.message,
      internal_code = internalCode
    }
  }
end

lib.callback.register('mz_inventory:server:toggleEquipment', function(source, request)
  local ok, resultOrErr = MZInventoryService.toggleEquipmentItem(source, request)
  return buildHotbarCallbackResponse(ok, resultOrErr)
end)

lib.callback.register('mz_inventory:server:getHotbar', function(source)
  return buildHotbarCallbackResponse(MZInventoryService.getPlayerHotbar(source))
end)

lib.callback.register('mz_inventory:server:getEquipment', function(source)
  return buildHotbarCallbackResponse(MZInventoryService.getPlayerEquipment(source))
end)

lib.callback.register('mz_inventory:server:bindHotbarSlot', function(source, payload)
  payload = type(payload) == 'table' and payload or {}
  return buildHotbarCallbackResponse(MZInventoryService.bindHotbarSlot(
    source,
    payload.hotbar_slot or payload.hotbarSlot,
    payload.inventory_slot or payload.inventorySlot or payload.slot
  ))
end)

lib.callback.register('mz_inventory:server:clearHotbarSlot', function(source, payload)
  payload = type(payload) == 'table' and payload or {}
  return buildHotbarCallbackResponse(MZInventoryService.clearHotbarSlot(
    source,
    payload.hotbar_slot or payload.hotbarSlot
  ))
end)

lib.callback.register('mz_inventory:server:useHotbarSlot', function(source, payload)
  payload = type(payload) == 'table' and payload or {}
  return buildHotbarCallbackResponse(MZInventoryService.useHotbarSlot(
    source,
    payload.hotbar_slot or payload.hotbarSlot
  ))
end)

lib.callback.register('mz_inventory:server:reloadWeapon', function(source, payload)
  return buildHotbarCallbackResponse(MZInventoryService.reloadEquippedWeaponFromInventory(source, payload))
end)

lib.callback.register('mz_inventory:server:syncWeaponAmmo', function(source, payload)
  return buildHotbarCallbackResponse(MZInventoryService.updateEquippedWeaponAmmo(source, payload))
end)

RegisterNetEvent('mz_inventory:server:updateWeaponAmmo', function(payload)
  MZInventoryService.updateEquippedWeaponAmmo(source, payload)
end)

RegisterNetEvent('mz_inventory:server:unauthorizedWeaponDetected', function(payload)
  MZInventoryService.logUnauthorizedWeapon(source, payload)
end)

RegisterNetEvent('mz_inventory:server:useHotbarSlot', function(payload)
  payload = type(payload) == 'table' and payload or {}
  MZInventoryService.useHotbarSlot(source, payload.hotbar_slot or payload.hotbarSlot)
end)

RegisterNetEvent('mz_inventory:server:useEquipmentWeaponSlot', function(payload)
  payload = type(payload) == 'table' and payload or {}
  MZInventoryService.useEquipmentWeaponSlot(source, payload.hotkey or payload.slot)
end)

-- MZ_SECURITY_CANARY: sensor DEV inerte. Nao concede item, arma, dinheiro ou permissao.
local securityCanaryAt = {}
RegisterNetEvent('mz_inventory:server:MZ_SECURITY_CANARY', function()
  local sourceId = tonumber(source)
  if Config.SecurityCanary and Config.SecurityCanary.enabled == true
    and sourceId and sourceId > 0 and GetResourceState('mz_banguard') == 'started' then
    local currentMs = math.max(0, math.floor(tonumber(GetGameTimer()) or 0))
    local cooldown = math.max(1000, math.floor(tonumber(Config.SecurityCanary.cooldownMs) or 5000))
    if currentMs - (securityCanaryAt[sourceId] or -cooldown) < cooldown then return end
    securityCanaryAt[sourceId] = currentMs
    pcall(function()
      exports['mz_banguard']:RecordSecurityCanary(sourceId, 'inventory', 'write_probe', {
        resourceName = 'mz_inventory',
        presenceStatus = 'canary_called'
      })
    end)
  end
end)

AddEventHandler('playerDropped', function() securityCanaryAt[tonumber(source)] = nil end)
