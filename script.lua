-- UNCODE Rivals HvH Script v5
-- KiciaHook/UE Executor API Full Integration
-- DO NOT USE JAPANESE IN CODE OR COMMENTS

-- ============================================================
-- THREAD IDENTITY ELEVATION
-- ============================================================
pcall(setthreadidentity, 8)
pcall(setthreadidentity, 7)
pcall(setthreadidentity, 6)
pcall(setthreadidentity, 3)

-- ============================================================
-- EXECUTOR ENVIRONMENT SETUP
-- ============================================================
local genv = (getgenv and getgenv()) or _G
local renv = (getrenv and getrenv()) or _G

-- Inject global flags into executor environment
genv.__UNCODE_LOADED = true
genv.__UNCODE_VERSION = "5.0"

-- ============================================================
-- SERVICES
-- ============================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace     = game:GetService("Workspace")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local Camera        = Workspace.CurrentCamera

local LocalPlayer   = Players.LocalPlayer

-- ============================================================
-- GUID UTILITY
-- ============================================================
local function GUID()
    return HttpService:GenerateGUID(false)
end

-- ============================================================
-- CONFIG
-- ============================================================
local Cfg = {
    -- Aimbot
    AimbotEnabled    = false,
    AimbotKey        = Enum.KeyCode.Q,
    AimbotFOV        = 200,
    AimbotSmooth     = 0.18,
    AimbotBone       = "Head",
    AimbotPrediction = true,
    AimbotPredMult   = 1.2,
    AimbotSilent     = false,
    AimbotSilentFOV  = 300,
    AimbotVisCheck   = true,

    -- VoidSpam
    VoidSpamEnabled  = false,
    VoidSpamKey      = Enum.KeyCode.E,
    VoidSpamDelay    = 0.05,
    VoidSpamCount    = 8,
    VoidSpamRandAngle= true,
    VoidSpamSpread   = 15,
    VoidSpamAutoAim  = true,

    -- FakePos
    FakePosEnabled   = false,
    FakePosKey       = Enum.KeyCode.F,
    FakePosDepth     = 5.8,
    FakePosDelay     = 0.1,
    FakePosType      = "Ground",

    -- VelDesync
    VelDesyncEnabled = false,
    VelDesyncSpeed   = 80,
    VelDesyncRandom  = true,
    VelDesyncMode    = "Random",

    -- AntiAim
    AntiAimEnabled   = false,
    AntiAimMode      = "Spin",
    AntiAimSpeed     = 12,
    AntiAimJitter    = 35,
    AntiAimCustom    = 0,
    AntiAimFlip      = false,

    -- Orbit
    OrbitEnabled     = false,
    OrbitKey         = Enum.KeyCode.R,
    OrbitMode        = "Circle",
    OrbitRadius      = 6,
    OrbitSpeed       = 2.5,
    OrbitHeight      = 0,
    OrbitEllipseX    = 8,
    OrbitEllipseZ    = 4,

    -- ESP
    EspEnabled       = true,
    EspBoxes         = true,
    EspNames         = true,
    EspHealth        = true,
    EspDist          = true,
    EspSkeleton      = false,
    EspTeamCheck     = false,
    EspMaxDist       = 1000,
    EspBoxColor      = Color3.fromRGB(0, 100, 255),
    EspNameColor     = Color3.fromRGB(255,255,255),
    EspHealthColor   = Color3.fromRGB(0,255,0),

    -- SlingBypass
    SlingEnabled     = false,
    SlingKey         = Enum.KeyCode.G,
    SlingMode        = "Follow",
    SlingSpeed       = 45,
    SlingOrbitR      = 5,

    -- Riot
    RiotEnabled      = false,
    RiotKey          = Enum.KeyCode.T,
    RiotDelay        = 0.06,
    RiotBurst        = 6,

    -- Staff Detector
    StaffDetectEnabled = true,

    -- Remote Spy
    RemoteSpyEnabled  = false,
    RemoteSpyLog      = true,
    RemoteSpyModify   = false,

    -- Anti-Cheat Silencer
    ACSilencerEnabled = true,
    ACSilencerKeywords = {"anticheat","anticheats","ac_","detect","report","ban","kick","teleport","tp_check"},

    -- Module Upvalue Miner
    UpvalueMinerEnabled = false,
    UpvalueMinerAuto    = true,

    -- Hook System
    HookSystemEnabled   = true,
    MetaHookEnabled     = true,
    CacheSpooferEnabled = true,

    -- Misc
    InfiniteJump     = false,
    Noclip           = false,
    AutoRespawn      = false,
    BunnyHop         = false,
    SpeedMultiplier  = 1.0,
    WalkspeedVal     = 16,
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    target           = nil,
    orbitAngle       = 0,
    fpVirtualCF      = nil,
    fpActive         = false,
    voidSpamActive   = false,
    riotActive       = false,
    slingActive      = false,
    aaAngle          = 0,
    staffList        = {},
    remoteLog        = {},
    hookedSignals    = {},
    minedUpvalues    = {},
    hookedFunctions  = {},
    originalFuncs    = {},
    acDisabledConns  = {},
    espDrawings      = {},
    metaHooks        = {},
}

-- ============================================================
-- HOOK INFRASTRUCTURE
-- ============================================================

-- Safe hookfunction wrapper
local function SafeHook(original, hookFn)
    if not hookfunction then return original, function() end end
    local ok, orig = pcall(hookfunction, original, newcclosure and newcclosure(hookFn) or hookFn)
    if ok then
        State.hookedFunctions[tostring(original)] = { orig = orig, hook = hookFn }
        return orig, function()
            pcall(hookfunction, original, orig)
        end
    end
    return original, function() end
end

-- Safe hookmetamethod wrapper
local function SafeHookMeta(obj, mm, hookFn)
    if not hookmetamethod then return function() end end
    local ok = pcall(hookmetamethod, obj, mm, newcclosure and newcclosure(hookFn) or hookFn)
    if ok then
        State.metaHooks[tostring(obj) .. mm] = true
        return function()
            -- restore not possible without original; log only
        end
    end
    return function() end
end

-- ============================================================
-- REMOTE SPY SYSTEM (hookfunction on FireServer/InvokeServer)
-- ============================================================
local OrigFireServer, OrigInvokeServer, OrigFireClient

local function SetupRemoteSpy()
    if not hookfunction then return end

    local RS_proto = (getrawmetatable and getrawmetatable(Instance.new("RemoteEvent"))) or {}

    -- Hook FireServer
    local rawFS = rawget(RS_proto, "FireServer")
    if rawFS then
        OrigFireServer = clonefunction and clonefunction(rawFS) or rawFS
        pcall(hookfunction, rawFS, newcclosure(function(self, ...)
            if Cfg.RemoteSpyEnabled and Cfg.RemoteSpyLog then
                local entry = {
                    remote = tostring(self),
                    name   = self.Name,
                    args   = {...},
                    tick   = tick(),
                }
                table.insert(State.remoteLog, entry)
                if #State.remoteLog > 200 then table.remove(State.remoteLog, 1) end
            end
            if Cfg.RemoteSpyModify and self.Name == "UseItem" then
                -- intercept UseItem calls (VoidSpam uses its own direct call)
            end
            return OrigFireServer(self, ...)
        end))
    end

    -- Hook InvokeServer
    local RS_invoke_proto = (getrawmetatable and getrawmetatable(Instance.new("RemoteFunction"))) or {}
    local rawIS = rawget(RS_invoke_proto, "InvokeServer")
    if rawIS then
        OrigInvokeServer = clonefunction and clonefunction(rawIS) or rawIS
        pcall(hookfunction, rawIS, newcclosure(function(self, ...)
            if Cfg.RemoteSpyEnabled and Cfg.RemoteSpyLog then
                table.insert(State.remoteLog, {
                    remote = tostring(self), name = self.Name .. "(invoke)",
                    args = {...}, tick = tick()
                })
            end
            return OrigInvokeServer(self, ...)
        end))
    end
