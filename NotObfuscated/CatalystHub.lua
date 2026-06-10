-- ========================================================
-- 🔧 РЕЖИМ РАБОТЫ (измените при необходимости)
-- ========================================================
local KeylessMode = true   -- true = без ключа, false = требовать ключ

-- ========================================================
-- 📦 ОБЪЯВЛЕНИЕ СЕРВИСОВ И ПЕРЕМЕННЫХ
-- ========================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- 🔥 ЗАГРУЗКА БИБЛИОТЕК
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()

Junkie.identifier = 1042993
Junkie.provider = "Alchemist Hub"

local KeyFileName = "Catalyst_Key.txt"

-- ========================================================
-- 🌐 БАЗА ДАННЫХ ИГР
-- ========================================================
local SupportedGames = {
    [286090429] = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystArsenal.lua",
    [142823291] = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystMM2.lua",
    [17625359962] = "https://raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystRivals.lua"
}

-- ========================================================
-- 🏆 ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ========================================================
_G.CatalystKeyType = "Unknown"
_G.CatalystRank = "Standard"
_G.ScriptURL = nil
_G.GameName = "Unknown Game"

-- ========================================================
-- 📝 ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ========================================================
local function Log(message)
    print("[Catalyst Hub] " .. tostring(message))
end

-- ========================================================
-- 🔑 ПРОВЕРКА КЛЮЧА ВО ВСЕХ СЕРВИСАХ
-- ========================================================
local function CheckKeyInAllServices(key)
    if type(key) == "string" then
        key = key:gsub("%s+", "")
    end
    
    if not key or key == "" or #key < 5 then
        return false, nil, nil
    end
    
    local services = {
        { name = "Free",     keyType = "Free",     rank = "Standard" },
        { name = "Premium",  keyType = "Premium",  rank = "Premium" },
        { name = "Ultimate", keyType = "Ultimate", rank = "Ultimate" }
    }
    
    for _, svc in ipairs(services) do
        Junkie.service = svc.name
        local success, result = pcall(function()
            return Junkie.check_key(key)
        end)
        
        if success and result and type(result) == "table" then
            Log(svc.name .. " service response: " .. (result.valid and "VALID" or "invalid"))
            if result.valid == true then
                pcall(function()
                    if writefile then writefile(KeyFileName, key) end
                end)
                Log("Key belongs to: " .. svc.name .. " → Type: " .. svc.keyType .. ", Rank: " .. svc.rank)
                return true, svc.keyType, svc.rank
            end
        end
    end
    
    return false, nil, nil
end

-- ========================================================
-- 🚀 ЗАПУСК ОСНОВНОГО СКРИПТА
-- ========================================================
local function LaunchCheatDirectly()
    local safeGameName = (_G.GameName ~= "") and _G.GameName or "Unknown Game"
    Log("Loading Catalyst / " .. safeGameName)
    Log("Key Type: " .. (_G.CatalystKeyType or "Unknown"))
    Log("Rank: " .. (_G.CatalystRank or "Standard"))
    
    if not _G.ScriptURL or _G.ScriptURL == "" then
        Log("ERROR: No script URL for game ID: " .. game.PlaceId)
        return
    end
    
    local success, content = pcall(game.HttpGet, game, _G.ScriptURL)
    if success and content and content ~= "" then
        loadstring(content)()
    else
        Log("ERROR: Failed to download script")
    end
end

-- ========================================================
-- 🕵️‍♂️ ОПРЕДЕЛЕНИЕ ИГРЫ
-- ========================================================
local currentPlaceId = game.PlaceId
_G.ScriptURL = SupportedGames[currentPlaceId]

local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(currentPlaceId)
end)
if success and info and info.Name ~= "" then
    _G.GameName = info.Name
end

if not _G.ScriptURL and (currentPlaceId == 142823291 or game.GameId == 504917579) then
    _G.ScriptURL = SupportedGames[142823291]
    _G.GameName = "Murder Mystery 2"
end

Log("=== Catalyst Hub ===")
Log("Place ID: " .. currentPlaceId)
Log("Game: " .. _G.GameName)
Log("Supported: " .. tostring(_G.ScriptURL ~= nil))

if not _G.ScriptURL then
    pcall(function()
        LP:Kick("[Catalyst Hub]\nGame not supported.\nPlace ID: " .. currentPlaceId)
    end)
    return
end

-- ========================================================
-- ⚡ ЕСЛИ KEYLESS MODE ВКЛЮЧЕН — ЗАПУСКАЕМ СРАЗУ
-- ========================================================
if KeylessMode then
    Log("Keyless mode enabled. Launching script with Standard rank.")
    _G.CatalystKeyType = "Keyless"
    _G.CatalystRank = "Standard"
    LaunchCheatDirectly()
    return
end

-- ========================================================
-- 🔑 АВТО-ВХОД ПО СОХРАНЕННОМУ КЛЮЧУ (если KeylessMode = false)
-- ========================================================
local savedKey = ""
pcall(function()
    if isfile and isfile(KeyFileName) then
        local content = readfile(KeyFileName)
        if content and content ~= "" then
            savedKey = content:gsub("%s+", "")
        end
    end
end)

local autoValid, keyType, rank = false, nil, nil
if savedKey ~= "" and #savedKey >= 5 then
    Log("Checking saved key...")
    autoValid, keyType, rank = CheckKeyInAllServices(savedKey)
end

if autoValid and keyType and rank then
    _G.CatalystKeyType = keyType
    _G.CatalystRank = rank
    Log("Auto-login success: " .. keyType .. " / " .. rank)
    LaunchCheatDirectly()
    return
else
    pcall(function()
        if delfile and isfile(KeyFileName) then
            delfile(KeyFileName)
        elseif writefile then
            writefile(KeyFileName, "")
        end
    end)
end

Log("No valid key found. Launching GUI...")

-- ========================================================
-- 🖥️ GUI FLUENT (только если нет сохранённого ключа)
-- ========================================================
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

KeyTab:AddInput("KeyInput", {
    Title = "Activation Key",
    Default = "",
    Placeholder = "Enter your key here..."
})

KeyTab:AddButton({
    Title = "Verify Key",
    Callback = function()
        local enteredKey = Options.KeyInput.Value
        Fluent:Notify({ Title = "Catalyst", Content = "Checking key...", Duration = 1.5 })
        task.wait(0.5)
        
        local valid, kt, r = CheckKeyInAllServices(enteredKey)
        if valid and kt and r then
            _G.CatalystKeyType = kt
            _G.CatalystRank = r
            Fluent:Notify({ Title = "Access Granted", Content = string.format("Type: %s | Rank: %s", kt, r), Duration = 3 })
            task.wait(0.8)
            KeyWindow:Destroy()
            task.wait(0.2)
            LaunchCheatDirectly()
        else
            Fluent:Notify({ Title = "Access Denied", Content = "Invalid key", Duration = 4 })
        end
    end
})

KeyTab:AddButton({
    Title = "Get Free Key (Copy Link)",
    Callback = function()
        Junkie.service = "Free"
        local success, link = pcall(Junkie.get_key_link)
        if success and link then
            setclipboard(link)
            Fluent:Notify({ Title = "Link Copied", Content = "Free key link copied", Duration = 2 })
        else
            Fluent:Notify({ Title = "Error", Content = "Failed to get link", Duration = 2 })
        end
    end
})

KeyWindow:SelectTab(1)
Log("GUI ready")
