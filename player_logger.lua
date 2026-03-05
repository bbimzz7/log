-- ============================================================
--  player_logger.lua  ·  VertictHub - Player ID Logger
--
--  CARA PAKAI:
--      local PlayerLogger = loadstring(game:HttpGet(
--          "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/player_logger.lua"
--      ))()
--      PlayerLogger.Log()
-- ============================================================

local PlayerLogger = {}

local BOT_TOKEN = "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/player_logger.lua"
local CHAT_ID   = "5488313125"

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

function PlayerLogger.Log()
    pcall(function()
        local userId = tostring(Players.LocalPlayer.UserId)
        local url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage"
        HttpService:PostAsync(url, HttpService:JSONEncode({
            chat_id = CHAT_ID,
            text    = "id: " .. userId,
        }), Enum.HttpContentType.ApplicationJson)
    end)
end

return PlayerLogger
