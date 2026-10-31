-- Shooter Utility Script: Speed, Auto Reload, Head Aim, and God Mode
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local speedEnabled = false
local godModeEnabled = false
local autoReloadEnabled = false
local headAimEnabled = false

local CUSTOM_SPEED = 24 -- Adjust walking speed here (default is usually 16)

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

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 180, 0, 210)
	mainFrame.Position = UDim2.new(0.8, -90, 0.3, 0)
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

	-- Draggable Window Logic
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

	-- 1. Speed Boost
	if speedEnabled then
		humanoid.WalkSpeed = CUSTOM_SPEED
	end

	-- 2. God Mode Loop
	if godModeEnabled then
		pcall(function()
			humanoid.MaxHealth = math.huge
			humanoid.Health = math.huge
		end)
	end

	-- 3. Auto Reload simulation (presses 'R' or triggers tool reload if available)
	if autoReloadEnabled then
		pcall(function()
			-- Simulates reloading check (VirtualInputManager or tool check)
			local tool = char:FindFirstChildOfClass("Tool")
			if tool and tool:FindFirstChild("Ammo") and tool.Ammo.Value <= 2 then
				-- Fires reload action if supported by the game environment
				vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
				task.wait(0.1)
				vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
			end
		end)
	end

	-- 4. Head Aim Assistance (Snaps camera slightly toward nearest enemy head)
	if headAimEnabled then
		pcall(function()
			local closestHead = nil
			local shortestDist = math.huge

			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local enemyChar = p.Character
					local enemyHead = enemyChar:FindFirstChild("Head")
					local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid")

					-- Ensure target is alive and on a different team/valid
					if enemyHead and enemyHumanoid and enemyHumanoid.Health > 0 then
						local dist = (enemyHead.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 100 then -- Within 100 studs range
							shortestDist = dist
							closestHead = enemyHead
						end
					end
				end
			end

			if closestHead then
				-- Smoothly point camera toward the enemy's head
				camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, closestHead.Position), 0.15)
			end
		end)
	end
end)

print("[ShooterScript] Menu loaded successfully!")
