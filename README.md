<div align="center">
  <a href="https://github.com/mz-core">
    <img src="https://raw.githubusercontent.com/mz-core/mz_core/main/assets/logo.svg" alt="MZ Core — identidade oficial" width="420" />
  </a>

  <h1>mz_inventory</h1>

  <p><strong>Inventário, equipamentos e gerenciamento de itens para servidores FiveM com MZ Core.</strong></p>

  <p>Itens &nbsp;·&nbsp; Equipamentos &nbsp;·&nbsp; Hotbar &nbsp;·&nbsp; Armazenamentos &nbsp;·&nbsp; Integrações</p>

  <p>
    <img src="https://img.shields.io/badge/vers%C3%A3o-1.0.0-009FE3?style=flat-square" alt="Versão 1.0.0" />
    <img src="https://img.shields.io/badge/FiveM-Lua%205.4-202733?style=flat-square" alt="FiveM — Lua 5.4" />
    <img src="https://img.shields.io/badge/NUI-HTML%20%7C%20CSS%20%7C%20JS-202733?style=flat-square" alt="NUI em HTML, CSS e JavaScript" />
  </p>

  <p>
    <a href="#visão-geral">Visão geral</a> &nbsp;·&nbsp;
    <a href="#instalação">Instalação</a> &nbsp;·&nbsp;
    <a href="#personalização">Personalização</a> &nbsp;·&nbsp;
    <a href="#atualizações">Atualizações</a> &nbsp;·&nbsp;
    <a href="#integrações-e-segurança">Integrações</a>
  </p>
</div>

---

## Visão geral

O **mz_inventory** é o resource responsável pelo domínio de inventário no ecossistema **MZ Core**. Ele reúne a interface de inventário do jogador, regras de itens e equipamentos, gerenciamento de armazenamentos e contratos de integração com outros resources.

A lógica de movimentação e persistência fica no servidor. A interface é entregue em **HTML, CSS e JavaScript estáticos**, pronta para o FiveM: **não é necessário instalar Node.js, npm ou compilar a NUI no servidor**.

### Recursos principais

| Área | O que oferece |
| :--- | :--- |
| **Inventário de jogador** | Slots, limite de peso, movimentação, divisão e uso de itens. |
| **Equipamentos** | Slots de roupas, mochila e categorias de armas configuráveis. |
| **Hotbar** | Atalhos configuráveis para itens e equipamentos. |
| **Armazenamentos** | Configurações para porta-malas, porta-luvas, stash pessoal e de organização. |
| **Imagens compartilhadas** | Carregamento das imagens de itens pelo resource `mz_assets`, com fallback local. |
| **Integrações** | Contratos para recursos como polícia, economia e outros consumidores autorizados. |

> [!NOTE]
> Este README descreve a versão **1.0.0** do pacote analisado. A integridade do ZIP e verificações locais não substituem a homologação no FXServer/CEF com MySQL real.

## Instalação

### Dependências

O `fxmanifest.lua` exige os seguintes resources:

| Resource | Função |
| :--- | :--- |
| `oxmysql` | Conexão e persistência no MySQL. |
| `ox_lib` | Callbacks e recursos compartilhados de interface/localização. |
| `mz_core` | Identidade, sessão e contratos fundamentais do MZ Core. |
| `mz_assets` | Catálogo compartilhado de imagens de itens. |

O `mz_core` também utiliza `spawnmanager`; instale os pré-requisitos dele conforme sua documentação.

### Passo a passo

1. Baixe as versões **compatíveis** de `mz_inventory` e `mz_assets` nas respectivas distribuições.
2. Extraia os pacotes em pastas chamadas exatamente `mz_inventory` e `mz_assets` dentro de `resources/`.
3. Configure o MySQL e os demais pré-requisitos do servidor.
4. Garanta a ordem de inicialização adequada no `server.cfg` ou na configuração equivalente do `mz_starter`:

```cfg
ensure oxmysql
ensure ox_lib
ensure spawnmanager
ensure mz_core
ensure mz_assets
ensure mz_inventory
```

5. Inicie o servidor e acompanhe os logs de `mz_core`, `mz_assets` e `mz_inventory`.
6. No FiveM, verifique abertura, fechamento, foco da NUI, carregamento das imagens e movimentações básicas.

> [!IMPORTANT]
> O resource pode criar tabelas na inicialização e precisa das permissões correspondentes no banco. Dados legados podem bloquear o estado pronto. Faça backup antes de qualquer migração; **não remova tabelas ou registros automaticamente**.

