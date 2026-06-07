-- ========================================================
-- CATALYST MM2 v2.9.0 (FIXED)
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

-- Загрузка Fluent (только UI)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local roleCache = {}
local lastRoleUpdate = 0

local function GetRole(p)
    if not p or not p.Character then return "Innocent" end
    local now = tick()
    if roleCache[p] and (now - lastRoleUpdate) < 1.5 then return roleCache[p] end
    local role = "Innocent"
    local char = p.Character
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

-- ========== GUI ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v2.9.0",
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
local rank = (_G.CatalystKeyType or "Free") .. " / " .. (_G.CatalystRank or "Standard")
Tabs.Home:AddParagraph({ Title = "Catalyst", Content = "Rank: " .. rank .. "\nMM2\nAlchemist Slime" })
Tabs.Home:AddButton({ Title = "Copy Discord", Callback = function() setclipboard("alchemistslimee") Fluent:Notify({Title="Copied"}) end })

-- ========== COMBAT ==========
Tabs.Combat:AddSection("Aimbot")
local aimToggle = Tabs.Combat:AddToggle("aim", { Title = "Enable Aimbot", Default = false })
local predToggle = Tabs.Combat:AddToggle("pred", { Title = "Prediction", Default = false })
local predSlider = Tabs.Combat:AddSlider("predDelay", { Title = "Prediction ms", Default = 80, Min = 0, Max = 100 })
local fovSlider = Tabs.Combat:AddSlider("fov", { Title = "FOV Degrees", Default = 80, Min = 1, Max = 360 })
local fovColor = Tabs.Combat:AddColorpicker("fovColor", { Title = "FOV Color", Default = Color3.fromRGB(255,255,255) })
local keybind = Tabs.Combat:AddKeybind("aimKey", { Title = "Aimbot Key", Mode = "Hold", Default = "MouseRight" })

-- Gun Drop Teleport
Tabs.Combat:AddSection("Gun Drop")
local tpBtn = Tabs.Combat:AddButton({ Title = "TP to Gun Drop", Callback = function() teleportToGunDrop(true) end })
local autoTP = Tabs.Combat:AddToggle("autoTP", { Title = "Auto TP (1s)", Default = false })
local safeTP = Tabs.Combat:AddToggle("safeTP", { Title = "Avoid Murderer within 5 studs", Default = true })
local cooldownPara = Tabs.Combat:AddParagraph({ Title = "Cooldown", Content = "Ready" })

-- Fling
Tabs.Combat:AddSection("Fling")
local antiFling = Tabs.Combat:AddToggle("antiFling", { Title = "Anti-Fling (basic)", Default = false })
local flingAll = Tabs.Combat:AddButton({ Title = "Fling All", Callback = function() flingPlayers("All") end })
local flingMurder = Tabs.Combat:AddButton({ Title = "Fling Murderers", Callback = function() flingPlayers("Murderer") end })
local flingSheriff = Tabs.Combat:AddButton({ Title = "Fling Sheriffs", Callback = function() flingPlayers("Sheriff") end })

-- Blacklist
Tabs.Combat:AddSection("Blacklist")
local blacklistDropdown = Tabs.Combat:AddDropdown("blacklist", { Title = "Ignore these players", Values = {}, Multi = true, Default = {} })
local function refreshBlacklist()
    local names = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    blacklistDropdown:SetValues(names)
end
refreshBlacklist()
Plrs.PlayerAdded:Connect(refreshBlacklist)
Plrs.PlayerRemoved:Connect(refreshBlacklist)

-- ========== VISUALS ==========
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

-- Gun Drop visuals
Tabs.Visuals:AddSection("Gun Drop Visual")
local gdHighlight = Tabs.Visuals:AddToggle("gdHl", { Title = "Highlight Gun Drop", Default = false })
local gdColor = Tabs.Visuals:AddColorpicker("gdCol", { Title = "Highlight Color", Default = Color3.fromRGB(128,0,255) })
local gdText = Tabs.Visuals:AddToggle("gdTxt", { Title = "Show Text", Default = true })
local gdTxtColor = Tabs.Visuals:AddColorpicker("gdTxtCol", { Title = "Text Color", Default = Color3.fromRGB(255,255,255) })

-- ========== MISC ==========
Tabs.Misc:AddSection("Movement")
local noclip = Tabs.Misc:AddToggle("noclip", { Title = "No-Clip", Default = false })
local fly = Tabs.Misc:AddToggle("fly", { Title = "Fly", Default = false })
local speedHack = Tabs.Misc:AddToggle("speed", { Title = "Speedhack", Default = false })
local speedVal = Tabs.Misc:AddSlider("speedVal", { Title = "Speed (walk)", Default = 50, Min = 16, Max = 250 })

