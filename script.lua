-- UNCODE v4 | Rivals HvH | All features integrated
-- DO NOT use Japanese in code or comments

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

pcall(setthreadidentity, 8)
pcall(setthreadidentity, 7)
pcall(setthreadidentity, 6)
pcall(setthreadidentity, 3)

local C_BG    = Color3.fromRGB(10, 10, 10)
local C_PANEL = Color3.fromRGB(15, 15, 15)
local C_BTN   = Color3.fromRGB(22, 22, 22)
local C_BOR   = Color3.fromRGB(0,  100, 255)
local C_ACC   = Color3.fromRGB(40, 120, 255)
local C_ON    = Color3.fromRGB(0,  200, 80)
local C_OFF   = Color3.fromRGB(55, 55,  55)
local C_TXT   = Color3.fromRGB(220, 220, 220)

local Cfg = {
    Rage = {
        Enabled=false, VoidSpam=false, SpamRate=10, AimRand=0.3,
        TpAttack=false, GodMode=false, GodY=10, SpinShot=false, SpinSpeed=720,
        TargetMode="Closest", PredictLead=0.12,
    },
    AntiAim = {
        Enabled=false, Mode="Spin", Pitch=0, Yaw=180, Jitter=30, SpinSpeed=360,
        BreatheEffect=false, BreatheSpeed=1.0, BreatheAmp=20,
        MicroJitter=false, MicroJitterAmp=5, MicroJitterSpeed=10,
        DesyncMode=false, DesyncOffset=90, RandomFlip=false, FlipChance=0.05,
        EnhancedMode=false, ChaosMode=false, ChaosInterval=0.5,
        MultiAxisSpin=false, LookAtRandom=false, LookInterval=1.0,
        RollEnabled=false, RollSpeed=180, CustomPitch=0, CustomYaw=180, CustomRoll=0,
    },
    VoidHide = {
        Enabled=false, Y=9e10, SyncRage=false, Method="Drift",
    },
    ESP = {
        Enabled=false, Box=true, Name=true, Healthbar=true, Distance=true,
        Skeleton=false, MaxDist=1200, BoxColor=Color3.fromRGB(0,100,255),
        TeamCheck=true, TargetHUD=false,
    },
    Visuals = {
        Aura=false, AuraMode="Cyber Blue", AuraRGB=false,
        Crosshair=false, CrossGap=8, CrossSize=17,
        HitFX=false, HitFXType="damage", HitSound=false, HitSoundFX="sparkle",
        Chams=false, ChamsColor=Color3.fromRGB(255,0,100),
        Fullbright=false, FOVCircle=false, FOVRadius=120, DamageMarkers=false,
    },
    Movement = {
        Fly=false, FlySpeed=60, Noclip=false, SpeedMult=false, SpeedVal=2.0,
        DoubleJump=false, InfJump=false, JumpHeight=1.0,
        LongJump=false, LongForce=150, ClickTP=false,
        TpToTarget=false, TpOffset=3, TpRate=0.5,
    },
    Orbit = {
        Enabled=false, Mode="Circle", Speed=90, Radius=8, Height=3,
        RadiusX=8, RadiusZ=5, Face=true, Predict=false,
        AutoShoot=false, Lerp=true, LerpAlpha=0.2,
    },
    Pred = {
        Enabled=false, AimDotThresh=0.92, VelDotThresh=0.5,
        PerpStrength=18, MultiPoint=true,
    },
    AntiBait = {
        Enabled=false, GunPred=true, FlickerDet=true, AnimThreat=true, AimDet=true,
        DodgeMode="Perpendicular", DodgeDist=15,
        FlickerWindow=1.0, FlickerMin=3,
    },
    AntiTransloc = {
        Enabled=false, JumpThresh=5, TpWindow=1.0, MinTps=2,
        Mode="Dodge", FreezeTime=0.5, ShieldMode=false, ShieldPush=20,
    },
    VelDesync = {
        Enabled=false, Intensity=60, SpikeMode=false, SpikeInterval=0.3,
        MultiVector=false, VectorCount=3, CounterVel=false,
        NoiseVel=false, Oscillate=false,
    },
    Hitbox = {
        Enabled=false, Size=8, BreakHitbox=false, BreakSize=2500,
        Massless=false, NoCollide=false, PatchRaycast=false,
    },
    FakePos = {
        Enabled=false, Depth=5.8, Panic=false, PanicAmp=3,
        AutoNoclip=true, ZeroVelocity=false, HideMeshes=false,
        CamElevation=true, WalkMode=false, WalkSpeed=8, GhostVis=false,
    },
    StaffDetect = {
        Enabled=false, AutoHop=true, Notify=true,
    },
    Riot = {
        GodmodeEnabled=false, MinJump=5, MaxJump=25, GroundSnap=false,
        SpinSpeed=360, SpinAxis="Y", PhaseMode=false, PhaseInterval=0.05,
        AvoidBullets=false, BulletDodge=10, AutoShoot=false, AttackRange=20,
        AbuserEnabled=false, AbuserMode="Stick", SpinOnTarget=false,
        ForceFace=false, RaVelZero=false, PredictTarget=false, PredictLead=0.1,
        RandomOffset=false, OffsetAmp=3, StickHeight=5, BounceAmp=4, BounceSpeed=3,
    },
    SlingBypass = {
        Enabled=false, Mode="Follow", FollowHeight=5, FollowDist=8,
        StalkDist=12, HoverBobAmp=2, HoverBobSpeed=1.5,
        FastTpCount=5, FastTpCooldown=0.1, Penetrate=false,
        HoverHeight=10, RandomRadius=15,
        OrbitSpeed=90, OrbitRadius=8, OrbitHeight=3,
        AutoShoot=false, NetworkOwn=false,
    },
    Misc = {
        Watermark=true, AntiAFK=false, UnlockFPS=false, TargetFPS=144,
        AutoCollect=false, CollectR=120, VoidKiller=false, VoidKillRange=15,
    },
}

local State = {
    Target=nil, UseItemRemote=nil,
    AntiAimConn=nil, FlyConn=nil, NoclipConn=nil, GodConn=nil,
    OrbitConn=nil, PredConn=nil, AntiBaitConn=nil, AntiTranslocConn=nil,
    VelDesyncConn=nil, HitboxConn=nil, FakePosConn=nil,
    RiotConn=nil, AbuserConn=nil, SlingConn=nil, VoidKillerConn=nil,
    EspObjects={}, AuraObjects={},
    aaAngAcc=0, aaBreatheAcc=0, aaRollAcc=0,
    aaLastMicro=0, aaLastLook=0, aaLastChaos=0, aaExtraYaw=0,
    orbitAng=0, orbitT=0, orbitSpiralR=8,
    velDesyncAng=0, slingOrbAng=0, slingBobT=0,
    fpVirtualCF=nil, ghostBox=nil,
    riotJumpT=0, riotShootT=0, abuserShootT=0,
    AntiBaitDodgeT=0,
}

local function GUID() return HttpService:GenerateGUID(false) end
local function GetChar(pl) return pl and pl.Character end
local function GetHRP(pl) local c=GetChar(pl); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(pl) local c=GetChar(pl); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsEnemy(pl)
    if pl==LP then return false end
    if Cfg.ESP.TeamCheck and pl.Team==LP.Team then return false end
    local h=GetHum(pl); return h and h.Health>0
end
local function GetEnemies()
    local list={}
    for _,pl in ipairs(Players:GetPlayers()) do if IsEnemy(pl) then list[#list+1]=pl end end
    return list
end
local function W2S(pos)
    local ok,sp=pcall(function() return Cam:WorldToViewportPoint(pos) end)
    if ok then return Vector2.new(sp.X,sp.Y),sp.Z>0 end
    return Vector2.new(),false
end
local function predictPos(hrp,lead)
    if not hrp then return Vector3.zero end
    local vel=hrp.AssemblyLinearVelocity
    local grav=Vector3.new(0,-Workspace.Gravity*0.5,0)
    return hrp.Position+vel*lead+grav*(lead*lead*0.5)
end
local function GetClosestEnemy(origin,maxDist)
    local best,bestDist=nil,maxDist or math.huge
    for _,pl in ipairs(GetEnemies()) do
        local hrp=GetHRP(pl)
        if hrp then local d=(hrp.Position-origin).Magnitude; if d<bestDist then bestDist=d;best=pl end end
    end
    return best
end
local function GetTargetEnemy(origin)
    local enemies=GetEnemies()
    if #enemies==0 then return nil end
    local mode=Cfg.Rage.TargetMode
    if mode=="Closest" then return GetClosestEnemy(origin,math.huge)
    elseif mode=="Random" then return enemies[math.random(1,#enemies)]
    elseif mode=="Weakest" then
        local best,bestHP=nil,math.huge
        for _,pl in ipairs(enemies) do local h=GetHum(pl); if h and h.Health<bestHP then bestHP=h.Health;best=pl end end
        return best
    elseif mode=="Strongest" then
        local best,bestHP=nil,-1
        for _,pl in ipairs(enemies) do local h=GetHum(pl); if h and h.Health>bestHP then bestHP=h.Health;best=pl end end
        return best
    end
    return GetClosestEnemy(origin,math.huge)
end
local function GetHitbox(char)
    if not char then return nil end
    return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end
local function RandUnit()
    return Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5).Unit
end
local function Notify(msg,dur)
    dur=dur or 3
    pcall(function()
        local sg=Instance.new("ScreenGui",LP.PlayerGui)
        sg.Name="UNCODENotif";sg.ResetOnSpawn=false;sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,280,0,36);f.Position=UDim2.new(0.5,-140,0,8)
        f.BackgroundColor3=C_BG;f.BorderColor3=C_ACC;f.BorderSizePixel=1
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1
        l.Text="[UNCODE] "..msg;l.TextColor3=C_TXT;l.Font=Enum.Font.Code;l.TextSize=13
        game:GetService("Debris"):AddItem(sg,dur)
    end)
end

local function CacheRemotes()
    pcall(function()
        local rem=ReplicatedStorage:FindFirstChild("Remotes")
        if rem then
            local rep=rem:FindFirstChild("Replication")
            if rep then
                local fig=rep:FindFirstChild("Fighter")
                if fig then State.UseItemRemote=fig:FindFirstChild("UseItem") end
            end
        end
    end)
    if not State.UseItemRemote then
        pcall(function()
            for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("useitem") or v.Name:lower():find("attack") or v.Name:lower():find("shoot")) then
                    State.UseItemRemote=v; break
                end
            end
        end)
    end
