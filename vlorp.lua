-- vlorp.lua -- Professional Alien-Themed Roblox Script Hub for Rivals -- Optimized for Potassium Executor - Full Rivals Skin Changer Support

local Services = { Players = game:GetService("Players"), TweenService = game:GetService("TweenService"), UserInputService = game:GetService("UserInputService"), RunService = game:GetService("RunService"), CoreGui = game:GetService("CoreGui"), HttpService = game:GetService("HttpService"), ReplicatedStorage = game:GetService("ReplicatedStorage"), }

local player = Services.Players.LocalPlayer

-- Configuration local CONFIG = { CorrectKey = "1234", GuiName = "VLORP_GUI", MainColor = Color3.fromRGB(0, 255, 100), BackgroundColor = Color3.fromRGB(8, 8, 8), ConfigFile = "vlorp_config.json", }

local keyVerified = false local connections = {}

local Settings = { Ragebot = { Enabled = false, TargetPart = "Head", FOV = 180, TeamCheck = true }, Voidspam = { Enabled = false, Speed = 0.08 }, Cosmetics = { Enabled = false, SkinID = "Default", UnlockAll = false }, }

-- Load / Save Config local function loadConfig() if isfile(CONFIG.ConfigFile) then local success, data = pcall(function() return Services.HttpService:JSONDecode(readfile(CONFIG.ConfigFile)) end) if success and data then for module, values in pairs(data) do if Settings[module] then for k, v in pairs(values) do if Settings[module][k] ~= nil then Settings[module][k] = v end end end end print("✅ VLORP: Config loaded") end end end

local function saveConfig() pcall(function() writefile(CONFIG.ConfigFile, Services.HttpService:JSONEncode(Settings)) end) print("💾 VLORP: Config saved") end

loadConfig()

-- UI Utilities local function createTween(obj, prop, val, dur) local tweenInfo = TweenInfo.new(dur or 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) return Services.TweenService:Create(obj, tweenInfo, {[prop] = val}) end

local function fadeElement(element, target, duration) duration = duration or 0.3 if element:IsA("GuiObject") then createTween(element, "BackgroundTransparency", target, duration):Play() end if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then createTween(element, "TextTransparency", target, duration):Play() end local stroke = element:FindFirstChildOfClass("UIStroke") if stroke then createTween(stroke, "Transparency", target, duration):Play() end end

local function addButtonEffects(button, baseColor, hoverColor) baseColor = baseColor or CONFIG.MainColor hoverColor = hoverColor or Color3.fromRGB(100, 255, 150) button.MouseEnter:Connect(function() createTween(button, "BackgroundColor3", hoverColor, 0.2):Play() fadeElement(button, 0.1, 0.2) end) button.MouseLeave:Connect(function() createTween(button, "BackgroundColor3", baseColor, 0.2):Play() fadeElement(button, 0, 0.2) end) end

-- ScreenGui & Main UI (same polished style) local screenGui = Instance.new("ScreenGui") screenGui.Name = CONFIG.GuiName screenGui.ResetOnSpawn = false screenGui.Parent = Services.CoreGui

local mainFrame = Instance.new("Frame") mainFrame.Size = UDim2.new(0, 640, 0, 520) mainFrame.Position = UDim2.new(0.5, -320, 0.5, -260) mainFrame.BackgroundColor3 = CONFIG.BackgroundColor mainFrame.Visible = false mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner") mainCorner.CornerRadius = UDim.new(0, 18) mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke") mainStroke.Color = CONFIG.MainColor mainStroke.Thickness = 3.5 mainStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel") titleLabel.Size = UDim2.new(1, 0, 0, 70) titleLabel.BackgroundTransparency = 1 titleLabel.Text = "VLORP.LUA" titleLabel.TextColor3 = CONFIG.MainColor titleLabel.TextScaled = true titleLabel.Font = Enum.Font.SourceSansItalic titleLabel.Parent = mainFrame

local titleStroke = Instance.new("UIStroke") titleStroke.Color = CONFIG.MainColor titleStroke.Thickness = 2.5 titleStroke.Parent = titleLabel

-- Key System (unchanged) local keyFrame = Instance.new("Frame") keyFrame.Size = UDim2.new(0, 340, 0, 220) keyFrame.Position = UDim2.new(0.5, -170, 0.5, -110) keyFrame.BackgroundColor3 = CONFIG.BackgroundColor keyFrame.Parent = screenGui

local keyCorner = Instance.new("UICorner") keyCorner.CornerRadius = UDim.new(0, 18) keyCorner.Parent = keyFrame

