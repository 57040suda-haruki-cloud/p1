print("[UNCODE v7] loading...")
task.wait(0.1)

-- ============================================================
-- THREAD IDENTITY ELEVATION
-- ============================================================
do
    if not getgenv().__UC7_Applied then
        getgenv().__UC7_Applied = true
        pcall(function() if setthreadidentity then setthreadidentity(8) end end)
    end
end

-- ============================================================
-- EXECUTOR API STUBS (safe fallbacks)
-- ============================================================
local GE = (getgenv and getgenv()) or _G
do
    local stubs = {
        hookmetamethod    = function(o,m,h) return nil end,
        hookfunction      = function(f,h) return f end,
        newcclosure       = function(f) return f end,
        checkcaller       = function() return false end,
        iscclosure        = function(f) return false end,
        cloneref          = function(o) return o end,
        getgc             = function() return {} end,
        getscripts        = function() return {} end,
        getscriptbytecode = function() return "" end,
        setthreadidentity = function() end,
        getthreadidentity = function() return 2 end,
        setreadonly       = function() end,
        getrawmetatable   = function(o) return getmetatable(o) end,
        setclipboard      = function() end,
        getclipboard      = function() return "" end,
        gethui            = function() return game:GetService("CoreGui") end,
        getfenv           = getfenv or function() return {} end,
        getconnections    = function() return {} end,
        getloadedmodules  = function() return {} end,
    }
    for k,v in pairs(stubs) do
        if rawget(GE,k)==nil then GE[k]=v end
    end
end
pcall(setthreadidentity, 8)

-- ============================================================
-- SERVICES
-- ============================================================
repeat task.wait() until game:IsLoaded()

local Players    = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UIS        = cloneref(game:GetService("UserInputService"))
local RS         = cloneref(game:GetService("ReplicatedStorage"))
local RF         = cloneref(game:GetService("ReplicatedFirst"))
local Lighting   = cloneref(game:GetService("Lighting"))
local HTTP       = cloneref(game:GetService("HttpService"))
local CoreGui    = cloneref(game:GetService("CoreGui"))
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ============================================================
-- CHARACTER STATE
-- ============================================================
local char, root, hum
local function bindChar(c)
    char=c; root=nil; hum=nil
    if not c then return end
    root = c:WaitForChild("HumanoidRootPart",5)
    hum  = c:WaitForChild("Humanoid",5)
end
if LP.Character then task.spawn(bindChar, LP.Character) end
LP.CharacterAdded:Connect(function(c) task.delay(0.15,bindChar,c) end)
LP.CharacterRemoving:Connect(function() char=nil; root=nil; hum=nil end)

-- ============================================================
-- CONNECTION MANAGEMENT HELPERS
-- ============================================================
local Conns={} local Binds={}
local function KC(k) if Conns[k] then pcall(Conns[k].Disconnect,Conns[k]); Conns[k]=nil end end
local function AC(k,c) KC(k); Conns[k]=c end
local function AB(k,p,f) if Binds[k] then pcall(RunService.UnbindFromRenderStep,RunService,k) end; Binds[k]=true; RunService:BindToRenderStep(k,p,f) end
local function KB(k) if Binds[k] then pcall(RunService.UnbindFromRenderStep,RunService,k); Binds[k]=nil end end

-- ============================================================
-- TARGET SELECTION
-- ============================================================
local function getClosest(byFOV)
    if not root then return nil end
    local best,bd = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP or not p.Character then continue end
        local r = p.Character:FindFirstChild("HumanoidRootPart")
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if not r or not h or h.Health<=0 then continue end
        local d
        if byFOV then
            local sp,vis = Camera:WorldToViewportPoint(r.Position)
            if not vis then continue end
            d = (Vector2.new(sp.X,sp.Y)-Camera.ViewportSize/2).Magnitude
        else
            d = (root.Position-r.Position).Magnitude
        end
        if d<bd then bd=d; best=p end
    end
    return best
end

-- ============================================================
-- AC BYPASS
-- ============================================================
local stateAC = {bypassed=false}
pcall(function()
    local function HookKick()
        for _,nm in ipairs({"Kick","kick"}) do
            local f=LP[nm]
            if type(f)=="function" then
                local old; old=hookfunction(f,newcclosure(function(self,...)
                    if self==LP and not checkcaller() then return end
                    return old(self,...)
                end))
            end
        end
    end
    local function HookAC(ac)
        if not ac then return end
        local oi; oi=hookmetamethod(ac,"__index",newcclosure(function(t,k)
            if t==ac and not checkcaller() and k=="Enabled" and not stateAC.bypassed then return false end
            if checkcaller() then return oi(t,k) end
            local old=getthreadidentity(); if old~=2 then setthreadidentity(2) end
            local r=oi(t,k); if old~=2 then setthreadidentity(old) end; return r
        end))
        local oni; oni=hookmetamethod(ac,"__newindex",newcclosure(function(t,k,v)
            if t==ac and not checkcaller() and k=="Enabled" and not stateAC.bypassed then return end
            if checkcaller() then return oni(t,k,v) end
            local old=getthreadidentity(); if old~=2 then setthreadidentity(2) end
            oni(t,k,v); if old~=2 then setthreadidentity(old) end
        end))
    end
    task.spawn(function()
        local kw={"ban","kick","moderation","anticheat","detection","ban_check","detect"}
        local function proc(o)
            pcall(function()
                if not(o:IsA("LocalScript") or o:IsA("ModuleScript")) then return end
                local nm=o.Name:lower()
                for _,t in ipairs(kw) do if nm:find(t) then pcall(function() o.Disabled=true end); break end end
            end)
        end
        for _,d in ipairs(game:GetDescendants()) do proc(d) end
        game.DescendantAdded:Connect(proc)
    end)
    task.spawn(function()
        local ac=RF:WaitForChild("LocalScript3",12)
        if ac then HookAC(ac); HookKick(); pcall(function() ac.Enabled=false end); stateAC.bypassed=true end
    end)
end)

-- ============================================================
-- ITEM LIBRARY COOLDOWN PATCH (KiciaHook)
-- ============================================================
task.spawn(function()
    task.wait(3)
    pcall(function()
        local IL = require(RS.Modules.ItemLibrary)
        local function scan(t)
            for _,v in pairs(t) do
                if type(v)=="table" then
                    if v.ShootCooldown       ~= nil then v.ShootCooldown=0.000001 end
                    if v.AttackCooldown      ~= nil then v.AttackCooldown=0.000001 end
                    if v.HeavyAttackCooldown ~= nil then v.HeavyAttackCooldown=0.000001 end
                    scan(v)
                end
            end
        end
        scan(IL)
        print("[UNCODE v7] ItemLibrary cooldowns patched")
    end)
end)

-- ============================================================
-- REMOTE DISCOVERY
-- ============================================================
local _atkRemCache = nil
local function findAtkRemote()
    local rem = RS:FindFirstChild("Remotes"); if not rem then return nil end
    for _,r in ipairs(rem:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            local nm=r.Name:lower()
            if nm:find("useitem") or nm:find("attack") or nm:find("fight") then
                _atkRemCache=r; return r
            end
        end
    end
    return nil
end
task.spawn(findAtkRemote)
RS.DescendantAdded:Connect(function(d)
    if d:IsA("RemoteEvent") then _atkRemCache=nil; task.delay(0.1,findAtkRemote) end
end)

-- ============================================================
-- POSITION SPOOF / REMOTE HOOK
-- ============================================================
local PB = {enabled=false, spoof=true, pred=true, expand=0.18, lerp=0.88, spd=90, predMult=1}
local projSpoofed = nil

local function predictTarget(tr, origin)
    local vel=tr.AssemblyLinearVelocity
    local prev=tr:GetAttribute("PV") or vel
    local acc=(vel-prev)/0.1
    tr:SetAttribute("PV",vel)
    local dist=(origin-tr.Position).Magnitude
    local t=(dist/math.max(PB.spd,1))*PB.predMult
    return tr.Position + vel*t + 0.5*acc*t*t
end

local function hookRemotes()
    local rem = RS:FindFirstChild("Remotes"); if not rem then return end
    for _,r in ipairs(rem:GetDescendants()) do
        if r:IsA("RemoteEvent") and not r:GetAttribute("_uc7_hooked") then
            r:SetAttribute("_uc7_hooked",true)
            local old=r.FireServer
            r.FireServer = function(self,data,...)
                if PB.enabled and PB.spoof and type(data)=="table" then
                    local sc=projSpoofed or Camera.CFrame
                    if data.Origin   ~=nil then data.Origin   =sc.Position end
                    if data.Position ~=nil then data.Position =sc.Position end
                    if data.CFrame   ~=nil then data.CFrame   =sc end
                    if data.LookDir  ~=nil then data.LookDir  =sc.LookVector end
                    if data.Source   ~=nil then data.Source   =sc.Position end
                    if data.Spread   ~=nil then data.Spread   =0 end
                    if data.attackNum~=nil then data.attackNum=data.attackNum or math.random(1,9999) end
                end
                return old(self,data,...)
            end
        end
    end
end
task.spawn(hookRemotes)
RS.DescendantAdded:Connect(function(d) if d:IsA("RemoteEvent") then task.delay(0.1,hookRemotes) end end)

AB("uc7_proj",Enum.RenderPriority.Camera.Value+5,function()
    if not PB.enabled then return end
    local t=getClosest(); local orig=Camera.CFrame.Position
    if t and t.Character then
        local tr=t.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local pos=PB.pred and predictTarget(tr,orig) or tr.Position
            local aim=pos+(pos-orig).Unit*PB.expand
            projSpoofed=CFrame.new(orig,aim)
            Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(orig,aim),PB.lerp)
            return
        end
    end
    projSpoofed=Camera.CFrame
end)

