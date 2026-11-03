MZInventoryBridge = MZInventoryBridge or {}

local CALLBACKS = {
  view = 'mz_inventory:server:view',
  move = 'mz_inventory:server:move',
  merge = 'mz_inventory:server:merge',
  swap = 'mz_inventory:server:swap',
  split = 'mz_inventory:server:split',
  use = 'mz_inventory:server:use',
  drop = 'mz_inventory:server:drop',
  give = 'mz_inventory:server:give',
  hotbar = 'mz_inventory:server:getHotbar',
  bindHotbar = 'mz_inventory:server:bindHotbarSlot',
  clearHotbar = 'mz_inventory:server:clearHotbarSlot',
  toggleEquipment = 'mz_inventory:server:toggleEquipment'
}

local function buildFallbackError(code, message, internalCode, details)
  return {
    code = tostring(code or 'unknown_error'),
    message = tostring(message or 'Erro desconhecido do inventario.'),
    internal_code = tostring(internalCode or code or 'unknown_error'),
    details = MZInventoryState.cloneValue(type(details) == 'table' and details or {})
  }
end

local function safeEncode(value)
  local ok, encoded = pcall(function()
    return json.encode(value)
  end)

  if not ok then
    return '<json_encode_failed>'
  end

  return tostring(encoded or 'null')
end

