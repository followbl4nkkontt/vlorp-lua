-- vlorp.lua [BETA] - Professional Alien-Themed Roblox Script Hub for Rivals
-- Optimized for Potassium Executor | Full Skin Changer + Updated 2026

local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Lighting = game:GetService("Lighting")
}

local player = Services.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local CONFIG = {
    CorrectKey = "1234",
    GuiName = "VLORP_GUI_BETA",
    MainColor = Color3.fromRGB(0, 255, 160),
    AccentColor = Color3.fromRGB(100, 255, 220),
    BackgroundColor = Color3.fromRGB(5, 5, 15),
    ConfigFile = "vlorp_beta_config.json",
}

local keyVerified = false
local connections = {}
local espObjects = {}

-- Expanded & Fixed Settings
local Settings = {
    Ragebot = {
        Enabled = false,
        TargetPart = "Head",
        FOV = 180,
        Smoothness = 0.28,
        TeamCheck = true,
        AntiAim = false,
        AntiAimAngle = 180,
    },
    Voidspam = {
        Enabled = false,
        Speed = 0.08,
    },
    ESP = {
        Enabled = false,
        Skeleton = true,
        Health = true,
        Boxes = true,
        Names = true,
    },
    Cosmetics = {
        Enabled = false,
        UnlockAll = true,
    },
    SilentAim = {
        Enabled = false,
        FOV = 140,
    },
}

-- Load / Save Config
local function loadConfig()
    if isfile(CONFIG.ConfigFile) then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile(CONFIG.ConfigFile))
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
            print("✅ VLORP [BETA]: Config loaded successfully")
        end
    end
end

local function saveConfig()
    pcall(function()
        writefile(CONFIG.ConfigFile, Services.HttpService:JSONEncode(Settings))
    end)
    print("💾 VLORP [BETA]: Config saved")
end

loadConfig()

-- UI Utilities
local function createTween(obj, prop, val, dur)
    local tweenInfo = TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    return Services.TweenService:Create(obj, tweenInfo, {[prop] = val})
end

local function fadeElement(element, target, duration)
    duration = duration or 0.35
    if element:IsA("GuiObject") then createTween(element, "BackgroundTransparency", target, duration):Play() end
    if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        createTween(element, "TextTransparency", target, duration):Play()
    end
    local stroke = element:FindFirstChildOfClass("UIStroke")
    if stroke then createTween(stroke, "Transparency", target, duration):Play() end
end

local function addButtonEffects(button, baseColor, hoverColor)
    baseColor = baseColor or CONFIG.MainColor
    hoverColor = hoverColor or CONFIG.AccentColor
    button.MouseEnter:Connect(function()
        createTween(button, "BackgroundColor3", hoverColor, 0.15):Play()
    end)
    button.MouseLeave:Connect(function()
        createTween(button, "BackgroundColor3", baseColor, 0.15):Play()
    end)
end

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- ==================== KEY SYSTEM (Shown First) ====================
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 420, 0, 260)
keyFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
keyFrame.Visible = true
keyFrame.Parent = screenGui

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 24)
keyCorner.Parent = keyFrame

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = CONFIG.MainColor
keyStroke.Thickness = 5
keyStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -40, 0, 70)
keyTitle.Position = UDim2.new(0, 20, 0, 25)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "VLORP.LUA [BETA]"
keyTitle.TextColor3 = CONFIG.MainColor
keyTitle.TextScaled = true
keyTitle.Font = Enum.Font.Arcade
keyTitle.Parent = keyFrame

local keySubtitle = Instance.new("TextLabel")
keySubtitle.Size = UDim2.new(1, -40, 0, 30)
keySubtitle.Position = UDim2.new(0, 20, 0, 85)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "RIVALS • ALIEN PROTOCOL"
keySubtitle.TextColor3 = CONFIG.AccentColor
keySubtitle.TextScaled = true
keySubtitle.Font = Enum.Font.SourceSansItalic
keySubtitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0.82, 0, 0, 58)
keyInput.Position = UDim2.new(0.09, 0, 0.48, 0)
keyInput.PlaceholderText = "ENTER KEY (1234)"
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
keyInput.TextScaled = true
keyInput.Font = Enum.Font.Arcade
keyInput.Parent = keyFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 16)
inputCorner.Parent = keyInput

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0.65, 0, 0, 58)
submitButton.Position = UDim2.new(0.175, 0, 0.72, 0)
submitButton.BackgroundColor3 = CONFIG.MainColor
submitButton.Text = "VERIFY ACCESS"
submitButton.TextColor3 = Color3.new(0, 0, 0)
submitButton.TextScaled = true
submitButton.Font = Enum.Font.Arcade
submitButton.Parent = keyFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 16)
submitCorner.Parent = submitButton

