MZInventorySchema = {}

local status = {
  ready = false,
  writerOwner = 'mz_inventory',
  singleWriter = true,
  error = 'not_prepared'
}

local statements = {
  [[CREATE TABLE IF NOT EXISTS mz_inventory_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_type VARCHAR(32) NOT NULL DEFAULT 'character',
    owner_id VARCHAR(96) NOT NULL,
    inventory_type VARCHAR(32) NOT NULL DEFAULT 'main',
    slot INT NOT NULL,
    item VARCHAR(64) NOT NULL,
    amount BIGINT UNSIGNED NOT NULL,
    metadata LONGTEXT NULL,
    instance_uid VARCHAR(64) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_mz_inventory_slot (owner_type, owner_id, inventory_type, slot),
    UNIQUE KEY uq_mz_inventory_instance_uid (instance_uid),
    KEY idx_mz_inventory_owner (owner_type, owner_id, inventory_type),
    KEY idx_mz_inventory_item (item)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
  [[CREATE TABLE IF NOT EXISTS mz_player_hotbar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(32) NOT NULL,
    hotbar_slot INT NOT NULL,
    instance_uid VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_mz_player_hotbar_slot (citizenid, hotbar_slot),
    UNIQUE KEY uq_mz_player_hotbar_instance (citizenid, instance_uid),
    KEY idx_mz_player_hotbar_instance_uid (instance_uid)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
  [[CREATE TABLE IF NOT EXISTS mz_world_drops (
    id INT AUTO_INCREMENT PRIMARY KEY,
    drop_uid VARCHAR(64) NOT NULL,
    x DOUBLE NOT NULL DEFAULT 0,
    y DOUBLE NOT NULL DEFAULT 0,
    z DOUBLE NOT NULL DEFAULT 0,
    label VARCHAR(100) NULL,
    metadata_json LONGTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_mz_world_drops_uid (drop_uid)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
  [[CREATE TABLE IF NOT EXISTS mz_inventory_money_receipts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    caller_resource VARCHAR(64) NOT NULL,
    operation_key VARCHAR(128) NOT NULL,
    fingerprint VARCHAR(160) NOT NULL,
    citizenid VARCHAR(64) NOT NULL,
    item VARCHAR(64) NOT NULL,
    operation VARCHAR(16) NOT NULL,
    amount BIGINT UNSIGNED NOT NULL,
    container_type VARCHAR(32) NOT NULL,
    result_json LONGTEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_mz_inventory_money_operation (caller_resource, operation_key),
    KEY idx_mz_inventory_money_character (citizenid, item, created_at)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]
}

local function copy(value)
  if type(value) ~= 'table' then return value end
  local out = {}
  for key, nested in pairs(value) do out[key] = copy(nested) end
  return out
end

function MZInventorySchema.getStatus()
  return copy(status)
end

function MZInventorySchema.isReady()
  return status.ready == true
end

function MZInventorySchema.prepare()
  status.ready = false
  status.error = 'preparing'

  for index, statement in ipairs(statements) do
    local ok, err = pcall(function() MySQL.query.await(statement) end)
    if not ok then
      status.error = ('statement_%s_failed:%s'):format(index, tostring(err))
      print(('[mz_inventory][schema][ERROR] %s'):format(status.error))
      return false, status.error
    end
  end

  local legacy = MySQL.query.await([[
    SELECT owner_type, COUNT(*) AS total
    FROM mz_inventory_items
    WHERE owner_type IN ('player', 'stash', 'org', 'house', 'world')
    GROUP BY owner_type
  ]]) or {}
  if #legacy > 0 then
    status.error = 'legacy_owner_rows_detected_reset_required'
    print('[mz_inventory][schema][ERROR] legacy owner rows detected; execute the documented staging reset before cutover')
    return false, status.error
  end

  status.ready = true
  status.error = nil
  print('[mz_inventory][schema] ready writer_owner=mz_inventory single_writer=true')
  return true
end

CreateThread(function()
  MZInventorySchema.prepare()
end)
