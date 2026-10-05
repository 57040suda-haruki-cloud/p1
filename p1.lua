
print("[UNCODE v8] Script loaded OK -- starting")
task.wait(0.1)
do

    if not getgenv().__UC_HooksApplied then
        getgenv().__UC_HooksApplied = true
        pcall(function() if setthreadidentity then setthreadidentity(8) end end)
        print("[UNCODE v8] Hooks applied (safe mode)")
    end
end

do

    task.delay(8, function()
        pcall(function()
            if not getgc then return end
            local gc = getgc(true)
            for i = 1, #gc do
                local v = gc[i]
                if type(v) == "table" then
                    local v36 = rawget(v, "value36")
                    if type(v36) == "table" then
                        v36.SlingshotBypass = true
                        local v126 = rawget(v, "value126")
                        if type(v126) == "table" then table.clear(v126) end
                    end
                end
                if i % 500 == 0 then task.wait() end
            end
            print("[UNCODE v8] Kicia bypass done")
        end)
    end)
end

local function _genv()

    local ok, env = pcall(function() return getgenv() end)
    if ok and type(env)=="table" then return env end
    return _G
end
local GE = _genv()

pcall(function() GE.UC4_Loaded=nil; _G.UC4_Loaded=nil end)
pcall(function() GE.UC4_Running=nil; _G.UC4_Running=nil end)
GE.UC4_Running=true; pcall(function() _G.UC4_Running=true end)
task.wait() 

do
    local N = function() end
    local stubs = {
        hookmetamethod    = function(o,m,h) return nil end,
        hookfunction      = function(f,h) return f end,
        newcclosure       = function(f) return f end,
        checkcaller       = function() return false end,
        iscclosure        = function() return false end,
        cloneref          = function(o) return o end,
        getgc             = function() return {} end,
        getscripts        = function() return {} end,
        getscriptbytecode = function() return "" end,
        setthreadidentity = N, getthreadidentity = function() return 2 end,
        setreadonly       = N, getrawmetatable   = function(o) return getmetatable(o) end,
        setclipboard      = N, getclipboard      = function() return "" end,
        writefile=N, readfile=function() return "" end,
        isfile=function() return false end, isfolder=function() return false end,
        makefolder=N, listfiles=function() return {} end, delfile=N,
        gethui            = function() return game:GetService("CoreGui") end,
        getfenv           = getfenv or function() return {} end,
    }
    for k,v in pairs(stubs) do
        if rawget(GE,k)==nil then GE[k]=v end
    end
end

pcall(setthreadidentity, 8)
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

local char, root, hum
local function bindChar(c)
    char=c; root=nil; hum=nil
    if not c then return end
    root = c:WaitForChild("HumanoidRootPart",5)
    hum  = c:WaitForChild("Humanoid",5)
end
if LP.Character then task.spawn(bindChar, LP.Character) end
LP.CharacterAdded:Connect(function(c) task.delay(0.15,bindChar,c) end)
LP.CharacterRemoving:Connect(function() char=nil;root=nil;hum=nil end)

local Conns={} local Binds={}
local function KC(k) if Conns[k] then pcall(Conns[k].Disconnect,Conns[k]); Conns[k]=nil end end
local function AC(k,c) KC(k); Conns[k]=c end
local function AB(k,p,f) if Binds[k] then pcall(RunService.UnbindFromRenderStep,RunService,k) end; Binds[k]=true; RunService:BindToRenderStep(k,p,f) end
local function KB(k) if Binds[k] then pcall(RunService.UnbindFromRenderStep,RunService,k); Binds[k]=nil end end

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
            d=(Vector2.new(sp.X,sp.Y)-Camera.ViewportSize/2).Magnitude
        else
            d=(root.Position-r.Position).Magnitude
        end
        if d<bd then bd=d; best=p end
    end
    return best
end

local stateAC = {bypassed=false}
local kExp = {[1914481512]="Root",[1936447744]="ReplicatedController",[3892767096]="MiscellaneousController",[337076960]="LocalScript3",[2191862192]="ClientFighter"}

local function SafeHook(fn,...)
    local a={...}; local f,i,m,d
    if fn==hookmetamethod then i,m,d=a[1],a[2],a[3] else f,d=a[1],a[2] end
    if fn==hookfunction and iscclosure(f) then d=newcclosure(d) end
    if not iscclosure(d) then d=newcclosure(d) end
    local orig; pcall(function()
        if fn==hookmetamethod then orig=fn(i,m,d) else orig=fn(f,d) end
    end); return orig
end

local function SafeCall(fn,...)
    if checkcaller() then return fn(...) end
    local old=getthreadidentity(); if old~=2 then setthreadidentity(2) end
    local r={fn(...)}; if old~=2 then setthreadidentity(old) end
    return table.unpack(r)
end