end

-- ============================================================
-- ANTI-CHEAT CONNECTION SILENCER
-- ============================================================
local function IsACKeyword(name)
    local lower = string.lower(name)
    for _, kw in ipairs(Cfg.ACSilencerKeywords) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

local function SilenceACConnections()
    if not getconnections then return end
    -- Scan all scripts for AC-like names
    if getscripts then
        for _, scr in ipairs(getscripts()) do
            if IsACKeyword(scr.Name) then
                local ok, conns = pcall(getconnections, scr.AncestryChanged)
                if ok and conns then
                    for _, c in ipairs(conns) do
                        pcall(function() c:Disable() end)
                        table.insert(State.acDisabledConns, c)
                    end
                end
            end
        end
    end
    -- Silence RemoteEvent connections that look like AC
    local function scanFolder(folder)
        if not folder then return end
        for _, v in ipairs(folder:GetDescendants()) do
            if v:IsA("RemoteEvent") and IsACKeyword(v.Name) then
                local ok, conns = pcall(getconnections, v.OnClientEvent)
                if ok and conns then
                    for _, c in ipairs(conns) do
                        pcall(function() c:Disable() end)
                        table.insert(State.acDisabledConns, c)
                    end
                end
            end
        end
    end
    pcall(scanFolder, ReplicatedStorage)
    pcall(scanFolder, Workspace)
end

-- ============================================================
-- MODULE UPVALUE MINER
-- ============================================================
local MinedData = {}

local function MineUpvalues(func, tag)
    if not (debug and debug.getupvalues) then return end
    local ok, ups = pcall(debug.getupvalues, func)
    if not ok or not ups then return end
    for i, v in pairs(ups) do
        if type(v) == "table" or type(v) == "function" or type(v) == "userdata" then
            MinedData[tag .. "_" .. tostring(i)] = v
            State.minedUpvalues[#State.minedUpvalues+1] = {tag=tag, idx=i, val=v}
        end
    end
end

local function MineAllModules()
    if not getloadedmodules then return end
    local mods = getloadedmodules()
    for _, mod in ipairs(mods) do
        if IsACKeyword(mod.Name) then
            -- Mine upvalues from AC modules to extract internal state
            -- (e.g., whitelist tables, player lists)
        end
        local ok, closure = pcall(function()
            return debug and debug.getinfo and debug.getinfo(mod, "f")
        end)
        if ok and closure and type(closure) == "function" then
            MineUpvalues(closure, mod.Name)
        end
    end
end

-- ============================================================
-- METAMETHOD HOOK SYSTEM
-- ============================================================
local OrigPlayerIndex

local function SetupMetaHooks()
    if not (hookmetamethod and getrawmetatable) then return end

    -- Hook __index on Players to intercept property reads
    local playersmt = getrawmetatable(Players)
    if playersmt then
        local old__index = rawget(playersmt, "__index")
        if old__index then
            OrigPlayerIndex = clonefunction and clonefunction(old__index) or old__index
            pcall(hookmetamethod, Players, "__index", newcclosure(function(self, key)
                -- Intercept any banned property reads
                return OrigPlayerIndex(self, key)
            end))
        end
    end

    -- Hook __namecall on game services to monitor calls
    local gamemt = getrawmetatable(game)
    if gamemt then
        local old__namecall = rawget(gamemt, "__namecall")
        if old__namecall then
            local origNamecall = clonefunction and clonefunction(old__namecall) or old__namecall
            pcall(hookmetamethod, game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                -- Allow all calls through; log suspicious ones if spy is on
                if Cfg.RemoteSpyEnabled and (method == "FireServer" or method == "InvokeServer") then
                    -- already hooked via hookfunction
                end
                return origNamecall(self, ...)
            end))
        end
    end
end

-- ============================================================
-- INSTANCE CACHE SPOOFER
-- ============================================================
local function SpoolCache(realInst, fakeInst)
    if not cache then return end
    if cache.replace then
        pcall(cache.replace, realInst, fakeInst)
    end
end

local function InvalidateCache(inst)
    if not cache then return end
    if cache.invalidate then
        pcall(cache.invalidate, inst)
    end
end

-- ============================================================
-- ENVIRONMENT INJECTOR
-- ============================================================
local function InjectToGenv(key, value)
    pcall(function() genv[key] = value end)
end

local function InjectToRenv(key, value)
    pcall(function() renv[key] = value end)
end

-- Inject helpers globally for easy access from other scripts
InjectToGenv("UNCODEGetTarget", function() return State.target end)
InjectToGenv("UNCODEGetCfg", function() return Cfg end)

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetCharacter(player)
    return player and player.Character
end

local function GetRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetBone(char, bone)
    return char and (char:FindFirstChild(bone) or char:FindFirstChild("HumanoidRootPart"))
end

local function IsAlive(player)
    local char = GetCharacter(player)
    local hum = GetHumanoid(char)
    return hum and hum.Health > 0
end

local function WorldToViewport(pos)
    local screenPos, inBounds = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), inBounds, screenPos.Z
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetEnemies()
    local enemies = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            if not Cfg.EspTeamCheck or p.Team ~= LocalPlayer.Team then
                table.insert(enemies, p)
            end
        end
    end
    return enemies
end

local function RaycastVis(from, to)
    local dir = to - from
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character or Instance.new("Part")}
    local result = Workspace:Raycast(from, dir, params)
    if not result then return true end
    local hit = result.Instance
    if hit and hit:IsDescendantOf(Workspace) then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and hit:IsDescendantOf(p.Character or Instance.new("Part")) then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- USEITEM REMOTE (VoidSpam / Riot)
-- ============================================================
local UseItemRemote

local function FindUseItemRemote()
    local ok, rem = pcall(function()
        return ReplicatedStorage.Remotes.Replication.Fighter.UseItem
    end)
    if ok and rem then UseItemRemote = rem; return rem end
    -- fallback: search
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "UseItem" then
            UseItemRemote = v
            return v
        end
    end
end

local function FireUseItem(payload)
    local rem = UseItemRemote or FindUseItemRemote()
    if not rem then return end
    if OrigFireServer then
        pcall(OrigFireServer, rem, payload)
    else
        pcall(function() rem:FireServer(payload) end)
    end
end