Tabs.Misc:AddSection("Cheater Detection")
local cheatPara = Tabs.Misc:AddParagraph({ Title = "Suspicious", Content = "None" })
local autoCheat = Tabs.Misc:AddToggle("autoCheat", { Title = "Auto Scan (5s)", Default = false })
Tabs.Misc:AddButton({ Title = "Scan Now", Callback = function() scanCheaters() end })

-- ========== ЛОГИКА ==========
-- Gun Drop поиск
local gunDropPart = nil
local gunDropHighlight = nil
local gunDropText = nil
local lastGunSearch = 0
local cachedGun = nil

local function findGunDrop()
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

local function updateGunDropVisuals()
    if hasRevolver() then
        if gunDropHighlight then gunDropHighlight:Destroy(); gunDropHighlight = nil end
        if gunDropText then gunDropText:Remove(); gunDropText = nil end
        gunDropPart = nil
        return
    end
    local gd = findGunDrop()
    gunDropPart = gd
    if gd then
        if gdHighlight and gdHighlight.Value then
            if not gunDropHighlight or gunDropHighlight.Parent ~= gd then
                if gunDropHighlight then gunDropHighlight:Destroy() end
                gunDropHighlight = Instance.new("Highlight")
                local base = gdColor and gdColor.Value or Color3.fromRGB(128,0,255)
                local h,s,v = base:ToHSV()
                local darker = Color3.fromHSV(h, s, math.max(v*0.8, 0))
                gunDropHighlight.FillColor = darker
                gunDropHighlight.OutlineColor = base
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
                gunDropText.Text = "GUN DROP"
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

task.spawn(function() while true do task.wait(0.2) pcall(updateGunDropVisuals) end end)

-- RenderStepped для плавного движения текста
RunS.RenderStepped:Connect(function()
    if gunDropText and gunDropText.Visible and gunDropPart then
        local pos, on = Cam:WorldToViewportPoint(gunDropPart.Position + Vector3.new(0,1.5,0))
        if on then gunDropText.Position = Vector2.new(pos.X, pos.Y) end
    end
end)

local function hasRevolver()
    local c = LP.Character
    return c and c:FindFirstChild("Revolver") ~= nil
end

local tpCooldown = false
local lastTP = 0
function teleportToGunDrop(returnBack)
    if tpCooldown then
        cooldownPara:SetContent("Cooldown " .. math.ceil(3 - (tick()-lastTP)) .. "s")
        return false
    end
    if hasRevolver() then return false end
    local gd = findGunDrop()
    if not gd then return false end
    if safeTP and safeTP.Value then
        local nearby = false
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and GetRole(p)=="Murderer" then
                if (p.Character.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude < 5 then
                    nearby = true; break
                end
            end
        end
        if nearby then
            Fluent:Notify({Title="Safe TP", Content="Murderer nearby", Duration=1})
            return false
        end
    end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local orig = hrp.CFrame
    hrp.CFrame = gd.CFrame * CFrame.new(0,2,0)
    task.wait(0.1)
    if returnBack then hrp.CFrame = orig end
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
        if autoTP and autoTP.Value and not tpCooldown and not hasRevolver() then
            pcall(teleportToGunDrop, true)
        end
    end
end)