pcall(function()
    local function VerifyScripts()
        local ok1,gs=pcall(function() return getscripts or getsenv end)
        local ok2,gb=pcall(function() return getscriptbytecode end)
        if not ok1 or not ok2 then return true end
        local found={}
        for _,s in ipairs(gs()) do
            local ok,_ = pcall(gb,s)
            if ok then
                local so,src=pcall(debug.info,s,"s")
                if so and src and src~="=[C]" then
                    for id in pairs(kExp) do found[id]=true end
                end
            end
        end
        for id in pairs(kExp) do if not found[id] then return false end end
        return true
    end

    local function HookKick()
        for _,nm in ipairs({"Kick","kick"}) do
            local f=LP[nm]
            if type(f)=="function" then
                local old; old=SafeHook(hookfunction,f,function(self,...)
                    if self==LP and not checkcaller() then return end
                    return old(self,...)
                end)
            end
        end
    end

    local function HookAC(ac)
        if not ac then return end
        local oi; oi=SafeHook(hookmetamethod,ac,"__index",function(t,k)
            if t==ac and not checkcaller() and k=="Enabled" and not stateAC.bypassed then return false end
            if checkcaller() then return oi(t,k) end
            return SafeCall(oi,t,k)
        end)
        local oni; oni=SafeHook(hookmetamethod,ac,"__newindex",function(t,k,v)
            if t==ac and not checkcaller() and k=="Enabled" and not stateAC.bypassed then return end
            if checkcaller() then return oni(t,k,v) end
            return SafeCall(oni,t,k,v)
        end)
    end

    task.spawn(function()
        local KL={"ban","kick","moderation","anticheat","detection"}
        local function proc(o)
            pcall(function()
                if not(o:IsA("LocalScript") or o:IsA("ModuleScript")) then return end
                local ok,nm=pcall(function() return o.Name:lower() end)
                if not ok then return end
                for _,t in ipairs(KL) do
                    if nm:find(t) then pcall(function() o.Disabled=true end); break end
                end
            end)
        end
        for _,d in ipairs(game:GetDescendants()) do proc(d) end
        game.DescendantAdded:Connect(proc)
    end)

    if VerifyScripts() then
        local ac = RF:WaitForChild("LocalScript3",10)
        if ac then
            HookAC(ac)
            HookKick()
            pcall(function() ac.Enabled=false end)
            stateAC.bypassed=true
        end
    end
end)

task.spawn(function()
    task.wait(2)
    pcall(function()
        local IL = require(RS.Modules.ItemLibrary)
        local function scan(t)
            for _,v in pairs(t) do
                if typeof(v)=="table" then
                    if v.ShootCooldown ~= nil then v.ShootCooldown=0.000000000000001 end
                    if v.AttackCooldown ~= nil then v.AttackCooldown=0.000000000000001 end
                    if v.HeavyAttackCooldown ~= nil then v.HeavyAttackCooldown=0.000000000000001 end
                    scan(v)
                end
            end
        end
        scan(IL)
    end)
end)

local PB = {
    enabled=false, spoof=true, pred=true,
    expand=0.18, lerp=0.88, spd=90, predMult=1
}
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

local function expandPos(pos)
    return pos+(pos-Camera.CFrame.Position).Unit*PB.expand
end

local function hookRemotes()
    local rem = RS:FindFirstChild("Remotes"); if not rem then return end
    for _,r in ipairs(rem:GetDescendants()) do
        if r:IsA("RemoteEvent") and not r:GetAttribute("_uc_hooked") then
            r:SetAttribute("_uc_hooked",true)
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

AB("uc_proj",Enum.RenderPriority.Camera.Value+5,function()
    if not PB.enabled then return end
    local t=getClosest(); local orig=Camera.CFrame.Position
    if t and t.Character then
        local tr=t.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local pos=PB.pred and predictTarget(tr,orig) or tr.Position
            local aim=expandPos(pos)
            projSpoofed=CFrame.new(orig,aim)
            Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(orig,aim),PB.lerp)
            return
        end
    end
    projSpoofed=Camera.CFrame
end)

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
    for _=1,4 do nx = nx + math.noise(t*f,0,0)*a; ny = ny + math.noise(0,t*f,0)*a; nz = nz + math.noise(0,0,t*f)*a; f=f*2.37; a=a*0.5 end
    local cp=t*0.00213
    nx = nx + math.sin(cp)*math.cos(cp*1.618)*0.2; ny = ny + math.cos(cp*0.618)*math.sin(cp*2.718)*0.2; nz = nz + math.sin(cp*1.3)*math.cos(cp*0.7)*0.2
    local l=math.sqrt(nx*nx+ny*ny+nz*nz); if l<0.001 then return 1,0,0 end
    return nx/l,ny/l,nz/l
end

