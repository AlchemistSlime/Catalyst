local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera
local CatalystThreads = {}
local function ClearESP() for _, p in pairs(Plrs:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Catalyst_Highlight") then p.Character.Catalyst_Highlight:Destroy() end end end

-- 🔥 АВТО-ЗАГРУЗКА БИБЛИОТЕК С GITHUB
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- 📦 КАЖДЫЙ ЭЛЕМЕНТ ИНТЕРФЕЙСА В ОДНУ СТРОКУ (МЕНЯЙ НАЗВАНИЯ В КАВЫЧКАХ ТУТ ➡️)
local Window = Fluent:CreateWindow({Title = "Catalyst v2.3.8", SubTitle = "MM2", TabWidth = 160, Size = UDim2.fromOffset(580, 460), Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl})
local Tabs = {Main = Window:AddTab({ Title = "Combat", Icon = "crosshair" }), Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }), Misc = Window:AddTab({ Title = "Misc", Icon = "star" }), Home = Window:AddTab({ Title = "Home", Icon = "house" }), Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })}
local Options = Fluent.Options
-- ТАБ 0: HOME (TAB: 1)
    Tabs.Home:AddParagraph({
        Title = "Welcome to Catalyst!",
        Content = "Rank:" .. tostring(_G.CatalystKeyType) .. "/nMurder Mystery 2 /nHappy Exploiting!"
     })
-- ТАБ 1: COMBAT
Tabs.Main:AddSection("Rage Aimbot Settings")
local ToggleAim = Tabs.Main:AddToggle("MyToggle", {Title = "Enable Aimbot", Default = false})
local TogglePred = Tabs.Main:AddToggle("Prediction", {Title = "Enable Prediction", Default = false}) -- ПРЕДИКТ ТУТ!
local Keybind = Tabs.Main:AddKeybind("Keybind", {Title = "Aimbot Keybind", Mode = "Hold", Default = "MouseRight"})
local Slider = Tabs.Main:AddSlider("Slider", {Title = "Aimbot FOV (Degrees)", Default = 80, Min = 1, Max = 360, Rounding = 0})
local Colorpicker2 = Tabs.Main:AddColorpicker("Colorpicker2", {Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255)})

-- ТАБ 2: VISUALS
Tabs.Visuals:AddSection("Player ESP Settings")
local KillerToggle = Tabs.Visuals:AddToggle("KillerESP", { Title = "Killer ESP (Murderer)", Default = false })
local KillerColor = Tabs.Visuals:AddColorpicker("KillerESPColor", { Title = "Killer ESP Color", Default = Color3.fromRGB(255, 0, 0) })
local SherifToggle = Tabs.Visuals:AddToggle("SherifESP", { Title = "Sherif ESP", Default = false })
local SherifColor = Tabs.Visuals:AddColorpicker("SherifESPColor", { Title = "Sherif ESP Color", Default = Color3.fromRGB(0, 0, 255) })
local InnocentToggle = Tabs.Visuals:AddToggle("InnocentESP", { Title = "Innocent ESP", Default = false })
local InnocentColor = Tabs.Visuals:AddColorpicker("InnocentESPColor", { Title = "Innocent ESP Color", Default = Color3.fromRGB(0, 255, 0) })

-- ТАБ 3: MISC
Tabs.Misc:AddSection("Blatant Exploits & Movement")
local NoclipToggle = Tabs.Misc:AddToggle("Noclip", {Title = "Enable No-Clip", Default = false})
local FlyToggle = Tabs.Misc:AddToggle("Fly", {Title = "Enable Infinite Fly", Default = false})
local SpeedToggle = Tabs.Misc:AddToggle("Speedhack", {Title = "Enable Speedhack", Default = false})
local SpeedSlider = Tabs.Misc:AddSlider("SpeedSlider", {Title = "Speedhack Limit (KM/h)", Default = 50, Min = 16, Max = 250, Rounding = 0})