-- ============================================================
-- VOID SYSTEM
-- ============================================================
local VCFG = {
    enabled=false, method="Quantum",
    speed=1e9, chaos=0.98, altitude=1e10, radius=2e11,
    evade=true, evadeR=8e9, evadeS=6e9, evadeV=3e9,
    evadeCD=0.05, evadeTrig=1.0, evadeStr=1.0,
}
local vElapsed=0; local vPos=Vector3.new(0,1e10,0)
local vDrift=Vector3.new(1,0,0).Unit; local vBase=Vector3.new(0,1e10,0)
local vEvadeCD=0; local vX=math.random(-1e8,1e8); local vZ=math.random(-1e8,1e8)
local vYOff=0; local vYDir=1

local function noise3D(t)
    local nx,ny,nz,a,f=0,0,0,1,0.0001
    for _=1,4 do nx=nx+math.noise(t*f,0,0)*a; ny=ny+math.noise(0,t*f,0)*a; nz=nz+math.noise(0,0,t*f)*a; f=f*2.37; a=a*0.5 end
    local l=math.sqrt(nx*nx+ny*ny+nz*nz); if l<0.001 then return 1,0,0 end
    return nx/l,ny/l,nz/l
end

local function stepVoid(dt)
    vElapsed=vElapsed+dt
    local m=VCFG.method; local B=VCFG.altitude; local R=VCFG.radius; local S=VCFG.speed
    if     m=="Drift"      then local dx,dy,dz=noise3D(vElapsed); vDrift=vDrift:Lerp(Vector3.new(dx,dy,dz).Unit,VCFG.chaos*dt*10); vPos=vPos+vDrift*S*dt; if (vPos-vBase).Magnitude>R then vPos=vBase+(vPos-vBase).Unit*R; vDrift=-vDrift end
    elseif m=="Chaos"      then vPos=vPos+Vector3.new((math.random()-0.5)*S*dt*5,(math.random()-0.5)*S*dt*5,(math.random()-0.5)*S*dt*5); if (vPos-vBase).Magnitude>R then vPos=vBase+(vPos-vBase).Unit*R end
    elseif m=="Quantum"    then local r=R*(math.random()>0.5 and 1 or -1); vPos=vBase+Vector3.new(r+(math.random()-0.5)*R,(math.random()-0.5)*R*0.2,r+(math.random()-0.5)*R)
    elseif m=="Loop"       then local r=math.min(R*0.8,(vElapsed%100)*1e7); vPos=vBase+Vector3.new(math.cos(vElapsed*2)*r,math.sin(vElapsed*1.3)*r*0.2,math.sin(vElapsed*2)*r)
    elseif m=="Spiral"     then local r=math.min(R*0.9,(vElapsed%50)*2e9); vPos=vBase+Vector3.new(math.cos(vElapsed*3)*r,math.sin(vElapsed*0.5)*r*0.3,math.sin(vElapsed*3)*r)
    elseif m=="Still"      then vPos=Vector3.new(vX,B,vZ)
    elseif m=="Circle"     then vPos=Vector3.new(vX+math.cos(vElapsed*3)*R,B,vZ+math.sin(vElapsed*3)*R)
    elseif m=="Figure8"    then vPos=Vector3.new(vX+math.sin(vElapsed*2)*R,B,vZ+math.sin(vElapsed*3)*R)
    elseif m=="WideSweep"  then vPos=Vector3.new(vX+math.sin(vElapsed*15)*R,B+math.cos(vElapsed*1.5)*R*0.1,vZ+math.cos(vElapsed*15)*R)
    elseif m=="FastBounce" then local r=R*math.sin(vElapsed*50); vPos=Vector3.new(vX+r,B+math.cos(vElapsed*50)*1e10,vZ+r)
    elseif m=="Blink"      then vPos=(vElapsed%0.1<0.05) and Vector3.new(vX*2,B+1e11,vZ*2) or Vector3.new(vX,B,vZ)
    elseif m=="GridHop"    then local c=5e8; local s=math.floor(vElapsed*8); vPos=Vector3.new(vX+(s%5-2)*c,B+(s%2==0 and 0 or c*0.18),vZ+(math.floor(s/5)%5-2)*c)
    elseif m=="HeightWave" then vPos=Vector3.new(vX+math.cos(vElapsed*0.4)*R,B+math.sin(vElapsed)*R*0.35,vZ+math.sin(vElapsed*0.4)*R)
    elseif m=="NoiseCloud" then vPos=Vector3.new(vX+math.noise(vElapsed,0,0)*R,B+math.noise(0,vElapsed,0)*R*0.25,vZ+math.noise(0,0,vElapsed)*R)
    elseif m=="SlowDrift"  then vYOff=vYOff+vYDir*S*dt*0.4; if math.abs(vYOff)>R*0.5 then vYDir=-vYDir end; vPos=Vector3.new(vX,B+vYOff,vZ)
    end
    return vPos
end

local function checkVoidEvade()
    if not VCFG.evade or vEvadeCD>0 then return end
    local minD,tv=math.huge,Vector3.new()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP or not p.Character then continue end
        local r=p.Character:FindFirstChild("HumanoidRootPart"); if not r then continue end
        local pred=r.Position+r.AssemblyLinearVelocity*0.5
        local d=(pred-vPos).Magnitude
        if d<minD then minD=d; tv=(pred-vPos).Unit end
    end
    if minD<VCFG.evadeR*VCFG.evadeTrig then
        vPos=vPos-tv*VCFG.evadeS*(1+(1-minD/(VCFG.evadeR*VCFG.evadeTrig))*2)*VCFG.evadeStr*0.5
        if (vPos-vBase).Magnitude>VCFG.radius then vPos=vBase+(vPos-vBase).Unit*VCFG.radius end
        vEvadeCD=VCFG.evadeCD
    end
end

local function startVoid()
    KC("void")
    if root then vPos=Vector3.new(root.Position.X,VCFG.altitude,root.Position.Z) end
    vBase=Vector3.new(0,VCFG.altitude,0); vElapsed=0
    AC("void",RunService.Heartbeat:Connect(function(dt)
        if not VCFG.enabled then KC("void"); return end
        vEvadeCD=math.max(0,vEvadeCD-dt)
        checkVoidEvade(); vPos=stepVoid(dt)
        if not root then return end
        pcall(function()
            root.CFrame=CFrame.new(vPos)
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            if math.random(1,10)==1 then
                root.AssemblyLinearVelocity=Vector3.new((math.random()-0.5)*2e7,(math.random()-0.5)*2e7,(math.random()-0.5)*2e7)
            end
        end)
    end))
end
local function stopVoid() KC("void"); VCFG.enabled=false end

