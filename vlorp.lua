-- vlorp.lua [BETA] - Unnamed Enhancements Style for Rivals
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

local CONFIG = {
    CorrectKey = "1234",
    GuiName = "VLORP_GUI_BETA",
    MainColor = Color3.fromRGB(0, 255, 180),
    AccentColor = Color3.fromRGB(120, 255, 240),
    BackgroundColor = Color3.fromRGB(12, 12, 28),
}

local keyVerified = false
local connections = {}
local espObjects = {}

local Settings = {
    Combat = {
        Ragebot = { Enabled = false, FOV = 180, Smoothness = 0.22, TargetPart = "Head", TeamCheck = true },
        SilentAim = { Enabled = false, FOV = 135, TargetPart = "Head", HitChance = 100 },
        Triggerbot = { Enabled = false },
        Wallbang = { Enabled = false }
    },
    Visuals = {
        ESP = { Enabled = false, Health = true, Names = true, Boxes = true },
    },
    Misc = {
        Voidspam = { Enabled = false },
        SkinChanger = { Enabled = false },
        Fly = { Enabled = false, Speed = 65 },
        SpeedHack = { Enabled = false, Value = 24 },
        Noclip = { Enabled = false },
        AntiAim = { Enabled = false, Mode = "Spin", Speed = 25 }
    }
}

-- Config System
local configFolder = "vlorp_configs"
if not isfolder(configFolder) then makefolder(configFolder) end
local configPath = configFolder .. "/default.json"

local function loadConfig()
    if isfile(configPath) then
        local success, data = pcall(function() return Services.HttpService:JSONDecode(readfile(configPath)) end)
        if success and data then
            for k, v in pairs(data) do
                if Settings[k] then Settings[k] = v end
            end
        end
    end
end

local function saveConfig()
    pcall(function() writefile(configPath, Services.HttpService:JSONEncode(Settings)) end)
end
loadConfig()

-- UI Utilities
local function createTween(obj, prop, val, dur)
    return Services.TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[prop] = val})
end

local function addHover(btn, base)
    btn.MouseEnter:Connect(function() createTween(btn, "BackgroundColor3", CONFIG.AccentColor, 0.2):Play() end)
    btn.MouseLeave:Connect(function() createTween(btn, "BackgroundColor3", base, 0.2):Play() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONFIG.GuiName
screenGui.ResetOnSpawn = false
screenGui.Parent = Services.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 960, 0, 680)
mainFrame.Position = UDim2.new(0.5, -480, 0.5, -340)
mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", mainFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", mainFrame).Thickness = 8

-- Draggable
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
Services.UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Title
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 90)
title.BackgroundTransparency = 1
title.Text = "VLORP.LUA"
title.TextColor3 = CONFIG.MainColor
title.TextScaled = true
title.Font = Enum.Font.GothamBlack

-- Tabs
local tabHolder = Instance.new("Frame", mainFrame)
tabHolder.Size = UDim2.new(1, -40, 0, 65)
tabHolder.Position = UDim2.new(0, 20, 0, 95)
tabHolder.BackgroundTransparency = 1

local tabList = Instance.new("UIListLayout", tabHolder)
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 12)

local pages = {}

local function createTab(name)
    local btn = Instance.new("TextButton", tabHolder)
    btn.Size = UDim2.new(0, 180, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 255, 230)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 18)
    addHover(btn, Color3.fromRGB(25, 25, 45))

    local page = Instance.new("ScrollingFrame", mainFrame)
    page.Size = UDim2.new(1, -40, 1, -190)
    page.Position = UDim2.new(0, 20, 0, 170)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 8
    page.ScrollBarImageColor3 = CONFIG.MainColor
    page.Visible = false
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 16)

    pages[name] = page

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
        for _, b in pairs(tabHolder:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(25, 25, 45) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 80, 60)
    end)
    return page
end

local combatTab = createTab("Combat")
local visualsTab = createTab("Visuals")
local miscTab = createTab("Misc")

-- Toggle Creator
local function createToggle(parent, name, settingTbl, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 82)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 48)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)
    Instance.new("UIStroke", frame).Color = CONFIG.MainColor

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. name
    label.TextColor3 = Color3.fromRGB(235, 255, 245)
    label.TextScaled = true
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("TextButton", frame)
    tog.Size = UDim2.new(0, 120, 0, 52)
    tog.Position = UDim2.new(1, -145, 0.5, -26)
    tog.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    tog.Text = "OFF"
    tog.TextColor3 = Color3.fromRGB(255, 100, 100)
    tog.TextScaled = true
    tog.Font = Enum.Font.GothamBold
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 14)

    local state = settingTbl.Enabled
    local function update()
        if state then
            tog.BackgroundColor3 = Color3.fromRGB(0, 160, 90)
            tog.Text = "ON"
            tog.TextColor3 = CONFIG.AccentColor
        else
            tog.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
            tog.Text = "OFF"
            tog.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    tog.MouseButton1Click:Connect(function()
        state = not state
        settingTbl.Enabled = state
        if callback then callback(state) end
        update()
        saveConfig()
    end)
    update()
end

-- Features
local function getClosest(fov, teamCheck)
    local closest, d = nil, math.huge
    local pos = camera.CFrame.Position
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if teamCheck and p.Team == player.Team then continue end
            local dist = (p.Character.Head.Position - pos).Magnitude
            if dist < d and dist <= fov then d, closest = dist, p end
        end
    end
    return closest
end