local function stepVoid(dt)
    vElapsed = vElapsed + dt
    local m=VCFG.method; local B=VCFG.altitude; local R=VCFG.radius; local S=VCFG.speed
    if m=="Drift" then
        local dx,dy,dz=noise3D(vElapsed)
        vDrift=vDrift:Lerp(Vector3.new(dx,dy,dz).Unit,VCFG.chaos*dt*10)
        vPos=vPos+vDrift*S*dt
        if (vPos-vBase).Magnitude>R then vPos=vBase+(vPos-vBase).Unit*R; vDrift=-vDrift end
    elseif m=="Chaos" then
        vPos=vPos+Vector3.new((math.random()-0.5)*S*dt*5,(math.random()-0.5)*S*dt*5,(math.random()-0.5)*S*dt*5)
        if (vPos-vBase).Magnitude>R then vPos=vBase+(vPos-vBase).Unit*R end
    elseif m=="Quantum" then
        local r=R*(math.random()>0.5 and 1 or -1)
        vPos=vBase+Vector3.new(r+(math.random()-0.5)*R,(math.random()-0.5)*R*0.2,r+(math.random()-0.5)*R)
    elseif m=="Loop" then
        local r=math.min(R*0.8,(vElapsed%100)*1e7)
        vPos=vBase+Vector3.new(math.cos(vElapsed*2)*r,math.sin(vElapsed*1.3)*r*0.2,math.sin(vElapsed*2)*r)
    elseif m=="Spiral" then
        local r=math.min(R*0.9,(vElapsed%50)*2e9)
        vPos=vBase+Vector3.new(math.cos(vElapsed*3)*r,math.sin(vElapsed*0.5)*r*0.3,math.sin(vElapsed*3)*r)
    elseif m=="Still" then
        vPos=Vector3.new(vX,B,vZ)
    elseif m=="Circle" then
        vPos=Vector3.new(vX+math.cos(vElapsed*3)*R,B,vZ+math.sin(vElapsed*3)*R)
    elseif m=="Figure8" then
        vPos=Vector3.new(vX+math.sin(vElapsed*2)*R,B,vZ+math.sin(vElapsed*3)*R)
    elseif m=="WideSweep" then
        vPos=Vector3.new(vX+math.sin(vElapsed*15)*R,B+math.cos(vElapsed*1.5)*R*0.1,vZ+math.cos(vElapsed*15)*R)
    elseif m=="FastBounce" then
        local r=R*math.sin(vElapsed*50)
        vPos=Vector3.new(vX+r,B+math.cos(vElapsed*50)*1e10,vZ+r)
    elseif m=="Blink" then
        vPos=(vElapsed%0.1<0.05) and Vector3.new(vX*2,B+1e11,vZ*2) or Vector3.new(vX,B,vZ)
    elseif m=="GridHop" then
        local c=5e8; local s=math.floor(vElapsed*8)
        vPos=Vector3.new(vX+(s%5-2)*c,B+(s%2==0 and 0 or c*0.18),vZ+(math.floor(s/5)%5-2)*c)
    elseif m=="HeightWave" then
        vPos=Vector3.new(vX+math.cos(vElapsed*0.4)*R,B+math.sin(vElapsed)*R*0.35,vZ+math.sin(vElapsed*0.4)*R)
    elseif m=="SquareLoop" then
        local r=R; local s=math.floor((vElapsed*1.8)%4); local a=(vElapsed*1.8)%4-s
        local x,z
        if s==0 then x=-r+a*2*r; z=-r elseif s==1 then x=r; z=-r+a*2*r elseif s==2 then x=r-a*2*r; z=r else x=-r; z=r-a*2*r end
        vPos=Vector3.new(vX+x,B,vZ+z)
    elseif m=="CrossSweep" then
        local r=R; local s=math.floor(vElapsed*4)%4; local a=math.sin(vElapsed*math.pi)*r
        vPos = s==0 and Vector3.new(vX+a,B,vZ) or s==1 and Vector3.new(vX,B,vZ+a) or s==2 and Vector3.new(vX-a,B,vZ) or Vector3.new(vX,B,vZ-a)
    elseif m=="Stairs" then
        local c=2e9; local s=math.floor(vElapsed*7)
        vPos=Vector3.new(vX+(s%7-3)*c,B+(s%5)*c*0.12,vZ+(math.floor(s/7)%7-3)*c)
    elseif m=="NoiseCloud" then
        vPos=Vector3.new(vX+math.noise(vElapsed,0,0)*R,B+math.noise(0,vElapsed,0)*R*0.25,vZ+math.noise(0,0,vElapsed)*R)
    elseif m=="SlowDrift" then
        vYOff = vYOff + vYDir*S*dt*0.4; if math.abs(vYOff)>R*0.5 then vYDir=-vYDir end
        vPos=Vector3.new(vX,B+vYOff,vZ)
    end
    return vPos
end

local function checkVoidEvade()
    if not VCFG.evade or vEvadeCD>0 then return end
    local minD,tv=math.huge,Vector3.new()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP or not p.Character then continue end
        local r=p.Character:FindFirstChild("HumanoidRootPart")
        if not r then continue end
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

local OCFG = {
    enabled=false,speed=90,dist=8,height=0,lerp=0.3,mode="Circle",
    predict=false,predStr=0.2,faceTarget=true,maxLockDist=50
}
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
        oAngle = oAngle + math.rad(OCFG.speed)*dt; oElapsed = oElapsed + dt
        local r=OCFG.dist; local h=OCFG.height; local x,y,z=0,h,0
        local m=OCFG.mode
        if m=="Circle" then x=math.cos(oAngle)*r; z=math.sin(oAngle)*r
        elseif m=="Figure8" then x=math.sin(oAngle)*r; z=math.sin(oAngle)*math.cos(oAngle)*r*0.7
        elseif m=="SpiralIn" then oCurR=math.max(1,oCurR-dt*2); x=math.cos(oAngle)*oCurR; z=math.sin(oAngle)*oCurR
        elseif m=="SpiralOut" then oCurR=math.min(r*2,oCurR+dt*2); x=math.cos(oAngle)*oCurR; z=math.sin(oAngle)*oCurR
        elseif m=="Bounce" then x=math.cos(oAngle)*r; z=math.sin(oAngle)*r; y=h+math.sin(oElapsed*3)*5
        end
        local dst=tp+Vector3.new(x,y,z)
        local sm=root.Position:Lerp(dst,OCFG.lerp)
        pcall(function()
            root.CFrame=OCFG.faceTarget and CFrame.new(sm,Vector3.new(tp.X,sm.Y,tp.Z)) or CFrame.new(sm)
        end)
    end))
