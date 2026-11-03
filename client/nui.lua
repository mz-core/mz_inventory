MZInventoryNUI = MZInventoryNUI or {
  ready = false,
  buildReported = false,
  vehicleInputActive = false,
  inputPolicyThread = false
}

local NUI_BUILD = tostring(Config and Config.Inventory and Config.Inventory.nuiBuild or 'unknown')

local function safeEncode(value)
  local ok, encoded = pcall(function()
    return json.encode(value)
  end)

  if not ok then
    return '<json_encode_failed>'
  end

  return tostring(encoded or 'null')
end

local function inventoryNuiLog(stage, session)
  local snapshots = type(session) == 'table' and session.snapshots or {}
  local playerSnapshot = type(snapshots) == 'table' and snapshots.player or nil
  local targetSnapshot = type(snapshots) == 'table' and snapshots.target or nil
  local equipmentSnapshot = type(snapshots) == 'table' and snapshots.equipment or nil
  local playerSlots = type(playerSnapshot) == 'table' and type(playerSnapshot.slots) == 'table' and #playerSnapshot
      .slots or 0
  local targetSlots = type(targetSnapshot) == 'table' and type(targetSnapshot.slots) == 'table' and #targetSnapshot
      .slots or 0

  print(('[mz_inventory][nui][%s] isOpen=%s | ready=%s | has_player=%s | player_slots=%s | equipment_slots=%s | has_target=%s | target_slots=%s')
    :format(
      tostring(stage or 'unknown'),
      tostring(type(session) == 'table' and session.isOpen == true),
      tostring(MZInventoryNUI.ready == true),
      tostring(type(playerSnapshot) == 'table'),
      tostring(playerSlots),
      tostring(type(equipmentSnapshot) == 'table' and type(equipmentSnapshot.slots) == 'table' and #equipmentSnapshot
        .slots or 0),
      tostring(type(targetSnapshot) == 'table'),
      tostring(targetSlots)
    ))

  print(('[mz_inventory][nui][%s][raw] session=%s'):format(
    tostring(stage or 'unknown'),
    safeEncode(session)
  ))
end

local function sendDebugBuildMarker()
  if not (Config and Config.Debug == true) then return end

  if MZInventoryNUI.buildReported ~= true then
    print(('[MZ Inventory NUI] build=%s'):format(NUI_BUILD))
    MZInventoryNUI.buildReported = true
  end

  SendNUIMessage({
    action = 'debugBuild',
    build = NUI_BUILD
  })
end

local function isValidHotbarSlot(slot)
  slot = tonumber(slot)
  local first = math.max(1, math.floor(tonumber(Config and Config.Inventory and Config.Inventory.hotbarFirstSlot) or 5))
  local count = math.max(1, math.floor(tonumber(Config and Config.Inventory and Config.Inventory.hotbarSlots) or 5))
  return slot ~= nil and slot >= first and slot < first + count and math.floor(slot) == slot
end

local VEHICLE_BLOCKED_CONTROLS = {
  24, 25, 37, 44, 45,
  68, 69, 70, 91, 92,
  140, 141, 142, 157, 158, 159, 160, 161, 162, 163, 164,
  257, 263, 264, 346, 347
}

local function needsVehicleInput()
  local ped = PlayerPedId()
  return ped ~= 0 and IsPedInAnyVehicle(ped, false)
end

local function blockVehicleCombatControls()
  for _, control in ipairs(VEHICLE_BLOCKED_CONTROLS) do
    DisableControlAction(0, control, true)
  end
  DisablePlayerFiring(PlayerId(), true)
end

local function updateVehicleInputPolicy(enabled)
  enabled = enabled == true
  if MZInventoryNUI.vehicleInputActive == enabled then return end

  MZInventoryNUI.vehicleInputActive = enabled
  SetNuiFocusKeepInput(enabled)
end

local function startInputPolicyThread()
  if MZInventoryNUI.inputPolicyThread then return end
  MZInventoryNUI.inputPolicyThread = true

  CreateThread(function()
    while MZInventoryState.isOpen() do
      local vehicleInput = needsVehicleInput()
      updateVehicleInputPolicy(vehicleInput)

      if vehicleInput then
        blockVehicleCombatControls()
        Wait(0)
      else
        Wait(150)
      end
    end

    MZInventoryNUI.inputPolicyThread = false
    MZInventoryNUI.vehicleInputActive = false
    SetNuiFocusKeepInput(false)
  end)
end

function MZInventoryNUI.renderSession()
  local session = MZInventoryState.exportForNui()
  inventoryNuiLog('render_session', session)

  SendNUIMessage({
    action = 'session',
    session = session
  })
end

function MZInventoryNUI.openSession()
  MZInventoryState.setOpen(true)

  TriggerScreenblurFadeIn(180.0)

  MZInventoryNUI.vehicleInputActive = needsVehicleInput()
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(MZInventoryNUI.vehicleInputActive)

  local session = MZInventoryState.exportForNui()
  inventoryNuiLog('open_session', session)

  SendNUIMessage({
    action = 'open',
    session = session
  })

  sendDebugBuildMarker()
  TriggerEvent('mz_inventory:client:visibilityChanged', true)
  startInputPolicyThread()
end

function MZInventoryNUI.pushError(errorData)
  SendNUIMessage({
    action = 'error',
    error = MZInventoryState.cloneValue(errorData)
  })
