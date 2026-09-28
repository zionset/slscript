-- Services.
local playersService = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")

-- State.
local localPlayer = playersService.LocalPlayer
local currentCamera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

-- Config.
local HUB_NAME = "Zion Hub"
local HUB_VERSION = "1.0.0"
local TOGGLE_KEY = Enum.KeyCode.RightShift

-- Feature flags.
local featureState = {
	autoFarm = false,
	autoQuest = false,
	espEnabled = false,
	espMobs = false,
	espPlayers = false,
	noclip = false,
	antiAfk = false,
	autoSkills = false,
	speedHack = false,
	infiniteJump = false,
}

-- Settings.
local settings = {
	farmRange = 100,
	walkSpeed = 16,
	jumpPower = 50,
	fovRadius = 250,
}

-- Cleanup tracking.
local connections = {}
local espObjects = {}

-- ============================================================================
-- UTILITY
-- ============================================================================

-- Safe tween helper.
local function tweenProperty(object, props, duration)
	local info = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = tweenService:Create(object, info, props)
	tween:Play()
	return tween
end

-- Send notification.
local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title or HUB_NAME,
			Text = text or "",
			Duration = duration or 3,
		})
	end)
end

-- Safe find utility.
local function findFirstDescendant(parent, name)
	for _, child in parent:GetDescendants() do
		if child.Name == name then
			return child
		end
	end
	return nil
end

-- ============================================================================
-- GUI BUILDER
-- ============================================================================

-- Color palette.
local palette = {
	bg = Color3.fromRGB(15, 15, 20),
	surface = Color3.fromRGB(22, 22, 30),
	surface2 = Color3.fromRGB(30, 30, 40),
	border = Color3.fromRGB(45, 45, 60),
	text = Color3.fromRGB(230, 235, 245),
	subtext = Color3.fromRGB(140, 145, 160),
	accent = Color3.fromRGB(100, 140, 255),
	accentHover = Color3.fromRGB(130, 165, 255),
	danger = Color3.fromRGB(255, 90, 90),
	success = Color3.fromRGB(90, 255, 130),
	toggleOn = Color3.fromRGB(90, 255, 130),
	toggleOff = Color3.fromRGB(60, 60, 75),
}

-- Destroy old GUI if re-executing.
pcall(function()
	if coreGui:FindFirstChild("ZionHub") then
		coreGui:FindFirstChild("ZionHub"):Destroy()
	end
end)

-- Screen GUI.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZionHub"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = coreGui end)
if not screenGui.Parent then screenGui.Parent = localPlayer:WaitForChild("PlayerGui") end

-- Main frame.
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 520, 0, 370)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -185)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = palette.border
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Draggable.
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

userInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Title bar.
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = palette.surface
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Fix bottom corners of title bar.
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = palette.surface
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = HUB_NAME .. " v" .. HUB_VERSION .. " | Slayers 2"
titleLabel.TextColor3 = palette.text
titleLabel.TextSize = 15
titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button.
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -37, 0, 5)
closeBtn.BackgroundColor3 = palette.danger
closeBtn.Text = "X"
closeBtn.TextColor3 = palette.text
closeBtn.TextSize = 14
closeBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Minimize button.
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -72, 0, 5)
minBtn.BackgroundColor3 = palette.surface2
minBtn.Text = "_"
minBtn.TextColor3 = palette.text
minBtn.TextSize = 14
minBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local minBtnCorner = Instance.new("UICorner")
minBtnCorner.CornerRadius = UDim.new(0, 6)
minBtnCorner.Parent = minBtn

-- Tab bar.
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0, 120, 1, -40)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = palette.surface
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 2)
tabLayout.Parent = tabBar

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 5)
tabPadding.PaddingLeft = UDim.new(0, 5)
tabPadding.PaddingRight = UDim.new(0, 5)
tabPadding.Parent = tabBar

-- Content area.
local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -125, 1, -45)
contentArea.Position = UDim2.new(0, 122, 0, 42)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame

-- Tab system.
local tabs = {}
local activeTab = nil

