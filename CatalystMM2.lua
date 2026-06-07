-- ========================================================
-- 📦 ОБЪЯВЛЕНИЕ СЕРВИСОВ И ПЕРЕМЕННЫХ
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera
local CatalystThreads = {}

-- 🔥 АВТО-ЗАГРУЗКА БИБЛИОТЕК
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ========================================================
-- 🏆 ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ========================================================
_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"

-- ========================================================
-- 📝 ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ========================================================
local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    if p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) or p.Character:FindFirstChild("MurdererEffect") then return "Murderer" end
    if p.Character:FindFirstChild("Gun") or (p.Backpack and p.Backpack:FindFirstChild("Gun")) then return "Sheriff" end
    local rd = RS:FindFirstChild("RoundView") or RS:FindFirstChild("GameStorage")
    local ur = rd and rd:FindFirstChild("RoleData") and rd.RoleData:FindFirstChild(p.Name)
    if ur then
        if ur.Value == "Murderer" then return "Murderer"
        elseif ur.Value == "Sheriff" or ur.Value == "Hero" then return "Sheriff" end
    end
    return "Innocent"
end

local function HasRevolver()
    local char = LP.Character
    if not char then return false end
    return char:FindFirstChild("Revolver") ~= nil
end

-- ========================================================
-- 🖥️ СОЗДАНИЕ ОКНА И ВКЛАДОК
-- ========================================================
local Window = Fluent:CreateWindow({
    Title = "Catalyst v2.5.0",
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 540),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "house" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "star" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ========================================================
-- 🏠 HOME TAB (ПЕРВАЯ)
-- ========================================================
local rankText = (_G.CatalystKeyType or "Unknown") .. " / " .. (_G.CatalystRank or "Standard")
Tabs.Home:AddParagraph({
    Title = "Welcome to Catalyst!",
    Content = "Rank: " .. rankText .. "\nGame: Murder Mystery 2\nDeveloper: Alchemist Slime\nTG: @alchemistslimee"
})
Tabs.Home:AddButton({
    Title = "📋 Copy Discord Tag",
    Callback = function()
        setclipboard("alchemistslimee")
        Fluent:Notify({ Title = "Copied!", Content = "Discord tag: alchemistslimee", Duration = 2 })
    end
})
Tabs.Home:AddSection("Version 2.5.0")
Tabs.Home:AddParagraph({
    Title = "Changelog",
    Content = "• Added separate text ESP for each role\n• Added Gun Drop text ESP\n• Added Prediction Delay slider\n• Added Safe TP (avoid Murderer)\n• Added TP cooldown (3 sec)\n• Auto-disable TP when Revolver equipped"
})

-- ========================================================
-- ⚔️ COMBAT TAB
-- ========================================================
Tabs.Combat:AddSection("Rage Aimbot Settings")
local ToggleAim = Tabs.Combat:AddToggle("MyToggle", { Title = "Enable Aimbot", Default = false })
local TogglePred = Tabs.Combat:AddToggle("Prediction", { Title = "Enable Prediction", Default = false })
local PredDelay = Tabs.Combat:AddSlider("PredictionDelay", { Title = "Prediction Delay (ms)", Default = 80, Min = 0, Max = 100, Rounding = 0 })
local Keybind = Tabs.Combat:AddKeybind("Keybind", { Title = "Aimbot Keybind", Mode = "Hold", Default = "MouseRight" })
local Slider = Tabs.Combat:AddSlider("Slider", { Title = "Aimbot FOV (Degrees)", Default = 80, Min = 1, Max = 360, Rounding = 0 })
local Colorpicker2 = Tabs.Combat:AddColorpicker("Colorpicker2", { Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255) })

Tabs.Combat:AddSection("Gun Drop Teleport")
local TPGunDrop = Tabs.Combat:AddButton({
    Title = "TP to Gun Drop (once)",
    Callback = function() TeleportToGunDrop(true) end
})
local AutoTPGunDrop = Tabs.Combat:AddToggle("AutoTPGunDrop", { Title = "Auto TP to Gun Drop (every 1s)", Default = false })
local SafeTPToggle = Tabs.Combat:AddToggle("SafeTP", { Title = "Safe TP (avoid Murderer within 5 studs)", Default = true })
local CooldownInfo = Tabs.Combat:AddParagraph({ Title = "Cooldown", Content = "Ready" })

