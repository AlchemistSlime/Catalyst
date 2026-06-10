-- ========================================================
-- CATALYST MM2 v5.3.7 (Fling fixed, no status notifications)
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

local function HasKnife()
    local char = LP.Character
    return char and char:FindFirstChild("Knife") ~= nil
end

local function HasGun()
    local char = LP.Character
    return char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) ~= nil
end

-- ========== IsMapLoaded / IsDead ==========
local MAP_FOLDERS = {
    "House2", "MilBase", "Office2", "Office3", "Hospital3",
    "Hotel2", "Mansion2", "Factory", "Bank2", "BioLab",
    "PoliceStation", "Workplace"
}

local isMapLoaded = false
local isDead = false
local currentMapName = "None"
local lastMapLoadTime = 0
local deathImmuneUntil = 0

local function checkMapLoaded()
    local found = false
    local mapName = nil
    for _, name in ipairs(MAP_FOLDERS) do
        if workspace:FindFirstChild(name) then
            found = true
            mapName = name
            break
        end
    end
    local prev = isMapLoaded
    isMapLoaded = found
    if found then
        currentMapName = mapName
    else
        currentMapName = "None"
    end

    if not prev and found then
        lastMapLoadTime = tick()
        isDead = false
        deathImmuneUntil = tick() + 15
    elseif prev and not found then
        isDead = false
        deathImmuneUntil = 0
    end
end

local function checkDead()
    if not isMapLoaded then
        isDead = false
        return
    end
    if tick() < deathImmuneUntil then
        isDead = false
        return
    end
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        isDead = false
        return
    end
    local hrp = char.HumanoidRootPart

    local glitch = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GlitchProof" then
            glitch = obj
            break
        end
    end

    if not glitch then
        isDead = false
        return
    end

    local pos = nil
    if glitch:IsA("BasePart") then
        pos = glitch.Position
    elseif glitch:IsA("Model") then
        pos = glitch:GetPivot().Position
    else
        isDead = false
        return
    end

    if pos and (pos - hrp.Position).Magnitude <= 250 then
        isDead = true
    else
        isDead = false
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        local prevMap, prevDead = isMapLoaded, isDead
        pcall(checkMapLoaded)
        pcall(checkDead)
        if (isMapLoaded ~= prevMap) or (isDead ~= prevDead) then
            print(string.format("[Catalyst] Map: %s | Loaded: %s | Dead: %s", currentMapName, tostring(isMapLoaded), tostring(isDead)))
        end
    end
end)

-- ========== ПОИСК GUN DROP ==========
local function findGun()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "GunDrop" and v:IsA("BasePart") then return v end
    end
    return nil
end

-- ========== GUN TP (Murderer не может) ==========
local autoTpGun = false
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoTpGun and not isDead and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            if GetRole(LP) == "Murderer" then continue end
            local gun = findGun()
            if gun then
                local hrp = LP.Character.HumanoidRootPart
                local oldPos = hrp.CFrame
                hrp.CFrame = gun.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.2)
                hrp.CFrame = oldPos
                task.wait(1)
            end
        end
    end
end)

local function TpToGunOnce()
    if isDead then return end
    if GetRole(LP) == "Murderer" then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local gun = findGun()
    if gun then
        local hrp = LP.Character.HumanoidRootPart
        local oldPos = hrp.CFrame
        hrp.CFrame = gun.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.2)
        hrp.CFrame = oldPos
    end
end

-- ========== STAB AURA ==========
local stabAuraEnabled = false
task.spawn(function()
    while true do
        task.wait(0.1)
        if stabAuraEnabled and GetRole(LP) == "Murderer" and HasKnife() then
            local knife = LP.Character:FindFirstChild("Knife") or (LP.Backpack and LP.Backpack:FindFirstChild("Knife"))
            if knife and knife:IsA("Tool") then
                local hum = LP.Character:FindFirstChild("Humanoid")
                if hum then
                    knife:Activate()
                end
            end
        end
    end
end)

-- ========== AUTO EVADE ==========
local autoEvadeEnabled = false
local lastEvadeTime = 0
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoEvadeEnabled and GetRole(LP) ~= "Murderer" and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LP.Character.HumanoidRootPart
            local myPos = myHrp.Position
            local nearestMurderer = nil
            local minDist = 15
            for _, p in pairs(Plrs:GetPlayers()) do
                if p ~= LP and GetRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < minDist then
                        nearestMurderer = p.Character.HumanoidRootPart
                        minDist = dist
                    end
                end
            end
            if nearestMurderer and tick() - lastEvadeTime > 1.5 then
                local evadeDir = (myPos - nearestMurderer.Position).Unit
                local hum = LP.Character:FindFirstChild("Humanoid")
                if hum then hum:ChangeState("Jumping") end
                myHrp.Velocity = evadeDir * Vector3.new(40, 0, 40) + Vector3.new(0, 20, 0)
                lastEvadeTime = tick()
            end
        end
    end
