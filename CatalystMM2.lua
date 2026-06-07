-- ========================================================
-- CATALYST MM2 v3.9.1 (FIXED LOADSTRING ERROR)
-- ========================================================
local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

local isMobile = UIS.TouchEnabled or not UIS.MouseEnabled

-- Безопасная загрузка с повторными попытками
local function LoadLibrary(url, name)
    for i = 1, 3 do
        local success, result = pcall(game.HttpGet, game, url)
        if success and type(result) == "string" and #result > 100 then
            local func, err = loadstring(result)
            if func then
                return func()
            else
                warn("[Catalyst] Error compiling " .. name .. ": " .. err)
            end
        else
            warn("[Catalyst] Failed to download " .. name .. ", attempt " .. i)
        end
        task.wait(1)
    end
    error("[Catalyst] Could not load " .. name)
end

local Fluent = LoadLibrary("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent")
local SaveManager = LoadLibrary("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager")
local InterfaceManager = LoadLibrary("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager")

_G.CatalystKeyType = _G.CatalystKeyType or "Free"
_G.CatalystRank = _G.CatalystRank or "Standard"

-- ========== ОПРЕДЕЛЕНИЕ РОЛЕЙ ==========
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

local function UpdateRoleCache()
    lastRoleUpdate = tick()
    for _, p in pairs(Plrs:GetPlayers()) do
        GetRole(p)
    end
end

local function HasGun()
    local char = LP.Character
    return char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) ~= nil
end

local function IsMurderer()
    return GetRole(LP) == "Murderer"
end

-- ========== ПОИСК GUN DROP ==========
local function FindGunDrop()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name == "Revolver") then
            if obj:FindFirstChild("Handle") then return obj.Handle
            elseif obj:FindFirstChild("PrimaryPart") then return obj.PrimaryPart
            else return obj:FindFirstChildWhichIsA("BasePart") end
        end
    end
    return nil
end