-- ============================================================
-- ORBIT SYSTEM
-- ============================================================
local OCFG = {enabled=false,speed=90,dist=8,height=0,lerp=0.3,mode="Circle",predict=false,predStr=0.2,faceTarget=true,maxLockDist=50}
local oAngle=0; local oElapsed=0; local oCurR=8

local function startOrbit()
    KC("orbit"); oAngle=0; oElapsed=0; oCurR=OCFG.dist
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
    AC("orbit",RunService.Heartbeat:Connect(function(dt)
        if not OCFG.enabled then KC("orbit"); return end
        if not root then return end
        local t=getClosest(); if not t or not t.Character then return end
        local tr=t.Character:FindFirstChild("HumanoidRootPart"); if not tr then return end
        if (root.Position-tr.Position).Magnitude>OCFG.maxLockDist then return end
        local tp=OCFG.predict and tr.Position+tr.AssemblyLinearVelocity*OCFG.predStr or tr.Position
        oAngle=oAngle+math.rad(OCFG.speed)*dt; oElapsed=oElapsed+dt
        local r=OCFG.dist; local h=OCFG.height; local x,y,z=0,h,0
        local m=OCFG.mode
        if     m=="Circle"   then x=math.cos(oAngle)*r; z=math.sin(oAngle)*r
        elseif m=="Figure8"  then x=math.sin(oAngle)*r; z=math.sin(oAngle)*math.cos(oAngle)*r*0.7
        elseif m=="SpiralIn" then oCurR=math.max(1,oCurR-dt*2); x=math.cos(oAngle)*oCurR; z=math.sin(oAngle)*oCurR
        elseif m=="SpiralOut"then oCurR=math.min(r*2,oCurR+dt*2); x=math.cos(oAngle)*oCurR; z=math.sin(oAngle)*oCurR
        elseif m=="Bounce"   then x=math.cos(oAngle)*r; z=math.sin(oAngle)*r; y=h+math.sin(oElapsed*3)*5
        elseif m=="Lemniscate" then local s=1/(1+math.sin(oAngle)^2); x=r*math.cos(oAngle)*s; z=r*math.sin(oAngle)*math.cos(oAngle)*s
        end
        local dst=tp+Vector3.new(x,y,z)
        local sm=root.Position:Lerp(dst,OCFG.lerp)
        pcall(function()
            root.CFrame=OCFG.faceTarget and CFrame.new(sm,Vector3.new(tp.X,sm.Y,tp.Z)) or CFrame.new(sm)
        end)
    end))
end
local function stopOrbit() KC("orbit"); OCFG.enabled=false end

-- ============================================================
-- ANTI-AIM SYSTEM
-- ============================================================
local ACFG={enabled=false,mode="Spin",speed=5000,angle=90,randSpeed=true,jitterPitch=true}
local aaAcc=0; local aaJS=0; local aaRT=0; local aaRM=1

local function startAntiAim()
    KC("antiaim")
    AC("antiaim",RunService.Heartbeat:Connect(function(dt)
        if not ACFG.enabled or not root then KC("antiaim"); return end
        local spd=ACFG.speed
        if ACFG.randSpeed then
            aaRT=aaRT+dt; if aaRT>0.1 then aaRT=0; aaRM=0.2+math.random()*0.8 end
            spd=spd*aaRM
        end
        pcall(function()
            if ACFG.mode=="Spin" then
                aaAcc=aaAcc+spd*dt
                root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(aaAcc),0)
            elseif ACFG.mode=="Jitter" then
                local a=aaJS==0 and ACFG.angle or -ACFG.angle
                root.CFrame=root.CFrame*CFrame.Angles(ACFG.jitterPitch and math.rad(a)*0.3 or 0,math.rad(a),0)
                aaJS=(aaJS+1)%2
            elseif ACFG.mode=="Static" then
                root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(ACFG.angle),0)
            end
        end)
    end))
end
local function stopAntiAim() KC("antiaim"); ACFG.enabled=false end

-- ============================================================
-- DODGE SYSTEM
-- ============================================================
local DCFG={enabled=false,radius=20,dist=30,cooldown=0.3,threshold=800,mult=1}
local lastDodge=0

local function startDodge()
    KC("dodge")
    AC("dodge",RunService.Heartbeat:Connect(function(dt)
        if not DCFG.enabled or not root then KC("dodge"); return end
        local myPos=root.Position
        for _,p in ipairs(Players:GetPlayers()) do
            if p==LP or not p.Character then continue end
            local r=p.Character:FindFirstChild("HumanoidRootPart"); if not r then continue end
            local vel=r.AssemblyLinearVelocity
            if vel.Magnitude<=DCFG.threshold then continue end
            local pred=r.Position+vel*(dt*3*DCFG.mult)
            if (pred-myPos).Magnitude<DCFG.radius and tick()-lastDodge>DCFG.cooldown then
                lastDodge=tick()
                local perp=Vector3.new(-vel.Z,0,vel.X).Unit
                local dir=math.random(0,1)==0 and perp or -perp
                pcall(function() root.CFrame=CFrame.new(myPos+dir*DCFG.dist) end)
                break
            end
        end
    end))
end
local function stopDodge() KC("dodge"); DCFG.enabled=false end

-- ============================================================
-- RIOT SYSTEM
-- ============================================================
local RCFG={enabled=false,speed=0.03,range=50,evadeRange=30,spinSpeed=180}
local rTimer=0; local rAngle=0

local function startRiot()
    KC("riot")
    AC("riot",RunService.Heartbeat:Connect(function(dt)
        if not RCFG.enabled or not root then KC("riot"); return end
        rTimer=rTimer+dt; if rTimer<RCFG.speed then return end; rTimer=0
        local cp=root.Position; local t=getClosest(); local np=cp
        if t and t.Character then
            local tr=t.Character:FindFirstChild("HumanoidRootPart")
            if tr and (cp-tr.Position).Magnitude<RCFG.evadeRange then
                local dir=(cp-tr.Position).Unit
                np=cp+dir*math.random(RCFG.range*0.5,RCFG.range*1.5)
            else
                local a=math.random()*2*math.pi
                np=cp+Vector3.new(math.cos(a)*math.random(RCFG.range*0.2,RCFG.range),math.random(-RCFG.range*0.5,RCFG.range*0.5),math.sin(a)*math.random(RCFG.range*0.2,RCFG.range))
            end
        else
            local a=math.random()*2*math.pi
            np=cp+Vector3.new(math.cos(a)*math.random(5,RCFG.range),math.random(-5,5),math.sin(a)*math.random(5,RCFG.range))
        end
        rAngle=rAngle+RCFG.spinSpeed*dt; if rAngle>=360 then rAngle=rAngle-360 end
        pcall(function() root.CFrame=CFrame.new(np)*CFrame.Angles(0,math.rad(rAngle),0); root.AssemblyLinearVelocity=Vector3.zero end)
    end))
end
local function stopRiot() KC("riot"); RCFG.enabled=false end

-- Riot Abuse
local RABCFG={enabled=false,mode="Stick",height=3,forward=0,right=0,down=0}

local function startRiotAbuse()
    KC("riotabuse")
    AC("riotabuse",RunService.Heartbeat:Connect(function()
        if not RABCFG.enabled or not root then KC("riotabuse"); return end
        local t=getClosest(); if not t or not t.Character then return end
        local tr=t.Character:FindFirstChild("HumanoidRootPart"); if not tr then return end
        local off=Vector3.new(RABCFG.right,RABCFG.height-RABCFG.down,RABCFG.forward)
        pcall(function()
            if RABCFG.mode=="Stick" then root.CFrame=CFrame.new(tr.Position+off)
            elseif RABCFG.mode=="Bounce" then
                root.CFrame=CFrame.new(tr.Position+Vector3.new(RABCFG.right,math.abs(math.sin(tick()*8))*math.abs(RABCFG.height)-RABCFG.down,RABCFG.forward))
            end
            root.AssemblyLinearVelocity=Vector3.zero
        end)
    end))
end
local function stopRiotAbuse() KC("riotabuse"); RABCFG.enabled=false end