end

local function FireUseItem(payload)
    if State.UseItemRemote then pcall(function() State.UseItemRemote:FireServer(payload) end) end
end

local function DoVoidSpam()
    local myHRP=GetHRP(LP); if not myHRP then return end
    local target=GetTargetEnemy(myHRP.Position)
    local hitbox=target and GetHitbox(GetChar(target))
    local aimPos=hitbox and predictPos(hitbox,Cfg.Rage.PredictLead) or (myHRP.Position+Vector3.new(Cfg.Rage.AimRand,0,0))
    if Cfg.Rage.AimRand>0 then aimPos=aimPos+RandUnit()*Cfg.Rage.AimRand end
    local char=LP.Character
    local tool=char and char:FindFirstChildOfClass("Tool")
    local item=tool and (tool:FindFirstChild("Handle") or tool)
    local rotVec=hitbox and (hitbox.Position-(myHRP.Position)).Unit or Vector3.new(0,0,-1)
    local payload={
        id=GUID(), objectId=GUID(), item="primary", position=aimPos,
        attackNum=math.random(1,99),
        animationKeys={math.random(1,999999),math.random(1,999999)},
        rotation=CFrame.lookAt(Vector3.zero,rotVec),
        one=Vector3.new(1,1,1), packed={"\x00","\x01","\x02","\x03"},
    }
    FireUseItem(payload)
    if item then
        pcall(function() item:StartShooting(aimPos) end)
        pcall(function() item:StartAiming(aimPos) end)
        pcall(function() item:HeavyAttack(aimPos) end)
    end
    if State.UseItemRemote then
        pcall(function()
            State.UseItemRemote:FireServer(GUID(),Enum.UserInputType.MouseButton1,
                {CFrame=Cam.CFrame,Focus=CFrame.new(aimPos)},nil)
        end)
    end
end

local function BindGodMode()
    if State.GodConn then State.GodConn:Disconnect() end
    State.GodConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Rage.GodMode then return end
        local hrp=GetHRP(LP)
        if hrp and hrp.Position.Y<Cfg.Rage.GodY then
            pcall(function() hrp.CFrame=CFrame.new(hrp.Position.X,Cfg.Rage.GodY+0.1,hrp.Position.Z) end)
        end
    end)
end

local function BindAntiAim()
    if State.AntiAimConn then State.AntiAimConn:Disconnect() end
    State.aaAngAcc=0;State.aaBreatheAcc=0;State.aaRollAcc=0
    State.AntiAimConn=RunService:BindToRenderStep("UNCODE_AA",Enum.RenderPriority.Character.Value+1,function(dt)
        if not Cfg.AntiAim.Enabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local aa=Cfg.AntiAim; local mode=aa.Mode
        local pitch,yaw,roll=0,0,0
        local extra=State.aaExtraYaw
        if aa.BreatheEffect then
            State.aaBreatheAcc=State.aaBreatheAcc+dt
            yaw=yaw+math.sin(State.aaBreatheAcc*aa.BreatheSpeed*math.pi*2)*aa.BreatheAmp
        end
        if aa.MicroJitter then
            State.aaLastMicro=State.aaLastMicro+dt
            if State.aaLastMicro>=1/aa.MicroJitterSpeed then
                State.aaLastMicro=0
                extra=extra+(math.random()-0.5)*2*aa.MicroJitterAmp
            end
        end
        if aa.DesyncMode then extra=extra+aa.DesyncOffset end
        if aa.RandomFlip and math.random()<aa.FlipChance then extra=extra+180 end
        if aa.ChaosMode then
            State.aaLastChaos=State.aaLastChaos+dt
            if State.aaLastChaos>=aa.ChaosInterval then State.aaLastChaos=0;extra=extra+(math.random()-0.5)*360 end
        end
        if aa.LookAtRandom then
            State.aaLastLook=State.aaLastLook+dt
            if State.aaLastLook>=aa.LookInterval then State.aaLastLook=0;extra=extra+math.random(0,360) end
        end
        if aa.RollEnabled then State.aaRollAcc=State.aaRollAcc+dt;roll=State.aaRollAcc*aa.RollSpeed end
        if mode=="Spin" then State.aaAngAcc=State.aaAngAcc+aa.SpinSpeed*dt;yaw=yaw+State.aaAngAcc
        elseif mode=="Jitter" then
            State.aaAngAcc=State.aaAngAcc+dt*20
            local side=math.floor(State.aaAngAcc)%2==0 and 1 or -1
            yaw=yaw+side*aa.Jitter;pitch=pitch+side*(aa.Pitch or 0)
        elseif mode=="Static" then pitch=aa.Pitch;yaw=aa.Yaw
        elseif mode=="Up" then pitch=90
        elseif mode=="Down" then pitch=-90
        elseif mode=="Side" then roll=90
        elseif mode=="RandomSpin" then
            State.aaAngAcc=State.aaAngAcc+(math.random()*2-1)*aa.SpinSpeed*dt;yaw=yaw+State.aaAngAcc
        elseif mode=="Custom" then pitch=aa.CustomPitch;yaw=aa.CustomYaw;roll=aa.CustomRoll
        end
        if aa.MultiAxisSpin then
            State.aaAngAcc=State.aaAngAcc+aa.SpinSpeed*dt
            pitch=pitch+State.aaAngAcc*0.7;roll=roll+State.aaAngAcc*0.5
        end
        yaw=yaw+extra
        pcall(function()
            hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(math.rad(pitch),math.rad(yaw),math.rad(roll))
        end)
    end)
end

local function ApplyVoidHide(on)
    if on then
        local hrp=GetHRP(LP)
        if hrp then
            pcall(function() hrp.CFrame=CFrame.new(hrp.Position.X,Cfg.VoidHide.Y,hrp.Position.Z) end)
            pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero end)
        end
    end
end

local function CleanESP(pl)
    local objs=State.EspObjects[pl]
    if objs then for _,o in ipairs(objs) do pcall(function() o:Destroy() end) end;State.EspObjects[pl]=nil end
end

