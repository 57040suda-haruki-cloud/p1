--!nocheck
-- UNCODE v3 | Rivals HvH | Unified: Rage + ESP + Visuals + Movement + Effects
-- UI: dark (15,15,15) bg, blue (0,100,255) borders, Code font | No Japanese in code

if getgenv().UNCODE_LOADED then
    warn("[UNCODE] Reloading...")
    pcall(function()
        if getgenv().UNCODE_GUI then getgenv().UNCODE_GUI:Destroy() end
    end)
    pcall(function()
        for _, c in ipairs(getgenv().UNCODE_CONNS or {}) do pcall(function() c:Disconnect() end) end
    end)
    pcall(function()
        local rs = game:GetService("RunService")
        for _, n in ipairs({"UNCODE_AntiAim","UNCODE_FakePos","UNCODE_Fly"}) do
            pcall(function() rs:UnbindFromRenderStep(n) end)
        end
    end)
end
getgenv().UNCODE_LOADED = true
getgenv().UNCODE_CONNS  = {}

print("[UNCODE v3] Starting...")

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local Debris           = game:GetService("Debris")
local CoreGui          = game:GetService("CoreGui")
local StarterGui       = game:GetService("StarterGui")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
if not game:IsLoaded() then game.Loaded:Wait() end
if not LocalPlayer then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() LocalPlayer = Players.LocalPlayer end

local Random_ = Random.new()

-- ── Palette ───────────────────────────────────────────────────────────────────
local C_BG    = Color3.fromRGB(10,  10,  10)
local C_PANEL = Color3.fromRGB(15,  15,  15)
local C_BTN   = Color3.fromRGB(22,  22,  22)
local C_BOR   = Color3.fromRGB(0,   100, 255)
local C_ACC   = Color3.fromRGB(40,  120, 255)
local C_ACC2  = Color3.fromRGB(80,  160, 255)
local C_ON    = Color3.fromRGB(0,   200, 80)
local C_OFF   = Color3.fromRGB(55,  55,  55)
local C_TXT   = Color3.fromRGB(230, 230, 230)
local C_DIM   = Color3.fromRGB(140, 140, 140)
local C_WHT   = Color3.fromRGB(255, 255, 255)

-- ── Config ────────────────────────────────────────────────────────────────────
local Cfg = {
    Rage = {
        Enabled    = false,
        VoidSpam   = false,
        SpamRate   = 10,
        AimRand    = 0.3,
        TpAttack   = false,
        GodMode    = false,
        GodY       = 10,
        SpinShot   = false,
        SpinSpeed  = 720,
    },
    AntiAim = {
        Enabled    = false,
        Pitch      = 0,
        Yaw        = 180,
        FloorHide  = false,
        Jitter     = 0,
    },
    VoidHide = {
        Enabled    = false,
        Y          = 9e10,
        SyncRage   = false,
    },
    ESP = {
        Enabled    = false,
        Box        = true,
        Name       = true,
        Healthbar  = true,
        Distance   = true,
        Skeleton   = false,
        MaxDist    = 1200,
        BoxColor   = Color3.fromRGB(0, 120, 255),
        NameColor  = Color3.fromRGB(230, 230, 230),
        HBColor    = Color3.fromRGB(80, 220, 80),
        TeamCheck  = true,
        TargetHUD  = false,
    },
    Visuals = {
        Aura       = false,
        AuraMode   = "Cyber Blue",
        AuraRGB    = false,
        Tracers    = false,
        Crosshair  = false,
        CrossGap   = 8,
        CrossSize  = 17,
        HitFX      = false,
        HitFXType  = "damage",
        HitSound   = false,
        HitSoundFX = "sparkle",
        Chams      = false,
        ChamsColor = Color3.fromRGB(255,0,100),
        ChamsMat   = "Neon",
        ChamsTrans = 50,
        WorldFX    = false,
        Fullbright = false,
        FOVCircle  = false,
        FOVRadius  = 120,
    },
    Movement = {
        Fly        = false,
        FlySpeed   = 60,
        Noclip     = false,
        SpeedMult  = false,
        SpeedVal   = 2.0,
        SlideBoost = false,
        SlideMult  = 2.0,
        DoubleJump = false,
        InfJump    = false,
        JumpHeight = 1.0,
        LongJump   = false,
        LongForce  = 150,
        ClickTP    = false,
        TpToTarget = false,
        TpOffset   = 3,
        TpRate     = 0.5,
    },
    Misc = {
        Watermark  = true,
        AntiAFK    = false,
        UnlockFPS  = false,
        TargetFPS  = 144,
        AutoCollect= false,
        CollectR   = 120,
        CfgSave    = false,
        UIKey      = "Insert",
    },
}

-- ── State ─────────────────────────────────────────────────────────────────────
local S = {
    Conns        = getgenv().UNCODE_CONNS,
    ESPObjects   = {},
    AuraObjs     = {},
    AuraActive   = false,
    AuraRing     = nil,
    AuraHRP      = nil,
    TracerPool   = {},
    CrossLines   = {},
    ChamsMap     = {},
    HUDGui       = nil,
    FOVDraw      = nil,
    FOVOutline   = nil,
    HitMarkers   = {},
    WmLabel      = nil,
    AntiAimBound = false,
    FlyBound     = false,
    LastTP       = 0,
    LastAttack   = 0,
    AttackNum    = 0,
    HeavyNum     = 0,
    LastJump     = 0,
    JumpsUsed    = 0,
    LastTracer   = 0,
    Hue          = 0,
    CharConns    = {},
    FakePosCF    = nil,
    FakePosOn    = false,
    VoidHideOn   = false,
}

local function Bind(c)
    table.insert(S.Conns, c)
    return c
end

-- ── Helper ────────────────────────────────────────────────────────────────────
local function NI(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
    if parent then o.Parent = parent end
    return o
end

local function GetChar(pl)
    pl = pl or LocalPlayer
    local c = pl and pl.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then return c end
    return nil
end

local function GetHRP(pl)
    local c = GetChar(pl)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum(pl)
    local c = GetChar(pl)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsEnemy(pl)
    if pl == LocalPlayer then return false end
    if Cfg.ESP.TeamCheck then
        if pl.Team and LocalPlayer.Team and pl.Team == LocalPlayer.Team then return false end
    end
    return true
end

local function GetEnemies()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            local c = GetChar(p)
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(out, p) end
            end
        end
    end
    return out
end

local function W2S(pos)
    local ok, s = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok then return nil, nil, nil end
    return s.X, s.Y, s.Z
end

local function RandUnit()
    return Vector3.new(
        Random_:NextNumber(-1, 1),
        Random_:NextNumber(-1, 1),
        Random_:NextNumber(-1, 1)
    ).Unit
end

local function GUID()
    return HttpService:GenerateGUID(false)
end

local function Notify(msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="UNCODE v3", Text=msg, Duration=dur or 3})
    end)
end

-- ── Remote cache ──────────────────────────────────────────────────────────────
local UseItemRemote   = nil
local FighterRemote   = nil
local RemotesFolder   = nil

local function CacheRemotes()
    pcall(function()
        local rs = ReplicatedStorage:WaitForChild("Remotes", 5)
        if not rs then return end
        RemotesFolder = rs
        -- Try Replication.Fighter path first (meow.lua style)
        local rep = rs:FindFirstChild("Replication")
        if rep then
            local fig = rep:FindFirstChild("Fighter")
            if fig then
                UseItemRemote = fig:FindFirstChild("UseItem")
                FighterRemote = fig
                return
            end
        end
        -- Fallback: direct Fighter child
        local fig2 = rs:FindFirstChild("Fighter")
        if fig2 then
            UseItemRemote = fig2:FindFirstChild("UseItem")
            FighterRemote = fig2
        end
    end)
end
task.spawn(CacheRemotes)

local function FireUseItem(payload)
    if not UseItemRemote then
        task.spawn(CacheRemotes)
        return false
    end
    local ok = pcall(function() UseItemRemote:FireServer(unpack(payload)) end)
    return ok
end

