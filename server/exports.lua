exports('GetPlayerInventory', function(source)
  return MZInventoryService.getPlayerInventory(source)
end)

exports('GetPlayerInventoryWeight', function(source)
  return MZInventoryService.getPlayerWeight(source)
end)

exports('GetPlayerEquipment', function(source)
  return MZInventoryService.getPlayerEquipment(source)
end)

exports('GetPlayerEquipmentState', function(source)
  return MZInventoryService.getPlayerEquipmentState(source, GetInvokingResource())
end)

exports('FindClothingPurchaseItem', function(source, operationId)
  return MZInventoryService.findClothingPurchaseItem(source, operationId, GetInvokingResource())
end)

exports('EquipPlayerItem', function(source, instanceUid, equipmentSlot)
  return MZInventoryService.equipPlayerItem(source, instanceUid, equipmentSlot)
end)

exports('UnequipPlayerItem', function(source, equipmentSlot)
  return MZInventoryService.unequipPlayerItem(source, equipmentSlot)
end)

exports('ApplyPlayerEquipmentLoadout', function(source, desiredSlots)
  return MZInventoryService.applyEquipmentLoadout(source, desiredSlots, GetInvokingResource())
end)

exports('GetPersonalStash', function(source)
  return MZInventoryService.getPersonalStash(source)
end)

exports('GetPersonalStashWeight', function(source)
  return MZInventoryService.getPersonalStashWeight(source)
end)