-- === УЛЬТРА СЖАТЫЙ КОД ПОДКАПОТНОЙ ЛОГИКИ ХАКОВ (С ПРЕДИКТОМ) ===
local function GetRole(p) if not p or not p.Character then return "Innocent" end if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("MurdererEffect") then return "Killer" end if p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun") then return "Sheriff" end local rd = RS:FindFirstChild("RoundView") or RS:FindFirstChild("GameStorage") local ur = rd and rd:FindFirstChild("RoleData") and rd.RoleData:FindFirstChild(p.Name) return ur and (ur.Value == "Murderer" and "Killer" or (ur.Value == "Sheriff" or ur.Value == "Hero") and "Sheriff") or "Innocent" end
local function GetTarg() local b, minA, maxA, mPos, myR, sher = nil, math.huge, (Options.Slider and Options.Slider.Value or 80), UIS:GetMouseLocation(), GetRole(LP), nil if myR == "Innocent" then return nil end for _, p in pairs(Plrs:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then local tR = GetRole(p) local sPos, onS = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position) if onS and (Vector2.new(sPos.X, sPos.Y) - mPos).Magnitude <= (maxA / 360) * Cam.ViewportSize.X then local ang = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.HumanoidRootPart.Position - Cam.CFrame.Position).Unit), -1, 1))) if myR == "Killer" and tR == "Sheriff" and ang < minA then minA, sher = ang, p.Character.HumanoidRootPart elseif myR == "Killer" and tR == "Innocent" and ang < minA then minA, b = ang, p.Character.HumanoidRootPart elseif myR == "Sheriff" and tR == "Killer" and ang < minA then minA, b = ang, p.Character.HumanoidRootPart end end end end return sher or b end
if (typeof(Drawing) == "table" and Drawing.new ~= nil) then FOV = Drawing.new("Circle") FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1 table.insert(CatalystThreads, RunS.RenderStepped:Connect(function() if Options.Slider and Options.Colorpicker2 and Options.MyToggle then FOV.Visible = Options.MyToggle.Value FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X FOV.Color, FOV.Position = Options.Colorpicker2.Value, UIS:GetMouseLocation() else FOV.Visible = false end end)) end

-- АИМБОТ С ПРАВИЛЬНЫМ РАСЧЕТОМ ПРЕДИКТА (УПРЕЖДЕНИЯ СКОРОСТИ) ПО ТОРСУ
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function() if not (Options.MyToggle and Options.MyToggle.Value) then return end local pr = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (Options.Keybind and Options.Keybind:GetState()) local t = GetTarg() if pr and t then local pos = t.Position if Options.Prediction and Options.Prediction.Value and t.Parent:FindFirstChild("Humanoid") then pos = pos + (t.Velocity * 0.145) end Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos) end end))
local function UpdateESP(p) if not p or p == LP or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end local r, ex = GetRole(p), p.Character:FindFirstChild("Catalyst_Highlight") if (r == "Killer" and Options.KillerESP.Value) or (r == "Sheriff" and Options.SherifESP.Value) or (r == "Innocent" and Options.InnocentESP.Value) then local fl = Options[(r == "Sheriff" and "Sherif" or r) .. "ESPColor"].Value local h, s, v = fl:ToHSV() local hg = ex or Instance.new("Highlight") hg.Name, hg.FillColor, hg.OutlineColor, hg.FillTransparency, hg.OutlineTransparency, hg.Parent = "Catalyst_Highlight", fl, Color3.fromHSV(h, s, math.clamp(v * 0.4, 0, 1)), 0.4, 0, p.Character else if ex then ex:Destroy() end end end
local function RefreshESP() ClearESP() for _, p in pairs(Plrs:GetPlayers()) do if p.Character then UpdateESP(p) end end end
table.insert(CatalystThreads, task.spawn(function() while task.wait(0.3) do pcall(function() if Options.KillerESP and (Options.KillerESP.Value or Options.SherifESP.Value or Options.InnocentESP.Value) then for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end else ClearESP() end end) end end))
table.insert(CatalystThreads, Plrs.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(0.5) pcall(UpdateESP, p) end) end))
KillerToggle:OnChanged(RefreshESP) KillerColor:OnChanged(RefreshESP) SherifToggle:OnChanged(RefreshESP) SherifColor:OnChanged(RefreshESP) InnocentToggle:OnChanged(RefreshESP) InnocentColor:OnChanged(RefreshESP)

table.insert(CatalystThreads, RunS.RenderStepped:Connect(function() if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character:FindFirstChild("HumanoidRootPart") then local char, root, hum = LP.Character, LP.Character.HumanoidRootPart, LP.Character.Humanoid if Options.Speedhack and Options.Speedhack.Value then hum.WalkSpeed = Options.SpeedSlider and Options.SpeedSlider.Value or 50 else hum.WalkSpeed = 16 end if Options.Noclip and Options.Noclip.Value then for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false if Options.Fly and Options.Fly.Value and part.Name == "HumanoidRootPart" then part.CanCollide = false end end end end if Options.Fly and Options.Fly.Value then if UIS:IsKeyDown(Enum.KeyCode.Space) then root.Velocity = Vector3.new(root.Velocity.X, 60, root.Velocity.Z) elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then root.Velocity = Vector3.new(root.Velocity.X, -60, root.Velocity.Z) else root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z) end end end end))
table.insert(CatalystThreads, UIS.JumpRequest:Connect(function() if Options.Fly and Options.Fly.Value and LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end end))

SaveManager:SetLibrary(Fluent) InterfaceManager:SetLibrary(Fluent) SaveManager:IgnoreThemeSettings() InterfaceManager:SetFolder("Catalyst") SaveManager:SetFolder("Catalyst/MM2")
InterfaceManager:BuildInterfaceSection(Tabs.Settings) SaveManager:BuildConfigSection(Tabs.Settings) SaveManager:LoadAutoloadConfig() Window:SelectTab(1)