local function logViewStage(stage, payload)
  payload = type(payload) == 'table' and payload or {}

  local playerSnapshot = type(payload.player) == 'table' and payload.player or nil
  local targetSnapshot = type(payload.target) == 'table' and payload.target or nil
  local equipmentSnapshot = type(payload.equipment) == 'table' and payload.equipment or nil
  local playerSlots = type(playerSnapshot) == 'table' and type(playerSnapshot.slots) == 'table' and #playerSnapshot.slots or 0
  local targetSlots = type(targetSnapshot) == 'table' and type(targetSnapshot.slots) == 'table' and #targetSnapshot.slots or 0

  print(('[mz_inventory][bridge][%s] has_player=%s | player_slots=%s | equipment_slots=%s | has_target=%s | target_slots=%s | raw=%s'):format(
    tostring(stage or 'unknown'),
    tostring(type(playerSnapshot) == 'table'),
    tostring(playerSlots),
    tostring(type(equipmentSnapshot) == 'table' and type(equipmentSnapshot.slots) == 'table' and #equipmentSnapshot.slots or 0),
    tostring(type(targetSnapshot) == 'table'),
    tostring(targetSlots),
    safeEncode(payload)
  ))
end

local function hasValidPlayerSnapshot(viewData)
  local playerSnapshot = type(viewData) == 'table' and viewData.player or nil
  return type(playerSnapshot) == 'table'
    and type(playerSnapshot.container) == 'table'
    and type(playerSnapshot.slots) == 'table'
    and type(viewData.equipment) == 'table'
    and type(viewData.equipment.slots) == 'table'
end

local function getHotbarSlotCount()
  local count = tonumber(Config and Config.Inventory and Config.Inventory.hotbarSlots) or 5
  count = math.floor(count)
  if count < 1 then
    count = 1
  end
  return count
end

local function getHotbarFirstSlot()
  return math.max(1, math.floor(tonumber(Config and Config.Inventory and Config.Inventory.hotbarFirstSlot) or 5))
end

local function normalizeHotbarPayload(payload)
  local out = {}
  local firstSlot = getHotbarFirstSlot()
  for slot = firstSlot, firstSlot + getHotbarSlotCount() - 1 do
    out[slot] = {
      hotbar_slot = slot,
      occupied = false
    }
  end

  local entries = {}
  if type(payload) == 'table' and type(payload.slots) == 'table' then
    entries = payload.slots
  elseif type(payload) == 'table' then
    entries = payload
  end

  for _, entry in pairs(entries) do
    if type(entry) == 'table' then
      local slot = tonumber(entry.hotbar_slot or entry.hotbarSlot or entry.slot)
      if slot then
        slot = math.floor(slot)
      end

      if slot and out[slot] then
        local itemName = tostring(entry.item or entry.item_id or entry.itemId or ''):gsub('^%s+', ''):gsub('%s+$', '')
        local valid = entry.valid == true and itemName ~= ''
        if valid then
          out[slot] = {
            hotbar_slot = slot,
            occupied = true,
            valid = true,
            inventory_slot = tonumber(entry.inventory_slot or entry.inventorySlot) or entry.inventory_slot or entry.inventorySlot,
            item_id = itemName,
            item = itemName,
            label = tostring(entry.label or itemName),
            amount = tonumber(entry.amount) or 1,
            usable = entry.usable == true,
            unique = entry.unique == true,
            metadata = MZInventoryState.cloneValue(type(entry.metadata) == 'table' and entry.metadata or {})
          }
        else
          out[slot] = {
            hotbar_slot = slot,
            occupied = false,
            valid = entry.valid == true
          }
        end
      end
    end
  end

  return out
end

local function normalizeVehiclePlate(plate)
  local normalized = tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', '')
  normalized = normalized:upper()

  if normalized == '' then
    return nil
  end

  return normalized
end

local function buildVehicleTargetDescriptor(containerType, plate)
  local normalizedPlate = normalizeVehiclePlate(plate)
  if not normalizedPlate then
    return nil, buildFallbackError(
      'invalid_target',
      'Placa invalida para abrir o container do veiculo.',
      'invalid_vehicle_plate',
      {
        container_type = tostring(containerType or ''),
        plate = tostring(plate or '')
      }
    )
  end

  return {
    type = tostring(containerType or ''),
    plate = normalizedPlate
  }
end

local function normalizeInventoryError(errorData)
  if type(errorData) ~= 'table' then
    return buildFallbackError('unknown_error', 'Erro desconhecido do inventario.')
  end

  return {
    code = tostring(errorData.code or 'unknown_error'),
    message = tostring(errorData.message or 'Erro desconhecido do inventario.'),
    internal_code = tostring(errorData.internal_code or errorData.code or 'unknown_error'),
    details = MZInventoryState.cloneValue(type(errorData.details) == 'table' and errorData.details or {})
  }
end

local function shouldFallbackToPlayerView(currentView, errorData)
  local targetDescriptor = type(currentView) == 'table' and currentView.target or nil
  local targetType = type(targetDescriptor) == 'table' and tostring(targetDescriptor.type or '') or ''
  if targetType ~= 'drop' then
    return false
  end

  local publicCode = tostring(type(errorData) == 'table' and errorData.code or '')
  local internalCode = tostring(type(errorData) == 'table' and errorData.internal_code or '')
  return publicCode == 'container_not_found' or internalCode == 'drop_not_found'
end

local function getGroundDropCoords()
  local ped = PlayerPedId()
  if not ped or ped == 0 then
    return nil, buildFallbackError(
      'invalid_target',
      'Nao foi possivel identificar a posicao do jogador para dropar o item.',
      'invalid_player_ped'
    )
  end

  if IsPedInAnyVehicle(ped, false) then
    return nil, buildFallbackError(
      'invalid_target',
      'Saia do veiculo para largar itens no chao.',
      'drop_while_in_vehicle'
    )
  end

  local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.9, 0.0)
  return {
    x = tonumber(coords.x) or 0,
    y = tonumber(coords.y) or 0,
    z = tonumber(coords.z) or 0
  }
end

local function pushInventoryError(errorData)
  local normalizedError = normalizeInventoryError(errorData)
  MZInventoryState.clearActionState()
  MZInventoryState.setError(normalizedError)

  if MZInventoryState.isOpen() and MZInventoryNUI and MZInventoryNUI.pushError then
    MZInventoryNUI.pushError(normalizedError)
    MZInventoryNUI.renderSession()
  else
    MZInventoryClientHelpers.notify(normalizedError.message, 'error')
  end

  return normalizedError
end

local function syncInventorySession()
  if MZInventoryState.isOpen() and MZInventoryNUI and MZInventoryNUI.renderSession then
    MZInventoryNUI.renderSession()
  end
end

