-- ========================================================
-- CATALYST MM2 v5.1 (AIMBOT BACK, LIGHT & FAST)
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

local isMobile = UIS.TouchEnabled or not UIS.MouseEnabled

-- Загрузка Fluent
local Fluent, SaveManager, InterfaceManager
local ok = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)
if not ok then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Catalyst Error", Text="Failed to load UI", Duration=5})
    return
end

_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"

-- ========== ОПРЕДЕЛЕНИЕ РОЛЕЙ ==========
local roleCache = {}
local lastRoleUpdate = 0

local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    local now = tick()
    if roleCache[p] and (now - lastRoleUpdate) < 2 then return roleCache[p] end
    local char = p.Character
    local role = "Innocent"
    if char:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) or char:FindFirstChild("MurdererEffect") then
        role = "Murderer"
    elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or (p.Backpack and (p.Backpack:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Revolver"))) then
        role = "Sheriff"
    else
        local rd = RS:FindFirstChild("RoundView") or RS:FindFirstChild("GameStorage")
        local ur = rd and rd:FindFirstChild("RoleData") and rd.RoleData:FindFirstChild(p.Name)
        if ur then
            if ur.Value == "Murderer" then role = "Murderer"
            elseif ur.Value == "Sheriff" or ur.Value == "Hero" then role = "Sheriff" end
        end
    end
    roleCache[p] = role
    return role
end

local function HasGun()
    local char = LP.Character
    return char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) ~= nil
end

-- ========== ПОИСК GUN DROP ==========
local function FindGunDrop()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name == "Revolver") then
            local part = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
            if part then return part end
        end
    end
    return nil
end

-- ========== ТЕЛЕПОРТ К GUN DROP ==========
local tpCooldown = false
local lastTP = 0
local cooldownPara = nil

local function TeleportToGunDrop(returnBack)
    if tpCooldown then
        if cooldownPara then cooldownPara:SetContent("Cooldown " .. math.ceil(3 - (tick() - lastTP)) .. "s") end
        return false
    end
    if HasGun() then return false end
    local gd = FindGunDrop()
    if not gd then return false end
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local orig = hrp.CFrame
    hrp.CFrame = gd.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.1)
    if returnBack and hrp and hrp.Parent then
        hrp.CFrame = orig
    end
    tpCooldown = true
    lastTP = tick()
    if cooldownPara then cooldownPara:SetContent("Cooldown 3s") end
    task.wait(3)
    tpCooldown = false
    if cooldownPara then cooldownPara:SetContent("Ready") end
    return true
end

-- ========== GUI ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v5.1" .. (isMobile and " [Mobile]" or ""),
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 500),
    Acrylic = false,
    Theme = "Dark"
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "star" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options

-- Home
local rankText = (_G.CatalystKeyType or "Free") .. " / " .. (_G.CatalystRank or "Standard")
Tabs.Home:AddParagraph({ Title = "Catalyst", Content = "Rank: " .. rankText .. "\nMM2\nAlchemist Slime\nTG: @alchemistslimee\nVersion 5.1" })
Tabs.Home:AddButton({ Title = "Copy Discord", Callback = function() setclipboard("alchemistslimee") Fluent:Notify({ Title = "Copied" }) end })

-- ========== COMBAT TAB ==========
if not isMobile then
    Tabs.Combat:AddSection("Aimbot (PC only)")
    local aimToggle = Tabs.Combat:AddToggle("aim", { Title = "Enable Aimbot", Default = false })
    local predToggle = Tabs.Combat:AddToggle("pred", { Title = "Prediction", Default = false })
    local predDelay = Tabs.Combat:AddSlider("predDelay", { Title = "Prediction ms", Default = 80, Min = 0, Max = 100, Rounding = 0 })
    local aimKey = Tabs.Combat:AddKeybind("aimKey", { Title = "Aimbot Key", Mode = "Hold", Default = "MouseRight" })
    local fovSlider = Tabs.Combat:AddSlider("fov", { Title = "FOV Degrees", Default = 80, Min = 1, Max = 360, Rounding = 0 })
    local fovColor = Tabs.Combat:AddColorpicker("fovColor", { Title = "FOV Color", Default = Color3.fromRGB(255,255,255) })
end

Tabs.Combat:AddSection("Gun Drop Teleport")
local tpBtn = Tabs.Combat:AddButton({ Title = "TP to Gun (once)", Callback = function() TeleportToGunDrop(true) end })
local autoTP = Tabs.Combat:AddToggle("autoTP", { Title = "Auto TP every 2s", Default = false })
cooldownPara = Tabs.Combat:AddParagraph({ Title = "Cooldown", Content = "Ready" })

