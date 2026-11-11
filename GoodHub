-- Good Hub (n4th patched) v10
-- Tiap bagian dipasang sendiri-sendiri. Kalau salah satu tidak cocok dengan script terbaru,
-- bagian itu dilewati dan yang lain tetap jalan. Urutan percobaan kompilasi:
--   semua yang berhasil dipasang  ->  perbaikan saja  ->  script asli.
assert(type(loadstring) == "function", "[AFK] Executor tidak menyediakan loadstring")
local repository = "ZennJxD/n4th"
local httpService = game:GetService("HttpService")

---------------------------------------------------------------------
-- PENGATURAN CEPAT
---------------------------------------------------------------------
local SOURCE_PATH = "main.lua" -- GANTI kalau nama file script utama di repo berbeda
local BRANCH = "main"
local BREAK_DEFAULT = 20 -- Speed Break (ms) awal, makin kecil makin cepat
local BREAK_MIN = 5      -- batas terendah slider Speed Break

---------------------------------------------------------------------
-- PERBAIKAN: bungkus blok World Finder jadi fungsi (batas 200 variabel local)
---------------------------------------------------------------------
local FIX = {
    {
        name = "buka bungkus World Finder",
        old = "-- WORLD FINDER: pindah world dan verifikasi seluruh foreground sebelum menyebutnya tanpa lock.\ndo\n",
        new = "-- WORLD FINDER: pindah world dan verifikasi seluruh foreground sebelum menyebutnya tanpa lock.\ndo (function()\n",
    },
    {
        name = "tutup bungkus World Finder",
        old = "end\n\n-- ===== TAB: WORLD FINDER =====",
        new = "end)() end\n\n-- ===== TAB: WORLD FINDER =====",
    },
}