local function createTab(name, order)
	-- Tab button.
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = name
	tabBtn.Size = UDim2.new(1, 0, 0, 32)
	tabBtn.BackgroundColor3 = palette.surface2
	tabBtn.BackgroundTransparency = 1
	tabBtn.Text = name
	tabBtn.TextColor3 = palette.subtext
	tabBtn.TextSize = 13
	tabBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	tabBtn.BorderSizePixel = 0
	tabBtn.LayoutOrder = order
	tabBtn.Parent = tabBar

	local tabBtnCorner = Instance.new("UICorner")
	tabBtnCorner.CornerRadius = UDim.new(0, 6)
	tabBtnCorner.Parent = tabBtn

	-- Tab content frame.
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = name
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 3
	contentFrame.ScrollBarImageColor3 = palette.accent
	contentFrame.Visible = false
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentFrame.Parent = contentArea

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.Parent = contentFrame

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingTop = UDim.new(0, 5)
	contentPad.PaddingLeft = UDim.new(0, 5)
	contentPad.PaddingRight = UDim.new(0, 5)
	contentPad.PaddingBottom = UDim.new(0, 5)
	contentPad.Parent = contentFrame

	local tabData = { button = tabBtn, content = contentFrame, order = order }
	tabs[name] = tabData

	tabBtn.MouseButton1Click:Connect(function()
		-- Deactivate all tabs.
		for _, t in tabs do
			t.content.Visible = false
			t.button.BackgroundTransparency = 1
			t.button.TextColor3 = palette.subtext
		end
		-- Activate this tab.
		contentFrame.Visible = true
		tabBtn.BackgroundTransparency = 0
		tabBtn.BackgroundColor3 = palette.accent
		tabBtn.TextColor3 = palette.bg
		activeTab = name
	end)

	return contentFrame
end

-- Toggle widget.
local function createToggle(parent, label, featureKey, order, callback)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, 0, 0, 35)
	toggleFrame.BackgroundColor3 = palette.surface2
	toggleFrame.BorderSizePixel = 0
	toggleFrame.LayoutOrder = order or 0
	toggleFrame.Parent = parent

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleFrame

	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Size = UDim2.new(1, -60, 1, 0)
	toggleLabel.Position = UDim2.new(0, 12, 0, 0)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = label
	toggleLabel.TextColor3 = palette.text
	toggleLabel.TextSize = 13
	toggleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Parent = toggleFrame

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 40, 0, 20)
	toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
	toggleBg.BackgroundColor3 = palette.toggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = toggleFrame

	local toggleBgCorner = Instance.new("UICorner")
	toggleBgCorner.CornerRadius = UDim.new(1, 0)
	toggleBgCorner.Parent = toggleBg

	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 16, 0, 16)
	toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
	toggleCircle.BackgroundColor3 = palette.text
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = toggleCircle

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = toggleFrame

	local function updateVisual()
		local on = featureState[featureKey]
		tweenProperty(toggleBg, { BackgroundColor3 = on and palette.toggleOn or palette.toggleOff }, 0.2)
		tweenProperty(toggleCircle, { Position = on and UDim2.new(0, 22, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.2)
	end

	toggleBtn.MouseButton1Click:Connect(function()
		featureState[featureKey] = not featureState[featureKey]
		updateVisual()
		if callback then callback(featureState[featureKey]) end
	end)

	updateVisual()
	return toggleFrame
end

-- Slider widget.
local function createSlider(parent, label, settingKey, min, max, order, callback)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(1, 0, 0, 50)
	sliderFrame.BackgroundColor3 = palette.surface2
	sliderFrame.BorderSizePixel = 0
	sliderFrame.LayoutOrder = order or 0
	sliderFrame.Parent = parent

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 6)
	sliderCorner.Parent = sliderFrame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -24, 0, 20)
	valueLabel.Position = UDim2.new(0, 12, 0, 3)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = label .. ": " .. tostring(settings[settingKey])
	valueLabel.TextColor3 = palette.text
	valueLabel.TextSize = 12
	valueLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = sliderFrame

	local trackFrame = Instance.new("Frame")
	trackFrame.Size = UDim2.new(1, -24, 0, 6)
	trackFrame.Position = UDim2.new(0, 12, 0, 30)
	trackFrame.BackgroundColor3 = palette.toggleOff
	trackFrame.BorderSizePixel = 0
	trackFrame.Parent = sliderFrame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = trackFrame

	local fillFrame = Instance.new("Frame")
	fillFrame.Size = UDim2.new((settings[settingKey] - min) / (max - min), 0, 1, 0)
	fillFrame.BackgroundColor3 = palette.accent
	fillFrame.BorderSizePixel = 0
	fillFrame.Parent = trackFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fillFrame

	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Size = UDim2.new(1, 0, 1, 0)
	sliderBtn.BackgroundTransparency = 1
	sliderBtn.Text = ""
	sliderBtn.Parent = trackFrame

	local sliding = false

	local function update(input)
		local relX = math.clamp((input.Position.X - trackFrame.AbsolutePosition.X) / trackFrame.AbsoluteSize.X, 0, 1)
		local value = math.floor(min + (max - min) * relX)
		settings[settingKey] = value
		fillFrame.Size = UDim2.new(relX, 0, 1, 0)
		valueLabel.Text = label .. ": " .. tostring(value)
		if callback then callback(value) end
	end

	sliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			update(input)
		end
	end)

	sliderBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end)

	return sliderFrame
