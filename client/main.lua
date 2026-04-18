local QBCore = exports['qb-core']:GetCoreObject()
local spawnedEntities = {}
local CurrentBlip = nil
local workVehicle = nil
local workVehiclePlate = nil
local isOnDuty = false
local activeCase = 1
local currentPhase = 0
local missionTimerActive = false
local missionTimeRemaining = 0

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function SetWaypoint(coords, label)
    if CurrentBlip ~= nil then RemoveBlip(CurrentBlip) end
    CurrentBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(CurrentBlip, 1)
    SetBlipColour(CurrentBlip, 5)
    SetBlipScale(CurrentBlip, 1.0)
    SetBlipRoute(CurrentBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(CurrentBlip)
end

local function ClearAllEntities()
    for _, entity in pairs(spawnedEntities) do
        if DoesEntityExist(entity) then
            if IsEntityAVehicle(entity) then
                QBCore.Functions.DeleteVehicle(entity)
            else
                DeleteEntity(entity)
            end
        end
    end
    spawnedEntities = {}
    if CurrentBlip ~= nil then 
        RemoveBlip(CurrentBlip) 
        CurrentBlip = nil
    end
end

-- NPC INICIAL (O CHEFE)
CreateThread(function()
    local hash = GetHashKey(Config.NPC_Start.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    -- Se usar a [qb-target] / [ox_target] compatível
    local bossPed = CreatePed(4, hash, Config.NPC_Start.coords.x, Config.NPC_Start.coords.y, Config.NPC_Start.coords.z, Config.NPC_Start.coords.w, false, true)
    PlaceObjectOnGroundProperly(bossPed)
    FreezeEntityPosition(bossPed, true)
    SetEntityInvincible(bossPed, true)
    SetBlockingOfNonTemporaryEvents(bossPed, true)

    exports['qb-target']:AddTargetEntity(bossPed, {
        options = {
            {
                type = "server",
                event = "lopestorm-detective:server:StartMission",
                icon = "fas fa-search",
                label = "Aceitar Trabalho Investigativo",
                canInteract = function()
                    return not isOnDuty
                end
            },
            {
                icon = "fas fa-car",
                label = "Finalizar Caso e Devolver Viatura",
                action = function()
                    TriggerServerEvent('lopestorm-detective:server:FinishMission')
                end,
                canInteract = function()
                    return isOnDuty
                end

            },
            {
                icon = "fas fa-times-circle",
                label = "Abortar Investigação",
                action = function()
                    TriggerServerEvent('lopestorm-detective:server:CancelMission')
                end,
                canInteract = function()
                    return isOnDuty and currentPhase < 5
                end
            }
        },
        distance = 2.0
    })
end)

RegisterNetEvent('lopestorm-detective:client:BeginPhase1', function(caseId)
    ClearAllEntities()
    isOnDuty = true
    activeCase = caseId
    currentPhase = 1
    QBCore.Functions.Notify(Config.Casos[activeCase].Historia, "primary", 8000)

    -- Início do Temporizador vai primeiro para ser à prova de falhas!
    local extraMinutes = Config.Casos[activeCase].TempoMinutos or 20
    missionTimeRemaining = extraMinutes * 60 -- Conversão para segundos
    missionTimerActive = true
    QBCore.Functions.Notify("O Gabinete do Chefe lhe deu " .. extraMinutes .. " minutos contados para investigar tudo antes de a imprensa invadir o local!", "primary", 10000)

    -- Spawn da Viatura de Trabalho isolada em Thread própria (Evita crash de modelos corrompidos do servidor)
    CreateThread(function()
        QBCore.Functions.SpawnVehicle(Config.Vehicle.model, function(veh)
            local plateT = "DETC"..tostring(math.random(1000, 9999))
            SetVehicleNumberPlateText(veh, plateT)
            SetEntityHeading(veh, Config.Vehicle.spawnCoords.w)
            workVehiclePlate = plateT
            SetVehicleEngineOn(veh, true, true, false)
            exports['mri_Qcarkeys']:GiveTempKeys(plateT)
            
            -- Reabastecimento universal agressivo (Suporte garantido ao cdn-fuel e outros)
            CreateThread(function()
                for i = 1, 10 do
                    Wait(500)
                    if DoesEntityExist(veh) then
                        SetVehicleFuelLevel(veh, 100.0)
                        if Entity(veh) then Entity(veh).state.fuel = 100.0 end
                        pcall(function() exports['cdn-fuel']:SetFuel(veh, 100.0) end)
                        pcall(function() exports['LegacyFuel']:SetFuel(veh, 100.0) end)
                        pcall(function() exports['ps-fuel']:SetFuel(veh, 100.0) end)
                        pcall(function() exports['ox_fuel']:SetFuel(veh, 100.0) end)
                    end
                end
            end)

            workVehicle = veh
            QBCore.Functions.Notify("Sua viatura descaracterizada está no estacionamento da DP.", "success", 7000)
        end, Config.Vehicle.spawnCoords, true)
    end)

    CreateThread(function()
        while missionTimerActive and isOnDuty do
            Wait(60000) -- Aguarda exatamente 1 Minuto
            if not missionTimerActive or not isOnDuty then break end
            
            missionTimeRemaining = missionTimeRemaining - 60
            if missionTimeRemaining <= 0 then
                QBCore.Functions.Notify("O tempo limite expirou! O Departamento repassou seu caso para a corregedoria.", "error", 15000)
                TriggerServerEvent('lopestorm-detective:server:CancelMission')
                missionTimerActive = false
                break
            else
                local tot = Config.Casos[activeCase].TempoMinutos or 20
                local mins = math.floor(missionTimeRemaining / 60)
                local elapsed = tot - mins
                
                if mins == 5 or mins == 3 or mins == 1 then
                    QBCore.Functions.Notify("URGENTE: Restam apenas " .. mins .. " minutos de investigação!", "warning", 8000)
                elseif elapsed % 3 == 0 and mins > 0 then
                    QBCore.Functions.Notify("Tempo sob controle. Ainda restam " .. mins .. " minutos.", "primary", 5000)
                end
            end
        end
    end)


    -- Spawn Corpse
    local hash = GetHashKey(Config.Casos[activeCase].CrimeScene.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local coords = Config.Casos[activeCase].CrimeScene.coords
    
    local corpse = CreatePed(4, hash, coords.x, coords.y, coords.z, coords.w, false, true)
    table.insert(spawnedEntities, corpse)
    PlaceObjectOnGroundProperly(corpse)
    
    SetEntityInvincible(corpse, true)
    SetBlockingOfNonTemporaryEvents(corpse, true)
    FreezeEntityPosition(corpse, true)
    
    LoadAnimDict(Config.Casos[activeCase].CrimeScene.animDict)
    TaskPlayAnim(corpse, Config.Casos[activeCase].CrimeScene.animDict, Config.Casos[activeCase].CrimeScene.anim, 8.0, 8.0, -1, 1, 0, 0, 0, 0)
    
    -- [NOVO] Adição de Curiosos Ambientais perto do corpo
    local pedsCuriosos = {"a_f_y_hipster_01", "a_m_m_skater_01"}
    for i, pModel in ipairs(pedsCuriosos) do
        local cHash = GetHashKey(pModel)
        RequestModel(cHash)
        while not HasModelLoaded(cHash) do Wait(10) end
        
        local xOff = (i == 1 and 1.5 or -1.5)
        local yOff = (i == 1 and 1.5 or 0.8)
        local cPed = CreatePed(4, cHash, coords.x + xOff, coords.y + yOff, coords.z, 0.0, false, true)
        table.insert(spawnedEntities, cPed)
        
        PlaceObjectOnGroundProperly(cPed)
        SetEntityInvincible(cPed, true)
        SetBlockingOfNonTemporaryEvents(cPed, true)
        TaskTurnPedToFaceEntity(cPed, corpse, -1)
        
        if i == 1 then
            TaskStartScenarioInPlace(cPed, "WORLD_HUMAN_STAND_MOBILE", 0, true) -- Filmando com celular
        else
            TaskStartScenarioInPlace(cPed, "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, true) -- Em choque anotando placa
        end
    end

    SetWaypoint(coords, "Cena do Crime")

    exports['qb-target']:AddTargetEntity(corpse, {
        options = {
            {
                icon = "fas fa-search",
                label = Config.Casos[activeCase].CrimeScene.label,
                action = function()
                    -- Um pequeno timeout/setup para não jogar o minigame solto na tela
                    local isReady = lib.progressBar({
                        duration = 2000,
                        label = 'Avaliando cenário...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true },
                    })

                    if not isReady then return end

                    local skill = lib.skillCheck({'easy', 'easy'})
                    if skill then
                        lib.progressBar({
                            duration = 5000,
                            label = 'Ajoelhado investigando feridas...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = { car = true, move = true },
                            anim = { dict = "amb@medic@standing@tendtodead@idle_a", clip = "idle_a", flag = 1 }
                        })
                        TriggerServerEvent('lopestorm-detective:server:Reward', 1)
                        TriggerEvent('lopestorm-detective:client:BeginPhase2')
                    else
                        QBCore.Functions.Notify("Você estragou as evidências e precisou se recompor. Tente de novo.", "error")
                    end
                end
            }
        },
        distance = 2.0
    })
end)

RegisterNetEvent('lopestorm-detective:client:BeginPhase2', function()
    QBCore.Functions.Notify("Achei um bilhete! Ele menciona um item descartado num ponto de coleta.", "primary", 6000)
    currentPhase = 2
    
    local hash = GetHashKey(Config.Casos[activeCase].Evidence.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local coords = Config.Casos[activeCase].Evidence.coords
    
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    table.insert(spawnedEntities, prop)
    PlaceObjectOnGroundProperly(prop)
    SetEntityHeading(prop, coords.w)
    FreezeEntityPosition(prop, true)
    
    SetWaypoint(coords, "Caçando Vestígios")

    exports['qb-target']:AddTargetEntity(prop, {
        options = {
            {
                icon = "fas fa-box-open",
                label = Config.Casos[activeCase].Evidence.label,
                action = function()
                    lib.progressBar({
                        duration = 4000,
                        label = 'Revirando...',
                        useWhileDead = false,
                        canCancel = false,
                        disable = { car = true, move = true },
                        anim = { dict = "amb@medic@standing@kneel@base", clip = "base", flag = 1 }
                    })
                    TriggerServerEvent('lopestorm-detective:server:Reward', 2)
                    TriggerEvent('lopestorm-detective:client:BeginPhase3')
                end
            }
        },
        distance = 2.0
    })
end)

RegisterNetEvent('lopestorm-detective:client:BeginPhase3', function()
    QBCore.Functions.Notify("Encontramos o Furgão Suspeito do crime via rastreio! Aproxime-se com cautela e hackeie seu painel.", "primary", 8000)
    currentPhase = 3
    
    local model = Config.Casos[activeCase].Hacker.model
    local coords = Config.Casos[activeCase].Hacker.coords
    
    QBCore.Functions.SpawnVehicle(model, function(veh)
        SetEntityHeading(veh, coords.w)
        SetVehicleDoorsLocked(veh, 2) -- Trancado para ninguem roubar
        SetVehicleEngineOn(veh, false, false, true)
        SetVehicleUndriveable(veh, true)
        table.insert(spawnedEntities, veh)

        SetWaypoint(coords, "Furgão Hacker")

        exports['qb-target']:AddTargetEntity(veh, {
            options = {
                {
                    icon = "fas fa-network-wired",
                    label = Config.Casos[activeCase].Hacker.label,
                    action = function()
                        local isReady = lib.progressBar({
                            duration = 2000,
                            label = "Conectando o cabo nas portas traseiras...",
                            useWhileDead = false,
                            canCancel = true,
                            disable = { move = true, car = true, combat = true }
                        })
                        
                        if not isReady then return end

                        local success = lib.skillCheck({'easy', 'easy', 'easy', 'easy'})
                        if success then
                            lib.progressBar({
                                duration = 4000,
                                label = "Baixando Histórico do Veículo...",
                                useWhileDead = false,
                                canCancel = false,
                                disable = { move = true, car = true, combat = true },
                                anim = { dict = "anim@heists@prison_heiststation@cop_reactions", clip = "cop_b_idle" }
                            })
                            ClearPedTasks(PlayerPedId())
                            TriggerServerEvent('lopestorm-detective:server:Reward', 3)
                            TriggerEvent('lopestorm-detective:client:BeginPhase4')
                            exports['qb-target']:RemoveTargetEntity(veh, Config.Casos[activeCase].Hacker.label)
                        else
                            QBCore.Functions.Notify("A Firewall nativa do carro te bloqueou! Concentre-se e pare de tremer.", "error")
                        end
                    end
                }
            },
            distance = 2.5
        })
    end, coords, true)
end)

RegisterNetEvent('lopestorm-detective:client:BeginPhase4', function()
    QBCore.Functions.Notify("Identidade Obtida! Ele está no local marcado. Vá prendê-lo e tenha CUIDADO!", "primary", 7000)
    currentPhase = 4
    
    local hash = GetHashKey(Config.Casos[activeCase].Suspect.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local coords = Config.Casos[activeCase].Suspect.coords
    
    local suspect = CreatePed(4, hash, coords.x, coords.y, coords.z, coords.w, false, true)
    table.insert(spawnedEntities, suspect)
    PlaceObjectOnGroundProperly(suspect)
    SetEntityAsMissionEntity(suspect, true, true)
    SetBlockingOfNonTemporaryEvents(suspect, true)
    FreezeEntityPosition(suspect, true)
    
    SetWaypoint(coords, "Esconderijo do Suspeito")

    exports['qb-target']:AddTargetEntity(suspect, {
        options = {
            {
                icon = "fas fa-handcuffs",
                label = Config.Casos[activeCase].Suspect.label,
                action = function()
                    LoadAnimDict("mp_arresting")
                    TaskPlayAnim(PlayerPedId(), "mp_arresting", "a_uncuff", 8.0, -8, -1, 49, 0, 0, 0, 0)
                    lib.progressBar({
                        duration = 5000,
                        label = 'Imobilizando e Prendendo o suspeito...',
                        useWhileDead = false,
                        canCancel = false,
                        disable = { car = true, move = true }
                    })
                    ClearPedTasks(PlayerPedId())
                    TriggerServerEvent('lopestorm-detective:server:Reward', 4)
                    currentPhase = 5
                    QBCore.Functions.Notify("Prisão confirmada! O suspeito está sob custódia. Volte ao Delegado na DP para fechar o caso.", "success", 8000)
                    ClearAllEntities()
                    SetWaypoint(Config.NPC_Start.coords, "Entregar Relatório na DP")
                end
            }
        },
        distance = 2.0
    })
end)

RegisterNetEvent('lopestorm-detective:client:DeleteVehicleAndFinish', function(isCancel)
    missionTimerActive = false
    missionTimeRemaining = 0
    
    if workVehiclePlate then
        exports['mri_Qcarkeys']:RemoveTempKeys(workVehiclePlate)
        TriggerEvent('mm_carkeys:client:removetempkeys', workVehiclePlate)
        workVehiclePlate = nil
    end

    if workVehicle and DoesEntityExist(workVehicle) then
        QBCore.Functions.DeleteVehicle(workVehicle)
        workVehicle = nil
    end
    ClearAllEntities()
    isOnDuty = false
    currentPhase = 0
    
    if isCancel then
        QBCore.Functions.Notify("Investigação abortada. Viatura devolvida à corporação.", "error", 6000)
    end
end)
RegisterNetEvent('lopestorm-detective:client:OpenDossier', function()
    if not isOnDuty then
        QBCore.Functions.Notify("Você não tem nenhum caso em andamento. Inicie um primeiro.", "error")
        return
    end

    -- Cálculo simples de estimativa financeira
    local estTotal = Config.Rewards.step_1 + Config.Rewards.step_2 + Config.Rewards.step_3 + 1500 + Config.Rewards.final
    local currentMoney = 0
    if currentPhase > 1 then currentMoney = currentMoney + Config.Rewards.step_1 end
    if currentPhase > 2 then currentMoney = currentMoney + Config.Rewards.step_2 end
    if currentPhase > 3 then currentMoney = currentMoney + Config.Rewards.step_3 end

    local remMins = math.floor(missionTimeRemaining / 60)
    local totMins = Config.Casos[activeCase].TempoMinutos or 20
    local pPerc = (remMins / totMins) * 100
    local timeColor = 'green'
    if pPerc <= 20 then
        timeColor = 'red'
    elseif pPerc <= 50 then
        timeColor = 'yellow'
    end

    ExecuteCommand("e tablet2") -- Puxa seu emote de tablet da base

    lib.registerContext({
        id = 'dossier_menu',
        title = 'Central de Investigação - Tablet',
        onExit = function()
            ExecuteCommand("e c") -- Cancela o tablet ao fechar a UI
        end,
        options = {
            {
                title = 'Caso: ' .. Config.Casos[activeCase].Historia,
                icon = 'briefcase',
                readOnly = true,
            },
            {
                title = 'Progresso de Provas ('..currentPhase..'/4)',
                description = 'Encontre e verifique todas as provas no radar e conclua prisões.',
                progress = (currentPhase / 4) * 100,
                colorScheme = 'blue',
                icon = 'spinner',
                readOnly = true,
            },
            {
                title = 'Tempo da Operação',
                description = 'Tempo restante estimado: ' .. remMins .. ' minutos.',
                progress = pPerc,
                colorScheme = timeColor,
                icon = 'clock',
                readOnly = true,
            },
            {
                title = 'Financeiro da Operação',
                description = 'Ganhos atuais: $' .. currentMoney .. ' / Estimativa total: $' .. estTotal,
                icon = 'money-bill-wave',
                readOnly = true,
            },
            {
                title = 'Marcar Delegacia (Base)',
                description = 'Trace uma Rota de GPS direto para a matriz.',
                icon = 'location-dot',
                onSelect = function()
                    SetWaypoint(Config.NPC_Start.coords.x, Config.NPC_Start.coords.y)
                    QBCore.Functions.Notify("GPS marcado para a Delegacia Central.", "success")
                end
            }
        }
    })

    lib.showContext('dossier_menu')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    ClearAllEntities()
    if workVehicle and DoesEntityExist(workVehicle) then QBCore.Functions.DeleteVehicle(workVehicle) end
end)

-- Sistema de DEBUG Admin
RegisterNetEvent('lopestorm-detective:client:DebugSpawns', function()
    ClearAllEntities()
    
    for caseId, caseData in pairs(Config.Casos) do
        -- 1. Vítima
        local hash1 = GetHashKey(caseData.CrimeScene.model)
        RequestModel(hash1)
        local t1 = 0
        while not HasModelLoaded(hash1) and t1 < 50 do Wait(10) t1 = t1 + 1 end
        if HasModelLoaded(hash1) then
            local ped = CreatePed(4, hash1, caseData.CrimeScene.coords.x, caseData.CrimeScene.coords.y, caseData.CrimeScene.coords.z, caseData.CrimeScene.coords.w, false, true)
            PlaceObjectOnGroundProperly(ped)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            
            LoadAnimDict(caseData.CrimeScene.animDict)
            TaskPlayAnim(ped, caseData.CrimeScene.animDict, caseData.CrimeScene.anim, 8.0, 8.0, -1, 1, 0, 0, 0, 0)
            table.insert(spawnedEntities, ped)
        else
            print("ERRO DEBUG: Modelo de vítima falhou: " .. tostring(caseData.CrimeScene.model))
        end

        -- 1.b. Curiosos
        local pedsCuriosos = {"a_f_y_hipster_01", "a_m_m_skater_01"}
        for i, pModel in ipairs(pedsCuriosos) do
            local cHash = GetHashKey(pModel)
            RequestModel(cHash)
            while not HasModelLoaded(cHash) do Wait(10) end
            local xOff = (i == 1 and 1.5 or -1.5)
            local yOff = (i == 1 and 1.5 or 0.8)
            local cPed = CreatePed(4, cHash, caseData.CrimeScene.coords.x + xOff, caseData.CrimeScene.coords.y + yOff, caseData.CrimeScene.coords.z, 0.0, false, true)
            PlaceObjectOnGroundProperly(cPed)
            SetEntityInvincible(cPed, true)
            SetBlockingOfNonTemporaryEvents(cPed, true)
            TaskTurnPedToFaceEntity(cPed, ped, -1)
            if i == 1 then
                TaskStartScenarioInPlace(cPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
            else
                TaskStartScenarioInPlace(cPed, "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, true)
            end
            table.insert(spawnedEntities, cPed)
        end
        
        -- 2. Evidência
        local hash2 = GetHashKey(caseData.Evidence.model)
        RequestModel(hash2)
        local t2 = 0
        while not HasModelLoaded(hash2) and t2 < 50 do Wait(10) t2 = t2 + 1 end
        if HasModelLoaded(hash2) then
            local prop = CreateObject(hash2, caseData.Evidence.coords.x, caseData.Evidence.coords.y, caseData.Evidence.coords.z, false, false, false)
            PlaceObjectOnGroundProperly(prop)
            SetEntityHeading(prop, caseData.Evidence.coords.w)
            table.insert(spawnedEntities, prop)
        else
            print("ERRO DEBUG: Modelo de evidência falhou: " .. tostring(caseData.Evidence.model))
        end
        
        -- 3. Furgão (Hacker)
        local hash3 = GetHashKey(caseData.Hacker.model)
        RequestModel(hash3)
        local t3 = 0
        while not HasModelLoaded(hash3) and t3 < 50 do Wait(10) t3 = t3 + 1 end
        if HasModelLoaded(hash3) then
            local veh = CreateVehicle(hash3, caseData.Hacker.coords.x, caseData.Hacker.coords.y, caseData.Hacker.coords.z, caseData.Hacker.coords.w, false, false)
            PlaceObjectOnGroundProperly(veh)
            table.insert(spawnedEntities, veh)
        else
            print("ERRO DEBUG: Modelo do carro falhou: " .. tostring(caseData.Hacker.model))
        end

        -- 4. Suspeito
        local hash4 = GetHashKey(caseData.Suspect.model)
        RequestModel(hash4)
        local t4 = 0
        while not HasModelLoaded(hash4) and t4 < 50 do Wait(10) t4 = t4 + 1 end
        if HasModelLoaded(hash4) then
            local susp = CreatePed(4, hash4, caseData.Suspect.coords.x, caseData.Suspect.coords.y, caseData.Suspect.coords.z, caseData.Suspect.coords.w, false, true)
            PlaceObjectOnGroundProperly(susp)
            SetEntityInvincible(susp, true)
            FreezeEntityPosition(susp, true)
            table.insert(spawnedEntities, susp)
        else
            print("ERRO DEBUG: Modelo do suspeito falhou: " .. tostring(caseData.Suspect.model))
        end
    end
    QBCore.Functions.Notify("DEBUG: Entidades de TODOS os casos de Teste criadas pelo mapa! Use noclip para avaliá-las.", "primary", 10000)
end)

RegisterNetEvent('lopestorm-detective:client:DebugClear', function()
    ClearAllEntities()
    QBCore.Functions.Notify("DEBUG: Entidades Limpas.", "error")
end)
