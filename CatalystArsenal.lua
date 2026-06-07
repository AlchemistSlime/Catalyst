local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

-- Определяем мобильное устройство
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

-- Загрузка библиотек
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

_G.HighlightAll, _G.FocusNPCHead = false, false

local Window = Fluent:CreateWindow({
    Title = "Catalyst v2.3.0" .. (isMobile and " [Mobile]" or ""),
    SubTitle = "Arsenal",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

local Tabs = {
    Main = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "menu" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ========================================================
-- FOV Circle (только для ПК / при включённом AimAssist)
-- ========================================================
local IsExec = (typeof(Drawing) == "table" and Drawing.new ~= nil)
local FOV = nil
if IsExec then
    FOV = Drawing.new("Circle")
    FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1
    RunS.RenderStepped:Connect(function()
        if Options.Slider and Options.Colorpicker2 and Options.MyToggle then
            local isHitbox = Options.Dropdown and Options.Dropdown.Value == "Hitbox Increase"
            FOV.Visible = Options.MyToggle.Value and not isHitbox
            FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X
            FOV.Color = Options.Colorpicker2.Value
            FOV.Position = UIS:GetMouseLocation()
        else
            if FOV then FOV.Visible = false end
        end
    end)
end

-- ========================================================
-- Вспомогательные функции
-- ========================================================
local function IsEnemy(char)
    local p = Plrs:GetPlayerFromCharacter(char)
    if p and p ~= LP then
        if LP.Team ~= "" and p.Team ~= "" and LP.Team == p.Team then return false end
        return true
    end
    return _G.HighlightAll
end

local function IsVisible(part)
    local origin = Cam.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LP.Character, Cam}
    local result = workspace:Raycast(origin, part.Position - origin, raycastParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetTarget()
    local best, minAngle = nil, math.huge
    local fallbackTarget, fallbackMinAngle = nil, math.huge
    local maxAngle = (Options.Slider and Options.Slider.Value or 180)

    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if IsEnemy(p.Character) then
                local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.Head.Position - Cam.CFrame.Position).Unit), -1, 1)))
                if maxAngle >= 360 or angle <= maxAngle / 2 then
                    if IsVisible(p.Character.Head) then
                        if angle < minAngle then minAngle, best = angle, p.Character.Head end
                    else
                        if angle < fallbackMinAngle then fallbackMinAngle, fallbackTarget = angle, p.Character.Head end
                    end
                end
            end
        end
    end
    return best or fallbackTarget
end

-- ========================================================
-- Aimbot (для ПК – по клавише, для мобильных – всегда вкл или по тоглу)
-- ========================================================
local function ShouldAim()
    if not (Options.MyToggle and Options.MyToggle.Value) then return false end
    local mode = Options.Dropdown and Options.Dropdown.Value or "AimAssist"
    if mode ~= "AimAssist" then return false end

    if isMobile then
        -- На телефоне: либо всегда активно (если включён Mobile Aim Assist), либо по касанию экрана
        if Options.MobileAim and Options.MobileAim.Value then
            return true
        else
            return UIS:IsTouchEnabled and #UIS:GetTouches() > 0
        end
    else
        -- На ПК: по зажатой клавише (правый клик)
        return Options.Keybind and Options.Keybind:GetState()
    end
end

RunS.RenderStepped:Connect(function()
    if not ShouldAim() then return end
    local target = GetTarget()
    if target and IsVisible(target) then
        Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, target.Position), 0.4)
    end
end)

-- Hitbox Increase (увеличение хитбоксов)
RunS.RenderStepped:Connect(function()
    if not (Options.MyToggle and Options.MyToggle.Value) then return end
    local mode = Options.Dropdown and Options.Dropdown.Value or "AimAssist"
    if mode == "Hitbox Increase" then
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and IsEnemy(p.Character) then
                for _, name in pairs({"HeadHB", "HumanoidRootPart"}) do
                    local part = p.Character:FindFirstChild(name)
                    if part then
                        part.CanCollide = false
                        part.Transparency = 1
                        part.Size = Vector3.new(13, 13, 13)
                    end
                end
            end
        end
    end
end)

-- ========================================================
-- ESP (только Highlight)
-- ========================================================
local function ClearESP()
    for _, p in pairs(Plrs:GetPlayers()) do
        local h = p.Character and p.Character:FindFirstChild("Catalyst_Highlight")
        if h then h:Destroy() end
    end
end

local function CreateESP(char)
    if not char or not char:IsA("Model") or char == LP.Character then return end
    if not (Options["ESP Toggle"] and Options["ESP Toggle"].Value) then return end
    if not IsEnemy(char) then return end
    local h = char:FindFirstChild("Catalyst_Highlight") or Instance.new("Highlight")
    h.Name = "Catalyst_Highlight"
    h.FillColor = Options.Colorpicker.Value
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Parent = char
end

