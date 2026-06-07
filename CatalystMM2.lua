-- ========================================================
-- CATALYST MM2 v3.5 (FULLY WORKING + MOBILE SUPPORT)
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

-- Определяем устройство
local isMobile = UIS.TouchEnabled or not UIS.MouseEnabled

-- Загрузка Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ========== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ==========
_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"

-- ========== ОПРЕДЕЛЕНИЕ РОЛЕЙ (МГНОВЕННО) ==========
local roleCache = {}
local lastRoleUpdate = 0

local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    local now = tick()
    if roleCache[p] and (now - lastRoleUpdate) < 1.5 then
        return roleCache[p]
    end
    local char = p.Character
    local role = "Innocent"
    -- Проверка убийцы (ножик в руке или в рюкзаке)
    if char:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) or char:FindFirstChild("MurdererEffect") then
        role = "Murderer"
    -- Проверка шерифа (пистолет в руке или в рюкзаке)
    elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or (p.Backpack and (p.Backpack:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Revolver"))) then
        role = "Sheriff"
    else
        -- Резерв: данные из RoundView (для начала раунда)
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

-- ========== ПОИСК GUN DROP (НЕ ЗАВИСИТ ОТ ИМЕНИ) ==========
local function FindGunDrop()
    -- Ищем объект класса Tool в workspace с именем "Gun" или "Revolver"
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name == "Revolver") then
            -- Возвращаем PrimaryPart или HumanoidRootPart (если есть)
            if obj:FindFirstChild("Handle") then
                return obj.Handle
            elseif obj:FindFirstChild("PrimaryPart") then
                return obj.PrimaryPart
            else
                return obj:FindFirstChildWhichIsA("BasePart")
            end
        end
    end
    return nil
end

local function HasGun()
    local char = LP.Character
    return char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) ~= nil
end

-- ========== GUI (FLUENT) ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v3.5" .. (isMobile and " [Mobile]" or ""),
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
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
Tabs.Home:AddParagraph({ Title = "Catalyst", Content = "Rank: " .. rankText .. "\nMM2\nAlchemist Slime\nTG: @alchemistslimee" })
Tabs.Home:AddButton({ Title = "Copy Discord", Callback = function() setclipboard("alchemistslimee") Fluent:Notify({ Title = "Copied" }) end })

-- ========== COMBAT TAB ==========
Tabs.Combat:AddSection("Aimbot" .. (isMobile and " (Disabled on Mobile)" or ""))
local aimToggle = Tabs.Combat:AddToggle("aim", { Title = "Enable Aimbot", Default = false, Enabled = not isMobile })
local predToggle = Tabs.Combat:AddToggle("pred", { Title = "Prediction", Default = false, Enabled = not isMobile })
local predDelay = Tabs.Combat:AddSlider("predDelay", { Title = "Prediction ms", Default = 80, Min = 0, Max = 100, Rounding = 0 })
local aimKey = Tabs.Combat:AddKeybind("aimKey", { Title = "Aimbot Key", Mode = "Hold", Default = "MouseRight" })
local fovSlider = Tabs.Combat:AddSlider("fov", { Title = "FOV Degrees", Default = 80, Min = 1, Max = 360, Rounding = 0 })
local fovColor = Tabs.Combat:AddColorpicker("fovColor", { Title = "FOV Color", Default = Color3.fromRGB(255,255,255) })

Tabs.Combat:AddSection("Gun Drop Teleport")
local tpBtn = Tabs.Combat:AddButton({ Title = "TP to Gun (once)", Callback = function() TeleportToGunDrop(true) end })
local autoTP = Tabs.Combat:AddToggle("autoTP", { Title = "Auto TP every 1s", Default = false })
local safeTP = Tabs.Combat:AddToggle("safeTP", { Title = "Avoid Murderer", Default = true })
local cooldownPara = Tabs.Combat:AddParagraph({ Title = "Cooldown", Content = "Ready" })

