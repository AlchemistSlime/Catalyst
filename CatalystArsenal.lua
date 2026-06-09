

local UIS = game:GetService("UserInputService")
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Rank system (optional)
_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"
local rankText = (_G.CatalystKeyType or "Free") .. " / " .. (_G.CatalystRank or "Standard")

local Window = Fluent:CreateWindow({
    Title = "Catalyst v3.3.0" .. (isMobile and " [Mobile]" or ""),
    SubTitle = "Arsenal",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

-- Tabs
local HomeTab = Window:AddTab({ Title = "Home", Icon = "home" })
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "crosshair" })
local MovementTab = Window:AddTab({ Title = "Movement", Icon = "" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "eye" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ========== SETTINGS ==========
local aimEnabled = false
local holding = false
local mobileAimLock = false
local wallCheck = true
local hitboxIncrease = false
local hitboxSize = 13

local keybind = "MouseRight"
local fovDeg = 90
local smoothness = 0.07
local aimPart = "Head"
local teamCheck = true

-- Weapon mods
local fireRateEnabled = false
local recoilEnabled = false

-- Movement
local speedEnabled = false
local speedValue = 100
local infJumpEnabled = false

-- Visuals
local espEnabled = false
local espColor = Color3.fromRGB(255,0,0)
local fovCircleEnabled = true
local fovCircleColor = Color3.fromRGB(255,255,255)

-- ========== HELPERS ==========
local function IsEnemy(plr)
    if plr == LP then return false end
    if not plr.Character then return false end
    if teamCheck then
        return plr.Team ~= LP.Team
    else
        return true
    end
end

local function IsVisible(part)
    if not wallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LP.Character, Camera}
    local result = workspace:Raycast(origin, direction * (part.Position - origin).Magnitude, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- ========== AIM V2 (LERP) ==========
local function GetTarget()
    local bestPart, bestAngle = nil, fovDeg
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            local char = plr.Character
            if char then
                local part = char:FindFirstChild(aimPart)
                local hum = char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local dir = (part.Position - cameraPos).Unit
                    local angle = math.deg(math.acos(math.clamp(cameraLook:Dot(dir), -1, 1)))
                    if angle <= bestAngle then
                        if IsVisible(part) then
                            bestAngle = angle
                            bestPart = part
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

local currentCF = Camera.CFrame
local aimConnection = nil
local function startAim()
    if aimConnection then aimConnection:Disconnect() end
    aimConnection = RunService.RenderStepped:Connect(function(dt)
        if not aimEnabled then
            currentCF = Camera.CFrame
            return
        end
        local active = false
        if isMobile then active = mobileAimLock else active = holding end
        if active then
            local target = GetTarget()
            if target then
                local targetCF = CFrame.new(Camera.CFrame.Position, target.Position)
                local alpha = math.clamp(smoothness / dt, 0, 1)
                currentCF = currentCF:Lerp(targetCF, alpha)
                Camera.CFrame = currentCF
            else
                currentCF = Camera.CFrame
            end
        else
            currentCF = Camera.CFrame
        end
    end)
end

-- Key handling (PC)
if not isMobile then
    local keyEnum = Enum.UserInputType.MouseButton2
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == keyEnum or input.KeyCode == keyEnum then holding = true end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == keyEnum or input.KeyCode == keyEnum then holding = false end
    end)
end

-- ========== HITBOX INCREASE (adjustable size) ==========
task.spawn(function()
    while true do
        task.wait(0.2)
        if not hitboxIncrease then continue end
        local size = hitboxSize
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local parts = {"HeadHB", "HumanoidRootPart"}
                for _, pname in ipairs(parts) do
                    local part = plr.Character:FindFirstChild(pname)
                    if part then
                        part.CanCollide = false
                        part.Transparency = 1
                        part.Size = Vector3.new(size, size, size)
                    end
                end
            end
        end
    end
end)

-- ========== WEAPON MODS ==========
task.spawn(function()
    while true do
        task.wait(5)
        if fireRateEnabled then
            local weapons = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
            if weapons then
                for _, v in ipairs(weapons:GetDescendants()) do
                    if v.Name == "Auto" then v.Value = true end
                    if v.Name == "FireRate" then v.Value = 0.02 end
                end
            end
        end
        if recoilEnabled then
            local weapons = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
            if weapons then
                for _, v in ipairs(weapons:GetDescendants()) do
                    if v.Name == "RecoilControl" then v.Value = 0 end
                    if v.Name == "MaxSpread" then v.Value = 0 end
                end
            end
        end
    end
end)

-- ========== MOVEMENT ==========
RunService.RenderStepped:Connect(function()
    if speedEnabled and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speedValue end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if infJumpEnabled and input.KeyCode == Enum.KeyCode.Space and not gp then
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.Velocity = Vector3.new(
                LP.Character.HumanoidRootPart.Velocity.X, 52, LP.Character.HumanoidRootPart.Velocity.Z
            )
        end
    end
end)

-- ========== ESP ==========
local espHighlights = {}
local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        local should = espEnabled and IsEnemy(plr) and char
        if should then
            if not espHighlights[plr] then
                local hl = Instance.new("Highlight")
                hl.Name = "Catalyst_ESP"
                hl.Parent = char
                espHighlights[plr] = hl
            end
            local hl = espHighlights[plr]
            hl.FillColor = espColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.new(1,1,1)
            hl.OutlineTransparency = 0
            hl.Adornee = char
        else
            if espHighlights[plr] then
                espHighlights[plr]:Destroy()
                espHighlights[plr] = nil
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if espEnabled then updateESP() end
    end
end)

