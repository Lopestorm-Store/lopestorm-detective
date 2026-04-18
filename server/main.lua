local QBCore = exports['qb-core']:GetCoreObject()

-- State Tracking (Anti-Exploit)
-- state: 0 (não começou), 1 (achou corpo), 2 (achou prova), 3 (hackeou), 4 (prendeu)
local playerStates = {}
local activeCases = {} -- Armazena qual o caseId atual do jogador

-- Função para variação de 50% para cima e para baixo
local function GetRandomizedPayout(baseValue)
    if baseValue <= 0 then return 0 end
    local minVal = math.floor(baseValue * 0.5)
    local maxVal = math.floor(baseValue * 1.5)
    return math.random(minVal, maxVal)
end

RegisterNetEvent('lopestorm-detective:server:Reward', function(step)
    local src = source
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid

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

RegisterNetEvent('lopestorm-detective:server:StartMission', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check Job (se ativado na config)
    if Config.RequireJob and player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', src, "Apenas o departamento de policia ou investigadores autorizados podem fazer isso.", "error")
        return
    end

    local citizenid = player.PlayerData.citizenid
    
    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Você já está num caso! Termine-o primeiro.", "error")
        return
    end

    playerStates[citizenid] = 0 -- Setup mission
    exports.ox_inventory:AddItem(src, 'tablet_detetive', 1)
    
    local randomId = math.random(1, #Config.Casos)
    activeCases[citizenid] = randomId
    TriggerClientEvent('lopestorm-detective:client:BeginPhase1', src, randomId)
end)

RegisterNetEvent('lopestorm-detective:server:FinishMission', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local citizenid = player.PlayerData.citizenid

    if playerStates[citizenid] == 4 then
        playerStates[citizenid] = 5
        
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
        exports.ox_inventory:RemoveItem(src, 'tablet_detetive', 1)
        
        playerStates[citizenid] = -1 -- Reseta para novos casos
        activeCases[citizenid] = nil
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

    if playerStates[citizenid] and playerStates[citizenid] >= 0 then
        playerStates[citizenid] = -1 -- Reseta o status ativamente
        exports.ox_inventory:RemoveItem(src, 'tablet_detetive', 1)
        TriggerClientEvent('lopestorm-detective:client:DeleteVehicleAndFinish', src, false)
    end
end)

QBCore.Functions.CreateUseableItem('tablet_detetive', function(source, item)
    TriggerClientEvent('lopestorm-detective:client:OpenDossier', source)
end)

-- Comandos de Debug para Admins
QBCore.Commands.Add('debugcasos', 'Spawnar prop e peds de todos os casos (Admin)', {}, false, function(source, args)
    TriggerClientEvent('lopestorm-detective:client:DebugSpawns', source)
end, 'admin')

QBCore.Commands.Add('limpardebug', 'Limpa entidades de depuracao', {}, false, function(source, args)
    TriggerClientEvent('lopestorm-detective:client:DebugClear', source)
end, 'admin')