-- ============================================================
-- AIMBOT SYSTEM
-- ============================================================
local function GetBestTarget()
    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return nil end

    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge

    for _, p in ipairs(GetEnemies()) do
        local char = GetCharacter(p)
        local bone = GetBone(char, Cfg.AimbotBone)
        if bone then
            if Cfg.AimbotVisCheck and not RaycastVis(lr.Position, bone.Position) then continue end
            local sp, inB = WorldToViewport(bone.Position)
            if inB then
                local dist = (sp - center).Magnitude
                if dist < Cfg.AimbotFOV and dist < bestDist then
                    bestDist = dist
                    best = p
                end
            end
        end
    end
    return best
end

local function PredictedPos(char, bone, mult)
    local hrp = GetRoot(char)
    if not hrp then return bone.Position end
    local vel = hrp.AssemblyLinearVelocity
    local dist = GetDistance(Camera.CFrame.Position, bone.Position)
    local t = dist / 1000 * mult
    return bone.Position + vel * t
end

local function AimbotStep()
    if not Cfg.AimbotEnabled then return end
    local holding = UserInputService:IsKeyDown(Cfg.AimbotKey)
    if not holding and not Cfg.AimbotSilent then return end

    local target = GetBestTarget()
    State.target = target
    if not target then return end

    local char = GetCharacter(target)
    local bone = GetBone(char, Cfg.AimbotBone)
    if not bone then return end

    local aimPos = Cfg.AimbotPrediction
        and PredictedPos(char, bone, Cfg.AimbotPredMult)
        or bone.Position

    if Cfg.AimbotSilent then
        -- Silent aim: manipulate camera CF via rawset
        local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
        local mt = getrawmetatable and getrawmetatable(Camera)
        if mt then
            local ni = rawget(mt, "__newindex")
            if ni then pcall(ni, Camera, "CFrame", targetCF) end
        end
    else
        local currentLook = Camera.CFrame.LookVector
        local targetDir = (aimPos - Camera.CFrame.Position).Unit
        local newLook = currentLook:Lerp(targetDir, Cfg.AimbotSmooth)
        local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
        pcall(function() Camera.CFrame = newCF end)
    end
end

-- ============================================================
-- VOID SPAM SYSTEM
-- ============================================================
local lastVoidSpam = 0

local function VoidSpamStep()
    if not Cfg.VoidSpamEnabled then return end
    if not UserInputService:IsKeyDown(Cfg.VoidSpamKey) then return end
    if tick() - lastVoidSpam < Cfg.VoidSpamDelay then return end
    lastVoidSpam = tick()

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    local aimTarget = State.target
    local aimPos = lr.Position + Vector3.new(0, 0, -3)

    if Cfg.VoidSpamAutoAim and aimTarget then
        local char = GetCharacter(aimTarget)
        local bone = GetBone(char, "HumanoidRootPart")
        if bone then aimPos = bone.Position end
    end

    for i = 1, Cfg.VoidSpamCount do
        local spread = Cfg.VoidSpamRandAngle
            and CFrame.Angles(
                math.rad(math.random(-Cfg.VoidSpamSpread, Cfg.VoidSpamSpread)),
                math.rad(math.random(-Cfg.VoidSpamSpread, Cfg.VoidSpamSpread)),
                0
            )
            or CFrame.identity

        local baseDir = (aimPos - lr.Position).Unit
        local rotVec = (spread * baseDir).Unit
        local finalPos = aimPos + rotVec * 0.1

        local payload = {
            id          = GUID(),
            objectId    = GUID(),
            item        = "primary",
            position    = finalPos,
            attackNum   = math.random(1, 99),
            animationKeys = {math.random(1,999999), math.random(1,999999)},
            rotation    = CFrame.lookAt(Vector3.zero, rotVec),
            one         = Vector3.new(1,1,1),
            packed      = {"\x00", "\x01", "\x02", "\x03"},
        }
        task.spawn(FireUseItem, payload)
    end
end

-- ============================================================
-- FAKEPOS SYSTEM
-- ============================================================
local function FakePosStep()
    if not Cfg.FakePosEnabled then return end
    if not UserInputService:IsKeyDown(Cfg.FakePosKey) then return end

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    if not State.fpVirtualCF then
        State.fpVirtualCF = lr.CFrame
    end

    local surfaceRot = CFrame.identity
    local underPos = State.fpVirtualCF.Position - Vector3.new(0, Cfg.FakePosDepth, 0)

    -- Use rawmetatable bypass to set CFrame without network updates
    local mt = getrawmetatable and getrawmetatable(lr)
    if mt then
        local ni = rawget(mt, "__newindex")
        if ni then
            pcall(ni, lr, "CFrame", CFrame.new(underPos) * surfaceRot)
            return
        end
    end
    -- Fallback: sethiddenproperty
    if sethiddenproperty then
        pcall(sethiddenproperty, lr, "CFrame", CFrame.new(underPos) * surfaceRot)
        return
    end
    pcall(function() lr.CFrame = CFrame.new(underPos) * surfaceRot end)
end

-- ============================================================
-- VELOCITY DESYNC SYSTEM
-- ============================================================
local function VelDesyncStep()
    if not Cfg.VelDesyncEnabled then return end
    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    local spd = Cfg.VelDesyncSpeed
    local dir
    if Cfg.VelDesyncRandom then
        dir = Vector3.new(math.random()-0.5, 0, math.random()-0.5).Unit
    else
        dir = lr.CFrame.LookVector
    end
    local spoofVel = dir * spd

    -- Try metamethod bypass first
    local mt = getrawmetatable and getrawmetatable(lr)
    if mt then
        local ni = rawget(mt, "__newindex")
        if ni then
            pcall(ni, lr, "AssemblyLinearVelocity", spoofVel)
            return
        end
    end
    -- Try sethiddenproperty
    if sethiddenproperty then
        pcall(sethiddenproperty, lr, "AssemblyLinearVelocity", spoofVel)
        return
    end
    pcall(function() lr.AssemblyLinearVelocity = spoofVel end)
end

-- ============================================================
-- ANTI-AIM SYSTEM
-- ============================================================
local function AntiAimStep(dt)
    if not Cfg.AntiAimEnabled then return end
    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    State.aaAngle = State.aaAngle + Cfg.AntiAimSpeed * dt
    local mode = Cfg.AntiAimMode
    local finalYaw = 0

    if mode == "Spin" then
        finalYaw = State.aaAngle * 60
    elseif mode == "Jitter" then
        local j = Cfg.AntiAimJitter
        finalYaw = (math.sin(State.aaAngle * 10) > 0) and j or -j
    elseif mode == "Static" then
        finalYaw = 180
    elseif mode == "Up" then
        finalYaw = 0
    elseif mode == "Down" then
        finalYaw = 0
    elseif mode == "Side" then
        finalYaw = 90
    elseif mode == "RandomSpin" then
        finalYaw = State.aaAngle * (math.random(30,120))
    elseif mode == "Custom" then
        finalYaw = Cfg.AntiAimCustom
    end

    if Cfg.AntiAimFlip and math.sin(tick()) > 0 then
        finalYaw = finalYaw + 180
    end

    local base = lr.CFrame
    local mt = getrawmetatable and getrawmetatable(lr)
    local newCF = CFrame.new(base.Position) * CFrame.Angles(0, math.rad(finalYaw), 0)
    if mt then
        local ni = rawget(mt, "__newindex")
        if ni then pcall(ni, lr, "CFrame", newCF); return end
    end
    if sethiddenproperty then
        pcall(sethiddenproperty, lr, "CFrame", newCF); return
    end
    pcall(function() lr.CFrame = newCF end)