end)

-- ========== FAKE LAG ==========
local fakeLagEnabled = false
local fakeLagPing = 500

task.spawn(function()
    while true do
        task.wait(0.1)
        if fakeLagEnabled and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            local oldVel = hrp.Velocity
            hrp.Velocity = Vector3.zero
            task.wait(fakeLagPing / 1000)
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                LP.Character.HumanoidRootPart.Velocity = oldVel
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end)

-- ========== INFINITY JUMP + SHIFT ==========
local infinityJumpEnabled = false
RunS.RenderStepped:Connect(function()
    if not infinityJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return end

    if UIS:IsKeyDown(Enum.KeyCode.Space) or (isMobile and #UIS:GetTouches() > 0) then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, 60, hrp.Velocity.Z)
    elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, -80, hrp.Velocity.Z)
    else
        if hrp.Velocity.Y < -10 then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z)
        end
    end
end)

-- ========== FLY (WASD) ==========
local flyEnabled = false
local BodyVel, BodyGyro = nil, nil

local function cleanupFly()
    if BodyVel then BodyVel:Destroy() BodyVel = nil end
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
end

local function setupFly()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LP.Character.HumanoidRootPart
    BodyVel = Instance.new("BodyVelocity")
    BodyVel.MaxForce = Vector3.new(40000, 40000, 40000)
    BodyVel.Velocity = Vector3.zero
    BodyVel.P = 1000
    BodyVel.Parent = hrp

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
    BodyGyro.D = 100
    BodyGyro.P = 5000
    BodyGyro.CFrame = hrp.CFrame
    BodyGyro.Parent = hrp
end

RunS.RenderStepped:Connect(function()
    if not flyEnabled then
        cleanupFly()
        return
    end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
        cleanupFly()
        return
    end
    if not BodyVel or not BodyGyro or BodyVel.Parent == nil then
        setupFly()
    end
    local hrp = LP.Character.HumanoidRootPart
    local speed = 50
    local moveDir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Cam.CFrame.RightVector end
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
    BodyVel.Velocity = moveDir * speed

    if UIS:IsKeyDown(Enum.KeyCode.Space) or (isMobile and #UIS:GetTouches() > 0) then
        BodyVel.Velocity = Vector3.new(BodyVel.Velocity.X, speed, BodyVel.Velocity.Z)
    elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        BodyVel.Velocity = Vector3.new(BodyVel.Velocity.X, -speed, BodyVel.Velocity.Z)
    end

    BodyGyro.CFrame = Cam.CFrame
end)

UIS.JumpRequest:Connect(function()
    if flyEnabled and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)
-- ========== ИНИЦИАЛИЗАЦИЯ СЛУЖБ ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Plrs = Players
local LP = Players.LocalPlayer

-- ========== TROLLING FUNCTIONS ==========
local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p ~= LP then
            table.insert(names, p.Name)
        end
    end
    return names
end

local function GetPlayerByName(name)
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p.Name == name then return p end
    end
    return nil
end

local function TPToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myHrp = LP.Character.HumanoidRootPart
    local targetHrp = targetPlayer.Character.HumanoidRootPart
    myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 2, 0)
end

local function TPToRole(role)
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p ~= LP and GetRole(p) == role and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            TPToPlayer(p)
            break
        end
    end
end

