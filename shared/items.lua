-- Definição do item do dossiê eletrônico, no formato esperado por ox_inventory/data/items.lua.
-- Isso NÃO registra o item sozinho (ox_inventory não expõe registro dinâmico de outro resource) —
-- é a fonte única de verdade que:
--   1. o server/main.lua lê no boot pra checar se o item já existe no seu inventário, e
--   2. você copia para dentro de ox_inventory/data/items.lua caso o boot-check acuse que falta.
--
-- Ver README.md > "Instalação" para o passo a passo.

Config.Items = Config.Items or {}

Config.Items[Config.Item] = {
    label = "Tablet de Investigação",
    weight = 1000,
    stack = false,
    close = true,
    decay = true,
    degrade = 30, -- minutos (tempo de jogo) até o item sumir sozinho do inventário se não for usado
    description = "Dossiê eletrônico da central de investigação. Expira sozinho se ficar muito tempo sem uso.",
    client = {
        image = "tablet_detetive.png",
    },
}
