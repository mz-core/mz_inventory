-- O inventario disponibiliza apenas objetos locais de drops reais; o servidor
-- continua validando a existencia, a distancia e o acesso ao inventario.
local points = {}

RegisterNetEvent('mz_inventory:client:interactVehicleTrunk', function(vehicle)
  vehicle = tonumber(vehicle)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return end
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then return end
  local bone = GetEntityBoneIndexByName(vehicle, 'boot')
  local coords = bone and bone ~= -1 and GetWorldPositionOfEntityBone(vehicle, bone)
    or GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.2, 0.45)
  if #(GetEntityCoords(ped) - coords) > 1.75 then return end
  local plate = tostring(GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if plate ~= '' then MZInventoryClient.openVehicleTrunkView(plate) end
end)

local function removePoint(uid)
  if GetResourceState('mz_interact') == 'started' then
    pcall(function() exports['mz_interact']:RemovePoint('mz_inventory:drop:' .. uid) end)
  end
  points[uid] = nil
end

RegisterNetEvent('mz_inventory:client:interactDrop', function(uid, entity, backpackUid)
  if not DoesEntityExist(entity) then return end
  local ok, current = pcall(function() return MZInventoryDrops.GetDropUid(entity) end)
  if not ok or current ~= uid then return end
  if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) > 1.5 then return end
  if backpackUid and backpackUid ~= '' then
    local valid, currentBag = pcall(function() return MZInventoryDrops.GetBackpackUid(entity) end)
    if not valid or currentBag ~= backpackUid then return end
    MZInventoryBridge.openTargetView({ type = 'ground_backpack', drop_uid = uid, instance_uid = backpackUid })
  else
    MZInventoryBridge.openTargetView({ type = 'drop', drop_uid = uid })
  end
end)

CreateThread(function()
  while true do
    if GetResourceState('mz_interact') == 'started' then
      local ok, drops = pcall(function() return MZInventoryDrops.GetStreamedDrops() end)
      if ok and type(drops) == 'table' then
        local seen = {}
        for _, drop in ipairs(drops) do
          local uid, entity = drop.drop_uid, drop.entity
          if type(uid) == 'string' and DoesEntityExist(entity) then
            seen[uid] = true
            local backpackUid = tostring(drop.backpack_uid or '')
            if not points[uid] or points[uid].entity ~= entity or points[uid].backpackUid ~= backpackUid then
              if points[uid] then removePoint(uid) end
              local added, result = pcall(function() return exports['mz_interact']:AddPoint({
                id = 'mz_inventory:drop:' .. uid,
                coords = GetEntityCoords(entity),
                follow = { entity = entity },
                drawDistance = 4.0,
                interactDistance = 1.5,
                marker = false,
                text = { enabled = true, ui = true, discovery = true, keyLabel = 'E',
                  label = drop.backpack_uid and drop.backpack_uid ~= '' and 'Interagir' or 'Abrir itens' },
                actionMenu = drop.backpack_uid and drop.backpack_uid ~= '' or false,
                actions = drop.backpack_uid and drop.backpack_uid ~= '' and {
                  { label = 'Abrir mochila', key = 38, event = { type = 'client', name = 'mz_inventory:client:interactDrop', args = { uid, entity, drop.backpack_uid } } },
                  { label = 'Ver item no chão', key = 47, event = { type = 'client', name = 'mz_inventory:client:interactDrop', args = { uid, entity } } }
                } or nil,
                event = { type = 'client', name = 'mz_inventory:client:interactDrop', args = { uid, entity } }
              }) end)
              if added and result == true then points[uid] = { entity = entity, backpackUid = backpackUid } end
            end
          end
        end
        for uid in pairs(points) do if not seen[uid] then removePoint(uid) end end
      end
    else
      for uid in pairs(points) do removePoint(uid) end
    end
    Wait(500)
  end
end)

AddEventHandler('onClientResourceStop', function(resource)
  if resource == 'mz_interact' then
    points = {}
  elseif resource == GetCurrentResourceName() then
    for uid in pairs(points) do removePoint(uid) end
  end
end)
