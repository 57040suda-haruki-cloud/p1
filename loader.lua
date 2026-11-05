-- UNCODE Combined Loader
-- Auto-detects game and loads the right script

local BASE = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/"

-- Game detection: check for Rivals or FTAP specific objects
local function isRivals()
    local ok, result = pcall(function()
        return game:GetService("ReplicatedStorage"):FindFirstChild("Rivals") ~= nil
            or game:GetService("ReplicatedStorage"):FindFirstChild("RivalsInfo") ~= nil
            or (game.PlaceId == 17017769292)
    end)
    return ok and result
end

local function isFTAP()
    local ok, result = pcall(function()
        return game:GetService("ReplicatedStorage"):FindFirstChild("GrabEvents") ~= nil
            or game:GetService("ReplicatedStorage"):FindFirstChild("MenuToys") ~= nil
    end)
    return ok and result
end

local scriptUrl
if isRivals() then
    scriptUrl = BASE .. "rivals.txt"
    warn("[LOADER] Game: Rivals")
elseif isFTAP() then
    scriptUrl = BASE .. "uncode.txt"
    warn("[LOADER] Game: Fling Things and People")
else
    -- Fallback: check by PlaceId manually or default to FTAP
    scriptUrl = BASE .. "uncode.txt"
    warn("[LOADER] Game: Unknown (defaulting to FTAP)")
end

local ok, content = pcall(function() return game:HttpGet(scriptUrl) end)
if not ok then
    warn("[LOADER] HttpGet failed: " .. tostring(content))
    return
end

warn("[LOADER] Downloaded " .. #content .. " bytes")

local fn, err = loadstring(content)
if not fn then
    warn("[LOADER] Parse error: " .. tostring(err))
    return
end

warn("[LOADER] Executing...")
fn()
