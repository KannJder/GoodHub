--=====================================================================
-- Good Hub - BAGIAN AWAL (versi diperbaiki)
-- Ganti baris dari "local G = ..." sampai sebelum "local State = {"
-- dengan isi file ini. Sisanya tidak diubah.
--=====================================================================

local G = (getgenv and getgenv()) or _G
local SESSION_KEYS = { "__GoodHub", "__KzoyzOpus", "__GTFarm" } -- dua terakhir = nama versi lama

---------------------------------------------------------------------
-- SESI & CLEANUP
---------------------------------------------------------------------
for _, key in ipairs(SESSION_KEYS) do
    local old = G[key]
    if type(old) == "table" and type(old.Cleanup) == "function" then
        pcall(old.Cleanup)
    end
    G[key] = nil
end

local Session = { Connections = {}, Destroyers = {}, Closed = false }
G.__GoodHub = Session

local function alive()
    return not Session.Closed and G.__GoodHub == Session
end

-- Daftarkan koneksi supaya otomatis diputus saat Cleanup
local function track(conn)
    if conn then Session.Connections[#Session.Connections + 1] = conn end
    return conn
end

-- Daftarkan fungsi pembersih (hapus UI, restore hook, dst)
local function onCleanup(fn)
    Session.Destroyers[#Session.Destroyers + 1] = fn
end

function Session.Cleanup()
    if Session.Closed then return end
    Session.Closed = true
    for _, c in ipairs(Session.Connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, fn in ipairs(Session.Destroyers) do
        pcall(fn)
    end
    table.clear(Session.Connections)
    table.clear(Session.Destroyers)
    if G.__GoodHub == Session then G.__GoodHub = nil end
end

---------------------------------------------------------------------
-- IDENTITAS THREAD (tanpa coroutine yang bisa bentrok)
---------------------------------------------------------------------
local getId = getthreadidentity or get_thread_identity or getidentity
    or (syn and syn.get_thread_identity)
local setId = setthreadidentity or set_thread_identity or setidentity
    or (syn and syn.set_thread_identity)

do
    if type(getId) == "function" then
        local ok, v = pcall(getId)
        if ok then Session.Ident = v end
    end
end

local UI = {}

function UI.ident()
    if type(getId) ~= "function" then return nil end
    local ok, v = pcall(getId)
    return ok and v or nil
end

-- Jalankan fn SATU kali dengan identitas penuh. Hasil: ok, err (seperti pcall).
-- fn tidak boleh yield (jangan task.wait / WaitForChild di dalamnya).
function UI.exec(fn)
    local prev = UI.ident()
    if Session.Ident and type(setId) == "function" then
        pcall(setId, Session.Ident)
    end
    local ok, err = pcall(fn)
    if prev and type(setId) == "function" then
        pcall(setId, prev)
    end
    if ok then return true end
    return false, tostring(err)
end

UI.Jobs = {}
function UI.later(key, fn, delay)
    UI.Jobs[key] = { fn = fn, at = os.clock() + (delay or 0) }
end
function UI.runJobs()
    local now = os.clock()
    local due = {}
    for key, job in pairs(UI.Jobs) do
        if now >= job.at then due[#due + 1] = key end
    end
    for _, key in ipairs(due) do
        local job = UI.Jobs[key]
        if job and now >= job.at then
            UI.Jobs[key] = nil
            local ok, err = pcall(job.fn)
            if not ok then
                warn("[Good Hub] UI job " .. tostring(key) .. ": " .. tostring(err))
            end
        end
    end
end

---------------------------------------------------------------------
-- HELPER AMAN: WaitForChild ber-timeout & require ber-pcall
---------------------------------------------------------------------
local function fail(msg)
    warn("[Good Hub] " .. msg)
    Session.Cleanup()
    error("[Good Hub] " .. msg, 0)
end

-- Tunggu child maksimal `timeout` detik. required=true -> hentikan script kalau tidak ada.
local function waitFor(parent, name, timeout, required)
    local obj = parent and parent:WaitForChild(name, timeout or 10)
    if not obj and required then
        fail("Tidak menemukan '" .. tostring(name) .. "'. Game mungkin sudah update.")
    end
    return obj
end

-- require aman: kembalikan ok, modul
local function safeRequire(moduleScript, label)
    if typeof(moduleScript) ~= "Instance" then
        return false, "modul " .. tostring(label) .. " tidak ada"
    end
    local ok, mod = pcall(require, moduleScript)
    if not ok then
        warn("[Good Hub] require " .. tostring(label) .. " gagal: " .. tostring(mod))
    end
    return ok, mod
end

---------------------------------------------------------------------
-- SERVICES & MODUL GAME
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = waitFor(LocalPlayer, "PlayerGui", 15, true)

local Shared = waitFor(ReplicatedStorage, "Shared", 15, true)
local WorldRemotes = waitFor(ReplicatedStorage, "WorldRemotes", 15, true)
-- Remote lama (sebelum ByteNet). Hanya dipakai kalau fungsi baru tidak ada.
local SetTileRemote = WorldRemotes:FindFirstChild("SetTile")

-- Modul wajib: kalau gagal, script berhenti dengan pesan jelas (bukan crash diam-diam)
local okItemDB, ItemDB = safeRequire(waitFor(Shared, "ItemDB", 10), "ItemDB")
local okInv, InventoryModule = safeRequire(waitFor(Shared, "Inventory", 10), "Inventory")
if not okItemDB or not okInv then
    fail("Modul ItemDB / Inventory gagal dimuat. Game mungkin sudah update.")
end

-- Modul opsional
local NetOk, Net = safeRequire(Shared:FindFirstChild("Net"), "Net")
local GameGui = waitFor(PlayerGui, "GameGui", 15, true)
local ParticlesOk, ParticlesModule = safeRequire(waitFor(GameGui, "Particles", 10), "Particles")
local MenuModOk, MenuModule = safeRequire(waitFor(GameGui, "WorldMenu", 10), "WorldMenu")
local RolesOk, RolesModule = safeRequire(Shared:FindFirstChild("Roles"), "Roles")
local SfxOk, SfxModule = safeRequire(Shared:FindFirstChild("Sfx"), "Sfx")

---------------------------------------------------------------------
-- WINDUI (dimuat aman)
---------------------------------------------------------------------
-- Untuk kestabilan, ganti "latest" dengan versi tertentu yang sudah kamu tes,
-- contoh: .../releases/download/<versi>/main.lua
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"

local WindUI
do
    local okGet, src = pcall(game.HttpGet, game, WINDUI_URL)
    if not okGet or type(src) ~= "string" or #src < 100 then
        fail("Gagal download WindUI (cek koneksi / GitHub): " .. tostring(src))
    end
    local chunk, cErr = loadstring(src)
    if not chunk then fail("WindUI rusak: " .. tostring(cErr)) end
    local okRun, lib = pcall(chunk)
    if not okRun or type(lib) ~= "table" then
        fail("WindUI gagal dijalankan: " .. tostring(lib))
    end
    WindUI = lib
end

---------------------------------------------------------------------
-- TEMA HITAM BIRU (diterapkan global, tidak perlu ubah CreateWindow)
---------------------------------------------------------------------
pcall(function()
    WindUI:AddTheme({
        Name = "GoodHub",
        Accent = Color3.fromHex("#3B82F6"),
        Background = Color3.fromHex("#090D16"),
        Outline = Color3.fromHex("#1B2742"),
        Text = Color3.fromHex("#E6EDF7"),
        Placeholder = Color3.fromHex("#7F8CA6"),
        Button = Color3.fromHex("#111A2E"),
        Icon = Color3.fromHex("#6AA5FF"),
    })
    WindUI:SetTheme("GoodHub")
end)

---------------------------------------------------------------------
-- PENERJEMAH: panggil installTranslator(I18N) SETELAH tabel I18N.EN / I18N.PH
-- di script asli selesai dibuat. Ini menggantikan I18N.T dan I18N.build lama.
---------------------------------------------------------------------
local function isLetter(ch)
    return ch ~= "" and ch:match("[%a\128-\255]") ~= nil
end

local function replacePlain(text, from, to)
    local firstLetter = isLetter(from:sub(1, 1))
    local lastLetter = isLetter(from:sub(-1))
    local out, pos = {}, 1
    while true do
        local s, e = text:find(from, pos, true)
        if not s then break end
        local before = s > 1 and text:sub(s - 1, s - 1) or ""
        local after = text:sub(e + 1, e + 1)
        local okBefore = not (firstLetter and isLetter(before))
        local okAfter = not (lastLetter and isLetter(after))
        out[#out + 1] = text:sub(pos, s - 1)
        out[#out + 1] = (okBefore and okAfter) and to or from
        pos = e + 1
    end
    out[#out + 1] = text:sub(pos)
    return table.concat(out)
end

local function installTranslator(I18N)
    function I18N.build()
        local seen, list = {}, {}
        for _, pair in ipairs(I18N.PH or {}) do
            local from, to = pair[1], pair[2]
            if from and to and not seen[from] then
                seen[from] = true
                list[#list + 1] = { from, to }
            end
        end
        table.sort(list, function(a, b) return #a[1] > #b[1] end)
        I18N.Sorted = list
    end
    function I18N.T(text)
        if I18N.Lang ~= "en" or type(text) ~= "string" or text == "" then return text end
        local exact = I18N.EN and I18N.EN[text]
        if exact then return exact end
        if not I18N.Sorted then I18N.build() end
        for _, pair in ipairs(I18N.Sorted) do
            text = replacePlain(text, pair[1], pair[2])
        end
        return text
    end
end

--=====================================================================
-- >>> TEMPEL SISA SCRIPT ASLI DI BAWAH INI <<<
-- Mulai dari baris:  local State = {
-- sampai akhir file.
--=====================================================================