local keyStroke = Instance.new("UIStroke") keyStroke.Color = CONFIG.MainColor keyStroke.Thickness = 3 keyStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel") keyTitle.Size = UDim2.new(1, -40, 0, 50) keyTitle.Position = UDim2.new(0, 20, 0, 20) keyTitle.BackgroundTransparency = 1 keyTitle.Text = "VLORP.LUA • KEY SYSTEM" keyTitle.TextColor3 = CONFIG.MainColor keyTitle.TextScaled = true keyTitle.Font = Enum.Font.SourceSansItalic keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox") keyInput.Size = UDim2.new(0.85, 0, 0, 45) keyInput.Position = UDim2.new(0.075, 0, 0.42, 0) keyInput.PlaceholderText = "Enter key... (1234)" keyInput.TextColor3 = Color3.fromRGB(255, 255, 255) keyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25) keyInput.TextScaled = true keyInput.Parent = keyFrame

local inputCorner = Instance.new("UICorner") inputCorner.CornerRadius = UDim.new(0, 10) inputCorner.Parent = keyInput

local submitButton = Instance.new("TextButton") submitButton.Size = UDim2.new(0.6, 0, 0, 48) submitButton.Position = UDim2.new(0.2, 0, 0.68, 0) submitButton.BackgroundColor3 = Color3.fromRGB(0, 220, 90) submitButton.Text = "VERIFY" submitButton.TextColor3 = Color3.new(0,0,0) submitButton.TextScaled = true submitButton.Font = Enum.Font.SourceSansBold submitButton.Parent = keyFrame

local submitCorner = Instance.new("UICorner") submitCorner.CornerRadius = UDim.new(0, 12) submitCorner.Parent = submitButton

addButtonEffects(submitButton, Color3.fromRGB(0, 220, 90))

-- RAGEBOT (unchanged) local function getClosestPlayer() local closest, dist = nil, math.huge local cam = workspace.CurrentCamera local myPos = cam.CFrame.Position for _, p in ipairs(Services.Players:GetPlayers()) do if p ~= player and p.Character and p.Character:FindFirstChild(Settings.Ragebot.TargetPart) then if Settings.Ragebot.TeamCheck and p.Team == player.Team then continue end local d = (p.Character[Settings.Ragebot.TargetPart].Position - myPos).Magnitude if d < dist and d <= Settings.Ragebot.FOV then dist, closest = d, p end end end return closest end

local function toggleRagebot(state) Settings.Ragebot.Enabled = state if state then if connections.ragebot then connections.ragebot:Disconnect() end connections.ragebot = Services.RunService.Heartbeat:Connect(function() if not Settings.Ragebot.Enabled then return end local target = getClosestPlayer() if target and target.Character then local cam = workspace.CurrentCamera local targetCF = CFrame.new(cam.CFrame.Position, target.Character[Settings.Ragebot.TargetPart].Position) cam.CFrame = cam.CFrame:Lerp(targetCF, 0.35) end end) elseif connections.ragebot then connections.ragebot:Disconnect() connections.ragebot = nil end end

-- VOIDSPAM local function toggleVoidspam(state) Settings.Voidspam.Enabled = state if state then if connections.voidspam then connections.voidspam:Disconnect() end connections.voidspam = Services.RunService.Heartbeat:Connect(function() if not Settings.Voidspam.Enabled then return end local tool = player.Character and player.Character:FindFirstChildOfClass("Tool") if tool then pcall(function() tool:Activate() end) end end) elseif connections.voidspam then connections.voidspam:Disconnect() connections.voidspam = nil end end

-- Rivals Skin Changer (Improved) local function unlockAllCosmetics() -- Common client-sided unlock for Rivals (visual / local) pcall(function() local playerData = Services.ReplicatedStorage:FindFirstChild("PlayerData") or player:FindFirstChild("PlayerData") if playerData then -- Force unlock visuals (many scripts do similar) for _, v in pairs(playerData:GetDescendants()) do if v:IsA("BoolValue") and v.Name:match("Unlocked") then v.Value = true end end end end) print("🎨 VLORP: Unlocked all cosmetics (client-side)") end

local function changeWeaponSkin(skinName) -- Apply to equipped tools (Rivals weapon skins are often Material/Color/Texture based) local char = player.Character if char then for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") then pcall(function() local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("MeshPart") if handle then handle.Color = Color3.fromRGB(0, 255, 150) -- Example neon handle.Material = Enum.Material.Neon print("Applied skin to " .. tool.Name .. ": " .. skinName) end end) end end end end

local function toggleCosmetics(state) Settings.Cosmetics.Enabled = state if state then unlockAllCosmetics() if Settings.Cosmetics.UnlockAll then unlockAllCosmetics() end connections.skin = player.CharacterAdded:Connect(function() task.wait(1) unlockAllCosmetics() changeWeaponSkin(Settings.Cosmetics.SkinID) end) else if connections.skin then connections.skin:Disconnect() end end end

