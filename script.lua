-- UNCODE v6 -- Rivals HvH -- KiciaHook/UE Full Integration
-- UI: Obsidian Library (message 2 style)
-- All code/comments in English. Do NOT use Japanese in code.

-- ============================================================
-- THREAD IDENTITY ELEVATION
-- ============================================================
pcall(setthreadidentity, 8)
pcall(setthreadidentity, 7)
pcall(setthreadidentity, 6)
pcall(setthreadidentity, 3)

-- ============================================================
-- EXECUTOR ENVIRONMENT DETECTION
-- ============================================================
local genv = (getgenv and getgenv()) or _G
local renv = (getrenv and getrenv()) or _G

-- Executor API availability flags
local HAS_HOOKFUNC   = hookfunction  ~= nil
local HAS_HOOKMETA   = hookmetamethod ~= nil
local HAS_GETCONNS   = getconnections ~= nil
local HAS_NEWCC      = newcclosure   ~= nil
local HAS_CLONEFUNC  = clonefunction ~= nil
local HAS_RAWMT      = getrawmetatable ~= nil
local HAS_SETHIDDEN  = sethiddenproperty ~= nil
local HAS_GETHIDDEN  = gethiddenproperty ~= nil
local HAS_CACHE      = cache ~= nil
local HAS_SCRIPTS    = getscripts    ~= nil
local HAS_MODULES    = getloadedmodules ~= nil
local HAS_DEBUG_UPV  = (debug and debug.getupvalue) ~= nil
local HAS_DEBUG_UPS  = (debug and debug.setupvalue) ~= nil
local HAS_DEBUG_CON  = (debug and debug.getconstants) ~= nil
local HAS_FIRESIG    = firesignal    ~= nil
local HAS_IDENTITY   = setidentity   ~= nil
local HAS_ISCLOS     = isexecutorclosure ~= nil

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local Camera           = Workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- GUID
-- ============================================================
local function GUID()
    return HttpService:GenerateGUID(false)
end

-- ============================================================
-- FETCH UTILITY
-- ============================================================
local function fetch(url)
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and res and #res > 10 then return res end
    return nil
end

-- ============================================================
-- LOAD OBSIDIAN UI LIBRARY
-- ============================================================
local Library, ThemeManager, SaveManager
local Toggles = {}
local Options  = {}

do
    local libSrc = fetch("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/Library.lua")
    if libSrc then
        local ok, fn = pcall(loadstring, libSrc)
        if ok and fn then
            local ok2, res = pcall(fn)
            if ok2 and type(res) == "table" then
                Library = res
            end
        end
    end
    if Library then
        Toggles = Library.Toggles or Toggles
        Options  = Library.Options  or Options
        local tmSrc = fetch("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/addons/ThemeManager.lua")
        if tmSrc then pcall(function() ThemeManager = loadstring(tmSrc)() end) end
        local smSrc = fetch("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/addons/SaveManager.lua")
        if smSrc then pcall(function() SaveManager = loadstring(smSrc)() end) end
    end
    if not Library then
        -- Fallback headless stub so gameplay still works without UI
        local function fake()
            local e = {}
            setmetatable(e, {__index = function() return function(...) return fake() end end})
            return e
        end
        local fT = setmetatable({}, {__index = function() return {Value=false} end})
        local fO = setmetatable({}, {__index = function() return {Value=nil}   end})
        Library = {
            Toggles = fT, Options = fO,
            Notify  = function() end,
            Unload  = function() end,
            CreateWindow = function() return fake() end,
        }
        Toggles = fT
        Options  = fO
        warn("[UNCODE v6] Obsidian unavailable - headless mode")
    end
end

-- ============================================================
-- WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title            = "UNCODE v6",
    Footer           = "rivals . hvh . kiciahook . ue",
    NotifySide       = "Right",
    ShowCustomCursor = true,
    AutoShow         = true,
    Center           = true,
    Resizable        = true,
    ShowMobileButtons = true,
    MobileButtonsSide = "Left",
    ToggleKeybind    = Enum.KeyCode.RightShift,
    EnableSidebarResize = true,
})

local function Notify(t, d)
    pcall(function()
        Library:Notify({Title="UNCODE", Description=t, Time=d or 3})
    end)
end

-- ============================================================
-- TABS
-- ============================================================
local Tabs = {}
for _, nm in ipairs({"Combat","Void","Movement","AntiAim","Visuals","Hooks","Configs","Settings"}) do
    Tabs[nm] = Window:AddTab(nm)
end

-- Shortcut helper: AddToggle + optional keybind
local function BT(box, id, txt, def, cb)
    local t = box:AddToggle(id, {Text=txt, Default=def or false, Callback=cb or function() end})
    pcall(function()
        t:AddKeyPicker(id.."_key", {Default="None", Mode="Toggle", Text=txt, SyncToggleState=true, NoUI=false})
    end)
    return t
end

-- ============================================================
-- CONFIG TABLE (synced with Obsidian Options/Toggles)
-- ============================================================
local Cfg = {
    -- Aimbot
    AimbotEnabled    = false,
    AimbotFOV        = 200,
    AimbotSmooth     = 0.18,
    AimbotBone       = "Head",
    AimbotPrediction = true,
    AimbotPredMult   = 1.2,
    AimbotSilent     = false,
    AimbotSilentFOV  = 300,
    AimbotVisCheck   = true,
    AimbotTeamCheck  = false,

    -- VoidSpam
    VoidSpamEnabled  = false,
    VoidSpamDelay    = 0.05,
    VoidSpamCount    = 8,
    VoidSpamSpread   = 15,
    VoidSpamAutoAim  = true,
    VoidSpamRandAngle = true,
    VoidSpamMultiDir = false,

    -- FakePos
    FakePosEnabled   = false,
    FakePosDepth     = 5.8,
    FakePosMode      = "Ground",

    -- VelDesync
    VelDesyncEnabled = false,
    VelDesyncSpeed   = 80,
    VelDesyncRandom  = true,
    VelDesyncBurst   = false,

    -- Riot
    RiotEnabled      = false,
    RiotDelay        = 0.06,
    RiotBurst        = 6,
    RiotRadial       = true,

    -- SlingBypass
    SlingEnabled     = false,
    SlingMode        = "Follow",
    SlingSpeed       = 45,
    SlingOrbitR      = 5,

    -- AntiAim
    AntiAimEnabled   = false,
    AntiAimMode      = "Spin",
    AntiAimSpeed     = 12,
    AntiAimJitter    = 35,
    AntiAimCustom    = 0,
    AntiAimFlip      = false,
    AntiAimFakeUp    = false,

    -- Resolver
    ResolverEnabled  = false,
    ResolverMode     = "Mirror",

    -- Orbit
    OrbitEnabled     = false,
    OrbitMode        = "Circle",
    OrbitRadius      = 6,
    OrbitSpeed       = 2.5,
    OrbitHeight      = 0,
    OrbitEllipseX    = 8,
    OrbitEllipseZ    = 4,

    -- Movement
    InfiniteJump     = false,
    Noclip           = false,
    BunnyHop         = false,
    SpeedMult        = 1.0,
    WalkspeedVal     = 16,
    AutoRespawn      = false,
    Fly              = false,
    FlySpeed         = 60,

    -- ESP
    EspEnabled       = true,
    EspBoxes         = true,
    EspNames         = true,
    EspHealth        = true,
    EspDist          = true,
    EspSkeleton      = false,
    EspHeadDot       = false,
    EspTracers       = false,
    EspTeamCheck     = false,
    EspMaxDist       = 1000,
    EspBoxColor      = Color3.fromRGB(0, 100, 255),

    -- Staff Detector
    StaffDetectEnabled = true,

    -- Remote Spy
    RemoteSpyEnabled  = false,
    RemoteSpyModify   = false,

    -- AC Silencer
    ACSilencerEnabled = true,
    ACSilencerKeywords = {"anticheat","anticheats","ac_","detect","report","ban","kick","teleport","tp_check","sanity"},

    -- Upvalue Miner
    UpvalueMinerEnabled = false,

    -- Meta Hook
    MetaHookEnabled    = true,

    -- Cache Spoofer
    CacheSpooferEnabled = true,

    -- Hook all __namecall remotes
    NamecallHookEnabled = true,
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    target        = nil,
    orbitAngle    = 0,
    fpVirtualCF   = nil,
    aaAngle       = 0,
    staffList     = {},
    remoteLog     = {},
    acDisabledConns = {},
    minedUpvalues = {},
    espDrawings   = {},
    hookedFuncs   = {},
    flyBG         = nil,
    flyConn       = nil,
    origFireServer = nil,
    origInvoke    = nil,
    origNamecall  = nil,
}