-- ============================================================
-- RAGEBOT
-- ============================================================
local rbAtk=0
local rbResolver={
    angles={0,30,60,90,120,150,180,210,240,270,300,330},
    idx=1, shotsSinceAdvance=0, advanceEvery=3,
    hitBias={}, lastTargetName=nil,
    onHit=function(self,angle) self.hitBias[angle]=(self.hitBias[angle] or 0)+1 end,
    get=function(self) return self.angles[self.idx] end,
    advance=function(self)
        local best,bestScore=nil,-1
        for _,a in ipairs(self.angles) do
            local s=self.hitBias[a] or 0
            if s>bestScore and a~=self.angles[self.idx] then bestScore=s; best=a end
        end
        if best and bestScore>0 then for i,a in ipairs(self.angles) do if a==best then self.idx=i; return end end end
        self.idx=(self.idx%#self.angles)+1
    end,
}

AC("ragebot",RunService.Heartbeat:Connect(function()
    if not Conns["ragebot_on"] then return end -- guard below replaces this
end))
KC("ragebot")

AC("ragebot",RunService.Heartbeat:Connect(function()
    if not (GE.UC7_Toggles and GE.UC7_Toggles.RB_On and GE.UC7_Toggles.RB_On.Value) then return end
    local intv=((GE.UC7_Options and GE.UC7_Options.RB_Interval and GE.UC7_Options.RB_Interval.Value) or 50)/1000
    if tick()-rbAtk<intv then return end; rbAtk=tick()
    local t=getClosest(); if not t or not t.Character then return end
    local tr=t.Character:FindFirstChild("HumanoidRootPart"); if not tr then return end
    local okPos,rawPos=pcall(function() return tr.Position end)
    local pos=okPos and rawPos or Vector3.zero

    if GE.UC7_Toggles.RB_Snap and GE.UC7_Toggles.RB_Snap.Value and root then
        pcall(function()
            local sd=(GE.UC7_Options.RB_SnapDist and GE.UC7_Options.RB_SnapDist.Value) or 4
            local dir=pos-root.Position; local dist=dir.Magnitude
            if dist>0.1 then root.CFrame=CFrame.new(pos-dir.Unit*math.min(sd,dist)) end
        end)
    end

    local resolverOff=0
    if GE.UC7_Toggles.Resolver_On and GE.UC7_Toggles.Resolver_On.Value then
        local tn=t.Name
        if rbResolver.lastTargetName~=tn then
            rbResolver.lastTargetName=tn; rbResolver.idx=1; rbResolver.shotsSinceAdvance=0
        end
        resolverOff=rbResolver:get()
        rbResolver.shotsSinceAdvance=rbResolver.shotsSinceAdvance+1
        if rbResolver.shotsSinceAdvance>=rbResolver.advanceEvery then
            rbResolver.shotsSinceAdvance=0; rbResolver:advance()
        end
    end

    local burst=GE.UC7_Toggles.RB_Burst and GE.UC7_Toggles.RB_Burst.Value
    local baseAngles=burst and {0,90,180,270} or {0}
    local weapon=(GE.UC7_Options.RB_Weapon and GE.UC7_Options.RB_Weapon.Value) or "Sword"
    local atkRem=_atkRemCache or findAtkRemote()
    for _,extra in ipairs(baseAngles) do
        if not atkRem then break end
        local bPos=pos+CFrame.Angles(0,math.rad(extra+resolverOff),0)*Vector3.new(0,0,0.4)
        pcall(function()
            atkRem:FireServer({
                id=HTTP:GenerateGUID(false),item=weapon,position=bPos,
                attackNum=math.random(1,9999),heavyAttackNum=math.random(1,9999),
                rotation=tr.CFrame.Rotation,one=Vector3.one,startAiming=true,
                packed={"\x00","\x01","\x02","\x03"},
            })
        end)
    end
end))

-- ============================================================
-- FLY MODE
-- ============================================================
local FLYCFG={enabled=false}
local _flyBG,_flyBV=nil,nil

local function startFly()
    KC("fly"); if not root then return end
    pcall(function()
        _flyBG=Instance.new("BodyGyro"); _flyBG.MaxTorque=Vector3.new(1e9,1e9,1e9); _flyBG.P=1e5; _flyBG.D=100; _flyBG.Parent=root
        _flyBV=Instance.new("BodyVelocity"); _flyBV.MaxForce=Vector3.new(1e9,1e9,1e9); _flyBV.Velocity=Vector3.zero; _flyBV.Parent=root
    end)
    FLYCFG.enabled=true
    AC("fly",RunService.Heartbeat:Connect(function()
        if not FLYCFG.enabled or not root then KC("fly"); return end
        pcall(function()
            if hum then hum.PlatformStand=true end
            local spd=(GE.UC7_Options and GE.UC7_Options.FlySpeed and GE.UC7_Options.FlySpeed.Value) or 80
            local cf=Camera.CFrame; local vel=Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then vel=vel+cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then vel=vel-cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then vel=vel-cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then vel=vel+cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vel=vel+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel=vel+Vector3.new(0,-1,0) end
            if vel.Magnitude>0 then vel=vel.Unit*spd end
            if _flyBV and _flyBV.Parent then _flyBV.Velocity=vel end
            if _flyBG and _flyBG.Parent then _flyBG.CFrame=cf end
        end)
    end))
end

local function stopFly()
    KC("fly"); FLYCFG.enabled=false
    pcall(function()
        if hum then hum.PlatformStand=false end
        if _flyBG and _flyBG.Parent then _flyBG:Destroy() end
        if _flyBV and _flyBV.Parent then _flyBV:Destroy() end
        _flyBG,_flyBV=nil,nil
    end)
end

-- ============================================================
-- MOVEMENT SETUP
-- ============================================================
local function setupMovement()
    AC("noclip_rebind",LP.CharacterAdded:Connect(function(c)
        AC("noclip",RunService.Stepped:Connect(function()
            if not (GE.UC7_Toggles and GE.UC7_Toggles.NoClip and GE.UC7_Toggles.NoClip.Value) then return end
            for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end))
        AC("speed_loop",RunService.Heartbeat:Connect(function()
            local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
            local T=GE.UC7_Toggles; local O=GE.UC7_Options
            if T and T.SpeedOn and T.SpeedOn.Value then h.WalkSpeed=O and O.SpeedVal and O.SpeedVal.Value or 60 end
            if T and T.SuperJump and T.SuperJump.Value then pcall(function() h.JumpPower=O and O.JumpPower and O.JumpPower.Value or 150 end) end
        end))
    end))
    AC("infjump",UIS.JumpRequest:Connect(function()
        local T=GE.UC7_Toggles
        if T and T.InfJump and T.InfJump.Value and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
    AC("bhop",RunService.Heartbeat:Connect(function()
        local T=GE.UC7_Toggles
        if not (T and T.BhopOn and T.BhopOn.Value) then return end
        if not hum or not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
        pcall(function() if hum.FloorMaterial~=Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end)
    end))
end

-- ============================================================
-- ESP (BillboardGui)
-- ============================================================
local ESPs={}

local function updateESP(enabled,showName,showHP,showDist)
    if not enabled then for _,bb in pairs(ESPs) do if bb and bb.Parent then bb.Parent=nil end end; return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local c=p.Character; local r=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
        if not r or not h then continue end
        if not ESPs[p] then
            local bb=Instance.new("BillboardGui")
            bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,150,0,52); bb.StudsOffset=Vector3.new(0,3,0)
            local nl=Instance.new("TextLabel",bb); nl.Name="N"; nl.Size=UDim2.new(1,0,0,16); nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold; nl.TextSize=12; nl.TextColor3=Color3.fromRGB(120,80,255); nl.TextStrokeTransparency=0.5
            local hl=Instance.new("TextLabel",bb); hl.Name="H"; hl.Position=UDim2.new(0,0,0,17); hl.Size=UDim2.new(1,0,0,14); hl.BackgroundTransparency=1; hl.Font=Enum.Font.Gotham; hl.TextSize=11
            local dl=Instance.new("TextLabel",bb); dl.Name="D"; dl.Position=UDim2.new(0,0,0,32); dl.Size=UDim2.new(1,0,0,12); dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham; dl.TextSize=10; dl.TextColor3=Color3.fromRGB(160,160,180)
            ESPs[p]=bb
        end
        local bb=ESPs[p]; bb.Adornee=r; bb.Parent=CoreGui
        local N=bb:FindFirstChild("N"); local H=bb:FindFirstChild("H"); local D=bb:FindFirstChild("D")
        if N then N.Text=showName and p.Name or "" end
        if H and showHP then
            local hp=math.floor(h.Health); local mhp=math.max(math.floor(h.MaxHealth),1); local rat=hp/mhp
            H.Text=hp.."/"..mhp; H.TextColor3=Color3.fromRGB(math.floor((1-rat)*210),math.floor(rat*190),60)
        elseif H then H.Text="" end
        if D and showDist and Camera then D.Text=math.floor((Camera.CFrame.Position-r.Position).Magnitude).."m"
        elseif D then D.Text="" end
    end
    for p,bb in pairs(ESPs) do if not p.Parent then bb:Destroy(); ESPs[p]=nil end end
end

-- ============================================================
-- COSMETICS
-- ============================================================
local cosHooked=false
local function hookCosmetics()
    if cosHooked then return end; cosHooked=true
    pcall(function()
        local m=RS:WaitForChild("Modules",8)
        local cl=require(m:WaitForChild("CosmeticLibrary",5))
        if cl then
            cl.OwnsCosmeticNormally=function() return true end
            cl.OwnsCosmeticUniversally=function() return true end
            cl.OwnsCosmeticForWeapon=function() return true end
            local oc=cl.OwnsCosmetic
            cl.OwnsCosmetic=function(self,inv,nm,wep)
                if type(nm)=="string" and nm:find("MISSING_") then return oc(self,inv,nm,wep) end
                return true
            end
        end
    end)
end

-- SHADERS
local origLighting=nil; local shaderFX={}
local SHADERS={
    Cyber={B=2.4,Co=0.35,Sa=0.2,Ti=Color3.fromRGB(185,210,255),Bl=0.45,BS=36,Sr=0.08,Br=0},
    Void={B=1.6,Co=0.55,Sa=-0.1,Ti=Color3.fromRGB(170,145,255),Bl=0.7,BS=48,Sr=0.03,Br=0},
    Neon={B=2.8,Co=0.5,Sa=0.45,Ti=Color3.fromRGB(190,255,245),Bl=0.9,BS=56,Sr=0.06,Br=0},
    Warm={B=2.1,Co=0.25,Sa=0.25,Ti=Color3.fromRGB(255,215,180),Bl=0.35,BS=30,Sr=0.1,Br=0},
    Cold={B=1.9,Co=0.3,Sa=0.05,Ti=Color3.fromRGB(170,220,255),Bl=0.4,BS=34,Sr=0.05,Br=0},
    Moonlight={B=1.45,Co=0.38,Sa=-0.18,Ti=Color3.fromRGB(165,185,255),Bl=0.28,BS=28,Sr=0.02,Br=0},
    GoldenHour={B=2.25,Co=0.32,Sa=0.3,Ti=Color3.fromRGB(255,198,130),Bl=0.5,BS=42,Sr=0.18,Br=0},
    Cinematic={B=1.7,Co=0.45,Sa=-0.05,Ti=Color3.fromRGB(235,225,210),Bl=0.25,BS=24,Sr=0.12,Br=1},
    Soft={B=1.9,Co=0.12,Sa=0.08,Ti=Color3.fromRGB(235,238,255),Bl=0.18,BS=22,Sr=0.04,Br=1},
    DeepFried={B=3.1,Co=0.75,Sa=0.85,Ti=Color3.fromRGB(255,235,185),Bl=1.1,BS=64,Sr=0.16,Br=0},
}
local function clearShaders() for _,fx in pairs(shaderFX) do pcall(fx.Destroy,fx) end; shaderFX={} end
local function applyShader(nm)
    local p=SHADERS[nm]; if not p then return end
    if not origLighting then origLighting={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,GlobalShadows=Lighting.GlobalShadows} end
    clearShaders()
    Lighting.Brightness=p.B; Lighting.FogEnd=100000; Lighting.FogStart=0
    local cc=Instance.new("ColorCorrectionEffect"); cc.Contrast=p.Co; cc.Saturation=p.Sa; cc.TintColor=p.Ti; cc.Parent=Lighting; table.insert(shaderFX,cc)
    local bl=Instance.new("BloomEffect"); bl.Intensity=p.Bl; bl.Size=p.BS; bl.Threshold=1; bl.Parent=Lighting; table.insert(shaderFX,bl)
    local sr=Instance.new("SunRaysEffect"); sr.Intensity=p.Sr; sr.Spread=0.75; sr.Parent=Lighting; table.insert(shaderFX,sr)
    if p.Br>0 then local bz=Instance.new("BlurEffect"); bz.Size=p.Br; bz.Parent=Lighting; table.insert(shaderFX,bz) end
end

-- ============================================================
-- LOAD OBSIDIAN LIBRARY
-- ============================================================
print("[UNCODE v7] Loading Obsidian UI...")

local Library,ThemeManager,SaveManager
local Toggles={} local Options={}
do
    local function fetchRaw(url)
        local ok,r=pcall(function() return game:HttpGet(url) end)
        return ok and r or nil
    end
    local libSrc=fetchRaw("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/Library.lua")
    if libSrc then
        local fnOk,fn=pcall(loadstring,libSrc)
        if fnOk and fn then
            local ok2,res=pcall(fn)
            if ok2 and type(res)=="table" then Library=res end
        end
    end
    if Library then
        Toggles=Library.Toggles or Toggles
        Options =Library.Options  or Options
        local tmSrc=fetchRaw("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/addons/ThemeManager.lua")
        if tmSrc then pcall(function() ThemeManager=loadstring(tmSrc)() end) end
        local smSrc=fetchRaw("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/addons/SaveManager.lua")
        if smSrc then pcall(function() SaveManager=loadstring(smSrc)() end) end
        print("[UNCODE v7] Obsidian loaded OK")
    else
        local function fakeEl()
            local e={}
            setmetatable(e,{__index=function(_,_) return function(...) return fakeEl() end end})
            return e
        end
        local fakeT=setmetatable({},{__index=function() return {Value=false} end})
        local fakeO=setmetatable({},{__index=function() return {Value=nil}   end})
        Library={Toggles=fakeT,Options=fakeO,Notify=function()end,Unload=function()end,CreateWindow=function() return fakeEl() end}
        Toggles=fakeT; Options=fakeO
        warn("[UNCODE v7] Obsidian unavailable - headless mode")
    end
    task.wait()
end

-- Expose to GE so gameplay loops (before UI runs) can read toggles
GE.UC7_Toggles=Toggles; GE.UC7_Options=Options

-- ============================================================
-- WINDOW
-- ============================================================
local Window=Library:CreateWindow({
    Title="uncode", Footer="rivals . v7 . anti-kicia . anti-transcrait",
    NotifySide="Right", ShowCustomCursor=true, AutoShow=true, Center=true,
    Resizable=true, ShowMobileButtons=true, MobileButtonsSide="Left",
    ToggleKeybind=Enum.KeyCode.RightShift, EnableSidebarResize=true,
})
task.wait()

local function Notify(t,d) pcall(function() Library:Notify({Title="uncode",Description=t,Time=d or 3}) end) end

local Tabs={}
for _,nm in ipairs({"Combat","Void","Orbit","AntiAim","Riot","Visuals","Misc","Configs","Settings"}) do
    Tabs[nm]=Window:AddTab(nm)
end

local function BT(box,id,txt,def,cb)
    local t=box:AddToggle(id,{Text=txt,Default=def or false,Callback=cb or function()end})
    pcall(function() t:AddKeyPicker(id.."_key",{Default="None",Mode="Toggle",Text=txt,SyncToggleState=true,NoUI=false}) end)
    return t
end

-- ============================================================
-- TAB: Combat
-- ============================================================
pcall(function()
    local CL=Tabs.Combat:AddLeftGroupbox("Ragebot / HVH")
    BT(CL,"RB_On","Ragebot",false)
    CL:AddDropdown("RB_Weapon",{Text="Weapon",Default="Sword",Values={"Sword","Revolver","Katana","Knife","Fist","Hammer"}})
    CL:AddSlider("RB_Interval",{Text="Interval (ms)",Default=50,Min=10,Max=500,Rounding=0})
    BT(CL,"RB_Snap","Snap-to-Target",false)
    CL:AddSlider("RB_SnapDist",{Text="Snap Distance",Default=4,Min=1,Max=20,Rounding=0})
    BT(CL,"RB_Burst","Multi-Angle Burst (4x)",true)

    local CR=Tabs.Combat:AddRightGroupbox("Resolver / Remote")
    BT(CR,"Resolver_On","Resolver (Anti-Kicia/Transcrait)",true)
    CR:AddLabel("12-angle . hit-bias learning")
    BT(CR,"PB_On","Position Spoof",true,function(v) PB.enabled=v end)
    BT(CR,"PB_Pred","Prediction",true,function(v) PB.pred=v end)
    CR:AddSlider("PB_Expand",{Text="Expand",Default=18,Min=0,Max=200,Rounding=0,Callback=function(v) PB.expand=v*0.01 end})
    CR:AddSlider("PB_Lerp",{Text="Aim Lerp",Default=88,Min=10,Max=100,Rounding=0,Callback=function(v) PB.lerp=v*0.01 end})
    CR:AddButton("Re-hook Remotes",function() hookRemotes(); Notify("Remotes re-hooked",2) end)

    local CL2=Tabs.Combat:AddLeftGroupbox("KX Aimbot")
    BT(CL2,"KX_On","KX Aimbot",false)
    CL2:AddSlider("KX_Smooth",{Text="Smoothness",Default=12,Min=1,Max=50,Rounding=0})
    CL2:AddSlider("KX_FOV",{Text="FOV px",Default=120,Min=10,Max=360,Rounding=0})
    CL2:AddDropdown("KX_Hitbox",{Text="Hitbox",Default="Head",Values={"Head","HumanoidRootPart","UpperTorso"}})
    BT(CL2,"KX_Vis","Vis Check",true)
    BT(CL2,"KX_Silent","Silent Aim",false)
    BT(CL2,"KX_Pred","Velocity Prediction",true)
    BT(CL2,"KX_FOVCircle","FOV Circle",true)
end)

-- KX aimbot loop
local _kxRP=RaycastParams.new(); _kxRP.FilterType=Enum.RaycastFilterType.Blacklist
AB("uc7_kxaim",Enum.RenderPriority.Camera.Value+10,function()
    if not Toggles.KX_On or not Toggles.KX_On.Value then return end
    local t=getClosest(true); if not t or not t.Character then return end
    local hn=Options.KX_Hitbox and Options.KX_Hitbox.Value or "Head"
    local hb=t.Character:FindFirstChild(hn) or t.Character:FindFirstChild("HumanoidRootPart"); if not hb then return end
    if Toggles.KX_Vis and Toggles.KX_Vis.Value then
        _kxRP.FilterDescendantsInstances={LP.Character,Camera}
        local res=workspace:Raycast(Camera.CFrame.Position,(hb.Position-Camera.CFrame.Position).Unit*2000,_kxRP)
        if res and not res.Instance:IsDescendantOf(t.Character) then return end
    end
    local sm=1/((Options.KX_Smooth and Options.KX_Smooth.Value) or 12)
    local aimPos=hb.Position
    if Toggles.KX_Pred and Toggles.KX_Pred.Value then
        pcall(function()
            local vel=hb.AssemblyLinearVelocity
            local ping=(game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value or 80)*0.001
            aimPos=hb.Position+vel*(ping+0.05)
        end)
    end
    if Toggles.KX_Silent and Toggles.KX_Silent.Value then
        pcall(function()
            local dir=(aimPos-Camera.CFrame.Position).Unit
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,Camera.CFrame.Position+dir*0.98+Camera.CFrame.LookVector*0.02)
        end)
    else
        pcall(function() Camera.CFrame=Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position,aimPos),sm) end)
    end
