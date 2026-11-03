MZInventoryThirdParty = MZInventoryThirdParty or {}

local active
local generation = 0
local localeName = tostring(GetConvar('ox:locale', '')):lower()
if localeName == '' or localeName == 'pt' then localeName = 'pt-br' end
if type(lib) == 'table' and type(lib.locale) == 'function' then lib.locale(localeName) end

local function L(key, fallback)
  if type(locale) == 'function' then
    local value = locale(key)
    if type(value) == 'string' and value ~= key then return value end
  end
  return fallback or key
end

local function errorMessage(code)
  return L('third_party.error.' .. tostring(code or 'access_denied'),
    L('third_party.error.access_denied', 'Acesso indisponível.'))
end

local function detach()
  generation = generation + 1
  local old = active
  active = nil
  if old then TriggerServerEvent('mz_police:server:thirdParty:close', old.id) end
end

local function endSession(code)
  if not active then return end
  detach()
  MZInventoryNUI.forceClose()
  if code then MZInventoryClientHelpers.notify(errorMessage(code), 'warning') end
end

local function request(callbackName, payload)
  local ok, response = pcall(function()
    return lib.callback.await(callbackName, false, payload)
  end)
  if not ok or type(response) ~= 'table' then return false, 'inventory_unavailable' end
  if response.ok ~= true then
    return false, type(response.error) == 'table' and response.error.code or 'access_denied'
  end
  return true, response.data
end

local function applyView(view, expectedId, expectedGeneration)
  if not active or active.id ~= expectedId or generation ~= expectedGeneration then return false end
  if type(view) ~= 'table' or type(view.player) ~= 'table' or type(view.player.slots) ~= 'table'
    or type(view.equipment) ~= 'table' or type(view.target) ~= 'table' then
    endSession('inventory_unavailable')
    return false
  end
  local wasOpen = MZInventoryState.isOpen()
  if wasOpen then
    local session = MZInventoryState.session
    session.snapshots.player = MZInventoryState.cloneValue(view.player)
    session.snapshots.equipment = MZInventoryState.cloneValue(view.equipment)
    session.snapshots.target = MZInventoryState.cloneValue(view.target)
    session.snapshots.targetEquipment = MZInventoryState.cloneValue(view.targetEquipment)
    session.profile = MZInventoryState.cloneValue(view.profile)
  else
    MZInventoryState.applyView(view, { player = { type = 'player' }, target = { type = 'third_party' } })
  end
  MZInventoryState.session.thirdParty = {
    mode = active.mode, canSeize = view.thirdParty and view.thirdParty.canSeize == true,
    labels = {
      title = active.mode == 'police_search' and L('third_party.search_title', 'Revista policial')
        or L('third_party.robbery_title', 'Roubo'),
      target = L('third_party.target', 'Inventário do alvo'),
      equipment = L('third_party.equipment', 'Equipamento do alvo'),
      take = L('third_party.take', 'Retirar'),
      seize = L('third_party.seize', 'Apreender'),
      quantity = L('third_party.quantity', 'Escolha a quantidade'),
      blocked = L('third_party.blocked', 'Ação indisponível nesta interação.'),
      invalidDestination = L('third_party.invalid_destination', 'Este destino não aceita o item.')
    }
  }
  if wasOpen then MZInventoryNUI.renderSession() else MZInventoryNUI.openSession() end
  return true
end

function MZInventoryThirdParty.isActive()
  return active ~= nil
end

function MZInventoryThirdParty.message(code)
  return errorMessage(code)
end

function MZInventoryThirdParty.detach()
  detach()
end

function MZInventoryThirdParty.close(code)
  endSession(code)
end

function MZInventoryThirdParty.refresh()
  if not active then return false, 'session_not_found' end
  local id, currentGeneration = active.id, generation
  local ok, viewOrCode = request('mz_police:server:thirdParty:view', id)
  if not active or active.id ~= id or generation ~= currentGeneration then return false, 'session_closed' end
  if not ok then endSession(viewOrCode); return false, viewOrCode end
  return applyView(viewOrCode, id, currentGeneration)
end

function MZInventoryThirdParty.perform(action, payload)
  if not active then return false, 'session_not_found' end
  if MZInventoryState.session.actionState.busy == true then return false, 'inventory_busy' end
  local id, currentGeneration = active.id, generation
  payload = type(payload) == 'table' and payload or {}
  payload.id = id
  MZInventoryState.setActionState(action, L('third_party.quantity', 'Processando ação...'))
  MZInventoryNUI.renderSession()
  local ok, viewOrCode = request('mz_police:server:thirdParty:' .. action, payload)
  if not active or active.id ~= id or generation ~= currentGeneration then return false, 'session_closed' end
  if not ok then
    MZInventoryState.clearActionState()
    MZInventoryNUI.renderSession()
    if viewOrCode == 'session_expired' or viewOrCode == 'session_not_found'
      or viewOrCode == 'session_identity_changed' or viewOrCode == 'target_too_far'
      or viewOrCode == 'routing_bucket_mismatch' or viewOrCode == 'target_not_vulnerable'
      or viewOrCode == 'target_not_in_custody' then endSession(viewOrCode)
    end
    return false, viewOrCode
  end
  MZInventoryState.clearActionState()
  MZInventoryState.clearInteractionState()
  if not applyView(viewOrCode, id, currentGeneration) then return false, 'session_closed' end
  MZInventoryClientHelpers.notify(L(action == 'seize' and 'third_party.seized' or 'third_party.transferred',
    action == 'seize' and 'Item apreendido.' or 'Item transferido.'), 'success')
  return true, viewOrCode
end

RegisterNetEvent('mz_inventory:client:openThirdParty', function(payload)
  payload = type(payload) == 'table' and payload or {}
  local id = tostring(payload.id or '')
  if id == '' or (payload.mode ~= 'civil_robbery' and payload.mode ~= 'police_search') then return end
  if MZInventoryState.isOpen() then MZInventoryNUI.forceClose() end
  detach()
  active = {
    id = id, mode = payload.mode,
    expiresAt = GetGameTimer() + math.max(0, tonumber(payload.expiresInMs) or 0)
  }
  local currentGeneration = generation
  MZInventoryThirdParty.refresh()
  CreateThread(function()
    while active and active.id == id and generation == currentGeneration do
      Wait(1000)
      if active and active.id == id and generation == currentGeneration then
        if GetGameTimer() >= active.expiresAt then endSession('session_expired')
        elseif MZInventoryState.isOpen() and MZInventoryState.session.actionState.busy ~= true then
          local ok, reason = request('mz_police:server:thirdParty:status', id)
          if active and active.id == id and generation == currentGeneration and not ok then endSession(reason) end
        end
      end
    end
  end)
end)

RegisterNetEvent('mz_inventory:client:thirdPartyClosed', function(id)
  if active and active.id == tostring(id or '') then endSession('session_closed') end
end)

RegisterNetEvent('mz_inventory:client:thirdPartyDenied', function(code)
  MZInventoryClientHelpers.notify(errorMessage(code), 'error')
end)

AddEventHandler('onClientResourceStop', function(resourceName)
  if resourceName == 'mz_police' or resourceName == GetCurrentResourceName() then
    endSession('session_closed')
  end
end)