end

-- ============================================================
-- ORBIT SYSTEM
-- ============================================================
local function OrbitStep(dt)
    if not Cfg.OrbitEnabled then return end
    if not UserInputService:IsKeyDown(Cfg.OrbitKey) then return end

    local target = State.target
    if not target then target = GetBestTarget() end
    if not target then return end

    local char = GetCharacter(target)
    local trp = GetRoot(char)
    if not trp then return end

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    State.orbitAngle = State.orbitAngle + Cfg.OrbitSpeed * dt
    local t = State.orbitAngle
    local r = Cfg.OrbitRadius
    local mode = Cfg.OrbitMode

    local offset
    if mode == "Circle" then
        offset = Vector3.new(math.cos(t)*r, Cfg.OrbitHeight, math.sin(t)*r)
    elseif mode == "Figure8" then
        local scale = 1/(1+math.sin(t)^2)
        offset = Vector3.new(r*math.cos(t)*scale, Cfg.OrbitHeight, r*math.sin(t)*math.cos(t)*scale)
    elseif mode == "Ellipse" then
        offset = Vector3.new(math.cos(t)*Cfg.OrbitEllipseX, Cfg.OrbitHeight, math.sin(t)*Cfg.OrbitEllipseZ)
    elseif mode == "SpiralIn" then
        local sr = math.max(0.5, r - (t % (math.pi*2)) * 0.3)
        offset = Vector3.new(math.cos(t)*sr, Cfg.OrbitHeight, math.sin(t)*sr)
    elseif mode == "SpiralOut" then
        local sr = r + (t % (math.pi*2)) * 0.3
        offset = Vector3.new(math.cos(t)*sr, Cfg.OrbitHeight, math.sin(t)*sr)
    elseif mode == "Bounce" then
        offset = Vector3.new(math.cos(t)*r, math.abs(math.sin(t*2))*3 + Cfg.OrbitHeight, math.sin(t)*r)
    elseif mode == "Lemniscate" then
        local scale = math.cos(t) ~= 0 and 1/(1+math.sin(t)^2) or 1
        offset = Vector3.new(r*math.cos(t)*scale, Cfg.OrbitHeight, r*math.sin(t)*math.cos(t)*scale)
    elseif mode == "RandomOrbit" then
        offset = Vector3.new(
            math.cos(t + math.sin(t*0.7))*r,
            Cfg.OrbitHeight + math.sin(t*1.3)*1.5,
            math.sin(t + math.cos(t*0.5))*r
        )
    else
        offset = Vector3.new(math.cos(t)*r, Cfg.OrbitHeight, math.sin(t)*r)
    end

    local newPos = trp.Position + offset
    local newCF = CFrame.new(newPos, trp.Position)

    local mt = getrawmetatable and getrawmetatable(lr)
    if mt then
        local ni = rawget(mt, "__newindex")
        if ni then pcall(ni, lr, "CFrame", newCF); return end
    end
    pcall(function() lr.CFrame = newCF end)
end

-- ============================================================
-- SLINGBYPASS SYSTEM
-- ============================================================
local function SlingStep()
    if not Cfg.SlingEnabled then return end
    if not UserInputService:IsKeyDown(Cfg.SlingKey) then return end

    local target = State.target or GetBestTarget()
    if not target then return end

    local char = GetCharacter(target)
    local trp = GetRoot(char)
    if not trp then return end

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    local mode = Cfg.SlingMode
    local spd = Cfg.SlingSpeed

    if mode == "Follow" then
        local dir = (trp.Position - lr.Position)
        if dir.Magnitude > 1 then
            local vel = dir.Unit * spd
            local mt = getrawmetatable and getrawmetatable(lr)
            if mt then
                local ni = rawget(mt, "__newindex")
                if ni then pcall(ni, lr, "AssemblyLinearVelocity", vel) end
            elseif sethiddenproperty then
                pcall(sethiddenproperty, lr, "AssemblyLinearVelocity", vel)
            else
                pcall(function() lr.AssemblyLinearVelocity = vel end)
            end
        end
    elseif mode == "Stalk" then
        local stalkPos = trp.Position + trp.CFrame.LookVector * -4
        local dir = (stalkPos - lr.Position)
        if dir.Magnitude > 0.5 then
            local vel = dir.Unit * spd
            pcall(function() lr.AssemblyLinearVelocity = vel end)
        end
    elseif mode == "Hover" then
        local hoverPos = trp.Position + Vector3.new(0, 6, 0)
        lr.CFrame = CFrame.new(lr.Position:Lerp(hoverPos, 0.2))
    elseif mode == "FastTp" then
        lr.CFrame = trp.CFrame * CFrame.new(3, 0, 3)
    elseif mode == "TargetStick" then
        lr.CFrame = trp.CFrame * CFrame.new(0, 0, 2)
    elseif mode == "OrbitTarget" then
        local t = tick() * 2
        local r = Cfg.SlingOrbitR
        local offset = Vector3.new(math.cos(t)*r, 0, math.sin(t)*r)
        lr.CFrame = CFrame.new(trp.Position + offset, trp.Position)
    elseif mode == "RandomAroundTarget" then
        local rpos = trp.Position + Vector3.new(
            (math.random()-0.5)*Cfg.SlingOrbitR*2,
            (math.random()-0.5)*2,
            (math.random()-0.5)*Cfg.SlingOrbitR*2
        )
        lr.CFrame = CFrame.new(rpos)
    end
end

-- ============================================================
-- RIOT SYSTEM
-- ============================================================
local lastRiot = 0

local function RiotStep()
    if not Cfg.RiotEnabled then return end
    if not UserInputService:IsKeyDown(Cfg.RiotKey) then return end
    if tick() - lastRiot < Cfg.RiotDelay then return end
    lastRiot = tick()

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)
    if not lr then return end

    for i = 1, Cfg.RiotBurst do
        local angle = (i / Cfg.RiotBurst) * math.pi * 2
        local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local pos = lr.Position + dir * 2

        local payload = {
            id          = GUID(),
            objectId    = GUID(),
            item        = "primary",
            position    = pos,
            attackNum   = math.random(1,99),
            animationKeys = {math.random(1,999999), math.random(1,999999)},
            rotation    = CFrame.lookAt(Vector3.zero, dir),
            one         = Vector3.new(1,1,1),
            packed      = {"\x00","\x01","\x02","\x03"},
        }
        task.spawn(FireUseItem, payload)
    end
end

-- ============================================================
-- STAFF DETECTOR
-- ============================================================
local MOD_KEYWORDS = {"mod","admin","staff","owner","developer","tester","creator","contributor","qa"}

local function IsStaff(player)
    local name = string.lower(player.Name)
    local dname = player.DisplayName and string.lower(player.DisplayName) or ""
    for _, kw in ipairs(MOD_KEYWORDS) do
        if string.find(name, kw, 1, true) or string.find(dname, kw, 1, true) then
            return true
        end
    end
    -- Check group ranks if available
    local ok, rank = pcall(function() return player:GetRankInGroup(game.CreatorId) end)
    if ok and rank and rank >= 200 then return true end
    return false
