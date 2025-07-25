local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    Players.PlayerAdded:Wait()
    player = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera

-- Настройки телепортации
local TARGET_SEAT = workspace["#GAME"].Map.Houses["Blue House"].Rooms.LivingRoom.DinnerTable:GetChildren()[6].Seat
local TELEPORT_KEY = Enum.KeyCode.U
local isTeleporting = true
local isSeated = false

-- Настройки Auto-Equip
local EQUIP_TOGGLE_KEY = Enum.KeyCode.Y
local TOOL_PRIORITY = {
    "Maus",
    "M1 Abrams",
    "Pine Tree",
    "King Slayer",
}
local isEquipRunning = true

-- Настройки Auto-Attack/Eat
local ATTACK_TOGGLE_KEY = Enum.KeyCode.T
local isActive = false
local priorityNames1 = { "Amethyst", "Ruby", "Emerald", "Diamond", "Golden" }
local priorityNames2 = { "Bull" }

-- Получение необходимых папок для Auto-Attack
local gameFolder = Workspace:WaitForChild("#GAME", 10)
local foldersFolder = gameFolder and gameFolder:WaitForChild("Folders", 5)
local humanoidFolder = foldersFolder and foldersFolder:WaitForChild("HumanoidFolder", 5)
local mainFolder = humanoidFolder and humanoidFolder:WaitForChild("NPCFolder", 5)
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
local remote = eventsFolder and eventsFolder:WaitForChild("MainAttack", 5)

-- Функция телепортации
local function teleportToSeat()
    if not isTeleporting then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Проверяем, сидит ли игрок уже
    if humanoid.SeatPart ~= nil then
        isSeated = true
        return
    else
        isSeated = false
    end
    
    -- Телепортируем к стулу
    if TARGET_SEAT and TARGET_SEAT.Parent then
        character:PivotTo(TARGET_SEAT.CFrame)
        -- Пробуем сесть (некоторые игры требуют дополнительных действий для сидения)
    end
end

-- Функция Auto-Equip
local function EquipTool()
    if not isEquipRunning then return end
    local Character = player.Character or player.CharacterAdded:Wait()
    local Backpack = player:FindFirstChildOfClass("Backpack")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Backpack or not Humanoid then return end
    for _, toolName in ipairs(TOOL_PRIORITY) do
        local Tool = Backpack:FindFirstChild(toolName) or Character:FindFirstChild(toolName)
        if Tool and Tool:IsA("Tool") then
            if not Character:FindFirstChild(Tool.Name) then
                Humanoid:EquipTool(Tool)
                print("🔹 [Auto-Equip] Взят: " .. Tool.Name)
            end
            return
        end
    end
end

-- Функции Auto-Attack
local function getDeadNPCs()
    local deadList = {}
    if not mainFolder then return deadList end

    for _, npc in ipairs(mainFolder:GetChildren()) do
        if npc:IsA("Model") then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            if humanoid and (humanoid.Health <= 0 or string.find(humanoid.Name, "Dead", 1, true)) then
                table.insert(deadList, npc)
            end
        end
    end
    return deadList
end

local function getPriorityTarget(npcList)
    local function findByPriority(list, keywords)
        for _, keyword in ipairs(keywords) do
            for _, npc in ipairs(list) do
                if npc.Name:find(keyword, 1, true) then
                    return npc
                end
            end
        end
        return nil
    end

    local target = findByPriority(npcList, priorityNames1)
    if target then return target end

    target = findByPriority(npcList, priorityNames2)
    if target then return target end

    if #npcList > 0 then
        return npcList[math.random(1, #npcList)]
    end

    return nil
end

local function getValidBodyParts(model)
    local validParts = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local isGettingEaten = part:GetAttribute("IsGettingEaten")
            if not isGettingEaten then
                table.insert(validParts, part)
            end
        end
    end
    return validParts
end

-- Обработчики ввода
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Переключение телепортации
    if input.KeyCode == TELEPORT_KEY then
        isTeleporting = not isTeleporting
        print(isTeleporting and "🟢 [Auto-Teleport] Включено" or "🔴 [Auto-Teleport] Выключено")
        if isTeleporting then
            isSeated = false -- Сбросим флаг сидения при включении
        end
    end
    
    -- Переключение Auto-Equip
    if input.KeyCode == EQUIP_TOGGLE_KEY then
        isEquipRunning = not isEquipRunning
        print(isEquipRunning and "🟢 [Auto-Equip] Включено" or "🔴 [Auto-Equip] Выключено")
    end
    
    -- Переключение Auto-Attack
    if input.KeyCode == ATTACK_TOGGLE_KEY then
        isActive = not isActive
        print(isActive and "🟢 [Auto-Attack] Включено" or "🔴 [Auto-Attack] Выключено")
    end
end)

-- Подключение к событиям персонажа
player.CharacterAdded:Connect(function()
    task.wait(2)
    if isEquipRunning then
        EquipTool()
    end
    isSeated = false -- Сбросим флаг при спавне нового персонажа
end)

-- Основной цикл
RunService.Heartbeat:Connect(function()
    -- Телепортация
    if isTeleporting and not isSeated then
        teleportToSeat()
    end
    
    -- Auto-Equip
    if isEquipRunning then
        EquipTool()
        task.wait(1.5)
    end
    
    -- Auto-Attack
    if not isActive then return end

    local deadNPCList = getDeadNPCs()
    if #deadNPCList == 0 then return end

    local targetNpc = getPriorityTarget(deadNPCList)
    if not targetNpc or not targetNpc.Parent then return end

    local validParts = getValidBodyParts(targetNpc)
    if #validParts == 0 then
        return
    end

    local bodyPart = validParts[math.random(1, #validParts)]

    local origin = Camera.CFrame.Position

    local targetPosition = bodyPart.Position

    local USE_DEVIATION = true
    local MAX_DEVIATION_STUDS = 0.5

    if USE_DEVIATION and MAX_DEVIATION_STUDS > 0 then
        local offsetX = (math.random() - 0.5) * 2 * MAX_DEVIATION_STUDS
        local offsetY = (math.random() - 0.5) * 2 * MAX_DEVIATION_STUDS
        local offsetZ = (math.random() - 0.5) * 2 * MAX_DEVIATION_STUDS
        targetPosition = targetPosition + Vector3.new(offsetX, offsetY, offsetZ)
    end

    local direction = (targetPosition - origin).Unit

    if direction.X ~= direction.X or direction.Y ~= direction.Y or direction.Z ~= direction.Z then
        warn("Calculated NaN direction! Falling back to LookVector. Origin:", origin, "Target:", targetPosition)
        direction = Camera.CFrame.LookVector
    end

    local args = {
        [1] = {
            ["AN"] = "Eat",
            ["D"] = direction,
            ["O"] = origin,
            ["FBP"] = bodyPart
        }
    }
    remote:FireServer(unpack(args))
end)

-- Инициализация
EquipTool()
print("🛠 [Auto-Equip] Готово! Нажми Y для включения/выключения.")
print("🏠 [Auto-Teleport] Готово! Нажми U для включения/выключения.")
if mainFolder and remote then
    print("⚔️ [Auto-Attack] Готово! Нажми T для включения/выключения.")
else
    warn("❌ [Auto-Attack] Не удалось найти необходимые объекты!")
end