local function callInventoryCallback(callbackName, payload)
  if callbackName == CALLBACKS.view then
    print(('[mz_inventory][bridge][view_request] payload=%s'):format(safeEncode(payload)))
  end

  local ok, response = pcall(function()
    return lib.callback.await(callbackName, false, payload)
  end)

  if not ok then
    return false, buildFallbackError(
      'unknown_error',
      'Nao foi possivel comunicar com o backend do inventario.',
      'callback_failed'
    )
  end

  if callbackName == CALLBACKS.view then
    print(('[mz_inventory][bridge][view_response_raw] response=%s'):format(safeEncode(response)))
  end

  if type(response) ~= 'table' then
    return false, buildFallbackError(
      'unknown_error',
      'Resposta invalida do backend do inventario.',
      'invalid_response'
    )
  end

  if response.ok ~= true then
    return false, normalizeInventoryError(response.error)
  end

  return true, response.data or {}
end

local function applyViewData(viewData, targetDescriptor)
  local normalizedData = type(viewData) == 'table' and viewData or {}
  local wasOpen = MZInventoryState.isOpen()
  local playerSnapshot = type(normalizedData.player) == 'table' and normalizedData.player or nil
  local targetSnapshot = type(normalizedData.target) == 'table' and normalizedData.target or nil
  local playerSlots = type(playerSnapshot) == 'table' and type(playerSnapshot.slots) == 'table' and #playerSnapshot.slots or 0
  local targetSlots = type(targetSnapshot) == 'table' and type(targetSnapshot.slots) == 'table' and #targetSnapshot.slots or 0

  print(('[mz_inventory][bridge][apply_view] was_open=%s | has_player=%s | player_slots=%s | has_target=%s | target_slots=%s | target_type=%s'):format(
    tostring(wasOpen == true),
    tostring(type(playerSnapshot) == 'table'),
    tostring(playerSlots),
    tostring(type(targetSnapshot) == 'table'),
    tostring(targetSlots),
    tostring(type(targetDescriptor) == 'table' and targetDescriptor.type or 'none')
  ))

  logViewStage('apply_view_payload', normalizedData)

  if not hasValidPlayerSnapshot(normalizedData) then
    MZInventoryState.setLoading(false)
    return false, pushInventoryError(buildFallbackError(
      'unknown_error',
      'Nao foi possivel carregar o inventario do jogador.',
      'invalid_view_snapshot',
      {
        has_player = type(playerSnapshot) == 'table',
        player_slots = playerSlots,
        target_type = type(targetDescriptor) == 'table' and targetDescriptor.type or 'none'
      }
    ))
  end

  MZInventoryState.applyView(normalizedData, {
    player = { type = 'player' },
    equipment = { type = 'equipment' },
    target = MZInventoryState.cloneValue(targetDescriptor)
  })
  MZInventoryBridge.getHotbar()

  if MZInventoryNUI then
    if wasOpen and MZInventoryNUI.renderSession then
      MZInventoryNUI.renderSession()
    elseif MZInventoryNUI.openSession then
      MZInventoryNUI.openSession()
    end
  end

  return true, normalizedData
end

function MZInventoryBridge.toggleEquipment(containerKey, slotData)
  slotData = type(slotData) == 'table' and slotData or {}
  local ok, dataOrError = callInventoryCallback(CALLBACKS.toggleEquipment, {
    container = tostring(containerKey or ''),
    slot = tonumber(slotData.slot) or slotData.slot,
    instance_uid = slotData.instance_uid,
    equipment_slot = slotData.equipment_slot
  })
  if not ok then return false, pushInventoryError(dataOrError) end
  local refreshOk, refreshResult = MZInventoryBridge.refreshCurrentView()
  if not refreshOk then return false, refreshResult end
  return true, dataOrError
end

local function startInventoryAction(actionType, label)
  MZInventoryState.clearError()
  MZInventoryState.clearInteractionState()
  MZInventoryState.setActionState(actionType, label)
  syncInventorySession()
end

local function finishInventoryAction()
  MZInventoryState.clearActionState()
  syncInventorySession()
end

