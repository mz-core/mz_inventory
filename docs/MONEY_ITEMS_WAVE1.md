# MONEY_ITEMS Wave 1

Esta Wave preparou a custodia fisica sem alterar a economia. A integracao MONEY_ITEMS Wave 2 agora ativa `Config.Inventory.moneyItems.sourceEnabled = true`; `mz_economy` consulta e muta os itens exclusivamente pelos exports protegidos descritos abaixo. O schema, receipts, recovery e protecoes desta fundacao permanecem os mesmos.

## Instalacao limpa

O bootstrap de `server/schema.lua` cria `mz_inventory_items.amount` diretamente como `BIGINT UNSIGNED NOT NULL` e cria `mz_inventory_money_receipts` no banco vazio. Nenhum script de migracao ou `ALTER TABLE` previo e necessario.

O bootstrap nao executa `ALTER`, `DROP` ou conversoes destrutivas em bancos preexistentes. O framework em desenvolvimento assume instalacao limpa com o schema atual.

## Contratos server-side

- `GetMoneyItemAmount(citizenid, itemName, inventoryType)`
- `CreditMoneyItem(citizenid, itemName, amount, { operationKey, fingerprint })`
- `DebitMoneyItem(citizenid, itemName, amount, { operationKey, fingerprint })`
- `ClaimMoneyRecovery(citizenid, itemName, amount, { operationKey, fingerprint })`
- `GetMoneyItemReceipt(operationKey)`

Somente `money` e `dirty_money` sao aceitos. Mutacoes exigem caller autorizado, inteiro positivo, limite seguro, operation key e fingerprint. `mz_economy` e o writer financeiro autorizado; `mz_admin` e o caller administrativo canonico. `mz_testkit` so pode escrever quando `Config.Debug=true`.

Credito sem slot no inventario principal e persistido em `character/<citizenid>/money_recovery`. Esse container nao faz parte dos descritores publicos nem do dinheiro gastavel. O claim e server-only e idempotente.

Receipts em `mz_inventory_money_receipts` registram somente custodia. Eles nao substituem o ledger financeiro do `mz_economy`.

## Apreensao de pilha

Snapshots policiais passam a emitir `stack_locator` opaco para pilhas monetarias. O locator e vinculado ao grant, resource, personagem, sessao, row, slot, item, quantidade e versao observada; a transferencia revalida tudo sob o lock do container. A parcela apreendida recebe um UID novo de evidencia e a pilha restante continua sem UID duplicado.