addButtonEffects(submitButton)

-- ==================== MAIN GUI ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 780, 0, 580)
mainFrame.Position = UDim2.new(0.5, -390, 0.5, -290)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 24)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = CONFIG.MainColor
mainStroke.Thickness = 5
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 85)
title.BackgroundTransparency = 1
title.Text = "VLORP.LUA [BETA]"
title.TextColor3 = CONFIG.MainColor
title.TextScaled = true
title.Font = Enum.Font.Arcade
title.Parent = mainFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{COLOR3.new(1,1,1), CONFIG.AccentColor}
titleGradient.Parent = title

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = CONFIG.AccentColor
titleStroke.Thickness = 3.5
titleStroke.Parent = title

-- Tab System (Fixed & Beautiful)
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -40, 0, 60)
tabHolder.Position = UDim2.new(0, 20, 0, 90)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = mainFrame

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 12)
tabList.Parent = tabHolder

local mainTab = Instance.new("ScrollingFrame")
mainTab.Size = UDim2.new(1, -40, 1, -190)
mainTab.Position = UDim2.new(0, 20, 0, 165)
mainTab.BackgroundTransparency = 1
mainTab.ScrollBarThickness = 8
mainTab.ScrollBarImageColor3 = CONFIG.MainColor
mainTab.Visible = true
mainTab.Parent = mainFrame

local settingsTab = Instance.new("ScrollingFrame")
settingsTab.Size = UDim2.new(1, -40, 1, -190)
settingsTab.Position = UDim2.new(0, 20, 0, 165)
settingsTab.BackgroundTransparency = 1
settingsTab.ScrollBarThickness = 8
settingsTab.ScrollBarImageColor3 = CONFIG.MainColor
settingsTab.Visible = false
settingsTab.Parent = mainFrame

local listLayoutMain = Instance.new("UIListLayout")
listLayoutMain.Padding = UDim.new(0, 16)
listLayoutMain.Parent = mainTab

local listLayoutSettings = Instance.new("UIListLayout")
listLayoutSettings.Padding = UDim.new(0, 16)
listLayoutSettings.Parent = settingsTab

local function createTabButton(text, targetFrame)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 55)
    btn.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
    btn.Text = text
    btn.TextColor3 = CONFIG.MainColor
    btn.TextScaled = true
    btn.Font = Enum.Font.Arcade
    btn.Parent = tabHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.MainColor
    stroke.Thickness = 2.5
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        mainTab.Visible = false
        settingsTab.Visible = false
        targetFrame.Visible = true

        for _, b in ipairs(tabHolder:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 60, 45)
    end)
    return btn
end

createTabButton("MAIN", mainTab)
createTabButton("SETTINGS", settingsTab)

-- Create Toggle (Improved)
local function createFeatureToggle(parent, name, settingsTable, toggleFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 78)
    frame.BackgroundColor3 = Color3.fromRGB(15, 18, 35)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.MainColor
    stroke.Thickness = 2.2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. name
    label.TextColor3 = Color3.fromRGB(230, 255, 240)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 110, 0, 48)
    toggleBtn.Position = UDim2.new(1, -130, 0.5, -24)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.Arcade
    toggleBtn.Parent = frame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 14)
    tCorner.Parent = toggleBtn

    local state = settingsTable.Enabled

    local function updateUI()
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
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
        settingsTable.Enabled = state
        if toggleFunc then toggleFunc(state) end
        updateUI()
        saveConfig()
    end)

    updateUI()
    return frame
end

-- Ragebot
local function getClosestPlayer()
    local closest, dist = nil, math.huge
    local myPos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(Settings.Ragebot.TargetPart) then
            if Settings.Ragebot.TeamCheck and p.Team == player.Team then continue end
            local d = (p.Character[Settings.Ragebot.TargetPart].Position - myPos).Magnitude
            if d < dist and d <= Settings.Ragebot.FOV then
                dist, closest = d, p
            end
        end
    end
    return closest
end

