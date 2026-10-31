-- Shooter Utility Script: Speed, God Mode, Auto Reload, Head Aim, & Minimize Toggle
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local speedEnabled = false
local godModeEnabled = false
local autoReloadEnabled = false
local headAimEnabled = false

local CUSTOM_SPEED = 24

-- ==================== UI SETUP ====================
local function createUI()
	local old = player.PlayerGui:FindFirstChild("ShooterHelperUI")
	if old then old:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShooterHelperUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Main Menu Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 180, 0, 210)
	mainFrame.Position = UDim2.new(0.75, -90, 0.3, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Text = "Shooter Menu"
	title.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	-- Minimize (Circular) Button
	local minButton = Instance.new("TextButton")
	minButton.Name = "MinButton"
	minButton.Size = UDim2.new(0, 45, 0, 45)
	minButton.Position = UDim2.new(0.9, -45, 0.15, 0)
	minButton.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
	minButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	minButton.Font = Enum.Font.GothamBold
	minButton.TextSize = 18
	minButton.Text = "⚙️"
	minButton.Parent = screenGui

	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(1, 0) -- Perfect Circle
	minCorner.Parent = minButton

	-- Toggle Menu Visibility
	local menuVisible = true
	minButton.MouseButton1Click:Connect(function()
		menuVisible = not menuVisible
		mainFrame.Visible = menuVisible
	end)

	-- Helper function to create toggle buttons
	local function createToggle(name, yPos, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 160, 0, 32)
		btn.Position = UDim2.new(0.5, -80, 0, yPos)
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 12
		btn.Text = name .. ": OFF"
		btn.Parent = mainFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local active = false
		btn.MouseButton1Click:Connect(function()
			active = not active
			if active then
				btn.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
				btn.Text = name .. ": ON"
			else
				btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
				btn.Text = name .. ": OFF"
			end
			callback(active)
		end)
	end

	createToggle("Speed Boost", 40, function(state) speedEnabled = state end)
	createToggle("God Mode", 78, function(state) godModeEnabled = state end)
	createToggle("Auto Reload", 116, function(state) autoReloadEnabled = state end)
	createToggle("Head Aim", 154, function(state) headAimEnabled = state end)

	-- Draggable Window Logic for Main Frame
	local dragging, dragStart, startPos
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- Draggable Minimize Button Logic
	local minDragging, minDragStart, minStartPos
	minButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			minDragging = true
			minDragStart = input.Position
			minStartPos = minButton.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if minDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - minDragStart
			minButton.Position = UDim2.new(minStartPos.X.Scale, minStartPos.X.Offset + delta.X, minStartPos.Y.Scale, minStartPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			minDragging = false
		end
	end)

	return screenGui
end

createUI()

-- ==================== FEATURES LOOP ====================
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	-- 1. Speed Boost (Enforced every frame)
	if speedEnabled then
		humanoid.WalkSpeed = CUSTOM_SPEED
	end

	-- 2. God Mode (Using a safe high health value instead of math.huge)
	if godModeEnabled then
		pcall(function()
			humanoid.MaxHealth = 999999
			humanoid.Health = 999999
		end)
	end

	-- 3. Auto Reload (Simulates pressing 'R' using VirtualInputManager)
	if autoReloadEnabled then
		pcall(function()
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
			end
		end)
	end

	-- 4. Head Aim Assistance (Smoothly shifts camera toward enemy heads)
	if headAimEnabled then
		pcall(function()
			local closestHead = nil
			local shortestDist = math.huge

			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local enemyChar = p.Character
					local enemyHead = enemyChar:FindFirstChild("Head")
					local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid")

					if enemyHead and enemyHumanoid and enemyHumanoid.Health > 0 then
						local dist = (enemyHead.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 120 then
							shortestDist = dist
							closestHead = enemyHead
						end
					end
				end
			end

			if closestHead then
				camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, closestHead.Position), 0.2)
			end
		end)
	end
end)

print("[ShooterScript] Fully updated with Minimize and fixes!")
