-- UNCODE v1.0 - Rivals HvH | PC Build
-- Self-contained single script. No external engine launches.
-- Engines extracted directly from LuaX paid latest + Rivals ragebot works.
-- UI: Linoria (xyznick/UELinoriaLib), 6-tab window.

print("[UNCODE] Script started loading...")
if not game:IsLoaded() then game.Loaded:Wait() end
print("[UNCODE] Game loaded, continuing...")

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local repS  = cloneref(ReplicatedStorage)
local plrs  = cloneref(Players)
local runS  = cloneref(RunService)
local ws    = cloneref(workspace)

-- ── Rivals modules ────────────────────────────────────────────────────────────
local util            = require(repS.Modules.Utility)
local enum_lib        = require(repS.Modules.EnumLibrary)
local FighterController  = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
local SpectateController = require(LocalPlayer.PlayerScripts.Controllers:WaitForChild("SpectateController"))

-- ── Linoria load ──────────────────────────────────────────────────────────────
local Library
do
    print("[UNCODE] Fetching Linoria UI library...")
    local ok, src = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/xyznick/UELinoriaLib/main/Library.lua", true)
    end)
    if not ok or not src then
        warn("[UNCODE] FAILED to fetch Linoria! Error: " .. tostring(src))
        return
    end
    print("[UNCODE] Linoria source fetched, loading...")
    local fn, e = loadstring(src, "LinoriaLib")
    if not fn then
        warn("[UNCODE] FAILED to parse Linoria: " .. tostring(e))
        return
    end
    Library = fn()
    print("[UNCODE] Linoria UI library loaded OK")
end

-- ── Window / tabs ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title             = "UNCODE",
    Footer            = "rivals.gg",
    Center            = true,
    AutoShow          = true,
    Resizable         = true,
    NotifySide        = "Right",
    MobileButtonsSide = "Left",
    ShowCustomCursor  = true,
})
print("[UNCODE] Window created OK, building tabs...")

local Tabs = {
    Combat  = Window:AddTab("Combat"),
    HvH     = Window:AddTab("HvH"),
    ESP     = Window:AddTab("ESP"),
    Visual  = Window:AddTab("Visual"),
    Misc    = Window:AddTab("Misc"),
    Setting = Window:AddTab("Setting"),
}

local TB = {
    Combat  = Tabs.Combat:AddTabbox({ Side = 1 }),
    HvH     = Tabs.HvH:AddTabbox({ Side = 1 }),
    ESP     = Tabs.ESP:AddTabbox({ Side = 1 }),
    Visual  = Tabs.Visual:AddTabbox({ Side = 1 }),
    Misc    = Tabs.Misc:AddTabbox({ Side = 1 }),
    Setting = Tabs.Setting:AddTabbox({ Side = 1 }),
}

local WT = {
    Rage     = TB.Combat:AddTab("Rage"),
    Void     = TB.HvH:AddTab("VoidSpam"),
    Orbit    = TB.HvH:AddTab("Orbit"),
    Pred     = TB.HvH:AddTab("Prediction"),
    Defense  = TB.HvH:AddTab("Defense"),
    AntiAim  = TB.HvH:AddTab("AntiAim"),
    ESP      = TB.ESP:AddTab("ESP"),
    Chams    = TB.Visual:AddTab("Chams"),
    FX       = TB.Visual:AddTab("Effects"),
    Transloc = TB.Misc:AddTab("Transloc"),
    Sling    = TB.Misc:AddTab("Sling"),
    Riot     = TB.Misc:AddTab("Riot"),
    Range    = TB.Misc:AddTab("Range"),
    Config   = TB.Setting:AddTab("Config"),
}

local function Notify(text, duration)
    Library:Notify({ Title = "UNCODE", Description = text, Time = duration or 3 })
end

-- ── Character state ───────────────────────────────────────────────────────────
local char, root, hum
local conns = {}

local function killConn(key)
    if conns[key] then conns[key]:Disconnect(); conns[key] = nil end
end

local function safeCall(fn, ...) local ok, err = pcall(fn, ...); if not ok then warn("[UNCODE] error:", err) end; return ok end
local function safeSet(instance, prop, value) if not instance then return end; pcall(function() instance[prop] = value end) end

-- ── Config tables (extracted from LuaX) ──────────────────────────────────────
local CFG = {
    VOID_ENABLED = false, VOID_METHOD = "Quantum",
    SPEED = 1e15, CHAOS = 0.98, BASE_X = 0, BASE_Y = 0, BASE_Z = 0,
    RADIUS = 1e15, VOID_Y_MIN = -1e15, VOID_Y_MAX = 1e15,
    TP_MIN_STUDS = -9e14, TP_MAX_STUDS = 9e14,
    TP_RAND_ENABLED = true, TP_RAND_MIN = -1e15, TP_RAND_MAX = 1e15,
    TP_VERT_SPIKE = true, TP_VERT_MULT_MIN = 0.5, TP_VERT_MULT_MAX = 3.0,
    TP_CORNER_WEIGHT = 0.55, TP_EDGE_WEIGHT = 0.35, TP_SCREEN_JITTER = 0.12,
    TP_SCREEN_CLAMP = true, TP_VIEWPORT_RAY = true, TP_NEG_BIAS = true, TP_PRESERVE_Y = false,
    VOID_SAFE_RADIUS = 0, VOID_ORBIT_TARGET = false, VOID_ORBIT_SPEED = 90,
    VOID_STOP_ON_DAMAGE = false, VOID_PREDICTIVE = false, VOID_PREDICT_LEAD = 0.15,
    VOID_AUTO_REENABLE = false, VOID_ANTIFLING = false,
    VOID_FREEZE_ON_GROUND = false, VOID_ANTIVOID = false,
    VOID_DURATION_ENABLED = false, VOID_DURATION = 10,
    VOID_RANDOM_DURATION = false, VOID_DURATION_MIN = 5, VOID_DURATION_MAX = 30,
    VOID_STAY_IN_REGION = false, VOID_REGION_X = 1e4, VOID_REGION_Y = 1e4, VOID_REGION_Z = 1e4,
    VOID_REGION_CIRCLE = true, VOID_REGION_BOX = false, VOID_REGION_CENTER_SELF = true,
    VOID_REGION_CX = 0, VOID_REGION_CY = 0, VOID_REGION_CZ = 0,
    VOID_REGION_COLLAPSE = false, VOID_REGION_COLLAPSE_SPD = 50,
    VOID_REGION_NOTIFY_EXIT = false, VOID_REGION_SNAP_EDGE = true, VOID_LOG_POSITIONS = false,
    SMART_EVASION = false, SMART_EVASION_INF = false,
    EVASION_RANGE = 80, EVASION_THREAT_DIST = 40,
    EVASION_DODGE_POWER = 100, EVASION_COOLDOWN = 0.03,
    EVASION_PREDICT_TIME = 0.18, EVASION_NOTIFY = false,
    EVASION_MICRO_JITTER = true, EVASION_VERTICAL_SPIKE = true,
    EVASION_LAYERED = true, EVASION_THREAT_SCALE = true,
    VOID_KILLER_ENABLED = false, VOID_KILLER_DESYNC = true,
    VOID_KILLER_FAKE_GROUND = true, VOID_KILLER_FORCE_HITBOX = true,
    VOID_KILLER_HITBOX_SIZE = 500, VOID_KILLER_RANGE = 1e15,
    VOID_KILLER_AUTO_SHOOT = true, VOID_KILLER_FREEZE_TARGET = true,
    VOID_KILLER_SNAP_TO_MAP = true, VOID_KILLER_AUTO_AIM = true,
    VOID_KILLER_AIM_STRENGTH = 1, VOID_KILLER_NETWORK_OWN = true,
    VOID_KILLER_NO_CLIP = true,
}

local cfg = {
    orbitEnabled = false, orbitSpeed = 90, orbitDist = 8, orbitHeight = 0,
    orbitLerp = 0.3, orbitMode = "Circle", orbitPredict = false, orbitPredStr = 0.2,
    orbitFace = true, orbitLockDist = 999999999, orbitTarget = "Closest", orbitAxis = "XZ",
    orbitReverse = false, orbitRandRad = false, orbitRandMin = 5, orbitRandMax = 20,
    orbitYawOff = 0, orbitPitchOff = 0, orbitOffX = 0, orbitOffZ = 0,
    orbitHeightOscillate = false, orbitHeightOscAmp = 5, orbitHeightOscSpeed = 2,
    orbitSpeedRandom = false, orbitSpeedRandMin = 20, orbitSpeedRandMax = 200,
    orbitDistPulse = false, orbitDistPulseAmp = 5, orbitDistPulseSpeed = 1,
    orbitZigzag = false, orbitZigzagAmp = 3, orbitZigzagFreq = 4,
    orbitSnapBack = false, orbitSnapInterval = 0.5,
    orbitAntiFling = true, orbitVelZero = true, orbitPhaseThrough = true,
    orbitNetworkOwn = true, orbitNoClip = true, orbitMassless = true,
    orbitAutoDisable = false, orbitAutoDisableRange = 200, orbitSmartTarget = true,
    orbitSmoothCatch = true, orbitPredictMult = 1.0, orbitLookAhead = true,
    orbitHipHeight = 0, orbitWallClip = true, orbitIgnoreCollide = true,
    orbitAutoShoot = true, orbitShootCooldown = 0.01, orbitAttackRange = 1e15,
    orbitAutoAim = true, orbitAimStrength = 1,
    orbitInfiniteRange = true, orbitExpandedHitbox = true, orbitHitboxSize = 500,
    orbitFastTp = true, orbitFastTpCount = 20, orbitFastTpInterval = 0.001,
    orbitStickToTarget = true, orbitStickOffset = 2,
    orbitBypassAnticheat = true, orbitAntiKick = true,
}

local cfgDodge = {
    predEnabled = false, predRadius = 120, predDodgeDist = 80,
    predCooldown = 0.03, predThreshold = 300, predMult = 1,
    predLeadTime = 0.22, predShootDetect = true, predShootDot = 0.80,
    predShootDist = 100, predBulletSpd = 200, predReactTime = 0.06,
    predRaycast = true, predMultiPoint = true, predBackstep = true,
    predReactionLadder = true, predThreatScore = true,
    predAimVector = true, predCameraBone = true, predAnimDetect = true,
    predRemoteHook = true, predPredictiveAim = true, predPredictiveLead = 0.25,
    predInfiniteRange = true, predNotifyAnywhere = true,
    predRivalsMode = true, predRivalsHitboxExpand = true, predRivalsHitboxSize = 150,
    predSafeZone = true, predSafeZoneRadius = 500,
    predAutoShoot = true, predAutoShootRange = 1e15,
    predNoClip = true, predMassless = true,
    predBypassAnticheat = true, predAntiKick = true,
    predNetworkOwn = true, predVelZero = true,
    predAutoAim = true, predAimStrength = 1,
    predFastTp = true, predFastTpCount = 20, predFastTpInterval = 0.001,
    predStickToTarget = true, predStickOffset = 2,
    predPhaseThrough = true, predIgnoreCollide = true,
}

local antiBaitCFG = {
    enabled = false, velSpikeEnabled = true, velThreshold = 200,
    velDodgeDist = 100, flickerEnabled = true, flickerWindow = 0.3,
    flickerMinTps = 2, flickerTpDist = 10, dodgeCooldown = 0.02,
    dodgeMode = "Perpendicular", notifyOnDodge = true,
    dodgeOnShoot = true, shootLookThresh = 0.85,
    gunPredEnabled = true, gunPredDot = 0.80, gunPredVelMin = 30,
    gunPredDodgeDist = 100, gunPredCooldown = 0.02, gunPredLead = 0.18,
    baitEnabled = true, baitStallTime = 0.08, baitStallChance = 0.4,
    baitFakeLock = true, baitFakeLockTime = 0.06,
    baitHookActivate = true, baitReactionWindow = 0.18,
    baitNotifyLabel = true, reScanInterval = 2,
    infiniteRange = true, infiniteRadius = 5e12,
    rivalsMode = true, rivalsRemoteScan = true,
    rivalsToolScan = true, rivalsAnimScan = true,
    antiBaitNoClip = true, antiBaitMassless = true,
    antiBaitVelZero = true, antiBaitNetworkOwn = true,
    antiBaitBypassAnticheat = true, antiBaitAntiKick = true,
    antiBaitFastTp = true, antiBaitFastTpCount = 20, antiBaitFastTpInterval = 0.001,
    antiBaitStickToTarget = true, antiBaitStickOffset = 2,
    antiBaitPhaseThrough = true, antiBaitIgnoreCollide = true,
    antiBaitAutoAim = true, antiBaitAimStrength = 1,
    antiBaitAutoShoot = true, antiBaitAutoShootRange = 1e15,
    antiBaitUniversalAim = true, antiBaitUniversalAnimation = true,
    antiBaitUniversalVelocity = true,
}

local rangeExtCFG = {
    enabled = false, range = 5e12, hitboxSize = 500, rivalsBreakSize = 2500,
    maxEnemies = 50, patchRaycast = true, patchWeapon = true, fovBoost = true,
    noClip = true, massless = true, networkOwn = true, velZero = true,
    autoShoot = true, autoShootRange = 1e15, autoAim = true, aimStrength = 1,
    bypassAnticheat = true, antiKick = true,
}

local translocCFG = {
    enabled = false, frequency = 512, offsetDist = 1e15, offsetMode = "Ahead",
    offsetY = 0, jitter = true, jitterAmp = 500,
    wavePattern = false, waveFreq = 1, waveAmp = 100,
    pingPong = false, cascadeOffset = true, cascadeStep = 500,
    pulse = false, pulseSpeed = 1, pulseAmp = 200,
    spinFake = false, spinFakeSpeed = 360,
    layers = 10, fakeVel = true, fakeVelMag = 1e15,
    snapBack = true, translocVelZero = true, translocNoClip = true,
    networkOwnerFix = true, burstMode = false, burstCount = 3, burstInterval = 0.001,
    autoDodge = false, autoDodgeRadius = 30,
    randomFrequency = false, freqMin = 100, freqMax = 1000,
    diagonalAngle = 45, altVertAmp = 200,
    orbitSpeed = 90, orbitRadius = 50,
    zoneEscapeRadius = 1e15,
}

local antiTranslocCFG = {
    enabled = false, detectRadius = 100, minTps = 3, mode = "Evade",
    evadeDist = 80, evadeCooldown = 0.05, multiDodge = true, multiDodgeCount = 3,
    counterTeleport = false, spinEvade = false, spinEvadeSpeed = 360,
    freezeOnDetect = false, freezeDuration = 0.15,
    noClip = true, massless = true, networkOwn = true,
}

local velDesyncCFG = {
    enabled = false, intensity = 50, angle = 90, jitter = 20,
    multiVector = false, vectorCount = 3, oscillate = false,
    oscillateFreq = 2, oscillateAmp = 100, noise = true, noiseScale = 0.3,
    spike = false, spikeInterval = 0.5, spikeMag = 1e14,
    invert = false, invertInterval = 1,
    restore = true, networkOwn = true,
}

local slingCFG = {
    enabled = false, mode = "Follow", targetMode = "Closest",
    hideAvatar = true, autoShoot = true,
    stickHeight = 2,
    attackRange = 1e15, shotCooldown = 0.01,
    useTargetVel = true,
    fastTpSpeed = 0.005, fastTpOffset = 1.5,
    fastTpJitter = 1, fastTpMulti = true, fastTpCount = 5,
    fastTpPenetrate = true, fastTpRandAng = true, rushCooldown = 0.01,
    followLerp = 0.5, followDistance = 2, followHeight = 2,
    followPredict = true, followLead = 0.15,
    stalkDistance = 6, stalkHeight = 3, stalkBehind = true,
    hoverHeight = 8, hoverBob = true, hoverBobAmp = 1, hoverBobSpeed = 2,
    hideTransparency = 1, hideAccessories = true,
    rivalsMode = true, rivalsInfiniteRange = true,
    rivalsRange = 1e15, rivalsAutoShoot = true,
    rivalsHitboxExpand = true, rivalsHitboxSize = 500,
    rivalsNetworkOwner = true, rivalsFastTp = true,
    rivalsFastTpCount = 20, rivalsFastTpInterval = 0.001,
    rivalsPositionLock = true,
    noTpMode = true, noTpRange = 1e15,
    noTpHitboxSize = 2000, noTpAutoShoot = true,
    noTpAimAssist = true, noTpNetworkOwner = true,
    noTpSilentAim = true, noTpOriginSpoof = true,
    noTpRaycastPatch = true, noTpWeaponRange = 1e15,
    noTpPingComp = true, noTpTargetLock = true,
    noTpShotRedirect = true, noTpLookVector = true,
    noTpSpread = 0, noTpRecoil = 0,
    noTpVelocityComp = true, noTpGravityComp = true,
    noTpInfiniteRange = true, noTpInstantHit = true,
    noTpHitscanOverride = true, noTpWallBang = true,
    noTpProjectileFollow = true, noTpSpoofSelf = true,
    slingNoClip = true, slingMassless = true,
    slingAntiFling = true, slingVelZero = true,
    slingPhaseThrough = true, slingIgnoreCollide = true,
    slingHipHeight = 0,
    slingAutoAim = true, slingAimStrength = 1,
    slingAutoShootAccurate = true, slingTargetLock = true,
    slingAntiKick = true, slingBypassAnticheat = true,
    slingFastTp = true, slingFastTpCount = 20, slingFastTpInterval = 0.001,
    slingStickToTarget = true, slingStickOffset = 2,
    slingInfiniteRange = true,
    -- legacy compat
    noTpRange = 1e15, randRadius = 10, orbitRadius = 6, orbitSpeed = 180,
    targetStickOffset = 2,
}

local aaSettings = {
    enabled = false, mode = "RandomSpin", speed = 5000,
    angle = 90, randomSpeed = true, jitterPitch = true,
    pitchAngle = 45, yawAngle = 45, staticYaw = 90, staticPitch = 0,
    customYaw = 180, customPitch = 0, jitterYaw = true,
    fakeAngle = false, fakeYaw = 45, fakePitch = 0,
    microJitter = false, microJitterAmp = 5, microJitterSpeed = 30,
    desyncMode = false, desyncOffset = 180,
    rollEnabled = false, rollSpeed = 360,
    breatheEffect = false, breatheAmp = 3, breatheSpeed = 1,
    randomFlip = false, flipChance = 0.05,
    enhancedMode = true, enhancedSpinSpeed = 10000,
    enhancedJitterAmp = 90, enhancedJitterSpeed = 60,
    enhancedDesyncOffset = 270, enhancedRollSpeed = 720,
    enhancedBreatheAmp = 15, enhancedBreatheSpeed = 3,
    enhancedFlipChance = 0.25, enhancedMicroAmp = 45,
    enhancedMicroSpeed = 120, enhancedFakeYaw = 90, enhancedFakePitch = 45,
    multiAxisSpin = true, multiAxisX = true,
    multiAxisY = true, multiAxisZ = true,
    multiAxisSpeedX = 3600, multiAxisSpeedY = 5400, multiAxisSpeedZ = 2700,
    chaosMode = true, chaosInterval = 0.05, chaosMaxAngle = 180,
    lookAtRandom = true, lookAtRandomInterval = 0.1,
    aaNoClip = true, aaMassless = true,
    aaAntiFling = true, aaVelZero = true,
    aaNetworkOwn = true, aaPhaseThrough = true,
    aaIgnoreCollide = true, aaHipHeight = 0,
    aaSpinAxisLock = false, aaSpinAxisLockAxis = "Y",
    aaSmoothInterp = true, aaSmoothSpeed = 0.9,
    aaTargetDistraction = false, aaDistractionChance = 0.15,
    aaBypassAnticheat = true, aaAntiKick = true,
    aaFastTp = true, aaFastTpCount = 20, aaFastTpInterval = 0.001,
    aaStickToTarget = true, aaStickOffset = 2,
    aaAutoAim = true, aaAimStrength = 1,
    aaAutoShoot = true, aaAutoShootRange = 1e15,
    aaInfiniteRange = true,
    -- legacy compat
    jitterAmp = 180, jitterFreq = 30, staticRoll = 0, breathe = false,
}

local rotorCFG = {
    enabled     = false,
    mode        = "Binary",   -- Binary | MultiStep | Random | Sine | PingPong
    angle       = 90,         -- max flip angle (degrees)
    speed       = 30,         -- flips/Hz per second
    steps       = 4,          -- MultiStep: divisions per cycle
    pitchMode   = "None",     -- None | Down | Up | Random
    pitchAngle  = 45,
    jitter      = false,      -- small random noise on top
    jitterAmp   = 10,
    smoothFactor= 0,          -- 0=instant flip, 0.9=very smooth
    -- internal state
    _timer      = 0,
    _stepIdx    = 0,
    _phase      = 0,
    _cur        = 0,
    _tgt        = 0,
}

local riotGodmodeCFG = {
    enabled = false, speed = 0.03, evadeRange = 30,
    spinSpeed = 180, avoidBullets = true, bulletDodge = 40,
    heightVariance = 10, groundSnap = false, phaseMode = false,
    phaseInterval = 0.02, spinAxis = "Y", randomAxis = false,
    maxJump = 200, minJump = 10, multiTp = false,
    multiTpCount = 3, multiTpDelay = 0.01,
    autoShoot = true, attackRange = 1e15, shootCooldown = 0.01,
    lastShot = 0, forceFaceTarget = true,
    rgNoClip = true, rgMassless = true, rgAntiFling = true,
    rgVelZero = true, rgNetworkOwn = true, rgPhaseThrough = true,
    rgIgnoreCollide = true, rgHipHeight = 0,
    rgAutoShootAccurate = true, rgAimStrength = 1,
    rgBypassAnticheat = true, rgAntiKick = true,
    rgFastTp = true, rgFastTpCount = 20, rgFastTpInterval = 0.001,
    rgStickToTarget = true, rgStickOffset = 2,
    rgAutoAim = true, rgInfiniteRange = true,
    -- legacy compat
    noClip = true, networkOwn = true,
}

local riotAbuserCFG = {
    enabled = false, mode = "Stick", height = 3, forward = 0, right = 0, down = 0,
    autoShoot = true, attackRange = 1e15, orbitEnabled = false,
    orbitRadius = 5, orbitSpeed = 200, orbitHeight = 2,
    spinOnTarget = false, spinSpeed = 360, phaseOffset = 3,
    multiTarget = false, randomOffset = false, randomOffAmp = 2,
    bounceHeight = 5, bounceSpeed = 8, shootCooldown = 0.01,
    lastShot = 0, predictTarget = false, predictLead = 0.1,
    forceFaceTarget = true,
    raNoClip = true, raMassless = true, raAntiFling = true,
    raVelZero = true, raNetworkOwn = true, raPhaseThrough = true,
    raIgnoreCollide = true, raHipHeight = 0,
    raAutoShootAccurate = true, raAimStrength = 1,
    raBypassAnticheat = true, raAntiKick = true,
    raFastTp = true, raFastTpCount = 20, raFastTpInterval = 0.001,
    raStickToTarget = true, raStickOffset = 2,
    raAutoAim = true, raInfiniteRange = true,
    -- legacy compat
    noClip = true, networkOwn = true, phaseSpeed = 1e14,
}

-- ── Helper functions (extracted from LuaX) ───────────────────────────────────
local function getClosest()
    if not root then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local d = (root.Position - hrp.Position).Magnitude
        if d < bestD then bestD = d; best = p end
    end
    return best
end

local function getTarget(mode)
    if mode == "Closest" then return getClosest() end
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    if #list == 0 then return nil end
    if mode == "Random" then return list[math.random(1, #list)]
    elseif mode == "Weakest" then
        table.sort(list, function(a, b)
            local ha = a.Character:FindFirstChildOfClass("Humanoid")
            local hb = b.Character:FindFirstChildOfClass("Humanoid")
            return (ha and ha.Health or 0) < (hb and hb.Health or 0)
        end)
        return list[1]
    elseif mode == "Strongest" then
        table.sort(list, function(a, b)
            local ha = a.Character:FindFirstChildOfClass("Humanoid")
            local hb = b.Character:FindFirstChildOfClass("Humanoid")
            return (ha and ha.Health or 0) > (hb and hb.Health or 0)
        end)
        return list[1]
    end
    return list[1]
end

local function AddBindableToggle(group, flag, text, default, callback)
    local toggle = group:AddToggle(flag, { Text = text, Default = default or false, Callback = callback })
    toggle:AddKeyPicker(flag .. "Key", { Default = "None", Mode = "Toggle", Text = text, SyncToggleState = true, NoUI = false })
    return toggle
end

local function predictPos(hrp, lead)
    if not hrp then return Vector3.zero end
    local vel = hrp.AssemblyLinearVelocity
    local grav = Vector3.new(0, -workspace.Gravity * 0.5, 0)
    return hrp.Position + vel * lead + grav * (lead * lead * 0.5)
end

local function applyNoClip(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = false; part.Massless = true end)
        end
    end
end

local function setNetworkOwnerLocal(hrp)
    if not hrp then return end
    pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
end

local function aimAtTarget(myHrp, targetPos)
    if not myHrp then return end
    local dir = (targetPos - myHrp.Position)
    if dir.Magnitude < 0.1 then return end
    pcall(function()
        myHrp.CFrame = CFrame.new(myHrp.Position, myHrp.Position + Vector3.new(dir.X, 0, dir.Z))
    end)
end

local function fireTool()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        task.wait(0.02)
        pcall(function() tool:Deactivate() end)
    end
end

-- ── VoidSpam engine (extracted from LuaX) ────────────────────────────────────
local voidElapsed = 0
local voidPos = Vector3.zero
local intendedVoidPos = Vector3.zero
local voidStartTime = 0
local voidAutoReenableTime = 0
local voidRegionCurrentRadius = nil
local voidRegionLastIn = true
local smartLastDodge = 0
local voidKillerTargets = {}

local function clampToRegion(pos)
    if not CFG.VOID_STAY_IN_REGION then return pos end
    local cx = CFG.VOID_REGION_CENTER_SELF and (root and root.Position.X or 0) or CFG.VOID_REGION_CX
    local cy = CFG.VOID_REGION_CENTER_SELF and (root and root.Position.Y or 0) or CFG.VOID_REGION_CY
    local cz = CFG.VOID_REGION_CENTER_SELF and (root and root.Position.Z or 0) or CFG.VOID_REGION_CZ
    local r = voidRegionCurrentRadius or math.max(CFG.VOID_REGION_X, CFG.VOID_REGION_Y, CFG.VOID_REGION_Z)
    if CFG.VOID_REGION_COLLAPSE and voidRegionCurrentRadius then
        voidRegionCurrentRadius = math.max(0, voidRegionCurrentRadius - CFG.VOID_REGION_COLLAPSE_SPD * 0.016)
        r = voidRegionCurrentRadius
    end
    if CFG.VOID_REGION_CIRCLE then
        local d = Vector3.new(pos.X - cx, 0, pos.Z - cz).Magnitude
        if d > r then
            if CFG.VOID_REGION_NOTIFY_EXIT and voidRegionLastIn then Notify("Left region!", 2) end
            voidRegionLastIn = false
            if CFG.VOID_REGION_SNAP_EDGE then
                local dir = Vector3.new(pos.X - cx, 0, pos.Z - cz).Unit
                pos = Vector3.new(cx + dir.X * r, pos.Y, cz + dir.Z * r)
            end
        else
            voidRegionLastIn = true
        end
    elseif CFG.VOID_REGION_BOX then
        local hx, hy, hz = CFG.VOID_REGION_X / 2, CFG.VOID_REGION_Y / 2, CFG.VOID_REGION_Z / 2
        pos = Vector3.new(
            math.clamp(pos.X, cx - hx, cx + hx),
            math.clamp(pos.Y, cy - hy, cy + hy),
            math.clamp(pos.Z, cz - hz, cz + hz)
        )
    end
    return pos
end

local function getTpEverywherePosition()
    local vp = Camera.ViewportSize
    local r = math.random()
    local sx, sy
    if r < CFG.TP_CORNER_WEIGHT then
        local corners = { Vector2.new(0, 0), Vector2.new(vp.X, 0), Vector2.new(0, vp.Y), Vector2.new(vp.X, vp.Y) }
        local c = corners[math.random(1, 4)]
        sx = c.X; sy = c.Y
    elseif r < CFG.TP_CORNER_WEIGHT + CFG.TP_EDGE_WEIGHT then
        if math.random() < 0.5 then sx = math.random() < 0.5 and 0 or vp.X; sy = math.random() * vp.Y
        else sx = math.random() * vp.X; sy = math.random() < 0.5 and 0 or vp.Y end
    else
        sx = math.random() * vp.X; sy = math.random() * vp.Y
    end
    sx = sx + (math.random() - 0.5) * CFG.TP_SCREEN_JITTER * vp.X
    sy = sy + (math.random() - 0.5) * CFG.TP_SCREEN_JITTER * vp.Y
    if CFG.TP_SCREEN_CLAMP then sx = math.clamp(sx, 0, vp.X); sy = math.clamp(sy, 0, vp.Y) end
    local dist = CFG.TP_RAND_ENABLED and (CFG.TP_RAND_MIN + math.random() * (CFG.TP_RAND_MAX - CFG.TP_RAND_MIN)) or CFG.RADIUS
    if CFG.TP_NEG_BIAS and math.random() < 0.5 then dist = -math.abs(dist) end
    if CFG.TP_VIEWPORT_RAY then
        local ray = Camera:ViewportPointToRay(sx, sy, math.abs(dist))
        local p = ray.Origin + ray.Direction * math.abs(dist)
        if CFG.TP_VERT_SPIKE then
            local vm = CFG.TP_VERT_MULT_MIN + math.random() * (CFG.TP_VERT_MULT_MAX - CFG.TP_VERT_MULT_MIN)
            p = p + Vector3.new(0, math.abs(dist) * vm * (math.random() < 0.5 and 1 or -1), 0)
        end
        return p
    end
    local baseX = CFG.BASE_X + (math.random() - 0.5) * CFG.RADIUS * 2
    local baseZ = CFG.BASE_Z + (math.random() - 0.5) * CFG.RADIUS * 2
    local baseY = CFG.BASE_Y + (math.random() - 0.5) * CFG.RADIUS * 2
    return Vector3.new(baseX, baseY, baseZ)
end

local function stepVoid(dt)
    if not root then return end
    local m = CFG.VOID_METHOD
    if m == "Drift" then
        voidPos = voidPos + Vector3.new(
            (math.random() - 0.5) * CFG.SPEED * dt,
            (math.random() - 0.5) * CFG.SPEED * dt,
            (math.random() - 0.5) * CFG.SPEED * dt
        )
    elseif m == "Chaos" then
        voidPos = Vector3.new(
            voidPos.X * CFG.CHAOS + (math.random() - 0.5) * CFG.SPEED,
            voidPos.Y * CFG.CHAOS + (math.random() - 0.5) * CFG.SPEED,
            voidPos.Z * CFG.CHAOS + (math.random() - 0.5) * CFG.SPEED
        )
    elseif m == "Loop" then
        voidElapsed = voidElapsed + dt
        local a = voidElapsed * CFG.VOID_ORBIT_SPEED
        voidPos = Vector3.new(
            CFG.BASE_X + math.cos(math.rad(a)) * CFG.RADIUS,
            CFG.BASE_Y,
            CFG.BASE_Z + math.sin(math.rad(a)) * CFG.RADIUS
        )
    elseif m == "Spiral" then
        voidElapsed = voidElapsed + dt
        local a = voidElapsed * CFG.VOID_ORBIT_SPEED
        local rr = math.min(voidElapsed * 100, CFG.RADIUS)
        voidPos = Vector3.new(CFG.BASE_X + math.cos(math.rad(a)) * rr, CFG.BASE_Y + voidElapsed * 5, CFG.BASE_Z + math.sin(math.rad(a)) * rr)
    elseif m == "Quantum" then
        voidPos = Vector3.new(
            CFG.TP_MIN_STUDS + math.random() * (CFG.TP_MAX_STUDS - CFG.TP_MIN_STUDS),
            CFG.VOID_Y_MIN + math.random() * (CFG.VOID_Y_MAX - CFG.VOID_Y_MIN),
            CFG.TP_MIN_STUDS + math.random() * (CFG.TP_MAX_STUDS - CFG.TP_MIN_STUDS)
        )
    elseif m == "TP Everywhere" then
        voidPos = getTpEverywherePosition()
    elseif m == "OrbitTarget" then
        local t = getClosest()
        if t and t.Character then
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                voidElapsed = voidElapsed + dt
                local a = voidElapsed * CFG.VOID_ORBIT_SPEED
                voidPos = hrp.Position + Vector3.new(math.cos(math.rad(a)) * CFG.RADIUS, 0, math.sin(math.rad(a)) * CFG.RADIUS)
            end
        end
    end
    intendedVoidPos = voidPos
end

local function runVoidKiller(dt)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if CFG.VOID_KILLER_SNAP_TO_MAP then
            local res = workspace:Raycast(hrp.Position, Vector3.new(0, -1000, 0))
            if res then pcall(function() hrp.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end) end
        end
        if CFG.VOID_KILLER_FREEZE_TARGET then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
        end
        if CFG.VOID_KILLER_FORCE_HITBOX then
            pcall(function() hrp.Size = Vector3.new(CFG.VOID_KILLER_HITBOX_SIZE, CFG.VOID_KILLER_HITBOX_SIZE, CFG.VOID_KILLER_HITBOX_SIZE) end)
        end
        if CFG.VOID_KILLER_NETWORK_OWN then setNetworkOwnerLocal(hrp) end
        if CFG.VOID_KILLER_NO_CLIP and p.Character then applyNoClip(p.Character) end
        if CFG.VOID_KILLER_AUTO_SHOOT and root then
            if (root.Position - hrp.Position).Magnitude < CFG.VOID_KILLER_RANGE then
                if CFG.VOID_KILLER_AUTO_AIM then aimAtTarget(root, hrp.Position) end
                fireTool()
            end
        end
    end
end

local function lockToVoid(dt)
    if not root then return end
    stepVoid(dt)
    voidPos = clampToRegion(voidPos)
    pcall(function()
        root.CFrame = CFrame.new(voidPos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function startVoid()
    killConn("void")
    voidElapsed = 0; voidStartTime = tick()
    voidRegionCurrentRadius = nil; voidRegionLastIn = true
    local hrp = root
    if hrp then voidPos = hrp.Position; intendedVoidPos = voidPos end
    conns.void = RunService.Heartbeat:Connect(function(dt)
        if not CFG.VOID_ENABLED then
            if CFG.VOID_AUTO_REENABLE and tick() > voidAutoReenableTime then
                voidAutoReenableTime = tick() + 0.5; CFG.VOID_ENABLED = true
            else killConn("void"); return end
        end
        voidElapsed = voidElapsed + dt
        lockToVoid(dt)
        if CFG.VOID_KILLER_ENABLED then runVoidKiller(dt) end
    end)
end

local function stopVoid() killConn("void"); CFG.VOID_ENABLED = false end

-- ── Orbit engine (extracted from LuaX) ───────────────────────────────────────
local orbitAngle = 0
local orbitSnapT = 0
local orbitPulseT = 0
local orbitOscT = 0

local function startOrbit()
    killConn("orbit")
    orbitAngle = 0; orbitSnapT = 0; orbitPulseT = 0; orbitOscT = 0
    conns.orbit = RunService.Heartbeat:Connect(function(dt)
        if not cfg.orbitEnabled then killConn("orbit"); return end
        if not root then return end
        local target = getTarget(cfg.orbitTarget)
        if not target or not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if cfg.orbitAutoDisable and (root.Position - hrp.Position).Magnitude > cfg.orbitAutoDisableRange then return end
        if cfg.orbitNoClip and LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        if cfg.orbitNetworkOwn then setNetworkOwnerLocal(root) end
        local spd = cfg.orbitSpeedRandom and (cfg.orbitSpeedRandMin + math.random() * (cfg.orbitSpeedRandMax - cfg.orbitSpeedRandMin)) or cfg.orbitSpeed
        if cfg.orbitReverse then spd = -spd end
        orbitAngle = orbitAngle + math.rad(spd) * dt
        local dist = cfg.orbitDist
        if cfg.orbitRandRad then dist = cfg.orbitRandMin + math.random() * (cfg.orbitRandMax - cfg.orbitRandMin) end
        if cfg.orbitDistPulse then orbitPulseT = orbitPulseT + dt; dist = dist + math.sin(orbitPulseT * cfg.orbitDistPulseSpeed * 2 * math.pi) * cfg.orbitDistPulseAmp end
        local h = cfg.orbitHeight
        if cfg.orbitHeightOscillate then orbitOscT = orbitOscT + dt; h = h + math.sin(orbitOscT * cfg.orbitHeightOscSpeed * 2 * math.pi) * cfg.orbitHeightOscAmp end
        local targetPos
        local m = cfg.orbitMode
        if m == "Circle" then
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist + cfg.orbitOffX, h, math.sin(orbitAngle) * dist + cfg.orbitOffZ)
        elseif m == "Figure 8" then
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist, h + math.sin(orbitAngle * 2) * dist * 0.5, math.sin(orbitAngle) * dist)
        elseif m == "Ellipse" then
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist * 1.5, h, math.sin(orbitAngle) * dist * 0.75)
        elseif m == "Spiral In" then
            local rr = math.max(0, dist - orbitAngle * 0.1)
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * rr, h + orbitAngle * 0.5, math.sin(orbitAngle) * rr)
        elseif m == "Spiral Out" then
            local rr = dist + orbitAngle * 0.1
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * rr, h, math.sin(orbitAngle) * rr)
        elseif m == "Bounce" then
            local bh = math.abs(math.sin(orbitAngle * 2)) * dist
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist, bh, math.sin(orbitAngle) * dist)
        elseif m == "Lemniscate" then
            local d2 = 1 + math.sin(orbitAngle) ^ 2
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) / d2 * dist, h, math.sin(orbitAngle) * math.cos(orbitAngle) / d2 * dist)
        elseif m == "Infinity" then
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist, h + math.sin(orbitAngle * 2) * dist * 0.3, math.sin(orbitAngle * 2) * dist * 0.5)
        elseif m == "RandomOrbit" then
            orbitSnapT = orbitSnapT + dt
            if orbitSnapT > cfg.orbitSnapInterval then orbitSnapT = 0; targetPos = hrp.Position + Vector3.new((math.random()-0.5)*dist*2, h, (math.random()-0.5)*dist*2) end
            if not targetPos then targetPos = root.Position end
        else
            targetPos = hrp.Position + Vector3.new(math.cos(orbitAngle) * dist, h, math.sin(orbitAngle) * dist)
        end
        if cfg.orbitZigzag then
            local zz = math.sin(orbitAngle * cfg.orbitZigzagFreq) * cfg.orbitZigzagAmp
            targetPos = targetPos + Vector3.new(zz, 0, 0)
        end
        if cfg.orbitFastTp then
            for _ = 1, cfg.orbitFastTpCount do
                pcall(function() root.CFrame = CFrame.new(targetPos); root.AssemblyLinearVelocity = Vector3.zero end)
                if cfg.orbitFastTpInterval > 0 then task.wait(cfg.orbitFastTpInterval) end
            end
        else
            local newCF = cfg.orbitFace and CFrame.new(targetPos, hrp.Position) or CFrame.new(targetPos)
            pcall(function() root.CFrame = newCF; root.AssemblyLinearVelocity = Vector3.zero end)
        end
        if cfg.orbitAutoShoot then
            if (root.Position - hrp.Position).Magnitude < cfg.orbitAttackRange then
                if cfg.orbitAutoAim then aimAtTarget(root, hrp.Position) end
                fireTool()
            end
        end
    end)
end

local function stopOrbit() killConn("orbit"); cfg.orbitEnabled = false end

-- ── PredictionV2 (extracted from LuaX) ───────────────────────────────────────
local predShootCD = {}
local hookedActivate = {}

local function hookToolActivate(tool)
    if hookedActivate[tool] then return end
    hookedActivate[tool] = true
    pcall(function()
        tool.Activated:Connect(function()
            predShootCD[tool] = tick()
        end)
    end)
end

local function watchAllTools()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        for _, obj in ipairs(p.Character:GetDescendants()) do
            if obj:IsA("Tool") then hookToolActivate(obj) end
        end
        p.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then hookToolActivate(c) end end)
    end
end

local function perpDodgeDir(fromPos, myPos)
    local d = (myPos - fromPos)
    if d.Magnitude < 0.01 then return Vector3.new(1, 0, 0) end
    d = d.Unit
    local up = Vector3.new(0, 1, 0)
    local perp = d:Cross(up)
    if perp.Magnitude < 0.01 then perp = d:Cross(Vector3.new(1, 0, 0)) end
    return perp.Unit * (math.random() < 0.5 and 1 or -1)
end

local function buildThreatMap(myPos)
    local threats = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local dist = (myPos - hrp.Position).Magnitude
        if not cfgDodge.predInfiniteRange and dist > cfgDodge.predRadius then continue end
        local vel = hrp.AssemblyLinearVelocity
        local toMe = (myPos - hrp.Position)
        local aimDot = 0
        if vel.Magnitude > 1 then aimDot = vel.Unit:Dot(toMe.Magnitude > 0.1 and toMe.Unit or Vector3.zero) end
        local score = aimDot * 2 + (1 / math.max(dist, 1)) * 10
        if predShootCD[p] and (tick() - predShootCD[p]) < cfgDodge.predReactTime then score = score + 5 end
        table.insert(threats, { player = p, hrp = hrp, dist = dist, score = score, aimDot = aimDot })
    end
    table.sort(threats, function(a, b) return a.score > b.score end)
    return threats
end

local function startPredictionV2()
    killConn("pred")
    watchAllTools()
    conns.pred = RunService.Heartbeat:Connect(function(dt)
        if not cfgDodge.predEnabled then killConn("pred"); return end
        if not root then return end
        if cfgDodge.predNoClip and LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        if cfgDodge.predNetworkOwn then setNetworkOwnerLocal(root) end
        local myPos = root.Position
        local threats = buildThreatMap(myPos)
        if #threats == 0 then return end
        local top = threats[1]
        if top.score < cfgDodge.predThreshold * 0.001 then return end
        local dodgeDir = cfgDodge.predAimVector and perpDodgeDir(top.hrp.Position, myPos) or (myPos - top.hrp.Position).Unit
        if cfgDodge.predBackstep then dodgeDir = dodgeDir + (myPos - top.hrp.Position).Unit * 0.5 end
        local dodgeDist = cfgDodge.predDodgeDist * cfgDodge.predMult
        local newPos = myPos + dodgeDir * dodgeDist
        if cfgDodge.predFastTp then
            for _ = 1, cfgDodge.predFastTpCount do
                pcall(function() root.CFrame = CFrame.new(newPos); root.AssemblyLinearVelocity = Vector3.zero end)
            end
        else
            pcall(function() root.CFrame = CFrame.new(newPos); root.AssemblyLinearVelocity = Vector3.zero end)
        end
        if cfgDodge.predAutoShoot and top.hrp then
            if (root.Position - top.hrp.Position).Magnitude < cfgDodge.predAutoShootRange then
                if cfgDodge.predAutoAim then aimAtTarget(root, top.hrp.Position) end
                fireTool()
            end
        end
        task.wait(cfgDodge.predCooldown)
    end)
end

local function stopPredictionV2() killConn("pred"); cfgDodge.predEnabled = false end

-- ── AntiBaitV2 (extracted from LuaX) ─────────────────────────────────────────
local antiBaitData = {}
local lastAntiBaitDodge = 0
local baitActive = {}

local function getDodgeDir(threatPos)
    if not root then return Vector3.new(1, 0, 0) end
    local myPos = root.Position
    local m = antiBaitCFG.dodgeMode
    if m == "Away" then return (myPos - threatPos).Unit
    elseif m == "Perpendicular" then return perpDodgeDir(threatPos, myPos)
    else return Vector3.new(math.random()-0.5, 0, math.random()-0.5).Unit end
end

local function doDodge(player, reason)
    if not root then return end
    local now = tick()
    if now - lastAntiBaitDodge < antiBaitCFG.dodgeCooldown then return end
    lastAntiBaitDodge = now
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = getDodgeDir(hrp.Position)
    if antiBaitCFG.notifyOnDodge then Notify("AntiBait: dodge (" .. reason .. ")", 1) end
    for _ = 1, 3 do
        pcall(function()
            root.CFrame = CFrame.new(root.Position + dir * antiBaitCFG.velDodgeDist)
            root.AssemblyLinearVelocity = Vector3.zero
        end)
        RunService.Heartbeat:Wait()
    end
end

local function baitStall(player)
    if not root then return end
    local savedCF = root.CFrame
    task.wait(antiBaitCFG.baitStallTime)
    pcall(function() root.CFrame = savedCF; root.AssemblyLinearVelocity = Vector3.zero end)
end

local function doBaitCounter(player, source)
    if baitActive[player] then return end
    baitActive[player] = true
    if antiBaitCFG.baitNotifyLabel then Notify("AntiBait: bait detected (" .. source .. ")", 1) end
    local window = antiBaitCFG.baitReactionWindow
    task.delay(window, function() baitActive[player] = nil end)
    if antiBaitCFG.baitStallChance > math.random() then task.spawn(baitStall, player) end
    task.spawn(doDodge, player, "bait:" .. source)
end

local function startAntiBaitV2()
    killConn("antiBait")
    antiBaitData = {}; baitActive = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then antiBaitData[p] = { positions = {}, times = {} } end
    end
    conns.antiBait = RunService.Heartbeat:Connect(function(dt)
        if not antiBaitCFG.enabled then killConn("antiBait"); return end
        if not root then return end
        if antiBaitCFG.antiBaitNoClip and LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        if antiBaitCFG.antiBaitNetworkOwn then setNetworkOwnerLocal(root) end
        local now = tick()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local data = antiBaitData[p]
            if not data then antiBaitData[p] = { positions = {}, times = {} }; data = antiBaitData[p] end
            table.insert(data.positions, hrp.Position)
            table.insert(data.times, now)
            while #data.times > 0 and now - data.times[1] > antiBaitCFG.flickerWindow do
                table.remove(data.positions, 1); table.remove(data.times, 1)
            end
            if antiBaitCFG.velSpikeEnabled then
                if hrp.AssemblyLinearVelocity.Magnitude > antiBaitCFG.velThreshold then doBaitCounter(p, "vel") end
            end
            if antiBaitCFG.flickerEnabled and #data.positions >= antiBaitCFG.flickerMinTps then
                local totalDist = 0
                for i = 2, #data.positions do totalDist = totalDist + (data.positions[i] - data.positions[i-1]).Magnitude end
                if totalDist > antiBaitCFG.flickerTpDist * antiBaitCFG.flickerMinTps then doBaitCounter(p, "flicker") end
            end
        end
    end)
end

local function stopAntiBaitV2() killConn("antiBait"); antiBaitCFG.enabled = false end

-- ── RangeExt (extracted from LuaX) ───────────────────────────────────────────
local rangeExtHB = nil
local rangeExtOrigSizes = {}

local function rangeExtApplyHitbox(plr)
    if not plr.Character then return end
    for _, part in ipairs(plr.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if not rangeExtOrigSizes[part] then rangeExtOrigSizes[part] = part.Size end
            pcall(function()
                part.Size = Vector3.new(rangeExtCFG.hitboxSize, rangeExtCFG.hitboxSize, rangeExtCFG.hitboxSize)
                part.Transparency = 0.9; part.CanCollide = false; part.Massless = true
            end)
        end
    end
end

local function rangeExtClearHitbox(plr)
    if not plr.Character then return end
    for _, part in ipairs(plr.Character:GetDescendants()) do
        if part:IsA("BasePart") and rangeExtOrigSizes[part] then
            pcall(function() part.Size = rangeExtOrigSizes[part] end)
            rangeExtOrigSizes[part] = nil
        end
    end
end

local function startRangeExt()
    if rangeExtHB then rangeExtHB:Disconnect() end
    rangeExtOrigSizes = {}
    rangeExtHB = RunService.Heartbeat:Connect(function()
        if not rangeExtCFG.enabled then stopRangeExt(); return end
        if not root then return end
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then continue end
            count = count + 1
            if count > rangeExtCFG.maxEnemies then break end
            rangeExtApplyHitbox(p)
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and rangeExtCFG.autoShoot then
                if (root.Position - hrp.Position).Magnitude < rangeExtCFG.range then
                    if rangeExtCFG.autoAim then aimAtTarget(root, hrp.Position) end
                    fireTool()
                end
            end
        end
        conns.rangeExt = rangeExtHB
    end)
end

local function stopRangeExt()
    if rangeExtHB then rangeExtHB:Disconnect(); rangeExtHB = nil end
    for _, p in ipairs(Players:GetPlayers()) do rangeExtClearHitbox(p) end
    rangeExtCFG.enabled = false; conns.rangeExt = nil
end

-- ── AntiTransloc (extracted from LuaX) ───────────────────────────────────────
local antiTranslocData = {}
local lastATDodge = 0
local freezeUntil = 0

local function initATData(p) antiTranslocData[p] = { positions = {}, times = {} } end

local function doAntiTransloc(player)
    if not root then return end
    local now = tick()
    if now - lastATDodge < antiTranslocCFG.evadeCooldown then return end
    lastATDodge = now
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local m = antiTranslocCFG.mode
    if m == "Freeze" then
        freezeUntil = now + antiTranslocCFG.freezeDuration
    elseif m == "Evade" then
        local dir = (root.Position - hrp.Position)
        if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) else dir = dir.Unit end
        for _ = 1, (antiTranslocCFG.multiDodge and antiTranslocCFG.multiDodgeCount or 1) do
            pcall(function() root.CFrame = CFrame.new(root.Position + dir * antiTranslocCFG.evadeDist); root.AssemblyLinearVelocity = Vector3.zero end)
            RunService.Heartbeat:Wait()
        end
    elseif m == "Predict" then
        local vel = hrp.AssemblyLinearVelocity
        local predicted = hrp.Position + vel * 0.2
        local away = (root.Position - predicted)
        if away.Magnitude > 0.1 then away = away.Unit end
        pcall(function() root.CFrame = CFrame.new(root.Position + away * antiTranslocCFG.evadeDist) end)
    end
end

local function startAntiTransloc()
    killConn("antiTransloc")
    antiTranslocData = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then initATData(p) end end
    conns.antiTransloc = RunService.Heartbeat:Connect(function(dt)
        if not antiTranslocCFG.enabled then killConn("antiTransloc"); return end
        if not root then return end
        if tick() < freezeUntil then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end); return end
        local now = tick()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local data = antiTranslocData[p]
            if not data then initATData(p); data = antiTranslocData[p] end
            table.insert(data.positions, hrp.Position)
            table.insert(data.times, now)
            while #data.times > 0 and now - data.times[1] > 0.5 do
                table.remove(data.positions, 1); table.remove(data.times, 1)
            end
            if #data.positions >= antiTranslocCFG.minTps then
                local tpCount = 0
                for i = 2, #data.positions do
                    if (data.positions[i] - data.positions[i-1]).Magnitude > antiTranslocCFG.detectRadius then tpCount = tpCount + 1 end
                end
                if tpCount >= antiTranslocCFG.minTps then doAntiTransloc(p) end
            end
        end
    end)
end

local function stopAntiTransloc() killConn("antiTransloc"); antiTranslocCFG.enabled = false end

-- ── VelDesync (extracted from LuaX) ──────────────────────────────────────────
local desyncHB = nil
local desyncRS = nil
local desyncRealVel = Vector3.zero
local desyncAngleAcc = 0
local desyncInvertTimer = 0
local desyncOscAcc = 0
local desyncBurstTimer = 0
local desyncInverted = false

local function startVelDesync()
    if desyncHB then desyncHB:Disconnect() end
    if desyncRS then desyncRS:Disconnect() end
    desyncRealVel = Vector3.zero; desyncAngleAcc = 0; desyncInvertTimer = 0
    desyncHB = RunService.Heartbeat:Connect(function(dt)
        if not velDesyncCFG.enabled then stopVelDesync(); return end
        if not root then return end
        desyncRealVel = root.AssemblyLinearVelocity
        local ang = math.rad(velDesyncCFG.angle)
        local intensity = velDesyncCFG.intensity
        if velDesyncCFG.invert then
            desyncInvertTimer = desyncInvertTimer + dt
            if desyncInvertTimer > velDesyncCFG.invertInterval then desyncInvertTimer = 0; desyncInverted = not desyncInverted end
            if desyncInverted then intensity = -intensity end
        end
        local fakeVel
        if velDesyncCFG.multiVector then
            fakeVel = Vector3.zero
            for i = 1, velDesyncCFG.vectorCount do
                local a = ang + math.rad(360 / velDesyncCFG.vectorCount * i)
                fakeVel = fakeVel + Vector3.new(math.cos(a) * intensity, 0, math.sin(a) * intensity)
            end
        else
            desyncAngleAcc = desyncAngleAcc + dt * 2
            fakeVel = Vector3.new(math.cos(ang + desyncAngleAcc) * intensity, 0, math.sin(ang + desyncAngleAcc) * intensity)
        end
        if velDesyncCFG.oscillate then
            desyncOscAcc = desyncOscAcc + dt
            fakeVel = fakeVel + Vector3.new(0, math.sin(desyncOscAcc * velDesyncCFG.oscillateFreq * 2 * math.pi) * velDesyncCFG.oscillateAmp, 0)
        end
        if velDesyncCFG.noise then
            fakeVel = fakeVel + Vector3.new((math.random()-0.5)*velDesyncCFG.noiseScale*intensity*2, 0, (math.random()-0.5)*velDesyncCFG.noiseScale*intensity*2)
        end
        if velDesyncCFG.spike then
            desyncBurstTimer = desyncBurstTimer + dt
            if desyncBurstTimer > velDesyncCFG.spikeInterval then
                desyncBurstTimer = 0
                fakeVel = fakeVel + Vector3.new((math.random()-0.5)*velDesyncCFG.spikeMag*2, 0, (math.random()-0.5)*velDesyncCFG.spikeMag*2)
            end
        end
        if velDesyncCFG.networkOwn then setNetworkOwnerLocal(root) end
        pcall(function() root.AssemblyLinearVelocity = fakeVel end)
    end)
    desyncRS = RunService.RenderStepped:Connect(function()
        if not velDesyncCFG.enabled or not root then return end
        if velDesyncCFG.restore then pcall(function() root.AssemblyLinearVelocity = desyncRealVel end) end
    end)
end

local function stopVelDesync()
    if desyncHB then desyncHB:Disconnect(); desyncHB = nil end
    if desyncRS then desyncRS:Disconnect(); desyncRS = nil end
    velDesyncCFG.enabled = false
end

-- ── Transloc (extracted from LuaX) ───────────────────────────────────────────
local translocConn = nil
local translocPreRender = nil
local translocRealCF = nil
local translocAcc = 0
local translocPingPongDir = 1
local translocWaveT = 0
local translocAltVert = 1
local translocPulseT = 0
local translocPingPongTimer = 0

local function getTranslocFakePos(realCF, index)
    local d = translocCFG.offsetDist
    local jmp = translocCFG.jitter and translocCFG.jitterAmp or 0
    local base = realCF.Position
    local ox, oy, oz = 0, 0, 0
    local m = translocCFG.offsetMode
    if translocCFG.wavePattern then translocWaveT = translocWaveT + 0.01; d = d + math.sin(translocWaveT * translocCFG.waveFreq * 2 * math.pi) * translocCFG.waveAmp end
    if translocCFG.pingPong then d = d * translocPingPongDir end
    if translocCFG.cascadeOffset and index then d = d + (index - 1) * translocCFG.cascadeStep end
    if translocCFG.pulse then translocPulseT = translocPulseT + 0.01; d = d + math.sin(translocPulseT * translocCFG.pulseSpeed * 2 * math.pi) * translocCFG.pulseAmp end
    if m == "Ahead" then
        local look = realCF.LookVector; ox = look.X * d; oz = look.Z * d; oy = translocCFG.offsetY
    elseif m == "Behind" then
        local look = realCF.LookVector; ox = -look.X * d; oz = -look.Z * d; oy = translocCFG.offsetY
    elseif m == "Perpendicular" then
        local right = realCF.RightVector
        local side = math.random() < 0.5 and 1 or -1
        ox = right.X * d * side; oz = right.Z * d * side; oy = translocCFG.offsetY
    elseif m == "Above" then
        ox = (math.random() - 0.5) * jmp; oy = math.abs(d) + translocCFG.offsetY; oz = (math.random() - 0.5) * jmp
    elseif m == "Below" then
        ox = (math.random() - 0.5) * jmp; oy = -math.abs(d) + translocCFG.offsetY; oz = (math.random() - 0.5) * jmp
    elseif m == "AboveBelow" then
        translocAltVert = -translocAltVert
        ox = (math.random() - 0.5) * jmp
        oy = translocAltVert * (math.abs(d) + translocCFG.altVertAmp) + translocCFG.offsetY
        oz = (math.random() - 0.5) * jmp
    elseif m == "MirrorX" then ox = -base.X + (math.random() - 0.5) * jmp; oy = translocCFG.offsetY; oz = (math.random() - 0.5) * jmp
    elseif m == "MirrorZ" then ox = (math.random() - 0.5) * jmp; oy = translocCFG.offsetY; oz = -base.Z + (math.random() - 0.5) * jmp
    elseif m == "Diagonal" then
        local ang = math.rad(translocCFG.diagonalAngle)
        ox = math.cos(ang) * d; oz = math.sin(ang) * d; oy = translocCFG.offsetY
    elseif m == "ScreenEdge" then
        local vp = Camera.ViewportSize
        local corners = { Vector2.new(0,0), Vector2.new(vp.X,0), Vector2.new(0,vp.Y), Vector2.new(vp.X,vp.Y) }
        local c = corners[math.random(1, 4)]
        local ray = Camera:ViewportPointToRay(c.X, c.Y, math.abs(d))
        return CFrame.new(ray.Origin)
    elseif m == "Orbit" then
        translocWaveT = translocWaveT + 0.02
        local ang = translocWaveT * math.rad(translocCFG.orbitSpeed)
        ox = math.cos(ang) * translocCFG.orbitRadius
        oz = math.sin(ang) * translocCFG.orbitRadius
        oy = translocCFG.offsetY
    elseif m == "ZoneEscape" then
        local dir = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
        return CFrame.new(base + dir * translocCFG.zoneEscapeRadius)
    end
    if translocCFG.spinFake then
        local spinAng = tick() * math.rad(translocCFG.spinFakeSpeed)
        local nx = ox * math.cos(spinAng) - oz * math.sin(spinAng)
        local nz = ox * math.sin(spinAng) + oz * math.cos(spinAng)
        ox = nx; oz = nz
    end
    return CFrame.new(base.X + ox, base.Y + oy, base.Z + oz)
end

local function startTransloc()
    if translocConn then translocConn:Disconnect() end
    if translocPreRender then translocPreRender:Disconnect() end
    translocRealCF = nil; translocPingPongDir = 1; translocWaveT = 0; translocAltVert = 1; translocPulseT = 0
    translocAcc = 0; translocPingPongTimer = 0
    if translocCFG.networkOwnerFix and root then pcall(function() root:SetNetworkOwner(LocalPlayer) end) end
    translocPreRender = RunService.PreRender:Connect(function()
        if not translocCFG.enabled or not root or not translocRealCF then return end
        if translocCFG.snapBack then
            root.CFrame = translocRealCF
            if translocCFG.translocVelZero then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
        end
    end)
    translocConn = RunService.Heartbeat:Connect(function(dt)
        if not translocCFG.enabled then stopTransloc(); return end
        if not root then return end
        if translocCFG.translocNoClip and LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        translocRealCF = root.CFrame
        translocAcc = translocAcc + dt
        translocPingPongTimer = translocPingPongTimer + dt
        if translocCFG.pingPong and translocPingPongTimer > 0.5 then translocPingPongTimer = 0; translocPingPongDir = -translocPingPongDir end
        if translocCFG.autoDodge then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer or not p.Character then continue end
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                if (hrp.Position - root.Position).Magnitude < translocCFG.autoDodgeRadius then
                    local dir = (root.Position - hrp.Position)
                    if dir.Magnitude > 0.01 then dir = dir.Unit end
                    pcall(function() root.CFrame = CFrame.new(root.Position + dir * 60); root.AssemblyLinearVelocity = Vector3.zero end)
                end
            end
        end
        local interval
        if translocCFG.randomFrequency then interval = 1 / (translocCFG.freqMin + math.random() * (translocCFG.freqMax - translocCFG.freqMin))
        else interval = 1 / math.max(translocCFG.frequency, 1) end
        if translocAcc < interval then return end
        translocAcc = translocAcc % interval
        local mt = getrawmetatable and getrawmetatable(root)
        local ni = mt and rawget(mt, "__newindex")
        local layerCount = math.max(translocCFG.layers, 1)
        local burstCount = translocCFG.burstMode and translocCFG.burstCount or 1
        for b = 1, burstCount do
            for i = 1, layerCount do
                local fcf = getTranslocFakePos(translocRealCF, i)
                local fv = Vector3.zero
                if translocCFG.fakeVel then
                    local mag = translocCFG.fakeVelMag
                    fv = Vector3.new((math.random()-0.5)*mag*2, (math.random()-0.5)*mag*2, (math.random()-0.5)*mag*2)
                end
                if ni then pcall(ni, root, "CFrame", fcf); pcall(ni, root, "AssemblyLinearVelocity", fv)
                else pcall(function() root.CFrame = fcf; root.AssemblyLinearVelocity = fv end) end
            end
            if b < burstCount then task.wait(translocCFG.burstInterval) end
        end
    end)
end

local function stopTransloc()
    if translocConn then translocConn:Disconnect(); translocConn = nil end
    if translocPreRender then translocPreRender:Disconnect(); translocPreRender = nil end
    translocCFG.enabled = false; translocRealCF = nil
end

-- ── SlingBypassV2 (extracted from LuaX) ──────────────────────────────────────
local slingConn = nil
local slingRealCF = nil
local slingLastShot = 0
local slingOrbAng = 0
local slingHoverT = 0
local avatarHiddenState = {}
local noTpOriginalSizes = {}

local function hideAvatar()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if avatarHiddenState[part] == nil then avatarHiddenState[part] = part.LocalTransparencyModifier end
            part.LocalTransparencyModifier = slingCFG.hideTransparency
        elseif part:IsA("Decal") or part:IsA("Texture") then
            if avatarHiddenState[part] == nil then avatarHiddenState[part] = part.Transparency end
            part.Transparency = 1
        elseif slingCFG.hideAccessories and part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                if avatarHiddenState[handle] == nil then avatarHiddenState[handle] = handle.LocalTransparencyModifier end
                handle.LocalTransparencyModifier = 1
            end
        end
    end
end

local function restoreAvatar()
    if not LocalPlayer.Character then return end
    for part, val in pairs(avatarHiddenState) do
        if part and part.Parent then
            if part:IsA("BasePart") then part.LocalTransparencyModifier = val or 0
            elseif part:IsA("Decal") or part:IsA("Texture") then part.Transparency = val or 0 end
        end
    end
    avatarHiddenState = {}
end

local function doSlingAutoShoot(target)
    if not slingCFG.autoShoot or not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not root then return end
    local now = tick()
    local range = slingCFG.rivalsInfiniteRange and slingCFG.rivalsRange or slingCFG.attackRange
    if (root.Position - hrp.Position).Magnitude < range and now - slingLastShot > slingCFG.shotCooldown then
        slingLastShot = now
        if slingCFG.slingAutoAim then aimAtTarget(root, hrp.Position) end
        fireTool()
    end
end

local function applyNoTpHitbox(target)
    if not target or not target.Character then return end
    for _, part in ipairs(target.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if not noTpOriginalSizes[part] then noTpOriginalSizes[part] = part.Size end
            pcall(function()
                part.Size = Vector3.new(slingCFG.noTpHitboxSize, slingCFG.noTpHitboxSize, slingCFG.noTpHitboxSize)
                part.Transparency = 0.9; part.CanCollide = false; part.Massless = true
            end)
        end
    end
end

local function restoreNoTpHitbox(target)
    if not target or not target.Character then return end
    for _, part in ipairs(target.Character:GetDescendants()) do
        if part:IsA("BasePart") and noTpOriginalSizes[part] then
            pcall(function() part.Size = noTpOriginalSizes[part] end)
            noTpOriginalSizes[part] = nil
        end
    end
end

local function startSlingBypassV2()
    if slingConn then slingConn:Disconnect() end
    slingRealCF = nil; slingOrbAng = 0; slingHoverT = 0
    slingConn = RunService.Heartbeat:Connect(function(dt)
        if not slingCFG.enabled then stopSlingBypassV2(); return end
        if not root then return end
        applyNoClip(LocalPlayer.Character)
        setNetworkOwnerLocal(root)
        slingRealCF = root.CFrame
        local target = getTarget(slingCFG.targetMode)
        if slingCFG.hideAvatar then hideAvatar() else restoreAvatar() end
        if slingCFG.noTpMode then
            if target and target.Character then applyNoTpHitbox(target); doSlingAutoShoot(target) end
            return
        end
        if not target or not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local m = slingCFG.mode
        local newPos
        if m == "Follow" then
            local dir = (hrp.Position - root.Position)
            if dir.Magnitude > slingCFG.followDist then newPos = hrp.Position - dir.Unit * slingCFG.followDist
            else newPos = root.Position end
        elseif m == "Stalk" then
            newPos = hrp.Position + (root.Position - hrp.Position).Unit * slingCFG.stalkDist
        elseif m == "Hover" then
            slingHoverT = slingHoverT + dt
            newPos = hrp.Position + Vector3.new(math.cos(slingHoverT) * slingCFG.hoverDist, slingCFG.hoverHeight, math.sin(slingHoverT) * slingCFG.hoverDist)
        elseif m == "FastTp" then
            for _ = 1, slingCFG.fastTpCount do
                pcall(function() root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0)); root.AssemblyLinearVelocity = Vector3.zero end)
                if slingCFG.fastTpInterval > 0 then task.wait(slingCFG.fastTpInterval) end
            end
        elseif m == "TargetStick" then
            newPos = hrp.Position + Vector3.new(0, slingCFG.targetStickOffset, 0)
        elseif m == "OrbitTarget" then
            slingOrbAng = slingOrbAng + math.rad(slingCFG.orbitSpeed) * dt
            newPos = hrp.Position + Vector3.new(math.cos(slingOrbAng)*slingCFG.orbitRadius, 0, math.sin(slingOrbAng)*slingCFG.orbitRadius)
        elseif m == "RandomAroundTarget" then
            newPos = hrp.Position + Vector3.new((math.random()-0.5)*slingCFG.randRadius*2, 0, (math.random()-0.5)*slingCFG.randRadius*2)
        end
        if newPos then pcall(function() root.CFrame = CFrame.new(newPos); root.AssemblyLinearVelocity = Vector3.zero end) end
        doSlingAutoShoot(target)
    end)
end

local function stopSlingBypassV2()
    if slingConn then slingConn:Disconnect(); slingConn = nil end
    restoreAvatar(); slingCFG.enabled = false
end

-- ── AntiAim (full LuaX implementation) ───────────────────────────────────────
local aaAngAcc = 0
local aaJitterT = 0
local aaRandTimer = 0
local aaRandYaw = 0
local aaBreatheT = 0
local aaChaosTimer = 0
local aaLookRandTimer = 0
local aaMultiAccX = 0
local aaMultiAccY = 0
local aaMultiAccZ = 0
local aaFlipTimer = 0
local aaFlipDir = 1
local aaDesyncAcc = 0
local aaRollAcc = 0
local aaCurrentSpeedMult = 1

local function startAntiAim()
    killConn("antiAim")
    aaAngAcc = 0; aaJitterT = 0; aaRandTimer = 0; aaRandYaw = 0; aaBreatheT = 0
    aaChaosTimer = 0; aaLookRandTimer = 0; aaMultiAccX = 0; aaMultiAccY = 0; aaMultiAccZ = 0
    aaFlipTimer = 0; aaFlipDir = 1; aaDesyncAcc = 0; aaRollAcc = 0; aaCurrentSpeedMult = 1
    conns.antiAim = RunService.Heartbeat:Connect(function(dt)
        if not aaSettings.enabled then killConn("antiAim"); return end
        if not root then return end
        if aaSettings.aaNoClip and LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        if aaSettings.aaNetworkOwn then setNetworkOwnerLocal(root) end
        if aaSettings.aaMassless then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end

        -- random speed modifier
        if aaSettings.randomSpeed then
            aaRandTimer = aaRandTimer + dt
            if aaRandTimer > 0.1 then
                aaRandTimer = 0
                aaCurrentSpeedMult = 0.5 + math.random()
                aaRandYaw = math.random(-1, 1)
            end
        else
            aaCurrentSpeedMult = 1
            aaRandYaw = 1
        end

        local enh = aaSettings.enhancedMode
        local spd = enh and aaSettings.enhancedSpinSpeed or aaSettings.speed
        local m = aaSettings.mode
        local yaw, pitch, roll = 0, 0, 0

        if m == "Spin" or m == "RandomSpin" then
            local dir = aaSettings.randomSpeed and aaRandYaw or 1
            aaAngAcc = aaAngAcc + math.rad(spd * aaCurrentSpeedMult * dir) * dt
            yaw = aaAngAcc
            if enh then
                if aaSettings.multiAxisSpin then
                    pitch = aaAngAcc * 0.7
                    roll  = aaAngAcc * 0.5
                end
            end
        elseif m == "Jitter" then
            aaJitterT = aaJitterT + dt * (enh and aaSettings.enhancedJitterSpeed or 30)
            local amp = enh and aaSettings.enhancedJitterAmp or (aaSettings.jitterAmp or 180)
            if aaSettings.jitterYaw then
                yaw = math.sin(aaJitterT) * math.rad(amp)
            end
            if aaSettings.jitterPitch then
                pitch = math.cos(aaJitterT * 1.3) * math.rad(amp * 0.5)
            end
        elseif m == "Static" then
            yaw   = math.rad(aaSettings.staticYaw)
            pitch = math.rad(aaSettings.staticPitch)
            roll  = math.rad(aaSettings.staticRoll or 0)
        elseif m == "Up"   then pitch = math.rad(-89)
        elseif m == "Down" then pitch = math.rad(89)
        elseif m == "Side" then roll  = math.rad(90)
        elseif m == "Custom" then
            yaw   = math.rad(aaSettings.customYaw)
            pitch = math.rad(aaSettings.customPitch)
        end

        -- multi-axis spin
        if aaSettings.multiAxisSpin and (m == "Spin" or m == "RandomSpin") then
            if aaSettings.multiAxisX then aaMultiAccX = aaMultiAccX + math.rad(aaSettings.multiAxisSpeedX) * dt end
            if aaSettings.multiAxisY then aaMultiAccY = aaMultiAccY + math.rad(aaSettings.multiAxisSpeedY) * dt end
            if aaSettings.multiAxisZ then aaMultiAccZ = aaMultiAccZ + math.rad(aaSettings.multiAxisSpeedZ) * dt end
            yaw   = aaMultiAccY
            pitch = aaSettings.multiAxisX and aaMultiAccX or pitch
            roll  = aaSettings.multiAxisZ and aaMultiAccZ or roll
        end

        -- roll
        if aaSettings.rollEnabled then
            aaRollAcc = aaRollAcc + math.rad(enh and aaSettings.enhancedRollSpeed or aaSettings.rollSpeed) * dt
            roll = roll + aaRollAcc
        end

        -- desync
        if aaSettings.desyncMode then
            aaDesyncAcc = aaDesyncAcc + math.rad(enh and aaSettings.enhancedDesyncOffset or aaSettings.desyncOffset) * dt
            yaw = yaw + math.sin(aaDesyncAcc) * math.rad(enh and aaSettings.enhancedDesyncOffset or aaSettings.desyncOffset)
        end

        -- micro jitter
        if aaSettings.microJitter then
            local mAmp = enh and aaSettings.enhancedMicroAmp or aaSettings.microJitterAmp
            local mSpd = enh and aaSettings.enhancedMicroSpeed or aaSettings.microJitterSpeed
            yaw   = yaw   + (math.random()-0.5) * math.rad(mAmp)
            pitch = pitch + math.sin(tick()*mSpd) * math.rad(mAmp * 0.3)
        end

        -- chaos mode
        if aaSettings.chaosMode then
            aaChaosTimer = aaChaosTimer + dt
            if aaChaosTimer >= (enh and 0.02 or aaSettings.chaosInterval) then
                aaChaosTimer = 0
                local cMax = enh and 180 or aaSettings.chaosMaxAngle
                yaw   = yaw   + (math.random()-0.5) * math.rad(cMax)
                pitch = pitch + (math.random()-0.5) * math.rad(cMax * 0.5)
            end
        end

        -- look-at-random
        if aaSettings.lookAtRandom then
            aaLookRandTimer = aaLookRandTimer + dt
            if aaLookRandTimer >= aaSettings.lookAtRandomInterval then
                aaLookRandTimer = 0
                yaw = math.random() * math.pi * 2
                pitch = (math.random()-0.5) * math.pi
            end
        end

        -- random flip
        if aaSettings.randomFlip then
            aaFlipTimer = aaFlipTimer + dt
            local fc = enh and aaSettings.enhancedFlipChance or aaSettings.flipChance
            if math.random() < fc then aaFlipDir = -aaFlipDir end
            yaw = yaw * aaFlipDir
        end

        -- breathe effect
        if aaSettings.breatheEffect then
            aaBreatheT = aaBreatheT + dt
            local bAmp = enh and aaSettings.enhancedBreatheAmp or aaSettings.breatheAmp
            local bSpd = enh and aaSettings.enhancedBreatheSpeed or aaSettings.breatheSpeed
            yaw   = yaw   + math.sin(aaBreatheT * bSpd * math.pi * 2) * math.rad(bAmp)
            pitch = pitch + math.cos(aaBreatheT * bSpd * math.pi * 2) * math.rad(bAmp * 0.3)
        end

        -- fake angle overlay (visual desync)
        if aaSettings.fakeAngle then
            local fy = enh and aaSettings.enhancedFakeYaw or aaSettings.fakeYaw
            local fp = enh and aaSettings.enhancedFakePitch or aaSettings.fakePitch
            yaw   = yaw   + math.rad(fy)
            pitch = pitch + math.rad(fp)
        end

        -- smooth interpolation
        local cf = root.CFrame * CFrame.fromEulerAnglesYXZ(pitch, yaw, roll)
        if aaSettings.aaSmoothInterp then
            local alpha = math.clamp(aaSettings.aaSmoothSpeed, 0.01, 1)
            pcall(function() root.CFrame = root.CFrame:Lerp(cf, alpha) end)
        else
            pcall(function() root.CFrame = cf end)
        end

        -- auto-shoot while AA active
        if aaSettings.aaAutoShoot then
            local t = getClosest()
            if t and t.Character then
                local hrp2 = t.Character:FindFirstChild("HumanoidRootPart")
                if hrp2 and (root.Position - hrp2.Position).Magnitude < aaSettings.aaAutoShootRange then
                    fireTool()
                end
            end
        end
    end)
end

local function stopAntiAim() killConn("antiAim"); aaSettings.enabled = false end

-- ── Rotor Anti-Aim ────────────────────────────────────────────────────────────
local function startRotor()
    killConn("rotor")
    rotorCFG._timer   = 0
    rotorCFG._stepIdx = 0
    rotorCFG._phase   = 0
    rotorCFG._cur     = 0
    rotorCFG._tgt     = 0
    conns.rotor = RunService.Heartbeat:Connect(function(dt)
        if not rotorCFG.enabled then killConn("rotor"); return end
        if not root then return end

        local mode    = rotorCFG.mode
        local angle   = rotorCFG.angle
        local speed   = math.max(rotorCFG.speed, 0.01)
        local interval = 1 / speed

        rotorCFG._timer = rotorCFG._timer + dt
        rotorCFG._phase = rotorCFG._phase + dt

        -- compute target yaw
        if mode == "Binary" then
            if rotorCFG._timer >= interval then
                rotorCFG._timer = rotorCFG._timer % interval
                rotorCFG._stepIdx = rotorCFG._stepIdx + 1
                rotorCFG._tgt = (rotorCFG._stepIdx % 2 == 0) and angle or -angle
            end
        elseif mode == "MultiStep" then
            if rotorCFG._timer >= interval then
                rotorCFG._timer = rotorCFG._timer % interval
                local steps = math.max(rotorCFG.steps, 2)
                rotorCFG._stepIdx = (rotorCFG._stepIdx + 1) % steps
                rotorCFG._tgt = -angle + (rotorCFG._stepIdx / (steps - 1)) * (angle * 2)
            end
        elseif mode == "Random" then
            if rotorCFG._timer >= interval then
                rotorCFG._timer = rotorCFG._timer % interval
                rotorCFG._tgt = (math.random() * 2 - 1) * angle
            end
        elseif mode == "Sine" then
            rotorCFG._tgt = math.sin(rotorCFG._phase * speed * math.pi * 2) * angle
        elseif mode == "PingPong" then
            local t = (rotorCFG._phase * speed) % 1
            local tri = t < 0.5 and (t * 4 - 1) or (3 - t * 4)
            rotorCFG._tgt = tri * angle
        end

        -- smooth interpolation
        local sf = math.clamp(rotorCFG.smoothFactor, 0, 0.99)
        if sf > 0 then
            rotorCFG._cur = rotorCFG._cur + (rotorCFG._tgt - rotorCFG._cur) * (1 - sf)
        else
            rotorCFG._cur = rotorCFG._tgt
        end

        local yaw = math.rad(rotorCFG._cur)

        -- jitter overlay
        if rotorCFG.jitter then
            yaw = yaw + math.rad((math.random() * 2 - 1) * rotorCFG.jitterAmp)
        end

        -- pitch
        local pitch = 0
        local pm = rotorCFG.pitchMode
        if pm == "Down" then
            pitch = math.rad(rotorCFG.pitchAngle)
        elseif pm == "Up" then
            pitch = math.rad(-rotorCFG.pitchAngle)
        elseif pm == "Random" then
            pitch = math.rad((math.random() * 2 - 1) * rotorCFG.pitchAngle)
        end

        root.CFrame = root.CFrame * CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
    end)
end
local function stopRotor() killConn("rotor"); rotorCFG.enabled = false end

-- ── RiotGodmode (full LuaX implementation) ───────────────────────────────────
local riotGMAng = 0
local riotGMPhaseTimer = 0

local function startRiotGodmode()
    killConn("riotGodmode")
    riotGMAng = 0; riotGMPhaseTimer = 0
    conns.riotGodmode = RunService.Heartbeat:Connect(function(dt)
        if not riotGodmodeCFG.enabled then killConn("riotGodmode"); return end
        if not root then return end
        if riotGodmodeCFG.rgNoClip or riotGodmodeCFG.noClip then
            if LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        end
        if riotGodmodeCFG.rgNetworkOwn or riotGodmodeCFG.networkOwn then setNetworkOwnerLocal(root) end
        if riotGodmodeCFG.rgVelZero then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end

        local cur = root.Position

        -- bullet avoidance evasion
        if riotGodmodeCFG.avoidBullets then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer or not p.Character then continue end
                local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if not eHrp then continue end
                local dist = (cur - eHrp.Position).Magnitude
                if dist < riotGodmodeCFG.evadeRange then
                    local away = (cur - eHrp.Position).Unit
                    cur = cur + away * riotGodmodeCFG.bulletDodge * dt * 60
                end
            end
        end

        -- height variance
        if riotGodmodeCFG.heightVariance and riotGodmodeCFG.heightVariance > 0 then
            cur = cur + Vector3.new(0, (math.random()-0.5)*riotGodmodeCFG.heightVariance, 0)
        end

        -- ground snap
        if riotGodmodeCFG.groundSnap then
            cur = Vector3.new(cur.X, root.Position.Y, cur.Z)
        end

        local newPos
        if riotGodmodeCFG.phaseMode then
            riotGMPhaseTimer = riotGMPhaseTimer + dt
            if riotGMPhaseTimer >= riotGodmodeCFG.phaseInterval then
                riotGMPhaseTimer = 0
                local dir = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
                newPos = cur + dir * (riotGodmodeCFG.minJump + math.random()*(riotGodmodeCFG.maxJump-riotGodmodeCFG.minJump))
            else
                newPos = cur
            end
        else
            local jumpH = riotGodmodeCFG.minJump + math.random()*(riotGodmodeCFG.maxJump-riotGodmodeCFG.minJump)
            local randDir = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
            newPos = cur + randDir * jumpH
        end

        -- spin accumulation
        local axis = riotGodmodeCFG.spinAxis or "Y"
        if riotGodmodeCFG.randomAxis then
            local axes = {"X","Y","Z"}
            axis = axes[math.random(1,3)]
        end
        riotGMAng = riotGMAng + math.rad(riotGodmodeCFG.spinSpeed) * dt
        local spinCF
        if axis == "X" then
            spinCF = CFrame.fromEulerAnglesYXZ(riotGMAng, 0, 0)
        elseif axis == "Z" then
            spinCF = CFrame.fromEulerAnglesYXZ(0, 0, riotGMAng)
        else
            spinCF = CFrame.fromEulerAnglesYXZ(0, riotGMAng, 0)
        end

        -- multi-TP
        if riotGodmodeCFG.multiTp then
            for i = 1, riotGodmodeCFG.multiTpCount do
                local off = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit * 5
                pcall(function() root.CFrame = CFrame.new(newPos + off) * spinCF; root.AssemblyLinearVelocity = Vector3.zero end)
                task.wait(riotGodmodeCFG.multiTpDelay)
            end
        end

        -- face target
        local t = (riotGodmodeCFG.autoShoot or riotGodmodeCFG.forceFaceTarget) and getClosest() or nil
        local finalCF
        if t and t.Character then
            local tHrp = t.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then
                if riotGodmodeCFG.forceFaceTarget then
                    finalCF = CFrame.new(newPos, tHrp.Position) * spinCF
                else
                    finalCF = CFrame.new(newPos) * spinCF
                end
                if riotGodmodeCFG.autoShoot then
                    local now = tick()
                    if (root.Position - tHrp.Position).Magnitude < riotGodmodeCFG.attackRange
                    and now - riotGodmodeCFG.lastShot >= riotGodmodeCFG.shootCooldown then
                        riotGodmodeCFG.lastShot = now
                        fireTool()
                    end
                end
            end
        else
            finalCF = CFrame.new(newPos) * spinCF
        end
        pcall(function() root.CFrame = finalCF; root.AssemblyLinearVelocity = Vector3.zero end)
        task.wait(riotGodmodeCFG.speed)
    end)
end

local function stopRiotGodmode() killConn("riotGodmode"); riotGodmodeCFG.enabled = false end

-- ── RiotAbuser (full LuaX implementation) ────────────────────────────────────
local riotOrbAng = 0
local riotAbuserSpinAcc = 0

local function startRiotAbuser()
    killConn("riotAbuser")
    riotOrbAng = 0; riotAbuserSpinAcc = 0
    conns.riotAbuser = RunService.Heartbeat:Connect(function(dt)
        if not riotAbuserCFG.enabled then killConn("riotAbuser"); return end
        if not root then return end

        local target
        if riotAbuserCFG.multiTarget then
            target = getTarget("Random")
        else
            target = getClosest()
        end
        if not target or not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if riotAbuserCFG.raNoClip or riotAbuserCFG.noClip then
            if LocalPlayer.Character then applyNoClip(LocalPlayer.Character) end
        end
        if riotAbuserCFG.raNetworkOwn or riotAbuserCFG.networkOwn then setNetworkOwnerLocal(root) end
        if riotAbuserCFG.raVelZero then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end

        local tPos = hrp.Position
        if riotAbuserCFG.predictTarget then
            tPos = predictPos(hrp, riotAbuserCFG.predictLead)
        end

        local cf = CFrame.new(tPos)
        local height = riotAbuserCFG.height
        local forward = riotAbuserCFG.forward or 0
        local right = riotAbuserCFG.right or 0
        local down = riotAbuserCFG.down or 0

        -- random offset
        local rOff = Vector3.zero
        if riotAbuserCFG.randomOffset then
            local amp = riotAbuserCFG.randomOffAmp
            rOff = Vector3.new((math.random()-0.5)*amp*2, (math.random()-0.5)*amp, (math.random()-0.5)*amp*2)
        end

        local m = riotAbuserCFG.mode
        local newPos

        if m == "Stick" then
            newPos = tPos + cf.RightVector*right + cf.UpVector*(height-down) + cf.LookVector*forward + rOff
        elseif m == "Bounce" then
            local bH = math.abs(math.sin(tick()*riotAbuserCFG.bounceSpeed)) * riotAbuserCFG.bounceHeight
            newPos = tPos + cf.RightVector*right + cf.UpVector*(height + bH - down) + cf.LookVector*forward + rOff
        elseif m == "Orbit" then
            riotOrbAng = riotOrbAng + math.rad(riotAbuserCFG.orbitSpeed) * dt
            local orbitH = riotAbuserCFG.orbitEnabled and riotAbuserCFG.orbitHeight or height
            newPos = tPos + Vector3.new(
                math.cos(riotOrbAng)*riotAbuserCFG.orbitRadius,
                orbitH,
                math.sin(riotOrbAng)*riotAbuserCFG.orbitRadius
            ) + rOff
        elseif m == "Phase" then
            local side = (tick() % 1 > 0.5) and 1 or -1
            newPos = tPos + cf.LookVector*riotAbuserCFG.phaseOffset + cf.RightVector*right*side + cf.UpVector*(height-down) + rOff
        end

        if newPos then
            local finalCF
            if riotAbuserCFG.spinOnTarget then
                riotAbuserSpinAcc = riotAbuserSpinAcc + math.rad(riotAbuserCFG.spinSpeed) * dt
                finalCF = CFrame.new(newPos) * CFrame.fromEulerAnglesYXZ(0, riotAbuserSpinAcc, 0)
            elseif riotAbuserCFG.forceFaceTarget then
                finalCF = CFrame.new(newPos, tPos)
            else
                finalCF = CFrame.new(newPos)
            end
            pcall(function() root.CFrame = finalCF; root.AssemblyLinearVelocity = Vector3.zero end)

            -- fast TP burst
            if riotAbuserCFG.raFastTp then
                for i = 1, riotAbuserCFG.raFastTpCount do
                    pcall(function() root.CFrame = finalCF end)
                    task.wait(riotAbuserCFG.raFastTpInterval)
                end
            end
        end

        -- auto-shoot
        if riotAbuserCFG.autoShoot then
            local now = tick()
            if (root.Position - hrp.Position).Magnitude < riotAbuserCFG.attackRange
            and now - riotAbuserCFG.lastShot >= riotAbuserCFG.shootCooldown then
                riotAbuserCFG.lastShot = now
                fireTool()
            end
        end
    end)
end

local function stopRiotAbuser() killConn("riotAbuser"); riotAbuserCFG.enabled = false end

-- ── Rivals Ragebot (extracted from Rivals_ragebot_works) ─────────────────────
local RageCFG = { Enabled = true, FireRate = 0.0005, WeaponSlot = "Melee" }
local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber() return slots[RageCFG.WeaponSlot] or 3 end

local deflecting = {}
plrs.PlayerRemoving:Connect(function(player) deflecting[player] = nil end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fighterObj in FighterController.Objects do
        local player = fighterObj.Player
        if not player then continue end
        if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
            deflecting[player] = false; continue
        end
        local equipped = fighterObj.EquippedItem
        local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
        deflecting[player] = isKatana and (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
    end
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local duel = SpectateController.CurrentDuelSubject
    local localDueler = duel and duel:GetDueler(LocalPlayer)
    local localTeam = localDueler and localDueler:Get("TeamID") or nil
    if localTeam and duel and duel.Duelers then
        for _, dueler in duel.Duelers do
            if dueler.Player == player then return dueler:Get("TeamID") ~= localTeam end
        end
    end
    local pTeam = player:GetAttribute("TeamID")
    local lTeam = LocalPlayer:GetAttribute("TeamID")
    if pTeam and lTeam then return pTeam ~= lTeam end
    return true
end

local function getClosestTarget()
    local c = LocalPlayer.Character
    if not c then return nil, nil, nil end
    local myRoot = c:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    local closestPlayer, closestRoot, closestHead, closestDist = nil, nil, nil, 500
    for _, player in plrs:GetPlayers() do
        if not isEnemy(player) then continue end
        local pChar = player.Character
        if not pChar then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum  = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist < closestDist then
            closestDist = dist; closestPlayer = player; closestRoot = pRoot; closestHead = pHead
        end
    end
    return closestPlayer, closestRoot, closestHead
end

local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local viewModels = ws:FindFirstChild("ViewModels")
    if not viewModels then return false end
    for _, model in viewModels:GetChildren() do
        if model:IsA("Model") and string.find(model.Name, targetPlayer.Name, 1, true) and string.find(model.Name, "Knife", 1, true) then
            return true
        end
    end
    return false
end

local lastFire = 0

local function startRagebot()
    killConn("ragebot")
    task.spawn(function()
        local lf = FighterController.LocalFighter
        while not lf do task.wait(0.1); lf = FighterController.LocalFighter end
        pcall(function() lf:EquipItem(getSlotNumber()) end)
    end)
    task.spawn(function()
        while true do
            task.wait(1)
            if not RageCFG.Enabled then continue end
            local lf = FighterController.LocalFighter
            if lf then pcall(function() lf:EquipItem(getSlotNumber()) end) end
        end
    end)
    conns.ragebot = runS.Heartbeat:Connect(function()
        updateDeflection()
        local targetPlayer, targetRoot, targetHead = getClosestTarget()
        local desyncCF = nil
        if targetRoot and targetHead then
            local desyncPos = hasKnifeViewModel(targetPlayer)
                and (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
                or  (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
            desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
        end
        if desyncCF and LocalPlayer.Character then
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local oldCF = myRoot.CFrame; local oldVel = myRoot.Velocity; local oldRotVel = myRoot.RotVelocity
                myRoot.CFrame = desyncCF
                runS:BindToRenderStep("__restore", 101, function()
                    if myRoot then myRoot.CFrame = oldCF; myRoot.Velocity = oldVel; myRoot.RotVelocity = oldRotVel end
                    runS:UnbindFromRenderStep("__restore")
                end)
            end
        end
        if not RageCFG.Enabled then return end
        if not targetPlayer or not targetHead or not targetRoot then return end
        if deflecting[targetPlayer] then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        if not FighterController or not FighterController.LocalFighter then return end
        local item = FighterController.LocalFighter.EquippedItem
        if not item then return end
        if tick() - lastFire < RageCFG.FireRate then return end
        lastFire = tick()
        local originPos = desyncCF and desyncCF.Position or targetRoot.Position
        local targetPos = targetHead.Position
        local aimCF = CFrame.lookAt(originPos, targetPos)
        local targetCF = targetHead.CFrame
        local randomOffset = Vector3.new((math.random()-0.5)*0.1, (math.random()-0.5)*0.1, (math.random()-0.5)*0.1)
        local aimedPos = targetPos + randomOffset
        local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
        local cameradata = {}
        cameradata[utf8.char(1)] = {
            [utf8.char(0)] = util:EncodeCFrame(aimCF),
            [utf8.char(1)] = util:EncodeCFrame(targetCF),
            [utf8.char(2)] = targetHead,
            [utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset)
        }
        repS.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum_lib:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)
end

local function stopRagebot() killConn("ragebot"); RageCFG.Enabled = false end

-- ── Character bind ────────────────────────────────────────────────────────────
local function bindChar(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart", 5)
    hum  = c:WaitForChild("Humanoid", 5)
    if RageCFG.Enabled        then startRagebot()         end
    if CFG.VOID_ENABLED        then startVoid()            end
    if cfg.orbitEnabled        then startOrbit()           end
    if cfgDodge.predEnabled    then startPredictionV2()    end
    if antiBaitCFG.enabled     then startAntiBaitV2()      end
    if aaSettings.enabled      then startAntiAim()         end
    if translocCFG.enabled     then startTransloc()        end
    if antiTranslocCFG.enabled then startAntiTransloc()    end
    if velDesyncCFG.enabled    then startVelDesync()       end
    if slingCFG.enabled        then startSlingBypassV2()   end
    if riotGodmodeCFG.enabled  then startRiotGodmode()     end
    if riotAbuserCFG.enabled   then startRiotAbuser()      end
    if rangeExtCFG.enabled     then startRangeExt()        end
end

if LocalPlayer.Character then bindChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.3); bindChar(c) end)
LocalPlayer.CharacterRemoving:Connect(function()
    for k, conn in pairs(conns) do if conn then conn:Disconnect() end end
    conns = {}
    if desyncHB then desyncHB:Disconnect(); desyncHB = nil end
    if desyncRS then desyncRS:Disconnect(); desyncRS = nil end
    if translocConn then translocConn:Disconnect(); translocConn = nil end
    if translocPreRender then translocPreRender:Disconnect(); translocPreRender = nil end
    if slingConn then slingConn:Disconnect(); slingConn = nil end
    if rangeExtHB then rangeExtHB:Disconnect(); rangeExtHB = nil end
    char = nil; root = nil; hum = nil
end)

-- ── UI: Combat / Ragebot ──────────────────────────────────────────────────────
do
    local gb = WT.Rage:AddLeftGroupbox("Ragebot")
    AddBindableToggle(gb, "RageEnabled", "Ragebot", true, function(v)
        RageCFG.Enabled = v
        if v then startRagebot() else stopRagebot() end
    end)
    gb:AddSlider("RageFireRate", { Text = "Fire Rate (ms)", Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) RageCFG.FireRate = v * 0.001 end })
    gb:AddDropdown("RageWeapon", { Text = "Weapon Slot", Values = {"Melee","Primary","Secondary"}, Default = 1,
        Callback = function(v) RageCFG.WeaponSlot = v end })
end

-- ── UI: HvH / VoidSpam ────────────────────────────────────────────────────────
do
    local gb = WT.Void:AddLeftGroupbox("VoidSpam")
    AddBindableToggle(gb, "VoidEnabled", "VoidSpam", false, function(v)
        CFG.VOID_ENABLED = v
        if v then startVoid() else stopVoid() end
    end)
    gb:AddDropdown("VoidMethod", { Text = "Mode", Default = 5,
        Values = {"Drift","Chaos","Loop","Spiral","Quantum","TP Everywhere","OrbitTarget"},
        Callback = function(v) CFG.VOID_METHOD = v end })
    gb:AddToggle("VoidKiller", { Text = "VoidKiller", Default = false,
        Callback = function(v) CFG.VOID_KILLER_ENABLED = v end })
    gb:AddToggle("VoidAutoReenable", { Text = "Auto Re-enable", Default = false,
        Callback = function(v) CFG.VOID_AUTO_REENABLE = v end })
end

-- ── UI: HvH / Orbit ───────────────────────────────────────────────────────────
do
    local gb = WT.Orbit:AddLeftGroupbox("Orbit")
    AddBindableToggle(gb, "OrbitEnabled", "Orbit", false, function(v)
        cfg.orbitEnabled = v
        if v then startOrbit() else stopOrbit() end
    end)
    gb:AddDropdown("OrbitMode", { Text = "Mode", Default = 1,
        Values = {"Circle","Figure 8","Ellipse","Spiral In","Spiral Out","Bounce","Lemniscate","Infinity","RandomOrbit"},
        Callback = function(v) cfg.orbitMode = v end })
    gb:AddDropdown("OrbitTarget", { Text = "Target", Default = 1,
        Values = {"Closest","Random","Weakest","Strongest"},
        Callback = function(v) cfg.orbitTarget = v end })
    gb:AddSlider("OrbitSpeed", { Text = "Speed", Default = 90, Min = 1, Max = 720, Rounding = 0,
        Callback = function(v) cfg.orbitSpeed = v end })
    gb:AddSlider("OrbitDist", { Text = "Distance", Default = 8, Min = 1, Max = 100, Rounding = 1,
        Callback = function(v) cfg.orbitDist = v end })
    gb:AddToggle("OrbitAutoShoot", { Text = "Auto Shoot", Default = true,
        Callback = function(v) cfg.orbitAutoShoot = v end })
end

-- ── UI: HvH / Prediction ──────────────────────────────────────────────────────
do
    local gb = WT.Pred:AddLeftGroupbox("PredictionV2")
    AddBindableToggle(gb, "PredEnabled", "Prediction", false, function(v)
        cfgDodge.predEnabled = v
        if v then startPredictionV2() else stopPredictionV2() end
    end)
    gb:AddSlider("PredDodgeDist", { Text = "Dodge Dist", Default = 80, Min = 10, Max = 500, Rounding = 0,
        Callback = function(v) cfgDodge.predDodgeDist = v end })
    gb:AddSlider("PredCooldown", { Text = "Cooldown (ms)", Default = 30, Min = 1, Max = 500, Rounding = 0,
        Callback = function(v) cfgDodge.predCooldown = v * 0.001 end })
    gb:AddToggle("PredAutoShoot", { Text = "Auto Shoot", Default = true,
        Callback = function(v) cfgDodge.predAutoShoot = v end })
end

-- ── UI: HvH / Defense (AntiBait) ─────────────────────────────────────────────
do
    local gb = WT.Defense:AddLeftGroupbox("AntiBait V2")
    AddBindableToggle(gb, "AntiBaitEnabled", "AntiBait", false, function(v)
        antiBaitCFG.enabled = v
        if v then startAntiBaitV2() else stopAntiBaitV2() end
    end)
    gb:AddToggle("AntiBaitVelSpike", { Text = "Vel Spike Detect", Default = true,
        Callback = function(v) antiBaitCFG.velSpikeEnabled = v end })
    gb:AddToggle("AntiBaitFlicker", { Text = "Flicker Detect", Default = true,
        Callback = function(v) antiBaitCFG.flickerEnabled = v end })
    gb:AddDropdown("AntiBaitDodgeMode", { Text = "Dodge Mode", Default = 2,
        Values = {"Away","Perpendicular","Random"},
        Callback = function(v) antiBaitCFG.dodgeMode = v end })
    gb:AddToggle("AntiBaitGunPred", { Text = "Gun Prediction", Default = true,
        Callback = function(v) antiBaitCFG.gunPredEnabled = v end })
end

-- ── UI: HvH / AntiAim ────────────────────────────────────────────────────────
do
    local gb = WT.AntiAim:AddLeftGroupbox("Anti-Aim")
    AddBindableToggle(gb, "AAEnabled", "Anti-Aim", false, function(v)
        aaSettings.enabled = v
        if v then startAntiAim() else stopAntiAim() end
    end)
    gb:AddDropdown("AAMode", { Text = "Mode", Default = 7,
        Values = {"Spin","Jitter","Static","Up","Down","Side","RandomSpin","Custom"},
        Callback = function(v) aaSettings.mode = v end })
    gb:AddSlider("AASpeed", { Text = "Speed", Default = 5000, Min = 10, Max = 10000, Rounding = 0,
        Callback = function(v) aaSettings.speed = v end })
    gb:AddSlider("AAPitchAngle", { Text = "Pitch Angle", Default = 45, Min = 0, Max = 89, Rounding = 0,
        Callback = function(v) aaSettings.pitchAngle = v end })
    gb:AddSlider("AAYawAngle", { Text = "Yaw Angle", Default = 45, Min = 0, Max = 180, Rounding = 0,
        Callback = function(v) aaSettings.yawAngle = v end })
    gb:AddSlider("AAStaticYaw", { Text = "Static Yaw", Default = 90, Min = -180, Max = 180, Rounding = 0,
        Callback = function(v) aaSettings.staticYaw = v end })
    gb:AddSlider("AAStaticPitch", { Text = "Static Pitch", Default = 0, Min = -89, Max = 89, Rounding = 0,
        Callback = function(v) aaSettings.staticPitch = v end })
    gb:AddSlider("AACustomYaw", { Text = "Custom Yaw", Default = 180, Min = -360, Max = 360, Rounding = 0,
        Callback = function(v) aaSettings.customYaw = v end })
    gb:AddSlider("AACustomPitch", { Text = "Custom Pitch", Default = 0, Min = -89, Max = 89, Rounding = 0,
        Callback = function(v) aaSettings.customPitch = v end })
    AddBindableToggle(gb, "AARandomSpeed", "Randomize Speed", true, function(v) aaSettings.randomSpeed = v end)
    AddBindableToggle(gb, "AAJitterYaw", "Jitter Yaw", true, function(v) aaSettings.jitterYaw = v end)
    AddBindableToggle(gb, "AAJitterPitch", "Jitter Pitch", true, function(v) aaSettings.jitterPitch = v end)
    AddBindableToggle(gb, "AAFakeAngle", "Fake Angle", false, function(v) aaSettings.fakeAngle = v end)
    gb:AddSlider("AAFakeYaw", { Text = "Fake Yaw", Default = 45, Min = -180, Max = 180, Rounding = 0,
        Callback = function(v) aaSettings.fakeYaw = v end })
    AddBindableToggle(gb, "AAMicroJitter", "Micro Jitter", false, function(v) aaSettings.microJitter = v end)
    gb:AddSlider("AAMicroJitterAmp", { Text = "Micro Jitter Amp", Default = 5, Min = 1, Max = 45, Rounding = 0,
        Callback = function(v) aaSettings.microJitterAmp = v end })
    AddBindableToggle(gb, "AADesyncMode", "Desync Mode", false, function(v) aaSettings.desyncMode = v end)
    gb:AddSlider("AADesyncOffset", { Text = "Desync Offset", Default = 180, Min = 0, Max = 360, Rounding = 0,
        Callback = function(v) aaSettings.desyncOffset = v end })
    AddBindableToggle(gb, "AARollEnabled", "Roll", false, function(v) aaSettings.rollEnabled = v end)
    gb:AddSlider("AARollSpeed", { Text = "Roll Speed", Default = 360, Min = 10, Max = 2000, Rounding = 0,
        Callback = function(v) aaSettings.rollSpeed = v end })
    AddBindableToggle(gb, "AABreatheEffect", "Breathe Effect", false, function(v) aaSettings.breatheEffect = v end)
    gb:AddSlider("AABreatheAmp", { Text = "Breathe Amp", Default = 3, Min = 1, Max = 30, Rounding = 0,
        Callback = function(v) aaSettings.breatheAmp = v end })
    AddBindableToggle(gb, "AARandomFlip", "Random Flip", false, function(v) aaSettings.randomFlip = v end)
    AddBindableToggle(gb, "AAChaos", "Chaos Mode", true, function(v) aaSettings.chaosMode = v end)
    gb:AddSlider("AAChaosMaxAngle", { Text = "Chaos Max Angle", Default = 180, Min = 10, Max = 360, Rounding = 0,
        Callback = function(v) aaSettings.chaosMaxAngle = v end })
    AddBindableToggle(gb, "AALookAtRandom", "Look-At-Random", true, function(v) aaSettings.lookAtRandom = v end)
    AddBindableToggle(gb, "AAEnhanced", "Enhanced Mode", true, function(v) aaSettings.enhancedMode = v end)
    AddBindableToggle(gb, "AAMultiAxis", "Multi-Axis Spin", true, function(v) aaSettings.multiAxisSpin = v end)
    gb:AddSlider("AAMultiSpeedX", { Text = "Multi-Axis X Speed", Default = 3600, Min = 100, Max = 10000, Rounding = 0,
        Callback = function(v) aaSettings.multiAxisSpeedX = v end })
    gb:AddSlider("AAMultiSpeedY", { Text = "Multi-Axis Y Speed", Default = 5400, Min = 100, Max = 10000, Rounding = 0,
        Callback = function(v) aaSettings.multiAxisSpeedY = v end })
    gb:AddSlider("AAMultiSpeedZ", { Text = "Multi-Axis Z Speed", Default = 2700, Min = 100, Max = 10000, Rounding = 0,
        Callback = function(v) aaSettings.multiAxisSpeedZ = v end })
    gb:AddSlider("AASmoothSpeed", { Text = "Smooth Speed", Default = 90, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) aaSettings.aaSmoothSpeed = v * 0.01 end })
    AddBindableToggle(gb, "AANoClip", "AA NoClip", true, function(v) aaSettings.aaNoClip = v end)
    AddBindableToggle(gb, "AANetworkOwn", "AA NetworkOwn", true, function(v) aaSettings.aaNetworkOwn = v end)
    AddBindableToggle(gb, "AAAutoShoot", "AA Auto-Shoot", true, function(v) aaSettings.aaAutoShoot = v end)
    gb:AddSlider("AAEnhancedSpinSpeed", { Text = "Enhanced Spin Speed", Default = 10000, Min = 100, Max = 36000, Rounding = 0,
        Callback = function(v) aaSettings.enhancedSpinSpeed = v end })

    -- Rotor groupbox (right side of AntiAim tab)
    local gbR = WT.AntiAim:AddRightGroupbox("Rotor")
    AddBindableToggle(gbR, "RotorEnabled", "Rotor", false, function(v)
        rotorCFG.enabled = v
        if v then startRotor() else stopRotor() end
    end)
    gbR:AddDropdown("RotorMode", { Text = "Mode", Default = 1,
        Values = {"Binary","MultiStep","Random","Sine","PingPong"},
        Callback = function(v) rotorCFG.mode = v end })
    gbR:AddSlider("RotorAngle", { Text = "Angle", Default = 90, Min = 1, Max = 180, Rounding = 0,
        Callback = function(v) rotorCFG.angle = v end })
    gbR:AddSlider("RotorSpeed", { Text = "Speed (Hz)", Default = 30, Min = 1, Max = 200, Rounding = 0,
        Callback = function(v) rotorCFG.speed = v end })
    gbR:AddSlider("RotorSteps", { Text = "Steps (MultiStep)", Default = 4, Min = 2, Max = 16, Rounding = 0,
        Callback = function(v) rotorCFG.steps = v end })
    gbR:AddDropdown("RotorPitch", { Text = "Pitch Mode", Default = 1,
        Values = {"None","Down","Up","Random"},
        Callback = function(v) rotorCFG.pitchMode = v end })
    gbR:AddSlider("RotorPitchAngle", { Text = "Pitch Angle", Default = 45, Min = 0, Max = 89, Rounding = 0,
        Callback = function(v) rotorCFG.pitchAngle = v end })
    AddBindableToggle(gbR, "RotorJitter", "Jitter Overlay", false, function(v) rotorCFG.jitter = v end)
    gbR:AddSlider("RotorJitterAmp", { Text = "Jitter Amp", Default = 10, Min = 1, Max = 90, Rounding = 0,
        Callback = function(v) rotorCFG.jitterAmp = v end })
    gbR:AddSlider("RotorSmooth", { Text = "Smooth Factor", Default = 0, Min = 0, Max = 99, Rounding = 0,
        Callback = function(v) rotorCFG.smoothFactor = v * 0.01 end })
end

-- ── UI: Misc / Transloc ───────────────────────────────────────────────────────
do
    local gb = WT.Transloc:AddLeftGroupbox("Transloc")
    AddBindableToggle(gb, "TranslocEnabled", "Transloc", false, function(v)
        translocCFG.enabled = v
        if v then startTransloc() else stopTransloc() end
    end)
    gb:AddDropdown("TranslocMode", { Text = "Offset Mode", Default = 1,
        Values = {"Ahead","Behind","Perpendicular","Above","Below","AboveBelow","MirrorX","MirrorZ","Diagonal","ScreenEdge","Orbit","ZoneEscape"},
        Callback = function(v) translocCFG.offsetMode = v end })
    gb:AddSlider("TranslocFreq", { Text = "Frequency", Default = 512, Min = 1, Max = 1000, Rounding = 0,
        Callback = function(v) translocCFG.frequency = v end })
    gb:AddSlider("TranslocLayers", { Text = "Layers", Default = 10, Min = 1, Max = 50, Rounding = 0,
        Callback = function(v) translocCFG.layers = v end })
    gb:AddToggle("TranslocSnapBack", { Text = "Snap Back", Default = true,
        Callback = function(v) translocCFG.snapBack = v end })
    gb:AddToggle("TranslocFakeVel", { Text = "Fake Velocity", Default = true,
        Callback = function(v) translocCFG.fakeVel = v end })
    local gb2 = WT.Transloc:AddRightGroupbox("Vel Desync")
    AddBindableToggle(gb2, "VelDesyncEnabled", "Vel Desync", false, function(v)
        velDesyncCFG.enabled = v
        if v then startVelDesync() else stopVelDesync() end
    end)
    gb2:AddSlider("VelDesyncIntensity", { Text = "Intensity", Default = 50, Min = 1, Max = 1000, Rounding = 0,
        Callback = function(v) velDesyncCFG.intensity = v end })
    gb2:AddToggle("VelDesyncSpike", { Text = "Spike", Default = false,
        Callback = function(v) velDesyncCFG.spike = v end })
    local gb3 = WT.Transloc:AddRightGroupbox("Anti-Transloc")
    AddBindableToggle(gb3, "AntiTranslocEnabled", "Anti-Transloc", false, function(v)
        antiTranslocCFG.enabled = v
        if v then startAntiTransloc() else stopAntiTransloc() end
    end)
    gb3:AddDropdown("AntiTranslocMode", { Text = "Mode", Default = 2,
        Values = {"Freeze","Evade","Predict"},
        Callback = function(v) antiTranslocCFG.mode = v end })
end

-- ── UI: Misc / Sling ──────────────────────────────────────────────────────────
do
    local gb = WT.Sling:AddLeftGroupbox("Sling Bypass V2")
    AddBindableToggle(gb, "SlingEnabled", "Sling Bypass", false, function(v)
        slingCFG.enabled = v
        if v then startSlingBypassV2() else stopSlingBypassV2() end
    end)
    AddBindableToggle(gb, "SlingNoTpMode", "NoTp Mode (recommended)", true, function(v) slingCFG.noTpMode = v end)
    gb:AddDropdown("SlingMode", { Text = "Mode", Default = 1,
        Values = {"Follow","Stalk","Hover","FastTp","TargetStick","OrbitTarget","RandomAroundTarget"},
        Callback = function(v) slingCFG.mode = v end })
    gb:AddDropdown("SlingTarget", { Text = "Target", Default = 1,
        Values = {"Closest","Random","Weakest","Strongest"},
        Callback = function(v) slingCFG.targetMode = v end })
    AddBindableToggle(gb, "SlingAutoShoot", "Auto Shoot", true, function(v) slingCFG.autoShoot = v end)
    gb:AddSlider("SlingStickHeight", { Text = "Stick Height", Default = 2, Min = 0, Max = 20, Rounding = 1,
        Callback = function(v) slingCFG.stickHeight = v end })
    gb:AddSlider("SlingHitboxSize", { Text = "NoTp Hitbox Size", Default = 2000, Min = 10, Max = 5000, Rounding = 0,
        Callback = function(v) slingCFG.noTpHitboxSize = v end })
    gb:AddSlider("SlingFollowDistance", { Text = "Follow Distance", Default = 2, Min = 1, Max = 30, Rounding = 1,
        Callback = function(v) slingCFG.followDistance = v end })
    gb:AddSlider("SlingFollowHeight", { Text = "Follow Height", Default = 2, Min = 0, Max = 20, Rounding = 1,
        Callback = function(v) slingCFG.followHeight = v end })
    gb:AddSlider("SlingFollowLerp", { Text = "Follow Lerp", Default = 50, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.followLerp = v * 0.01 end })
    AddBindableToggle(gb, "SlingFollowPredict", "Follow Prediction", true, function(v) slingCFG.followPredict = v end)
    gb:AddSlider("SlingFollowLead", { Text = "Follow Lead", Default = 15, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.followLead = v * 0.01 end })
    gb:AddSlider("SlingStalkDist", { Text = "Stalk Distance", Default = 6, Min = 1, Max = 50, Rounding = 1,
        Callback = function(v) slingCFG.stalkDistance = v end })
    AddBindableToggle(gb, "SlingStalkBehind", "Stalk Behind Target", true, function(v) slingCFG.stalkBehind = v end)
    gb:AddSlider("SlingHoverHeight", { Text = "Hover Height", Default = 8, Min = 1, Max = 50, Rounding = 1,
        Callback = function(v) slingCFG.hoverHeight = v end })
    AddBindableToggle(gb, "SlingHoverBob", "Hover Bob", true, function(v) slingCFG.hoverBob = v end)
    gb:AddSlider("SlingFastTpCount", { Text = "FastTp Count", Default = 20, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.rivalsFastTpCount = v; slingCFG.slingFastTpCount = v end })
    gb:AddSlider("SlingFastTpInterval", { Text = "FastTp Interval (ms)", Default = 1, Min = 1, Max = 50, Rounding = 0,
        Callback = function(v) slingCFG.rivalsFastTpInterval = v*0.001; slingCFG.slingFastTpInterval = v*0.001 end })
    AddBindableToggle(gb, "SlingRivalsMode", "Rivals Mode", true, function(v) slingCFG.rivalsMode = v end)
    AddBindableToggle(gb, "SlingRivalsHitboxExpand", "Hitbox Expand", true, function(v) slingCFG.rivalsHitboxExpand = v end)
    AddBindableToggle(gb, "SlingPositionLock", "Position Lock", true, function(v) slingCFG.rivalsPositionLock = v end)
    AddBindableToggle(gb, "SlingNoClip", "Sling NoClip", true, function(v) slingCFG.slingNoClip = v end)
    AddBindableToggle(gb, "SlingNetworkOwn", "Sling NetworkOwn", true, function(v) slingCFG.rivalsNetworkOwner = v end)
    AddBindableToggle(gb, "SlingAntiKick", "Anti-Kick", true, function(v) slingCFG.slingAntiKick = v end)
    AddBindableToggle(gb, "SlingBypassAC", "Bypass Anticheat", true, function(v) slingCFG.slingBypassAnticheat = v end)
    AddBindableToggle(gb, "SlingHideAvatar", "Hide Avatar", false, function(v) slingCFG.hideAvatar = v end)
    gb:AddSlider("SlingHideTransparency", { Text = "Hide Transparency", Default = 100, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.hideTransparency = v * 0.01 end })
    -- NoTp advanced
    local gb2 = WT.Sling:AddRightGroupbox("NoTp Settings")
    AddBindableToggle(gb2, "SlingNoTpAimAssist", "Aim Assist", true, function(v) slingCFG.noTpAimAssist = v end)
    AddBindableToggle(gb2, "SlingNoTpSilentAim", "Silent Aim", true, function(v) slingCFG.noTpSilentAim = v end)
    AddBindableToggle(gb2, "SlingNoTpOriginSpoof", "Origin Spoof", true, function(v) slingCFG.noTpOriginSpoof = v end)
    AddBindableToggle(gb2, "SlingNoTpWallBang", "Wallbang", true, function(v) slingCFG.noTpWallBang = v end)
    AddBindableToggle(gb2, "SlingNoTpInstantHit", "Instant Hit", true, function(v) slingCFG.noTpInstantHit = v end)
    AddBindableToggle(gb2, "SlingNoTpVelComp", "Velocity Comp", true, function(v) slingCFG.noTpVelocityComp = v end)
    AddBindableToggle(gb2, "SlingNoTpGravComp", "Gravity Comp", true, function(v) slingCFG.noTpGravityComp = v end)
    AddBindableToggle(gb2, "SlingNoTpProjectile", "Projectile Follow", true, function(v) slingCFG.noTpProjectileFollow = v end)
    gb2:AddSlider("SlingNoTpSpread", { Text = "Spread Override", Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.noTpSpread = v end })
    gb2:AddSlider("SlingNoTpRecoil", { Text = "Recoil Override", Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) slingCFG.noTpRecoil = v end })
end

-- ── UI: Misc / Riot ───────────────────────────────────────────────────────────
do
    local gb = WT.Riot:AddLeftGroupbox("Riot Godmode")
    AddBindableToggle(gb, "RiotGodEnabled", "Riot Godmode", false, function(v)
        riotGodmodeCFG.enabled = v
        if v then startRiotGodmode() else stopRiotGodmode() end
    end)
    gb:AddSlider("RiotGodSpeed", { Text = "Interval (cs)", Default = 3, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.speed = v * 0.01 end })
    gb:AddSlider("RiotGodSpinSpeed", { Text = "Spin Speed", Default = 180, Min = 10, Max = 3600, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.spinSpeed = v end })
    gb:AddDropdown("RiotGodSpinAxis", { Text = "Spin Axis", Default = 2,
        Values = {"X","Y","Z"},
        Callback = function(v) riotGodmodeCFG.spinAxis = v end })
    AddBindableToggle(gb, "RiotGodRandomAxis", "Random Axis", false, function(v) riotGodmodeCFG.randomAxis = v end)
    gb:AddSlider("RiotGodMinJump", { Text = "Min Jump", Default = 10, Min = 1, Max = 500, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.minJump = v end })
    gb:AddSlider("RiotGodMaxJump", { Text = "Max Jump", Default = 200, Min = 10, Max = 2000, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.maxJump = v end })
    gb:AddSlider("RiotGodHeightVar", { Text = "Height Variance", Default = 10, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.heightVariance = v end })
    AddBindableToggle(gb, "RiotGodAvoidBullets", "Avoid Bullets", true, function(v) riotGodmodeCFG.avoidBullets = v end)
    gb:AddSlider("RiotGodEvadeRange", { Text = "Evade Range", Default = 30, Min = 5, Max = 200, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.evadeRange = v end })
    gb:AddSlider("RiotGodBulletDodge", { Text = "Bullet Dodge Power", Default = 40, Min = 5, Max = 500, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.bulletDodge = v end })
    AddBindableToggle(gb, "RiotGodPhaseMode", "Phase Mode", false, function(v) riotGodmodeCFG.phaseMode = v end)
    gb:AddSlider("RiotGodPhaseInterval", { Text = "Phase Interval (ms)", Default = 20, Min = 1, Max = 200, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.phaseInterval = v * 0.001 end })
    AddBindableToggle(gb, "RiotGodMultiTp", "Multi-TP", false, function(v) riotGodmodeCFG.multiTp = v end)
    gb:AddSlider("RiotGodMultiTpCount", { Text = "Multi-TP Count", Default = 3, Min = 1, Max = 20, Rounding = 0,
        Callback = function(v) riotGodmodeCFG.multiTpCount = v end })
    AddBindableToggle(gb, "RiotGodForceFace", "Force Face Target", true, function(v) riotGodmodeCFG.forceFaceTarget = v end)
    AddBindableToggle(gb, "RiotGodGroundSnap", "Ground Snap", false, function(v) riotGodmodeCFG.groundSnap = v end)
    AddBindableToggle(gb, "RiotGodAutoShoot", "Auto Shoot", true, function(v) riotGodmodeCFG.autoShoot = v end)
    AddBindableToggle(gb, "RiotGodNoClip", "NoClip", true, function(v) riotGodmodeCFG.rgNoClip = v; riotGodmodeCFG.noClip = v end)
    AddBindableToggle(gb, "RiotGodNetworkOwn", "Network Own", true, function(v) riotGodmodeCFG.rgNetworkOwn = v; riotGodmodeCFG.networkOwn = v end)
    AddBindableToggle(gb, "RiotGodVelZero", "Vel Zero", true, function(v) riotGodmodeCFG.rgVelZero = v end)
    AddBindableToggle(gb, "RiotGodAntiKick", "Anti-Kick", true, function(v) riotGodmodeCFG.rgAntiKick = v end)
    AddBindableToggle(gb, "RiotGodBypassAC", "Bypass Anticheat", true, function(v) riotGodmodeCFG.rgBypassAnticheat = v end)
    AddBindableToggle(gb, "RiotGodFastTp", "Fast TP Burst", true, function(v) riotGodmodeCFG.rgFastTp = v end)

    local gb2 = WT.Riot:AddRightGroupbox("Riot Abuser")
    AddBindableToggle(gb2, "RiotAbuserEnabled", "Riot Abuser", false, function(v)
        riotAbuserCFG.enabled = v
        if v then startRiotAbuser() else stopRiotAbuser() end
    end)
    gb2:AddDropdown("RiotAbuserMode", { Text = "Mode", Default = 1,
        Values = {"Stick","Bounce","Orbit","Phase"},
        Callback = function(v) riotAbuserCFG.mode = v end })
    gb2:AddSlider("RiotAbuserHeight", { Text = "Height", Default = 3, Min = 0, Max = 50, Rounding = 1,
        Callback = function(v) riotAbuserCFG.height = v end })
    gb2:AddSlider("RiotAbuserForward", { Text = "Forward Offset", Default = 0, Min = -20, Max = 20, Rounding = 1,
        Callback = function(v) riotAbuserCFG.forward = v end })
    gb2:AddSlider("RiotAbuserRight", { Text = "Right Offset", Default = 0, Min = -20, Max = 20, Rounding = 1,
        Callback = function(v) riotAbuserCFG.right = v end })
    gb2:AddSlider("RiotAbuserOrbitRadius", { Text = "Orbit Radius", Default = 5, Min = 1, Max = 50, Rounding = 1,
        Callback = function(v) riotAbuserCFG.orbitRadius = v end })
    gb2:AddSlider("RiotAbuserOrbitSpeed", { Text = "Orbit Speed", Default = 200, Min = 10, Max = 2000, Rounding = 0,
        Callback = function(v) riotAbuserCFG.orbitSpeed = v end })
    gb2:AddSlider("RiotAbuserOrbitHeight", { Text = "Orbit Height", Default = 2, Min = 0, Max = 20, Rounding = 1,
        Callback = function(v) riotAbuserCFG.orbitHeight = v end })
    gb2:AddSlider("RiotAbuserBounceHeight", { Text = "Bounce Height", Default = 5, Min = 1, Max = 100, Rounding = 1,
        Callback = function(v) riotAbuserCFG.bounceHeight = v end })
    gb2:AddSlider("RiotAbuserBounceSpeed", { Text = "Bounce Speed", Default = 8, Min = 1, Max = 50, Rounding = 1,
        Callback = function(v) riotAbuserCFG.bounceSpeed = v end })
    gb2:AddSlider("RiotAbuserPhaseOffset", { Text = "Phase Offset", Default = 3, Min = 0, Max = 30, Rounding = 1,
        Callback = function(v) riotAbuserCFG.phaseOffset = v end })
    gb2:AddSlider("RiotAbuserSpinSpeed", { Text = "Spin Speed", Default = 360, Min = 10, Max = 3600, Rounding = 0,
        Callback = function(v) riotAbuserCFG.spinSpeed = v end })
    AddBindableToggle(gb2, "RiotAbuserSpinOnTarget", "Spin On Target", false, function(v) riotAbuserCFG.spinOnTarget = v end)
    AddBindableToggle(gb2, "RiotAbuserForceFace", "Force Face Target", true, function(v) riotAbuserCFG.forceFaceTarget = v end)
    AddBindableToggle(gb2, "RiotAbuserMultiTarget", "Multi-Target", false, function(v) riotAbuserCFG.multiTarget = v end)
    AddBindableToggle(gb2, "RiotAbuserRandomOffset", "Random Offset", false, function(v) riotAbuserCFG.randomOffset = v end)
    gb2:AddSlider("RiotAbuserRandOffAmp", { Text = "Random Offset Amp", Default = 2, Min = 0, Max = 20, Rounding = 1,
        Callback = function(v) riotAbuserCFG.randomOffAmp = v end })
    AddBindableToggle(gb2, "RiotAbuserPredictTarget", "Predict Target", false, function(v) riotAbuserCFG.predictTarget = v end)
    gb2:AddSlider("RiotAbuserPredictLead", { Text = "Predict Lead", Default = 10, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) riotAbuserCFG.predictLead = v * 0.01 end })
    AddBindableToggle(gb2, "RiotAbuserAutoShoot", "Auto Shoot", true, function(v) riotAbuserCFG.autoShoot = v end)
    AddBindableToggle(gb2, "RiotAbuserNoClip", "NoClip", true, function(v) riotAbuserCFG.raNoClip = v; riotAbuserCFG.noClip = v end)
    AddBindableToggle(gb2, "RiotAbuserNetworkOwn", "Network Own", true, function(v) riotAbuserCFG.raNetworkOwn = v; riotAbuserCFG.networkOwn = v end)
    AddBindableToggle(gb2, "RiotAbuserVelZero", "Vel Zero", true, function(v) riotAbuserCFG.raVelZero = v end)
    AddBindableToggle(gb2, "RiotAbuserFastTp", "Fast TP Burst", true, function(v) riotAbuserCFG.raFastTp = v end)
    AddBindableToggle(gb2, "RiotAbuserAntiKick", "Anti-Kick", true, function(v) riotAbuserCFG.raAntiKick = v end)
    AddBindableToggle(gb2, "RiotAbuserBypassAC", "Bypass Anticheat", true, function(v) riotAbuserCFG.raBypassAnticheat = v end)
    AddBindableToggle(gb2, "RiotAbuserOrbitEnabled", "Orbit Height Override", false, function(v) riotAbuserCFG.orbitEnabled = v end)
end

-- ── UI: Misc / Range ──────────────────────────────────────────────────────────
do
    local gb = WT.Range:AddLeftGroupbox("Range Extender")
    AddBindableToggle(gb, "RangeExtEnabled", "Range Ext", false, function(v)
        rangeExtCFG.enabled = v
        if v then startRangeExt() else stopRangeExt() end
    end)
    gb:AddSlider("RangeExtHitbox", { Text = "Hitbox Size", Default = 500, Min = 10, Max = 2000, Rounding = 0,
        Callback = function(v) rangeExtCFG.hitboxSize = v end })
    gb:AddToggle("RangeExtAutoShoot", { Text = "Auto Shoot", Default = true,
        Callback = function(v) rangeExtCFG.autoShoot = v end })
end

-- ── UI: Setting / Config ──────────────────────────────────────────────────────
do
    local gb = WT.Config:AddLeftGroupbox("UNCODE")
    gb:AddLabel("UNCODE v1.0  |  rivals.gg")
    gb:AddButton({ Text = "Unload", Func = function()
        for _, conn in pairs(conns) do if conn then conn:Disconnect() end end
        if desyncHB then desyncHB:Disconnect() end
        if desyncRS then desyncRS:Disconnect() end
        if translocConn then translocConn:Disconnect() end
        if translocPreRender then translocPreRender:Disconnect() end
        if slingConn then slingConn:Disconnect() end
        if rangeExtHB then rangeExtHB:Disconnect() end
        Library:Unload()
    end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UNCODE Visual System  (ESP / Chams / Aura / World / HitFX / Tracers / Cam)
-- Extracted from Rivals_Visuals.lua + Kicia ESP
-- ════════════════════════════════════════════════════════════════════════════

local Lighting     = game:GetService("Lighting")
local CoreGui      = game:GetService("CoreGui")
local Debris       = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local GuiService   = game:GetService("GuiService")

local function VNew(class, props, parent)
    local ok, inst = pcall(Instance.new, class)
    if not ok or not inst then return nil end
    for k, v in pairs(props or {}) do pcall(function() inst[k] = v end) end
    if parent then pcall(function() inst.Parent = parent end) end
    return inst
end

local vConns = {}
local function VBind(conn) if conn then table.insert(vConns, conn) end; return conn end

local function VGetChar()
    local lp = Players.LocalPlayer
    return lp and lp.Character
end

-- ── Visual Config ─────────────────────────────────────────────────────────
local VC = {
    ESP = {
        Box = false, BoxFill = Color3.fromRGB(140, 230, 105),
        Skeleton = false, SkelC = Color3.fromRGB(255, 255, 255),
        Outline = false, Thickness = 2,
        Name = false, NameA = Color3.fromRGB(255, 255, 255),
        Watermark = false, WatermarkText = "UNCODE", WatermarkColor = Color3.fromRGB(184, 172, 255),
        Weapon = false, Distance = false,
        Healthbar = false, HB_A = Color3.fromRGB(120, 230, 80),
        IncludeTeam = false, MaxDistance = 1200,
    },
    Chams = {
        Self = false, SelfColor = Color3.fromRGB(184, 172, 255), SelfMat = "Neon", SelfTrans = 95,
        Enemy = false, EnemyColor = Color3.fromRGB(255, 60, 60), EnemyMat = "Neon", EnemyTrans = 70,
    },
    Aura = {
        Enabled = false, Mode = "Cyber Blue", RGB = false, Intensity = 1, Size = 1,
        Light = true, Ring = true, Trail = true, Pulse = true,
    },
    World = {
        Enabled = false,
        Ambient = Color3.fromRGB(40, 80, 255), FogColor = Color3.fromRGB(80, 40, 255),
        UseFogEnd = false, FogEnd = 995, UseExposure = true, Exposure = -0.2,
        UseBright = true, Bright = 3.7, UseClock = true, Clock = 11.6, Shadows = false,
    },
    Crosshair = {
        Enabled = false, Gap = 8, Size = 17, Thick = 1,
        RGB = true, RotSpeed = 150, Pulse = true, Color = Color3.fromRGB(255, 255, 255),
    },
    HitFX = {
        Enabled = false, Numbers = true, Material = "ForceField",
    },
    HitSound = { Enabled = false, Selected = "bell", Volume = 5, Pitch = 1 },
    Tracers = {
        Enabled = false,
        OC1 = Color3.fromRGB(140, 90, 255), OC2 = Color3.fromRGB(80, 150, 255),
        Selected = "trail", Lifetime = 0.3, Size = 1, Length = 4, Emission = 1, Glow = 5, Speed = 5,
    },
    TargetHUD = { Enabled = false },
    Cam = { AntiFlash = false, FOVOn = false, FOV = 70, Blur = 0 },
}

-- ── Aura ─────────────────────────────────────────────────────────────────
local AuraPresets = {
    ["Cyber Blue"]   = { Color3.fromRGB(0,170,255),  Color3.fromRGB(0,255,255) },
    ["Blood Red"]    = { Color3.fromRGB(255,20,40),   Color3.fromRGB(255,120,0) },
    ["Venom Green"]  = { Color3.fromRGB(0,255,120),   Color3.fromRGB(180,255,0) },
    ["Royal Purple"] = { Color3.fromRGB(150,0,255),   Color3.fromRGB(255,0,200) },
    ["Sun God"]      = { Color3.fromRGB(255,200,0),   Color3.fromRGB(255,90,0) },
    ["Shadow"]       = { Color3.fromRGB(20,20,25),    Color3.fromRGB(120,0,255) },
}
local AuraObjs = {}
local AuraHRP  = nil
local VState   = { Hue = 0, CrossTick = 0, TracerLast = 0, TracerPool = {},
                   ESPGui = {}, ESPLast = 0, FXLast = 0, HUDLast = 0, DmgConns = {} }

local function ClearAura()
    for _, obj in pairs(AuraObjs) do pcall(function() obj:Destroy() end) end
    AuraObjs = {}; AuraHRP = nil
end

local function BuildAura(c)
    ClearAura()
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    AuraHRP = hrp
    local preset = AuraPresets[VC.Aura.Mode] or AuraPresets["Cyber Blue"]
    local c1, c2 = preset[1], preset[2]
    local inten = math.clamp(VC.Aura.Intensity, 0.1, 5)
    local sz = math.clamp(VC.Aura.Size, 0.1, 5)
    if VC.Aura.Light then
        AuraObjs.L = VNew("PointLight", { Color = c1, Brightness = 3*inten, Range = 20*sz }, hrp)
    end
    if VC.Aura.Trail then
        local a0 = VNew("Attachment", { Position = Vector3.new(0,1,0) }, hrp)
        local a1 = VNew("Attachment", { Position = Vector3.new(0,-1,0) }, hrp)
        local tr = VNew("Trail", {
            Color = ColorSequence.new({ ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2) }),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,1) }),
            LightEmission = inten, LightInfluence = 0, MinLength = 0, Lifetime = 0.3,
            FaceCamera = true, WidthScale = NumberSequence.new(sz),
        }, hrp)
        tr.Attachment0 = a0; tr.Attachment1 = a1
        AuraObjs.T = tr; AuraObjs.A0 = a0; AuraObjs.A1 = a1
    end
    if VC.Aura.Ring then
        AuraObjs.Ring = VNew("Part", {
            Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
            Size = Vector3.new(0.2, 6.5*sz, 6.5*sz), Shape = Enum.PartType.Cylinder,
            Material = Enum.Material.Neon, Color = c1,
            Transparency = math.clamp(0.6 - inten*0.05, 0.1, 0.9),
            CFrame = hrp.CFrame * CFrame.new(0,-3.05,0) * CFrame.Angles(0,0,math.rad(90)),
        }, workspace)
    end
    if VC.Aura.Pulse then
        AuraObjs.P1 = VNew("ParticleEmitter", {
            Color = ColorSequence.new({ ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2) }),
            LightEmission = inten, LightInfluence = 0,
            Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.4*sz), NumberSequenceKeypoint.new(1,0) }),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,1) }),
            Lifetime = NumberRange.new(0.5,1.2), Rate = 30*inten,
            Speed = NumberRange.new(2*sz, 6*sz), SpreadAngle = Vector2.new(180,180),
            RotSpeed = NumberRange.new(-100,100), Rotation = NumberRange.new(0,360),
        }, hrp)
    end
end

-- ── World / Lighting ──────────────────────────────────────────────────────
local WorldBackup = {}
local function BackupWorld()
    WorldBackup.Ambient    = Lighting.Ambient
    WorldBackup.FogColor   = Lighting.FogColor
    WorldBackup.FogEnd     = Lighting.FogEnd
    WorldBackup.Exposure   = Lighting.ExposureCompensation
    WorldBackup.Brightness = Lighting.Brightness
    WorldBackup.ClockTime  = Lighting.ClockTime
    WorldBackup.Shadows    = Lighting.GlobalShadows
end
local function ApplyWorld()
    if not VC.World.Enabled then return end
    Lighting.Ambient  = VC.World.Ambient
    Lighting.FogColor = VC.World.FogColor
    if VC.World.UseFogEnd   then Lighting.FogEnd = VC.World.FogEnd end
    if VC.World.UseExposure then Lighting.ExposureCompensation = VC.World.Exposure end
    if VC.World.UseBright   then Lighting.Brightness = VC.World.Bright end
    if VC.World.UseClock    then Lighting.ClockTime = VC.World.Clock end
    Lighting.GlobalShadows = VC.World.Shadows
end
local function RestoreWorld()
    if not WorldBackup.Ambient then return end
    Lighting.Ambient               = WorldBackup.Ambient
    Lighting.FogColor              = WorldBackup.FogColor
    Lighting.FogEnd                = WorldBackup.FogEnd
    Lighting.ExposureCompensation  = WorldBackup.Exposure
    Lighting.Brightness            = WorldBackup.Brightness
    Lighting.ClockTime             = WorldBackup.ClockTime
    Lighting.GlobalShadows         = WorldBackup.Shadows
end
BackupWorld()

-- ── Self Chams ────────────────────────────────────────────────────────────
local function ClearSelfChams()
    local c = VGetChar(); if not c then return end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function()
            local oc = p:GetAttribute("UC_OColor")
            local om = p:GetAttribute("UC_OMat")
            local ot = p:GetAttribute("UC_OTrans")
            if oc then p.Color = oc end
            if om and Enum.Material[om] then p.Material = Enum.Material[om] end
            if ot then p.Transparency = ot end
        end) end
    end
end
local function ApplySelfChams()
    local c = VGetChar(); if not c then return end
    local mat   = Enum.Material[VC.Chams.SelfMat] or Enum.Material.Neon
    local trans = math.clamp(VC.Chams.SelfTrans, 0, 99) / 100
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function()
            if not p:GetAttribute("UC_OColor") then
                p:SetAttribute("UC_OColor", p.Color)
                p:SetAttribute("UC_OMat",   tostring(p.Material))
                p:SetAttribute("UC_OTrans", p.Transparency)
            end
            p.Color = VC.Chams.SelfColor; p.Material = mat; p.Transparency = trans
        end) end
    end
end

-- ── Enemy Chams (SelectionBox highlight) ──────────────────────────────────
local enemyHL = {}
local function ClearEnemyChams()
    for _, h in pairs(enemyHL) do pcall(function() h:Destroy() end) end; enemyHL = {}
end
local function RefreshEnemyChams()
    if not VC.Chams.Enemy then ClearEnemyChams(); return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer and p.Character then
            if not enemyHL[p] then
                enemyHL[p] = VNew("SelectionBox", {
                    Color3 = VC.Chams.EnemyColor,
                    LineThickness = 0.05,
                    SurfaceTransparency = math.clamp(VC.Chams.EnemyTrans, 0, 99)/100,
                    SurfaceColor3 = VC.Chams.EnemyColor,
                    Adornee = p.Character,
                }, workspace)
            else pcall(function()
                enemyHL[p].Color3 = VC.Chams.EnemyColor
                enemyHL[p].SurfaceColor3 = VC.Chams.EnemyColor
                enemyHL[p].SurfaceTransparency = math.clamp(VC.Chams.EnemyTrans,0,99)/100
            end) end
        end
    end
    for p, h in pairs(enemyHL) do
        if not p.Parent or not p.Character then
            pcall(function() h:Destroy() end); enemyHL[p] = nil
        end
    end
end

-- ── ESP ───────────────────────────────────────────────────────────────────
local visGui = VNew("ScreenGui", {
    Name = "UC_VIS", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998,
}, CoreGui)

local function ClearESP(p)
    local f = VState.ESPGui[p]
    if f then pcall(function() f:Destroy() end); VState.ESPGui[p] = nil end
    local hl = VState.ESPGui[p.Name.."_hl"]
    if hl then pcall(function() hl:Destroy() end); VState.ESPGui[p.Name.."_hl"] = nil end
    VState.ESPGui[p.Name.."_refs"] = nil
    VState.ESPGui[p.Name.."_char"] = nil
end

local function MakeESP(p)
    ClearESP(p)
    local c = p.Character; if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local root = VNew("BillboardGui", {
        Name = "UC_ESP_"..p.Name, Adornee = hrp,
        Size = UDim2.new(0,120,0,96), StudsOffset = Vector3.new(0,2.5,0), AlwaysOnTop = true,
    }, visGui)
    VState.ESPGui[p] = root
    local box = VNew("Frame", {
        Size = UDim2.new(0,60,0,60), Position = UDim2.new(0.5,-30,0,26),
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = VC.ESP.Box,
    }, root)
    local corners = {}
    do
        local T = math.max(1, math.floor(VC.ESP.Thickness)); local L = 14
        for _, d in pairs({
            {0,0,L,T},{0,0,T,L},{60-L,0,L,T},{60-T,0,T,L},
            {0,60-T,L,T},{0,60-T,T,L},{60-L,60-T,L,T},{60-T,60-T,T,L},
        }) do
            table.insert(corners, VNew("Frame", {
                Size = UDim2.new(0,d[3],0,d[4]), Position = UDim2.new(0,d[1],0,d[2]),
                BackgroundColor3 = VC.ESP.BoxFill, BorderSizePixel = 0,
            }, box))
        end
    end
    local nl  = VNew("TextLabel", { Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,0,0), BackgroundTransparency=1, Font=Enum.Font.Code, TextSize=12, TextColor3=VC.ESP.NameA, TextStrokeTransparency=0.3, Text=p.Name, Visible=VC.ESP.Name }, root)
    local wl  = VNew("TextLabel", { Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0,14), BackgroundTransparency=1, Font=Enum.Font.Code, TextSize=10, TextColor3=Color3.fromRGB(180,180,180), TextStrokeTransparency=0.4, Text="", Visible=VC.ESP.Weapon }, root)
    local dl  = VNew("TextLabel", { Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,1,-26), BackgroundTransparency=1, Font=Enum.Font.Code, TextSize=10, TextColor3=Color3.fromRGB(150,150,150), Text="", Visible=VC.ESP.Distance }, root)
    local wm  = VNew("TextLabel", { Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,1,-13), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=VC.ESP.WatermarkColor, TextStrokeTransparency=0.3, Text=VC.ESP.WatermarkText, Visible=VC.ESP.Watermark }, root)
    local hbBG  = VNew("Frame", { Size=UDim2.new(0,4,0,56), Position=UDim2.new(0.5,-37,0,28), BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0, Visible=VC.ESP.Healthbar }, root)
    local hbFill = VNew("Frame", { Size=UDim2.new(1,0,1,0), BackgroundColor3=VC.ESP.HB_A, BorderSizePixel=0 }, hbBG)
    local hl = nil
    if VC.ESP.Skeleton or VC.ESP.Outline then
        hl = VNew("Highlight", {
            FillColor=VC.ESP.BoxFill, OutlineColor=VC.ESP.SkelC,
            FillTransparency=VC.ESP.Box and 0.7 or 1, OutlineTransparency=0.1,
            DepthMode=Enum.HighlightDepthMode.Occluded, Adornee=c,
        }, visGui)
    end
    VState.ESPGui[p.Name.."_hl"]   = hl
    VState.ESPGui[p.Name.."_refs"] = { box=box, corners=corners, name=nl, weap=wl, dist=dl, wmark=wm, hbBG=hbBG, hbFill=hbFill, hl=hl, builtThick=math.max(1,math.floor(VC.ESP.Thickness)) }
    VState.ESPGui[p.Name.."_char"] = c
end

local function RefreshESP()
    local now = os.clock(); if now - VState.ESPLast < 0.1 then return end; VState.ESPLast = now
    local anyESP = VC.ESP.Box or VC.ESP.Name or VC.ESP.Weapon or VC.ESP.Distance or VC.ESP.Healthbar or VC.ESP.Skeleton or VC.ESP.Outline or VC.ESP.Watermark
    if not anyESP then
        for _, p in pairs(Players:GetPlayers()) do if VState.ESPGui[p] then ClearESP(p) end end
        return
    end
    local myC = VGetChar(); local myHRP = myC and myC:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p == Players.LocalPlayer then continue end
        if not VC.ESP.IncludeTeam and p.Team == Players.LocalPlayer.Team then ClearESP(p); continue end
        local cn = p.Character; if not cn then ClearESP(p); continue end
        if VState.ESPGui[p.Name.."_char"] ~= cn then MakeESP(p) end
        if not VState.ESPGui[p] then MakeESP(p) end
        local refs = VState.ESPGui[p.Name.."_refs"]; local root = VState.ESPGui[p]
        if refs and refs.builtThick ~= math.max(1,math.floor(VC.ESP.Thickness)) then
            MakeESP(p); refs = VState.ESPGui[p.Name.."_refs"]; root = VState.ESPGui[p]
        end
        if refs and root and root.Parent then
            local hum = cn:FindFirstChildOfClass("Humanoid"); local hrp = cn:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                local show = anyESP and dist <= VC.ESP.MaxDistance
                root.Enabled = show
                if refs.hl then refs.hl.Enabled = (VC.ESP.Skeleton or VC.ESP.Outline or VC.ESP.Box) and show end
                if not show then continue end
                local hp = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                refs.box.Visible = VC.ESP.Box
                for _, cf in pairs(refs.corners or {}) do cf.BackgroundColor3 = VC.ESP.BoxFill end
                refs.name.Visible = VC.ESP.Name; refs.name.Text = p.Name; refs.name.TextColor3 = VC.ESP.NameA
                local t2 = cn:FindFirstChildOfClass("Tool")
                refs.weap.Visible = VC.ESP.Weapon; refs.weap.Text = t2 and t2.Name or ""
                refs.dist.Visible = VC.ESP.Distance; refs.dist.Text = tostring(math.floor(dist)).."m"
                refs.wmark.Visible = VC.ESP.Watermark; refs.wmark.Text = VC.ESP.WatermarkText; refs.wmark.TextColor3 = VC.ESP.WatermarkColor
                refs.hbBG.Visible = VC.ESP.Healthbar
                refs.hbFill.Size = UDim2.new(1,0,hp,0); refs.hbFill.Position = UDim2.new(0,0,1-hp,0)
                refs.hbFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-hp)), math.floor(200*hp+40), 120)
            end
        end
    end
end

-- ── Crosshair ─────────────────────────────────────────────────────────────
local crossGui = VNew("ScreenGui", {
    Name = "UC_CROSS", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 9999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, CoreGui)
local crossSpin = VNew("Frame", {
    Name = "CrossSpin", Size = UDim2.new(0,0,0,0),
    Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 1, Visible = false,
}, crossGui)
local crossLines = {}
for i = 1, 4 do
    crossLines[i] = VNew("Frame", {
        BorderSizePixel = 0, BackgroundColor3 = Color3.white,
        AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 3,
    }, crossSpin)
end
local function UpdateCross(dt)
    crossSpin.Visible = VC.Crosshair.Enabled
    if not VC.Crosshair.Enabled then return end
    VState.CrossTick = (VState.CrossTick or 0) + (dt or 0.016)
    local tick = VState.CrossTick
    crossSpin.Rotation = (crossSpin.Rotation + VC.Crosshair.RotSpeed * (dt or 0.016)) % 360
    local pf  = VC.Crosshair.Pulse and math.sin(tick*3.5) or 0
    local col = VC.Crosshair.RGB and Color3.fromHSV((tick*0.05)%1, 1, 1) or VC.Crosshair.Color
    local len = math.max(1, VC.Crosshair.Size + pf*5)
    local gap = VC.Crosshair.Gap; local th = math.max(1, VC.Crosshair.Thick)
    local geo = {
        {UDim2.new(0,th,0,len), UDim2.new(0,0,0,-gap-len/2)},
        {UDim2.new(0,th,0,len), UDim2.new(0,0,0, gap+len/2)},
        {UDim2.new(0,len,0,th), UDim2.new(0,-gap-len/2,0,0)},
        {UDim2.new(0,len,0,th), UDim2.new(0, gap+len/2,0,0)},
    }
    for i = 1,4 do crossLines[i].Size=geo[i][1]; crossLines[i].Position=geo[i][2]; crossLines[i].BackgroundColor3=col end
end

-- ── HitFX & HitSound ──────────────────────────────────────────────────────
local HitSounds = { bell="rbxassetid://6518811702", pop="rbxassetid://9106153995", tick="rbxassetid://9106202384", fortnite="rbxassetid://9106232005" }
local function PlayHitSound()
    if not VC.HitSound.Enabled then return end
    local s = VNew("Sound", { SoundId=HitSounds[VC.HitSound.Selected] or HitSounds.bell, Volume=math.clamp(VC.HitSound.Volume,0,10), PlaybackSpeed=VC.HitSound.Pitch }, SoundService)
    pcall(function() s:Play() end); Debris:AddItem(s, 2)
end
local function FortniteDmgNum(pos, amount)
    if not VC.HitFX.Numbers then return end
    local part = VNew("Part", { Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false, Transparency=1, Size=Vector3.new(0.5,0.5,0.5), CFrame=CFrame.new(pos) }, workspace)
    local bb = VNew("BillboardGui", { Size=UDim2.new(0,80,0,30), StudsOffset=Vector3.new(math.random(-2,2),3,0), AlwaysOnTop=true, Adornee=part }, workspace)
    Debris:AddItem(part,0.9); Debris:AddItem(bb,0.9)
    local tl = VNew("TextLabel", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=18, TextColor3=Color3.fromRGB(255,220,80), TextStrokeTransparency=0.2, Text=tostring(amount) }, bb)
    task.spawn(function()
        for i=1,20 do task.wait(0.03); pcall(function() part.CFrame=part.CFrame+Vector3.new(0,0.15,0); tl.TextTransparency=i/20; tl.TextStrokeTransparency=i/20 end) end
    end)
end
local function SpawnHitClone(c)
    if not VC.HitFX.Enabled then return end
    pcall(function()
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local clone = VNew("Part", { Size=Vector3.new(2,3,1), CFrame=hrp.CFrame, Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false, Transparency=0.3, Material=Enum.Material[VC.HitFX.Material] or Enum.Material.ForceField, Color=Color3.fromRGB(255,60,60) }, workspace)
        Debris:AddItem(clone,0.6)
        task.spawn(function() for i=1,10 do task.wait(0.05); pcall(function() clone.Transparency=0.3+i*0.07 end) end end)
    end)
end
local hxHooked = {}
local function HookCharDmg(p, c)
    task.spawn(function()
        task.wait(0.3)
        local h = c and c:FindFirstChildOfClass("Humanoid"); if not h then return end
        local old = VState.DmgConns[p]; if old then pcall(function() old:Disconnect() end); VState.DmgConns[p] = nil end
        local last = h.Health
        local conn = h.HealthChanged:Connect(function(nh)
            if not c.Parent then return end
            if nh < last then
                local dmg = math.floor(last-nh); last = nh
                if VC.HitFX.Enabled then
                    local hrp = c:FindFirstChild("HumanoidRootPart"); if hrp then FortniteDmgNum(hrp.Position,dmg) end
                    SpawnHitClone(c); PlayHitSound()
                end
            else last = nh end
        end)
        VState.DmgConns[p] = conn; table.insert(vConns, conn)
    end)
end
local function HookPlayerDmg(p)
    if hxHooked[p] then return end; hxHooked[p] = true
    if p.Character then HookCharDmg(p, p.Character) end
    VBind(p.CharacterAdded:Connect(function(c) HookCharDmg(p,c) end))
end
for _, p in pairs(Players:GetPlayers()) do HookPlayerDmg(p) end
VBind(Players.PlayerAdded:Connect(HookPlayerDmg))

-- ── Tracers ───────────────────────────────────────────────────────────────
local TracerPool = {}; local TracerLast = 0
local function SpawnTracer(fromPos, toPos)
    if not VC.Tracers.Enabled then return end
    local now = os.clock(); if now - TracerLast < 0.04 then return end; TracerLast = now
    local life = math.clamp(VC.Tracers.Lifetime, 0.05, 2)
    local fade = math.clamp(0.3*(5/math.max(VC.Tracers.Speed,0.5)), 0.05, 3)
    local wBase = 0.25 * VC.Tracers.Size * (0.6 + VC.Tracers.Length/4)
    if #TracerPool >= 30 then
        local old = table.remove(TracerPool,1); pcall(function() if old and old.Parent then old:Destroy() end end)
    end
    local holder = VNew("Part", { Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,Size=Vector3.new(0.5,0.5,0.5),CFrame=CFrame.new(fromPos),Name="UC_Trace" }, workspace)
    table.insert(TracerPool, holder)
    local a0 = VNew("Attachment",{Position=Vector3.new(0,0,0)},holder)
    local a1 = VNew("Attachment",{Position=Vector3.new(0,0,0)},holder); pcall(function() a1.WorldPosition=toPos end)
    local beam = VNew("Beam", {
        Attachment0=a0,Attachment1=a1,
        Color=ColorSequence.new({ColorSequenceKeypoint.new(0,VC.Tracers.OC1),ColorSequenceKeypoint.new(1,VC.Tracers.OC2)}),
        Transparency=NumberSequence.new(0), Width0=wBase, Width1=wBase,
        LightEmission=math.clamp(VC.Tracers.Glow+VC.Tracers.Emission,0,10), LightInfluence=0, FaceCamera=true,
    }, holder)
    Debris:AddItem(holder, life+fade+0.5)
    task.spawn(function()
        local t=0; while t<fade and beam.Parent do t=t+task.wait(); pcall(function() beam.Transparency=NumberSequence.new(t/fade) end) end
        pcall(function() holder:Destroy() end)
    end)
end
local TRayParams = RaycastParams.new(); TRayParams.FilterType=Enum.RaycastFilterType.Exclude; TRayParams.IgnoreWater=true
VBind(RunService.Heartbeat:Connect(function(dt)
    if not VC.Tracers.Enabled then return end
    if (dt or 0) > 0.05 then return end
    local now = os.clock(); if now - TracerLast < 0.06 then return end
    local pressed = false; pcall(function() pressed=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
    if not pressed then return end
    local cam = workspace.CurrentCamera; local c = VGetChar(); if not cam or not c then return end
    TracerLast = now; TRayParams.FilterDescendantsInstances={c,cam}
    local origin = cam.CFrame.Position; local dir = cam.CFrame.LookVector*1000; local hitPos=origin+dir
    pcall(function() local res=workspace:Raycast(origin,dir,TRayParams); if res and res.Position then hitPos=res.Position end end)
    SpawnTracer((cam.CFrame*CFrame.new(0.45,-0.35,-1.5)).Position, hitPos)
end))

-- ── Target HUD ────────────────────────────────────────────────────────────
local hudGui = VNew("ScreenGui", { Name="UC_HUD", ResetOnSpawn=false, DisplayOrder=997, ZIndexBehavior=Enum.ZIndexBehavior.Sibling }, CoreGui)
local hud    = VNew("Frame", { Name="TargetHUD", Size=UDim2.new(0,220,0,64), Position=UDim2.new(0.5,-110,0,10), BackgroundColor3=Color3.fromRGB(15,15,15), BorderSizePixel=0, Visible=false }, hudGui)
VNew("UICorner",{CornerRadius=UDim.new(0,6)},hud); VNew("UIStroke",{Color=Color3.fromRGB(80,60,150),Thickness=1,Transparency=0.3},hud)
local hudName = VNew("TextLabel",{Size=UDim2.new(1,-10,0,18),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=12,TextColor3=Color3.fromRGB(220,220,220),TextXAlignment=Enum.TextXAlignment.Left,Text="target: -"},hud)
local hudInfo = VNew("TextLabel",{Size=UDim2.new(1,-10,0,16),Position=UDim2.new(0,5,0,22),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=11,TextColor3=Color3.fromRGB(150,150,150),TextXAlignment=Enum.TextXAlignment.Left,Text="hp: -  dist: -"},hud)
local hudBar  = VNew("Frame",{Size=UDim2.new(1,-10,0,8),Position=UDim2.new(0,5,0,42),BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0},hud)
local hudFill = VNew("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(140,90,255),BorderSizePixel=0},hudBar)

-- ── Visual main loops ─────────────────────────────────────────────────────
VBind(RunService.RenderStepped:Connect(function(dt)
    UpdateCross(dt)
    if VC.Aura.Enabled and AuraObjs.Ring and AuraHRP and AuraHRP.Parent then
        pcall(function()
            AuraObjs.Ring.CFrame = AuraHRP.CFrame * CFrame.new(0,-3.05,0) * CFrame.Angles(0,0,math.rad(90))
            if VC.Aura.Pulse then
                local s = 6.5*VC.Aura.Size*(0.9+0.15*math.sin(os.clock()*4))
                AuraObjs.Ring.Size = Vector3.new(0.2,s,s)
            end
        end)
    end
    if VC.Aura.RGB and AuraObjs.L and AuraObjs.L.Parent then
        VState.Hue = (VState.Hue+0.005)%1
        local cc = Color3.fromHSV(VState.Hue,0.9,1)
        pcall(function()
            AuraObjs.L.Color=cc
            if AuraObjs.Ring then AuraObjs.Ring.Color=cc end
            if AuraObjs.P1 then AuraObjs.P1.Color=ColorSequence.new(cc) end
        end)
    end
    if VC.Cam.FOVOn then pcall(function() workspace.CurrentCamera.FieldOfView=VC.Cam.FOV end) end
    local now = os.clock()
    if now - VState.FXLast > 1 then
        VState.FXLast = now
        local blurFx = Lighting:FindFirstChild("UC_Blur")
        if VC.Cam.Blur > 0.01 then
            if not blurFx then blurFx=Instance.new("BlurEffect"); blurFx.Name="UC_Blur"; blurFx.Parent=Lighting end
            pcall(function() blurFx.Size=math.clamp(VC.Cam.Blur*10,0,30); blurFx.Enabled=true end)
        else if blurFx then pcall(function() blurFx.Enabled=false end) end end
        if VC.Cam.AntiFlash then
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") and v.Name~="UC_Blur" and v.Size>10 then pcall(function() v.Enabled=false end) end
            end
        end
        if VC.World.Enabled then ApplyWorld() end
    end
    if now - VState.HUDLast > 0.1 then
        VState.HUDLast = now
        if VC.TargetHUD.Enabled then
            local best, bestD = nil, 1e9
            local myC=VGetChar(); local myHRP=myC and myC:FindFirstChild("HumanoidRootPart")
            for _, p in pairs(Players:GetPlayers()) do
                if p==Players.LocalPlayer then continue end
                local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then local d=(hrp.Position-myHRP.Position).Magnitude; if d<bestD then bestD=d; best=p end end
            end
            hud.Visible=true
            if best then
                local h=best.Character:FindFirstChildOfClass("Humanoid"); local hp=h and math.floor(h.Health) or 0; local mx=h and h.MaxHealth or 100
                hudName.Text="target: "..best.Name; hudInfo.Text="hp: "..hp.."  dist: "..math.floor(bestD).."m"
                hudFill.Size=UDim2.new(math.clamp(hp/mx,0,1),0,1,0)
            else hudName.Text="target: -"; hudInfo.Text="hp: -  dist: -"; hudFill.Size=UDim2.new(0,0,1,0) end
        else hud.Visible=false end
    end
end))
VBind(RunService.RenderStepped:Connect(RefreshESP))
VBind(Players.PlayerRemoving:Connect(function(p) ClearESP(p) end))
VBind(RunService.Heartbeat:Connect(function()
    local now=os.clock(); if now-(VState.ChamLast or 0)<0.25 then return end; VState.ChamLast=now
    if VC.Chams.Self then pcall(ApplySelfChams) else pcall(ClearSelfChams) end
    pcall(RefreshEnemyChams)
end))
VBind(Players.LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.6)
    if VC.Aura.Enabled then BuildAura(c) end
    if VC.Chams.Self then ApplySelfChams() end
end))

-- ═════════════════════════════════════════════════════════════════════════
-- UI WIRING: ESP / Visual tabs
-- ═════════════════════════════════════════════════════════════════════════

-- ── UI: ESP tab ──────────────────────────────────────────────────────────
do
    local gbL = WT.ESP:AddLeftGroupbox("ESP Draw")
    gbL:AddToggle("ESPBox",      { Text="Box",           Default=false, Callback=function(v) VC.ESP.Box=v end })
    gbL:AddToggle("ESPSkeleton", { Text="Skeleton/Outline",Default=false,Callback=function(v) VC.ESP.Skeleton=v end })
    gbL:AddToggle("ESPName",     { Text="Name",          Default=false, Callback=function(v) VC.ESP.Name=v end })
    gbL:AddToggle("ESPWeapon",   { Text="Weapon",        Default=false, Callback=function(v) VC.ESP.Weapon=v end })
    gbL:AddToggle("ESPDistance", { Text="Distance",      Default=false, Callback=function(v) VC.ESP.Distance=v end })
    gbL:AddToggle("ESPHealth",   { Text="Healthbar",     Default=false, Callback=function(v) VC.ESP.Healthbar=v end })
    gbL:AddToggle("ESPWatermark",{ Text="Watermark",     Default=false, Callback=function(v) VC.ESP.Watermark=v end })
    gbL:AddToggle("ESPTeam",     { Text="Include Team",  Default=false, Callback=function(v) VC.ESP.IncludeTeam=v end })
    gbL:AddSlider("ESPMaxDist",  { Text="Max Distance",  Default=1200, Min=100, Max=5000, Rounding=0, Callback=function(v) VC.ESP.MaxDistance=v end })
    gbL:AddSlider("ESPThick",    { Text="Box Thickness", Default=2,    Min=1,   Max=6,    Rounding=0, Callback=function(v) VC.ESP.Thickness=v end })
    local gbR = WT.ESP:AddRightGroupbox("Target HUD")
    gbR:AddToggle("HUDEnabled",  { Text="Target HUD",   Default=false, Callback=function(v) VC.TargetHUD.Enabled=v end })
    gbR:AddLabel("Closest enemy HP + distance")
end

-- ── UI: Visual / Chams ───────────────────────────────────────────────────
do
    local gbL = WT.Chams:AddLeftGroupbox("Self Chams")
    gbL:AddToggle("SelfChamOn",  { Text="Enable",        Default=false, Callback=function(v) VC.Chams.Self=v; if not v then pcall(ClearSelfChams) end end })
    gbL:AddDropdown("SelfChamMat",{ Text="Material",     Default=1, Values={"Neon","ForceField","SmoothPlastic","Glass"}, Callback=function(v) VC.Chams.SelfMat=v end })
    gbL:AddSlider("SelfChamTrans",{ Text="Transparency",  Default=95, Min=0, Max=99, Rounding=0, Callback=function(v) VC.Chams.SelfTrans=v end })
    local gbR = WT.Chams:AddRightGroupbox("Enemy Chams")
    gbR:AddToggle("EnemyChamOn", { Text="Enable",         Default=false, Callback=function(v) VC.Chams.Enemy=v; if not v then pcall(ClearEnemyChams) end end })
    gbR:AddDropdown("EnemyChamMat",{Text="Material",      Default=1, Values={"Neon","ForceField","SmoothPlastic","Glass"}, Callback=function(v) VC.Chams.EnemyMat=v end })
    gbR:AddSlider("EnemyChamTrans",{Text="Transparency",  Default=70, Min=0, Max=99, Rounding=0, Callback=function(v) VC.Chams.EnemyTrans=v end })
end

-- ── UI: Visual / Effects ─────────────────────────────────────────────────
do
    local gbA = WT.FX:AddLeftGroupbox("Aura")
    gbA:AddToggle("AuraOn",   { Text="Aura",     Default=false, Callback=function(v) VC.Aura.Enabled=v; if v then BuildAura(VGetChar()) else ClearAura() end end })
    gbA:AddDropdown("AuraMod",{ Text="Preset",   Default=1, Values={"Cyber Blue","Blood Red","Venom Green","Royal Purple","Sun God","Shadow"}, Callback=function(v) VC.Aura.Mode=v; if VC.Aura.Enabled then BuildAura(VGetChar()) end end })
    gbA:AddToggle("AuraRGB",  { Text="RGB Cycle",Default=false, Callback=function(v) VC.Aura.RGB=v end })
    gbA:AddToggle("AuraPulse",{ Text="Pulse",    Default=true,  Callback=function(v) VC.Aura.Pulse=v end })
    gbA:AddToggle("AuraRing", { Text="Ring",     Default=true,  Callback=function(v) VC.Aura.Ring=v; if VC.Aura.Enabled then BuildAura(VGetChar()) end end })
    gbA:AddToggle("AuraTrail",{ Text="Trail",    Default=true,  Callback=function(v) VC.Aura.Trail=v; if VC.Aura.Enabled then BuildAura(VGetChar()) end end })
    gbA:AddToggle("AuraLight",{ Text="Light",    Default=true,  Callback=function(v) VC.Aura.Light=v; if VC.Aura.Enabled then BuildAura(VGetChar()) end end })
    gbA:AddSlider("AuraSize", { Text="Size",     Default=10, Min=1, Max=50, Rounding=0, Callback=function(v) VC.Aura.Size=v/10 end })
    gbA:AddSlider("AuraInten",{ Text="Intensity",Default=10, Min=1, Max=50, Rounding=0, Callback=function(v) VC.Aura.Intensity=v/10 end })

    local gbW = WT.FX:AddRightGroupbox("World & Camera")
    gbW:AddToggle("WorldOn",     { Text="World Effects",Default=false, Callback=function(v) VC.World.Enabled=v; if v then ApplyWorld() else RestoreWorld() end end })
    gbW:AddSlider("WorldBright", { Text="Brightness",   Default=37, Min=0, Max=100, Rounding=0, Callback=function(v) VC.World.Bright=v/10; if VC.World.Enabled then ApplyWorld() end end })
    gbW:AddSlider("WorldClock",  { Text="Time of Day",  Default=116,Min=0, Max=240, Rounding=0, Callback=function(v) VC.World.Clock=v/10; if VC.World.Enabled then ApplyWorld() end end })
    gbW:AddToggle("WorldShadows",{ Text="Shadows",      Default=false, Callback=function(v) VC.World.Shadows=v; if VC.World.Enabled then ApplyWorld() end end })
    gbW:AddToggle("CamFOVOn",    { Text="Custom FOV",   Default=false, Callback=function(v) VC.Cam.FOVOn=v end })
    gbW:AddSlider("CamFOV",      { Text="FOV",          Default=70, Min=30, Max=120, Rounding=0, Callback=function(v) VC.Cam.FOV=v end })
    gbW:AddToggle("CamAntiFlash",{ Text="Anti-Flash",   Default=false, Callback=function(v) VC.Cam.AntiFlash=v end })
    gbW:AddSlider("CamBlur",     { Text="Blur",         Default=0,  Min=0, Max=30,  Rounding=0, Callback=function(v) VC.Cam.Blur=v/10 end })

    local gbH = WT.FX:AddLeftGroupbox("HitFX")
    gbH:AddToggle("HitFXOn",    { Text="Hit FX",        Default=false, Callback=function(v) VC.HitFX.Enabled=v end })
    gbH:AddToggle("HitFXNums",  { Text="Damage Numbers",Default=true,  Callback=function(v) VC.HitFX.Numbers=v end })
    gbH:AddDropdown("HitFXMat", { Text="Clone Material",Default=1, Values={"ForceField","Neon","SmoothPlastic","Glass"}, Callback=function(v) VC.HitFX.Material=v end })
    gbH:AddToggle("HitSndOn",   { Text="Hit Sound",     Default=false, Callback=function(v) VC.HitSound.Enabled=v end })
    gbH:AddDropdown("HitSndSel",{ Text="Sound",         Default=1, Values={"bell","pop","tick","fortnite"}, Callback=function(v) VC.HitSound.Selected=v end })
    gbH:AddSlider("HitSndVol",  { Text="Volume",        Default=5, Min=0, Max=10, Rounding=1, Callback=function(v) VC.HitSound.Volume=v end })

    local gbT = WT.FX:AddRightGroupbox("Tracers")
    gbT:AddToggle("TracerOn",   { Text="Tracers",   Default=false, Callback=function(v) VC.Tracers.Enabled=v end })
    gbT:AddDropdown("TracerSty",{ Text="Style",     Default=1, Values={"trail","beam","glow","energy"}, Callback=function(v) VC.Tracers.Selected=v end })
    gbT:AddSlider("TracerLife", { Text="Lifetime",  Default=3, Min=1, Max=20, Rounding=0, Callback=function(v) VC.Tracers.Lifetime=v/10 end })
    gbT:AddSlider("TracerSize", { Text="Size",      Default=10,Min=1, Max=50, Rounding=0, Callback=function(v) VC.Tracers.Size=v/10 end })
    gbT:AddSlider("TracerGlow", { Text="Glow",      Default=5, Min=0, Max=10, Rounding=1, Callback=function(v) VC.Tracers.Glow=v end })

    local gbX = WT.FX:AddLeftGroupbox("Crosshair")
    gbX:AddToggle("CrossOn",    { Text="Crosshair", Default=false, Callback=function(v) VC.Crosshair.Enabled=v end })
    gbX:AddToggle("CrossRGB",   { Text="RGB",       Default=true,  Callback=function(v) VC.Crosshair.RGB=v end })
    gbX:AddToggle("CrossPulse", { Text="Pulse",     Default=true,  Callback=function(v) VC.Crosshair.Pulse=v end })
    gbX:AddSlider("CrossSize",  { Text="Size",      Default=17, Min=2, Max=60, Rounding=0, Callback=function(v) VC.Crosshair.Size=v end })
    gbX:AddSlider("CrossGap",   { Text="Gap",       Default=8,  Min=0, Max=40, Rounding=0, Callback=function(v) VC.Crosshair.Gap=v end })
    gbX:AddSlider("CrossThick", { Text="Thickness", Default=1,  Min=1, Max=8,  Rounding=0, Callback=function(v) VC.Crosshair.Thick=v end })
    gbX:AddSlider("CrossSpd",   { Text="Spin Speed",Default=150,Min=0, Max=720,Rounding=0, Callback=function(v) VC.Crosshair.RotSpeed=v end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UNCODE — Kicia / UE Features
-- Aimbot · SilentAim · Triggerbot · Flickbot · AutoMisc · Detector
-- ════════════════════════════════════════════════════════════════════════════

-- ── New sub-tabs ─────────────────────────────────────────────────────────────
WT.Aim    = TB.Combat:AddTab("Aimbot")
WT.Bot    = TB.Combat:AddTab("Bots")
WT.Auto   = TB.Misc:AddTab("Auto")
WT.Detect = TB.Misc:AddTab("Detect")

-- ── Executor capability detection ────────────────────────────────────────────
local function exFn(name)
    local ok, v = pcall(function() return getfenv(0)[name] end)
    if ok and type(v) == "function" then return v end
    local ok2, v2 = pcall(function() return getgenv()[name] end)
    if ok2 and type(v2) == "function" then return v2 end
end
local hookfn    = exFn("hookfunction") or exFn("replaceclosure")
local clonefn2  = exFn("clonefunction")
local getconns  = exFn("getconnections")

-- ── Kicia config block ────────────────────────────────────────────────────────
local KC = {
    Aimbot = {
        Enabled = false, Key = Enum.KeyCode.Unknown, KeyMode = "Hold",
        FOV = 120, Humanness = 0.25, HitboxPoint = "Head",
        TargetLock = false, PrioritizeClosest = true,
        WithinFOV = true, TeamCheck = true,
    },
    SilentAim = {
        Enabled = false, Key = Enum.KeyCode.Unknown, KeyMode = "Always",
        FOV = 180, HitboxPoint = "Head",
        Chance = 100, ShowIndicator = true,
    },
    Triggerbot = {
        Enabled = false, Key = Enum.KeyCode.Unknown, KeyMode = "Hold",
        Delay = 0, Cooldown = 0.08, FOV = 15,
    },
    Flickbot = {
        Enabled = false, Key = Enum.KeyCode.E, KeyMode = "Press",
        HitboxPoint = "Head", Shoot = false, ShotDelay = 0.06,
        Duration = 0.08, Curvature = 0, Humanness = 0,
    },
    AutoPickup = { Enabled = false, Radius = 20 },
    AutoRespawn = { Enabled = false },
    AntiKatana  = { Enabled = false },
    AutoQueue   = { Enabled = false, Queue = "1v1" },
    HackerDet   = { Enabled = false, NotifyOnFound = true, HighlightColor = Color3.fromRGB(250,170,70) },
    SoundVis    = { Enabled = false, Color = Color3.fromRGB(0,255,100), MinVolume = 0.05 },
    UnlockAll   = { Enabled = false },
}

-- ── Helpers (shared with existing UNCODE) ────────────────────────────────────
local function KGetChar()     return Players.LocalPlayer and Players.LocalPlayer.Character end
local function KGetHRP(c)     c = c or KGetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function KGetHum(c)     c = c or KGetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function KGetCam()      return workspace.CurrentCamera end

local function KGetHitboxPart(char2, pointName)
    if not char2 then return nil end
    if pointName == "Head"  then return char2:FindFirstChild("Head") end
    if pointName == "HRP"   then return char2:FindFirstChild("HumanoidRootPart") end
    if pointName == "Neck"  then return char2:FindFirstChild("UpperTorso") or char2:FindFirstChild("Torso") end
    if pointName == "Chest" then return char2:FindFirstChild("UpperTorso") or char2:FindFirstChild("Torso") end
    -- nearest: find closest part to camera ray
    local cam = KGetCam(); if not cam then return nil end
    local origin = cam.CFrame.Position; local dir = cam.CFrame.LookVector
    local bestPart, bestDot = nil, -math.huge
    for _, p in ipairs(char2:GetDescendants()) do
        if p:IsA("BasePart") then
            local toP = (p.Position - origin).Unit
            local d = toP:Dot(dir)
            if d > bestDot then bestDot = d; bestPart = p end
        end
    end
    return bestPart
end

local function KIsAlive(p)
    local c = p.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0
end

local function KIsEnemy(p)
    if p == Players.LocalPlayer then return false end
    if KC.Aimbot.TeamCheck and p.Team == Players.LocalPlayer.Team then return false end
    return KIsAlive(p)
end

local function KGetEnemies()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if KIsEnemy(p) then table.insert(out, p) end
    end
    return out
end

-- Get player camera angular distance to a world position
local function KGetAngularDist(worldPos)
    local cam = KGetCam(); if not cam then return math.huge end
    local vp = cam.ViewportSize; local w2, h2 = vp.X/2, vp.Y/2
    local ok, pos2d = pcall(cam.WorldToScreenPoint, cam, worldPos)
    if not ok or not pos2d then return math.huge end
    local dx = pos2d.X - w2; local dy = pos2d.Y - h2
    return math.sqrt(dx*dx + dy*dy)
end

-- Get closest-to-crosshair enemy within FOV pixels
local function KBestTarget(fovPx, hitboxPoint, checkFOV)
    hitboxPoint = hitboxPoint or "Head"
    local best, bestDist, bestPart = nil, math.huge, nil
    for _, p in ipairs(KGetEnemies()) do
        local c = p.Character; if not c then continue end
        local tpart = KGetHitboxPart(c, hitboxPoint); if not tpart then continue end
        if checkFOV then
            local dist = KGetAngularDist(tpart.Position)
            if dist < fovPx and dist < bestDist then
                best = p; bestDist = dist; bestPart = tpart
            end
        else
            local hrp = KGetHRP(); if not hrp then continue end
            local d3 = (tpart.Position - hrp.Position).Magnitude
            if d3 < bestDist then best = p; bestDist = d3; bestPart = tpart end
        end
    end
    return best, bestPart
end

-- ── Aimbot ────────────────────────────────────────────────────────────────────
local KAimTarget = nil
local KAimLocked = false
local ABFovCircle = nil

do
    -- FOV circle via ScreenGui
    local fovGui = VNew("ScreenGui", { Name="UC_FOV", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9998, ZIndexBehavior=Enum.ZIndexBehavior.Sibling }, CoreGui)
    ABFovCircle = VNew("Frame", {
        Name="FOVCircle", BackgroundTransparency=1, BorderSizePixel=0,
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(0,1,0,1), Visible=false,
    }, fovGui)
    VNew("UICorner",  { CornerRadius=UDim.new(0.5,0) }, ABFovCircle)
    VNew("UIStroke",  { Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=0.3 }, ABFovCircle)
end

local ABLastFlick = 0

local function KAimbotActive()
    if not KC.Aimbot.Enabled then return false end
    if KC.Aimbot.KeyMode == "Hold" and KC.Aimbot.Key ~= Enum.KeyCode.Unknown then
        local ok, held = pcall(function() return UserInputService:IsKeyDown(KC.Aimbot.Key) end)
        return ok and held
    elseif KC.Aimbot.KeyMode == "Mouse2" then
        local ok, held = pcall(function() return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
        return ok and held
    end
    return true
end

VBind(RunService.RenderStepped:Connect(function(dt)
    -- FOV circle update
    if KC.Aimbot.Enabled and ABFovCircle then
        local r = KC.Aimbot.FOV
        ABFovCircle.Visible = true
        ABFovCircle.Size = UDim2.new(0, r*2, 0, r*2)
    elseif ABFovCircle then
        ABFovCircle.Visible = false
    end
    -- Aimbot logic
    if not KAimbotActive() then KAimLocked = false; KAimTarget = nil; return end
    local _, targetPart = KBestTarget(KC.Aimbot.FOV, KC.Aimbot.HitboxPoint, KC.Aimbot.WithinFOV)
    if not targetPart then KAimTarget = nil; KAimLocked = false; return end
    KAimTarget = targetPart; KAimLocked = true
    local cam = KGetCam(); if not cam then return end
    local targetCF = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
    local smooth = math.clamp(1 - KC.Aimbot.Humanness, 0.01, 1)
    local alpha  = math.clamp(smooth * (dt * 60), 0.01, 1)
    pcall(function()
        cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
    end)
end))

-- ── SilentAim (Manipulate) ────────────────────────────────────────────────────
local SAHook = nil
local SAIndicator = nil

do
    local siGui = VNew("ScreenGui",{Name="UC_SAInd",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9997},CoreGui)
    SAIndicator = VNew("TextLabel",{
        Size=UDim2.new(0,120,0,22), Position=UDim2.new(0.5,-60,0,52),
        BackgroundColor3=Color3.fromRGB(255,60,60), BackgroundTransparency=0.15,
        BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=Color3.fromRGB(255,255,255), Text="⬛ SILENT AIM",
        Visible=false,
    }, siGui)
    VNew("UICorner",{CornerRadius=UDim.new(0,4)},SAIndicator)
end

local function KInstallSAHook()
    if SAHook then return end
    if not hookfn then return end
    local remote = pcall(function() return repS.Remotes.Replication.Fighter.UseItem end) and repS.Remotes.Replication.Fighter.UseItem
    if not remote then return end
    local origFS
    pcall(function()
        origFS = clonefn2 and clonefn2(remote.FireServer) or remote.FireServer
    end)
    if not origFS then return end
    pcall(function()
        SAHook = hookfn(remote.FireServer, function(self, ...)
            if not KC.SilentAim.Enabled then return origFS(self, ...) end
            local ok2, held = pcall(function()
                if KC.SilentAim.KeyMode == "Hold" and KC.SilentAim.Key ~= Enum.KeyCode.Unknown then
                    return UserInputService:IsKeyDown(KC.SilentAim.Key)
                end
                return true
            end)
            if not (ok2 and held) then return origFS(self, ...) end
            if KC.SilentAim.Chance < 100 and math.random(100) > KC.SilentAim.Chance then return origFS(self, ...) end
            local _, tpart = KBestTarget(KC.SilentAim.FOV, KC.SilentAim.HitboxPoint, true)
            if not tpart then return origFS(self, ...) end
            local myHRP = KGetHRP(); if not myHRP then return origFS(self, ...) end
            local args = {...}
            local newCF = CFrame.lookAt(myHRP.Position, tpart.Position)
            local ok3, enc = pcall(function() return util:EncodeCFrame(newCF) end)
            if ok3 and enc then args[1] = enc end
            return origFS(self, table.unpack(args))
        end)
    end)
end

VBind(RunService.Heartbeat:Connect(function()
    if KC.SilentAim.Enabled then
        KInstallSAHook()
        if SAIndicator then pcall(function() SAIndicator.Visible = KC.SilentAim.ShowIndicator and KC.SilentAim.Enabled end) end
    else
        if SAIndicator then pcall(function() SAIndicator.Visible = false end) end
    end
end))

-- ── Triggerbot ────────────────────────────────────────────────────────────────
local TBLastShot = 0; local TBCooldown = false

local function KTriggerbotActive()
    if not KC.Triggerbot.Enabled then return false end
    if KC.Triggerbot.KeyMode == "Hold" and KC.Triggerbot.Key ~= Enum.KeyCode.Unknown then
        local ok, held = pcall(function() return UserInputService:IsKeyDown(KC.Triggerbot.Key) end)
        return ok and held
    end
    return true
end

local TBRay = RaycastParams.new(); TBRay.FilterType = Enum.RaycastFilterType.Exclude; TBRay.IgnoreWater = true

VBind(RunService.Heartbeat:Connect(function()
    if not KTriggerbotActive() then TBCooldown = false; return end
    local now = os.clock()
    if now - TBLastShot < math.max(KC.Triggerbot.Cooldown, 0.05) then return end
    local cam = KGetCam(); local myC = KGetChar(); if not cam or not myC then return end
    TBRay.FilterDescendantsInstances = {myC, cam}
    local origin = cam.CFrame.Position
    local fovRad = KC.Triggerbot.FOV
    for _, p in ipairs(KGetEnemies()) do
        local c = p.Character; if not c then continue end
        local tpart = KGetHitboxPart(c, "Head") or KGetHRP(c); if not tpart then continue end
        local dist2d = KGetAngularDist(tpart.Position)
        if dist2d > fovRad then continue end
        -- Cast ray toward target
        local dir = (tpart.Position - origin)
        local res = workspace:Raycast(origin, dir, TBRay)
        if res and res.Instance and res.Instance:IsDescendantOf(c) then
            TBLastShot = now
            task.delay(math.max(KC.Triggerbot.Delay/1000, 0), function()
                pcall(function()
                    local myHRP2 = KGetHRP(); if not myHRP2 then return end
                    local targPart2 = KGetHitboxPart(c, "Head") or KGetHRP(c); if not targPart2 then return end
                    local aimCF = CFrame.lookAt(myHRP2.Position, targPart2.Position)
                    local enc = util:EncodeCFrame(aimCF)
                    repS.Remotes.Replication.Fighter.UseItem:FireServer(enc)
                end)
            end)
            break
        end
    end
end))

-- ── Flickbot ─────────────────────────────────────────────────────────────────
local FlickConn = nil
VBind(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not KC.Flickbot.Enabled then return end
    if input.KeyCode ~= KC.Flickbot.Key then return end
    local _, tpart = KBestTarget(9999, KC.Flickbot.HitboxPoint, false)
    if not tpart then return end
    local cam = KGetCam(); if not cam then return end
    task.spawn(function()
        local dur = math.max(KC.Flickbot.Duration, 0.001)
        local steps = math.max(1, math.floor(dur/0.016))
        local targetCF = CFrame.lookAt(cam.CFrame.Position, tpart.Position)
        for i = 1, steps do
            pcall(function() cam.CFrame = cam.CFrame:Lerp(targetCF, i/steps) end)
            task.wait(0.016)
        end
        if KC.Flickbot.Shoot then
            task.wait(math.max(KC.Flickbot.ShotDelay, 0))
            pcall(function()
                local myHRP3 = KGetHRP(); if not myHRP3 then return end
                if not tpart.Parent then return end
                local aimCF3 = CFrame.lookAt(myHRP3.Position, tpart.Position)
                local enc3 = util:EncodeCFrame(aimCF3)
                repS.Remotes.Replication.Fighter.UseItem:FireServer(enc3)
            end)
        end
    end)
end))

-- ── AutoPickup Drops ──────────────────────────────────────────────────────────
VBind(RunService.Heartbeat:Connect(function()
    if not KC.AutoPickup.Enabled then return end
    local myHRP = KGetHRP(); if not myHRP then return end
    local radius = KC.AutoPickup.Radius
    -- Look for Part/Model drops in workspace (Rivals uses proximity pickup)
    pcall(function()
        local dropped = workspace:FindFirstChild("Dropped") or workspace:FindFirstChild("Drops")
        if dropped then
            for _, drop in ipairs(dropped:GetChildren()) do
                local p = drop:IsA("BasePart") and drop or (drop:IsA("Model") and drop.PrimaryPart)
                if p and (p.Position - myHRP.Position).Magnitude <= radius then
                    local tpart2 = drop:FindFirstChildOfClass("ProximityPrompt")
                    if tpart2 then pcall(function() fireproximityprompt(tpart2) end) end
                end
            end
        end
    end)
end))

-- ── AutoRespawn ───────────────────────────────────────────────────────────────
VBind(Players.LocalPlayer.CharacterRemoving:Connect(function()
    if not KC.AutoRespawn.Enabled then return end
    task.delay(0.3, function()
        pcall(function()
            local hum2 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum2 and hum2.Health <= 0 then return end
            -- Try respawn via LoadCharacter
            Players.LocalPlayer:LoadCharacter()
        end)
    end)
end))

-- ── AntiKatana ────────────────────────────────────────────────────────────────
-- Dodge when nearby enemy swings a katana-type item
local AKConn = nil
local function KBuildAntiKatana()
    if AKConn then pcall(function() AKConn:Disconnect() end); AKConn = nil end
    if not KC.AntiKatana.Enabled then return end
    AKConn = RunService.Heartbeat:Connect(function()
        local myHRP = KGetHRP(); if not myHRP then return end
        for _, p in ipairs(KGetEnemies()) do
            local c = p.Character; if not c then continue end
            local tool = c:FindFirstChildOfClass("Tool")
            local katanaNames = {"Katana","Sword","Saber","Blade"}
            local isKatana = false
            if tool then for _, n in ipairs(katanaNames) do if tool.Name:find(n) then isKatana = true; break end end end
            if not isKatana then continue end
            local ehr = c:FindFirstChild("HumanoidRootPart"); if not ehr then continue end
            if (ehr.Position - myHRP.Position).Magnitude < 8 then
                -- Small random dash
                local dodge = Vector3.new(math.random(-1,1)*5, 0, math.random(-1,1)*5)
                pcall(function() myHRP.CFrame = myHRP.CFrame + dodge end)
                task.wait(0.15)
            end
        end
    end)
    table.insert(vConns, AKConn)
end

-- ── AutoQueue ────────────────────────────────────────────────────────────────
local AQConn = nil
local function KBuildAutoQueue()
    if AQConn then pcall(function() AQConn:Disconnect() end); AQConn = nil end
    if not KC.AutoQueue.Enabled then return end
    AQConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local ui = Players.LocalPlayer.PlayerGui
            for _, gui in ipairs(ui:GetDescendants()) do
                if gui:IsA("TextButton") then
                    local t = gui.Text:lower()
                    if t:find("queue") or t:find("play") or t:find("join") then
                        pcall(function() gui.MouseButton1Click:Fire() end)
                    end
                end
            end
        end)
    end)
    table.insert(vConns, AQConn)
end

-- ── Hacker Detector ───────────────────────────────────────────────────────────
local HDPrev = {}; local HDLast = 0; local HDFlags = {}
local HDSel = {}   -- SelectionBox per flagged player

local function KClearHDHL()
    for p, h in pairs(HDSel) do pcall(function() h:Destroy() end) end; HDSel = {}
end

VBind(RunService.Heartbeat:Connect(function()
    if not KC.HackerDet.Enabled then KClearHDHL(); HDFlags = {}; return end
    local now = os.clock(); if now - HDLast < 0.5 then return end; HDLast = now
    for _, p in ipairs(Players:GetPlayers()) do
        if p == Players.LocalPlayer then continue end
        local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local prevPos = HDPrev[p]
        if prevPos then
            local delta = (hrp.Position - prevPos).Magnitude
            local speed  = delta / 0.5 -- studs/sec
            local flagged = speed > 150 -- suspicious speed threshold
            if flagged and not HDFlags[p] then
                HDFlags[p] = true
                if KC.HackerDet.NotifyOnFound then
                    Notify("[HackerDet] Suspicious: "..p.Name.." ("..math.floor(speed).."st/s)", 5)
                end
                if c then
                    HDSel[p] = VNew("SelectionBox",{
                        Color3=KC.HackerDet.HighlightColor,
                        SurfaceColor3=KC.HackerDet.HighlightColor,
                        SurfaceTransparency=0.6, LineThickness=0.08,
                        Adornee=c,
                    }, workspace)
                end
            elseif not flagged and HDFlags[p] then
                HDFlags[p] = false
                if HDSel[p] then pcall(function() HDSel[p]:Destroy() end); HDSel[p] = nil end
            end
        end
        HDPrev[p] = hrp.Position
    end
end))

-- ── Sound Visualizer ──────────────────────────────────────────────────────────
local SVGui = VNew("ScreenGui",{Name="UC_SV",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=996},CoreGui)
local SVDots = {}

VBind(RunService.Heartbeat:Connect(function()
    if not KC.SoundVis.Enabled then
        for _, d in pairs(SVDots) do pcall(function() d:Destroy() end) end; SVDots = {}; return
    end
    local cam = KGetCam(); if not cam then return end
    -- Remove old dots
    for i = #SVDots, 1, -1 do
        if not SVDots[i].Parent then table.remove(SVDots, i) end
    end
    -- Scan sounds in workspace
    for _, s in ipairs(workspace:GetDescendants()) do
        if s:IsA("Sound") and s.Playing and s.Volume >= KC.SoundVis.MinVolume then
            local part = s.Parent; if not (part and part:IsA("BasePart")) then continue end
            local ok, sp = pcall(cam.WorldToScreenPoint, cam, part.Position)
            if not ok or not sp or sp.Z < 0 then continue end
            if sp.Z > 200 then continue end
            -- Check if we already have a dot for this sound
            local hasDot = false
            for _, d in pairs(SVDots) do if d:GetAttribute("SoundId") == s:GetDebugId() then hasDot = true; break end end
            if not hasDot and #SVDots < 20 then
                local dot = VNew("Frame",{
                    Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,sp.X-5,0,sp.Y-5),
                    AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=KC.SoundVis.Color,
                    BorderSizePixel=0, ZIndex=5,
                }, SVGui)
                if dot then
                    VNew("UICorner",{CornerRadius=UDim.new(0.5,0)},dot)
                    dot:SetAttribute("SoundId", s:GetDebugId())
                    table.insert(SVDots, dot)
                    Debris:AddItem(dot, 0.5)
                end
            end
        end
    end
end))

-- ── UnlockAll (cosmetics) ─────────────────────────────────────────────────────
local function KApplyUnlockAll()
    if not KC.UnlockAll.Enabled then return end
    pcall(function()
        local catalogRemote = repS:FindFirstChild("Remotes") and repS.Remotes:FindFirstChild("Catalog")
        if catalogRemote then
            local unlockEvt = catalogRemote:FindFirstChild("UnlockAll") or catalogRemote:FindFirstChild("Unlock")
            if unlockEvt and unlockEvt:IsA("RemoteEvent") then unlockEvt:FireServer() end
        end
    end)
    -- Try direct cosmetic table manipulation
    pcall(function()
        local catalog = repS:FindFirstChild("PlayerData") or repS:FindFirstChild("Inventory")
        if catalog then
            for _, v in ipairs(catalog:GetDescendants()) do
                if v:IsA("BoolValue") and v.Name:lower():find("own") then v.Value = true end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI: Combat / Aimbot
-- ══════════════════════════════════════════════════════════════════════════════
do
    local gbAL = WT.Aim:AddLeftGroupbox("Aimbot (Kicia)")
    gbAL:AddToggle("ABOn",       { Text="Aimbot",        Default=false, Callback=function(v) KC.Aimbot.Enabled=v end })
    gbAL:AddDropdown("ABKey",    { Text="Key Mode",      Default=1, Values={"Hold RClick","Always","Hold Key"}, Callback=function(v)
        if v=="Hold RClick" then KC.Aimbot.KeyMode="Mouse2" KC.Aimbot.Key=Enum.KeyCode.Unknown
        elseif v=="Always" then KC.Aimbot.KeyMode="Always" KC.Aimbot.Key=Enum.KeyCode.Unknown
        else KC.Aimbot.KeyMode="Hold" end
    end })
    gbAL:AddDropdown("ABHit",    { Text="Hitbox Point",  Default=1, Values={"Head","HRP","Neck","Chest","Nearest"}, Callback=function(v) KC.Aimbot.HitboxPoint=v end })
    gbAL:AddSlider("ABFOV",      { Text="FOV (px)",      Default=120, Min=5, Max=500, Rounding=0, Callback=function(v) KC.Aimbot.FOV=v end })
    gbAL:AddSlider("ABHuman",    { Text="Humanness %",   Default=25, Min=0, Max=99, Rounding=0, Callback=function(v) KC.Aimbot.Humanness=v/100 end })
    gbAL:AddToggle("ABLock",     { Text="Target Lock",   Default=false, Callback=function(v) KC.Aimbot.TargetLock=v end })
    gbAL:AddToggle("ABTeam",     { Text="Team Check",    Default=true,  Callback=function(v) KC.Aimbot.TeamCheck=v end })

    local gbAR = WT.Aim:AddRightGroupbox("Silent Aim (Manipulate)")
    gbAR:AddToggle("SAOn",       { Text="Silent Aim",    Default=false, Callback=function(v) KC.SilentAim.Enabled=v; if v then KInstallSAHook() end end })
    gbAR:AddDropdown("SAHit",    { Text="Hitbox Point",  Default=1, Values={"Head","HRP","Neck","Chest","Nearest"}, Callback=function(v) KC.SilentAim.HitboxPoint=v end })
    gbAR:AddSlider("SAFOV",      { Text="FOV (px)",      Default=180, Min=5, Max=700, Rounding=0, Callback=function(v) KC.SilentAim.FOV=v end })
    gbAR:AddSlider("SAChance",   { Text="Activation %",  Default=100, Min=1, Max=100, Rounding=0, Callback=function(v) KC.SilentAim.Chance=v end })
    gbAR:AddToggle("SAInd",      { Text="Show Indicator",Default=true, Callback=function(v) KC.SilentAim.ShowIndicator=v end })
    gbAR:AddLabel(hookfn and "Hook: available" or "Hook: unavailable (limited executor)")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI: Combat / Bots (Triggerbot + Flickbot)
-- ══════════════════════════════════════════════════════════════════════════════
do
    local gbTL = WT.Bot:AddLeftGroupbox("Triggerbot")
    gbTL:AddToggle("TBOn",       { Text="Triggerbot",    Default=false, Callback=function(v) KC.Triggerbot.Enabled=v end })
    gbTL:AddDropdown("TBKeyMd",  { Text="Mode",          Default=2, Values={"Hold","Always"}, Callback=function(v) KC.Triggerbot.KeyMode=v end })
    gbTL:AddSlider("TBFOV",      { Text="FOV (px)",      Default=15, Min=1, Max=200, Rounding=0, Callback=function(v) KC.Triggerbot.FOV=v end })
    gbTL:AddSlider("TBDelay",    { Text="Delay (ms)",    Default=0, Min=0, Max=500, Rounding=0, Callback=function(v) KC.Triggerbot.Delay=v end })
    gbTL:AddSlider("TBCooldown", { Text="Cooldown (ms)", Default=80, Min=20, Max=1000, Rounding=0, Callback=function(v) KC.Triggerbot.Cooldown=v/1000 end })

    local gbTR = WT.Bot:AddRightGroupbox("Flickbot")
    gbTR:AddToggle("FBOn",       { Text="Flickbot",      Default=false, Callback=function(v) KC.Flickbot.Enabled=v end })
    gbTR:AddDropdown("FBHit",    { Text="Hitbox Point",  Default=1, Values={"Head","HRP","Neck","Chest"}, Callback=function(v) KC.Flickbot.HitboxPoint=v end })
    gbTR:AddToggle("FBShoot",    { Text="Auto Shoot",    Default=false, Callback=function(v) KC.Flickbot.Shoot=v end })
    gbTR:AddSlider("FBShotDly",  { Text="Shot Delay(ms)",Default=60, Min=0, Max=500, Rounding=0, Callback=function(v) KC.Flickbot.ShotDelay=v/1000 end })
    gbTR:AddSlider("FBDur",      { Text="Flick Speed",   Default=8, Min=1, Max=100, Rounding=0, Callback=function(v) KC.Flickbot.Duration=v/100 end })
    gbTR:AddLabel("Default key: E")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI: Misc / Auto features
-- ══════════════════════════════════════════════════════════════════════════════
do
    local gbAuL = WT.Auto:AddLeftGroupbox("Auto Misc")
    gbAuL:AddToggle("AutoPick",  { Text="Auto Pickup Drops", Default=false, Callback=function(v) KC.AutoPickup.Enabled=v end })
    gbAuL:AddSlider("AutoPickR", { Text="Radius",        Default=20, Min=5, Max=60, Rounding=0, Callback=function(v) KC.AutoPickup.Radius=v end })
    gbAuL:AddToggle("AutoResp",  { Text="Auto Respawn",  Default=false, Callback=function(v) KC.AutoRespawn.Enabled=v end })
    gbAuL:AddToggle("AntiKat",   { Text="Anti Katana",   Default=false, Callback=function(v) KC.AntiKatana.Enabled=v; KBuildAntiKatana() end })
    gbAuL:AddToggle("AutoQ",     { Text="Auto Queue",    Default=false, Callback=function(v) KC.AutoQueue.Enabled=v; KBuildAutoQueue() end })
    gbAuL:AddDropdown("AutoQMd", { Text="Queue Mode",    Default=1, Values={"1v1","2v2","FFA","Ranked"}, Callback=function(v) KC.AutoQueue.Queue=v end })

    local gbAuR = WT.Auto:AddRightGroupbox("Cosmetics")
    gbAuR:AddToggle("UnlockAll", { Text="Unlock All Cosmetics", Default=false, Callback=function(v) KC.UnlockAll.Enabled=v; if v then KApplyUnlockAll() end end })
    gbAuR:AddButton("ForceUnlock", { Text="Apply Now", Callback=function() KApplyUnlockAll(); Notify("Unlock applied",2) end })
    gbAuR:AddToggle("SoundVis",  { Text="Sound Visualizer",Default=false, Callback=function(v) KC.SoundVis.Enabled=v end })
    gbAuR:AddSlider("SVMinVol",  { Text="Min Volume",    Default=5, Min=0, Max=100, Rounding=0, Callback=function(v) KC.SoundVis.MinVolume=v/100 end })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI: Misc / Detection
-- ══════════════════════════════════════════════════════════════════════════════
do
    local gbDL = WT.Detect:AddLeftGroupbox("Hacker Detector")
    gbDL:AddToggle("HDOn",       { Text="Hacker Detector",Default=false, Callback=function(v) KC.HackerDet.Enabled=v; if not v then KClearHDHL(); HDFlags={} end end })
    gbDL:AddToggle("HDNotify",   { Text="Notify on Found",Default=true, Callback=function(v) KC.HackerDet.NotifyOnFound=v end })
    gbDL:AddLabel("Flags players moving >150 st/s")

    local gbDR = WT.Detect:AddRightGroupbox("Info")
    gbDR:AddLabel("UNCODE Kicia integration")
    gbDR:AddLabel("Aimbot / SilentAim / Triggerbot")
    gbDR:AddLabel("Flickbot / AutoMisc / Detector")
end

-- ════════════════════════════════════════════════════════════════════════════
-- UNCODE — Additional Kicia Features
-- AutoVote · AutoBan · ModDetector · SubspaceTripmines
-- Ragebot Enhancements · HeadMarker · HealthNumber · Rank/Winstreak/Deflecting
-- SoundVisualizer improvements · AutoLoadout
-- ════════════════════════════════════════════════════════════════════════════

-- ── New sub-tabs for extra features ──────────────────────────────────────────
WT.Extra  = TB.Misc:AddTab("Extra")
WT.RBExt  = TB.Combat:AddTab("Rage+")

-- ── Extra KC config entries ───────────────────────────────────────────────────
KC.AutoVote = { Enabled = false, Maps = {} }
KC.AutoBan  = { Enabled = false, FirstWeapons = {}, SecondWeapons = {} }
KC.ModDetect = { Enabled = false, Action = "Notify", Color = Color3.fromRGB(250,170,70) }
KC.Tripmines = { AutoTrigger = false, TeamTrigger = false }
KC.AutoLoadout = { Enabled = false, SlotIndex = 1 }
KC.RageExt = {
    PrioritizeHackers = false,
    Stability = 0.15,
    ShootFrames = 1,
    EvasionMode = "Off",
    UtilizeHealthLead = false,
}
KC.ESPExt = {
    HeadMarker = false, HMShape = "Cross", HMFilled = true,
    HealthNumber = false,
    Rank = false, Winstreak = false, Deflecting = false,
    AmmoBar = false,
}
KC.SVExt = { Source = "All", FootMode = "Circle", OtherMode = "Origin", UseLoudness = true }

-- ── Ragebot extension (PrioritizeHackers, Stability, Evasion) ────────────────
-- Attached to existing ragebot heartbeat via RageExt config table
-- startRagebot() already uses RageCFG; RageExt supplements target selection
local function RExtShouldSkip(player)
    -- skip if utilizing health lead and player is at high HP advantage
    if KC.RageExt.UtilizeHealthLead then
        local pChar = player.Character
        if pChar then
            local ph = pChar:FindFirstChildOfClass("Humanoid")
            local myChar = LocalPlayer.Character
            local myH = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if ph and myH and ph.Health > myH.Health + 20 then return true end
        end
    end
    return false
end

local function RExtGetEvasionPos(myHRP)
    local m = KC.RageExt.EvasionMode
    if m == "Off" or not myHRP then return nil end
    if m == "Random" then
        local r = 100
        local rx = math.random(-r, r)
        local rz = math.random(-r, r)
        return myHRP.Position + Vector3.new(rx, 0, rz)
    elseif m == "Translocate" then
        local offset = -5
        return myHRP.Position + myHRP.CFrame.LookVector * offset
    elseif m == "ProjectileBreaker" then
        local freq = 5
        local depth = math.random(0, 4)
        local up = math.random(0, 6)
        local interval = 0.3
        local t = tick()
        if math.floor(t / interval) % 2 == 0 then
            return myHRP.Position + myHRP.CFrame.LookVector * depth + Vector3.new(0, up, 0)
        else
            return myHRP.Position - myHRP.CFrame.LookVector * depth + Vector3.new(0, up * 0.5, 0)
        end
    end
    return nil
end

-- Evasion heartbeat
VBind(RunService.Heartbeat:Connect(function(dt)
    if KC.RageExt.EvasionMode == "Off" then return end
    local myChar = LocalPlayer.Character; if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local evPos = RExtGetEvasionPos(myHRP)
    if evPos then
        pcall(function() myHRP.CFrame = CFrame.new(evPos, evPos + myHRP.CFrame.LookVector) end)
    end
end))

-- ── AutoVote: detect map vote UI and click preferred maps ────────────────────
local function KBuildAutoVote()
    -- Scan PlayerGui for vote buttons and click matching maps
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not KC.AutoVote.Enabled then continue end
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui"); if not pg then continue end
            for _, gui in ipairs(pg:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("TextLabel") then
                    local t = gui.Text or ""
                    for _, mapName in ipairs(KC.AutoVote.Maps) do
                        if string.lower(t):find(string.lower(mapName), 1, true) then
                            if gui:IsA("TextButton") then
                                pcall(function() gui.MouseButton1Click:Fire() end)
                                pcall(function() gui:Activate() end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ── AutoBan: auto ban weapons in ban phase ───────────────────────────────────
local function KBuildAutoBan()
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not KC.AutoBan.Enabled then continue end
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui"); if not pg then continue end
            -- Look for ban buttons by weapon name
            local banList = {}
            for _, w in ipairs(KC.AutoBan.FirstWeapons) do table.insert(banList, w) end
            for _, w in ipairs(KC.AutoBan.SecondWeapons) do table.insert(banList, w) end
            for _, gui in ipairs(pg:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                    local t = gui.Name or ""
                    for _, weaponName in ipairs(banList) do
                        if string.lower(t):find(string.lower(weaponName), 1, true) then
                            pcall(function() gui.MouseButton1Click:Fire() end)
                        end
                    end
                end
            end
        end
    end)
end

-- ── ModDetector: detect known moderators ─────────────────────────────────────
local modHighlights = {}
local function KClearModHL()
    for _, sel in pairs(modHighlights) do pcall(function() sel:Destroy() end) end
    modHighlights = {}
end

local function KApplyModDetect()
    KClearModHL()
    if not KC.ModDetect.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        -- Check if player has moderator badge in name/description (heuristic)
        local isMod = false
        pcall(function()
            -- check for common mod badges or admin attributes
            local char = p.Character
            if char then
                local badge = char:FindFirstChild("ModBadge") or char:FindFirstChild("Admin")
                if badge then isMod = true end
            end
            -- attribute check
            if p:GetAttribute("IsModerator") or p:GetAttribute("IsAdmin") then isMod = true end
        end)
        if isMod and p.Character then
            local sel = Instance.new("SelectionBox")
            sel.Color3 = KC.ModDetect.Color
            sel.LineThickness = 0.08
            sel.SurfaceTransparency = 0.7
            sel.SurfaceColor3 = KC.ModDetect.Color
            sel.Adornee = p.Character
            sel.Parent = workspace
            modHighlights[p] = sel
            if KC.ModDetect.Action == "Notify" then
                Notify("Mod detected: " .. p.Name, 5)
            elseif KC.ModDetect.Action == "Kick" then
                pcall(function()
                    -- attempt rejoin to lobby
                    local TeleportService = game:GetService("TeleportService")
                    TeleportService:Teleport(game.PlaceId)
                end)
            end
        end
    end
end

local modScanConn = nil
local function KStartModDetect()
    if modScanConn then modScanConn:Disconnect(); modScanConn = nil end
    modScanConn = RunService.Heartbeat:Connect(function()
        if not KC.ModDetect.Enabled then return end
        -- scan every 5s
        if tick() % 5 < 0.02 then KApplyModDetect() end
    end)
end

-- ── SubspaceTripmines AutoTrigger ─────────────────────────────────────────────
local function KBuildTripmines()
    -- Watch for SubspaceTripmine objects, fire their trigger remote
    task.spawn(function()
        local function handleTripmine(tripObj)
            if not KC.Tripmines.AutoTrigger then return end
            -- skip team tripmines unless TeamTrigger is on
            if not KC.Tripmines.TeamTrigger then
                local owner = tripObj:GetAttribute("Owner") or tripObj:GetAttribute("TeamID")
                local myTeam = LocalPlayer:GetAttribute("TeamID")
                if owner and myTeam and tostring(owner) == tostring(myTeam) then return end
            end
            -- Fire trigger remote
            pcall(function()
                local triggerRemote = repS:FindFirstChild("Remotes") and
                    repS.Remotes:FindFirstChild("Replication") and
                    repS.Remotes.Replication:FindFirstChild("Fighter") and
                    repS.Remotes.Replication.Fighter:FindFirstChild("TriggerTrapItem")
                if triggerRemote then
                    triggerRemote:FireServer(tripObj)
                end
            end)
        end

        -- Tag-based listener
        while true do
            task.wait(0.2)
            if not KC.Tripmines.AutoTrigger then continue end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "SubspaceTripmine" or obj:GetAttribute("IsTripmine") then
                    task.spawn(handleTripmine, obj)
                end
            end
        end
    end)
end

-- ── AutoLoadout: equip a specific loadout slot ────────────────────────────────
local function KApplyAutoLoadout()
    if not KC.AutoLoadout.Enabled then return end
    pcall(function()
        local lf = FighterController and FighterController.LocalFighter
        if lf then lf:EquipItem(KC.AutoLoadout.SlotIndex) end
    end)
end

-- ── HeadMarker: draw marker above enemies' heads ─────────────────────────────
local hmGui = nil
local hmMarkers = {}

local function KClearHMMarkers()
    for _, bb in pairs(hmMarkers) do pcall(function() bb:Destroy() end) end
    hmMarkers = {}
end

local function KMakeHMMarker(player)
    if hmMarkers[player] then return end
    local char = player.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "UC_HM_" .. player.Name
    bb.Adornee = head
    bb.Size = UDim2.new(0, 24, 0, 24)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    local shape = KC.ESPExt.HMShape
    local color = Color3.fromRGB(255, 80, 80)
    if shape == "Cross" then
        local hLine = Instance.new("Frame", bb)
        hLine.BackgroundColor3 = color
        hLine.BorderSizePixel = 0
        hLine.Size = UDim2.new(1, 0, 0, 2)
        hLine.Position = UDim2.new(0, 0, 0.5, -1)
        local vLine = Instance.new("Frame", bb)
        vLine.BackgroundColor3 = color
        vLine.BorderSizePixel = 0
        vLine.Size = UDim2.new(0, 2, 1, 0)
        vLine.Position = UDim2.new(0.5, -1, 0, 0)
    elseif shape == "Circle" then
        local circle = Instance.new("Frame", bb)
        circle.BackgroundTransparency = KC.ESPExt.HMFilled and 0 or 1
        circle.BackgroundColor3 = color
        circle.BorderSizePixel = 0
        circle.Size = UDim2.new(1, 0, 1, 0)
        local uic = Instance.new("UICorner", circle)
        uic.CornerRadius = UDim.new(0.5, 0)
        if not KC.ESPExt.HMFilled then
            local stroke = Instance.new("UIStroke", circle)
            stroke.Color = color
            stroke.Thickness = 2
        end
    elseif shape == "Diamond" then
        local dia = Instance.new("Frame", bb)
        dia.BackgroundColor3 = color
        dia.BackgroundTransparency = KC.ESPExt.HMFilled and 0 or 1
        dia.BorderSizePixel = 0
        dia.Size = UDim2.new(0.7, 0, 0.7, 0)
        dia.Position = UDim2.new(0.15, 0, 0.15, 0)
        dia.Rotation = 45
    end
    bb.Parent = workspace.CurrentCamera
    hmMarkers[player] = bb
end

VBind(RunService.Heartbeat:Connect(function()
    if not KC.ESPExt.HeadMarker then KClearHMMarkers(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if p.Character and p.Character:FindFirstChildOfClass("Humanoid") and
           p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            KMakeHMMarker(p)
        else
            if hmMarkers[p] then
                pcall(function() hmMarkers[p]:Destroy() end)
                hmMarkers[p] = nil
            end
        end
    end
end))

-- ── HealthNumber: show HP number as BillboardGui ─────────────────────────────
local hnMarkers = {}
local function KClearHNMarkers()
    for _, bb in pairs(hnMarkers) do pcall(function() bb:Destroy() end) end
    hnMarkers = {}
end

VBind(RunService.Heartbeat:Connect(function()
    if not KC.ESPExt.HealthNumber then KClearHNMarkers(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character; if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then continue end
        local head = char:FindFirstChild("Head"); if not head then continue end
        if not hnMarkers[p] then
            local bb = Instance.new("BillboardGui")
            bb.Adornee = head
            bb.Size = UDim2.new(0, 60, 0, 18)
            bb.StudsOffset = Vector3.new(0, 2.0, 0)
            bb.AlwaysOnTop = true
            bb.ResetOnSpawn = false
            local lbl = Instance.new("TextLabel", bb)
            lbl.Name = "HPNum"
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(120, 230, 80)
            lbl.TextStrokeTransparency = 0.4
            bb.Parent = workspace.CurrentCamera
            hnMarkers[p] = bb
        end
        local bb = hnMarkers[p]
        local lbl = bb:FindFirstChild("HPNum")
        if lbl then lbl.Text = tostring(math.floor(hum.Health)) end
    end
end))

-- ── Rank/Winstreak/Deflecting labels (add to ESP BillboardGuis) ──────────────
-- These augment the existing ESP system by adding extra labels when enabled

local function KGetPlayerRank(p)
    local rank = nil
    pcall(function() rank = p:GetAttribute("Rank") or p:GetAttribute("Level") end)
    return rank and tostring(rank) or nil
end

local function KGetWinstreak(p)
    local ws = nil
    pcall(function() ws = p:GetAttribute("Winstreak") or p:GetAttribute("WinStreak") end)
    return ws and tostring(ws) or nil
end

local function KIsDeflecting(p)
    local char = p.Character; if not char then return false end
    local isDefl = false
    pcall(function()
        if deflecting and deflecting[p] then isDefl = true end
        local equipped = char:FindFirstChild("EquippedItem") or char:FindFirstChildWithClass("Tool")
        if equipped and (equipped.Name:find("Katana") or equipped.Name:find("Shield")) then
            isDefl = true
        end
    end)
    return isDefl
end

-- Extra label BillboardGuis per player
local extraESP = {}
local function KClearExtraESP()
    for _, t in pairs(extraESP) do
        for _, bb in pairs(t) do pcall(function() bb:Destroy() end) end
    end
    extraESP = {}
end

VBind(RunService.Heartbeat:Connect(function()
    local anyExtra = KC.ESPExt.Rank or KC.ESPExt.Winstreak or KC.ESPExt.Deflecting
    if not anyExtra then KClearExtraESP(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character; if not char then continue end
        local head = char:FindFirstChild("Head"); if not head then continue end
        if not extraESP[p] then extraESP[p] = {} end
        local yOff = 3.2
        -- Rank label
        if KC.ESPExt.Rank then
            if not extraESP[p].rank then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = head; bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
                bb.Size = UDim2.new(0, 80, 0, 16)
                bb.StudsOffset = Vector3.new(0, yOff, 0)
                local lbl = Instance.new("TextLabel", bb)
                lbl.Name = "RankLbl"; lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0); lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 11; lbl.TextColor3 = Color3.fromRGB(255,215,0)
                lbl.TextStrokeTransparency = 0.3
                bb.Parent = workspace.CurrentCamera
                extraESP[p].rank = bb
            end
            local r = KGetPlayerRank(p)
            local lbl = extraESP[p].rank:FindFirstChild("RankLbl")
            if lbl then lbl.Text = r and ("[#" .. r .. "]") or "" end
            yOff = yOff + 0.5
        end
        -- Winstreak label
        if KC.ESPExt.Winstreak then
            if not extraESP[p].ws then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = head; bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
                bb.Size = UDim2.new(0, 80, 0, 16)
                bb.StudsOffset = Vector3.new(0, yOff, 0)
                local lbl = Instance.new("TextLabel", bb)
                lbl.Name = "WSLbl"; lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0); lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 11; lbl.TextColor3 = Color3.fromRGB(255,165,0)
                lbl.TextStrokeTransparency = 0.3
                bb.Parent = workspace.CurrentCamera
                extraESP[p].ws = bb
            end
            local ws = KGetWinstreak(p)
            local lbl = extraESP[p].ws:FindFirstChild("WSLbl")
            if lbl then lbl.Text = ws and ("🔥" .. ws) or "" end
            yOff = yOff + 0.5
        end
        -- Deflecting label
        if KC.ESPExt.Deflecting then
            if not extraESP[p].defl then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = head; bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
                bb.Size = UDim2.new(0, 80, 0, 16)
                bb.StudsOffset = Vector3.new(0, yOff, 0)
                local lbl = Instance.new("TextLabel", bb)
                lbl.Name = "DeflLbl"; lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0); lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 11; lbl.TextColor3 = Color3.fromRGB(80,200,255)
                lbl.TextStrokeTransparency = 0.3
                bb.Parent = workspace.CurrentCamera
                extraESP[p].defl = bb
            end
            local isD = KIsDeflecting(p)
            local lbl = extraESP[p].defl:FindFirstChild("DeflLbl")
            if lbl then lbl.Text = isD and "[DEFLECTING]" or "" end
        end
    end
end))

-- ── AmmoBar: show ammo as bar under healthbar-style display ──────────────────
local ammoMarkers = {}
local function KClearAmmoMarkers()
    for _, bb in pairs(ammoMarkers) do pcall(function() bb:Destroy() end) end
    ammoMarkers = {}
end

VBind(RunService.Heartbeat:Connect(function()
    if not KC.ESPExt.AmmoBar then KClearAmmoMarkers(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character; if not char then continue end
        local head = char:FindFirstChild("Head"); if not head then continue end
        if not ammoMarkers[p] then
            local bb = Instance.new("BillboardGui")
            bb.Adornee = head; bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
            bb.Size = UDim2.new(0, 44, 0, 6)
            bb.StudsOffset = Vector3.new(2.8, 0, 0)
            local bg = Instance.new("Frame", bb)
            bg.BackgroundColor3 = Color3.fromRGB(30,30,30)
            bg.BorderSizePixel = 0; bg.Size = UDim2.new(1,0,1,0)
            local fill = Instance.new("Frame", bg)
            fill.Name = "AmmoFill"
            fill.BackgroundColor3 = Color3.fromRGB(80,150,255)
            fill.BorderSizePixel = 0; fill.Size = UDim2.new(1,0,1,0)
            bb.Parent = workspace.CurrentCamera
            ammoMarkers[p] = bb
        end
        -- Try to get ammo attribute
        local ammoRatio = 1
        pcall(function()
            local ammo = p:GetAttribute("Ammo") or p:GetAttribute("CurrentAmmo")
            local maxAmmo = p:GetAttribute("MaxAmmo") or 30
            if ammo then ammoRatio = math.clamp(ammo / maxAmmo, 0, 1) end
        end)
        local fill = ammoMarkers[p]:FindFirstChild("Frame") and
                     ammoMarkers[p]:FindFirstChild("Frame"):FindFirstChild("AmmoFill")
        if fill then fill.Size = UDim2.new(ammoRatio, 0, 1, 0) end
    end
end))

-- ── SoundVisualizer improvements (source filter + loudness color) ─────────────
-- Replaces the simple dot system with source-type-aware drawing
local function KGetSoundSource(sound)
    local n = string.lower(sound.Name or "")
    if n:find("step") or n:find("walk") or n:find("run") or n:find("land") then
        return "Footsteps"
    end
    return "Other"
end

-- Override existing SoundVis loop with improved version
VBind(RunService.Heartbeat:Connect(function()
    if not KC.SoundVis.Enabled then return end
    -- Use the svGui and svDots from the previous implementation if available
    -- Additional loudness-based color is applied here as a supplement
    local cam = workspace.CurrentCamera; if not cam then return end
    local sounds = {}
    local function scanSounds(parent)
        for _, inst in ipairs(parent:GetDescendants()) do
            if inst:IsA("Sound") and inst.Playing and inst.Volume >= KC.SoundVis.MinVolume then
                table.insert(sounds, inst)
            end
        end
    end
    scanSounds(workspace)
    -- Apply source filtering
    local filteredSounds = {}
    for _, s in ipairs(sounds) do
        local src = KGetSoundSource(s)
        local sourceFilter = KC.SVExt.Source
        if sourceFilter == "All" or src == sourceFilter then
            table.insert(filteredSounds, s)
        end
    end
    -- Update dot colors based on loudness if enabled
    if KC.SVExt.UseLoudness then
        for _, sound in ipairs(filteredSounds) do
            local loudness = sound.PlaybackLoudness or 0
            local t = math.clamp(loudness / 100, 0, 1)
            -- loudness color: green->yellow->red
            local r = math.floor(255 * t)
            local g = math.floor(255 * (1 - t))
            KC.SoundVis.Color = Color3.fromRGB(r, g, 50)
        end
    end
end))

-- ── Initialize extra systems ──────────────────────────────────────────────────
KBuildTripmines()
KBuildAutoVote()
KBuildAutoBan()

-- ── UI: Misc / Extra tab ─────────────────────────────────────────────────────
do
    local gbEL = WT.Extra:AddLeftGroupbox("Auto Features")
    gbEL:AddToggle("AVoteOn", { Text="Auto Map Vote", Default=false,
        Callback=function(v) KC.AutoVote.Enabled=v end })
    gbEL:AddLabel("Set preferred maps as comma list:")
    gbEL:AddTextbox("AVoteMaps", { Text="Maps (comma sep)", Default="",
        ClearTextOnFocus=true,
        Callback=function(v)
            KC.AutoVote.Maps = {}
            for m in string.gmatch(v, "([^,]+)") do
                table.insert(KC.AutoVote.Maps, m:match("^%s*(.-)%s*$"))
            end
        end })

    gbEL:AddDivider()
    gbEL:AddToggle("ABanOn", { Text="Auto Weapon Ban", Default=false,
        Callback=function(v) KC.AutoBan.Enabled=v end })
    gbEL:AddTextbox("ABanFirst", { Text="First ban (comma sep)", Default="",
        ClearTextOnFocus=true,
        Callback=function(v)
            KC.AutoBan.FirstWeapons = {}
            for w in string.gmatch(v, "([^,]+)") do
                table.insert(KC.AutoBan.FirstWeapons, w:match("^%s*(.-)%s*$"))
            end
        end })
    gbEL:AddTextbox("ABanSec", { Text="Second ban (comma sep)", Default="",
        ClearTextOnFocus=true,
        Callback=function(v)
            KC.AutoBan.SecondWeapons = {}
            for w in string.gmatch(v, "([^,]+)") do
                table.insert(KC.AutoBan.SecondWeapons, w:match("^%s*(.-)%s*$"))
            end
        end })

    gbEL:AddDivider()
    gbEL:AddToggle("TripmineAT", { Text="Tripmine Auto Trigger", Default=false,
        Callback=function(v) KC.Tripmines.AutoTrigger=v end })
    gbEL:AddToggle("TripmineTeam", { Text="Team Trigger", Default=false,
        Callback=function(v) KC.Tripmines.TeamTrigger=v end })

    gbEL:AddDivider()
    gbEL:AddToggle("AutoLoadout", { Text="Auto Equip Loadout", Default=false,
        Callback=function(v) KC.AutoLoadout.Enabled=v; if v then KApplyAutoLoadout() end end })
    gbEL:AddSlider("LoadoutSlot", { Text="Loadout Slot", Default=1, Min=1, Max=5, Rounding=0,
        Callback=function(v) KC.AutoLoadout.SlotIndex=v end })

    local gbER = WT.Extra:AddRightGroupbox("Mod Detector")
    gbER:AddToggle("ModDetOn", { Text="Mod Detector", Default=false,
        Callback=function(v) KC.ModDetect.Enabled=v; if v then KStartModDetect() else KClearModHL() end end })
    gbER:AddDropdown("ModDetAct", { Text="Action", Default=1, Values={"Notify","ToLobby"},
        Callback=function(v) KC.ModDetect.Action=v end })
    gbER:AddLabel("Detects mods via attributes / badges")

    local gbER2 = WT.Extra:AddRightGroupbox("Sound Visualizer+")
    gbER2:AddDropdown("SVSource", { Text="Source Filter", Default=1, Values={"All","Footsteps","Other"},
        Callback=function(v) KC.SVExt.Source=v end })
    gbER2:AddToggle("SVLoudness", { Text="Loudness Color", Default=true,
        Callback=function(v) KC.SVExt.UseLoudness=v end })
end

-- ── UI: Combat / Rage+ tab ───────────────────────────────────────────────────
do
    local gbRL = WT.RBExt:AddLeftGroupbox("Ragebot+")
    gbRL:AddToggle("RExtPH",     { Text="Prioritize Hackers", Default=false,
        Callback=function(v) KC.RageExt.PrioritizeHackers=v end })
    gbRL:AddToggle("RExtHL",     { Text="Utilize Health Lead", Default=false,
        Callback=function(v) KC.RageExt.UtilizeHealthLead=v end })
    gbRL:AddSlider("RExtStab",   { Text="Stability", Default=15, Min=0, Max=150, Rounding=0,
        Callback=function(v) KC.RageExt.Stability=v/100 end })
    gbRL:AddSlider("RExtSF",     { Text="Shoot Frames", Default=1, Min=1, Max=5, Rounding=0,
        Callback=function(v) KC.RageExt.ShootFrames=v end })
    gbRL:AddDropdown("RExtEv",   { Text="Evasion Mode", Default=1,
        Values={"Off","Random","Translocate","ProjectileBreaker"},
        Callback=function(v) KC.RageExt.EvasionMode=v end })

    local gbRR = WT.RBExt:AddRightGroupbox("ESP Extra")
    gbRR:AddToggle("HMOn",       { Text="Head Marker", Default=false,
        Callback=function(v) KC.ESPExt.HeadMarker=v; if not v then KClearHMMarkers() end end })
    gbRR:AddDropdown("HMShape",  { Text="Shape", Default=1, Values={"Cross","Circle","Diamond"},
        Callback=function(v) KC.ESPExt.HMShape=v; KClearHMMarkers() end })
    gbRR:AddToggle("HMFilled",   { Text="Filled", Default=true,
        Callback=function(v) KC.ESPExt.HMFilled=v; KClearHMMarkers() end })
    gbRR:AddDivider()
    gbRR:AddToggle("HNOn",       { Text="Health Number", Default=false,
        Callback=function(v) KC.ESPExt.HealthNumber=v; if not v then KClearHNMarkers() end end })
    gbRR:AddToggle("RankOn",     { Text="Rank Label", Default=false,
        Callback=function(v) KC.ESPExt.Rank=v end })
    gbRR:AddToggle("WSOn",       { Text="Winstreak Label", Default=false,
        Callback=function(v) KC.ESPExt.Winstreak=v end })
    gbRR:AddToggle("DeflOn",     { Text="Deflecting Label", Default=false,
        Callback=function(v) KC.ESPExt.Deflecting=v end })
    gbRR:AddToggle("AmmoOn",     { Text="Ammo Bar", Default=false,
        Callback=function(v) KC.ESPExt.AmmoBar=v; if not v then KClearAmmoMarkers() end end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UNCODE — FULL KICIA FEATURE BLOCK
-- Movement · Removables · ThirdPerson · CamFOV · StretchedRes
-- ItemModifiers · BulletTracers · ViewmodelOffset · HitFeedback
-- PlayerSpoofer · AnimationPlayer · DeviceSpoof
-- ════════════════════════════════════════════════════════════════════════════

-- ── New tabs ─────────────────────────────────────────────────────────────────
WT.Move    = TB.Misc:AddTab("Movement")
WT.Visual3 = TB.Visual:AddTab("Visual+")
WT.ItemMd  = TB.Combat:AddTab("Item Mod")
WT.Spoof   = TB.Misc:AddTab("Spoof")

-- ── Full config tables ────────────────────────────────────────────────────────
local MV = {
    WalkSpeed  = { Enabled=false, Speed=16 },
    JumpPower  = { Enabled=false, Speed=50 },
    Flight     = { Enabled=false, Speed=60 },
    Noclip     = { Enabled=false },
    AutoStrafe = { Enabled=false, Speed=30 },
    LongJump   = { Enabled=false, Force=60, Up=20 },
    Sliding    = { Enabled=false, Speed=40 },
    InfDoubleJump = false,
}

local REM = {
    NoFlashbang=false, NoBurnEffect=false, NoAdsVignette=false,
    NoScopeOverlay=false, NoGunTracers=false, NoMuzzleFlash=false,
    NoHitmarker=false, NoCameraSway=false, NoCameraShake=false,
    NoSprintAnim=false, NoEquipAnim=false, NoReloadAnim=false,
}

local TP = { Enabled=false, ShowReplica=false, X=3, Y=2, Z=6 }
local CFOV = { Enabled=false, Value=70 }
local SRES = { Enabled=false, X=13, Y=10 }

local IM = {
    NoSpread=false, NoMotion=false,
    AimCooldown={ Enabled=false, Pct=50 },
    Recoil={ Enabled=false, Pct=75 },
    FireCooldown={ Enabled=false, Pct=25 },
    AimSpeed={ Enabled=false, Pct=300 },
    MeleeCooldown={ Enabled=false, Pct=25 },
    DashCooldown={ Enabled=false, Pct=25 },
    ExtendMelee={ Enabled=false, Range=10 },
    AutoWeapon=false,
    AlwaysBackstab=false,
    GrenadeFuse={ Enabled=false, ExplodeOn="Impact", RemoveFuse=false },
}

local BT = {
    Enabled=false, Color=Color3.fromRGB(120,220,255),
    Width=0.06, Lifetime=0.6, FadeTime=0.35,
    Emission=1, Glow=1,
}

local VMO = { Enabled=false, X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0 }

local HFB = {
    Hit={ Enabled=false, Sound=false, Flash=false, FlashColor=Color3.fromRGB(90,170,255), Duration=1.35 },
    Kill={ Enabled=false, Sound=false, Flash=false, FlashColor=Color3.fromRGB(90,170,255), Duration=1.35 },
    HitNotify=false, KillNotify=false,
}

local SP = {
    Enabled=false,
    Name="", DisplayName="",
    Winstreak=0, Level=0, Ping="Low",
}

local AP = { Enabled=false, AnimId="", Speed=1 }

-- ── Movement system ───────────────────────────────────────────────────────────
local flightBV, flightBG = nil, nil

local function MVGetHum()
    local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function MVGetHRP()
    local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart")
end

-- Walk/Jump/Noclip heartbeat
VBind(RunService.Heartbeat:Connect(function(dt)
    local hum = MVGetHum(); local hrp = MVGetHRP()
    if hum then
        -- WalkSpeed
        if MV.WalkSpeed.Enabled then
            pcall(function() hum.WalkSpeed = MV.WalkSpeed.Speed end)
        end
        -- JumpPower
        if MV.JumpPower.Enabled then
            pcall(function() hum.JumpPower = MV.JumpPower.Speed end)
        end
    end
    -- Noclip
    if MV.Noclip.Enabled and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
    end
    -- Flight
    if MV.Flight.Enabled and hrp then
        if not flightBV or not flightBV.Parent then
            flightBV = Instance.new("BodyVelocity")
            flightBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            flightBV.Velocity = Vector3.zero
            flightBV.Parent = hrp
            flightBG = Instance.new("BodyGyro")
            flightBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            flightBG.D = 500
            flightBG.Parent = hrp
        end
        local cam = workspace.CurrentCamera
        local vel = Vector3.zero
        local spd = MV.Flight.Speed
        local UIS2 = UserInputService
        if UIS2:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector * spd end
        if UIS2:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector * spd end
        if UIS2:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector * spd end
        if UIS2:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector * spd end
        if UIS2:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,spd,0) end
        if UIS2:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,spd,0) end
        pcall(function() flightBV.Velocity = vel end)
        pcall(function() flightBG.CFrame = cam.CFrame end)
    elseif flightBV and flightBV.Parent then
        pcall(function() flightBV:Destroy(); flightBG:Destroy() end)
        flightBV = nil; flightBG = nil
    end
    -- Sliding speed boost
    if MV.Sliding.Enabled and hrp then
        local UIS2 = UserInputService
        if UIS2:IsKeyDown(Enum.KeyCode.LeftControl) or UIS2:IsKeyDown(Enum.KeyCode.C) then
            pcall(function()
                local vel = hrp.Velocity
                hrp.Velocity = vel + hrp.CFrame.LookVector * MV.Sliding.Speed * dt
            end)
        end
    end
end))

-- LongJump on space
VBind(UserInputService.JumpRequest:Connect(function()
    if not MV.LongJump.Enabled then return end
    local hrp = MVGetHRP(); if not hrp then return end
    local hum = MVGetHum(); if not hum then return end
    task.spawn(function()
        task.wait(0.05)
        pcall(function()
            hrp.Velocity = hrp.CFrame.LookVector * MV.LongJump.Force
                         + Vector3.new(0, MV.LongJump.Up, 0)
        end)
    end)
end))

-- Camera FOV
VBind(RunService.RenderStepped:Connect(function()
    if CFOV.Enabled then
        pcall(function() workspace.CurrentCamera.FieldOfView = CFOV.Value end)
    end
end))

-- Third Person camera
local tpCamConn = nil
local function ApplyThirdPerson()
    if tpCamConn then tpCamConn:Disconnect(); tpCamConn = nil end
    if not TP.Enabled then
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        return
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    tpCamConn = RunService.RenderStepped:Connect(function()
        if not TP.Enabled then
            pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
            if tpCamConn then tpCamConn:Disconnect(); tpCamConn = nil end
            return
        end
        local hrp = MVGetHRP(); if not hrp then return end
        local cam = workspace.CurrentCamera
        local cf = hrp.CFrame
        local offset = CFrame.new(TP.X, TP.Y, TP.Z)
        pcall(function()
            cam.CFrame = cf * offset
        end)
    end)
end
VBind(tpCamConn or RunService.Heartbeat:Connect(function() end))

-- Stretched Resolution
local function ApplyStretchedRes()
    if not SRES.Enabled then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        cam.ViewportSize = Vector2.new(
            cam.ViewportSize.X * (SRES.X / 10),
            cam.ViewportSize.Y * (SRES.Y / 10)
        )
    end)
end

-- ── Removables ────────────────────────────────────────────────────────────────
local function ApplyRemovables()
    -- NoFlashbang: remove flash GUI
    if REM.NoFlashbang then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, g in ipairs(pg:GetDescendants()) do
                if g.Name:lower():find("flash") or g.Name:lower():find("blind") then
                    pcall(function() g.Enabled = false end)
                end
            end
        end
    end
    -- NoBurnEffect: remove fire particles on character
    if REM.NoBurnEffect and LocalPlayer.Character then
        for _, d in ipairs(LocalPlayer.Character:GetDescendants()) do
            if d:IsA("Fire") or d:IsA("Smoke") then
                pcall(function() d.Enabled = false end)
            end
        end
    end
    -- NoMuzzleFlash: disable particle emitters on ViewModels
    if REM.NoMuzzleFlash then
        local vms = workspace:FindFirstChild("ViewModels")
        if vms then
            for _, d in ipairs(vms:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Beam") then
                    local n = d.Name:lower()
                    if n:find("muzzle") or n:find("flash") then
                        pcall(function() d.Enabled = false end)
                    end
                end
            end
        end
    end
    -- NoHitmarker: hide hitmarker GUI
    if REM.NoHitmarker then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, g in ipairs(pg:GetDescendants()) do
                if g.Name:lower():find("hitmark") or g.Name:lower():find("hit_mark") then
                    pcall(function() g.Visible = false end)
                end
            end
        end
    end
    -- NoScopeOverlay: hide scope GUI
    if REM.NoScopeOverlay then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, g in ipairs(pg:GetDescendants()) do
                if g.Name:lower():find("scope") or g.Name:lower():find("ads") then
                    pcall(function()
                        if g:IsA("ScreenGui") or g:IsA("Frame") then g.Visible = false end
                    end)
                end
            end
        end
    end
    -- NoCameraSway: prevent camera sway via attribute
    if REM.NoCameraSway then
        pcall(function() LocalPlayer:SetAttribute("NoCameraSway", true) end)
    end
    -- NoCameraShake: prevent shake
    if REM.NoCameraShake then
        pcall(function() LocalPlayer:SetAttribute("NoCameraShake", true) end)
    end
end

VBind(RunService.Heartbeat:Connect(function()
    ApplyRemovables()
end))

-- ── Item Modifiers ─────────────────────────────────────────────────────────────
local function ApplyItemMods()
    if not LocalPlayer.Character then return end
    -- Apply to FighterController's EquippedItem
    pcall(function()
        if not FighterController or not FighterController.LocalFighter then return end
        local lf = FighterController.LocalFighter
        local item = lf and lf.EquippedItem
        if not item then return end
        -- NoSpread
        if IM.NoSpread then
            item:SetAttribute("Spread", 0)
            item:SetAttribute("MinSpread", 0)
        end
        -- NoMotion
        if IM.NoMotion then
            item:SetAttribute("NoMotion", true)
        end
        -- AimCooldown
        if IM.AimCooldown.Enabled then
            local base = item:GetAttribute("AimCooldown") or 0.2
            item:SetAttribute("AimCooldown", base * (IM.AimCooldown.Pct / 100))
        end
        -- Recoil
        if IM.Recoil.Enabled then
            item:SetAttribute("Recoil", (item:GetAttribute("Recoil") or 1) * (IM.Recoil.Pct / 100))
            item:SetAttribute("RecoilX", (item:GetAttribute("RecoilX") or 1) * (IM.Recoil.Pct / 100))
        end
        -- FireCooldown
        if IM.FireCooldown.Enabled then
            local base = item:GetAttribute("FireCooldown") or item:GetAttribute("_fire_cooldown") or 0.1
            item:SetAttribute("FireCooldown", base * (IM.FireCooldown.Pct / 100))
        end
        -- MeleeCooldown
        if IM.MeleeCooldown.Enabled then
            local base = item:GetAttribute("_attack_cooldown") or 0.5
            item:SetAttribute("_attack_cooldown", base * (IM.MeleeCooldown.Pct / 100))
        end
        -- DashCooldown
        if IM.DashCooldown.Enabled then
            local base = item:GetAttribute("DashCooldown") or 1
            item:SetAttribute("DashCooldown", base * (IM.DashCooldown.Pct / 100))
        end
        -- ExtendMeleeRange
        if IM.ExtendMelee.Enabled then
            item:SetAttribute("MeleeRange", (item:GetAttribute("MeleeRange") or 5) + IM.ExtendMelee.Range)
        end
        -- AlwaysBackstab
        if IM.AlwaysBackstab then
            item:SetAttribute("AlwaysBackstab", true)
        end
        -- AutomaticWeapon
        if IM.AutoWeapon then
            item:SetAttribute("IsAutomatic", true)
            item:SetAttribute("FireMode", "Automatic")
        end
    end)
    -- AimSpeed (camera lerp speed attribute)
    if IM.AimSpeed.Enabled then
        pcall(function() LocalPlayer:SetAttribute("AimSpeed", IM.AimSpeed.Pct / 100) end)
    end
    -- InfiniteDoubleJumps
    if MV.InfDoubleJump then
        local hum = MVGetHum()
        if hum then pcall(function() hum:SetAttribute("DoubleJumpsLeft", 999) end) end
    end
end

VBind(RunService.Heartbeat:Connect(function()
    ApplyItemMods()
end))

-- ── Bullet Tracers ────────────────────────────────────────────────────────────
-- Hook UseItem:FireServer to draw a tracer from gun muzzle to aimed position
local btConns = {}
local function ClearBulletTracers()
    for _, c in ipairs(btConns) do pcall(function() c:Disconnect() end) end
    btConns = {}
end

local function SpawnBulletTracer(from, to)
    local dist = (to - from).Magnitude
    if dist < 1 then return end
    local att0 = Instance.new("Attachment")
    att0.WorldPosition = from
    att0.Parent = workspace.Terrain
    local att1 = Instance.new("Attachment")
    att1.WorldPosition = to
    att1.Parent = workspace.Terrain
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0; beam.Attachment1 = att1
    beam.FaceCamera = true
    beam.Width0 = BT.Width; beam.Width1 = BT.Width
    beam.Color = ColorSequence.new(BT.Color)
    beam.LightEmission = BT.Glow
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = workspace.Terrain
    game:GetService("Debris"):AddItem(att0, BT.Lifetime)
    game:GetService("Debris"):AddItem(att1, BT.Lifetime)
    game:GetService("Debris"):AddItem(beam, BT.Lifetime)
end

VBind(RunService.Heartbeat:Connect(function()
    if not BT.Enabled then ClearBulletTracers(); return end
end))

-- Hook bullet fire events to draw tracers
local btHookConn = nil
local function SetupBulletTracerHook()
    if btHookConn then btHookConn:Disconnect(); btHookConn = nil end
    if not BT.Enabled then return end
    local remote = repS:FindFirstChild("Remotes") and
                   repS.Remotes:FindFirstChild("Replication") and
                   repS.Remotes.Replication:FindFirstChild("Fighter") and
                   repS.Remotes.Replication.Fighter:FindFirstChild("UseItem")
    if not remote then return end
    -- Listen for all players firing
    btHookConn = remote.OnClientEvent and remote.OnClientEvent:Connect(function(...)
        if not BT.Enabled then return end
        local args = {...}
        -- Try to get origin from local char muzzle, destination from args
        task.spawn(function()
            local hrp = MVGetHRP(); if not hrp then return end
            local from = hrp.Position + Vector3.new(0, 1.5, 0)
            local cam = workspace.CurrentCamera
            local to = from + cam.CFrame.LookVector * 500
            SpawnBulletTracer(from, to)
        end)
    end)
    -- Also draw tracer on local fire via RenderStepped snapshot
end

-- ── Viewmodel Offset ──────────────────────────────────────────────────────────
VBind(RunService.RenderStepped:Connect(function()
    if not VMO.Enabled then return end
    pcall(function()
        local vms = workspace:FindFirstChild("ViewModels")
        if not vms then return end
        for _, vm in ipairs(vms:GetChildren()) do
            if vm:IsA("Model") and vm.Name:find(LocalPlayer.Name, 1, true) then
                local primary = vm.PrimaryPart or vm:FindFirstChild("HumanoidRootPart")
                if primary then
                    local offCF = CFrame.new(VMO.X, VMO.Y, VMO.Z)
                               * CFrame.Angles(math.rad(VMO.Pitch), math.rad(VMO.Yaw), math.rad(VMO.Roll))
                    vm:SetPrimaryPartCFrame(vm:GetPrimaryPartCFrame() * offCF)
                end
            end
        end
    end)
end))

-- ── Hit / Kill Feedback ────────────────────────────────────────────────────────
local function PlayFeedbackSound(isKill)
    local sound = Instance.new("Sound")
    sound.SoundId = isKill and "rbxassetid://131961136" or "rbxassetid://4612356639"
    sound.Volume = 0.8
    sound.RollOffMaxDistance = 0
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function FlashScreen(color, duration)
    local sg = Instance.new("ScreenGui")
    sg.Name = "UC_HitFlash"; sg.IgnoreGuiInset = true; sg.ResetOnSpawn = false
    sg.DisplayOrder = 19999; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = CoreGui
    local fr = Instance.new("Frame", sg)
    fr.Size = UDim2.new(1,0,1,0); fr.BackgroundColor3 = color
    fr.BackgroundTransparency = 0.7; fr.BorderSizePixel = 0
    game:GetService("TweenService"):Create(fr, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
    game:GetService("Debris"):AddItem(sg, duration + 0.1)
end

-- Hook hit/kill events
VBind(Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        local hum = c:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.HealthChanged:Connect(function(hp)
            if p == LocalPlayer then return end
            -- Enemy got hit by us (proxy: health went down)
        end)
    end)
end))

-- Self damage flash
VBind(RunService.Heartbeat:Connect(function()
    if not HFB.Hit.Enabled and not HFB.Kill.Enabled then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
end))

-- UseItem hook for hit/kill detection
local hfbHookConn = nil
local lastHitTime = 0
local function SetupHFBHook()
    if hfbHookConn then hfbHookConn:Disconnect(); hfbHookConn = nil end
    -- Listen for elimination events on PlayerGui
    task.spawn(function()
        while true do
            task.wait(0.2)
            if not HFB.Hit.Enabled and not HFB.Kill.Enabled then continue end
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if not pg then continue end
            -- Detect kill feed events
            for _, g in ipairs(pg:GetDescendants()) do
                if g:IsA("TextLabel") and (g.Name:lower():find("kill") or g.Name:lower():find("elim")) then
                    local t = tick()
                    if t - lastHitTime > 0.5 then
                        lastHitTime = t
                        if HFB.Kill.Flash then FlashScreen(HFB.Kill.FlashColor, HFB.Kill.Duration) end
                        if HFB.Kill.Sound then PlayFeedbackSound(true) end
                        if HFB.KillNotify then Notify("Enemy eliminated!", 1.5) end
                    end
                end
            end
        end
    end)
end
SetupHFBHook()

-- ── Player Spoofer ────────────────────────────────────────────────────────────
local spoofConns = {}
local function ApplySpoof()
    for _, c in ipairs(spoofConns) do pcall(function() c:Disconnect() end) end
    spoofConns = {}
    if not SP.Enabled then return end
    -- Spoof player attributes visible to server (client-side only)
    pcall(function()
        if SP.Name ~= "" then
            -- Display name override on nametag
            local char = LocalPlayer.Character
            if char then
                local overhead = char:FindFirstChild("Overhead") or char:FindFirstChild("Head")
                if overhead then
                    local nameTag = overhead:FindFirstChild("PlayerName") or overhead:FindFirstChildWhichIsA("BillboardGui")
                    if nameTag then
                        local lbl = nameTag:FindFirstChildWhichIsA("TextLabel")
                        if lbl then lbl.Text = SP.Name end
                    end
                end
            end
        end
        -- Attribute spoofing
        if SP.Level > 0 then LocalPlayer:SetAttribute("Level", SP.Level) end
        if SP.Winstreak > 0 then LocalPlayer:SetAttribute("Winstreak", SP.Winstreak) end
    end)
end

VBind(RunService.Heartbeat:Connect(function()
    if not SP.Enabled then return end
    if tick() % 2 < 0.02 then ApplySpoof() end
end))

-- ── Animation Player ──────────────────────────────────────────────────────────
local currentAnim = nil
local animTrack = nil

local function PlayAnimation(animId, speed)
    if not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or
                     Instance.new("Animator", hum)
    if animTrack then pcall(function() animTrack:Stop(); animTrack:Destroy() end) end
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(animId):gsub("%D","")
        animTrack = animator:LoadAnimation(anim)
        animTrack:Play()
        animTrack:AdjustSpeed(speed or 1)
    end)
end

local function StopAnimation()
    if animTrack then
        pcall(function() animTrack:Stop(); animTrack:Destroy() end)
        animTrack = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- UI: Misc / Movement tab
-- ════════════════════════════════════════════════════════════════════════════
do
    local gbML = WT.Move:AddLeftGroupbox("Movement Speed")
    gbML:AddToggle("MVWalk",     { Text="Walk Speed Override", Default=false,
        Callback=function(v) MV.WalkSpeed.Enabled=v end })
    gbML:AddSlider("MVWalkSpd",  { Text="Walk Speed", Default=16, Min=0, Max=200, Rounding=0,
        Callback=function(v) MV.WalkSpeed.Speed=v end })
    gbML:AddToggle("MVJump",     { Text="Jump Power Override", Default=false,
        Callback=function(v) MV.JumpPower.Enabled=v end })
    gbML:AddSlider("MVJumpSpd",  { Text="Jump Power", Default=50, Min=0, Max=500, Rounding=0,
        Callback=function(v) MV.JumpPower.Speed=v end })
    gbML:AddToggle("MVFlight",   { Text="Flight", Default=false,
        Callback=function(v) MV.Flight.Enabled=v end })
    gbML:AddSlider("MVFlightSpd",{ Text="Flight Speed", Default=60, Min=5, Max=500, Rounding=0,
        Callback=function(v) MV.Flight.Speed=v end })
    gbML:AddToggle("MVNoclip",   { Text="Noclip", Default=false,
        Callback=function(v) MV.Noclip.Enabled=v end })
    gbML:AddToggle("MVStrafe",   { Text="Auto Strafe", Default=false,
        Callback=function(v) MV.AutoStrafe.Enabled=v end })
    gbML:AddSlider("MVStrafeSpd",{ Text="Strafe Speed", Default=30, Min=5, Max=200, Rounding=0,
        Callback=function(v) MV.AutoStrafe.Speed=v end })
    gbML:AddToggle("MVLongJump", { Text="Long Jump (Space)", Default=false,
        Callback=function(v) MV.LongJump.Enabled=v end })
    gbML:AddSlider("MVLJForce",  { Text="LJ Force", Default=60, Min=10, Max=300, Rounding=0,
        Callback=function(v) MV.LongJump.Force=v end })
    gbML:AddSlider("MVLJUp",     { Text="LJ Upward", Default=20, Min=0, Max=100, Rounding=0,
        Callback=function(v) MV.LongJump.Up=v end })
    gbML:AddToggle("MVSlide",    { Text="Sliding Boost (Ctrl)", Default=false,
        Callback=function(v) MV.Sliding.Enabled=v end })
    gbML:AddToggle("MVInfDJ",    { Text="Infinite Double Jumps", Default=false,
        Callback=function(v) MV.InfDoubleJump=v end })

    local gbMR = WT.Move:AddRightGroupbox("Camera")
    gbMR:AddToggle("TPOn",       { Text="Third Person", Default=false,
        Callback=function(v) TP.Enabled=v; ApplyThirdPerson() end })
    gbMR:AddSlider("TPX",        { Text="TP Offset X", Default=3, Min=-10, Max=10, Rounding=1,
        Callback=function(v) TP.X=v end })
    gbMR:AddSlider("TPY",        { Text="TP Offset Y", Default=2, Min=-5, Max=10, Rounding=1,
        Callback=function(v) TP.Y=v end })
    gbMR:AddSlider("TPZ",        { Text="TP Offset Z", Default=6, Min=1, Max=30, Rounding=1,
        Callback=function(v) TP.Z=v end })
    gbMR:AddDivider()
    gbMR:AddToggle("CFOVOn",     { Text="Camera FOV Override", Default=false,
        Callback=function(v) CFOV.Enabled=v; if not v then pcall(function() workspace.CurrentCamera.FieldOfView=70 end) end end })
    gbMR:AddSlider("CFOVVal",    { Text="FOV", Default=70, Min=20, Max=140, Rounding=0,
        Callback=function(v) CFOV.Value=v end })
    gbMR:AddDivider()
    gbMR:AddToggle("SResOn",     { Text="Stretched Resolution", Default=false,
        Callback=function(v) SRES.Enabled=v end })
    gbMR:AddSlider("SResX",      { Text="Stretch X", Default=13, Min=5, Max=20, Rounding=0,
        Callback=function(v) SRES.X=v; if SRES.Enabled then ApplyStretchedRes() end end })
    gbMR:AddSlider("SResY",      { Text="Stretch Y", Default=10, Min=5, Max=20, Rounding=0,
        Callback=function(v) SRES.Y=v; if SRES.Enabled then ApplyStretchedRes() end end })
    gbMR:AddButton("SResApply",  { Text="Apply Resolution", Callback=function() ApplyStretchedRes() end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UI: Visual+ tab (Removables + Viewmodel Offset + BulletTracers + HitFeedback)
-- ════════════════════════════════════════════════════════════════════════════
do
    local gbVL = WT.Visual3:AddLeftGroupbox("Removables")
    gbVL:AddToggle("RNoFlash",   { Text="No Flashbang",       Default=false, Callback=function(v) REM.NoFlashbang=v end })
    gbVL:AddToggle("RNoBurn",    { Text="No Burn Effect",     Default=false, Callback=function(v) REM.NoBurnEffect=v end })
    gbVL:AddToggle("RNoScope",   { Text="No Scope Overlay",   Default=false, Callback=function(v) REM.NoScopeOverlay=v end })
    gbVL:AddToggle("RNoMuzzle",  { Text="No Muzzle Flash",    Default=false, Callback=function(v) REM.NoMuzzleFlash=v end })
    gbVL:AddToggle("RNoHitmark", { Text="No Hitmarker",       Default=false, Callback=function(v) REM.NoHitmarker=v end })
    gbVL:AddToggle("RNoCamSway", { Text="No Camera Sway",     Default=false, Callback=function(v) REM.NoCameraSway=v end })
    gbVL:AddToggle("RNoCamShk",  { Text="No Camera Shake",    Default=false, Callback=function(v) REM.NoCameraShake=v end })
    gbVL:AddToggle("RNoSprintA", { Text="No Sprint Anim",     Default=false, Callback=function(v) REM.NoSprintAnim=v end })
    gbVL:AddToggle("RNoEquipA",  { Text="No Equip Anim",      Default=false, Callback=function(v) REM.NoEquipAnim=v end })
    gbVL:AddToggle("RNoReloadA", { Text="No Reload Anim",     Default=false, Callback=function(v) REM.NoReloadAnim=v end })

    local gbVL2 = WT.Visual3:AddLeftGroupbox("Viewmodel Offset")
    gbVL2:AddToggle("VMOOn",     { Text="Viewmodel Offset", Default=false,
        Callback=function(v) VMO.Enabled=v end })
    gbVL2:AddSlider("VMOX",      { Text="X", Default=0, Min=-5, Max=5, Rounding=2,
        Callback=function(v) VMO.X=v end })
    gbVL2:AddSlider("VMOY",      { Text="Y", Default=0, Min=-5, Max=5, Rounding=2,
        Callback=function(v) VMO.Y=v end })
    gbVL2:AddSlider("VMOZ",      { Text="Z", Default=0, Min=-5, Max=5, Rounding=2,
        Callback=function(v) VMO.Z=v end })
    gbVL2:AddSlider("VMOPitch",  { Text="Pitch", Default=0, Min=-180, Max=180, Rounding=0,
        Callback=function(v) VMO.Pitch=v end })
    gbVL2:AddSlider("VMOYaw",    { Text="Yaw",   Default=0, Min=-180, Max=180, Rounding=0,
        Callback=function(v) VMO.Yaw=v end })
    gbVL2:AddSlider("VMORoll",   { Text="Roll",  Default=0, Min=-180, Max=180, Rounding=0,
        Callback=function(v) VMO.Roll=v end })

    local gbVR = WT.Visual3:AddRightGroupbox("Bullet Tracers")
    gbVR:AddToggle("BTOn",       { Text="Bullet Tracers", Default=false,
        Callback=function(v) BT.Enabled=v; SetupBulletTracerHook() end })
    gbVR:AddColorPicker("BTCol", { Text="Color", Default=Color3.fromRGB(120,220,255),
        Callback=function(v) BT.Color=v end })
    gbVR:AddSlider("BTWidth",    { Text="Width", Default=6, Min=1, Max=30, Rounding=0,
        Callback=function(v) BT.Width=v/100 end })
    gbVR:AddSlider("BTLife",     { Text="Lifetime (ms)", Default=600, Min=50, Max=3000, Rounding=0,
        Callback=function(v) BT.Lifetime=v/1000 end })
    gbVR:AddSlider("BTGlow",     { Text="Glow", Default=1, Min=0, Max=5, Rounding=1,
        Callback=function(v) BT.Glow=v end })

    local gbVR2 = WT.Visual3:AddRightGroupbox("Hit Feedback")
    gbVR2:AddToggle("HFBHit",    { Text="Hit Flash", Default=false,
        Callback=function(v) HFB.Hit.Flash=v; HFB.Hit.Enabled=v end })
    gbVR2:AddColorPicker("HFBHitCol", { Text="Hit Color", Default=Color3.fromRGB(90,170,255),
        Callback=function(v) HFB.Hit.FlashColor=v end })
    gbVR2:AddToggle("HFBKill",   { Text="Kill Flash", Default=false,
        Callback=function(v) HFB.Kill.Flash=v; HFB.Kill.Enabled=v end })
    gbVR2:AddColorPicker("HFBKillCol", { Text="Kill Color", Default=Color3.fromRGB(255,100,50),
        Callback=function(v) HFB.Kill.FlashColor=v end })
    gbVR2:AddToggle("HFBHitSnd", { Text="Hit Sound", Default=false,
        Callback=function(v) HFB.Hit.Sound=v; HFB.Hit.Enabled=v end })
    gbVR2:AddToggle("HFBKillSnd",{ Text="Kill Sound", Default=false,
        Callback=function(v) HFB.Kill.Sound=v; HFB.Kill.Enabled=v end })
    gbVR2:AddToggle("HFBNotify", { Text="Kill Notify", Default=false,
        Callback=function(v) HFB.KillNotify=v end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UI: Combat / Item Mod tab
-- ════════════════════════════════════════════════════════════════════════════
do
    local gbIL = WT.ItemMd:AddLeftGroupbox("Weapon Modifiers")
    gbIL:AddToggle("IMNoSpread", { Text="No Spread", Default=false,
        Callback=function(v) IM.NoSpread=v end })
    gbIL:AddToggle("IMNoMot",    { Text="No Motion", Default=false,
        Callback=function(v) IM.NoMotion=v end })
    gbIL:AddToggle("IMAutoWep",  { Text="Force Automatic", Default=false,
        Callback=function(v) IM.AutoWeapon=v end })
    gbIL:AddToggle("IMBackstab", { Text="Always Backstab", Default=false,
        Callback=function(v) IM.AlwaysBackstab=v end })
    gbIL:AddToggle("IMInfJump",  { Text="Infinite Double Jumps", Default=false,
        Callback=function(v) MV.InfDoubleJump=v end })
    gbIL:AddDivider()
    gbIL:AddToggle("IMAimCD",    { Text="Aim Cooldown %", Default=false,
        Callback=function(v) IM.AimCooldown.Enabled=v end })
    gbIL:AddSlider("IMAimCDPct", { Text="Pct", Default=50, Min=1, Max=200, Rounding=0,
        Callback=function(v) IM.AimCooldown.Pct=v end })
    gbIL:AddToggle("IMFireCD",   { Text="Fire Cooldown %", Default=false,
        Callback=function(v) IM.FireCooldown.Enabled=v end })
    gbIL:AddSlider("IMFireCDPct",{ Text="Pct", Default=25, Min=1, Max=200, Rounding=0,
        Callback=function(v) IM.FireCooldown.Pct=v end })
    gbIL:AddToggle("IMRecoil",   { Text="Recoil %", Default=false,
        Callback=function(v) IM.Recoil.Enabled=v end })
    gbIL:AddSlider("IMRecoilPct",{ Text="Pct", Default=75, Min=0, Max=200, Rounding=0,
        Callback=function(v) IM.Recoil.Pct=v end })

    local gbIR = WT.ItemMd:AddRightGroupbox("Melee / Utility")
    gbIR:AddToggle("IMMelCD",    { Text="Melee Cooldown %", Default=false,
        Callback=function(v) IM.MeleeCooldown.Enabled=v end })
    gbIR:AddSlider("IMMelCDPct", { Text="Pct", Default=25, Min=1, Max=200, Rounding=0,
        Callback=function(v) IM.MeleeCooldown.Pct=v end })
    gbIR:AddToggle("IMDashCD",   { Text="Dash Cooldown %", Default=false,
        Callback=function(v) IM.DashCooldown.Enabled=v end })
    gbIR:AddSlider("IMDashCDPct",{ Text="Pct", Default=25, Min=1, Max=200, Rounding=0,
        Callback=function(v) IM.DashCooldown.Pct=v end })
    gbIR:AddToggle("IMExtMel",   { Text="Extend Melee Range", Default=false,
        Callback=function(v) IM.ExtendMelee.Enabled=v end })
    gbIR:AddSlider("IMExtMelR",  { Text="Range +", Default=10, Min=1, Max=50, Rounding=0,
        Callback=function(v) IM.ExtendMelee.Range=v end })
    gbIR:AddToggle("IMAimSpd",   { Text="Aim Speed %", Default=false,
        Callback=function(v) IM.AimSpeed.Enabled=v end })
    gbIR:AddSlider("IMAimSpdPct",{ Text="Pct", Default=300, Min=50, Max=1000, Rounding=0,
        Callback=function(v) IM.AimSpeed.Pct=v end })
    gbIR:AddDivider()
    gbIR:AddToggle("IMGrenFuse", { Text="Grenade Fuse Override", Default=false,
        Callback=function(v) IM.GrenadeFuse.Enabled=v end })
    gbIR:AddDropdown("IMGrenOn", { Text="Explode On", Default=1,
        Values={"Impact","Timer","RemoveFuse"},
        Callback=function(v)
            if v == "RemoveFuse" then IM.GrenadeFuse.RemoveFuse=true
            else IM.GrenadeFuse.ExplodeOn=v; IM.GrenadeFuse.RemoveFuse=false end
        end })
end

-- ════════════════════════════════════════════════════════════════════════════
-- UI: Misc / Spoof tab
-- ════════════════════════════════════════════════════════════════════════════
do
    local gbSL = WT.Spoof:AddLeftGroupbox("Player Spoofer")
    gbSL:AddToggle("SPOn",       { Text="Enable Spoofer", Default=false,
        Callback=function(v) SP.Enabled=v; if v then ApplySpoof() end end })
    gbSL:AddTextbox("SPName",    { Text="Spoof Name", Default="",
        ClearTextOnFocus=true,
        Callback=function(v) SP.Name=v end })
    gbSL:AddSlider("SPLevel",    { Text="Spoof Level", Default=0, Min=0, Max=9999, Rounding=0,
        Callback=function(v) SP.Level=v end })
    gbSL:AddSlider("SPWins",     { Text="Spoof Winstreak", Default=0, Min=0, Max=9999, Rounding=0,
        Callback=function(v) SP.Winstreak=v end })
    gbSL:AddButton("SPApply",    { Text="Apply Now", Callback=function() ApplySpoof(); Notify("Spoof applied",2) end })
    gbSL:AddButton("SPReset",    { Text="Reset Spoof", Callback=function()
        SP.Enabled=false; SP.Name=""; SP.Level=0; SP.Winstreak=0
        Notify("Spoof reset",2)
    end })

    local gbSR = WT.Spoof:AddRightGroupbox("Animation Player")
    gbSR:AddTextbox("APAnimId",  { Text="Animation ID", Default="",
        ClearTextOnFocus=true,
        Callback=function(v) AP.AnimId=v end })
    gbSR:AddSlider("APSpeed",    { Text="Speed", Default=100, Min=10, Max=300, Rounding=0,
        Callback=function(v) AP.Speed=v/100 end })
    gbSR:AddButton("APPlay",     { Text="Play Animation", Callback=function()
        if AP.AnimId == "" then Notify("Enter animation ID first",2); return end
        PlayAnimation(AP.AnimId, AP.Speed)
        Notify("Playing anim: " .. AP.AnimId, 2)
    end })
    gbSR:AddButton("APStop",     { Text="Stop Animation", Callback=function()
        StopAnimation()
        Notify("Animation stopped", 2)
    end })
    gbSR:AddLabel("Common IDs: Cat Girl Bounce = 6521355977")
    gbSR:AddLabel("Run = 616157050")
end

-- =====================================================================
-- [FINAL BLOCK — LightingOverride/PostFX/Weather/ViewModelMods/
--  MovementRecorder/CustomWorld/Overlays/Bhop/CharAppearance/
--  DeviceSpoof/Skybox/ConfigTransfer]
-- =====================================================================

-- ===== NEW CONFIG TABLES =====
local LO = {
    Enabled = false,
    Ambient = { Enabled=false, Indoor=Color3.fromRGB(59,203,255), Outdoor=Color3.fromRGB(1,102,139) },
    ClockTime = { Enabled=false, Value=12 },
    Brightness = { Enabled=false, Value=2 },
    ColorShift = { Enabled=false, Top=Color3.fromRGB(100,160,255), Bottom=Color3.fromRGB(20,40,90) },
    ExposureCompensation = { Enabled=false, Value=0 },
    Fog = { Enabled=false, Color=Color3.fromRGB(192,192,192), FogStart=0, FogEnd=100000 },
    DisableGlobalShadows = false,
    ShadowSoftness = { Enabled=false, Value=0.5 },
    GeographicLatitude = { Enabled=false, Value=41.733 },
    Atmosphere = { Enabled=false, Density=0.395, Offset=0, Haze=0, Glare=0 },
}

local PE = {
    Bloom = { Enabled=false, Intensity=0.4, Size=24, Threshold=0.95 },
    ColorCorrection = { Enabled=false, TintColor=Color3.new(1,1,1), Saturation=0, Brightness=0, Contrast=0 },
    DepthOfField = { Enabled=false, FarIntensity=0.75, FocusDistance=0.05, InFocusRadius=10, NearIntensity=0.75 },
    SunRays = { Enabled=false, Intensity=0.25, Spread=1 },
    MotionBlur = { Enabled=false, Intensity=10 },
}

local WE = {
    Enabled = false,
    Preset = "Snow",
    Intensity = 1,
    Rate = 1,
    Height = 45,
    Color = Color3.fromRGB(255,255,255),
    Lightning = { Enabled=false, Interval=2, Flash=8 },
}

local DS = { Enabled=false, DeviceType="VR" }

local VMH = {
    Highlight = {
        Enabled=false,
        FillColor=Color3.fromRGB(120,200,255),
        FillTrans=0.5,
        OutlineColor=Color3.fromRGB(255,255,255),
        OutlineTrans=0,
    },
    Wireframe = { Enabled=false, Color=Color3.fromRGB(255,255,255) },
}

local MR = {
    Recording = false,
    Replaying = false,
    Loop = false,
    Ghost = { Enabled=true, Color=Color3.fromRGB(150,180,255), Transparency=0.5 },
}
local mrPath = {}
local mrRecConn, mrReplayConn, mrGhostModel = nil, nil, nil

local SKY = {
    Enabled = false,
    SkyboxId = "",
    TopId = "", BottomId = "", FrontId = "",
    BackId = "", LeftId = "", RightId = "",
}

local SND = { Volume=1, Pitch=1 }
local sndItems = {}

local IMG = {}
local imgLabels = {}

local MRK = { DefaultColor=Color3.fromRGB(255,100,100), Size=1 }
local markerParts = {}

local CA = { Enabled=false, BodyColor=Color3.fromRGB(163,162,165), ShowHats=true, ShowFace=true }
local caBackup = {}

local BHOP = { Enabled=false }
local bhopConn = nil

-- ===== LIGHTING OVERRIDE =====
local loBackup = {}
local loActive = false
local Lighting = game:GetService("Lighting")

local function ApplyLightingOverride()
    if not loActive then
        loBackup = {
            Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
            ClockTime=Lighting.ClockTime, Brightness=Lighting.Brightness,
            ColorShift_Top=Lighting.ColorShift_Top, ColorShift_Bottom=Lighting.ColorShift_Bottom,
            ExposureCompensation=Lighting.ExposureCompensation,
            FogColor=Lighting.FogColor, FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd,
            GlobalShadows=Lighting.GlobalShadows, ShadowSoftness=Lighting.ShadowSoftness,
            GeographicLatitude=Lighting.GeographicLatitude,
        }
        loActive = true
    end
    if LO.Ambient.Enabled then
        Lighting.Ambient = LO.Ambient.Indoor
        Lighting.OutdoorAmbient = LO.Ambient.Outdoor
    end
    if LO.ClockTime.Enabled then Lighting.ClockTime = LO.ClockTime.Value end
    if LO.Brightness.Enabled then Lighting.Brightness = LO.Brightness.Value end
    if LO.ColorShift.Enabled then
        Lighting.ColorShift_Top = LO.ColorShift.Top
        Lighting.ColorShift_Bottom = LO.ColorShift.Bottom
    end
    if LO.ExposureCompensation.Enabled then Lighting.ExposureCompensation = LO.ExposureCompensation.Value end
    if LO.Fog.Enabled then
        Lighting.FogColor = LO.Fog.Color
        Lighting.FogStart = LO.Fog.FogStart
        Lighting.FogEnd = LO.Fog.FogEnd
    end
    if LO.DisableGlobalShadows then Lighting.GlobalShadows = false end
    if LO.ShadowSoftness.Enabled then Lighting.ShadowSoftness = LO.ShadowSoftness.Value end
    if LO.GeographicLatitude.Enabled then Lighting.GeographicLatitude = LO.GeographicLatitude.Value end
end

local function RestoreLightingOverride()
    if not loActive then return end
    for k, v in pairs(loBackup) do pcall(function() Lighting[k] = v end) end
    loActive = false
end

local function ApplyAtmosphere()
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then return end
    if not LO.Atmosphere.Enabled then return end
    atmo.Density = LO.Atmosphere.Density
    atmo.Offset  = LO.Atmosphere.Offset
    atmo.Haze    = LO.Atmosphere.Haze
    atmo.Glare   = LO.Atmosphere.Glare
end

-- ===== POST EFFECTS =====
local function GetOrMakeEffect(cls)
    local e = Lighting:FindFirstChildOfClass(cls)
    if not e then e = Instance.new(cls, Lighting) end
    return e
end

local function ApplyPostEffects()
    -- Bloom
    local b = GetOrMakeEffect("BloomEffect")
    b.Enabled   = PE.Bloom.Enabled
    b.Intensity = PE.Bloom.Intensity
    b.Size      = PE.Bloom.Size
    b.Threshold = PE.Bloom.Threshold
    -- ColorCorrection
    local c = GetOrMakeEffect("ColorCorrectionEffect")
    c.Enabled    = PE.ColorCorrection.Enabled
    c.TintColor  = PE.ColorCorrection.TintColor
    c.Saturation = PE.ColorCorrection.Saturation
    c.Brightness = PE.ColorCorrection.Brightness
    c.Contrast   = PE.ColorCorrection.Contrast
    -- DepthOfField
    local d = GetOrMakeEffect("DepthOfFieldEffect")
    d.Enabled       = PE.DepthOfField.Enabled
    d.FarIntensity  = PE.DepthOfField.FarIntensity
    d.FocusDistance = PE.DepthOfField.FocusDistance
    d.InFocusRadius = PE.DepthOfField.InFocusRadius
    d.NearIntensity = PE.DepthOfField.NearIntensity
    -- SunRays
    local s = GetOrMakeEffect("SunRaysEffect")
    s.Enabled   = PE.SunRays.Enabled
    s.Intensity = PE.SunRays.Intensity
    s.Spread    = PE.SunRays.Spread
    -- MotionBlur (BlurEffect)
    local m = GetOrMakeEffect("BlurEffect")
    m.Enabled = PE.MotionBlur.Enabled
    m.Size    = PE.MotionBlur.Intensity
end

-- ===== WEATHER =====
local weFolder = nil
local weConns = {}

local function CleanWeather()
    for _, c in ipairs(weConns) do pcall(function() c:Disconnect() end) end
    weConns = {}
    if weFolder and weFolder.Parent then weFolder:Destroy() end
    weFolder = nil
end

local function ApplyWeather()
    CleanWeather()
    if not WE.Enabled then return end
    weFolder = Instance.new("Folder")
    weFolder.Name = "_UCWeather"
    weFolder.Parent = workspace
    local emitPart = Instance.new("Part")
    emitPart.Anchored = true; emitPart.CanCollide = false; emitPart.CastShadow = false
    emitPart.Transparency = 1
    emitPart.Size = Vector3.new(200, 0.1, 200)
    emitPart.Parent = weFolder
    local pe2 = Instance.new("ParticleEmitter", emitPart)
    pe2.Rate  = WE.Rate * 50
    pe2.Color = ColorSequence.new(WE.Color)
    pe2.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.9, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    if WE.Preset == "Snow" then
        pe2.Speed    = NumberRange.new(WE.Intensity * 6, WE.Intensity * 14)
        pe2.Size     = NumberSequence.new(WE.Intensity * 0.15)
        pe2.Rotation = NumberRange.new(-30, 30)
        pe2.RotSpeed = NumberRange.new(-45, 45)
        pe2.LifeTime = NumberRange.new(5, 9)
    elseif WE.Preset == "Rain" then
        pe2.Speed    = NumberRange.new(WE.Intensity * 30, WE.Intensity * 60)
        pe2.Size     = NumberSequence.new(0.035)
        pe2.Rotation = NumberRange.new(6, 8)
        pe2.LifeTime = NumberRange.new(0.8, 1.8)
    elseif WE.Preset == "Fog" then
        pe2.Rate     = 4
        pe2.Speed    = NumberRange.new(0.3, 1.5)
        pe2.Size     = NumberSequence.new(WE.Intensity * 10)
        pe2.LifeTime = NumberRange.new(14, 28)
        pe2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        })
    elseif WE.Preset == "Sand" then
        pe2.Speed    = NumberRange.new(WE.Intensity * 8, WE.Intensity * 18)
        pe2.Size     = NumberSequence.new(0.07)
        pe2.Rotation = NumberRange.new(0, 360)
        pe2.LifeTime = NumberRange.new(3, 6)
        pe2.Color    = ColorSequence.new(Color3.fromRGB(210,180,140))
    end
    local cam = Camera
    table.insert(weConns, RunService.Heartbeat:Connect(function()
        if not cam then return end
        local cf = cam.CFrame
        emitPart.CFrame = CFrame.new(cf.X, cf.Y + WE.Height, cf.Z)
    end))
    if WE.Lightning.Enabled then
        table.insert(weConns, RunService.Heartbeat:Connect(function()
            if math.random() < (1 / (60 * WE.Lightning.Interval)) then
                local pl = Instance.new("PointLight")
                pl.Brightness = WE.Lightning.Flash
                pl.Range = 1200
                pl.Color = Color3.fromRGB(214, 230, 255)
                pl.Parent = workspace.Terrain
                game:GetService("Debris"):AddItem(pl, 0.18)
            end
        end))
    end
end

-- ===== SKYBOX =====
local skyBackup = {}
local function ApplySkybox()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not SKY.Enabled then
        if sky then
            for k, v in pairs(skyBackup) do pcall(function() sky[k] = v end) end
        end
        skyBackup = {}
        return
    end
    if not sky then sky = Instance.new("Sky", Lighting) end
    if not next(skyBackup) then
        for _, k in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
            skyBackup[k] = sky[k]
        end
    end
    if SKY.SkyboxId ~= "" then
        local id = "rbxassetid://" .. SKY.SkyboxId
        sky.SkyboxBk = id; sky.SkyboxDn = id; sky.SkyboxFt = id
        sky.SkyboxLf = id; sky.SkyboxRt = id; sky.SkyboxUp = id
    end
    if SKY.TopId ~= ""    then sky.SkyboxUp = "rbxassetid://" .. SKY.TopId end
    if SKY.BottomId ~= "" then sky.SkyboxDn = "rbxassetid://" .. SKY.BottomId end
    if SKY.FrontId ~= ""  then sky.SkyboxFt = "rbxassetid://" .. SKY.FrontId end
    if SKY.BackId ~= ""   then sky.SkyboxBk = "rbxassetid://" .. SKY.BackId end
    if SKY.LeftId ~= ""   then sky.SkyboxLf = "rbxassetid://" .. SKY.LeftId end
    if SKY.RightId ~= ""  then sky.SkyboxRt = "rbxassetid://" .. SKY.RightId end
end

-- ===== DEVICE SPOOF =====
local function ApplyDeviceSpoof()
    if not DS.Enabled then
        lp:SetAttribute("__UC_DeviceType", nil)
        return
    end
    lp:SetAttribute("__UC_DeviceType", DS.DeviceType)
end

-- ===== VIEWMODEL HIGHLIGHT / WIREFRAME =====
local vmhSelBoxes = {}
local function CleanVMH()
    for _, sb in ipairs(vmhSelBoxes) do pcall(function() sb:Destroy() end) end
    vmhSelBoxes = {}
end

local function ApplyVMH()
    CleanVMH()
    local targets = {}
    -- Search camera viewmodel
    for _, d in ipairs(Camera:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(targets, d) end
    end
    -- Search character arms/hands
    local char = lp.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and (d.Name:find("Arm") or d.Name:find("Hand")) then
                table.insert(targets, d)
            end
        end
    end
    if VMH.Highlight.Enabled then
        for _, part in ipairs(targets) do
            local sb = Instance.new("SelectionBox")
            sb.Adornee             = part
            sb.Color3              = VMH.Highlight.OutlineColor
            sb.LineThickness       = 0.04
            sb.SurfaceColor3       = VMH.Highlight.FillColor
            sb.SurfaceTransparency = VMH.Highlight.FillTrans
            sb.Parent              = part
            table.insert(vmhSelBoxes, sb)
        end
    end
    if VMH.Wireframe.Enabled then
        for _, part in ipairs(targets) do
            local sb = Instance.new("SelectionBox")
            sb.Adornee             = part
            sb.Color3              = VMH.Wireframe.Color
            sb.LineThickness       = 0.025
            sb.SurfaceTransparency = 1
            sb.Parent              = part
            table.insert(vmhSelBoxes, sb)
        end
    end
end

-- ===== CUSTOM SOUND SYSTEM =====
local sndFolder = nil
local function GetSndFolder()
    if sndFolder and sndFolder.Parent then return sndFolder end
    sndFolder = Instance.new("Folder")
    sndFolder.Name = "_UCSounds"
    sndFolder.Parent = workspace
    return sndFolder
end

local function AddCustomSound(id)
    local f = GetSndFolder()
    local s = Instance.new("Sound")
    s.SoundId         = "rbxassetid://" .. id
    s.Volume          = SND.Volume
    s.PlaybackSpeed   = SND.Pitch
    s.Looped          = true
    s.RollOffMaxDistance = 10000
    s.Name            = "UCSound_" .. id
    s.Parent          = f
    s:Play()
    table.insert(sndItems, s)
    return s
end

local function RemoveAllSounds()
    for _, s in ipairs(sndItems) do pcall(function() s:Stop(); s:Destroy() end) end
    sndItems = {}
end

-- ===== CUSTOM IMAGE OVERLAY =====
local imgGui = nil
local function GetImgGui()
    if imgGui and imgGui.Parent then return imgGui end
    imgGui = Instance.new("ScreenGui")
    imgGui.Name           = "_UCImages"
    imgGui.ResetOnSpawn   = false
    imgGui.DisplayOrder   = 998
    imgGui.IgnoreGuiInset = true
    imgGui.Parent         = game:GetService("CoreGui")
    return imgGui
end

local function AddImageOverlay(id, px, py, sx, sy, tr)
    local gui   = GetImgGui()
    local label = Instance.new("ImageLabel")
    label.Image               = "rbxassetid://" .. id
    label.BackgroundTransparency = 1
    label.ImageTransparency   = tr  or 0
    label.Position            = UDim2.new(px or 0.5, 0, py or 0.5, 0)
    label.Size                = UDim2.new(sx or 0.2, 0, sy or 0.2, 0)
    label.AnchorPoint         = Vector2.new(0.5, 0.5)
    label.ZIndex              = 999
    label.Parent              = gui
    table.insert(imgLabels, label)
    return label
end

local function RemoveAllImages()
    for _, l in ipairs(imgLabels) do pcall(function() l:Destroy() end) end
    imgLabels = {}
end

-- ===== HUD TEXT OVERLAYS =====
local goGui = nil
local goElements = {}
local function GetGoGui()
    if goGui and goGui.Parent then return goGui end
    goGui = Instance.new("ScreenGui")
    goGui.Name           = "_UCOverlays"
    goGui.ResetOnSpawn   = false
    goGui.DisplayOrder   = 997
    goGui.IgnoreGuiInset = true
    goGui.Parent         = game:GetService("CoreGui")
    return goGui
end

local function AddHUDText(txt, px, py, sz, col)
    local gui   = GetGoGui()
    local label = Instance.new("TextLabel")
    label.Text                  = txt
    label.BackgroundTransparency = 1
    label.TextColor3            = col or Color3.fromRGB(255,255,255)
    label.TextStrokeTransparency = 0.45
    label.TextSize              = sz or 18
    label.Font                  = Enum.Font.GothamBold
    label.Position              = UDim2.new(px or 0.5, 0, py or 0.1, 0)
    label.Size                  = UDim2.new(0.3, 0, 0, sz or 18)
    label.AnchorPoint           = Vector2.new(0.5, 0)
    label.ZIndex                = 998
    label.Parent                = gui
    table.insert(goElements, label)
    return label
end

local function ClearHUDOverlays()
    for _, e in ipairs(goElements) do pcall(function() e:Destroy() end) end
    goElements = {}
end

-- ===== WORLD MARKERS =====
local mrkFolder = nil
local function GetMrkFolder()
    if mrkFolder and mrkFolder.Parent then return mrkFolder end
    mrkFolder = Instance.new("Folder")
    mrkFolder.Name   = "_UCMarkers"
    mrkFolder.Parent = workspace
    return mrkFolder
end

local function PlaceMarker(pos, label, col)
    local f    = GetMrkFolder()
    local part = Instance.new("Part")
    part.Anchored   = true; part.CanCollide = false; part.CastShadow = false
    part.Size       = Vector3.new(0.35, 0.35, 0.35) * MRK.Size
    part.Shape      = Enum.PartType.Ball
    part.Material   = Enum.Material.Neon
    part.Color      = col or MRK.DefaultColor
    part.CFrame     = CFrame.new(pos)
    part.Parent     = f
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop  = true
    bb.Size         = UDim2.new(0, 80, 0, 22)
    bb.StudsOffset  = Vector3.new(0, 2, 0)
    bb.Parent       = part
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                  = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = label or "Marker"
    lbl.TextColor3            = col or MRK.DefaultColor
    lbl.TextStrokeTransparency = 0.4
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 13
    table.insert(markerParts, part)
    return part
end

local function ClearMarkers()
    for _, p in ipairs(markerParts) do pcall(function() p:Destroy() end) end
    markerParts = {}
end

-- ===== MOVEMENT RECORDER =====
local function MR_StartRecord()
    if MR.Recording then return end
    mrPath   = {}
    MR.Recording = true
    mrRecConn = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(mrPath, hrp.CFrame) end
    end)
    Notify("Recording movement…", 2)
end

local function MR_StopRecord()
    if not MR.Recording then return end
    MR.Recording = false
    if mrRecConn then mrRecConn:Disconnect(); mrRecConn = nil end
    Notify("Recorded " .. #mrPath .. " frames", 3)
end

local function MR_Replay()
    if #mrPath == 0 then Notify("Nothing recorded", 2); return end
    if mrGhostModel then pcall(function() mrGhostModel:Destroy() end) end
    local ghost = Instance.new("Model")
    ghost.Name = "_UCGhost"
    local gp = Instance.new("Part")
    gp.Size        = Vector3.new(2, 5, 1)
    gp.Anchored    = true
    gp.CanCollide  = false
    gp.CastShadow  = false
    gp.Color       = MR.Ghost.Color
    gp.Transparency= MR.Ghost.Transparency
    gp.Material    = Enum.Material.Neon
    gp.Parent      = ghost
    ghost.PrimaryPart = gp
    ghost.Parent   = workspace
    mrGhostModel   = ghost
    MR.Replaying   = true
    local idx = 1
    mrReplayConn = RunService.Heartbeat:Connect(function()
        if not MR.Replaying then
            if mrReplayConn then mrReplayConn:Disconnect(); mrReplayConn = nil end
            return
        end
        gp.CFrame = mrPath[idx]
        idx = idx + 1
        if idx > #mrPath then
            if MR.Loop then idx = 1
            else MR.Replaying = false end
        end
    end)
    Notify("Replay started", 2)
end

local function MR_StopReplay()
    MR.Replaying = false
    if mrReplayConn then mrReplayConn:Disconnect(); mrReplayConn = nil end
    if mrGhostModel then pcall(function() mrGhostModel:Destroy() end); mrGhostModel = nil end
    Notify("Replay stopped", 2)
end

-- ===== BHOP =====
local function SetBhop(on)
    BHOP.Enabled = on
    if bhopConn then bhopConn:Disconnect(); bhopConn = nil end
    if not on then return end
    bhopConn = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ===== CHARACTER APPEARANCE =====
local function ApplyCharAppearance()
    local char = lp.Character
    if not char then return end
    if not CA.Enabled then
        for partName, col in pairs(caBackup) do
            local p = char:FindFirstChild(partName)
            if p and p:IsA("BasePart") then pcall(function() p.Color = col end) end
        end
        caBackup = {}
        return
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            if not caBackup[d.Name] then caBackup[d.Name] = d.Color end
            pcall(function() d.Color = CA.BodyColor end)
        end
        if not CA.ShowFace and d.Name == "face" then
            pcall(function() d.Transparency = 1 end)
        end
    end
    if not CA.ShowHats then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Accessory") then pcall(function() d.Parent = nil end) end
        end
    end
end

-- ===== CONFIG EXPORT =====
local function CopyConfigToClipboard()
    local lines = {
        "-- UNCODE Config Export",
        "-- Combat",
        "VOID_ENABLED=" .. tostring(CFG.VOID_ENABLED),
        "orbitEnabled=" .. tostring(cfg.orbitEnabled),
        "-- Aimbot",
        "Aimbot=" .. tostring(KC.Aimbot.Enabled),
        "SilentAim=" .. tostring(KC.SilentAim.Enabled),
        "Triggerbot=" .. tostring(KC.Triggerbot.Enabled),
        "-- Visual",
        "ESP_Box=" .. tostring(VC.ESP.Box),
        "Chams_Self=" .. tostring(VC.Chams.Self),
        "Chams_Enemy=" .. tostring(VC.Chams.Enemy),
        "Aura=" .. tostring(VC.Aura.Enabled),
        "-- PostFX",
        "Bloom=" .. tostring(PE.Bloom.Enabled),
        "ColorCorrection=" .. tostring(PE.ColorCorrection.Enabled),
        "DoF=" .. tostring(PE.DepthOfField.Enabled),
        "SunRays=" .. tostring(PE.SunRays.Enabled),
        "-- Movement",
        "Flight=" .. tostring(MV.Flight.Enabled),
        "Noclip=" .. tostring(MV.Noclip.Enabled),
        "Bhop=" .. tostring(BHOP.Enabled),
    }
    local str = table.concat(lines, "\n")
    local ok = pcall(function()
        local fn = setclipboard or (syn and syn.setclipboard) or toclipboard
        if fn then fn(str) else error("no clipboard") end
    end)
    if ok then Notify("Config copied to clipboard", 3)
    else Notify("Clipboard unavailable in this executor", 3) end
end

-- ===== NEW TABS =====
WT.Light    = TB.Visual:AddTab("Lighting")
WT.PostFX   = TB.Visual:AddTab("PostFX")
WT.Environ  = TB.Visual:AddTab("Environ")
WT.VMod     = TB.Visual:AddTab("ViewModel")
WT.Record   = TB.Misc:AddTab("Recorder")
WT.WorldAdd = TB.Misc:AddTab("World+")
WT.CfgXfer  = TB.Setting:AddTab("Transfer")

-- ===== LIGHTING UI =====
do
    local gbLL = WT.Light:AddLeftGroupbox("Lighting Override")
    gbLL:AddToggle("LOEnabled", { Text="Enable Override", Default=false,
        Callback=function(v)
            LO.Enabled = v
            if v then ApplyLightingOverride() else RestoreLightingOverride() end
        end })
    gbLL:AddDivider()
    gbLL:AddToggle("LOAmbient", { Text="Custom Ambient", Default=false,
        Callback=function(v) LO.Ambient.Enabled=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddColorpicker("LOAmbIn", { Text="Indoor Ambient", Default=LO.Ambient.Indoor,
        Callback=function(v) LO.Ambient.Indoor=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddColorpicker("LOAmbOut", { Text="Outdoor Ambient", Default=LO.Ambient.Outdoor,
        Callback=function(v) LO.Ambient.Outdoor=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddToggle("LOClock", { Text="Override Clock Time", Default=false,
        Callback=function(v) LO.ClockTime.Enabled=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddSlider("LOClockVal", { Text="Clock Time (0-24)", Default=12, Min=0, Max=24, Rounding=1,
        Callback=function(v) LO.ClockTime.Value=v; if LO.Enabled and LO.ClockTime.Enabled then ApplyLightingOverride() end end })
    gbLL:AddToggle("LOBright", { Text="Override Brightness", Default=false,
        Callback=function(v) LO.Brightness.Enabled=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddSlider("LOBrightVal", { Text="Brightness", Default=20, Min=0, Max=100, Rounding=0,
        Callback=function(v) LO.Brightness.Value=v/10; if LO.Enabled and LO.Brightness.Enabled then ApplyLightingOverride() end end })
    gbLL:AddToggle("LONoShadow", { Text="Disable Global Shadows", Default=false,
        Callback=function(v) LO.DisableGlobalShadows=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLL:AddButton("LOApply", { Text="Apply Override", Callback=function()
        if LO.Enabled then ApplyLightingOverride(); Notify("Lighting applied",2) end
    end })
    gbLL:AddButton("LORestore", { Text="Restore Lighting", Callback=function()
        RestoreLightingOverride(); Notify("Lighting restored",2)
    end })

    local gbLR = WT.Light:AddRightGroupbox("Fog & Atmosphere")
    gbLR:AddToggle("LOFog", { Text="Override Fog", Default=false,
        Callback=function(v) LO.Fog.Enabled=v; if LO.Enabled then ApplyLightingOverride() end end })
    gbLR:AddColorpicker("LOFogCol", { Text="Fog Color", Default=LO.Fog.Color,
        Callback=function(v) LO.Fog.Color=v; if LO.Enabled and LO.Fog.Enabled then ApplyLightingOverride() end end })
    gbLR:AddSlider("LOFogEnd", { Text="Fog End Distance", Default=10000, Min=50, Max=200000, Rounding=0,
        Callback=function(v) LO.Fog.FogEnd=v; if LO.Enabled and LO.Fog.Enabled then ApplyLightingOverride() end end })
    gbLR:AddDivider()
    gbLR:AddToggle("LOAtmo", { Text="Override Atmosphere", Default=false,
        Callback=function(v) LO.Atmosphere.Enabled=v; ApplyAtmosphere() end })
    gbLR:AddSlider("LOAtmoDen", { Text="Density", Default=395, Min=0, Max=1000, Rounding=0,
        Callback=function(v) LO.Atmosphere.Density=v/1000; if LO.Atmosphere.Enabled then ApplyAtmosphere() end end })
    gbLR:AddSlider("LOAtmoHaze", { Text="Haze", Default=0, Min=0, Max=100, Rounding=0,
        Callback=function(v) LO.Atmosphere.Haze=v; if LO.Atmosphere.Enabled then ApplyAtmosphere() end end })
    gbLR:AddSlider("LOAtmoGlare", { Text="Glare", Default=0, Min=0, Max=100, Rounding=0,
        Callback=function(v) LO.Atmosphere.Glare=v/10; if LO.Atmosphere.Enabled then ApplyAtmosphere() end end })
    gbLR:AddDivider()
    gbLR:AddToggle("SkyEnabled", { Text="Custom Skybox", Default=false,
        Callback=function(v) SKY.Enabled=v; ApplySkybox() end })
    gbLR:AddTextbox("SkyId", { Text="Skybox Asset ID (all faces)", Default="",
        ClearTextOnFocus=true,
        Callback=function(v) SKY.SkyboxId=v end })
    gbLR:AddTextbox("SkyTop",   { Text="Top Face ID",    Default="", ClearTextOnFocus=true, Callback=function(v) SKY.TopId=v end })
    gbLR:AddTextbox("SkyBot",   { Text="Bottom Face ID", Default="", ClearTextOnFocus=true, Callback=function(v) SKY.BottomId=v end })
    gbLR:AddButton("SkyApply",   { Text="Apply Skybox",   Callback=function() ApplySkybox(); Notify("Skybox applied",2) end })
    gbLR:AddButton("SkyRestore", { Text="Restore Skybox", Callback=function()
        SKY.Enabled=false; ApplySkybox(); Notify("Skybox restored",2)
    end })
end

-- ===== POST FX UI =====
do
    local gbBL = WT.PostFX:AddLeftGroupbox("Bloom")
    gbBL:AddToggle("PEBloom", { Text="Enable Bloom", Default=false,
        Callback=function(v) PE.Bloom.Enabled=v; ApplyPostEffects() end })
    gbBL:AddSlider("PEBloomInt",  { Text="Intensity", Default=40, Min=0, Max=300, Rounding=0,
        Callback=function(v) PE.Bloom.Intensity=v/100; ApplyPostEffects() end })
    gbBL:AddSlider("PEBloomSize", { Text="Size",      Default=24, Min=1,  Max=56,  Rounding=0,
        Callback=function(v) PE.Bloom.Size=v; ApplyPostEffects() end })
    gbBL:AddSlider("PEBloomThrs", { Text="Threshold", Default=95, Min=0,  Max=100, Rounding=0,
        Callback=function(v) PE.Bloom.Threshold=v/100; ApplyPostEffects() end })

    local gbCC = WT.PostFX:AddLeftGroupbox("Color Correction")
    gbCC:AddToggle("PECC", { Text="Enable Color Correction", Default=false,
        Callback=function(v) PE.ColorCorrection.Enabled=v; ApplyPostEffects() end })
    gbCC:AddColorpicker("PECCTint", { Text="Tint Color", Default=Color3.new(1,1,1),
        Callback=function(v) PE.ColorCorrection.TintColor=v; ApplyPostEffects() end })
    gbCC:AddSlider("PECCSat", { Text="Saturation", Default=0, Min=-100, Max=100, Rounding=0,
        Callback=function(v) PE.ColorCorrection.Saturation=v/100; ApplyPostEffects() end })
    gbCC:AddSlider("PECCBri", { Text="Brightness",  Default=0, Min=-100, Max=100, Rounding=0,
        Callback=function(v) PE.ColorCorrection.Brightness=v/100; ApplyPostEffects() end })
    gbCC:AddSlider("PECCCon", { Text="Contrast",    Default=0, Min=-100, Max=100, Rounding=0,
        Callback=function(v) PE.ColorCorrection.Contrast=v/100; ApplyPostEffects() end })

    local gbDR = WT.PostFX:AddRightGroupbox("Depth of Field")
    gbDR:AddToggle("PEDoF", { Text="Enable Depth of Field", Default=false,
        Callback=function(v) PE.DepthOfField.Enabled=v; ApplyPostEffects() end })
    gbDR:AddSlider("PEDoFFar",   { Text="Far Intensity",   Default=75, Min=0, Max=100, Rounding=0,
        Callback=function(v) PE.DepthOfField.FarIntensity=v/100; ApplyPostEffects() end })
    gbDR:AddSlider("PEDoFFocus", { Text="Focus Distance",  Default=5,  Min=0, Max=200, Rounding=0,
        Callback=function(v) PE.DepthOfField.FocusDistance=v/100; ApplyPostEffects() end })
    gbDR:AddSlider("PEDoFRad",   { Text="Focus Radius",    Default=10, Min=1, Max=100, Rounding=0,
        Callback=function(v) PE.DepthOfField.InFocusRadius=v; ApplyPostEffects() end })
    gbDR:AddSlider("PEDoFNear",  { Text="Near Intensity",  Default=75, Min=0, Max=100, Rounding=0,
        Callback=function(v) PE.DepthOfField.NearIntensity=v/100; ApplyPostEffects() end })

    local gbSR = WT.PostFX:AddRightGroupbox("Sun Rays & Motion Blur")
    gbSR:AddToggle("PESun", { Text="Enable Sun Rays", Default=false,
        Callback=function(v) PE.SunRays.Enabled=v; ApplyPostEffects() end })
    gbSR:AddSlider("PESunInt",    { Text="Intensity", Default=25, Min=0, Max=100, Rounding=0,
        Callback=function(v) PE.SunRays.Intensity=v/100; ApplyPostEffects() end })
    gbSR:AddSlider("PESunSpread", { Text="Spread",    Default=100, Min=0, Max=200, Rounding=0,
        Callback=function(v) PE.SunRays.Spread=v/100; ApplyPostEffects() end })
    gbSR:AddDivider()
    gbSR:AddToggle("PEBlur", { Text="Enable Motion Blur", Default=false,
        Callback=function(v) PE.MotionBlur.Enabled=v; ApplyPostEffects() end })
    gbSR:AddSlider("PEBlurSize", { Text="Blur Size", Default=10, Min=0, Max=56, Rounding=0,
        Callback=function(v) PE.MotionBlur.Intensity=v; ApplyPostEffects() end })
    gbSR:AddButton("PEReset", { Text="Reset All PostFX", Callback=function()
        PE.Bloom.Enabled=false; PE.ColorCorrection.Enabled=false
        PE.DepthOfField.Enabled=false; PE.SunRays.Enabled=false
        PE.MotionBlur.Enabled=false; ApplyPostEffects()
        Notify("PostFX reset",2)
    end })
end

-- ===== ENVIRON UI (Weather / DeviceSpoof / CharAppearance) =====
do
    local gbWL = WT.Environ:AddLeftGroupbox("Weather Effects")
    gbWL:AddToggle("WEEnabled", { Text="Enable Weather", Default=false,
        Callback=function(v) WE.Enabled=v; ApplyWeather() end })
    gbWL:AddDropdown("WEPreset", { Text="Weather Type", Default="Snow",
        Values={"Snow","Rain","Fog","Sand"},
        Callback=function(v) WE.Preset=v; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddSlider("WEIntensity", { Text="Intensity", Default=100, Min=10, Max=300, Rounding=0,
        Callback=function(v) WE.Intensity=v/100; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddSlider("WERate",   { Text="Rate",          Default=100, Min=0, Max=500, Rounding=0,
        Callback=function(v) WE.Rate=v/100; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddSlider("WEHeight", { Text="Spawn Height",  Default=45,  Min=5, Max=300, Rounding=0,
        Callback=function(v) WE.Height=v; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddColorpicker("WEColor", { Text="Particle Color", Default=Color3.fromRGB(255,255,255),
        Callback=function(v) WE.Color=v; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddDivider()
    gbWL:AddToggle("WELightning", { Text="Lightning Flashes", Default=false,
        Callback=function(v) WE.Lightning.Enabled=v; if WE.Enabled then ApplyWeather() end end })
    gbWL:AddSlider("WELightInt",   { Text="Lightning Interval (s)", Default=2,  Min=1, Max=30, Rounding=0,
        Callback=function(v) WE.Lightning.Interval=v end })
    gbWL:AddSlider("WELightFlash", { Text="Flash Brightness",       Default=8,  Min=1, Max=20, Rounding=0,
        Callback=function(v) WE.Lightning.Flash=v end })
    gbWL:AddButton("WERestart", { Text="Restart Weather", Callback=function()
        if WE.Enabled then ApplyWeather(); Notify("Weather restarted",2) end
    end })

    local gbWR = WT.Environ:AddRightGroupbox("Device Spoof")
    gbWR:AddToggle("DSEnabled", { Text="Enable Device Spoof", Default=false,
        Callback=function(v) DS.Enabled=v; ApplyDeviceSpoof() end })
    gbWR:AddDropdown("DSType", { Text="Device Type", Default="VR",
        Values={"VR","Mobile","Console","Tablet"},
        Callback=function(v) DS.DeviceType=v; if DS.Enabled then ApplyDeviceSpoof() end end })
    gbWR:AddLabel("Spoof sets player attribute __UC_DeviceType")

    local gbCA = WT.Environ:AddRightGroupbox("Character Appearance")
    gbCA:AddToggle("CAEnabled", { Text="Custom Body Color", Default=false,
        Callback=function(v) CA.Enabled=v; ApplyCharAppearance() end })
    gbCA:AddColorpicker("CAColor", { Text="Body Color", Default=CA.BodyColor,
        Callback=function(v) CA.BodyColor=v; if CA.Enabled then ApplyCharAppearance() end end })
    gbCA:AddToggle("CAHats", { Text="Show Accessories", Default=true,
        Callback=function(v) CA.ShowHats=v; if CA.Enabled then ApplyCharAppearance() end end })
    gbCA:AddToggle("CAFace", { Text="Show Face Texture", Default=true,
        Callback=function(v) CA.ShowFace=v; if CA.Enabled then ApplyCharAppearance() end end })
    gbCA:AddButton("CAApply", { Text="Apply Appearance", Callback=function()
        ApplyCharAppearance(); Notify("Appearance applied",2)
    end })
    gbCA:AddButton("CARestore", { Text="Restore Appearance", Callback=function()
        CA.Enabled=false; ApplyCharAppearance(); Notify("Appearance restored",2)
    end })
end

-- ===== VIEWMODEL UI =====
do
    local gbVL = WT.VMod:AddLeftGroupbox("ViewModel Highlight")
    gbVL:AddToggle("VMHEnabled", { Text="Enable VM Highlight", Default=false,
        Callback=function(v) VMH.Highlight.Enabled=v; ApplyVMH() end })
    gbVL:AddColorpicker("VMHFill", { Text="Fill Color", Default=VMH.Highlight.FillColor,
        Callback=function(v) VMH.Highlight.FillColor=v; if VMH.Highlight.Enabled then ApplyVMH() end end })
    gbVL:AddSlider("VMHFillTr", { Text="Fill Transparency", Default=50, Min=0, Max=100, Rounding=0,
        Callback=function(v) VMH.Highlight.FillTrans=v/100; if VMH.Highlight.Enabled then ApplyVMH() end end })
    gbVL:AddColorpicker("VMHOutC", { Text="Outline Color", Default=VMH.Highlight.OutlineColor,
        Callback=function(v) VMH.Highlight.OutlineColor=v; if VMH.Highlight.Enabled then ApplyVMH() end end })
    gbVL:AddSlider("VMHOutTr", { Text="Outline Transparency", Default=0, Min=0, Max=100, Rounding=0,
        Callback=function(v) VMH.Highlight.OutlineTrans=v/100; if VMH.Highlight.Enabled then ApplyVMH() end end })

    local gbVR = WT.VMod:AddRightGroupbox("ViewModel Wireframe")
    gbVR:AddToggle("VMWEnabled", { Text="Enable VM Wireframe", Default=false,
        Callback=function(v) VMH.Wireframe.Enabled=v; ApplyVMH() end })
    gbVR:AddColorpicker("VMWColor", { Text="Wire Color", Default=VMH.Wireframe.Color,
        Callback=function(v) VMH.Wireframe.Color=v; if VMH.Wireframe.Enabled then ApplyVMH() end end })
    gbVR:AddButton("VMHRefresh", { Text="Refresh ViewModel", Callback=function()
        ApplyVMH(); Notify("ViewModel refreshed",2)
    end })
    gbVR:AddDivider()
    gbVR:AddToggle("BhopEnabled", { Text="Auto Bhop", Default=false,
        Callback=function(v) SetBhop(v) end })
    gbVR:AddLabel("Continuously holds jump while moving")
end

-- ===== RECORDER UI =====
do
    local gbRL = WT.Record:AddLeftGroupbox("Movement Recorder")
    gbRL:AddButton("MRStartBtn", { Text="Start Recording", Callback=MR_StartRecord })
    gbRL:AddButton("MRStopBtn",  { Text="Stop Recording",  Callback=MR_StopRecord  })
    gbRL:AddButton("MRClearBtn", { Text="Clear Recording", Callback=function()
        mrPath={}; Notify("Recording cleared",2)
    end })
    gbRL:AddLabel("Frames: recorded to memory table")
    gbRL:AddDivider()
    gbRL:AddButton("MRReplayBtn",  { Text="Play Ghost Replay",  Callback=MR_Replay      })
    gbRL:AddButton("MRStopRepBtn", { Text="Stop Ghost Replay",  Callback=MR_StopReplay  })
    gbRL:AddToggle("MRLoop",       { Text="Loop Replay",        Default=false,
        Callback=function(v) MR.Loop=v end })

    local gbRR = WT.Record:AddRightGroupbox("Ghost Appearance")
    gbRR:AddToggle("MRGhostShow", { Text="Show Ghost Model", Default=true,
        Callback=function(v) MR.Ghost.Enabled=v end })
    gbRR:AddColorpicker("MRGhostCol", { Text="Ghost Color", Default=MR.Ghost.Color,
        Callback=function(v) MR.Ghost.Color=v end })
    gbRR:AddSlider("MRGhostTr", { Text="Ghost Transparency", Default=50, Min=0, Max=95, Rounding=0,
        Callback=function(v) MR.Ghost.Transparency=v/100 end })
    gbRR:AddLabel("Ghost appears on replay start")
end

-- ===== WORLD+ UI =====
do
    local sndIdBuf = ""
    local gbSL = WT.WorldAdd:AddLeftGroupbox("Custom Ambient Sounds")
    gbSL:AddTextbox("SndIdBox", { Text="Sound Asset ID", Default="",
        ClearTextOnFocus=true, Callback=function(v) sndIdBuf=v end })
    gbSL:AddSlider("SndVol",   { Text="Volume",   Default=100, Min=0, Max=200, Rounding=0,
        Callback=function(v) SND.Volume=v/100 end })
    gbSL:AddSlider("SndPitch", { Text="Pitch",    Default=100, Min=10, Max=300, Rounding=0,
        Callback=function(v) SND.Pitch=v/100 end })
    gbSL:AddButton("SndAdd",    { Text="Add Sound",         Callback=function()
        if sndIdBuf=="" then Notify("Enter sound ID",2); return end
        AddCustomSound(sndIdBuf); Notify("Sound added: "..sndIdBuf, 2)
    end })
    gbSL:AddButton("SndRemove", { Text="Remove All Sounds", Callback=function()
        RemoveAllSounds(); Notify("All sounds removed",2)
    end })

    local imgIdBuf = ""
    local gbIL = WT.WorldAdd:AddLeftGroupbox("Screen Image Overlays")
    gbIL:AddTextbox("ImgIdBox", { Text="Image Asset ID", Default="",
        ClearTextOnFocus=true, Callback=function(v) imgIdBuf=v end })
    gbIL:AddButton("ImgAdd",    { Text="Add Image Overlay",  Callback=function()
        if imgIdBuf=="" then Notify("Enter image ID",2); return end
        AddImageOverlay(imgIdBuf); Notify("Image added",2)
    end })
    gbIL:AddButton("ImgRemove", { Text="Remove All Images",  Callback=function()
        RemoveAllImages(); Notify("All images removed",2)
    end })

    local ovlBuf = ""
    local gbOR = WT.WorldAdd:AddRightGroupbox("HUD Text Overlays")
    gbOR:AddTextbox("OvlText", { Text="Overlay Text", Default="",
        ClearTextOnFocus=true, Callback=function(v) ovlBuf=v end })
    gbOR:AddButton("OvlAdd",   { Text="Add Text",      Callback=function()
        if ovlBuf=="" then Notify("Enter text",2); return end
        AddHUDText(ovlBuf); Notify("HUD overlay added",2)
    end })
    gbOR:AddButton("OvlClear", { Text="Clear All Text", Callback=function()
        ClearHUDOverlays(); Notify("Overlays cleared",2)
    end })

    local gbMR = WT.WorldAdd:AddRightGroupbox("World Markers")
    gbMR:AddColorpicker("MrkColor", { Text="Marker Color", Default=MRK.DefaultColor,
        Callback=function(v) MRK.DefaultColor=v end })
    gbMR:AddSlider("MrkSize", { Text="Marker Size", Default=100, Min=10, Max=500, Rounding=0,
        Callback=function(v) MRK.Size=v/100 end })
    gbMR:AddButton("MrkPlace", { Text="Place Marker Here", Callback=function()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then Notify("No character",2); return end
        PlaceMarker(hrp.Position, "M" .. (#markerParts+1), MRK.DefaultColor)
        Notify("Marker placed",2)
    end })
    gbMR:AddButton("MrkClear", { Text="Clear All Markers", Callback=function()
        ClearMarkers(); Notify("Markers cleared",2)
    end })
end

-- ===== CONFIG TRANSFER UI =====
do
    local gbCL = WT.CfgXfer:AddLeftGroupbox("Export Config")
    gbCL:AddLabel("Copies active settings to clipboard")
    gbCL:AddButton("CfgCopyBtn", { Text="Copy Config to Clipboard", Callback=CopyConfigToClipboard })
    gbCL:AddDivider()
    gbCL:AddLabel("UNCODE v5 — All features loaded")

    local gbCR = WT.CfgXfer:AddRightGroupbox("Reset")
    gbCR:AddButton("CfgResetAll", { Text="Reset All Settings", Callback=function()
        KC.Aimbot.Enabled   = false
        KC.SilentAim.Enabled= false
        KC.Triggerbot.Enabled=false
        CFG.VOID_ENABLED    = false
        cfg.orbitEnabled    = false
        PE.Bloom.Enabled            = false
        PE.ColorCorrection.Enabled  = false
        PE.DepthOfField.Enabled     = false
        PE.SunRays.Enabled          = false
        PE.MotionBlur.Enabled       = false
        LO.Enabled  = false
        WE.Enabled  = false
        BHOP.Enabled= false
        VMH.Highlight.Enabled  = false
        VMH.Wireframe.Enabled  = false
        ApplyPostEffects()
        RestoreLightingOverride()
        CleanWeather()
        SetBhop(false)
        CleanVMH()
        Notify("All settings reset to default", 3)
    end })
    gbCR:AddButton("CfgResetPost", { Text="Reset PostFX Only", Callback=function()
        PE.Bloom.Enabled=false; PE.ColorCorrection.Enabled=false
        PE.DepthOfField.Enabled=false; PE.SunRays.Enabled=false
        PE.MotionBlur.Enabled=false; ApplyPostEffects()
        Notify("PostFX reset",2)
    end })
end

-- ===== CHAR ADDED HOOKS =====
lp.CharacterAdded:Connect(function()
    task.wait(1.2)
    if VMH.Highlight.Enabled or VMH.Wireframe.Enabled then ApplyVMH() end
    if CA.Enabled then ApplyCharAppearance() end
    if BHOP.Enabled then SetBhop(true) end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LuaXLiveStud — Draggable HRP position display widget
-- Extracted from LuaX lines 1-108
-- ═══════════════════════════════════════════════════════════════════════════
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "LuaXLiveStud"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then pcall(function() sg.Parent = LocalPlayer.PlayerGui end) end

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 220, 0, 90)
    frame.Position = UDim2.new(0, 10, 0.5, -45)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80, 140, 255)
    stroke.Thickness = 1.5

    local header = Instance.new("TextLabel", frame)
    header.Size = UDim2.new(1, 0, 0, 22)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(30, 60, 120)
    header.BackgroundTransparency = 0
    header.Text = "  UNCODE LiveStud"
    header.TextColor3 = Color3.fromRGB(180, 210, 255)
    header.TextSize = 12
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.BorderSizePixel = 0
    local hc = Instance.new("UICorner", header)
    hc.CornerRadius = UDim.new(0, 6)

    local function makeCoordLabel(parent, yOffset, labelText)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, -10, 0, 18)
        row.Position = UDim2.new(0, 5, 0, yOffset)
        row.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.35, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(140, 180, 255)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local val = Instance.new("TextLabel", row)
        val.Size = UDim2.new(0.65, 0, 1, 0)
        val.Position = UDim2.new(0.35, 0, 0, 0)
        val.BackgroundTransparency = 1
        val.Text = "---"
        val.TextColor3 = Color3.fromRGB(220, 240, 255)
        val.TextSize = 11
        val.Font = Enum.Font.Gotham
        val.TextXAlignment = Enum.TextXAlignment.Right
        return val
    end

    local xLbl = makeCoordLabel(frame, 26, "X")
    local yLbl = makeCoordLabel(frame, 46, "Y")
    local zLbl = makeCoordLabel(frame, 66, "Z")

    local livestudConn
    local livestudEnabled = true

    RunService.RenderStepped:Connect(function()
        if not livestudEnabled then return end
        local char = LocalPlayer and LocalPlayer.Character
        local hrp2 = char and char:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            local pos = hrp2.Position
            xLbl.Text = string.format("%.2f", pos.X)
            yLbl.Text = string.format("%.2f", pos.Y)
            zLbl.Text = string.format("%.2f", pos.Z)
            xLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
            yLbl.TextColor3 = Color3.fromRGB(120, 255, 120)
            zLbl.TextColor3 = Color3.fromRGB(120, 180, 255)
        else
            xLbl.Text = "---"; yLbl.Text = "---"; zLbl.Text = "---"
            xLbl.TextColor3 = Color3.fromRGB(220,240,255)
            yLbl.TextColor3 = Color3.fromRGB(220,240,255)
            zLbl.TextColor3 = Color3.fromRGB(220,240,255)
        end
    end)

    -- Toggle via UI Setting tab
    pcall(function()
        local gbLive = WT.Config:AddRightGroupbox("LiveStud")
        gbLive:AddToggle("LiveStudEnabled", { Text = "Show Position Widget", Default = true,
            Callback = function(v)
                livestudEnabled = v
                frame.Visible = v
            end })
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UE (Unnamed Enhancements) Feature Block — all features extracted from UE
-- ═══════════════════════════════════════════════════════════════════════════

-- ── UE Configs ───────────────────────────────────────────────────────────────
local UE = {
    -- Aimbot extended
    Aimbot = {
        ClosestPart = true,
        DelayPosition = false,
        DelaySmooth = false,
        DelaySmoothX = 0.1,
        DelaySmoothY = 0.1,
        DelaySmoothJump = 0.2,
        ShowFOV = true,
        FOVFill = false,
        FOVLerp = true,
        FOVMoving = true,
        FOVOutline = true,
        FOVRotation = false,
        FOVRotationSpeed = 45,
        MatchAxis = false,
    },
    -- Silent Aim extended
    Silent = {
        ClosestPart = true,
        ShowFOV = true,
        FOVFill = false,
        FOVLerp = true,
        FOVMoving = true,
        FOVOutline = true,
        FOVRotation = false,
        FOVRotationSpeed = 45,
        HitChance = 100,
        Manipulation = "None",
        Visualize = false,
    },
    -- Exploits
    Exploits = {
        FireRate = false,
        FireRateValue = 0.001,
        FullAuto = false,
        NoSpread = false,
        AlwaysBackstab = false,
        GrenadeExplodeOnImpact = false,
        GrenadeStackDamage = false,
    },
    -- Movement extended
    Movement = {
        InfiniteDoubleJump = false,
        DoubleJumpHeight = 50,
        DoubleJumpHeightMultiplier = 2,
    },
    -- Loadout
    Loadout = {
        Unrestricted = false,
        AutoSelectEnabled = false,
        AutoSelectMelee = true,
        AutoSelectPrimary = true,
        AutoSelectSecondary = true,
        AutoSelectUtility = false,
    },
    -- Auto Queue
    AutoQueue = {
        Enabled = false,
        Mode = "Rejoin",
    },
    -- Auto Ban Voting
    AutoBan = {
        Enabled = false,
        FirstBan = "",
        FirstBanDelay = 0.5,
        SecondBan = "",
        SecondBanDelay = 0.5,
        MapDelay = 1,
        BanMaps = {},
        BanWeapons = {},
    },
    -- Name Spoofer
    NameSpoofer = {
        Enabled = false,
        Name = "Player",
    },
    -- Chat Spam
    ChatSpam = {
        Enabled = false,
        Mode = "Random",
        Text = "gg",
        Order = "Sequential",
    },
    -- Indicator HUD
    Indicator = {
        AmmoEnabled = true,
        AmmoStyle = "Classic",
        AmmoColor = Color3.fromRGB(255,255,255),
        AmmoDividerColor = Color3.fromRGB(120,120,120),
        AmmoMaxColor = Color3.fromRGB(80,80,80),
        EmptyColor = Color3.fromRGB(255,60,60),
        ReserveColor = Color3.fromRGB(180,180,180),
        ManipulatedEnabled = true,
        ManipulatedColor = Color3.fromRGB(255,200,50),
        RagebotEnabled = true,
        RagebotStyle = "Text",
        RagebotStatusColor = Color3.fromRGB(50,255,100),
        RagebotTextColor = Color3.fromRGB(255,255,255),
        Font = "GothamBold",
        Lerp = true,
        OffsetX = 0,
        OffsetY = 0,
        TextStyle = "Shadow",
    },
    -- Target UI / Highlight
    Target = {
        HighlightEnabled = false,
        HighlightFill = Color3.fromRGB(255,80,80),
        HighlightOutline = Color3.fromRGB(255,255,255),
        HighlightType = "Outline",
        HitNotifyEnabled = true,
        HitNotifyDuration = 1,
        HitNotifyText = "HIT",
        TracerEnabled = false,
        UIEnabled = false,
        UIPositionX = 0.5,
        UIPositionY = 0.2,
        UIItemScale = 1,
        UIShowTargets = true,
    },
    -- Target Tracer
    TargetTracer = {
        Enabled = false,
        Customization = "Default",
    },
    -- Arm / Viewmodel Appearance
    Arm = {
        OverrideAppearance = false,
        BodyColor = Color3.fromRGB(255,220,185),
        BodyTransparency = 0,
        Material = "SmoothPlastic",
        DisableTextures = false,
    },
    -- Shoot Sound Changer
    ShootSound = {
        Enabled = false,
        SoundId = "",
        Volume = 0.5,
        Speed = 1,
        StartTick = 0,
        CustomValue = "",
    },
    -- Hit Sounds
    HitSounds = {
        Enabled = false,
        DisableDefault = false,
        Selected = "Classic",
        Volume = 0.5,
    },
    -- Ambience
    Ambience = {
        Enabled = false,
        SoundId = "",
        Volume = 0.3,
    },
    -- Animation Player
    AnimationPlayer = {
        Enabled = false,
        AnimationId = "rbxassetid://",
        Speed = 1,
        StartPosition = 0,
        EndPosition = 1,
        Loop = false,
    },
    -- Item / Vignette
    Item = {
        StatusEnabled = false,
        StatusOverride = false,
        RemoveVignette = false,
    },
    -- Cosmetics
    Cosmetics = {
        SaveData = false,
    },
    -- Lighting Technology
    Lighting = {
        Technology = "Automatic",
    },
    -- ESP extended (animated/fancy)
    ESPExt = {
        BodyColor = Color3.fromRGB(255,255,255),
        BodyTransparency = 0,
        BodyDisables = false,
        BoundsType = "Dynamic",
        BoundsWidthScale = 1,
        BoxMoving = false,
        BoxRotation = false,
        BoxRotationSpeed = 45,
        ChamsFill = 0.5,
        ChamsOutline = 1,
        ChamsColor = Color3.fromRGB(255,100,100),
        DistanceRotation = false,
        FillEnabled = false,
        FillMoving = false,
        FillRotation = false,
        FillRotationSpeed = 30,
        HealthBarType = "Gradient",
        HealthBarSlices = 10,
        HealthBarSpeed = 1,
        HealthBarLerp = true,
        HealthBarResize = true,
        HealthBarMoving = false,
        HealthBarStart = Color3.fromRGB(255,80,80),
        HealthBarMid = Color3.fromRGB(255,200,50),
        HealthBarEnd = Color3.fromRGB(80,255,80),
        MaterialEnabled = false,
        Material = "Neon",
        NameRotation = false,
        NameType = "Billboard",
        OverrideAppearance = false,
        ShowTeam = true,
        SkeletonOutline = false,
        SkeletonThickness = 1,
        WeaponEnabled = false,
        WeaponRotation = false,
        WorldDistance = false,
        WorldDistanceColor = Color3.fromRGB(255,255,255),
        WorldFont = "GothamBold",
        WorldImage = false,
        WorldLerpSpeed = 0.1,
        WorldName = false,
        WorldNameColor = Color3.fromRGB(255,255,255),
        WorldObjectScale = 1,
        WorldWhitelist = {},
    },
}

-- ── UE: Exploits Engine ───────────────────────────────────────────────────────
local ueFRConn
local function startUEExploits()
    if ueFRConn then ueFRConn:Disconnect(); ueFRConn = nil end
    ueFRConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        -- infinite double jump
        if UE.Movement.InfiniteDoubleJump then
            local hum2 = char:FindFirstChildOfClass("Humanoid")
            if hum2 then
                pcall(function()
                    local h = UE.Movement.DoubleJumpHeight * UE.Movement.DoubleJumpHeightMultiplier
                    hum2.JumpPower = h
                    -- reset jump counter attributes so the player can always jump again
                    if hum2:GetAttribute("JumpsLeft") ~= nil then
                        hum2:SetAttribute("JumpsLeft", 1)
                    end
                    if hum2:GetAttribute("DoubleJumpsLeft") ~= nil then
                        hum2:SetAttribute("DoubleJumpsLeft", 1)
                    end
                    local djv = hum2:FindFirstChild("DoubleJumpsLeft")
                    if djv then djv.Value = 1 end
                end)
            end
        end
        -- no spread patch
        if UE.Exploits.NoSpread then
            pcall(function()
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("Tool") then
                        local spread = v:FindFirstChild("SpreadValue") or v:FindFirstChild("Spread")
                        if spread and spread:IsA("NumberValue") then spread.Value = 0 end
                    end
                end
            end)
        end
        -- fire rate
        if UE.Exploits.FireRate then
            pcall(function()
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("Tool") then
                        local fr = v:FindFirstChild("FireRate") or v:FindFirstChild("firerate")
                        if fr and fr:IsA("NumberValue") then fr.Value = UE.Exploits.FireRateValue end
                    end
                end
            end)
        end
        -- full auto
        if UE.Exploits.FullAuto then
            pcall(function()
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("Tool") then
                        local fa = v:FindFirstChild("FullAuto") or v:FindFirstChild("IsFullAuto")
                        if fa and fa:IsA("BoolValue") then fa.Value = true end
                    end
                end
            end)
        end
        -- always backstab
        if UE.Exploits.AlwaysBackstab then
            pcall(function()
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("Tool") then
                        local bs = v:FindFirstChild("Backstab") or v:FindFirstChild("IsBackstab")
                        if bs and bs:IsA("BoolValue") then bs.Value = true end
                    end
                end
            end)
        end
    end)
end
startUEExploits()

-- ── UE: Grenade Exploit Hooks ─────────────────────────────────────────────────
local function hookGrenadeObj(obj)
    if not obj:IsA("BasePart") then return end
    local n = obj.Name:lower()
    if not (n:find("grenade") or n:find("explosive") or n:find("bomb") or n:find("projectile")) then return end
    if obj:FindFirstChild("_UE_GrenHook") then return end
    local tag = Instance.new("BoolValue", obj); tag.Name = "_UE_GrenHook"
    obj.Touched:Connect(function(hit)
        local hitChar = hit and hit.Parent
        local hitHum  = hitChar and hitChar:FindFirstChildOfClass("Humanoid")
        if UE.Exploits.GrenadeExplodeOnImpact and not hitHum then
            pcall(function()
                local exp = Instance.new("Explosion")
                exp.Position = obj.Position
                exp.BlastRadius = 14
                exp.BlastPressure = 500000
                exp.Parent = workspace
            end)
        end
        if UE.Exploits.GrenadeStackDamage and hitHum and hitHum.Health > 0 then
            pcall(function()
                local repS5 = game:GetService("ReplicatedStorage")
                local useItem = repS5.Remotes and repS5.Remotes.Replication and
                    repS5.Remotes.Replication.Fighter and repS5.Remotes.Replication.Fighter.UseItem
                if useItem then
                    useItem:FireServer()
                    useItem:FireServer()
                end
            end)
        end
    end)
end
for _, obj in ipairs(workspace:GetDescendants()) do pcall(hookGrenadeObj, obj) end
workspace.DescendantAdded:Connect(function(obj) pcall(hookGrenadeObj, obj) end)

-- ── UE: Loadout Unrestricted ──────────────────────────────────────────────────
local function applyLoadoutUnrestricted()
    if not UE.Loadout.Unrestricted then return end
    pcall(function()
        local inv = LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("Backpack")
        if not inv then return end
        for _, tool in ipairs(inv:GetChildren()) do
            if tool:IsA("Tool") then
                local slot = tool:FindFirstChild("SlotRestrict") or tool:FindFirstChild("Slot")
                if slot then slot.Value = 0 end
            end
        end
    end)
end

-- ── UE: Auto Queue ────────────────────────────────────────────────────────────
local ueQueueConn
local function startAutoQueue()
    if ueQueueConn then ueQueueConn:Disconnect(); ueQueueConn = nil end
    if not UE.AutoQueue.Enabled then return end
    ueQueueConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local repS2 = game:GetService("ReplicatedStorage")
            local qr = repS2:FindFirstChild("Remotes") and repS2.Remotes:FindFirstChild("Queue")
            if qr then
                if UE.AutoQueue.Mode == "Rejoin" then
                    -- attempt rejoin queue on death
                    local char = LocalPlayer.Character
                    local hum2 = char and char:FindFirstChildOfClass("Humanoid")
                    if hum2 and hum2.Health <= 0 then
                        task.wait(1.5)
                        pcall(function() qr:FireServer("auto") end)
                    end
                end
            end
        end)
    end)
end

-- ── UE: Name Spoofer ──────────────────────────────────────────────────────────
local function applyNameSpoofer()
    if not UE.NameSpoofer.Enabled then return end
    pcall(function()
        local nameTag = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and
            LocalPlayer.Character.Head:FindFirstChildOfClass("BillboardGui")
        if nameTag then
            local lbl = nameTag:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = UE.NameSpoofer.Name end
        end
        -- also try displayname
        LocalPlayer.DisplayName = UE.NameSpoofer.Name
    end)
end

-- ── UE: Chat Spam ─────────────────────────────────────────────────────────────
local ueChatSpamConn
local ueChatMessages = {
    "gg", "ez", "lol", "skill diff", "get good", "nice try", "reported", "ratio",
    "no shot", "you're bad", "stay mad", "cringe", "L + ratio", "skill issue",
    "cope", "seethe", "malding", "uninstall", "go next", "diff",
}
local ueChatIdx = 1
local function startChatSpam()
    if ueChatSpamConn then ueChatSpamConn:Disconnect(); ueChatSpamConn = nil end
    if not UE.ChatSpam.Enabled then return end
    ueChatSpamConn = task.delay(0, function()
        while UE.ChatSpam.Enabled do
            pcall(function()
                local msg
                if UE.ChatSpam.Mode == "Custom" then
                    msg = UE.ChatSpam.Text
                elseif UE.ChatSpam.Mode == "Sequential" then
                    msg = ueChatMessages[ueChatIdx]
                    ueChatIdx = (ueChatIdx % #ueChatMessages) + 1
                else
                    msg = ueChatMessages[math.random(1, #ueChatMessages)]
                end
                local chatService = game:GetService("TextChatService")
                local channel = chatService and chatService:FindFirstChild("TextChannels") and
                    chatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    channel:SendAsync(msg)
                else
                    local cs = game:GetService("Chat")
                    cs:Chat(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"), msg)
                end
            end)
            task.wait(3)
        end
    end)
end

-- ── UE: Shoot Sound Changer ───────────────────────────────────────────────────
local ueOrigShootSounds = {}
local function applyShootSound()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, tool in ipairs(char:GetChildren()) do
            if not tool:IsA("Tool") then continue end
            for _, s in ipairs(tool:GetDescendants()) do
                if s:IsA("Sound") and (s.Name:lower():find("shoot") or s.Name:lower():find("fire") or s.Name:lower():find("shot")) then
                    if not ueOrigShootSounds[s] then ueOrigShootSounds[s] = s.SoundId end
                    if UE.ShootSound.Enabled and UE.ShootSound.SoundId ~= "" then
                        s.SoundId = UE.ShootSound.SoundId
                        s.Volume = UE.ShootSound.Volume
                        s.PlaybackSpeed = UE.ShootSound.Speed
                        s.TimePosition = UE.ShootSound.StartTick
                    else
                        s.SoundId = ueOrigShootSounds[s]
                        s.Volume = 0.5
                        s.PlaybackSpeed = 1
                    end
                end
            end
        end
    end)
end

-- ── UE: Hit Sounds ────────────────────────────────────────────────────────────
local ueHitSoundLib = {
    Classic    = "rbxassetid://9119713991",
    Skeet      = "rbxassetid://362457685",
    Fatality   = "rbxassetid://3200501396",
    Minecraft  = "rbxassetid://131070489",
    Oof        = "rbxassetid://142376088",
    Vine       = "rbxassetid://9116969188",
}
local ueHitSoundInst
local function setupHitSound()
    if ueHitSoundInst then ueHitSoundInst:Destroy(); ueHitSoundInst = nil end
    if not UE.HitSounds.Enabled then return end
    ueHitSoundInst = Instance.new("Sound")
    ueHitSoundInst.SoundId = ueHitSoundLib[UE.HitSounds.Selected] or ueHitSoundLib.Classic
    ueHitSoundInst.Volume = UE.HitSounds.Volume
    ueHitSoundInst.RollOffMaxDistance = 1e9
    pcall(function() ueHitSoundInst.Parent = workspace end)
end

-- ── UE: Ambience ──────────────────────────────────────────────────────────────
local ueAmbienceInst
local function applyAmbience()
    if ueAmbienceInst then ueAmbienceInst:Stop(); ueAmbienceInst:Destroy(); ueAmbienceInst = nil end
    if not UE.Ambience.Enabled or UE.Ambience.SoundId == "" then return end
    ueAmbienceInst = Instance.new("Sound")
    ueAmbienceInst.SoundId = UE.Ambience.SoundId
    ueAmbienceInst.Volume = UE.Ambience.Volume
    ueAmbienceInst.Looped = true
    ueAmbienceInst.RollOffMaxDistance = 1e9
    pcall(function() ueAmbienceInst.Parent = workspace; ueAmbienceInst:Play() end)
end

-- ── UE: Arm Appearance ────────────────────────────────────────────────────────
local function applyArmAppearance()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local targets = {"LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm"}
        for _, name2 in ipairs(targets) do
            local part = char:FindFirstChild(name2)
            if part and part:IsA("BasePart") then
                if UE.Arm.OverrideAppearance then
                    part.Color = UE.Arm.BodyColor
                    part.Transparency = UE.Arm.BodyTransparency
                    pcall(function() part.Material = Enum.Material[UE.Arm.Material] end)
                    if UE.Arm.DisableTextures then
                        for _, d in ipairs(part:GetDescendants()) do
                            if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SpecialMesh") then
                                d.Transparency = 1
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ── UE: Animation Player ──────────────────────────────────────────────────────
local ueAnimTrack
local function playCustomAnimation()
    pcall(function()
        if not UE.AnimationPlayer.Enabled then
            if ueAnimTrack then ueAnimTrack:Stop(); ueAnimTrack = nil end
            return
        end
        local char = LocalPlayer.Character
        local hum2 = char and char:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local animator = hum2:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum2)
        if ueAnimTrack then ueAnimTrack:Stop() end
        local anim = Instance.new("Animation")
        anim.AnimationId = UE.AnimationPlayer.AnimationId
        ueAnimTrack = animator:LoadAnimation(anim)
        ueAnimTrack:Play()
        ueAnimTrack:AdjustSpeed(UE.AnimationPlayer.Speed)
        ueAnimTrack.TimePosition = UE.AnimationPlayer.StartPosition
        if not UE.AnimationPlayer.Loop then
            ueAnimTrack.Looped = false
        else
            ueAnimTrack.Looped = true
        end
    end)
end

-- ── UE: Item Remove Vignette ──────────────────────────────────────────────────
local function applyRemoveVignette()
    if not UE.Item.RemoveVignette then return end
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("Frame") and gui.Name:lower():find("vignette") then
                gui.Visible = false
            end
        end
    end)
end

-- ── UE: Lighting Technology ───────────────────────────────────────────────────
local ueOrigLightTech
local function applyLightingTechnology()
    local Lighting2 = game:GetService("Lighting")
    if not ueOrigLightTech then ueOrigLightTech = Lighting2.Technology end
    pcall(function()
        if UE.Lighting.Technology == "Automatic" then
            Lighting2.Technology = ueOrigLightTech
        else
            Lighting2.Technology = Enum.Technology[UE.Lighting.Technology]
        end
    end)
end

-- ── UE: FOV Ring (Aimbot / Silent) ────────────────────────────────────────────
local ueFovRingAimbot, ueFovRingSilent
local ueFovRotAcc = 0
local function updateFovRings(dt)
    ueFovRotAcc = ueFovRotAcc + dt * 60
    local center = UDim2.new(0.5, 0, 0.5, 0)
    -- Aimbot FOV ring
    if ueFovRingAimbot then
        local vis = UE.Aimbot.ShowFOV and KC and KC.Aimbot and KC.Aimbot.Enabled
        ueFovRingAimbot.Visible = vis or false
        if vis and KC.Aimbot.FOV then
            local r = KC.Aimbot.FOV
            ueFovRingAimbot.Size = UDim2.new(0, r*2, 0, r*2)
            ueFovRingAimbot.Position = UDim2.new(0.5, -r, 0.5, -r)
            if UE.Aimbot.FOVRotation then
                ueFovRingAimbot.Rotation = ueFovRotAcc * UE.Aimbot.FOVRotationSpeed * 0.01
            end
        end
    end
    -- Silent FOV ring
    if ueFovRingSilent then
        local vis2 = UE.Silent.ShowFOV and KC and KC.SilentAim and KC.SilentAim.Enabled
        ueFovRingSilent.Visible = vis2 or false
        if vis2 and KC.SilentAim.FOV then
            local r = KC.SilentAim.FOV
            ueFovRingSilent.Size = UDim2.new(0, r*2, 0, r*2)
            ueFovRingSilent.Position = UDim2.new(0.5, -r, 0.5, -r)
            if UE.Silent.FOVRotation then
                ueFovRingSilent.Rotation = -ueFovRotAcc * UE.Silent.FOVRotationSpeed * 0.01
            end
        end
    end
end
do
    local sg2 = Instance.new("ScreenGui")
    sg2.Name = "UE_FOV_Rings"
    sg2.ResetOnSpawn = false
    sg2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg2.Parent = game:GetService("CoreGui") end)
    if not sg2.Parent then pcall(function() sg2.Parent = LocalPlayer.PlayerGui end) end
    -- aimbot ring
    ueFovRingAimbot = Instance.new("ImageLabel", sg2)
    ueFovRingAimbot.BackgroundTransparency = 1
    ueFovRingAimbot.Image = "rbxassetid://3570695787"
    ueFovRingAimbot.ImageColor3 = Color3.fromRGB(255, 80, 80)
    ueFovRingAimbot.ImageTransparency = 0.4
    ueFovRingAimbot.AnchorPoint = Vector2.new(0.5, 0.5)
    ueFovRingAimbot.Visible = false
    -- silent ring
    ueFovRingSilent = Instance.new("ImageLabel", sg2)
    ueFovRingSilent.BackgroundTransparency = 1
    ueFovRingSilent.Image = "rbxassetid://3570695787"
    ueFovRingSilent.ImageColor3 = Color3.fromRGB(80, 200, 255)
    ueFovRingSilent.ImageTransparency = 0.4
    ueFovRingSilent.AnchorPoint = Vector2.new(0.5, 0.5)
    ueFovRingSilent.Visible = false
    RunService.RenderStepped:Connect(updateFovRings)
end

-- ── UE: Indicator HUD ─────────────────────────────────────────────────────────
do
    local sg3 = Instance.new("ScreenGui")
    sg3.Name = "UE_Indicator"
    sg3.ResetOnSpawn = false
    pcall(function() sg3.Parent = game:GetService("CoreGui") end)
    if not sg3.Parent then pcall(function() sg3.Parent = LocalPlayer.PlayerGui end) end

    local indFrame = Instance.new("Frame", sg3)
    indFrame.Size = UDim2.new(0, 180, 0, 70)
    indFrame.Position = UDim2.new(0.5, -90, 1, -90)
    indFrame.BackgroundColor3 = Color3.fromRGB(10,10,15)
    indFrame.BackgroundTransparency = 0.3
    indFrame.BorderSizePixel = 0
    indFrame.Active = true
    indFrame.Draggable = true
    Instance.new("UICorner", indFrame).CornerRadius = UDim.new(0,5)
    local ist = Instance.new("UIStroke", indFrame)
    ist.Color = Color3.fromRGB(60,120,255)
    ist.Thickness = 1

    local function makeIndLabel(parent, pos, sz, txt, color, fsize)
        local l = Instance.new("TextLabel", parent)
        l.Position = pos; l.Size = sz
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = color or Color3.fromRGB(255,255,255)
        l.TextSize = fsize or 13
        l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end

    local lblAmmo     = makeIndLabel(indFrame, UDim2.new(0,8,0,6),  UDim2.new(1,-16,0,18), "AMMO: --", Color3.fromRGB(200,220,255), 12)
    local lblManip    = makeIndLabel(indFrame, UDim2.new(0,8,0,26), UDim2.new(1,-16,0,18), "",         Color3.fromRGB(255,200,50),  12)
    local lblRagebot  = makeIndLabel(indFrame, UDim2.new(0,8,0,46), UDim2.new(1,-16,0,18), "",         Color3.fromRGB(80,255,120),  12)

    RunService.RenderStepped:Connect(function()
        if not UE.Indicator.AmmoEnabled then lblAmmo.Text = ""; return end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
                local maxAmmo = tool:FindFirstChild("MaxAmmo") or tool:FindFirstChild("MaxAmmoValue")
                if ammo then
                    local reserve = tool:FindFirstChild("Reserve") or tool:FindFirstChild("ReserveAmmo")
                    local aVal = ammo.Value or 0
                    local mVal = maxAmmo and maxAmmo.Value or 0
                    local rVal = reserve and reserve.Value or 0
                    if aVal == 0 then
                        lblAmmo.TextColor3 = UE.Indicator.EmptyColor
                        lblAmmo.Text = "AMMO: EMPTY"
                    elseif aVal >= mVal then
                        lblAmmo.TextColor3 = UE.Indicator.AmmoMaxColor
                        lblAmmo.Text = string.format("AMMO: %d / %d [%d]", aVal, mVal, rVal)
                    else
                        lblAmmo.TextColor3 = UE.Indicator.AmmoColor
                        lblAmmo.Text = string.format("AMMO: %d / %d [%d]", aVal, mVal, rVal)
                    end
                else
                    lblAmmo.Text = "AMMO: --"
                    lblAmmo.TextColor3 = UE.Indicator.AmmoColor
                end
            else
                lblAmmo.Text = "AMMO: --"
                lblAmmo.TextColor3 = UE.Indicator.AmmoColor
            end
        end)
        -- manipulation indicator
        if UE.Indicator.ManipulatedEnabled then
            local anyActive = (CFG and CFG.VOID_ENABLED) or (slingCFG and slingCFG.enabled) or (riotGodmodeCFG and riotGodmodeCFG.enabled)
            lblManip.Text = anyActive and "[MANIPULATED]" or ""
            lblManip.TextColor3 = UE.Indicator.ManipulatedColor
        else
            lblManip.Text = ""
        end
        -- ragebot indicator
        if UE.Indicator.RagebotEnabled then
            local on = CFG and CFG.VOID_ENABLED
            lblRagebot.Text = on and "[RAGEBOT ON]" or "[RAGEBOT OFF]"
            lblRagebot.TextColor3 = on and UE.Indicator.RagebotStatusColor or Color3.fromRGB(120,120,120)
        else
            lblRagebot.Text = ""
        end
    end)
end

-- ── UE: Target Highlight ──────────────────────────────────────────────────────
local ueTargetHighlights = {}
RunService.Heartbeat:Connect(function()
    if not UE.Target.HighlightEnabled then
        for p, hl in pairs(ueTargetHighlights) do
            pcall(function() hl:Destroy() end)
            ueTargetHighlights[p] = nil
        end
        return
    end
    local tgt = getClosest()
    for p, hl in pairs(ueTargetHighlights) do
        if p ~= tgt then
            pcall(function() hl:Destroy() end)
            ueTargetHighlights[p] = nil
        end
    end
    if tgt and tgt.Character then
        if not ueTargetHighlights[tgt] then
            local hl = Instance.new("Highlight")
            hl.FillColor    = UE.Target.HighlightFill
            hl.OutlineColor = UE.Target.HighlightOutline
            hl.FillTransparency    = UE.Target.HighlightType == "FillOnly" and 0.3 or 1
            hl.OutlineTransparency = UE.Target.HighlightType == "Outline"  and 0 or 0.3
            pcall(function() hl.Adornee = tgt.Character; hl.Parent = workspace end)
            ueTargetHighlights[tgt] = hl
        end
    end
end)

-- ── UE: Target Tracer ─────────────────────────────────────────────────────────
local ueTracerLine = Drawing.new("Line")
ueTracerLine.Thickness = 1.5
ueTracerLine.Color = Color3.fromRGB(255, 80, 80)
ueTracerLine.Transparency = 1
ueTracerLine.Visible = false
RunService.RenderStepped:Connect(function()
    if not UE.TargetTracer.Enabled then ueTracerLine.Visible = false; return end
    local tgt = getClosest()
    if not tgt or not tgt.Character then ueTracerLine.Visible = false; return end
    local tHRP = tgt.Character:FindFirstChild("HumanoidRootPart") or tgt.Character:FindFirstChild("Head")
    if not tHRP then ueTracerLine.Visible = false; return end
    local cam = workspace.CurrentCamera
    local tPos, onScreen = cam:WorldToViewportPoint(tHRP.Position)
    if not onScreen or tPos.Z <= 0 then ueTracerLine.Visible = false; return end
    local vp = cam.ViewportSize
    ueTracerLine.From = Vector2.new(vp.X / 2, vp.Y)
    ueTracerLine.To   = Vector2.new(tPos.X, tPos.Y)
    local cust = UE.TargetTracer.Customization
    if cust == "Rainbow" then
        ueTracerLine.Color = Color3.fromHSV(tick() % 1, 1, 1)
    elseif cust == "Team" then
        ueTracerLine.Color = (tgt.TeamColor and tgt.TeamColor.Color) or Color3.fromRGB(255, 80, 80)
    else
        ueTracerLine.Color = Color3.fromRGB(255, 80, 80)
    end
    ueTracerLine.Visible = true
end)

-- ── UE: Target Info Panel ─────────────────────────────────────────────────────
do
    local ueTgtGui = Instance.new("ScreenGui")
    ueTgtGui.Name = "UE_TargetInfo"
    ueTgtGui.ResetOnSpawn = false
    pcall(function() ueTgtGui.Parent = game:GetService("CoreGui") end)
    if not ueTgtGui.Parent then pcall(function() ueTgtGui.Parent = LocalPlayer.PlayerGui end) end
    local ueTgtFrame = Instance.new("Frame", ueTgtGui)
    ueTgtFrame.Size = UDim2.new(0, 160, 0, 62)
    ueTgtFrame.AnchorPoint = Vector2.new(0.5, 0)
    ueTgtFrame.Position = UDim2.new(0.5, 0, 0.2, 0)
    ueTgtFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    ueTgtFrame.BackgroundTransparency = 0.35
    ueTgtFrame.BorderSizePixel = 0
    ueTgtFrame.Visible = false
    ueTgtFrame.Active = true
    ueTgtFrame.Draggable = true
    Instance.new("UICorner", ueTgtFrame).CornerRadius = UDim.new(0, 5)
    local tgtStroke = Instance.new("UIStroke", ueTgtFrame)
    tgtStroke.Color = Color3.fromRGB(255, 60, 60); tgtStroke.Thickness = 1
    local function mkTL(parent, py, sz, fsize, color)
        local l = Instance.new("TextLabel", parent)
        l.Position = UDim2.new(0, 6, 0, py); l.Size = UDim2.new(1, -12, 0, sz)
        l.BackgroundTransparency = 1; l.Text = ""
        l.TextColor3 = color or Color3.fromRGB(255,255,255)
        l.TextSize = fsize or 12; l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end
    local tgtName = mkTL(ueTgtFrame,  4, 16, 12, Color3.fromRGB(255, 200, 100))
    local tgtHP   = mkTL(ueTgtFrame, 23, 16, 12, Color3.fromRGB(80,  255, 100))
    local tgtDst  = mkTL(ueTgtFrame, 42, 14, 11, Color3.fromRGB(180, 180, 255))
    RunService.RenderStepped:Connect(function()
        local en = UE.Target.UIEnabled and UE.Target.UIShowTargets
        ueTgtFrame.Visible = en
        if not en then return end
        local tgt = getClosest()
        if not tgt then tgtName.Text = "No Target"; tgtHP.Text = ""; tgtDst.Text = ""; return end
        tgtName.Text = tgt.Name or "???"
        local tHum = tgt.Character and tgt.Character:FindFirstChildOfClass("Humanoid")
        tgtHP.Text = tHum and string.format("HP: %d / %d", math.floor(tHum.Health), math.floor(tHum.MaxHealth)) or "HP: ??"
        local tHRP = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
        tgtDst.Text = (tHRP and root) and string.format("DIST: %d", math.floor((tHRP.Position - root.Position).Magnitude)) or ""
    end)
end

-- ── UE: Hit Notify ────────────────────────────────────────────────────────────
do
    local hitNotifyGui = Instance.new("ScreenGui")
    hitNotifyGui.Name = "UE_HitNotify"
    hitNotifyGui.ResetOnSpawn = false
    pcall(function() hitNotifyGui.Parent = game:GetService("CoreGui") end)
    if not hitNotifyGui.Parent then pcall(function() hitNotifyGui.Parent = LocalPlayer.PlayerGui end) end

    local hitLbl = Instance.new("TextLabel", hitNotifyGui)
    hitLbl.Size = UDim2.new(0, 120, 0, 30)
    hitLbl.Position = UDim2.new(0.5, -60, 0.4, 0)
    hitLbl.BackgroundTransparency = 1
    hitLbl.Text = ""
    hitLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
    hitLbl.TextSize = 20
    hitLbl.Font = Enum.Font.GothamBold
    hitLbl.TextStrokeTransparency = 0.5
    hitLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local hitNotifyTimer = 0
    RunService.RenderStepped:Connect(function(dt)
        if hitNotifyTimer > 0 then
            hitNotifyTimer = hitNotifyTimer - dt
            hitLbl.TextTransparency = math.clamp(1 - (hitNotifyTimer / UE.Target.HitNotifyDuration) * 2, 0, 1)
            if hitNotifyTimer <= 0 then hitLbl.Text = "" end
        end
    end)

    -- Hook: show on damage dealt (listen to DamagePart events)
    local function hookHitNotify()
        pcall(function()
            local repS3 = game:GetService("ReplicatedStorage")
            local dmgRem = repS3:FindFirstChild("Remotes") and repS3.Remotes:FindFirstChild("DamageDealt")
            if dmgRem then
                dmgRem.OnClientEvent:Connect(function(amount)
                    if UE.Target.HitNotifyEnabled then
                        hitLbl.Text = UE.Target.HitNotifyText .. " -" .. tostring(math.floor(amount or 0))
                        hitLbl.TextTransparency = 0
                        hitNotifyTimer = UE.Target.HitNotifyDuration
                    end
                end)
            end
        end)
    end
    hookHitNotify()
end

-- ── UE: Auto Weapon Select ────────────────────────────────────────────────────
local ueAutoSelConn
local function startAutoWeaponSelect()
    if ueAutoSelConn then ueAutoSelConn:Disconnect(); ueAutoSelConn = nil end
    if not UE.Loadout.AutoSelectEnabled then return end
    ueAutoSelConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not FighterController then return end
            local lf = FighterController.LocalFighter
            if not lf then return end
            local slots = { Primary = 1, Secondary = 2, Melee = 3, Utility = 4 }
            for slotName, idx in pairs(slots) do
                if UE.Loadout["AutoSelect" .. slotName] then
                    lf:EquipItem(idx)
                    break
                end
            end
        end)
    end)
end

-- ── Apply UE systems on char added ───────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applyArmAppearance()
    applyRemoveVignette()
    applyShootSound()
    applyLoadoutUnrestricted()
    setupHitSound()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- UE UI tabs (added to existing WT tabs)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── UE UI: Combat / Exploits ──────────────────────────────────────────────────
do
    local gbEx = WT.Void:AddRightGroupbox("UE Exploits")
    gbEx:AddToggle("UEFireRate", { Text = "Fast Fire Rate", Default = false,
        Callback = function(v) UE.Exploits.FireRate = v end })
    gbEx:AddSlider("UEFireRateVal", { Text = "Fire Rate Interval", Default = 1, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) UE.Exploits.FireRateValue = v * 0.001 end })
    gbEx:AddToggle("UEFullAuto", { Text = "Full Auto", Default = false,
        Callback = function(v) UE.Exploits.FullAuto = v end })
    gbEx:AddToggle("UENoSpread", { Text = "No Spread", Default = false,
        Callback = function(v) UE.Exploits.NoSpread = v end })
    gbEx:AddToggle("UEAlwaysBackstab", { Text = "Always Backstab", Default = false,
        Callback = function(v) UE.Exploits.AlwaysBackstab = v end })
    gbEx:AddToggle("UEGrenadeExplode", { Text = "Grenade Explode On Impact", Default = false,
        Callback = function(v) UE.Exploits.GrenadeExplodeOnImpact = v end })
    gbEx:AddToggle("UEGrenadeStack", { Text = "Stack Grenade Damage", Default = false,
        Callback = function(v) UE.Exploits.GrenadeStackDamage = v end })
end

-- ── UE UI: Misc / Loadout + AutoQueue ────────────────────────────────────────
do
    local gbLo = WT.Range:AddRightGroupbox("UE Loadout")
    gbLo:AddToggle("UELoadoutUnrestrict", { Text = "Unrestricted Loadout", Default = false,
        Callback = function(v) UE.Loadout.Unrestricted = v; applyLoadoutUnrestricted() end })
    gbLo:AddToggle("UEAutoSelect", { Text = "Auto Weapon Select", Default = false,
        Callback = function(v) UE.Loadout.AutoSelectEnabled = v; startAutoWeaponSelect() end })
    gbLo:AddToggle("UEAutoSelectMelee", { Text = "  Melee", Default = true,
        Callback = function(v) UE.Loadout.AutoSelectMelee = v end })
    gbLo:AddToggle("UEAutoSelectPrimary", { Text = "  Primary", Default = true,
        Callback = function(v) UE.Loadout.AutoSelectPrimary = v end })
    gbLo:AddToggle("UEAutoSelectSecondary", { Text = "  Secondary", Default = true,
        Callback = function(v) UE.Loadout.AutoSelectSecondary = v end })
    gbLo:AddDivider()
    gbLo:AddToggle("UEAutoQueue", { Text = "Auto Re-Queue", Default = false,
        Callback = function(v) UE.AutoQueue.Enabled = v; startAutoQueue() end })
    gbLo:AddDropdown("UEAutoQueueMode", { Text = "Queue Mode", Default = 1,
        Values = {"Rejoin","Next"},
        Callback = function(v) UE.AutoQueue.Mode = v end })
end

-- ── UE UI: Setting / Misc ─────────────────────────────────────────────────────
do
    local gbUESetting = WT.Config:AddLeftGroupbox and WT.Config:AddLeftGroupbox("UE Settings") or nil
    if not gbUESetting then gbUESetting = Window:AddTab("UE"):AddTabbox({Side=1}):AddTab("UE Misc"):AddLeftGroupbox("UE Settings") end
    gbUESetting:AddToggle("UENameSpoofer", { Text = "Name Spoofer", Default = false,
        Callback = function(v)
            UE.NameSpoofer.Enabled = v
            if v then applyNameSpoofer() end
        end })
    gbUESetting:AddInput("UENameSpooferName", { Text = "Spoof Name", Default = "Player",
        Callback = function(v) UE.NameSpoofer.Name = v end })
    gbUESetting:AddToggle("UEChatSpam", { Text = "Chat Spam", Default = false,
        Callback = function(v) UE.ChatSpam.Enabled = v; startChatSpam() end })
    gbUESetting:AddDropdown("UEChatSpamMode", { Text = "Spam Mode", Default = 1,
        Values = {"Random","Sequential","Custom"},
        Callback = function(v) UE.ChatSpam.Mode = v end })
    gbUESetting:AddInput("UEChatSpamText", { Text = "Custom Spam Text", Default = "gg",
        Callback = function(v) UE.ChatSpam.Text = v end })
    gbUESetting:AddDivider()
    gbUESetting:AddToggle("UERemoveVignette", { Text = "Remove Vignette", Default = false,
        Callback = function(v) UE.Item.RemoveVignette = v; applyRemoveVignette() end })
    gbUESetting:AddDropdown("UELightingTech", { Text = "Lighting Technology", Default = 1,
        Values = {"Automatic","Compatibility","Voxel","ShadowMap","Future"},
        Callback = function(v) UE.Lighting.Technology = v; applyLightingTechnology() end })
end

-- ── UE UI: Visual / Target Highlight + Hit Notify ────────────────────────────
do
    local gbTgt = WT.FX:AddRightGroupbox("UE Target")
    gbTgt:AddToggle("UETargetHighlight", { Text = "Target Highlight", Default = false,
        Callback = function(v) UE.Target.HighlightEnabled = v end })
    gbTgt:AddDropdown("UETargetHighlightType", { Text = "Highlight Type", Default = 1,
        Values = {"Outline","FillOnly","Both"},
        Callback = function(v) UE.Target.HighlightType = v end })
    gbTgt:AddColorpicker("UETargetHighlightFill", { Text = "Fill Color", Default = UE.Target.HighlightFill,
        Callback = function(v) UE.Target.HighlightFill = v end })
    gbTgt:AddColorpicker("UETargetHighlightOutline", { Text = "Outline Color", Default = UE.Target.HighlightOutline,
        Callback = function(v) UE.Target.HighlightOutline = v end })
    gbTgt:AddDivider()
    gbTgt:AddToggle("UEHitNotify", { Text = "Hit Notify", Default = true,
        Callback = function(v) UE.Target.HitNotifyEnabled = v end })
    gbTgt:AddInput("UEHitNotifyText", { Text = "Notify Text", Default = "HIT",
        Callback = function(v) UE.Target.HitNotifyText = v end })
    gbTgt:AddSlider("UEHitNotifyDur", { Text = "Notify Duration", Default = 100, Min = 10, Max = 500, Rounding = 0,
        Callback = function(v) UE.Target.HitNotifyDuration = v * 0.01 end })
end

-- ── UE UI: Visual / Arm Appearance ───────────────────────────────────────────
do
    local gbArm = WT.FX:AddLeftGroupbox("UE Arm Appearance")
    gbArm:AddToggle("UEArmOverride", { Text = "Override Arm Appearance", Default = false,
        Callback = function(v) UE.Arm.OverrideAppearance = v; applyArmAppearance() end })
    gbArm:AddColorpicker("UEArmColor", { Text = "Arm Color", Default = UE.Arm.BodyColor,
        Callback = function(v) UE.Arm.BodyColor = v; applyArmAppearance() end })
    gbArm:AddSlider("UEArmTransparency", { Text = "Arm Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) UE.Arm.BodyTransparency = v * 0.01; applyArmAppearance() end })
    gbArm:AddDropdown("UEArmMaterial", { Text = "Arm Material", Default = 1,
        Values = {"SmoothPlastic","Neon","Glass","Metal","Wood","Granite","Brick","Slate"},
        Callback = function(v) UE.Arm.Material = v; applyArmAppearance() end })
    gbArm:AddToggle("UEArmDisableTextures", { Text = "Disable Textures", Default = false,
        Callback = function(v) UE.Arm.DisableTextures = v; applyArmAppearance() end })
end

-- ── UE UI: Visual / Sounds ────────────────────────────────────────────────────
do
    local gbSnd = WT.FX:AddRightGroupbox("UE Sounds")
    -- Hit Sounds
    gbSnd:AddToggle("UEHitSounds", { Text = "Custom Hit Sounds", Default = false,
        Callback = function(v) UE.HitSounds.Enabled = v; setupHitSound() end })
    gbSnd:AddToggle("UEHitSoundsDisable", { Text = "Disable Default Hit Sound", Default = false,
        Callback = function(v) UE.HitSounds.DisableDefault = v end })
    gbSnd:AddDropdown("UEHitSoundsSelected", { Text = "Hit Sound", Default = 1,
        Values = {"Classic","Skeet","Fatality","Minecraft","Oof","Vine"},
        Callback = function(v) UE.HitSounds.Selected = v; setupHitSound() end })
    gbSnd:AddSlider("UEHitSoundsVol", { Text = "Hit Sound Volume", Default = 50, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) UE.HitSounds.Volume = v * 0.01; if ueHitSoundInst then ueHitSoundInst.Volume = UE.HitSounds.Volume end end })
    gbSnd:AddDivider()
    -- Shoot Sound
    gbSnd:AddToggle("UEShootSound", { Text = "Custom Shoot Sound", Default = false,
        Callback = function(v) UE.ShootSound.Enabled = v; applyShootSound() end })
    gbSnd:AddInput("UEShootSoundId", { Text = "Shoot Sound ID", Default = "",
        Callback = function(v) UE.ShootSound.SoundId = v; applyShootSound() end })
    gbSnd:AddSlider("UEShootSoundVol", { Text = "Shoot Volume", Default = 50, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) UE.ShootSound.Volume = v * 0.01 end })
    gbSnd:AddSlider("UEShootSoundSpeed", { Text = "Shoot Speed", Default = 100, Min = 10, Max = 300, Rounding = 0,
        Callback = function(v) UE.ShootSound.Speed = v * 0.01 end })
    gbSnd:AddDivider()
    -- Ambience
    gbSnd:AddToggle("UEAmbience", { Text = "Custom Ambience", Default = false,
        Callback = function(v) UE.Ambience.Enabled = v; applyAmbience() end })
    gbSnd:AddInput("UEAmbienceId", { Text = "Ambience Sound ID", Default = "",
        Callback = function(v) UE.Ambience.SoundId = v end })
    gbSnd:AddSlider("UEAmbienceVol", { Text = "Ambience Volume", Default = 30, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) UE.Ambience.Volume = v * 0.01 end })
    gbSnd:AddButton({ Text = "Apply Ambience", Func = function() applyAmbience() end })
end

-- ── UE UI: Visual / Indicator HUD ─────────────────────────────────────────────
do
    local gbInd = WT.FX:AddLeftGroupbox("UE Indicator")
    gbInd:AddToggle("UEIndAmmo", { Text = "Ammo Indicator", Default = true,
        Callback = function(v) UE.Indicator.AmmoEnabled = v end })
    gbInd:AddDropdown("UEIndAmmoStyle", { Text = "Ammo Style", Default = 1,
        Values = {"Classic","Bars","Minimal"},
        Callback = function(v) UE.Indicator.AmmoStyle = v end })
    gbInd:AddColorpicker("UEIndAmmoColor", { Text = "Ammo Color", Default = UE.Indicator.AmmoColor,
        Callback = function(v) UE.Indicator.AmmoColor = v end })
    gbInd:AddColorpicker("UEIndEmptyColor", { Text = "Empty Color", Default = UE.Indicator.EmptyColor,
        Callback = function(v) UE.Indicator.EmptyColor = v end })
    gbInd:AddToggle("UEIndManip", { Text = "Manipulation Indicator", Default = true,
        Callback = function(v) UE.Indicator.ManipulatedEnabled = v end })
    gbInd:AddColorpicker("UEIndManipColor", { Text = "Manipulation Color", Default = UE.Indicator.ManipulatedColor,
        Callback = function(v) UE.Indicator.ManipulatedColor = v end })
    gbInd:AddToggle("UEIndRagebot", { Text = "Ragebot Indicator", Default = true,
        Callback = function(v) UE.Indicator.RagebotEnabled = v end })
    gbInd:AddColorpicker("UEIndRagebotColor", { Text = "Ragebot Active Color", Default = UE.Indicator.RagebotStatusColor,
        Callback = function(v) UE.Indicator.RagebotStatusColor = v end })
    gbInd:AddSlider("UEIndOffsetX", { Text = "Indicator X Offset", Default = 0, Min = -500, Max = 500, Rounding = 0,
        Callback = function(v) UE.Indicator.OffsetX = v end })
    gbInd:AddSlider("UEIndOffsetY", { Text = "Indicator Y Offset", Default = 0, Min = -500, Max = 500, Rounding = 0,
        Callback = function(v) UE.Indicator.OffsetY = v end })
end

-- ── UE UI: Aimbot FOV Ring ────────────────────────────────────────────────────
do
    pcall(function()
        local gbFOV = WT.Aim:AddRightGroupbox("UE FOV Ring")
        gbFOV:AddToggle("UEAimbotShowFOV", { Text = "Show Aimbot FOV Ring", Default = true,
            Callback = function(v) UE.Aimbot.ShowFOV = v end })
        gbFOV:AddToggle("UEAimbotFOVRotate", { Text = "Rotate FOV Ring", Default = false,
            Callback = function(v) UE.Aimbot.FOVRotation = v end })
        gbFOV:AddSlider("UEAimbotFOVRotSpeed", { Text = "FOV Rotation Speed", Default = 45, Min = 1, Max = 360, Rounding = 0,
            Callback = function(v) UE.Aimbot.FOVRotationSpeed = v end })
        gbFOV:AddToggle("UESilentShowFOV", { Text = "Show Silent FOV Ring", Default = true,
            Callback = function(v) UE.Silent.ShowFOV = v end })
        gbFOV:AddToggle("UESilentFOVRotate", { Text = "Rotate Silent FOV Ring", Default = false,
            Callback = function(v) UE.Silent.FOVRotation = v end })
        gbFOV:AddSlider("UESilentHitChance", { Text = "Silent Hit Chance %", Default = 100, Min = 1, Max = 100, Rounding = 0,
            Callback = function(v)
                UE.Silent.HitChance = v
                if KC and KC.SilentAim then KC.SilentAim.HitChance = v end
            end })
        gbFOV:AddToggle("UEAimbotClosestPart", { Text = "Aimbot Closest Part", Default = true,
            Callback = function(v) UE.Aimbot.ClosestPart = v end })
        gbFOV:AddToggle("UESilentClosestPart", { Text = "Silent Closest Part", Default = true,
            Callback = function(v) UE.Silent.ClosestPart = v end })
    end)
end

-- ── UE UI: Movement Extended ──────────────────────────────────────────────────
do
    pcall(function()
        local gbMv = WT.Move:AddRightGroupbox("UE Movement")
        gbMv:AddToggle("UEInfiniteDoubleJump", { Text = "Infinite Double Jump", Default = false,
            Callback = function(v) UE.Movement.InfiniteDoubleJump = v end })
        gbMv:AddSlider("UEDoubleJumpHeight", { Text = "Double Jump Height", Default = 50, Min = 10, Max = 500, Rounding = 0,
            Callback = function(v) UE.Movement.DoubleJumpHeight = v end })
        gbMv:AddSlider("UEDoubleJumpMult", { Text = "Double Jump Multiplier", Default = 200, Min = 100, Max = 1000, Rounding = 0,
            Callback = function(v) UE.Movement.DoubleJumpHeightMultiplier = v * 0.01 end })
    end)
end

-- ── UE UI: Misc / Animation Player ───────────────────────────────────────────
do
    pcall(function()
        local gbAnim = WT.Config:AddLeftGroupbox("UE Animation Player")
        gbAnim:AddToggle("UEAnimPlayer", { Text = "Custom Animation", Default = false,
            Callback = function(v) UE.AnimationPlayer.Enabled = v; playCustomAnimation() end })
        gbAnim:AddInput("UEAnimID", { Text = "Animation ID", Default = "rbxassetid://",
            Callback = function(v) UE.AnimationPlayer.AnimationId = v end })
        gbAnim:AddSlider("UEAnimSpeed", { Text = "Speed", Default = 100, Min = 10, Max = 500, Rounding = 0,
            Callback = function(v) UE.AnimationPlayer.Speed = v * 0.01 end })
        gbAnim:AddToggle("UEAnimLoop", { Text = "Loop", Default = false,
            Callback = function(v) UE.AnimationPlayer.Loop = v end })
        gbAnim:AddButton({ Text = "Play Animation", Func = function() playCustomAnimation() end })
        gbAnim:AddButton({ Text = "Stop Animation", Func = function()
            UE.AnimationPlayer.Enabled = false
            if ueAnimTrack then ueAnimTrack:Stop(); ueAnimTrack = nil end
        end })
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Kicia Feature Block — all features extracted from Kicia deobfuscated source
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Kicia Config ──────────────────────────────────────────────────────────────
local KC = {
    -- VoidSpam extended
    VoidSpam = {
        VoidDistance    = 1000000,
        VoidDistPercent = 5,
        HeightOffset    = 0,
        Mode            = "None",   -- None/Spin/Float/Jitter/Desync/Orbit/OrbitAround
        SpinSpeed       = 10,
        FloatSpeed      = 2,
        FloatIntensity  = 5,
        JitterIntensity = 5,
        DesyncSpeed     = 50,
    },
    -- Anti-Aim (Kicia version)
    AntiAim = {
        Enabled    = false,
        Mode       = "None",   -- None/Spin/Jitter/Desync/Static/Random
        Pitch      = "None",   -- None/Down/Up/Random
        Speed      = 15,
        JitterRange= 45,
    },
    -- Orbit Around Enemy
    OrbitAround = {
        Enabled    = false,
        Distance   = 10,
        HeightOff  = 0,
        UpdateRate = 0.5,
        AroundEnemy= false,
        Radius     = 10,
        Speed      = 2,
    },
    -- Hitsound
    Hitsound = {
        SoundId    = "rbxassetid://719384308",
        Id         = 719384308,
    },
    -- RageBot (Kicia version)
    RageBot = {
        Enabled         = false,
        FOVEnabled      = false,
        FOVRadius       = 80,
        OnScreen        = false,
        ShotgunMeta     = false,
        SlingshotBypass = false,
        AutoScope       = false,
        RemoveScope     = false,
    },
    -- Hit Effect
    HitEffect = {
        Enabled     = false,
        Type        = "Neon",  -- Neon/SmoothPlastic/Glass
        FadeInTime  = 0.1,
        FadeOutTime = 0.3,
        Color       = Color3.fromRGB(85, 255, 255),
    },
    -- Lighting
    Lighting = {
        Enabled        = false,
        Brightness     = 2,
        AmbientColor   = Color3.fromRGB(128, 128, 128),
        OutdoorAmbient = Color3.fromRGB(128, 128, 128),
        ClockTime      = 14,
        FogEnd         = 1000,
        FogColor       = Color3.fromRGB(192, 192, 192),
    },
    -- ESP extended (Kicia style)
    ESP = {
        Enabled              = false,
        IgnoreTeammates      = false,
        ShowBox              = false,
        ShowName             = false,
        ShowDistance         = false,
        ShowHealthBar        = false,
        ShowSkeleton         = false,
        ShowTracers          = false,
        MaxDistance          = 1000,
        BoxColor             = Color3.fromRGB(255, 0, 0),
        TeamColor            = Color3.fromRGB(0, 255, 0),
        BoxThickness         = 1.5,
        BoxFilled            = false,
        BoxFillTransparency  = 0.85,
        NameColor            = Color3.fromRGB(255, 255, 255),
        NameSize             = 14,
        NameOutline          = false,
        DistColor            = Color3.fromRGB(255, 255, 255),
        DistSize             = 12,
        DistOutline          = false,
        TracerThickness      = 1,
        TracerOrigin         = "Bottom",
        SkeletonThickness    = 1,
        HealthBarWidth       = 4,
    },
    -- Chams (Kicia version)
    Chams = {
        Enabled             = false,
        FillColor           = Color3.fromRGB(255, 0, 255),
        FillTransparency    = 0.5,
        OutlineColor        = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
    },
    -- Movement
    Move = {
        FreecamEnabled  = false,
        FreecamSpeed    = 30,
        FreecamCharDist = 4,
        FlyEnabled      = false,
        FlySpeed        = 50,
        VelocityEnabled = false,
        VelocitySpeed   = 50,
        NoClipEnabled   = false,
        BHopEnabled     = false,
    },
    -- HUD overlays
    HUD = {
        ShowActiveHUD   = false,
        ShowKeybindList = false,
    },
    -- Config
    AutoLoadConfig  = true,
    LastConfig      = "default",
}

-- ── Kicia: RageBot / ShotgunMeta ──────────────────────────────────────────────
local kcRBFOVCircle
do
    local sg4 = Instance.new("ScreenGui")
    sg4.Name = "KC_RB_FOV"
    sg4.ResetOnSpawn = false
    pcall(function() sg4.Parent = game:GetService("CoreGui") end)
    if not sg4.Parent then pcall(function() sg4.Parent = LocalPlayer.PlayerGui end) end
    kcRBFOVCircle = Instance.new("ImageLabel", sg4)
    kcRBFOVCircle.BackgroundTransparency = 1
    kcRBFOVCircle.Image = "rbxassetid://3570695787"
    kcRBFOVCircle.ImageColor3 = Color3.fromRGB(255, 255, 100)
    kcRBFOVCircle.ImageTransparency = 0.5
    kcRBFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    kcRBFOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    kcRBFOVCircle.Visible = false
end

local kcRBConn
local function startKiciaRageBot()
    if kcRBConn then kcRBConn:Disconnect(); kcRBConn = nil end
    kcRBConn = RunService.Heartbeat:Connect(function()
        local rb = KC.RageBot
        -- FOV circle
        if kcRBFOVCircle then
            kcRBFOVCircle.Visible = rb.Enabled and rb.FOVEnabled
            if rb.FOVEnabled then
                local r = rb.FOVRadius
                kcRBFOVCircle.Size = UDim2.new(0, r*2, 0, r*2)
            end
        end
        if not rb.Enabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Remove scope overlay
        if rb.RemoveScope then
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    for _, gui in ipairs(pg:GetDescendants()) do
                        if gui.Name:lower():find("scope") or gui.Name:lower():find("zoom") then
                            if gui:IsA("ScreenGui") or gui:IsA("Frame") then
                                gui.Enabled = false
                            end
                        end
                    end
                end
            end)
        end
        -- ShotgunMeta: pick closest body part for shotgun spread compensation
        if rb.ShotgunMeta then
            pcall(function()
                local tgt = getClosest()
                if not tgt or not tgt.Character then return end
                local bestPart, bestDist = nil, math.huge
                local partNames = {"Head","UpperTorso","LowerTorso","HumanoidRootPart"}
                for _, pn in ipairs(partNames) do
                    local p = tgt.Character:FindFirstChild(pn)
                    if p then
                        local cam = workspace.CurrentCamera
                        local v2, onScreen = cam:WorldToViewportPoint(p.Position)
                        if onScreen then
                            local screenCenter = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                            local d = Vector2.new(v2.X, v2.Y) - screenCenter
                            if d.Magnitude < bestDist then
                                bestDist = d.Magnitude
                                bestPart = p
                            end
                        end
                    end
                end
                if bestPart and bestDist <= rb.FOVRadius then
                    -- store best part for aimbot use
                    getgenv()._KC_ShotgunTarget = bestPart
                end
            end)
        end
        -- SlingshotBypass (Kicia version): override sling aim
        if rb.SlingshotBypass then
            pcall(function()
                local tgt = getClosest()
                if not tgt or not tgt.Character then return end
                local tHRP = tgt.Character:FindFirstChild("HumanoidRootPart")
                if not tHRP then return end
                local repS4 = game:GetService("ReplicatedStorage")
                local slingRem = repS4:FindFirstChild("Remotes") and repS4.Remotes:FindFirstChild("Replication") and
                    repS4.Remotes.Replication:FindFirstChild("Fighter") and repS4.Remotes.Replication.Fighter:FindFirstChild("UseItem")
                if slingRem then
                    pcall(function()
                        local fakeCF = CFrame.new(tHRP.Position)
                        slingRem:FireServer()
                    end)
                end
            end)
        end
        -- AutoScope
        if rb.AutoScope then
            pcall(function()
                local tgt = getClosest()
                if tgt and FighterController and FighterController.LocalFighter then
                    FighterController.LocalFighter:EquipItem(2) -- equip scope/secondary
                end
            end)
        end
    end)
end
startKiciaRageBot()

-- ── Kicia: AntiAim ────────────────────────────────────────────────────────────
local kcAAAngAcc = 0
local kcAAJitterT = 0
local kcAAConn
local function startKiciaAntiAim()
    if kcAAConn then kcAAConn:Disconnect(); kcAAConn = nil end
    if not KC.AntiAim.Enabled then return end
    kcAAConn = RunService.Heartbeat:Connect(function(dt)
        local aa = KC.AntiAim
        if not aa.Enabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function()
            local yaw, pitch = 0, 0
            local mode = aa.Mode
            if mode == "Spin" then
                kcAAAngAcc = kcAAAngAcc + dt * aa.Speed * 60
                yaw = kcAAAngAcc
            elseif mode == "Jitter" then
                kcAAJitterT = kcAAJitterT + dt * aa.Speed
                yaw = math.sin(kcAAJitterT * math.pi * 2) * aa.JitterRange
            elseif mode == "Desync" then
                kcAAAngAcc = kcAAAngAcc + dt * aa.Speed * 30
                yaw = kcAAAngAcc % 360 > 180 and aa.JitterRange or -aa.JitterRange
            elseif mode == "Static" then
                yaw = 180
            elseif mode == "Random" then
                kcAAJitterT = kcAAJitterT + dt * 10
                if math.floor(kcAAJitterT) % 2 == 0 then
                    yaw = math.random(-180, 180)
                end
            end
            local ap = aa.Pitch
            if ap == "Down"   then pitch = 89  end
            if ap == "Up"     then pitch = -89 end
            if ap == "Random" then pitch = math.random(-89, 89) end
            local cur = hrp.CFrame
            hrp.CFrame = CFrame.new(cur.Position) * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
        end)
    end)
end

-- ── Kicia: Orbit Around Enemy ─────────────────────────────────────────────────
local kcOrbitAng = 0
local kcOrbitConn
local function startKiciaOrbit()
    if kcOrbitConn then kcOrbitConn:Disconnect(); kcOrbitConn = nil end
    if not KC.OrbitAround.Enabled then return end
    kcOrbitConn = RunService.Heartbeat:Connect(function(dt)
        local oa = KC.OrbitAround
        if not oa.Enabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local tgt
        if oa.AroundEnemy then
            tgt = getClosest()
            if not tgt then return end
            tgt = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
        end
        local center = tgt and tgt.Position or hrp.Position
        kcOrbitAng = kcOrbitAng + dt * math.rad(oa.Speed * 60)
        local x = center.X + math.cos(kcOrbitAng) * oa.Radius
        local z = center.Z + math.sin(kcOrbitAng) * oa.Radius
        local y = center.Y + oa.HeightOff
        pcall(function()
            hrp.CFrame = CFrame.new(x, y, z) * CFrame.new(hrp.CFrame - hrp.CFrame.Position)
        end)
    end)
end

-- ── Kicia: Hit Effect ─────────────────────────────────────────────────────────
local kcHitFXPool = {}
local function spawnKiciaHitFX(pos)
    if not KC.HitEffect.Enabled then return end
    pcall(function()
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Anchored = true
        part.CanCollide = false
        part.CastShadow = false
        part.Position = pos or Vector3.new(0,0,0)
        pcall(function() part.Material = Enum.Material[KC.HitEffect.Type] end)
        part.Color = KC.HitEffect.Color
        part.Parent = workspace
        local fi, fo = KC.HitEffect.FadeInTime, KC.HitEffect.FadeOutTime
        task.spawn(function()
            local t0 = os.clock()
            while os.clock() - t0 < fi do
                part.Transparency = 1 - (os.clock()-t0)/fi
                task.wait()
            end
            part.Transparency = 0
            task.wait(0.05)
            local t1b = os.clock()
            while os.clock() - t1b < fo do
                part.Transparency = (os.clock()-t1b)/fo
                task.wait()
            end
            part:Destroy()
        end)
    end)
end

-- ── Kicia: Lighting Control ───────────────────────────────────────────────────
local kcOrigLight = {}
local function applyKiciaLighting()
    local Lit = game:GetService("Lighting")
    if KC.Lighting.Enabled then
        if not kcOrigLight.saved then
            kcOrigLight.Brightness     = Lit.Brightness
            kcOrigLight.AmbientColor   = Lit.Ambient
            kcOrigLight.OutdoorAmbient = Lit.OutdoorAmbient
            kcOrigLight.ClockTime      = Lit.ClockTime
            kcOrigLight.FogEnd         = Lit.FogEnd
            kcOrigLight.FogColor       = Lit.FogColor
            kcOrigLight.saved = true
        end
        pcall(function()
            Lit.Brightness     = KC.Lighting.Brightness
            Lit.Ambient        = KC.Lighting.AmbientColor
            Lit.OutdoorAmbient = KC.Lighting.OutdoorAmbient
            Lit.ClockTime      = KC.Lighting.ClockTime
            Lit.FogEnd         = KC.Lighting.FogEnd
            Lit.FogColor       = KC.Lighting.FogColor
        end)
    else
        if kcOrigLight.saved then
            pcall(function()
                Lit.Brightness     = kcOrigLight.Brightness
                Lit.Ambient        = kcOrigLight.AmbientColor
                Lit.OutdoorAmbient = kcOrigLight.OutdoorAmbient
                Lit.ClockTime      = kcOrigLight.ClockTime
                Lit.FogEnd         = kcOrigLight.FogEnd
                Lit.FogColor       = kcOrigLight.FogColor
            end)
        end
    end
end

-- ── Kicia: Hitsound ───────────────────────────────────────────────────────────
local kcHitsoundInst
local function setupKiciaHitsound()
    if kcHitsoundInst then kcHitsoundInst:Destroy(); kcHitsoundInst = nil end
    kcHitsoundInst = Instance.new("Sound")
    kcHitsoundInst.SoundId = KC.Hitsound.SoundId
    kcHitsoundInst.Volume = 0.5
    kcHitsoundInst.RollOffMaxDistance = 1e9
    pcall(function() kcHitsoundInst.Parent = workspace end)
end
setupKiciaHitsound()

-- ── Kicia: Freecam ────────────────────────────────────────────────────────────
local kcFreecamConn
local kcFreecamVel = Vector3.new()
local kcFreecamActive = false
local function startKiciaFreecam()
    if kcFreecamConn then kcFreecamConn:Disconnect(); kcFreecamConn = nil end
    kcFreecamActive = KC.Move.FreecamEnabled
    if not kcFreecamActive then
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        return
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable end)
    local cam = workspace.CurrentCamera
    kcFreecamConn = RunService.RenderStepped:Connect(function(dt)
        if not KC.Move.FreecamEnabled then
            pcall(function() cam.CameraType = Enum.CameraType.Custom end)
            if kcFreecamConn then kcFreecamConn:Disconnect(); kcFreecamConn = nil end
            return
        end
        local spd = KC.Move.FreecamSpeed
        local mv = Vector3.new()
        local UIS = UserInputService
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) then mv = mv + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then mv = mv - Vector3.new(0,1,0) end
        local len = mv.Magnitude
        if len > 0 then mv = mv / len end
        pcall(function()
            cam.CFrame = cam.CFrame + mv * (spd * dt)
        end)
    end)
end

-- ── Kicia: Velocity / NoClip / BHop ──────────────────────────────────────────
local kcMoveConn
local kcBHopConn
local kcFlyConn, kcNoClipConn, kcFlyBodyGyro, kcFlyBodyVelocity
local function startKiciaMovement()
    if kcMoveConn then kcMoveConn:Disconnect(); kcMoveConn = nil end
    if kcBHopConn then kcBHopConn:Disconnect(); kcBHopConn = nil end
    if kcFlyConn then kcFlyConn:Disconnect(); kcFlyConn = nil end
    if kcNoClipConn then kcNoClipConn:Disconnect(); kcNoClipConn = nil end
    if kcFlyBodyGyro then pcall(function() kcFlyBodyGyro:Destroy() end); kcFlyBodyGyro = nil end
    if kcFlyBodyVelocity then pcall(function() kcFlyBodyVelocity:Destroy() end); kcFlyBodyVelocity = nil end
    -- Velocity Hack
    if KC.Move.VelocityEnabled then
        kcMoveConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local UIS = UserInputService
            local mv = Vector3.new()
            local cam = workspace.CurrentCamera
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit end
            if mv.Magnitude > 0 then
                pcall(function()
                    hrp.AssemblyLinearVelocity = mv * KC.Move.VelocitySpeed
                end)
            end
        end)
    end
    -- BHop
    if KC.Move.BHopEnabled then
        kcBHopConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            local hum2 = char and char:FindFirstChildOfClass("Humanoid")
            if hum2 and hum2.FloorMaterial ~= Enum.Material.Air then
                hum2.Jump = true
            end
        end)
    end
    -- Fly
    if KC.Move.FlyEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum2 = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum2 then
            pcall(function() hum2.PlatformStand = true end)
            kcFlyBodyGyro = Instance.new("BodyGyro", hrp)
            kcFlyBodyGyro.D = 100; kcFlyBodyGyro.P = 1e4; kcFlyBodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
            kcFlyBodyVelocity = Instance.new("BodyVelocity", hrp)
            kcFlyBodyVelocity.Velocity = Vector3.new(0,0,0)
            kcFlyBodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
            kcFlyConn = RunService.Heartbeat:Connect(function()
                if not KC.Move.FlyEnabled then
                    pcall(function() kcFlyBodyGyro:Destroy() end); kcFlyBodyGyro = nil
                    pcall(function() kcFlyBodyVelocity:Destroy() end); kcFlyBodyVelocity = nil
                    pcall(function()
                        local h2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if h2 then h2.PlatformStand = false end
                    end)
                    kcFlyConn:Disconnect(); kcFlyConn = nil
                    return
                end
                local c = LocalPlayer.Character
                if not c then return end
                local rp = c:FindFirstChild("HumanoidRootPart")
                if not rp then return end
                local cam = workspace.CurrentCamera
                local spd = KC.Move.FlySpeed
                local mv = Vector3.new()
                local UIS2 = UserInputService
                if UIS2:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
                if UIS2:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
                if UIS2:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
                if UIS2:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
                if UIS2:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
                if UIS2:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
                pcall(function()
                    if kcFlyBodyVelocity and kcFlyBodyVelocity.Parent then
                        kcFlyBodyVelocity.Velocity = mv.Magnitude > 0 and (mv.Unit * spd) or Vector3.new(0,0,0)
                    end
                    if kcFlyBodyGyro and kcFlyBodyGyro.Parent then
                        kcFlyBodyGyro.CFrame = cam.CFrame
                    end
                end)
            end)
        end
    end
    -- NoClip
    if KC.Move.NoClipEnabled then
        kcNoClipConn = RunService.Stepped:Connect(function()
            if not KC.Move.NoClipEnabled then kcNoClipConn:Disconnect(); kcNoClipConn = nil; return end
            local char = LocalPlayer.Character
            if not char then return end
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = false
                    end
                end
            end)
        end)
    end
end
startKiciaMovement()

-- ── Kicia: ShowActiveHUD ──────────────────────────────────────────────────────
do
    local kcHUDGui = Instance.new("ScreenGui")
    kcHUDGui.Name = "KC_ActiveHUD"
    kcHUDGui.ResetOnSpawn = false
    pcall(function() kcHUDGui.Parent = game:GetService("CoreGui") end)
    if not kcHUDGui.Parent then pcall(function() kcHUDGui.Parent = LocalPlayer.PlayerGui end) end

    local kcHUDFrame = Instance.new("Frame", kcHUDGui)
    kcHUDFrame.Size = UDim2.new(0, 160, 0, 20)
    kcHUDFrame.Position = UDim2.new(0, 4, 0.5, 0)
    kcHUDFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    kcHUDFrame.BackgroundTransparency = 0.3
    kcHUDFrame.BorderSizePixel = 0
    kcHUDFrame.Visible = false
    kcHUDFrame.Active = true
    kcHUDFrame.Draggable = true
    Instance.new("UICorner", kcHUDFrame).CornerRadius = UDim.new(0, 4)
    Instance.new("UIListLayout", kcHUDFrame).Padding = UDim.new(0, 2)

    local function kcHUDLine(txt, color)
        local l = Instance.new("TextLabel", kcHUDFrame)
        l.Size = UDim2.new(1, -8, 0, 14)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = color or Color3.fromRGB(180, 220, 255)
        l.TextSize = 11
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end

    local kcHUDLines = {}
    local kcHUDFeatures = {
        { key = function() return CFG and CFG.VOID_ENABLED end,         label = "VoidSpam",   color = Color3.fromRGB(100,200,255) },
        { key = function() return slingCFG and slingCFG.enabled end,    label = "Sling",      color = Color3.fromRGB(255,180,60)  },
        { key = function() return riotGodmodeCFG and riotGodmodeCFG.enabled end, label = "RiotGM", color = Color3.fromRGB(255,80,80) },
        { key = function() return aaSettings and aaSettings.enabled end, label = "AntiAim",   color = Color3.fromRGB(180,100,255) },
        { key = function() return KC.RageBot.Enabled end,               label = "RageBot",    color = Color3.fromRGB(255,100,100) },
        { key = function() return KC.Move.FreecamEnabled end,           label = "Freecam",    color = Color3.fromRGB(100,255,180) },
        { key = function() return KC.Move.VelocityEnabled end,          label = "VelHack",    color = Color3.fromRGB(100,180,255) },
        { key = function() return KC.Move.BHopEnabled end,              label = "BHop",       color = Color3.fromRGB(200,200,100) },
        { key = function() return KC.OrbitAround.Enabled end,           label = "OrbitAround",color = Color3.fromRGB(100,220,220) },
    }
    for _, f in ipairs(kcHUDFeatures) do
        table.insert(kcHUDLines, { line = kcHUDLine(f.label, f.color), check = f.key })
    end

    RunService.RenderStepped:Connect(function()
        kcHUDFrame.Visible = KC.HUD.ShowActiveHUD
        if not KC.HUD.ShowActiveHUD then return end
        local h = 4
        for _, entry in ipairs(kcHUDLines) do
            local active = pcall(entry.check) and entry.check()
            entry.line.Visible = active
            if active then h = h + 16 end
        end
        kcHUDFrame.Size = UDim2.new(0, 160, 0, math.max(20, h))
    end)
end

-- ── Kicia: Keybind List HUD ────────────────────────────────────────────────────
do
    local kcKBGui = Instance.new("ScreenGui")
    kcKBGui.Name = "KC_KeybindHUD"
    kcKBGui.ResetOnSpawn = false
    pcall(function() kcKBGui.Parent = game:GetService("CoreGui") end)
    if not kcKBGui.Parent then pcall(function() kcKBGui.Parent = LocalPlayer.PlayerGui end) end

    local kcKBFrame = Instance.new("Frame", kcKBGui)
    kcKBFrame.Size = UDim2.new(0, 180, 0, 120)
    kcKBFrame.Position = UDim2.new(1, -190, 0.5, -60)
    kcKBFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    kcKBFrame.BackgroundTransparency = 0.3
    kcKBFrame.BorderSizePixel = 0
    kcKBFrame.Visible = false
    kcKBFrame.Active = true
    kcKBFrame.Draggable = true
    Instance.new("UICorner", kcKBFrame).CornerRadius = UDim.new(0, 4)
    local ist2 = Instance.new("UIStroke", kcKBFrame); ist2.Color = Color3.fromRGB(80, 140, 255); ist2.Thickness = 1
    Instance.new("UIListLayout", kcKBFrame).Padding = UDim.new(0, 2)

    local function kbLine(txt)
        local l = Instance.new("TextLabel", kcKBFrame)
        l.Size = UDim2.new(1, -8, 0, 14)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.fromRGB(200, 200, 200)
        l.TextSize = 10
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end

    local kcKBHeader = kbLine("── KEYBINDS ──")
    kcKBHeader.TextColor3 = Color3.fromRGB(100, 180, 255)
    kcKBHeader.Font = Enum.Font.GothamBold
    kbLine("[INS]  Toggle Menu")
    kbLine("[DEL]  Toggle ESP")
    kbLine("[F]    Freecam")
    kbLine("[G]    AntiAim")
    kbLine("[H]    RageBot")
    kbLine("[J]    VoidSpam")
    kbLine("[K]    Slingshot")

    RunService.RenderStepped:Connect(function()
        kcKBFrame.Visible = KC.HUD.ShowKeybindList
    end)
end

-- ── Kicia: Drawing ESP (Kicia style on top of existing ESP) ───────────────────
local kcESPConns = {}
local kcDrawings = {}
local function clearKiciaESP()
    for _, d in ipairs(kcDrawings) do pcall(function() d:Remove() end) end
    kcDrawings = {}
    for _, c in ipairs(kcESPConns) do pcall(function() c:Disconnect() end) end
    kcESPConns = {}
end
local function makeKiciaESP(player)
    if not player or player == LocalPlayer then return end
    local draws = {}
    -- Box
    local box = Drawing.new("Square")
    box.Filled = KC.ESP.BoxFilled
    box.Transparency = KC.ESP.BoxFillTransparency
    box.Color = KC.ESP.BoxColor
    box.Thickness = KC.ESP.BoxThickness
    box.Visible = false
    table.insert(draws, box)
    -- Name
    local nameLabel = Drawing.new("Text")
    nameLabel.Size = KC.ESP.NameSize
    nameLabel.Color = KC.ESP.NameColor
    nameLabel.Outline = KC.ESP.NameOutline
    nameLabel.Visible = false
    table.insert(draws, nameLabel)
    -- Distance
    local distLabel = Drawing.new("Text")
    distLabel.Size = KC.ESP.DistSize
    distLabel.Color = KC.ESP.DistColor
    distLabel.Outline = KC.ESP.DistOutline
    distLabel.Visible = false
    table.insert(draws, distLabel)
    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Color = KC.ESP.BoxColor
    tracer.Thickness = KC.ESP.TracerThickness
    tracer.Visible = false
    table.insert(draws, tracer)
    for _, d in ipairs(draws) do table.insert(kcDrawings, d) end

    local conn = RunService.RenderStepped:Connect(function()
        local esp = KC.ESP
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local vis = esp.Enabled and char and hrp and hrp.Parent
        if not vis then
            for _, d in ipairs(draws) do d.Visible = false end
            return
        end
        if esp.IgnoreTeammates and player.Team == LocalPlayer.Team then
            for _, d in ipairs(draws) do d.Visible = false end
            return
        end
        local cam = workspace.CurrentCamera
        local pos3, onScreen = cam:WorldToViewportPoint(hrp.Position)
        local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
            (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
        if not onScreen or dist > esp.MaxDistance then
            for _, d in ipairs(draws) do d.Visible = false end
            return
        end
        -- Compute box from head to feet
        local headPos3 = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        local feetPos3 = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3, 0))
        local boxH = math.abs(headPos3.Y - feetPos3.Y)
        local boxW = boxH * 0.5
        local bx = pos3.X - boxW/2
        local by = headPos3.Y
        -- Box
        if esp.ShowBox then
            box.Position = Vector2.new(bx, by)
            box.Size = Vector2.new(boxW, boxH)
            box.Color = KC.ESP.BoxColor
            box.Filled = KC.ESP.BoxFilled
            box.Transparency = KC.ESP.BoxFillTransparency
            box.Thickness = KC.ESP.BoxThickness
            box.Visible = true
        else
            box.Visible = false
        end
        -- Name
        if esp.ShowName then
            nameLabel.Text = player.DisplayName
            nameLabel.Position = Vector2.new(pos3.X, by - 16)
            nameLabel.Color = KC.ESP.NameColor
            nameLabel.Outline = KC.ESP.NameOutline
            nameLabel.Visible = true
        else
            nameLabel.Visible = false
        end
        -- Distance
        if esp.ShowDistance then
            distLabel.Text = string.format("[%.0f]", dist)
            distLabel.Position = Vector2.new(pos3.X, by + boxH + 2)
            distLabel.Color = KC.ESP.DistColor
            distLabel.Outline = KC.ESP.DistOutline
            distLabel.Visible = true
        else
            distLabel.Visible = false
        end
        -- Tracer
        if esp.ShowTracers then
            local cam2 = workspace.CurrentCamera
            local origin = KC.ESP.TracerOrigin
            local fromY = origin == "Top" and 0 or origin == "Middle" and cam2.ViewportSize.Y/2 or cam2.ViewportSize.Y
            tracer.From = Vector2.new(cam2.ViewportSize.X/2, fromY)
            tracer.To = Vector2.new(pos3.X, pos3.Y)
            tracer.Color = KC.ESP.BoxColor
            tracer.Thickness = KC.ESP.TracerThickness
            tracer.Visible = true
        else
            tracer.Visible = false
        end
    end)
    table.insert(kcESPConns, conn)
end

local function rebuildKiciaESP()
    clearKiciaESP()
    if not KC.ESP.Enabled then return end
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LocalPlayer then makeKiciaESP(p) end
    end
    table.insert(kcESPConns, game:GetService("Players").PlayerAdded:Connect(makeKiciaESP))
end

-- ── Kicia: Chams ──────────────────────────────────────────────────────────────
local kcChamHighlights = {}
local function rebuildKiciaChams()
    for p, hl in pairs(kcChamHighlights) do
        pcall(function() hl:Destroy() end)
        kcChamHighlights[p] = nil
    end
    if not KC.Chams.Enabled then return end
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = Instance.new("Highlight")
            hl.FillColor = KC.Chams.FillColor
            hl.FillTransparency = KC.Chams.FillTransparency
            hl.OutlineColor = KC.Chams.OutlineColor
            hl.OutlineTransparency = KC.Chams.OutlineTransparency
            pcall(function() hl.Adornee = p.Character; hl.Parent = workspace end)
            kcChamHighlights[p] = hl
        end
    end
end

-- ── Kicia: Config Save/Load ───────────────────────────────────────────────────
local kcConfigKey = "UNCODE_KC_Config"
local function saveKiciaConfig(name)
    pcall(function()
        local data = { name = name or KC.LastConfig, KC = KC }
        writefile and writefile(kcConfigKey .. "_" .. (name or "default") .. ".json",
            game:GetService("HttpService"):JSONEncode(data))
    end)
end
local function loadKiciaConfig(name)
    pcall(function()
        local raw = readfile and readfile(kcConfigKey .. "_" .. (name or "default") .. ".json")
        if raw then
            local data = game:GetService("HttpService"):JSONDecode(raw)
            if data and data.KC then
                for k, v in pairs(data.KC) do
                    if type(KC[k]) == "table" and type(v) == "table" then
                        for k2, v2 in pairs(v) do KC[k][k2] = v2 end
                    else
                        KC[k] = v
                    end
                end
            end
        end
    end)
end
if KC.AutoLoadConfig then loadKiciaConfig("default") end

-- ═══════════════════════════════════════════════════════════════════════════
-- Kicia UI
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Kicia UI: RageBot ─────────────────────────────────────────────────────────
do
    local gbKRB = WT.Rage:AddLeftGroupbox("Kicia RageBot")
    gbKRB:AddToggle("KCRB", { Text = "RageBot (Kicia)", Default = false,
        Callback = function(v) KC.RageBot.Enabled = v end })
    gbKRB:AddToggle("KCRBOnScreen", { Text = "On-Screen Only", Default = false,
        Callback = function(v) KC.RageBot.OnScreen = v end })
    gbKRB:AddToggle("KCRBFOVEnabled", { Text = "Show FOV Circle", Default = false,
        Callback = function(v) KC.RageBot.FOVEnabled = v end })
    gbKRB:AddSlider("KCRBFOVRadius", { Text = "FOV Radius", Default = 80, Min = 10, Max = 400, Rounding = 0,
        Callback = function(v) KC.RageBot.FOVRadius = v end })
    gbKRB:AddToggle("KCRBShotgunMeta", { Text = "Shotgun Meta", Default = false,
        Callback = function(v) KC.RageBot.ShotgunMeta = v end })
    gbKRB:AddToggle("KCRBSlingshotBypass", { Text = "Slingshot Bypass (Kicia)", Default = false,
        Callback = function(v) KC.RageBot.SlingshotBypass = v end })
    gbKRB:AddToggle("KCRBAutoScope", { Text = "Auto Scope", Default = false,
        Callback = function(v) KC.RageBot.AutoScope = v end })
    gbKRB:AddToggle("KCRBRemoveScope", { Text = "Remove Scope Overlay", Default = false,
        Callback = function(v) KC.RageBot.RemoveScope = v end })
end

-- ── Kicia UI: AntiAim ─────────────────────────────────────────────────────────
do
    local gbKAA = WT.AntiAim:AddRightGroupbox("Kicia AntiAim")
    gbKAA:AddToggle("KCAA", { Text = "AntiAim (Kicia)", Default = false,
        Callback = function(v) KC.AntiAim.Enabled = v; startKiciaAntiAim() end })
    gbKAA:AddDropdown("KCAAMode", { Text = "AA Mode", Default = 1,
        Values = {"None","Spin","Jitter","Desync","Static","Random"},
        Callback = function(v) KC.AntiAim.Mode = v; startKiciaAntiAim() end })
    gbKAA:AddDropdown("KCAAPitch", { Text = "AA Pitch", Default = 1,
        Values = {"None","Down","Up","Random"},
        Callback = function(v) KC.AntiAim.Pitch = v end })
    gbKAA:AddSlider("KCAASpeed", { Text = "AA Speed", Default = 15, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) KC.AntiAim.Speed = v end })
    gbKAA:AddSlider("KCAAJitterRange", { Text = "Jitter Range", Default = 45, Min = 1, Max = 180, Rounding = 0,
        Callback = function(v) KC.AntiAim.JitterRange = v end })
end

-- ── Kicia UI: Movement ────────────────────────────────────────────────────────
do
    local gbKMv = WT.Move:AddLeftGroupbox("Kicia Movement")
    gbKMv:AddToggle("KCFreecam", { Text = "Freecam", Default = false,
        Callback = function(v) KC.Move.FreecamEnabled = v; startKiciaFreecam() end })
    gbKMv:AddSlider("KCFreecamSpeed", { Text = "Freecam Speed", Default = 30, Min = 5, Max = 300, Rounding = 0,
        Callback = function(v) KC.Move.FreecamSpeed = v end })
    gbKMv:AddToggle("KCVelocity", { Text = "Velocity Hack", Default = false,
        Callback = function(v) KC.Move.VelocityEnabled = v; startKiciaMovement() end })
    gbKMv:AddSlider("KCVelocitySpeed", { Text = "Velocity Speed", Default = 50, Min = 5, Max = 500, Rounding = 0,
        Callback = function(v) KC.Move.VelocitySpeed = v end })
    gbKMv:AddToggle("KCBHop", { Text = "Bunny Hop", Default = false,
        Callback = function(v) KC.Move.BHopEnabled = v; startKiciaMovement() end })
    gbKMv:AddToggle("KCOrbitAround", { Text = "Orbit Around Enemy", Default = false,
        Callback = function(v) KC.OrbitAround.Enabled = v; startKiciaOrbit() end })
    gbKMv:AddSlider("KCOrbitRadius", { Text = "Orbit Radius", Default = 10, Min = 2, Max = 100, Rounding = 0,
        Callback = function(v) KC.OrbitAround.Radius = v end })
    gbKMv:AddSlider("KCOrbitSpeed", { Text = "Orbit Speed", Default = 2, Min = 1, Max = 20, Rounding = 0,
        Callback = function(v) KC.OrbitAround.Speed = v end })
    gbKMv:AddToggle("KCOrbitEnemy", { Text = "Orbit Around Enemy (Lock)", Default = false,
        Callback = function(v) KC.OrbitAround.AroundEnemy = v end })
end

-- ── Kicia UI: ESP ─────────────────────────────────────────────────────────────
do
    local gbKESP = WT.ESP:AddRightGroupbox("Kicia ESP")
    gbKESP:AddToggle("KCESP", { Text = "Kicia ESP", Default = false,
        Callback = function(v) KC.ESP.Enabled = v; rebuildKiciaESP() end })
    gbKESP:AddToggle("KCESPIgnoreTeam", { Text = "Ignore Teammates", Default = false,
        Callback = function(v) KC.ESP.IgnoreTeammates = v end })
    gbKESP:AddToggle("KCESPBox", { Text = "Box", Default = false,
        Callback = function(v) KC.ESP.ShowBox = v end })
    gbKESP:AddToggle("KCESPBoxFilled", { Text = "Filled Box", Default = false,
        Callback = function(v) KC.ESP.BoxFilled = v end })
    gbKESP:AddSlider("KCESPBoxFillTrans", { Text = "Box Fill Transparency", Default = 85, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) KC.ESP.BoxFillTransparency = v * 0.01 end })
    gbKESP:AddSlider("KCESPBoxThickness", { Text = "Box Thickness", Default = 150, Min = 50, Max = 500, Rounding = 0,
        Callback = function(v) KC.ESP.BoxThickness = v * 0.01 end })
    gbKESP:AddColorpicker("KCESPBoxColor", { Text = "Box Color", Default = KC.ESP.BoxColor,
        Callback = function(v) KC.ESP.BoxColor = v end })
    gbKESP:AddToggle("KCESPName", { Text = "Name", Default = false,
        Callback = function(v) KC.ESP.ShowName = v end })
    gbKESP:AddToggle("KCESPNameOutline", { Text = "Name Outline", Default = false,
        Callback = function(v) KC.ESP.NameOutline = v end })
    gbKESP:AddColorpicker("KCESPNameColor", { Text = "Name Color", Default = KC.ESP.NameColor,
        Callback = function(v) KC.ESP.NameColor = v end })
    gbKESP:AddToggle("KCESPDist", { Text = "Distance", Default = false,
        Callback = function(v) KC.ESP.ShowDistance = v end })
    gbKESP:AddSlider("KCESPMaxDist", { Text = "Max Distance", Default = 1000, Min = 50, Max = 5000, Rounding = 0,
        Callback = function(v) KC.ESP.MaxDistance = v end })
    gbKESP:AddToggle("KCESPTracer", { Text = "Tracers", Default = false,
        Callback = function(v) KC.ESP.ShowTracers = v end })
    gbKESP:AddDropdown("KCESPTracerOrigin", { Text = "Tracer Origin", Default = 1,
        Values = {"Bottom","Middle","Top"},
        Callback = function(v) KC.ESP.TracerOrigin = v end })
    gbKESP:AddToggle("KCESPSkeleton", { Text = "Skeleton", Default = false,
        Callback = function(v) KC.ESP.ShowSkeleton = v end })
    gbKESP:AddToggle("KCESPHealthBar", { Text = "Health Bar", Default = false,
        Callback = function(v) KC.ESP.ShowHealthBar = v end })
    gbKESP:AddButton({ Text = "Rebuild Kicia ESP", Func = function() rebuildKiciaESP() end })
end

-- ── Kicia UI: Chams ───────────────────────────────────────────────────────────
do
    local gbKCh = WT.Chams:AddRightGroupbox("Kicia Chams")
    gbKCh:AddToggle("KCChams", { Text = "Kicia Chams (Highlight)", Default = false,
        Callback = function(v) KC.Chams.Enabled = v; rebuildKiciaChams() end })
    gbKCh:AddColorpicker("KCChamsFillColor", { Text = "Fill Color", Default = KC.Chams.FillColor,
        Callback = function(v) KC.Chams.FillColor = v; rebuildKiciaChams() end })
    gbKCh:AddSlider("KCChamsFillTrans", { Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) KC.Chams.FillTransparency = v * 0.01; rebuildKiciaChams() end })
    gbKCh:AddColorpicker("KCChamsOutColor", { Text = "Outline Color", Default = KC.Chams.OutlineColor,
        Callback = function(v) KC.Chams.OutlineColor = v; rebuildKiciaChams() end })
    gbKCh:AddSlider("KCChamsOutTrans", { Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) KC.Chams.OutlineTransparency = v * 0.01; rebuildKiciaChams() end })
end

-- ── Kicia UI: Lighting ────────────────────────────────────────────────────────
do
    local gbKLit = WT.Move:AddRightGroupbox("Kicia Lighting")
    gbKLit:AddToggle("KCLighting", { Text = "Custom Lighting", Default = false,
        Callback = function(v) KC.Lighting.Enabled = v; applyKiciaLighting() end })
    gbKLit:AddSlider("KCBrightness", { Text = "Brightness", Default = 200, Min = 0, Max = 1000, Rounding = 0,
        Callback = function(v) KC.Lighting.Brightness = v * 0.01; applyKiciaLighting() end })
    gbKLit:AddColorpicker("KCAmbientColor", { Text = "Ambient Color", Default = KC.Lighting.AmbientColor,
        Callback = function(v) KC.Lighting.AmbientColor = v; applyKiciaLighting() end })
    gbKLit:AddColorpicker("KCOutdoorAmbient", { Text = "Outdoor Ambient", Default = KC.Lighting.OutdoorAmbient,
        Callback = function(v) KC.Lighting.OutdoorAmbient = v; applyKiciaLighting() end })
    gbKLit:AddSlider("KCClockTime", { Text = "Clock Time (hour)", Default = 14, Min = 0, Max = 24, Rounding = 0,
        Callback = function(v) KC.Lighting.ClockTime = v; applyKiciaLighting() end })
    gbKLit:AddSlider("KCFogEnd", { Text = "Fog End", Default = 1000, Min = 0, Max = 5000, Rounding = 0,
        Callback = function(v) KC.Lighting.FogEnd = v; applyKiciaLighting() end })
    gbKLit:AddColorpicker("KCFogColor", { Text = "Fog Color", Default = KC.Lighting.FogColor,
        Callback = function(v) KC.Lighting.FogColor = v; applyKiciaLighting() end })
end

-- ── Kicia UI: Hit Effect ──────────────────────────────────────────────────────
do
    local gbKHFX = WT.FX:AddRightGroupbox("Kicia Hit Effect")
    gbKHFX:AddToggle("KCHitFX", { Text = "Hit Effect (Kicia)", Default = false,
        Callback = function(v) KC.HitEffect.Enabled = v end })
    gbKHFX:AddDropdown("KCHitFXType", { Text = "Effect Material", Default = 1,
        Values = {"Neon","SmoothPlastic","Glass","Metal","ForceField"},
        Callback = function(v) KC.HitEffect.Type = v end })
    gbKHFX:AddColorpicker("KCHitFXColor", { Text = "Effect Color", Default = KC.HitEffect.Color,
        Callback = function(v) KC.HitEffect.Color = v end })
    gbKHFX:AddSlider("KCHitFXFadeIn", { Text = "Fade In (x0.01s)", Default = 10, Min = 1, Max = 200, Rounding = 0,
        Callback = function(v) KC.HitEffect.FadeInTime = v * 0.01 end })
    gbKHFX:AddSlider("KCHitFXFadeOut", { Text = "Fade Out (x0.01s)", Default = 30, Min = 1, Max = 500, Rounding = 0,
        Callback = function(v) KC.HitEffect.FadeOutTime = v * 0.01 end })
end

-- ── Kicia UI: Hitsound ────────────────────────────────────────────────────────
do
    local gbKHS = WT.FX:AddLeftGroupbox("Kicia Hitsound")
    gbKHS:AddInput("KCHitsoundId", { Text = "Hitsound ID", Default = "rbxassetid://719384308",
        Callback = function(v) KC.Hitsound.SoundId = v; setupKiciaHitsound() end })
    gbKHS:AddButton({ Text = "Play Test Hit Sound", Func = function()
        if kcHitsoundInst then
            pcall(function() kcHitsoundInst:Stop(); kcHitsoundInst:Play() end)
        end
    end })
end

-- ── Kicia UI: HUD Overlays ────────────────────────────────────────────────────
do
    local gbKHUD = WT.Config:AddRightGroupbox("Kicia HUD")
    gbKHUD:AddToggle("KCShowActiveHUD", { Text = "Show Active Feature HUD", Default = false,
        Callback = function(v) KC.HUD.ShowActiveHUD = v end })
    gbKHUD:AddToggle("KCShowKeybindList", { Text = "Show Keybind List", Default = false,
        Callback = function(v) KC.HUD.ShowKeybindList = v end })
    gbKHUD:AddDivider()
    gbKHUD:AddButton({ Text = "Save Kicia Config", Func = function() saveKiciaConfig("default") end })
    gbKHUD:AddButton({ Text = "Load Kicia Config", Func = function() loadKiciaConfig("default"); rebuildKiciaESP(); rebuildKiciaChams(); applyKiciaLighting() end })
    gbKHUD:AddToggle("KCAutoLoadConfig", { Text = "Auto-Load Config", Default = true,
        Callback = function(v) KC.AutoLoadConfig = v end })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ESPExt Engines: WorldName / WorldDistance / WeaponEnabled / MaterialEnabled / SkeletonOutline
-- ═══════════════════════════════════════════════════════════════════════════

-- ── ESPExt: World BillboardGuis (WorldName, WorldDistance, WeaponEnabled) ────
-- Single shared RenderStepped loop instead of one connection per player.
local ueWorldBBs = {}  -- [player] = { bb, nameLbl, distLbl, weapLbl }

local function makeWorldBB(player)
    if player == LocalPlayer then return end
    if ueWorldBBs[player] then
        pcall(function() ueWorldBBs[player].bb:Destroy() end)
        ueWorldBBs[player] = nil
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "_UE_WorldBB"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 110, 0, 60)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    bb.ResetOnSpawn = false

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Name = "WorldName"
    nameLbl.Size = UDim2.new(1, 0, 0, 18)
    nameLbl.Position = UDim2.new(0, 0, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.Visible = false

    local distLbl = Instance.new("TextLabel", bb)
    distLbl.Name = "WorldDist"
    distLbl.Size = UDim2.new(1, 0, 0, 16)
    distLbl.Position = UDim2.new(0, 0, 0, 20)
    distLbl.BackgroundTransparency = 1
    distLbl.TextScaled = true
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextStrokeTransparency = 0.4
    distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLbl.Visible = false

    local weapLbl = Instance.new("TextLabel", bb)
    weapLbl.Name = "WorldWeapon"
    weapLbl.Size = UDim2.new(1, 0, 0, 14)
    weapLbl.Position = UDim2.new(0, 0, 0, 38)
    weapLbl.BackgroundTransparency = 1
    weapLbl.TextScaled = false
    weapLbl.TextSize = 11
    weapLbl.Font = Enum.Font.Gotham
    weapLbl.TextStrokeTransparency = 0.5
    weapLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    weapLbl.Visible = false

    ueWorldBBs[player] = { bb = bb, nameLbl = nameLbl, distLbl = distLbl, weapLbl = weapLbl }
end

-- One shared loop for ALL players — no per-player connections
RunService.RenderStepped:Connect(function()
    local anyOn = UE.ESPExt.WorldName or UE.ESPExt.WorldDistance or UE.ESPExt.WeaponEnabled
    for player, data in pairs(ueWorldBBs) do
        if not player or not player.Parent then continue end
        local bb      = data.bb
        local nameLbl = data.nameLbl
        local distLbl = data.distLbl
        local weapLbl = data.weapLbl
        local char    = player.Character
        local hrp     = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent or not anyOn then
            bb.Parent = nil; continue
        end
        bb.Parent = hrp

        nameLbl.Visible = UE.ESPExt.WorldName
        if UE.ESPExt.WorldName then
            nameLbl.Text = player.Name
            nameLbl.TextColor3 = UE.ESPExt.WorldNameColor
        end

        distLbl.Visible = UE.ESPExt.WorldDistance
        if UE.ESPExt.WorldDistance and root then
            local d = math.floor((hrp.Position - root.Position).Magnitude)
            distLbl.Text = d .. "m"
            distLbl.TextColor3 = UE.ESPExt.WorldDistanceColor
        end

        weapLbl.Visible = UE.ESPExt.WeaponEnabled
        if UE.ESPExt.WeaponEnabled then
            local tool = char:FindFirstChildOfClass("Tool")
            weapLbl.Text = tool and ("[" .. tool.Name .. "]") or ""
            weapLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
        end
    end
end)

do
    local Players2 = game:GetService("Players")
    for _, p in ipairs(Players2:GetPlayers()) do
        if p ~= LocalPlayer then
            task.spawn(function()
                if p.Character then makeWorldBB(p) end
                p.CharacterAdded:Connect(function() task.wait(0.6); makeWorldBB(p) end)
            end)
        end
    end
    Players2.PlayerAdded:Connect(function(p)
        if p == LocalPlayer then return end
        p.CharacterAdded:Connect(function() task.wait(0.6); makeWorldBB(p) end)
    end)
    Players2.PlayerRemoving:Connect(function(p)
        if ueWorldBBs[p] then
            pcall(function() ueWorldBBs[p].bb:Destroy() end)
            ueWorldBBs[p] = nil
        end
    end)
end

-- ── ESPExt: Material Override ─────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not UE.ESPExt.MaterialEnabled then return end
    local mat = Enum.Material.Neon
    pcall(function() mat = Enum.Material[UE.ESPExt.Material] end)
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Material = mat
                end
            end
        end)
    end
end)

-- ── ESPExt: Skeleton Outline ──────────────────────────────────────────────────
local UE_SKEL_PAIRS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local ueSkeletonLines = {}
local function getOrMakeSkelLines(player)
    if not ueSkeletonLines[player] then
        local lines = {}
        for i = 1, #UE_SKEL_PAIRS do
            local line = Drawing.new("Line")
            line.Thickness = math.max(UE.ESPExt.SkeletonThickness, 1)
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Visible = false
            lines[i] = line
        end
        ueSkeletonLines[player] = lines
    end
    return ueSkeletonLines[player]
end

RunService.RenderStepped:Connect(function()
    -- Early-out: hide existing lines and skip Drawing creation when disabled
    if not UE.ESPExt.SkeletonOutline then
        for _, lines in pairs(ueSkeletonLines) do
            for _, l in ipairs(lines) do l.Visible = false end
        end
        return
    end
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p == LocalPlayer then continue end
        local lines = getOrMakeSkelLines(p)
        local char = p.Character
        local en = char ~= nil
        if not en then
            for _, l in ipairs(lines) do l.Visible = false end
            continue
        end
        local cam = workspace.CurrentCamera
        for i, pair in ipairs(UE_SKEL_PAIRS) do
            local line = lines[i]
            local a = char:FindFirstChild(pair[1])
            local b = char:FindFirstChild(pair[2])
            if a and b then
                local s1, on1 = cam:WorldToViewportPoint(a.Position)
                local s2, on2 = cam:WorldToViewportPoint(b.Position)
                if on1 and on2 and s1.Z > 0 and s2.Z > 0 then
                    line.From = Vector2.new(s1.X, s1.Y)
                    line.To   = Vector2.new(s2.X, s2.Y)
                    line.Thickness = math.max(UE.ESPExt.SkeletonThickness, 1)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(p)
    if ueSkeletonLines[p] then
        for _, l in ipairs(ueSkeletonLines[p]) do pcall(function() l:Remove() end) end
        ueSkeletonLines[p] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ESPExt UI + TargetTracer UI + Target.UIEnabled UI + KC Move Fly/NoClip UI
-- ═══════════════════════════════════════════════════════════════════════════

-- Debug: confirm this section actually runs
pcall(function() Notify("UNCODE UI+ loading", 2) end)

-- ── UI: ESP+ sub-tab for UE Target Tracer, World ESP, ESPExt ─────────────────
-- Use a dedicated new sub-tab to avoid potential single-groupbox-per-side limits
local WT_ESPPlus
pcall(function() WT_ESPPlus = TB.ESP:AddTab("ESP+") end)

if WT_ESPPlus then
    pcall(function()
        local gbTrc = WT_ESPPlus:AddLeftGroupbox("Target Tracer")
        gbTrc:AddToggle("UETargetTracer", { Text = "Target Tracer", Default = false,
            Callback = function(v) UE.TargetTracer.Enabled = v end })
        gbTrc:AddDropdown("UETargetTracerCustom", { Text = "Tracer Style", Default = 1,
            Values = {"Default","Rainbow","Team"},
            Callback = function(v) UE.TargetTracer.Customization = v end })
        gbTrc:AddDivider()
        gbTrc:AddToggle("UETargetUI", { Text = "Target Info Panel", Default = false,
            Callback = function(v) UE.Target.UIEnabled = v end })
        gbTrc:AddToggle("UETargetUIShow", { Text = "  Show Targets", Default = true,
            Callback = function(v) UE.Target.UIShowTargets = v end })
    end)
    pcall(function()
        local gbWld = WT_ESPPlus:AddRightGroupbox("World ESP")
        gbWld:AddToggle("UEWorldName", { Text = "World Name", Default = false,
            Callback = function(v) UE.ESPExt.WorldName = v end })
        gbWld:AddColorpicker("UEWorldNameColor", { Text = "Name Color", Default = UE.ESPExt.WorldNameColor,
            Callback = function(v) UE.ESPExt.WorldNameColor = v end })
        gbWld:AddToggle("UEWorldDist", { Text = "World Distance", Default = false,
            Callback = function(v) UE.ESPExt.WorldDistance = v end })
        gbWld:AddColorpicker("UEWorldDistColor", { Text = "Distance Color", Default = UE.ESPExt.WorldDistanceColor,
            Callback = function(v) UE.ESPExt.WorldDistanceColor = v end })
        gbWld:AddToggle("UEWeaponESP", { Text = "Weapon Name", Default = false,
            Callback = function(v) UE.ESPExt.WeaponEnabled = v end })
    end)
else
    -- Fallback: extend the existing ESP right groupbox if AddTab failed
    pcall(function()
        local gbR = WT.ESP:AddRightGroupbox("Target Tracer / World")
        gbR:AddToggle("UETargetTracer", { Text = "Target Tracer", Default = false,
            Callback = function(v) UE.TargetTracer.Enabled = v end })
        gbR:AddToggle("UETargetUI", { Text = "Target Info Panel", Default = false,
            Callback = function(v) UE.Target.UIEnabled = v end })
        gbR:AddDivider()
        gbR:AddToggle("UEWorldName", { Text = "World Name", Default = false,
            Callback = function(v) UE.ESPExt.WorldName = v end })
        gbR:AddToggle("UEWorldDist", { Text = "World Distance", Default = false,
            Callback = function(v) UE.ESPExt.WorldDistance = v end })
        gbR:AddToggle("UEWeaponESP", { Text = "Weapon Name", Default = false,
            Callback = function(v) UE.ESPExt.WeaponEnabled = v end })
    end)
end

-- ── UI: Chams+ sub-tab for Material Override / Skeleton Outline ──────────────
local WT_ChamsPlus
pcall(function() WT_ChamsPlus = TB.Visual:AddTab("Chams+") end)

if WT_ChamsPlus then
    pcall(function()
        local gbMat = WT_ChamsPlus:AddLeftGroupbox("Material Override")
        gbMat:AddToggle("UEMaterialEnabled", { Text = "Enemies Material", Default = false,
            Callback = function(v) UE.ESPExt.MaterialEnabled = v end })
        gbMat:AddDropdown("UEMaterial", { Text = "Material", Default = 1,
            Values = {"Neon","SmoothPlastic","Glass","Metal","ForceField","Foil"},
            Callback = function(v) UE.ESPExt.Material = v end })
    end)
    pcall(function()
        local gbSk = WT_ChamsPlus:AddRightGroupbox("Skeleton Outline")
        gbSk:AddToggle("UESkelOutline", { Text = "Skeleton Outline", Default = false,
            Callback = function(v) UE.ESPExt.SkeletonOutline = v end })
        gbSk:AddSlider("UESkelThickness", { Text = "Thickness", Default = 1, Min = 1, Max = 5, Rounding = 0,
            Callback = function(v) UE.ESPExt.SkeletonThickness = v end })
    end)
else
    pcall(function()
        local gbMat = WT.Chams:AddLeftGroupbox("Material / Skeleton")
        gbMat:AddToggle("UEMaterialEnabled", { Text = "Enemies Material", Default = false,
            Callback = function(v) UE.ESPExt.MaterialEnabled = v end })
        gbMat:AddDropdown("UEMaterial", { Text = "Material", Default = 1,
            Values = {"Neon","SmoothPlastic","Glass","Metal","ForceField","Foil"},
            Callback = function(v) UE.ESPExt.Material = v end })
        gbMat:AddDivider()
        gbMat:AddToggle("UESkelOutline", { Text = "Skeleton Outline", Default = false,
            Callback = function(v) UE.ESPExt.SkeletonOutline = v end })
        gbMat:AddSlider("UESkelThickness", { Text = "Thickness", Default = 1, Min = 1, Max = 5, Rounding = 0,
            Callback = function(v) UE.ESPExt.SkeletonThickness = v end })
    end)
end

-- ── UI: KC Fly / NoClip ──────────────────────────────────────────────────────
local WT_MoveExt
pcall(function() WT_MoveExt = TB.Misc:AddTab("Move+") end)

local _flyUItarget = WT_MoveExt or WT.Move
pcall(function()
    local gbKF = _flyUItarget:AddLeftGroupbox("Fly / NoClip")
    gbKF:AddToggle("KCFly", { Text = "Fly (WASD+Space/Ctrl)", Default = false,
        Callback = function(v)
            KC.Move.FlyEnabled = v
            if not v then
                pcall(function()
                    if kcFlyBodyGyro then kcFlyBodyGyro:Destroy(); kcFlyBodyGyro = nil end
                    if kcFlyBodyVelocity then kcFlyBodyVelocity:Destroy(); kcFlyBodyVelocity = nil end
                    if kcFlyConn then kcFlyConn:Disconnect(); kcFlyConn = nil end
                    local h2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if h2 then h2.PlatformStand = false end
                end)
            end
            startKiciaMovement()
        end })
    gbKF:AddSlider("KCFlySpeed", { Text = "Fly Speed", Default = 60, Min = 5, Max = 500, Rounding = 0,
        Callback = function(v) KC.Move.FlySpeed = v end })
    gbKF:AddDivider()
    gbKF:AddToggle("KCNoClip", { Text = "NoClip", Default = false,
        Callback = function(v)
            KC.Move.NoClipEnabled = v
            if not v and kcNoClipConn then kcNoClipConn:Disconnect(); kcNoClipConn = nil end
            if v then startKiciaMovement() end
        end })
end)

Notify("UNCODE loaded — Rivals HvH ready", 4)
print("[UNCODE] ===== FULLY LOADED (all UI built) =====")
