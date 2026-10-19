-- UNCODE  |  Engine: UeCrack + LuaX  |  Executor: Delta (iOS)

local BASE = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/"

local function fetch(name)
    local ok, src = pcall(function() return game:HttpGet(BASE .. name, true) end)
    if not ok or not src or src == "" then
        warn("[UNCODE] fetch failed: " .. name); return ""
    end
    return src
end

-- Reassemble UeCrack from 4 chunks in memory, then run it
task.spawn(function()
    task.wait(0.5)
    local parts = {}
    for i = 1, 4 do
        parts[i] = fetch("ue_" .. i .. ".lua")
        task.wait(0.1)
    end
    local full = table.concat(parts)
    parts = nil
    local fn, err = loadstring(full, "UeCrack")
    full = nil
    if not fn then warn("[UNCODE] UeCrack loadstring: " .. tostring(err)); return end
    local ok2, err2 = pcall(fn)
    if not ok2 then warn("[UNCODE] UeCrack runtime: " .. tostring(err2)) end
end)

-- LuaX: Void / Orbit / Prediction / Sling Bypass / Riot / Defense / Settings
task.spawn(function()
    local t = 0
    repeat task.wait(0.3); t += 0.3 until getgenv().UE_LOADED == true or t >= 90
    task.wait(0.5)
    local src = fetch("luax.lua")
    if src == "" then return end
    local fn, err = loadstring(src, "LuaX")
    if not fn then warn("[UNCODE] LuaX loadstring: " .. tostring(err)); return end
    local ok2, err2 = pcall(fn)
    if not ok2 then warn("[UNCODE] LuaX runtime: " .. tostring(err2)) end
end)