end

-- Button widget.
local function createButton(parent, label, order, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = palette.accent
	btn.Text = label
	btn.TextColor3 = palette.bg
	btn.TextSize = 13
	btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order or 0
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)

	return btn
end

-- Section label.
local function createSection(parent, text, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = palette.accent
	label.TextSize = 12
	label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order or 0
	label.Parent = parent
	return label
end

-- ============================================================================
-- TABS
-- ============================================================================

local farmTab = createTab("Farm", 1)
local combatTab = createTab("Combat", 2)
local teleportTab = createTab("Teleport", 3)
local playerTab = createTab("Player", 4)
local espTab = createTab("ESP", 5)
local settingsTab = createTab("Settings", 6)

-- Activate first tab.
tabs["Farm"].button.BackgroundTransparency = 0
tabs["Farm"].button.BackgroundColor3 = palette.accent
tabs["Farm"].button.TextColor3 = palette.bg
tabs["Farm"].content.Visible = true
activeTab = "Farm"

-- ============================================================================
-- FARM TAB
-- ============================================================================

createSection(farmTab, "AUTO FARM", 1)
createToggle(farmTab, "Auto Farm Mobs", "autoFarm", 2)
createToggle(farmTab, "Auto Quest", "autoQuest", 3)
createSlider(farmTab, "Farm Range", "farmRange", 10, 300, 4)

-- ============================================================================
-- COMBAT TAB
-- ============================================================================

createSection(combatTab, "COMBAT", 1)
createToggle(combatTab, "Auto Skills", "autoSkills", 2)

-- ============================================================================
-- TELEPORT TAB
-- ============================================================================

createSection(teleportTab, "LOCATIONS", 1)

-- Teleport helper.
local function teleportTo(cframe)
	local character = localPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = cframe
	notify(HUB_NAME, "Teleported!", 2)
end

createButton(teleportTab, "Safe Zone", 2, function()
	-- Placeholder coordinates, update for actual game.
	teleportTo(CFrame.new(0, 50, 0))
end)

createButton(teleportTab, "Shop", 3, function()
	teleportTo(CFrame.new(100, 50, 100))
end)

createButton(teleportTab, "Boss Area", 4, function()
	teleportTo(CFrame.new(-200, 50, 300))
end)

createButton(teleportTab, "Training Area", 5, function()
	teleportTo(CFrame.new(500, 50, -100))
end)

-- ============================================================================
-- PLAYER TAB
-- ============================================================================

createSection(playerTab, "MOVEMENT", 1)

createToggle(playerTab, "Speed Hack", "speedHack", 2, function(enabled)
	local character = localPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = enabled and settings.walkSpeed or 16
	end
end)

createSlider(playerTab, "Walk Speed", "walkSpeed", 16, 200, 3, function(value)
	if featureState.speedHack then
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = value
			end
		end
	end
end)

createToggle(playerTab, "Infinite Jump", "infiniteJump", 4)

createToggle(playerTab, "Noclip", "noclip", 5)

createSlider(playerTab, "Jump Power", "jumpPower", 50, 300, 6, function(value)
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = value
		end
	end
end)

-- ============================================================================
-- ESP TAB
-- ============================================================================

createSection(espTab, "VISUALS", 1)
createToggle(espTab, "ESP Enabled", "espEnabled", 2)
createToggle(espTab, "Show Mobs", "espMobs", 3)
createToggle(espTab, "Show Players", "espPlayers", 4)

-- ============================================================================
-- SETTINGS TAB
-- ============================================================================

createSection(settingsTab, "GENERAL", 1)
createToggle(settingsTab, "Anti-AFK", "antiAfk", 2)

createButton(settingsTab, "Destroy GUI", 3, function()
	-- Cleanup.
	for _, conn in connections do
		pcall(function() conn:Disconnect() end)
	end
	for _, obj in espObjects do
		pcall(function() obj:Destroy() end)
	end
	screenGui:Destroy()
end)

createSection(settingsTab, "INFO", 4)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundColor3 = palette.surface2
infoLabel.Text = "  " .. HUB_NAME .. " v" .. HUB_VERSION .. "\n  Toggle GUI: RightShift\n  Made by Zion"
infoLabel.TextColor3 = palette.subtext
infoLabel.TextSize = 11
infoLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.LayoutOrder = 5
infoLabel.Parent = settingsTab

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = infoLabel

-- ============================================================================
-- FEATURE LOGIC
-- ============================================================================

-- Toggle GUI visibility.
table.insert(connections, userInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == TOGGLE_KEY then
		mainFrame.Visible = not mainFrame.Visible
	end
end))