-- ========== ПОИСК KILL REMOTE ==========
local KillRemote = nil
local function FindKillRemote()
    if KillRemote then return KillRemote end
    local possibleNames = {"MainEvent", "KillPlayer", "Hit", "Attack", "Damage", "KillRemote", "ServerEvent", "RemoteEvent"}
    for _, name in pairs(possibleNames) do
        local rem = RS:FindFirstChild(name)
        if rem and (rem:IsA("RemoteEvent") or rem:IsA("UnreliableRemoteEvent")) then
            KillRemote = rem
            return KillRemote
        end
    end
    for _, obj in pairs(RS:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            KillRemote = obj
            return KillRemote
        end
    end
    return nil
end

local function KillPlayer(target)
    local rem = FindKillRemote()
    if rem then
        pcall(function()
            rem:FireServer(target)
            rem:FireServer(target.Character or target)
            rem:FireServer(target.Name)
        end)
    else
        -- Запасной метод: телепорт + удар
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHrp then
            local oldPos = hrp.CFrame
            hrp.CFrame = targetHrp.CFrame
            task.wait(0.05)
            hrp.CFrame = oldPos
        end
    end
end

-- ========== KILL ALL (только Murderer) ==========
local function KillAll()
    if not IsMurderer() then
        Fluent:Notify({ Title = "Error", Content = "You are not Murderer!", Duration = 2 })
        return
    end
    local targets = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(targets, p)
        end
    end
    if #targets == 0 then
        Fluent:Notify({ Title = "Kill All", Content = "No valid targets", Duration = 2 })
        return
    end
    for _, p in ipairs(targets) do
        KillPlayer(p)
        task.wait(0.05)
    end
    Fluent:Notify({ Title = "Kill All", Content = #targets .. " player(s) killed", Duration = 2 })
end

-- ========== KILL MURDERER (только с оружием) ==========
local function KillMurderer()
    if not HasGun() then
        Fluent:Notify({ Title = "Error", Content = "You need a gun!", Duration = 2 })
        return
    end
    local targets = {}
    for _, p in pairs(Plrs:GetPlayers()) do
        if p ~= LP and GetRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(targets, p)
        end
    end
    if #targets == 0 then
        Fluent:Notify({ Title = "Kill Murderer", Content = "No Murderer found", Duration = 2 })
        return
    end
    for _, p in ipairs(targets) do
        KillPlayer(p)
        task.wait(0.05)
    end
    Fluent:Notify({ Title = "Kill Murderer", Content = #targets .. " Murderer(s) killed", Duration = 2 })
end

-- ========== АВТО-КИЛЛ ФАРМ ==========
local autoKillEnabled = false
local lastKillTime = 0
local function AutoKillFarm()
    if not autoKillEnabled then return end
    local now = tick()
    if now - lastKillTime < 1.5 then return end
    local myRole = GetRole(LP)
    if myRole == "Murderer" then
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and GetRole(p) == "Innocent" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                KillPlayer(p)
                lastKillTime = now
                break
            end
        end
    elseif myRole == "Sheriff" and HasGun() then
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and GetRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                KillPlayer(p)
                lastKillTime = now
                break
            end
        end
    end
end

-- ========== ПОИСК COIN_SERVER ==========
local CoinServerPart = nil
local lastCoinLog = 0
local coinLogCount = 0

local function GetCoinServer()
    if CoinServerPart and CoinServerPart.Parent then return CoinServerPart end
    local container = workspace:FindFirstChild("CoinContainer")
    if container then
        CoinServerPart = container:FindFirstChild("Coin_Server") or container:FindFirstChild("CoinServer")
        if CoinServerPart and CoinServerPart:IsA("BasePart") then
            return CoinServerPart
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name and (obj.Name == "Coin_Server" or obj.Name == "CoinServer") and obj:IsA("BasePart") then
            CoinServerPart = obj
            return CoinServerPart
        end
    end
    -- Логируем в консоль с группировкой
    local now = tick()
    if now - lastCoinLog > 5 then
        coinLogCount = 1
        lastCoinLog = now
        print("[Catalyst] CoinServer not found (x1)")
    else
        coinLogCount = coinLogCount + 1
        if coinLogCount % 10 == 0 then
            print("[Catalyst] CoinServer not found (x" .. coinLogCount .. ")")
        end
    end
    return nil
end

local farmCooldown = false
local function FarmCoins()
    if farmCooldown then return end
    local cs = GetCoinServer()
    if not cs then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    farmCooldown = true
    local originalPos = hrp.CFrame
    hrp.CFrame = cs.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.2)
    if hrp and hrp.Parent then
        hrp.CFrame = originalPos
    end
    task.wait(0.5)
    farmCooldown = false
end

-- ========== GUI ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v3.9.1" .. (isMobile and " [Mobile]" or ""),
    SubTitle = "MM2",
    TabWidth = 160,
    Size = UDim2.fromOffset(660, 620),
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
Tabs.Home:AddParagraph({ Title = "Catalyst", Content = "Rank: " .. rankText .. "\nMM2\nAlchemist Slime\nTG: @alchemistslimee\nVersion 3.9.1" })
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

Tabs.Combat:AddSection("Kill & Farm")
local killAllBtn = Tabs.Combat:AddButton({ Title = "Kill All (Murderer only)", Callback = function() KillAll() end })
local killMurderBtn = Tabs.Combat:AddButton({ Title = "Kill Murderer (requires gun)", Callback = function() KillMurderer() end })
local farmBtn = Tabs.Combat:AddButton({ Title = "Farm Coins (once)", Callback = function() FarmCoins() end })
local autoFarm = Tabs.Combat:AddToggle("autoFarm", { Title = "Auto Farm Coins (every 2s)", Default = false })
local autoKillToggle = Tabs.Combat:AddToggle("autoKill", { Title = "Auto Kill Farm (Murderer→Innocent / Sheriff→Murderer)", Default = false })
autoKillToggle:OnChanged(function(val) autoKillEnabled = val end)

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

-- ========== GUN DROP КОД ==========
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
    if not gd then return false end
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

-- ========== AIMBOT ==========
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
    aimToggle.Enabled = false
end

-- ========== ESP ==========
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

-- ========== АВТОФАРМ И АВТО-КИЛЛ (ЦИКЛЫ) ==========
task.spawn(function()
    while true do
        task.wait(2)
        if autoFarm and autoFarm.Value then
            pcall(FarmCoins)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(AutoKillFarm)
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