end

local function UpdateStaffList()
    State.staffList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if IsStaff(p) then
            table.insert(State.staffList, p.Name)
        end
    end
end

-- ============================================================
-- MISC SYSTEMS
-- ============================================================
local function SetupInfiniteJump()
    if not Cfg.InfiniteJump then return end
    UserInputService.JumpRequest:Connect(function()
        if not Cfg.InfiniteJump then return end
        local lc = GetCharacter(LocalPlayer)
        local hum = GetHumanoid(lc)
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function NoclipStep()
    if not Cfg.Noclip then return end
    local lc = GetCharacter(LocalPlayer)
    if not lc then return end
    for _, part in ipairs(lc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function BunnyHopStep()
    if not Cfg.BunnyHop then return end
    local lc = GetCharacter(LocalPlayer)
    local hum = GetHumanoid(lc)
    if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function SpeedStep()
    if Cfg.SpeedMultiplier <= 1.0 then return end
    local lc = GetCharacter(LocalPlayer)
    local hum = GetHumanoid(lc)
    if hum then
        hum.WalkSpeed = Cfg.WalkspeedVal * Cfg.SpeedMultiplier
    end
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local function CreateEspDrawings(player)
    local d = {
        box    = Drawing.new("Square"),
        name   = Drawing.new("Text"),
        health = Drawing.new("Text"),
        dist   = Drawing.new("Text"),
    }
    d.box.Visible = false
    d.box.Color = Cfg.EspBoxColor
    d.box.Thickness = 1.5
    d.box.Filled = false

    d.name.Visible = false
    d.name.Color = Cfg.EspNameColor
    d.name.Size = 13
    d.name.Font = Drawing.Fonts and Drawing.Fonts.Code or 3
    d.name.Center = true

    d.health.Visible = false
    d.health.Color = Cfg.EspHealthColor
    d.health.Size = 12
    d.health.Center = true
    d.health.Font = Drawing.Fonts and Drawing.Fonts.Code or 3

    d.dist.Visible = false
    d.dist.Color = Color3.fromRGB(200,200,200)
    d.dist.Size = 12
    d.dist.Center = true
    d.dist.Font = Drawing.Fonts and Drawing.Fonts.Code or 3

    State.espDrawings[player.UserId] = d
end

local function RemoveEspDrawings(player)
    local d = State.espDrawings[player.UserId]
    if not d then return end
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
    State.espDrawings[player.UserId] = nil
end

local function EspStep()
    if not (Cfg.EspEnabled and Drawing) then return end

    local lc = GetCharacter(LocalPlayer)
    local lr = GetRoot(lc)

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end

        local d = State.espDrawings[p.UserId]
        if not d then CreateEspDrawings(p) d = State.espDrawings[p.UserId] end

        local char = GetCharacter(p)
        local root = GetRoot(char)
        local hum = GetHumanoid(char)

        if not (Cfg.EspEnabled and char and root and hum and hum.Health > 0) then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end

        local headPos = char:FindFirstChild("Head") and char.Head.Position or root.Position + Vector3.new(0,1.5,0)
        local feetPos = root.Position - Vector3.new(0,2.8,0)

        local topSP, topVis, topZ = WorldToViewport(headPos)
        local botSP = WorldToViewport(feetPos)

        local dist = lr and GetDistance(lr.Position, root.Position) or 999

        if not topVis or topZ < 0 or dist > Cfg.EspMaxDist then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end

        local h = math.abs(topSP.Y - botSP.Y)
        local w = h * 0.5
        local x = topSP.X - w/2
        local y = topSP.Y

        if Cfg.EspBoxes then
            d.box.Position = Vector2.new(x, y)
            d.box.Size = Vector2.new(w, h)
            d.box.Visible = true
        else
            d.box.Visible = false
        end

        if Cfg.EspNames then
            d.name.Text = p.DisplayName or p.Name
            d.name.Position = Vector2.new(topSP.X, y - 16)
            d.name.Visible = true
        else
            d.name.Visible = false
        end

        if Cfg.EspHealth then
            local hp = math.floor(hum.Health)
            local maxHp = math.floor(hum.MaxHealth)
            d.health.Text = hp .. "/" .. maxHp
            d.health.Position = Vector2.new(topSP.X, y + h + 2)
            d.health.Color = Color3.fromRGB(
                math.floor((1 - hp/maxHp) * 255),
                math.floor((hp/maxHp) * 255),
                0
            )
            d.health.Visible = true
        else
            d.health.Visible = false
        end

        if Cfg.EspDist then
            d.dist.Text = math.floor(dist) .. "m"
            d.dist.Position = Vector2.new(topSP.X, y + h + (Cfg.EspHealth and 16 or 2))
            d.dist.Visible = true
        else
            d.dist.Visible = false
        end
    end
end

-- ============================================================
-- UI SYSTEM
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UNCODE_v5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 580, 0, 430)
MainFrame.Position = UDim2.new(0, 80, 0, 80)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 60, 180)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "UNCODE v5  |  KiciaHook / UE"
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 28, 1, 0)
CloseBtn.Position = UDim2.new(1, -28, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
CloseBtn.BorderSizePixel = 0
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Text = "_"
MinimizeBtn.Size = UDim2.new(0, 28, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -56, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 13
MinimizeBtn.Parent = TitleBar

local ContentArea = Instance.new("Frame")
ContentArea.Name = "Content"
ContentArea.Size = UDim2.new(1, 0, 1, -28)
ContentArea.Position = UDim2.new(0, 0, 0, 28)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Minimize: show only title bar
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentArea.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 580, 0, 28) or UDim2.new(0, 580, 0, 430)
end)

-- Tab system
local TAB_NAMES = {"Aimbot","VoidSpam","AntiAim","ESP","Orbit","Sling/Riot","Hooks","Misc"}
local TabButtons = {}
local TabFrames = {}
local currentTab = 1

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 100, 1, 0)
TabBar.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
TabBar.BorderSizePixel = 0
TabBar.Parent = ContentArea

local TabList = Instance.new("UIListLayout")
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Parent = TabBar

local PanelArea = Instance.new("Frame")
PanelArea.Size = UDim2.new(1, -100, 1, 0)
PanelArea.Position = UDim2.new(0, 100, 0, 0)
PanelArea.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
PanelArea.BorderSizePixel = 0
PanelArea.Parent = ContentArea

local function SwitchTab(idx)
    currentTab = idx
    for i, f in ipairs(TabFrames) do
        f.Visible = (i == idx)
    end
    for i, b in ipairs(TabButtons) do
        b.BackgroundColor3 = (i == idx)
            and Color3.fromRGB(0, 80, 220)
            or Color3.fromRGB(20, 20, 35)
    end
end

for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(0, 80, 220) or Color3.fromRGB(20, 20, 35)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(220, 220, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.LayoutOrder = i
    btn.Parent = TabBar
    btn.MouseButton1Click:Connect(function() SwitchTab(i) end)
    table.insert(TabButtons, btn)

    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.ScrollBarImageColor3 = Color3.fromRGB(0, 100, 255)
    frame.Visible = (i == 1)
    frame.Parent = PanelArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = frame

    table.insert(TabFrames, frame)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)