end)

local _fovCircle=Drawing.new("Circle"); _fovCircle.Visible=false; _fovCircle.Color=Color3.fromRGB(255,255,255); _fovCircle.Thickness=1.5; _fovCircle.NumSides=64; _fovCircle.Filled=false; _fovCircle.Transparency=0.8
AB("uc7_fov",Enum.RenderPriority.Camera.Value+1,function()
    local show=Toggles.KX_On and Toggles.KX_On.Value and Toggles.KX_FOVCircle and Toggles.KX_FOVCircle.Value
    _fovCircle.Visible=show or false
    if show then _fovCircle.Position=Camera.ViewportSize/2; _fovCircle.Radius=Options.KX_FOV and Options.KX_FOV.Value or 120 end
end)

task.wait()

-- ============================================================
-- TAB: Void
-- ============================================================
pcall(function()
    local VOID_MODES={"Quantum","Chaos","Drift","Still","Circle","Figure8","WideSweep","FastBounce","Blink","GridHop","HeightWave","NoiseCloud","Spiral","Loop","SlowDrift"}
    local VL=Tabs.Void:AddLeftGroupbox("Void Control")
    BT(VL,"Void_On","Enable Void",false,function(v) VCFG.enabled=v; if v then startVoid() else stopVoid() end end)
    VL:AddDropdown("VoidMode",{Text="Mode",Default="Quantum",Values=VOID_MODES,Callback=function(v) VCFG.method=v; vElapsed=0 end})
    VL:AddSlider("VoidSpeed",{Text="Speed (x109 B/s)",Default=1,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.speed=v*1e9 end})
    VL:AddSlider("VoidRadius",{Text="Radius (x109 B)",Default=200,Min=10,Max=1000,Rounding=0,Callback=function(v) VCFG.radius=v*1e9 end})
    VL:AddSlider("VoidAlt",{Text="Altitude (x109 B)",Default=10,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.altitude=v*1e9 end})
    VL:AddSlider("VoidChaos",{Text="Chaos Factor %",Default=98,Min=1,Max=100,Rounding=0,Callback=function(v) VCFG.chaos=v*0.01 end})
    VL:AddButton("Reset Pattern",function() vElapsed=0; vX=math.random(-1e8,1e8); vZ=math.random(-1e8,1e8); vYOff=0; Notify("Pattern reset",2) end)

    local VR=Tabs.Void:AddRightGroupbox("Evasion & Godmode")
    BT(VR,"VoidEvade","Void Evasion",true,function(v) VCFG.evade=v end)
    VR:AddSlider("VoidEvR",{Text="Evade Radius (x109)",Default=8,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.evadeR=v*1e9 end})
    VR:AddSlider("VoidEvS",{Text="Evade Speed (x109)",Default=6,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.evadeS=v*1e9 end})
    VR:AddSlider("VoidEvT",{Text="Trigger %",Default=100,Min=10,Max=200,Rounding=0,Callback=function(v) VCFG.evadeTrig=v*0.01 end})
    VR:AddSlider("VoidEvCD",{Text="Cooldown (x0.01s)",Default=5,Min=1,Max=100,Rounding=0,Callback=function(v) VCFG.evadeCD=v*0.01 end})
    VR:AddSlider("VoidEvStr",{Text="Strength %",Default=100,Min=10,Max=300,Rounding=0,Callback=function(v) VCFG.evadeStr=v*0.01 end})
    BT(VR,"VoidGod","Godmode (Fallen Parts)",false,function(v)
        pcall(function()
            workspace.FallenPartsDestroyHeight=v and -99999999 or 2000
            if hum then hum.MaxHealth=v and math.huge or 100; hum.Health=v and math.huge or 100; hum:SetStateEnabled(Enum.HumanoidStateType.Dead,not v) end
        end)
    end)
end)
task.wait()