-- ── Target selection ──────────────────────────────────────────────────────────
local function GetClosestEnemy(origin, maxDist)
    origin = origin or (Camera and Camera.CFrame.Position)
    if not origin then return nil end
    local best, bestDist = nil, maxDist or math.huge
    for _, plr in ipairs(GetEnemies()) do
        local hrp = GetHRP(plr)
        if hrp then
            local d = (hrp.Position - origin).Magnitude
            if d < bestDist then bestDist = d; best = plr end
        end
    end
    return best, bestDist
end

local function GetHitbox(char)
    if not char then return nil end
    return char:FindFirstChild("HitboxHead")
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

-- ── Ragebot: Void Spam ────────────────────────────────────────────────────────
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local function CalculateShotPoint(origin, targetPos, excludeChars)
    RayParams.FilterDescendantsInstances = excludeChars or {}
    local offsets = {
        Vector3.new(0,0,0), Vector3.new(0,8,0), Vector3.new(0,16,0),
        Vector3.new(0,24,0), Vector3.new(0,32,0),
    }
    for _, off in ipairs(offsets) do
        local src = origin + off
        if not Workspace:Raycast(src, targetPos - src, RayParams) then
            return src, off.Y
        end
    end
    return origin, 0
end

local function DoVoidSpam()
    if not Cfg.Rage.VoidSpam then return end
    local myChar = GetChar()
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local now = tick()
    local cooldown = 1 / math.max(Cfg.Rage.SpamRate, 1)
    if now - S.LastAttack < cooldown then return end
    S.LastAttack = now

    local target, _ = GetClosestEnemy(Camera and Camera.CFrame.Position)
    if not target then return end
    local tChar = GetChar(target)
    local tHB   = GetHitbox(tChar)
    if not tHB then return end

    -- Teleport if enabled
    if Cfg.Rage.TpAttack then
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if tHRP then
            local offset = (myHRP.Position - tHRP.Position).Unit * Cfg.Movement.TpOffset
            pcall(function()
                myHRP.CFrame = CFrame.new(tHRP.Position + offset)
            end)
        end
    end

    local aimPos = tHB.Position + RandUnit() * Cfg.Rage.AimRand
    local camCF  = Camera.CFrame
    local shootPt, height = CalculateShotPoint(camCF.Position, aimPos, {myChar, tChar})

    S.AttackNum  = S.AttackNum  + 1
    S.HeavyNum   = S.HeavyNum   + 1

    -- Method 1: try full packet (meow.lua style)
    local fired1 = pcall(function()
        local Util  = require(ReplicatedStorage.Modules.Utility)
        local Enums = require(ReplicatedStorage.Modules.EnumLibrary)
        local FC    = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
        if not FC.LocalFighter then return end
        local item = FC.LocalFighter.EquippedItem
        if not item then return end
        local cd = {}
        cd["\1"] = {
            ["\0"] = Util:EncodeCFrame(CFrame.new(shootPt) * CFrame.Angles(CFrame.lookAt(shootPt, aimPos):ToOrientation())),
            ["\1"] = Util:EncodeCFrame(CFrame.new(aimPos)),
            ["\2"] = tHB,
            ["\3"] = Util:EncodeCFrame(tHB.CFrame:ToObjectSpace(CFrame.new(aimPos))),
        }
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"), Enums:ToEnum("StartShooting"), cd, nil
        )
    end)

    -- Method 2: fallback direct FireServer
    if not fired1 and UseItemRemote then
        pcall(function()
            UseItemRemote:FireServer(
                GUID(),
                {
                    id            = GUID(),
                    position      = aimPos,
                    attackNum     = S.AttackNum,
                    heavyAttackNum= S.HeavyNum,
                    rotation      = tHB.CFrame.Rotation,
                    one           = Vector3.one,
                }
            )
        end)
    end

    -- Spin shot: rotate HRP before attack
    if Cfg.Rage.SpinShot then
        pcall(function()
            local spinYaw = math.rad(tick() * Cfg.Rage.SpinSpeed % 360)
            myHRP.CFrame = CFrame.new(myHRP.Position) * CFrame.Angles(0, spinYaw, 0)
        end)
    end
end

-- God mode: keep Y position underground (unhittable)
local function GodModeHook()
    if not Cfg.Rage.GodMode then return end
    local hrp = GetHRP()
    if not hrp then return end
    if hrp.Position.Y < Cfg.Rage.GodY then return end
    pcall(function()
        local cf = hrp.CFrame
        hrp.CFrame = CFrame.new(cf.X, Cfg.Rage.GodY, cf.Z) * cf.Rotation
    end)
end

-- ── Anti-Aim ──────────────────────────────────────────────────────────────────
local function BindAntiAim()
    if S.AntiAimBound then return end
    S.AntiAimBound = true
    pcall(function()
        RunService:BindToRenderStep("UNCODE_AntiAim", Enum.RenderPriority.Camera.Value, function()
            if not Cfg.AntiAim.Enabled then
                S.AntiAimBound = false
                pcall(function() RunService:UnbindFromRenderStep("UNCODE_AntiAim") end)
                return
            end
            local char = GetChar()
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if Cfg.AntiAim.FloorHide and hrp.Position.Y < 8 then
                pcall(function()
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, -4, 0)
                end)
                return
            end
            local yaw   = math.rad(Cfg.AntiAim.Yaw + Random_:NextNumber(-Cfg.AntiAim.Jitter, Cfg.AntiAim.Jitter))
            local pitch = math.rad(Cfg.AntiAim.Pitch)
            pcall(function()
                hrp.CFrame = CFrame.new(hrp.Position)
                    * CFrame.Angles(0, yaw, 0)
                    * CFrame.Angles(pitch, 0, 0)
            end)
        end)
    end)
end

-- ── Void Hide ────────────────────────────────────────────────────────────────
local function ApplyVoidHide(on)
    local hrp = GetHRP()
    if not hrp then return end
    pcall(function()
        if on then
            hrp.CFrame = CFrame.new(hrp.Position.X, Cfg.VoidHide.Y, hrp.Position.Z)
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- ── Movement ──────────────────────────────────────────────────────────────────
local function BindFly()
    if S.FlyBound then return end
    S.FlyBound = true
    pcall(function()
        RunService:BindToRenderStep("UNCODE_Fly", Enum.RenderPriority.Character.Value + 1, function()
            if not Cfg.Movement.Fly then
                S.FlyBound = false
                pcall(function() RunService:UnbindFromRenderStep("UNCODE_Fly") end)
                local hum = GetHum()
                if hum then pcall(function() hum.PlatformStand = false end) end
                return
            end
            local char = GetChar()
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            hum.PlatformStand = true
            local cam  = Camera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)     then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)     then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)     then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)     then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end
            local spd = Cfg.Movement.FlySpeed
            if move.Magnitude > 0 then move = move.Unit * spd end
            pcall(function()
                hrp.AssemblyLinearVelocity  = move
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end)
    end)
end

local function NoclipLoop()
    if not Cfg.Movement.Noclip then return end
    local char = GetChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
                part.CanTouch   = false
            end)
        end
    end
end

local function SpeedLoop()
    if not Cfg.Movement.SpeedMult then return end
    local hrp = GetHRP()
    if not hrp then return end
    local cam = Camera
    pcall(function()
        local vel = hrp.AssemblyLinearVelocity
        local flat = Vector3.new(vel.X, 0, vel.Z)
        if flat.Magnitude > 0.5 then
            hrp.AssemblyLinearVelocity = Vector3.new(
                flat.Unit.X * flat.Magnitude * Cfg.Movement.SpeedVal,
                vel.Y,
                flat.Unit.Z * flat.Magnitude * Cfg.Movement.SpeedVal
            )
        end
    end)
end

local function SlideBoostLoop()
    if not Cfg.Movement.SlideBoost then return end
    local hum = GetHum()
    local hrp = GetHRP()
    if not hum or not hrp then return end
    pcall(function()
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * Cfg.Movement.SlideMult
        end
    end)
end

