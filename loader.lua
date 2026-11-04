-- UNCODE v1 Loader
local url = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/uncode.txt"
local ok, content = pcall(function() return game:HttpGet(url) end)
if not ok then warn("[LOADER] HttpGet failed: " .. tostring(content)); return end
warn("[LOADER] Downloaded " .. #content .. " bytes")
local fn, err = loadstring(content)
if not fn then warn("[LOADER] Parse error: " .. tostring(err)); return end
warn("[LOADER] Executing...")
fn()
