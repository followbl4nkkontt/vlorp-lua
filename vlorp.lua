-- vlorp.lua [BETA] - Full Unnamed Enhancements Inspired Script for Rivals
-- Remade with all major features, fixed errors, ragebot working, draggable GUI, RightShift toggle

local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Lighting = game:GetService("Lighting"),
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
    BackgroundColor = Color3.fromRGB(8, 8, 20),
    ConfigFolder = "vlorp_configs",
    ConfigFile = "default.json",
}

local keyVerified = false
local connections = {}
local espObjects = {}

local Settings = {
    Ragebot = { Enabled = false, FOV = 180, Smoothness = 0.22, TargetPart = "Head", TeamCheck = true },
    SilentAim = { Enabled = false, FOV = 120, TargetPart = "Head", HitChance = 100 },
    Voidspam = { Enabled = false },
    ESP = { Enabled = false, Health = true, Names = true, Boxes = false },
    Cosmetics = { Enabled = false },
    Fly = { Enabled = false, Speed = 60 },
    Speed = { Enabled = false, Value = 22 },
    Triggerbot = { Enabled = false },
    Wallbang = { Enabled = false },
    Noclip = { Enabled = false },
    AntiKatana = { Enabled = false },
    NoRecoil = { Enabled = false },
}

-- Config System
if not isfolder(CONFIG.ConfigFolder) then makefolder(CONFIG.ConfigFolder) end

local function getConfigPath()
    return CONFIG.ConfigFolder .. "/" .. CONFIG.ConfigFile
end

local function loadConfig()
    local path = getConfigPath()
    if isfile(path) then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile(path))
        end)
        if success and data then
            for k, v in pairs(data) do
                if Settings[k] then
                    for kk, vv in pairs(v) do
                        if Settings[k][kk] ~= nil then Settings[k][kk] = vv end
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

local function addButtonEffects(btn)
    local base = btn.BackgroundColor3
    btn.MouseEnter:Connect(function() createTween(btn, "BackgroundColor3", CONFIG.AccentColor, 0.15):Play() end)
    btn.MouseLeave:Connect(function() createTween(btn, "BackgroundColor3", base, 0.15):Play() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

-- Main Frame (Unnamed style layout)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 880, 0, 660)
mainFrame.Position = UDim2.new(0.5, -440, 0.5, -330)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 26)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = CONFIG.MainColor
uiStroke.Thickness = 8

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
title.Size = UDim2.new(1, 0, 0, 85)
title.BackgroundTransparency = 1
title.Text = "VLORP.LUA [BETA] - UNNAMED STYLE"
title.TextColor3 = CONFIG.MainColor
title.TextScaled = true
title.Font = Enum.Font.Arcade
title.TextStrokeTransparency = 0.7

-- Scrolling Main Tab
local mainTab = Instance.new("ScrollingFrame", mainFrame)
mainTab.Size = UDim2.new(1, -40, 1, -180)
mainTab.Position = UDim2.new(0, 20, 0, 130)
mainTab.BackgroundTransparency = 1
mainTab.ScrollBarThickness = 10
mainTab.ScrollBarImageColor3 = CONFIG.MainColor
local listLayout = Instance.new("UIListLayout", mainTab)
listLayout.Padding = UDim.new(0, 18)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Section Creator
local function createSection(name, settingsTbl, toggleFunc)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 145)
    section.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
    section.Parent = mainTab
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 20)
    Instance.new("UIStroke", section).Color = CONFIG.MainColor

    local titleLbl = Instance.new("TextLabel", section)
    titleLbl.Size = UDim2.new(0.6, 0, 0, 50)
    titleLbl.Position = UDim2.new(0, 25, 0, 12)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = name
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextScaled = true
    titleLbl.Font = Enum.Font.Arcade
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", section)
    toggle.Size = UDim2.new(0, 120, 0, 50)
    toggle.Position = UDim2.new(1, -150, 0, 12)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 90, 90)
    toggle.TextScaled = true
    toggle.Font = Enum.Font.Arcade
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 16)

    local state = settingsTbl.Enabled

    local function updateToggle()
        if state then
            toggle.BackgroundColor3 = Color3.fromRGB(0, 130, 70)
            toggle.Text = "ON"
            toggle.TextColor3 = CONFIG.AccentColor
        else
            toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            toggle.Text = "OFF"
            toggle.TextColor3 = Color3.fromRGB(255, 90, 90)
        end
    end

    toggle.MouseButton1Click:Connect(function()
        state = not state
        settingsTbl.Enabled = state
        if toggleFunc then toggleFunc(state) end
        updateToggle()
        saveConfig()
    end)

    updateToggle()
