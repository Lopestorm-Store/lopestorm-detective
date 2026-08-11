# Changelog

Todas as mudanças notáveis deste resource são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [2.0.0] - 2026-08-10

### Adicionado
- `shared/items.lua`: definição única do item `tablet_detetive` (fonte de verdade compartilhada por server e documentação).
- Checagem automática, no boot, se o item existe no `ox_inventory` (`exports.ox_inventory:Items()`); se não existir, imprime aviso no console com o trecho pronto pra copiar em vez de falhar em silêncio quando um jogador aceita o trabalho.
- Trava de casos por jogador (`lockedCases`): dois detetives não recebem mais o mesmo caso sorteado ao mesmo tempo.
- Cooldown configurável entre missões (`Config.MissionCooldown`, padrão 5 min) pra evitar engatar um caso atrás do outro.
- Limpeza autoritativa no servidor via `playerDropped`: se o jogador cai no meio de um caso, o servidor libera a trava do caso, devolve a chave temporária e apaga a viatura pelo `netId` — mesmo sem o client por perto.
- Rastreamento próprio `src → citizenid` (`srcToCitizenId`) no servidor, usado pela limpeza de desconexão, pra não depender do player object do framework (que alguns cores, como o `qbx_core`, já removem antes do nosso handler de `playerDropped` rodar).
- Evento `lopestorm-detective:server:RegisterWorkVehicle`: o client avisa o servidor do `netId` da viatura assim que ela spawna.
- `Config.Item`, `Config.CarKeysResource` e `Config.FuelResources`: nomes de item/resources externos agora configuráveis em vez de hardcoded no client.
- `CHANGELOG.md` (este arquivo).

### Corrigido
- Botão "Marcar Delegacia (Base)" do tablet: `SetWaypoint` era chamado com dois números soltos em vez de `(coords, label)`, e nunca traçava a rota.
- Cálculo de "Estimativa total" no tablet usava um valor fixo `1500` em vez de `Config.Rewards.step_4`.
- Cálculo de "Ganhos atuais" no tablet nunca somava a recompensa da etapa 4, mesmo após ela ser paga.
- `/debugcasos` e `/limpardebug` eram registrados sempre, independente de `Config.Debug` — agora só existem quando `Config.Debug = true`, como a documentação sempre disse.
- Remoção de chave temporária da viatura era feita duas vezes (export do `mri_Qcarkeys` + evento `mm_carkeys:client:removetempkeys` disparado manualmente); agora é feita uma única vez, de forma autoritativa pelo servidor.
- Faltava `decay = true` na definição do item no README — sem isso o `degrade` (auto-expiração do tablet) não funcionava mesmo se copiado.
- Chamadas a `QBCore.Functions.GetPlayer(src)` sem checagem de `nil` em todos os eventos de servidor, que podiam derrubar o resource em condições de corrida na desconexão.

### Alterado
- Reabastecimento da viatura de trabalho passou a iterar `Config.FuelResources` em vez de ter 4 chamadas de export fixas no código.
- `fxmanifest.lua`: versão `1.0.0` → `2.0.0`, incluído `shared/items.lua` nos `shared_scripts` e declarado `dependency 'ox_lib'`.
- `README.md`: seção de instalação, configurações e novidades atualizada pra refletir tudo acima.

## [1.0.0] - Versão inicial
- Sistema de investigação em 4 fases (corpo → evidência → furgão hackeado → prisão) com 11 casos, temporizador por caso, economia escalonada por etapa (±50% de variação) e tablet de investigação via item do `ox_inventory`.
