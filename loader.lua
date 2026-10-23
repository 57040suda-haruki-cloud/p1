local src = game:HttpGet("https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/script.lua")
print("[LOADER] src length: " .. #src)
local fn, err = loadstring(src)
if not fn then
    warn("[LOADER] PARSE ERROR: " .. tostring(err))
else
    print("[LOADER] loadstring OK, calling...")
    local ok2, err2 = pcall(fn)
    if not ok2 then
        warn("[LOADER] RUNTIME ERROR: " .. tostring(err2))
    else
        print("[LOADER] Script finished OK")
    end
end