-- ============================================================
-- HOOK INFRASTRUCTURE (KiciaHook / UE APIs)
-- ============================================================

-- Wrap function as newcclosure if available
local function MakeCClosure(fn)
    if HAS_NEWCC then
        local ok, r = pcall(newcclosure, fn)
        if ok then return r end
    end
    return fn
end

-- Clone a function safely
local function SafeClone(fn)
    if HAS_CLONEFUNC then
        local ok, r = pcall(clonefunction, fn)
        if ok and r then return r end
    end
    return fn
end

-- hookfunction wrapper: returns original (cloned), unhook function
local function Hook(original, replacement)
    if not HAS_HOOKFUNC then return original, function() end end
    local wrapped = MakeCClosure(replacement)
    local ok, orig = pcall(hookfunction, original, wrapped)
    if ok then
        local cloned = SafeClone(orig)
        State.hookedFuncs[tostring(original)] = {orig = cloned, wrapped = wrapped}
        return cloned, function() pcall(hookfunction, original, cloned) end
    end
    return original, function() end
end

-- hookmetamethod wrapper
local function HookMeta(obj, mm, replacement)
    if not HAS_HOOKMETA then return function() end end
    local wrapped = MakeCClosure(replacement)
    local ok = pcall(hookmetamethod, obj, mm, wrapped)
    if ok then
        return function() end -- restore not straightforward; log only
    end
    return function() end
end

-- Get raw metamethod from object
local function GetMM(obj, mm)
    if not HAS_RAWMT then return nil end
    local mt = getrawmetatable(obj)
    if mt then return rawget(mt, mm) end
    return nil
end

-- Set bypassing __metatable lock
local function RawSet(obj, key, value)
    -- Try metamethod bypass first
    local ni = GetMM(obj, "__newindex")
    if ni then
        local ok = pcall(ni, obj, key, value)
        if ok then return true end
    end
    -- Try sethiddenproperty
    if HAS_SETHIDDEN then
        local ok = pcall(sethiddenproperty, obj, key, value)
        if ok then return true end
    end
    -- Direct set
    local ok = pcall(function() obj[key] = value end)
    return ok
end

-- debug.getupvalue / debug.setupvalue wrappers
local function GetUpvalue(fn, idx)
    if not HAS_DEBUG_UPV then return nil end
    local ok, name, val = pcall(debug.getupvalue, fn, idx)
    if ok then return name, val end
    return nil, nil
end

local function SetUpvalue(fn, idx, val)
    if not HAS_DEBUG_UPS then return false end
    local ok = pcall(debug.setupvalue, fn, idx, val)
    return ok
end

local function GetConstants(fn)
    if not HAS_DEBUG_CON then return {} end
    local ok, consts = pcall(debug.getconstants, fn)
    if ok and consts then return consts end
    return {}
end

-- ============================================================
-- REMOTE SPY (hookfunction on FireServer / InvokeServer)
-- ============================================================
local function SetupRemoteSpy()
    if not HAS_HOOKFUNC then return end
    -- Hook via __namecall on game (catches all remote calls)
    local origNC = GetMM(game, "__namecall")
    if origNC then
        local cloned = SafeClone(origNC)
        State.origNamecall = cloned
        HookMeta(game, "__namecall", function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if Cfg.RemoteSpyEnabled and (method == "FireServer" or method == "InvokeServer" or method == "FireAllClients") then
                local entry = {
                    remote = self.Name,
                    method = method,
                    args   = {...},
                    tick   = tick(),
                }
                table.insert(State.remoteLog, entry)
                if #State.remoteLog > 300 then table.remove(State.remoteLog, 1) end
            end
            return cloned(self, ...)
        end)
    end

    -- Also hook RemoteEvent prototype FireServer directly
    local reProto = getrawmetatable and getrawmetatable(Instance.new("RemoteEvent"))
    if reProto then
        local rawFS = rawget(reProto, "FireServer")
        if rawFS then
            local clonedFS = SafeClone(rawFS)
            State.origFireServer = clonedFS
            pcall(hookfunction, rawFS, MakeCClosure(function(self, ...)
                if Cfg.RemoteSpyEnabled then
                    table.insert(State.remoteLog, {
                        remote = self.Name, method = "FireServer",
                        args = {...}, tick = tick(),
                    })
                    if #State.remoteLog > 300 then table.remove(State.remoteLog, 1) end
                end
                return clonedFS(self, ...)
            end))
        end
        local rawFAC = rawget(reProto, "FireAllClients")
        if rawFAC then
            local cloned = SafeClone(rawFAC)
            pcall(hookfunction, rawFAC, MakeCClosure(function(self, ...)
                if Cfg.RemoteSpyEnabled then
                    table.insert(State.remoteLog, {
                        remote = self.Name, method = "FireAllClients",
                        args = {...}, tick = tick(),
                    })
                end
                return cloned(self, ...)
            end))
        end
    end

    -- Hook RemoteFunction InvokeServer
    local rfProto = getrawmetatable and getrawmetatable(Instance.new("RemoteFunction"))
    if rfProto then
        local rawIS = rawget(rfProto, "InvokeServer")
        if rawIS then
            local cloned = SafeClone(rawIS)
            State.origInvoke = cloned
            pcall(hookfunction, rawIS, MakeCClosure(function(self, ...)
                if Cfg.RemoteSpyEnabled then
                    table.insert(State.remoteLog, {
                        remote = self.Name, method = "InvokeServer",
                        args = {...}, tick = tick(),
                    })
                end
                return cloned(self, ...)
            end))
        end
    end
end

-- ============================================================
-- ANTI-CHEAT CONNECTION SILENCER (getconnections → :Disable())
-- ============================================================
local function IsACName(name)
    local low = string.lower(name)
    for _, kw in ipairs(Cfg.ACSilencerKeywords) do
        if string.find(low, kw, 1, true) then return true end
    end
    return false
end

local function SilenceConnections(signal, tag)
    if not HAS_GETCONNS then return end
    local ok, conns = pcall(getconnections, signal)
    if not ok or not conns then return end
    for _, c in ipairs(conns) do
        local disabled = pcall(function() c:Disable() end)
        if disabled then
            table.insert(State.acDisabledConns, {conn=c, tag=tag})
        end
    end