local function performActionAndRefresh(actionType, callbackName, payload, label)
  startInventoryAction(actionType, label)

  local ok, dataOrError = callInventoryCallback(callbackName, payload)
  if not ok then
    return false, pushInventoryError(dataOrError)
  end

  -- Item handlers may hand focus to another resource (e.g. mz_computer).
  -- A late use response must not reopen the inventory that was just closed.
  if not MZInventoryState.isOpen() then
    finishInventoryAction()
    return true, dataOrError
  end

  local refreshOk, refreshResult = MZInventoryBridge.refreshCurrentView()
  if not refreshOk then
    return false, refreshResult
  end

  return true, dataOrError
end

function MZInventoryBridge.openPlayerView()
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() then MZInventoryThirdParty.detach() end
  print('[mz_inventory][bridge][open_player_view] requesting player inventory view')
  MZInventoryState.setLoading(true)
  syncInventorySession()

  local ok, dataOrError = callInventoryCallback(CALLBACKS.view, {
    player = { type = 'player' }
  })

  if not ok then
    MZInventoryState.setLoading(false)
    return false, pushInventoryError(dataOrError)
  end

  return applyViewData(dataOrError, nil)
end

function MZInventoryBridge.openTargetView(targetDescriptor)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() then MZInventoryThirdParty.detach() end
  print(('[mz_inventory][bridge][open_target_view] target=%s'):format(safeEncode(targetDescriptor)))
  MZInventoryState.setLoading(true)
  syncInventorySession()

  local ok, dataOrError = callInventoryCallback(CALLBACKS.view, {
    player = { type = 'player' },
    target = targetDescriptor
  })

  if not ok then
    MZInventoryState.setLoading(false)
    return false, pushInventoryError(dataOrError)
  end

  return applyViewData(dataOrError, targetDescriptor)
end

function MZInventoryBridge.openVehicleTrunkView(plate)
  local targetDescriptor, errorData = buildVehicleTargetDescriptor('trunk', plate)
  if not targetDescriptor then
    return false, pushInventoryError(errorData)
  end

  return MZInventoryBridge.openTargetView(targetDescriptor)
end

function MZInventoryBridge.openVehicleGloveboxView(plate)
  local targetDescriptor, errorData = buildVehicleTargetDescriptor('glovebox', plate)
  if not targetDescriptor then
    return false, pushInventoryError(errorData)
  end

  return MZInventoryBridge.openTargetView(targetDescriptor)
end

function MZInventoryBridge.refreshCurrentView()
  if not MZInventoryState.isOpen() then return true end
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() then
    return MZInventoryThirdParty.refresh()
  end
  local currentView = MZInventoryState.getCurrentViewRequest()
  MZInventoryState.setLoading(true)
  syncInventorySession()

  local ok, dataOrError = callInventoryCallback(CALLBACKS.view, currentView)
  if not MZInventoryState.isOpen() then
    MZInventoryState.setLoading(false)
    return ok, dataOrError
  end
  if not ok then
    if shouldFallbackToPlayerView(currentView, dataOrError) then
      MZInventoryState.setLoading(false)
      return MZInventoryBridge.openPlayerView()
    end

    MZInventoryState.setLoading(false)
    return false, pushInventoryError(dataOrError)
  end

  return applyViewData(dataOrError, currentView.target)
end

function MZInventoryBridge.getHotbar()
  local ok, dataOrError = callInventoryCallback(CALLBACKS.hotbar, {})
  if not ok then
    print(('[mz_inventory][bridge][hotbar_fallback] error=%s'):format(safeEncode(dataOrError)))
    MZInventoryState.setHotbar(normalizeHotbarPayload({}))
    return false, dataOrError
  end

  local hotbar = normalizeHotbarPayload(dataOrError)
  MZInventoryState.setHotbar(hotbar)
  return true, hotbar
end

function MZInventoryBridge.bindHotbarSlot(inventorySlot, hotbarSlot)
  inventorySlot = tonumber(inventorySlot)
  hotbarSlot = tonumber(hotbarSlot)

  if not inventorySlot or not hotbarSlot then
    return false, buildFallbackError('invalid_slot', 'Atalho invalido.', 'invalid_hotbar_bind')
  end

  local ok, dataOrError = callInventoryCallback(CALLBACKS.bindHotbar, {
    inventorySlot = math.floor(inventorySlot),
    hotbarSlot = math.floor(hotbarSlot)
  })

  if not ok then
    return false, dataOrError
  end

  MZInventoryBridge.getHotbar()
  syncInventorySession()
  return true, dataOrError