end

function MZInventoryNUI.closeView()
  local wasOpen = MZInventoryState.isOpen()
  if MZInventoryThirdParty then MZInventoryThirdParty.detach() end

  TriggerScreenblurFadeOut(180.0)

  MZInventoryState.close()
  MZInventoryNUI.vehicleInputActive = false
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)

  SendNUIMessage({ action = 'close' })
  TriggerEvent('mz_inventory:client:visibilityChanged', false)

  return wasOpen
end

function MZInventoryNUI.forceClose()
  if MZInventoryThirdParty then MZInventoryThirdParty.detach() end
  TriggerScreenblurFadeOut(0.0)

  MZInventoryNUI.vehicleInputActive = false
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)

  SendNUIMessage({ action = 'close' })
  MZInventoryState.reset()
  TriggerEvent('mz_inventory:client:visibilityChanged', false)
end

RegisterNUICallback('ready', function(_, cb)
  MZInventoryNUI.ready = true
  inventoryNuiLog('ready', MZInventoryState.exportForNui())
  sendDebugBuildMarker()

  if MZInventoryState.isOpen() then
    MZInventoryNUI.renderSession()
  end

  cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
  MZInventoryNUI.closeView()
  cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
  local ok, resultOrErr = MZInventoryBridge.refreshCurrentView()
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('selectSlot', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.selectSlot(data and data.container, data and data.slot)
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('startDrag', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.startDrag(data and data.container, data and data.slot)
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('clearDrag', function(_, cb)
  MZInventoryBridge.clearDrag()
  cb({ ok = true })
end)

RegisterNUICallback('clearSelection', function(_, cb)
  MZInventoryBridge.clearSelection()
  cb({ ok = true })
end)

RegisterNUICallback('beginSplit', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.beginSplit(
    data and data.container,
    data and data.slot,
    data and data.amount
  )

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('cancelSplit', function(_, cb)
  MZInventoryBridge.cancelSplit()
  cb({ ok = true })
end)

RegisterNUICallback('useItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.useItem(data and data.container, data and data.slot)
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('toggleEquipment', function(data, cb)
  local container = data and data.container
  local slotData = MZInventoryState.getSlot(container, data and data.slot)
  local ok, resultOrErr = MZInventoryBridge.toggleEquipment(container, slotData)
  cb({ ok = ok == true, error = ok and nil or resultOrErr, data = ok and resultOrErr or nil })
end)

RegisterNUICallback('bindHotbarSlot', function(data, cb)
  local inventorySlot = tonumber(data and data.inventorySlot or data and data.inventory_slot)
  local hotbarSlot = tonumber(data and data.hotbarSlot or data and data.hotbar_slot)

  if not inventorySlot or not hotbarSlot then
    cb({
      ok = false,
      error = {
        code = 'invalid_slot',
        message = 'Atalho invalido.',
        internal_code = 'invalid_hotbar_bind'
      }
    })
    return
  end

  local ok, resultOrErr = MZInventoryBridge.bindHotbarSlot(inventorySlot, hotbarSlot)
  if ok and MZInventoryNUI and MZInventoryNUI.renderSession then
    MZInventoryNUI.renderSession()
  end

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr,
    data = ok and resultOrErr or nil
  })
end)

RegisterNUICallback('clearHotbarSlot', function(data, cb)
  local hotbarSlot = tonumber(data and data.hotbarSlot or data and data.hotbar_slot)

  if not isValidHotbarSlot(hotbarSlot) then
    cb({
      ok = false,
      error = {
        code = 'invalid_slot',
        message = 'Atalho invalido.',
        internal_code = 'invalid_hotbar_clear'
      }
    })
    return
  end

  local ok, resultOrErr = MZInventoryBridge.clearHotbarSlot(math.floor(hotbarSlot))
  if ok and MZInventoryNUI and MZInventoryNUI.renderSession then
    MZInventoryNUI.renderSession()
  end

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr,
    data = ok and resultOrErr or nil
  })
end)

RegisterNUICallback('dropItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.dropItem(data and data.container, data and data.slot)
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr,
    data = ok and resultOrErr or nil
  })
end)

RegisterNUICallback('giveItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.giveItem(
    data and data.container,
    data and data.slot,
    data and data.amount
  )
  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr,
    data = ok and resultOrErr or nil
  })
end)

RegisterNUICallback('moveItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.moveItem(
    data and data.from_container,
    data and data.from_slot,
    data and data.to_container,
    data and data.to_slot,
    data and data.amount
  )

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('seizeThirdPartyItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.seizeThirdPartyItem(
    data and data.from_slot, data and data.amount, data and data.section)
  cb({ ok = ok == true, error = ok and nil or resultOrErr })
end)

RegisterNUICallback('mergeItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.mergeItem(
    data and data.container,
    data and data.from_slot,
    data and data.to_slot
  )

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('swapItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.swapItem(
    data and data.container,
    data and data.from_slot,
    data and data.to_slot
  )

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)

RegisterNUICallback('splitItem', function(data, cb)
  local ok, resultOrErr = MZInventoryBridge.splitItem(
    data and data.container,
    data and data.from_slot,
    data and data.to_slot,
    data and data.amount
  )

  cb({
    ok = ok == true,
    error = ok and nil or resultOrErr
  })
end)
