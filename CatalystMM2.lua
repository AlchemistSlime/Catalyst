-- ========================================================
-- CATALYST MM2 v3.2 (FINAL WORKING)
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

-- Загрузка Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ========== ГЛОБАЛЬНЫЕ НАСТРОЙКИ ==========
_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"
_G.CatalystOptions = {}

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local roleCache = {}
local lastRoleUpdate = 0

local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    local now = tick()
    if roleCache[p] and (now - lastRoleUpdate) < 2 then
        return roleCache[p]
    end
    local char = p.Character
    local role = "Innocent"
    if char:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) or char:FindFirstChild("MurdererEffect") then
        role = "Murderer"
    elseif char:FindFirstChild("Gun") or (p.Backpack and p.Backpack:FindFirstChild("Gun")) then
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

local function UpdateRoleCache()
    lastRoleUpdate = tick()
    for _, p in pairs(Plrs:GetPlayers()) do
        GetRole(p)
    end
end

local function HasRevolver()
    local char = LP.Character
    return char and char:FindFirstChild("Revolver") ~= nil
end

-- ========== GUN DROP ПОИСК ==========
local gunDropPart = nil
local gunDropHighlight = nil
local gunDropText = nil
local lastGunSearch = 0
local cachedGun = nil

local function FindGunDrop()
    local now = tick()
    if now - lastGunSearch < 0.5 then return cachedGun end
    lastGunSearch = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name and (obj.Name:lower():find("gun") or obj.Name:lower():find("drop")) then
            cachedGun = obj
            return obj
        end
    end
    cachedGun = nil
    return nil
end

-- ========== ФУНКЦИИ ДЕЙСТВИЙ ==========
local tpCooldown = false
local lastTP = 0