local function toggleRagebot(state)
    if connections.rage then connections.rage:Disconnect() end
    if state then
        connections.rage = Services.RunService.Heartbeat:Connect(function()
            if not Settings.Combat.Ragebot.Enabled then return end
            local target = getClosest(Settings.Combat.Ragebot.FOV, Settings.Combat.Ragebot.TeamCheck)
            if target and target.Character then
                local part = target.Character:FindFirstChild(Settings.Combat.Ragebot.TargetPart) or target.Character.Head
                local cf = CFrame.new(camera.CFrame.Position, part.Position)
                camera.CFrame = camera.CFrame:Lerp(cf, Settings.Combat.Ragebot.Smoothness)
            end
        end)
    end
end

local function toggleESP(state)
    if connections.esp then connections.esp:Disconnect() end
    for _, o in pairs(espObjects) do pcall(o.Destroy, o) end
    espObjects = {}
    if state then
        connections.esp = Services.RunService.RenderStepped:Connect(function()
            for _, o in pairs(espObjects) do pcall(o.Destroy, o) end
            espObjects = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local bg = Instance.new("BillboardGui")
                    bg.Adornee = p.Character.HumanoidRootPart
                    bg.Size = UDim2.new(0, 240, 0, 110)
                    bg.StudsOffset = Vector3.new(0, 5, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = screenGui
                    local tl = Instance.new("TextLabel", bg)
                    tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1
                    tl.Text = p.Name .. (Settings.Visuals.ESP.Health and "\nHP: "..math.floor(p.Character.Humanoid.Health) or "")
                    tl.TextColor3 = CONFIG.AccentColor
                    tl.TextScaled = true
                    tl.Font = Enum.Font.GothamBold
                    table.insert(espObjects, bg)
                end
            end
        end)
    end
end

local function toggleSkinChanger(state)
    if state then
        pcall(function()
            local pd = player:FindFirstChild("PlayerData") or Services.ReplicatedStorage:FindFirstChild("PlayerData")
            if pd then
                for _, v in pairs(pd:GetDescendants()) do
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

-- Populate Tabs
createToggle(combatTab, "Ragebot", Settings.Combat.Ragebot, toggleRagebot)
createToggle(combatTab, "Silent Aim", Settings.Combat.SilentAim, toggleSilentAim)
createToggle(combatTab, "Triggerbot", Settings.Combat.Triggerbot)
createToggle(combatTab, "Wallbang", Settings.Combat.Wallbang)

createToggle(visualsTab, "ESP", Settings.Visuals.ESP, toggleESP)

createToggle(miscTab, "Voidspam", Settings.Misc.Voidspam)
createToggle(miscTab, "Skin Changer", Settings.Misc.SkinChanger, toggleSkinChanger)
createToggle(miscTab, "Fly", Settings.Misc.Fly, toggleFly)
createToggle(miscTab, "Speed Hack", Settings.Misc.SpeedHack)
createToggle(miscTab, "Noclip", Settings.Misc.Noclip)
createToggle(miscTab, "Anti-Aim", Settings.Misc.AntiAim)

-- Close Button
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 60, 0, 60)
closeBtn.Position = UDim2.new(1, -80, 0, 18)
closeBtn.BackgroundColor3 = Color3.fromRGB(185, 25, 25)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 30)
addHover(closeBtn, Color3.fromRGB(185, 25, 25))

closeBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(connections) do pcall(c.Disconnect, c) end
    for _, o in pairs(espObjects) do pcall(o.Destroy, o) end
    saveConfig()
    screenGui:Destroy()
end)

-- Key System
local keyFrame = Instance.new("Frame", screenGui)
keyFrame.Size = UDim2.new(0, 460, 0, 290)
keyFrame.Position = UDim2.new(0.5, -230, 0.5, -145)
keyFrame.BackgroundColor3 = CONFIG.BackgroundColor
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 28)
Instance.new("UIStroke", keyFrame).Color = CONFIG.MainColor
Instance.new("UIStroke", keyFrame).Thickness = 6

local kt = Instance.new("TextLabel", keyFrame)
kt.Size = UDim2.new(1, -40, 0, 70)
kt.Position = UDim2.new(0, 20, 0, 30)
kt.BackgroundTransparency = 1
kt.Text = "VLORP.LUA"
kt.TextColor3 = CONFIG.MainColor
kt.TextScaled = true
kt.Font = Enum.Font.GothamBlack

local ki = Instance.new("TextBox", keyFrame)
ki.Size = UDim2.new(0.78, 0, 0, 58)
ki.Position = UDim2.new(0.11, 0, 0.42, 0)
ki.PlaceholderText = "ENTER KEY (1234)"
ki.TextScaled = true
ki.Font = Enum.Font.Gotham
Instance.new("UICorner", ki).CornerRadius = UDim.new(0, 16)

local sub = Instance.new("TextButton", keyFrame)
sub.Size = UDim2.new(0.6, 0, 0, 58)
sub.Position = UDim2.new(0.2, 0, 0.65, 0)
sub.BackgroundColor3 = CONFIG.MainColor
sub.Text = "VERIFY ACCESS"
sub.TextColor3 = Color3.new(0,0,0)
sub.TextScaled = true
sub.Font = Enum.Font.GothamBold
Instance.new("UICorner", sub).CornerRadius = UDim.new(0, 16)
addHover(sub, CONFIG.MainColor)

sub.MouseButton1Click:Connect(function()
    if ki.Text == CONFIG.CorrectKey then
        keyVerified = true
        keyFrame:Destroy()
        mainFrame.Visible = true
        combatTab.Visible = true
    else
        ki.Text = "INVALID KEY"
        task.wait(1.5)
        ki.Text = ""
    end
end)

-- Right Shift Toggle
Services.UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not keyVerified then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("vlorp.lua [BETA] - Unnamed Enhancements Style Loaded Successfully!")