local function UpdateESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if not IsEnemy(pl) then CleanESP(pl);continue end
        local char=GetChar(pl);local hrp=GetHRP(pl);local hum=GetHum(pl)
        if not char or not hrp or not hum then CleanESP(pl);continue end
        local myHRP=GetHRP(LP)
        local dist=(hrp.Position-(myHRP and myHRP.Position or Vector3.zero)).Magnitude
        if dist>Cfg.ESP.MaxDist then CleanESP(pl);continue end
        local objs=State.EspObjects[pl]
        if not objs then
            objs={};State.EspObjects[pl]=objs
            if Cfg.ESP.Box then
                local sb=Instance.new("SelectionBox",Workspace)
                sb.Color3=Cfg.ESP.BoxColor;sb.LineThickness=0.04;sb.SurfaceTransparency=1;sb.Adornee=char
                objs[#objs+1]=sb
            end
            local bg=Instance.new("BillboardGui",hrp)
            bg.Size=UDim2.new(0,120,0,40);bg.StudsOffset=Vector3.new(0,3,0);bg.AlwaysOnTop=true
            local nl=Instance.new("TextLabel",bg)
            nl.Size=UDim2.new(1,0,0.5,0);nl.BackgroundTransparency=1;nl.Font=Enum.Font.Code
            nl.TextSize=12;nl.TextStrokeTransparency=0.5;nl.TextColor3=Color3.new(1,1,1);nl.Name="NL"
            local il=Instance.new("TextLabel",bg)
            il.Size=UDim2.new(1,0,0.5,0);il.Position=UDim2.new(0,0,0.5,0);il.BackgroundTransparency=1
            il.Font=Enum.Font.Code;il.TextSize=11;il.Name="IL";il.TextColor3=Color3.fromRGB(100,200,100)
            objs[#objs+1]=bg
        end
        for _,obj in ipairs(objs) do
            if obj:IsA("BillboardGui") then
                local nl=obj:FindFirstChild("NL");local il=obj:FindFirstChild("IL")
                if nl and Cfg.ESP.Name then nl.Text=pl.Name end
                if il then
                    local parts={}
                    if Cfg.ESP.Healthbar then parts[#parts+1]=string.format("HP:%.0f",hum.Health) end
                    if Cfg.ESP.Distance  then parts[#parts+1]=string.format("%.0fm",dist) end
                    il.Text=table.concat(parts," ")
                end
            end
        end
    end
end

local function BindOrbit()
    if State.OrbitConn then State.OrbitConn:Disconnect() end
    State.orbitAng=0;State.orbitSpiralR=Cfg.Orbit.Radius
    State.OrbitConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.Orbit.Enabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local target=GetTargetEnemy(hrp.Position)
        local tHRP=target and GetHRP(target)
        local tPos=tHRP and (Cfg.Orbit.Predict and predictPos(tHRP,Cfg.Rage.PredictLead) or tHRP.Position) or hrp.Position
        local orb=Cfg.Orbit
        State.orbitAng=State.orbitAng+math.rad(orb.Speed)*dt
        local t=State.orbitAng;local r=orb.Radius
        local ox,oz=0,0
        if orb.Mode=="Circle" then ox=math.cos(t)*r;oz=math.sin(t)*r
        elseif orb.Mode=="Figure8" or orb.Mode=="Lemniscate" or orb.Mode=="Infinity" then
            local d=1+math.sin(t)^2;ox=(math.cos(t)/d)*r;oz=(math.sin(t)*math.cos(t)/d)*r
        elseif orb.Mode=="Ellipse" then ox=math.cos(t)*orb.RadiusX;oz=math.sin(t)*orb.RadiusZ
        elseif orb.Mode=="SpiralIn" then
            State.orbitSpiralR=math.max(2,State.orbitSpiralR-dt*2);ox=math.cos(t)*State.orbitSpiralR;oz=math.sin(t)*State.orbitSpiralR
        elseif orb.Mode=="SpiralOut" then
            State.orbitSpiralR=math.min(40,State.orbitSpiralR+dt*2);ox=math.cos(t)*State.orbitSpiralR;oz=math.sin(t)*State.orbitSpiralR
        elseif orb.Mode=="Bounce" then local br=math.abs(math.sin(t))*r+2;ox=math.cos(t)*br;oz=math.sin(t)*br
        elseif orb.Mode=="RandomOrbit" then
            State.orbitAng=State.orbitAng+(math.random()-0.5)*0.5;ox=math.cos(State.orbitAng)*r;oz=math.sin(State.orbitAng)*r
        end
        local newPos=tPos+Vector3.new(ox,orb.Height,oz)
        local goal=orb.Face and CFrame.lookAt(newPos,tPos) or CFrame.new(newPos)
        pcall(function()
            if orb.Lerp then hrp.CFrame=hrp.CFrame:Lerp(goal,orb.LerpAlpha) else hrp.CFrame=goal end
        end)
        if orb.AutoShoot and target then DoVoidSpam() end
    end)
end

local function BindPredV2()
    if State.PredConn then State.PredConn:Disconnect() end
    State.PredConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Pred.Enabled then return end
        local myHRP=GetHRP(LP); if not myHRP then return end
        local bestScore,bestHRP=0,nil
        for _,pl in ipairs(GetEnemies()) do
            local eHRP=GetHRP(pl)
            if eHRP then
                local toMe=(myHRP.Position-eHRP.Position);local eDist=toMe.Magnitude
                if eDist<200 then
                    local eVel=eHRP.AssemblyLinearVelocity;local eLook=eHRP.CFrame.LookVector
                    local aimDot=eLook:Dot(toMe.Unit)
                    local velDot=(eVel.Magnitude>0.1) and eVel.Unit:Dot(toMe.Unit) or 0
                    local score=aimDot*0.7+velDot*0.3
                    if aimDot>Cfg.Pred.AimDotThresh and score>bestScore then bestScore=score;bestHRP=eHRP end
                end
            end
        end
        if bestHRP and bestScore>Cfg.Pred.AimDotThresh then
            local toMe=(myHRP.Position-bestHRP.Position).Unit
            local perp=Vector3.new(-toMe.Z,0,toMe.X).Unit
            local dodgePos=myHRP.Position+perp*Cfg.Pred.PerpStrength
            if Cfg.Pred.MultiPoint then dodgePos=dodgePos+Vector3.new((math.random()-0.5)*6,math.random()*3,(math.random()-0.5)*6) end
            pcall(function() myHRP.CFrame=CFrame.new(dodgePos)*CFrame.Angles(0,math.atan2(-toMe.X,-toMe.Z),0) end)
        end
    end)
end

local function BindAntiBaitV2()
    if State.AntiBaitConn then State.AntiBaitConn:Disconnect() end
    local tpHistory={}
    State.AntiBaitConn=RunService.Heartbeat:Connect(function()
        if not Cfg.AntiBait.Enabled then return end
        local myHRP=GetHRP(LP); if not myHRP then return end
        local now=tick()
        if now-State.AntiBaitDodgeT<0.3 then return end
        for _,pl in ipairs(GetEnemies()) do
            local eHRP=GetHRP(pl); if not eHRP then continue end
            local dist=(eHRP.Position-myHRP.Position).Magnitude; if dist>120 then continue end
            local threat=false
            if Cfg.AntiBait.GunPred then
                local eLook=eHRP.CFrame.LookVector;local toMe=(myHRP.Position-eHRP.Position).Unit
                if eLook:Dot(toMe)>0.85 then threat=true end
            end
            if Cfg.AntiBait.FlickerDet then
                tpHistory[pl]=tpHistory[pl] or {lastPos=eHRP.Position,count=0,t=now}
                local hist=tpHistory[pl];local moved=(eHRP.Position-hist.lastPos).Magnitude
                if moved>10 then hist.count=hist.count+1 end
                hist.lastPos=eHRP.Position
                if now-hist.t>Cfg.AntiBait.FlickerWindow then hist.count=0;hist.t=now end
                if hist.count>=Cfg.AntiBait.FlickerMin then threat=true end
            end
            if threat then
                State.AntiBaitDodgeT=now
                local toMe=(myHRP.Position-eHRP.Position).Unit;local dir
                if Cfg.AntiBait.DodgeMode=="Away" then dir=toMe
                elseif Cfg.AntiBait.DodgeMode=="Perpendicular" then dir=Vector3.new(-toMe.Z,0,toMe.X).Unit
                else local r=RandUnit()*Vector3.new(1,0,1);dir=(r.Magnitude>0.01 and r.Unit or Vector3.new(1,0,0)) end
                local newPos=myHRP.Position+dir*Cfg.AntiBait.DodgeDist
                pcall(function() myHRP.CFrame=CFrame.new(newPos) end);break
            end
        end
    end)
end

local function BindAntiTransloc()
    if State.AntiTranslocConn then State.AntiTranslocConn:Disconnect() end
    local posHist={};local tpCounts={}
    State.AntiTranslocConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.AntiTransloc.Enabled then return end
        local myHRP=GetHRP(LP); if not myHRP then return end
        local now=tick()
        for _,pl in ipairs(GetEnemies()) do
            local eHRP=GetHRP(pl); if not eHRP then continue end
            local prev=posHist[pl]
            if prev then
                local moved=(eHRP.Position-prev).Magnitude/math.max(dt,0.001)
                if moved>Cfg.AntiTransloc.JumpThresh/math.max(dt,0.001) then
                    tpCounts[pl]=tpCounts[pl] or {c=0,t=now};tpCounts[pl].c=tpCounts[pl].c+1
                    if now-tpCounts[pl].t>Cfg.AntiTransloc.TpWindow then tpCounts[pl].c=1;tpCounts[pl].t=now end
                    if tpCounts[pl].c>=Cfg.AntiTransloc.MinTps then
                        if Cfg.AntiTransloc.Mode=="Freeze" then
                            pcall(function() myHRP.AssemblyLinearVelocity=Vector3.zero end)
                        else
                            local toMe=(myHRP.Position-eHRP.Position).Unit
                            local perp=Vector3.new(-toMe.Z,0,toMe.X).Unit
                            pcall(function() myHRP.CFrame=myHRP.CFrame+perp*15 end)
                        end
                        tpCounts[pl].c=0
                    end
                end
            end
            posHist[pl]=eHRP.Position
        end
    end)
end

local function BindVelDesync()
    if State.VelDesyncConn then State.VelDesyncConn:Disconnect() end
    State.velDesyncAng=0;local spikeT=0
    State.VelDesyncConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.VelDesync.Enabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local cfg=Cfg.VelDesync
        State.velDesyncAng=State.velDesyncAng+dt*180
        local mag=(cfg.Intensity/100)*50000
        local angle=math.rad(State.velDesyncAng)
        local spoofVel=Vector3.new(math.cos(angle)*mag,0,math.sin(angle)*mag)
        if cfg.Oscillate then spoofVel=spoofVel*math.abs(math.sin(State.velDesyncAng*0.01)) end
        if cfg.NoiseVel then
            spoofVel=spoofVel+Vector3.new(math.noise(tick()*0.5,0)*mag*0.3,math.noise(0,tick()*0.5)*mag*0.1,math.noise(tick()*0.5,tick()*0.5)*mag*0.3)
        end
        if cfg.CounterVel then spoofVel=spoofVel+(-hrp.AssemblyLinearVelocity*2) end
        if cfg.SpikeMode then spikeT=spikeT+dt; if spikeT>=cfg.SpikeInterval then spikeT=0;spoofVel=spoofVel*5 end end
        local ok=false
        pcall(function()
            local mt=getrawmetatable(hrp);local ni=mt and rawget(mt,"__newindex")
            if ni then pcall(ni,hrp,"AssemblyLinearVelocity",spoofVel);ok=true end
        end)
        if not ok then pcall(function() hrp.AssemblyLinearVelocity=spoofVel end) end
        if sethiddenproperty then pcall(sethiddenproperty,hrp,"AssemblyLinearVelocity",spoofVel) end
    end)
end

local function BindHitbox()
    if State.HitboxConn then State.HitboxConn:Disconnect() end
    State.HitboxConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Hitbox.Enabled then return end
        local size=Cfg.Hitbox.BreakHitbox and Cfg.Hitbox.BreakSize or Cfg.Hitbox.Size
        for _,pl in ipairs(GetEnemies()) do
            local char=GetChar(pl)
            if char then
                for _,part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.Size=Vector3.new(size,size,size) end)
                        if Cfg.Hitbox.Massless then pcall(function() part.Massless=true end) end
                        if Cfg.Hitbox.NoCollide then pcall(function() part.CanCollide=false end) end
                    end
                end
            end
        end
    end)