-- ========== ОБНОВЛЕННЫЙ MM2 FLING (С GOD MODE) ==========
local function FlingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHrp or not targetHum or targetHum.Health <= 0 then return end

    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myHrp = LP.Character.HumanoidRootPart
    local myHum = LP.Character:FindFirstChildOfClass("Humanoid")

    -- 1. Сохраняем исходную позицию
    local oldCFrame = myHrp.CFrame

    -- 2. АНТИ-СМЕРТЬ ДЛЯ MM2 (Ломаем получение урона на сервере)
    local charChildren = LP.Character:GetChildren()
    if myHum then
        myHum.PlatformStand = true
        -- Отключаем получение урона через внутренние стейты Roblox
        myHum:ChangeState(Enum.HumanoidStateType.Physics)
    end

    -- 3. Настройка сил для флинга (Раскрутка)
    local att = Instance.new("Attachment", myHrp)
    
    local angVel = Instance.new("AngularVelocity")
    angVel.Attachment0 = att
    angVel.MaxTorque = math.huge
    angVel.AngularVelocity = Vector3.new(0, 999999, 0)
    angVel.Parent = myHrp

    local linVel = Instance.new("LinearVelocity")
    linVel.Attachment0 = att
    linVel.MaxForce = math.huge
    linVel.VectorVelocity = Vector3.new(9999, 9999, 9999)
    linVel.Parent = myHrp

    -- 4. Отключение коллизии + убираем регистрацию ударов по нам
    local collisionLoop = RunService.Heartbeat:Connect(function()
        if LP.Character then
            for _, part in ipairs(LP.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    -- Обнуляем скорость падения, чтобы античит MM2 не думал, что мы упали в бездну
                    part.Velocity = Vector3.new(part.Velocity.X, 0, part.Velocity.Z)
                end
            end
        end
    end)

    -- 5. Цикл удержания на цели (сократим до 2.5 сек, для MM2 этого за глаза)
    local duration = 2.5 
    local startTime = tick()

    while (tick() - startTime) < duration do
        if not targetPlayer or not targetPlayer.Character or not targetHrp or not targetHum or targetHum.Health <= 0 then 
            break 
        end
        
        -- Упреждение движения + залетаем жестко под ноги/в торс
        local prediction = targetHrp.AssemblyLinearVelocity * 0.04
        local randomOffset = Vector3.new(math.random(-3, 3), math.random(-1, 1), math.random(-3, 3)) * 0.05
        
        myHrp.CFrame = CFrame.new(targetHrp.Position + prediction + randomOffset)
        myHrp.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999)
        
        RunService.Heartbeat:Wait()
    end

    -- 6. Завершение атаки и удаление сил флинга
    collisionLoop:Disconnect()
    angVel:Destroy()
    linVel:Destroy()
    att:Destroy()
    
    myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    myHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    -- 7. ТЕЛЕПОРТ НАЗАД И СТОПОР (ФЛАЙ)
    myHrp.CFrame = oldCFrame

    local flyStopper = Instance.new("BodyVelocity")
    flyStopper.Name = "MM2Stop"
    flyStopper.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyStopper.Velocity = Vector3.new(0, 0, 0)
    flyStopper.Parent = myHrp

    local stopTime = tick()
    while (tick() - stopTime) < 0.15 do -- Чуть дольше держим стопор для проверки античитом MM2
        myHrp.CFrame = oldCFrame
        myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        myHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        RunService.Heartbeat:Wait()
    end

    flyStopper:Destroy()
    
    -- 8. ВЫХОД ИЗ GOD MODE (Полный разбаг персонажа)
    if myHum then
        myHum.PlatformStand = false
        myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function FlingRole(role)
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p ~= LP and GetRole(p) == role and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            FlingPlayer(p)
            break
        end
    end
end