-- Minimize.
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	contentArea.Visible = not minimized
	tabBar.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 220, 0, 40) or UDim2.new(0, 520, 0, 370)
end)

-- Noclip loop.
table.insert(connections, runService.Stepped:Connect(function()
	if featureState.noclip then
		local character = localPlayer.Character
		if character then
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end
end))

-- Infinite jump.
table.insert(connections, userInputService.JumpRequest:Connect(function()
	if featureState.infiniteJump then
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
end))

-- Speed hack reapply on respawn.
localPlayer.CharacterAdded:Connect(function(character)
	task.wait(1)
	if featureState.speedHack then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = settings.walkSpeed
		end
	end
end)

-- Anti-AFK.
pcall(function()
	if featureState.antiAfk or true then
		local virtualUser = game:GetService("VirtualUser")
		table.insert(connections, localPlayer.Idled:Connect(function()
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new())
		end))
	end
end)

-- ESP system.
local function createESPHighlight(target, color, label)
	if not target or not target.Parent then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ZionESP"
	highlight.FillColor = color
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.3
	highlight.Adornee = target
	highlight.Parent = target
	table.insert(espObjects, highlight)

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ZionESPLabel"
	billboardGui.Size = UDim2.new(0, 100, 0, 30)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = target
	billboardGui.Parent = target
	table.insert(espObjects, billboardGui)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label or target.Name
	nameLabel.TextColor3 = color
	nameLabel.TextSize = 12
	nameLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboardGui

	return highlight, billboardGui
end

local function clearESP()
	for _, obj in espObjects do
		pcall(function() obj:Destroy() end)
	end
	espObjects = {}
end

local function refreshESP()
	clearESP()

	if not featureState.espEnabled then return end

	-- Player ESP.
	if featureState.espPlayers then
		for _, player in playersService:GetPlayers() do
			if player ~= localPlayer and player.Character then
				createESPHighlight(player.Character, palette.accent, player.Name)
			end
		end
	end

	-- Mob ESP.
	if featureState.espMobs then
		-- Search common mob folders.
		local mobFolders = {
			workspace:FindFirstChild("Mobs"),
			workspace:FindFirstChild("NPCs"),
			workspace:FindFirstChild("Enemies"),
			workspace:FindFirstChild("Living"),
		}
		for _, folder in mobFolders do
			if folder then
				for _, mob in folder:GetChildren() do
					if mob:FindFirstChild("Humanoid") or mob:FindFirstChild("HumanoidRootPart") then
						local humanoid = mob:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							createESPHighlight(mob, palette.danger, mob.Name)
						end
					end
				end
			end
		end
	end
end

-- ESP refresh loop.
task.spawn(function()
	while task.wait(3) do
		if screenGui.Parent then
			refreshESP()
		else
			break
		end
	end
end)

-- Auto Farm loop.
task.spawn(function()
	while task.wait(0.5) do
		if not screenGui.Parent then break end
		if not featureState.autoFarm then continue end

		local character = localPlayer.Character
		if not character then continue end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		-- Find closest mob.
		local closestMob = nil
		local closestDist = settings.farmRange

		local mobFolders = {
			workspace:FindFirstChild("Mobs"),
			workspace:FindFirstChild("NPCs"),
			workspace:FindFirstChild("Enemies"),
			workspace:FindFirstChild("Living"),
		}

		for _, folder in mobFolders do
			if folder then
				for _, mob in folder:GetChildren() do
					local mobHrp = mob:FindFirstChild("HumanoidRootPart")
					local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
					if mobHrp and mobHumanoid and mobHumanoid.Health > 0 then
						local dist = (hrp.Position - mobHrp.Position).Magnitude
						if dist < closestDist then
							closestDist = dist
							closestMob = mob
						end
					end
				end
			end
		end

		-- Move to mob.
		if closestMob then
			local mobHrp = closestMob:FindFirstChild("HumanoidRootPart")
			if mobHrp then
				hrp.CFrame = mobHrp.CFrame * CFrame.new(0, 0, 3)
			end
		end
	end
end)

-- ============================================================================
-- INIT
-- ============================================================================

notify(HUB_NAME, "Loaded! Press RightShift to toggle.", 5)