---------------------------------------------------------------------
-- FITUR AFK: drop semua seed yang stack-nya penuh (200)
---------------------------------------------------------------------
local AFK = {
    {
        name = "tabel AutoDrop",
        old = [==[local AutoDrop = {]==],
        new = [==[local AutoDrop = {
    AllSeeds = true,]==],
    },
    {
        name = "fungsi seed penuh",
        old = [==[function AutoDrop.labels()]==],
        new = [==[function AutoDrop.isKept(id)
        return (Pabrik.Running and id == Pabrik.SeedId) or (Farmer.Running and id == Farmer.SeedId)
            or (Splice.Running and (id == Splice.A or id == Splice.B)) or false
    end

    function AutoDrop.covers(id)
        if table.find(AutoDrop.Items, id) then return true end
        if not AutoDrop.AllSeeds or AutoDrop.isKept(id) then return false end
        local item = ItemDB[id]
        return item ~= nil and item.kind == "seed"
    end

    AutoDrop.baseFull = AutoDrop.fullItems
    function AutoDrop.fullItems()
        local items = AutoDrop.baseFull()
        if AutoDrop.AllSeeds and Refs.Inv then
            local seen = {}
            for _, id in ipairs(items) do seen[id] = true end
            for _, slot in pairs(Refs.Inv.slots) do
                local id = type(slot) == "table" and slot.id or nil
                local item = type(id) == "number" and ItemDB[id] or nil
                if item and item.kind == "seed" and not seen[id] and not AutoDrop.isKept(id) and invCount(id) >= 200 then
                    seen[id] = true
                    items[#items + 1] = id
                end
            end
        end
        return items
    end

    function AutoDrop.labels()]==],
    },
    {
        name = "drop saat trip",
        old = [==[if table.find(AutoDrop.Items, id) and invCount(id) >= 200 then]==],
        new = [==[if AutoDrop.covers(id) and invCount(id) >= 200 then]==],
    },
    {
        name = "validasi toggle",
        old = [==[local reason = #AutoDrop.Items == 0 and "Pilih item dulu" or AutoDrop.targetError()]==],
        new = [==[local reason = (#AutoDrop.Items == 0 and not AutoDrop.AllSeeds) and "Pilih item dulu" or AutoDrop.targetError()]==],
    },
    {
        name = "Farmer tidak dobel drop",
        old = [==[not (AutoDrop.On and table.find(AutoDrop.Items, id))]==],
        new = [==[not (AutoDrop.On and AutoDrop.covers(id))]==],
    },
    {
        name = "Auto Farm tidak dobel drop",
        old = [==[not (AutoDrop.On and table.find(AutoDrop.Items, seed))]==],
        new = [==[not (AutoDrop.On and AutoDrop.covers(seed))]==],
    },
}

---------------------------------------------------------------------
-- FPS BOOST: toggle + opsi di tab Pengaturan > Opsi
---------------------------------------------------------------------
local FPS = {
    {
        name = "menu FPS Boost",
        old = [==[local OptTab = Box.SetOpt]==],
        new = [==[local OptTab = Box.SetOpt

do (function()
    local Lighting = game:GetService("Lighting")
    local PerfTab = Box.SetPerf or OptTab
    local Boost = {
        On = false, Cap = 40, Quality = true, Shadows = true, Hide3D = false, HideGui = false, Saved = nil,
    }
    Session.FpsBoost = Boost
    Config.add("FpsBoost", Boost, { "Cap", "Quality", "Shadows", "Hide3D", "HideGui" })

    local function setCap(n)
        local f = setfpscap or set_fps_cap
        if type(f) ~= "function" and syn then f = syn.set_fps_cap end
        if type(f) ~= "function" then return false end
        return (pcall(f, n))
    end

    local function apply()
        local s = { effects = {} }
        Boost.Saved = s
        s.lite, s.visual = State.LiteMode, State.Visual
        if not State.LiteMode then setLite(true) end
        State.Visual = false
        if Boost.Quality then
            pcall(function()
                local r = settings().Rendering
                s.quality = r.QualityLevel
                r.QualityLevel = Enum.QualityLevel.Level01
            end)
        end
        if Boost.Shadows then
            pcall(function()
                s.shadows = Lighting.GlobalShadows
                Lighting.GlobalShadows = false
                for _, e in ipairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") then
                        s.effects[e] = e.Enabled
                        e.Enabled = false
                    end
                end
            end)
        end
        if Boost.Hide3D then
            if pcall(function() RunService:Set3dRenderingEnabled(false) end) then s.hide3d = true end
        end
        if Boost.HideGui then
            local gg = PlayerGui:FindFirstChild("GameGui")
            if gg and gg:IsA("ScreenGui") then
                s.gui, s.guiOn = gg, gg.Enabled
                gg.Enabled = false
            end
        end
        s.fps = setCap(Boost.Cap)
        if not s.fps then notify("FPS Boost", "Executor tidak punya setfpscap, batas FPS dilewati", 4) end
    end

    local function restore()
        local s = Boost.Saved
        if not s then return end
        Boost.Saved = nil
        if s.fps then setCap(60) end
        if s.quality then pcall(function() settings().Rendering.QualityLevel = s.quality end) end
        if s.shadows ~= nil then pcall(function() Lighting.GlobalShadows = s.shadows end) end
        for e, was in pairs(s.effects) do pcall(function() e.Enabled = was end) end
        if s.hide3d then pcall(function() RunService:Set3dRenderingEnabled(true) end) end
        if s.gui then pcall(function() s.gui.Enabled = s.guiOn end) end
        if s.lite == false then setLite(false) end
        if s.visual ~= nil then State.Visual = s.visual end
    end

    function Boost.set(on)
        if on == Boost.On then return end
        Boost.On = on
        if on then apply() else restore() end
    end

    local function changed()
        if Boost.On then
            restore()
            apply()
        end
    end

    safe(function()
        PerfTab:Toggle({
            Title = "FPS Boost",
            Desc = "Kurangi beban HP: batas FPS, grafis terendah, Mode Lite & animasi dimatikan. Semua dikembalikan saat dimatikan.",
            Value = false,
            Callback = function(on) Boost.set(on) end,
        })
    end)

    addNumber(PerfTab, {
        Title = "Batas FPS",
        Desc = "Makin rendah makin ringan. Jangan di bawah 30 kalau pakai Clear / Farmer / Pabrik",
        Min = 15, Max = 60, Step = 5, Default = Boost.Cap,
        Callback = function(v)
            Boost.Cap = math.floor(v)
            if Boost.On then setCap(Boost.Cap) end
        end,
    })

    safe(function()
        PerfTab:Toggle({
            Title = "Boost: kualitas grafis terendah",
            Value = Boost.Quality,
            Callback = function(on) Boost.Quality = on changed() end,
        })
    end)

    safe(function()
        PerfTab:Toggle({
            Title = "Boost: matikan bayangan & efek layar",
            Value = Boost.Shadows,
            Callback = function(on) Boost.Shadows = on changed() end,
        })
    end)

    safe(function()
        PerfTab:Toggle({
            Title = "Boost: matikan render 3D",
            Desc = "Game digambar lewat UI, jadi tampilan tidak berubah. Bisa bikin latar hitam di sebagian executor.",
            Value = Boost.Hide3D,
            Callback = function(on) Boost.Hide3D = on changed() end,
        })
    end)

    safe(function()
        PerfTab:Toggle({
            Title = "Boost: sembunyikan layar game (AFK)",
            Desc = "Layar game jadi kosong tapi farming tetap jalan. Paling hemat GPU. Matikan untuk melihat game lagi.",
            Value = Boost.HideGui,
            Callback = function(on) Boost.HideGui = on changed() end,
        })
    end)

    -- dipulihkan otomatis saat script ditutup / dijalankan ulang
    table.insert(Connections, { Disconnect = function() pcall(restore) end })
end)() end]==],
    },
}

---------------------------------------------------------------------
-- SUSUNAN MENU BARU: grup, urutan & nama tab
--   Farming: Auto Farm, Harvest, Splice | World: Clear World, Dirt Farm, Pabrik
--   Shop: Drop, Titik Drop, Vending, Tas | Info: Growscan, Statistik
--   Utilitas: Auto Chat, World Finder, Lainnya | Keamanan: Auto Mods, Auto Reconnect
--   Setelan: Umum, Performa, Koneksi & Config, Discord
---------------------------------------------------------------------
local LAYOUT = {
    {
        name = "grup World, Shop, Info",
        old = [==[{ key = "farm", title = "Farming", icon = "sprout", opened = true },]==],
        new = [==[{ key = "farm", title = "Farming", icon = "sprout", opened = true },
    { key = "world", title = "World", icon = "map" },
    { key = "shop", title = "Shop", icon = "shopping-bag" },
    { key = "info", title = "Info", icon = "info" },]==],
    },
    {
        name = "grup Utilitas",
        old = [==[{ key = "fitur", title = "Fitur", icon = "sparkles" },]==],
        new = [==[{ key = "fitur", title = "Utilitas", icon = "sparkles" },]==],
    },
    {
        name = "urutan dan nama tab",
        old = [==[local function makeTab(title, icon, group)]==],
        new = [==[Session.PreTabs = {}
do (function()
    -- { judul lama (dipakai kode), judul baru, ikon, grup }. Urutan di sini = urutan di sidebar.
    local PLAN = {
        { "Farm", "Auto Farm", "pickaxe", "farm" },
        { "Farmer", "Harvest", "leaf", "farm" },
        { "Splice", "Splice", "git-merge", "farm" },
        { "Clear World", "Clear World", "eraser", "world" },
        { "Lahan", "Dirt Farm", "layout-grid", "world" },
        { "Pabrik", "Pabrik", "factory", "world" },
        { "Auto Drop", "Drop", "package-open", "shop" },
        { "Vending", "Vending", "store", "shop" },
        { "Tas", "Tas", "backpack", "shop" },
        { "Growscan", "Growscan", "scan-search", "info" },
        { "Statistik", "Statistik", "bar-chart-3", "info" },
        { "Auto Chat", "Auto Chat", "message-circle", "fitur" },
        { "World Finder", "World Finder", "globe", "fitur" },
        { "Bonus", "Lainnya", "gift", "fitur" },
        { "Penjaga", "Auto Mods", "eye", "aman" },
        { "Auto Reconnect", "Auto Reconnect", "refresh-cw", "aman" },
        { "Pengaturan", "Umum", "sliders-horizontal", "setel" },
        { "Performa", "Performa", "gauge", "setel" },
        { "Koneksi", "Koneksi & Config", "plug", "setel" },
        { "Discord", "Discord", "bell", "setel" },
    }
    for _, e in ipairs(PLAN) do
        local section = Groups[e[4]]
        if section then
            local ok, tab = pcall(function() return section:Tab({ Title = e[2], Icon = e[3] }) end)
            if ok and tab then Session.PreTabs[e[1]] = tab end
        end
    end
    Session.PreTabs["Titik Drop"] = Session.PreTabs["Auto Drop"] -- satu tab Drop
end)() end

local function makeTab(title, icon, group)
    local cached = Session.PreTabs[title]
    if cached then return cached end
    local created = Session.rawTab(title, icon, group)
    Session.PreTabs[title] = created
    return created
end

Session.rawTab = function(title, icon, group)]==],
    },
    {
        name = "Auto Reconnect jadi tab Keamanan",
        old = [==[local rBox = box(ConnTab, "Auto Reconnect", false)]==],
        new = [==[local rBox = box(makeTab("Auto Reconnect", "refresh-cw", "aman"), "Auto Reconnect", true)]==],
    },
    {
        name = "kotak Performa",
        old = [==[Box.SetOpt = box(SetTab, "Opsi", true)]==],
        new = [==[Box.SetOpt = box(SetTab, "Opsi", true)
Box.SetPerf = box(makeTab("Performa", "gauge", "setel"), "Performa", true)]==],
    },
    {
        name = "Mode Lite ke Performa",
        old = "OptTab:Toggle({\n        Title = \"Mode Lite\",",
        new = "Box.SetPerf:Toggle({\n        Title = \"Mode Lite\",",
    },
    {
        name = "Mute suara ke Performa",
        old = "OptTab:Toggle({\n        Title = \"Mute suara pukulan\",",
        new = "Box.SetPerf:Toggle({\n        Title = \"Mute suara pukulan\",",
    },
    {
        name = "Animasi aksi ke Performa",
        old = "OptTab:Toggle({\n        Title = \"Animasi aksi\",",
        new = "Box.SetPerf:Toggle({\n        Title = \"Animasi aksi\",",
    },
    {
        name = "terjemahan English",
        old = [==[["Fitur"] = "Features", ["Keamanan"] = "Security", ["Setelan"] = "Setup",]==],
        new = [==[["Fitur"] = "Features", ["Keamanan"] = "Security", ["Setelan"] = "Setup",
    ["Utilitas"] = "Utilities", ["Umum"] = "General", ["Performa"] = "Performance",
    ["Koneksi & Config"] = "Connection & Config",
    ["Status Harvest"] = "Harvest Status", ["Jalankan Harvest"] = "Run Harvest",
    ["Status Dirt Farm"] = "Dirt Farm Status", ["Bangun Dirt Farm"] = "Build Dirt Farm",
    ["Status Auto Mods"] = "Auto Mods Status", ["Aktifkan Auto Mods"] = "Enable Auto Mods",
    ["Lanjutan: pilih item sendiri"] = "Advanced: pick items yourself",
    ["Lanjutan: drop di world lain"] = "Advanced: drop in another world",
    ["Set titik drop di sini"] = "Set drop point here",
    ["Berdiri di tempat drop lalu tekan. Dipakai semua fitur drop."] = "Stand where you want to drop, then press. Used by every drop feature.",
    ["Seed yang stack-nya penuh (200) dibawa ke titik drop, lalu balik farming. Block atau item lain bisa dipilih di Lanjutan."] =
        "Full seed stacks (200) are taken to the drop point, then back to farming. Blocks or other items can be picked under Advanced.",]==],
    },
}

---------------------------------------------------------------------
-- RAPI-IN UI: tab Farm. Collect & kecepatan (global) pindah ke Setelan > Umum,
-- Auto Break Block pindah ke tab Clear World.
---------------------------------------------------------------------
local FARMUI = {
    {
        name = "judul kotak Auto Farm",
        old = [==[Box.FarmCtl = box(FarmTab, "Kontrol", true)]==],
        new = [==[Box.FarmCtl = box(FarmTab, "Auto Farm", true)]==],
    },
    {
        name = "kotak Mode, Collect, Kecepatan",
        old = [==[Box.FarmSpeed = box(FarmTab, "Mode & Kecepatan", false)]==],
        new = [==[Box.FarmSpeed = box(FarmTab, "Mode", false)
Box.GlobCollect = box(makeTab("Pengaturan", "sliders-horizontal", "setel"), "Collect", false)
Box.GlobSpeed = box(makeTab("Pengaturan", "sliders-horizontal", "setel"), "Kecepatan", false)]==],
    },
    {
        name = "Auto Collect pindah",
        old = "Box.FarmCtl:Toggle({\n        Title = \"Auto Collect\",",
        new = "Box.GlobCollect:Toggle({\n        Title = \"Auto Collect\",",
    },
    {
        name = "Mode collect pindah",
        old = "Box.FarmCtl:Dropdown({\n        Title = \"Mode collect\",",
        new = "Box.GlobCollect:Dropdown({\n        Title = \"Mode collect\",",
    },
    {
        name = "Radius collect pindah",
        old = "addNumber(Box.FarmCtl, {\n    Title = \"Radius collect (mode Remote)\",",
        new = "addNumber(Box.GlobCollect, {\n    Title = \"Radius collect (mode Remote)\",",
    },
    {
        name = "Speed Place pindah",
        old = "addNumber(SpeedTab, {\n    Title = \"Speed Place (ms)\",",
        new = "addNumber(Box.GlobSpeed, {\n    Title = \"Speed Place (ms)\",",
    },
    {
        name = "Speed Break pindah",
        old = "addNumber(SpeedTab, {\n    Title = \"Speed Break (ms)\",",
        new = "addNumber(Box.GlobSpeed, {\n    Title = \"Speed Break (ms)\",",
    },
    {
        name = "Auto Break Block pindah ke Clear World",
        old = [==[local controls = box(FarmTab, "Auto Break Block", true)]==],
        new = [==[local controls = box(makeTab("Clear World", "eraser", "world"), "Auto Break Block", false)]==],
    },
}

---------------------------------------------------------------------
-- GANTI NAMA yang kelihatan di menu: Farmer -> Harvest, Lahan -> Dirt Farm, Penjaga -> Auto Mods
---------------------------------------------------------------------
local RENAME = {
    {
        name = "judul notifikasi",
        old = [==[Title = I18N.T(title), Content = I18N.T(content)]==],
        new = [==[Title = I18N.T(({ Penjaga = "Auto Mods", Lahan = "Dirt Farm", ["Bangun Lahan"] = "Dirt Farm", Farmer = "Harvest" })[title] or title), Content = I18N.T(content)]==],
    },
    { name = "Status Farmer", old = [==[Title = "Status Farmer"]==], new = [==[Title = "Status Harvest"]==] },
    { name = "Jalankan Farmer", old = [==[Title = "Jalankan Farmer",]==], new = [==[Title = "Jalankan Harvest",]==] },
    { name = "Status Lahan", old = [==[Title = "Status Lahan"]==], new = [==[Title = "Status Dirt Farm"]==] },
    { name = "kotak Bangun Lahan", old = [==[local lCtl = box(LTab, "Bangun Lahan", true)]==], new = [==[local lCtl = box(LTab, "Bangun Dirt Farm", true)]==] },
    { name = "toggle Bangun Lahan", old = [==[Title = "Bangun Lahan",]==], new = [==[Title = "Bangun Dirt Farm",]==] },
    { name = "Status Penjaga", old = [==[Title = "Status Penjaga"]==], new = [==[Title = "Status Auto Mods"]==] },
    { name = "Aktifkan Penjaga", old = [==[Title = "Aktifkan Penjaga",]==], new = [==[Title = "Aktifkan Auto Mods",]==] },
}

---------------------------------------------------------------------
-- NAMA: n4th -> Good Hub + tema Biru Hitam
-- Nama folder config dan nama internal tidak diubah, supaya pengaturan lama tidak hilang.
---------------------------------------------------------------------
local BRAND = {
    {
        name = "judul jendela + tema Biru Hitam",
        old = "WindUI:CreateWindow({\n    Title = \"n4th\",",
        new = [==[do
    local function goodHubTheme()
        pcall(function()
            WindUI:AddTheme({
                Name = "GoodHub",
                Accent = Color3.fromHex("#1E6FFF"),
                Dialog = Color3.fromHex("#0A0F1C"),
                Outline = Color3.fromHex("#1B3A7A"),
                Text = Color3.fromHex("#E6EEFF"),
                Placeholder = Color3.fromHex("#6B7FA8"),
                Background = Color3.fromHex("#05070D"),
                Button = Color3.fromHex("#0F1A33"),
                Icon = Color3.fromHex("#5AA2FF"),
            })
            WindUI:SetTheme("GoodHub")
        end)
    end
    goodHubTheme()
    task.delay(1, goodHubTheme) -- jaga-jaga kalau tema bawaan menimpa
end
WindUI:CreateWindow({
    Title = "Good Hub",]==],
    },
    { name = "tombol buka menu", old = "Window:EditOpenButton({\n        Title = \"n4th\",", new = "Window:EditOpenButton({\n        Title = \"Good Hub\"," },
    { name = "popup bahasa", old = "WindUI:Popup({\n            Title = \"n4th\",", new = "WindUI:Popup({\n            Title = \"Good Hub\"," },
    { name = "nama di atas karakter", old = [==[NameText = "n4th",]==], new = [==[NameText = "Good Hub",]==] },
    { name = "nama pengirim Discord", old = [==[username = "n4th",]==], new = [==[username = "Good Hub",]==] },
    { name = "tes notifikasi", old = [==[Hook.send("test", "Tes notifikasi dari n4th")]==], new = [==[Hook.send("test", "Tes notifikasi dari Good Hub")]==] },
    { name = "tes notifikasi EN", old = [==[["Tes notifikasi dari n4th"] = "Test notification from n4th",]==], new = [==[["Tes notifikasi dari Good Hub"] = "Test notification from Good Hub",]==] },
    { name = "tes World Finder", old = [==["World Finder siap mengirim hasil hunting dari n4th"]==], new = [==["World Finder siap mengirim hasil hunting dari Good Hub"]==] },
    { name = "notifikasi koneksi", old = [==[reconnect("n4th v5.2")]==], new = [==[reconnect("Good Hub")]==] },
}

---------------------------------------------------------------------
-- PEMASANG PATCH
---------------------------------------------------------------------
local function log(msg)
    print("[AFK] " .. msg)
end

local function fetch()
    local url = ("https://raw.githubusercontent.com/%s/%s/%s"):format(repository, BRANCH, SOURCE_PATH)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or type(body) ~= "string" or #body == 0 then
        error("[AFK] Gagal mengunduh script: " .. tostring(body))
    end
    return body
end

-- Ganti kemunculan pertama teks `old` tanpa pola regex
local function replaceOnce(src, old, new)
    local s, e = src:find(old, 1, true)
    if not s then return nil end
    return src:sub(1, s - 1) .. new .. src:sub(e + 1)
end

-- Satu bagian dipasang utuh atau dilewati utuh (kalau ada satu entri yang tidak cocok)
local function applySection(src, label, entries)
    local out = src
    for _, p in ipairs(entries) do
        local nxt = replaceOnce(out, p.old, p.new)
        if not nxt then
            log(("bagian '%s' dilewati: '%s' tidak cocok"):format(label, p.name))
            return src, false
        end
        out = nxt
    end
    log(("bagian '%s' terpasang (%d perubahan)"):format(label, #entries))
    return out, true
end

local function compiles(src)
    local fn, err = loadstring(src, "=GoodHub")
    return fn, err
end

local original = fetch()

-- Percobaan 1: semua bagian yang cocok (FIX dulu, LAYOUT sebelum FARMUI)
local patched = original
local SECTIONS = {
    { "FIX", FIX }, { "AFK", AFK }, { "LAYOUT", LAYOUT },
    { "FPS", FPS }, { "FARMUI", FARMUI }, { "RENAME", RENAME }, { "BRAND", BRAND },
}
for _, s in ipairs(SECTIONS) do
    patched = select(1, applySection(patched, s[1], s[2]))
end

-- Ganti kata "tester" (huruf kecil, Tester, TESTER) menjadi "Kann". Hanya kata utuh.
do
    local total = 0
    for _, word in ipairs({ "tester", "Tester", "TESTER" }) do
        local n
        patched, n = patched:gsub("%f[%w_]" .. word .. "%f[^%w_]", "Kann")
        total = total + n
    end
    log(("penggantian 'tester' -> 'Kann': %d tempat"):format(total))
end

-- Percepat Speed Break (ms): makin kecil makin cepat
do
    local n
    patched, n = patched:gsub(
        'addNumber%(([%w%.]+), {(\n%s*)Title = "Speed Break %(ms%)",',
        function(target, indent)
            return ("addNumber(%s, (function(t) t.Min = %d t.Default = %d return t end){%sTitle = \"Speed Break (ms)\","):format(
                target, BREAK_MIN, BREAK_DEFAULT, indent)
        end
    )
    log(("Speed Break dipercepat: %d tempat"):format(n))
end

local fn, err = compiles(patched)

-- Percobaan 2: perbaikan kompilasi saja
if not fn then
    log("gagal kompilasi dengan semua bagian: " .. tostring(err))
    local fixOnly = select(1, applySection(original, "FIX", FIX))
    fn, err = compiles(fixOnly)
end

-- Percobaan 3: script asli
if not fn then
    log("gagal kompilasi dengan FIX saja: " .. tostring(err))
    fn, err = compiles(original)
end

assert(fn, "[AFK] Script tidak bisa dikompilasi sama sekali: " .. tostring(err))
return fn()