end

local function ScanAndSilenceAC()
    -- Scan running scripts
    if HAS_SCRIPTS then
        for _, scr in ipairs(getscripts()) do
            if IsACName(scr.Name) then
                pcall(SilenceConnections, scr.AncestryChanged, "script:"..scr.Name)
                -- Also disable the script itself if possible
                pcall(function()
                    if scr:IsA("LocalScript") then
                        scr.Disabled = true
                    end
                end)
            end
        end
    end
    -- Scan RemoteEvents in game hierarchy
    local function scanDescendants(root)
        if not root then return end
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("RemoteEvent") and IsACName(v.Name) then
                SilenceConnections(v.OnClientEvent, "remote:"..v.Name)
            end
            if v:IsA("BindableEvent") and IsACName(v.Name) then
                SilenceConnections(v.Event, "bindable:"..v.Name)
            end
        end
    end
    pcall(scanDescendants, ReplicatedStorage)
    pcall(scanDescendants, Workspace)
    -- Player-specific
    SilenceConnections(Players.PlayerAdded, "Players:PlayerAdded")
    SilenceConnections(Players.LocalPlayer.Chatted, "LocalPlayer:Chatted")
end

-- ============================================================
-- MODULE UPVALUE MINER (debug.getupvalue on loaded modules)
-- ============================================================
local MinedMap = {}

local function MineFunction(fn, tag)
    if type(fn) ~= "function" then return end
    if not HAS_DEBUG_UPV then return end
    -- Mine upvalues
    local i = 1
    while true do
        local name, val = GetUpvalue(fn, i)
        if not name then break end
        if type(val) == "table" or type(val) == "function" then
            local key = tag .. "." .. (name or tostring(i))
            MinedMap[key] = val
            table.insert(State.minedUpvalues, {key=key, type=type(val), val=val})
        end
        i = i + 1
        if i > 64 then break end
    end
    -- Mine constants
    local consts = GetConstants(fn)
    for ci, cv in pairs(consts) do
        if type(cv) == "string" and #cv > 3 then
            -- Strings in constants may reveal internal keys
            MinedMap[tag..".const."..tostring(ci)] = cv
        end
    end
end

local function MineAllModules()
    if not HAS_MODULES then return end
    for _, mod in ipairs(getloadedmodules()) do
        local info = debug and debug.getinfo and debug.getinfo(mod, "f")
        if info and type(info) == "function" then
            MineFunction(info, mod.Name)
        end
    end
    -- Also try to mine from running scripts
    if HAS_SCRIPTS then
        for _, scr in ipairs(getscripts()) do
            local info = debug and debug.getinfo and debug.getinfo(scr, "f")
            if info and type(info) == "function" then
                MineFunction(info, scr.Name)
            end
        end
    end
end

-- ============================================================
-- METAMETHOD HOOK SYSTEM
-- ============================================================
local function SetupMetaHooks()
    if not HAS_HOOKMETA then return end
    -- Hook __namecall on game to monitor all method calls
    -- (RemoteSpy reuses this; here we add anti-AC hooking)
    local workspaceMT = HAS_RAWMT and getrawmetatable(Workspace)
    if workspaceMT then
        local origWI = rawget(workspaceMT, "__index")
        if origWI and type(origWI) == "function" then
            local cl = SafeClone(origWI)
            pcall(hookmetamethod, Workspace, "__index", MakeCClosure(function(self, key)
                return cl(self, key)
            end))
        end
    end
end

-- ============================================================
-- INSTANCE CACHE SPOOFER
-- ============================================================
local function CacheReplace(orig, fake)
    if not HAS_CACHE then return end
    pcall(function() cache.replace(orig, fake) end)
end

local function CacheInvalidate(inst)
    if not HAS_CACHE then return end
    pcall(function() cache.invalidate(inst) end)
end

local function IsCached(inst)
    if not HAS_CACHE then return false end
    local ok, r = pcall(function() return cache.iscached(inst) end)
    return ok and r
end

-- ============================================================
-- ENVIRONMENT INJECTOR
-- ============================================================
local function InjectGenv(key, val)
    pcall(function() genv[key] = val end)
end

InjectGenv("UNCODEv6", true)
InjectGenv("UNCODETarget", function() return State.target end)
InjectGenv("UNCODECfg", Cfg)
InjectGenv("UNCODERemoteLog", State.remoteLog)
InjectGenv("UNCODEMined", MinedMap)

-- ============================================================
-- UTILITY
-- ============================================================
local function GetChar(p)  return p and p.Character end
local function GetRoot(c)  return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(c)   return c and c:FindFirstChildOfClass("Humanoid") end
local function GetBone(c,b) return c and (c:FindFirstChild(b) or c:FindFirstChild("HumanoidRootPart")) end

local function IsAlive(p)
    local c = GetChar(p); local h = GetHum(c)
    return h and h.Health > 0
end

local function W2S(pos)
    local sp, inB = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), inB, sp.Z
end

local function Dist(a, b) return (a - b).Magnitude end

local function GetEnemies()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            if not Cfg.AimbotTeamCheck or p.Team ~= LocalPlayer.Team then
                table.insert(out, p)
            end
        end
    end
    return out
end

local function Raycast(from, to)
    local dir = to - from
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character or Instance.new("Part")}
    local r = Workspace:Raycast(from, dir, params)
    if not r then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and r.Instance and r.Instance:IsDescendantOf(p.Character or Instance.new("Part")) then
            return true
        end
    end
    return false
end

-- ============================================================
-- USEITEM REMOTE
-- ============================================================
local UseItemRemote

local function FindUseItemRemote()
    local ok, r = pcall(function()
        return ReplicatedStorage.Remotes.Replication.Fighter.UseItem
    end)
    if ok and r then UseItemRemote = r; return r end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "UseItem" then
            UseItemRemote = v; return v
        end
    end
end

local function FireUseItem(payload)
    local rem = UseItemRemote or FindUseItemRemote()
    if not rem then return end
    -- Use cloned FireServer if available (bypasses spy loop)
    if State.origFireServer then
        pcall(State.origFireServer, rem, payload)
    else
        pcall(function() rem:FireServer(payload) end)
    end
end

-- ============================================================
-- AIMBOT
-- ============================================================
local function GetBestTarget()
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return nil end
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bd = nil, math.huge
    for _, p in ipairs(GetEnemies()) do
        local c = GetChar(p); local bone = GetBone(c, Cfg.AimbotBone)
        if bone then
            if Cfg.AimbotVisCheck and not Raycast(lr.Position, bone.Position) then continue end
            local sp, inB = W2S(bone.Position)
            if inB then
                local d = (sp - center).Magnitude
                if d < Cfg.AimbotFOV and d < bd then bd=d; best=p end
            end
        end
    end
    return best
end

local function Predict(c, bone, mult)
    local r = GetRoot(c)
    if not r then return bone.Position end
    local vel = r.AssemblyLinearVelocity
    local d = Dist(Camera.CFrame.Position, bone.Position)
    return bone.Position + vel * (d/1000*mult)
end

