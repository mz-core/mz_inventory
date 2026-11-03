const SHOW_DEBUG_ITEM_INFO = false;

const state = {
  uiVisible: false,
  rootVisibleApplied: null,
  session: createDefaultSession(),
  localError: null,
  dragUi: createDefaultDragUi(),
  splitModal: createDefaultSplitModal(),
  contextMenu: createDefaultContextMenu(),
  shortcutPickerOpen: false,
};

const els = {
  app: document.getElementById("app"),
  workspace: document.getElementById("workspace"),
  viewTitle: document.getElementById("view-title"),
  viewSubtitle: document.getElementById("view-subtitle"),
  errorBanner: document.getElementById("error-banner"),
  actionBanner: document.getElementById("action-banner"),
  actionRail: document.getElementById("action-rail"),
  refreshBtn: document.getElementById("refresh-btn"),
  closeBtn: document.getElementById("close-btn"),
  playerName: document.getElementById("player-name"),
  playerStats: document.getElementById("player-stats"),
  playerGrid: document.getElementById("player-grid"),
  equipmentGrid: document.getElementById("equipment-grid"),
  weaponEquipmentGrid: document.getElementById("weapon-equipment-grid"),
  playerSummaryName: document.getElementById("player-summary-name"),
  playerSummaryMonogram: document.getElementById("player-summary-monogram"),
  playerSummaryWallet: document.getElementById("player-summary-wallet"),
  playerSummaryBank: document.getElementById("player-summary-bank"),
  playerSummaryCitizenId: document.getElementById("player-summary-citizenid"),
  targetPane: document.getElementById("target-pane"),
  targetName: document.getElementById("target-name"),
  targetStats: document.getElementById("target-stats"),
  targetGrid: document.getElementById("target-grid"),
  targetEquipmentSection: document.getElementById("target-equipment-section"),
  targetEquipmentName: document.getElementById("target-equipment-name"),
  targetEquipmentStats: document.getElementById("target-equipment-stats"),
  targetEquipmentGrid: document.getElementById("target-equipment-grid"),
  selectionTitle: document.getElementById("selection-title"),
  selectionSubtitle: document.getElementById("selection-subtitle"),
  selectionDetails: document.getElementById("selection-details"),
  useBtn: document.getElementById("use-btn"),
  equipBtn: document.getElementById("equip-btn"),
  splitBtn: document.getElementById("split-btn"),
  dropBtn: document.getElementById("drop-btn"),
  giveBtn: document.getElementById("give-btn"),
  shortcutBtn: document.getElementById("shortcut-btn"),
  shortcutPicker: document.getElementById("shortcut-picker"),
  cancelSelectionBtn: document.getElementById("cancel-selection-btn"),
  cancelSplitBtn: document.getElementById("cancel-split-btn"),
  hotbarGrid: document.getElementById("hotbar-grid"),
  splitModal: document.getElementById("split-modal"),
  splitModalTitle: document.getElementById("split-modal-title"),
  splitModalSubtitle: document.getElementById("split-modal-subtitle"),
  splitRange: document.getElementById("split-range"),
  splitAmountInput: document.getElementById("split-amount-input"),
  splitConfirmBtn: document.getElementById("split-confirm-btn"),
  splitCancelBtn: document.getElementById("split-cancel-btn"),
  splitModalCloseBtn: document.getElementById("split-modal-close-btn"),
  itemTooltip: document.getElementById("item-tooltip"),
  dragGhost: document.getElementById("drag-ghost"),
  dragGhostFallback: document.getElementById("drag-ghost-fallback"),
  dragGhostLabel: document.getElementById("drag-ghost-label"),
  dragGhostAmount: document.getElementById("drag-ghost-amount"),
  slotMenu: document.getElementById("slot-menu"),
  menuSelectBtn: document.getElementById("menu-select-btn"),
  menuUseBtn: document.getElementById("menu-use-btn"),
  menuSplitBtn: document.getElementById("menu-split-btn"),
  menuDropBtn: document.getElementById("menu-drop-btn"),
  menuGiveBtn: document.getElementById("menu-give-btn"),
  menuThirdPartyBtn: document.getElementById("menu-third-party-btn"),
  menuCancelBtn: document.getElementById("menu-cancel-btn"),
  nuiBuildBadge: document.getElementById("nui-build-badge"),
};

const UI_BUILD = "20261011inventorysubmenu1";
const BRL_FORMATTER = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
  maximumFractionDigits: 0,
});

const AMMO_TYPE_LABELS = {
  ammo_pistol: "Pistola",
  ammo_smg: "SMG",
  ammo_shotgun: "Calibre 12",
  ammo_rifle: "Fuzil",
  ammo_sniper: "Sniper",
  ammo_heavy: "Pesada",
  ammo_rpg: "RPG",
};

const WEAPON_CLASS_LABELS = {
  ammo_pistol: "Arma curta",
  ammo_smg: "Arma autom\u00e1tica",
  ammo_shotgun: "Arma calibre 12",
  ammo_rifle: "Arma longa",
  ammo_sniper: "Arma de precis\u00e3o",
  ammo_heavy: "Arma pesada",
  ammo_rpg: "Lan\u00e7ador",
};

const ITEM_IMAGE_SOURCES = [
  { type: "resource", resource: "mz_assets", path: "itens" },
];

const ITEM_IMAGE_EXTENSIONS = ["png", "PNG", "webp"];
const ITEM_IMAGE_ALIASES = {
  cellphone: "phone",
  jerrycan: "jerry_can",
  ammo_pistol: "pistol_ammo",
  ammo_smg: "smg_ammo",
  ammo_shotgun: "shotgun_ammo",
  ammo_rifle: "rifle_ammo",
};
const ITEM_IMAGE_PLACEHOLDER = "assets/icons/equipment/backpack.svg";

function logUiStage(stage, details) {
  try {
    console.info(`[mz_inventory/ui][${stage}]`, details || {});
  } catch (_) {
    console.info(`[mz_inventory/ui][${stage}]`);
  }
}

function showDebugBuild(clientBuild) {
  const requestedBuild = String(clientBuild || "").trim();
  const matchesClient = requestedBuild === "" || requestedBuild === UI_BUILD;
  const marker = `[MZ Inventory NUI] build=${UI_BUILD}`;

  document.documentElement.dataset.nuiBuild = UI_BUILD;
  if (els.nuiBuildBadge) {
    els.nuiBuildBadge.textContent = matchesClient
      ? marker
      : `${marker} client=${requestedBuild} MISMATCH`;
    els.nuiBuildBadge.classList.remove("is-hidden");
  }

  console.info(marker, {
    client_build: requestedBuild || null,
    match: matchesClient,
  });
}

document.documentElement.dataset.nuiBuild = UI_BUILD;

const missingEls = Object.entries(els)
  .filter(([, value]) => !value)
  .map(([key]) => key);

logUiStage("boot", {
  missing_elements: missingEls,
  get_parent_resource_name: typeof GetParentResourceName,
});

function forceNuiTransparency() {
  [
    document.documentElement,
    document.body,
    els.app,
    els.workspace,
    document.querySelector(".shell"),
  ].forEach((element) => {
    if (!element) {
      return;
    }

    element.style.setProperty("background", "transparent", "important");
    element.style.setProperty("background-color", "transparent", "important");
    element.style.setProperty("background-image", "none", "important");
  });
}

function createDefaultSession() {
  return {
    isOpen: false,
    isLoading: false,
    context: {
      player: { type: "player" },
      equipment: { type: "equipment" },
      target: null,
      targetEquipment: null,
    },
    snapshots: {
      player: null,
      equipment: null,
      target: null,
    },
    profile: null,
    thirdParty: null,
    selectedSlot: null,
    dragState: {
      active: false,
      descriptor: null,
      container: null,
      slot: null,
      item: null,
    },
    splitState: {
      active: false,
      descriptor: null,
      container: null,
      from_slot: null,
      max_amount: 0,
      amount: 1,
      item: null,
    },
    actionState: {
      busy: false,
      type: null,
      label: null,
    },
    hotbar: [],
    lastError: null,
  };
}

function createDefaultDragUi() {
  return {
    source: null,
    dropTarget: null,
    dropHandled: false,
    pending: null,
    suppressClick: false,
    pointerX: 0,
    pointerY: 0,
  };
}

function createDefaultSplitModal() {
  return {
    mode: "split",
    open: false,
    container: null,
    slot: null,
    amount: 1,
    maxAmount: 1,
    itemLabel: "",
  };
}

function createDefaultContextMenu() {
  return {
    open: false,
    x: 0,
    y: 0,
    container: null,
    slot: null,
  };
}

function syncRootVisibility() {
  forceNuiTransparency();

  const visible = state.uiVisible === true;
  const root = document.documentElement;

  root.classList.toggle("nui-visible", visible);
  root.classList.toggle("nui-closed", !visible);

  document.body.classList.toggle("nui-visible", visible);
  document.body.classList.toggle("nui-closed", !visible);

  els.app.classList.toggle("is-hidden", visible !== true);

  if (state.rootVisibleApplied !== visible) {
    state.rootVisibleApplied = visible;
    logUiStage("root_visibility", {
      ui_visible: visible,
      html_class: root.className,
      body_class: document.body.className,
      app_hidden: els.app.classList.contains("is-hidden"),
    });
  }
}

function cloneValue(value) {
  if (Array.isArray(value)) {
    return value.map(cloneValue);
  }

  if (value && typeof value === "object") {
    const out = {};
    Object.keys(value).forEach((key) => {
      out[key] = cloneValue(value[key]);
    });
    return out;
  }

  return value;
}

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function normalizeSession(session) {
  const base = createDefaultSession();
  if (!session || typeof session !== "object") {
    return base;
  }

  base.isOpen = session.isOpen === true;
  base.isLoading = session.isLoading === true;
  base.context = cloneValue(session.context || base.context);
  base.snapshots = cloneValue(session.snapshots || base.snapshots);
  base.profile = session.profile && typeof session.profile === "object"
    ? cloneValue(session.profile)
    : null;
  base.thirdParty = session.thirdParty && typeof session.thirdParty === "object"
    ? cloneValue(session.thirdParty) : null;
  base.selectedSlot =
    session.selectedSlot && typeof session.selectedSlot === "object"
      ? cloneValue(session.selectedSlot)
      : null;
  base.dragState =
    session.dragState && typeof session.dragState === "object"
      ? cloneValue(session.dragState)
      : base.dragState;
  base.splitState =
    session.splitState && typeof session.splitState === "object"
      ? cloneValue(session.splitState)
      : base.splitState;
  base.actionState =
    session.actionState && typeof session.actionState === "object"
      ? cloneValue(session.actionState)
      : base.actionState;
  base.hotbar = normalizeHotbar(session.hotbar);
  base.lastError =
    session.lastError && typeof session.lastError === "object"
      ? cloneValue(session.lastError)
      : null;

  return base;
}

function normalizeHotbar(rawHotbar) {
  const source = Array.isArray(rawHotbar)
    ? rawHotbar
    : rawHotbar && typeof rawHotbar === "object"
      ? Object.values(rawHotbar)
      : [];
  const bySlot = new Map();

  source.forEach((entry) => {
    if (!entry || typeof entry !== "object") {
      return;
    }

    const slot = Number(entry.hotbar_slot || entry.hotbarSlot || entry.slot || 0);
    if (slot >= 5 && slot <= 9) {
      bySlot.set(slot, entry);
    }
  });

  return Array.from({ length: 5 }, (_, index) => {
    const slot = index + 5;
    const entry = bySlot.get(slot);
    if (!entry || entry.occupied !== true) {
      return {
        hotbar_slot: slot,
        occupied: false,
      };
    }

    const itemId = String(entry.item_id || entry.item || entry.name || "").trim();
    if (!itemId) {
      return {
        hotbar_slot: slot,
        occupied: false,
      };
    }

    return {
      ...cloneValue(entry),
      hotbar_slot: slot,
      occupied: true,
      item_id: itemId,
      item: itemId,
      label: String(entry.label || itemId),
      amount: Number(entry.amount || 1),
      metadata:
        entry.metadata && typeof entry.metadata === "object"
          ? cloneValue(entry.metadata)
          : {},
    };
  });
}