end
local function stopOrbit() KC("orbit"); OCFG.enabled=false end

-- Fly Mode implementation
local FLYCFG = {enabled=false}
local _flyBG, _flyBV = nil, nil

local function startFly()
    KC("fly")
    if not root then return end
    pcall(function()
        _flyBG = Instance.new("BodyGyro")
        _flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
        _flyBG.P = 1e5
        _flyBG.D = 100
        _flyBG.Parent = root

        _flyBV = Instance.new("BodyVelocity")
        _flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
        _flyBV.Velocity = Vector3.zero
        _flyBV.Parent = root
    end)
    FLYCFG.enabled = true
    AC("fly", RunService.Heartbeat:Connect(function()
        if not FLYCFG.enabled or not root then KC("fly"); return end
        pcall(function()
            if hum then hum.PlatformStand = true end
            local spd = Options.FlySpeed and Options.FlySpeed.Value or 80
            local cf = Camera.CFrame
            local vel = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel + Vector3.new(0,-1,0) end
            if vel.Magnitude > 0 then vel = vel.Unit * spd end
            if _flyBV and _flyBV.Parent then _flyBV.Velocity = vel end
            if _flyBG and _flyBG.Parent then _flyBG.CFrame = cf end
        end)
    end))
end

local function stopFly()
    KC("fly")
    FLYCFG.enabled = false
    pcall(function()
        if hum then hum.PlatformStand = false end
        if _flyBG and _flyBG.Parent then _flyBG:Destroy() end
        if _flyBV and _flyBV.Parent then _flyBV:Destroy() end
        _flyBG, _flyBV = nil, nil
    end)
end

