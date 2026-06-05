

-- 🔥 ЗАГРУЗКА БИБЛИОТЕК С GITHUB
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()

-- Настройки Jnkie
Junkie.service = "Free"
Junkie.identifier = "1042993"
Junkie.provider = "Alchemist Hub"

local KeyFileName = "Catalyst_Key.txt"

-- ========================================================
-- 🌐 БАЗА ДАННЫХ ИГР
-- ========================================================
local SupportedGames = {
    [286090429] = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystArsenal.lua", -- Arsenal
	[142823291]  = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystMM2.lua" -- MM2
	[17625359962] = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystRivals.lua" -- Rivals
}

-- ========================================================
-- 🕵️‍♂️ ПРОВЕРКА ПОДДЕРЖКИ ИГРЫ ПРИ ЗАПУСКЕ
-- ========================================================
local currentPlaceId = game.PlaceId
local scriptURL = SupportedGames[currentPlaceId]
local gameName = "Unknown Game"

-- Получаем официальное название игры через API Roblox
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(currentPlaceId)
end)
if success and info and info.Name then gameName = info.Name end

local function Log(message)
    print("[Catalyst Hub] " .. tostring(message))
end

Log("Checking current environment...")
Log("Finding game place...")

-- Если игра НЕ поддерживается — сразу жестко кикаем
if not scriptURL then
    Log("Game is not supported. Disconnecting user...")
pcall(function() LP:Kick("\n\n[Catalyst Hub]\nThis game (" .. tostring(gameName) .. ") is currently not supported.") end)

    return
end

Log("Found script for the current game!")

-- Функция верификации ключа через Jnkie API
local function ProcessKeyVerification(key)
    local success, result = pcall(function() return Junkie.check_key(key) end)
    if success and result and result.valid then
        if result.message == "KEYLESS" or result.message == "KEY_VALID" then
            if result.message == "KEY_VALID" and writefile then writefile(KeyFileName, key) end
            return true
        end
    end
    return false
end

-- Функция прямой тихой загрузки нужной игры
local function LaunchCheatDirectly()
    Log("Loading Catalyst / " .. gameName .. "...")
    -- Скачиваем и запускаем именно тот скрипт, который мы нашли по ID игры в таблице!
    loadstring(game:HttpGet(scriptURL))()
end

-- ========================================================
-- 🔑 СКРЫТАЯ ПРОВЕРКА АВТО-ВХОДА (ВЫПОЛНЯЕТСЯ ДО СОЗДАНИЯ GUI)
-- ========================================================
local savedKey = readfile and isfile and isfile(KeyFileName) and readfile(KeyFileName) or ""
if savedKey ~= "" and ProcessKeyVerification(savedKey) then
    -- Ключ валиден! Сразу тихо запускаем чит и завершаем лоадер
    LaunchCheatDirectly()
    return -- Стопим дальнейшее выполнение лоадера, GUI ключа не создастся!
end

-- ========================================================
-- ⛔ ЕСЛИ КЛЮЧА НЕТ ИЛИ ОН НЕ СРАБОТАЛ — СОЗДАЕМ ИНТЕРФЕЙС FLUENT
-- ========================================================
local Fluent = loadstring(game:HttpGet("https://github.com"))()

local KeyWindow = Fluent:CreateWindow({
	Title = "Catalyst",
	SubTitle = "Key System",
	TabWidth = 120,
	Size = UDim2.fromOffset(450, 240),
	Acrylic = false, 
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.RightControl
})

local KeyTab = KeyWindow:AddTab({ Title = "Verification", Icon = "shield-check" })
local Options = Fluent.Options

local KeyInput = KeyTab:AddInput("KeyInput", {
	Title = "Activation Key",
	Default = "", -- Здесь пусто, так как авто-вход уже провалился
	Placeholder = "Enter your key here...",
})

-- Кнопка ручной проверки ключа
KeyTab:AddButton({
	Title = "Verify Key",
	Callback = function()
		local enteredKey = Options.KeyInput.Value
        Fluent:Notify({Title = "Catalyst Safety", Content = "Checking key validity...", Duration = 1.5})
        
        task.wait(0.5)
        if ProcessKeyVerification(enteredKey) then
            Fluent:Notify({Title = "Access Granted", Content = "Welcome back to Catalyst Hub!", Duration = 2})
            task.wait(0.8)
            KeyWindow:Destroy() -- Уничтожаем окно авторизации
            task.wait(0.2) -- Даем очистить старые бинды
            LaunchCheatDirectly() -- Запускаем чит
        else
            Fluent:Notify({Title = "Access Denied", Content = "Invalid key. Try again.", Duration = 4})
        end
	end
})

-- Кнопка получения ссылки на ключ
KeyTab:AddButton({
	Title = "Get Key (Copy Link)",
	Callback = function()
		local success, link = pcall(function() return Junkie.get_key_link() end)
        if success and link then
            if setclipboard then setclipboard(link) end
            Fluent:Notify({Title = "Link Copied", Content = "Key link copied to clipboard!", Duration = 2})
        end
	end
})

KeyWindow:SelectTab(1)