-- ========== FOV CIRCLE ==========
local FovCircle = nil
if pcall(function() return Drawing end) then
    FovCircle = Drawing.new("Circle")
    FovCircle.Thickness = 1.5
    FovCircle.NumSides = 60
    FovCircle.Filled = false
    FovCircle.Transparency = 0.8
end

local function updateFOVCircle()
    if not FovCircle then return end
    if aimEnabled and fovCircleEnabled then
        local mousePos = UIS:GetMouseLocation()
        FovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        local screenSize = Camera.ViewportSize
        local radius = (fovDeg / 120) * screenSize.X
        FovCircle.Radius = math.clamp(radius, 50, math.min(screenSize.X, screenSize.Y) / 1.5)
        FovCircle.Color = fovCircleColor
        FovCircle.Visible = true
    else
        if FovCircle then FovCircle.Visible = false end
    end
end

RunService.RenderStepped:Connect(updateFOVCircle)

-- ========== UI ==========
HomeTab:AddParagraph({
    Title = "Catalyst Hub",
    Content = "Rank: " .. rankText .. "\nGame: Arsenal\nVersion 3.3.0\nTG: @alchemistslimee"
})
HomeTab:AddButton({
    Title = "Copy Discord",
    Callback = function()
        setclipboard("https://discord.gg/w9mfcck2zV")
        Fluent:Notify({ Title = "Copied", Content = "Discord link copied", Duration = 2 })
    end
})

-- Combat Tab
CombatTab:AddToggle("AimMain", {Title = "Enable Aim", Default = false})
    :OnChanged(function(v) aimEnabled = v end)

CombatTab:AddSlider("FOV", {Title = "FOV (degrees)", Default = 90, Min = 10, Max = 180, Rounding = 0})
    :OnChanged(function(v) fovDeg = v end)

CombatTab:AddSlider("Smoothness", {Title = "Smoothness", Default = 0.07, Min = 0.01, Max = 0.2, Rounding = 3})
    :OnChanged(function(v) smoothness = v end)

local aimPartDropdown = CombatTab:AddDropdown("AimPart", {
    Title = "Aim Part",
    Values = {"Head", "HumanoidRootPart", "Torso"},
    Default = "Head",
    Multi = false
})
aimPartDropdown:OnChanged(function(v) aimPart = v end)

local teamCheckToggle = CombatTab:AddToggle("TeamCheck", {Title = "Team Check", Default = true})
teamCheckToggle:OnChanged(function(v) teamCheck = v; updateESP() end)

CombatTab:AddToggle("WallCheck", {Title = "WallCheck", Default = true})
    :OnChanged(function(v) wallCheck = v end)

if not isMobile then
    CombatTab:AddKeybind("AimKey", {Title = "Aim Key", Mode = "Hold", Default = "MouseRight"})
        :OnChanged(function(val)
            if type(val) == "string" then
                keybind = val
                if val == "MouseRight" then
                    keyEnum = Enum.UserInputType.MouseButton2
                elseif val == "MouseLeft" then
                    keyEnum = Enum.UserInputType.MouseButton1
                else
                    for _, e in pairs(Enum.UserInputType:GetEnumItems()) do
                        if e.Name == val then keyEnum = e break end
                    end
                    for _, e in pairs(Enum.KeyCode:GetEnumItems()) do
                        if e.Name == val then keyEnum = e break end
                    end
                end
            end
        end)
end

if isMobile then
    CombatTab:AddToggle("MobileAimLock", {Title = "Mobile Aim Lock", Default = false})
        :OnChanged(function(v) mobileAimLock = v end)
end

CombatTab:AddToggle("HitboxIncrease", {Title = "Hitbox Increase", Default = false})
    :OnChanged(function(v) hitboxIncrease = v end)

CombatTab:AddSlider("HitboxSize", {Title = "Hitbox Size", Default = 13, Min = 5, Max = 20, Rounding = 0})
    :OnChanged(function(v) hitboxSize = v end)

CombatTab:AddSection("Weapon Mods")
CombatTab:AddToggle("FireRate", {Title = "FireRate Mod", Default = false})
    :OnChanged(function(v) fireRateEnabled = v end)
CombatTab:AddToggle("Recoil", {Title = "No Recoil / No Spread", Default = false})
    :OnChanged(function(v) recoilEnabled = v end)

-- Movement Tab
MovementTab:AddToggle("Speed", {Title = "Speed Hack", Default = false})
    :OnChanged(function(v) speedEnabled = v end)
MovementTab:AddSlider("SpeedVal", {Title = "WalkSpeed Value", Default = 100, Min = 16, Max = 250, Rounding = 0})
    :OnChanged(function(v) speedValue = v end)
MovementTab:AddToggle("InfJump", {Title = "Infinite Jump", Default = false})
    :OnChanged(function(v) infJumpEnabled = v end)

-- Visuals Tab
VisualsTab:AddToggle("ESP", {Title = "Player ESP", Default = false})
    :OnChanged(function(v) espEnabled = v; updateESP() end)
VisualsTab:AddColorpicker("ESPColor", {Title = "ESP Color", Default = Color3.fromRGB(255,0,0)})
    :OnChanged(function(v) espColor = v; updateESP() end)
VisualsTab:AddToggle("FOVCircle", {Title = "Show FOV Circle", Default = true})
    :OnChanged(function(v) fovCircleEnabled = v end)
VisualsTab:AddColorpicker("FOVColor", {Title = "FOV Circle Color", Default = Color3.fromRGB(255,255,255)})
    :OnChanged(function(v) fovCircleColor = v end)

-- Settings Tab
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("CatalystHub")
SaveManager:SetFolder("CatalystHub/Arsenal")
InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- Start aim
startAim()

-- Open Home tab
Window:SelectTab(HomeTab)
