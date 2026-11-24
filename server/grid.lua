MZInventoryGrid = {}

function MZInventoryGrid.columns()
  return math.max(1, math.floor(tonumber(Config and Config.Inventory and Config.Inventory.gridColumns) or 8))
end

function MZInventoryGrid.dimensions(definition, rotated)
  local size = type(definition) == 'table' and definition.grid or nil
  local width = math.max(1, math.floor(tonumber(size and size.width) or 1))
  local height = math.max(1, math.floor(tonumber(size and size.height) or 1))
  if rotated then return height, width end
  return width, height
end

function MZInventoryGrid.cells(slot, maxSlots, width, height, columns)
  slot, maxSlots = tonumber(slot), tonumber(maxSlots)
  columns = columns or MZInventoryGrid.columns()
  if not slot or slot % 1 ~= 0 or slot < 1 or slot > maxSlots then return nil end
  local x, y = (slot - 1) % columns, math.floor((slot - 1) / columns)
  if x + width > columns then return nil end
  local cells = {}
  for dy = 0, height - 1 do
    for dx = 0, width - 1 do
      local cell = (y + dy) * columns + x + dx + 1
      if cell > maxSlots then return nil end
      cells[#cells + 1] = cell
    end
  end
  return cells
end

function MZInventoryGrid.occupancy(rows, maxSlots, definitions, used)
  local occupied = {}
  for _, row in ipairs(rows or {}) do
    local metadata = type(row.metadata) == 'table' and row.metadata or {}
    local width, height = MZInventoryGrid.dimensions(definitions[row.item], metadata.grid_rotated == true)
    local cells = MZInventoryGrid.cells(tonumber(row.slot), maxSlots, width, height)
    if not cells then return nil end
    for _, cell in ipairs(cells) do
      if occupied[cell] then return nil end
      occupied[cell] = true
    end
  end
  for slot, value in pairs(used or {}) do if value then occupied[slot] = true end end
  return occupied
end

function MZInventoryGrid.fits(occupied, slot, maxSlots, width, height)
  local cells = MZInventoryGrid.cells(slot, maxSlots, width, height)
  if not cells then return false end
  for _, cell in ipairs(cells) do if occupied[cell] then return false end end
  return true, cells
end

function MZInventoryGrid.findFree(rows, maxSlots, definitions, item, metadata, used)
  local occupied = MZInventoryGrid.occupancy(rows, maxSlots, definitions, used)
  if not occupied then return nil end
  local width, height = MZInventoryGrid.dimensions(definitions[item], type(metadata) == 'table' and metadata.grid_rotated == true)
  for slot = 1, maxSlots do
    if MZInventoryGrid.fits(occupied, slot, maxSlots, width, height) then return slot end
  end
  return nil
end
