-- Good Hub - script DIAGNOSA (bukan script utama)
-- Jalankan di Delta. Tiap langkah muncul sebagai notifikasi di layar + tercetak di console.

local function say(text)
    print("[Diagnosa] " .. text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Diagnosa", Text = text, Duration = 6,
        })
    end)
end

say("1. Script jalan di executor")

say("2. PlaceId: " .. tostring(game.PlaceId))

say("3. loadstring: " .. (type(loadstring) == "function" and "ADA" or "TIDAK ADA"))
say("4. HttpGet: " .. (pcall(function() return game.HttpGet end) and "ADA" or "TIDAK ADA"))
say("5. getgenv: " .. (type(getgenv) == "function" and "ADA" or "TIDAK ADA"))

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared", 10)
say("6. ReplicatedStorage.Shared: " .. (Shared and "ADA" or "TIDAK ADA (game beda / sudah update)"))
say("7. WorldRemotes: " .. (RS:WaitForChild("WorldRemotes", 10) and "ADA" or "TIDAK ADA"))

if Shared then
    for _, name in ipairs({ "ItemDB", "Inventory" }) do
        local m = Shared:FindFirstChild(name)
        local ok = m and pcall(require, m)
        say("8. Modul " .. name .. ": " .. (ok and "OK" or "GAGAL / TIDAK ADA"))
    end
end

local okGet, src = pcall(function()
    return game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
end)
say("9. Download WindUI: " .. ((okGet and type(src) == "string" and #src > 100) and ("OK (" .. #src .. " byte)") or ("GAGAL: " .. tostring(src))))

if okGet and type(loadstring) == "function" then
    local chunk, err = loadstring(src)
    say("10. Compile WindUI: " .. (chunk and "OK" or ("GAGAL: " .. tostring(err))))
end

say("SELESAI. Catat langkah terakhir yang muncul.")