local function DoubleJumpCheck()
    if not Cfg.Movement.DoubleJump and not Cfg.Movement.InfJump then return end
    local hum = GetHum()
    local hrp = GetHRP()
    if not hum or not hrp then return end
    local grounded = hum:GetState() == Enum.HumanoidStateType.Running
        or hum:GetState() == Enum.HumanoidStateType.Idle
        or hum:GetState() == Enum.HumanoidStateType.Running
    if grounded then S.JumpsUsed = 0; return end
    local pressed = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local limit = Cfg.Movement.InfJump and 999 or 1
    if pressed and S.JumpsUsed < limit then
        local now = tick()
        if now - S.LastJump > 0.15 then
            S.LastJump  = now
            S.JumpsUsed = S.JumpsUsed + 1
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    hum.JumpPower * Cfg.Movement.JumpHeight,
                    hrp.AssemblyLinearVelocity.Z
                )
            end)
        end
    end
end

-- Long jump
Bind(UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if not Cfg.Movement.LongJump then return end
    if inp.KeyCode ~= Enum.KeyCode.Space then return end
    local hum = GetHum()
    local hrp = GetHRP()
    if not hum or not hrp then return end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Idle then
        local dir = Camera.CFrame.LookVector
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(
                dir.X * Cfg.Movement.LongForce,
                hum.JumpPower * (Cfg.Movement.JumpHeight or 1),
                dir.Z * Cfg.Movement.LongForce
            )
        end)
    end
end))

-- Click TP
Bind(UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if not Cfg.Movement.ClickTP then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    local hrp = GetHRP()
    if not hrp then return end
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit then
        pcall(function() hrp.CFrame = mouse.Hit + Vector3.new(0, 4, 0) end)
    end
end))

-- Teleport to target loop
local function TpToTargetLoop()
    if not Cfg.Movement.TpToTarget then return end
    local now = tick()
    if now - S.LastTP < Cfg.Movement.TpRate then return end
    S.LastTP = now
    local hrp = GetHRP()
    if not hrp then return end
    local enemy, _ = GetClosestEnemy(hrp.Position)
    if not enemy then return end
    local eHRP = GetHRP(enemy)
    if not eHRP then return end
    local offset = (hrp.Position - eHRP.Position)
    if offset.Magnitude < 0.01 then offset = Vector3.new(Cfg.Movement.TpOffset, 0, 0) else
        offset = offset.Unit * Cfg.Movement.TpOffset
    end
    pcall(function()
        hrp.CFrame = CFrame.new(eHRP.Position + offset)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- Auto collect items
local function AutoCollectLoop()
    if not Cfg.Misc.AutoCollect then return end
    local hrp = GetHRP()
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CollectibleItem" or obj.Name == "Collectible" or obj.Name == "GlowOrb" or obj.Name == "XP" then
            pcall(function()
                if obj:IsA("BasePart") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist <= Cfg.Misc.CollectR then
                        hrp.CFrame = CFrame.new(obj.Position)
                    end
                end
            end)
        end
    end
end

-- Anti-AFK
local _afkConn = nil
local function StartAntiAFK()
    if _afkConn then return end
    _afkConn = Bind(RunService.Heartbeat:Connect(function()
        if not Cfg.Misc.AntiAFK then return end
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end))
end

-- ── Hit Effects ───────────────────────────────────────────────────────────────
local SOUND_IDS = {
    sparkle = "5070376932",
    ding    = "5617972474",
    thud    = "4539867272",
    ping    = "5070394352",
}

local targetGui = (type(gethui) == "function" and gethui()) or CoreGui

pcall(function()
    for _, n in ipairs({"UNCODE_V2","UNCODE_V3","UNCODE_ESP","UNCODE_CH","UNCODE_Tracers","UNCODE_HitFX","UNCODE_WM","UNCODE_HUD","UNCODE_FOV"}) do
        local old = targetGui:FindFirstChild(n)
        if old then old:Destroy() end
        local old2 = CoreGui:FindFirstChild(n)
        if old2 then old2:Destroy() end
    end
end)

local HitFXGui = NI("ScreenGui", {Name="UNCODE_HitFX", ResetOnSpawn=false}, targetGui)

local function SpawnDamageMarker(worldPos, damage)
    if not Cfg.Visuals.HitFX or Cfg.Visuals.HitFXType ~= "damage" then return end
    -- Find an adornee near the position
    local closest, closestD = nil, 8
    for _, plr in ipairs(GetEnemies()) do
        local head = (plr.Character or {}) and plr.Character:FindFirstChild("Head")
        if head then
            local d = (head.Position - worldPos).Magnitude
            if d < closestD then closestD = d; closest = head end
        end
    end

    local adornee = closest
    if not adornee then
        -- fallback: screen position
        local x, y, z = W2S(worldPos)
        if not x or z < 0 then return end
        local lbl = NI("TextLabel", {
            Name="HM", Size=UDim2.new(0,60,0,28),
            Position=UDim2.new(0,x-30,0,y-14),
            BackgroundTransparency=1,
            Text="-"..tostring(damage or "?"),
            TextColor3=Color3.fromRGB(255,60,60),
            TextSize=20,
            Font=Enum.Font.Code,
        }, HitFXGui)
        local tween = TweenService:Create(lbl,
            TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position=UDim2.new(0,x-30,0,y-60), TextTransparency=1}
        )
        tween:Play()
        Debris:AddItem(lbl, 1)
        return
    end

    local bg = NI("BillboardGui", {
        Size=UDim2.new(0,80,0,24),
        StudsOffsetWorldSpace=Vector3.new(0, 3.5, 0),
        AlwaysOnTop=true,
        Adornee=adornee,
        ResetOnSpawn=false,
    }, HitFXGui)
    local lbl = NI("TextLabel", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="-"..tostring(damage and math.round(damage) or "HIT"),
        TextColor3=Color3.fromRGB(255,60,60),
        TextSize=22,
        Font=Enum.Font.Fortnite,
        TextStrokeTransparency=0,
    }, bg)
    local tween = TweenService:Create(bg,
        TweenInfo.new(0.85, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        {StudsOffsetWorldSpace=Vector3.new(0,5.5,0)}
    )
    tween:Play()
    Debris:AddItem(bg, 1.1)
end

local function SpawnHitDot(worldPos)
    if not Cfg.Visuals.HitFX or Cfg.Visuals.HitFXType ~= "dot" then return end
    local x, y, z = W2S(worldPos)
    if not x or z < 0 then return end
    local dot = NI("Frame", {
        Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(0,x-5,0,y-5),
        BackgroundColor3=Color3.fromRGB(255,50,50),
        BorderSizePixel=0,
    }, HitFXGui)
    NI("UICorner",{CornerRadius=UDim.new(1,0)},dot)
    local tw = TweenService:Create(dot,
        TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0,x,0,y), BackgroundTransparency=1}
    )
    tw:Play()
    Debris:AddItem(dot, 0.35)
end

local function PlayHitSound()
    if not Cfg.Visuals.HitSound then return end
    local char = GetChar()
    if not char then return end
    local id = SOUND_IDS[Cfg.Visuals.HitSoundFX] or SOUND_IDS.sparkle
    pcall(function()
        local snd = NI("Sound", {SoundId="rbxassetid://"..id, Volume=0.7, RollOffMaxDistance=0}, char:FindFirstChild("HumanoidRootPart") or char)
        snd:Play()
        Debris:AddItem(snd, 2)
    end)
end

local function MuzzleFlash(fromPos, toPos, color)
    if not Cfg.Visuals.HitFX then return end
    local a0 = NI("Attachment",{WorldPosition=fromPos},Workspace.Terrain)
    local a1 = NI("Attachment",{WorldPosition=toPos}, Workspace.Terrain)
    local beam = NI("Beam",{
        Attachment0=a0, Attachment1=a1,
        Width0=0.08, Width1=0.04,
        Color=ColorSequence.new(color or C_ACC),
        LightEmission=1,
        TextureSpeed=12,
        TextureLength=1.5,
    }, Workspace.Terrain)
    task.delay(0.06, function()
        local tw = TweenService:Create(beam, TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Width0=0,Width1=0})
        tw.Completed:Connect(function()
            pcall(function() a0:Destroy() a1:Destroy() end)
        end)
        tw:Play()
    end)