local function AimbotStep()
    if not Cfg.AimbotEnabled then return end
    local holding = UserInputService:IsMouseButtonDown(Enum.UserInputType.MouseButton2)
        or UserInputService:IsKeyDown(Enum.KeyCode.Q)
    if not holding and not Cfg.AimbotSilent then return end

    local t = GetBestTarget()
    State.target = t
    if not t then return end
    local c = GetChar(t); local bone = GetBone(c, Cfg.AimbotBone)
    if not bone then return end

    local aimPos = Cfg.AimbotPrediction and Predict(c, bone, Cfg.AimbotPredMult) or bone.Position

    if Cfg.AimbotSilent then
        -- Silent aim via rawmetatable CFrame bypass
        local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
        RawSet(Camera, "CFrame", targetCF)
    else
        local cur = Camera.CFrame.LookVector
        local tgt = (aimPos - Camera.CFrame.Position).Unit
        local newLook = cur:Lerp(tgt, Cfg.AimbotSmooth)
        pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook) end)
    end
end

-- ============================================================
-- VOID SPAM
-- ============================================================
local lastVoid = 0

local function VoidSpamStep()
    if not Cfg.VoidSpamEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.E) then return end
    if tick() - lastVoid < Cfg.VoidSpamDelay then return end
    lastVoid = tick()

    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end

    local aimPos = lr.Position + Vector3.new(0,0,-3)
    if Cfg.VoidSpamAutoAim and State.target then
        local tc = GetChar(State.target); local tb = GetRoot(tc)
        if tb then aimPos = tb.Position end
    end

    local dirs = Cfg.VoidSpamMultiDir
        and {Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
        or {(aimPos - lr.Position).Unit}

    for i = 1, Cfg.VoidSpamCount do
        local spreadCF = Cfg.VoidSpamRandAngle
            and CFrame.Angles(
                math.rad(math.random(-Cfg.VoidSpamSpread, Cfg.VoidSpamSpread)),
                math.rad(math.random(-Cfg.VoidSpamSpread, Cfg.VoidSpamSpread)), 0)
            or CFrame.identity

        local baseDir = dirs[((i-1) % #dirs) + 1]
        local rotDir = (spreadCF * baseDir).Unit
        local pos = aimPos + rotDir * 0.1

        local payload = {
            id           = GUID(),
            objectId     = GUID(),
            item         = "primary",
            position     = pos,
            attackNum    = math.random(1, 99),
            animationKeys = {math.random(1,999999), math.random(1,999999)},
            rotation     = CFrame.lookAt(Vector3.zero, rotDir),
            one          = Vector3.new(1,1,1),
            packed       = {"\x00","\x01","\x02","\x03"},
        }
        task.spawn(FireUseItem, payload)
    end
end

-- ============================================================
-- RIOT
-- ============================================================
local lastRiot = 0

local function RiotStep()
    if not Cfg.RiotEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.T) then return end
    if tick() - lastRiot < Cfg.RiotDelay then return end
    lastRiot = tick()
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end

    for i = 1, Cfg.RiotBurst do
        local angle = Cfg.RiotRadial and ((i/Cfg.RiotBurst)*math.pi*2) or math.random()*math.pi*2
        local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local payload = {
            id           = GUID(), objectId = GUID(), item = "primary",
            position     = lr.Position + dir * 2,
            attackNum    = math.random(1,99),
            animationKeys = {math.random(1,999999), math.random(1,999999)},
            rotation     = CFrame.lookAt(Vector3.zero, dir),
            one          = Vector3.new(1,1,1),
            packed       = {"\x00","\x01","\x02","\x03"},
        }
        task.spawn(FireUseItem, payload)
    end
end

-- ============================================================
-- FAKEPOS
-- ============================================================
local function FakePosStep()
    if not Cfg.FakePosEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.F) then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end
    if not State.fpVirtualCF then State.fpVirtualCF = lr.CFrame end
    local d = Cfg.FakePosDepth
    local underPos = State.fpVirtualCF.Position - Vector3.new(0, d, 0)
    RawSet(lr, "CFrame", CFrame.new(underPos))
end

-- ============================================================
-- VEL DESYNC
-- ============================================================
local function VelDesyncStep()
    if not Cfg.VelDesyncEnabled then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end
    local spd = Cfg.VelDesyncSpeed
    local dir = Cfg.VelDesyncRandom
        and Vector3.new(math.random()-0.5, 0, math.random()-0.5).Unit
        or lr.CFrame.LookVector
    local vel = dir * spd
    if Cfg.VelDesyncBurst then vel = vel * (1 + math.sin(tick()*10)*0.5) end
    RawSet(lr, "AssemblyLinearVelocity", vel)
end

-- ============================================================
-- ANTI-AIM
-- ============================================================
local function AntiAimStep(dt)
    if not Cfg.AntiAimEnabled then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end
    State.aaAngle = State.aaAngle + Cfg.AntiAimSpeed * dt
    local t = State.aaAngle
    local yaw = 0
    local mode = Cfg.AntiAimMode
    if mode == "Spin"       then yaw = t * 60
    elseif mode == "Jitter" then yaw = (math.sin(t*10)>0) and Cfg.AntiAimJitter or -Cfg.AntiAimJitter
    elseif mode == "Static" then yaw = 180
    elseif mode == "Up"     then yaw = 0
    elseif mode == "Down"   then yaw = 0
    elseif mode == "Side"   then yaw = 90
    elseif mode == "RandomSpin" then yaw = t * (30 + math.sin(t)*50)
    elseif mode == "Custom" then yaw = Cfg.AntiAimCustom
    elseif mode == "Lurch"  then yaw = math.sin(t*3)*90
    elseif mode == "FakeDown" then yaw = 90 * (math.sin(t*5)>0 and 1 or -1)
    end
    if Cfg.AntiAimFlip and math.sin(tick()) > 0 then yaw = yaw + 180 end

    local newCF = CFrame.new(lr.Position) * CFrame.Angles(
        Cfg.AntiAimFakeUp and math.rad(89) or 0,
        math.rad(yaw), 0
    )
    RawSet(lr, "CFrame", newCF)
end

-- ============================================================
-- RESOLVER
-- ============================================================
local resolverOffsets = {}

local function ResolverStep()
    if not Cfg.ResolverEnabled then return end
    for _, p in ipairs(GetEnemies()) do
        local c = GetChar(p); local lr = GetRoot(c)
        if not lr then continue end
        local uid = p.UserId
        local mode = Cfg.ResolverMode
        if mode == "Mirror" then
            resolverOffsets[uid] = 180
        elseif mode == "Bruteforce" then
            resolverOffsets[uid] = (resolverOffsets[uid] or 0) + 45
            if resolverOffsets[uid] >= 360 then resolverOffsets[uid] = 0 end
        elseif mode == "Jitter" then
            resolverOffsets[uid] = math.random(0, 360)
        end
    end
end

local function GetResolvedPos(player, pos)
    if not Cfg.ResolverEnabled then return pos end
    local off = resolverOffsets[player.UserId] or 0
    local c = GetChar(player); local lr = GetRoot(c)
    if not lr then return pos end
    return lr.CFrame * CFrame.Angles(0, math.rad(off), 0) * CFrame.new(0,0,-1) * Vector3.new(0,0,0)
end

-- ============================================================
-- ORBIT
-- ============================================================
local function OrbitStep(dt)
    if not Cfg.OrbitEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.R) then return end
    local tgt = State.target
    if not tgt then tgt = GetBestTarget() end
    if not tgt then return end
    local tc = GetChar(tgt); local trp = GetRoot(tc)
    if not trp then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end

    State.orbitAngle = State.orbitAngle + Cfg.OrbitSpeed * dt
    local t = State.orbitAngle
    local r = Cfg.OrbitRadius
    local mode = Cfg.OrbitMode
    local offset

    if     mode == "Circle"     then offset = Vector3.new(math.cos(t)*r, Cfg.OrbitHeight, math.sin(t)*r)
    elseif mode == "Figure8"    then
        local s = 1/(1+math.sin(t)^2)
        offset = Vector3.new(r*math.cos(t)*s, Cfg.OrbitHeight, r*math.sin(t)*math.cos(t)*s)
    elseif mode == "Ellipse"    then offset = Vector3.new(math.cos(t)*Cfg.OrbitEllipseX, Cfg.OrbitHeight, math.sin(t)*Cfg.OrbitEllipseZ)
    elseif mode == "SpiralIn"   then
        local sr = math.max(0.5, r - (t%(math.pi*2))*0.3)
        offset = Vector3.new(math.cos(t)*sr, Cfg.OrbitHeight, math.sin(t)*sr)
    elseif mode == "SpiralOut"  then
        local sr = r + (t%(math.pi*2))*0.3
        offset = Vector3.new(math.cos(t)*sr, Cfg.OrbitHeight, math.sin(t)*sr)
    elseif mode == "Bounce"     then offset = Vector3.new(math.cos(t)*r, math.abs(math.sin(t*2))*3+Cfg.OrbitHeight, math.sin(t)*r)
    elseif mode == "Lemniscate" then
        local s = 1/(1+math.sin(t)^2)
        offset = Vector3.new(r*math.cos(t)*s, Cfg.OrbitHeight, r*math.sin(t)*math.cos(t)*s)
    elseif mode == "RandomOrbit" then
        offset = Vector3.new(math.cos(t+math.sin(t*0.7))*r, Cfg.OrbitHeight+math.sin(t*1.3)*1.5, math.sin(t+math.cos(t*0.5))*r)
    else   offset = Vector3.new(math.cos(t)*r, Cfg.OrbitHeight, math.sin(t)*r)
    end

    local newCF = CFrame.new(trp.Position + offset, trp.Position)
    RawSet(lr, "CFrame", newCF)