end

function MZInventoryBridge.clearHotbarSlot(hotbarSlot)
  hotbarSlot = tonumber(hotbarSlot)

  if not hotbarSlot then
    return false, buildFallbackError('invalid_slot', 'Atalho invalido.', 'invalid_hotbar_clear')
  end

  local ok, dataOrError = callInventoryCallback(CALLBACKS.clearHotbar, {
    hotbarSlot = math.floor(hotbarSlot)
  })

  if not ok then
    return false, dataOrError
  end

  MZInventoryBridge.getHotbar()
  syncInventorySession()
  return true, dataOrError
end

function MZInventoryBridge.selectSlot(containerKey, slotNumber)
  local selected = MZInventoryState.setSelectedSlot(containerKey, slotNumber)
  if not selected then
    return false, pushInventoryError(buildFallbackError(
      'invalid_slot',
      'Slot invalido para selecao.',
      'invalid_slot',
      {
        container = tostring(containerKey or ''),
        slot = tonumber(slotNumber) or slotNumber
      }
    ))
  end

  MZInventoryState.clearError()
  syncInventorySession()
  return true, selected
end

function MZInventoryBridge.clearSelection()
  MZInventoryState.clearSelectedSlot()
  MZInventoryState.clearDragState()
  MZInventoryState.clearSplitState()
  MZInventoryState.clearError()
  syncInventorySession()
  return true
end

function MZInventoryBridge.startDrag(containerKey, slotNumber)
  local dragState = MZInventoryState.beginDrag(containerKey, slotNumber)
  if not dragState then
    return false, pushInventoryError(buildFallbackError(
      'invalid_slot',
      'Nao foi possivel iniciar o arraste deste slot.',
      'invalid_drag_source',
      {
        container = tostring(containerKey or ''),
        slot = tonumber(slotNumber) or slotNumber
      }
    ))
  end

  MZInventoryState.clearError()
  syncInventorySession()
  return true, dragState
end

function MZInventoryBridge.clearDrag()
  MZInventoryState.clearDragState()
  syncInventorySession()
  return true
end

function MZInventoryBridge.beginSplit(containerKey, slotNumber, amount)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() and containerKey == 'target' then
    return false, pushInventoryError(buildFallbackError('session_mode_denied', MZInventoryThirdParty.message('session_mode_denied')))
  end
  local splitState = MZInventoryState.beginSplit(containerKey, slotNumber, amount)
  if not splitState then
    return false, pushInventoryError(buildFallbackError(
      'invalid_amount',
      'Nao foi possivel preparar a divisao deste item.',
      'invalid_split_request',
      {
        container = tostring(containerKey or ''),
        slot = tonumber(slotNumber) or slotNumber,
        amount = tonumber(amount) or amount
      }
    ))
  end

  MZInventoryState.clearError()
  syncInventorySession()
  return true, splitState
end

function MZInventoryBridge.cancelSplit()
  MZInventoryState.clearSplitState()
  MZInventoryState.clearDragState()
  MZInventoryState.clearError()
  syncInventorySession()
  return true
end

function MZInventoryBridge.useItem(containerKey, slotNumber)
  local selectedSlot = MZInventoryState.getSlot(containerKey, slotNumber)
  if not selectedSlot or selectedSlot.occupied ~= true then
    return false, pushInventoryError(buildFallbackError('invalid_slot', 'Slot invalido para uso.', 'invalid_slot'))
  end

  if tostring(containerKey or '') ~= 'player' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Apenas itens do jogador podem ser usados aqui.', 'invalid_target'))
  end

  if selectedSlot.usable ~= true then
    return false, pushInventoryError(buildFallbackError('item_not_usable', 'Este item nao pode ser usado.', 'item_not_usable'))
  end

  -- Garante que disparos recentes sejam persistidos antes de guardar, trocar
  -- ou reequipar uma arma pela interface do inventario.
  if GetResourceState('mz_inventory') == 'started' then
    local flushCallOk, flushOk = pcall(function()
      return exports['mz_inventory']:FlushEquippedWeaponAmmo('before_inventory_use')
    end)
    if flushCallOk and flushOk == false then
      return false, pushInventoryError(buildFallbackError(
        'inventory_busy',
        'Aguarde a munição sincronizar antes de usar outro item.',
        'weapon_ammo_sync_failed'
      ))
    end
  end

  return performActionAndRefresh('use', CALLBACKS.use, {
    container = { type = 'player' },
    slot = tonumber(slotNumber) or slotNumber
  }, 'Usando item...')
