MZInventoryCoreBridge = {}

local function coreStarted()
  return GetResourceState('mz_core') == 'started'
end

function MZInventoryCoreBridge.getPlayer(source)
  source = tonumber(source)
  if not source or source <= 0 or not coreStarted() then return nil end
  local ok, player = pcall(function()
    return exports['mz_core']:GetPlayerSnapshot(source)
  end)
  if not ok or type(player) ~= 'table' or tostring(player.citizenid or '') == '' then return nil end
  return player
end

function MZInventoryCoreBridge.resolveIdentity(source)
  source = tonumber(source)
  if not source or source <= 0 or not coreStarted() then return nil, 'player_not_loaded' end
  local ok, identity = pcall(function()
    return exports['mz_core']:ResolvePlayerIdentity(source)
  end)
  if not ok or type(identity) ~= 'table' or identity.ok ~= true then
    return nil, type(identity) == 'table' and tostring(identity.error or 'player_not_loaded')
      or 'player_not_loaded'
  end
  return identity
end

function MZInventoryCoreBridge.getLegacyPlayerMoney(source)
  source = tonumber(source)
  if not source or source <= 0 or GetResourceState('mz_economy') ~= 'started' then return nil end
  local ok, money = pcall(function()
    return exports['mz_economy']:GetMoney(source)
  end)
  if not ok or type(money) ~= 'table' then return nil end
  return {
    wallet = math.floor(tonumber(money.wallet) or 0),
    bank = math.floor(tonumber(money.bank) or 0)
  }
end

-- Compatibilidade interna enquanto o dinheiro fisico permanece desativado.
MZInventoryCoreBridge.getPlayerMoney = MZInventoryCoreBridge.getLegacyPlayerMoney

function MZInventoryCoreBridge.isPlayerLoaded(source)
  local player = MZInventoryCoreBridge.getPlayer(source)
  return type(player) == 'table' and tonumber(player.source) == tonumber(source)
end

function MZInventoryCoreBridge.canPerformAction(source, action)
  if not coreStarted() then return false, { allowed = false, reason = 'core_unavailable' } end
  local ok, allowed, result = pcall(function()
    return exports['mz_core']:CanPlayerPerformAction(source, action)
  end)
  if not ok then return false, { allowed = false, reason = 'state_unavailable' } end
  return allowed == true, result
end

function MZInventoryCoreBridge.getPlayerOrg(source, orgCode)
  if GetResourceState('mz_org') ~= 'started' then return nil, 'org_unavailable' end
  local okOrg, org = pcall(function()
    return exports['mz_org']:GetOrgByCode(orgCode)
  end)
  if not okOrg or type(org) ~= 'table' or tonumber(org.id) == nil then return nil, 'org_not_found' end

  local okContexts, contexts = pcall(function()
    return exports['mz_org']:GetPlayerOrgContext(source)
  end)
  if not okContexts or type(contexts) ~= 'table' then return nil, 'not_in_org' end
  for _, membership in ipairs(contexts) do
    local code = tostring(membership.code or membership.orgCode or membership.org_code or ''):lower()
    local id = tonumber(membership.id or membership.orgId or membership.org_id)
    if code == tostring(orgCode):lower() or id == tonumber(org.id) then
      return { org = org, membership = membership }
    end
  end
  return nil, 'not_in_org'
end

function MZInventoryCoreBridge.canAccessVehicle(source, plate)
  if GetResourceState('mz_org') ~= 'started' then return false, 'org_unavailable' end
  local ok, allowed, vehicle = pcall(function()
    return exports['mz_org']:CanAccessVehicle(source, plate)
  end)
  if not ok then return false, 'vehicle_access_unavailable' end
  return allowed == true, vehicle
end

function MZInventoryCoreBridge.log(action, payload)
  if not coreStarted() then return false end
  local ok = pcall(function()
    exports['mz_core']:CreateDetailedLog('inventory', action, payload)
  end)
  return ok
end