-- Bunny Hop
local _bhopConn = nil
local function setupBhop()
    if _bhopConn then _bhopConn:Disconnect() end
    _bhopConn = RunService.Heartbeat:Connect(function()
        if not Toggles.BhopOn or not Toggles.BhopOn.Value then return end
        if not hum or not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
        pcall(function()
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end)
end

-- Super Jump
local function applyJump()
    if not hum then return end
    pcall(function()
        if Toggles.SuperJump and Toggles.SuperJump.Value then
            hum.JumpPower = Options.JumpPower and Options.JumpPower.Value or 150
        else
            hum.JumpPower = 50
        end
    end)
end

local ACFG = {enabled=false,mode="Spin",speed=5000,angle=90,randSpeed=true,jitterPitch=true}
local aaAcc=0; local aaJS=0; local aaRT=0; local aaRM=1

local function startAntiAim()
    KC("antiaim")
    AC("antiaim",RunService.Heartbeat:Connect(function(dt)
        if not ACFG.enabled or not root then KC("antiaim"); return end
        local spd=ACFG.speed
        if ACFG.randSpeed then
            aaRT = aaRT + dt; if aaRT>0.1 then aaRT=0; aaRM=0.2+math.random()*0.8 end
            spd=spd*aaRM
        end
        pcall(function()
            if ACFG.mode=="Spin" then
                aaAcc = aaAcc + spd*dt
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

local RCFG = {enabled=false,speed=0.03,range=50,evadeRange=30,spinSpeed=180}
local rTimer=0; local rAngle=0

local function startRiot()
    KC("riot")
    AC("riot",RunService.Heartbeat:Connect(function(dt)
        if not RCFG.enabled or not root then KC("riot"); return end
        rTimer = rTimer + dt; if rTimer<RCFG.speed then return end; rTimer=0
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
        rAngle = rAngle + RCFG.spinSpeed*dt; if rAngle>=360 then rAngle = rAngle - 360 end
        pcall(function()
            root.CFrame=CFrame.new(np)*CFrame.Angles(0,math.rad(rAngle),0)
            root.AssemblyLinearVelocity=Vector3.zero
        end)
    end))
end
local function stopRiot() KC("riot"); RCFG.enabled=false end

local RABCFG = {enabled=false,mode="Stick",height=3,forward=0,right=0,down=0}
local function startRiotAbuse()
    KC("riotabuse")
    AC("riotabuse",RunService.Heartbeat:Connect(function(dt)
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

local DCFG = {enabled=false,radius=20,dist=30,cooldown=0.3,threshold=800,mult=1}
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

local NSCFG = {enabled=false,myName="UNCODE",otherName="Player",levelSpoof=false,level=77,wsSpoof=false,ws=100}

local function spoofLeaderstats()
    local ls=LP:FindFirstChild("CustomLeaderstats"); if not ls then return end
    if NSCFG.levelSpoof then
        local lv=ls:FindFirstChild("Level")
        if lv and lv:IsA("IntValue") then lv.Value=NSCFG.level end
        pcall(function() LP:SetAttribute("Level",NSCFG.level) end)
    end
    if NSCFG.wsSpoof then
        local wsf=ls:FindFirstChild("Win Streak")
        if wsf then
            local wsv=wsf:IsA("Folder") and wsf:FindFirstChildWhichIsA("IntValue") or (wsf:IsA("IntValue") and wsf)
            if wsv then wsv.Value=NSCFG.ws end
        end
        pcall(function() LP:SetAttribute("StatisticDuelsWinStreak",NSCFG.ws) end)
    end
end

local nsLoopConn
local function startNameSpoof()
    if nsLoopConn then nsLoopConn:Disconnect() end
    pcall(function()
        LP.DisplayName=NSCFG.myName
        LP.Name=NSCFG.myName
    end)
    spoofLeaderstats()
    nsLoopConn=task.spawn(function()
        while NSCFG.enabled do
            pcall(spoofLeaderstats)
            task.wait(3)
        end
    end)

    task.spawn(function()
        while NSCFG.enabled do
            pcall(function()
                local gui=LP:FindFirstChild("PlayerGui")
                if not gui then return end
                local function scan(inst)
                    for _,c in ipairs(inst:GetChildren()) do
                        if c:IsA("TextLabel") and c.Name=="Title" then
                            local isSelf=c.Text==LP.Name or c.Text==LP.DisplayName
                            c.Text=isSelf and NSCFG.myName or NSCFG.otherName
                        end
                        scan(c)
                    end
                end
                scan(gui)
            end)
            task.wait(0.5)
        end
    end)
end

local avEnabled=false; local avTargetUID=nil

local function spoofPlayerMeta(uid,uname,dname)
    pcall(function()
        local mt=getrawmetatable(LP)
        if not mt or not setreadonly then return end
        setreadonly(mt,false)
        local oldIdx=mt.__index
        mt.__index=newcclosure(function(self,key)
            if not checkcaller() and self==LP then
                if (key=="Name" or key=="name") and uname~="" then return uname end
                if key=="DisplayName" and dname~="" then return dname end
                if (key=="UserId" or key=="userId") and uid then return uid end
            end
            return oldIdx(self,key)
        end)
        setreadonly(mt,true)
    end)
end

local function cloneAvatar(uid)
    if not uid then return end
    local c=LP.Character; if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
    local ok,desc=pcall(function() return Players:GetHumanoidDescriptionFromUserId(uid) end)
    if not ok or not desc then return end
    local ok2,model=pcall(function() return Players:CreateHumanoidModelFromDescription(desc,h.RigType) end)
    if not ok2 or not model then return end
    if c:GetAttribute("UC_Spoofed") then return end
    model:SetAttribute("UC_Spoofed",true)
    local oldCF=c:GetPivot()
    model.Name=LP.Name
    local anim=c:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then
        local ac=anim:Clone(); ac.Disabled=true; ac.Parent=model; ac.Disabled=false
    end
    LP.Character=model; model.Parent=workspace; c:Destroy()
    model:PivotTo(oldCF)
    local cam=workspace.CurrentCamera
    if cam then cam.CameraSubject=model:WaitForChild("Humanoid") end
end

local origLighting=nil
local shaderFX={}

local SHADERS = {
    Cyber      ={B=2.4,Co=0.35,Sa=0.2, Ti=Color3.fromRGB(185,210,255),Bl=0.45,BS=36,Sr=0.08,Br=0},
    Void       ={B=1.6,Co=0.55,Sa=-0.1,Ti=Color3.fromRGB(170,145,255),Bl=0.7, BS=48,Sr=0.03,Br=0},
    Neon       ={B=2.8,Co=0.5, Sa=0.45,Ti=Color3.fromRGB(190,255,245),Bl=0.9, BS=56,Sr=0.06,Br=0},
    Warm       ={B=2.1,Co=0.25,Sa=0.25,Ti=Color3.fromRGB(255,215,180),Bl=0.35,BS=30,Sr=0.1, Br=0},
    Cold       ={B=1.9,Co=0.3, Sa=0.05,Ti=Color3.fromRGB(170,220,255),Bl=0.4, BS=34,Sr=0.05,Br=0},
    Moonlight  ={B=1.45,Co=0.38,Sa=-0.18,Ti=Color3.fromRGB(165,185,255),Bl=0.28,BS=28,Sr=0.02,Br=0},
    GoldenHour ={B=2.25,Co=0.32,Sa=0.3,Ti=Color3.fromRGB(255,198,130),Bl=0.5, BS=42,Sr=0.18,Br=0},
    Cinematic  ={B=1.7,Co=0.45,Sa=-0.05,Ti=Color3.fromRGB(235,225,210),Bl=0.25,BS=24,Sr=0.12,Br=1},
    Soft       ={B=1.9,Co=0.12,Sa=0.08,Ti=Color3.fromRGB(235,238,255),Bl=0.18,BS=22,Sr=0.04,Br=1},
    DeepFried  ={B=3.1,Co=0.75,Sa=0.85,Ti=Color3.fromRGB(255,235,185),Bl=1.1, BS=64,Sr=0.16,Br=0},
}

local function capLighting()
    if origLighting then return end
    origLighting={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,
        GlobalShadows=Lighting.GlobalShadows,ExposureCompensation=Lighting.ExposureCompensation}
end

local function clearShaders()
    for _,fx in pairs(shaderFX) do pcall(fx.Destroy,fx) end; shaderFX={}
    if origLighting then for k,v in pairs(origLighting) do pcall(function() Lighting[k]=v end) end end
end

local function applyShader(nm)
    local p=SHADERS[nm]; if not p then return end; capLighting(); clearShaders()
    Lighting.Brightness=p.B; Lighting.ExposureCompensation=0.15; Lighting.ClockTime=17.5
    Lighting.FogEnd=100000; Lighting.FogStart=0
    local cc=Instance.new("ColorCorrectionEffect"); cc.Contrast=p.Co; cc.Saturation=p.Sa; cc.TintColor=p.Ti; cc.Parent=Lighting; table.insert(shaderFX,cc)
    local bl=Instance.new("BloomEffect"); bl.Intensity=p.Bl; bl.Size=p.BS; bl.Threshold=1; bl.Parent=Lighting; table.insert(shaderFX,bl)
    local sr=Instance.new("SunRaysEffect"); sr.Intensity=p.Sr; sr.Spread=0.75; sr.Parent=Lighting; table.insert(shaderFX,sr)
    if p.Br>0 then local bz=Instance.new("BlurEffect"); bz.Size=p.Br; bz.Parent=Lighting; table.insert(shaderFX,bz) end
end

local ESPs={}
local function updateESP(enabled, showName, showHP, showDist)
    if not enabled then
        for _,bb in pairs(ESPs) do if bb and bb.Parent then bb.Parent=nil end end; return
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local c=p.Character; local r=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
        if not r or not h then continue end
        if not ESPs[p] then
            local bb=Instance.new("BillboardGui")
            bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,150,0,52); bb.StudsOffset=Vector3.new(0,3,0)
            local nl=Instance.new("TextLabel",bb); nl.Name="N"; nl.Size=UDim2.new(1,0,0,16); nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold; nl.TextSize=12; nl.TextColor3=Color3.fromRGB(120,80,255); nl.TextStrokeTransparency=0.5
            local hl=Instance.new("TextLabel",bb); hl.Name="H"; hl.Size=UDim2.new(1,0,0,14); hl.Position=UDim2.new(0,0,0,17); hl.BackgroundTransparency=1; hl.Font=Enum.Font.Gotham; hl.TextSize=11
            local dl=Instance.new("TextLabel",bb); dl.Name="D"; dl.Size=UDim2.new(1,0,0,12); dl.Position=UDim2.new(0,0,0,32); dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham; dl.TextSize=10; dl.TextColor3=Color3.fromRGB(160,160,180)
            ESPs[p]=bb
        end
        local bb=ESPs[p]; bb.Adornee=r; bb.Parent=CoreGui
        local N=bb:FindFirstChild("N"); local H=bb:FindFirstChild("H"); local D=bb:FindFirstChild("D")
        if N then N.Text=showName and p.Name or "" end
        if H and showHP then
            local hp=math.floor(h.Health); local mhp=math.max(math.floor(h.MaxHealth),1); local rat=hp/mhp
            H.Text=hp.."/"..mhp; H.TextColor3=Color3.fromRGB(math.floor((1-rat)*210),math.floor(rat*190),60)
        elseif H then H.Text="" end
        if D and showDist and Camera then
            D.Text=math.floor((Camera.CFrame.Position-r.Position).Magnitude).."m"
        elseif D then D.Text="" end
    end
    for p,bb in pairs(ESPs) do if not p.Parent then bb:Destroy(); ESPs[p]=nil end end
end

local function setupMovement()

    AC("noclip_char",LP.CharacterAdded:Connect(function(c)
        AC("noclip",RunService.Stepped:Connect(function()
            if not Toggles.NoClip or not Toggles.NoClip.Value then return end
            for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end))
        AC("speed",RunService.Heartbeat:Connect(function()
            local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
            if Toggles.SpeedOn and Toggles.SpeedOn.Value then
                h.WalkSpeed=Options.SpeedVal and Options.SpeedVal.Value or 60
            end
            if Toggles.SuperJump and Toggles.SuperJump.Value then
                h.JumpPower=Options.JumpPower and Options.JumpPower.Value or 150
            end
        end))
    end))

    AC("infjump",UIS.JumpRequest:Connect(function()
        if Toggles.InfJump and Toggles.InfJump.Value and hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
end

local cosHooked=false
local function hookCosmetics()
    if cosHooked then return end; cosHooked=true
    pcall(function()
        local m=RS:WaitForChild("Modules",8)
        local cl=require(m:WaitForChild("CosmeticLibrary",5))
        local dc=require(LP:WaitForChild("PlayerScripts",8):WaitForChild("Controllers",8):WaitForChild("PlayerDataController",5))
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
        if dc then
            local g=dc.Get
            dc.Get=function(self,k)
                if k=="CosmeticInventory" then return setmetatable({},{__index=function() return true end}) end
                return g(self,k)
            end
        end
    end)
end

local function fetch(path)
    local ok,r=pcall(function() return game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"..path) end)
    return ok and r or nil
end

print("[UNCODE v8] Starting - loading UI library...")

local Library,ThemeManager,SaveManager
local Toggles={} local Options={}
do
    local libSrc=nil
    -- Try loading from workspace cache first (fast, no HTTP)
    pcall(function()
        local cached = dofile("Obsidian/Library.lua")
        if type(cached)=="table" then Library=cached end
    end)
    if not Library then
        -- Fallback: HTTP download
        print("[UNCODE v8] Fetching Obsidian from network...")
        libSrc=fetch("Library.lua")
        if not libSrc then
            pcall(function()
                libSrc=game:HttpGet("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/Library.lua")
            end)
        end
        if libSrc then
            local fnOk,fn=pcall(loadstring,libSrc)
            if fnOk and fn then
                local ok2,res=pcall(fn)
                if ok2 and type(res)=="table" then
                    Library=res
                else
                    warn("[UNCODE] Obsidian init failed: "..tostring(res))
                end
            else
                warn("[UNCODE] Obsidian loadstring failed: "..tostring(fn))
            end
        else
            warn("[UNCODE] Obsidian fetch failed - check HTTP permissions")
        end
    end
    if Library then
        Toggles=Library.Toggles or Toggles
        Options =Library.Options  or Options
        local tmSrc=fetch("addons/ThemeManager.lua")
        if tmSrc then pcall(function() ThemeManager=loadstring(tmSrc)() end) end
        local smSrc=fetch("addons/SaveManager.lua")
        if smSrc then pcall(function() SaveManager=loadstring(smSrc)() end) end
    end
    if not Library then

        local function fakeEl()
            local e={}
            setmetatable(e,{__index=function(_,_) return function(...) return fakeEl() end end})
            return e
        end
        local fakeToggles=setmetatable({},{__index=function() return {Value=false} end})
        local fakeOptions =setmetatable({},{__index=function() return {Value=nil}   end})
        Library={
            Toggles=fakeToggles, Options=fakeOptions,
            Notify=function() end, Unload=function() end,
            OnUnload=function(self,cb) end,
            CreateWindow=function() return fakeEl() end,
        }
        Toggles=fakeToggles; Options=fakeOptions
        warn("[UNCODE] Running in headless mode (Obsidian unavailable)")
    else
        print("[UNCODE v8] UI library loaded - building interface...")
    end

    task.wait()
end

local Window=Library:CreateWindow({
    Title="uncode",Footer="rivals . v4 . anti-kicia . anti-transcrait",
    NotifySide="Right",ShowCustomCursor=true,AutoShow=true,Center=true,
    Resizable=true,ShowMobileButtons=true,MobileButtonsSide="Left",
    ToggleKeybind=Enum.KeyCode.RightShift,EnableSidebarResize=true,
})
task.wait() 
local function Notify(t,d) pcall(function() Library:Notify({Title="uncode",Description=t,Time=d or 3}) end) end

local Tabs={}
for _,nm in ipairs({"Combat","Void","Orbit","AntiAim","Riot","Visuals","Misc","Configs","Settings"}) do
    Tabs[nm]=Window:AddTab(nm)
end

local function BT(box,id,txt,def,cb)
    local t=box:AddToggle(id,{Text=txt,Default=def or false,Callback=cb or function() end})
    pcall(function() t:AddKeyPicker(id.."_key",{Default="None",Mode="Toggle",Text=txt,SyncToggleState=true,NoUI=false}) end)
    return t
end
local _ucBoxes = {}  

pcall(function()
    local CL=Tabs.Combat:AddLeftGroupbox("Ragebot / HVH")
    BT(CL,"RB_On","Ragebot Enabled",false)
    CL:AddDropdown("RB_Prio",{Text="Priority",Default="Closest",Values={"Closest","Low HP","FOV"}})
    CL:AddDropdown("RB_Weapon",{Text="Weapon",Default="Sword",Values={"Sword","Revolver","Katana","Knife","Fist","Hammer"}})
    CL:AddSlider("RB_Interval",{Text="Interval (ms)",Default=50,Min=10,Max=500,Rounding=0})
    BT(CL,"RB_Snap","Snap-to-Target",false)
    CL:AddSlider("RB_SnapDist",{Text="Snap Distance",Default=4,Min=1,Max=20,Rounding=0})
    BT(CL,"RB_Burst","Multi-Angle Burst (4x)",true)
    CL:AddDropdown("RB_BurstN",{Text="Burst Count",Default="4x",Values={"2x","3x","4x","6x","8x"}})

    local CR=Tabs.Combat:AddRightGroupbox("Resolver / Backtrack")
    BT(CR,"Resolver_On","Resolver (Anti-Kicia/Transcrait)",true)
    CR:AddLabel("12-angle . hit-bias learning")
    BT(CR,"BT_On","Backtrack",false)
    CR:AddSlider("BT_Delay",{Text="BT Ticks",Default=8,Min=1,Max=20,Rounding=0})
    CR:AddDropdown("BT_Mode",{Text="BT Mode",Default="Position Only",Values={"Position Only","Full CFrame","Velocity-predicted"}})

    local CL2=Tabs.Combat:AddLeftGroupbox("KX Aimbot"); _ucBoxes.combatKX=CL2
    BT(CL2,"KX_On","KX Aimbot",false)
    CL2:AddSlider("KX_Smooth",{Text="Smoothness",Default=12,Min=1,Max=50,Rounding=0})
    CL2:AddSlider("KX_FOV",{Text="FOV px",Default=120,Min=10,Max=360,Rounding=0})
    CL2:AddDropdown("KX_Hitbox",{Text="Hitbox",Default="Head",Values={"Head","HumanoidRootPart","Chest"}})
    BT(CL2,"KX_Vis","Visibility Check",true)
    BT(CL2,"KX_Silent","Silent Aim",false)
    CL2:AddToggle("KX_Pred","Velocity Prediction",true)
    CL2:AddToggle("KX_FOVCircle","FOV Circle",true)
    CL2:AddDropdown("KX_Priority",{Text="Priority",Default="Closest",Values={"Closest","Lowest HP","Highest Threat"}})


    local CR2=Tabs.Combat:AddRightGroupbox("Remote Hook")
    BT(CR2,"PB_On","Position Spoof",true,function(v) PB.enabled=v end)
    BT(CR2,"PB_Pred","Prediction",true,function(v) PB.pred=v end)
    CR2:AddSlider("PB_Expand",{Text="Expand",Default=18,Min=0,Max=200,Rounding=0,Callback=function(v) PB.expand=v*0.01 end})
    CR2:AddSlider("PB_Lerp",{Text="Aim Lerp",Default=88,Min=10,Max=100,Rounding=0,Callback=function(v) PB.lerp=v*0.01 end})
    CR2:AddSlider("PB_PredMult",{Text="Pred Mult",Default=1,Min=1,Max=10,Rounding=1,Callback=function(v) PB.predMult=v end})
    CR2:AddButton("Re-hook Remotes",function() hookRemotes(); Notify("Remotes re-hooked",2) end)

    local CL3=Tabs.Combat:AddLeftGroupbox("Weapon Mods"); _ucBoxes.combatWP=CL3
    BT(CL3,"WP_NoSpread","No Spread",false)
    BT(CL3,"WP_FullAuto","Full Auto",false)
    BT(CL3,"WP_Rapid","Rapid Fire",false)
    BT(CL3,"WP_InfAmmo","Infinite Ammo",false)
    BT(CL3,"WP_AutoReload","Auto Reload",false)
    BT(CL3,"WP_NoRecoil","No Recoil",false)
    BT(CL3,"WP_NoSwing","No Swing CD",false)
    BT(CL3,"WP_Heavy","Force Heavy Attack",false)
    CL3:AddSlider("WP_Reach",{Text="Reach Extender",Default=1,Min=1,Max=50,Rounding=0})
    CL3:AddSlider("WP_FireRate",{Text="Fire Rate x",Default=1,Min=1,Max=10,Rounding=1})
end)

local _kxRP=RaycastParams.new()
_kxRP.FilterType=Enum.RaycastFilterType.Blacklist
AB("uc_kxaim",Enum.RenderPriority.Camera.Value+10,function()
    if not Toggles.KX_On or not Toggles.KX_On.Value then return end
    local tChar=getClosest(false)
    if not tChar or not tChar.Character then return end
    local hn=Options.KX_Hitbox and Options.KX_Hitbox.Value or "Head"
    local hb=tChar.Character:FindFirstChild(hn) or tChar.Character:FindFirstChild("HumanoidRootPart")
    if not hb then return end
    if Toggles.KX_Vis and Toggles.KX_Vis.Value then
        _kxRP.FilterDescendantsInstances={LP.Character,Camera}
        local res=workspace:Raycast(Camera.CFrame.Position,(hb.Position-Camera.CFrame.Position).Unit*2000,_kxRP)
        if res and not res.Instance:IsDescendantOf(tChar.Character) then return end
    end
    local sm=1/((Options.KX_Smooth and Options.KX_Smooth.Value) or 12)
    local aimPos = hb.Position
    if Toggles.KX_Pred and Toggles.KX_Pred.Value then
        pcall(function()
            local vel = hb.AssemblyLinearVelocity
            local ping = (game:GetService("Stats").Network.ServerStatsItem["Data Ping"].Value or 80) * 0.001
            aimPos = hb.Position + vel * (ping + 0.05)
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


-- FOV Circle
local _fovCircle = Drawing.new("Circle")
_fovCircle.Visible = false
_fovCircle.Color = Color3.fromRGB(255,255,255)
_fovCircle.Thickness = 1.5
_fovCircle.NumSides = 64
_fovCircle.Filled = false
_fovCircle.Transparency = 0.8

AB("fov_circle",Enum.RenderPriority.Camera.Value+1,function()
    local ok = Toggles.KX_On and Toggles.KX_On.Value
    local show = ok and Toggles.KX_FOVCircle and Toggles.KX_FOVCircle.Value
    _fovCircle.Visible = show or false