function hasValidPlayerSnapshot(session) {
  const snapshots =
    session && typeof session === "object" ? session.snapshots : null;
  const playerSnapshot =
    snapshots && typeof snapshots === "object" ? snapshots.player : null;

  return !!(
    playerSnapshot &&
    typeof playerSnapshot === "object" &&
    playerSnapshot.container &&
    typeof playerSnapshot.container === "object" &&
    Array.isArray(playerSnapshot.slots)
  );
}

async function postNui(action, payload) {
  const response = await fetch(`https://${GetParentResourceName()}/${action}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(payload || {}),
  }).catch(() => null);

  if (!response) {
    return null;
  }

  try {
    return await response.json();
  } catch (_) {
    return null;
  }
}

function setLocalError(message) {
  state.localError = String(message || "").trim() || null;
  render();
}

function clearLocalError() {
  state.localError = null;
}

function clearDragUi() {
  hideDragGhost();
  state.dragUi = createDefaultDragUi();
}

function closeSplitModal() {
  state.splitModal = createDefaultSplitModal();
}

function closeContextMenu() {
  state.contextMenu = createDefaultContextMenu();
}

function resetLocalUiState() {
  clearDragUi();
  closeSplitModal();
  closeContextMenu();
  state.shortcutPickerOpen = false;
}

function isBusy() {
  return state.session.actionState && state.session.actionState.busy === true;
}

function formatWeight(weight) {
  const value = Number(weight || 0);
  if (value >= 1000) {
    return `${(value / 1000).toFixed(value % 1000 === 0 ? 0 : 1)} kg`;
  }

  return `${value} g`;
}

function getWeightTone(percentage) {
  if (percentage >= 100) {
    return "danger";
  }

  if (percentage >= 80) {
    return "warning";
  }

  return "success";
}

function getItemMonogram(slot) {
  const label = String((slot && (slot.label || slot.item_id)) || "").trim();
  if (!label) {
    return "--";
  }

  const parts = label.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }

  return label.slice(0, 2).toUpperCase();
}

function sanitizeAssetPath(rawValue) {
  const value = String(rawValue || "")
    .trim()
    .replace(/\\/g, "/");
  if (!value) {
    return "";
  }

  return value
    .replace(/^\/+/, "")
    .split("/")
    .filter((part) => part && part !== "." && part !== "..")
    .join("/");
}

function splitAssetName(value) {
  const normalized = sanitizeAssetPath(value);
  if (!normalized) {
    return { name: "", extension: "" };
  }

  const match = normalized.match(/^(.*)\.([a-z0-9]+)$/i);
  if (!match) {
    return { name: normalized, extension: "" };
  }

  return {
    name: match[1],
    extension: match[2].toLowerCase(),
  };
}

function getNuiResourceBaseUrl() {
  try {
    if (typeof GetParentResourceName === "function") {
      const resourceName = String(GetParentResourceName() || "").trim();
      if (resourceName) {
        return `https://cfx-nui-${resourceName}`;
      }
    }
  } catch (_) {
    // Ignore and fall back to relative paths below.
  }

  return "";
}

function buildImageUrl(source, assetName, extension) {
  const cleanAssetName = sanitizeAssetPath(assetName);
  const fileName = extension
    ? `${cleanAssetName}.${extension}`
    : cleanAssetName;

  if (!cleanAssetName) {
    return "";
  }

  if (source && source.type === "remote") {
    const baseUrl = String(source.baseUrl || "")
      .trim()
      .replace(/\/+$/, "");
    if (!baseUrl) {
      return "";
    }

    return `${baseUrl}/${fileName}`;
  }

  const cleanSourcePath = sanitizeAssetPath(source && source.path);

  if (source && source.type === "resource") {
    const resourceName = String(source.resource || "").trim();
    if (!resourceName) {
      return "";
    }

    const fullPath = cleanSourcePath
      ? `${cleanSourcePath}/${fileName}`
      : fileName;
    return `https://cfx-nui-${resourceName}/${fullPath}`;
  }

  const localPath = cleanSourcePath
    ? `${cleanSourcePath}/${fileName}`
    : fileName;

  // No FiveM, usar a URL absoluta da resource evita falha de resolução/cache
  // em alguns casos do Chromium/NUI. No navegador comum, mantém relativo.
  const baseUrl = getNuiResourceBaseUrl();
  return baseUrl ? baseUrl + "/web/" + localPath : localPath;
}

function buildItemImageCandidates(item) {
  if (!item || typeof item !== "object") {
    return [];
  }

  const metadata =
    item.metadata && typeof item.metadata === "object" ? item.metadata : {};
  const rawOverride = [
    item.image,
    item.icon,
    item.img,
    item.name,
    item.item,
    item.item_name,
    item.itemName,
    metadata.image,
    metadata.icon,
    metadata.img,
    metadata.inventory_image,
    metadata.inventory_icon,
  ].find((value) => typeof value === "string" && value.trim().length > 0);

  const rawNames = [];
  if (rawOverride) {
    rawNames.push(rawOverride);
  }

  [
    item.item_id,
    item.name,
    item.item,
    item.item_name,
    item.itemName,
    item.id,
  ].forEach((value) => {
    if (typeof value === "string" && value.trim().length > 0) {
      rawNames.push(value);
    }
  });

  const candidates = [];
  const seen = new Set();

  rawNames.forEach((rawName) => {
    const directValue = String(rawName || "").trim();
    if (!directValue) {
      return;
    }

    if (/^(https?:|nui:\/\/)/i.test(directValue)) {
      if (/^https:\/\/cfx-nui-mz_assets\/itens\//i.test(directValue) && !seen.has(directValue)) {
        seen.add(directValue);
        candidates.push(directValue);
      }
      return;
    }

    const asset = splitAssetName(directValue);
    if (!asset.name) {
      return;
    }

    const names = [asset.name, ITEM_IMAGE_ALIASES[asset.name.toLowerCase()]].filter(Boolean);
    const extensions = [...new Set([asset.extension, ...ITEM_IMAGE_EXTENSIONS].filter(Boolean))];
    ITEM_IMAGE_SOURCES.forEach((source) => {
      names.forEach((name) => extensions.forEach((extension) => {
        const candidateUrl = buildImageUrl(source, name, extension);
        if (candidateUrl && !seen.has(candidateUrl)) {
          seen.add(candidateUrl);
          candidates.push(candidateUrl);
        }
      }));
    });
  });

  candidates.push(ITEM_IMAGE_PLACEHOLDER);
  return candidates;
}

function bindItemImage(root, item, options = {}) {
  const imageSelector = options.imageSelector || ".slot-image";
  const imageElement = root.querySelector(imageSelector);
  if (!imageElement) {
    return;
  }

  const candidates = buildItemImageCandidates(item);
  if (!candidates.length) {
    console.info("[mz_inventory/image] no_candidates", {
      item_id: item && item.item_id,
      label: item && item.label,
    });
    return;
  }

  console.info("[mz_inventory/image] candidates", {
    item_id: item && item.item_id,
    label: item && item.label,
    candidates,
  });

  let currentIndex = 0;
  imageElement.alt = String((item && (item.label || item.item_id)) || "Item");

  const loadNextCandidate = () => {
    if (currentIndex >= candidates.length) {
      imageElement.classList.add("is-hidden");
      imageElement.removeAttribute("src");
      return;
    }

    imageElement.src = candidates[currentIndex];
    currentIndex += 1;
  };

  imageElement.onload = () => {
    console.info("[mz_inventory/image] loaded", {
      item_id: item && item.item_id,
      src: imageElement.src,
    });
    imageElement.classList.remove("is-hidden");
  };

  imageElement.onerror = () => {
    console.warn("[mz_inventory/image] failed", {
      item_id: item && item.item_id,
      attempted: candidates[currentIndex - 1] || null,
    });
    loadNextCandidate();
  };

  loadNextCandidate();
}

function moveDragGhost(clientX, clientY) {
  if (!els.dragGhost || els.dragGhost.classList.contains("is-hidden")) {
    return;
  }

  const x = Number(clientX || 0);
  const y = Number(clientY || 0);
  state.dragUi.pointerX = x;
  state.dragUi.pointerY = y;
  els.dragGhost.style.transform = `translate3d(${x + 16}px, ${y + 16}px, 0)`;
}

function showDragGhost(item, clientX, clientY) {
  if (!els.dragGhost || !item) {
    return;
  }

  const label = String(item.label || item.item_id || "Item");
  const amount = Math.max(Number(item.amount || 1), 1);
  const image = els.dragGhost.querySelector(".drag-ghost-image");

  if (image) {
    image.classList.add("is-hidden");
    image.removeAttribute("src");
  }

  els.dragGhostFallback.textContent = getItemMonogram(item);
  els.dragGhostLabel.textContent = label;
  els.dragGhostAmount.textContent = `x${amount}`;
  els.dragGhost.classList.remove("is-hidden");
  document.body.classList.add("inventory-dragging");
  bindItemImage(els.dragGhost, item, {
    imageSelector: ".drag-ghost-image",
  });
  moveDragGhost(clientX, clientY);
}

function hideDragGhost() {
  if (els.dragGhost) {
    els.dragGhost.classList.add("is-hidden");
  }
  document.body.classList.remove("inventory-dragging");
}

function getContainerTitle(snapshot, fallback) {
  const container = snapshot && snapshot.container ? snapshot.container : {};
  const label = String(container.label || "").trim();
  const model = String(container.model || "").trim();
  const plate = String(container.plate || "").trim();
  const orgCode = String(container.org_code || "").trim();
  const dropUid = String(container.drop_uid || "").trim();

  const knownLabels = {
    player_main: "Inventario principal",
    vehicle_trunk: "Porta-malas",
    vehicle_glovebox: "Porta-luvas",
    personal_stash: "Bau pessoal",
    org_stash: "Bau da organizacao",
    world_drop: "Drop no mundo",
  };

  if (label && knownLabels[label]) {
    return knownLabels[label];
  }

  if (label) {
    return label.replace(/_/g, " ");
  }

  if (plate) {
    return `${fallback} ${plate}`;
  }

  if (model) {
    return `${fallback} ${model}`;
  }

  if (orgCode) {
    return `${fallback} ${orgCode}`;
  }

  if (dropUid) {
    return `${fallback} ${dropUid}`;
  }

  return fallback;
}

function getContainerStats(snapshot) {
  const container = snapshot && snapshot.container ? snapshot.container : {};
  const slotCount = Number(container.slot_count || 0);
  const maxSlots = Number(container.max_slots || 0);
  const currentWeight = Number(container.current_weight || 0);
  const maxWeight = Number(container.max_weight || 0);

  return [
    `${slotCount}/${maxSlots} slots`,
    `${formatWeight(currentWeight)} / ${formatWeight(maxWeight)}`,
  ].join(" | ");
}

function summarizeMetadata(metadata) {
  if (!metadata || typeof metadata !== "object") {
    return "";
  }

  const keys = Object.keys(metadata);
  if (keys.length === 0) {
    return "";
  }

  const serial = String(metadata.serial || "").trim();
  if (serial) {
    return `serial: ${serial}`;
  }

  const owner = String(metadata.owner || "").trim();
  if (owner) {
    return `owner: ${owner}`;
  }

  return `${keys.length} metadado(s)`;
}

function getSelectionChips(item) {
  const chips = [];

  if (!item || typeof item !== "object") {
    return chips;
  }

  if (item.usable === true) {
    chips.push("Usável");
  }

  if (item.stack === true) {
    chips.push("Stack");
  }

  if (item.unique === true) {
    chips.push("Único");
  }

  return chips;
}

function getItemMetadata(item) {
  return item && item.metadata && typeof item.metadata === "object"
    ? item.metadata
    : {};
}

function getFirstTextValue(item, keys) {
  const metadata = getItemMetadata(item);

  for (const key of keys) {
    const value =
      Object.prototype.hasOwnProperty.call(item || {}, key) === true
        ? item[key]
        : metadata[key];
    const text = String(value || "").trim();
    if (text) {
      return text;
    }
  }

  return "";
}

function getFirstNumberValue(item, keys) {
  const metadata = getItemMetadata(item);

  for (const key of keys) {
    const rawValue =
      Object.prototype.hasOwnProperty.call(item || {}, key) === true
        ? item[key]
        : metadata[key];
    const value = Number(rawValue);
    if (Number.isFinite(value)) {
      return value;
    }
  }

  return null;
}