Tabs.Combat:AddSection("Fling (Speed 9999)")
local flingAll = Tabs.Combat:AddButton({ Title = "Fling All", Callback = function() FlingPlayers("All") end })
local flingMurder = Tabs.Combat:AddButton({ Title = "Fling Murderers", Callback = function() FlingPlayers("Murderer") end })
local flingSheriff = Tabs.Combat:AddButton({ Title = "Fling Sheriffs", Callback = function() FlingPlayers("Sheriff") end })

Tabs.Combat:AddSection("Blacklist")
local blacklistDropdown = Tabs.Combat:AddDropdown("blacklist", { Title = "Ignore players", Values = {}, Multi = true, Default = {} })
local function RefreshBlacklist()
    local names = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    blacklistDropdown:SetValues(names)
end
RefreshBlacklist()
Plrs.PlayerAdded:Connect(RefreshBlacklist)
Plrs.PlayerRemoving:Connect(RefreshBlacklist)

-- ========== VISUALS TAB ==========
-- Murderer
Tabs.Visuals:AddSection("Murderer")
local murHighlight = Tabs.Visuals:AddToggle("murHl", { Title = "Highlight", Default = false })
local murColor = Tabs.Visuals:AddColorpicker("murCol", { Title = "Color", Default = Color3.fromRGB(255,0,0) })
local murText = Tabs.Visuals:AddToggle("murTxt", { Title = "Name ESP", Default = false })
local murTxtColor = Tabs.Visuals:AddColorpicker("murTxtCol", { Title = "Text Color", Default = Color3.fromRGB(255,0,0) })
-- Sheriff
Tabs.Visuals:AddSection("Sheriff")
local sherHighlight = Tabs.Visuals:AddToggle("sherHl", { Title = "Highlight", Default = false })
local sherColor = Tabs.Visuals:AddColorpicker("sherCol", { Title = "Color", Default = Color3.fromRGB(0,0,255) })
local sherText = Tabs.Visuals:AddToggle("sherTxt", { Title = "Name ESP", Default = false })
local sherTxtColor = Tabs.Visuals:AddColorpicker("sherTxtCol", { Title = "Text Color", Default = Color3.fromRGB(0,0,255) })
-- Innocent
Tabs.Visuals:AddSection("Innocent")
local innocHighlight = Tabs.Visuals:AddToggle("innHl", { Title = "Highlight", Default = false })
local innocColor = Tabs.Visuals:AddColorpicker("innCol", { Title = "Color", Default = Color3.fromRGB(0,255,0) })
local innocText = Tabs.Visuals:AddToggle("innTxt", { Title = "Name ESP", Default = false })
local innocTxtColor = Tabs.Visuals:AddColorpicker("innTxtCol", { Title = "Text Color", Default = Color3.fromRGB(0,255,0) })
-- Gun Drop
Tabs.Visuals:AddSection("Gun Drop")
local gdHighlight = Tabs.Visuals:AddToggle("gdHl", { Title = "Highlight", Default = false })
local gdColor = Tabs.Visuals:AddColorpicker("gdCol", { Title = "Color", Default = Color3.fromRGB(128,0,255) })
local gdText = Tabs.Visuals:AddToggle("gdTxt", { Title = "Show Text", Default = true })
local gdTxtColor = Tabs.Visuals:AddColorpicker("gdTxtCol", { Title = "Text Color", Default = Color3.fromRGB(255,255,255) })

-- ========== MISC TAB ==========
Tabs.Misc:AddSection("Movement")
local noclip = Tabs.Misc:AddToggle("noclip", { Title = "No-Clip", Default = false })
local fly = Tabs.Misc:AddToggle("fly", { Title = "Fly", Default = false })
local speed = Tabs.Misc:AddToggle("speed", { Title = "Speedhack", Default = false })
local speedVal = Tabs.Misc:AddSlider("speedVal", { Title = "Speed", Default = 50, Min = 16, Max = 250, Rounding = 0 })

Tabs.Misc:AddSection("Cheater Detection")
local cheatPara = Tabs.Misc:AddParagraph({ Title = "Suspects", Content = "None" })
local autoCheat = Tabs.Misc:AddToggle("autoCheat", { Title = "Auto Scan", Default = false })
Tabs.Misc:AddButton({ Title = "Scan Now", Callback = function() detectCheaters() end })

