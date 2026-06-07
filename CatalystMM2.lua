-- ========================================================
-- 📦 ОБЪЯВЛЕНИЕ СЕРВИСОВ И ПЕРЕМЕННЫХ
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera
local CatalystThreads = {}

-- 🔥 АВТО-ЗАГРУЗКА БИБЛИОТЕК С GITHUB
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ========================================================
-- 🏆 ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ (устанавливаются хабом)
-- ========================================================
_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"

-- ========================================================
-- 📝 ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ========================================================
local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    if p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) or p.Character:FindFirstChild("MurdererEffect") then return "Killer" end
    if p.Character:FindFirstChild("Gun") or (p.Backpack and p.Backpack:FindFirstChild("Gun")) then return "Sheriff" end
    local rd = RS:FindFirstChild("RoundView") or RS:FindFirstChild("GameStorage")
    local ur = rd and rd:FindFirstChild("RoleData") and rd.RoleData:FindFirstChild(p.Name)
    if ur then
        if ur.Value == "Murderer" then return "Killer"
        elseif ur.Value == "Sheriff" or ur.Value == "Hero" then return "Sheriff" end
    end
    return "Innocent"
end

local function ClearESP()
    for _, p in pairs(Plrs:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Catalyst_Highlight") then
            p.Character.Catalyst_Highlight:Destroy()
        end
    end
end

-- ========================================================
-- 🖥️ СОЗДАНИЕ ОКНА И ВКЛАДОК (FLUENT)
-- ========================================================
local Window = Fluent:CreateWindow({
    Title = "Catalyst v2.4.0",
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 500),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "star" }),
    Home = Window:AddTab({ Title = "Home", Icon = "house" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ========================================================
-- 🏠 HOME TAB (ИНФОРМАЦИЯ)
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
Tabs.Home:AddSection("Version 2.4.0")
Tabs.Home:AddParagraph({
    Title = "Changelog",
    Content = "• Added Name ESP toggle\n• Added GunDrop highlight & TP\n• Fixed Home tab display"
})

-- ========================================================
-- ⚔️ COMBAT TAB
-- ========================================================
Tabs.Combat:AddSection("Rage Aimbot Settings")
local ToggleAim = Tabs.Combat:AddToggle("MyToggle", { Title = "Enable Aimbot", Default = false })
local TogglePred = Tabs.Combat:AddToggle("Prediction", { Title = "Enable Prediction", Default = false })
local Keybind = Tabs.Combat:AddKeybind("Keybind", { Title = "Aimbot Keybind", Mode = "Hold", Default = "MouseRight" })
local Slider = Tabs.Combat:AddSlider("Slider", { Title = "Aimbot FOV (Degrees)", Default = 80, Min = 1, Max = 360, Rounding = 0 })
local Colorpicker2 = Tabs.Combat:AddColorpicker("Colorpicker2", { Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255) })

Tabs.Combat:AddSection("Gun Drop Teleport")
local TPGunDrop = Tabs.Combat:AddButton({
    Title = "TP to Gun Drop (once)",
    Callback = function() TeleportToGunDrop(true) end
})
local AutoTPGunDrop = Tabs.Combat:AddToggle("AutoTPGunDrop", { Title = "Auto TP to Gun Drop (every 1s)", Default = false })

-- ========================================================
-- 👁️ VISUALS TAB
-- ========================================================
Tabs.Visuals:AddSection("Player ESP Settings")
local KillerToggle = Tabs.Visuals:AddToggle("KillerESP", { Title = "Killer ESP (Murderer)", Default = false })
local KillerColor = Tabs.Visuals:AddColorpicker("KillerESPColor", { Title = "Killer ESP Color", Default = Color3.fromRGB(255, 0, 0) })
local SherifToggle = Tabs.Visuals:AddToggle("SherifESP", { Title = "Sheriff ESP", Default = false })
local SherifColor = Tabs.Visuals:AddColorpicker("SherifESPColor", { Title = "Sheriff ESP Color", Default = Color3.fromRGB(0, 0, 255) })
local InnocentToggle = Tabs.Visuals:AddToggle("InnocentESP", { Title = "Innocent ESP", Default = false })
local InnocentColor = Tabs.Visuals:AddColorpicker("InnocentESPColor", { Title = "Innocent ESP Color", Default = Color3.fromRGB(0, 255, 0) })

-- NEW: Name ESP
local NameESPToggle = Tabs.Visuals:AddToggle("NameESP", { Title = "Show Names ESP", Default = false })
local NameESPColor = Tabs.Visuals:AddColorpicker("NameESPColor", { Title = "Name Text Color", Default = Color3.fromRGB(255, 255, 255) })

Tabs.Visuals:AddSection("World ESP")
local HighlightGunDrop = Tabs.Visuals:AddToggle("HighlightGunDrop", { Title = "Highlight Gun Drop", Default = false })
local GunDropColor = Tabs.Visuals:AddColorpicker("GunDropColor", { Title = "Gun Drop Highlight Color", Default = Color3.fromRGB(128, 0, 255) })

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

local function FindGunDrop()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name and obj.Name:lower():find("gundrop") and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

local function UpdateGunDropHighlight()
    if HighlightGunDrop and HighlightGunDrop.Value then
        local gd = FindGunDrop()
        if gd then
            if not GunDropHighlight or GunDropHighlight.Parent ~= gd then
                if GunDropHighlight then GunDropHighlight:Destroy() end
                GunDropHighlight = Instance.new("Highlight")
                GunDropHighlight.FillColor = GunDropColor and GunDropColor.Value or Color3.fromRGB(128,0,255)
                GunDropHighlight.OutlineColor = Color3.fromRGB(255,255,255)
                GunDropHighlight.FillTransparency = 0.5
                GunDropHighlight.OutlineTransparency = 0
                GunDropHighlight.Parent = gd
            end
            GunDropPart = gd
        else
            if GunDropHighlight then GunDropHighlight:Destroy(); GunDropHighlight = nil end
            GunDropPart = nil
        end
    else
        if GunDropHighlight then GunDropHighlight:Destroy(); GunDropHighlight = nil end
        GunDropPart = nil
    end
end

-- Периодическое обновление подсветки
table.insert(CatalystThreads, task.spawn(function()
    while task.wait(1) do
        pcall(UpdateGunDropHighlight)
    end
end))

-- Реакция на изменение настроек подсветки
HighlightGunDrop:OnChanged(UpdateGunDropHighlight)
GunDropColor:OnChanged(UpdateGunDropHighlight)

-- ========================================================
-- 🚀 ТЕЛЕПОРТ К GUN DROP
-- ========================================================
local function TeleportToGunDrop(returnBack)
    local character = LP.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local gd = FindGunDrop()
    if not gd then
        Fluent:Notify({ Title = "Gun Drop", Content = "No GunDrop found!", Duration = 2 })
        return
    end
    local originalPos = hrp.CFrame
    hrp.CFrame = gd.CFrame * CFrame.new(0, 2, 0) -- чуть выше
    if returnBack then
        task.wait(0.1)
        if hrp and hrp.Parent then
            hrp.CFrame = originalPos
        end
    end
end

-- Авто-телепорт каждую секунду
table.insert(CatalystThreads, task.spawn(function()
    while true do
        task.wait(1)
        if AutoTPGunDrop and AutoTPGunDrop.Value then
            pcall(TeleportToGunDrop, true)
        end
    end
end))

-- ========================================================
-- 🎯 AIMBOT (ОСТАЁТСЯ БЕЗ ИЗМЕНЕНИЙ, ТОЛЬКО ПРОВЕРКА)
-- ========================================================
local function GetTarget()
    local best, minAngle, maxAngle = nil, math.huge, (Options.Slider and Options.Slider.Value or 80)
    local mousePos = UIS:GetMouseLocation()
    local myRole = GetRole(LP)
    if myRole == "Innocent" then return nil end
    local sheriffTarget = nil
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local tRole = GetRole(p)
            local screenPos, onScreen = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local maxDist = (maxAngle / 360) * Cam.ViewportSize.X
                if dist <= maxDist then
                    local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.HumanoidRootPart.Position - Cam.CFrame.Position).Unit), -1, 1)))
                    if myRole == "Killer" and tRole == "Sheriff" and angle < minAngle then
                        minAngle, sheriffTarget = angle, p.Character.HumanoidRootPart
                    elseif myRole == "Killer" and tRole == "Innocent" and angle < minAngle then
                        minAngle, best = angle, p.Character.HumanoidRootPart
                    elseif myRole == "Sheriff" and tRole == "Killer" and angle < minAngle then
                        minAngle, best = angle, p.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return sheriffTarget or best
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

