local QBCore = exports['qb-core']:GetCoreObject()

-- State Tracking (Anti-Exploit)
-- state: -1 (livre), 0 (não começou), 1 (achou corpo), 2 (achou prova), 3 (hackeou), 4 (prendeu), 5 (finalizado)
local playerStates = {}
local activeCases = {}      -- [citizenid] = caseId em andamento
local activeVehicles = {}   -- [citizenid] = { plate = ..., netId = ... } (viatura de trabalho atual)
local lockedCases = {}      -- [caseId] = citizenid que está investigando esse caso agora
local lastMissionEnd = {}   -- [citizenid] = os.time() do último fim/cancelamento (cooldown)

-- [src] = citizenid. Mantido à parte porque no 'playerDropped' o objeto de player do framework
-- já pode ter sido removido (ex.: qbx_core apaga QBX.Players[src] dentro do próprio handler de
-- playerDropped, e a ordem entre handlers de resources diferentes não é garantida).
local srcToCitizenId = {}

-- Função para variação de 50% para cima e para baixo
local function GetRandomizedPayout(baseValue)
    if baseValue <= 0 then return 0 end
    local minVal = math.floor(baseValue * 0.5)
    local maxVal = math.floor(baseValue * 1.5)
    return math.random(minVal, maxVal)
end

-- Libera a trava de um caso, se ela pertencer a esse citizenid (evita destravar caso de outro jogador por engano)
local function ReleaseCaseLock(citizenid, caseId)
    if caseId and lockedCases[caseId] == citizenid then
        lockedCases[caseId] = nil
    end
end

