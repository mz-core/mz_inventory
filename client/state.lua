MZInventoryState = MZInventoryState or {}

local function cloneValue(value)
  if type(value) ~= 'table' then
    return value
  end

  local out = {}
  for key, innerValue in pairs(value) do
    out[key] = cloneValue(innerValue)
  end

  return out
end

local function createDefaultSession()
  return {
    isOpen = false,
    isLoading = false,
    context = {
      player = {
        type = 'player'
      },
      equipment = {
        type = 'equipment'
      },
      target = nil
    },
    snapshots = {
      player = nil,
      equipment = nil,
      target = nil,
      targetEquipment = nil
    },
    profile = nil,
    thirdParty = nil,
    hotbar = {},
    selectedSlot = nil,
    hoverSlot = nil,
    dragState = {
      active = false,
      descriptor = nil,
      container = nil,
      slot = nil,
      item = nil
    },
    splitState = {
      active = false,
      descriptor = nil,
      container = nil,
      from_slot = nil,
      max_amount = 0,
      amount = 1,
      item = nil
    },
    actionState = {
      busy = false,
      type = nil,
      label = nil
    },
    lastError = nil
  }
end

MZInventoryState.session = MZInventoryState.session or createDefaultSession()

function MZInventoryState.cloneValue(value)
  return cloneValue(value)
end

function MZInventoryState.getSession()
  return MZInventoryState.session
end

function MZInventoryState.exportForNui()
  return cloneValue(MZInventoryState.session)
end

function MZInventoryState.reset()
  MZInventoryState.session = createDefaultSession()
  return MZInventoryState.session
end

function MZInventoryState.isOpen()
  return MZInventoryState.session.isOpen == true
end

function MZInventoryState.setOpen(isOpen)
  MZInventoryState.session.isOpen = isOpen == true
  return MZInventoryState.session.isOpen
end

function MZInventoryState.setLoading(isLoading)
  MZInventoryState.session.isLoading = isLoading == true
  return MZInventoryState.session.isLoading
end

function MZInventoryState.setError(errorData)
  MZInventoryState.session.lastError = cloneValue(type(errorData) == 'table' and errorData or nil)
  return MZInventoryState.session.lastError
end

function MZInventoryState.clearError()
  MZInventoryState.session.lastError = nil
end

function MZInventoryState.applyView(viewData, context)
  local session = MZInventoryState.session

  session.isOpen = true
  session.isLoading = false
  session.lastError = nil
  session.context.player = cloneValue(context and context.player or { type = 'player' })
  session.context.equipment = { type = 'equipment' }
  session.context.target = cloneValue(context and context.target or nil)
  session.snapshots.player = cloneValue(viewData and viewData.player or nil)
  session.snapshots.equipment = cloneValue(viewData and viewData.equipment or nil)
  session.snapshots.target = cloneValue(viewData and viewData.target or nil)
  session.snapshots.targetEquipment = cloneValue(viewData and viewData.targetEquipment or nil)
  session.profile = cloneValue(viewData and viewData.profile or nil)
  session.thirdParty = nil
  MZInventoryState.clearInteractionState()
  session.actionState = createDefaultSession().actionState

  return session
end

function MZInventoryState.setHotbar(hotbar)
  MZInventoryState.session.hotbar = cloneValue(type(hotbar) == 'table' and hotbar or {})
  return MZInventoryState.session.hotbar
end

function MZInventoryState.close()
  local closedSession = createDefaultSession()
  MZInventoryState.session = closedSession
  return closedSession
end

function MZInventoryState.getCurrentViewRequest()
  local session = MZInventoryState.session

  return {
    player = cloneValue(session.context.player or { type = 'player' }),
    equipment = { type = 'equipment' },
    target = cloneValue(session.context.target)
  }
end

function MZInventoryState.clearInteractionState()
  local defaults = createDefaultSession()

  MZInventoryState.session.selectedSlot = nil
  MZInventoryState.session.hoverSlot = nil
  MZInventoryState.session.dragState = defaults.dragState
  MZInventoryState.session.splitState = defaults.splitState

  return true
end

function MZInventoryState.getContainerDescriptor(containerKey)
  containerKey = tostring(containerKey or ''):lower()

  if containerKey == 'player' then
    return cloneValue(MZInventoryState.session.context.player)
  end

  if containerKey == 'equipment' then
    return { type = 'equipment' }
  end

  if containerKey == 'target' then
    return cloneValue(MZInventoryState.session.context.target)
  end

  return nil
end