-- ========== VISUALS TAB ==========
Tabs.Visuals:AddSection("Highlight ESP")
local murHighlight = Tabs.Visuals:AddToggle("murHl", { Title = "Highlight Murderer", Default = false })
local murColor = Tabs.Visuals:AddColorpicker("murCol", { Title = "Color", Default = Color3.fromRGB(255,0,0) })
local sherHighlight = Tabs.Visuals:AddToggle("sherHl", { Title = "Highlight Sheriff", Default = false })
local sherColor = Tabs.Visuals:AddColorpicker("sherCol", { Title = "Color", Default = Color3.fromRGB(0,0,255) })
local innocHighlight = Tabs.Visuals:AddToggle("innHl", { Title = "Highlight Innocent", Default = false })
local innocColor = Tabs.Visuals:AddColorpicker("innCol", { Title = "Color", Default = Color3.fromRGB(0,255,0) })
local gdHighlight = Tabs.Visuals:AddToggle("gdHl", { Title = "Highlight Gun", Default = false })
local gdColor = Tabs.Visuals:AddColorpicker("gdCol", { Title = "Color", Default = Color3.fromRGB(128,0,255) })

if not isMobile then
    Tabs.Visuals:AddSection("Name ESP (PC only)")
    local murText = Tabs.Visuals:AddToggle("murTxt", { Title = "Murderer Names", Default = false })
    local murTxtColor = Tabs.Visuals:AddColorpicker("murTxtCol", { Title = "Text Color", Default = Color3.fromRGB(255,0,0) })
    local sherText = Tabs.Visuals:AddToggle("sherTxt", { Title = "Sheriff Names", Default = false })
    local sherTxtColor = Tabs.Visuals:AddColorpicker("sherTxtCol", { Title = "Text Color", Default = Color3.fromRGB(0,0,255) })
    local innocText = Tabs.Visuals:AddToggle("innTxt", { Title = "Innocent Names", Default = false })
    local innocTxtColor = Tabs.Visuals:AddColorpicker("innTxtCol", { Title = "Text Color", Default = Color3.fromRGB(0,255,0) })
end

-- ========== MISC TAB ==========
Tabs.Misc:AddSection("Movement")
local noclip = Tabs.Misc:AddToggle("noclip", { Title = "No-Clip", Default = false })
local fly = Tabs.Misc:AddToggle("fly", { Title = "Fly", Default = false })
local speed = Tabs.Misc:AddToggle("speed", { Title = "Speedhack", Default = false })
local speedVal = Tabs.Misc:AddSlider("speedVal", { Title = "Speed", Default = 50, Min = 16, Max = 250, Rounding = 0 })

-- ========== ESP HIGHLIGHT ==========
local function UpdateHighlight(p)
    if not p or p == LP or not p.Character then return end
    local role = GetRole(p)
    local hl = p.Character:FindFirstChild("Catalyst_HL")
    local show = false
    local base = Color3.new(1,1,1)
    if role == "Murderer" and murHighlight and murHighlight.Value then
        show = true
        base = murColor and murColor.Value or Color3.fromRGB(255,0,0)
    elseif role == "Sheriff" and sherHighlight and sherHighlight.Value then
        show = true
        base = sherColor and sherColor.Value or Color3.fromRGB(0,0,255)
    elseif role == "Innocent" and innocHighlight and innocHighlight.Value then
        show = true
        base = innocColor and innocColor.Value or Color3.fromRGB(0,255,0)
    end
    if show then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "Catalyst_HL"
            hl.Parent = p.Character
        end
        local h,s,v = base:ToHSV()
        hl.FillColor = Color3.fromHSV(h, s, math.max(v*0.8,0))
        hl.OutlineColor = base
        hl.FillTransparency = 0.4
    elseif hl then
        hl:Destroy()
    end
end

local gunDropHighlight = nil
local function UpdateGunDropHighlight()
    if gdHighlight and gdHighlight.Value then
        local gd = FindGunDrop()
        if gd then
            if not gunDropHighlight or gunDropHighlight.Parent ~= gd then
                if gunDropHighlight then gunDropHighlight:Destroy() end
                gunDropHighlight = Instance.new("Highlight")
                local base = gdColor and gdColor.Value or Color3.fromRGB(128,0,255)
                local h,s,v = base:ToHSV()
                gunDropHighlight.FillColor = base
                gunDropHighlight.OutlineColor = Color3.fromHSV(h, s, math.max(v*0.8,0))
                gunDropHighlight.FillTransparency = 0.4
                gunDropHighlight.Parent = gd
            end
        elseif gunDropHighlight then
            gunDropHighlight:Destroy(); gunDropHighlight = nil
        end
    elseif gunDropHighlight then
        gunDropHighlight:Destroy(); gunDropHighlight = nil
    end
end

-- Цикл обновления ролей и подсветки
task.spawn(function()
    while true do
        task.wait(2)
        lastRoleUpdate = tick()
        for _, p in pairs(Plrs:GetPlayers()) do GetRole(p) end
        for _, p in pairs(Plrs:GetPlayers()) do pcall(UpdateHighlight, p) end
        pcall(UpdateGunDropHighlight)
    end
end)