end

-- ============================================================
-- SLINGBYPASS
-- ============================================================
local function SlingStep()
    if not Cfg.SlingEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.G) then return end
    local tgt = State.target or GetBestTarget()
    if not tgt then return end
    local tc = GetChar(tgt); local trp = GetRoot(tc)
    if not trp then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end

    local mode = Cfg.SlingMode
    local spd  = Cfg.SlingSpeed

    if mode == "Follow" then
        local d = (trp.Position - lr.Position)
        if d.Magnitude > 1 then RawSet(lr, "AssemblyLinearVelocity", d.Unit*spd) end
    elseif mode == "Stalk" then
        local sp = trp.Position + trp.CFrame.LookVector * -4
        local d = (sp - lr.Position)
        if d.Magnitude > 0.5 then RawSet(lr, "AssemblyLinearVelocity", d.Unit*spd) end
    elseif mode == "Hover" then
        local hp = trp.Position + Vector3.new(0,6,0)
        RawSet(lr, "CFrame", CFrame.new(lr.Position:Lerp(hp, 0.25)))
    elseif mode == "FastTp" then
        RawSet(lr, "CFrame", trp.CFrame * CFrame.new(3,0,3))
    elseif mode == "TargetStick" then
        RawSet(lr, "CFrame", trp.CFrame * CFrame.new(0,0,2))
    elseif mode == "OrbitTarget" then
        local t2 = tick()*2
        local ro = Vector3.new(math.cos(t2)*Cfg.SlingOrbitR, 0, math.sin(t2)*Cfg.SlingOrbitR)
        RawSet(lr, "CFrame", CFrame.new(trp.Position+ro, trp.Position))
    elseif mode == "RandomAroundTarget" then
        local rp = trp.Position + Vector3.new(
            (math.random()-0.5)*Cfg.SlingOrbitR*2,
            (math.random()-0.5)*2,
            (math.random()-0.5)*Cfg.SlingOrbitR*2
        )
        RawSet(lr, "CFrame", CFrame.new(rp))
    end
end

-- ============================================================
-- FLY
-- ============================================================
local function StartFly()
    if State.flyBG then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)
    if not lr then return end

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
    bg.D = 100
    bg.P = 10000
    bg.CFrame = Camera.CFrame
    bg.Parent = lr

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = lr

    State.flyBG = bg
    State.flyBV = bv

    State.flyConn = RunService.RenderStepped:Connect(function()
        if not Cfg.Fly then
            if State.flyBG then State.flyBG:Destroy(); State.flyBG = nil end
            if State.flyBV then State.flyBV:Destroy(); State.flyBV = nil end
            if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
            return
        end
        local cf = Camera.CFrame
        bg.CFrame = cf
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
        bv.Velocity = vel * Cfg.FlySpeed
    end)
end

local function StopFly()
    if State.flyBG then State.flyBG:Destroy(); State.flyBG = nil end
    if State.flyBV then State.flyBV:Destroy(); State.flyBV = nil end
    if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
end