-- ========================================================
-- 👁️ VISUALS TAB
-- ========================================================
Tabs.Visuals:AddSection("Player Highlight ESP")
local MurdererESP = Tabs.Visuals:AddToggle("KillerESP", { Title = "Highlight Murderer", Default = false })
local MurdererColor = Tabs.Visuals:AddColorpicker("KillerESPColor", { Title = "Murderer Color", Default = Color3.fromRGB(255, 0, 0) })
local SheriffESP = Tabs.Visuals:AddToggle("SherifESP", { Title = "Highlight Sheriff", Default = false })
local SheriffColor = Tabs.Visuals:AddColorpicker("SherifESPColor", { Title = "Sheriff Color", Default = Color3.fromRGB(0, 0, 255) })
local InnocentESP = Tabs.Visuals:AddToggle("InnocentESP", { Title = "Highlight Innocent", Default = false })
local InnocentColor = Tabs.Visuals:AddColorpicker("InnocentESPColor", { Title = "Innocent Color", Default = Color3.fromRGB(0, 255, 0) })

Tabs.Visuals:AddSection("Player Name ESP (Text)")
local MurdererTextESP = Tabs.Visuals:AddToggle("MurdererTextESP", { Title = "Show Murderer Names", Default = true })
local MurdererTextColor = Tabs.Visuals:AddColorpicker("MurdererTextColor", { Title = "Murderer Name Color", Default = Color3.fromRGB(255, 0, 0) })
local SheriffTextESP = Tabs.Visuals:AddToggle("SheriffTextESP", { Title = "Show Sheriff Names", Default = true })
local SheriffTextColor = Tabs.Visuals:AddColorpicker("SheriffTextColor", { Title = "Sheriff Name Color", Default = Color3.fromRGB(0, 0, 255) })
local InnocentTextESP = Tabs.Visuals:AddToggle("InnocentTextESP", { Title = "Show Innocent Names", Default = false })
local InnocentTextColor = Tabs.Visuals:AddColorpicker("InnocentTextColor", { Title = "Innocent Name Color", Default = Color3.fromRGB(0, 255, 0) })

Tabs.Visuals:AddSection("Gun Drop ESP")
local HighlightGunDrop = Tabs.Visuals:AddToggle("HighlightGunDrop", { Title = "Highlight Gun Drop", Default = false })
local GunDropColor = Tabs.Visuals:AddColorpicker("GunDropColor", { Title = "Gun Drop Highlight Color", Default = Color3.fromRGB(128, 0, 255) })
local GunDropTextToggle = Tabs.Visuals:AddToggle("GunDropTextESP", { Title = "Show Gun Drop Text", Default = true })
local GunDropTextColor = Tabs.Visuals:AddColorpicker("GunDropTextColor", { Title = "Gun Drop Text Color", Default = Color3.fromRGB(255, 255, 255) })

-- ========================================================
-- 🛠️ MISC TAB
-- ========================================================
Tabs.Misc:AddSection("Blatant Exploits & Movement")
local NoclipToggle = Tabs.Misc:AddToggle("Noclip", { Title = "Enable No-Clip", Default = false })
local FlyToggle = Tabs.Misc:AddToggle("Fly", { Title = "Enable Infinite Fly", Default = false })
local SpeedToggle = Tabs.Misc:AddToggle("Speedhack", { Title = "Enable Speedhack", Default = false })
local SpeedSlider = Tabs.Misc:AddSlider("SpeedSlider", { Title = "Speedhack Limit (KM/h)", Default = 50, Min = 16, Max = 250, Rounding = 0 })

-- ========================================================
-- 🔫 GUN DROP ПОИСК И ПОДСВЕТКА
-- ========================================================
local GunDropPart = nil
local GunDropHighlight = nil
local GunDropTextObj = nil
local LastTPTime = 0
local TPBlocked = false

local function FindGunDrop()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name and obj.Name:lower():find("gundrop") and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