end

-- UI Helpers
local function MakeToggle(parent, label, getter, setter, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200,200,255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local padl = Instance.new("UIPadding")
    padl.PaddingLeft = UDim.new(0,6)
    padl.Parent = lbl

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 20)
    btn.Position = UDim2.new(1, -68, 0.5, -10)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = row

    local function Refresh()
        local val = getter()
        btn.Text = val and "ON" or "OFF"
        btn.BackgroundColor3 = val and Color3.fromRGB(0,160,80) or Color3.fromRGB(100,30,30)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
    end
    Refresh()

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        Refresh()
    end)
    return row
end

local function MakeSlider(parent, label, getter, setter, minV, maxV, step, order)
    step = step or 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text = label .. ": " .. tostring(getter())
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180,180,220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local padl = Instance.new("UIPadding")
    padl.PaddingLeft = UDim.new(0,6)
    padl.Parent = lbl

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 8)
    track.Position = UDim2.new(0, 8, 0, 22)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    track.BorderSizePixel = 0
    track.Parent = row

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(0,100,255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local function UpdateFill()
        local v = getter()
        local pct = math.clamp((v - minV)/(maxV - minV), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        lbl.Text = label .. ": " .. tostring(v)
    end
    UpdateFill()

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = inp.Position.X - track.AbsolutePosition.X
            local pct = math.clamp(rel / track.AbsoluteSize.X, 0, 1)
            local raw = minV + (maxV - minV) * pct
            local snapped = math.floor(raw / step + 0.5) * step
            setter(math.clamp(snapped, minV, maxV))
            UpdateFill()
        end
    end)
    return row
end

local function MakeDropdown(parent, label, options, getter, setter, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180,180,220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local padl = Instance.new("UIPadding")
    padl.PaddingLeft = UDim.new(0,6)
    padl.Parent = lbl

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -8, 0, 22)
    btn.Position = UDim2.new(0.5, 4, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(0,80,200)
    btn.Text = getter()
    btn.TextColor3 = Color3.fromRGB(200,200,255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = row

    local idx = 1
    for i, v in ipairs(options) do if v == getter() then idx = i break end end

    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        setter(options[idx])
        btn.Text = options[idx]
    end)
    return row
end

local function MakeSectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Text = "-- " .. text .. " --"
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundColor3 = Color3.fromRGB(12,12,24)
    lbl.BorderSizePixel = 0
    lbl.TextColor3 = Color3.fromRGB(100,150,255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent
    return lbl
end

-- ============================================================
-- TAB 1: AIMBOT
-- ============================================================
do
    local p = TabFrames[1]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p, "Aimbot", no())
    MakeToggle(p,"Aimbot Enabled",function() return Cfg.AimbotEnabled end, function(v) Cfg.AimbotEnabled=v end, no())
    MakeSlider(p,"FOV",function() return Cfg.AimbotFOV end,function(v) Cfg.AimbotFOV=v end,50,600,10,no())
    MakeSlider(p,"Smooth",function() return Cfg.AimbotSmooth end,function(v) Cfg.AimbotSmooth=v end,0.01,1,0.01,no())
    MakeDropdown(p,"Bone",{"Head","HumanoidRootPart","UpperTorso","RightUpperArm","LeftUpperArm"},function() return Cfg.AimbotBone end,function(v) Cfg.AimbotBone=v end,no())
    MakeToggle(p,"Prediction",function() return Cfg.AimbotPrediction end,function(v) Cfg.AimbotPrediction=v end,no())
    MakeSlider(p,"Pred Mult",function() return Cfg.AimbotPredMult end,function(v) Cfg.AimbotPredMult=v end,0.1,5,0.1,no())
    MakeToggle(p,"Silent Aim",function() return Cfg.AimbotSilent end,function(v) Cfg.AimbotSilent=v end,no())
    MakeToggle(p,"Vis Check",function() return Cfg.AimbotVisCheck end,function(v) Cfg.AimbotVisCheck=v end,no())
    MakeSectionLabel(p,"VoidSpam",no())
    MakeToggle(p,"VoidSpam Enabled",function() return Cfg.VoidSpamEnabled end,function(v) Cfg.VoidSpamEnabled=v end,no())
    MakeSlider(p,"Delay (s)",function() return Cfg.VoidSpamDelay end,function(v) Cfg.VoidSpamDelay=v end,0.01,1,0.01,no())
    MakeSlider(p,"Count",function() return Cfg.VoidSpamCount end,function(v) Cfg.VoidSpamCount=v end,1,20,1,no())
    MakeSlider(p,"Spread",function() return Cfg.VoidSpamSpread end,function(v) Cfg.VoidSpamSpread=v end,0,90,1,no())
    MakeToggle(p,"Auto Aim",function() return Cfg.VoidSpamAutoAim end,function(v) Cfg.VoidSpamAutoAim=v end,no())
    MakeToggle(p,"Random Angle",function() return Cfg.VoidSpamRandAngle end,function(v) Cfg.VoidSpamRandAngle=v end,no())
end

-- ============================================================
-- TAB 2: VOIDSPAM (extra controls)
-- ============================================================
do
    local p = TabFrames[2]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"FakePos",no())
    MakeToggle(p,"FakePos Enabled",function() return Cfg.FakePosEnabled end,function(v) Cfg.FakePosEnabled=v end,no())
    MakeSlider(p,"Depth",function() return Cfg.FakePosDepth end,function(v) Cfg.FakePosDepth=v end,0.5,20,0.5,no())
    MakeDropdown(p,"Type",{"Ground","Underground","Above"},function() return Cfg.FakePosType end,function(v) Cfg.FakePosType=v end,no())
    MakeSectionLabel(p,"VelDesync",no())
    MakeToggle(p,"VelDesync Enabled",function() return Cfg.VelDesyncEnabled end,function(v) Cfg.VelDesyncEnabled=v end,no())
    MakeSlider(p,"Speed",function() return Cfg.VelDesyncSpeed end,function(v) Cfg.VelDesyncSpeed=v end,10,500,5,no())
    MakeToggle(p,"Random Dir",function() return Cfg.VelDesyncRandom end,function(v) Cfg.VelDesyncRandom=v end,no())
    MakeSectionLabel(p,"Riot",no())
    MakeToggle(p,"Riot Enabled",function() return Cfg.RiotEnabled end,function(v) Cfg.RiotEnabled=v end,no())
    MakeSlider(p,"Burst Count",function() return Cfg.RiotBurst end,function(v) Cfg.RiotBurst=v end,1,20,1,no())
    MakeSlider(p,"Delay",function() return Cfg.RiotDelay end,function(v) Cfg.RiotDelay=v end,0.01,1,0.01,no())
end

-- ============================================================
-- TAB 3: ANTI-AIM
-- ============================================================
do
    local p = TabFrames[3]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"Anti-Aim",no())
    MakeToggle(p,"AntiAim Enabled",function() return Cfg.AntiAimEnabled end,function(v) Cfg.AntiAimEnabled=v end,no())
    MakeDropdown(p,"Mode",{"Spin","Jitter","Static","Up","Down","Side","RandomSpin","Custom"},function() return Cfg.AntiAimMode end,function(v) Cfg.AntiAimMode=v end,no())
    MakeSlider(p,"Speed",function() return Cfg.AntiAimSpeed end,function(v) Cfg.AntiAimSpeed=v end,1,60,1,no())
    MakeSlider(p,"Jitter Deg",function() return Cfg.AntiAimJitter end,function(v) Cfg.AntiAimJitter=v end,1,180,1,no())
    MakeSlider(p,"Custom Yaw",function() return Cfg.AntiAimCustom end,function(v) Cfg.AntiAimCustom=v end,-180,180,1,no())
    MakeToggle(p,"Flip",function() return Cfg.AntiAimFlip end,function(v) Cfg.AntiAimFlip=v end,no())
