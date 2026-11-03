Config = Config or {}

Config.Debug = false

Config.Inventory = {
  nuiBuild = '20261011inventorysubmenu1',
  defaultSlots = 40,
  defaultWeight = 50000,
  playerTransferDistance = 3.0,
  hotbarSlots = 5,
  hotbarFirstSlot = 5,
  hotbarKeys = {
    [5] = '5', [6] = '6', [7] = '7', [8] = '8', [9] = '9'
  },
  equipmentSlots = {
    { id = 'hat', label = 'Chapeu', slot = 1, kind = 'clothing', placeholderIcon = 'hard-hat.svg' },
    { id = 'glasses', label = 'Oculos', slot = 2, kind = 'clothing', placeholderIcon = 'glasses.svg' },
    { id = 'ears', label = 'Orelhas', slot = 3, kind = 'clothing', placeholderIcon = 'ear.svg' },
    { id = 'mask', label = 'Mascara', slot = 4, kind = 'clothing', placeholderIcon = 'venetian-mask.svg' },
    { id = 'neck', label = 'Pescoco', slot = 5, kind = 'clothing', placeholderIcon = 'badge.svg' },
    { id = 'undershirt', label = 'Camisa', slot = 6, kind = 'clothing', placeholderIcon = 'shirt.svg' },
    { id = 'torso', label = 'Jaqueta', slot = 7, kind = 'clothing', placeholderIcon = 'swatch-book.svg' },
    { id = 'arms_gloves', label = 'Bracos', slot = 8, kind = 'clothing', placeholderIcon = 'hand.svg' },
    { id = 'armour', label = 'Colete', slot = 9, kind = 'clothing', placeholderIcon = 'shield.svg', disabled = true },
    { id = 'backpack', label = 'Mochila', slot = 10, kind = 'clothing', placeholderIcon = 'backpack.svg' },
    { id = 'legs', label = 'Calca', slot = 11, kind = 'clothing', placeholderIcon = 'footprints.svg' },
    { id = 'shoes', label = 'Calcados', slot = 12, kind = 'clothing', placeholderIcon = 'sport-shoe.svg' },
    { id = 'watch', label = 'Relogio', slot = 13, kind = 'clothing', placeholderIcon = 'watch.svg' },
    { id = 'bracelet', label = 'Pulseira', slot = 14, kind = 'clothing', placeholderIcon = 'circle.svg' },
    { id = 'primary', label = 'Primaria', slot = 15, kind = 'weapon', hotkey = 1, weaponCategory = 'primary', placeholderIcon = 'crosshair.svg' },
    { id = 'sidearm', label = 'Pistola', slot = 16, kind = 'weapon', hotkey = 2, weaponCategory = 'sidearm', placeholderIcon = 'target.svg' },
    { id = 'melee', label = 'Branca', slot = 17, kind = 'weapon', hotkey = 3, weaponCategory = 'melee', placeholderIcon = 'pocket-knife.svg' },
    { id = 'special', label = 'Especial', slot = 18, kind = 'weapon', hotkey = 4, weaponCategory = 'special', placeholderIcon = 'zap.svg' }
  },
  backpackCapacities = {
    backpack_small = { extraSlots = 10, extraWeight = 10000 },
    backpack_medium = { extraSlots = 20, extraWeight = 20000 },
    backpack_large = { extraSlots = 30, extraWeight = 30000 }
  },
  medicalReservation = {
    writers = { 'mz_medical' },
    readers = { 'mz_medical', 'mz_admin' },
    terminalRetentionSeconds = 900,
    maximumTtlSeconds = 60
  },
  policeAccess = {
    writers = { 'mz_police' },
    organizations = { police = true },
    maximumDistance = 3.0,
    maximumTtlSeconds = 30,
    terminalRetentionSeconds = 900,
    evidenceSlots = 200,
    evidenceWeight = 1000000,
    armorySlots = 200,
    armoryWeight = 1000000
  },
  prisonProperty = {
    slots = 400,
    weight = 2000000
  },
  moneyItems = {
    sourceEnabled = true,
    maxSafeAmount = 9007199254740991,
    recoverySlots = 4,
    writers = { 'mz_economy' },
    administrators = { 'mz_admin' },
    readers = { 'mz_economy', 'mz_admin', 'mz_police' },
    debugWriters = { 'mz_testkit' }
  },
  personalStash = { slots = 40, weight = 75000 },
  orgStash = { slots = 80, weight = 200000 },
  trunk = { slots = 30, weight = 120000 },
  glovebox = { slots = 8, weight = 15000 }
}

Config.Weapons = {
  blockWeaponWheel = true,
  enforceInventoryWeapons = true,
  autoReloadFromInventory = true,
  ammoSaveIntervalMs = 5000,
  ammoUpdateMinIntervalMs = 750,
  unauthorizedLogIntervalMs = 5000,
  bodyAttachments = {
    presets = {
      primary_back = {
        bone = 24818,
        position = { x = 0.08, y = -0.16, z = 0.02 },
        rotation = { x = 0.0, y = 165.0, z = 0.0 }
      },
      sidearm_hip = {
        bone = 51826,
        position = { x = -0.01, y = 0.10, z = 0.07 },
        rotation = { x = -115.0, y = 0.0, z = 0.0 }
      },
      melee_hip = {
        bone = 58271,
        position = { x = -0.04, y = 0.02, z = -0.12 },
        rotation = { x = -80.0, y = 0.0, z = 20.0 }
      },
      special_hip = {
        bone = 51826,
        position = { x = 0.10, y = 0.03, z = -0.08 },
        rotation = { x = -90.0, y = 0.0, z = 0.0 }
      }
    },
    items = {
      weapon_pistol = { model = 'w_pi_pistol', preset = 'sidearm_hip' },
      weapon_smg = { model = 'w_sb_smg', preset = 'primary_back' },
      weapon_pumpshotgun = { model = 'w_sg_pumpshotgun', preset = 'primary_back' },
      weapon_carbinerifle = { model = 'w_ar_carbinerifle', preset = 'primary_back' },
      weapon_sniperrifle = { model = 'w_sr_sniperrifle', preset = 'primary_back' },
      weapon_mg = { model = 'w_mg_mg', preset = 'primary_back' },
      weapon_knife = { model = 'w_me_knife_01', preset = 'melee_hip' },
      weapon_stungun = { model = 'w_pi_stungun', preset = 'special_hip' }
    }
  },
  ammoTypes = {
    ammo_pistol = { label = 'Municao de Pistola', reloadAmount = 1, maxAmmo = 120 },
    ammo_smg = { label = 'Municao de SMG', reloadAmount = 1, maxAmmo = 180 },
    ammo_shotgun = { label = 'Cartucho Calibre 12', reloadAmount = 1, maxAmmo = 48 },
    ammo_rifle = { label = 'Municao de Fuzil', reloadAmount = 1, maxAmmo = 210 },
    ammo_sniper = { label = 'Municao de Sniper', reloadAmount = 1, maxAmmo = 40 },
    ammo_heavy = { label = 'Municao Pesada', reloadAmount = 1, maxAmmo = 100 },
    ammo_rpg = { label = 'Foguete RPG', reloadAmount = 1, maxAmmo = 5 }
  }
}

Config.SecurityCanary = {
  enabled = true,
  cooldownMs = 5000
}