function getFriendlyCategory(item) {
  const type = String(item && (item.type || item.category) || "").toLowerCase();
  const itemId = String(item && item.item_id || "").toLowerCase();

  if (
    type === "weapon" ||
    (item && item.weapon) ||
    itemId.startsWith("weapon_")
  ) {
    return "Arma";
  }

  if (
    type === "ammo" ||
    (item && item.ammoType) ||
    itemId.startsWith("ammo_")
  ) {
    return "Muni\u00e7\u00e3o";
  }

  if (item && item.usable === true) {
    return "Consum\u00edvel";
  }

  return "Item";
}

function getFriendlyItemSubtitle(item, category) {
  const ammoType = getFirstTextValue(item, ["ammoType", "ammo_type"]);

  if (category === "Arma") {
    return WEAPON_CLASS_LABELS[ammoType] || "Arma";
  }

  if (category === "Muni\u00e7\u00e3o") {
    return "Muni\u00e7\u00e3o";
  }

  return category;
}

function getFriendlyAmmoType(item) {
  const ammoType = getFirstTextValue(item, ["ammoType", "ammo_type"]);
  return AMMO_TYPE_LABELS[ammoType] || ammoType || "";
}

function getDisplayWeight(item) {
  const totalWeight = Number(item && item.total_weight);
  if (Number.isFinite(totalWeight) && totalWeight > 0) {
    return totalWeight;
  }

  const unitWeight = Number(item && item.weight || 0);
  const amount = Number(item && item.amount || 0);
  if (unitWeight > 0 && amount > 1) {
    return unitWeight * amount;
  }

  return unitWeight;
}

function formatDurability(value) {
  const durability = Number(value);
  if (!Number.isFinite(durability)) {
    return "";
  }

  return `${Math.max(0, Math.min(100, Math.round(durability)))}%`;
}

function getItemDescription(item) {
  return getFirstTextValue(item, [
    "description",
    "desc",
    "details",
    "info",
  ]);
}

function buildSelectionRow(label, value, extraClass) {
  if (value === null || value === undefined || value === "") {
    return "";
  }

  const className = extraClass ? ` ${extraClass}` : "";
  return `
    <div class="selection-row${className}">
      <strong>${escapeHtml(label)}</strong>
      <span title="${escapeHtml(String(value))}">${escapeHtml(String(value))}</span>
    </div>
  `;
}

function buildSelectionDebug(selected, item) {
  if (SHOW_DEBUG_ITEM_INFO !== true) {
    return "";
  }

  return `
    <div class="selection-debug">
      <div class="selection-debug-title">Debug</div>
      ${buildSelectionRow("Item interno", item.item_id || "-")}
      ${buildSelectionRow("Container", selected.container || "-")}
      ${buildSelectionRow("Slot", Number(selected.slot || 0))}
      <pre>${escapeHtml(stableStringify(item.metadata || {}))}</pre>
    </div>
  `;
}

function getContainerDescriptor(containerKey) {
  if (containerKey === "player") {
    return state.session.context.player || { type: "player" };
  }

  if (containerKey === "target") {
    return state.session.context.target || null;
  }

  if (containerKey === "equipment") {
    return state.session.context.equipment || { type: "equipment" };
  }

  return null;
}

function getSnapshot(containerKey) {
  return state.session.snapshots
    ? state.session.snapshots[containerKey] || null
    : null;
}

function isContainerInteractive(containerKey) {
  if (containerKey === "player" || containerKey === "equipment") {
    return true;
  }

  return !!getSnapshot(containerKey);
}

function isGroundDropPlaceholder(containerKey) {
  return containerKey === "target" && !getSnapshot("target");
}

function getSlotData(containerKey, slotNumber) {
  const snapshot = getSnapshot(containerKey);
  const slots = snapshot && Array.isArray(snapshot.slots) ? snapshot.slots : [];
  const parsedSlot = Number(slotNumber || 0);
  return slots.find((slot) => Number(slot.slot || 0) === parsedSlot) || null;
}

function getSelectedSlot() {
  return state.session.selectedSlot &&
    typeof state.session.selectedSlot === "object"
    ? state.session.selectedSlot
    : null;
}

function getSplitState() {
  return state.session.splitState &&
    typeof state.session.splitState === "object"
    ? state.session.splitState
    : createDefaultSession().splitState;
}

function getDragState() {
  const localSource = state.dragUi.source;
  if (localSource && typeof localSource === "object") {
    return {
      active: true,
      container: localSource.container,
      slot: localSource.slot,
      item:
        localSource.item ||
        getSlotData(localSource.container, localSource.slot),
    };
  }

  return state.session.dragState && typeof state.session.dragState === "object"
    ? state.session.dragState
    : createDefaultSession().dragState;
}

function isSlotSelected(containerKey, slotNumber) {
  const selected = getSelectedSlot();
  return (
    selected &&
    selected.container === containerKey &&
    Number(selected.slot || 0) === Number(slotNumber || 0)
  );
}

function isSplitSource(containerKey, slotNumber) {
  const splitState = getSplitState();
  return (
    splitState.active === true &&
    splitState.container === containerKey &&
    Number(splitState.from_slot || 0) === Number(slotNumber || 0)
  );
}

function isDragSource(containerKey, slotNumber) {
  const dragState = getDragState();
  return (
    dragState.active === true &&
    dragState.container === containerKey &&
    Number(dragState.slot || 0) === Number(slotNumber || 0)
  );
}

function isDropTarget(containerKey, slotNumber) {
  const dropTarget = state.dragUi.dropTarget;
  return (
    dropTarget &&
    dropTarget.container === containerKey &&
    Number(dropTarget.slot || 0) === Number(slotNumber || 0)
  );
}

function isHotbarDropTarget(hotbarSlot) {
  const dropTarget = state.dragUi.dropTarget;
  return (
    dropTarget &&
    dropTarget.container === "hotbar" &&
    Number(dropTarget.slot || 0) === Number(hotbarSlot || 0)
  );
}

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map((entry) => stableStringify(entry)).join(",")}]`;
  }

  if (value && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(",")}}`;
  }

  return JSON.stringify(value);
}

function canLikelyMergeSlots(sourceSlot, targetSlot) {
  if (!sourceSlot || !targetSlot) {
    return false;
  }

  if (sourceSlot.occupied !== true || targetSlot.occupied !== true) {
    return false;
  }

  if (String(sourceSlot.item_id || "") !== String(targetSlot.item_id || "")) {
    return false;
  }

  if (sourceSlot.stack !== true || targetSlot.stack !== true) {
    return false;
  }

  if (sourceSlot.unique === true || targetSlot.unique === true) {
    return false;
  }

  return (
    stableStringify(sourceSlot.metadata || {}) ===
    stableStringify(targetSlot.metadata || {})
  );
}

function resolveSlotOperation(
  fromContainer,
  sourceSlot,
  toContainer,
  targetSlot,
) {
  if (!sourceSlot || sourceSlot.occupied !== true) {
    return { type: "invalid", message: "Slot de origem invalido." };
  }

  if (
    fromContainer === toContainer &&
    Number(sourceSlot.slot || 0) ===
      Number((targetSlot && targetSlot.slot) || 0)
  ) {
    return { type: "noop" };
  }

  if (!targetSlot || targetSlot.occupied !== true) {
    return { type: "move" };
  }

  if (fromContainer === toContainer) {
    if (canLikelyMergeSlots(sourceSlot, targetSlot)) {
      return { type: "merge" };
    }

    return { type: "swap" };
  }

  return { type: "move" };
}

function getContextMenuSlot() {
  if (state.contextMenu.open !== true) {
    return null;
  }

  return getSlotData(state.contextMenu.container, state.contextMenu.slot);
}

function canDropSelectedSlot(slotData, containerKey) {
  return !!(
    slotData &&
    slotData.occupied === true &&
    String(containerKey || "") === "player"
  );
}

function canBindSelectedSlotToHotbar(slotData, containerKey) {
  return !!(
    slotData &&
    slotData.occupied === true &&
    slotData.usable === true &&
    slotData.type !== "weapon" &&
    String(containerKey || "") === "player"
  );
}

function clampSplitAmount(value, maxAmount) {
  const parsed = Number(value || 1);
  if (!Number.isFinite(parsed)) {
    return 1;
  }

  return Math.min(
    Math.max(Math.floor(parsed), 1),
    Math.max(Number(maxAmount || 1), 1),
  );
}

function buildSlotCard(slot, containerKey) {
  const card = document.createElement("article");
  const classNames = ["slot-card"];
  const splitState = getSplitState();

  if (!slot.occupied) {
    classNames.push("empty");
  } else {
    classNames.push("occupied");
  }

  if (slot.stack === true) {
    classNames.push("stackable");
  }

  if (slot.usable === true) {
    classNames.push("usable");
  }

  if (slot.unique === true) {
    classNames.push("unique");
  }

  if (slot.placeholder === true) {
    classNames.push("placeholder");
  }

  if (isSlotSelected(containerKey, slot.slot)) {
    classNames.push("selected");
  }

  if (isSplitSource(containerKey, slot.slot)) {
    classNames.push("split-source");
  }

  if (isDragSource(containerKey, slot.slot)) {
    classNames.push("drag-source");
  }

  if (isDropTarget(containerKey, slot.slot)) {
    classNames.push("drop-target");
  }

  if (
    splitState.active === true &&
    splitState.container === containerKey &&
    slot.occupied !== true
  ) {
    classNames.push("split-target");
  }

  card.className = classNames.join(" ");
  card.dataset.slot = String(slot.slot || 0);
  card.dataset.container = containerKey;
  card.draggable = false;

  const flags = [];
  if (slot.stack === true) {
    flags.push("stack");
  }
  if (slot.usable === true) {
    flags.push("usable");
  }
  if (slot.unique === true) {
    flags.push("unique");
  }

  const metadataText = summarizeMetadata(slot.metadata);
  const title = slot.occupied
    ? String(slot.label || slot.item_id || "Item")
    : "Slot vazio";
  const amountValue = Number(slot.amount || 0);
  const amountText =
    slot.occupied && amountValue > 1
      ? String(amountValue)
      : "";
  const weightText = slot.occupied ? formatWeight(slot.total_weight || 0) : "";
  const emblem = getItemMonogram(slot);
  const primaryTag =
    slot.stack === true
      ? "stack"
      : slot.usable === true
        ? "use"
        : slot.unique === true
          ? "unique"
          : "";
  card.setAttribute("aria-label", title);

  card.innerHTML = `
    <div class="slot-topline">
      <span class="slot-index">${Number(slot.slot || 0)}</span>
      <span class="slot-amount ${amountText ? "" : "slot-amount-empty"}">${amountText}</span>
    </div>
    <div class="slot-visual">
      ${
        slot.occupied
          ? `
        <div class="slot-stage">
          <div class="slot-glow"></div>
          <img class="slot-image" alt="">
          <div class="slot-emblem">${escapeHtml(emblem)}</div>
        </div>
      `
          : `<div class="slot-empty-mark"></div>`
      }
    </div>
    <div class="slot-bottom">
      <div class="slot-name">${escapeHtml(title)}</div>
      <div class="slot-meta-row">
        <span class="slot-weight">${escapeHtml(weightText)}</span>
        <span class="slot-tag">${escapeHtml(primaryTag || metadataText || "")}</span>
      </div>
    </div>
  `;

  if (slot.occupied) {
    bindItemImage(card, slot);
  }

  return card;
}

function normalizeSlots(snapshot, fallbackSlots) {
  const container = snapshot && snapshot.container ? snapshot.container : {};
  const rawSlots =
    snapshot && Array.isArray(snapshot.slots) ? snapshot.slots : [];
  const declaredMaxSlots = Math.max(0, Math.floor(Number(container.max_slots) || 0));
  const observedMaxSlot = rawSlots.reduce(
    (max, slot) => Math.max(max, Number(slot.slot || 0)),
    0,
  );
  const maxSlots = declaredMaxSlots > 0
    ? declaredMaxSlots
    : Math.max(observedMaxSlot, Number(fallbackSlots || 0));
  const bySlot = new Map();

  rawSlots.forEach((slot) => {
    const slotNumber = Number((slot && slot.slot) || 0);
    if (slotNumber > 0 && slotNumber <= maxSlots) {
      bySlot.set(slotNumber, slot);
    }
  });

  return Array.from({ length: maxSlots }, (_, index) => {
    const slotNumber = index + 1;
    return (
      bySlot.get(slotNumber) || {
        slot: slotNumber,
        occupied: false,
      }
    );
  });
}

