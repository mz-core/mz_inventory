CreateThread(function()
  while not MZInventorySchema.isReady() do Wait(100) end
  if type(MZInventoryService) ~= 'table'
    or type(MZInventoryService.getInventoryViewSnapshot) ~= 'function' then
    print('[mz_inventory][fatal] service.lua incompleto; reinicie o resource mz_inventory')
  end
  print('[mz_inventory] ready mode=canonical_writer owner=mz_inventory')
end)

exports('GetInventoryDomainStatus', function()
  local schema = MZInventorySchema.getStatus()
  return {
    ready = schema.ready == true,
    mode = 'canonical_writer',
    canonicalWriter = 'mz_inventory',
    writerEnabled = schema.ready == true,
    singleWriter = true,
    moneyItems = {
      sourceEnabled = MZInventoryMoney and MZInventoryMoney.isSourceEnabled() == true or false,
      protected = true
    },
    schema = schema
  }
end)