-- ========== GUI ==========
local Window = Fluent:CreateWindow({
    Title = "Catalyst v5.3.7" .. (isMobile and " [Mobile]" or ""),
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
    Trolling = Window:AddTab({ Title = "Trolling", Icon = "users" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "star" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options

-- Home
local rankText = (_G.CatalystKeyType or "Free") .. " / " .. (_G.CatalystRank or "Standard")
local infoPara = Tabs.Home:AddParagraph({
    Title = "Catalyst",
    Content = string.format("Rank: %s\nMM2\nAlchemist Slime\nTG: @alchemistslimee\nVersion 5.3.7\nMap: %s | Dead: %s",
        rankText, currentMapName, tostring(isDead))
})
Tabs.Home:AddButton({ Title = "Copy Discord", Callback = function() setclipboard("https://discord.gg/w9mfcck2zV") Fluent:Notify({ Title = "Copied" }) end })

task.spawn(function()
    while true do
        task.wait(1)
        infoPara:SetContent(string.format("Rank: %s\nMM2\nAlchemist Slime\nTG: @alchemistslimee\nVersion 5.3.7\nMap: %s | Dead: %s",
            rankText, currentMapName, tostring(isDead)))
    end
end)

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
Tabs.Combat:AddButton({ Title = "TP to Gun (once)", Callback = TpToGunOnce })
local autoTPToggle = Tabs.Combat:AddToggle("autoTP", { Title = "Auto TP Gun (fast loop)", Default = false })
autoTPToggle:OnChanged(function(val) autoTpGun = val end)

Tabs.Combat:AddSection("Stab Aura")
local stabToggle = Tabs.Combat:AddToggle("stabAura", { Title = "Stab Aura (Murderer)", Default = false })
stabToggle:OnChanged(function(val) stabAuraEnabled = val end)

Tabs.Combat:AddSection("Auto Evade")
local evadeToggle = Tabs.Combat:AddToggle("autoEvade", { Title = "Auto Evade (innocent)", Default = false })
evadeToggle:OnChanged(function(val) autoEvadeEnabled = val end)

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

-- ========== TROLLING TAB ==========
local playerDropTP = Tabs.Trolling:AddDropdown("tpPlayer", { Title = "Selected Player (TP)", Values = GetPlayerNames(), Default = "", AllowClear = true })
local playerDropFling = Tabs.Trolling:AddDropdown("flingPlayer", { Title = "Selected Player (Fling)", Values = GetPlayerNames(), Default = "", AllowClear = true })

local function RefreshDropdowns()
    local names = GetPlayerNames()
    playerDropTP:SetValues(names)
    playerDropFling:SetValues(names)
end
Plrs.PlayerAdded:Connect(RefreshDropdowns)
Plrs.PlayerRemoving:Connect(function() task.wait(0.1) RefreshDropdowns() end)

Tabs.Trolling:AddSection("Teleport")
Tabs.Trolling:AddButton({ Title = "TP to Murderer", Callback = function() TPToRole("Murderer") end })
Tabs.Trolling:AddButton({ Title = "TP to Sheriff", Callback = function() TPToRole("Sheriff") end })
Tabs.Trolling:AddButton({ Title = "TP to Selected", Callback = function()
    local name = Options.tpPlayer.Value
    if name and name ~= "" then
        local target = GetPlayerByName(name)
        if target then TPToPlayer(target) end
    end
end })

Tabs.Trolling:AddSection("Fling")
Tabs.Trolling:AddButton({ Title = "Fling Murderer", Callback = function() FlingRole("Murderer") end })
Tabs.Trolling:AddButton({ Title = "Fling Sheriff", Callback = function() FlingRole("Sheriff") end })
Tabs.Trolling:AddButton({ Title = "Fling Selected", Callback = function()
    local name = Options.flingPlayer.Value
    if name and name ~= "" then
        local target = GetPlayerByName(name)
        if target then FlingPlayer(target) end
    end
end })

-- ========== MISC TAB ==========
Tabs.Misc:AddSection("Movement")
local noclip = Tabs.Misc:AddToggle("noclip", { Title = "No-Clip", Default = false })
local speed = Tabs.Misc:AddToggle("speed", { Title = "Speedhack", Default = false })
local speedVal = Tabs.Misc:AddSlider("speedVal", { Title = "Speed", Default = 50, Min = 16, Max = 250, Rounding = 0 })

Tabs.Misc:AddSection("Fly")
local infinityJumpToggle = Tabs.Misc:AddToggle("infinityJump", { Title = "Infinity Jump + Slow Fall", Default = false })
infinityJumpToggle:OnChanged(function(val) infinityJumpEnabled = val end)

local flyToggle = Tabs.Misc:AddToggle("fly", { Title = "Fly (WASD)", Default = false })
flyToggle:OnChanged(function(val)
    flyEnabled = val
    if not val then cleanupFly() end
end)

Tabs.Misc:AddSection("Fake Lag")
local lagToggle = Tabs.Misc:AddToggle("fakeLag", { Title = "Fake Lag (freeze)", Default = false })
lagToggle:OnChanged(function(val) fakeLagEnabled = val end)
local lagPingSlider = Tabs.Misc:AddSlider("fakeLagPing", { Title = "Ping (ms)", Default = 500, Min = 200, Max = 5000, Rounding = 0 })
lagPingSlider:OnChanged(function(val) fakeLagPing = val end)

-- ========== ESP HIGHLIGHT ==========
local function UpdateHighlight(p)
    if not p or p == LP or not p.Character then return end
    local role = GetRole(p)
    local hl = p.Character:FindFirstChild("Catalyst_HL")
    local hum = p.Character:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then
        if hl then hl:Destroy() end
        return
    end
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
        local gd = findGun()
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

task.spawn(function()
    while true do
        task.wait(2)
        lastRoleUpdate = tick()
        for _, p in pairs(Plrs:GetPlayers()) do GetRole(p) end
        for _, p in pairs(Plrs:GetPlayers()) do pcall(UpdateHighlight, p) end
        pcall(UpdateGunDropHighlight)
    end
end)

-- Name ESP для ПК
if not isMobile then
    local nameTexts = {}
    RunS.RenderStepped:Connect(function()
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                local health = hum and hum.Health or 0
                local isPlayerDead = health <= 0
                local role = GetRole(p)
                local show = false
                local color = Color3.new(1,1,1)
                if isPlayerDead then
                    show = true
                    color = Color3.fromRGB(128,128,128)
                elseif role == "Murderer" and Options.murTxt and Options.murTxt.Value then
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
                        txt.Text = p.Name .. " (" .. role .. ")" .. (isPlayerDead and " [DEAD]" or "")
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

-- ========== ДВИЖЕНИЕ (Speed, NoClip) ==========
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
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
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