-- ============================================================
-- MOVEMENT MISC
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if not Cfg.InfiniteJump then return end
    local lc = GetChar(LocalPlayer); local h = GetHum(lc)
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local function NoclipStep()
    if not Cfg.Noclip then return end
    local lc = GetChar(LocalPlayer)
    if not lc then return end
    for _, p in ipairs(lc:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

local function BhopStep()
    if not Cfg.BunnyHop then return end
    local lc = GetChar(LocalPlayer); local h = GetHum(lc)
    if h and h:GetState() == Enum.HumanoidStateType.Landed then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function SpeedStep()
    if Cfg.SpeedMult <= 1.0 then return end
    local lc = GetChar(LocalPlayer); local h = GetHum(lc)
    if h then h.WalkSpeed = Cfg.WalkspeedVal * Cfg.SpeedMult end
end

-- ============================================================
-- ESP
-- ============================================================
local ESPCache = {}

local function EnsureESP(p)
    if ESPCache[p.UserId] then return ESPCache[p.UserId] end
    if not Drawing then return nil end
    local d = {}
    d.box   = Drawing.new("Square")
    d.box.Visible = false; d.box.Filled = false; d.box.Thickness = 1.5
    d.box.Color = Cfg.EspBoxColor

    d.name  = Drawing.new("Text")
    d.name.Visible = false; d.name.Size = 13
    d.name.Color = Color3.fromRGB(255,255,255)
    d.name.Center = true
    d.name.Font = Drawing.Fonts and Drawing.Fonts.Code or 3

    d.health = Drawing.new("Text")
    d.health.Visible = false; d.health.Size = 12; d.health.Center = true
    d.health.Font = Drawing.Fonts and Drawing.Fonts.Code or 3

    d.dist  = Drawing.new("Text")
    d.dist.Visible = false; d.dist.Size = 12; d.dist.Center = true
    d.dist.Color = Color3.fromRGB(200,200,200)
    d.dist.Font = Drawing.Fonts and Drawing.Fonts.Code or 3

    d.tracer = Drawing.new("Line")
    d.tracer.Visible = false; d.tracer.Thickness = 1
    d.tracer.Color = Color3.fromRGB(0,200,255)

    d.hdot  = Drawing.new("Circle")
    d.hdot.Visible = false; d.hdot.Radius = 4; d.hdot.Filled = true
    d.hdot.Color = Color3.fromRGB(255,80,80)

    ESPCache[p.UserId] = d
    return d
end

local function CleanESP(p)
    local d = ESPCache[p.UserId]
    if not d then return end
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
    ESPCache[p.UserId] = nil
end

local function EspStep()
    if not (Cfg.EspEnabled and Drawing) then return end
    local lc = GetChar(LocalPlayer); local lr = GetRoot(lc)

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local d = EnsureESP(p)
        if not d then continue end

        local char = GetChar(p); local root = GetRoot(char); local hum = GetHum(char)
        local visible = Cfg.EspEnabled and char and root and hum and hum.Health > 0

        if not visible then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end

        local headPos = (char:FindFirstChild("Head") and char.Head.Position) or root.Position + Vector3.new(0,1.5,0)
        local feetPos = root.Position - Vector3.new(0,2.8,0)
        local topSP, topVis, topZ = W2S(headPos)
        local botSP = W2S(feetPos)
        local dist = lr and Dist(lr.Position, root.Position) or 999

        if not topVis or topZ < 0 or dist > Cfg.EspMaxDist then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end

        local h = math.abs(topSP.Y - botSP.Y)
        local w = h * 0.5
        local x = topSP.X - w/2
        local y = topSP.Y

        if Cfg.EspBoxes then
            d.box.Position = Vector2.new(x, y); d.box.Size = Vector2.new(w, h); d.box.Visible = true
        else d.box.Visible = false end

        if Cfg.EspNames then
            d.name.Text = p.DisplayName or p.Name
            d.name.Position = Vector2.new(topSP.X, y-16); d.name.Visible = true
        else d.name.Visible = false end

        if Cfg.EspHealth then
            local hp = math.floor(hum.Health); local mx = math.floor(hum.MaxHealth)
            d.health.Text = hp.."/"..mx
            d.health.Position = Vector2.new(topSP.X, y+h+2)
            d.health.Color = Color3.fromRGB(math.floor((1-hp/mx)*255), math.floor((hp/mx)*255), 0)
            d.health.Visible = true
        else d.health.Visible = false end

        if Cfg.EspDist then
            d.dist.Text = math.floor(dist).."m"
            d.dist.Position = Vector2.new(topSP.X, y+h+(Cfg.EspHealth and 16 or 2))
            d.dist.Visible = true
        else d.dist.Visible = false end

        if Cfg.EspTracers then
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            d.tracer.From = center; d.tracer.To = botSP; d.tracer.Visible = true
        else d.tracer.Visible = false end

        if Cfg.EspHeadDot then
            d.hdot.Position = topSP; d.hdot.Visible = true
        else d.hdot.Visible = false end
    end
end

-- ============================================================
-- STAFF DETECTOR
-- ============================================================
local STAFF_KW = {"mod","admin","staff","owner","developer","tester","creator","contributor","qa","support"}

local function IsStaff(p)
    local n = string.lower(p.Name)
    local d = string.lower(p.DisplayName or "")
    for _, kw in ipairs(STAFF_KW) do
        if string.find(n,kw,1,true) or string.find(d,kw,1,true) then return true end
    end
    local ok, rank = pcall(function() return p:GetRankInGroup(game.CreatorId) end)
    if ok and rank and rank >= 200 then return true end
    return false
end

local function UpdateStaffList()
    State.staffList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if IsStaff(p) then table.insert(State.staffList, p.Name) end
    end
end

-- ============================================================
-- UI PANELS
-- ============================================================

-- TAB: Combat
pcall(function()
    local CL = Tabs.Combat:AddLeftGroupbox("Aimbot")
    BT(CL, "AB_On", "Aimbot Enabled", false, function(v) Cfg.AimbotEnabled=v end)
    CL:AddSlider("AB_FOV",   {Text="FOV",       Min=50, Max=600, Default=200, Callback=function(v) Cfg.AimbotFOV=v end})
    CL:AddSlider("AB_Smooth",{Text="Smooth",    Min=0,  Max=100, Default=18,  Callback=function(v) Cfg.AimbotSmooth=v/100 end})
    CL:AddDropdown("AB_Bone",{Text="Bone",Values={"Head","HumanoidRootPart","UpperTorso","RightUpperArm","LeftUpperArm"},Default="Head",Callback=function(v) Cfg.AimbotBone=v end})
    BT(CL, "AB_Pred",  "Prediction",  true,  function(v) Cfg.AimbotPrediction=v end)
    CL:AddSlider("AB_PredM",{Text="Pred Mult", Min=1, Max=500, Default=120, Callback=function(v) Cfg.AimbotPredMult=v/100 end})
    BT(CL, "AB_Silent","Silent Aim",  false, function(v) Cfg.AimbotSilent=v end)
    BT(CL, "AB_Vis",   "Vis Check",   true,  function(v) Cfg.AimbotVisCheck=v end)
    BT(CL, "AB_Team",  "Team Check",  false, function(v) Cfg.AimbotTeamCheck=v end)

    local CR = Tabs.Combat:AddRightGroupbox("Resolver")
    BT(CR, "RES_On", "Resolver Enabled", false, function(v) Cfg.ResolverEnabled=v end)
    CR:AddDropdown("RES_Mode",{Text="Mode",Values={"Mirror","Bruteforce","Jitter"},Default="Mirror",Callback=function(v) Cfg.ResolverMode=v end})
end)

-- TAB: Void
pcall(function()
    local VL = Tabs.Void:AddLeftGroupbox("VoidSpam")
    BT(VL, "VS_On",   "VoidSpam",       false, function(v) Cfg.VoidSpamEnabled=v end)
    VL:AddSlider("VS_Delay", {Text="Delay (ms)", Min=1,  Max=500,  Default=50,  Callback=function(v) Cfg.VoidSpamDelay=v/1000 end})
    VL:AddSlider("VS_Count", {Text="Count",      Min=1,  Max=30,   Default=8,   Callback=function(v) Cfg.VoidSpamCount=v end})
    VL:AddSlider("VS_Spread",{Text="Spread",     Min=0,  Max=90,   Default=15,  Callback=function(v) Cfg.VoidSpamSpread=v end})
    BT(VL, "VS_AutoAim","Auto Aim",    true,  function(v) Cfg.VoidSpamAutoAim=v end)
    BT(VL, "VS_Rand",   "Random Angle",true,  function(v) Cfg.VoidSpamRandAngle=v end)
    BT(VL, "VS_Multi",  "Multi-Dir",   false, function(v) Cfg.VoidSpamMultiDir=v end)

    local VR = Tabs.Void:AddRightGroupbox("FakePos / VelDesync")
    BT(VR, "FP_On",  "FakePos",       false, function(v) Cfg.FakePosEnabled=v end)
    VR:AddSlider("FP_Depth",{Text="Depth",Min=1,Max=30,Default=6,Callback=function(v) Cfg.FakePosDepth=v end})
    VL:AddLabel("Key: F")

    BT(VR, "VD_On",  "VelDesync",     false, function(v) Cfg.VelDesyncEnabled=v end)
    VR:AddSlider("VD_Spd",{Text="Speed",Min=10,Max=500,Default=80,Callback=function(v) Cfg.VelDesyncSpeed=v end})
    BT(VR, "VD_Rand","Random Dir",    true,  function(v) Cfg.VelDesyncRandom=v end)
    BT(VR, "VD_Burst","Burst Sine",   false, function(v) Cfg.VelDesyncBurst=v end)

    local RL = Tabs.Void:AddLeftGroupbox("Riot / Sling")
    BT(RL, "RI_On",  "Riot",          false, function(v) Cfg.RiotEnabled=v end)
    RL:AddSlider("RI_Burst",{Text="Burst",Min=1,Max=30,Default=6,Callback=function(v) Cfg.RiotBurst=v end})
    RL:AddSlider("RI_Delay",{Text="Delay(ms)",Min=1,Max=500,Default=60,Callback=function(v) Cfg.RiotDelay=v/1000 end})
    BT(RL, "RI_Rad","Radial Spread", true, function(v) Cfg.RiotRadial=v end)
    RL:AddLabel("Key: T")

    BT(RL, "SL_On",  "SlingBypass",   false, function(v) Cfg.SlingEnabled=v end)
    RL:AddDropdown("SL_Mode",{Text="Sling Mode",Values={"Follow","Stalk","Hover","FastTp","TargetStick","OrbitTarget","RandomAroundTarget"},Default="Follow",Callback=function(v) Cfg.SlingMode=v end})
    RL:AddSlider("SL_Spd",{Text="Speed",Min=5,Max=300,Default=45,Callback=function(v) Cfg.SlingSpeed=v end})
    RL:AddSlider("SL_OrbitR",{Text="Orbit R",Min=1,Max=30,Default=5,Callback=function(v) Cfg.SlingOrbitR=v end})
    RL:AddLabel("Key: G")
end)

-- TAB: Movement
pcall(function()
    local ML = Tabs.Movement:AddLeftGroupbox("Movement")
    BT(ML, "IJ_On",  "Infinite Jump",  false, function(v) Cfg.InfiniteJump=v end)
    BT(ML, "NC_On",  "Noclip",         false, function(v) Cfg.Noclip=v end)
    BT(ML, "BH_On",  "Bunny Hop",      false, function(v) Cfg.BunnyHop=v end)
    ML:AddSlider("SP_Mult",{Text="Speed Mult",Min=100,Max=800,Default=100,Callback=function(v) Cfg.SpeedMult=v/100 end})
    ML:AddSlider("SP_WS",  {Text="Walkspeed", Min=16, Max=300,Default=16, Callback=function(v) Cfg.WalkspeedVal=v end})
    BT(ML, "FLY_On", "Fly",            false, function(v)
        Cfg.Fly=v
        if v then StartFly() else StopFly() end
    end)
    ML:AddSlider("FLY_Spd",{Text="Fly Speed",Min=10,Max=500,Default=60,Callback=function(v) Cfg.FlySpeed=v end})
    BT(ML, "AR_On",  "Auto Respawn",   false, function(v) Cfg.AutoRespawn=v end)

    local MR = Tabs.Movement:AddRightGroupbox("Orbit")
    BT(MR, "OR_On",  "Orbit",          false, function(v) Cfg.OrbitEnabled=v end)
    MR:AddDropdown("OR_Mode",{Text="Mode",Values={"Circle","Figure8","Ellipse","SpiralIn","SpiralOut","Bounce","Lemniscate","RandomOrbit"},Default="Circle",Callback=function(v) Cfg.OrbitMode=v end})
    MR:AddSlider("OR_R",  {Text="Radius", Min=1,  Max=50, Default=6,  Callback=function(v) Cfg.OrbitRadius=v end})
    MR:AddSlider("OR_Spd",{Text="Speed",  Min=1,  Max=200,Default=25, Callback=function(v) Cfg.OrbitSpeed=v/10 end})
    MR:AddSlider("OR_H",  {Text="Height", Min=-20,Max=30, Default=0,  Callback=function(v) Cfg.OrbitHeight=v end})
    MR:AddSlider("OR_EX", {Text="Ellipse X",Min=1,Max=40,Default=8,  Callback=function(v) Cfg.OrbitEllipseX=v end})
    MR:AddSlider("OR_EZ", {Text="Ellipse Z",Min=1,Max=40,Default=4,  Callback=function(v) Cfg.OrbitEllipseZ=v end})
    MR:AddLabel("Key: R")
end)

-- TAB: AntiAim
pcall(function()
    local AL = Tabs.AntiAim:AddLeftGroupbox("Anti-Aim")
    BT(AL, "AA_On",   "AntiAim",       false, function(v) Cfg.AntiAimEnabled=v end)
    AL:AddDropdown("AA_Mode",{Text="Mode",Values={"Spin","Jitter","Static","Up","Down","Side","RandomSpin","Custom","Lurch","FakeDown"},Default="Spin",Callback=function(v) Cfg.AntiAimMode=v end})
    AL:AddSlider("AA_Spd", {Text="Speed",    Min=1, Max=120, Default=12,  Callback=function(v) Cfg.AntiAimSpeed=v end})
    AL:AddSlider("AA_Jit", {Text="Jitter°",  Min=1, Max=180, Default=35,  Callback=function(v) Cfg.AntiAimJitter=v end})
    AL:AddSlider("AA_Cust",{Text="Custom Yaw",Min=-180,Max=180,Default=0, Callback=function(v) Cfg.AntiAimCustom=v end})
    BT(AL, "AA_Flip", "Flip",          false, function(v) Cfg.AntiAimFlip=v end)
    BT(AL, "AA_FakeUp","Fake Pitch Up",false, function(v) Cfg.AntiAimFakeUp=v end)
end)

-- TAB: Visuals
pcall(function()
    local EL = Tabs.Visuals:AddLeftGroupbox("ESP")
    BT(EL, "ESP_On",  "ESP Enabled",   true,  function(v) Cfg.EspEnabled=v end)
    BT(EL, "ESP_Box", "Boxes",         true,  function(v) Cfg.EspBoxes=v end)
    BT(EL, "ESP_Name","Names",         true,  function(v) Cfg.EspNames=v end)
    BT(EL, "ESP_HP",  "Health",        true,  function(v) Cfg.EspHealth=v end)
    BT(EL, "ESP_Dist","Distance",      true,  function(v) Cfg.EspDist=v end)
    BT(EL, "ESP_Skel","Skeleton",      false, function(v) Cfg.EspSkeleton=v end)
    BT(EL, "ESP_HDot","Head Dot",      false, function(v) Cfg.EspHeadDot=v end)
    BT(EL, "ESP_Trc", "Tracers",       false, function(v) Cfg.EspTracers=v end)
    BT(EL, "ESP_Team","Team Check",    false, function(v) Cfg.EspTeamCheck=v end)
    EL:AddSlider("ESP_MaxD",{Text="Max Dist",Min=50,Max=2000,Default=1000,Callback=function(v) Cfg.EspMaxDist=v end})

    local ER = Tabs.Visuals:AddRightGroupbox("Staff Detector")
    BT(ER, "SD_On",  "Staff Detect",  true,  function(v) Cfg.StaffDetectEnabled=v end)
    local staffLabel = ER:AddLabel("Scanning...")
    task.spawn(function()
        while task.wait(5) do
            if Cfg.StaffDetectEnabled then
                UpdateStaffList()
                local txt = #State.staffList == 0
                    and "No staff found"
                    or "STAFF: "..table.concat(State.staffList,", ")
                pcall(function() staffLabel:SetText(txt) end)
            end
        end
    end)
end)

-- TAB: Hooks
pcall(function()
    local HL = Tabs.Hooks:AddLeftGroupbox("KiciaHook / UE APIs")

    -- API status display
    local function apiStatus()
        return string.format(
            "hookfunction: %s\nhookmetamethod: %s\nnewcclosure: %s\nclonefunction: %s\ngetconnections: %s\ndebug.getupvalue: %s\ndebug.setupvalue: %s\ndebug.getconstants: %s\nsethiddenproperty: %s\ncache: %s\ngetscripts: %s\ngetloadedmodules: %s\nfiresignal: %s",
            HAS_HOOKFUNC and "YES" or "NO",
            HAS_HOOKMETA and "YES" or "NO",
            HAS_NEWCC and "YES" or "NO",
            HAS_CLONEFUNC and "YES" or "NO",
            HAS_GETCONNS and "YES" or "NO",
            HAS_DEBUG_UPV and "YES" or "NO",
            HAS_DEBUG_UPS and "YES" or "NO",
            HAS_DEBUG_CON and "YES" or "NO",
            HAS_SETHIDDEN and "YES" or "NO",
            HAS_CACHE and "YES" or "NO",
            HAS_SCRIPTS and "YES" or "NO",
            HAS_MODULES and "YES" or "NO",
            HAS_FIRESIG and "YES" or "NO"
        )
    end

    HL:AddLabel(apiStatus())

    BT(HL, "RSP_On", "Remote Spy",    false, function(v)
        Cfg.RemoteSpyEnabled=v
        if v then SetupRemoteSpy(); Notify("Remote Spy ON", 2) end
    end)
    BT(HL, "RSP_Mod","Spy Modify",    false, function(v) Cfg.RemoteSpyModify=v end)

    BT(HL, "ACS_On", "AC Silencer",   true,  function(v)
        Cfg.ACSilencerEnabled=v
        if v then task.spawn(ScanAndSilenceAC); Notify("AC Silencer ON", 2) end
    end)

    BT(HL, "UVM_On", "Upvalue Miner", false, function(v)
        Cfg.UpvalueMinerEnabled=v
        if v then task.spawn(MineAllModules); Notify("Mining upvalues...", 2) end
    end)

    BT(HL, "MH_On",  "Meta Hooks",    true,  function(v)
        Cfg.MetaHookEnabled=v
        if v then SetupMetaHooks() end
    end)

    BT(HL, "CS_On",  "Cache Spoofer", true,  function(v) Cfg.CacheSpooferEnabled=v end)

    local statsLabel = HL:AddLabel("Log: 0 | AC conns: 0 | Mined: 0")
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                statsLabel:SetText(string.format(
                    "Log: %d | AC silenced: %d | Mined: %d",
                    #State.remoteLog,
                    #State.acDisabledConns,
                    #State.minedUpvalues
                ))
            end)
        end
    end)

    local HR = Tabs.Hooks:AddRightGroupbox("Remote Log")
    HL:AddButton("Clear Log", function()
        State.remoteLog = {}
        Notify("Log cleared", 2)
    end)
    HL:AddButton("Re-Scan AC", function()
        task.spawn(ScanAndSilenceAC)
        Notify("AC rescan done", 2)
    end)
    HL:AddButton("Re-Mine Upvalues", function()
        task.spawn(MineAllModules)
        Notify("Upvalue mine done", 2)
    end)
    HL:AddButton("Dump to Output", function()
        for i = math.max(1,#State.remoteLog-9), #State.remoteLog do
            local e = State.remoteLog[i]
            if e then print(string.format("[%.1f] %s::%s args=%d", e.tick%1000, e.remote, e.method, #e.args)) end
        end
        Notify("Dumped last 10 to output", 3)
    end)

    -- Show last 5 log entries
    local logLabels = {}
    for i = 1, 5 do
        local lbl = HR:AddLabel("---")
        logLabels[i] = lbl
    end
    task.spawn(function()
        while task.wait(0.5) do
            if Cfg.RemoteSpyEnabled then
                local start = math.max(1, #State.remoteLog - 4)
                for i = 1, 5 do
                    local entry = State.remoteLog[start + i - 1]
                    pcall(function()
                        logLabels[i]:SetText(entry
                            and string.format("[%.0f] %s", entry.tick%1000, entry.remote)
                            or "---")
                    end)
                end
            end
        end
    end)
end)

-- TAB: Configs
pcall(function()
    if SaveManager then
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("UNCODE_v6")
        SaveManager:BuildConfigSection(Tabs.Configs)
    else
        Tabs.Configs:AddLeftGroupbox("Config"):AddLabel("SaveManager unavailable")
    end
end)

-- TAB: Settings
pcall(function()
    local SL = Tabs.Settings:AddLeftGroupbox("Menu")
    SL:AddLabel("Menu Toggle: RightShift")
    SL:AddButton("Unload Script", function() pcall(function() Library:Unload() end) end)
    SL:AddButton("Reconnect Remote Spy", function()
        task.spawn(SetupRemoteSpy)
        Notify("Remote spy reconnected", 2)
    end)

    if ThemeManager then
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("UNCODE_v6")
        ThemeManager:ApplyToTab(Tabs.Settings)
    end

    local SR = Tabs.Settings:AddRightGroupbox("Info")
    SR:AddLabel("UNCODE v6 -- KiciaHook/UE")
    SR:AddLabel("Loader:")
    SR:AddLabel('loadstring(game:HttpGet("')
    SR:AddLabel('https://raw.githubusercontent.com/')
    SR:AddLabel('57040suda-haruki-cloud/p1/main/script.lua"))()')
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================
task.spawn(function()
    FindUseItemRemote()

    -- Remote spy
    if Cfg.RemoteSpyEnabled then SetupRemoteSpy() end

    -- Meta hooks
    if Cfg.MetaHookEnabled then SetupMetaHooks() end

    -- AC silencer
    if Cfg.ACSilencerEnabled then ScanAndSilenceAC() end

    -- Mine upvalues
    if Cfg.UpvalueMinerEnabled then MineAllModules() end

    -- Init ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then EnsureESP(p) end
    end

    -- Staff scan
    UpdateStaffList()

    print("[UNCODE v6] Loaded")
    print(string.format(
        "[UNCODE v6] hookfunction=%s hookmetamethod=%s getconnections=%s newcclosure=%s",
        tostring(HAS_HOOKFUNC), tostring(HAS_HOOKMETA),
        tostring(HAS_GETCONNS), tostring(HAS_NEWCC)
    ))
    Notify("UNCODE v6 loaded!", 4)
end)

-- ============================================================
-- CHARACTER EVENTS
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            if Cfg.AutoRespawn then
                task.wait(1.5)
                LocalPlayer:LoadCharacter()
            end
        end)
    end
    State.fpVirtualCF = nil
    State.orbitAngle  = 0
    State.aaAngle     = 0
    if Cfg.ACSilencerEnabled then task.delay(2, ScanAndSilenceAC) end
    if Cfg.Fly then task.delay(0.5, StartFly) end
end)

Players.PlayerRemoving:Connect(function(p) CleanESP(p) end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    AimbotStep()
    EspStep()
    NoclipStep()
    BhopStep()
    SpeedStep()
    AntiAimStep(dt)
    OrbitStep(dt)
    ResolverStep()
end)

RunService.Heartbeat:Connect(function()
    VoidSpamStep()
    FakePosStep()
    VelDesyncStep()
    SlingStep()
    RiotStep()
end)