-- ============================================================
-- TAB: Orbit
-- ============================================================
pcall(function()
    local OL=Tabs.Orbit:AddLeftGroupbox("Orbit")
    BT(OL,"Orbit_On","Enable Orbit",false,function(v) OCFG.enabled=v; if v then startOrbit() else stopOrbit() end end)
    OL:AddDropdown("OrbitMode",{Text="Mode",Default="Circle",Values={"Circle","Figure8","SpiralIn","SpiralOut","Bounce","Lemniscate"},Callback=function(v) OCFG.mode=v; oCurR=OCFG.dist end})
    OL:AddSlider("OrbitSpeed",{Text="Speed (deg/s)",Default=90,Min=5,Max=720,Rounding=0,Callback=function(v) OCFG.speed=v end})
    OL:AddSlider("OrbitDist",{Text="Radius",Default=8,Min=1,Max=200,Rounding=0,Callback=function(v) OCFG.dist=v; oCurR=v end})
    OL:AddSlider("OrbitHeight",{Text="Height Offset",Default=0,Min=-50,Max=50,Rounding=0,Callback=function(v) OCFG.height=v end})
    OL:AddSlider("OrbitLerp",{Text="Smoothing",Default=30,Min=1,Max=100,Rounding=0,Callback=function(v) OCFG.lerp=v/100 end})

    local OR=Tabs.Orbit:AddRightGroupbox("Advanced")
    BT(OR,"OrbitFace","Face Target",true,function(v) OCFG.faceTarget=v end)
    BT(OR,"OrbitPred","Prediction",false,function(v) OCFG.predict=v end)
    OR:AddSlider("OrbitPredStr",{Text="Pred Strength %",Default=20,Min=0,Max=100,Rounding=0,Callback=function(v) OCFG.predStr=v/100 end})
    OR:AddSlider("OrbitMaxD",{Text="Max Lock Dist",Default=50,Min=10,Max=500,Rounding=0,Callback=function(v) OCFG.maxLockDist=v end})
end)
task.wait()

