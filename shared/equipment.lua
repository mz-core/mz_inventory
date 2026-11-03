MZEquipment = MZEquipment or {}

local function inventoryConfig()
  return type(Config) == 'table' and type(Config.Inventory) == 'table' and Config.Inventory or {}
end

local function normalizedId(value)
  return tostring(value or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
end

function MZEquipment.getSlots()
  local slots = inventoryConfig().equipmentSlots
  return type(slots) == 'table' and slots or {}
end

function MZEquipment.getSlot(value)
  local wanted = normalizedId(value)
  local numeric = tonumber(value)
  for _, definition in ipairs(MZEquipment.getSlots()) do
    if normalizedId(definition.id) == wanted or tonumber(definition.slot) == numeric then
      return definition
    end
  end
  return nil
end

function MZEquipment.getWeaponSlotByHotkey(value)
  local hotkey = tonumber(value)
  if not hotkey then return nil end
  hotkey = math.floor(hotkey)
  for _, definition in ipairs(MZEquipment.getSlots()) do
    if definition.kind == 'weapon' and tonumber(definition.hotkey) == hotkey then
      return definition
    end
  end
  return nil
end

function MZEquipment.getMaxSlot()
  local maximum = 0
  for _, definition in ipairs(MZEquipment.getSlots()) do
    maximum = math.max(maximum, tonumber(definition.slot) or 0)
  end
  return maximum
end

function MZEquipment.getHotbarFirstSlot()
  return math.max(1, math.floor(tonumber(inventoryConfig().hotbarFirstSlot) or 5))
end

function MZEquipment.getRowSlot(row, itemDefinition)
  if type(row) ~= 'table' or type(itemDefinition) ~= 'table' then return nil end
  if itemDefinition.type == 'weapon' then
    local category = normalizedId(itemDefinition.weaponCategory)
    if category == '' then return nil end
    for _, definition in ipairs(MZEquipment.getSlots()) do
      if definition.kind == 'weapon' and normalizedId(definition.weaponCategory) == category then
        return definition
      end
    end
    return nil
  end

  local metadata = type(row.metadata) == 'table' and row.metadata or {}
  local clothing = type(metadata.clothing) == 'table' and metadata.clothing or {}
  return MZEquipment.getSlot(clothing.slot)
end

function MZEquipment.canEnter(row, itemDefinition, targetSlot)
  local target = MZEquipment.getSlot(targetSlot)
  local expected = MZEquipment.getRowSlot(row, itemDefinition)
  if type(itemDefinition) ~= 'table' or itemDefinition.equipment ~= true or itemDefinition.unique ~= true then
    return false, 'item_not_equippable'
  end
  if not expected or not target or tostring(expected.id) ~= tostring(target.id) then
    return false, 'equipment_slot_mismatch'
  end
  if target.disabled == true then return false, 'equipment_slot_disabled' end
  return true
end

function MZEquipment.getBackpackBonus(row)
  if type(row) ~= 'table' then return { extraSlots = 0, extraWeight = 0 } end
  local itemDefinition = type(MZItems) == 'table' and MZItems[row.item] or nil
  local expected = MZEquipment.getRowSlot(row, itemDefinition)
  if not expected or expected.id ~= 'backpack' then return { extraSlots = 0, extraWeight = 0 } end

  local metadata = type(row.metadata) == 'table' and row.metadata or {}
  local clothing = type(metadata.clothing) == 'table' and metadata.clothing or {}
  local backpack = type(metadata.backpack) == 'table' and metadata.backpack or {}
  local capacities = inventoryConfig().backpackCapacities
  capacities = type(capacities) == 'table' and capacities or {}
  local keys = {}
  local function addKey(value)
    if value ~= nil then keys[#keys + 1] = value end
  end
  addKey(itemDefinition and itemDefinition.backpackCapacityId)
  addKey(row.item)
  addKey(clothing.garment_id)
  addKey(backpack.id)
  addKey(backpack.model)
  local configured
  for _, key in ipairs(keys) do
    key = normalizedId(key)
    if key ~= '' and type(capacities[key]) == 'table' then
      configured = capacities[key]
      break
    end
  end
  configured = configured or {}
  return {
    extraSlots = math.max(0, math.floor(tonumber(configured.extraSlots) or 0)),
    extraWeight = math.max(0, math.floor(tonumber(configured.extraWeight) or 0))
  }
end

function MZEquipment.getPlayerCapacity(backpackRow)
  local config = inventoryConfig()
  local bonus = MZEquipment.getBackpackBonus(backpackRow)
  local baseSlots = math.max(1, math.floor(tonumber(config.defaultSlots) or 40))
  local baseWeight = math.max(0, math.floor(tonumber(config.defaultWeight) or 50000))
  return {
    baseSlots = baseSlots,
    baseWeight = baseWeight,
    extraSlots = bonus.extraSlots,
    extraWeight = bonus.extraWeight,
    maxSlots = baseSlots + bonus.extraSlots,
    maxWeight = baseWeight + bonus.extraWeight
  }
end

function MZEquipment.validatePlayerRowsCapacity(rows, backpackRow)
  local capacity = MZEquipment.getPlayerCapacity(backpackRow)
  local weight = 0
  for _, row in ipairs(type(rows) == 'table' and rows or {}) do
    if (tonumber(row.slot) or 0) > capacity.maxSlots then
      return false, 'backpack_slots_in_use', capacity
    end
    local definition = type(MZItems) == 'table' and MZItems[row.item] or nil
    weight = weight + (tonumber(definition and definition.weight) or 0) * (tonumber(row.amount) or 0)
  end
  if weight > capacity.maxWeight then
    return false, 'backpack_weight_exceeded', capacity
  end
  return true, nil, capacity
end
