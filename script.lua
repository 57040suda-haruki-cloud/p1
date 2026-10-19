-- UNCODE
-- Engine: UeCrack (Visuals/ESP/Combat/Aimbot) + LuaX (HvH/Void/Orbit/Prediction)
-- Executor: Delta (iOS)

local BASE = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/"

local function safe_load(url, label)
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not src or src == "" then
        warn("[UNCODE] HttpGet failed: " .. label)
        return
    end
    local fn, err = loadstring(src, label)
    if not fn then
        warn("[UNCODE] loadstring failed (" .. label .. "): " .. tostring(err))
        return
    end
    local ok2, err2 = pcall(fn)
    if not ok2 then
        warn("[UNCODE] runtime error (" .. label .. "): " .. tostring(err2))
    end
end

-- UeCrack: Visuals / ESP / Combat / Aimbot / Silent Aim etc.
task.spawn(function()
    task.wait(0.5)
    safe_load(BASE .. "ue.lua", "UeCrack")
end)

-- LuaX: HvH / Void / Orbit / Prediction / Sling Bypass / Riot / Defense
-- Waits for UeCrack to finish initializing (UE_LOADED flag)
task.spawn(function()
    local t = 0
    repeat task.wait(0.3); t = t + 0.3 until getgenv().UE_LOADED == true or t >= 90
    task.wait(0.5)
    safe_load(BASE .. "luax.lua", "LuaX")
end)
