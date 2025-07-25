local TOGGLE_KEY = Enum.KeyCode.Y
local TOOL_PRIORITY = {
    "Maus",
    "M1 Abrams",
    "Pine Tree",
    "King Slayer",
}
local isRunning = true
local function EquipTool()
    if not isRunning then return end
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

player.CharacterAdded:Connect(function()
    task.wait(2)
    if isRunning then
        EquipTool()
    end
end)

RunService.Heartbeat:Connect(function()
    if isRunning then
        EquipTool()
        task.wait(1.5)
    end
end)

UserInputService.InputBegan:Connect(function(Input, _)
    if Input.KeyCode == TOGGLE_KEY then
        isRunning = not isRunning
        print(isRunning and "🟢 [Auto-Equip] Включено" or "🔴 [Auto-Equip] Выключено")
    end
end)

EquipTool()
print("🛠 [Auto-Equip] Готово! Нажми Y для включения/выключения.")

wait(1)

llocal UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.U -- Клавиша для включения/выключения
local isRunning = true
local seated = false

-- Путь к месту, куда нужно телепортировать
local function getSeat()
    local seatPath = workspace["#GAME"].Map.Houses["Blue House"].Rooms.LivingRoom.DinnerTable
    local children = seatPath:GetChildren()
    if #children >= 6 then
        return children[6].Seat
    end
    return nil
end

-- Функция для телепортации
local function teleportToSeat()
    if not isRunning then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local seat = getSeat()
    if not seat or not seat:IsA("Seat") then return end

    -- Если игрок уже сидит — не телепортируем
    if humanoid.SeatPart == seat then
        seated = true
        return
    end

    -- Если игрок не сидит — телепортируем
    if humanoid.Sit ~= true then
        seated = false
        local pos = seat.CFrame
        character:SetPrimaryPartCFrame(pos)
    else
        seated = true
    end
end

-- Проверка при смерти или возрождении
player.CharacterAdded:Connect(function(char)
    seated = false
    task.wait(1)
    while char and isRunning do
        teleportToSeat()
        task.wait(0.1)
    end
end)

-- Бесконечная проверка
RunService.Heartbeat:Connect(function()
    if isRunning and player.Character then
        teleportToSeat()
    end
end)

-- Переключение активности по кнопке
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        isRunning = not isRunning
        if isRunning then
            print("🟢 [Auto-Teleport] Включено")
            seated = false
        else
            print("🔴 [Auto-Teleport] Выключено")
        end
    end
end)

print("🛠 [Auto-Teleport] Готово! Нажми U для включения/выключения.")

wait(1)


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse() -- Retained as it might be needed for other game interactions, though not directly by this script's core logic.

local gameFolder = Workspace:WaitForChild("#GAME", 10)
local foldersFolder = gameFolder and gameFolder:WaitForChild("Folders", 5)
local humanoidFolder = foldersFolder and foldersFolder:WaitForChild("HumanoidFolder", 5)
local mainFolder = humanoidFolder and humanoidFolder:WaitForChild("NPCFolder", 5) -- Your target folder

local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
local remote = eventsFolder and eventsFolder:WaitForChild("MainAttack", 5)

if not mainFolder then
	warn("Auto Attack: Could not find NPCFolder at expected path.")
	return
end
if not remote then
	warn("Auto Attack: Could not find MainAttack RemoteEvent.")
	return
end


local isActive = false

local priorityNames1 = { "Amethyst", "Ruby", "Emerald", "Diamond", "Golden" }
local priorityNames2 = { "Bull" }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		isActive = not isActive
		print(isActive and "Auto Attack ON" or "Auto Attack OFF")
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
	remote:FireServer(unpack(args))
end)