end

local function BindFakePos()
    if State.FakePosConn then State.FakePosConn:Disconnect() end
    if State.ghostBox then pcall(function() State.ghostBox:Destroy() end);State.ghostBox=nil end
    if Cfg.FakePos.GhostVis then
        local gb=Instance.new("Part",Workspace)
        gb.Anchored=true;gb.CanCollide=false;gb.CanTouch=false
        gb.Size=Vector3.new(2,5,1);gb.Material=Enum.Material.Neon
        gb.BrickColor=BrickColor.new("Bright blue");gb.Transparency=0.5;gb.Name="UNCODEGhost"
        State.ghostBox=gb
    end
    State.FakePosConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.FakePos.Enabled then
            if State.ghostBox then State.ghostBox.CFrame=CFrame.new(0,-9999,0) end;return
        end
        local hrp=GetHRP(LP); if not hrp then return end
        local fp=Cfg.FakePos
        State.fpVirtualCF=hrp.CFrame
        local camLook=Cam.CFrame.LookVector
        local camYaw=math.atan2(-camLook.X,-camLook.Z)
        local surfaceRot=CFrame.Angles(0,camYaw,0)
        local underPos=State.fpVirtualCF.Position-Vector3.new(0,fp.Depth,0)
        if fp.Panic then
            underPos=underPos+Vector3.new((math.random()-0.5)*2*fp.PanicAmp,0,(math.random()-0.5)*2*fp.PanicAmp)
        end
        if fp.AutoNoclip then
            local char=LP.Character
            if char then for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=false;p.CanTouch=false end) end
            end end
        end
        if fp.ZeroVelocity then pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero end) end
        pcall(function() hrp.CFrame=CFrame.new(underPos)*surfaceRot end)
        if fp.HideMeshes then
            local char=LP.Character
            if char then for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("Decal") then pcall(function() p.Transparency=1 end) end
            end end
        end
        if State.ghostBox then State.ghostBox.CFrame=State.fpVirtualCF end
        if fp.CamElevation then pcall(function() Cam.CFrame=Cam.CFrame+Vector3.new(0,fp.Depth,0) end) end
    end)
end

local MOD_KEYWORDS={"mod","admin","staff","owner","developer","tester","creator","contributor"}
local detectedStaff={}
local function CheckStaff(pl)
    if pl==LP or detectedStaff[pl] then return end
    local nl=pl.Name:lower()
    local dl=(pcall(function() return pl.DisplayName end) and pl.DisplayName or pl.Name):lower()
    local isStaff=(pl.UserId==game.CreatorId)
    if not isStaff then for _,kw in ipairs(MOD_KEYWORDS) do if nl:find(kw) or dl:find(kw) then isStaff=true;break end end end
    if isStaff then
        detectedStaff[pl]=true
        warn("[UNCODE] Staff: "..pl.Name)
        if Cfg.StaffDetect.Notify then Notify("STAFF: "..pl.Name,8) end
        if Cfg.StaffDetect.AutoHop then pcall(function() TeleportService:Teleport(game.PlaceId,LP) end) end
    end
end
local function BindStaffDetect()
    for _,pl in ipairs(Players:GetPlayers()) do CheckStaff(pl) end
    Players.PlayerAdded:Connect(function(pl) if Cfg.StaffDetect.Enabled then CheckStaff(pl) end end)
end

local function BindRiotGodmode()
    if State.RiotConn then State.RiotConn:Disconnect() end
    State.RiotConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.Riot.GodmodeEnabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local cfg=Cfg.Riot
        State.riotJumpT=State.riotJumpT+dt
        if State.riotJumpT>=0.1 then
            State.riotJumpT=0
            local dir=RandUnit()*Vector3.new(1,0,1)
            if dir.Magnitude<0.01 then dir=Vector3.new(1,0,0) else dir=dir.Unit end
            local dist=cfg.MinJump+math.random()*(cfg.MaxJump-cfg.MinJump)
            local newPos=hrp.Position+dir*dist
            if cfg.GroundSnap then newPos=Vector3.new(newPos.X,hrp.Position.Y,newPos.Z) end
            if cfg.AvoidBullets then
                local target=GetTargetEnemy(hrp.Position);local eHRP=target and GetHRP(target)
                if eHRP then local away=(hrp.Position-eHRP.Position);if away.Magnitude>0.01 then newPos=hrp.Position+away.Unit*cfg.BulletDodge end end
            end
            pcall(function()
                local spinCF=CFrame.Angles(0,math.rad(cfg.SpinSpeed*tick()%360),0)
                hrp.CFrame=CFrame.new(newPos)*spinCF
            end)
        end
        if cfg.AutoShoot then
            State.riotShootT=State.riotShootT+dt
            if State.riotShootT>=0.15 then
                State.riotShootT=0
                local target=GetTargetEnemy(hrp.Position);local eHRP=target and GetHRP(target)
                if eHRP and (eHRP.Position-hrp.Position).Magnitude<cfg.AttackRange then DoVoidSpam() end
            end
        end
    end)
end

local function BindRiotAbuser()
    if State.AbuserConn then State.AbuserConn:Disconnect() end
    local bobT=0
    State.AbuserConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.Riot.AbuserEnabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local cfg=Cfg.Riot;local target=GetTargetEnemy(hrp.Position); if not target then return end
        local tHRP=GetHRP(target); if not tHRP then return end
        local tPos=cfg.PredictTarget and predictPos(tHRP,cfg.PredictLead) or tHRP.Position
        local offset=Vector3.new(0,cfg.StickHeight,0)
        if cfg.RandomOffset then offset=offset+Vector3.new((math.random()-0.5)*2*cfg.OffsetAmp,0,(math.random()-0.5)*2*cfg.OffsetAmp) end
        local newPos
        if cfg.AbuserMode=="Stick" then newPos=tPos+offset
        elseif cfg.AbuserMode=="Bounce" then bobT=bobT+dt;newPos=tPos+Vector3.new(0,math.abs(math.sin(bobT*cfg.BounceSpeed))*cfg.BounceAmp,0)
        elseif cfg.AbuserMode=="Orbit" then
            State.slingOrbAng=State.slingOrbAng+math.rad(90)*dt
            newPos=tPos+Vector3.new(math.cos(State.slingOrbAng)*6,cfg.StickHeight,math.sin(State.slingOrbAng)*6)
        elseif cfg.AbuserMode=="Phase" then
            local side=(math.floor(tick()*10)%2==0) and 1 or -1
            newPos=tPos+Vector3.new(side*4,cfg.StickHeight,0)
        end
        if newPos then
            pcall(function()
                local goalCF=CFrame.new(newPos)
                if cfg.ForceFace then goalCF=CFrame.lookAt(newPos,tPos) end
                if cfg.SpinOnTarget then goalCF=goalCF*CFrame.Angles(0,math.rad(cfg.SpinSpeed*tick()%360),0) end
                hrp.CFrame=goalCF
            end)
        end
        if cfg.RaVelZero then pcall(function() hrp.AssemblyLinearVelocity=tHRP.AssemblyLinearVelocity;hrp.AssemblyAngularVelocity=Vector3.zero end) end
        State.abuserShootT=State.abuserShootT+dt
        if cfg.AutoShoot and State.abuserShootT>=0.15 then
            State.abuserShootT=0
            if (tHRP.Position-hrp.Position).Magnitude<cfg.AttackRange then DoVoidSpam() end
        end
    end)
end

local function BindSlingBypass()
    if State.SlingConn then State.SlingConn:Disconnect() end
    local fastTpT=0;State.slingBobT=0
    State.SlingConn=RunService.Heartbeat:Connect(function(dt)
        if not Cfg.SlingBypass.Enabled then return end
        local hrp=GetHRP(LP); if not hrp then return end
        local sb=Cfg.SlingBypass;local target=GetTargetEnemy(hrp.Position); if not target then return end
        local tHRP=GetHRP(target); if not tHRP then return end
        local tPos=tHRP.Position;local newCF
        if sb.Mode=="Follow" then
            local dir=(tPos-hrp.Position)
            if dir.Magnitude>sb.FollowDist then
                local goal=tPos-dir.Unit*sb.FollowDist+Vector3.new(0,sb.FollowHeight,0)
                newCF=hrp.CFrame:Lerp(CFrame.new(goal),0.15)
            end
        elseif sb.Mode=="Stalk" then
            local behind=tHRP.CFrame*CFrame.new(0,0,sb.StalkDist)
            newCF=hrp.CFrame:Lerp(CFrame.new(behind.Position),0.1)
        elseif sb.Mode=="Hover" then
            State.slingBobT=State.slingBobT+dt
            local bob=math.sin(State.slingBobT*sb.HoverBobSpeed*math.pi*2)*sb.HoverBobAmp
            newCF=hrp.CFrame:Lerp(CFrame.new(tPos+Vector3.new(0,sb.HoverHeight+bob,0)),0.2)
        elseif sb.Mode=="FastTp" then
            fastTpT=fastTpT+dt
            if fastTpT>=sb.FastTpCooldown then
                fastTpT=0
                local predPos=predictPos(tHRP,Cfg.Rage.PredictLead)
                for i=1,sb.FastTpCount do pcall(function() hrp.CFrame=CFrame.new(predPos+RandUnit()*2) end) end
            end
        elseif sb.Mode=="TargetStick" then
            newCF=CFrame.new(tPos+Vector3.new(0,sb.StickHeight or 5,0))
        elseif sb.Mode=="OrbitTarget" then
            State.slingOrbAng=State.slingOrbAng+math.rad(sb.OrbitSpeed)*dt
            newCF=CFrame.new(tPos+Vector3.new(math.cos(State.slingOrbAng)*sb.OrbitRadius,sb.OrbitHeight,math.sin(State.slingOrbAng)*sb.OrbitRadius))
        elseif sb.Mode=="RandomAroundTarget" then
            local angle=math.random()*math.pi*2
            newCF=CFrame.new(tPos+Vector3.new(math.cos(angle)*sb.RandomRadius,2,math.sin(angle)*sb.RandomRadius))
        end
        if newCF then pcall(function() hrp.CFrame=newCF end) end
        if sb.NetworkOwn then pcall(function() tHRP:SetNetworkOwner(LP) end) end
        if sb.AutoShoot then DoVoidSpam() end
    end)