end

-- Hook into hit detection
pcall(function()
    task.delay(6, function()
        local rs = ReplicatedStorage:WaitForChild("Remotes", 8)
        if not rs then return end
        local targets = {
            rs:FindFirstChild("Replication") and rs.Replication:FindFirstChild("Fighter"),
            rs:FindFirstChild("Fighter"),
        }
        for _, fig in ipairs(targets) do
            if fig then
                for _, remote in ipairs(fig:GetChildren()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                        Bind(remote.OnClientEvent:Connect(function(data)
                            if not (Cfg.Visuals.HitFX or Cfg.Visuals.HitSound) then return end
                            pcall(function()
                                local pos, dmg = nil, nil
                                if type(data) == "table" then
                                    pos = data.Position or data.position
                                    dmg = data.Damage  or data.damage
                                end
                                if pos then
                                    SpawnDamageMarker(pos, dmg)
                                    SpawnHitDot(pos)
                                    PlayHitSound()
                                end
                            end)
                        end))
                    end
                end
                break
            end
        end
    end)
end)

-- ── ESP ────────────────────────────────────────────────────────────────────────
local ESPGui = NI("ScreenGui", {Name="UNCODE_ESP", ResetOnSpawn=false}, targetGui)

local function MakeESP(plr)
    if S.ESPObjects[plr] then return end
    local obj = {}

    obj.Box = NI("SelectionBox", {
        Color3=Cfg.ESP.BoxColor, LineThickness=0.035,
        SurfaceTransparency=1, SurfaceColor3=Cfg.ESP.BoxColor,
        SurfaceColor3=Color3.new(0,0,0), SurfaceTransparency=0.95,
    }, Camera)

    obj.NameBB = NI("BillboardGui", {
        Name=plr.Name.."_N", Size=UDim2.new(0,90,0,14),
        AlwaysOnTop=true, ResetOnSpawn=false,
    }, ESPGui)
    NI("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=plr.Name, TextColor3=Cfg.ESP.NameColor,
        TextSize=11, Font=Enum.Font.Code,
    }, obj.NameBB)

    obj.HBBB = NI("BillboardGui",{
        Name=plr.Name.."_HB", Size=UDim2.new(0,5,0,40),
        AlwaysOnTop=true, ResetOnSpawn=false,
    }, ESPGui)
    obj.HBBg = NI("Frame",{Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(30,30,30), BorderSizePixel=0}, obj.HBBB)
    obj.HBFill = NI("Frame",{Size=UDim2.new(1,0,1,0), BackgroundColor3=C_ON, BorderSizePixel=0}, obj.HBBg)

    obj.DistBB = NI("BillboardGui",{
        Name=plr.Name.."_D", Size=UDim2.new(0,60,0,12),
        AlwaysOnTop=true, ResetOnSpawn=false,
    }, ESPGui)
    obj.DistLbl = NI("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="", TextColor3=C_DIM, TextSize=9, Font=Enum.Font.Code,
    }, obj.DistBB)

    S.ESPObjects[plr] = obj
end

local function DestroyESP(plr)
    local obj = S.ESPObjects[plr]
    if not obj then return end
    for _, v in pairs(obj) do pcall(function() if typeof(v)=="Instance" and v.Parent then v:Destroy() end end) end
    S.ESPObjects[plr] = nil
end

local function UpdateESP()
    if not Cfg.ESP.Enabled then
        for plr in pairs(S.ESPObjects) do DestroyESP(plr) end
        return
    end
    local myHRP  = GetHRP()
    local myPos  = myHRP and myHRP.Position
    local target = GetClosestEnemy(Camera and Camera.CFrame.Position)

    for _, plr in ipairs(Players:GetPlayers()) do
        if not IsEnemy(plr) then DestroyESP(plr); goto next end
        local char = GetChar(plr)
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then DestroyESP(plr); goto next end
        local dist = myPos and (hrp.Position - myPos).Magnitude or 0
        if dist > Cfg.ESP.MaxDist then DestroyESP(plr); goto next end

        MakeESP(plr)
        local obj = S.ESPObjects[plr]
        local hum = char:FindFirstChildOfClass("Humanoid")

        -- Box
        obj.Box.Visible  = Cfg.ESP.Box
        obj.Box.Adornee  = Cfg.ESP.Box and char or nil
        obj.Box.Color3   = (plr == target) and Color3.fromRGB(255,60,60) or Cfg.ESP.BoxColor

        -- Name
        obj.NameBB.Visible    = Cfg.ESP.Name
        obj.NameBB.Adornee    = hrp
        obj.NameBB.StudsOffsetWorldSpace = Vector3.new(0,3.5,0)

        -- Health bar
        if Cfg.ESP.Healthbar and hum then
            obj.HBBB.Visible = true
            obj.HBBB.Adornee = hrp
            obj.HBBB.StudsOffsetWorldSpace = Vector3.new(-2,0,0)
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
            obj.HBFill.Size     = UDim2.new(1,0,pct,0)
            obj.HBFill.Position = UDim2.new(0,0,1-pct,0)
            obj.HBFill.BackgroundColor3 = Color3.new(1-pct, pct*0.85, 0.05)
        else
            obj.HBBB.Visible = false
        end

        -- Distance
        if Cfg.ESP.Distance then
            obj.DistBB.Visible = true
            obj.DistBB.Adornee = hrp
            obj.DistBB.StudsOffsetWorldSpace = Vector3.new(0,-2.8,0)
            obj.DistLbl.Text = math.floor(dist).."m"
            obj.DistLbl.TextColor3 = dist < 100 and Color3.fromRGB(255,80,80) or C_DIM
        else
            obj.DistBB.Visible = false
        end
        ::next::
    end

    for plr in pairs(S.ESPObjects) do
        if not plr or not plr.Parent then DestroyESP(plr) end
    end
end

Bind(Players.PlayerRemoving:Connect(function(pl) DestroyESP(pl) end))

-- ── Chams ─────────────────────────────────────────────────────────────────────
local function ApplyChams(char, on)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            pcall(function()
                if on then
                    if not p:GetAttribute("_oc") then
                        p:SetAttribute("_oc", p.Color)
                        p:SetAttribute("_om", tostring(p.Material))
                        p:SetAttribute("_ot", p.Transparency)
                    end
                    p.Color = Cfg.Visuals.ChamsColor
                    if Enum.Material[Cfg.Visuals.ChamsMat] then p.Material = Enum.Material[Cfg.Visuals.ChamsMat] end
                    p.Transparency = 1 - Cfg.Visuals.ChamsTrans / 100
                else
                    local c = p:GetAttribute("_oc")
                    if c and typeof(c)=="Color3" then p.Color = c end
                    local m = p:GetAttribute("_om")
                    if m and Enum.Material[m] then p.Material = Enum.Material[m] end
                    local t = p:GetAttribute("_ot")
                    if type(t)=="number" then p.Transparency = t end
                    p:SetAttribute("_oc",nil); p:SetAttribute("_om",nil); p:SetAttribute("_ot",nil)
                end
            end)
        end
    end
end

local function UpdateChams()
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            local char = GetChar(plr)
            if char then
                local want = Cfg.Visuals.Chams
                if want ~= S.ChamsMap[plr] then
                    S.ChamsMap[plr] = want
                    ApplyChams(char, want)
                end
            end
        end
    end
end

-- ── Aura ──────────────────────────────────────────────────────────────────────
local AuraPresets = {
    ["Cyber Blue"]   = {Color3.fromRGB(0,170,255),   Color3.fromRGB(0,255,255)},
    ["Blood Red"]    = {Color3.fromRGB(255,20,40),   Color3.fromRGB(255,120,0)},
    ["Venom Green"]  = {Color3.fromRGB(0,255,120),   Color3.fromRGB(180,255,0)},
    ["Royal Purple"] = {Color3.fromRGB(150,0,255),   Color3.fromRGB(255,0,200)},
    ["Shadow"]       = {Color3.fromRGB(20,20,25),    Color3.fromRGB(120,0,255)},
    ["Gold"]         = {Color3.fromRGB(255,200,0),   Color3.fromRGB(255,140,0)},
}

