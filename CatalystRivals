local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera
local CatalystThreads = {}
local function ClearESP() for _, p in pairs(Plrs:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Catalyst_Highlight") then p.Character.Catalyst_Highlight:Destroy() end end end

-- 🔥 АВТО-ЗАГРУЗКА БИБЛИОТЕК С GITHUB
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- 📦 ОДНОСТРОЧНЫЙ ИНТЕРФЕЙС (МЕНЯЙ НАЗВАНИЯ В КАВЫЧКАХ ТУТ ➡️)
local Window = Fluent:CreateWindow({Title = "Catalyst v2.4.2", SubTitle = "Rivals", TabWidth = 160, Size = UDim2.fromOffset(580, 460), Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl})
local Tabs = {Main = Window:AddTab({ Title = "Combat", Icon = "crosshair" }), Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }), Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })}
local Options = Fluent.Options

-- ТАБ 1: COMBAT (ОДИН ЭЛЕМЕНТ - ОДНА СТРОКА)
Tabs.Main:AddSection("Legit Aimbot Settings")
local ToggleAim = Tabs.Main:AddToggle("MyToggle", {Title = "Enable AimAssist", Default = false})
local TogglePred = Tabs.Main:AddToggle("Prediction", {Title = "Enable Projectile Prediction", Default = false})
local Keybind = Tabs.Main:AddKeybind("Keybind", {Title = "Aimbot Keybind", Mode = "Hold", Default = "Q"})
local Slider = Tabs.Main:AddSlider("Slider", {Title = "Aim FOV Radius", Default = 80, Min = 1, Max = 180, Rounding = 0})
local Colorpicker2 = Tabs.Main:AddColorpicker("Colorpicker2", {Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255)})

-- ТАБ 2: VISUALS (ОДИН ЭЛЕМЕНТ - ОДНА СТРОКА)
Tabs.Visuals:AddSection("Rivals Wallhack")
local EnemyToggle = Tabs.Visuals:AddToggle("EnemyESP", { Title = "Enable Enemy ESP", Default = false })
local EnemyColor = Tabs.Visuals:AddColorpicker("EnemyESPColor", { Title = "ESP Color", Default = Color3.fromRGB(255, 0, 0) })
local ShakeToggle = Tabs.Visuals:AddToggle("NoShake", { Title = "Enable No-Shake", Default = false })

-- === СКРИПТЫ ПОДКАПОТНОЙ МАТЕМАТИКИ И ХУКОВ (MOUSEMOVEREL FIX) ===
local function IsEnemy(p) if not p or p == LP then return false end if p:FindFirstChild("Team") and LP:FindFirstChild("Team") then return p.Team.Value ~= LP.Team.Value end if LP.Team and p.Team then return LP.Team ~= p.Team end return true end

-- Поиск цели и расчет финальной точки на экране с Предиктом
local function GetRivalsTargetPos()
    local bestPos, minDistance, maxA, mousePos = nil, math.huge, (Options.Slider and Options.Slider.Value or 60), UIS:GetMouseLocation()
    for _, p in pairs(Plrs:GetPlayers()) do
        if IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local root = p.Character.HumanoidRootPart
            local targetWorldPos = root.Position + Vector3.new(0, 1.2, 0) -- Математическое смещение в область груди
            
            -- Применяем киберспортивное упреждение под скорость снаряда в Rivals
            if Options.Prediction and Options.Prediction.Value then
                targetWorldPos = targetWorldPos + (root.Velocity * 0.135)
            end
            
            local screenPos, onScreen = Cam:WorldToViewportPoint(targetWorldPos)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance <= (maxA / 360) * Cam.ViewportSize.X and distance < minDistance then
                    minDistance, bestPos = distance, Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        end
    end
    return bestPos
end

if (typeof(Drawing) == "table" and Drawing.new ~= nil) then FOV = Drawing.new("Circle") FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1 table.insert(CatalystThreads, RunS.RenderStepped:Connect(function() if Options.Slider and Options.Colorpicker2 and Options.MyToggle then FOV.Visible = Options.MyToggle.Value FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X FOV.Color, FOV.Position = Options.Colorpicker2.Value, UIS:GetMouseLocation() else FOV.Visible = false end end)) end

-- 🔥 НЕУЯЗВИМЫЙ ХУК НАВОДКИ ЧЕРЕЗ СИМУЛЯЦИЮ МЫШИ (MOUSEMOVEREL)
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    if not (Options.MyToggle and Options.MyToggle.Value) then return end
    local pressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (Options.Keybind and Options.Keybind:GetState())
    local targetScreenPos = GetRivalsTargetPos()
    
    if pressed and targetScreenPos then
        local mousePos = UIS:GetMouseLocation()
        -- Вычисляем расстояние, на которое нужно физически сдвинуть мышь в пикселях
        local moveX = (targetScreenPos.X - mousePos.X) * 0.35 -- 0.35 - сглаживание доводки (меньше - плавнее)
        local moveY = (targetScreenPos.Y - mousePos.Y) * 0.35
        
        -- Физический сдвиг курсора силами Xeno/Delta (Обходит любые блокировки камеры!)
        if mousemoverel then
            mousemoverel(moveX, moveY)
        end
    end
end))

local function UpdateESP(p) if not p or not IsEnemy(p) or not p.Character then return end local ex = p.Character:FindFirstChild("Catalyst_Highlight") if Options.EnemyESP and Options.EnemyESP.Value and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then local fl = Options.EnemyESPColor.Value local h, s, v = fl:ToHSV() local hg = ex or Instance.new("Highlight") hg.Name, hg.FillColor, hg.OutlineColor, hg.FillTransparency, hg.OutlineTransparency, hg.Parent = "Catalyst_Highlight", fl, Color3.fromHSV(h, s, math.clamp(v * 0.4, 0, 1)), 0.4, 0, p.Character else if ex then ex:Destroy() end end end
local function RefreshESP() ClearESP() for _, p in pairs(Plrs:GetPlayers()) do if p.Character then UpdateESP(p) end end end
table.insert(CatalystThreads, task.spawn(function() while task.wait(0.3) do pcall(function() if Options.EnemyESP and Options.EnemyESP.Value then for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end else ClearESP() end end) end end))
table.insert(CatalystThreads, Plrs.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(0.5) pcall(UpdateESP, p) end) end))
EnemyToggle:OnChanged(RefreshESP) EnemyColor:OnChanged(RefreshESP)

table.insert(CatalystThreads, RunS.RenderStepped:Connect(function() pcall(function() if Options.NoShake and Options.NoShake.Value and LP.PlayerGui:FindFirstChild("CameraShake") then LP.PlayerGui.CameraShake:Destroy() end end) end))

SaveManager:SetLibrary(Fluent) InterfaceManager:SetLibrary(Fluent) SaveManager:IgnoreThemeSettings() InterfaceManager:SetFolder("Catalyst") SaveManager:SetFolder("Catalyst/Rivals")
InterfaceManager:BuildInterfaceSection(Tabs.Settings) SaveManager:BuildConfigSection(Tabs.Settings) SaveManager:LoadAutoloadConfig() Window:SelectTab(1)