end

local function BindFly()
    if State.FlyConn then State.FlyConn:Disconnect() end
    State.FlyConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Movement.Fly then return end
        local hrp=GetHRP(LP);local hum=GetHum(LP); if not hrp or not hum then return end
        pcall(function() hum.PlatformStand=true end)
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        pcall(function() hrp.AssemblyLinearVelocity=dir*Cfg.Movement.FlySpeed end)
    end)
end

local function BindNoclip()
    if State.NoclipConn then State.NoclipConn:Disconnect() end
    State.NoclipConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Movement.Noclip then return end
        local char=LP.Character; if not char then return end
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=false;p.CanTouch=false end) end
        end
    end)
end

local AuraModes={
    ["Cyber Blue"]={Color3.fromRGB(0,100,255),Color3.fromRGB(100,200,255)},
    ["Fire"]={Color3.fromRGB(255,80,0),Color3.fromRGB(255,200,0)},
    ["Poison"]={Color3.fromRGB(0,255,80),Color3.fromRGB(200,255,0)},
    ["Shadow"]={Color3.fromRGB(80,0,160),Color3.fromRGB(160,0,255)},
    ["Gold"]={Color3.fromRGB(255,200,0),Color3.fromRGB(255,255,100)},
    ["Crimson"]={Color3.fromRGB(200,0,0),Color3.fromRGB(255,80,80)},
}
local function CleanAura() for _,o in ipairs(State.AuraObjects) do pcall(function() o:Destroy() end) end;State.AuraObjects={} end
local function ApplyAura(on)
    CleanAura(); if not on then return end
    local char=LP.Character; if not char then return end
    local cols=AuraModes[Cfg.Visuals.AuraMode] or AuraModes["Cyber Blue"]
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
            local pe=Instance.new("ParticleEmitter",part)
            pe.Color=ColorSequence.new(cols[1],cols[2]);pe.LightEmission=0.9;pe.Rate=20
            pe.Speed=NumberRange.new(0.5,2);pe.Lifetime=NumberRange.new(0.3,0.8);pe.Size=NumberSequence.new(0.15,0)
            State.AuraObjects[#State.AuraObjects+1]=pe
            local pl2=Instance.new("PointLight",part)
            pl2.Brightness=2;pl2.Range=14;pl2.Color=cols[1]
            State.AuraObjects[#State.AuraObjects+1]=pl2
        end
    end
end

local function BindVoidKiller()
    if State.VoidKillerConn then State.VoidKillerConn:Disconnect() end
    State.VoidKillerConn=RunService.Heartbeat:Connect(function()
        if not Cfg.Misc.VoidKiller then return end
        local myHRP=GetHRP(LP); if not myHRP or myHRP.Position.Y>-100 then return end
        for _,pl in ipairs(GetEnemies()) do
            local eHRP=GetHRP(pl)
            if eHRP and (eHRP.Position-myHRP.Position).Magnitude<Cfg.Misc.VoidKillRange then
                pcall(function() eHRP:SetNetworkOwner(LP) end)
                local echar=GetChar(pl)
                if echar then for _,p in ipairs(echar:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.Size=Vector3.new(2500,2500,2500) end) end
                end end
                DoVoidSpam()
            end
        end
    end)
end

local function OnCharSpawn(char)
    task.wait(0.5);CacheRemotes()
    BindAntiAim();BindGodMode();BindFly();BindNoclip();BindOrbit()
    BindPredV2();BindAntiBaitV2();BindAntiTransloc();BindVelDesync()
    BindHitbox();BindFakePos();BindRiotGodmode();BindRiotAbuser()
    BindSlingBypass();BindVoidKiller()
end
LP.CharacterAdded:Connect(OnCharSpawn)
if LP.Character then OnCharSpawn(LP.Character) end

RunService.Heartbeat:Connect(function()
    if Cfg.Misc.AntiAFK then pcall(function() VirtualUser:CaptureController() end) end
end)
BindStaffDetect()

local spamClock=0
RunService.Heartbeat:Connect(function(dt)
    spamClock=spamClock+dt
    local spamInt=1/math.max(1,Cfg.Rage.SpamRate)
    if Cfg.Rage.Enabled and Cfg.Rage.VoidSpam and spamClock>=spamInt then spamClock=0;DoVoidSpam() end
    if Cfg.Rage.Enabled and Cfg.Rage.TpAttack then
        local myHRP=GetHRP(LP)
        if myHRP then
            local target=GetTargetEnemy(myHRP.Position);local tHRP=target and GetHRP(target)
            if tHRP then
                local off=(myHRP.Position-tHRP.Position).Unit*Cfg.Rage.TpOffset
                pcall(function() myHRP.CFrame=tHRP.CFrame+off end);DoVoidSpam()
            end
        end
    end
    if Cfg.Movement.TpToTarget then
        local myHRP=GetHRP(LP)
        if myHRP then
            local target=GetTargetEnemy(myHRP.Position);local tHRP=target and GetHRP(target)
            if tHRP then
                local off=(myHRP.Position-tHRP.Position).Unit*Cfg.Movement.TpOffset
                pcall(function() myHRP.CFrame=tHRP.CFrame+off end)
            end
        end
    end
    if Cfg.VoidHide.Enabled then ApplyVoidHide(true) end
    if Cfg.ESP.Enabled then UpdateESP() end
    if Cfg.Movement.SpeedMult then
        local hum=GetHum(LP); if hum then pcall(function() hum.WalkSpeed=16*Cfg.Movement.SpeedVal end) end
    end
end)

-- ===== UI =====
local GuiMain=Instance.new("ScreenGui")
GuiMain.Name="UNCODE_v4";GuiMain.ResetOnSpawn=false
GuiMain.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;GuiMain.IgnoreGuiInset=true
pcall(function() GuiMain.Parent=LP.PlayerGui end)
pcall(function() if not LP.PlayerGui:FindFirstChild("UNCODE_v4") then GuiMain.Parent=game.CoreGui end end)

local Win=Instance.new("Frame",GuiMain)
Win.Name="Window";Win.Size=UDim2.new(0,540,0,460)
Win.Position=UDim2.new(0.5,-270,0.5,-230)
Win.BackgroundColor3=C_BG;Win.BorderColor3=C_BOR;Win.BorderSizePixel=2
Win.Active=true;Win.Draggable=true

local TitleBar=Instance.new("Frame",Win)
TitleBar.Size=UDim2.new(1,0,0,28);TitleBar.BackgroundColor3=Color3.fromRGB(5,5,5)
TitleBar.BorderColor3=C_BOR;TitleBar.BorderSizePixel=1
local TitleLbl=Instance.new("TextLabel",TitleBar)
TitleLbl.Size=UDim2.new(1,0,1,0);TitleLbl.BackgroundTransparency=1
TitleLbl.Text="UNCODE v4  |  Rivals HvH  |  RCtrl = Toggle"
TitleLbl.Font=Enum.Font.Code;TitleLbl.TextSize=12;TitleLbl.TextColor3=C_BOR

local WaterLbl=Instance.new("TextLabel",GuiMain)
WaterLbl.Size=UDim2.new(0,180,0,18);WaterLbl.Position=UDim2.new(0,4,0,4)
WaterLbl.BackgroundTransparency=1;WaterLbl.Text="UNCODE v4"
WaterLbl.Font=Enum.Font.Code;WaterLbl.TextSize=12;WaterLbl.TextColor3=C_BOR
WaterLbl.TextXAlignment=Enum.TextXAlignment.Left

local visible=true
UserInputService.InputBegan:Connect(function(inp,proc)
    if proc then return end
    if inp.KeyCode==Enum.KeyCode.RightControl then visible=not visible;Win.Visible=visible end
end)

local TABS={"RAGE","AA","ESP","VISUAL","MOVE","BYPASS","MISC","EXTRA"}
local activeTab="RAGE"
local TabPanels={};local TabButtons={}

local function SetTab(name)
    activeTab=name
    for tName,panel in pairs(TabPanels) do panel.Visible=(tName==name) end
    for tName,btn in pairs(TabButtons) do
        btn.BackgroundColor3=(tName==name) and C_ACC or C_BTN
        btn.TextColor3=(tName==name) and Color3.new(1,1,1) or Color3.fromRGB(160,160,160)
    end
end

local TabBar=Instance.new("Frame",Win)
TabBar.Size=UDim2.new(1,0,0,24);TabBar.Position=UDim2.new(0,0,0,28)
TabBar.BackgroundColor3=Color3.fromRGB(8,8,8);TabBar.BorderSizePixel=0
local tabW=math.floor(540/#TABS)

for i,tabName in ipairs(TABS) do
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,tabW,1,0);btn.Position=UDim2.new(0,(i-1)*tabW,0,0)
    btn.BackgroundColor3=C_BTN;btn.BorderSizePixel=0
    btn.Text=tabName;btn.Font=Enum.Font.Code;btn.TextSize=11
    btn.TextColor3=Color3.fromRGB(160,160,160)
    TabButtons[tabName]=btn
    local panel=Instance.new("ScrollingFrame",Win)
    panel.Name=tabName;panel.Size=UDim2.new(1,0,1,-52);panel.Position=UDim2.new(0,0,0,52)
    panel.BackgroundColor3=C_PANEL;panel.BorderSizePixel=0
    panel.ScrollBarThickness=4;panel.ScrollBarImageColor3=C_ACC;panel.Visible=(tabName=="RAGE")
    TabPanels[tabName]=panel
    local layout=Instance.new("UIListLayout",panel)
    layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,2)
    btn.MouseButton1Click:Connect(function() SetTab(tabName) end)
end

local function MakeToggle(parent,label,getter,setter,order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,28);row.BackgroundColor3=C_BTN;row.BorderSizePixel=0;row.LayoutOrder=order or 0
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.72,0,1,0);lbl.Position=UDim2.new(0,8,0,0);lbl.BackgroundTransparency=1
    lbl.Text=label;lbl.Font=Enum.Font.Code;lbl.TextSize=12;lbl.TextColor3=C_TXT;lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,44,0,18);btn.Position=UDim2.new(1,-52,0.5,-9)
    btn.Font=Enum.Font.Code;btn.TextSize=11;btn.BorderSizePixel=0
    local function Refresh()
        local on=getter();btn.BackgroundColor3=on and C_ON or C_OFF
        btn.TextColor3=on and Color3.new(1,1,1) or Color3.fromRGB(120,120,120);btn.Text=on and "ON" or "OFF"
    end
    Refresh();btn.MouseButton1Click:Connect(function() setter(not getter());Refresh() end)
