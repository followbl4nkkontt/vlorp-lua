-- vlorp.lua [BETA] - Professional Alien-Themed Roblox Script Hub for Rivals

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
    BackgroundColor = Color3.fromRGB(5, 5, 15),
    ConfigFolder = "vlorp_configs",
    ConfigFile = "default.json",
}

local keyVerified = false
local connections = {}
local espObjects = {}

local Settings = {
    Ragebot = { Enabled = false, TargetPart = "Head", FOV = 180, Smoothness = 0.28, TeamCheck = true },
    Voidspam = { Enabled = false, Speed = 0.08 },
    ESP = { Enabled = false, Health = true, Names = true },
    Cosmetics = { Enabled = false, UnlockAll = true },
    SilentAim = { Enabled = false, FOV = 140 },
}

-- Config System
if not isfolder(CONFIG.ConfigFolder) then
    makefolder(CONFIG.ConfigFolder)
end

local function getConfigPath(filename)
    return CONFIG.ConfigFolder .. "/" .. (filename or CONFIG.ConfigFile)
end

local function loadConfig(filename)
    local path = getConfigPath(filename)
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

local function saveConfig(filename)
    local path = getConfigPath(filename)
    pcall(function()
        writefile(path, Services.HttpService:JSONEncode(Settings))
    end)
end

loadConfig("default.json")

-- UI Utilities
local function createTween(obj, prop, val, dur)
    return Services.TweenService:Create(obj, TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[prop] = val})
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

local function addButtonEffects(button, base, hover)
    base = base or CONFIG.MainColor
    hover = hover or CONFIG.AccentColor
    button.MouseEnter:Connect(function() createTween(button, "BackgroundColor3", hover, 0.2):Play() end)
    button.MouseLeave:Connect(function() createTween(button, "BackgroundColor3", base, 0.2):Play() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- ==================== KEY SYSTEM ====================
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 440, 0, 280)
keyFrame.Position = UDim2.new(0.5, -220, 0.5, -140)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
keyFrame.Parent = screenGui

Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", keyFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", keyFrame).Thickness = 6

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -40, 0, 80)
keyTitle.Position = UDim2.new(0, 20, 0, 30)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "VLORP.LUA [BETA]"
keyTitle.TextColor3 = CONFIG.MainColor
keyTitle.TextScaled = true
keyTitle.Font = Enum.Font.Arcade
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0.8, 0, 0, 60)
keyInput.Position = UDim2.new(0.1, 0, 0.45, 0)
keyInput.PlaceholderText = "ENTER KEY (1234)"
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
keyInput.TextScaled = true
keyInput.Font = Enum.Font.Arcade
keyInput.Parent = keyFrame
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 16)

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0.65, 0, 0, 60)
submitButton.Position = UDim2.new(0.175, 0, 0.7, 0)
submitButton.BackgroundColor3 = CONFIG.MainColor
submitButton.Text = "VERIFY ACCESS"
submitButton.TextColor3 = Color3.new(0,0,0)
submitButton.TextScaled = true
submitButton.Font = Enum.Font.Arcade
submitButton.Parent = keyFrame
Instance.new("UICorner", submitButton).CornerRadius = UDim.new(0, 16)
addButtonEffects(submitButton)

-- ==================== MAIN GUI ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 800, 0, 620)
mainFrame.Position = UDim2.new(0.5, -400, 0.5, -310)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", mainFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", mainFrame).Thickness = 6

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 90)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VLORP.LUA [BETA]"
titleLabel.TextColor3 = CONFIG.MainColor
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.Arcade
titleLabel.Parent = mainFrame

-- Tabs
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -40, 0, 65)
tabHolder.Position = UDim2.new(0, 20, 0, 95)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = mainFrame

local tabList = Instance.new("UIListLayout", tabHolder)
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 15)

local mainTab = Instance.new("ScrollingFrame")
mainTab.Size = UDim2.new(1, -40, 1, -210)
mainTab.Position = UDim2.new(0, 20, 0, 170)
mainTab.BackgroundTransparency = 1
mainTab.ScrollBarThickness = 6
mainTab.ScrollBarImageColor3 = CONFIG.MainColor
mainTab.Visible = true
mainTab.Parent = mainFrame
Instance.new("UIListLayout", mainTab).Padding = UDim.new(0, 18)

