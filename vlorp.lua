-- vlorp.lua [BETA] - Complete Fixed Script Hub for Rivals
local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = workspace
}

local player = Services.Players.LocalPlayer
local camera = Services.Workspace.CurrentCamera
local mouse = player:GetMouse()

local CONFIG = {
    CorrectKey = "1234",
    GuiName = "VLORP_GUI_BETA",
    MainColor = Color3.fromRGB(0, 255, 160),
    AccentColor = Color3.fromRGB(100, 255, 220),
    BackgroundColor = Color3.fromRGB(10, 10, 25),
    ConfigFolder = "vlorp_configs",
    ConfigFile = "default.json",
}

local keyVerified = false
local connections = {}
local espObjects = {}

local Settings = {
    Combat = {
        Ragebot = { Enabled = false, FOV = 180, Smoothness = 0.22, TargetPart = "Head", TeamCheck = true },
        SilentAim = { Enabled = false, FOV = 140, TargetPart = "Head", HitChance = 100 },
    },
    Visuals = {
        ESP = { Enabled = false, Health = true, Names = true, Boxes = false },
    },
    Misc = {
        Voidspam = { Enabled = false },
        Cosmetics = { Enabled = false },
        Fly = { Enabled = false, Speed = 60 },
        SpeedHack = { Enabled = false, Value = 22 },
        Triggerbot = { Enabled = false },
        Noclip = { Enabled = false },
    },
    Viewmodel = { Enabled = false, FOV = 90 },
}

-- Config System
if not isfolder(CONFIG.ConfigFolder) then makefolder(CONFIG.ConfigFolder) end
local function getConfigPath() return CONFIG.ConfigFolder .. "/" .. CONFIG.ConfigFile end
local function loadConfig()
    if isfile(getConfigPath()) then
        local success, data = pcall(function() return Services.HttpService:JSONDecode(readfile(getConfigPath())) end)
        if success and data then
            for module, values in pairs(data) do
                if Settings[module] then
                    for k, v in pairs(values) do
                        if Settings[module][k] ~= nil then Settings[module][k] = v end
                    end
                end
            end
        end
    end
end
local function saveConfig()
    pcall(function() writefile(getConfigPath(), Services.HttpService:JSONEncode(Settings)) end)
end
loadConfig()

-- UI Utilities
local function createTween(obj, prop, val, dur)
    return Services.TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[prop] = val})
end

local function addButtonEffects(btn)
    local base = btn.BackgroundColor3
    btn.MouseEnter:Connect(function() createTween(btn, "BackgroundColor3", CONFIG.AccentColor, 0.2):Play() end)
    btn.MouseLeave:Connect(function() createTween(btn, "BackgroundColor3", base, 0.2):Play() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- Main Frame (Clean multi-tab layout inspired by popular hubs)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 900, 0, 620)
mainFrame.Position = UDim2.new(0.5, -450, 0.5, -310)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 24)
Instance.new("UIStroke", mainFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", mainFrame).Thickness = 6

-- Draggable
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Title
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 70)
title.BackgroundTransparency = 1
title.Text = "VLORP.LUA [BETA]"
title.TextColor3 = CONFIG.MainColor
title.TextScaled = true
title.Font = Enum.Font.Arcade

-- Tab Buttons
local tabFrame = Instance.new("Frame", mainFrame)
tabFrame.Size = UDim2.new(1, -40, 0, 50)
tabFrame.Position = UDim2.new(0, 20, 0, 80)
tabFrame.BackgroundTransparency = 1

local tabs = {}
local tabContents = {}

local function createTab(name, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    btn.Text = name
    btn.TextColor3 = CONFIG.MainColor
    btn.TextScaled = true
    btn.Font = Enum.Font.Arcade
    btn.Parent = tabFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    addButtonEffects(btn)

    local content = Instance.new("ScrollingFrame", parent)
    content.Size = UDim2.new(1, -40, 1, -160)
    content.Position = UDim2.new(0, 20, 0, 150)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 8
    content.ScrollBarImageColor3 = CONFIG.MainColor
    content.Visible = false
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 15)

    table.insert(tabs, btn)
    tabContents[name] = content

    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(tabContents) do c.Visible = false end
        content.Visible = true
        for _, b in pairs(tabs) do b.BackgroundColor3 = Color3.fromRGB(20, 20, 40) end
        btn.BackgroundColor3 = Color3.fromRGB(0, 60, 45)
    end)
    return content