local function ClearAura()
    for _, v in ipairs(S.AuraObjs) do pcall(function() if typeof(v)=="Instance" and v.Parent then v:Destroy() end end) end
    S.AuraObjs   = {}
    S.AuraActive = false
    S.AuraRing   = nil
    S.AuraHRP    = nil
end

local function BuildAura()
    ClearAura()
    if not Cfg.Visuals.Aura then return end
    local char = GetChar()
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end

    local pr = AuraPresets[Cfg.Visuals.AuraMode] or AuraPresets["Cyber Blue"]
    local main, sub = pr[1], pr[2]
    if Cfg.Visuals.AuraRGB then
        S.Hue = (S.Hue + 0.05) % 1
        main = Color3.fromHSV(S.Hue, 0.95, 1)
        sub  = Color3.fromHSV((S.Hue + 0.18) % 1, 0.9, 1)
    end

    local folder = NI("Folder",{Name="UNCODE_Aura"},char)
    local pl = NI("PointLight",{Color=main, Brightness=2.5, Range=18, Shadows=false}, hrp)
    local a0 = NI("Attachment",{Position=Vector3.new(0,-1.5,0)}, hrp)
    local a1 = NI("Attachment",{Position=Vector3.new(0,2.8,0)},  hrp)
    local pe = NI("ParticleEmitter",{
        Texture       = "rbxassetid://243098098",
        Color         = ColorSequence.new({ColorSequenceKeypoint.new(0,sub), ColorSequenceKeypoint.new(1,main)}),
        Transparency  = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,1)}),
        Size          = NumberSequence.new({NumberSequenceKeypoint.new(0,0.7), NumberSequenceKeypoint.new(1,0.06)}),
        Speed         = NumberRange.new(3,7), Lifetime=NumberRange.new(0.6,1.3), Rate=30,
        EmissionDirection=Enum.NormalId.Top, SpreadAngle=Vector2.new(40,40),
        Acceleration  = Vector3.new(0,7,0), LightEmission=1,
    }, a0)

    local ring = NI("Part",{
        Name="UNCODE_Ring", Shape=Enum.PartType.Cylinder,
        Size=Vector3.new(0.18, 7, 7),
        Transparency=0.5, CanCollide=false, CanQuery=false, CanTouch=false,
        Anchored=true, Massless=true, Material=Enum.Material.Neon, Color=main,
    }, folder)

    for _, n in ipairs({"Left Arm","Right Arm","Left Leg","Right Leg"}) do
        local limb = char:FindFirstChild(n)
        if limb and limb:IsA("BasePart") then
            local t0 = NI("Attachment",{Position=Vector3.new(0,0.8,0)},limb)
            local t1 = NI("Attachment",{Position=Vector3.new(0,-0.8,0)},limb)
            local tr = NI("Trail",{
                Color=ColorSequence.new({ColorSequenceKeypoint.new(0,sub),ColorSequenceKeypoint.new(1,main)}),
                Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(1,1)}),
                Lifetime=0.5, LightEmission=1, LightInfluence=0,
                Attachment0=t0, Attachment1=t1,
            }, limb)
            for _, o in ipairs({t0,t1,tr}) do table.insert(S.AuraObjs, o) end
        end
    end

    for _, o in ipairs({folder,pl,a0,a1,pe,ring}) do table.insert(S.AuraObjs, o) end
    S.AuraRing   = ring
    S.AuraHRP    = hrp
    S.AuraActive = true
end

-- ── Crosshair ─────────────────────────────────────────────────────────────────
local CrossGui = NI("ScreenGui",{Name="UNCODE_CH",ResetOnSpawn=false}, targetGui)
for i = 1,4 do
    S.CrossLines[i] = NI("Frame",{BackgroundColor3=C_WHT, BorderSizePixel=0, Visible=false}, CrossGui)
end

local function UpdateCrosshair()
    local en = Cfg.Visuals.Crosshair
    local vp = Camera.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local g, sz  = Cfg.Visuals.CrossGap, Cfg.Visuals.CrossSize
    local offs = {
        {x=cx-1, y=cy-g-sz, w=2,  h=sz},
        {x=cx-1, y=cy+g,    w=2,  h=sz},
        {x=cx-g-sz, y=cy-1, w=sz, h=2},
        {x=cx+g,    y=cy-1, w=sz, h=2},
    }
    for i,l in ipairs(S.CrossLines) do
        l.Visible = en
        if en then
            local o = offs[i]
            l.Position = UDim2.new(0,o.x,0,o.y)
            l.Size     = UDim2.new(0,o.w,0,o.h)
            l.BackgroundColor3 = C_WHT
        end
    end
end

-- ── FOV Circle ────────────────────────────────────────────────────────────────
local FOVGui = NI("ScreenGui",{Name="UNCODE_FOV",ResetOnSpawn=false}, targetGui)
S.FOVDraw = NI("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false}, FOVGui)
NI("UIStroke",{Color=C_BOR,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, S.FOVDraw)
NI("UICorner",{CornerRadius=UDim.new(1,0)}, S.FOVDraw)

local function UpdateFOVCircle()
    local en = Cfg.Visuals.FOVCircle
    S.FOVDraw.Visible = en
    if en then
        local r  = Cfg.Visuals.FOVRadius
        local vp = Camera.ViewportSize
        S.FOVDraw.Size     = UDim2.new(0,r*2,0,r*2)
        S.FOVDraw.Position = UDim2.new(0,vp.X/2-r,0,vp.Y/2-r)
    end
end

-- ── Tracers ───────────────────────────────────────────────────────────────────
local TracerGui = NI("ScreenGui",{Name="UNCODE_Tracers",ResetOnSpawn=false}, targetGui)

local function DrawTracer(fromWorld, toWorld, color)
    if not Cfg.Visuals.Tracers then return end
    local now = os.clock()
    if now - S.LastTracer < 0.04 then return end
    S.LastTracer = now
    local x1,y1,z1 = W2S(fromWorld)
    local x2,y2,z2 = W2S(toWorld)
    if not x1 or not x2 or z1 < 0 or z2 < 0 then return end
    local dx, dy   = x2-x1, y2-y1
    local dist      = math.sqrt(dx*dx + dy*dy)
    local angle     = math.deg(math.atan2(dy, dx))
    local line = NI("Frame",{
        BackgroundColor3=color or C_ACC,
        BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,0.5),
        ZIndex=4,
        Position=UDim2.new(0,x1,0,y1),
        Size=UDim2.new(0,dist,0,1),
        Rotation=angle,
    }, TracerGui)
    Debris:AddItem(line, 0.1)
end

-- ── Watermark ────────────────────────────────────────────────────────────────
local WmGui   = NI("ScreenGui",{Name="UNCODE_WM",ResetOnSpawn=false}, targetGui)
local WmFrame = NI("Frame",{
    Size=UDim2.new(0,240,0,22), Position=UDim2.new(1,-248,0,4),
    BackgroundColor3=C_PANEL, BorderColor3=C_BOR, BorderSizePixel=1,
    Visible=Cfg.Misc.Watermark,
}, WmGui)
S.WmLabel = NI("TextLabel",{
    Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,6,0,0),
    BackgroundTransparency=1, Text="UNCODE v3 | Rivals",
    TextColor3=C_ACC2, TextSize=11, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
}, WmFrame)

-- ── Target HUD ───────────────────────────────────────────────────────────────
local HUDGui = NI("ScreenGui",{Name="UNCODE_HUD",ResetOnSpawn=false}, targetGui)
local HUDFrame = NI("Frame",{
    Size=UDim2.new(0,180,0,44), Position=UDim2.new(0.5,-90,1,-55),
    BackgroundColor3=C_PANEL, BorderColor3=C_BOR, BorderSizePixel=1,
    Visible=false,
}, HUDGui)
local HUDNameLbl = NI("TextLabel",{
    Size=UDim2.new(1,-8,0,18), Position=UDim2.new(0,4,0,2),
    BackgroundTransparency=1, Text="", TextColor3=C_WHT,
    TextSize=11, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left,
}, HUDFrame)
local HUDHPBar = NI("Frame",{Size=UDim2.new(1,-8,0,10), Position=UDim2.new(0,4,0,22),
    BackgroundColor3=Color3.fromRGB(40,40,40), BorderSizePixel=0}, HUDFrame)