-- Fling (упрощённый, без Velocity, просто телепорт вверх и назад)
function flingPlayers(targetType)
    local black = Options.blacklist and Options.blacklist.Value or {}
    local targets = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and not table.find(black, p.Name) then
            local role = GetRole(p)
            if targetType == "All" then table.insert(targets, p)
            elseif targetType == "Murderer" and role=="Murderer" then table.insert(targets, p)
            elseif targetType == "Sheriff" and role=="Sheriff" then table.insert(targets, p) end
        end
    end
    if #targets == 0 then Fluent:Notify({Title="Fling", Content="No targets"}) return end
    local origPos = {}
    for _, p in ipairs(targets) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            origPos[p] = hrp.CFrame
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 50, 0) -- подбросить
        end
    end
    task.wait(0.3)
    for p, cf in pairs(origPos) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = cf end
    end
    Fluent:Notify({Title="Fling", Content=#targets.." players flung"})
end

-- Anti-Fling (простой)
local lastPos = nil
RunS.RenderStepped:Connect(function()
    if antiFling and antiFling.Value then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cur = hrp.Position
            if lastPos and (cur - lastPos).Magnitude > 40 then
                hrp.CFrame = CFrame.new(lastPos)
                Fluent:Notify({Title="Anti-Fling", Content="Blocked", Duration=1})
            end
            lastPos = cur
        end
    else
        lastPos = nil
    end
end)

-- Aimbot
local function getTarget()
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

-- FOV Circle
local fovCircle = nil
if (typeof(Drawing) == "table" and Drawing.new) then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Filled = false
    fovCircle.Transparency = 1
end

RunS.RenderStepped:Connect(function()
    if fovCircle and aimToggle and aimToggle.Value then
        fovCircle.Visible = true
        local f = fovSlider and fovSlider.Value or 80
        fovCircle.Radius = (f / 360) * Cam.ViewportSize.X
        fovCircle.Color = fovColor and fovColor.Value or Color3.fromRGB(255,255,255)
        fovCircle.Position = UIS:GetMouseLocation()
    elseif fovCircle then
        fovCircle.Visible = false
    end
end)

RunS.RenderStepped:Connect(function()
    if not (aimToggle and aimToggle.Value) then return end
    local press = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (keybind and keybind:GetState())
    if press then
        local target = getTarget()
        if target then
            local pos = target.Position
            if predToggle and predToggle.Value then
                local delay = (predSlider and predSlider.Value or 80) / 1000
                pos = pos + (target.Velocity * delay)
            end
            Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, pos)
        end
    end
end)

-- ESP Highlight
local function updateHighlight(p)
    if not p or p==LP or not p.Character then return end
    local role = GetRole(p)
    local hl = p.Character:FindFirstChild("Catalyst_HL")
    local show = false
    local base = Color3.new(1,1,1)
    if role=="Murderer" and murHighlight and murHighlight.Value then show=true; base=murColor and murColor.Value or Color3.fromRGB(255,0,0)
    elseif role=="Sheriff" and sherHighlight and sherHighlight.Value then show=true; base=sherColor and sherColor.Value or Color3.fromRGB(0,0,255)
    elseif role=="Innocent" and innocHighlight and innocHighlight.Value then show=true; base=innocColor and innocColor.Value or Color3.fromRGB(0,255,0)
    end
    if show then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "Catalyst_HL"
            hl.Parent = p.Character
        end
        local h,s,v = base:ToHSV()
        local dark = Color3.fromHSV(h, s, math.max(v*0.8, 0))
        hl.FillColor = dark
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
        if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = GetRole(p)
            local show = false
            local col = Color3.new(1,1,1)
            if role=="Murderer" and murText and murText.Value then show=true; col=murTxtColor and murTxtColor.Value or Color3.fromRGB(255,0,0)
            elseif role=="Sheriff" and sherText and sherText.Value then show=true; col=sherTxtColor and sherTxtColor.Value or Color3.fromRGB(0,0,255)
            elseif role=="Innocent" and innocText and innocText.Value then show=true; col=innocTxtColor and innocTxtColor.Value or Color3.fromRGB(0,255,0)
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
                    txt.Color = col
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

-- Cheater Detection
function scanCheaters()
    local suspects = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p~=LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.WalkSpeed > 18 then
                table.insert(suspects, p.Name.." (Speed: "..math.floor(hum.WalkSpeed)..")")
            end
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and root.CanCollide == false then
                table.insert(suspects, p.Name.." (Noclip)")
            end
        end
    end
    if #suspects>0 then
        cheatPara:SetContent(table.concat(suspects, "\n"))
        Fluent:Notify({Title="Cheaters", Content=#suspects.." found", Duration=2})
    else
        cheatPara:SetContent("None")
        Fluent:Notify({Title="Scan", Content="Clean"})
    end
end
task.spawn(function()
    while true do
        task.wait(5)
        if autoCheat and autoCheat.Value then pcall(scanCheaters) end
    end
end)

-- Misc: Noclip, Fly, Speed
RunS.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root then
        if speedHack and speedHack.Value then hum.WalkSpeed = speedVal and speedVal.Value or 50 else hum.WalkSpeed = 16 end
        if noclip and noclip.Value then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        if fly and fly.Value then
            if UIS:IsKeyDown(Enum.KeyCode.Space) then root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
            elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then root.Velocity = Vector3.new(root.Velocity.X, -50, root.Velocity.Z)
            else root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z) end
        end
    end
end)
UIS.JumpRequest:Connect(function()
    if fly and fly.Value and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- Обновление ролей
task.spawn(function()
    while true do
        task.wait(2)
        lastRoleUpdate = tick()
        for _, p in pairs(Plrs:GetPlayers()) do GetRole(p) end
        for _, p in pairs(Plrs:GetPlayers()) do pcall(updateHighlight, p) end
    end
end)

-- События
Plrs.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(updateHighlight, p)
    end)
end)
local function refreshHL() for _,p in pairs(Plrs:GetPlayers()) do updateHighlight(p) end end
murHighlight:OnChanged(refreshHL); murColor:OnChanged(refreshHL)
sherHighlight:OnChanged(refreshHL); sherColor:OnChanged(refreshHL)
innocHighlight:OnChanged(refreshHL); innocColor:OnChanged(refreshHL)

-- SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/MM2")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)

LP.CharacterAdded:Connect(function()
    for _,t in pairs(nameTexts) do if t and t.Remove then t:Remove() end end
    nameTexts = {}
    tpCooldown = false
    lastTP = 0
    cooldownPara:SetContent("Ready")
end)