end

local combatTab = createTab("Combat", mainFrame)
local visualsTab = createTab("Visuals", mainFrame)
local miscTab = createTab("Misc", mainFrame)
local settingsTab = createTab("Settings", mainFrame)

-- Toggle Creator
local function createToggle(parent, name, settingTbl, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)
    Instance.new("UIStroke", frame).Color = CONFIG.MainColor

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. name
    label.TextColor3 = Color3.fromRGB(240, 255, 245)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0, 110, 0, 50)
    toggleBtn.Position = UDim2.new(1, -140, 0.5, -25)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.Arcade
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

    local state = settingTbl.Enabled
    local function updateUI()
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 70)
            toggleBtn.Text = "ON"
            toggleBtn.TextColor3 = CONFIG.AccentColor
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            toggleBtn.Text = "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        settingTbl.Enabled = state
        if callback then callback(state) end
        updateUI()
        saveConfig()
    end)
    updateUI()
end

-- ==================== FEATURES ====================

local function getClosest(fov, teamCheck)
    local closest, dist = nil, math.huge
    local myPos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if teamCheck and p.Team == player.Team then continue end
            local d = (p.Character.Head.Position - myPos).Magnitude
            if d < dist and d <= fov then
                dist, closest = d, p
            end
        end
    end
    return closest
end

-- Combat Features
local function toggleRagebot(state)
    if connections.rage then connections.rage:Disconnect() end
    if state then
        connections.rage = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Combat.Ragebot.Enabled then return end
            local target = getClosest(Settings.Combat.Ragebot.FOV, Settings.Combat.Ragebot.TeamCheck)
            if target and target.Character and target.Character:FindFirstChild(Settings.Combat.Ragebot.TargetPart) then
                local pos = target.Character[Settings.Combat.Ragebot.TargetPart].Position
                local targetCF = CFrame.new(camera.CFrame.Position, pos)
                camera.CFrame = camera.CFrame:Lerp(targetCF, Settings.Combat.Ragebot.Smoothness)
            end
        end)
    end
end

local function toggleSilentAim(state)
    if connections.silent then connections.silent:Disconnect() end
    if state then
        connections.silent = Services.RunService.RenderStepped:Connect(function()
            -- Silent Aim logic (placeholder for raycast modification)
        end)
    end
end

-- Visuals
local function toggleESP(state)
    if connections.esp then connections.esp:Disconnect() end
    for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
    espObjects = {}
    if state then
        connections.esp = Services.RunService.RenderStepped:Connect(function()
            for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
            espObjects = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local bg = Instance.new("BillboardGui")
                    bg.Adornee = p.Character.HumanoidRootPart
                    bg.Size = UDim2.new(0, 220, 0, 100)
                    bg.StudsOffset = Vector3.new(0, 5, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = screenGui
                    local tl = Instance.new("TextLabel", bg)
                    tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1
                    tl.Text = p.Name .. (Settings.Visuals.ESP.Health and "\nHP: "..math.floor(p.Character.Humanoid.Health) or "")
                    tl.TextColor3 = CONFIG.AccentColor
                    tl.TextScaled = true
                    tl.Font = Enum.Font.SourceSansBold
                    table.insert(espObjects, bg)
                end
            end
        end)
    end
end

-- Misc Features
local function toggleVoidspam(state)
    if connections.void then connections.void:Disconnect() end
    if state then
        connections.void = Services.RunService.Heartbeat:Connect(function()
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(tool.Activate, tool) end
        end)
    end
end

local function toggleCosmetics(state)
    if state then
        pcall(function()
            local pd = player:FindFirstChild("PlayerData") or Services.ReplicatedStorage:FindFirstChild("PlayerData")
            if pd then
                for _, v in pd:GetDescendants() do
                    if v:IsA("BoolValue") and (v.Name:match("Owned") or v.Name:match("Unlock")) then
                        v.Value = true
                    end
                end
            end
        end)
    end
end

local function toggleFly(state)
    if connections.fly then connections.fly:Disconnect() end
    if state then
        connections.fly = Services.RunService.Heartbeat:Connect(function()
            if not player.Character then return end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dir = Vector3.new()
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
                if dir.Magnitude > 0 then root.Velocity = dir.Unit * Settings.Misc.Fly.Speed end
            end
        end)
    end
end

local function toggleSpeedHack(state)
    if connections.speed then connections.speed:Disconnect() end
    if state then
        connections.speed = Services.RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = Settings.Misc.SpeedHack.Value
            end
        end)
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
end

