exports('OpenPlayerView', function()
  return MZInventoryBridge.openPlayerView()
end)

exports('OpenTargetView', function(targetDescriptor)
  return MZInventoryBridge.openTargetView(targetDescriptor)
end)

exports('OpenVehicleTrunkView', function(plate)
  return MZInventoryBridge.openVehicleTrunkView(plate)
end)

exports('OpenVehicleGloveboxView', function(plate)
  return MZInventoryBridge.openVehicleGloveboxView(plate)
end)

exports('RefreshCurrentView', function()
  return MZInventoryBridge.refreshCurrentView()
end)

exports('CloseView', function()
  return MZInventoryBridge.closeView()
end)

exports('IsOpen', function()
  return MZInventoryState.isOpen()
end)

exports('GetSession', function()
  return MZInventoryState.exportForNui()
end)
