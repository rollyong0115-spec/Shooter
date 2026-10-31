-- Shooter Pro Script: 100k HP, Wall Hack (ESP), Auto Aim, Head Assist, Fly, Speed, Auto Reload & Minimize
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local speedEnabled = false
local hpBoostEnabled = false
local autoReloadEnabled = false
local headAimEnabled = false
local autoAimEnabled = false
local flyEnabled = false
local espEnabled = false

local CUSTOM_SPEED = 24
local FLY_SPEED = 40

local bodyVelocity = nil
local bodyGyro = nil
local flyConnection = nil
local espHighlights = {}

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
	mainFrame.Size = UDim2.new(0, 180, 0, 310)
	mainFrame.Position = UDim2.new(0.75, -90, 0.2, 0)
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
	title.Text = "Shooter Pro Menu"
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
	minCorner.CornerRadius = UDim.new(1, 0)
	minCorner.Parent = minButton

	local menuVisible = true
	minButton.MouseButton1Click:Connect(function()
		menuVisible = not menuVisible
		mainFrame.Visible = menuVisible
	end)

	-- Helper function to create toggle buttons
	local function createToggle(name, yPos, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 160, 0, 30)
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

	createToggle("Speed Boost", 38, function(state) speedEnabled = state end)
	createToggle("100k HP Boost", 72, function(state) hpBoostEnabled = state end)
	createToggle("Auto Reload", 106, function(state) autoReloadEnabled = state end)
	createToggle("Wall Hack (ESP)", 140, function(state) espEnabled = state end)
	createToggle("Head Assist", 174, function(state) headAimEnabled = state end)
	createToggle("Auto Aim (Lock)", 208, function(state) autoAimEnabled = state end)
	createToggle("Fly Mode", 242, function(state) flyEnabled = state end)

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

-- ==================== FLY FUNCTIONS ====================
local function startFly(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(30000, 30000, 30000)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(30000, 30000, 30000)
	bodyGyro.P = 2500
	bodyGyro.Parent = root

	humanoid.PlatformStand = true

	flyConnection = RunService.Heartbeat:Connect(function()
		if not flyEnabled or not root or not root.Parent then return end
		local move = humanoid.MoveDirection
		local velocity = Vector3.zero

		if move.Magnitude > 0.05 then
			velocity = move * FLY_SPEED
		end

		if UserInputService.TouchEnabled and humanoid.Jump then
			velocity = velocity + Vector3.new(0, FLY_SPEED * 0.7, 0)
		end

		bodyVelocity.Velocity = velocity
		bodyGyro.CFrame = camera.CFrame
	end)
end

local function stopFly(char)
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.PlatformStand = false end
end

-- ==================== MAIN LOOP ====================
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	-- 1. Speed Boost
	if speedEnabled then
		humanoid.WalkSpeed = CUSTOM_SPEED
	end

	-- 2. 100k HP Boost Loop
	if hpBoostEnabled then
		pcall(function()
			humanoid.MaxHealth = 100000
			humanoid.Health = 100000
		end)
	end

	-- 3. Auto Reload
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

	-- 4. Wall Hack (ESP) Handler
	if espEnabled then
		pcall(function()
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local enemyChar = p.Character
					if not espHighlights[p] and enemyChar:FindFirstChild("HumanoidRootPart") then
						local hl = Instance.new("Highlight")
						hl.Name = "ESPHighlight"
						hl.FillColor = Color3.fromRGB(255, 0, 0)
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.4
						hl.Adornee = enemyChar
						hl.Parent = enemyChar
						espHighlights[p] = hl
					end
				end
			end
		end)
	else
		for p, hl in pairs(espHighlights) do
			if hl then hl:Destroy() end
		end
		espHighlights = {}
	end

	-- 5. Head Assist (Smooth tracking)
	if headAimEnabled and not autoAimEnabled then
		pcall(function()
			local closestHead = nil
			local shortestDist = math.huge
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local enemyHead = p.Character:FindFirstChild("Head")
					local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
					if enemyHead and enemyHum and enemyHum.Health > 0 then
						local dist = (enemyHead.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 150 then
							shortestDist = dist
							closestHead = enemyHead
						end
					end
				end
			end
			if closestHead then
				camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, closestHead.Position), 0.25)
			end
		end)
	end

	-- 6. Auto Aim (Hard Snap Lock to Enemy Head)
	if autoAimEnabled then
		pcall(function()
			local closestHead = nil
			local shortestDist = math.huge
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local enemyHead = p.Character:FindFirstChild("Head")
					local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
					if enemyHead and enemyHum and enemyHum.Health > 0 then
						local dist = (enemyHead.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 200 then
							shortestDist = dist
							closestHead = enemyHead
						end
					end
				end
			end
			if closestHead then
				camera.CFrame = CFrame.new(camera.CFrame.Position, closestHead.Position)
			end
		end)
	end

	-- 7. Fly Handler
	if flyEnabled and not flyConnection then
		startFly(char)
	elseif not flyEnabled and flyConnection then
		stopFly(char)
	end
end)

print("[Shooter Pro] Loaded with 100k HP Boost, Wall Hack, and more!")