local settingsTab = Instance.new("ScrollingFrame")
settingsTab.Size = UDim2.new(1, -40, 1, -210)
settingsTab.Position = UDim2.new(0, 20, 0, 170)
settingsTab.BackgroundTransparency = 1
settingsTab.ScrollBarThickness = 6
settingsTab.ScrollBarImageColor3 = CONFIG.MainColor
settingsTab.Visible = false
settingsTab.Parent = mainFrame
Instance.new("UIListLayout", settingsTab).Padding = UDim.new(0, 18)

local function createTabButton(text, targetFrame)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 170, 0, 58)
    btn.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
    btn.Text = text
    btn.TextColor3 = CONFIG.MainColor
    btn.TextScaled = true
    btn.Font = Enum.Font.Arcade
    btn.Parent = tabHolder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 18)
    Instance.new("UIStroke", btn).Color = CONFIG.MainColor

    btn.MouseButton1Click:Connect(function()
        mainTab.Visible = false
        settingsTab.Visible = false
        targetFrame.Visible = true
        for _, b in pairs(tabHolder:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 55, 40)
    end)
end

createTabButton("MAIN", mainTab)
createTabButton("SETTINGS", settingsTab)

-- Toggle Creator
local function createToggle(parent, name, settingTbl, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 82)
    frame.BackgroundColor3 = Color3.fromRGB(15, 18, 35)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)
    Instance.new("UIStroke", frame).Color = CONFIG.MainColor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.68, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "   " .. name
    label.TextColor3 = Color3.fromRGB(230, 255, 240)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 52)
    toggleBtn.Position = UDim2.new(1, -140, 0.5, -26)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.Arcade
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 16)

    local state = settingTbl.Enabled

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
        settingTbl.Enabled = state
        if callback then callback(state) end
        updateUI()
        saveConfig("default.json")
    end)

    updateUI()
end

-- Feature Functions
local function getClosestPlayer()
    local closest, dist = nil, math.huge
    local myPos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.Ragebot.TeamCheck and p.Team == player.Team then continue end
            local d = (p.Character.Head.Position - myPos).Magnitude
            if d < dist and d <= Settings.Ragebot.FOV then
                dist, closest = d, p
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
            local target = getClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local targetCF = CFrame.new(camera.CFrame.Position, target.Character.Head.Position)
                camera.CFrame = camera.CFrame:Lerp(targetCF, Settings.Ragebot.Smoothness)
            end
        end)
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
                    bg.Size = UDim2.new(0, 240, 0, 90)
                    bg.StudsOffset = Vector3.new(0, 4, 0)
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
            local pd = Services.ReplicatedStorage:FindFirstChild("PlayerData") or player:FindFirstChild("PlayerData")
            if pd then
                for _, v in pairs(pd:GetDescendants()) do
                    if v:IsA("BoolValue") and (v.Name:match("Unlock") or v.Name:match("Owned")) then
                        v.Value = true
                    end
                end
            end
        end)
    end
end

-- Populate Main Tab
createToggle(mainTab, "Ragebot", Settings.Ragebot, toggleRagebot)
createToggle(mainTab, "Voidspam", Settings.Voidspam, toggleVoidspam)
createToggle(mainTab, "ESP", Settings.ESP, toggleESP)
createToggle(mainTab, "Skin Changer + Unlock", Settings.Cosmetics, toggleCosmetics)

-- SETTINGS TAB (Settings + Configs)
local settingsHeader = Instance.new("TextLabel")
settingsHeader.Size = UDim2.new(1, -40, 0, 50)
settingsHeader.BackgroundTransparency = 1
settingsHeader.Text = "⚙️ SETTINGS"
settingsHeader.TextColor3 = CONFIG.AccentColor
settingsHeader.TextScaled = true
settingsHeader.Font = Enum.Font.Arcade
settingsHeader.Parent = settingsTab

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, -40, 0, 45)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "Ragebot FOV: " .. Settings.Ragebot.FOV .. "°"
fovLabel.TextColor3 = CONFIG.MainColor
fovLabel.TextScaled = true
fovLabel.Parent = settingsTab

