--[[
    VertictHub - Universal Blacklist System
    by @Bimz19

    CARA PAKAI:
    local Blacklist = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/blacklist.lua"
    ))()
    Blacklist.Check()
    Blacklist.StartLoop()

    FORMAT blacklist.txt:
    # Komentar diawali tanda pagar
    123456789|Cheating
]]

local Blacklist = {}

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local BLACKLIST_URL  = "https://raw.githubusercontent.com/bbimzz7/log/refs/heads/main/blacklist.txt?t=" .. os.time()
local BOT_TOKEN      = "8672141972:AAGl0yGh16if3rm2EfplYfkruGLPwaW0bP4"
local CHAT_ID        = "5488313125"
local CHECK_INTERVAL = 60
local OWNER_TG       = "@bimz"

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer

--------------------------------------------------
-- FETCH BLACKLIST
--------------------------------------------------

local function fetchBlacklist()
    local ok, result = pcall(function()
        return game:HttpGet(BLACKLIST_URL)
    end)

    if not ok or not result or result == "" then
        error("[Blacklist] Gagal fetch blacklist. Script dihentikan.")
    end

    local list = {}
    for line in result:gmatch("[^\n]+") do
        line = line:gsub("\r", "")
        if not line:match("^#") and line ~= "" then
            local id, reason = line:match("^(%d+)|(.+)$")
            if id and reason then
                list[id] = reason:gsub("^%s+", ""):gsub("%s+$", "")
            end
        end
    end
    return list
end

--------------------------------------------------
-- KIRIM NOTIF TELEGRAM
--------------------------------------------------

local function sendTelegram(reason)
    pcall(function()
        local function getGameName()
            local ok, r = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            return ok and r or "Unknown"
        end

        local function getPing()
            return math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
        end

        local msg = string.format(
            "[VertictHub - Blacklist Detected]\n\n" ..
            "= DATA USER =\n" ..
            "Username     : %s\n" ..
            "User ID      : %d\n" ..
            "Display Name : %s\n\n" ..
            "= DATA GAME =\n" ..
            "Game         : %s\n" ..
            "Place ID     : %d\n" ..
            "Job ID       : %s\n" ..
            "Ping         : %s\n\n" ..
            "= BLACKLIST =\n" ..
            "Reason       : %s\n\n" ..
            "= WAKTU =\n" ..
            "Tanggal      : %s\n" ..
            "Jam          : %s",

            LocalPlayer.Name,
            LocalPlayer.UserId,
            LocalPlayer.DisplayName,
            getGameName(),
            game.PlaceId,
            game.JobId,
            getPing(),
            reason,
            os.date("%Y-%m-%d"),
            os.date("%H:%M:%S")
        )

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
end

--------------------------------------------------
-- GUI FULLSCREEN
--------------------------------------------------

local guiShown = false

local function showBlacklistGui(reason)
    if guiShown then return end
    guiShown = true

    local existing = LocalPlayer.PlayerGui:FindFirstChild("BlacklistGui")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlacklistGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    -- Background hitam fullscreen
    local BG = Instance.new("Frame")
    BG.Size = UDim2.new(1, 0, 1, 0)
    BG.Position = UDim2.new(0, 0, 0, 0)
    BG.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    BG.BackgroundTransparency = 1
    BG.BorderSizePixel = 0
    BG.ZIndex = 1
    BG.Parent = ScreenGui

    TweenService:Create(BG, TweenInfo.new(0.5), {
        BackgroundTransparency = 0
    }):Play()

    -- Garis merah atas
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 4)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 2
    TopBar.Parent = ScreenGui

    -- Garis merah bawah
    local BotBar = Instance.new("Frame")
    BotBar.Size = UDim2.new(1, 0, 0, 4)
    BotBar.Position = UDim2.new(0, 0, 1, -4)
    BotBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    BotBar.BorderSizePixel = 0
    BotBar.ZIndex = 2
    BotBar.Parent = ScreenGui

    -- Container card di tengah
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 420, 0, 280)
    Container.Position = UDim2.new(0.5, -210, 1.5, 0)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    Container.BorderSizePixel = 0
    Container.ZIndex = 3
    Container.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 14)
    UICorner.Parent = Container

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(200, 30, 30)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Container

    -- Animasi container masuk setelah BG fade
    task.delay(0.3, function()
        TweenService:Create(Container, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -210, 0.5, -140)
        }):Play()
    end)

    -- Header merah
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 60)
    Header.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
    Header.BorderSizePixel = 0
    Header.ZIndex = 4
    Header.Parent = Container

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 14)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 14)
    HeaderFix.Position = UDim2.new(0, 0, 1, -14)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.ZIndex = 4
    HeaderFix.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "You Are Blacklisted!"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.ZIndex = 5
    Title.Parent = Header

    -- Body
    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -60)
    Body.Position = UDim2.new(0, 0, 0, 60)
    Body.BackgroundTransparency = 1
    Body.ZIndex = 4
    Body.Parent = Container

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft   = UDim.new(0, 24)
    UIPadding.PaddingRight  = UDim.new(0, 24)
    UIPadding.PaddingTop    = UDim.new(0, 18)
    UIPadding.PaddingBottom = UDim.new(0, 18)
    UIPadding.Parent = Body

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 12)
    UIListLayout.Parent = Body

    local function makeRow(labelText, valueText, order)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 30)
        Row.BackgroundTransparency = 1
        Row.LayoutOrder = order
        Row.ZIndex = 5
        Row.Parent = Body

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.35, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = labelText
        Label.TextColor3 = Color3.fromRGB(130, 130, 145)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 5
        Label.Parent = Row

        local Value = Instance.new("TextLabel")
        Value.Size = UDim2.new(0.65, 0, 1, 0)
        Value.Position = UDim2.new(0.35, 0, 0, 0)
        Value.BackgroundTransparency = 1
        Value.Text = valueText
        Value.TextColor3 = Color3.fromRGB(240, 240, 240)
        Value.Font = Enum.Font.GothamBold
        Value.TextSize = 14
        Value.TextXAlignment = Enum.TextXAlignment.Left
        Value.TextTruncate = Enum.TextTruncate.AtEnd
        Value.ZIndex = 5
        Value.Parent = Row
    end

    makeRow("Username", LocalPlayer.Name, 1)
    makeRow("Reason", reason, 2)

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Divider.BorderSizePixel = 0
    Divider.LayoutOrder = 3
    Divider.ZIndex = 5
    Divider.Parent = Body

    local Contact = Instance.new("TextLabel")
    Contact.Size = UDim2.new(1, 0, 0, 30)
    Contact.BackgroundTransparency = 1
    Contact.Text = "Mau banding? Hubungi: " .. OWNER_TG
    Contact.TextColor3 = Color3.fromRGB(80, 130, 255)
    Contact.Font = Enum.Font.Gotham
    Contact.TextSize = 13
    Contact.TextXAlignment = Enum.TextXAlignment.Center
    Contact.LayoutOrder = 4
    Contact.ZIndex = 5
    Contact.Parent = Body
