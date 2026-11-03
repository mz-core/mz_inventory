# mz_inventory: instalação e personalização

## Instalação

Instale os ZIPs compatíveis de `mz_assets` e `mz_inventory` em pastas com esses
nomes no diretório de resources. Instale também `oxmysql`, `ox_lib` e `mz_core`;
configure o banco usado pelo framework. Inicie os pré-requisitos e, em seguida:

```cfg
ensure mz_assets
ensure mz_inventory
```

O inventário usa HTML, CSS e JavaScript locais já prontos. Node.js, npm e build
não são necessários no servidor para este resource. Outros resources podem ter
seus próprios requisitos. O servidor precisa de permissão para criar as tabelas
do inventário; linhas legadas podem impedir sua inicialização. Não apague dados
automaticamente: faça backup e avalie a documentação e a migração do ambiente.

## Personalização

- `config.lua`: limites de slots e peso, distâncias, mochila, hotbar, armas e
  configurações de integração. É um script compartilhado: não coloque segredos.
- `shared/items.lua`: definições existentes, inclusive imagens, peso, pilha e
  equipamento. Mudanças podem afetar itens persistidos e outros resources;
  teste-as antes de atualizar o servidor.
- `mz_assets/itens/`: imagens de itens. Mantenha nome, extensão e maiúsculas;
  o manifesto de assets inclui os arquivos dessa pasta. O resolver também tenta
  `.png`, `.PNG` e `.webp` e tem alguns aliases definidos em `web/script.js`.
  Imagens indisponíveis usam um ícone local. Ao adicionar ou substituir imagens,
  reinicie o resource de assets e valide o carregamento em jogo.
- `locales/*.json`: traduções usadas pelas integrações que chamam `ox_lib`;
  `ox:locale` seleciona o idioma. Nem todo texto da interface usa esses arquivos.
- `web/style.css` e `web/index.html`: aparência e textos fixos da NUI, editáveis
  diretamente; alterações exigem validação de layout, transparência e foco no
  FiveM. SVGs próprios de equipamento ficam em `web/assets/icons/equipment/`.

Essas alterações normais não exigem recompilar a NUI. Reinicie os resources
afetados e confirme o resultado no cliente. Algumas teclas, textos, aliases e
estilos estão fixos no código; arquivos de configuração não os cobrem todos.
Permissões e regras de segurança dependem dos owners e integrações existentes;
não altere listas de writers ou canaries sem compreender os contratos.

## Atualização sem perder alterações

O ZIP não faz merge nem preserva arquivos editados automaticamente. Antes de
atualizar, guarde fora de `resources` uma cópia da versão instalada, do banco e
de suas alterações em `config.lua`, `shared/items.lua`, `locales/`, arquivos web
e imagens personalizadas de `mz_assets/itens/`. Não inclua segredos em arquivos
compartilhados ou em backups públicos.

Extraia os novos ZIPs em um diretório temporário separado. Compare cada arquivo
personalizado com a versão instalada e a nova versão; aplique suas alterações
manualmente sobre a versão nova, preservando novas opções e mudanças de contrato.
Não restaure cegamente arquivos inteiros antigos. Em staging isolado, valide
inicialização, banco, imagens e fluxos antes de substituir as pastas de produção.
Mantenha o backup para reversão conforme o procedimento do servidor. A preservação
é manual: não há arquivo de override nem merge automático neste release.