end

-- ============================================================
-- TAB 4: ESP
-- ============================================================
do
    local p = TabFrames[4]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"ESP",no())
    MakeToggle(p,"ESP Enabled",function() return Cfg.EspEnabled end,function(v) Cfg.EspEnabled=v end,no())
    MakeToggle(p,"Boxes",function() return Cfg.EspBoxes end,function(v) Cfg.EspBoxes=v end,no())
    MakeToggle(p,"Names",function() return Cfg.EspNames end,function(v) Cfg.EspNames=v end,no())
    MakeToggle(p,"Health",function() return Cfg.EspHealth end,function(v) Cfg.EspHealth=v end,no())
    MakeToggle(p,"Distance",function() return Cfg.EspDist end,function(v) Cfg.EspDist=v end,no())
    MakeToggle(p,"Skeleton",function() return Cfg.EspSkeleton end,function(v) Cfg.EspSkeleton=v end,no())
    MakeSlider(p,"Max Dist",function() return Cfg.EspMaxDist end,function(v) Cfg.EspMaxDist=v end,50,2000,50,no())
    MakeToggle(p,"Team Check",function() return Cfg.EspTeamCheck end,function(v) Cfg.EspTeamCheck=v end,no())
    MakeSectionLabel(p,"Staff Detector",no())
    MakeToggle(p,"Staff Detect",function() return Cfg.StaffDetectEnabled end,function(v) Cfg.StaffDetectEnabled=v end,no())
end

-- ============================================================
-- TAB 5: ORBIT
-- ============================================================
do
    local p = TabFrames[5]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"Orbit",no())
    MakeToggle(p,"Orbit Enabled",function() return Cfg.OrbitEnabled end,function(v) Cfg.OrbitEnabled=v end,no())
    MakeDropdown(p,"Mode",{"Circle","Figure8","Ellipse","SpiralIn","SpiralOut","Bounce","Lemniscate","RandomOrbit"},function() return Cfg.OrbitMode end,function(v) Cfg.OrbitMode=v end,no())
    MakeSlider(p,"Radius",function() return Cfg.OrbitRadius end,function(v) Cfg.OrbitRadius=v end,1,30,0.5,no())
    MakeSlider(p,"Speed",function() return Cfg.OrbitSpeed end,function(v) Cfg.OrbitSpeed=v end,0.1,15,0.1,no())
    MakeSlider(p,"Height",function() return Cfg.OrbitHeight end,function(v) Cfg.OrbitHeight=v end,-10,20,0.5,no())
    MakeSlider(p,"Ellipse X",function() return Cfg.OrbitEllipseX end,function(v) Cfg.OrbitEllipseX=v end,1,30,0.5,no())
    MakeSlider(p,"Ellipse Z",function() return Cfg.OrbitEllipseZ end,function(v) Cfg.OrbitEllipseZ=v end,1,30,0.5,no())
end

-- ============================================================
-- TAB 6: SLING / RIOT
-- ============================================================
do
    local p = TabFrames[6]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"SlingBypass",no())
    MakeToggle(p,"Sling Enabled",function() return Cfg.SlingEnabled end,function(v) Cfg.SlingEnabled=v end,no())
    MakeDropdown(p,"Mode",{"Follow","Stalk","Hover","FastTp","TargetStick","OrbitTarget","RandomAroundTarget"},function() return Cfg.SlingMode end,function(v) Cfg.SlingMode=v end,no())
    MakeSlider(p,"Speed",function() return Cfg.SlingSpeed end,function(v) Cfg.SlingSpeed=v end,5,200,5,no())
    MakeSlider(p,"Orbit Radius",function() return Cfg.SlingOrbitR end,function(v) Cfg.SlingOrbitR=v end,1,20,0.5,no())
end

-- ============================================================
-- TAB 7: HOOKS (KiciaHook/UE APIs)
-- ============================================================
do
    local p = TabFrames[7]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"Hook Systems",no())
    MakeToggle(p,"Remote Spy",function() return Cfg.RemoteSpyEnabled end,function(v)
        Cfg.RemoteSpyEnabled = v
        if v then SetupRemoteSpy() end
    end,no())
    MakeToggle(p,"Spy: Log",function() return Cfg.RemoteSpyLog end,function(v) Cfg.RemoteSpyLog=v end,no())
    MakeToggle(p,"Spy: Modify",function() return Cfg.RemoteSpyModify end,function(v) Cfg.RemoteSpyModify=v end,no())
    MakeToggle(p,"AC Silencer",function() return Cfg.ACSilencerEnabled end,function(v)
        Cfg.ACSilencerEnabled = v
        if v then task.spawn(SilenceACConnections) end
    end,no())
    MakeToggle(p,"Upvalue Miner",function() return Cfg.UpvalueMinerEnabled end,function(v)
        Cfg.UpvalueMinerEnabled = v
        if v then task.spawn(MineAllModules) end
    end,no())
    MakeToggle(p,"Meta Hooks",function() return Cfg.MetaHookEnabled end,function(v)
        Cfg.MetaHookEnabled = v
        if v then SetupMetaHooks() end
    end,no())
    MakeToggle(p,"Cache Spoofer",function() return Cfg.CacheSpooferEnabled end,function(v) Cfg.CacheSpooferEnabled=v end,no())

    MakeSectionLabel(p,"Remote Log",no())

    -- Log display
    local logBox = Instance.new("Frame")
    logBox.Size = UDim2.new(1, 0, 0, 140)
    logBox.BackgroundColor3 = Color3.fromRGB(8,8,18)
    logBox.BorderColor3 = Color3.fromRGB(0,60,150)
    logBox.BorderSizePixel = 1
    logBox.LayoutOrder = no()
    logBox.Parent = p

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, 0, 1, 0)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 3
    logScroll.Parent = logBox

    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Parent = logScroll

    local logCount = 0
    local function AddLogEntry(text)
        logCount = logCount + 1
        local lbl = Instance.new("TextLabel")
        lbl.Text = text
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(150, 200, 255)
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = logCount
        lbl.Parent = logScroll
        logScroll.CanvasSize = UDim2.new(0,0,0,logLayout.AbsoluteContentSize.Y)
        logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
        if logCount > 50 then
            local first = logScroll:FindFirstChildOfClass("TextLabel")
            if first then first:Destroy() end
        end
    end

    -- Update log display periodically
    task.spawn(function()
        local lastCount = 0
        while task.wait(0.5) do
            if #State.remoteLog > lastCount then
                for i = lastCount+1, #State.remoteLog do
                    local entry = State.remoteLog[i]
                    AddLogEntry(string.format("[%.2f] %s", entry.tick % 1000, entry.name))
                end
                lastCount = #State.remoteLog
            end
        end
    end)

    local clearBtn = Instance.new("TextButton")
    clearBtn.Text = "Clear Log"
    clearBtn.Size = UDim2.new(1, 0, 0, 24)
    clearBtn.BackgroundColor3 = Color3.fromRGB(30,30,60)
    clearBtn.BorderSizePixel = 0
    clearBtn.TextColor3 = Color3.fromRGB(180,180,255)
    clearBtn.Font = Enum.Font.Code
    clearBtn.TextSize = 12
    clearBtn.LayoutOrder = no()
    clearBtn.Parent = p
    clearBtn.MouseButton1Click:Connect(function()
        State.remoteLog = {}
        for _, v in ipairs(logScroll:GetChildren()) do
            if v:IsA("TextLabel") then v:Destroy() end
        end
        logCount = 0
    end)

    MakeSectionLabel(p,"Upvalue Data",no())
    local upvalLabel = Instance.new("TextLabel")
    upvalLabel.Size = UDim2.new(1, 0, 0, 18)
    upvalLabel.BackgroundTransparency = 1
    upvalLabel.TextColor3 = Color3.fromRGB(150,200,100)
    upvalLabel.Font = Enum.Font.Code
    upvalLabel.TextSize = 12
    upvalLabel.TextXAlignment = Enum.TextXAlignment.Left
    upvalLabel.LayoutOrder = no()
    upvalLabel.Text = "Mined: 0 values"
    upvalLabel.Parent = p

    task.spawn(function()
        while task.wait(2) do
            upvalLabel.Text = "Mined: " .. #State.minedUpvalues .. " values | Disabled AC conns: " .. #State.acDisabledConns
        end
    end)