local HUDHPFill = NI("Frame",{Size=UDim2.new(1,0,1,0), BackgroundColor3=C_ON, BorderSizePixel=0}, HUDHPBar)
local HUDDistLbl = NI("TextLabel",{
    Size=UDim2.new(1,-8,0,10), Position=UDim2.new(0,4,0,34),
    BackgroundTransparency=1, Text="", TextColor3=C_DIM,
    TextSize=9, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left,
}, HUDFrame)

local function UpdateTargetHUD()
    if not Cfg.ESP.TargetHUD then HUDFrame.Visible = false return end
    local myHRP = GetHRP()
    if not myHRP then HUDFrame.Visible = false return end
    local enemy, dist = GetClosestEnemy(myHRP.Position)
    if not enemy then HUDFrame.Visible = false return end
    local eChar = GetChar(enemy)
    local eHum  = eChar and eChar:FindFirstChildOfClass("Humanoid")
    if not eHum then HUDFrame.Visible = false return end
    HUDFrame.Visible   = true
    HUDNameLbl.Text    = enemy.Name
    local pct = math.clamp(eHum.Health / math.max(eHum.MaxHealth,1), 0, 1)
    HUDHPFill.Size     = UDim2.new(pct,0,1,0)
    HUDHPFill.BackgroundColor3 = Color3.new(1-pct, pct*0.85, 0.05)
    HUDDistLbl.Text    = math.floor(dist or 0).."m  |  HP: "..math.floor(eHum.Health)
end

-- ── Main UI ───────────────────────────────────────────────────────────────────
local WIN_W, WIN_H = 440, 340
local ScreenGui = NI("ScreenGui",{Name="UNCODE_V3",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, targetGui)
getgenv().UNCODE_GUI = ScreenGui

local MF = NI("Frame",{
    Name="MainFrame", Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    BackgroundColor3=C_PANEL, BorderColor3=C_BOR, BorderSizePixel=2,
    Active=true, Draggable=true,
}, ScreenGui)

-- Title bar
local TB = NI("Frame",{Size=UDim2.new(1,0,0,28), BackgroundColor3=C_BG, BorderSizePixel=0}, MF)
NI("TextLabel",{
    Size=UDim2.new(1,-45,1,0), Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1, Text="UNCODE v3 | Rivals HvH",
    TextColor3=C_WHT, TextSize=13, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
}, TB)
local MinBtn = NI("TextButton",{
    Size=UDim2.new(0,38,1,0), Position=UDim2.new(1,-38,0,0),
    BackgroundColor3=C_BTN, BorderSizePixel=0,
    Text="_", TextColor3=C_DIM, TextSize=14, Font=Enum.Font.Code,
}, TB)
local UIVisible = true
MinBtn.MouseButton1Click:Connect(function()
    UIVisible = not UIVisible
    MF.Size   = UIVisible and UDim2.new(0,WIN_W,0,WIN_H) or UDim2.new(0,WIN_W,0,28)
    MinBtn.Text = UIVisible and "_" or "^"
end)

-- Tab system
local TABS = {}
local ActiveTab = nil
local TAB_NAMES = {"RAGE","ESP","VISUAL","MOVE","MISC"}
local TAB_W = WIN_W / #TAB_NAMES
local TabBar = NI("Frame",{Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,28), BackgroundColor3=C_BG, BorderSizePixel=0}, MF)
local Content = NI("Frame",{
    Size=UDim2.new(1,0,1,-(28+24)), Position=UDim2.new(0,0,0,28+24),
    BackgroundTransparency=1, BorderSizePixel=0,
}, MF)

local function SelectTab(name)
    if ActiveTab==name then return end
    ActiveTab = name
    for n,t in pairs(TABS) do
        t.Page.Visible = (n==name)
        t.Btn.BackgroundColor3 = (n==name) and C_ACC or C_BTN
        t.Btn.TextColor3 = (n==name) and C_WHT or C_DIM
    end
end