local function toggleRagebot(state)
    Settings.Ragebot.Enabled = state
    if state then
        if connections.ragebot then connections.ragebot:Disconnect() end
        connections.ragebot = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Ragebot.Enabled then return end
            local target = getClosestPlayer()
            if target and target.Character then
                local targetPos = target.Character[Settings.Ragebot.TargetPart].Position
                local targetCF = CFrame.new(camera.CFrame.Position, targetPos)
                camera.CFrame = camera.CFrame:Lerp(targetCF, Settings.Ragebot.Smoothness)
            end
        end)
    elseif connections.ragebot then
        connections.ragebot:Disconnect()
        connections.ragebot = nil
    end
end

-- Voidspam
local function toggleVoidspam(state)
    Settings.Voidspam.Enabled = state
    if state then
        if connections.voidspam then connections.voidspam:Disconnect() end
        connections.voidspam = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Voidspam.Enabled then return end
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end)
    elseif connections.voidspam then
        connections.voidspam:Disconnect()
        connections.voidspam = nil
    end
end

-- ESP (Improved for Rivals)
local function updateESP()
    for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {}

    if not Settings.ESP.Enabled then return end

    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local char = p.Character
            local root = char.HumanoidRootPart
            local humanoid = char:FindFirstChild("Humanoid")

            -- Billboard
            local billboard = Instance.new("BillboardGui")
            billboard.Adornee = root
            billboard.Size = UDim2.new(0, 240, 0, 100)
            billboard.StudsOffset = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = screenGui

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1,0,0.5,0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = p.Name .. (humanoid and " | " .. math.floor(humanoid.Health) .. " HP" or "")
            nameLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = billboard

            table.insert(espObjects, billboard)
        end
    end
end

local function toggleESP(state)
    Settings.ESP.Enabled = state
    if state then
        if connections.esp then connections.esp:Disconnect() end
        connections.esp = Services.RunService.RenderStepped:Connect(updateESP)
    else
        if connections.esp then connections.esp:Disconnect() end
        for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
        espObjects = {}
    end
end

-- Cosmetics (Updated for Rivals)
local function unlockAllCosmetics()
    pcall(function()
        local dataFolders = {Services.ReplicatedStorage, player}
        for _, folder in ipairs(dataFolders) do
            local playerData = folder:FindFirstChild("PlayerData") or folder:FindFirstChildWhichIsA("Folder")
            if playerData then
                for _, v in pairs(playerData:GetDescendants()) do
                    if v:IsA("BoolValue") and (v.Name:match("Unlock") or v.Name:match("Owned")) then
                        v.Value = true
                    end
                end
            end
        end
    end)
end

local function changeWeaponSkin()
    local char = player.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle then
                    handle.Color = CONFIG.AccentColor
                    handle.Material = Enum.Material.Neon
                    handle.Reflectance = 0.8
                end
            end
        end
    end
end

local function toggleCosmetics(state)
    Settings.Cosmetics.Enabled = state
    if state then
        unlockAllCosmetics()
        changeWeaponSkin()
        if connections.skin then connections.skin:Disconnect() end
        connections.skin = player.CharacterAdded:Connect(function()
            task.wait(1)
            unlockAllCosmetics()
            changeWeaponSkin()
        end)
    else
        if connections.skin then connections.skin:Disconnect() end
    end
end

-- Populate Main Tab
createFeatureToggle(mainTab, "Ragebot", Settings.Ragebot, toggleRagebot)
createFeatureToggle(mainTab, "Voidspam", Settings.Voidspam, toggleVoidspam)
createFeatureToggle(mainTab, "ESP (Skeleton + Health)", Settings.ESP, toggleESP)
createFeatureToggle(mainTab, "Skin Changer + Unlock All", Settings.Cosmetics, toggleCosmetics)
createFeatureToggle(mainTab, "Silent Aim", Settings.SilentAim, function(s) Settings.SilentAim.Enabled = s end)

-- Settings Tab Content
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, -40, 0, 50)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "Ragebot FOV: " .. Settings.Ragebot.FOV .. "°"
fovLabel.TextColor3 = CONFIG.AccentColor
fovLabel.TextScaled = true
fovLabel.Font = Enum.Font.Arcade
fovLabel.Parent = settingsTab