local function RefreshESP()
    ClearESP()
    if Options["ESP Toggle"] and Options["ESP Toggle"].Value then
        for _, p in pairs(Plrs:GetPlayers()) do
            if p.Character then CreateESP(p.Character) end
        end
    end
end

-- Слежка за сменой команды и появлением персонажа
local function BindTeamChange(p)
    p:GetPropertyChangedSignal("Team"):Connect(RefreshESP)
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if IsEnemy(c) then CreateESP(c) else
            local h = c:FindFirstChild("Catalyst_Highlight")
            if h then h:Destroy() end
        end
    end)
end

for _, p in pairs(Plrs:GetPlayers()) do BindTeamChange(p) end
Plrs.PlayerAdded:Connect(BindTeamChange)
Plrs.PlayerRemoving:Connect(function() task.spawn(RefreshESP) end)

-- ========================================================
-- Движение: Speedhack, Infinite Jump, Fly
-- ========================================================
-- Speedhack
RunS.RenderStepped:Connect(function()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum and Options.Speedhack and Options.Speedhack.Value then
        hum.WalkSpeed = Options.SpeedSlider and Options.SpeedSlider.Value or 100
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if Options.InfJump and Options.InfJump.Value and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- Fly (BodyVelocity)
local flyEnabled = false
local flyBodyVel = nil
local function ToggleFly()
    if flyEnabled then
        if flyBodyVel then flyBodyVel:Destroy() end
        flyEnabled = false
    else
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVel.Parent = root
        flyEnabled = true
    end
end

-- Fly управление (зажатие прыжка)
RunS.RenderStepped:Connect(function()
    if not (Options.FlyToggle and Options.FlyToggle.Value) then
        if flyEnabled then ToggleFly() end
        return
    end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not flyEnabled then
        if not flyBodyVel then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyVel.Parent = root
        end
        flyEnabled = true
    end
    local up = 0
    local down = 0
    if isMobile then
        -- На мобилках: полёт активен при касании экрана (любой тач)
        if #UIS:GetTouches() > 0 then
            up = 60
        end
        -- Для снижения можно добавить отдельную кнопку, но для простоты используем Shift на ПК
    else
        if UIS:IsKeyDown(Enum.KeyCode.Space) then up = 60 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then down = -60 end
    end
    flyBodyVel.Velocity = Vector3.new(root.Velocity.X, up + down, root.Velocity.Z)
end)

-- Остановка полёта при выключении тогла или смерти
LP.CharacterAdded:Connect(function()
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    flyEnabled = false
end)

-- ========================================================
-- ПОСТРОЕНИЕ UI
-- ========================================================
-- Combat
Tabs.Main:AddSection("Aimbot Settings")
local Toggle = Tabs.Main:AddToggle("MyToggle", { Title = "Enable Aimbot", Default = false })
local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Aim Mode",
    Values = { "AimAssist", "Hitbox Increase" },
    Multi = false,
    Default = "AimAssist"
})
local Keybind = Tabs.Main:AddKeybind("Keybind", { Title = "Aim Assist Keybind (PC)", Mode = "Hold", Default = "MouseRight" })
local Slider = Tabs.Main:AddSlider("Slider", { Title = "Aimbot FOV (Degrees)", Default = 180, Min = 1, Max = 360, Rounding = 0 })
local Colorpicker2 = Tabs.Main:AddColorpicker("Colorpicker2", { Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255) })

if isMobile then
    Tabs.Main:AddSection("Mobile Controls")
    local mobileAim = Tabs.Main:AddToggle("MobileAim", { Title = "Mobile Aim Assist (Always On)", Default = false })
    Tabs.Main:AddParagraph({ Title = "Tip", Content = "When disabled, aim works on touch." })
end

-- Visuals
Tabs.Visuals:AddSection("Visual Settings")
local espToggle = Tabs.Visuals:AddToggle("ESP Toggle", { Title = "Enable ESP (Team Checks)", Default = false })
local espColor = Tabs.Visuals:AddColorpicker("Colorpicker", { Title = "Enemy ESP Color", Default = Color3.fromRGB(255, 0, 0) })

espToggle:OnChanged(RefreshESP)
espColor:OnChanged(RefreshESP)

-- Misc
Tabs.Misc:AddSection("Movement Hacks")
local speedToggle = Tabs.Misc:AddToggle("Speedhack", { Title = "Enable Speedhack", Default = false })
local speedSlider = Tabs.Misc:AddSlider("SpeedSlider", { Title = "WalkSpeed Value", Default = 100, Min = 16, Max = 250, Rounding = 0 })
local infJump = Tabs.Misc:AddToggle("InfJump", { Title = "Infinite Jump", Default = false })
local flyToggle = Tabs.Misc:AddToggle("FlyToggle", { Title = "Fly (Hold Jump / Touch)", Default = false })

-- ========================================================
-- Сохранение настроек
-- ========================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/Arsenal")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)

-- Периодическое обновление ESP
while task.wait(120) do
    RefreshESP()
end
