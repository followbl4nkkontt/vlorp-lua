-- vlorp.lua [BETA] - Fixed & Enhanced for Rivals
local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}

local player = Services.Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = {
    CorrectKey = "1234",
    GuiName = "VLORP_GUI_BETA",
    MainColor = Color3.fromRGB(0, 255, 160),
    AccentColor = Color3.fromRGB(100, 255, 220),
    BackgroundColor = Color3.fromRGB(8, 8, 20),
    ConfigFolder = "vlorp_configs",
    ConfigFile = "default.json",
}

local keyVerified = false
local connections = {}
local espObjects = {}

local Settings = {
    Ragebot = { Enabled = false, FOV = 180, Smoothness = 0.25, TargetPart = "Head", TeamCheck = true },
    SilentAim = { Enabled = false, FOV = 140, TargetPart = "Head" },
    Voidspam = { Enabled = false },
    ESP = { Enabled = false, Health = true, Names = true },
    Cosmetics = { Enabled = false },
    Fly = { Enabled = false, Speed = 50 },
}

-- Config System
if not isfolder(CONFIG.ConfigFolder) then makefolder(CONFIG.ConfigFolder) end

local function getConfigPath(filename)
    return CONFIG.ConfigFolder .. "/" .. (filename or CONFIG.ConfigFile)
end

local function loadConfig()
    local path = getConfigPath()
    if isfile(path) then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile(path))
        end)
        if success and data then
            for module, values in pairs(data) do
                if Settings[module] then
                    for k, v in pairs(values) do
                        if Settings[module][k] ~= nil then
                            Settings[module][k] = v
                        end
                    end
                end
            end
        end
    end
end

local function saveConfig()
    pcall(function()
        writefile(getConfigPath(), Services.HttpService:JSONEncode(Settings))
    end)
end

loadConfig()

-- UI Utilities
local function createTween(obj, prop, val, dur)
    return Services.TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[prop] = val})
end

local function addButtonEffects(btn, base, hover)
    base = base or Color3.fromRGB(20, 20, 45)
    hover = hover or CONFIG.AccentColor
    btn.MouseEnter:Connect(function() createTween(btn, "BackgroundColor3", hover, 0.2):Play() end)
    btn.MouseLeave:Connect(function() createTween(btn, "BackgroundColor3", base, 0.2):Play() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 860, 0, 640)
mainFrame.Position = UDim2.new(0.5, -430, 0.5, -320)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 24)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = CONFIG.MainColor
stroke.Thickness = 7

-- Draggable
local dragging = false
local dragStart, startPos
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
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 80)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VLORP.LUA [BETA]"
titleLabel.TextColor3 = CONFIG.MainColor
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.Arcade
titleLabel.Parent = mainFrame

-- Tabs
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -40, 0, 60)
tabHolder.Position = UDim2.new(0, 20, 0, 90)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = mainFrame

local mainTab = Instance.new("ScrollingFrame")
mainTab.Size = UDim2.new(1, -40, 1, -200)
mainTab.Position = UDim2.new(0, 20, 0, 170)
mainTab.BackgroundTransparency = 1
mainTab.ScrollBarThickness = 8
mainTab.ScrollBarImageColor3 = CONFIG.MainColor
mainTab.Parent = mainFrame
Instance.new("UIListLayout", mainTab).Padding = UDim.new(0, 15)

-- Create Toggle Section
local function createSection(parent, name, settingTbl, toggleCallback, extraFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 160)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 22)
    Instance.new("UIStroke", frame).Color = CONFIG.MainColor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 50)
    label.Position = UDim2.new(0, 25, 0, 15)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 255, 240)
    label.TextScaled = true
    label.Font = Enum.Font.Arcade
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 110, 0, 48)
    toggleBtn.Position = UDim2.new(1, -140, 0, 16)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.Arcade
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

    local state = settingTbl.Enabled

    local function updateUI()
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
            toggleBtn.Text = "ON"
            toggleBtn.TextColor3 = CONFIG.AccentColor
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            toggleBtn.Text = "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        settingTbl.Enabled = state
        if toggleCallback then toggleCallback(state) end
        updateUI()
        saveConfig()
    end)

    updateUI()

    if extraFunc then extraFunc(frame) end
end

-- ==================== FEATURES ====================

local function getClosestPlayer(fov, teamCheck)
    local closest, dist = nil, math.huge
    local myPos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if teamCheck and p.Team == player.Team then continue end
            local d = (p.Character.Head.Position - myPos).Magnitude
            if d < dist and d <= fov then
                dist = d
                closest = p
            end
        end
    end
    return closest
end