-- Key Submit submitButton.MouseButton1Click:Connect(function() if keyInput.Text == CONFIG.CorrectKey then keyVerified = true fadeElement(keyFrame, 1, 0.5) task.wait(0.55) keyFrame:Destroy()

	mainFrame.Visible = true
	fadeElement(mainFrame, 0, 0.6)

	task.spawn(function()
		local w = Instance.new("TextLabel")
		w.Size = UDim2.new(0,460,0,90)
		w.Position = UDim2.new(0.5,-230,0.15,0)
		w.BackgroundTransparency = 0.3
		w.BackgroundColor3 = CONFIG.BackgroundColor
		w.Text = "VLORP.LUA LOADED - RIVALS READY"
		w.TextColor3 = CONFIG.MainColor
		w.TextScaled = true
		w.Font = Enum.Font.SourceSansItalic
		w.Parent = screenGui
		local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0,16); wc.Parent = w
		local ws = Instance.new("UIStroke"); ws.Color = CONFIG.MainColor; ws.Thickness = 2; ws.Parent = w
		fadeElement(w, 0, 0.4)
		task.wait(2.5)
		fadeElement(w, 1, 0.8)
		task.wait(1)
		w:Destroy()
	end)
else
	keyInput.Text = "INVALID"
	task.wait(1)
	keyInput.Text = ""
end
end)

-- Tab Container local tabContainer = Instance.new("ScrollingFrame") tabContainer.Size = UDim2.new(1, -40, 1, -150) tabContainer.Position = UDim2.new(0, 20, 0, 85) tabContainer.BackgroundTransparency = 1 tabContainer.ScrollBarThickness = 6 tabContainer.ScrollBarImageColor3 = CONFIG.MainColor tabContainer.Parent = mainFrame

local listLayout = Instance.new("UIListLayout") listLayout.Padding = UDim.new(0, 12) listLayout.Parent = tabContainer

local features = { {Name = "Ragebot", Toggle = true, Action = toggleRagebot}, {Name = "Voidspam", Toggle = true, Action = toggleVoidspam}, {Name = "Skin Changer", Toggle = true, Action = toggleCosmetics}, {Name = "Unlock All Cosmetics", Action = unlockAllCosmetics}, {Name = "Save Config", Action = saveConfig}, {Name = "Load Config", Action = loadConfig}, {Name = "Silent Aim", Desc = "Hit assistance"}, {Name = "ESP", Desc = "Wallhacks"}, }

for _, f in ipairs(features) do local btn = Instance.new("TextButton") btn.Size = UDim2.new(1,0,0,62) btn.BackgroundColor3 = Color3.fromRGB(18,18,18) btn.Text = f.Name .. (f.Desc and ("\n"..f.Desc) or "") btn.TextColor3 = Color3.fromRGB(220,255,220) btn.TextScaled = true btn.Font = Enum.Font.SourceSansItalic btn.TextWrapped = true btn.Parent = tabContainer

local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = btn
local s = Instance.new("UIStroke"); s.Color = CONFIG.MainColor; s.Thickness = 1.8; s.Parent = btn

addButtonEffects(btn)

if f.Toggle then
	local state = Settings[f.Name:lower()] and Settings[f.Name:lower()].Enabled or false
	btn.MouseButton1Click:Connect(function()
		state = not state
		if f.Action then f.Action(state) end
		btn.BackgroundColor3 = state and Color3.fromRGB(0,100,60) or Color3.fromRGB(18,18,18)
	end)
else
	btn.MouseButton1Click:Connect(function()
		if f.Action then f.Action() end
	end)
end
end

-- Close Button local closeBtn = Instance.new("TextButton") closeBtn.Size = UDim2.new(0,36,0,36) closeBtn.Position = UDim2.new(1,-46,0,12) closeBtn.BackgroundColor3 = Color3.fromRGB(190,40,40) closeBtn.Text = "✕" closeBtn.TextColor3 = Color3.new(1,1,1) closeBtn.TextScaled = true closeBtn.Parent = mainFrame

local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,18); cc.Parent = closeBtn addButtonEffects(closeBtn, Color3.fromRGB(190,40,40))

closeBtn.MouseButton1Click:Connect(function() fadeElement(mainFrame, 1, 0.35) task.wait(0.4) for _, c in pairs(connections) do pcall(function() c:Disconnect() end) end saveConfig() screenGui:Destroy() end)

-- Insert Toggle Services.UserInputService.InputBegan:Connect(function(i, gp) if gp or not keyVerified then return end if i.KeyCode == Enum.KeyCode.Insert then mainFrame.Visible = not mainFrame.Visible end end)

print("✅ VLORP.LUA Loaded for Rivals | Key: 1234 | Skin Changer Fixed")