function renderContainer(
  gridEl,
  titleEl,
  statsEl,
  snapshot,
  fallbackTitle,
  containerKey,
) {
  const container = snapshot && snapshot.container ? snapshot.container : {};
  const slotCount = Number(container.slot_count || 0);
  const maxSlots = Number(container.max_slots || 0);
  const currentWeight = Number(container.current_weight || 0);
  const maxWeight = Number(container.max_weight || 0);
  const percentage =
    maxWeight > 0 ? Math.min((currentWeight / maxWeight) * 100, 100) : 0;
  const weightTone = getWeightTone(percentage);

  titleEl.textContent = getContainerTitle(snapshot, fallbackTitle);
  statsEl.innerHTML = `
    <div class="pane-metrics">
      <div class="pane-metric-row">
        <span>${slotCount}/${maxSlots} slots</span>
        <span>${escapeHtml(formatWeight(currentWeight))} / ${escapeHtml(formatWeight(maxWeight))}</span>
      </div>
      <div class="pane-weight-bar">
        <div class="pane-weight-fill ${weightTone}" style="width: ${percentage}%"></div>
      </div>
    </div>
  `;
  gridEl.innerHTML = "";

  const baseSlots = Number(container.base_slots || 0);
  const extraSlots = Number(container.backpack_extra_slots || 0);
  normalizeSlots(snapshot, containerKey === "player" ? 30 : 0).forEach((slot) => {
    if (containerKey === "player" && extraSlots > 0 && Number(slot.slot) === baseSlots + 1) {
      const divider = document.createElement("div");
      divider.className = "backpack-divider";
      divider.innerHTML = `<span>MOCHILA</span><strong>+${extraSlots} slots</strong>`;
      gridEl.appendChild(divider);
    }
    gridEl.appendChild(buildSlotCard(slot, containerKey));
  });
}

function renderEquipment() {
  els.equipmentGrid.innerHTML = "";
  els.weaponEquipmentGrid.innerHTML = "";
  const dragState = getDragState();
  const dragItem = dragState.active === true ? dragState.item : null;
  const dragEquipmentSlot = dragItem && (dragItem.type === "clothing" || dragItem.type === "weapon")
    ? String(
        dragItem.equipment_slot ||
          dragItem.metadata?.clothing?.slot ||
          "",
      )
    : "";

  normalizeSlots(state.session.snapshots.equipment, 18).forEach((slot) => {
    const isWeaponSlot = slot.equipment_kind === "weapon";
    const card = buildSlotCard(slot, "equipment");
    card.classList.add("equipment-slot", isWeaponSlot ? "weapon-equipment-slot" : "clothing-equipment-slot");
    card.dataset.equipmentSlot = String(slot.equipment_slot || "");
    if (slot.disabled === true) card.classList.add("disabled");
    if (dragEquipmentSlot) {
      const compatible = slot.disabled !== true &&
        String(slot.equipment_slot || "") === dragEquipmentSlot;
      card.classList.add(compatible ? "drag-compatible" : "drag-incompatible");
    }
    const label = document.createElement("span");
    label.className = "equipment-slot-label";
    label.textContent = slot.equipment_label || slot.equipment_slot || `Slot ${slot.slot}`;
    card.appendChild(label);
    if (!slot.occupied && slot.placeholder_icon) {
      const emptyMark = card.querySelector(".slot-empty-mark");
      if (emptyMark) emptyMark.innerHTML = `<img class="equipment-placeholder-icon" src="assets/icons/equipment/${escapeHtml(slot.placeholder_icon)}" alt="">`;
    }
    if (isWeaponSlot) {
      const hotkey = document.createElement("kbd");
      hotkey.className = "weapon-equipment-key";
      hotkey.textContent = String(slot.hotkey || "");
      card.appendChild(hotkey);
      els.weaponEquipmentGrid.appendChild(card);
    } else {
      els.equipmentGrid.appendChild(card);
    }
  });
}

function renderPlayerSummary() {
  const profile = state.session.profile || {};
  const name = String(profile.name || "Jogador").trim() || "Jogador";
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toLocaleUpperCase("pt-BR"))
    .join("") || "--";

  els.playerSummaryName.textContent = name;
  els.playerSummaryMonogram.textContent = initials;
  const showLegacyBalances = profile.showLegacyBalances !== false;
  if (els.playerSummaryWallet.parentElement) els.playerSummaryWallet.parentElement.hidden = !showLegacyBalances;
  if (els.playerSummaryBank.parentElement) els.playerSummaryBank.parentElement.hidden = !showLegacyBalances;
  els.playerSummaryWallet.textContent = BRL_FORMATTER.format(Number(profile.wallet) || 0);
  els.playerSummaryBank.textContent = BRL_FORMATTER.format(Number(profile.bank) || 0);
  els.playerSummaryCitizenId.textContent = String(profile.citizenid || "--").trim() || "--";
}

function renderDropPlaceholder() {
  els.targetName.textContent = "Drop";
  els.targetStats.innerHTML = `
    <div class="pane-metrics">
      <div class="pane-metric-row">
        <span>0/30 slots</span>
        <span>Solte item aqui</span>
      </div>
      <div class="pane-weight-bar">
        <div class="pane-weight-fill" style="width: 0%"></div>
      </div>
    </div>
  `;
  els.targetGrid.innerHTML = "";

  Array.from({ length: 30 }, (_, index) => ({
    slot: index + 1,
    occupied: false,
    placeholder: true,
  })).forEach((slot) => {
    els.targetGrid.appendChild(buildSlotCard(slot, "target"));
  });
}

function renderError() {
  const errorData =
    state.session.lastError && typeof state.session.lastError === "object"
      ? state.session.lastError
      : null;

  const message =
    state.localError ||
    (errorData ? String(errorData.message || "").trim() : "");

  if (!message) {
    els.errorBanner.classList.add("is-hidden");
    els.errorBanner.textContent = "";
    return;
  }

  els.errorBanner.classList.remove("is-hidden");
  els.errorBanner.textContent = message;
}

function renderActionBanner() {
  const actionState = state.session.actionState || {};
  const splitState = getSplitState();
  const dragState = getDragState();

  let message = "";
  if (actionState.busy === true) {
    message = String(actionState.label || "Processando acao...");
  } else if (splitState.active === true) {
    message = `Divisao pendente: clique em um slot vazio no mesmo container para mover ${splitState.amount} item(ns).`;
  } else if (dragState.active === true) {
    message =
      "Arrastando item: solte em outro slot para mover, mesclar ou trocar.";
  }

  if (!message) {
    els.actionBanner.classList.add("is-hidden");
    els.actionBanner.textContent = "";
    return;
  }

  els.actionBanner.classList.remove("is-hidden");
  els.actionBanner.textContent = message;
}

function renderHotbar() {
  if (!els.hotbarGrid) {
    return;
  }

  const slots = normalizeHotbar(state.session.hotbar);
  els.hotbarGrid.innerHTML = "";

  slots.forEach((slot) => {
    const itemLabel = String(slot.label || slot.item_id || "");
    const occupied = slot.occupied === true;
    const amount = Number(slot.amount || 0);
    const card = document.createElement("div");
    card.className = `hotbar-slot ${occupied ? "occupied" : "empty"}${isHotbarDropTarget(slot.hotbar_slot) ? " drop-target" : ""}`;
    card.setAttribute(
      "aria-label",
      occupied ? `Hotbar ${slot.hotbar_slot}: ${itemLabel}` : `Hotbar ${slot.hotbar_slot}: vazio`,
    );
    card.dataset.hotbarSlot = String(slot.hotbar_slot);

    card.innerHTML = `
      <div class="hotbar-key">${Number(slot.hotbar_slot || 0)}</div>
      ${
        occupied
          ? `<button type="button" class="hotbar-clear" data-hotbar-slot="${Number(slot.hotbar_slot || 0)}" aria-label="Limpar atalho ${Number(slot.hotbar_slot || 0)}">x</button>`
          : ""
      }
      <div class="hotbar-icon">
        ${
          occupied
            ? `<img class="hotbar-image" alt=""><span class="hotbar-fallback">${escapeHtml(getItemMonogram(slot))}</span>`
            : `<span class="hotbar-empty-mark"></span>`
        }
      </div>
      <div class="hotbar-copy">
        <span class="hotbar-name">${escapeHtml(occupied ? itemLabel : "Vazio")}</span>
        <span class="hotbar-meta">${escapeHtml(occupied && amount > 1 ? `x${amount}` : occupied ? "Vinculado" : "Sem item")}</span>
      </div>
    `;

    if (occupied) {
      bindItemImage(card, slot, {
        imageSelector: ".hotbar-image",
      });
    }

    els.hotbarGrid.appendChild(card);
  });
}

function renderSelectionPanel() {
  const selected = getSelectedSlot();
  const splitState = getSplitState();
  const busy = isBusy();
  const hasSelection = Boolean(selected && selected.item);

  if (els.actionRail) {
    els.actionRail.classList.toggle("has-selection", hasSelection);
    els.actionRail.classList.toggle("has-split", splitState.active === true);
    els.actionRail.setAttribute("aria-hidden", hasSelection ? "false" : "true");
  }

  if (!hasSelection) {
    els.selectionTitle.textContent = "Nenhum item selecionado";
    els.selectionSubtitle.textContent =
      splitState.active === true
        ? "Escolha um slot vazio para concluir."
        : "";
    els.selectionDetails.innerHTML = `<div class="selection-empty">Nenhum item selecionado</div>`;
    els.useBtn.disabled = true;
    els.equipBtn.disabled = true;
    els.splitBtn.disabled = true;
    els.dropBtn.disabled = true;
    els.giveBtn.disabled = true;
    els.shortcutBtn.disabled = true;
    els.shortcutPicker.classList.add("is-hidden");
    els.shortcutPicker.setAttribute("aria-hidden", "true");
    els.cancelSelectionBtn.disabled = true;
    els.cancelSplitBtn.classList.toggle(
      "is-hidden",
      splitState.active !== true,
    );
    els.cancelSplitBtn.disabled = busy !== false;
    return;
  }

  const item = selected.item;
  const canUse = selected.container === "player" && item.usable === true;
  const canEquip = (item.type === "clothing" || item.type === "weapon") && (selected.container === "player" || selected.container === "equipment");
  const canSplit = !(state.session.thirdParty &&
    (selected.container === "target" || selected.container === "targetEquipment"))
    && item.stack === true && Number(item.amount || 0) > 1;
  const canDrop = canDropSelectedSlot(item, selected.container);
  const canGive = selected.container === "player";
  const canShortcut = canBindSelectedSlotToHotbar(item, selected.container);
  const itemTitle = String(item.label || item.item_id || "Item");
  const category = getFriendlyCategory(item);
  const itemSubtitle = getFriendlyItemSubtitle(item, category);
  const description = getItemDescription(item);
  const rows = [
    buildSelectionRow("Quantidade", Number(item.amount || 0)),
    buildSelectionRow("Peso", formatWeight(getDisplayWeight(item))),
  ];

  if (category === "Arma") {
    const ammo = getFirstNumberValue(item, ["ammo", "currentAmmo"]);
    const maxAmmo = getFirstNumberValue(item, ["maxAmmo", "max_ammo"]);
    const durability = getFirstNumberValue(item, ["durability"]);
    const serial = getFirstTextValue(item, ["serial"]);

    if (ammo !== null && maxAmmo !== null) {
      rows.push(buildSelectionRow("Muni\u00e7\u00e3o", `${ammo} / ${maxAmmo}`));
    } else if (ammo !== null) {
      rows.push(buildSelectionRow("Muni\u00e7\u00e3o", ammo));
    }

    rows.push(buildSelectionRow("Durabilidade", formatDurability(durability)));
    rows.push(buildSelectionRow("S\u00e9rie", serial, "selection-row-serial"));
  } else if (category === "Muni\u00e7\u00e3o") {
    const reloadAmount = getFirstNumberValue(item, [
      "reloadAmount",
      "reload_amount",
    ]);

    rows.push(buildSelectionRow("Tipo", getFriendlyAmmoType(item)));
    rows.push(
      buildSelectionRow(
        "Recarrega",
        reloadAmount !== null ? `+${reloadAmount}` : "",
      ),
    );
  }

  rows.push(buildSelectionRow("Slot", Number(selected.slot || 0), "muted"));

  els.selectionTitle.textContent = itemTitle;
  els.selectionSubtitle.textContent = itemSubtitle;
  els.selectionDetails.innerHTML = `
    <div class="selection-hero">
      <div class="selection-icon">
        <img class="selection-icon-image" alt="">
        <span class="selection-icon-fallback">${escapeHtml(getItemMonogram(item))}</span>
      </div>
    </div>
    ${description ? `<div class="selection-description">${escapeHtml(description)}</div>` : ""}
    <div class="selection-grid">
      ${rows.join("")}
    </div>
    ${buildSelectionDebug(selected, item)}
  `;
  bindItemImage(els.selectionDetails, item, {
    imageSelector: ".selection-icon-image",
  });

  els.useBtn.disabled = busy || !canUse;
  els.equipBtn.disabled = busy || !canEquip;
  els.equipBtn.textContent = selected.container === "equipment" ? "Retirar" : "Equipar";
  els.splitBtn.disabled = busy || !canSplit || splitState.active === true;
  els.dropBtn.disabled = busy || !canDrop;
  els.giveBtn.disabled = busy || !canGive;
  els.shortcutBtn.disabled = busy || !canShortcut;
  [
    [els.useBtn, canUse],
    [els.equipBtn, canEquip],
    [els.splitBtn, canSplit && splitState.active !== true],
    [els.dropBtn, canDrop],
    [els.giveBtn, canGive],
    [els.shortcutBtn, canShortcut],
  ].forEach(([button, available]) => {
    button.classList.toggle("is-unavailable", !available);
  });
  els.shortcutPicker.classList.toggle(
    "is-hidden",
    state.shortcutPickerOpen !== true || !canShortcut || busy,
  );
  els.shortcutPicker.setAttribute(
    "aria-hidden",
    state.shortcutPickerOpen === true && canShortcut && !busy ? "false" : "true",
  );
  els.cancelSelectionBtn.disabled = busy;
  els.cancelSplitBtn.classList.toggle("is-hidden", splitState.active !== true);
  els.cancelSplitBtn.disabled = busy !== false;
}

