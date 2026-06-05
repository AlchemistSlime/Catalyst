local RS, Plrs, UIS, RunS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local LP, Cam = Plrs.LocalPlayer, workspace.CurrentCamera

-- 🔥 АВТО-ЗАГРУЗКА БИБЛИОТЕК С GITHUB
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

_G.HighlightAll, _G.FocusNPCHead = false, false

local Window = Fluent:CreateWindow({
	Title = "Catalyst v2.2.0",
	SubTitle = "Arsenal",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
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

-- === УЛЬТРА СЖАТЫЙ КОД ПОДКАПОТНОЙ ЛОГИКИ ===
local IsExec, FOV = (typeof(Drawing) == "table" and Drawing.new ~= nil), nil
if IsExec then
	FOV = Drawing.new("Circle") FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1
	RunS.RenderStepped:Connect(function()
		if Options.Slider and Options.Colorpicker2 and Options.MyToggle then
			FOV.Visible = Options.MyToggle.Value
			FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X
			FOV.Color, FOV.Position = Options.Colorpicker2.Value, UIS:GetMouseLocation()
		else FOV.Visible = false end
	end)
end

local function IsEnemy(char)
	local p = Plrs:GetPlayerFromCharacter(char)
	if p and p ~= LP then
		if LP.Team ~= "" and p.Team ~= "" and LP.Team == p.Team then return false end
		return true
	end
	return _G.HighlightAll
end

-- Функция проверки препятствий (Wall Check)
local function IsVisible(part)
    local origin = Cam.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LP.Character, Cam}
    
    local result = workspace:Raycast(origin, part.Position - origin, raycastParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- Поиск цели с приоритетом тех, кто НЕ за стеной
local function GetTarget()
	local best, minAngle, maxAngle = nil, math.huge, (Options.Slider and Options.Slider.Value or 180)
	local fallbackTarget, fallbackMinAngle = nil, math.huge

	for _, p in pairs(Plrs:GetPlayers()) do
		if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
			if IsEnemy(p.Character) then
				local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((p.Character.Head.Position - Cam.CFrame.Position).Unit), -1, 1)))
				if maxAngle >= 360 or angle <= maxAngle / 2 then
					if IsVisible(p.Character.Head) then
						-- Игрок виден напрямую (наивысший приоритет)
						if angle < minAngle then minAngle, best = angle, p.Character.Head end
					else
						-- Игрок за стеной (резервный приоритет)
						if angle < fallbackMinAngle then fallbackMinAngle, fallbackTarget = angle, p.Character.Head end
					end
				end
			end
		end
	end
	return best or fallbackTarget
end

-- Главный цикл AimAssist и Hitbox Increase
RunS.RenderStepped:Connect(function()
	if not (Options.MyToggle and Options.MyToggle.Value) then return end
	local mode = Options.Dropdown and Options.Dropdown.Value or "AimAssist"
	local pressed = false pcall(function() pressed = Options.Keybind:GetState() end)
	
	local t = GetTarget()
	if mode == "AimAssist" and pressed and t and IsVisible(t) then
		Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, t.Position), 0.4)
	elseif mode == "Hitbox Increase" then
		for _, p in pairs(Plrs:GetPlayers()) do
			if p ~= LP and p.Character and IsEnemy(p.Character) then
				for _, name in pairs({"HeadHB", "HumanoidRootPart"}) do
					local part = p.Character:FindFirstChild(name)
					if part then part.CanCollide, part.Transparency, part.Size = false, 1, Vector3.new(13, 13, 13) end
				end
			end
		end
	end
end)



-- Движение
UIS.JumpRequest:Connect(function()
	if Options.InfJump and Options.InfJump.Value and LP.Character then
		local hum = LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState("Jumping") end
	end
end)

RunS.RenderStepped:Connect(function()
	if Options.Speedhack and Options.Speedhack.Value and LP.Character then
		local hum = LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = Options.SpeedSlider and Options.SpeedSlider.Value or 100 end
	end
end)

-- === УЛЬТРА СЖАТЫЙ И ОПТИМИЗИРОВАННЫЙ БЛОК ESP (БЕЗ ЛАГОВ) ===
local function ClearESP()
	for _, p in pairs(Plrs:GetPlayers()) do
		local h = p.Character and p.Character:FindFirstChild("Catalyst_Highlight")
		if h then h:Destroy() end
	end
end