-- ========== ФУНКЦИЯ FLING (РАЗГОН 9999) ==========
function FlingPlayers(targetType)
    local blacklist = Options.blacklist or {}
    local blackVal = blacklist.Value or {}
    local targets = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and not table.find(blackVal, p.Name) then
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
    for _, p in ipairs(targets) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Случайное направление с сильным вертикальным компонентом
            local dir = Vector3.new(math.random(-100, 100), math.random(80, 150), math.random(-100, 100)).Unit
            hrp.Velocity = dir * 9999
            -- Отключаем коллизию на 0.1 сек, чтобы пролетел сквозь стены
            hrp.CanCollide = false
            task.wait(0.1)
            hrp.CanCollide = true
        end
    end
    Fluent:Notify({ Title = "Fling", Content = #targets .. " player(s) flung", Duration = 2 })
end

-- ========== GUN DROP (ТЕЛЕПОРТ И ПОДСВЕТКА) ==========
local gunDropPart = nil
local gunDropHighlight = nil
local gunDropText = nil
local tpCooldown = false
local lastTP = 0

local function UpdateGunDropVisuals()
    if HasGun() then
        if gunDropHighlight then gunDropHighlight:Destroy(); gunDropHighlight = nil end
        if gunDropText then gunDropText:Remove(); gunDropText = nil end
        gunDropPart = nil
        return
    end
    local gd = FindGunDrop()
    gunDropPart = gd
    if gd then
        if gdHighlight and gdHighlight.Value then
            if not gunDropHighlight or gunDropHighlight.Parent ~= gd then
                if gunDropHighlight then gunDropHighlight:Destroy() end
                gunDropHighlight = Instance.new("Highlight")
                local base = gdColor and gdColor.Value or Color3.fromRGB(128,0,255)
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
        if gdText and gdText.Value then
            if not gunDropText then
                gunDropText = Drawing.new("Text")
                gunDropText.Center = true
                gunDropText.Outline = true
                gunDropText.Size = 16
            end
            local pos, on = Cam:WorldToViewportPoint(gd.Position + Vector3.new(0,1.5,0))
            if on then
                gunDropText.Position = Vector2.new(pos.X, pos.Y)
                gunDropText.Text = "GUN"
                gunDropText.Color = gdTxtColor and gdTxtColor.Value or Color3.fromRGB(255,255,255)
                gunDropText.Visible = true
            else
                gunDropText.Visible = false
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

-- Плавное движение текста
RunS.RenderStepped:Connect(function()
    if gunDropText and gunDropText.Visible and gunDropPart then
        local pos, on = Cam:WorldToViewportPoint(gunDropPart.Position + Vector3.new(0,1.5,0))
        if on then gunDropText.Position = Vector2.new(pos.X, pos.Y) end
    end
end)

function TeleportToGunDrop(returnBack)
    if tpCooldown then
        cooldownPara:SetContent("Cooldown " .. math.ceil(3 - (tick() - lastTP)) .. "s")
        return false
    end
    if HasGun() then return false end
    local gd = FindGunDrop()
    if not gd then
        Fluent:Notify({ Title = "Gun Drop", Content = "No gun found", Duration = 1 })
        return false
    end
    if safeTP and safeTP.Value then
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
    hrp.CFrame = gd.CFrame * CFrame.new(0,2,0)
    task.wait(0.1)
    if returnBack and hrp and hrp.Parent then
        hrp.CFrame = orig
    end
    tpCooldown = true
    lastTP = tick()
    cooldownPara:SetContent("Cooldown 3s")
    task.wait(3)
    tpCooldown = false
    cooldownPara:SetContent("Ready")
    return true
end

task.spawn(function()
    while true do
        task.wait(1)
        if autoTP and autoTP.Value and not tpCooldown and not HasGun() then
            pcall(TeleportToGunDrop, true)
        end
    end
end)

-- ========== AIMBOT (ТОЛЬКО НЕ НА ТЕЛЕФОНЕ) ==========
if not isMobile then
    local function GetTarget()
        local myRole = GetRole(LP)
        if myRole == "Innocent" then return nil end
        local best, bestAngle = nil, math.huge
        local fov = fovSlider and fovSlider.Value or 80
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
        if aimToggle and aimToggle.Value then
            fovCircle.Visible = true
            fovCircle.Radius = (fovSlider and fovSlider.Value or 80) / 360 * Cam.ViewportSize.X
            fovCircle.Color = fovColor and fovColor.Value or Color3.fromRGB(255,255,255)
            fovCircle.Position = UIS:GetMouseLocation()
        else
            fovCircle.Visible = false
        end
    end)

    RunS.RenderStepped:Connect(function()
        if not (aimToggle and aimToggle.Value) then return end
        local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (aimKey and aimKey:GetState())
        if press then
            local target = GetTarget()
            if target then
                local pos = target.Position
                if predToggle and predToggle.Value then
                    local delay = (predDelay and predDelay.Value or 80) / 1000
                    pos = pos + (target.Velocity * delay)
                end
                Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
            end
        end
    end)
else
    -- На телефоне отключаем весь аимбот
    aimToggle.Enabled = false
end

-- ========== ESP (HIGHLIGHT + NAME) ==========
local nameTexts = {}
local function ClearNameESP()
    for _, txt in pairs(nameTexts) do
        if txt and txt.Remove then txt:Remove() end
    end
    nameTexts = {}
end

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
        local darker = Color3.fromHSV(h, s, math.max(v * 0.8, 0))
        hl.FillColor = darker
        hl.OutlineColor = base
        hl.FillTransparency = 0.4
    elseif hl then
        hl:Destroy()
    end
end

RunS.RenderStepped:Connect(function()
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local role = GetRole(p)
            local show = false
            local color = Color3.new(1,1,1)
            if role == "Murderer" and murText and murText.Value then
                show = true
                color = murTxtColor and murTxtColor.Value or Color3.fromRGB(255,0,0)
            elseif role == "Sheriff" and sherText and sherText.Value then
                show = true
                color = sherTxtColor and sherTxtColor.Value or Color3.fromRGB(0,0,255)
            elseif role == "Innocent" and innocText and innocText.Value then
                show = true
                color = innocTxtColor and innocTxtColor.Value or Color3.fromRGB(0,255,0)
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

-- Обновление ролей каждые 2 секунды
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
murHighlight:OnChanged(RefreshHighlights)
murColor:OnChanged(RefreshHighlights)
sherHighlight:OnChanged(RefreshHighlights)
sherColor:OnChanged(RefreshHighlights)
innocHighlight:OnChanged(RefreshHighlights)
innocColor:OnChanged(RefreshHighlights)

local function ClearTextCache()
    ClearNameESP()
end
murText:OnChanged(ClearTextCache)
murTxtColor:OnChanged(ClearTextCache)
sherText:OnChanged(ClearTextCache)
sherTxtColor:OnChanged(ClearTextCache)
innocText:OnChanged(ClearTextCache)
innocTxtColor:OnChanged(ClearTextCache)

-- ========== CHEATER DETECTION ==========
function detectCheaters()
    local suspects = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.WalkSpeed > 18 then
                table.insert(suspects, p.Name .. " (Speed " .. math.floor(hum.WalkSpeed) .. ")")
            end
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and root.CanCollide == false then
                table.insert(suspects, p.Name .. " (Noclip)")
            end
        end
    end
    if #suspects > 0 then
        cheatPara:SetContent(table.concat(suspects, "\n"))
        Fluent:Notify({ Title = "Cheaters", Content = #suspects .. " found", Duration = 3 })
    else
        cheatPara:SetContent("None")
        Fluent:Notify({ Title = "Scan", Content = "Clean", Duration = 2 })
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        if autoCheat and autoCheat.Value then
            pcall(detectCheaters)
        end
    end
end)

-- ========== MISC MOVEMENT ==========
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
        if UIS:IsKeyDown(Enum.KeyCode.Space) or (isMobile and UIS:GetTouchEnabled()) then
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

LP.CharacterAdded:Connect(function()
    ClearNameESP()
    nameTexts = {}
    tpCooldown = false
    lastTP = 0
    cooldownPara:SetContent("Ready")
end)