function renderToolbarState() {
  const actionState = state.session.actionState || {};
  const busy = actionState.busy === true;
  const targetContainer =
    state.session.snapshots.target && state.session.snapshots.target.container
      ? state.session.snapshots.target.container
      : null;
  const targetType = targetContainer
    ? String(targetContainer.type || "").trim()
    : "";

  if (els.refreshBtn) {
    els.refreshBtn.disabled = busy;
  }
  if (els.closeBtn) {
    els.closeBtn.disabled = false;
  }
  els.viewTitle.textContent = state.session.thirdParty?.labels?.title || "Inventario";
  els.viewSubtitle.textContent = busy
    ? String(actionState.label || "Processando acao...")
    : state.session.thirdParty
      ? state.session.thirdParty.labels?.target || "Inventário do alvo"
      : targetType
      ? `Player + ${targetType}`
      : "Player inventory";
}

function renderSplitModal() {
  const modal = state.splitModal;
  const open = modal.open === true;

  els.splitModal.classList.toggle("is-hidden", open !== true);
  els.splitModal.setAttribute("aria-hidden", open === true ? "false" : "true");

  if (!open) {
    return;
  }

  const amount = clampSplitAmount(modal.amount, modal.maxAmount);
  const isGive = modal.mode === "give";
  const thirdPartyAction = modal.mode === "thirdPartyTransfer" || modal.mode === "thirdPartySeize";
  els.splitModalTitle.textContent = isGive
    ? `Entregar ${modal.itemLabel || "item"}`
    : thirdPartyAction
      ? `${modal.mode === "thirdPartySeize" ? state.session.thirdParty?.labels?.seize : state.session.thirdParty?.labels?.take} ${modal.itemLabel || "item"}`
    : modal.itemLabel || "Dividir item";
  els.splitModalSubtitle.textContent = isGive
    ? `Escolha de 1 a ${modal.maxAmount}. O servidor entregara ao jogador mais proximo dentro do alcance permitido.`
    : thirdPartyAction
      ? state.session.thirdParty?.labels?.quantity || "Escolha a quantidade"
    : `Escolha uma quantidade entre 1 e ${modal.maxAmount}.`;
  els.splitConfirmBtn.textContent = thirdPartyAction
    ? modal.mode === "thirdPartySeize" ? state.session.thirdParty?.labels?.seize : state.session.thirdParty?.labels?.take
    : isGive ? "Entregar" : "Confirmar";
  els.splitRange.max = String(modal.maxAmount);
  els.splitRange.value = String(amount);
  els.splitAmountInput.max = String(modal.maxAmount);
  els.splitAmountInput.value = String(amount);
  els.splitConfirmBtn.disabled = isBusy();
  els.splitCancelBtn.disabled = isBusy();
  els.splitModalCloseBtn.disabled = isBusy();
}

function renderContextMenu() {
  const menu = state.contextMenu;
  const slotData = getContextMenuSlot();
  const splitState = getSplitState();
  const open = menu.open === true && slotData && slotData.occupied === true;

  els.slotMenu.classList.toggle("is-hidden", open !== true);
  els.slotMenu.setAttribute("aria-hidden", open === true ? "false" : "true");

  if (!open) {
    return;
  }

  const sameSelected = isSlotSelected(menu.container, menu.slot);
  const canEquip = (slotData.type === "clothing" || slotData.type === "weapon") && (menu.container === "player" || menu.container === "equipment");
  const canUse = (menu.container === "player" && slotData.usable === true) || canEquip;
  const thirdParty = state.session.thirdParty;
  const canSplit = !(thirdParty &&
    (menu.container === "target" || menu.container === "targetEquipment"))
    && slotData.stack === true && Number(slotData.amount || 0) > 1;
  const canDrop = canDropSelectedSlot(slotData, menu.container);
  const canGive = menu.container === "player";
  const thirdPartyAction = thirdParty
    && ((menu.container === "target" && thirdParty.mode === "civil_robbery")
      || ((menu.container === "target" || menu.container === "targetEquipment")
        && thirdParty.mode === "police_search" && thirdParty.canSeize === true));

  els.slotMenu.style.left = `${menu.x}px`;
  els.slotMenu.style.top = `${menu.y}px`;
  els.menuSelectBtn.textContent = sameSelected
    ? "Limpar selecao"
    : "Selecionar";
  els.menuUseBtn.disabled = !canUse || isBusy();
  els.menuUseBtn.textContent = canEquip ? (menu.container === "equipment" ? "Retirar" : "Equipar") : "Usar";
  els.menuSplitBtn.disabled =
    !canSplit || isBusy() || splitState.active === true;
  els.menuDropBtn.disabled = !canDrop || isBusy();
  els.menuGiveBtn.disabled = !canGive || isBusy();
  els.menuThirdPartyBtn.classList.toggle("is-hidden", !thirdPartyAction);
  els.menuThirdPartyBtn.disabled = !thirdPartyAction || isBusy();
  els.menuThirdPartyBtn.textContent = thirdParty?.mode === "police_search"
    ? thirdParty.labels?.seize || "Apreender" : thirdParty?.labels?.take || "Retirar";
}

function buildTooltipHtml(slotData, containerKey, slotNumber) {
  const label = String(slotData.label || slotData.item_id || "Item");
  const category = getFriendlyCategory(slotData);
  const rows = [];

  if (category === "Arma") {
    const ammo = getFirstNumberValue(slotData, ["ammo", "currentAmmo"]);
    const maxAmmo = getFirstNumberValue(slotData, ["maxAmmo", "max_ammo"]);
    const durability = getFirstNumberValue(slotData, ["durability"]);
    const serial = getFirstTextValue(slotData, ["serial"]);

    if (ammo !== null && maxAmmo !== null) {
      rows.push(buildTooltipRow("Muni\u00e7\u00e3o", `${ammo} / ${maxAmmo}`));
    } else if (ammo !== null) {
      rows.push(buildTooltipRow("Muni\u00e7\u00e3o", ammo));
    }

    rows.push(buildTooltipRow("Durabilidade", formatDurability(durability)));
    rows.push(buildTooltipRow("S\u00e9rie", serial, "tooltip-row-serial"));
    rows.push(buildTooltipRow("Slot", Number(slotNumber || 0), "muted"));
  } else if (category === "Muni\u00e7\u00e3o") {
    const reloadAmount = getFirstNumberValue(slotData, [
      "reloadAmount",
      "reload_amount",
    ]);

    rows.push(buildTooltipRow("Qtd", Number(slotData.amount || 0)));
    rows.push(buildTooltipRow("Tipo", getFriendlyAmmoType(slotData)));
    rows.push(
      buildTooltipRow(
        "Recarrega",
        reloadAmount !== null ? `+${reloadAmount}` : "",
      ),
    );
    rows.push(buildTooltipRow("Peso", formatWeight(getDisplayWeight(slotData))));
    rows.push(buildTooltipRow("Slot", Number(slotNumber || 0), "muted"));
  } else {
    rows.push(buildTooltipRow("Qtd", Number(slotData.amount || 0)));
    rows.push(buildTooltipRow("Peso", formatWeight(getDisplayWeight(slotData))));
    rows.push(buildTooltipRow("Slot", Number(slotNumber || 0), "muted"));
  }

  return `
    <h3 class="tooltip-title">${escapeHtml(label)}</h3>
    <div class="tooltip-category">${escapeHtml(category)}</div>
    <div class="tooltip-grid">
      ${rows.join("")}
    </div>
    ${buildTooltipDebug(slotData, containerKey, slotNumber)}
  `;
}

function buildTooltipRow(label, value, extraClass) {
  if (value === null || value === undefined || value === "") {
    return "";
  }

  const className = extraClass ? ` ${extraClass}` : "";
  return `
    <div class="tooltip-row${className}">
      <strong>${escapeHtml(label)}</strong>
      <span title="${escapeHtml(String(value))}">${escapeHtml(String(value))}</span>
    </div>
  `;
}

function buildTooltipDebug(slotData, containerKey, slotNumber) {
  if (SHOW_DEBUG_ITEM_INFO !== true) {
    return "";
  }

  const metadata = slotData.metadata || {};
  const hasMetadata =
    metadata && typeof metadata === "object" && Object.keys(metadata).length > 0;

  return `
    <div class="tooltip-debug">
      <div class="tooltip-debug-title">Debug</div>
      ${buildTooltipRow("Item interno", slotData.item_id || "-")}
      ${buildTooltipRow("Container", containerKey || "-")}
      ${buildTooltipRow("Slot", Number(slotNumber || 0))}
      ${hasMetadata ? `<pre>${escapeHtml(stableStringify(metadata))}</pre>` : ""}
    </div>
  `;
}

function moveTooltip(event) {
  if (!els.itemTooltip || els.itemTooltip.classList.contains("is-hidden")) {
    return;
  }

  const padding = 14;
  const tooltipRect = els.itemTooltip.getBoundingClientRect();
  const maxX = window.innerWidth - tooltipRect.width - padding;
  const maxY = window.innerHeight - tooltipRect.height - padding;
  const left = Math.max(padding, Math.min(event.clientX + 18, maxX));
  const top = Math.max(padding, Math.min(event.clientY + 18, maxY));

  els.itemTooltip.style.left = `${left}px`;
  els.itemTooltip.style.top = `${top}px`;
}

function showSlotTooltip(containerKey, slotNumber, event) {
  const slotData = getSlotData(containerKey, slotNumber);
  if (!els.itemTooltip || !slotData || slotData.occupied !== true) {
    hideSlotTooltip();
    return;
  }

  els.itemTooltip.innerHTML = buildTooltipHtml(
    slotData,
    containerKey,
    slotNumber,
  );
  els.itemTooltip.classList.remove("is-hidden");
  els.itemTooltip.setAttribute("aria-hidden", "false");
  moveTooltip(event);
}

