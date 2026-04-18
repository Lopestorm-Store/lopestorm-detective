Config = {}

Config.Debug = false -- Habilita funções de debug (debugcasos e limpardebug)

Config.RequireJob = false -- Defina para true e informe o cargo abaixo se for exclusivo.
Config.JobName = "policia"

-- NPC Inicial (O Despachante ou Delegado que dá o trabalho)
Config.NPC_Start = {
    model = "s_m_m_fibsec_01",
    coords = vec4(433.57, -986.12, 29.71, 90) -- Próximo à Mission Row PD
}

Config.Vehicle = {
    model = "police4", -- Carro descaracterizado
    spawnCoords = vec4(406.72, -979.01, 29.27, 50.94) -- Uma das vagas na frente da Delegacia
}

Config.Rewards = {
    step_1 = 50,    -- Recompensa da etapa 1: Encontrou o corpo (50% a 150%)
    step_2 = 100,   -- Recompensa da etapa 2: Achou a prova (50% a 150%)
    step_3 = 200,   -- Recompensa da etapa 3: Hackeou o veículo (50% a 150%)
    step_4 = 300,   -- Recompensa da etapa 4: Prendeu o suspeito (50% a 150%)
    final = 600     -- Recompensa final: Relatório aprovado (50% a 150%)
}