-- Aimbot
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    if not (Options.MyToggle and Options.MyToggle.Value) then return end
    local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (Options.Keybind and Options.Keybind:GetState())
    local target = GetTarget()
    if press and target then
        local pos = target.Position
        if Options.Prediction and Options.Prediction.Value and target.Parent:FindFirstChild("Humanoid") then
            pos = pos + (target.Velocity * 0.145)
        end
        Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
    end
end))

-- ========================================================
-- 👥 ESP (HIGHLIGHT + ИМЕНА)
-- ========================================================
-- Игровые ESP (подсветка)
local function UpdateESP(p)
    if not p or p == LP or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end
    local role = GetRole(p)
    local highlight = p.Character:FindFirstChild("Catalyst_Highlight")
    local shouldShow = false
    local color = Color3.new(1,1,1)
    if role == "Killer" and Options.KillerESP and Options.KillerESP.Value then
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

-- Name ESP (текст над головами)
local NameTextObjects = {}
local function ClearNameESP()
    for _, text in pairs(NameTextObjects) do
        if text and text.Remove then text:Remove() end
    end
    NameTextObjects = {}
end

local function UpdateNameESP()
    if not (Options.NameESP and Options.NameESP.Value) then
        ClearNameESP()
        return
    end
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
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
                text.Text = p.Name .. " (" .. GetRole(p) .. ")"
                text.Position = Vector2.new(vec.X, vec.Y)
                text.Color = Options.NameESPColor and Options.NameESPColor.Value or Color3.fromRGB(255,255,255)
                text.Visible = true
            else
                if NameTextObjects[p] then NameTextObjects[p].Visible = false end
            end
        else
            if NameTextObjects[p] then NameTextObjects[p].Visible = false end
        end
    end
end

-- Обновление всех ESP (высокая частота для имён)
table.insert(CatalystThreads, RunS.RenderStepped:Connect(function()
    pcall(UpdateNameESP)
end))

-- Обновление подсветки по таймеру
table.insert(CatalystThreads, task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            for _, p in pairs(Plrs:GetPlayers()) do
                UpdateESP(p)
            end
        end)
    end
end))

-- События добавления игроков
table.insert(CatalystThreads, Plrs.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(UpdateESP, p)
    end)
end))

-- Реакция на изменения настроек ESP
KillerToggle:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
KillerColor:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
SherifToggle:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
SherifColor:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
InnocentToggle:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
InnocentColor:OnChanged(function() for _, p in pairs(Plrs:GetPlayers()) do UpdateESP(p) end end)
NameESPToggle:OnChanged(ClearNameESP)

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
Window:SelectTab(1)

-- Очистка при выгрузке
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    ClearNameESP()
    for _, text in pairs(NameTextObjects) do if text then pcall(text.Remove, text) end end
    NameTextObjects = {}
end)