function hideSlotTooltip() {
  if (!els.itemTooltip) {
    return;
  }

  els.itemTooltip.classList.add("is-hidden");
  els.itemTooltip.setAttribute("aria-hidden", "true");
  els.itemTooltip.innerHTML = "";
}

function render() {
  try {
    const session = state.session;

    syncRootVisibility();
    if (state.uiVisible !== true) {
      return;
    }

    renderToolbarState();
    renderError();
    renderActionBanner();
    renderContainer(
      els.playerGrid,
      els.playerName,
      els.playerStats,
      session.snapshots.player,
      "Inventario",
      "player",
    );
    renderEquipment();
    renderPlayerSummary();

    if (session.snapshots.target) {
      if (els.workspace) {
        els.workspace.dataset.hasTarget = "true";
      }
      els.targetPane.classList.remove("is-hidden");
      renderContainer(
        els.targetGrid,
        els.targetName,
        els.targetStats,
        session.snapshots.target,
        "Container",
        "target",
      );
      if (session.thirdParty?.labels?.target) {
        els.targetName.textContent = session.thirdParty.labels.target;
      }
      const targetEquipment = session.thirdParty && session.snapshots.targetEquipment;
      els.targetEquipmentSection.classList.toggle("is-hidden", !targetEquipment);
      if (targetEquipment) {
        renderContainer(els.targetEquipmentGrid, els.targetEquipmentName,
          els.targetEquipmentStats, targetEquipment, "Equipamento", "targetEquipment");
        if (session.thirdParty?.labels?.equipment) {
          els.targetEquipmentName.textContent = session.thirdParty.labels.equipment;
        }
      }
    } else {
      if (els.workspace) {
        els.workspace.dataset.hasTarget = "false";
      }
      els.targetPane.classList.add("is-hidden");
    }

    renderSelectionPanel();
    renderHotbar();
    renderSplitModal();
    renderContextMenu();
  } catch (error) {
    console.error(`[mz_inventory/ui][${UI_BUILD}][render_error]`, error);

    if (els.app) {
      els.app.classList.remove("is-hidden");
    }

    document.documentElement.classList.add("nui-visible");
    document.documentElement.classList.remove("nui-closed");
    document.body.classList.add("nui-visible");
    document.body.classList.remove("nui-closed");

    if (els.errorBanner) {
      els.errorBanner.classList.remove("is-hidden");
      els.errorBanner.textContent = `Falha ao renderizar a interface: ${error && error.message ? error.message : "erro desconhecido"}`;
    }
  }
}

async function handleActionResponse(actionPromise, options = {}) {
  const response = await actionPromise;
  if (response === null) {
    setLocalError("Nao foi possivel comunicar com a interface do inventario.");
    return false;
  }

  if (
    response &&
    response.ok === false &&
    response.error &&
    response.error.message
  ) {
    setLocalError(String(response.error.message));
    return false;
  }

  if (options.resetTransient === true) {
    resetLocalUiState();
  }

  clearLocalError();
  render();
  return true;
}

async function performResolvedOperation(
  fromContainer,
  fromSlot,
  toContainer,
  toSlot,
  sourceSlot,
  targetSlot,
) {
  const thirdParty = state.session.thirdParty;
  if (thirdParty && (fromContainer === "target" || toContainer === "target")) {
    if (thirdParty.mode !== "civil_robbery" || fromContainer !== "target" || toContainer !== "player") {
      setLocalError(thirdParty.labels?.blocked || "Ação indisponível nesta interação.");
      return false;
    }
    if (targetSlot?.occupied === true && !canLikelyMergeSlots(sourceSlot, targetSlot)) {
      setLocalError(thirdParty.labels?.invalidDestination || "Este destino não aceita o item.");
      return false;
    }
    const amount = Number(sourceSlot?.amount || 0);
    if (amount > 1) {
      openThirdPartyModal("thirdPartyTransfer", fromSlot, amount, toSlot, sourceSlot);
      return true;
    }
    return handleActionResponse(postNui("moveItem", {
      from_container: "target", from_slot: Number(fromSlot),
      to_container: "player", to_slot: Number(toSlot), amount: 1,
    }), { resetTransient: true });
  }
  const operation = resolveSlotOperation(
    fromContainer,
    sourceSlot,
    toContainer,
    targetSlot,
  );
  if (operation.type === "invalid") {
    setLocalError(operation.message || "Operacao invalida para este slot.");
    return false;
  }

  if (operation.type === "noop") {
    return true;
  }

  const payloadBase = {
    from_slot: Number(fromSlot || 0),
    to_slot: Number(toSlot || 0),
  };

  if (operation.type === "merge") {
    return handleActionResponse(
      postNui("mergeItem", {
        container: fromContainer,
        ...payloadBase,
      }),
      { resetTransient: true },
    );
  }

  if (operation.type === "swap") {
    return handleActionResponse(
      postNui("swapItem", {
        container: fromContainer,
        ...payloadBase,
      }),
      { resetTransient: true },
    );
  }

  return handleActionResponse(
    postNui("moveItem", {
      from_container: fromContainer,
      from_slot: Number(fromSlot || 0),
      to_container: toContainer,
      to_slot: Number(toSlot || 0),
    }),
    { resetTransient: true },
  );
}

async function handleUseSelected() {
  const selected = getSelectedSlot();
  if (!selected || !selected.item) {
    setLocalError("Selecione um item antes de usar.");
    return;
  }

  closeContextMenu();
  await handleActionResponse(
    postNui("useItem", {
      container: selected.container,
      slot: selected.slot,
    }),
    { resetTransient: true },
  );
}

async function handleToggleEquipment(container, slot, item) {
  if (!item || (item.type !== "clothing" && item.type !== "weapon")) {
    setLocalError("Este item nao pode ser equipado.");
    return;
  }
  closeContextMenu();
  await handleActionResponse(postNui("toggleEquipment", {
    container,
    slot,
    instance_uid: item.instance_uid,
    equipment_slot: item.equipment_slot,
  }), { resetTransient: true });
}

async function handleDropSelected() {
  const selected = getSelectedSlot();
  if (!selected || !selected.item) {
    setLocalError("Selecione um item antes de largar no chao.");
    return;
  }

  if (!canDropSelectedSlot(selected.item, selected.container)) {
    setLocalError("Somente itens do inventario do jogador podem ser largados no chao.");
    return;
  }

  closeContextMenu();
  await handleActionResponse(
    postNui("dropItem", {
      container: selected.container,
      slot: selected.slot,
    }),
    { resetTransient: true },
  );
}

async function bindInventorySlotToHotbar(inventorySlot, hotbarSlot) {
  const sourceSlot = Number(inventorySlot || 0);
  const targetSlot = Number(hotbarSlot || 0);
  if (!sourceSlot || !targetSlot) {
    setLocalError("Selecione um item e um atalho valido.");
    return false;
  }

  const ok = await handleActionResponse(
    postNui("bindHotbarSlot", {
      inventorySlot: sourceSlot,
      hotbarSlot: targetSlot,
    }),
    { resetTransient: true },
  );

  state.shortcutPickerOpen = false;
  void postNui("clearDrag");
  render();
  return ok;
}

async function clearHotbarSlot(hotbarSlot) {
  const targetSlot = Number(hotbarSlot || 0);
  if (!targetSlot) {
    setLocalError("Atalho invalido.");
    return false;
  }

  const ok = await handleActionResponse(
    postNui("clearHotbarSlot", {
      hotbarSlot: targetSlot,
    }),
    { resetTransient: true },
  );

  render();
  return ok;
}

async function bindSelectedSlotToHotbar(hotbarSlot) {
  const selected = getSelectedSlot();
  if (!selected || !selected.item) {
    setLocalError("Selecione um item antes de criar atalho.");
    return false;
  }

  if (!canBindSelectedSlotToHotbar(selected.item, selected.container)) {
    setLocalError("Somente itens usaveis do inventario podem ir para a hotbar.");
    return false;
  }

  closeContextMenu();
  return bindInventorySlotToHotbar(selected.slot, hotbarSlot);
}

function openSplitModalFor(containerKey, slotNumber) {
  if (getSplitState().active === true) {
    setLocalError(
      "Ja existe uma divisao pendente. Conclua ou cancele antes de abrir outra.",
    );
    return false;
  }

  const slotData = getSlotData(containerKey, slotNumber);
  if (!slotData || slotData.occupied !== true) {
    setLocalError("Selecione um item valido para dividir.");
    return false;
  }

  if (slotData.stack !== true || Number(slotData.amount || 0) <= 1) {
    setLocalError("Este item nao pode ser dividido.");
    return false;
  }

  state.splitModal = {
    mode: "split",
    open: true,
    container: containerKey,
    slot: Number(slotNumber || 0),
    amount: 1,
    maxAmount: Math.max(Number(slotData.amount || 0) - 1, 1),
    itemLabel: String(slotData.label || slotData.item_id || "Item"),
  };

  closeContextMenu();
  clearLocalError();
  render();
  return true;
}

function openGiveModalFor(containerKey, slotNumber) {
  if (getSplitState().active === true) {
    setLocalError("Conclua ou cancele a divisao pendente antes de entregar um item.");
    return false;
  }

  const slotData = getSlotData(containerKey, slotNumber);
  if (!slotData || slotData.occupied !== true || containerKey !== "player") {
    setLocalError("Selecione um item do seu inventario para entregar.");
    return false;
  }

  state.splitModal = {
    mode: "give",
    open: true,
    container: containerKey,
    slot: Number(slotNumber || 0),
    amount: 1,
    maxAmount: Math.max(Number(slotData.amount || 1), 1),
    itemLabel: String(slotData.label || slotData.item_id || "Item"),
  };

  closeContextMenu();
  clearLocalError();
  render();
  return true;
}

function openThirdPartyModal(mode, slot, maxAmount, toSlot, item, container = "target") {
  state.splitModal = {
    mode, open: true, container, slot: Number(slot),
    toSlot: toSlot == null ? null : Number(toSlot),
    amount: 1, maxAmount: Math.max(Number(maxAmount || 1), 1),
    itemLabel: String(item?.label || item?.item_id || "Item"),
  };
  closeContextMenu();
  clearLocalError();
  render();
}

function syncSplitModalAmount(rawValue) {
  if (state.splitModal.open !== true) {
    return;
  }

  state.splitModal.amount = clampSplitAmount(
    rawValue,
    state.splitModal.maxAmount,
  );
  render();
}

async function confirmSplitModal() {
  const modal = state.splitModal;
  if (modal.open !== true) {
    return;
  }

  const payload = {
    container: modal.container,
    slot: modal.slot,
    amount: clampSplitAmount(modal.amount, modal.maxAmount),
  };

  const isGive = modal.mode === "give";
  if (modal.mode === "thirdPartyTransfer" || modal.mode === "thirdPartySeize") {
    const action = modal.mode === "thirdPartySeize" ? "seizeThirdPartyItem" : "moveItem";
    const request = modal.mode === "thirdPartySeize"
      ? { from_slot: modal.slot, amount: payload.amount,
          section: modal.container === "targetEquipment" ? "equipment" : "main" }
      : { from_container: "target", from_slot: modal.slot,
          to_container: "player", to_slot: modal.toSlot, amount: payload.amount };
    const ok = await handleActionResponse(postNui(action, request), { resetTransient: true });
    if (ok) { closeSplitModal(); render(); }
    return;
  }
  const ok = await handleActionResponse(
    postNui(isGive ? "giveItem" : "beginSplit", payload),
    { resetTransient: isGive },
  );
  if (ok) {
    closeSplitModal();
    render();
  }
}

function openContextMenu(containerKey, slotNumber, event) {
  const slotData = getSlotData(containerKey, slotNumber);
  if (!slotData || slotData.occupied !== true || isBusy()) {
    closeContextMenu();
    render();
    return;
  }

  const padding = 12;
  const maxX = window.innerWidth - 200;
  const maxY = window.innerHeight - 260;

  state.contextMenu = {
    open: true,
    x: Math.max(padding, Math.min(event.clientX, maxX)),
    y: Math.max(padding, Math.min(event.clientY, maxY)),
    container: containerKey,
    slot: Number(slotNumber || 0),
  };

  render();
}