function TeleportToGunDrop(returnBack)
    if tpCooldown then
        if _G.CatalystOptions.cooldownPara then
            _G.CatalystOptions.cooldownPara:SetContent("Cooldown " .. math.ceil(3 - (tick() - lastTP)) .. "s")
        end
        return false
    end
    if HasRevolver() then return false end
    local gd = FindGunDrop()
    if not gd then return false end
    if _G.CatalystOptions.safeTP and _G.CatalystOptions.safeTP.Value then
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and GetRole(p) == "Murderer" then
                if (p.Character.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude < 5 then
                    Fluent:Notify({ Title = "Safe TP", Content = "Murderer nearby", Duration = 1.5 })
                    return false
                end
            end
        end
    end
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
    if _G.CatalystOptions.cooldownPara then _G.CatalystOptions.cooldownPara:SetContent("Cooldown 3s") end
    task.wait(3)
    tpCooldown = false
    if _G.CatalystOptions.cooldownPara then _G.CatalystOptions.cooldownPara:SetContent("Ready") end
    return true
end

function FlingPlayers(targetType)
    local blacklist = (_G.CatalystOptions.blacklist and _G.CatalystOptions.blacklist.Value) or {}
    local targets = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and not table.find(blacklist, p.Name) then
            local role = GetRole(p)
            if targetType == "All" then
                table.insert(targets, p)
            elseif targetType == "Murderer" and role == "Murderer" then
                table.insert(targets, p)
            elseif targetType == "Sheriff" and role == "Sheriff" then
                table.insert(targets, p)
            end
        end
    end
    if #targets == 0 then
        Fluent:Notify({ Title = "Fling", Content = "No targets", Duration = 2 })
        return
    end
    local origPos = {}
    for _, p in ipairs(targets) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            origPos[p] = hrp.CFrame
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 50, 0)
        end
    end
    task.wait(0.3)
    for p, cf in pairs(origPos) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = cf
            hrp.Velocity = Vector3.zero
        end
    end
    Fluent:Notify({ Title = "Fling", Content = #targets .. " player(s) flung", Duration = 2 })
end

function ScanCheaters()
    local suspects = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.WalkSpeed > 18 then
                table.insert(suspects, p.Name .. " (Speed: " .. math.floor(hum.WalkSpeed) .. ")")
            end
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and root.CanCollide == false then
                table.insert(suspects, p.Name .. " (Noclip)")
            end
        end
    end
    if _G.CatalystOptions.cheatPara then
        if #suspects > 0 then
            _G.CatalystOptions.cheatPara:SetContent(table.concat(suspects, "\n"))
        else
            _G.CatalystOptions.cheatPara:SetContent("None found")
        end
    end
    Fluent:Notify({ Title = "Cheaters", Content = (#suspects > 0 and #suspects .. " found" or "Clean"), Duration = 2 })
end

-- ========== СОЗДАНИЕ GUI ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v3.2",
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(640, 540),
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

-- Home
local rankText = (_G.CatalystKeyType or "Free") .. " / " .. (_G.CatalystRank or "Standard")
Tabs.Home:AddParagraph({ Title = "Catalyst", Content = "Rank: " .. rankText .. "\nMurder Mystery 2\nDeveloper: Alchemist Slime\nTG: @alchemistslimee" })
Tabs.Home:AddButton({ Title = "Copy Discord Tag", Callback = function() setclipboard("alchemistslimee") Fluent:Notify({ Title = "Copied", Content = "alchemistslimee", Duration = 2 }) end })

-- ========== COMBAT TAB ==========
Tabs.Combat:AddSection("Aimbot")
_G.CatalystOptions.aimToggle = Tabs.Combat:AddToggle("aim", { Title = "Enable Aimbot", Default = false })
_G.CatalystOptions.predToggle = Tabs.Combat:AddToggle("pred", { Title = "Enable Prediction", Default = false })
_G.CatalystOptions.predSlider = Tabs.Combat:AddSlider("predDelay", { Title = "Prediction ms", Default = 80, Min = 0, Max = 100, Step = 1 })
_G.CatalystOptions.fovSlider = Tabs.Combat:AddSlider("fov", { Title = "FOV Degrees", Default = 80, Min = 1, Max = 360, Step = 1 })
_G.CatalystOptions.fovColor = Tabs.Combat:AddColorpicker("fovColor", { Title = "FOV Color", Default = Color3.fromRGB(255, 255, 255) })
_G.CatalystOptions.aimKey = Tabs.Combat:AddKeybind("aimKey", { Title = "Aimbot Key", Mode = "Hold", Default = "MouseButton2" })

Tabs.Combat:AddSection("Gun Drop Teleport")
_G.CatalystOptions.tpBtn = Tabs.Combat:AddButton({ Title = "TP to Gun Drop (once)", Callback = function() TeleportToGunDrop(true) end })
_G.CatalystOptions.autoTP = Tabs.Combat:AddToggle("autoTP", { Title = "Auto TP every 1s", Default = false })
_G.CatalystOptions.safeTP = Tabs.Combat:AddToggle("safeTP", { Title = "Avoid Murderer within 5 studs", Default = true })
_G.CatalystOptions.cooldownPara = Tabs.Combat:AddParagraph({ Title = "Cooldown", Content = "Ready" })

Tabs.Combat:AddSection("Fling")
_G.CatalystOptions.antiFling = Tabs.Combat:AddToggle("antiFling", { Title = "Anti-Fling (basic)", Default = false })
_G.CatalystOptions.flingAll = Tabs.Combat:AddButton({ Title = "Fling All", Callback = function() FlingPlayers("All") end })
_G.CatalystOptions.flingMurder = Tabs.Combat:AddButton({ Title = "Fling Murderers", Callback = function() FlingPlayers("Murderer") end })
_G.CatalystOptions.flingSheriff = Tabs.Combat:AddButton({ Title = "Fling Sheriffs", Callback = function() FlingPlayers("Sheriff") end })

Tabs.Combat:AddSection("Blacklist")
_G.CatalystOptions.blacklist = Tabs.Combat:AddDropdown("blacklist", { Title = "Do NOT fling these players", Values = {}, Multi = true, Default = {} })
local function RefreshBlacklist()
    local names = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    _G.CatalystOptions.blacklist:SetValues(names)
end
task.spawn(function()
    task.wait(0.2)
    RefreshBlacklist()
end)
Plrs.PlayerAdded:Connect(RefreshBlacklist)
Plrs.PlayerRemoving:Connect(RefreshBlacklist)

-- ========== VISUALS TAB ==========
-- Murderer
Tabs.Visuals:AddSection("Murderer")
_G.CatalystOptions.murHighlight = Tabs.Visuals:AddToggle("murHl", { Title = "Highlight Murderer", Default = false })
_G.CatalystOptions.murColor = Tabs.Visuals:AddColorpicker("murCol", { Title = "Highlight Color", Default = Color3.fromRGB(255, 0, 0) })
_G.CatalystOptions.murText = Tabs.Visuals:AddToggle("murTxt", { Title = "Show Name ESP", Default = false })
_G.CatalystOptions.murTxtColor = Tabs.Visuals:AddColorpicker("murTxtCol", { Title = "Name Color", Default = Color3.fromRGB(255, 0, 0) })
-- Sheriff
Tabs.Visuals:AddSection("Sheriff")
_G.CatalystOptions.sherHighlight = Tabs.Visuals:AddToggle("sherHl", { Title = "Highlight Sheriff", Default = false })
_G.CatalystOptions.sherColor = Tabs.Visuals:AddColorpicker("sherCol", { Title = "Highlight Color", Default = Color3.fromRGB(0, 0, 255) })
_G.CatalystOptions.sherText = Tabs.Visuals:AddToggle("sherTxt", { Title = "Show Name ESP", Default = false })
_G.CatalystOptions.sherTxtColor = Tabs.Visuals:AddColorpicker("sherTxtCol", { Title = "Name Color", Default = Color3.fromRGB(0, 0, 255) })
-- Innocent
Tabs.Visuals:AddSection("Innocent")
_G.CatalystOptions.innocHighlight = Tabs.Visuals:AddToggle("innHl", { Title = "Highlight Innocent", Default = false })
_G.CatalystOptions.innocColor = Tabs.Visuals:AddColorpicker("innCol", { Title = "Highlight Color", Default = Color3.fromRGB(0, 255, 0) })
_G.CatalystOptions.innocText = Tabs.Visuals:AddToggle("innTxt", { Title = "Show Name ESP", Default = false })
_G.CatalystOptions.innocTxtColor = Tabs.Visuals:AddColorpicker("innTxtCol", { Title = "Name Color", Default = Color3.fromRGB(0, 255, 0) })
-- Gun Drop
Tabs.Visuals:AddSection("Gun Drop Visuals")
_G.CatalystOptions.gdHighlight = Tabs.Visuals:AddToggle("gdHl", { Title = "Highlight Gun Drop", Default = false })
_G.CatalystOptions.gdColor = Tabs.Visuals:AddColorpicker("gdCol", { Title = "Highlight Color", Default = Color3.fromRGB(128, 0, 255) })
_G.CatalystOptions.gdText = Tabs.Visuals:AddToggle("gdTxt", { Title = "Show Text", Default = true })
_G.CatalystOptions.gdTxtColor = Tabs.Visuals:AddColorpicker("gdTxtCol", { Title = "Text Color", Default = Color3.fromRGB(255, 255, 255) })

-- ========== MISC TAB ==========
Tabs.Misc:AddSection("Movement")
_G.CatalystOptions.noclip = Tabs.Misc:AddToggle("noclip", { Title = "No-Clip", Default = false })
_G.CatalystOptions.fly = Tabs.Misc:AddToggle("fly", { Title = "Fly", Default = false })
_G.CatalystOptions.speed = Tabs.Misc:AddToggle("speed", { Title = "Speedhack", Default = false })
_G.CatalystOptions.speedVal = Tabs.Misc:AddSlider("speedVal", { Title = "Speed (walk)", Default = 50, Min = 16, Max = 250, Step = 1 })

Tabs.Misc:AddSection("Cheater Detection")
_G.CatalystOptions.cheatPara = Tabs.Misc:AddParagraph({ Title = "Suspicious Players", Content = "None" })
_G.CatalystOptions.autoCheat = Tabs.Misc:AddToggle("autoCheat", { Title = "Auto Scan (every 5s)", Default = false })
Tabs.Misc:AddButton({ Title = "Scan Now", Callback = function() ScanCheaters() end })

-- ========== НАСТРОЙКИ И СОХРАНЕНИЕ ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/MM2")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(Tabs.Home)

-- ========== ЗАПУСК ВСЕХ ЦИКЛОВ ПОСЛЕ ИНИЦИАЛИЗАЦИИ ==========
task.wait(0.5)

-- Обновление визуалов Gun Drop
local function UpdateGunDropVisuals()
    if HasRevolver() then
        if gunDropHighlight then gunDropHighlight:Destroy(); gunDropHighlight = nil end
        if gunDropText then gunDropText:Remove(); gunDropText = nil end
        gunDropPart = nil
        return
    end
    local gd = FindGunDrop()
    gunDropPart = gd
    if gd then
        if _G.CatalystOptions.gdHighlight and _G.CatalystOptions.gdHighlight.Value then
            if not gunDropHighlight or gunDropHighlight.Parent ~= gd then
                if gunDropHighlight then gunDropHighlight:Destroy() end
                gunDropHighlight = Instance.new("Highlight")
                local base = _G.CatalystOptions.gdColor and _G.CatalystOptions.gdColor.Value or Color3.fromRGB(128,0,255)
                local h,s,v = base:ToHSV()
                local darker = Color3.fromHSV(h, s, math.max(v * 0.8, 0))
                gunDropHighlight.FillColor = base
                gunDropHighlight.OutlineColor = darker
                gunDropHighlight.FillTransparency = 0.4
                gunDropHighlight.Parent = gd
            end
        elseif gunDropHighlight then
            gunDropHighlight:Destroy(); gunDropHighlight = nil
        end
        if _G.CatalystOptions.gdText and _G.CatalystOptions.gdText.Value then
            if not gunDropText and Drawing and Drawing.new then
                gunDropText = Drawing.new("Text")
                gunDropText.Center = true
                gunDropText.Outline = true
                gunDropText.Size = 16
            end
            if gunDropText then
                local pos, on = Cam:WorldToViewportPoint(gd.Position + Vector3.new(0,1.5,0))
                if on then
                    gunDropText.Position = Vector2.new(pos.X, pos.Y)
                    gunDropText.Text = "GUN DROP"
                    gunDropText.Color = _G.CatalystOptions.gdTxtColor and _G.CatalystOptions.gdTxtColor.Value or Color3.fromRGB(255,255,255)
                    gunDropText.Visible = true
                else
                    gunDropText.Visible = false
                end
            end
        elseif gunDropText then
            gunDropText.Visible = false
        end
    else
        if gunDropHighlight then gunDropHighlight:Destroy(); gunDropHighlight = nil end
        if gunDropText then gunDropText:Remove(); gunDropText = nil end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(UpdateGunDropVisuals)
    end
end)

RunS.RenderStepped:Connect(function()
    if gunDropText and gunDropText.Visible and gunDropPart then
        local pos, on = Cam:WorldToViewportPoint(gunDropPart.Position + Vector3.new(0,1.5,0))
        if on then gunDropText.Position = Vector2.new(pos.X, pos.Y) end
    end
end)

-- Auto TP loop
task.spawn(function()
    while true do
        task.wait(1)
        if _G.CatalystOptions.autoTP and _G.CatalystOptions.autoTP.Value and not tpCooldown and not HasRevolver() then
            pcall(TeleportToGunDrop, true)
        end
    end
end)

-- Anti-Fling
local lastPos = nil
RunS.RenderStepped:Connect(function()
    if _G.CatalystOptions.antiFling and _G.CatalystOptions.antiFling.Value then
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local cur = char.HumanoidRootPart.Position
            if lastPos and (cur - lastPos).Magnitude > 40 then
                char.HumanoidRootPart.CFrame = CFrame.new(lastPos)
                Fluent:Notify({ Title = "Anti-Fling", Content = "Blocked", Duration = 1 })
            end
            lastPos = cur
        end
    else
        lastPos = nil
    end
end)

-- ESP HIGHLIGHT
local function UpdateHighlight(p)
    if not p or p == LP or not p.Character then return end
    local role = GetRole(p)
    local hl = p.Character:FindFirstChild("Catalyst_HL")
    local show = false
    local base = Color3.new(1,1,1)
    if role == "Murderer" and _G.CatalystOptions.murHighlight and _G.CatalystOptions.murHighlight.Value then
        show = true
        base = _G.CatalystOptions.murColor and _G.CatalystOptions.murColor.Value or Color3.fromRGB(255,0,0)
    elseif role == "Sheriff" and _G.CatalystOptions.sherHighlight and _G.CatalystOptions.sherHighlight.Value then
        show = true
        base = _G.CatalystOptions.sherColor and _G.CatalystOptions.sherColor.Value or Color3.fromRGB(0,0,255)
    elseif role == "Innocent" and _G.CatalystOptions.innocHighlight and _G.CatalystOptions.innocHighlight.Value then
        show = true
        base = _G.CatalystOptions.innocColor and _G.CatalystOptions.innocColor.Value or Color3.fromRGB(0,255,0)
    end
    if show then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "Catalyst_HL"
            hl.Parent = p.Character
        end
        local h,s,v = base:ToHSV()
        local darker = Color3.fromHSV(h, s, math.max(v * 0.8, 0))
        hl.FillColor = darker
        hl.OutlineColor = base
        hl.FillTransparency = 0.4
    elseif hl then
        hl:Destroy()
    end
end

-- Name ESP
local nameTexts = {}
RunS.RenderStepped:Connect(function()
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local role = GetRole(p)
            local show = false
            local color = Color3.new(1,1,1)
            if role == "Murderer" and _G.CatalystOptions.murText and _G.CatalystOptions.murText.Value then
                show = true
                color = _G.CatalystOptions.murTxtColor and _G.CatalystOptions.murTxtColor.Value or Color3.fromRGB(255,0,0)
            elseif role == "Sheriff" and _G.CatalystOptions.sherText and _G.CatalystOptions.sherText.Value then
                show = true
                color = _G.CatalystOptions.sherTxtColor and _G.CatalystOptions.sherTxtColor.Value or Color3.fromRGB(0,0,255)
            elseif role == "Innocent" and _G.CatalystOptions.innocText and _G.CatalystOptions.innocText.Value then
                show = true
                color = _G.CatalystOptions.innocTxtColor and _G.CatalystOptions.innocTxtColor.Value or Color3.fromRGB(0,255,0)
            end
            if show then
                local root = p.Character.HumanoidRootPart
                local vec, on = Cam:WorldToViewportPoint(root.Position + Vector3.new(0,2.5,0))
                if on then
                    local txt = nameTexts[p]
                    if not txt and Drawing and Drawing.new then
                        txt = Drawing.new("Text")
                        txt.Center = true
                        txt.Outline = true
                        txt.Size = 14
                        nameTexts[p] = txt
                    end
                    if txt then
                        txt.Text = p.Name .. " (" .. role .. ")"
                        txt.Position = Vector2.new(vec.X, vec.Y)
                        txt.Color = color
                        txt.Visible = true
                    end
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

-- Обновление ролей и подсветки
task.spawn(function()
    while true do
        task.wait(2)
        UpdateRoleCache()
        for _, p in pairs(Plrs:GetPlayers()) do
            pcall(UpdateHighlight, p)
        end
    end
end)

Plrs.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(UpdateHighlight, p)
    end)
end)

local function RefreshHighlights()
    for _, p in pairs(Plrs:GetPlayers()) do UpdateHighlight(p) end
end
_G.CatalystOptions.murHighlight:OnChanged(RefreshHighlights)
_G.CatalystOptions.murColor:OnChanged(RefreshHighlights)
_G.CatalystOptions.sherHighlight:OnChanged(RefreshHighlights)
_G.CatalystOptions.sherColor:OnChanged(RefreshHighlights)
_G.CatalystOptions.innocHighlight:OnChanged(RefreshHighlights)
_G.CatalystOptions.innocColor:OnChanged(RefreshHighlights)

-- AIMBOT
local function GetTarget()
    local myRole = GetRole(LP)
    if myRole == "Innocent" then return nil end
    local best, bestAngle = nil, math.huge
    local fov = _G.CatalystOptions.fovSlider and _G.CatalystOptions.fovSlider.Value or 80
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

-- FOV Circle
local fovCircle = nil
if Drawing and Drawing.new then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Filled = false
    fovCircle.Transparency = 1
end

RunS.RenderStepped:Connect(function()
    if fovCircle and _G.CatalystOptions.aimToggle and _G.CatalystOptions.aimToggle.Value then
        fovCircle.Visible = true
        local f = _G.CatalystOptions.fovSlider and _G.CatalystOptions.fovSlider.Value or 80
        fovCircle.Radius = (f / 360) * Cam.ViewportSize.X
        fovCircle.Color = _G.CatalystOptions.fovColor and _G.CatalystOptions.fovColor.Value or Color3.fromRGB(255,255,255)
        fovCircle.Position = UIS:GetMouseLocation()
    elseif fovCircle then
        fovCircle.Visible = false
    end
end)

RunS.RenderStepped:Connect(function()
    if not (_G.CatalystOptions.aimToggle and _G.CatalystOptions.aimToggle.Value) then return end
    local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (_G.CatalystOptions.aimKey and _G.CatalystOptions.aimKey:GetState())
    if press then
        local target = GetTarget()
        if target then
            local pos = target.Position
            if _G.CatalystOptions.predToggle and _G.CatalystOptions.predToggle.Value then
                local delay = (_G.CatalystOptions.predSlider and _G.CatalystOptions.predSlider.Value or 80) / 1000
                pos = pos + (target.Velocity * delay)
            end
            Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
        end
    end
end)

-- NOCLIP, FLY, SPEED
RunS.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return end
    if _G.CatalystOptions.speed and _G.CatalystOptions.speed.Value then
        hum.WalkSpeed = _G.CatalystOptions.speedVal and _G.CatalystOptions.speedVal.Value or 50
    else
        hum.WalkSpeed = 16
    end
    if _G.CatalystOptions.noclip and _G.CatalystOptions.noclip.Value then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if _G.CatalystOptions.fly and _G.CatalystOptions.fly.Value then
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            root.Velocity = Vector3.new(root.Velocity.X, 60, root.Velocity.Z)
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            root.Velocity = Vector3.new(root.Velocity.X, -60, root.Velocity.Z)
        else
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if _G.CatalystOptions.fly and _G.CatalystOptions.fly.Value and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- AUTO CHEAT SCAN
task.spawn(function()
    while true do
        task.wait(5)
        if _G.CatalystOptions.autoCheat and _G.CatalystOptions.autoCheat.Value then
            pcall(ScanCheaters)
        end
    end
end)

-- Очистка при смене персонажа
LP.CharacterAdded:Connect(function()
    for _, txt in pairs(nameTexts) do
        if txt and txt.Remove then txt:Remove() end
    end
    nameTexts = {}
    tpCooldown = false
    lastTP = 0
    if _G.CatalystOptions.cooldownPara then _G.CatalystOptions.cooldownPara:SetContent("Ready") end
end)
