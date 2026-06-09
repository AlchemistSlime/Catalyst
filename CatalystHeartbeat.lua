-- ========================================================
-- CATALYST HEARTBEAT MODULE v1.0
-- Загружается отдельно через loadstring(game:HttpGet(...))
-- Без этого модуля скрипты не запустятся
-- ========================================================

local API_BASE = "https://catalyst-sites.vercel.app"
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UserId = LP.UserId
local PlaceId = game.PlaceId
local GameId = game.GameId

-- ========================================================
-- 🔐 ВАЛИДАЦИЯ НА СЕРВЕРЕ
-- ========================================================
local ModuleValid = false
local SessionHash = nil
local HeartbeatRunning = false
local HeartbeatCount = 0

local function ValidateOnServer()
    local success, result = pcall(function()
        return game:HttpGet(API_BASE .. "/api/heartbeat?action=validate&userId=" .. tostring(UserId) .. "&placeId=" .. tostring(PlaceId))
    end)
    
    if success and result and result:find("OK:") then
        SessionHash = result:gsub("OK:", ""):gsub("%s+", "")
        ModuleValid = true
        
        -- Глобальные переменные для проверки другими скриптами
        _G.Catalyst_HeartbeatActive = true
        _G.Catalyst_SessionHash = SessionHash
        
        return true
    end
    
    return false
end

-- Проверяем СРАЗУ при загрузке модуля
if not ValidateOnServer() then
    -- Модуль не прошёл валидацию — возвращаем nil
    -- Основной скрипт увидит что модуль не загрузился и не запустится
    return nil
end

-- ========================================================
-- 💓 ФУНКЦИЯ ОТПРАВКИ HEARTBEAT
-- ========================================================
local function SendHeartbeat(status)
    if not ModuleValid then return end
    
    status = status or "active"
    HeartbeatCount = HeartbeatCount + 1
    
    local url = API_BASE .. "/api/heartbeat"
    local query = "?action=heartbeat"
        .. "&userId=" .. tostring(UserId)
        .. "&placeId=" .. tostring(PlaceId)
        .. "&gameId=" .. tostring(GameId)
        .. "&status=" .. status
        .. "&hash=" .. (SessionHash or "none")
        .. "&count=" .. tostring(HeartbeatCount)
        .. "&keyType=" .. (_G.CatalystKeyType or "Unknown")
        .. "&rank=" .. (_G.CatalystRank or "Standard")
    
    pcall(function()
        local response = game:HttpGet(url .. query)
        
        if response == "banned" then
            -- Пользователь забанен
            ModuleValid = false
            HeartbeatRunning = false
            _G.Catalyst_Shutdown = true
            pcall(function()
                LP:Kick("[Catalyst Hub]\nYour access has been revoked.\nReason: Violation of Terms of Service")
            end)
        elseif response == "invalid" then
            -- Сессия невалидна
            ModuleValid = false
            HeartbeatRunning = false
            _G.Catalyst_Shutdown = true
        end
    end)
end

-- ========================================================
-- 🚀 ЗАПУСК HEARTBEAT ЦИКЛА
-- ========================================================
local function StartHeartbeat()
    if HeartbeatRunning then return end
    HeartbeatRunning = true
    
    -- Первый heartbeat сразу
    SendHeartbeat("active")
    
    -- Затем каждые 45 секунд
    spawn(function()
        while HeartbeatRunning and ModuleValid do
            wait(45)
            SendHeartbeat("active")
        end
    end)
end

local function StopHeartbeat()
    HeartbeatRunning = false
    if ModuleValid then
        SendHeartbeat("inactive")
    end
end

-- Автозапуск
StartHeartbeat()

-- Остановка при выходе из игры
Players.PlayerRemoving:Connect(function(player)
    if player == LP then
        StopHeartbeat()
    end
end)

-- ========================================================
-- 🛡️ ЗАЩИТА ОТ ПОДМЕНЫ ПЕРЕМЕННЫХ
-- ========================================================
spawn(function()
    while ModuleValid do
        wait(15)
        
        -- Проверяем что глобальные переменные не подменили
        if not _G.Catalyst_HeartbeatActive then
            ModuleValid = false
            _G.Catalyst_Shutdown = true
            StopHeartbeat()
            break
        end
        
        if _G.Catalyst_SessionHash ~= SessionHash then
            ModuleValid = false
            _G.Catalyst_Shutdown = true
            StopHeartbeat()
            break
        end
    end
end)

-- ========================================================
-- 📦 ВОЗВРАЩАЕМ API ДЛЯ ДРУГИХ СКРИПТОВ
-- ========================================================
return {
    IsValid = function()
        return ModuleValid
    end,
    
    GetHash = function()
        return SessionHash
    end,
    
    SendHeartbeat = SendHeartbeat,
    
    Stop = function()
        StopHeartbeat()
    end,
    
    GetStatus = function()
        return {
            valid = ModuleValid,
            running = HeartbeatRunning,
            count = HeartbeatCount,
            placeId = PlaceId,
            userId = UserId,
        }
    end,
}
