-- Pilot.lua - Script para detectar e exibir informações de jogadores usando LifeSensor
-- Para o jogo Waste of Space no Roblox

local Microcontroller = GetPart("Microcontroller")
local LifeSensor = GetPartFromPort(1, "LifeSensor")

-- Verificar se os componentes estão conectados
assert(LifeSensor, "LifeSensor não encontrado na porta 1")
-- Microcontroller é opcional, pode usar loop manual se não disponível

-- Variáveis para armazenar dados dos jogadores
local playersData = {}
local lastUpdate = 0
local updateInterval = 1 -- Atualizar a cada 1 segundo

-- Função para obter nome do jogador pelo UserId  
local function getPlayerName(userId)
    -- Em WOS, tentamos obter o nome de forma simplificada
    local success, result = pcall(function()
        -- Verifica se existe um método direto no WOS
        if game.Players.GetNameFromUserIdAsync then
            return game.Players:GetNameFromUserIdAsync(userId)
        else
            return "Player_" .. tostring(userId)
        end
    end)
    
    if success and result then
        return result
    else
        return "Player_" .. tostring(userId)
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
    playersData = {}
    
    print("=== LIFESENSOR - DETECÇÃO DE JOGADORES ===")
    print("Sensor Pos:", formatPosition(LifeSensor.Position))
    print("Time:", os.date("%H:%M:%S", currentTime))
    
    -- 1. Obter dados de humanoides usando GetReading() (método primário)
    local success1, humanoidData = pcall(function()
        return LifeSensor:GetReading()
    end)
    
    local humanoidCount = 0
    if success1 and humanoidData and next(humanoidData) then
        print("--- HUMANOIDES DETECTADOS ---")
        for playerName, position in pairs(humanoidData) do
            humanoidCount = humanoidCount + 1
            local distance = calculateDistance(LifeSensor.Position, position)
            
            print(string.format("%s - %s - %s", 
                playerName, 
                formatPosition(position), 
                formatDistance(distance)))
        end
    end
    
    -- 2. Obter jogadores próximos (CFrame data) usando GetPlayers()
    local success2, nearbyPlayers = pcall(function()
        return LifeSensor:GetPlayers()
    end)
    
    local nearbyCount = 0
    if success2 and nearbyPlayers and next(nearbyPlayers) then
        print("--- JOGADORES PRÓXIMOS (CFrame) ---")
        for userId, cframe in pairs(nearbyPlayers) do
            nearbyCount = nearbyCount + 1
            local distance = calculateDistance(LifeSensor.Position, cframe.Position)
            local playerName = getPlayerName(userId)
            
            playersData[userId] = {
                name = playerName,
                position = cframe.Position,
                distance = distance,
                isNearby = true
            }
            
            print(string.format("%s (ID:%d) - %s - %s", 
                playerName, userId,
                formatPosition(cframe.Position), 
                formatDistance(distance)))
        end
    end
    
    -- 3. Obter todos os jogadores usando ListPlayers()
    local success3, allPlayerIds = pcall(function()
        return LifeSensor:ListPlayers()
    end)
    
    local distantCount = 0
    if success3 and allPlayerIds and #allPlayerIds > 0 then
        print("--- TODOS OS JOGADORES ---")
        for _, userId in ipairs(allPlayerIds) do
            if not playersData[userId] then
                distantCount = distantCount + 1
                local playerName = getPlayerName(userId)
                
                playersData[userId] = {
                    name = playerName,
                    isNearby = false
                }
                
                print(string.format("%s (ID:%d) - FORA DE ALCANCE (>2000 studs)", 
                    playerName, userId))
            end
        end
    end
    
    -- Resumo
    print(string.format("--- RESUMO: %d humanoides, %d próximos, %d distantes ---", 
        humanoidCount, nearbyCount, distantCount))
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

-- Conectar ao evento Loop do Microcontroller para atualização contínua
-- Se Microcontroller não estiver disponível, usa um loop simples
if Microcontroller and Microcontroller.Loop then
    Microcontroller.Loop:Connect(onLoop)
    print("🔄 Conectado ao Microcontroller.Loop para atualizações automáticas")
else
    print("⚠️ Microcontroller.Loop não disponível, iniciando loop manual")
    task.spawn(function()
        while true do
            onLoop()
            task.wait(updateInterval)
        end
    end)
end

print("🚀 Pilot.lua - LifeSensor Player Detection Script")
print("📡 LifeSensor conectado - Monitorando jogadores...")
print("🔄 Intervalo de atualização:", updateInterval, "segundo(s)")
print()