-- Name ESP для ПК (только если включён)
if not isMobile then
    local nameTexts = {}
    RunS.RenderStepped:Connect(function()
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                local role = GetRole(p)
                local show = false
                local color = Color3.new(1,1,1)
                if role == "Murderer" and Options.murTxt and Options.murTxt.Value then
                    show = true
                    color = Options.murTxtCol and Options.murTxtCol.Value or Color3.fromRGB(255,0,0)
                elseif role == "Sheriff" and Options.sherTxt and Options.sherTxt.Value then
                    show = true
                    color = Options.sherTxtCol and Options.sherTxtCol.Value or Color3.fromRGB(0,0,255)
                elseif role == "Innocent" and Options.innTxt and Options.innTxt.Value then
                    show = true
                    color = Options.innTxtCol and Options.innTxtCol.Value or Color3.fromRGB(0,255,0)
                end
                if show then
                    local root = p.Character.HumanoidRootPart
                    local vec, on = Cam:WorldToViewportPoint(root.Position + Vector3.new(0,2.5,0))
                    if on then
                        local txt = nameTexts[p]
                        if not txt then
                            txt = Drawing.new("Text")
                            txt.Center = true
                            txt.Outline = true
                            txt.Size = 14
                            nameTexts[p] = txt
                        end
                        txt.Text = p.Name .. " (" .. role .. ")"
                        txt.Position = Vector2.new(vec.X, vec.Y)
                        txt.Color = color
                        txt.Visible = true
                    elseif nameTexts[p] then
                        nameTexts[p].Visible = false
                    end
                elseif nameTexts[p] then
                    nameTexts[p].Visible = false
                end
            elseif nameTexts[p] then
                nameTexts[p].Visible = false
            end
        end
    end)
end

-- ========== ДВИЖЕНИЕ ==========
RunS.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return end

    if speed and speed.Value then
        hum.WalkSpeed = speedVal and speedVal.Value or 50
    else
        hum.WalkSpeed = 16
    end

    if noclip and noclip.Value then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if fly and fly.Value then
        if UIS:IsKeyDown(Enum.KeyCode.Space) or (isMobile and #UIS:GetTouches() > 0) then
            root.Velocity = Vector3.new(root.Velocity.X, 60, root.Velocity.Z)
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            root.Velocity = Vector3.new(root.Velocity.X, -60, root.Velocity.Z)
        else
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if fly and fly.Value and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- ========== АВТО-ТП ==========
task.spawn(function()
    while true do
        task.wait(2)
        if autoTP and autoTP.Value then
            pcall(TeleportToGunDrop, true)
        end
    end
end)

-- ========== АИМБОТ ДЛЯ ПК ==========
if not isMobile then
    local function GetTarget()
        local myRole = GetRole(LP)
        if myRole == "Innocent" then return nil end
        local best, bestAngle = nil, math.huge
        local fov = Options.fov and Options.fov.Value or 80
        local maxDist = (fov / 360) * Cam.ViewportSize.X
        local mousePos = UIS:GetMouseLocation()
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                local tRole = GetRole(p)
                local vec, on = Cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if on then
                    local dist = (Vector2.new(vec.X, vec.Y) - mousePos).Magnitude
                    if dist <= maxDist then
                        local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.HumanoidRootPart.Position - Cam.CFrame.Position).Unit), -1, 1)))
                        if myRole == "Murderer" and (tRole == "Sheriff" or tRole == "Innocent") and angle < bestAngle then
                            bestAngle, best = angle, p.Character.HumanoidRootPart
                        elseif myRole == "Sheriff" and tRole == "Murderer" and angle < bestAngle then
                            bestAngle, best = angle, p.Character.HumanoidRootPart
                        end
                    end
                end
            end
        end
        return best
    end

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Filled = false
    fovCircle.Transparency = 1
    RunS.RenderStepped:Connect(function()
        if Options.aim and Options.aim.Value then
            fovCircle.Visible = true
            fovCircle.Radius = (Options.fov and Options.fov.Value or 80) / 360 * Cam.ViewportSize.X
            fovCircle.Color = Options.fovColor and Options.fovColor.Value or Color3.fromRGB(255,255,255)
            fovCircle.Position = UIS:GetMouseLocation()
        else
            fovCircle.Visible = false
        end
    end)

    RunS.RenderStepped:Connect(function()
        if not (Options.aim and Options.aim.Value) then return end
        local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (Options.aimKey and Options.aimKey:GetState())
        if press then
            local target = GetTarget()
            if target then
                local pos = target.Position
                if Options.pred and Options.pred.Value then
                    local delay = (Options.predDelay and Options.predDelay.Value or 80) / 1000
                    pos = pos + (target.Velocity * delay)
                end
                Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
            end
        end
    end)
end

-- ========== SAVE MANAGER ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/MM2")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(Tabs.Home)