end

--------------------------------------------------
-- STOP CALLBACKS
--------------------------------------------------

local stopCallbacks = {}

function Blacklist.OnStop(callback)
    table.insert(stopCallbacks, callback)
end

local function killScript(reason)
    -- 1. Kirim log ke Telegram terlebih dahulu
    sendTelegram(reason)
    task.wait(0.5)

    -- 2. Coba tendang (Kick) pemain dari server game
    pcall(function()
        LocalPlayer:Kick("\n[VertictHub] You Are Blacklisted!\nReason: " .. reason .. "\n\nMau banding? Hubungi: " .. OWNER_TG)
    end)

    -- 3. FALLBACK (CADANGAN): Jika fungsi Kick diblokir oleh anti-kick mereka, kunci layarnya pakai GUI
    showBlacklistGui(reason)
    
    -- 4. Matikan semua loop atau fitur script yang sedang berjalan
    for _, cb in ipairs(stopCallbacks) do
        pcall(cb)
    end
end


--------------------------------------------------
-- CEK BLACKLIST
--------------------------------------------------

local function checkAndAct()
    local list   = fetchBlacklist()
    local userId = tostring(LocalPlayer.UserId)
    if list[userId] then
        return true, list[userId]
    end
    return false, nil
end

--------------------------------------------------
-- PUBLIC API
--------------------------------------------------

function Blacklist.Check()
    local isBlacklisted, reason = checkAndAct()
    if isBlacklisted then
        killScript(reason)
        error("[Blacklist] Akses ditolak: " .. reason)
    end
end

function Blacklist.StartLoop()
    task.spawn(function()
        while task.wait(CHECK_INTERVAL) do
            local ok, isBlacklisted, reason = pcall(checkAndAct)
            if ok and isBlacklisted then
                killScript(reason)
                break
            end
        end
    end)
end

return Blacklist
