-- Taruh di paling atas script manapun
local TeleLogger = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/tele_logger.lua"
))()

TeleLogger.Send("Nama Script Lo")


--blacklist
-- paling atas
local Blacklist = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/blacklist.lua"
))()
Blacklist.Check()

-- paling bawah
Blacklist.StartLoop()