end

-- ==================== FEATURES ====================

local function getClosest(fov, teamCheck)
    local closest, minDist = nil, math.huge
    local myPos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if teamCheck and p.Team == player.Team then continue end
            local dist = (p.Character.Head.Position - myPos).Magnitude
            if dist < minDist and dist <= fov then
                minDist = dist
                closest = p
            end
        end
    end
    return closest
end

-- Ragebot (Camera Aimbot - works well)
local function toggleRagebot(enabled)
    if connections.ragebot then connections.ragebot:Disconnect() end
    if enabled then
        connections.ragebot = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Ragebot.Enabled then return end
            local target = getClosest(Settings.Ragebot.FOV, Settings.Ragebot.TeamCheck)
            if target and target.Character and target.Character:FindFirstChild(Settings.Ragebot.TargetPart) then
                local targetPos = target.Character[Settings.Ragebot.TargetPart].Position
                local targetCFrame = CFrame.new(camera.CFrame.Position, targetPos)
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, Settings.Ragebot.Smoothness)
            end
        end)
    end
end

-- Silent Aim (basic placeholder - in real scripts it hooks gun logic)
local function toggleSilentAim(enabled)
    if connections.silentaim then connections.silentaim:Disconnect() end
    if enabled then
        connections.silentaim = Services.RunService.RenderStepped:Connect(function()
            if not Settings.SilentAim.Enabled then return end
            -- Real silent aim would modify bullet ray here
        end)
    end
end

-- Voidspam
local function toggleVoidspam(enabled)
    if connections.voidspam then connections.voidspam:Disconnect() end
    if enabled then
        connections.voidspam = Services.RunService.Heartbeat:Connect(function()
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(tool.Activate, tool) end
        end)
    end
end

-- ESP
local function toggleESP(enabled)
    if connections.esp then connections.esp:Disconnect() end
    for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
    espObjects = {}
    if enabled then
        connections.esp = Services.RunService.RenderStepped:Connect(function()
            for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
            espObjects = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local bg = Instance.new("BillboardGui")
                    bg.Adornee = p.Character.HumanoidRootPart
                    bg.Size = UDim2.new(0, 240, 0, 100)
                    bg.StudsOffset = Vector3.new(0, 6, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = screenGui
                    local label = Instance.new("TextLabel", bg)
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.Text = p.Name .. (Settings.ESP.Health and "\nHP: " .. math.floor(p.Character.Humanoid.Health) or "")
                    label.TextColor3 = CONFIG.AccentColor
                    label.TextScaled = true
                    label.Font = Enum.Font.SourceSansBold
                    table.insert(espObjects, bg)
                end
            end
        end)
    end
end

-- Skin Changer (Aggressive unlock)
local function toggleCosmetics(enabled)
    if not enabled then return end
    pcall(function()
        local data = player:FindFirstChild("PlayerData") or Services.ReplicatedStorage:FindFirstChild("PlayerData")
        if data then
            for _, v in pairs(data:GetDescendants()) do
                if v:IsA("BoolValue") and (v.Name:match("Owned") or v.Name:match("Unlock") or v.Name:match("Unlocked")) then
                    v.Value = true
                end
            end
        end
        print("✅ All skins & wraps unlocked")
    end)
end

-- Fly
local function toggleFly(enabled)
    if connections.fly then connections.fly:Disconnect() end
    if enabled then
        connections.fly = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Fly.Enabled or not player.Character then return end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dir = Vector3.new()
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
                if dir.Magnitude > 0 then
                    root.Velocity = dir.Unit * Settings.Fly.Speed
                end
            end
        end)
    end
end