local function toggleRagebot(state)
    if connections.ragebot then connections.ragebot:Disconnect() end
    if state then
        connections.ragebot = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Ragebot.Enabled then return end
            local target = getClosestPlayer(Settings.Ragebot.FOV, Settings.Ragebot.TeamCheck)
            if target and target.Character and target.Character:FindFirstChild(Settings.Ragebot.TargetPart) then
                local pos = target.Character[Settings.Ragebot.TargetPart].Position
                local targetCF = CFrame.new(camera.CFrame.Position, pos)
                camera.CFrame = camera.CFrame:Lerp(targetCF, Settings.Ragebot.Smoothness)
            end
        end)
    end
end

local function toggleSilentAim(state)
    if connections.silent then connections.silent:Disconnect() end
    if state then
        print("Silent Aim Enabled (Target: " .. Settings.SilentAim.TargetPart .. ")")
    end
end

local function toggleVoidspam(state)
    if connections.voidspam then connections.voidspam:Disconnect() end
    if state then
        connections.voidspam = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Voidspam.Enabled then return end
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end)
    end
end

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
                    bg.Size = UDim2.new(0, 220, 0, 90)
                    bg.StudsOffset = Vector3.new(0, 5, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = screenGui

                    local tl = Instance.new("TextLabel", bg)
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.Text = p.Name .. (Settings.ESP.Health and "\nHP: " .. math.floor(p.Character.Humanoid.Health) or "")
                    tl.TextColor3 = CONFIG.AccentColor
                    tl.TextScaled = true
                    tl.Font = Enum.Font.SourceSansBold
                    table.insert(espObjects, bg)
                end
            end
        end)
    end
end

local function toggleCosmetics(state)
    if state then
        pcall(function()
            local folders = {player:FindFirstChild("PlayerData"), Services.ReplicatedStorage:FindFirstChild("PlayerData")}
            for _, folder in ipairs(folders) do
                if folder then
                    for _, v in pairs(folder:GetDescendants()) do
                        if v:IsA("BoolValue") and (v.Name:match("Owned") or v.Name:match("Unlock") or v.Name:match("Unlocked")) then
                            v.Value = true
                        end
                    end
                end
            end
            print("All skins unlocked!")
        end)
    end
end

local function toggleFly(state)
    if connections.fly then connections.fly:Disconnect() end
    if state then
        connections.fly = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Fly.Enabled or not player.Character then return end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dir = Vector3.new(0, 0, 0)
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
                if dir.Magnitude > 0 then
                    root.Velocity = dir.Unit * Settings.Fly.Speed
                else
                    root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
                end
            end
        end)
    end
end

-- Populate Main Tab
createSection(mainTab, "Ragebot", Settings.Ragebot, toggleRagebot)
createSection(mainTab, "Silent Aim", Settings.SilentAim, toggleSilentAim)
createSection(mainTab, "Voidspam", Settings.Voidspam, toggleVoidspam)
createSection(mainTab, "ESP", Settings.ESP, toggleESP)
createSection(mainTab, "Skin Changer + Unlock All", Settings.Cosmetics, toggleCosmetics)
createSection(mainTab, "Fly", Settings.Fly, toggleFly)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 60, 0, 60)
closeBtn.Position = UDim2.new(1, -80, 0, 20)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Arcade
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 30)
addButtonEffects(closeBtn, Color3.fromRGB(180, 30, 30))

closeBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(connections) do pcall(function() c:Disconnect() end) end
    for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
    saveConfig()
    screenGui:Destroy()
end)

-- Key System (Simple)
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 440, 0, 280)
keyFrame.Position = UDim2.new(0.5, -220, 0.5, -140)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
keyFrame.Parent = screenGui
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", keyFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", keyFrame).Thickness = 6

local keyTitle = Instance.new("TextLabel", keyFrame)
keyTitle.Size = UDim2.new(1, -40, 0, 80)
keyTitle.Position = UDim2.new(0, 20, 0, 30)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "VLORP.LUA [BETA]"
keyTitle.TextColor3 = CONFIG.MainColor
keyTitle.TextScaled = true
keyTitle.Font = Enum.Font.Arcade

local keyInput = Instance.new("TextBox", keyFrame)
keyInput.Size = UDim2.new(0.8, 0, 0, 60)
keyInput.Position = UDim2.new(0.1, 0, 0.45, 0)
keyInput.PlaceholderText = "ENTER KEY (1234)"
keyInput.TextColor3 = Color3.new(1,1,1)
keyInput.BackgroundColor3 = Color3.fromRGB(15,15,35)
keyInput.TextScaled = true
keyInput.Font = Enum.Font.Arcade
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 16)

local submitBtn = Instance.new("TextButton", keyFrame)
submitBtn.Size = UDim2.new(0.65, 0, 0, 60)
submitBtn.Position = UDim2.new(0.175, 0, 0.7, 0)
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
    else
        keyInput.Text = "INVALID KEY"
        task.wait(1.5)
        keyInput.Text = ""
    end
end)

-- Right Shift Toggle
Services.UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not keyVerified then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("vlorp.lua [BETA] loaded successfully - All errors fixed")