Config.Casos = {
    -- ======== CASO 1: Homicídio no Beco (Testes) ========
    [1] = {
        MinutesToResolve = 12, 
        StoryTelling = "Um homicídio foi reportado pelas redondezas. Vá até o local do crime nas pressas!",
        CrimeScene = {
            model = "a_m_y_stbla_01", 
            coords = vec4(458.04, -963.27, 27.37, 22.01),
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Corpo"
        },
        Evidence = {
            model = "prop_cs_cardbox_01", 
            coords = vec4(493.18, -998.59, 27.78, 282.59), 
            label = "Procurar Pistas"
        },
        Hacker = {
            model = "burrito", -- Furgão de carga modificado
            coords = vec4(466.23, -1064.29, 29.21, 88.52), 
            label = "Hackear Rádio do Furgão"
        },
        Suspect = {
            model = "g_m_y_strpunk_01",
            coords = vec4(404.54, -1065.43, 28.32, 88.36), 
            label = "Algemar Suspeito"
        }
    },
    -- ======== CASO 2: Tráfico na Praia de Vespucci ========
    [2] = {
        MinutesToResolve = 15, 
        StoryTelling = "Turistas apavorados denunciaram um corpo na areia da praia de Vespucci. Vá pra lá rápido!",
        CrimeScene = {
            model = "a_m_y_beach_01", 
            coords = vec4(-1218.4, -1533.8, 3.4, 114.0), -- Areia da praia
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Banhista"
        },
        Evidence = {
            model = "prop_drug_package", 
            coords = vec4(-1278.4, -1586.3, 4.4, 21.0), -- Perto do Pier dos Salva Vidas
            label = "Analisar Drogas"
        },
        Hacker = {
            model = "speedo", -- Furgão simples praia
            coords = vec4(-1474.9, -1004.9, 6.3, 212.0), -- Bancos do Del Perro
            label = "Extrair Dados do Furgão"
        },
        Suspect = {
            model = "g_m_m_mexboss_01",
            coords = vec4(-1012.3, -1274.1, 5.2, 45.0), -- Parte de trás das lojas da praia
            label = "Prender Traficante"
        }
    },
    
    -- ======== CASO 3: Assassinato no Parque (Mirror Park) ========
    [3] = {
        MinutesToResolve = 14, 
        StoryTelling = "Alguém ouviu tiros durante a noite no lago do Mirror Park. Verifique a área das árvores!",
        CrimeScene = {
            model = "a_m_y_vinewood_01", 
            coords = vec4(1048.2, -737.5, 56.5, 90.0), -- Árvores no Mirror Park
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Cidadão"
        },
        Evidence = {
            model = "prop_cs_cardbox_01", 
            coords = vec4(1209.5, -450.7, 66.8, 0.0), -- Rua aberta
            label = "Analisar Caixa Suspeita"
        },
        Hacker = {
            model = "pony", -- Furgão vintage
            coords = vec4(1060.0, -514.8, 63.1, 280.0), -- Estacionado perfeitamente na West Mirror Drive
            label = "Invadir Sistema do Furgão"
        },
        Suspect = {
            model = "a_m_y_hipster_01",
            coords = vec4(1085.6, -525.8, 61.9, 230.0), -- Calçada firme e plana em Mirror Park
            label = "Algemar Assassino"
        }
    },

    -- ======== CASO 4: Queima de Arquivo em Paleto Bay ========
    [4] = {
        MinutesToResolve = 28, 
        StoryTelling = "Um fazendeiro encontrou um corpo nas proximidades rurais de Paleto Bay. É longe, pegue a rodovia!",
        CrimeScene = {
            model = "s_m_y_garbage", 
            coords = vec4(-111.4, 6451.9, 30.4, 180.0), -- Paleto Bay centro
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Vítima"
        },
        Evidence = {
            model = "prop_ld_suitcase_01", 
            coords = vec4(175.7, 6599.9, 31.8, 90.0), -- Posto de gasolina Paleto
            label = "Analisar Maleta"
        },
        Hacker = {
            model = "rumpo", -- Furgão clássico
            coords = vec4(-148.9, 6385.0, 31.5, 220.0), -- Estacionamento aberto do Don's Country Store na rua principal
            label = "Invadir Furgão de Escuta"
        },
        Suspect = {
            model = "g_m_y_strpunk_02",
            coords = vec4(-281.4, 6330.1, 31.4, 225.0), -- Calçadas de trás / campo aberto das casas em Paleto
            label = "Algemar Suspeito"
        }
    },

    -- ======== CASO 5: Máfia do Deserto em Sandy Shores ========
    [5] = {
        MinutesToResolve = 22, 
        StoryTelling = "Tiroteio intenso no deserto de Sandy Shores deixou um turista morto. A prefeitura exige respostas rápidas.",
        CrimeScene = {
            model = "a_m_m_tramp_01", 
            coords = vec4(1530.5, 3776.3, 33.5, 0.0), -- Marina Dr (Sandy Shores)
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Cadáver"
        },
        Evidence = {
            model = "prop_poly_bag_01", 
            coords = vec4(1966.4, 3745.2, 31.0, 180.0), -- Fundo do Yellow Jack Bar
            label = "Analisar Saco Plástico"
        },
        Hacker = {
            model = "bison", -- Picape de fazendeiro
            coords = vec4(1694.0, 3600.0, 35.0, 90.0), -- Estradinha de terra (Airfield)
            label = "Hackear Rádio do Carro"
        },
        Suspect = {
            model = "a_m_m_salton_01",
            coords = vec4(1859.6, 3680.1, 32.7, 270.0), -- Perto do xerife de Sandy
            label = "Imobilizar Caipira"
        }
    },

    -- ======== CASO 6: Dívidas no Cassino Diamond ========
    [6] = {
        MinutesToResolve = 14, 
        StoryTelling = "Um endividado perdeu a vida no estacionamento do Cassino. Pode ter envolvimento de agiotas de luxo.",
        CrimeScene = {
            model = "a_m_y_business_01", 
            coords = vec4(928.3, -29.8, 77.7, 55.0), -- Estacionamento aberto do cassino
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Engravatado"
        },
        Evidence = {
            model = "prop_security_case_01", 
            coords = vec4(972.1, -112.5, 74.3, 110.0), -- Atrás do lado de fora do cassino
            label = "Analisar Maleta de Dinheiro"
        },
        Hacker = {
            model = "paradise", -- Furgão temático de praia
            coords = vec4(900.5, 12.8, 78.4, 210.0), -- Rua da frente do cassino
            label = "Revisar Câmeras do Furgão"
        },
        Suspect = {
            model = "a_m_y_business_02",
            coords = vec4(859.1, -17.5, 77.8, 120.0), -- Perto da estrada da represa
            label = "Render Agiota"
        }
    },

    -- ======== CASO 7: O Caso da Praça Principal (Legion Square) ========
    [7] = {
        MinutesToResolve = 12, 
        StoryTelling = "Corpo avistado em um dos bancos da Legion Square no centro da cidade. Mantenha os civis afastados!",
        CrimeScene = {
            model = "a_m_y_runner_01", 
            coords = vec4(184.2, -943.5, 29.1, 90.0), -- Dentro da Legion Square
            animDict = "dead",
            anim = "dead_a",
            label = "Avaliar Atleta"
        },
        Evidence = {
            model = "prop_paper_bag_01", 
            coords = vec4(210.5, -900.2, 30.6, 180.0), -- Fundo de um dos totens
            label = "Analisar Saco Pardo"
        },
        Hacker = {
            model = "youga", -- Furgão simples
            coords = vec4(230.1, -855.9, 30.1, 0.0), -- Vaga perto da prefeitura
            label = "Invadir Furgão Suspeito"
        },
        Suspect = {
            model = "g_m_m_chiboss_01",
            coords = vec4(302.6, -904.36, 28.29, 93.89), -- Praça da Escultura de Metal vermelha cruzando a rua
            label = "Algemar Mafioso"
        }
    },

    -- ======== CASO 8: Terror no Porto de Los Santos ========
    [8] = {
        MinutesToResolve = 16, 
        StoryTelling = "Guarda portuário achou um cadáver próximo aos contêineres de carga nas docas do Terminal.",
        CrimeScene = {
            model = "s_m_m_dockwork_01", 
            coords = vec4(72.34, -2741.86, 5.0, 180.0), -- Entradas do Porto
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Trabalhador"
        },
        Evidence = {
            model = "prop_tool_box_01", 
            coords = vec4(56.85, -2691.52, 5.1, 90.0), -- Chão perto de guindastes
            label = "Analisar Caixa de Ferramentas"
        },
        Hacker = {
            model = "burrito3", -- Furgão de serviço
            coords = vec4(-57.69, -2527.06, 5.01, 270.0), -- Estacionamento da Doca Seca
            label = "Rastrear Rádio"
        },
        Suspect = {
            model = "g_m_y_salvagoon_01",
            coords = vec4(-160.2, -2410.5, 5.0, 270.0), -- Posto do correio das Docas
            label = "Derrubar Contrabandista"
        }
    },

    -- ======== CASO 9: Assassinato Estudantil (Vinewood Central) ========
    [9] = {
        MinutesToResolve = 14, 
        StoryTelling = "Universitário sumiu e seu corpo foi descartado nos asfaltos chiques do centro de Vinewood.",
        CrimeScene = {
            model = "a_m_y_vinewood_02", 
            coords = vec4(310.2, 189.5, 103.05, 90.0), -- Asfalto central Vinewood
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Vítima Jovem"
        },
        Evidence = {
            model = "prop_drug_package", 
            coords = vec4(233.32, 205.7, 105.4, 180.0), -- Beco perto de loja
            label = "Verificar Mochila Suspeita"
        },
        Hacker = {
            model = "speedo", -- Furgão basico
            coords = vec4(204.83, 290.14, 105.59, 64.71), -- Estacionamento do shopping de vinewood
            label = "Acessar Banco de Fugas"
        },
        Suspect = {
            model = "a_m_y_soucent_02",
            coords = vec4(150.2, 190.5, 105.38, 270.0), -- Fundos de um beco comercial
            label = "Algemar Assaltante"
        }
    },

    -- ======== CASO 10: Caos no Aeroporto Internacional ========
    [10] = {
        MinutesToResolve = 17, 
        StoryTelling = "Corpo ejetado de um veículo de luxo nos desembarques do Aeroporto de LS. Resolva o mais rápido possível!",
        CrimeScene = {
            model = "s_m_m_highsec_01", 
            coords = vec4(-1055.2, -2700.5, 12.81, 90.0), -- Terminal Térreo externo do Aeroporto
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Segurança"
        },
        Evidence = {
            model = "prop_security_case_01", 
            coords = vec4(-1088.88, -2860.62, 13.95, 180.0), -- Perto dos carrinhos de bagagem
            label = "Analisar Bagagem Violada"
        },
        Hacker = {
            model = "pony", -- Furgão simples
            coords = vec4(-1208.27, -2805.91, 12.95, 0.0), -- Vagas do estacionamento grande (Aeroporto)
            label = "Invadir Furgão Lotado"
        },
        Suspect = {
            model = "g_m_m_mexboss_01",
            coords = vec4(-1300.2, -2700.5, 12.94, 270.0), -- Rua externa perto do aluguel de carros
            label = "Prender Assassino de Aluguel"
        }
    },

    -- ======== CASO 11: Misticismo no Cemitério (Pacific Bluffs) ========
    [11] = {
        MinutesToResolve = 17, 
        StoryTelling = "Coveiros entraram em pânico! Denunciaram um caixão violado acompanhado de um corpo fresco no Cemitério.",
        CrimeScene = {
            model = "u_m_y_zombie_01", 
            coords = vec4(-1650.2, -200.5, 54.2, 90.0), -- Gramado plano dentro do cemitério
            animDict = "dead",
            anim = "dead_a",
            label = "Investigar Ritual"
        },
        Evidence = {
            model = "prop_cs_cardbox_01", 
            coords = vec4(-1700.5, -150.2, 59.8, 180.0), -- Fundo de uma das lapides maiores
            label = "Analisar Oferenda"
        },
        Hacker = {
            model = "rumpo", -- Furgão retro
            coords = vec4(-1774.78, -89.65, 82.8, 2.34), -- Estacionamento da capela do cemitério
            label = "Hackear Placa do Veículo"
        },
        Suspect = {
            model = "s_m_m_mariachi_01",
            coords = vec4(-1939.07, -152.23, 33.58, 155.93), -- Rua costeira descendo o cemitério
            label = "Render Ocultista"
        }
    }
    
}