local function UpdateGunDropVisuals()
    if HasRevolver() then
        if GunDropHighlight then GunDropHighlight:Destroy(); GunDropHighlight = nil end
        if GunDropTextObj then GunDropTextObj:Remove(); GunDropTextObj = nil end
        GunDropPart = nil
        return
    end
    local gd = FindGunDrop()
    GunDropPart = gd
    if gd then
        if HighlightGunDrop and HighlightGunDrop.Value then
            if not GunDropHighlight or GunDropHighlight.Parent ~= gd then
                if GunDropHighlight then GunDropHighlight:Destroy() end
                GunDropHighlight = Instance.new("Highlight")
                GunDropHighlight.FillColor = GunDropColor and GunDropColor.Value or Color3.fromRGB(128,0,255)
                GunDropHighlight.OutlineColor = Color3.fromRGB(255,255,255)
                GunDropHighlight.FillTransparency = 0.4
                GunDropHighlight.OutlineTransparency = 0
                GunDropHighlight.Parent = gd
            end
        elseif GunDropHighlight then
            GunDropHighlight:Destroy(); GunDropHighlight = nil
        end
        if GunDropTextToggle and GunDropTextToggle.Value then
            if not GunDropTextObj then
                GunDropTextObj = Drawing.new("Text")
                GunDropTextObj.Center = true
                GunDropTextObj.Outline = true
                GunDropTextObj.Size = 16
            end
            local pos, onScreen = Cam:WorldToViewportPoint(gd.Position + Vector3.new(0, 1.5, 0))
            if onScreen then
                GunDropTextObj.Position = Vector2.new(pos.X, pos.Y)
                GunDropTextObj.Text = "🔫 GUN DROP"
                GunDropTextObj.Color = GunDropTextColor and GunDropTextColor.Value or Color3.fromRGB(255,255,255)
                GunDropTextObj.Visible = true
            else
                GunDropTextObj.Visible = false
            end
        else
            if GunDropTextObj then GunDropTextObj.Visible = false end
        end
    else
        if GunDropHighlight then GunDropHighlight:Destroy(); GunDropHighlight = nil end
        if GunDropTextObj then GunDropTextObj:Remove(); GunDropTextObj = nil end
    end
end

-- Периодическое обновление (каждые 0.2 сек для текста)
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    pcall(UpdateGunDropVisuals)
end))

-- Обновление подсветки при изменении настроек
HighlightGunDrop:OnChanged(UpdateGunDropVisuals)
GunDropColor:OnChanged(UpdateGunDropVisuals)
GunDropTextToggle:OnChanged(UpdateGunDropVisuals)
GunDropTextColor:OnChanged(UpdateGunDropVisuals)

-- ========================================================
-- 🚀 ТЕЛЕПОРТ К GUN DROP (С ЗАЩИТАМИ)
-- ========================================================
local function IsMurdererNearby(radius)
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and GetRole(p) == "Murderer" then
            local dist = (p.Character.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude
            if dist <= radius then return true end
        end
    end
    return false
end

function TeleportToGunDrop(returnBack)
    local now = tick()
    if TPBlocked then
        CooldownInfo:SetContent("Cooldown: " .. math.ceil(3 - (now - LastTPTime)) .. "s left")
        return false
    end
    if HasRevolver() then return false end
    local gd = FindGunDrop()
    if not gd then return false end
    if SafeTPToggle and SafeTPToggle.Value and IsMurdererNearby(5) then
        Fluent:Notify({ Title = "Safe TP", Content = "Murderer nearby, teleport blocked", Duration = 1.5 })
        return false
    end
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local originalPos = hrp.CFrame
    hrp.CFrame = gd.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.1)
    if returnBack and hrp and hrp.Parent then
        hrp.CFrame = originalPos
    end
    -- Успешный телепорт
    LastTPTime = now
    TPBlocked = true
    CooldownInfo:SetContent("Cooldown: 3s")
    task.wait(3)
    TPBlocked = false
    CooldownInfo:SetContent("Ready")
    return true
end