exports('MovePlayerItemToPersonalStash', function(source, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerToPersonalStash(source, fromSlot, toSlot, amount)
end)

exports('MovePersonalStashItemToPlayer', function(source, fromSlot, toSlot, amount)
  return MZInventoryService.movePersonalStashToPlayer(source, fromSlot, toSlot, amount)
end)

exports('GetOrgStash', function(source, orgCode)
  return MZInventoryService.getOrgStash(source, orgCode)
end)

exports('GetOrgStashWeight', function(source, orgCode)
  return MZInventoryService.getOrgStashWeight(source, orgCode)
end)

exports('MovePlayerItemToOrgStash', function(source, orgCode, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerToOrgStash(source, orgCode, fromSlot, toSlot, amount)
end)

exports('MoveOrgStashItemToPlayer', function(source, orgCode, fromSlot, toSlot, amount)
  return MZInventoryService.moveOrgStashToPlayer(source, orgCode, fromSlot, toSlot, amount)
end)

exports('GetVehicleTrunk', function(source, plate)
  return MZInventoryService.getVehicleTrunk(source, plate)
end)

exports('GetVehicleTrunkWeight', function(source, plate)
  return MZInventoryService.getVehicleTrunkWeight(source, plate)
end)

exports('MovePlayerItemToVehicleTrunk', function(source, plate, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerToVehicleTrunk(source, plate, fromSlot, toSlot, amount)
end)

exports('MoveVehicleTrunkItemToPlayer', function(source, plate, fromSlot, toSlot, amount)
  return MZInventoryService.moveVehicleTrunkToPlayer(source, plate, fromSlot, toSlot, amount)
end)

exports('GetVehicleGlovebox', function(source, plate)
  return MZInventoryService.getVehicleGlovebox(source, plate)
end)

exports('GetVehicleGloveboxWeight', function(source, plate)
  return MZInventoryService.getVehicleGloveboxWeight(source, plate)
end)

exports('MovePlayerItemToVehicleGlovebox', function(source, plate, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerToVehicleGlovebox(source, plate, fromSlot, toSlot, amount)
end)

exports('MoveVehicleGloveboxItemToPlayer', function(source, plate, fromSlot, toSlot, amount)
  return MZInventoryService.moveVehicleGloveboxToPlayer(source, plate, fromSlot, toSlot, amount)
end)

exports('CreateWorldDrop', function(coords, label, metadata)
  return MZInventoryService.createWorldDrop(coords, label, metadata)
end)

exports('DeleteWorldDrop', function(dropUid)
  return MZInventoryService.deleteWorldDrop(dropUid)
end)

exports('GetWorldDrop', function(dropUid)
  return MZInventoryService.getWorldDrop(dropUid)
end)

exports('GetWorldDropWeight', function(dropUid)
  return MZInventoryService.getWorldDropWeight(dropUid)
end)

exports('MovePlayerItemToWorldDrop', function(source, dropUid, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerToWorldDrop(source, dropUid, fromSlot, toSlot, amount)
end)

exports('MoveWorldDropItemToPlayer', function(source, dropUid, fromSlot, toSlot, amount)
  return MZInventoryService.moveWorldDropToPlayer(source, dropUid, fromSlot, toSlot, amount)
end)

exports('ListWorldDrops', function()
  return MZInventoryService.listWorldDrops()
end)

exports('GetItemDefinition', function(itemName)
  return MZInventoryService.getItemDefinition(itemName)
end)

exports('HasPlayerItem', function(source, itemName, amount)
  return MZInventoryService.hasPlayerItem(source, itemName, amount)
end)

exports('AddPlayerItem', function(source, itemName, amount, metadata)
  return MZInventoryService.addPlayerItem(source, itemName, amount, metadata)
end)

exports('RemovePlayerItem', function(source, itemName, amount)
  return MZInventoryService.removePlayerItem(source, itemName, amount)
end)

exports('GetMoneyItemAmount', function(citizenid, itemName, inventoryType)
  return MZInventoryMoney.getAmount(citizenid, itemName, inventoryType, GetInvokingResource())
end)

exports('CreditMoneyItem', function(citizenid, itemName, amount, options)
  return MZInventoryMoney.mutate('credit', citizenid, itemName, amount, options, GetInvokingResource())
end)

exports('DebitMoneyItem', function(citizenid, itemName, amount, options)
  return MZInventoryMoney.mutate('debit', citizenid, itemName, amount, options, GetInvokingResource())
end)

exports('ClaimMoneyRecovery', function(citizenid, itemName, amount, options)
  return MZInventoryMoney.mutate('claim', citizenid, itemName, amount, options, GetInvokingResource())
end)

exports('GetMoneyItemReceipt', function(operationKey)
  return MZInventoryMoney.getReceipt(operationKey, GetInvokingResource())
end)

exports('CreatePlayerInventoryAccessGrant', function(actorSource, targetSource, purpose, ttlSeconds)
  return MZInventoryPoliceAccess.create(actorSource, targetSource, purpose, ttlSeconds, GetInvokingResource())
end)

exports('GetGrantedPlayerInventorySnapshot', function(actorSource, grantToken)
  return MZInventoryPoliceAccess.snapshot(actorSource, grantToken, GetInvokingResource())
end)

exports('TransferGrantedPlayerItem', function(actorSource, grantToken, instanceUid, amount, destination, operationId)
  return MZInventoryPoliceAccess.transfer(
    actorSource, grantToken, instanceUid, amount, destination, operationId, GetInvokingResource()
  )
end)

exports('RevokePlayerInventoryAccessGrant', function(actorSource, grantToken)
  return MZInventoryPoliceAccess.revoke(actorSource, grantToken, GetInvokingResource())
end)

exports('CreateThirdPartyInventoryReadSession', function(actorSource, targetSource, mode)
  return MZInventoryPoliceAccess.createReadSession(actorSource, targetSource, mode, GetInvokingResource())
end)

exports('GetThirdPartyInventoryReadSnapshot', function(actorSource, sessionToken)
  return MZInventoryPoliceAccess.readSessionSnapshot(actorSource, sessionToken, GetInvokingResource())
end)

exports('RevokeThirdPartyInventoryReadSession', function(actorSource, sessionToken)
  return MZInventoryPoliceAccess.revokeReadSession(actorSource, sessionToken, GetInvokingResource())
end)

exports('TransferThirdPartyInventoryItem', function(actorSource, sessionToken, fromSlot, amount, toSlot)
  return MZInventoryPoliceAccess.transferReadSessionItem(
    actorSource, sessionToken, fromSlot, amount, toSlot, GetInvokingResource())
end)

exports('ListPoliceIssuedEquipment', function(source, orgCode, stationId)
  return MZInventoryPoliceAccess.listIssued(source, orgCode, stationId, GetInvokingResource())
end)

exports('IssuePoliceEquipment', function(source, orgCode, stationId, catalogKey, itemName, operationId)
  return MZInventoryPoliceAccess.issue(
    source, orgCode, stationId, catalogKey, itemName, operationId, GetInvokingResource()
  )
end)

exports('ReturnPoliceEquipment', function(source, orgCode, stationId, instanceUid, operationId)
  return MZInventoryPoliceAccess.returnIssued(
    source, orgCode, stationId, instanceUid, operationId, GetInvokingResource()
  )
end)

exports('ListPoliceEvidence', function(source, orgCode, containerId)
  return MZInventoryPoliceAccess.listEvidence(source, orgCode, containerId, GetInvokingResource())
end)

exports('TransferPoliceEvidence', function(source, orgCode, fromContainer, toContainer, instanceUid, operationId)
  return MZInventoryPoliceAccess.transferEvidence(
    source, orgCode, fromContainer, toContainer, instanceUid, operationId, GetInvokingResource()
  )
end)

local function prisonCaller()
  return type(GetInvokingResource) == 'function' and GetInvokingResource() == 'mz_prison'
end

exports('RetainPrisonerProperty', function(targetSource, sentenceId)
  if not prisonCaller() then return false, 'resource_not_authorized' end
  return MZInventoryService.retainPrisonerProperty(targetSource, sentenceId)
end)

exports('GetPrisonerProperty', function(targetSource, sentenceId)
  if not prisonCaller() then return false, 'resource_not_authorized' end
  return MZInventoryService.getPrisonerProperty(targetSource, sentenceId)
end)

exports('RestorePrisonerProperty', function(targetSource, sentenceId, expectedItemCount)
  if not prisonCaller() then return false, 'resource_not_authorized' end
  return MZInventoryService.restorePrisonerProperty(targetSource, sentenceId, expectedItemCount)
end)

exports('ApplyPrisonUniform', function(targetSource, sentenceId, garments)
  if not prisonCaller() then return false, 'resource_not_authorized' end
  return MZInventoryService.applyPrisonUniform(targetSource, sentenceId, garments)
end)

exports('RemovePrisonUniform', function(targetSource, sentenceId)
  if not prisonCaller() then return false, 'resource_not_authorized' end
  return MZInventoryService.removePrisonUniform(targetSource, sentenceId)
end)

exports('ReserveMedicalItem', function(source, itemName, operationId, ttlSeconds)
  return MZInventoryService.reserveMedicalItem(
    source,
    itemName,
    operationId,
    ttlSeconds,
    GetInvokingResource()
  )
end)

exports('CommitMedicalItemReservation', function(source, operationId)
  return MZInventoryService.commitMedicalItemReservation(source, operationId, GetInvokingResource())
end)

exports('CancelMedicalItemReservation', function(source, operationId)
  return MZInventoryService.cancelMedicalItemReservation(source, operationId, GetInvokingResource())
end)

exports('CancelMedicalItemReservationsForResource', function()
  return MZInventoryService.cancelMedicalItemReservationsForResource(GetInvokingResource())
end)

exports('GetMedicalItemReservations', function()
  return MZInventoryService.getMedicalItemReservations(GetInvokingResource())
end)

exports('SetPlayerSlot', function(source, slot, item, amount, metadata)
  return MZInventoryService.setPlayerSlot(source, slot, item, amount, metadata)
end)

exports('ClearPlayerSlot', function(source, slot)
  return MZInventoryService.clearPlayerSlot(source, slot)
end)

exports('MovePlayerSlot', function(source, fromSlot, toSlot, amount)
  return MZInventoryService.movePlayerSlot(source, fromSlot, toSlot, amount)
end)

exports('SetPlayerSlotMetadata', function(source, slot, metadata, mode)
  return MZInventoryService.setPlayerSlotMetadata(source, slot, metadata, mode)
end)

exports('RegisterItemUseHandler', function(itemName, handler)
  return MZInventoryService.registerItemUseHandler(itemName, handler)
end)

-- Server-only item custody contracts. Only mz_phone may obtain these opaque tokens.
exports('AcquireInventoryItemAccess', function(source, instanceUid, itemName, purpose)
  return MZInventoryService.acquireItemAccess(source, instanceUid, itemName, purpose, GetInvokingResource())
end)

exports('ValidateInventoryItemAccess', function(source, accessToken)
  return MZInventoryService.validateItemAccess(source, accessToken, GetInvokingResource())
end)

exports('BeginInventoryItemOperation', function(source, accessToken)
  return MZInventoryService.beginItemOperation(source, accessToken, GetInvokingResource())
end)

exports('EndInventoryItemOperation', function(source, permitToken)
  return MZInventoryService.endItemOperation(source, permitToken, GetInvokingResource())
end)

exports('ReleaseInventoryItemAccess', function(source, accessToken)
  return MZInventoryService.releaseItemAccess(source, accessToken, GetInvokingResource())
end)

exports('UsePlayerItem', function(source, slot)
  return MZInventoryService.usePlayerItem(source, slot)
end)

exports('OpenPlayerInventory', function(source)
  return MZInventoryService.openPlayerInventory(source)
end)

exports('OpenInventoryContainer', function(source, descriptor)
  return MZInventoryService.openInventoryContainer(source, descriptor)
end)

exports('CreateHouseStashAccessGrant', function(source, descriptor)
  return MZInventoryService.createHouseStashAccessGrant(source, descriptor)
end)

exports('GetInventorySnapshot', function(source, descriptor)
  return MZInventoryService.getInventorySnapshot(source, descriptor)
end)

exports('GetInventoryViewSnapshot', function(source, request)
  return MZInventoryService.getInventoryViewSnapshot(source, request)
end)

exports('MoveInventoryItem', function(source, request)
  return MZInventoryService.moveInventoryItem(source, request)
end)

exports('SplitInventoryStack', function(source, request)
  return MZInventoryService.splitInventoryStack(source, request)
end)

exports('MergeInventorySlots', function(source, request)
  return MZInventoryService.mergeInventorySlots(source, request)
end)

exports('SwapInventorySlots', function(source, request)
  return MZInventoryService.swapInventorySlots(source, request)
end)

exports('UseInventoryItemAction', function(source, request)
  return MZInventoryService.useInventoryItemAction(source, request)
end)

exports('GiveInventoryItemAction', function(source, request)
  return MZInventoryService.giveInventoryItemAction(source, request)
end)

exports('GetPlayerHotbar', function(source)
  return MZInventoryService.getPlayerHotbar(source)
end)

exports('BindHotbarSlot', function(source, hotbarSlot, inventorySlot)
  return MZInventoryService.bindHotbarSlot(source, hotbarSlot, inventorySlot)
end)

exports('ClearHotbarSlot', function(source, hotbarSlot)
  return MZInventoryService.clearHotbarSlot(source, hotbarSlot)
end)

exports('UseHotbarSlot', function(source, hotbarSlot)
  return MZInventoryService.useHotbarSlot(source, hotbarSlot)
end)

exports('CleanupInvalidHotbarRefs', function(source)
  return MZInventoryService.cleanupInvalidHotbarRefs(source)
end)

exports('GetInventoryErrorCatalog', function()
  return MZInventoryService.getPublicInventoryErrorCatalog()
end)

-- Server-only authority contracts. They return sanitized copies and never query inventory storage.
exports('GetEquippedWeaponState', function(source)
  return MZInventoryService.getEquippedWeaponState(source)
end)

exports('IsWeaponAuthorized', function(source, weaponHash)
  return MZInventoryService.isWeaponAuthorized(source, weaponHash)
end)

-- Narrow server-only restraint custody contract used by mz_police.
-- Only mz_police may call it and only handcuffs/handcuff_key are accepted.
exports('ConsumeRestraintItem', function(source, itemName, instanceUid, operationId)
  return MZInventoryService.consumeRestraintItem(
    source, itemName, instanceUid, operationId, GetInvokingResource()
  )
end)

exports('GrantRestraintItem', function(source, itemName, metadata, operationId)
  return MZInventoryService.grantRestraintItem(
    source, itemName, metadata, operationId, GetInvokingResource()
  )
end)