local fov60 = Instance.new("TextButton")
fov60.Size = UDim2.new(0.3, 0, 0, 55)
fov60.Position = UDim2.new(0.05, 0, 0, 70)
fov60.Text = "60°"
fov60.Parent = settingsTab
addButtonEffects(fov60)
fov60.MouseButton1Click:Connect(function()
    Settings.Ragebot.FOV = 60
    fovLabel.Text = "Ragebot FOV: 60°"
    saveConfig()
end)

local fov120 = Instance.new("TextButton")
fov120.Size = UDim2.new(0.3, 0, 0, 55)
fov120.Position = UDim2.new(0.35, 0, 0, 70)
fov120.Text = "120°"
fov120.Parent = settingsTab
addButtonEffects(fov120)
fov120.MouseButton1Click:Connect(function()
    Settings.Ragebot.FOV = 120
    fovLabel.Text = "Ragebot FOV: 120°"
    saveConfig()
end)

local fov180 = Instance.new("TextButton")
fov180.Size = UDim2.new(0.3, 0, 0, 55)
fov180.Position = UDim2.new(0.65, 0, 0, 70)
fov180.Text = "180°"
fov180.Parent = settingsTab
addButtonEffects(fov180)
fov180.MouseButton1Click:Connect(function()
    Settings.Ragebot.FOV = 180
    fovLabel.Text = "Ragebot FOV: 180°"
    saveConfig()
end)

-- Save / Load
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.45, 0, 0, 65)
saveBtn.Position = UDim2.new(0.05, 0, 1, -90)
saveBtn.BackgroundColor3 = CONFIG.MainColor
saveBtn.Text = "SAVE CONFIG"
saveBtn.TextColor3 = Color3.new(0,0,0)
saveBtn.TextScaled = true
saveBtn.Font = Enum.Font.Arcade
saveBtn.Parent = settingsTab
addButtonEffects(saveBtn)
saveBtn.MouseButton1Click:Connect(saveConfig)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0.45, 0, 0, 65)
loadBtn.Position = UDim2.new(0.5, 0, 1, -90)
loadBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
loadBtn.Text = "LOAD CONFIG"
loadBtn.TextColor3 = Color3.new(1,1,1)
loadBtn.TextScaled = true
loadBtn.Font = Enum.Font.Arcade
loadBtn.Parent = settingsTab
addButtonEffects(loadBtn)
loadBtn.MouseButton1Click:Connect(loadConfig)

-- Key System Logic
submitButton.MouseButton1Click:Connect(function()
    if keyInput.Text == CONFIG.CorrectKey then
        keyVerified = true
        fadeElement(keyFrame, 1, 0.6)
        task.wait(0.7)
        keyFrame:Destroy()

        mainFrame.Visible = true
        fadeElement(mainFrame, 0, 0.6)

        -- Welcome Message
        task.spawn(function()
            local welcome = Instance.new("TextLabel")
            welcome.Size = UDim2.new(0, 560, 0, 110)
            welcome.Position = UDim2.new(0.5, -280, 0.22, 0)
            welcome.BackgroundTransparency = 0.35
            welcome.BackgroundColor3 = CONFIG.BackgroundColor
            welcome.Text = "VLORP.LUA [BETA]\nRIVALS PROTOCOL ENGAGED"
            welcome.TextColor3 = CONFIG.MainColor
            welcome.TextScaled = true
            welcome.Font = Enum.Font.Arcade
            welcome.Parent = screenGui

            local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0, 24); wc.Parent = welcome
            local ws = Instance.new("UIStroke"); ws.Color = CONFIG.AccentColor; ws.Thickness = 4; ws.Parent = welcome

            fadeElement(welcome, 0, 0.4)
            task.wait(3.2)
            fadeElement(welcome, 1, 1)
            task.wait(1.2)
            welcome:Destroy()
        end)
    else
        keyInput.Text = "INVALID KEY"
        task.wait(1.4)
        keyInput.Text = ""
    end
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(1, -66, 0, 18)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Arcade
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 25)
closeCorner.Parent = closeBtn

addButtonEffects(closeBtn, Color3.fromRGB(170, 20, 20))

closeBtn.MouseButton1Click:Connect(function()
    fadeElement(mainFrame, 1, 0.4)
    task.wait(0.5)
    for _, c in pairs(connections) do pcall(function() c:Disconnect() end) end
    saveConfig()
    screenGui:Destroy()
end)

-- Toggle GUI with Insert
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not keyVerified then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("✅ vlorp.lua [BETA] Loaded for Rivals | Press INSERT | Key: 1234")