-- Авто-телепорт каждую секунду (с учётом блокировки и наличия револьвера)
table.insert(CatalystThreads, task.spawn(function()
    while true do
        task.wait(1)
        if AutoTPGunDrop and AutoTPGunDrop.Value and not TPBlocked and not HasRevolver() then
            pcall(TeleportToGunDrop, true)
        end
    end
end))

-- ========================================================
-- 🎯 AIMBOT (С ПРЕДИКТОМ И ЗАДЕРЖКОЙ)
-- ========================================================
local function GetTarget()
    local best, minAngle, maxAngle = nil, math.huge, (Options.Slider and Options.Slider.Value or 80)
    local mousePos = UIS:GetMouseLocation()
    local myRole = GetRole(LP)
    if myRole == "Innocent" then return nil end
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local tRole = GetRole(p)
            local screenPos, onScreen = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local maxDist = (maxAngle / 360) * Cam.ViewportSize.X
                if dist <= maxDist then
                    local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.HumanoidRootPart.Position - Cam.CFrame.Position).Unit), -1, 1)))
                    if myRole == "Murderer" and tRole == "Sheriff" and angle < minAngle then
                        minAngle, best = angle, p.Character.HumanoidRootPart
                    elseif myRole == "Murderer" and tRole == "Innocent" and angle < minAngle then
                        minAngle, best = angle, p.Character.HumanoidRootPart
                    elseif myRole == "Sheriff" and tRole == "Murderer" and angle < minAngle then
                        minAngle, best = angle, p.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return best
end

-- FOV Circle
if (typeof(Drawing) == "table" and Drawing.new ~= nil) then
    local FOV = Drawing.new("Circle")
    FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1
    table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
        if Options.Slider and Options.Colorpicker2 and Options.MyToggle then
            FOV.Visible = Options.MyToggle.Value
            FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X
            FOV.Color = Options.Colorpicker2.Value
            FOV.Position = UIS:GetMouseLocation()
        else
            FOV.Visible = false
        end
    end))
end

-- Aimbot с задержкой предсказания
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    if not (Options.MyToggle and Options.MyToggle.Value) then return end
    local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (Options.Keybind and Options.Keybind:GetState())
    local target = GetTarget()
    if press and target then
        local pos = target.Position
        if Options.Prediction and Options.Prediction.Value and target.Parent:FindFirstChild("Humanoid") then
            local delay = (Options.PredictionDelay and Options.PredictionDelay.Value or 80) / 1000
            pos = pos + (target.Velocity * delay)
        end
        Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
    end
end))

-- ========================================================
-- 👥 ESP (HIGHLIGHT + ИМЕНА)
-- ========================================================
-- Подсветка модельки
local function UpdateHighlight(p)
    if not p or p == LP or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end
    local role = GetRole(p)
    local highlight = p.Character:FindFirstChild("Catalyst_Highlight")
    local shouldShow = false
    local color = Color3.new(1,1,1)
    if role == "Murderer" and Options.KillerESP and Options.KillerESP.Value then
        shouldShow = true
        color = Options.KillerESPColor and Options.KillerESPColor.Value or Color3.fromRGB(255,0,0)
    elseif role == "Sheriff" and Options.SherifESP and Options.SherifESP.Value then
        shouldShow = true
        color = Options.SherifESPColor and Options.SherifESPColor.Value or Color3.fromRGB(0,0,255)
    elseif role == "Innocent" and Options.InnocentESP and Options.InnocentESP.Value then
        shouldShow = true
        color = Options.InnocentESPColor and Options.InnocentESPColor.Value or Color3.fromRGB(0,255,0)
    end
    if shouldShow then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "Catalyst_Highlight"
            highlight.Parent = p.Character
        end
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
    else
        if highlight then highlight:Destroy() end
    end
end

-- Текстовый ESP (имена)
local NameTextObjects = {}
local function ClearNameESP()
    for _, text in pairs(NameTextObjects) do
        if text and text.Remove then text:Remove() end
    end
    NameTextObjects = {}
end