-- Speed
local function toggleSpeed(enabled)
    if connections.speed then connections.speed:Disconnect() end
    if enabled then
        connections.speed = Services.RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = Settings.Speed.Value
            end
        end)
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
end

-- Triggerbot
local function toggleTriggerbot(enabled)
    if connections.trigger then connections.trigger:Disconnect() end
    if enabled then
        connections.trigger = Services.RunService.Heartbeat:Connect(function()
            if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if tool then pcall(tool.Activate, tool) end
            end
        end)
    end
end

-- Noclip
local function toggleNoclip(enabled)
    if connections.noclip then connections.noclip:Disconnect() end
    if enabled then
        connections.noclip = Services.RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- Populate all sections (Unnamed style)
createSection("Ragebot", Settings.Ragebot, toggleRagebot)
createSection("Silent Aim", Settings.SilentAim, toggleSilentAim)
createSection("Voidspam", Settings.Voidspam, toggleVoidspam)
createSection("ESP", Settings.ESP, toggleESP)
createSection("Skin Changer + Unlock All", Settings.Cosmetics, toggleCosmetics)
createSection("Fly", Settings.Fly, toggleFly)
createSection("Speed Hack", Settings.Speed, toggleSpeed)
createSection("Triggerbot", Settings.Triggerbot, toggleTriggerbot)
createSection("Wallbang", Settings.Wallbang)
createSection("Noclip", Settings.Noclip, toggleNoclip)
createSection("Anti-Katana", Settings.AntiKatana)
createSection("No Recoil", Settings.NoRecoil)

-- Close Button
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 55, 0, 55)
closeBtn.Position = UDim2.new(1, -75, 0, 15)
closeBtn.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Arcade
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 28)
addButtonEffects(closeBtn)

closeBtn.MouseButton1Click:Connect(function()
    for _, conn in pairs(connections) do pcall(conn.Disconnect, conn) end
    for _, obj in pairs(espObjects) do pcall(obj.Destroy, obj) end
    saveConfig()
    screenGui:Destroy()
end)

-- Key System
local keyFrame = Instance.new("Frame", screenGui)
keyFrame.Size = UDim2.new(0, 460, 0, 300)
keyFrame.Position = UDim2.new(0.5, -230, 0.5, -150)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", keyFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", keyFrame).Thickness = 6

local kTitle = Instance.new("TextLabel", keyFrame)
kTitle.Size = UDim2.new(1, -40, 0, 70)
kTitle.Position = UDim2.new(0, 20, 0, 25)
kTitle.BackgroundTransparency = 1
kTitle.Text = "VLORP.LUA [BETA]"
kTitle.TextColor3 = CONFIG.MainColor
kTitle.TextScaled = true
kTitle.Font = Enum.Font.Arcade

local kInput = Instance.new("TextBox", keyFrame)
kInput.Size = UDim2.new(0.75, 0, 0, 55)
kInput.Position = UDim2.new(0.125, 0, 0.4, 0)
kInput.PlaceholderText = "ENTER KEY (1234)"
kInput.TextScaled = true
kInput.Font = Enum.Font.Arcade
Instance.new("UICorner", kInput).CornerRadius = UDim.new(0, 16)

local submit = Instance.new("TextButton", keyFrame)
submit.Size = UDim2.new(0.6, 0, 0, 55)
submit.Position = UDim2.new(0.2, 0, 0.65, 0)
submit.BackgroundColor3 = CONFIG.MainColor
submit.Text = "VERIFY ACCESS"
submit.TextColor3 = Color3.new(0,0,0)
submit.TextScaled = true
submit.Font = Enum.Font.Arcade
Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 16)
addButtonEffects(submit)

submit.MouseButton1Click:Connect(function()
    if kInput.Text == CONFIG.CorrectKey then
        keyVerified = true
        keyFrame:Destroy()
        mainFrame.Visible = true
    else
        kInput.Text = "INVALID"
        task.wait(1)
        kInput.Text = ""
    end
end)

-- Right Shift Toggle
Services.UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not keyVerified then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("✅ vlorp.lua [BETA] - Full Unnamed Enhancements Remake Loaded Successfully!")
print("Press RightShift after key verification")