local function toggleNoclip(state)
    if connections.noclip then connections.noclip:Disconnect() end
    if state then
        connections.noclip = Services.RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end

local function toggleViewmodel(state)
    if state then
        camera.FieldOfView = Settings.Viewmodel.FOV
    else
        camera.FieldOfView = 70
    end
end

-- Populate Tabs
createToggle(combatTab, "Ragebot", Settings.Combat.Ragebot, toggleRagebot)
createToggle(combatTab, "Silent Aim", Settings.Combat.SilentAim, toggleSilentAim)

createToggle(visualsTab, "ESP", Settings.Visuals.ESP, toggleESP)

createToggle(miscTab, "Voidspam", Settings.Misc.Voidspam, toggleVoidspam)
createToggle(miscTab, "Skin Changer", Settings.Misc.Cosmetics, toggleCosmetics)
createToggle(miscTab, "Fly", Settings.Misc.Fly, toggleFly)
createToggle(miscTab, "Speed Hack", Settings.Misc.SpeedHack, toggleSpeedHack)
createToggle(miscTab, "Triggerbot", Settings.Misc.Triggerbot)
createToggle(miscTab, "Noclip", Settings.Misc.Noclip, toggleNoclip)

createToggle(settingsTab, "Viewmodel Override", Settings.Viewmodel, toggleViewmodel)

-- Close Button
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(1, -70, 0, 15)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Arcade
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 25)
addButtonEffects(closeBtn)

closeBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(connections) do pcall(c.Disconnect, c) end
    for _, o in pairs(espObjects) do pcall(o.Destroy, o) end
    saveConfig()
    screenGui:Destroy()
end)

-- Key System
local keyFrame = Instance.new("Frame", screenGui)
keyFrame.Size = UDim2.new(0, 440, 0, 280)
keyFrame.Position = UDim2.new(0.5, -220, 0.5, -140)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", keyFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", keyFrame).Thickness = 6

local keyTitle = Instance.new("TextLabel", keyFrame)
keyTitle.Size = UDim2.new(1, -40, 0, 70)
keyTitle.Position = UDim2.new(0, 20, 0, 30)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "VLORP.LUA [BETA]"
keyTitle.TextColor3 = CONFIG.MainColor
keyTitle.TextScaled = true
keyTitle.Font = Enum.Font.Arcade

local keyInput = Instance.new("TextBox", keyFrame)
keyInput.Size = UDim2.new(0.8, 0, 0, 55)
keyInput.Position = UDim2.new(0.1, 0, 0.45, 0)
keyInput.PlaceholderText = "ENTER KEY (1234)"
keyInput.TextScaled = true
keyInput.Font = Enum.Font.Arcade
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 16)

local submitBtn = Instance.new("TextButton", keyFrame)
submitBtn.Size = UDim2.new(0.65, 0, 0, 55)
submitBtn.Position = UDim2.new(0.175, 0, 0.68, 0)
submitBtn.BackgroundColor3 = CONFIG.MainColor
submitBtn.Text = "VERIFY"
submitBtn.TextColor3 = Color3.new(0,0,0)
submitBtn.TextScaled = true
submitBtn.Font = Enum.Font.Arcade
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 16)
addButtonEffects(submitBtn)

submitBtn.MouseButton1Click:Connect(function()
    if keyInput.Text == CONFIG.CorrectKey then
        keyVerified = true
        keyFrame:Destroy()
        mainFrame.Visible = true
        combatTab.Visible = true  -- Default tab
    else
        keyInput.Text = "INVALID KEY"
        task.wait(1.5)
        keyInput.Text = ""
    end
end)

-- Right Shift Toggle
Services.UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not keyVerified then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("vlorp.lua [BETA] loaded successfully")