-- UNCODE Combined Loader
-- Auto-detects game and loads the right script

local BASE = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/"

local RS = game:GetService("ReplicatedStorage")

-- Debug: log what we see
warn("[LOADER] PlaceId: " .. tostring(game.PlaceId))
warn("[LOADER] RS.Rivals: "    .. tostring(RS:FindFirstChild("Rivals")))
warn("[LOADER] RS.RivalsInfo: " .. tostring(RS:FindFirstChild("RivalsInfo")))
warn("[LOADER] RS.GrabEvents: " .. tostring(RS:FindFirstChild("GrabEvents")))
warn("[LOADER] RS.MenuToys: "  .. tostring(RS:FindFirstChild("MenuToys")))

-- Game detection: FTAP first (GrabEvents/MenuToys are reliable)
local function isFTAP()
    local ok, result = pcall(function()
        return RS:FindFirstChild("GrabEvents") ~= nil
            or RS:FindFirstChild("MenuToys") ~= nil
    end)
    return ok and result
end

local function isRivals()
    local ok, result = pcall(function()
        return RS:FindFirstChild("Rivals") ~= nil
            or RS:FindFirstChild("RivalsInfo") ~= nil
            or (game.PlaceId == 17017769292)
    end)
    return ok and result
end

local scriptUrl
if isFTAP() then
    scriptUrl = BASE .. "uncode.txt"
    warn("[LOADER] Game: Fling Things and People")
elseif isRivals() then
    scriptUrl = BASE .. "rivals.txt"
    warn("[LOADER] Game: Rivals")
else
    scriptUrl = BASE .. "rivals.txt"
    warn("[LOADER] Game: Unknown (defaulting to Rivals)")
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