-- ============================================================
-- TAB: AntiAim
-- ============================================================
pcall(function()
    local AL=Tabs.AntiAim:AddLeftGroupbox("Anti-Aim")
    BT(AL,"AA_On","Enable Anti-Aim",false,function(v) ACFG.enabled=v; if v then startAntiAim() else stopAntiAim() end end)
    AL:AddDropdown("AA_Mode",{Text="Mode",Default="Spin",Values={"Spin","Jitter","Static"},Callback=function(v) ACFG.mode=v end})
    AL:AddSlider("AA_Speed",{Text="Speed (deg/s)",Default=5000,Min=100,Max=5000,Rounding=0,Callback=function(v) ACFG.speed=v end})
    AL:AddSlider("AA_Angle",{Text="Jitter/Static Angle",Default=90,Min=10,Max=180,Rounding=0,Callback=function(v) ACFG.angle=v end})
    BT(AL,"AA_Rand","Randomize Speed",true,function(v) ACFG.randSpeed=v end)
    BT(AL,"AA_JitPitch","Jitter Pitch (2D)",true,function(v) ACFG.jitterPitch=v end)

    local AR=Tabs.AntiAim:AddRightGroupbox("Prediction Dodge")
    BT(AR,"Dodge_On","Enable Dodge",false,function(v) DCFG.enabled=v; if v then startDodge() else stopDodge() end end)
    AR:AddSlider("Dodge_R",{Text="Danger Radius",Default=20,Min=5,Max=100,Rounding=0,Callback=function(v) DCFG.radius=v end})
    AR:AddSlider("Dodge_D",{Text="Dodge Distance",Default=30,Min=5,Max=150,Rounding=0,Callback=function(v) DCFG.dist=v end})
    AR:AddSlider("Dodge_CD",{Text="Cooldown (ms)",Default=300,Min=50,Max=2000,Rounding=0,Callback=function(v) DCFG.cooldown=v/1000 end})
    AR:AddSlider("Dodge_T",{Text="Speed Threshold",Default=800,Min=200,Max=5000,Rounding=0,Callback=function(v) DCFG.threshold=v end})
    AR:AddSlider("Dodge_M",{Text="Pred Multiplier",Default=1,Min=0.5,Max=10,Rounding=1,Callback=function(v) DCFG.mult=v end})
end)
task.wait()

-- ============================================================
-- TAB: Riot
-- ============================================================
pcall(function()
    local GL=Tabs.Riot:AddLeftGroupbox("Riot - Erratic + Spin")
    BT(GL,"Riot_On","Enable Riot",false,function(v) RCFG.enabled=v; if v then startRiot() else stopRiot() end end)
    GL:AddSlider("Riot_Speed",{Text="Interval (s)",Default=3,Min=1,Max=50,Rounding=0,Callback=function(v) RCFG.speed=v*0.01 end})
    GL:AddSlider("Riot_Range",{Text="Jump Range",Default=50,Min=10,Max=200,Rounding=0,Callback=function(v) RCFG.range=v end})
    GL:AddSlider("Riot_EvR",{Text="Evade Trigger",Default=30,Min=0,Max=100,Rounding=0,Callback=function(v) RCFG.evadeRange=v end})
    GL:AddSlider("Riot_Spin",{Text="Spin Speed (deg/s)",Default=180,Min=0,Max=720,Rounding=0,Callback=function(v) RCFG.spinSpeed=v end})

    local GR=Tabs.Riot:AddRightGroupbox("Riot Abuse 3D")
    BT(GR,"RAbuse_On","Enable Riot Abuse",false,function(v) RABCFG.enabled=v; if v then startRiotAbuse() else stopRiotAbuse() end end)
    GR:AddDropdown("RAbuse_Mode",{Text="Mode",Default="Stick",Values={"Stick","Bounce"},Callback=function(v) RABCFG.mode=v end})
    GR:AddSlider("RAbuse_H",{Text="Height Offset",Default=3,Min=-50,Max=50,Rounding=1,Callback=function(v) RABCFG.height=v end})
    GR:AddSlider("RAbuse_F",{Text="Forward Offset",Default=0,Min=-50,Max=50,Rounding=1,Callback=function(v) RABCFG.forward=v end})
    GR:AddSlider("RAbuse_R",{Text="Right Offset",Default=0,Min=-50,Max=50,Rounding=1,Callback=function(v) RABCFG.right=v end})
    GR:AddSlider("RAbuse_D",{Text="Down Offset",Default=0,Min=0,Max=50,Rounding=1,Callback=function(v) RABCFG.down=v end})
end)
task.wait()

-- ============================================================
-- TAB: Visuals
-- ============================================================
pcall(function()
    local SL=Tabs.Visuals:AddLeftGroupbox("ESP")
    BT(SL,"ESP_On","ESP Enabled",false)
    BT(SL,"ESP_Name","Show Name",true)
    BT(SL,"ESP_HP","Show Health",true)
    BT(SL,"ESP_Dist","Show Distance",true)

    local SR=Tabs.Visuals:AddRightGroupbox("World / Shaders")
    BT(SR,"Fullbright","Full Bright",false)
    BT(SR,"NoFog","No Fog",true,function(v) Lighting.FogEnd=v and 100000 or (origLighting and origLighting.FogEnd or 1000); Lighting.FogStart=v and 100000 or 0 end)
    BT(SR,"NoShadows","No Shadows",false,function(v) Lighting.GlobalShadows=not v end)
    BT(SR,"NoPostFX","No Post-FX",false,function(v) for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then pcall(function() fx.Enabled=not v end) end end end)
    BT(SR,"CustomFOV","Custom FOV",false)
    SR:AddSlider("FOV_Val",{Text="FOV",Default=90,Min=60,Max=130,Rounding=0,Callback=function(v) if Toggles.CustomFOV and Toggles.CustomFOV.Value then Camera.FieldOfView=v end end})
    BT(SR,"Shader_On","Shaders",false,function(v)
        if v then applyShader(Options.ShaderPreset and Options.ShaderPreset.Value or "Cyber") else clearShaders() end
    end)
    SR:AddDropdown("ShaderPreset",{Text="Shader",Default="Cyber",Values={"Cyber","Void","Neon","Warm","Cold","Moonlight","GoldenHour","Cinematic","Soft","DeepFried"},
        Callback=function(v) if Toggles.Shader_On and Toggles.Shader_On.Value then applyShader(v) end end})
    SR:AddButton("Apply Shader",function()
        if Toggles.Shader_On and Toggles.Shader_On.Value then applyShader(Options.ShaderPreset and Options.ShaderPreset.Value or "Cyber"); Notify("Shader applied",2) end
    end)
end)

AC("esp",RunService.Heartbeat:Connect(function()
    updateESP(
        Toggles.ESP_On  and Toggles.ESP_On.Value,
        Toggles.ESP_Name and Toggles.ESP_Name.Value,
        Toggles.ESP_HP  and Toggles.ESP_HP.Value,
        Toggles.ESP_Dist and Toggles.ESP_Dist.Value
    )
end))

AB("uc7_vis",Enum.RenderPriority.Last.Value,function()
    if Toggles.Fullbright and Toggles.Fullbright.Value then
        Lighting.Brightness=3; Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
    end
    if Toggles.CustomFOV and Toggles.CustomFOV.Value then
        Camera.FieldOfView=Options.FOV_Val and Options.FOV_Val.Value or 90
    end
end)