for i, name in ipairs(TAB_NAMES) do
    local page = NI("ScrollingFrame",{
        Name=name.."_P", Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=C_BOR,
        Visible=false, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
    }, Content)
    NI("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},page)
    NI("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3)},page)
    local btn = NI("TextButton",{
        Size=UDim2.new(0,TAB_W,1,0), Position=UDim2.new(0,(i-1)*TAB_W,0,0),
        BackgroundColor3=C_BTN, BorderSizePixel=0,
        Text=name, TextColor3=C_DIM, TextSize=10, Font=Enum.Font.Code,
    }, TabBar)
    TABS[name]={Btn=btn, Page=page}
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end
SelectTab("RAGE")

-- ── Control builders ──────────────────────────────────────────────────────────
local ORD = 0
local function NextOrd() ORD=ORD+1 return ORD end

local function Section(page, label)
    NI("TextLabel",{
        Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
        Text="── "..label.." ──", TextColor3=C_ACC2,
        TextSize=10, Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=NextOrd(),
    }, page)
end

local function Toggle(page, label, get, set)
    local row = NI("Frame",{
        Size=UDim2.new(1,0,0,24), BackgroundColor3=C_BTN,
        BorderColor3=Color3.fromRGB(28,28,28), BorderSizePixel=1,
        LayoutOrder=NextOrd(),
    }, page)
    NI("TextLabel",{
        Size=UDim2.new(1,-56,1,0), Position=UDim2.new(0,7,0,0),
        BackgroundTransparency=1, Text=label, TextColor3=C_TXT,
        TextSize=11, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local btn = NI("TextButton",{
        Size=UDim2.new(0,46,0,18), Position=UDim2.new(1,-50,0.5,-9),
        BorderSizePixel=0, TextSize=10, Font=Enum.Font.Code,
        BackgroundColor3=get() and C_ON or C_OFF,
        Text=get() and "ON" or "OFF",
        TextColor3=get() and C_WHT or C_DIM,
    }, row)
    local function rf()
        local v=get()
        btn.BackgroundColor3=v and C_ON or C_OFF
        btn.Text=v and "ON" or "OFF"
        btn.TextColor3=v and C_WHT or C_DIM
    end
    btn.MouseButton1Click:Connect(function() set(not get()); rf() end)
    return rf
end

local function Slider(page, label, mn, mx, get, set)
    local row = NI("Frame",{
        Size=UDim2.new(1,0,0,26), BackgroundColor3=C_BTN,
        BorderColor3=Color3.fromRGB(28,28,28), BorderSizePixel=1,
        LayoutOrder=NextOrd(),
    }, page)
    NI("TextLabel",{
        Size=UDim2.new(0,72,1,0), Position=UDim2.new(0,7,0,0),
        BackgroundTransparency=1, Text=label, TextColor3=C_TXT,
        TextSize=10, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local track = NI("Frame",{
        Size=UDim2.new(1,-90,0,5), Position=UDim2.new(0,78,0.5,-2.5),
        BackgroundColor3=C_OFF, BorderSizePixel=0,
    }, row)
    local fill = NI("Frame",{BackgroundColor3=C_ACC, BorderSizePixel=0, Size=UDim2.new(0,0,1,0)}, track)
    local valL = NI("TextLabel",{
        Size=UDim2.new(0,38,1,0), Position=UDim2.new(1,-40,0,0),
        BackgroundTransparency=1, Text=tostring(get()),
        TextColor3=C_DIM, TextSize=10, Font=Enum.Font.Code,
    }, row)
    local function sv(v)
        v = math.clamp(type(v)=="number" and math.round(v) or mn, mn, mx)
        set(v)
        fill.Size = UDim2.new((v-mn)/(mx-mn),0,1,0)
        valL.Text = tostring(v)
    end
    sv(get())
    local drag = false
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
    track.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    Bind(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local ab = track.AbsolutePosition
            local sz = track.AbsoluteSize
            sv(mn + math.clamp((i.Position.X-ab.X)/sz.X,0,1) * (mx-mn))
        end
    end))
end

-- ── Populate RAGE tab ─────────────────────────────────────────────────────────
do
    local p = TABS["RAGE"].Page
    Section(p,"Ragebot")
    Toggle(p,"Ragebot Enabled", function() return Cfg.Rage.Enabled end, function(v) Cfg.Rage.Enabled=v end)
    Toggle(p,"Void Spam",       function() return Cfg.Rage.VoidSpam end, function(v) Cfg.Rage.VoidSpam=v end)
    Toggle(p,"TP + Attack",     function() return Cfg.Rage.TpAttack end, function(v) Cfg.Rage.TpAttack=v end)
    Toggle(p,"Spin Shot",       function() return Cfg.Rage.SpinShot end, function(v) Cfg.Rage.SpinShot=v end)
    Slider(p,"Spam Rate",1,30,  function() return Cfg.Rage.SpamRate end, function(v) Cfg.Rage.SpamRate=v end)
    Slider(p,"Aim Rand",0,100,  function() return math.floor(Cfg.Rage.AimRand*100) end, function(v) Cfg.Rage.AimRand=v/100 end)
    Section(p,"Anti-Aim")
    Toggle(p,"Anti-Aim",        function() return Cfg.AntiAim.Enabled end, function(v) Cfg.AntiAim.Enabled=v end)
    Slider(p,"Pitch",-90,90,    function() return Cfg.AntiAim.Pitch end,  function(v) Cfg.AntiAim.Pitch=v end)
    Slider(p,"Yaw",0,360,       function() return Cfg.AntiAim.Yaw end,    function(v) Cfg.AntiAim.Yaw=v end)
    Slider(p,"Jitter",0,90,     function() return Cfg.AntiAim.Jitter end, function(v) Cfg.AntiAim.Jitter=v end)
    Toggle(p,"Floor Hide",      function() return Cfg.AntiAim.FloorHide end, function(v) Cfg.AntiAim.FloorHide=v end)
    Section(p,"God Mode / Void")
    Toggle(p,"God Mode (Under Map)", function() return Cfg.Rage.GodMode end, function(v) Cfg.Rage.GodMode=v end)
    Toggle(p,"Void Hide",       function() return Cfg.VoidHide.Enabled end, function(v) Cfg.VoidHide.Enabled=v end)
    Slider(p,"Void Y",0,100,    function() return math.floor(Cfg.VoidHide.Y/1e8) end, function(v) Cfg.VoidHide.Y=v*1e8 end)
end

-- ── Populate ESP tab ──────────────────────────────────────────────────────────
do
    local p = TABS["ESP"].Page
    Section(p,"ESP")
    Toggle(p,"ESP Enabled",   function() return Cfg.ESP.Enabled end,   function(v) Cfg.ESP.Enabled=v end)
    Toggle(p,"Box",           function() return Cfg.ESP.Box end,       function(v) Cfg.ESP.Box=v end)
    Toggle(p,"Name",          function() return Cfg.ESP.Name end,      function(v) Cfg.ESP.Name=v end)
    Toggle(p,"Health Bar",    function() return Cfg.ESP.Healthbar end, function(v) Cfg.ESP.Healthbar=v end)
    Toggle(p,"Distance",      function() return Cfg.ESP.Distance end,  function(v) Cfg.ESP.Distance=v end)
    Toggle(p,"Skeleton",      function() return Cfg.ESP.Skeleton end,  function(v) Cfg.ESP.Skeleton=v end)
    Toggle(p,"Team Check",    function() return Cfg.ESP.TeamCheck end, function(v) Cfg.ESP.TeamCheck=v end)
    Toggle(p,"Target HUD",    function() return Cfg.ESP.TargetHUD end, function(v) Cfg.ESP.TargetHUD=v HUDFrame.Visible=v end)
    Slider(p,"Max Dist",100,3000, function() return Cfg.ESP.MaxDist end, function(v) Cfg.ESP.MaxDist=v end)
end

-- ── Populate VISUAL tab ───────────────────────────────────────────────────────
do
    local p = TABS["VISUAL"].Page
    Section(p,"Aura")
    Toggle(p,"Aura",         function() return Cfg.Visuals.Aura end,      function(v) Cfg.Visuals.Aura=v; if not v then ClearAura() end end)
    Toggle(p,"Aura RGB",     function() return Cfg.Visuals.AuraRGB end,   function(v) Cfg.Visuals.AuraRGB=v end)
    Section(p,"Tracers")
    Toggle(p,"Tracers",      function() return Cfg.Visuals.Tracers end,   function(v) Cfg.Visuals.Tracers=v end)
    Section(p,"Crosshair")
    Toggle(p,"Crosshair",    function() return Cfg.Visuals.Crosshair end, function(v) Cfg.Visuals.Crosshair=v end)
    Slider(p,"CH Gap",2,30,  function() return Cfg.Visuals.CrossGap end,  function(v) Cfg.Visuals.CrossGap=v end)
    Slider(p,"CH Size",5,50, function() return Cfg.Visuals.CrossSize end, function(v) Cfg.Visuals.CrossSize=v end)
    Section(p,"FOV Circle")
    Toggle(p,"FOV Circle",   function() return Cfg.Visuals.FOVCircle end, function(v) Cfg.Visuals.FOVCircle=v end)
    Slider(p,"FOV Radius",30,400,function() return Cfg.Visuals.FOVRadius end,function(v) Cfg.Visuals.FOVRadius=v end)
    Section(p,"Chams")
    Toggle(p,"Chams",        function() return Cfg.Visuals.Chams end,     function(v) Cfg.Visuals.Chams=v end)
    Slider(p,"Chams Trans",0,100,function() return Cfg.Visuals.ChamsTrans end,function(v) Cfg.Visuals.ChamsTrans=v end)
    Section(p,"Hit Effects")
    Toggle(p,"Hit FX",       function() return Cfg.Visuals.HitFX end,    function(v) Cfg.Visuals.HitFX=v end)
    Toggle(p,"Hit Sound",    function() return Cfg.Visuals.HitSound end, function(v) Cfg.Visuals.HitSound=v end)
    Section(p,"World")
    Toggle(p,"World FX (Night)",function() return Cfg.Visuals.WorldFX end,function(v)
        Cfg.Visuals.WorldFX=v
        pcall(function()
            if v then
                Lighting.Ambient=Color3.fromRGB(40,80,255)
                Lighting.Brightness=3.8
                Lighting.ClockTime=0
            else
                Lighting.Ambient=Color3.fromRGB(127,127,127)
                Lighting.Brightness=1
                Lighting.ClockTime=14
            end
        end)
    end)
    Toggle(p,"Fullbright",   function() return Cfg.Visuals.Fullbright end, function(v)
        Cfg.Visuals.Fullbright=v
        pcall(function() Lighting.FogEnd = v and 1e9 or 100000 end)
        pcall(function() Lighting.Brightness = v and 10 or 1 end)
    end)
end

-- ── Populate MOVE tab ─────────────────────────────────────────────────────────
do
    local p = TABS["MOVE"].Page
    Section(p,"Flight & Noclip")
    Toggle(p,"Fly (WASD+Space)",function() return Cfg.Movement.Fly end, function(v)
        Cfg.Movement.Fly=v
        if v then BindFly() end
    end)
    Slider(p,"Fly Speed",10,300,function() return Cfg.Movement.FlySpeed end,function(v) Cfg.Movement.FlySpeed=v end)
    Toggle(p,"Noclip",       function() return Cfg.Movement.Noclip end,    function(v) Cfg.Movement.Noclip=v end)
    Section(p,"Speed")
    Toggle(p,"Speed Mult",   function() return Cfg.Movement.SpeedMult end, function(v) Cfg.Movement.SpeedMult=v end)
    Slider(p,"Speed x",1,10,  function() return math.floor(Cfg.Movement.SpeedVal) end,function(v) Cfg.Movement.SpeedVal=v end)
    Toggle(p,"Slide Boost",  function() return Cfg.Movement.SlideBoost end,function(v) Cfg.Movement.SlideBoost=v end)
    Slider(p,"Slide x",1,10,  function() return math.floor(Cfg.Movement.SlideMult) end,function(v) Cfg.Movement.SlideMult=v end)
    Section(p,"Jump")
    Toggle(p,"Double Jump",  function() return Cfg.Movement.DoubleJump end,function(v) Cfg.Movement.DoubleJump=v end)
    Toggle(p,"Inf Jump",     function() return Cfg.Movement.InfJump end,   function(v) Cfg.Movement.InfJump=v end)
    Toggle(p,"Long Jump",    function() return Cfg.Movement.LongJump end,  function(v) Cfg.Movement.LongJump=v end)
    Slider(p,"Jump Height",1,5,function() return math.floor(Cfg.Movement.JumpHeight) end,function(v) Cfg.Movement.JumpHeight=v end)
    Slider(p,"Long Force",50,500,function() return Cfg.Movement.LongForce end,function(v) Cfg.Movement.LongForce=v end)
    Section(p,"Teleport")
    Toggle(p,"Click TP (RMB)",function() return Cfg.Movement.ClickTP end, function(v) Cfg.Movement.ClickTP=v end)
    Toggle(p,"TP to Target",  function() return Cfg.Movement.TpToTarget end,function(v) Cfg.Movement.TpToTarget=v end)
    Slider(p,"TP Rate",1,20,  function() return math.floor(1/Cfg.Movement.TpRate) end,function(v) Cfg.Movement.TpRate=1/v end)
    Slider(p,"TP Offset",1,15,function() return Cfg.Movement.TpOffset end,function(v) Cfg.Movement.TpOffset=v end)
end

-- ── Populate MISC tab ─────────────────────────────────────────────────────────
do
    local p = TABS["MISC"].Page
    Section(p,"UI")
    Toggle(p,"Watermark",    function() return Cfg.Misc.Watermark end, function(v) Cfg.Misc.Watermark=v; WmFrame.Visible=v end)
    Section(p,"Performance")
    Toggle(p,"Unlock FPS",   function() return Cfg.Misc.UnlockFPS end, function(v)
        Cfg.Misc.UnlockFPS=v
        pcall(function() if v then setfpscap(Cfg.Misc.TargetFPS) else setfpscap(60) end end)
    end)
    Slider(p,"FPS Cap",30,240,function() return Cfg.Misc.TargetFPS end,function(v) Cfg.Misc.TargetFPS=v; if Cfg.Misc.UnlockFPS then pcall(setfpscap,v) end end)
    Section(p,"Utility")
    Toggle(p,"Anti-AFK",     function() return Cfg.Misc.AntiAFK end,  function(v) Cfg.Misc.AntiAFK=v; StartAntiAFK() end)
    Toggle(p,"Auto Collect", function() return Cfg.Misc.AutoCollect end,function(v) Cfg.Misc.AutoCollect=v end)
    Slider(p,"Collect Radius",20,500,function() return Cfg.Misc.CollectR end,function(v) Cfg.Misc.CollectR=v end)
end

-- ── Hotkey: Insert = toggle UI ────────────────────────────────────────────────
Bind(UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
    -- Numpad0 = toggle Rage quick
    if inp.KeyCode == Enum.KeyCode.KeypadZero then
        Cfg.Rage.Enabled = not Cfg.Rage.Enabled
        Notify("Ragebot: "..(Cfg.Rage.Enabled and "ON" or "OFF"))
    end
    -- Numpad. = toggle Void Spam
    if inp.KeyCode == Enum.KeyCode.KeypadPeriod then
        Cfg.Rage.VoidSpam = not Cfg.Rage.VoidSpam
        Notify("Void Spam: "..(Cfg.Rage.VoidSpam and "ON" or "OFF"))
    end
    -- F5 = rebuild aura
    if inp.KeyCode == Enum.KeyCode.F5 then
        ClearAura()
        if Cfg.Visuals.Aura then task.spawn(BuildAura) end
    end
end))

-- ── Character reload hooks ────────────────────────────────────────────────────
local function OnCharAdded()
    ClearAura()
    S.ChamsMap = {}
    S.AntiAimBound = false
    S.FlyBound     = false
    S.JumpsUsed    = 0
    S.LastJump     = 0
end
if LocalPlayer.Character then OnCharAdded() end
Bind(LocalPlayer.CharacterAdded:Connect(OnCharAdded))

-- ── Main loop ─────────────────────────────────────────────────────────────────
local t_esp     = 0
local t_chams   = 0
local t_aura    = 0
local t_rage    = 0
local t_move    = 0
local t_util    = 0
local t_hudup   = 0
local t_wm      = 0

Bind(RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Rage (high freq)
    if now - t_rage > 1 / math.max(Cfg.Rage.SpamRate, 1) then
        t_rage = now
        if Cfg.Rage.Enabled then pcall(DoVoidSpam) end
        pcall(GodModeHook)
        if Cfg.VoidHide.Enabled then pcall(ApplyVoidHide, true) end
    end

    -- Anti-aim bind check
    if Cfg.AntiAim.Enabled and not S.AntiAimBound then pcall(BindAntiAim) end

    -- Fly bind check
    if Cfg.Movement.Fly and not S.FlyBound then pcall(BindFly) end

    -- Movement (8Hz)
    if now - t_move > 0.125 then
        t_move = now
        pcall(NoclipLoop)
        pcall(SpeedLoop)
        pcall(SlideBoostLoop)
        pcall(DoubleJumpCheck)
        pcall(TpToTargetLoop)
        pcall(AutoCollectLoop)
    end

    -- ESP (8Hz)
    if now - t_esp > 0.125 then
        t_esp = now
        pcall(UpdateESP)
    end

    -- Chams (4Hz)
    if now - t_chams > 0.25 then
        t_chams = now
        pcall(UpdateChams)
    end

    -- Aura (2Hz)
    if now - t_aura > 0.5 then
        t_aura = now
        if Cfg.Visuals.Aura then
            if not S.AuraActive then pcall(BuildAura) end
            if S.AuraRing and S.AuraHRP and S.AuraRing.Parent then
                pcall(function()
                    S.AuraRing.CFrame = S.AuraHRP.CFrame
                        * CFrame.new(0,-3.1,0)
                        * CFrame.Angles(0,0,math.rad(90))
                end)
            end
            if Cfg.Visuals.AuraRGB then pcall(BuildAura) end
        else
            if S.AuraActive then ClearAura() end
        end
    end

    -- Utility (1Hz)
    if now - t_util > 1 then
        t_util = now
    end
end))

-- Render stepped (per frame)
Bind(RunService.RenderStepped:Connect(function()
    pcall(UpdateCrosshair)
    pcall(UpdateFOVCircle)

    -- Tracers (enemies -> bottom center)
    if Cfg.Visuals.Tracers then
        local vp = Camera.ViewportSize
        local myHRP = GetHRP()
        if myHRP then
            for _, plr in ipairs(GetEnemies()) do
                local hrp = GetHRP(plr)
                if hrp then
                    DrawTracer(myHRP.Position, hrp.Position)
                end
            end
        end
    end

    -- Watermark
    if S.WmLabel and Cfg.Misc.Watermark then
        local rage_s = Cfg.Rage.Enabled and (Cfg.Rage.VoidSpam and "RAGE" or "ON") or "OFF"
        local enemy, dist = GetClosestEnemy(Camera and Camera.CFrame.Position)
        local tgt_s = enemy and enemy.Name or "-"
        S.WmLabel.Text = ("UNCODE v3 | Rage:%s | Tgt:%s"):format(rage_s, tgt_s:sub(1,10))
    end

    -- Target HUD
    pcall(UpdateTargetHUD)
end))

print("[UNCODE v3] ===== LOADED =====")
print("[UNCODE v3] Keys: Insert=UI, Numpad0=Rage toggle, Numpad.=VoidSpam, F5=Rebuild Aura")
Notify("UNCODE v3 loaded | Insert = toggle menu", 5)