end

function MZInventoryBridge.dropItem(containerKey, slotNumber)
  local selectedSlot = MZInventoryState.getSlot(containerKey, slotNumber)
  if not selectedSlot or selectedSlot.occupied ~= true then
    return false, pushInventoryError(buildFallbackError('invalid_slot', 'Slot invalido para dropar.', 'invalid_slot'))
  end

  if tostring(containerKey or '') ~= 'player' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Apenas itens do jogador podem ser largados no chao.', 'invalid_target'))
  end

  local coords, coordsOrErr = getGroundDropCoords()
  if not coords then
    return false, pushInventoryError(coordsOrErr)
  end

  startInventoryAction('drop', 'Largando item no chao...')

  local ok, dataOrError = callInventoryCallback(CALLBACKS.drop, {
    container = { type = 'player' },
    slot = tonumber(slotNumber) or slotNumber,
    coords = coords
  })
  if not ok then
    return false, pushInventoryError(dataOrError)
  end

  local dropUid = tostring(dataOrError.drop_uid or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if dropUid ~= '' then
    return MZInventoryBridge.openTargetView({
      type = 'drop',
      drop_uid = dropUid
    })
  end

  local refreshOk, refreshResult = MZInventoryBridge.refreshCurrentView()
  if not refreshOk then
    return false, refreshResult
  end

  return true, dataOrError
end

function MZInventoryBridge.giveItem(containerKey, slotNumber, amount)
  local selectedSlot = MZInventoryState.getSlot(containerKey, slotNumber)
  if not selectedSlot or selectedSlot.occupied ~= true then
    return false, pushInventoryError(buildFallbackError('invalid_slot', 'Slot invalido para entrega.', 'invalid_slot'))
  end

  if tostring(containerKey or '') ~= 'player' then
    return false, pushInventoryError(buildFallbackError(
      'invalid_target',
      'Apenas itens do jogador podem ser entregues.',
      'invalid_target'
    ))
  end

  amount = tonumber(amount)
  if not amount or amount < 1 or amount > (tonumber(selectedSlot.amount) or 0) then
    return false, pushInventoryError(buildFallbackError(
      'invalid_amount',
      'Quantidade invalida para entrega.',
      'invalid_amount'
    ))
  end

  local ok, resultOrErr = performActionAndRefresh('give', CALLBACKS.give, {
    container = { type = 'player' },
    slot = tonumber(slotNumber) or slotNumber,
    amount = math.floor(amount)
  }, 'Entregando item...')

  if not ok then
    return false, resultOrErr
  end

  local targetName = tostring(type(resultOrErr) == 'table' and resultOrErr.target_name or 'jogador proximo')
  local itemLabel = tostring(type(resultOrErr) == 'table' and resultOrErr.item_label or selectedSlot.label or 'item')
  local deliveredAmount = tonumber(type(resultOrErr) == 'table' and resultOrErr.amount) or math.floor(amount)
  MZInventoryClientHelpers.notify(
    ('Voce entregou %sx %s para %s.'):format(deliveredAmount, itemLabel, targetName),
    'success'
  )

  return true, resultOrErr
end

function MZInventoryBridge.moveItem(fromContainerKey, fromSlot, toContainerKey, toSlot, amount)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive()
    and (fromContainerKey == 'target' or toContainerKey == 'target') then
    if fromContainerKey ~= 'target' or toContainerKey ~= 'player'
      or MZInventoryState.session.thirdParty.mode ~= 'civil_robbery' then
      return false, pushInventoryError(buildFallbackError('session_mode_denied',
        MZInventoryThirdParty.message('session_mode_denied')))
    end
    local source = MZInventoryState.getSlot('target', fromSlot)
    local requested = tonumber(amount) or tonumber(source and source.amount)
    local ok, result = MZInventoryThirdParty.perform('transfer', {
      fromSlot = tonumber(fromSlot), toSlot = tonumber(toSlot), amount = requested
    })
    if not ok then return false, pushInventoryError(buildFallbackError(result, MZInventoryThirdParty.message(result))) end
    return true, result
  end
  local fromDescriptor = MZInventoryState.getContainerDescriptor(fromContainerKey)
  local toDescriptor = MZInventoryState.getContainerDescriptor(toContainerKey)

  if type(fromDescriptor) ~= 'table' or type(toDescriptor) ~= 'table' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Destino invalido para mover o item.', 'invalid_target'))
  end

  return performActionAndRefresh('move', CALLBACKS.move, {
    from = {
      container = fromDescriptor,
      slot = tonumber(fromSlot) or fromSlot
    },
    to = {
      container = toDescriptor,
      slot = tonumber(toSlot) or toSlot
    }
  }, 'Movendo item...')
end

function MZInventoryBridge.seizeThirdPartyItem(fromSlot, amount, section)
  if not MZInventoryThirdParty or not MZInventoryThirdParty.isActive()
    or not MZInventoryState.session.thirdParty
    or MZInventoryState.session.thirdParty.mode ~= 'police_search' then
    return false, pushInventoryError(buildFallbackError('session_mode_denied', 'Apreensão indisponível.'))
  end
  local ok, result = MZInventoryThirdParty.perform('seize', {
    fromSlot = tonumber(fromSlot), amount = tonumber(amount), section = section
  })
  if not ok then return false, pushInventoryError(buildFallbackError(result, MZInventoryThirdParty.message(result))) end
  return true, result
end

function MZInventoryBridge.mergeItem(containerKey, fromSlot, toSlot)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() and containerKey == 'target' then
    return false, pushInventoryError(buildFallbackError('session_mode_denied', MZInventoryThirdParty.message('session_mode_denied')))
  end
  local descriptor = MZInventoryState.getContainerDescriptor(containerKey)
  if type(descriptor) ~= 'table' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Container invalido para mesclar o item.', 'invalid_target'))
  end

  return performActionAndRefresh('merge', CALLBACKS.merge, {
    container = descriptor,
    from_slot = tonumber(fromSlot) or fromSlot,
    to_slot = tonumber(toSlot) or toSlot
  }, 'Mesclando stack...')
end

function MZInventoryBridge.swapItem(containerKey, fromSlot, toSlot)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() and containerKey == 'target' then
    return false, pushInventoryError(buildFallbackError('session_mode_denied', MZInventoryThirdParty.message('session_mode_denied')))
  end
  local descriptor = MZInventoryState.getContainerDescriptor(containerKey)
  if type(descriptor) ~= 'table' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Container invalido para trocar os slots.', 'invalid_target'))
  end

  return performActionAndRefresh('swap', CALLBACKS.swap, {
    container = descriptor,
    from_slot = tonumber(fromSlot) or fromSlot,
    to_slot = tonumber(toSlot) or toSlot
  }, 'Trocando itens...')
end

function MZInventoryBridge.splitItem(containerKey, fromSlot, toSlot, amount)
  if MZInventoryThirdParty and MZInventoryThirdParty.isActive() and containerKey == 'target' then
    return false, pushInventoryError(buildFallbackError('session_mode_denied', MZInventoryThirdParty.message('session_mode_denied')))
  end
  local descriptor = MZInventoryState.getContainerDescriptor(containerKey)
  if type(descriptor) ~= 'table' then
    return false, pushInventoryError(buildFallbackError('invalid_target', 'Container invalido para dividir o item.', 'invalid_target'))
  end

  return performActionAndRefresh('split', CALLBACKS.split, {
    container = descriptor,
    from_slot = tonumber(fromSlot) or fromSlot,
    to_slot = tonumber(toSlot) or toSlot,
    amount = tonumber(amount) or amount
  }, 'Dividindo stack...')
end

function MZInventoryBridge.closeView()
  if MZInventoryNUI and MZInventoryNUI.closeView then
    return MZInventoryNUI.closeView()
  end

  MZInventoryState.close()
  return true
end
