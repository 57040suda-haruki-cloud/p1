-- UNCODE v1 · Cache-Busting Loader
-- Paste this into Delta instead of the full script URL.
-- The ?v= timestamp forces Delta to bypass its HTTP cache every execution.
local url = "https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/script.lua"
loadstring(game:HttpGet(url .. "?v=" .. tostring(os.time())))()