function MZInventoryState.getSnapshot(containerKey)
  containerKey = tostring(containerKey or ''):lower()
  if containerKey == 'player' then
    return MZInventoryState.session.snapshots.player
  end

  if containerKey == 'equipment' then
    return MZInventoryState.session.snapshots.equipment
  end

  if containerKey == 'target' then
    return MZInventoryState.session.snapshots.target
  end

  if containerKey == 'targetequipment' then
    return MZInventoryState.session.snapshots.targetEquipment
  end

  return nil
end

function MZInventoryState.getSlot(containerKey, slotNumber)
  local snapshot = MZInventoryState.getSnapshot(containerKey)
  if type(snapshot) ~= 'table' or type(snapshot.slots) ~= 'table' then
    return nil
  end

  slotNumber = tonumber(slotNumber)
  if not slotNumber then
    return nil
  end

  for _, slotData in ipairs(snapshot.slots) do
    if tonumber(slotData.slot) == slotNumber then
      return cloneValue(slotData)
    end
  end

  return nil
end

function MZInventoryState.setSelectedSlot(containerKey, slotNumber)
  local slotData = MZInventoryState.getSlot(containerKey, slotNumber)
  if type(slotData) ~= 'table' or slotData.occupied ~= true then
    return false
  end

  MZInventoryState.session.selectedSlot = {
    container = tostring(containerKey or ''),
    descriptor = MZInventoryState.getContainerDescriptor(containerKey),
    slot = tonumber(slotData.slot) or tonumber(slotNumber) or slotNumber,
    item = cloneValue(slotData)
  }

  MZInventoryState.session.dragState = createDefaultSession().dragState
  MZInventoryState.session.splitState = createDefaultSession().splitState
  return cloneValue(MZInventoryState.session.selectedSlot)
end

function MZInventoryState.clearSelectedSlot()
  MZInventoryState.session.selectedSlot = nil
  return true
end

function MZInventoryState.beginSplit(containerKey, slotNumber, amount)
  local slotData = MZInventoryState.getSlot(containerKey, slotNumber)
  local stackAmount = tonumber(slotData and slotData.amount) or 0

  amount = tonumber(amount)
  if type(slotData) ~= 'table' or slotData.occupied ~= true or slotData.stack ~= true or stackAmount <= 1 then
    return false
  end

  if not amount or amount <= 0 or amount >= stackAmount then
    return false
  end

  MZInventoryState.session.selectedSlot = {
    container = tostring(containerKey or ''),
    descriptor = MZInventoryState.getContainerDescriptor(containerKey),
    slot = tonumber(slotData.slot) or tonumber(slotNumber) or slotNumber,
    item = cloneValue(slotData)
  }

  MZInventoryState.session.dragState = createDefaultSession().dragState
  MZInventoryState.session.splitState = {
    active = true,
    descriptor = MZInventoryState.getContainerDescriptor(containerKey),
    container = tostring(containerKey or ''),
    from_slot = tonumber(slotData.slot) or tonumber(slotNumber) or slotNumber,
    max_amount = math.max(stackAmount - 1, 1),
    amount = math.floor(amount),
    item = cloneValue(slotData)
  }

  return cloneValue(MZInventoryState.session.splitState)
end

function MZInventoryState.beginDrag(containerKey, slotNumber)
  local slotData = MZInventoryState.getSlot(containerKey, slotNumber)
  if type(slotData) ~= 'table' or slotData.occupied ~= true then
    return false
  end

  -- Arrastar e selecionar sao gestos diferentes. O drag nao deve deixar o
  -- item preso como selecionado depois que o jogador soltar ou cancelar.
  MZInventoryState.session.selectedSlot = nil

  MZInventoryState.session.dragState = {
    active = true,
    descriptor = MZInventoryState.getContainerDescriptor(containerKey),
    container = tostring(containerKey or ''),
    slot = tonumber(slotData.slot) or tonumber(slotNumber) or slotNumber,
    item = cloneValue(slotData)
  }

  MZInventoryState.session.splitState = createDefaultSession().splitState
  return cloneValue(MZInventoryState.session.dragState)
end

function MZInventoryState.clearDragState()
  MZInventoryState.session.dragState = createDefaultSession().dragState
  return true
end

function MZInventoryState.clearSplitState()
  MZInventoryState.session.splitState = createDefaultSession().splitState
  return true
end

function MZInventoryState.setActionState(actionType, label)
  MZInventoryState.session.actionState = {
    busy = true,
    type = tostring(actionType or ''),
    label = tostring(label or '')
  }
  MZInventoryState.session.isLoading = true
  return cloneValue(MZInventoryState.session.actionState)
end

function MZInventoryState.clearActionState()
  MZInventoryState.session.actionState = createDefaultSession().actionState
  MZInventoryState.session.isLoading = false
  return true
end