local function UpdateNameESP()
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local role = GetRole(p)
            local show = false
            local color = Color3.new(1,1,1)
            if role == "Murderer" and Options.MurdererTextESP and Options.MurdererTextESP.Value then
                show = true
                color = Options.MurdererTextColor and Options.MurdererTextColor.Value or Color3.fromRGB(255,0,0)
            elseif role == "Sheriff" and Options.SheriffTextESP and Options.SheriffTextESP.Value then
                show = true
                color = Options.SheriffTextColor and Options.SheriffTextColor.Value or Color3.fromRGB(0,0,255)
            elseif role == "Innocent" and Options.InnocentTextESP and Options.InnocentTextESP.Value then
                show = true
                color = Options.InnocentTextColor and Options.InnocentTextColor.Value or Color3.fromRGB(0,255,0)
            end
            if show then
                local root = p.Character.HumanoidRootPart
                local vec, onScreen = Cam:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))
                if onScreen then
                    local text = NameTextObjects[p]
                    if not text then
                        text = Drawing.new("Text")
                        text.Center = true
                        text.Outline = true
                        text.Size = 14
                        NameTextObjects[p] = text
                    end
                    text.Text = p.Name .. " (" .. role .. ")"
                    text.Position = Vector2.new(vec.X, vec.Y)
                    text.Color = color
                    text.Visible = true
                else
                    if NameTextObjects[p] then NameTextObjects[p].Visible = false end
                end
            else
                if NameTextObjects[p] then NameTextObjects[p].Visible = false end
            end
        else
            if NameTextObjects[p] then NameTextObjects[p].Visible = false end
        end
    end
end

-- Обновление имён каждый рендер
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    pcall(UpdateNameESP)
end))

-- Обновление подсветки по таймеру (0.3 сек)
table.insert(CatalystThreads, task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            for _, p in pairs(Plrs:GetPlayers()) do
                UpdateHighlight(p)
            end
        end)
    end
end))

-- Подписка на новых игроков
table.insert(CatalystThreads, Plrs.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(UpdateHighlight, p)
    end)
end))

-- Реакция на изменение настроек подсветки
local function RefreshHighlights()
    for _, p in pairs(Plrs:GetPlayers()) do UpdateHighlight(p) end
end
MurdererESP:OnChanged(RefreshHighlights)
MurdererColor:OnChanged(RefreshHighlights)
SheriffESP:OnChanged(RefreshHighlights)
SheriffColor:OnChanged(RefreshHighlights)
InnocentESP:OnChanged(RefreshHighlights)
InnocentColor:OnChanged(RefreshHighlights)

-- При изменении настроек текста – очищаем объекты, чтобы пересоздать с новым цветом
local function RefreshNameESP()
    ClearNameESP()
end
MurdererTextESP:OnChanged(RefreshNameESP)
MurdererTextColor:OnChanged(RefreshNameESP)
SheriffTextESP:OnChanged(RefreshNameESP)
SheriffTextColor:OnChanged(RefreshNameESP)
InnocentTextESP:OnChanged(RefreshNameESP)
InnocentTextColor:OnChanged(RefreshNameESP)

-- ========================================================
-- 🏃‍♂️ MISC (NOCLIP, FLY, SPEED)
-- ========================================================
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return end
    if Options.Speedhack and Options.Speedhack.Value then
        hum.WalkSpeed = Options.SpeedSlider and Options.SpeedSlider.Value or 50
    else
        hum.WalkSpeed = 16
    end
    if Options.Noclip and Options.Noclip.Value then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if Options.Fly and Options.Fly.Value then
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            root.Velocity = Vector3.new(root.Velocity.X, 60, root.Velocity.Z)
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            root.Velocity = Vector3.new(root.Velocity.X, -60, root.Velocity.Z)
        else
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        end
    end
end))

table.insert(CatalystThreads, UIS.JumpRequest:Connect(function()
    if Options.Fly and Options.Fly.Value and LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
        LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end))

-- ========================================================
-- 💾 SAVE MANAGER
-- ========================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/MM2")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Установка Home первой вкладкой (индекс 1)
Window:SelectTab(1)

-- Очистка при смене персонажа
LP.CharacterAdded:Connect(function()
    ClearNameESP()
    for _, text in pairs(NameTextObjects) do if text then pcall(text.Remove, text) end end
    NameTextObjects = {}
    TPBlocked = false
    LastTPTime = 0
    CooldownInfo:SetContent("Ready")
end)
