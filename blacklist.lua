--[[
    VertictHub - Universal Blacklist System
    by @Bimz19

    CARA PAKAI:
    local Blacklist = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/UsernameLo/RepoLo/main/blacklist.lua"
    ))()
    Blacklist.Check() -- taruh sebelum load script utama
    Blacklist.StartLoop() -- taruh setelah script utama load

    FORMAT blacklist.txt di GitHub:
    # Komentar diawali tanda pagar
    123456789|Cheating
    987654321|Spam
]]

local Blacklist = {}

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local BLACKLIST_URL = "https://raw.githubusercontent.com/UsernameLo/RepoLo/main/blacklist.txt"
local BOT_TOKEN     = "8672141972:AAGl0yGh16if3rm2EfplYfkruGLPwaW0bP4"
local CHAT_ID       = "5488313125"
local CHECK_INTERVAL = 60 -- cek ulang tiap 60 detik
local OWNER_TG      = "@bimz"

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

--------------------------------------------------
-- FETCH BLACKLIST
--------------------------------------------------

local function fetchBlacklist()
    local ok, result = pcall(function()
        return game:HttpGet(BLACKLIST_URL)
    end)

    -- Gagal fetch = berhenti total
    if not ok or not result or result == "" then
        error("[Blacklist] Gagal mengambil data blacklist. Script dihentikan.")
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
        local function getPing()
            return math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
        end

        local function getGameName()
            local ok, result = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            return ok and result or "Unknown"
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
-- BUAT GUI BLACKLIST
--------------------------------------------------

local guiShown = false

local function showBlacklistGui(reason)
    if guiShown then return end
    guiShown = true

    -- Hapus GUI lama kalau ada
    local existing = LocalPlayer.PlayerGui:FindFirstChild("BlacklistGui")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlacklistGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    -- Overlay gelap
    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 1
    Overlay.Parent = ScreenGui

    -- Fade in overlay
    TweenService:Create(Overlay, TweenInfo.new(0.4), {
        BackgroundTransparency = 0.5
    }):Play()

    -- Container utama
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 360, 0, 260)
    Container.Position = UDim2.new(0.5, -180, 0.5, -130)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Container.BorderSizePixel = 0
    Container.ZIndex = 2
    Container.Parent = ScreenGui

    -- Animasi muncul dari bawah
    Container.Position = UDim2.new(0.5, -180, 1, 0)
    TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -180, 0.5, -130)
    }):Play()

    -- Corner radius
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container

    -- Stroke border merah
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(200, 40, 40)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Container

    -- Header merah
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 55)
    Header.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    Header.BorderSizePixel = 0
    Header.ZIndex = 3
    Header.Parent = Container

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header

    -- Fix corner bawah header
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 12)
    HeaderFix.Position = UDim2.new(0, 0, 1, -12)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.ZIndex = 3
    HeaderFix.Parent = Header

    -- Icon + Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "You Are Blacklisted!"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.ZIndex = 4
    Title.Parent = Header

    -- Body
    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -55)
    Body.Position = UDim2.new(0, 0, 0, 55)
    Body.BackgroundTransparency = 1
    Body.ZIndex = 3
    Body.Parent = Container

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft   = UDim.new(0, 20)
    UIPadding.PaddingRight  = UDim.new(0, 20)
    UIPadding.PaddingTop    = UDim.new(0, 16)
    UIPadding.PaddingBottom = UDim.new(0, 16)
    UIPadding.Parent = Body

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = Body

    -- Fungsi buat label info
    local function makeRow(labelText, valueText, order)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 28)
        Row.BackgroundTransparency = 1
        Row.LayoutOrder = order
        Row.ZIndex = 4
        Row.Parent = Body

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.38, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = labelText
        Label.TextColor3 = Color3.fromRGB(150, 150, 160)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 4
        Label.Parent = Row

        local Value = Instance.new("TextLabel")
        Value.Size = UDim2.new(0.62, 0, 1, 0)
        Value.Position = UDim2.new(0.38, 0, 0, 0)
        Value.BackgroundTransparency = 1
        Value.Text = valueText
        Value.TextColor3 = Color3.fromRGB(235, 235, 235)
        Value.Font = Enum.Font.GothamBold
        Value.TextSize = 13
        Value.TextXAlignment = Enum.TextXAlignment.Left
        Value.TextTruncate = Enum.TextTruncate.AtEnd
        Value.ZIndex = 4
        Value.Parent = Row
    end

    makeRow("Username", LocalPlayer.Name, 1)
    makeRow("Reason", reason, 2)

    -- Divider
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Divider.BorderSizePixel = 0
    Divider.LayoutOrder = 3
    Divider.ZIndex = 4
    Divider.Parent = Body

    -- Contact label
    local Contact = Instance.new("TextLabel")
    Contact.Size = UDim2.new(1, 0, 0, 28)
    Contact.BackgroundTransparency = 1
    Contact.Text = "Mau banding? Hubungi: " .. OWNER_TG
    Contact.TextColor3 = Color3.fromRGB(100, 150, 255)
    Contact.Font = Enum.Font.Gotham
    Contact.TextSize = 12
    Contact.TextXAlignment = Enum.TextXAlignment.Center
    Contact.LayoutOrder = 4
    Contact.ZIndex = 4
    Contact.Parent = Body
end

--------------------------------------------------
-- HENTIKAN SCRIPT TOTAL
--------------------------------------------------

local stopCallbacks = {}

function Blacklist.OnStop(callback)
    table.insert(stopCallbacks, callback)
end

local function killScript(reason)
    -- Kirim notif telegram dulu
    sendTelegram(reason)
    task.wait(0.5)

    -- Tampilkan GUI
    showBlacklistGui(reason)

    -- Jalankan semua stop callback yang didaftarkan
    for _, cb in ipairs(stopCallbacks) do
        pcall(cb)
    end
end

--------------------------------------------------
-- CEK BLACKLIST
--------------------------------------------------

local function checkAndAct()
    local list = fetchBlacklist() -- error otomatis kalau gagal
    local userId = tostring(LocalPlayer.UserId)

    if list[userId] then
        return true, list[userId]
    end
    return false, nil
end

--------------------------------------------------
-- CHECK (dipanggil sebelum script utama load)
--------------------------------------------------

function Blacklist.Check()
    local isBlacklisted, reason = checkAndAct()
    if isBlacklisted then
        killScript(reason)
        -- Stop eksekusi script utama
        error("[Blacklist] Akses ditolak: " .. reason)
    end
end

--------------------------------------------------
-- START LOOP (dipanggil setelah script utama load)
-- Cek ulang tiap CHECK_INTERVAL detik
-- Kalau tiba-tiba kena blacklist saat main = langsung mati
--------------------------------------------------

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