## Personalização

O pacote de release mantém os arquivos abaixo **editáveis**, sem necessidade de recompilar a NUI para mudanças normais de configuração.

| Arquivo ou diretório | O que você pode personalizar |
| :--- | :--- |
| `config.lua` | Slots, limites de peso, hotbar, mochilas, distância de interação, equipamentos e parâmetros de integração. |
| `shared/items.lua` | Catálogo de itens, peso, pilhas, propriedades e nomes de imagens. |
| `mz_assets/itens/` | Imagens compartilhadas dos itens. |
| `locales/*.json` | Traduções utilizadas nos caminhos integrados ao `ox_lib`. |
| `web/style.css` | Aparência e estilos da NUI. |
| `web/index.html` | Estrutura e textos fixos da interface. |

### Imagens de itens

As imagens **não são distribuídas dentro de `mz_inventory/web/images`**. A interface procura os arquivos no resource `mz_assets`, sob `itens/`.

- Mantenha nomes, extensões e diferenças entre maiúsculas/minúsculas compatíveis com as referências dos itens.
- O resolver tenta extensões como `.png`, `.PNG` e `.webp` e alguns aliases definidos em `web/script.js`.
- Imagens indisponíveis usam o placeholder local da NUI. Após atualizar o catálogo, reinicie `mz_assets` e confira o resultado dentro do jogo.

Nem todos os textos, teclas e estilos estão centralizados em arquivos de configuração. Alterações diretas no frontend precisam ser testadas no CEF do FiveM.

> [!WARNING]
> `config.lua` é compartilhado entre cliente e servidor: **não armazene senhas, tokens ou outros segredos nele**. Modificações em itens persistidos, writers, permissões e integrações podem afetar outros resources e devem ser testadas em staging.

## Atualizações

O ZIP é um pacote pronto para instalação, **não um atualizador com merge automático**. Extrair a nova versão sobre a instalação existente pode sobrescrever alterações do administrador.

Para atualizar com segurança:

1. Faça backup do banco, da versão instalada e dos arquivos personalizados — incluindo `config.lua`, `shared/items.lua`, `locales/`, NUI e imagens de `mz_assets`.
2. Extraia os novos ZIPs em uma pasta temporária **separada**.
3. Compare os arquivos personalizados com a nova versão e reaplique as alterações necessárias, preservando novas opções e contratos.
4. Teste em staging a inicialização, os itens, as imagens, os equipamentos e as integrações antes de atualizar produção.
5. Mantenha o backup disponível para reversão.

**Não substitua cegamente arquivos novos por cópias antigas.** Nesta versão, a preservação das personalizações é manual.

## Integrações e segurança

O `mz_inventory` permanece responsável pelas operações e validações do inventário. Outros resources consomem seus **exports e contratos autorizados**, sem assumir a escrita direta dos dados de itens.

Alguns fluxos dependem de integrações específicas, como dinheiro representado por itens via `mz_economy` e acesso de terceiros mediado por `mz_police`. Essas integrações devem respeitar permissões, ordem de inicialização, sessões e validações no servidor.

Para testes administrativos, há comandos como `minv_give`, `minv_take` e `minv_has`. Seu uso por jogadores é restrito pela permissão ACE `mzcore.inventory.manage` nos caminhos correspondentes.

## Estrutura do resource

```text
mz_inventory/
├── fxmanifest.lua
├── README.md
├── config.lua
├── shared/                 # Definições e contratos compartilhados
├── server/                 # Persistência, validação e serviços
├── client/                 # Integração com o cliente FiveM
├── locales/                # Traduções
└── web/
    ├── index.html
    ├── style.css
    ├── script.js
    └── assets/icons/equipment/
```

## Projeto e distribuição

O **mz_inventory** faz parte do ecossistema [MZ Core](https://github.com/mz-core).

- **Código:** [mz-core/mz_inventory](https://github.com/mz-core/mz_inventory)
- **Releases:** [versões do mz_inventory](https://github.com/mz-core/mz_inventory/releases)
- **Núcleo:** [mz-core/mz_core](https://github.com/mz-core/mz_core)

---

<div align="center">
  <sub>Desenvolvido para o ecossistema <a href="https://github.com/mz-core"><strong>MZ Core</strong></a> · FiveM</sub>
</div>