async function handleContextMenuSelect() {
  const menu = state.contextMenu;
  if (menu.open !== true) {
    return;
  }

  const sameSelected = isSlotSelected(menu.container, menu.slot);
  closeContextMenu();

  if (sameSelected) {
    await handleActionResponse(postNui("clearSelection"));
    return;
  }

  await handleActionResponse(
    postNui("selectSlot", {
      container: menu.container,
      slot: menu.slot,
    }),
  );
}

async function handleContextMenuUse() {
  const menu = state.contextMenu;
  if (menu.open !== true) {
    return;
  }

  const slotData = getContextMenuSlot();
  if (slotData && (slotData.type === "clothing" || slotData.type === "weapon") && (menu.container === "player" || menu.container === "equipment")) {
    await handleToggleEquipment(menu.container, menu.slot, slotData);
    return;
  }
  if (!slotData || menu.container !== "player" || slotData.usable !== true) {
    setLocalError("Este item nao pode ser usado por este menu.");
    return;
  }

  closeContextMenu();
  await handleActionResponse(
    postNui("useItem", {
      container: menu.container,
      slot: menu.slot,
    }),
    { resetTransient: true },
  );
}

async function handleContextMenuDrop() {
  const menu = state.contextMenu;
  if (menu.open !== true) {
    return;
  }

  const slotData = getContextMenuSlot();
  if (!canDropSelectedSlot(slotData, menu.container)) {
    setLocalError("Este item nao pode ser largado no chao por este menu.");
    return;
  }

  closeContextMenu();
  await handleActionResponse(
    postNui("dropItem", {
      container: menu.container,
      slot: menu.slot,
    }),
    { resetTransient: true },
  );
}

function handleContextMenuGive() {
  const menu = state.contextMenu;
  if (menu.open !== true) {
    return;
  }

  const container = menu.container;
  const slot = menu.slot;
  closeContextMenu();
  openGiveModalFor(container, slot);
}

function handleContextMenuThirdParty() {
  const menu = state.contextMenu;
  const item = getContextMenuSlot();
  const thirdParty = state.session.thirdParty;
  if (!menu.open || (menu.container !== "target" && menu.container !== "targetEquipment")
    || !item?.occupied || !thirdParty) return;
  if (menu.container === "targetEquipment" && thirdParty.mode !== "police_search") return;
  if (thirdParty.mode === "police_search" && thirdParty.canSeize !== true) return;
  openThirdPartyModal(thirdParty.mode === "police_search" ? "thirdPartySeize" : "thirdPartyTransfer",
    menu.slot, item.amount, null, item, menu.container);
}

function handleContextMenuSplit() {
  const menu = state.contextMenu;
  if (menu.open !== true) {
    return;
  }

  const container = menu.container;
  const slot = menu.slot;
  closeContextMenu();
  openSplitModalFor(container, slot);
}

async function handleSlotClick(containerKey, slotNumber) {
  if (isBusy()) {
    return;
  }

  closeContextMenu();
  clearLocalError();

  const slotData = getSlotData(containerKey, slotNumber);
  const selected = getSelectedSlot();
  const splitState = getSplitState();
  const sameAsSelected =
    selected &&
    selected.container === containerKey &&
    Number(selected.slot || 0) === Number(slotNumber || 0);

  if (splitState.active === true) {
    if (containerKey !== splitState.container) {
      setLocalError(
        "Escolha um slot vazio no mesmo container para concluir a divisao.",
      );
      return;
    }

    if (Number(slotNumber || 0) === Number(splitState.from_slot || 0)) {
      setLocalError("Escolha um slot diferente para receber a divisao.");
      return;
    }

    if (slotData && slotData.occupied === true) {
      setLocalError("A divisao precisa de um slot vazio no mesmo container.");
      return;
    }

    await handleActionResponse(
      postNui("splitItem", {
        container: splitState.container,
        from_slot: splitState.from_slot,
        to_slot: Number(slotNumber || 0),
        amount: splitState.amount,
      }),
      { resetTransient: true },
    );
    return;
  }

  if (selected && !sameAsSelected) {
    const sourceSlot =
      selected.item || getSlotData(selected.container, selected.slot);
    await performResolvedOperation(
      selected.container,
      selected.slot,
      containerKey,
      Number(slotNumber || 0),
      sourceSlot,
      slotData,
    );
    return;
  }

  if (!slotData || slotData.occupied !== true) {
    return;
  }

  if (sameAsSelected) {
    await handleActionResponse(postNui("clearSelection"));
    return;
  }

  await handleActionResponse(
    postNui("selectSlot", {
      container: containerKey,
      slot: Number(slotNumber || 0),
    }),
  );
}

function beginDrag(containerKey, slotNumber, clientX, clientY) {
  if (containerKey === "targetEquipment" ||
    (containerKey === "target" && state.session.thirdParty?.mode === "police_search")) return false;
  const slotData = getSlotData(containerKey, slotNumber);
  if (
    !slotData ||
    slotData.occupied !== true ||
    isBusy() ||
    getSplitState().active === true
  ) {
    return false;
  }

  clearLocalError();
  closeContextMenu();
  closeSplitModal();
  state.dragUi = {
    ...createDefaultDragUi(),
    source: {
      container: containerKey,
      slot: Number(slotNumber || 0),
      item: cloneValue(slotData),
    },
    pointerX: Number(clientX || 0),
    pointerY: Number(clientY || 0),
  };
  state.session.selectedSlot = null;

  void postNui("startDrag", {
    container: containerKey,
    slot: Number(slotNumber || 0),
  });

  render();
  showDragGhost(slotData, clientX, clientY);
  return true;
}

function beginPointerDrag(containerKey, slotNumber, clientX, clientY) {
  const slotData = getSlotData(containerKey, slotNumber);
  if (
    !slotData ||
    slotData.occupied !== true ||
    isBusy() ||
    getSplitState().active === true
  ) {
    state.dragUi.pending = null;
    return false;
  }

  state.dragUi.pending = {
    container: containerKey,
    slot: Number(slotNumber || 0),
    startX: Number(clientX || 0),
    startY: Number(clientY || 0),
  };

  return true;
}

function clearDrag() {
  clearDragUi();
  void postNui("clearDrag");
  render();
}

function resolvePointDropTarget(clientX, clientY) {
  const pointedElement = document.elementFromPoint(
    Number(clientX || 0),
    Number(clientY || 0),
  );
  const hotbarCard = pointedElement && pointedElement.closest(".hotbar-slot");
  if (hotbarCard) {
    const hotbarSlot = Number(hotbarCard.dataset.hotbarSlot || 0);
    if (hotbarSlot) {
      return {
        container: "hotbar",
        slot: hotbarSlot,
      };
    }
  }

  const card = pointedElement && pointedElement.closest(".slot-card");
  if (!card) {
    return null;
  }

  const containerKey = String(card.dataset.container || "").trim();
  const slotNumber = Number(card.dataset.slot || 0);
  if (!slotNumber) {
    return null;
  }

  if (
    !isContainerInteractive(containerKey) &&
    !isGroundDropPlaceholder(containerKey)
  ) {
    return null;
  }

  return {
    container: containerKey,
    slot: slotNumber,
  };
}

function clearDropTargetPreview() {
  if (state.dragUi.dropTarget !== null) {
    state.dragUi.dropTarget = null;
    render();
  }
}

function maybePromotePendingDrag(clientX, clientY) {
  const pending = state.dragUi.pending;
  if (!pending) {
    return false;
  }

  const dx = Number(clientX || 0) - Number(pending.startX || 0);
  const dy = Number(clientY || 0) - Number(pending.startY || 0);
  if (Math.sqrt(dx * dx + dy * dy) < 6) {
    return false;
  }

  state.dragUi.pending = null;
  if (beginDrag(pending.container, pending.slot, clientX, clientY) !== true) {
    return false;
  }

  state.dragUi.suppressClick = true;
  return true;
}

function updatePointerDragTarget(clientX, clientY) {
  const dragState = getDragState();
  if (dragState.active !== true || getSplitState().active === true) {
    clearDropTargetPreview();
    return;
  }

  const target = resolvePointDropTarget(clientX, clientY);
  if (!target) {
    clearDropTargetPreview();
    return;
  }

  updateDropTarget(target.container, target.slot);
}

function finishPointerDrag(clientX, clientY) {
  state.dragUi.pending = null;

  const dragState = getDragState();
  if (dragState.active !== true) {
    return false;
  }

  state.dragUi.suppressClick = true;
  const target = resolvePointDropTarget(clientX, clientY);
  if (!target) {
    clearDrag();
    return true;
  }

  void handleDropOperation(target.container, target.slot);
  return true;
}

function updateDropTarget(containerKey, slotNumber) {
  const dragState = getDragState();
  if (dragState.active !== true) {
    return;
  }

  let nextTarget = null;
  if (
    !slotNumber ||
    (dragState.container === containerKey &&
      Number(dragState.slot || 0) === Number(slotNumber || 0))
  ) {
    nextTarget = null;
  } else {
    nextTarget = {
      container: containerKey,
      slot: Number(slotNumber || 0),
    };
  }

  const current = state.dragUi.dropTarget;
  if (
    (current === null && nextTarget === null) ||
    (current &&
      nextTarget &&
      current.container === nextTarget.container &&
      Number(current.slot || 0) === Number(nextTarget.slot || 0))
  ) {
    return;
  }

  state.dragUi.dropTarget = nextTarget;

  render();
}

async function handleDropOperation(containerKey, slotNumber) {
  const dragState = getDragState();
  if (dragState.active !== true) {
    return false;
  }

  hideDragGhost();

  if (containerKey === "hotbar") {
    if (dragState.container !== "player") {
      setLocalError("Somente itens do inventario podem ser vinculados a hotbar.");
      clearDrag();
      return false;
    }

    state.dragUi.dropHandled = true;
    return bindInventorySlotToHotbar(dragState.slot, slotNumber);
  }

  if (isGroundDropPlaceholder(containerKey)) {
    if (dragState.container !== "player") {
      setLocalError("Somente itens do inventario do jogador podem ser largados no chao.");
      return false;
    }

    state.dragUi.dropHandled = true;
    return handleActionResponse(
      postNui("dropItem", {
        container: dragState.container,
        slot: Number(dragState.slot || 0),
      }),
      { resetTransient: true },
    );
  }

  const sourceSlot =
    dragState.item || getSlotData(dragState.container, dragState.slot);
  const targetSlot = getSlotData(containerKey, slotNumber);
  state.dragUi.dropHandled = true;

  return performResolvedOperation(
    dragState.container,
    dragState.slot,
    containerKey,
    Number(slotNumber || 0),
    sourceSlot,
    targetSlot,
  );
}

function findSlotCard(event) {
  return event.target.closest(".slot-card");
}

function onGridClick(containerKey, event) {
  if (state.dragUi.suppressClick === true) {
    state.dragUi.suppressClick = false;
    return;
  }

  if (!isContainerInteractive(containerKey)) {
    return;
  }

  const card = findSlotCard(event);
  if (!card) {
    return;
  }

  const slotNumber = Number(card.dataset.slot || 0);
  if (!slotNumber) {
    return;
  }

  void handleSlotClick(containerKey, slotNumber);
}

function onGridMouseDown(containerKey, event) {
  if (event.button !== 0) {
    return;
  }

  const card = findSlotCard(event);
  if (!card) {
    state.dragUi.pending = null;
    return;
  }

  const slotNumber = Number(card.dataset.slot || 0);
  if (!slotNumber) {
    state.dragUi.pending = null;
    return;
  }

  beginPointerDrag(containerKey, slotNumber, event.clientX, event.clientY);
}

function onGridContextMenu(containerKey, event) {
  if (!isContainerInteractive(containerKey)) {
    return;
  }

  const card = findSlotCard(event);
  if (!card) {
    return;
  }

  event.preventDefault();

  const slotNumber = Number(card.dataset.slot || 0);
  if (!slotNumber) {
    return;
  }

  openContextMenu(containerKey, slotNumber, event);
}