end

-- ============================================================
-- TAB 8: MISC
-- ============================================================
do
    local p = TabFrames[8]
    local o = 0
    local function no() o=o+1; return o end
    MakeSectionLabel(p,"Movement",no())
    MakeToggle(p,"Infinite Jump",function() return Cfg.InfiniteJump end,function(v) Cfg.InfiniteJump=v end,no())
    MakeToggle(p,"Noclip",function() return Cfg.Noclip end,function(v) Cfg.Noclip=v end,no())
    MakeToggle(p,"Bunny Hop",function() return Cfg.BunnyHop end,function(v) Cfg.BunnyHop=v end,no())
    MakeSlider(p,"Speed Mult",function() return Cfg.SpeedMultiplier end,function(v) Cfg.SpeedMultiplier=v end,1,5,0.1,no())
    MakeSlider(p,"Walkspeed",function() return Cfg.WalkspeedVal end,function(v) Cfg.WalkspeedVal=v end,16,200,2,no())
    MakeSectionLabel(p,"Auto",no())
    MakeToggle(p,"Auto Respawn",function() return Cfg.AutoRespawn end,function(v) Cfg.AutoRespawn=v end,no())
    MakeSectionLabel(p,"Staff List",no())

    local staffLbl = Instance.new("TextLabel")
    staffLbl.Size = UDim2.new(1, 0, 0, 60)
    staffLbl.BackgroundColor3 = Color3.fromRGB(8,8,18)
    staffLbl.BorderSizePixel = 1
staffLbl.BorderColor3 = Color3.fromRGB(0,60,150)
    staffLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
    staffLbl.Font = Enum.Font.Code
    staffLbl.TextSize = 12
    staffLbl.TextXAlignment = Enum.TextXAlignment.Left
    staffLbl.TextYAlignment = Enum.TextYAlignment.Top
    staffLbl.TextWrapped = true
    staffLbl.LayoutOrder = no()
    staffLbl.Parent = p

    local staffPad = Instance.new("UIPadding")
    staffPad.PaddingLeft = UDim.new(0,4)
    staffPad.PaddingTop = UDim.new(0,4)
    staffPad.Parent = staffLbl

    task.spawn(function()
        while task.wait(5) do
            if Cfg.StaffDetectEnabled then
                UpdateStaffList()
                staffLbl.Text = #State.staffList == 0
                    and "No staff detected"
                    or "STAFF: " .. table.concat(State.staffList, ", ")
            end
        end
    end)

    MakeSectionLabel(p,"Info",no())
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0, 60)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3 = Color3.fromRGB(120,120,180)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.TextWrapped = true
    infoLbl.LayoutOrder = no()
    infoLbl.Parent = p

    task.spawn(function()
        while task.wait(1) do
            local hasHook = hookfunction and "YES" or "NO"
            local hasMeta = hookmetamethod and "YES" or "NO"
            local hasDbg  = (debug and debug.getupvalue) and "YES" or "NO"
            local hasConns = getconnections and "YES" or "NO"
            local hasCfn  = newcclosure and "YES" or "NO"
            infoLbl.Text = string.format(
                "hookfunction: %s | hookmetamethod: %s\ndebug.upvalue: %s | getconnections: %s\nnewcclosure: %s | Target: %s",
                hasHook, hasMeta, hasDbg, hasConns, hasCfn,
                State.target and State.target.Name or "none"
            )
        end
    end)
end

-- ============================================================
-- KEYBIND: TOGGLE UI (Insert key)
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ============================================================
-- AUTO-RESPAWN
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
    -- Re-silence AC on respawn
    if Cfg.ACSilencerEnabled then
        task.delay(2, SilenceACConnections)
    end
    -- Reset state
    State.fpVirtualCF = nil
    State.fpActive = false
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================
task.spawn(function()
    -- Find UseItem remote
    FindUseItemRemote()

    -- Start remote spy if enabled
    if Cfg.RemoteSpyEnabled then
        SetupRemoteSpy()
    end

    -- Start meta hooks if enabled
    if Cfg.MetaHookEnabled then
        SetupMetaHooks()
    end

    -- Silence AC connections
    if Cfg.ACSilencerEnabled then
        SilenceACConnections()
    end

    -- Mine upvalues
    if Cfg.UpvalueMinerEnabled then
        MineAllModules()
    end

    -- Setup infinite jump
    SetupInfiniteJump()

    -- Init ESP drawings for existing players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            CreateEspDrawings(p)
        end
    end

    -- Initial staff scan
    UpdateStaffList()

    print("[UNCODE v5] Loaded. hookfunction=" .. tostring(hookfunction ~= nil))
    print("[UNCODE v5] hookmetamethod=" .. tostring(hookmetamethod ~= nil))
    print("[UNCODE v5] getconnections=" .. tostring(getconnections ~= nil))
    print("[UNCODE v5] debug.getupvalue=" .. tostring(debug ~= nil and debug.getupvalue ~= nil))
end)

-- ESP: cleanup on player leave
Players.PlayerRemoving:Connect(function(p)
    RemoveEspDrawings(p)
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    AimbotStep()
    EspStep()
    NoclipStep()
    BunnyHopStep()
    SpeedStep()
    AntiAimStep(dt)
    OrbitStep(dt)
end)

RunService.Heartbeat:Connect(function()
    VoidSpamStep()
    FakePosStep()
    VelDesyncStep()
    SlingStep()
    RiotStep()
end)
