-- Pilot.lua - Script para detectar e exibir informações de jogadores usando LifeSensor
-- Para o jogo Waste of Space no Roblox

local Microcontroller = GetPart("Microcontroller")
local LifeSensor = GetPartFromPort(1, "LifeSensor")

-- Verificar se os componentes estão conectados
assert(Microcontroller, "Microcontroller não encontrado")
assert(LifeSensor, "LifeSensor não encontrado na porta 1")

-- Variáveis para armazenar dados dos jogadores
local playersData = {}
local lastUpdate = 0
local updateInterval = 1 -- Atualizar a cada 1 segundo

-- Função para obter nome do jogador pelo UserId
local function getPlayerName(userId)
    -- No WOS, utilizamos o Players service para obter nomes
    local success, result = pcall(function()
        return game.Players:GetNameFromUserIdAsync(userId)
    end)
    
    if success then
        return result
    else
        return "Jogador " .. tostring(userId)
    end
end

-- Função para calcular distância entre duas posições
local function calculateDistance(pos1, pos2)
    if typeof(pos1) == "CFrame" then
        pos1 = pos1.Position
    end
    if typeof(pos2) == "CFrame" then
        pos2 = pos2.Position
    end
    
    return (pos1 - pos2).Magnitude
end

-- Função para formatar posição para exibição
local function formatPosition(position)
    if typeof(position) == "CFrame" then
        position = position.Position
    end
    return string.format("(%.1f, %.1f, %.1f)", position.X, position.Y, position.Z)
end

-- Função para formatar distância
local function formatDistance(distance)
    if distance < 1000 then
        return string.format("%.1f studs", distance)
    else
        return string.format("%.2f k studs", distance / 1000)
    end
end

-- Função para atualizar dados dos jogadores
local function updatePlayersData()
    local currentTime = tick()
    
    -- Limpar dados antigos
    playersData = {}
    
    print("=== LIFESENSOR - DETECÇÃO DE JOGADORES ===")
    print("Sensor Position:", formatPosition(LifeSensor.Position))
    print("Timestamp:", os.date("%H:%M:%S", currentTime))
    print("---")
    
    -- Obter jogadores próximos (dentro de 2000 studs) usando GetPlayers()
    local nearbyPlayers = LifeSensor:GetPlayers()
    local nearbyCount = 0
    
    for userId, cframe in pairs(nearbyPlayers) do
        nearbyCount = nearbyCount + 1
        local distance = calculateDistance(LifeSensor.Position, cframe.Position)
        local playerName = getPlayerName(userId)
        
        playersData[userId] = {
            name = playerName,
            position = cframe.Position,
            cframe = cframe,
            distance = distance,
            isNearby = true
        }
        
        print(string.format("👤 %s (ID: %d)", playerName, userId))
        print(string.format("   📍 Posição: %s", formatPosition(cframe.Position)))
        print(string.format("   📏 Distância: %s", formatDistance(distance)))
        print("---")
    end
    
    -- Obter todos os jogadores (ignorando limite de distância) usando ListPlayers()
    local allPlayerIds = LifeSensor:ListPlayers()
    local distantCount = 0
    
    for _, userId in ipairs(allPlayerIds) do
        if not playersData[userId] then
            -- Este jogador está fora do alcance de 2000 studs
            distantCount = distantCount + 1
            local playerName = getPlayerName(userId)
            
            playersData[userId] = {
                name = playerName,
                position = nil,
                cframe = nil,
                distance = nil,
                isNearby = false
            }
            
            print(string.format("🔍 %s (ID: %d) - FORA DE ALCANCE", playerName, userId))
            print("   📍 Posição: Desconhecida (>2000 studs)")
            print("   📏 Distância: >2000 studs")
            print("---")
        end
    end
    
    -- Obter dados de humanoides usando GetReading()
    local humanoidData = LifeSensor:GetReading()
    local humanoidCount = 0
    
    if next(humanoidData) then
        print("=== DADOS DE HUMANOIDES ===")
        for name, position in pairs(humanoidData) do
            humanoidCount = humanoidCount + 1
            local distance = calculateDistance(LifeSensor.Position, position)
            
            print(string.format("🤖 %s", name))
            print(string.format("   📍 Posição: %s", formatPosition(position)))
            print(string.format("   📏 Distância: %s", formatDistance(distance)))
            print("---")
        end
    end
    
    -- Resumo final
    print("=== RESUMO ===")
    print(string.format("👥 Jogadores próximos: %d", nearbyCount))
    print(string.format("🔍 Jogadores distantes: %d", distantCount))
    print(string.format("🤖 Humanoides detectados: %d", humanoidCount))
    print(string.format("📊 Total de jogadores: %d", nearbyCount + distantCount))
    print("=======================================")
    print()
    
    lastUpdate = currentTime
end

-- Função principal de loop
local function onLoop()
    local currentTime = tick()
    
    -- Verificar se é hora de atualizar
    if currentTime - lastUpdate >= updateInterval then
        local success, error = pcall(updatePlayersData)
        
        if not success then
            print("❌ Erro ao atualizar dados dos jogadores:", error)
        end
    end
end

-- Conectar ao evento Loop do Microcontroller
Microcontroller.Loop:Connect(onLoop)

print("🚀 Pilot.lua iniciado com sucesso!")
print("📡 LifeSensor conectado e monitorando jogadores...")
print("🔄 Atualizando a cada", updateInterval, "segundo(s)")
print()