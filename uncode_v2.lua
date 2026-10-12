-- UNCODE v2  -  Master Loader
-- Architecture:
--   Base  : UeCrack (full UI + standard features)
--   HvH   : LuaX engine (Void, Orbit, Prediction, Sling Bypass, Riot)
--   Rage  : Kicia Rebuild (rage engine)

local BASE_URL = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/"

-- Utility: load a module from the repo
local function loadModule(name)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(BASE_URL .. name))()
    end)
    if not ok then
        warn("[UNCODE] Failed to load " .. name .. ": " .. tostring(err))
    end
end

-- Step 1: Load UeCrack (base UI + standard features)
-- UeCrack sets getgenv().UE_LOADED = true when ready
loadModule("uecrack.lua")

-- Step 2: Wait for UE to finish initializing
local waitTimeout = 60
local elapsed = 0
repeat
    task.wait(0.3)
    elapsed = elapsed + 0.3
until getgenv().UE_LOADED == true or elapsed >= waitTimeout

if elapsed >= waitTimeout then
    warn("[UNCODE] UeCrack load timeout - continuing anyway")
end

-- Step 3: HvH module (LuaX engine, separate Obsidian window)
task.delay(0.5, function()
    loadModule("uncode_hvh.lua")
end)

-- Step 4: Rage module (Kicia)
task.delay(1.0, function()
    loadModule("uncode_rage.lua")
end)
