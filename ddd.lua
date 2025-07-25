local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Если LocalPlayer еще не существует, ждем, пока игрок присоединится
if not LocalPlayer then
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:WaitForChild("Mouse") or LocalPlayer:GetMouse()

-- === AUTO EQUIP СКРИПТ ===
local EQUIP_TOGGLE_KEY = Enum.KeyCode.Y
local TOOL_PRIORITY = {
    "Maus",
    "M1 Abrams",
    "Pine Tree",
    "King Slayer",
}
local isEquipRunning = true

local function EquipTool()
    if not isEquipRunning then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local Humanoid = character:FindFirstChildOfClass("Humanoid")
    if not Backpack or not Humanoid then return end
    
    for _, toolName in ipairs(TOOL_PRIORITY) do
        local Tool = Backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
        if Tool and Tool:IsA("Tool") then
            if not character:FindFirstChild(Tool.Name) then
                Humanoid:EquipTool(Tool)
                print("🔹 [Auto-Equip] Взят: " .. Tool.Name)
            end
            return
        end
    end
end

-- Подключение события CharacterAdded только если LocalPlayer существует
if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(2)
        if isEquipRunning then
            EquipTool()
        end
    end)
else
    warn("LocalPlayer не найден при подключении CharacterAdded.")
end

RunService.Heartbeat:Connect(function()
    if isEquipRunning then
        EquipTool()
        task.wait(1.5)
    end
end)

UserInputService.InputBegan:Connect(function(Input, gameProcessed)
    if gameProcessed then return end
    
    if Input.KeyCode == EQUIP_TOGGLE_KEY then
        isEquipRunning = not isEquipRunning
        print(isEquipRunning and "🟢 [Auto-Equip] Включено" or "🔴 [Auto-Equip] Выключено")
    end
end)

EquipTool()
print("🛠 [Auto-Equip] Готово! Нажми Y для включения/выключения.")

-- === AUTO SEAT СКРИПТ ===
local SEAT_TOGGLE_KEY = Enum.KeyCode.U

-- Безопасное получение пути к месту
local function getSeatPath()
    local gameObj = Workspace:FindFirstChild("#GAME")
    if not gameObj then return nil end
    
    local map = gameObj:FindFirstChild("Map")
    if not map then return nil end
    
    local houses = map:FindFirstChild("Houses")
    if not houses then return nil end
    
    local blueHouse = houses:FindFirstChild("Blue House")
    if not blueHouse then return nil end
    
    local rooms = blueHouse:FindFirstChild("Rooms")
    if not rooms then return nil end
    
    local livingRoom = rooms:FindFirstChild("LivingRoom")
    if not livingRoom then return nil end
    
    local dinnerTable = livingRoom:FindFirstChild("DinnerTable")
    if not dinnerTable then return nil end
    
    local children = dinnerTable:GetChildren()
    if #children < 6 then return nil end
    
    local sixthChild = children[6]
    local seat = sixthChild:FindFirstChild("Seat")
    
    return seat
end

local isSeatRunning = true
local isSeated = false

-- Функция для телепортации к месту
local function TeleportToSeat()
    if not isSeatRunning or isSeated then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local seatPath = getSeatPath()
    
    if humanoid and rootPart and seatPath and seatPath:IsA("Seat") then
        -- Проверяем, что место свободно
        if not seatPath.Occupant then
            rootPart.CFrame = seatPath.CFrame
            print("🔹 [Auto-Seat] Телепортация к месту...")
        end
    end
end

-- Функция для проверки, сел ли игрок
local function CheckIfSeated()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local seatPath = getSeatPath()
    
    if humanoid and humanoid.SeatPart and seatPath and humanoid.SeatPart == seatPath then
        isSeated = true
        print("✅ [Auto-Seat] Игрок сел!")
    else
        isSeated = false
    end
end

-- Обработчик смерти персонажа
if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1) -- Небольшая задержка для загрузки персонажа
        isSeated = false
        print("🔄 [Auto-Seat] Персонаж возрожден, возобновление телепортации...")
    end)
else
    warn("LocalPlayer не найден при подключении CharacterAdded.")
end

-- Основной цикл для сидения
RunService.Heartbeat:Connect(function()
    if isSeatRunning then
        CheckIfSeated()
        TeleportToSeat()
    end
end)

-- Обработчик нажатия клавиши для сидения
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == SEAT_TOGGLE_KEY then
        isSeatRunning = not isSeatRunning
        if isSeatRunning then
            isSeated = false -- Сброс статуса при включении
            print("🟢 [Auto-Seat] Включено")
        else
            print("🔴 [Auto-Seat] Выключено")
        end
    end
end)

print("🛠 [Auto-Seat] Готово! Нажми U для включения/выключения.")

-- === AUTO ATTACK СКРИПТ ===
local gameFolder = Workspace:FindFirstChild("#GAME")
local foldersFolder = gameFolder and gameFolder:FindFirstChild("Folders")
local humanoidFolder = foldersFolder and foldersFolder:FindFirstChild("HumanoidFolder")
local mainFolder = humanoidFolder and humanoidFolder:FindFirstChild("NPCFolder")

local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
local remote = eventsFolder and eventsFolder:FindFirstChild("MainAttack")

if not mainFolder then
    warn("Auto Attack: Could not find NPCFolder at expected path.")
else
    print("✅ [Auto-Attack] NPCFolder найден")
end

if not remote then
    warn("Auto Attack: Could not find MainAttack RemoteEvent.")
else
    print("✅ [Auto-Attack] MainAttack RemoteEvent найден")
end

local isActive = false
local priorityNames1 = { "Amethyst", "Ruby", "Emerald", "Diamond", "Golden" }
local priorityNames2 = { "Bull" }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        isActive = not isActive
        print(isActive and "🟢 Auto Attack ON" or "🔴 Auto Attack OFF")
    end
end)

local function getDeadNPCs()
    local deadList = {}
    if not mainFolder then return deadList end

    for _, npc in ipairs(mainFolder:GetChildren()) do
        if npc:IsA("Model") then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            -- Check if Humanoid exists AND (Health is 0 or less OR its name contains "Dead")
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

local USE_DEVIATION = true
local MAX_DEVIATION_STUDS = 0.5

RunService.Heartbeat:Connect(function()
    if not isActive then return end
    if not remote or not mainFolder then return end

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
    
    pcall(function()
        remote:FireServer(unpack(args))
    end)
end)

print("✅ Все скрипты загружены!")
