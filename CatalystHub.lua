-- ========================================================
-- 🔥 CATALYST LOADER / HUB v2.2.1 (FIXED)
-- ========================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- База данных поддерживаемых игр (ПРОВЕРЬ ССЫЛКУ ТУТ)
local SupportedGames = {
    [286090429] = "raw.githubusercontent.com/AlchemistSlime/Catalyst/refs/heads/main/CatalystArsenal.lua",
}

local function Log(message)
    print("[Catalyst Hub] " .. tostring(message))
end

Log("Checking current environment...")
Log("Finding game place...")

local currentPlaceId = game.PlaceId
local scriptURL = SupportedGames[currentPlaceId]
local gameName = "Unknown Game"

local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(currentPlaceId)
end)

if success and info and info.Name then
    gameName = info.Name
end

if scriptURL then
    Log("Found script for the current game!")
    Log("Loading Catalyst / " .. gameName .. "...")
    
    -- Безопасно скачиваем код
    local downloadSuccess, scriptCode = pcall(function()
        return game:HttpGet(scriptURL)
    end)
    
    -- Проверяем, что скачался текст, а не пустота (nil)
    if downloadSuccess and scriptCode and scriptCode ~= "" and scriptCode ~= "404: Not Found" then
        local launchSuccess, err = pcall(function()
            loadstring(scriptCode)()
        end)
        
        if not launchSuccess then
            Log("Error while executing script: " .. tostring(err))
        end
    else
        Log("CRITICAL ERROR: Failed to download script from GitHub!")
        Log("Please make sure your GitHub Repository is set to PUBLIC.")
    end
else
    Log("Game is not supported. Disconnecting user...")
    LP:Kick("\n\n[Catalyst Hub]\nThis game (" .. gameName .. ") is currently not supported.\nJoin our Discord to check supported games list!")
end