function onGridDragStart(containerKey, event) {
  if (!isContainerInteractive(containerKey)) {
    event.preventDefault();
    return;
  }

  const card = findSlotCard(event);
  if (!card) {
    return;
  }

  const slotNumber = Number(card.dataset.slot || 0);
  if (!slotNumber || beginDrag(containerKey, slotNumber, event.clientX, event.clientY) !== true) {
    event.preventDefault();
    return;
  }

  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", `${containerKey}:${slotNumber}`);
  }
}

function onGridDragOver(containerKey, event) {
  if (!isContainerInteractive(containerKey) && !isGroundDropPlaceholder(containerKey)) {
    return;
  }

  const dragState = getDragState();
  if (dragState.active !== true || getSplitState().active === true) {
    return;
  }

  const card = findSlotCard(event);
  const slotNumber = Number((card && card.dataset.slot) || 0);
  if (!slotNumber) {
    return;
  }

  event.preventDefault();
  updateDropTarget(containerKey, slotNumber);
}

function onGridDrop(containerKey, event) {
  if (!isContainerInteractive(containerKey) && !isGroundDropPlaceholder(containerKey)) {
    return;
  }

  const dragState = getDragState();
  if (dragState.active !== true) {
    return;
  }

  const card = findSlotCard(event);
  const slotNumber = Number((card && card.dataset.slot) || 0);
  state.dragUi.dropTarget = null;

  if (!slotNumber) {
    render();
    return;
  }

  event.preventDefault();
  void handleDropOperation(containerKey, slotNumber);
}

function onGridDragEnd() {
  const dragState = getDragState();
  if (dragState.active !== true && state.dragUi.source === null) {
    clearDragUi();
    render();
    return;
  }

  clearDrag();
}

function onGridMouseMove(containerKey, event) {
  const card = findSlotCard(event);
  const slotNumber = Number((card && card.dataset.slot) || 0);

  if (!slotNumber || !isContainerInteractive(containerKey)) {
    hideSlotTooltip();
    return;
  }

  const slotData = getSlotData(containerKey, slotNumber);
  if (!slotData || slotData.occupied !== true) {
    hideSlotTooltip();
    return;
  }

  if (els.itemTooltip && els.itemTooltip.classList.contains("is-hidden")) {
    showSlotTooltip(containerKey, slotNumber, event);
    return;
  }

  moveTooltip(event);
}

function findHotbarSlot(event) {
  return event.target.closest(".hotbar-slot");
}

function onHotbarDragOver(event) {
  const dragState = getDragState();
  if (dragState.active !== true || dragState.container !== "player") {
    return;
  }

  const card = findHotbarSlot(event);
  const hotbarSlot = Number((card && card.dataset.hotbarSlot) || 0);
  if (!hotbarSlot) {
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  updateDropTarget("hotbar", hotbarSlot);
}

function onHotbarDrop(event) {
  const dragState = getDragState();
  if (dragState.active !== true || dragState.container !== "player") {
    return;
  }

  const card = findHotbarSlot(event);
  const hotbarSlot = Number((card && card.dataset.hotbarSlot) || 0);
  if (!hotbarSlot) {
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  state.dragUi.dropTarget = null;
  void handleDropOperation("hotbar", hotbarSlot);
}

function onHotbarClick(event) {
  const clearButton = event.target.closest(".hotbar-clear");
  if (!clearButton) {
    return;
  }

  event.preventDefault();
  event.stopPropagation();

  const hotbarSlot = Number(clearButton.dataset.hotbarSlot || 0);
  void clearHotbarSlot(hotbarSlot);
}

window.addEventListener("message", (event) => {
  forceNuiTransparency();

  const payload = event.data || {};
  logUiStage("message", {
    action: payload.action || "unknown",
    has_session:
      typeof payload.session === "object" && payload.session !== null,
    has_error: typeof payload.error === "object" && payload.error !== null,
  });

  if (payload.action === "debugBuild") {
    showDebugBuild(payload.build);
    return;
  }

  if (payload.action === "open" || payload.action === "session") {
    const normalizedSession = normalizeSession(payload.session);
    const hasRenderablePlayer = hasValidPlayerSnapshot(normalizedSession);

    logUiStage("session_payload", {
      action: payload.action,
      is_open: normalizedSession.isOpen === true,
      has_player: hasRenderablePlayer,
      player_slots: hasRenderablePlayer
        ? normalizedSession.snapshots.player.slots.length
        : 0,
      has_target: !!(
        normalizedSession.snapshots && normalizedSession.snapshots.target
      ),
    });

    if (payload.action === "open") {
      logUiStage("open_received", {
        has_session:
          typeof payload.session === "object" && payload.session !== null,
      });
    }

    if (!hasRenderablePlayer) {
      state.session = normalizedSession;
      state.localError =
        "Falha ao carregar o inventario do jogador. Snapshot invalido ou ausente.";
      state.uiVisible = state.uiVisible === true || payload.action === "open";
      resetLocalUiState();
      render();
      return;
    }

    state.session = normalizedSession;
    state.localError = null;

    if (payload.action === "open") {
      state.uiVisible = true;
    }

    if (
      normalizedSession.dragState &&
      normalizedSession.dragState.active === true
    ) {
      state.dragUi.dropTarget = null;
      state.dragUi.dropHandled = false;
    } else {
      clearDragUi();
    }

    if (
      !(
        normalizedSession.splitState &&
        normalizedSession.splitState.active === true
      )
    ) {
      closeSplitModal();
    }

    closeContextMenu();
    render();
    return;
  }

  if (payload.action === "error") {
    state.session.lastError =
      payload.error && typeof payload.error === "object"
        ? cloneValue(payload.error)
        : null;
    state.localError = null;
    render();
    return;
  }

  if (payload.action === "close") {
    logUiStage("close_received", {
      had_session: state.session && state.session.isOpen === true,
    });
    state.uiVisible = false;
    state.session = createDefaultSession();
    state.localError = null;
    resetLocalUiState();
    render();
  }
});

if (els.closeBtn) {
  els.closeBtn.addEventListener("click", () => {
    resetLocalUiState();
    void postNui("close");
  });
}

if (els.refreshBtn) {
  els.refreshBtn.addEventListener("click", () => {
    resetLocalUiState();
    void handleActionResponse(postNui("refresh"));
  });
}

els.useBtn.addEventListener("click", () => {
  void handleUseSelected();
});

els.equipBtn.addEventListener("click", () => {
  const selected = getSelectedSlot();
  if (selected) void handleToggleEquipment(selected.container, selected.slot, selected.item);
});

els.splitBtn.addEventListener("click", () => {
  const selected = getSelectedSlot();
  if (!selected) {
    setLocalError("Selecione um item antes de dividir.");
    return;
  }

  openSplitModalFor(selected.container, selected.slot);
});

els.dropBtn.addEventListener("click", () => {
  void handleDropSelected();
});

els.giveBtn.addEventListener("click", () => {
  const selected = getSelectedSlot();
  if (!selected) {
    setLocalError("Selecione um item antes de entregar.");
    return;
  }

  openGiveModalFor(selected.container, selected.slot);
});

els.shortcutBtn.addEventListener("click", () => {
  if (els.shortcutBtn.disabled === true) {
    return;
  }

  state.shortcutPickerOpen = state.shortcutPickerOpen !== true;
  render();
});

els.shortcutPicker.addEventListener("click", (event) => {
  const button = event.target.closest("button[data-hotbar-slot]");
  if (!button) {
    return;
  }

  const hotbarSlot = Number(button.dataset.hotbarSlot || 0);
  void bindSelectedSlotToHotbar(hotbarSlot);
});

els.cancelSelectionBtn.addEventListener("click", () => {
  resetLocalUiState();
  void postNui("clearSelection");
});

els.cancelSplitBtn.addEventListener("click", () => {
  closeSplitModal();
  void postNui("cancelSplit");
  render();
});

els.splitRange.addEventListener("input", (event) => {
  syncSplitModalAmount(event.target.value);
});

els.splitAmountInput.addEventListener("input", (event) => {
  syncSplitModalAmount(event.target.value);
});

els.splitConfirmBtn.addEventListener("click", () => {
  void confirmSplitModal();
});

els.splitCancelBtn.addEventListener("click", () => {
  closeSplitModal();
  render();
});

els.splitModalCloseBtn.addEventListener("click", () => {
  closeSplitModal();
  render();
});

els.splitModal.addEventListener("click", (event) => {
  if (event.target === els.splitModal && isBusy() !== true) {
    closeSplitModal();
    render();
  }
});

els.menuSelectBtn.addEventListener("click", () => {
  void handleContextMenuSelect();
});

els.menuUseBtn.addEventListener("click", () => {
  void handleContextMenuUse();
});

els.menuSplitBtn.addEventListener("click", () => {
  handleContextMenuSplit();
});

els.menuDropBtn.addEventListener("click", () => {
  void handleContextMenuDrop();
});

els.menuGiveBtn.addEventListener("click", () => {
  handleContextMenuGive();
});

els.menuThirdPartyBtn.addEventListener("click", () => {
  handleContextMenuThirdParty();
});

els.menuCancelBtn.addEventListener("click", () => {
  closeContextMenu();
  render();
});

[
  ["player", els.playerGrid],
  ["equipment", els.equipmentGrid],
  ["equipment", els.weaponEquipmentGrid],
  ["target", els.targetGrid],
  ["targetEquipment", els.targetEquipmentGrid],
].forEach(([containerKey, grid]) => {
  grid.addEventListener("mousedown", (event) => {
    onGridMouseDown(containerKey, event);
  });

  grid.addEventListener("click", (event) => {
    onGridClick(containerKey, event);
  });

  grid.addEventListener("contextmenu", (event) => {
    onGridContextMenu(containerKey, event);
  });

  grid.addEventListener("dragstart", (event) => {
    onGridDragStart(containerKey, event);
  });

  grid.addEventListener("dragover", (event) => {
    onGridDragOver(containerKey, event);
  });

  grid.addEventListener("drop", (event) => {
    onGridDrop(containerKey, event);
  });

  grid.addEventListener("dragend", () => {
    onGridDragEnd();
  });

  grid.addEventListener("mousemove", (event) => {
    onGridMouseMove(containerKey, event);
  });

  grid.addEventListener("mouseleave", () => {
    hideSlotTooltip();
  });
});

if (els.hotbarGrid) {
  els.hotbarGrid.addEventListener("click", onHotbarClick);
  els.hotbarGrid.addEventListener("dragover", onHotbarDragOver);
  els.hotbarGrid.addEventListener("drop", onHotbarDrop);
  els.hotbarGrid.addEventListener("mouseleave", () => {
    if (state.dragUi.dropTarget && state.dragUi.dropTarget.container === "hotbar") {
      state.dragUi.dropTarget = null;
      render();
    }
  });
}

window.addEventListener("mousemove", (event) => {
  const promoted = maybePromotePendingDrag(event.clientX, event.clientY);
  if (promoted || getDragState().active === true) {
    moveDragGhost(event.clientX, event.clientY);
    updatePointerDragTarget(event.clientX, event.clientY);
    hideSlotTooltip();
  }
});

window.addEventListener("mouseup", (event) => {
  if (event.button !== 0) {
    return;
  }

  if (finishPointerDrag(event.clientX, event.clientY) !== true) {
    state.dragUi.pending = null;
  }
});

window.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") {
    return;
  }

  if (state.contextMenu.open === true) {
    closeContextMenu();
    render();
    return;
  }

  if (state.splitModal.open === true) {
    closeSplitModal();
    render();
    return;
  }

  if (getSplitState().active === true) {
    void postNui("cancelSplit");
    return;
  }

  resetLocalUiState();
  void postNui("close");
});

window.addEventListener("click", (event) => {
  if (state.dragUi.suppressClick === true) {
    state.dragUi.suppressClick = false;
  }

  if (state.contextMenu.open !== true) {
    return;
  }

  if (!els.slotMenu.contains(event.target)) {
    closeContextMenu();
    render();
  }
});

window.addEventListener("DOMContentLoaded", () => {
  forceNuiTransparency();

  logUiStage("dom_ready", {
    missing_elements: missingEls,
    get_parent_resource_name: typeof GetParentResourceName,
  });
  render();
  void postNui("ready");
});