for _, deg in ipairs({60, 120, 180}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.28, 0, 0, 55)
    btn.Position = UDim2.new(0.05 + (_-1)*0.32, 0, 0, 60)
    btn.Text = deg .. "°"
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    btn.TextColor3 = CONFIG.AccentColor
    btn.TextScaled = true
    btn.Font = Enum.Font.Arcade
    btn.Parent = settingsTab
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
    addButtonEffects(btn)
    btn.MouseButton1Click:Connect(function()
        Settings.Ragebot.FOV = deg
        fovLabel.Text = "Ragebot FOV: " .. deg .. "°"
        saveConfig("default.json")
    end)
end

-- Configs Section
local configHeader = Instance.new("TextLabel")
configHeader.Size = UDim2.new(1, -40, 0, 50)
configHeader.Position = UDim2.new(0, 20, 0, 280)
configHeader.BackgroundTransparency = 1
configHeader.Text = "💾 CONFIGS"
configHeader.TextColor3 = CONFIG.AccentColor
configHeader.TextScaled = true
configHeader.Font = Enum.Font.Arcade
configHeader.Parent = settingsTab

-- Save / Load / Reset buttons (same as before, cleaned)
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.45, 0, 0, 65)
saveBtn.Position = UDim2.new(0.05, 0, 0, 340)
saveBtn.Text = "Save Config"
saveBtn.BackgroundColor3 = CONFIG.MainColor
saveBtn.TextColor3 = Color3.new(0,0,0)
saveBtn.TextScaled = true
saveBtn.Font = Enum.Font.Arcade
saveBtn.Parent = settingsTab
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 16)
addButtonEffects(saveBtn)
saveBtn.MouseButton1Click:Connect(function() saveConfig("default.json") end)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0.45, 0, 0, 65)
loadBtn.Position = UDim2.new(0.5, 0, 0, 340)
loadBtn.Text = "Load Config"
loadBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
loadBtn.TextColor3 = Color3.new(1,1,1)
loadBtn.TextScaled = true
loadBtn.Font = Enum.Font.Arcade
loadBtn.Parent = settingsTab
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 16)
addButtonEffects(loadBtn)
loadBtn.MouseButton1Click:Connect(function() loadConfig("default.json") end)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.45, 0, 0, 65)
resetBtn.Position = UDim2.new(0.05, 0, 0, 420)
resetBtn.Text = "Reset Defaults"
resetBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.TextScaled = true
resetBtn.Font = Enum.Font.Arcade
resetBtn.Parent = settingsTab
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 16)
addButtonEffects(resetBtn)
resetBtn.MouseButton1Click:Connect(function()
    Settings.Ragebot.FOV = 180
    Settings.Ragebot.Smoothness = 0.28
    saveConfig("default.json")
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 52, 0, 52)
closeBtn.Position = UDim2.new(1, -70, 0, 18)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Arcade
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 26)
addButtonEffects(closeBtn, Color3.fromRGB(170, 20, 20))

closeBtn.MouseButton1Click:Connect(function()
    fadeElement(mainFrame, 1, 0.4)
    task.wait(0.5)
    for _, c in pairs(connections) do pcall(function() c:Disconnect() end) end
    saveConfig("default.json")
    screenGui:Destroy()
end)

-- Key System Logic
submitButton.MouseButton1Click:Connect(function()
    if keyInput.Text == CONFIG.CorrectKey then
        keyVerified = true
        fadeElement(keyFrame, 1, 0.6)
        task.wait(0.7)
        keyFrame:Destroy()

        mainFrame.Visible = true
        fadeElement(mainFrame, 0, 0.6)
    else
        keyInput.Text = "INVALID KEY"
        task.wait(1.5)
        keyInput.Text = ""
    end
end)

-- Toggle GUI
Services.UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not keyVerified then return end
    if i.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("vlorp.lua [BETA] loaded successfully")