-- Devolve a chave temporária e apaga a viatura de trabalho pelo netId (funciona mesmo se o client já caiu)
local function CleanupVehicle(citizenid)
    local vData = activeVehicles[citizenid]
    if not vData then return end
    activeVehicles[citizenid] = nil

    if vData.plate then
        pcall(function()
            exports[Config.CarKeysResource]:RemoveTempKeys(vData.src, vData.plate)
        end)
    end

    if vData.netId then
        local veh = NetworkGetEntityFromNetworkId(vData.netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
end

-- Reset completo de um jogador (usado em Finish/Cancel/timeout/disconnect)
local function ResetPlayerMission(citizenid)
    local caseId = activeCases[citizenid]
    ReleaseCaseLock(citizenid, caseId)
    activeCases[citizenid] = nil
    CleanupVehicle(citizenid)
    lastMissionEnd[citizenid] = os.time()
    playerStates[citizenid] = -1
end

RegisterNetEvent('lopestorm-detective:server:Reward', function(step)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    srcToCitizenId[src] = citizenid

    if not playerStates[citizenid] then
        playerStates[citizenid] = -1
    end

    -- Validar se o jogador está na parte correta da missão
    if playerStates[citizenid] == (step - 1) then
        playerStates[citizenid] = step

        local amount = 0
        if step == 1 then amount = GetRandomizedPayout(Config.Rewards.step_1) end
        if step == 2 then amount = GetRandomizedPayout(Config.Rewards.step_2) end
        if step == 3 then amount = GetRandomizedPayout(Config.Rewards.step_3) end
        if step == 4 then amount = GetRandomizedPayout(Config.Rewards.step_4) end

        if amount > 0 then
            exports.qbx_core:AddMoney(src, 'cash', amount, "detective-reward")
            TriggerClientEvent('QBCore:Notify', src, "Fundos para a investigação liberados: $"..amount, "success")
        end
    else
        -- Exploit detectado ou dessincronização
        print("[Anti-Exploit] Jogador " .. src .. " tentou pular etapas no lopestorm-detective!")
        TriggerClientEvent('QBCore:Notify', src, "Ocorreu um erro no progresso da sua investigação.", "error")
    end
end)

-- Chamado pelo client assim que a viatura de trabalho é spawnada, pra dar ao servidor um netId
-- que sobrevive à queda de conexão do jogador (usado no cleanup autoritativo).
RegisterNetEvent('lopestorm-detective:server:RegisterWorkVehicle', function(plate, netId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    srcToCitizenId[src] = citizenid

    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        activeVehicles[citizenid] = { plate = plate, netId = netId, src = src }
    end
end)

RegisterNetEvent('lopestorm-detective:server:StartMission', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    -- Check Job (se ativado na config)
    if Config.RequireJob and player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', src, "Apenas o departamento de policia ou investigadores autorizados podem fazer isso.", "error")
        return
    end

    local citizenid = player.PlayerData.citizenid
    srcToCitizenId[src] = citizenid

    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Você já está num caso! Termine-o primeiro.", "error")
        return
    end

    -- Cooldown entre missões
    local lastEnd = lastMissionEnd[citizenid]
    if lastEnd then
        local remaining = (Config.MissionCooldown * 60) - (os.time() - lastEnd)
        if remaining > 0 then
            TriggerClientEvent('QBCore:Notify', src, "Aguarde mais " .. math.ceil(remaining / 60) .. " minuto(s) antes de aceitar outro caso.", "error")
            return
        end
    end

    -- Sorteia um caso que não esteja sendo investigado por outro detetive no momento
    local candidates = {}
    for caseId in pairs(Config.Casos) do
        if not lockedCases[caseId] then
            candidates[#candidates + 1] = caseId
        end
    end

    if #candidates == 0 then
        TriggerClientEvent('QBCore:Notify', src, "Todos os casos disponíveis já estão sendo investigados por outros detetives. Tente novamente em instantes.", "error", 8000)
        return
    end

    local randomId = candidates[math.random(1, #candidates)]
    lockedCases[randomId] = citizenid
    activeCases[citizenid] = randomId
    playerStates[citizenid] = 0 -- Setup mission

    exports.ox_inventory:AddItem(src, Config.Item, 1)
    TriggerClientEvent('lopestorm-detective:client:BeginPhase1', src, randomId)
end)

RegisterNetEvent('lopestorm-detective:server:FinishMission', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    srcToCitizenId[src] = citizenid

    if playerStates[citizenid] == 4 then
        -- Montante Final Dinâmico
        local dynFinal = GetRandomizedPayout(Config.Rewards.final)

        -- Adicional por Distância (0% a ~100%)
        local distanceBonus = 0
        local caseId = activeCases[citizenid]
        if caseId and Config.Casos[caseId] then
            local p1 = Config.NPC_Start.coords
            local p2 = Config.Casos[caseId].CrimeScene.coords
            local dist = #(vec3(p1.x, p1.y, p1.z) - vec3(p2.x, p2.y, p2.z))

            -- Multiplicador baseado na distância até Paleto (aprox 8000 unidades)
            local multi = math.min(dist / 8000.0, 1.0)
            distanceBonus = math.floor(dynFinal * multi)
        end

        local totalFinal = dynFinal + distanceBonus

        exports.qbx_core:AddMoney(src, 'cash', totalFinal, "detective-final-reward")
        TriggerClientEvent('QBCore:Notify', src, "Relatório aprovado! O pagamento final de $"..totalFinal.." (incluindo bônus de risco/distância) foi transferido.", "success", 10000)
        exports.ox_inventory:RemoveItem(src, Config.Item, 1)

        ResetPlayerMission(citizenid)
        TriggerClientEvent('lopestorm-detective:client:DeleteVehicleAndFinish', src, false)
    else
        TriggerClientEvent('QBCore:Notify', src, "Você ainda não concluiu a investigação ou não pegou o caso.", "error")
    end
end)

RegisterNetEvent('lopestorm-detective:server:CancelMission', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    srcToCitizenId[src] = citizenid

    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        exports.ox_inventory:RemoveItem(src, Config.Item, 1)
        ResetPlayerMission(citizenid)
        TriggerClientEvent('lopestorm-detective:client:DeleteVehicleAndFinish', src, false)
    end
end)

QBCore.Functions.CreateUseableItem(Config.Item, function(source, item)
    TriggerClientEvent('lopestorm-detective:client:OpenDossier', source)
end)

-- Limpeza autoritativa: se o jogador cair no meio de um caso, libera a trava do caso,
-- devolve a chave temporária e apaga a viatura mesmo sem o client por perto.
-- Não usa QBCore.Functions.GetPlayer(src) aqui de propósito: alguns frameworks (ex.: qbx_core)
-- já removem o player object dentro do próprio ciclo do 'playerDropped', antes do nosso handler
-- rodar. srcToCitizenId é preenchido por nós mesmos em cada evento, então não depende disso.
AddEventHandler('playerDropped', function(_reason)
    local src = source
    local citizenid = srcToCitizenId[src]
    srcToCitizenId[src] = nil
    if not citizenid then return end

    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        print("[lopestorm-detective] Jogador " .. src .. " caiu com um caso em andamento. Limpando estado, chave e viatura.")
        ResetPlayerMission(citizenid)
    end
end)

-- Checagem do item no boot: evita falha silenciosa (jogador aceita o trabalho, AddItem falha,
-- e ele fica "em serviço" sem o tablet) trocando por um aviso claro e acionável no console.
CreateThread(function()
    local waited = 0
    while GetResourceState('ox_inventory') ~= 'started' and waited < 30000 do
        Wait(500)
        waited = waited + 500
    end

    if GetResourceState('ox_inventory') ~= 'started' then
        print("^1[lopestorm-detective] ATENÇÃO:^0 ox_inventory não foi encontrado rodando. O item '" .. Config.Item .. "' não pode ser verificado.")
        return
    end

    local exists = exports.ox_inventory:Items(Config.Item)
    if not exists then
        print("^1[lopestorm-detective] ATENÇÃO: o item '" .. Config.Item .. "' NÃO existe no seu ox_inventory!^0")
        print("^3[lopestorm-detective] Copie o conteúdo de 'shared/items.lua' deste resource para dentro de^0")
        print("^3ox_inventory/data/items.lua (usando a chave \"" .. Config.Item .. "\") e reinicie o ox_inventory.^0")
        print("^3Sem isso, jogadores vão aceitar o trabalho mas nunca receberão o tablet.^0")
    end
end)

-- Comandos de Debug para Admins (só existem se Config.Debug estiver ativado)
if Config.Debug then
    QBCore.Commands.Add('debugcasos', 'Spawnar prop e peds de todos os casos (Admin)', {}, false, function(source, args)
        TriggerClientEvent('lopestorm-detective:client:DebugSpawns', source)
    end, 'admin')

    QBCore.Commands.Add('limpardebug', 'Limpa entidades de depuracao', {}, false, function(source, args)
        TriggerClientEvent('lopestorm-detective:client:DebugClear', source)
    end, 'admin')
end