task.wait()

-- ============================================================
-- TAB: Misc
-- ============================================================
pcall(function()
    local ML=Tabs.Misc:AddLeftGroupbox("Movement")
    BT(ML,"SpeedOn","Speed Hack",false,function(v) if not v and hum then hum.WalkSpeed=16 end end)
    ML:AddSlider("SpeedVal",{Text="Walk Speed",Default=60,Min=16,Max=300,Rounding=0})
    BT(ML,"InfJump","Infinite Jump",false)
    BT(ML,"SuperJump","Super Jump",false,function(v) if not v and hum then pcall(function() hum.JumpPower=50 end) end end)
    ML:AddSlider("JumpPower",{Text="Jump Power",Default=150,Min=50,Max=1000,Rounding=0})
    BT(ML,"BhopOn","Bunny Hop",false)
    BT(ML,"FlyOn","Fly Mode",false,function(v) if v then startFly() else stopFly() end end)
    ML:AddSlider("FlySpeed",{Text="Fly Speed",Default=80,Min=10,Max=500,Rounding=0})
    BT(ML,"NoClip","No Clip",false)
    BT(ML,"FreezeChar","Freeze Character",false,function(v)
        if root then pcall(function() root.Anchored=v; if v then root.AssemblyLinearVelocity=Vector3.zero end end) end
    end)
    ML:AddButton("Teleport to Target",function()
        local t=getClosest(); if not t or not t.Character then return end
        local r=t.Character:FindFirstChild("HumanoidRootPart"); if not r or not root then return end
        pcall(function() root.CFrame=r.CFrame*CFrame.new(0,0,3) end)
    end)

    local MR=Tabs.Misc:AddRightGroupbox("Spoof / Cosmetics")
    BT(MR,"UnlockAll","Unlock All Skins",false,function(v) if v then hookCosmetics() end end)
    MR:AddDivider()
    BT(MR,"AutoRespawn","Auto Respawn",false)
    MR:AddButton("Respawn Now",function()
        pcall(function() LP:LoadCharacter() end)
    end)
    MR:AddDivider()
    MR:AddLabel("Godmode / Exploits")
    BT(MR,"GodmodeHP","Inf Health (local)",false,function(v)
        if not hum then return end
        pcall(function()
            hum.MaxHealth=v and math.huge or 100
            hum.Health=v and math.huge or 100
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead,not v)
        end)
    end)
    MR:AddButton("Kill All (Ragebot)",function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p==LP then continue end
            local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if not r then continue end
            local atkRem=_atkRemCache or findAtkRemote(); if not atkRem then break end
            pcall(function()
                for i=1,8 do
                    atkRem:FireServer({id=HTTP:GenerateGUID(false),item=Options.RB_Weapon and Options.RB_Weapon.Value or "Sword",
                        position=r.Position,attackNum=math.random(1,9999),heavyAttackNum=math.random(1,9999),
                        rotation=r.CFrame.Rotation,one=Vector3.one,startAiming=true,packed={"\x00","\x01","\x02","\x03"}})
                    task.wait(0.01)
                end
            end)
        end
        Notify("Kill all sent",2)
    end)
end)

setupMovement()

AC("speed_outer",RunService.Heartbeat:Connect(function()
    if not hum then return end
    if Toggles.SpeedOn and Toggles.SpeedOn.Value then hum.WalkSpeed=Options.SpeedVal and Options.SpeedVal.Value or 60 end
    if Toggles.SuperJump and Toggles.SuperJump.Value then pcall(function() hum.JumpPower=Options.JumpPower and Options.JumpPower.Value or 150 end) end
    if Toggles.AutoRespawn and Toggles.AutoRespawn.Value and hum.Health<=0 then
        task.delay(1.5,function() pcall(function() LP:LoadCharacter() end) end)
    end
end))

task.wait()

-- ============================================================
-- TAB: Configs
-- ============================================================
pcall(function()
    local PRESETS={
        ["Anti-Kicia v3"]   ={Resolver_On=true,RB_On=true,AA_On=true,AA_Mode="Spin",AA_Speed=5000,AA_Rand=true,Void_On=true,VoidMode="Quantum",VoidEvade=true,VoidGod=true,PB_On=true,RB_Burst=true},
        ["Anti-Transcrait"] ={Resolver_On=true,RB_On=true,AA_On=true,AA_Mode="Spin",AA_Speed=5000,AA_Rand=true,Void_On=true,VoidMode="Quantum",VoidEvade=true,VoidGod=true,PB_On=true,RB_Burst=true,RB_Snap=true},
        ["Rage Max"]        ={AA_On=true,AA_Mode="Spin",AA_Speed=5000,Void_On=true,VoidMode="Chaos",VoidEvade=false,VoidGod=true,PB_On=true,RB_Burst=true,RB_Snap=true},
        ["Balanced HVH"]    ={Resolver_On=true,AA_On=true,AA_Mode="Jitter",AA_Speed=3000,Void_On=true,VoidMode="Quantum",VoidEvade=true,PB_On=true,RB_Burst=false,KX_On=true},
        ["Safe / Legit"]    ={Resolver_On=false,AA_On=false,Void_On=false,PB_On=false,RB_Burst=false,KX_On=true,KX_Vis=true},
        ["Orbit Spam"]      ={Orbit_On=true,OrbitMode="Circle",Void_On=true,VoidMode="Quantum",PB_On=true,RB_Burst=true},
        ["Full Defense"]    ={Dodge_On=true,VoidEvade=true,AA_On=true,AA_Mode="Spin",AA_Rand=true,Void_On=true,VoidGod=true},
    }
    local function applyPreset(name)
        local p=PRESETS[name]; if not p then return end
        for k,v in pairs(p) do
            if Toggles[k] then pcall(function() Toggles[k]:SetValue(v) end) end
            if Options[k] then pcall(function() Options[k]:SetValue(v) end) end
        end
        Notify("Preset: "..name,3)
    end
    local CL=Tabs.Configs:AddLeftGroupbox("Community Presets")
    for nm,_ in pairs(PRESETS) do
        CL:AddButton(nm,function() applyPreset(nm) end)
    end
    if SaveManager then
        SaveManager:SetLibrary(Library); SaveManager:SetFolder("uncode7")
        local CR=Tabs.Configs:AddRightGroupbox("Saved Configs")
        SaveManager:BuildConfigSection(CR)
    end
end)
task.wait()

-- ============================================================
-- TAB: Settings
-- ============================================================
pcall(function()
    local SL=Tabs.Settings:AddLeftGroupbox("Menu")
    SL:AddLabel("Menu Toggle"):AddKeyPicker("MenuKey",{Default="RightShift",Text="Menu Key",Mode="Toggle",NoUI=false})
    Library.ToggleKeybind=Options.MenuKey
    BT(SL,"KeybindMenu","Keybind Menu",false,function(v)
        pcall(function() Library.KeybindFrame.Visible=v end)
    end)
    SL:AddButton("Unload Script",function() pcall(function() Library:Unload() end) end)
    SL:AddButton("Re-hook Remotes",function() hookRemotes(); Notify("Re-hooked",2) end)
    SL:AddButton("Re-scan AC",function()
        task.spawn(function()
            local kw={"ban","kick","moderation","anticheat","detection"}
            local function proc(o)
                pcall(function()
                    if not(o:IsA("LocalScript") or o:IsA("ModuleScript")) then return end
                    local nm=o.Name:lower()
                    for _,t in ipairs(kw) do if nm:find(t) then pcall(function() o.Disabled=true end) end end
                end)
            end
            for _,d in ipairs(game:GetDescendants()) do proc(d) end
        end)
        Notify("AC rescan done",2)
    end)

    local SR=Tabs.Settings:AddRightGroupbox("Info")
    SR:AddLabel("UNCODE v7")
    SR:AddLabel("rivals . hvh . ue . kiciahook")

    if ThemeManager then
        ThemeManager:SetLibrary(Library); ThemeManager:SetFolder("uncode7")
        ThemeManager:ApplyToTab(Tabs.Settings)
    end

    if SaveManager then
        SaveManager:LoadAutoloadConfig()
    end
end)

-- ============================================================
-- DONE
-- ============================================================
print("[UNCODE v7] All systems loaded")
Notify("UNCODE v7 loaded!",4)