end

local function MakeSlider(parent,label,min_,max_,getter,setter,order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,30);row.BackgroundColor3=C_BTN;row.BorderSizePixel=0;row.LayoutOrder=order or 0
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.5,0,1,0);lbl.Position=UDim2.new(0,8,0,0);lbl.BackgroundTransparency=1
    lbl.Text=label;lbl.Font=Enum.Font.Code;lbl.TextSize=11;lbl.TextColor3=Color3.fromRGB(180,180,180);lbl.TextXAlignment=Enum.TextXAlignment.Left
    local valLbl=Instance.new("TextLabel",row)
    valLbl.Size=UDim2.new(0.15,0,1,0);valLbl.Position=UDim2.new(0.5,0,0,0);valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.Code;valLbl.TextSize=11;valLbl.TextColor3=C_ACC;valLbl.TextXAlignment=Enum.TextXAlignment.Center
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0.3,0,0,6);track.Position=UDim2.new(0.68,0,0.5,-3);track.BackgroundColor3=C_OFF;track.BorderSizePixel=0
    local fill=Instance.new("Frame",track);fill.BackgroundColor3=C_ACC;fill.BorderSizePixel=0;fill.Size=UDim2.new(0,0,1,0)
    local dragging=false
    local function UpdateVal(x)
        local tA=track.AbsolutePosition.X;local tS=track.AbsoluteSize.X
        local pct=math.clamp((x-tA)/math.max(tS,1),0,1)
        local val=min_+(max_-min_)*pct
        if (max_-min_)<=20 then val=math.round(val*10)/10 else val=math.round(val) end
        setter(val);fill.Size=UDim2.new(pct,0,1,0);valLbl.Text=tostring(val)
    end
    local function RefreshDisplay()
        local val=getter();local pct=math.clamp((val-min_)/math.max(max_-min_,0.001),0,1)
        fill.Size=UDim2.new(pct,0,1,0);valLbl.Text=tostring(val)
    end
    RefreshDisplay()
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;UpdateVal(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then UpdateVal(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

local function MakeLabel(parent,text,order)
    local lbl=Instance.new("TextLabel",parent)
    lbl.Size=UDim2.new(1,0,0,18);lbl.BackgroundColor3=Color3.fromRGB(5,5,5);lbl.BorderSizePixel=0
    lbl.Font=Enum.Font.Code;lbl.TextSize=11;lbl.TextColor3=C_ACC
    lbl.Text="  "..text;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.LayoutOrder=order or 0
end

local function MakeDrop(parent,label,options,getter,setter,order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,28);row.BackgroundColor3=C_BTN;row.BorderSizePixel=0;row.LayoutOrder=order or 0
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.45,0,1,0);lbl.Position=UDim2.new(0,8,0,0);lbl.BackgroundTransparency=1
    lbl.Text=label;lbl.Font=Enum.Font.Code;lbl.TextSize=11;lbl.TextColor3=C_TXT;lbl.TextXAlignment=Enum.TextXAlignment.Left
    local cyc=Instance.new("TextButton",row)
    cyc.Size=UDim2.new(0.5,-8,0,20);cyc.Position=UDim2.new(0.5,0,0.5,-10)
    cyc.BackgroundColor3=C_PANEL;cyc.BorderColor3=C_ACC;cyc.BorderSizePixel=1
    cyc.Font=Enum.Font.Code;cyc.TextSize=10;cyc.TextColor3=C_ACC;cyc.Text=getter()
    cyc.MouseButton1Click:Connect(function()
        local cur=getter();local idx=1
        for i,v in ipairs(options) do if v==cur then idx=i;break end end
        idx=(idx%#options)+1;setter(options[idx]);cyc.Text=options[idx]
    end)
end

local o=0
-- RAGE
local rp=TabPanels["RAGE"]
MakeLabel(rp,"-- RAGE --",o);o=o+1
MakeToggle(rp,"Rage Enabled",function() return Cfg.Rage.Enabled end,function(v) Cfg.Rage.Enabled=v end,o);o=o+1
MakeToggle(rp,"Void Spam",function() return Cfg.Rage.VoidSpam end,function(v) Cfg.Rage.VoidSpam=v end,o);o=o+1
MakeSlider(rp,"Spam Rate",1,60,function() return Cfg.Rage.SpamRate end,function(v) Cfg.Rage.SpamRate=v end,o);o=o+1
MakeSlider(rp,"Aim Random",0,5,function() return Cfg.Rage.AimRand end,function(v) Cfg.Rage.AimRand=v end,o);o=o+1
MakeSlider(rp,"Pred Lead",0,1,function() return Cfg.Rage.PredictLead end,function(v) Cfg.Rage.PredictLead=v end,o);o=o+1
MakeDrop(rp,"Target Mode",{"Closest","Random","Weakest","Strongest"},function() return Cfg.Rage.TargetMode end,function(v) Cfg.Rage.TargetMode=v end,o);o=o+1
MakeToggle(rp,"Tp Attack",function() return Cfg.Rage.TpAttack end,function(v) Cfg.Rage.TpAttack=v end,o);o=o+1
MakeToggle(rp,"God Mode",function() return Cfg.Rage.GodMode end,function(v) Cfg.Rage.GodMode=v end,o);o=o+1
MakeSlider(rp,"God Y",-200,200,function() return Cfg.Rage.GodY end,function(v) Cfg.Rage.GodY=v end,o);o=o+1
MakeToggle(rp,"Spin Shot",function() return Cfg.Rage.SpinShot end,function(v) Cfg.Rage.SpinShot=v end,o);o=o+1
MakeSlider(rp,"Spin Speed",0,1440,function() return Cfg.Rage.SpinSpeed end,function(v) Cfg.Rage.SpinSpeed=v end,o);o=o+1
MakeLabel(rp,"-- VOID HIDE --",o);o=o+1
MakeToggle(rp,"Void Hide",function() return Cfg.VoidHide.Enabled end,function(v) Cfg.VoidHide.Enabled=v end,o);o=o+1
MakeDrop(rp,"Void Method",{"Drift","Chaos","Loop","Spiral","Quantum","TPEverywhere","OrbitTarget"},function() return Cfg.VoidHide.Method end,function(v) Cfg.VoidHide.Method=v end,o);o=o+1
MakeToggle(rp,"Void Killer",function() return Cfg.Misc.VoidKiller end,function(v) Cfg.Misc.VoidKiller=v end,o);o=o+1

-- AA
o=0;local ap=TabPanels["AA"]
MakeLabel(ap,"-- ANTI-AIM --",o);o=o+1
MakeToggle(ap,"Anti-Aim",function() return Cfg.AntiAim.Enabled end,function(v) Cfg.AntiAim.Enabled=v;if v then BindAntiAim() end end,o);o=o+1
MakeDrop(ap,"AA Mode",{"Spin","Jitter","Static","Up","Down","Side","RandomSpin","Custom"},function() return Cfg.AntiAim.Mode end,function(v) Cfg.AntiAim.Mode=v end,o);o=o+1
MakeSlider(ap,"Spin Speed",0,1440,function() return Cfg.AntiAim.SpinSpeed end,function(v) Cfg.AntiAim.SpinSpeed=v end,o);o=o+1
MakeSlider(ap,"Jitter Amp",0,90,function() return Cfg.AntiAim.Jitter end,function(v) Cfg.AntiAim.Jitter=v end,o);o=o+1
MakeSlider(ap,"Pitch",-180,180,function() return Cfg.AntiAim.Pitch end,function(v) Cfg.AntiAim.Pitch=v end,o);o=o+1
MakeSlider(ap,"Yaw",-360,360,function() return Cfg.AntiAim.Yaw end,function(v) Cfg.AntiAim.Yaw=v end,o);o=o+1
MakeToggle(ap,"Breathe Effect",function() return Cfg.AntiAim.BreatheEffect end,function(v) Cfg.AntiAim.BreatheEffect=v end,o);o=o+1
MakeSlider(ap,"Breathe Speed",0,5,function() return Cfg.AntiAim.BreatheSpeed end,function(v) Cfg.AntiAim.BreatheSpeed=v end,o);o=o+1
MakeSlider(ap,"Breathe Amp",0,90,function() return Cfg.AntiAim.BreatheAmp end,function(v) Cfg.AntiAim.BreatheAmp=v end,o);o=o+1
MakeToggle(ap,"Micro Jitter",function() return Cfg.AntiAim.MicroJitter end,function(v) Cfg.AntiAim.MicroJitter=v end,o);o=o+1
MakeToggle(ap,"Desync Mode",function() return Cfg.AntiAim.DesyncMode end,function(v) Cfg.AntiAim.DesyncMode=v end,o);o=o+1
MakeSlider(ap,"Desync Offset",0,360,function() return Cfg.AntiAim.DesyncOffset end,function(v) Cfg.AntiAim.DesyncOffset=v end,o);o=o+1
MakeToggle(ap,"Random Flip",function() return Cfg.AntiAim.RandomFlip end,function(v) Cfg.AntiAim.RandomFlip=v end,o);o=o+1
MakeToggle(ap,"Chaos Mode",function() return Cfg.AntiAim.ChaosMode end,function(v) Cfg.AntiAim.ChaosMode=v end,o);o=o+1
MakeToggle(ap,"Multi-Axis Spin",function() return Cfg.AntiAim.MultiAxisSpin end,function(v) Cfg.AntiAim.MultiAxisSpin=v end,o);o=o+1
MakeToggle(ap,"Roll",function() return Cfg.AntiAim.RollEnabled end,function(v) Cfg.AntiAim.RollEnabled=v end,o);o=o+1
MakeSlider(ap,"Roll Speed",0,720,function() return Cfg.AntiAim.RollSpeed end,function(v) Cfg.AntiAim.RollSpeed=v end,o);o=o+1
MakeToggle(ap,"Look At Random",function() return Cfg.AntiAim.LookAtRandom end,function(v) Cfg.AntiAim.LookAtRandom=v end,o);o=o+1

-- ESP
o=0;local ep=TabPanels["ESP"]
MakeLabel(ep,"-- ESP --",o);o=o+1
MakeToggle(ep,"ESP",function() return Cfg.ESP.Enabled end,function(v) Cfg.ESP.Enabled=v end,o);o=o+1
MakeToggle(ep,"Box",function() return Cfg.ESP.Box end,function(v) Cfg.ESP.Box=v end,o);o=o+1
MakeToggle(ep,"Names",function() return Cfg.ESP.Name end,function(v) Cfg.ESP.Name=v end,o);o=o+1
MakeToggle(ep,"Healthbar",function() return Cfg.ESP.Healthbar end,function(v) Cfg.ESP.Healthbar=v end,o);o=o+1
MakeToggle(ep,"Distance",function() return Cfg.ESP.Distance end,function(v) Cfg.ESP.Distance=v end,o);o=o+1
MakeToggle(ep,"Team Check",function() return Cfg.ESP.TeamCheck end,function(v) Cfg.ESP.TeamCheck=v end,o);o=o+1
MakeSlider(ep,"Max Dist",100,2000,function() return Cfg.ESP.MaxDist end,function(v) Cfg.ESP.MaxDist=v end,o);o=o+1

-- VISUAL
o=0;local vp=TabPanels["VISUAL"]
MakeLabel(vp,"-- VISUALS --",o);o=o+1
MakeToggle(vp,"Aura",function() return Cfg.Visuals.Aura end,function(v) Cfg.Visuals.Aura=v;ApplyAura(v) end,o);o=o+1
MakeDrop(vp,"Aura Mode",{"Cyber Blue","Fire","Poison","Shadow","Gold","Crimson"},function() return Cfg.Visuals.AuraMode end,function(v) Cfg.Visuals.AuraMode=v;if Cfg.Visuals.Aura then ApplyAura(true) end end,o);o=o+1
MakeToggle(vp,"Crosshair",function() return Cfg.Visuals.Crosshair end,function(v) Cfg.Visuals.Crosshair=v end,o);o=o+1
MakeToggle(vp,"Hit FX",function() return Cfg.Visuals.HitFX end,function(v) Cfg.Visuals.HitFX=v end,o);o=o+1
MakeToggle(vp,"Hit Sound",function() return Cfg.Visuals.HitSound end,function(v) Cfg.Visuals.HitSound=v end,o);o=o+1
MakeDrop(vp,"Sound Type",{"sparkle","ding","thud","ping"},function() return Cfg.Visuals.HitSoundFX end,function(v) Cfg.Visuals.HitSoundFX=v end,o);o=o+1
MakeToggle(vp,"Chams",function() return Cfg.Visuals.Chams end,function(v) Cfg.Visuals.Chams=v end,o);o=o+1
MakeToggle(vp,"Fullbright",function() return Cfg.Visuals.Fullbright end,function(v) Cfg.Visuals.Fullbright=v;pcall(function() if v then Lighting.Brightness=10 else Lighting.Brightness=2 end end) end,o);o=o+1
MakeToggle(vp,"FOV Circle",function() return Cfg.Visuals.FOVCircle end,function(v) Cfg.Visuals.FOVCircle=v end,o);o=o+1
MakeSlider(vp,"FOV Radius",10,500,function() return Cfg.Visuals.FOVRadius end,function(v) Cfg.Visuals.FOVRadius=v end,o);o=o+1
MakeToggle(vp,"Damage Markers",function() return Cfg.Visuals.DamageMarkers end,function(v) Cfg.Visuals.DamageMarkers=v end,o);o=o+1

-- MOVE
o=0;local mp=TabPanels["MOVE"]
MakeLabel(mp,"-- MOVEMENT --",o);o=o+1
MakeToggle(mp,"Fly",function() return Cfg.Movement.Fly end,function(v) Cfg.Movement.Fly=v;if not v then local h=GetHum(LP);if h then pcall(function() h.PlatformStand=false end) end end end,o);o=o+1
MakeSlider(mp,"Fly Speed",1,500,function() return Cfg.Movement.FlySpeed end,function(v) Cfg.Movement.FlySpeed=v end,o);o=o+1
MakeToggle(mp,"Noclip",function() return Cfg.Movement.Noclip end,function(v) Cfg.Movement.Noclip=v end,o);o=o+1
MakeToggle(mp,"Speed Mult",function() return Cfg.Movement.SpeedMult end,function(v) Cfg.Movement.SpeedMult=v end,o);o=o+1
MakeSlider(mp,"Speed Val",1,20,function() return Cfg.Movement.SpeedVal end,function(v) Cfg.Movement.SpeedVal=v end,o);o=o+1
MakeToggle(mp,"Click TP",function() return Cfg.Movement.ClickTP end,function(v) Cfg.Movement.ClickTP=v end,o);o=o+1
MakeToggle(mp,"TP to Target",function() return Cfg.Movement.TpToTarget end,function(v) Cfg.Movement.TpToTarget=v end,o);o=o+1
MakeSlider(mp,"TP Offset",0,20,function() return Cfg.Movement.TpOffset end,function(v) Cfg.Movement.TpOffset=v end,o);o=o+1
MakeLabel(mp,"-- ORBIT --",o);o=o+1
MakeToggle(mp,"Orbit",function() return Cfg.Orbit.Enabled end,function(v) Cfg.Orbit.Enabled=v;if v then BindOrbit() end end,o);o=o+1
MakeDrop(mp,"Orbit Mode",{"Circle","Figure8","Ellipse","SpiralIn","SpiralOut","Bounce","Lemniscate","Infinity","RandomOrbit"},function() return Cfg.Orbit.Mode end,function(v) Cfg.Orbit.Mode=v end,o);o=o+1
MakeSlider(mp,"Orbit Speed",10,360,function() return Cfg.Orbit.Speed end,function(v) Cfg.Orbit.Speed=v end,o);o=o+1
MakeSlider(mp,"Orbit Radius",1,40,function() return Cfg.Orbit.Radius end,function(v) Cfg.Orbit.Radius=v end,o);o=o+1
MakeSlider(mp,"Orbit Height",-10,20,function() return Cfg.Orbit.Height end,function(v) Cfg.Orbit.Height=v end,o);o=o+1
MakeToggle(mp,"Orbit Auto Shoot",function() return Cfg.Orbit.AutoShoot end,function(v) Cfg.Orbit.AutoShoot=v end,o);o=o+1

-- BYPASS
o=0;local bp=TabPanels["BYPASS"]
MakeLabel(bp,"-- PREDICTION V2 --",o);o=o+1
MakeToggle(bp,"Prediction V2",function() return Cfg.Pred.Enabled end,function(v) Cfg.Pred.Enabled=v;if v then BindPredV2() end end,o);o=o+1
MakeSlider(bp,"Aim Dot Thresh",0,1,function() return Cfg.Pred.AimDotThresh end,function(v) Cfg.Pred.AimDotThresh=v end,o);o=o+1
MakeSlider(bp,"Perp Strength",0,50,function() return Cfg.Pred.PerpStrength end,function(v) Cfg.Pred.PerpStrength=v end,o);o=o+1
MakeLabel(bp,"-- ANTI-BAIT V2 --",o);o=o+1
MakeToggle(bp,"Anti-Bait V2",function() return Cfg.AntiBait.Enabled end,function(v) Cfg.AntiBait.Enabled=v;if v then BindAntiBaitV2() end end,o);o=o+1
MakeDrop(bp,"Dodge Mode",{"Away","Perpendicular","Random"},function() return Cfg.AntiBait.DodgeMode end,function(v) Cfg.AntiBait.DodgeMode=v end,o);o=o+1
MakeSlider(bp,"Dodge Dist",5,60,function() return Cfg.AntiBait.DodgeDist end,function(v) Cfg.AntiBait.DodgeDist=v end,o);o=o+1
MakeLabel(bp,"-- ANTI-TRANSLOC --",o);o=o+1
MakeToggle(bp,"Anti-Transloc",function() return Cfg.AntiTransloc.Enabled end,function(v) Cfg.AntiTransloc.Enabled=v;if v then BindAntiTransloc() end end,o);o=o+1
MakeDrop(bp,"AT Mode",{"Freeze","Dodge"},function() return Cfg.AntiTransloc.Mode end,function(v) Cfg.AntiTransloc.Mode=v end,o);o=o+1
MakeLabel(bp,"-- VEL DESYNC --",o);o=o+1
MakeToggle(bp,"Vel Desync",function() return Cfg.VelDesync.Enabled end,function(v) Cfg.VelDesync.Enabled=v;if v then BindVelDesync() end end,o);o=o+1
MakeSlider(bp,"Intensity",0,100,function() return Cfg.VelDesync.Intensity end,function(v) Cfg.VelDesync.Intensity=v end,o);o=o+1
MakeToggle(bp,"Spike Mode",function() return Cfg.VelDesync.SpikeMode end,function(v) Cfg.VelDesync.SpikeMode=v end,o);o=o+1
MakeToggle(bp,"Counter Vel",function() return Cfg.VelDesync.CounterVel end,function(v) Cfg.VelDesync.CounterVel=v end,o);o=o+1
MakeToggle(bp,"Noise Vel",function() return Cfg.VelDesync.NoiseVel end,function(v) Cfg.VelDesync.NoiseVel=v end,o);o=o+1
MakeLabel(bp,"-- HITBOX --",o);o=o+1
MakeToggle(bp,"Hitbox Expand",function() return Cfg.Hitbox.Enabled end,function(v) Cfg.Hitbox.Enabled=v;if v then BindHitbox() end end,o);o=o+1
MakeSlider(bp,"Size",1,2500,function() return Cfg.Hitbox.Size end,function(v) Cfg.Hitbox.Size=v end,o);o=o+1
MakeToggle(bp,"Break Hitbox (2500)",function() return Cfg.Hitbox.BreakHitbox end,function(v) Cfg.Hitbox.BreakHitbox=v end,o);o=o+1
MakeToggle(bp,"Massless",function() return Cfg.Hitbox.Massless end,function(v) Cfg.Hitbox.Massless=v end,o);o=o+1
MakeLabel(bp,"-- SLING BYPASS --",o);o=o+1
MakeToggle(bp,"Sling Bypass",function() return Cfg.SlingBypass.Enabled end,function(v) Cfg.SlingBypass.Enabled=v;if v then BindSlingBypass() end end,o);o=o+1
MakeDrop(bp,"Sling Mode",{"Follow","Stalk","Hover","FastTp","TargetStick","OrbitTarget","RandomAroundTarget"},function() return Cfg.SlingBypass.Mode end,function(v) Cfg.SlingBypass.Mode=v end,o);o=o+1
MakeToggle(bp,"Sling Auto Shoot",function() return Cfg.SlingBypass.AutoShoot end,function(v) Cfg.SlingBypass.AutoShoot=v end,o);o=o+1
MakeToggle(bp,"Network Own",function() return Cfg.SlingBypass.NetworkOwn end,function(v) Cfg.SlingBypass.NetworkOwn=v end,o);o=o+1

-- MISC
o=0;local msp=TabPanels["MISC"]
MakeLabel(msp,"-- MISC --",o);o=o+1
MakeToggle(msp,"Watermark",function() return Cfg.Misc.Watermark end,function(v) Cfg.Misc.Watermark=v;WaterLbl.Visible=v end,o);o=o+1
MakeToggle(msp,"Anti-AFK",function() return Cfg.Misc.AntiAFK end,function(v) Cfg.Misc.AntiAFK=v end,o);o=o+1
MakeToggle(msp,"Staff Detect",function() return Cfg.StaffDetect.Enabled end,function(v) Cfg.StaffDetect.Enabled=v end,o);o=o+1
MakeToggle(msp,"Staff Auto-Hop",function() return Cfg.StaffDetect.AutoHop end,function(v) Cfg.StaffDetect.AutoHop=v end,o);o=o+1
MakeToggle(msp,"Unlock FPS",function() return Cfg.Misc.UnlockFPS end,function(v) Cfg.Misc.UnlockFPS=v;if v then pcall(setfpscap,Cfg.Misc.TargetFPS) end end,o);o=o+1
MakeSlider(msp,"Target FPS",30,240,function() return Cfg.Misc.TargetFPS end,function(v) Cfg.Misc.TargetFPS=v;if Cfg.Misc.UnlockFPS then pcall(setfpscap,v) end end,o);o=o+1
MakeLabel(msp,"-- FAKE POS DESYNC --",o);o=o+1
MakeToggle(msp,"FakePos Desync",function() return Cfg.FakePos.Enabled end,function(v) Cfg.FakePos.Enabled=v;BindFakePos() end,o);o=o+1
MakeSlider(msp,"Depth",0,20,function() return Cfg.FakePos.Depth end,function(v) Cfg.FakePos.Depth=v end,o);o=o+1
MakeToggle(msp,"Panic Mode",function() return Cfg.FakePos.Panic end,function(v) Cfg.FakePos.Panic=v end,o);o=o+1
MakeToggle(msp,"Zero Velocity",function() return Cfg.FakePos.ZeroVelocity end,function(v) Cfg.FakePos.ZeroVelocity=v end,o);o=o+1
MakeToggle(msp,"Hide Meshes",function() return Cfg.FakePos.HideMeshes end,function(v) Cfg.FakePos.HideMeshes=v end,o);o=o+1
MakeToggle(msp,"Ghost Visualizer",function() return Cfg.FakePos.GhostVis end,function(v) Cfg.FakePos.GhostVis=v;BindFakePos() end,o);o=o+1
MakeToggle(msp,"Camera Elevation",function() return Cfg.FakePos.CamElevation end,function(v) Cfg.FakePos.CamElevation=v end,o);o=o+1

-- EXTRA
o=0;local xp=TabPanels["EXTRA"]
MakeLabel(xp,"-- RIOT GODMODE --",o);o=o+1
MakeToggle(xp,"Riot Godmode",function() return Cfg.Riot.GodmodeEnabled end,function(v) Cfg.Riot.GodmodeEnabled=v;if v then BindRiotGodmode() end end,o);o=o+1
MakeSlider(xp,"Min Jump",0,50,function() return Cfg.Riot.MinJump end,function(v) Cfg.Riot.MinJump=v end,o);o=o+1
MakeSlider(xp,"Max Jump",0,100,function() return Cfg.Riot.MaxJump end,function(v) Cfg.Riot.MaxJump=v end,o);o=o+1
MakeToggle(xp,"Ground Snap",function() return Cfg.Riot.GroundSnap end,function(v) Cfg.Riot.GroundSnap=v end,o);o=o+1
MakeToggle(xp,"Phase Mode",function() return Cfg.Riot.PhaseMode end,function(v) Cfg.Riot.PhaseMode=v end,o);o=o+1
MakeToggle(xp,"Avoid Bullets",function() return Cfg.Riot.AvoidBullets end,function(v) Cfg.Riot.AvoidBullets=v end,o);o=o+1
MakeToggle(xp,"Riot AutoShoot",function() return Cfg.Riot.AutoShoot end,function(v) Cfg.Riot.AutoShoot=v end,o);o=o+1
MakeLabel(xp,"-- RIOT ABUSER --",o);o=o+1
MakeToggle(xp,"Riot Abuser",function() return Cfg.Riot.AbuserEnabled end,function(v) Cfg.Riot.AbuserEnabled=v;if v then BindRiotAbuser() end end,o);o=o+1
MakeDrop(xp,"Abuser Mode",{"Stick","Bounce","Orbit","Phase"},function() return Cfg.Riot.AbuserMode end,function(v) Cfg.Riot.AbuserMode=v end,o);o=o+1
MakeToggle(xp,"Spin On Target",function() return Cfg.Riot.SpinOnTarget end,function(v) Cfg.Riot.SpinOnTarget=v end,o);o=o+1
MakeToggle(xp,"Force Face",function() return Cfg.Riot.ForceFace end,function(v) Cfg.Riot.ForceFace=v end,o);o=o+1
MakeToggle(xp,"Zero Vel Match",function() return Cfg.Riot.RaVelZero end,function(v) Cfg.Riot.RaVelZero=v end,o);o=o+1
MakeToggle(xp,"Predict Target",function() return Cfg.Riot.PredictTarget end,function(v) Cfg.Riot.PredictTarget=v end,o);o=o+1
MakeToggle(xp,"Random Offset",function() return Cfg.Riot.RandomOffset end,function(v) Cfg.Riot.RandomOffset=v end,o);o=o+1
MakeToggle(xp,"Abuser AutoShoot",function() return Cfg.Riot.AutoShoot end,function(v) Cfg.Riot.AutoShoot=v end,o);o=o+1

-- canvas size update
for _,panel in pairs(TabPanels) do
    local layout=panel:FindFirstChildOfClass("UIListLayout")
    if layout then
        local function upd() panel.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8) end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd);upd()
    end
end

-- Click TP
UserInputService.InputBegan:Connect(function(inp,proc)
    if proc then return end
    if inp.UserInputType==Enum.UserInputType.MouseButton2 and Cfg.Movement.ClickTP then
        local hrp=GetHRP(LP); if not hrp then return end
        local ray=Cam:ScreenPointToRay(inp.Position.X,inp.Position.Y)
        local result=Workspace:Raycast(ray.Origin,ray.Direction*1000)
        if result then pcall(function() hrp.CFrame=CFrame.new(result.Position+Vector3.new(0,3,0)) end) end
    end
end)

SetTab("RAGE")
CacheRemotes()
Notify("UNCODE v4 loaded | RCtrl = toggle",4)