local function CreateESP(char)
	if not char or not char:IsA("Model") or char == LP.Character or not (Options["ESP Toggle"] and Options["ESP Toggle"].Value) or not IsEnemy(char) then return end
	local h = char:FindFirstChild("Catalyst_Highlight") or Instance.new("Highlight")
	h.Name, h.FillColor, h.OutlineColor, h.FillTransparency, h.OutlineTransparency, h.Parent = "Catalyst_Highlight", Options.Colorpicker.Value, Color3.fromRGB(255,255,255), 0.5, 0, char
end

local function RefreshESP()
	ClearESP()
	if Options["ESP Toggle"] and Options["ESP Toggle"].Value then
		for _, p in pairs(Plrs:GetPlayers()) do if p.Character then CreateESP(p.Character) end end
	end
end

-- Слежка за сменой команд локального игрока и всех в лобби
local function BindTeamChange(p)
	p:GetPropertyChangedSignal("Team"):Connect(RefreshESP)
	p.CharacterAdded:Connect(function(c) task.wait(0.5) if IsEnemy(c) then CreateESP(c) else local h = c:FindFirstChild("Catalyst_Highlight") if h then h:Destroy() end end end)
end

for _, p in pairs(Plrs:GetPlayers()) do BindTeamChange(p) end
Plrs.PlayerAdded:Connect(BindTeamChange)
Plrs.PlayerRemoving:Connect(function() task.spawn(RefreshESP) end)

-- === УПРАВЛЕНИЕ ВИДИМОСТЬЮ FOV КРУГА (СКРЫТИЕ ДЛЯ HITBOX INCREASE) ===
local IsExec, FOV = (typeof(Drawing) == "table" and Drawing.new ~= nil), nil
if IsExec then
	FOV = Drawing.new("Circle") FOV.Thickness, FOV.NumSides, FOV.Filled, FOV.Transparency = 1.5, 60, false, 1
	RunS.RenderStepped:Connect(function()
		if Options.Slider and Options.Colorpicker2 and Options.MyToggle then
			-- Проверяем: если выбран Hitbox Increase — круг принудительно скрывается (false)
			local isHitbox = Options.Dropdown and Options.Dropdown.Value == "Hitbox Increase"
			FOV.Visible = Options.MyToggle.Value and not isHitbox
			
			FOV.Radius = (Options.Slider.Value / 360) * Cam.ViewportSize.X
			FOV.Color, FOV.Position = Options.Colorpicker2.Value, UIS:GetMouseLocation()
		else FOV.Visible = false end
	end)
end

-- ========================================================
-- 🔥 РАЗВЕРНУТЫЕ ЭЛЕМЕНТЫ ИНТЕРФЕЙСА (UI)
-- ========================================================

-- ТАБ 1: COMBAT
Tabs.Main:AddSection("Aimbot Settings")
local Toggle = Tabs.Main:AddToggle("MyToggle", {Title = "Enable Aimbot", Default = false})
local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
	Title = "Aim Mode",
	Values = {"AimAssist", "Hitbox Increase"},
	Multi = false,
	Default = "AimAssist",
})
local Keybind = Tabs.Main:AddKeybind("Keybind", {Title = "Aim Assist Keybind", Mode = "Hold", Default = "MouseRight"})
local Slider = Tabs.Main:AddSlider("Slider", {Title = "Aimbot FOV (Degrees)", Default = 180, Min = 1, Max = 360, Rounding = 0})
local Colorpicker2 = Tabs.Main:AddColorpicker("Colorpicker2", {Title = "FOV Circle Color", Default = Color3.fromRGB(255, 255, 255)})

-- ТАБ 2: VISUALS
Tabs.Visuals:AddSection("Visual Settings")
local Toggle2 = Tabs.Visuals:AddToggle("ESP Toggle", {Title = "Enable ESP (Team Checks)", Default = false})
local Colorpicker = Tabs.Visuals:AddColorpicker("Colorpicker", {Title = "Enemy ESP Color", Default = Color3.fromRGB(255, 0, 0)})
Toggle2:OnChanged(function() end) Colorpicker:OnChanged(function() end)
Tabs.Misc:AddSection("Movement Hacks")
local SpeedToggle = Tabs.Misc:AddToggle("Speedhack", {Title = "Enable Speedhack", Default = false})
local SpeedSlider = Tabs.Misc:AddSlider("SpeedSlider", {Title = "WalkSpeed Custom Value", Default = 100, Min = 16, Max = 250, Rounding = 0})
local JumpToggle = Tabs.Misc:AddToggle("InfJump", {Title = "Infinite Jump", Default = false})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Catalyst")
SaveManager:SetFolder("Catalyst/Arsenal")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
