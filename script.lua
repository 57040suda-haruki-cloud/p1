
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

-- World Changer system
local wcSkyObj=nil
local wcAtmObj=nil
local wcBackup=nil

local function wcCapture()
    if wcBackup then return end
    wcBackup={
        Brightness=Lighting.Brightness,
        ClockTime=Lighting.ClockTime,
        Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient,
        FogEnd=Lighting.FogEnd,
        FogStart=Lighting.FogStart,
        FogColor=Lighting.FogColor,
        ExposureCompensation=Lighting.ExposureCompensation,
        GlobalShadows=Lighting.GlobalShadows,
    }
end

local WORLDS = {
    ["Default"]      = {Brt=1,   Clock=14,  Amb=Color3.fromRGB(127,127,127), OAmb=Color3.fromRGB(127,127,127), Exp=0,    FogE=100000, FogS=0,    FogC=Color3.fromRGB(191,191,191), Shadows=true,  AtmDen=0.395, AtmOff=0.1, AtmC=Color3.fromRGB(199,170,140), AtmGl=0.25, AtmHz=0},
    ["Void"]         = {Brt=0,   Clock=0,   Amb=Color3.new(0,0,0),           OAmb=Color3.new(0,0,0),           Exp=-5,   FogE=30,     FogS=0,    FogC=Color3.new(0,0,0),           Shadows=false, AtmDen=1,     AtmOff=0,   AtmC=Color3.new(0,0,0),           AtmGl=0,    AtmHz=0},
    ["Cyber Night"]  = {Brt=1.8, Clock=0,   Amb=Color3.fromRGB(40,0,80),     OAmb=Color3.fromRGB(20,0,60),     Exp=0.4,  FogE=800,    FogS=0,    FogC=Color3.fromRGB(80,40,180),   Shadows=false, AtmDen=0.8,   AtmOff=0,   AtmC=Color3.fromRGB(80,40,180),   AtmGl=0.5,  AtmHz=2.2},
    ["Deep Space"]   = {Brt=0.2, Clock=0,   Amb=Color3.fromRGB(5,5,20),      OAmb=Color3.new(0,0,0),           Exp=-2,   FogE=99999,  FogS=0,    FogC=Color3.fromRGB(0,0,10),      Shadows=false, AtmDen=0,     AtmOff=0,   AtmC=Color3.fromRGB(0,0,20),      AtmGl=0,    AtmHz=0},
    ["Sunset"]       = {Brt=2.2, Clock=18,  Amb=Color3.fromRGB(200,100,60),  OAmb=Color3.fromRGB(220,140,80),  Exp=0.3,  FogE=4000,   FogS=200,  FogC=Color3.fromRGB(220,120,80),  Shadows=true,  AtmDen=0.6,   AtmOff=0.1, AtmC=Color3.fromRGB(220,130,80),  AtmGl=0.6,  AtmHz=1.8},
    ["Arctic"]       = {Brt=2.8, Clock=13,  Amb=Color3.fromRGB(160,195,255), OAmb=Color3.fromRGB(185,215,255), Exp=1,    FogE=500,    FogS=0,    FogC=Color3.fromRGB(200,225,255), Shadows=true,  AtmDen=0.9,   AtmOff=0,   AtmC=Color3.fromRGB(185,210,255), AtmGl=0.1,  AtmHz=3},
    ["Hellfire"]     = {Brt=3.2, Clock=17,  Amb=Color3.fromRGB(200,50,0),    OAmb=Color3.fromRGB(180,40,0),    Exp=0.6,  FogE=250,    FogS=0,    FogC=Color3.fromRGB(200,80,20),   Shadows=true,  AtmDen=0.85,  AtmOff=0,   AtmC=Color3.fromRGB(200,60,10),   AtmGl=0.4,  AtmHz=2},
    ["Underwater"]   = {Brt=1.1, Clock=14,  Amb=Color3.fromRGB(20,80,120),   OAmb=Color3.fromRGB(30,100,150),  Exp=-0.6, FogE=180,    FogS=0,    FogC=Color3.fromRGB(30,90,140),   Shadows=false, AtmDen=0.95,  AtmOff=0,   AtmC=Color3.fromRGB(20,80,130),   AtmGl=0,    AtmHz=4},
    ["Pastel Dream"] = {Brt=2,   Clock=15,  Amb=Color3.fromRGB(220,180,255), OAmb=Color3.fromRGB(240,200,255), Exp=0.5,  FogE=3000,   FogS=500,  FogC=Color3.fromRGB(230,210,255), Shadows=true,  AtmDen=0.45,  AtmOff=0.1, AtmC=Color3.fromRGB(220,190,255), AtmGl=0.3,  AtmHz=1},
    ["Golden Hour"]  = {Brt=2.4, Clock=17.5,Amb=Color3.fromRGB(220,160,90),  OAmb=Color3.fromRGB(240,180,100), Exp=0.3,  FogE=5000,   FogS=400,  FogC=Color3.fromRGB(220,160,80),  Shadows=true,  AtmDen=0.55,  AtmOff=0.1, AtmC=Color3.fromRGB(220,160,90),  AtmGl=0.5,  AtmHz=1.2},
    ["Midnight"]     = {Brt=0.3, Clock=1,   Amb=Color3.fromRGB(10,10,30),    OAmb=Color3.fromRGB(5,5,20),      Exp=-1.5, FogE=350,    FogS=0,    FogC=Color3.fromRGB(10,10,40),    Shadows=false, AtmDen=0.7,   AtmOff=0,   AtmC=Color3.fromRGB(10,10,50),    AtmGl=0,    AtmHz=1.5},
    ["Foggy Dawn"]   = {Brt=1.5, Clock=6,   Amb=Color3.fromRGB(200,190,220), OAmb=Color3.fromRGB(215,205,235), Exp=0.2,  FogE=100,    FogS=0,    FogC=Color3.fromRGB(200,190,220), Shadows=true,  AtmDen=0.98,  AtmOff=0,   AtmC=Color3.fromRGB(190,185,215), AtmGl=0.1,  AtmHz=5},
    ["Toxic Swamp"]  = {Brt=1.3, Clock=12,  Amb=Color3.fromRGB(50,80,20),    OAmb=Color3.fromRGB(60,90,25),    Exp=-0.3, FogE=220,    FogS=0,    FogC=Color3.fromRGB(60,90,20),    Shadows=false, AtmDen=0.9,   AtmOff=0,   AtmC=Color3.fromRGB(60,90,20),    AtmGl=0.2,  AtmHz=3},
    ["Crimson Sky"]  = {Brt=2,   Clock=10,  Amb=Color3.fromRGB(180,30,30),   OAmb=Color3.fromRGB(200,40,40),   Exp=0.2,  FogE=2000,   FogS=100,  FogC=Color3.fromRGB(180,30,30),   Shadows=true,  AtmDen=0.5,   AtmOff=0.05,AtmC=Color3.fromRGB(180,30,30),   AtmGl=0.3,  AtmHz=1},
    ["Neon Paradise"]= {Brt=2.5, Clock=22,  Amb=Color3.fromRGB(0,200,180),   OAmb=Color3.fromRGB(0,180,160),   Exp=0.6,  FogE=600,    FogS=0,    FogC=Color3.fromRGB(0,150,200),   Shadows=false, AtmDen=0.7,   AtmOff=0,   AtmC=Color3.fromRGB(0,180,200),   AtmGl=0.8,  AtmHz=2},
}

local function applyWorld(name)
    local w=WORLDS[name]; if not w then return end
    wcCapture()
    pcall(function()
        Lighting.Brightness           = w.Brt
        Lighting.ClockTime            = w.Clock
        Lighting.Ambient              = w.Amb
        Lighting.OutdoorAmbient       = w.OAmb
        Lighting.ExposureCompensation = w.Exp
        Lighting.FogEnd               = w.FogE
        Lighting.FogStart             = w.FogS
        Lighting.FogColor             = w.FogC
        Lighting.GlobalShadows        = w.Shadows
    end)
    -- Remove old atmosphere
    if wcAtmObj and wcAtmObj.Parent then wcAtmObj:Destroy(); wcAtmObj=nil end
    -- Apply atmosphere
    pcall(function()
        local atm=Instance.new("Atmosphere")
        atm.Density=w.AtmDen; atm.Offset=w.AtmOff; atm.Color=w.AtmC
        atm.Glare=w.AtmGl; atm.Haze=w.AtmHz; atm.Name="UC_WorldAtm"
        atm.Parent=Lighting; wcAtmObj=atm
        -- Remove any existing Atmosphere that isn't ours
        for _,c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Atmosphere") and c~=atm then c.Enabled=false end
        end
    end)
end

local function clearWorld()
    if wcAtmObj and wcAtmObj.Parent then wcAtmObj:Destroy(); wcAtmObj=nil end
    if wcBackup then
        for k,v in pairs(wcBackup) do pcall(function() Lighting[k]=v end) end
        wcBackup=nil
    end
    -- Re-enable original atmospheres
    pcall(function()
        for _,c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Atmosphere") and c.Name~="UC_WorldAtm" then c.Enabled=true end
        end
    end)
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
    CL2:AddColorPicker("KX_FOVColor",{Text="FOV Circle Color",Default=Color3.fromRGB(255,255,255),Callback=function(v) if _fovCircle then _fovCircle.Color=v end end})
    CL2:AddSlider("KX_FOVThick",{Text="FOV Thickness",Default=1.5,Min=0.5,Max=6,Rounding=1,Callback=function(v) if _fovCircle then _fovCircle.Thickness=v end end})
    CL2:AddSlider("KX_FOVAlpha",{Text="FOV Opacity %",Default=80,Min=10,Max=100,Rounding=0,Callback=function(v) if _fovCircle then _fovCircle.Transparency=1-(v*0.01) end end})
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
    if show then
        _fovCircle.Position = Camera.ViewportSize/2
        _fovCircle.Radius = Options.KX_FOV and Options.KX_FOV.Value or 120
        _fovCircle.Color = Options.KX_FOVColor and Options.KX_FOVColor.Value or Color3.fromRGB(255,255,255)
        _fovCircle.Thickness = Options.KX_FOVThick and Options.KX_FOVThick.Value or 1.5
        local alpha = Options.KX_FOVAlpha and Options.KX_FOVAlpha.Value or 80
        _fovCircle.Transparency = 1-(alpha*0.01)
    end
end)

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
    if d:IsA("RemoteEvent") then _atkRemCache=nil end
end)

local rbAtk=0
local rbResolver={
    angles={0,30,60,90,120,150,180,210,240,270,300,330},
    idx=1, shotsSinceAdvance=0, advanceEvery=3,
    hitBias={}, lastTargetName=nil,

    onHit=function(self, angle)
        self.hitBias[angle]=(self.hitBias[angle] or 0)+1
    end,

    get=function(self)
        return self.angles[self.idx]
    end,

    advance=function(self)

        local best,bestScore=nil,-1
        for _,a in ipairs(self.angles) do
            local s=self.hitBias[a] or 0
            if s>bestScore and a~=self.angles[self.idx] then bestScore=s; best=a end
        end
        if best and bestScore>0 then

            for i,a in ipairs(self.angles) do if a==best then self.idx=i; return end end
        end
        self.idx=(self.idx%#self.angles)+1
    end,
}

AC("ragebot",RunService.Heartbeat:Connect(function()
    if not Toggles.RB_On or not Toggles.RB_On.Value then return end
    local intv=(Options.RB_Interval and Options.RB_Interval.Value or 50)/1000
    if tick()-rbAtk<intv then return end; rbAtk=tick()

    local t=getClosest(); if not t or not t.Character then return end
    local tr=t.Character:FindFirstChild("HumanoidRootPart"); if not tr then return end
    local okPos,rawPos=pcall(function() return tr.Position end)
    local pos=okPos and rawPos or Vector3.zero

    if Toggles.RB_Snap and Toggles.RB_Snap.Value and root then
        pcall(function()
            local sd=Options.RB_SnapDist and Options.RB_SnapDist.Value or 4
            local dir=pos-root.Position; local dist=dir.Magnitude
            if dist>0.1 then root.CFrame=CFrame.new(pos-dir.Unit*math.min(sd,dist)) end
        end)
    end

    local resolverOff=0
    if Toggles.Resolver_On and Toggles.Resolver_On.Value then

        local tn=t.Name
        if rbResolver.lastTargetName~=tn then
            rbResolver.lastTargetName=tn
            rbResolver.idx=1
            rbResolver.shotsSinceAdvance=0
        end
        resolverOff=rbResolver:get()
        rbResolver.shotsSinceAdvance = rbResolver.shotsSinceAdvance + 1
        if rbResolver.shotsSinceAdvance>=rbResolver.advanceEvery then
            rbResolver.shotsSinceAdvance=0
            rbResolver:advance()
        end
    end

    local burst=Toggles.RB_Burst and Toggles.RB_Burst.Value
    local baseAngles=burst and {0,90,180,270} or {0}
    local weapon=Options.RB_Weapon and Options.RB_Weapon.Value or "Sword"
    local atkRem=_atkRemCache or findAtkRemote()
    for _,extra in ipairs(baseAngles) do
        if not atkRem then break end
        local bPos=pos+CFrame.Angles(0,math.rad(extra+resolverOff),0)*Vector3.new(0,0,0.4)
        pcall(function()
            atkRem:FireServer({id=HTTP:GenerateGUID(false),item=weapon,position=bPos,
                attackNum=math.random(1,9999),heavyAttackNum=math.random(1,9999),
                rotation=tr.CFrame.Rotation,one=Vector3.one,startAiming=true,
                packed={"\x00","\x01","\x02","\x03"}})
        end)
    end
end))

pcall(function()
    local VOID_MODES={"Quantum","Chaos","Drift","Still","Circle","Figure8","WideSweep","FastBounce","Blink","GridHop","HeightWave","SquareLoop","CrossSweep","Stairs","NoiseCloud","Spiral","Loop","SlowDrift"}
    local VL=Tabs.Void:AddLeftGroupbox("Void Control")
    BT(VL,"Void_On","Enable Void",false,function(v) VCFG.enabled=v; if v then startVoid() else stopVoid() end end)
    VL:AddDropdown("VoidMode",{Text="Mode",Default="Quantum",Values=VOID_MODES,Callback=function(v) VCFG.method=v; vElapsed=0 end})
    VL:AddSlider("VoidSpeed",{Text="Speed (x109 B/s)",Default=1,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.speed=v*1e9 end})
    VL:AddSlider("VoidRadius",{Text="Radius (x109 B)",Default=200,Min=10,Max=1000,Rounding=0,Callback=function(v) VCFG.radius=v*1e9 end})
    VL:AddSlider("VoidAlt",{Text="Altitude (x109 B)",Default=10,Min=1,Max=500,Rounding=0,Callback=function(v) VCFG.altitude=v*1e9; VCFG.radius=VCFG.radius end})
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
            if hum then hum.MaxHealth=v and math.huge or 100; hum.Health=v and math.huge or 100
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead,not v) end
        end)
    end)
end)
task.wait() 

pcall(function()
    local OL=Tabs.Orbit:AddLeftGroupbox("Orbit"); _ucBoxes.orbitLeft=OL
    BT(OL,"Orbit_On","Enable Orbit",false,function(v) OCFG.enabled=v; if v then startOrbit() else stopOrbit() end end)
    OL:AddDropdown("OrbitMode",{Text="Mode",Default="Circle",Values={"Circle","Figure8","SpiralIn","SpiralOut","Bounce"},Callback=function(v) OCFG.mode=v; oCurR=OCFG.dist end})
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

pcall(function()
    local AL=Tabs.AntiAim:AddLeftGroupbox("Anti-Aim"); _ucBoxes.aaLeft=AL
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

pcall(function()
    local GL=Tabs.Riot:AddLeftGroupbox("Riot - Erratic + Spin")
    BT(GL,"Riot_On","Enable Riot",false,function(v) RCFG.enabled=v; if v then startRiot() else stopRiot() end end)
    GL:AddSlider("Riot_Speed",{Text="Interval (s)",Default=0.03,Min=0.01,Max=0.5,Rounding=2,Callback=function(v) RCFG.speed=v end})
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

pcall(function()
    local SL=Tabs.Visuals:AddLeftGroupbox("ESP"); _ucBoxes.visLeft=SL
    BT(SL,"ESP_On","ESP Enabled",false)
    BT(SL,"ESP_Name","Show Name",true)
    BT(SL,"ESP_HP","Show Health",true)
    BT(SL,"ESP_Dist","Show Distance",true)

    local SL2=Tabs.Visuals:AddLeftGroupbox("World Changer"); _ucBoxes.visWorld=SL2
    local wcNames={}; for k in pairs(WORLDS) do table.insert(wcNames,k) end; table.sort(wcNames)
    BT(SL2,"WC_On","Enable World Changer",false,function(v)
        if v then
            applyWorld(Options.WC_World and Options.WC_World.Value or "Default")
        else
            clearWorld()
        end
    end)
    SL2:AddDropdown("WC_World",{Text="World",Default="Void",Values=wcNames,
        Callback=function(v) if Toggles.WC_On and Toggles.WC_On.Value then applyWorld(v) end end})
    SL2:AddButton("Apply World",function()
        if Toggles.WC_On and Toggles.WC_On.Value then
            applyWorld(Options.WC_World and Options.WC_World.Value or "Void"); Notify("World applied",2)
        else Notify("Enable World Changer first",2) end
    end)
    SL2:AddDivider()
    SL2:AddLabel("Fine Tune")
    SL2:AddSlider("WC_Bright",{Text="Brightness",Default=20,Min=0,Max=50,Rounding=0,
        Callback=function(v) pcall(function() Lighting.Brightness=v*0.1 end) end})
    SL2:AddSlider("WC_Clock",{Text="Time of Day (h)",Default=14,Min=0,Max=24,Rounding=0,
        Callback=function(v) pcall(function() Lighting.ClockTime=v end) end})
    SL2:AddSlider("WC_Fog",{Text="Fog Distance",Default=100,Min=10,Max=1000,Rounding=0,
        Callback=function(v) pcall(function() Lighting.FogEnd=v*10 end) end})
    SL2:AddSlider("WC_Exp",{Text="Exposure",Default=10,Min=0,Max=20,Rounding=0,
        Callback=function(v) pcall(function() Lighting.ExposureCompensation=(v-10)*0.2 end) end})
    SL2:AddButton("Reset World",function() clearWorld(); Notify("World reset",2) end)

    local SR=Tabs.Visuals:AddRightGroupbox("World / Shaders"); _ucBoxes.visRight=SR
    BT(SR,"Fullbright","Full Bright",false)
    BT(SR,"NoFog","No Fog",true,function(v) Lighting.FogEnd=v and 100000 or (origLighting and origLighting.FogEnd or 1000); Lighting.FogStart=v and 100000 or 0 end)
    BT(SR,"NoShadows","No Shadows",false,function(v) Lighting.GlobalShadows=not v end)
    BT(SR,"NoPostFX","No Post-FX",false,function(v) for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then pcall(function() fx.Enabled=not v end) end end end)
    BT(SR,"CustomFOV","Custom FOV",false)
    SR:AddSlider("FOV_Val",{Text="FOV",Default=90,Min=60,Max=130,Rounding=0,Callback=function(v) if Toggles.CustomFOV and Toggles.CustomFOV.Value then Camera.FieldOfView=v end end})
    BT(SR,"Shader_On","Shaders",false,function(v)
        if v then applyShader(Options.ShaderPreset and Options.ShaderPreset.Value or "Cyber")
        else clearShaders() end
    end)
    SR:AddDropdown("ShaderPreset",{Text="Shader",Default="Cyber",Values={"Cyber","Void","Neon","Warm","Cold","Moonlight","GoldenHour","Cinematic","Soft","DeepFried"},
        Callback=function(v) if Toggles.Shader_On and Toggles.Shader_On.Value then applyShader(v) end end})
    SR:AddButton("Apply Shader",function()
        if Toggles.Shader_On and Toggles.Shader_On.Value then
            applyShader(Options.ShaderPreset and Options.ShaderPreset.Value or "Cyber"); Notify("Shader applied",2) end end)
end)

AC("esp",RunService.Heartbeat:Connect(function()
    updateESP(
        Toggles.ESP_On and Toggles.ESP_On.Value,
        Toggles.ESP_Name and Toggles.ESP_Name.Value,
        Toggles.ESP_HP and Toggles.ESP_HP.Value,
        Toggles.ESP_Dist and Toggles.ESP_Dist.Value
    )
end))
AB("visloop",Enum.RenderPriority.Last.Value,function()
    if Toggles.Fullbright and Toggles.Fullbright.Value then
        Lighting.Brightness=3; Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
    end
    if Toggles.CustomFOV and Toggles.CustomFOV.Value then
        Camera.FieldOfView=Options.FOV_Val and Options.FOV_Val.Value or 90
    end
end)
task.wait() 

pcall(function()
    local ML=Tabs.Misc:AddLeftGroupbox("Movement"); _ucBoxes.miscLeft=ML
    BT(ML,"SpeedOn","Speed Hack",false,function(v) if not v and hum then hum.WalkSpeed=16 end end)
    ML:AddSlider("SpeedVal",{Text="Walk Speed",Default=60,Min=16,Max=300,Rounding=0})
    BT(ML,"InfJump","Infinite Jump",false)
    BT(ML,"SuperJump","Super Jump",false,function(v) if not v and hum then pcall(function() hum.JumpPower=50 end) end end)
    ML:AddSlider("JumpPower",{Text="Jump Power",Default=150,Min=50,Max=1000,Rounding=0,Callback=function(v) if Toggles.SuperJump and Toggles.SuperJump.Value and hum then pcall(function() hum.JumpPower=v end) end end})
    BT(ML,"BhopOn","Bunny Hop",false,function(v) if v then setupBhop() end end)
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

    local MR=Tabs.Misc:AddRightGroupbox("Spoof / Cosmetics"); _ucBoxes.miscRight=MR
    BT(MR,"UnlockAll","Unlock All Skins",false,function(v) if v then hookCosmetics() end end)
    MR:AddDivider()
    MR:AddLabel("Name Spoofer")
    BT(MR,"NS_On","Enable Name Spoof",false,function(v) NSCFG.enabled=v; if v then startNameSpoof() end end)
    MR:AddInput("NS_MyName",{Text="Your Spoof Name",Default="UNCODE",Placeholder="name...",ClearTextOnFocus=false,Callback=function(v) NSCFG.myName=v end})
    MR:AddInput("NS_OtherName",{Text="Enemy Spoof Name",Default="Player",Placeholder="name...",ClearTextOnFocus=false,Callback=function(v) NSCFG.otherName=v end})
    BT(MR,"NS_Level","Level Spoof",false,function(v) NSCFG.levelSpoof=v end)
    MR:AddSlider("NS_LevelV",{Text="Level",Default=77,Min=1,Max=500,Rounding=0,Callback=function(v) NSCFG.level=v end})
    BT(MR,"NS_WS","Win Streak Spoof",false,function(v) NSCFG.wsSpoof=v end)
    MR:AddSlider("NS_WSV",{Text="Win Streak",Default=100,Min=0,Max=999,Rounding=0,Callback=function(v) NSCFG.ws=v end})
    MR:AddDivider()
    MR:AddLabel("Avatar Spoofer")
    BT(MR,"AV_On","Enable Avatar Spoof",false,function(v)
        avEnabled=v
        if v and avTargetUID then task.spawn(cloneAvatar, avTargetUID) end
    end)
    MR:AddInput("AV_UID",{Text="Target User ID",Default="",Placeholder="12345...",ClearTextOnFocus=false,Callback=function(v) avTargetUID=tonumber(v) end})
    MR:AddButton("Apply Avatar",function()
        if avTargetUID then task.spawn(cloneAvatar,avTargetUID); Notify("Avatar cloning...",3) end
    end)
    MR:AddButton("Avatar: Copy Closest",function()
        local t=getClosest(); if not t then return end
        avTargetUID=t.UserId; task.spawn(cloneAvatar,avTargetUID); Notify("Copying "..t.Name,3)
    end)
end)

pcall(function()

    local PRESETS = {
        ["Anti-Kicia v3"]    = {Resolver_On=true,BT_On=true,BT_Delay=10,AA_On=true,AA_Mode="Spin",AA_Speed=5000,AA_Rand=true,Void_On=true,VoidMode="Quantum",VoidEvade=true,VoidGod=true,PB_On=true,RB_Burst=true,RB_Interval=40},
        ["Anti-Transcrait"]  = {Resolver_On=true,BT_On=true,BT_Delay=14,AA_On=true,AA_Mode="Spin",AA_Speed=5000,AA_Rand=true,Void_On=true,VoidMode="Quantum",VoidEvade=true,VoidGod=true,PB_On=true,RB_Burst=true,RB_Snap=true,RB_Interval=25},
        ["Rage Max"]         = {Resolver_On=false,BT_On=false,AA_On=true,AA_Mode="Spin",AA_Speed=5000,Void_On=true,VoidMode="Chaos",VoidEvade=false,VoidGod=true,PB_On=true,RB_Burst=true,RB_Snap=true,RB_Interval=10},
        ["Balanced HVH"]     = {Resolver_On=true,BT_On=true,BT_Delay=8,AA_On=true,AA_Mode="Jitter",AA_Speed=3000,Void_On=true,VoidMode="Quantum",VoidEvade=true,PB_On=true,RB_Burst=false,RB_Interval=60,KX_On=true},
        ["Safe / Legit"]     = {Resolver_On=false,BT_On=false,AA_On=false,Void_On=false,PB_On=false,RB_Burst=false,KX_On=true,KX_Vis=true},
        ["Orbit Spam"]       = {Orbit_On=true,OrbitMode="Circle",Void_On=true,VoidMode="Quantum",PB_On=true,RB_Burst=true},
        ["Full Defense"]     = {Dodge_On=true,VoidEvade=true,AA_On=true,AA_Mode="Spin",AA_Rand=true,Void_On=true,VoidGod=true},
        ["Speed Rush"]       = {SpeedOn=true,InfJump=true,KX_On=true,PB_On=true},
    }

    local function applyPreset(name)
        local p=PRESETS[name]; if not p then return end
        for k,v in pairs(p) do
            if Toggles[k] then pcall(function() Toggles[k]:SetValue(v) end) end
            if Options[k] and type(v)=="number" then pcall(function() Options[k]:SetValue(v) end) end
            if Options[k] and type(v)=="string" then pcall(function() Options[k]:SetValue(v) end) end
        end
        Notify("Preset: "..name,3)
    end

    local CL=Tabs.Configs:AddLeftGroupbox("Community Presets")
    CL:AddDropdown("PresetSel",{Text="Preset",Default="Anti-Kicia v3",Values={"Anti-Kicia v3","Anti-Transcrait","Rage Max","Balanced HVH","Safe / Legit","Orbit Spam","Full Defense","Speed Rush"}})
    CL:AddButton("> Apply Preset",function() applyPreset(Options.PresetSel and Options.PresetSel.Value or "Anti-Kicia v3") end)
    CL:AddLabel("Anti-Kicia v3: Resolver+BT+Evade+God")
    CL:AddLabel("Anti-Transcrait: Snap+25ms+BT14+God")
    CL:AddLabel("Rage Max: 10ms+Chaos+4xBurst")
    CL:AddLabel("Balanced: KX+Jitter+Quantum")
    CL:AddLabel("Safe: KX only")

    local CR=Tabs.Configs:AddRightGroupbox("Custom Configs")
    CR:AddInput("CfgName",{Text="Config Name",Default="",Placeholder="my_cfg",ClearTextOnFocus=false})
    CR:AddButton("Save",function()
        local n=Options.CfgName and Options.CfgName.Value or ""
        if n=="" then Notify("Enter config name",2); return end
        pcall(function()
            if not isfolder("uncode4") then makefolder("uncode4") end
            local d={}
            for k,v in pairs(Toggles) do d["T:"..k]=v.Value end
            for k,v in pairs(Options) do if type(v.Value)~="userdata" then d["O:"..k]=v.Value end end
            writefile("uncode4/"..n..".json",HTTP:JSONEncode(d))
            Notify("Saved: "..n,3)
        end)
    end)
    CR:AddButton("Load",function()
        local n=Options.CfgName and Options.CfgName.Value or ""
        if n=="" then Notify("Enter config name",2); return end
        pcall(function()
            local raw=readfile("uncode4/"..n..".json")
            local d=HTTP:JSONDecode(raw)
            for k,v in pairs(d) do
                if k:sub(1,2)=="T:" and Toggles[k:sub(3)] then pcall(function() Toggles[k:sub(3)]:SetValue(v) end)
                elseif k:sub(1,2)=="O:" and Options[k:sub(3)] and type(v)=="number" then pcall(function() Options[k:sub(3)]:SetValue(v) end)
                elseif k:sub(1,2)=="O:" and Options[k:sub(3)] and type(v)=="string" then pcall(function() Options[k:sub(3)]:SetValue(v) end)
                end
            end
            Notify("Loaded: "..n,3)
        end)
    end)
    CR:AddButton("Export to Clipboard",function()
        pcall(function()
            local d={}
            for k,v in pairs(Toggles) do d["T:"..k]=v.Value end
            for k,v in pairs(Options) do if type(v.Value)~="userdata" then d["O:"..k]=v.Value end end
            setclipboard(HTTP:JSONEncode(d)); Notify("Exported to clipboard",3)
        end)
    end)
    CR:AddButton("Import from Clipboard",function()
        pcall(function()
            local raw=getclipboard()
            local d=HTTP:JSONDecode(raw)
            for k,v in pairs(d) do
                if k:sub(1,2)=="T:" and Toggles[k:sub(3)] then pcall(function() Toggles[k:sub(3)]:SetValue(v) end)
                elseif k:sub(1,2)=="O:" and Options[k:sub(3)] then pcall(function() Options[k:sub(3)]:SetValue(v) end) end
            end
            Notify("Imported from clipboard",3)
        end)
    end)
end)

pcall(function()
    local SL=Tabs.Settings:AddLeftGroupbox("Menu")
    SL:AddLabel("Menu Toggle"):AddKeyPicker("MenuKey",{Default="RightShift",Text="Menu Key",Mode="Toggle",NoUI=false})
    Library.ToggleKeybind=Options.MenuKey
    SL:AddToggle("KeybindMenu",{Text="Keybind Menu",Default=false,Callback=function(v) pcall(function() if Library.KeybindFrame then Library.KeybindFrame.Visible=v end end) end})
    SL:AddButton("Re-hook Remotes",function() hookRemotes(); Notify("Re-hooked",2) end)
    SL:AddButton("Unload Script",function() Library:Unload() end)
    local SR=Tabs.Settings:AddRightGroupbox("Info")
    SR:AddLabel("uncode v4")
    SR:AddLabel("AC: 4-layer bypass")
    SR:AddLabel("Void: 18 modes + evade")
    SR:AddLabel("Anti-Kicia v3 + Transcrait")
    SR:AddLabel("Remote Hook projectile bypass")
    SR:AddLabel("ItemLib ShootCooldown zeroed")
    if ThemeManager then
        ThemeManager:SetLibrary(Library); ThemeManager:SetFolder("uncode4")
        pcall(function() ThemeManager:ApplyToTab(Tabs.Settings) end)
    end
    if SaveManager then
        SaveManager:SetLibrary(Library); SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({"MenuKey"}); SaveManager:SetFolder("uncode4/configs")
        pcall(function() SaveManager:BuildConfigSection(Tabs.Settings) end)
        pcall(function() SaveManager:LoadAutoloadConfig() end)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    if VCFG.enabled then startVoid() end
    if OCFG.enabled then startOrbit() end
    if DCFG.enabled then startDodge() end
    if ACFG.enabled then startAntiAim() end
    if RCFG.enabled then startRiot() end
    if RABCFG.enabled then startRiotAbuse() end
end)

Library:OnUnload(function()
    for k in pairs(Conns)  do KC(k) end
    for k in pairs(Binds)  do KB(k) end
    GE.UC4_Loaded=nil; pcall(function() _G.UC4_Loaded=nil end)
    for _,bb in pairs(ESPs) do pcall(bb.Destroy,bb) end
    clearShaders()
    clearWorld()
    pcall(function() if _fovCircle then _fovCircle:Remove() end end)
    pcall(function() if nsLoopConn then task.cancel(nsLoopConn) end end)
    pcall(function() if RV then RV:Destroy() end end)
end)

setupMovement()
pcall(function() if setfpscap then setfpscap(0) end end)
Lighting.FogEnd=100000; Lighting.FogStart=100000

Notify("uncode v4 loaded . RShift to toggle . AC bypass active",5)
print("[UNCODE v8] Loaded - RightShift to toggle menu")

local Debris      = game:GetService("Debris")
local SoundSvc    = game:GetService("SoundService")
local GuiSvc      = game:GetService("GuiService")

local function RVNew(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do if k~="Parent" then pcall(function() o[k]=v end) end end
    o.Parent = parent; return o
end
local function RVBind(c) table.insert(Conns, {Disconnect=c.Disconnect and function() c:Disconnect() end or function() end}); return c end
local function GetRVChar(pl)
    pl=pl or LP; local c=pl and pl.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then return c end
end

local RV = {
    ESP = {
        Box=false,BoxFill=Color3.fromRGB(140,230,105),BoxFill2=Color3.fromRGB(255,255,255),
        Skeleton=false,SkelC=Color3.fromRGB(255,255,255),Outline=false,Thickness=2,
        Name=false,NameA=Color3.fromRGB(255,255,255),Watermark=true,
        WatermarkText="uncode",WatermarkColor=Color3.fromRGB(184,172,255),
        Weapon=false,Distance=false,Healthbar=false,HB_A=Color3.fromRGB(120,255,120),
        HBType="gradient",Slices=1,HBSpeed=1.5,HealthLerp=0.05,
        IncludeTeam=false,MaxDistance=1200,NameType="DisplayName",Dormant=true,
        FixedScale=100,
    },
    Crosshair = {
        Enabled=false,C1=Color3.new(1,1,1),C2=Color3.new(1,1,1),C3=Color3.new(1,1,1),C4=Color3.new(1,1,1),
        DisableGame=false,Gap=8,Size=17,Thick=1,RGB=true,RotSpeed=150,Pulse=true,
        FollowMouse=true,Label=true,LabelText="uncode",Glow=true,
    },
    HitFX = { Enabled=false,Selected="fortnite damage",Material="ForceField",DisableNumbers=false },
    HitSound = { Selected="bell",Volume=5,Pitch=1 },
    Tracers = {
        Enabled=false,Outline=false,OC1=Color3.fromRGB(140,90,255),OC2=Color3.fromRGB(80,150,255),
        Selected="trail",Lifetime=0.3,Fade=0.4,PosLerp=0,Size=1,Length=4,Emission=1,Glow=5,Speed=5,
    },
    TargetHUD = { Enabled=false,OffX=17,OffY=70,ItemScale=150,UIScale=170,Mode="closest" },
    Aura = {
        Enabled=false,Mode="Cyber Blue",RGB=false,Intensity=1,Size=1,
        Light=true,Ring=true,Trail=true,Pulse=true,
    },
    Appearance = {
        Enabled=false,Color=Color3.fromRGB(255,0,0),Material="ForceField",
        NoDecal=false,Transparency=100,Aura=false,
    },
    Viewmodel = {
        OverrideEnabled=false,VMColor=Color3.fromRGB(184,172,255),VMMaterial="Neon",
        VMWireframe=false,VMNoTextures=false,VMTrans=95,
        ArmColor=Color3.new(1,1,1),ArmMaterial="Neon",ArmNoClothes=false,ArmTrans=32,
        OverrideFPS=false,FPS=60,Recoil=100,
    },
    Light = {
        Ambient=Color3.fromRGB(40,80,255),CSB=Color3.fromRGB(20,60,255),CST=Color3.fromRGB(20,60,255),
        FogColor=Color3.fromRGB(80,40,255),UseFogEnd=false,FogEnd=995,UseFogStart=false,FogStart=0,
        UseExposure=true,Exposure=-0.2,UseBright=true,Bright=3.7,UseClock=true,Clock=11.6,Shadows=false,
    },
    Sky = { Enabled=false,Selected="Vertical Milky Way",NoSunStars=false,Bloom=false,BInt=0.1,BSize=0,BThresh=0.88,SunRays=false },
    CC  = { Enabled=false,Saturation=0.1,Contrast=0,Brightness=0,Tint=Color3.new(1,1,1) },
}

local RVBackup=nil; local RVFX={}; local RVSkyObj=nil

local function RVGetFX(cls,name)
    local f=Lighting:FindFirstChild("UC_"..name)
    if f then return f end
    if not RVBackup then
        RVBackup={Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,Brightness=Lighting.Brightness,
            ClockTime=Lighting.ClockTime,FogColor=Lighting.FogColor,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,
            ExposureCompensation=Lighting.ExposureCompensation,GlobalShadows=Lighting.GlobalShadows,
            ColorShift_Bottom=Lighting.ColorShift_Bottom,ColorShift_Top=Lighting.ColorShift_Top}
    end
    local e=Instance.new(cls); e.Name="UC_"..name; e.Parent=Lighting
    table.insert(RVFX,e); return e
end

local SkyIDs = {
    ["Vertical Milky Way"]={Bk="rbxassetid://159454299",Ft="rbxassetid://159454299",Dn="rbxassetid://159454299",Lf="rbxassetid://159454299",Rt="rbxassetid://159454299",Up="rbxassetid://159454299"},
    ["Night Stars"]={Bk="rbxassetid://151165214",Ft="rbxassetid://151165214",Dn="rbxassetid://151165214",Lf="rbxassetid://151165214",Rt="rbxassetid://151165214",Up="rbxassetid://151165214"},
    ["Clean Day"]={Bk="rbxassetid://252818973",Ft="rbxassetid://252818973",Dn="rbxassetid://252818973",Lf="rbxassetid://252818973",Rt="rbxassetid://252818973",Up="rbxassetid://252818973"},
}

local function RVApplyWorld()
    local cc=RVGetFX("ColorCorrectionEffect","CC")
    cc.Enabled=RV.CC.Enabled; cc.Saturation=RV.CC.Saturation; cc.Contrast=RV.CC.Contrast; cc.Brightness=RV.CC.Brightness; cc.TintColor=RV.CC.Tint
    local L=RV.Light
    pcall(function() Lighting.Ambient=L.Ambient; Lighting.ColorShift_Bottom=L.CSB; Lighting.ColorShift_Top=L.CST; Lighting.FogColor=L.FogColor end)
    Lighting.FogEnd    = L.UseFogEnd    and L.FogEnd    or 100000
    Lighting.FogStart  = L.UseFogStart  and L.FogStart  or 5000
    if L.UseExposure then Lighting.ExposureCompensation=L.Exposure end
    if L.UseBright   then Lighting.Brightness=L.Bright end
    if L.UseClock    then Lighting.ClockTime=L.Clock end
    Lighting.GlobalShadows=L.Shadows
    local atmo=Lighting:FindFirstChildOfClass("Atmosphere"); if atmo then atmo.Density=0.25 end

    if RVSkyObj then pcall(RVSkyObj.Destroy,RVSkyObj); RVSkyObj=nil end
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") and v.Name=="UC_Sky" then v:Destroy() end end
    if RV.Sky.Enabled then
        local d=SkyIDs[RV.Sky.Selected]
        if d then
            local s=Instance.new("Sky"); s.Name="UC_Sky"
            s.SkyboxBk=d.Bk; s.SkyboxFt=d.Ft; s.SkyboxDn=d.Dn; s.SkyboxLf=d.Lf; s.SkyboxRt=d.Rt; s.SkyboxUp=d.Up
            s.CelestialBodiesShown=not RV.Sky.NoSunStars; s.Parent=Lighting; RVSkyObj=s
        end
    end
    local bl=RVGetFX("BloomEffect","Bloom")
    bl.Enabled=RV.Sky.Bloom; bl.Intensity=RV.Sky.BInt; bl.Size=math.max(RV.Sky.BSize,1); bl.Threshold=RV.Sky.BThresh
    local sr=RVGetFX("SunRaysEffect","Sun")
    sr.Enabled=RV.Sky.SunRays; sr.Intensity=0.15; sr.Spread=0.7
end

local function RVRestoreWorld()
    if RVBackup then
        pcall(function()
            for k,v in pairs(RVBackup) do Lighting[k]=v end
        end)
    end
    for _,e in ipairs(RVFX) do pcall(e.Destroy,e) end; table.clear(RVFX)
    if RVSkyObj then pcall(RVSkyObj.Destroy,RVSkyObj); RVSkyObj=nil end
    for _,v in ipairs(Lighting:GetChildren()) do if v.Name and v.Name:sub(1,3)=="UC_" then v:Destroy() end end
end

local AuraObjs={}; local AuraHue=0
local AuraPresets = {
    ["Cyber Blue"]   = {Color3.fromRGB(0,170,255),  Color3.fromRGB(0,255,255)},
    ["Blood Red"]    = {Color3.fromRGB(255,20,40),   Color3.fromRGB(255,120,0)},
    ["Venom Green"]  = {Color3.fromRGB(0,255,120),   Color3.fromRGB(180,255,0)},
    ["Royal Purple"] = {Color3.fromRGB(150,0,255),   Color3.fromRGB(255,0,200)},
    ["Sun God"]      = {Color3.fromRGB(255,200,0),   Color3.fromRGB(255,90,0)},
    ["Shadow"]       = {Color3.fromRGB(20,20,25),    Color3.fromRGB(120,0,255)},
}

local function ClearAura()
    for _,v in ipairs(AuraObjs) do pcall(function() if typeof(v)=="Instance" and v.Parent then v:Destroy() end end) end
    table.clear(AuraObjs)
end

local function BuildAura(c)
    ClearAura(); if not RV.Aura.Enabled then return end
    local hrp=c and c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local pr=AuraPresets[RV.Aura.Mode] or AuraPresets["Cyber Blue"]
    local main,second=pr[1],pr[2]
    if RV.Aura.RGB then
        AuraHue=(AuraHue+0.02)%1; main=Color3.fromHSV(AuraHue,0.9,1); second=Color3.fromHSV((AuraHue+0.12)%1,0.9,1)
    end
    local inten=math.clamp(RV.Aura.Intensity,0.3,2); local sz=math.clamp(RV.Aura.Size,0.6,1.8)
    local folder=RVNew("Folder",{Name="UC_Aura"},c); table.insert(AuraObjs,folder)
    if RV.Aura.Light then
        local pl=RVNew("PointLight",{Name="UC_L",Color=main,Brightness=2*inten,Range=16*sz,Shadows=false},hrp)
        table.insert(AuraObjs,pl)
    end
    local a0=RVNew("Attachment",{Name="UC_A0",Position=Vector3.new(0,-1.2,0)},hrp)
    local a1=RVNew("Attachment",{Name="UC_A1",Position=Vector3.new(0,2.5,0)},hrp)
    table.insert(AuraObjs,a0); table.insert(AuraObjs,a1)
    local p1=RVNew("ParticleEmitter",{
        Texture="rbxassetid://243098098",
        Color=ColorSequence.new({ColorSequenceKeypoint.new(0,second),ColorSequenceKeypoint.new(1,main)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,1)}),
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6*sz),NumberSequenceKeypoint.new(1,0.05)}),
        Speed=NumberRange.new(3*inten,6*inten),Lifetime=NumberRange.new(0.6,1.2),
        Rate=math.floor(26*inten),EmissionDirection=Enum.NormalId.Top,
        SpreadAngle=Vector2.new(35,35),Acceleration=Vector3.new(0,6,0),
    },a0); table.insert(AuraObjs,p1)
    if RV.Aura.Ring then
        local ring=RVNew("Part",{Name="UC_Ring",Shape=Enum.PartType.Cylinder,
            Size=Vector3.new(0.2,6.5*sz,6.5*sz),Transparency=0.55,CanCollide=false,
            CanQuery=false,CanTouch=false,Anchored=true,Massless=true,
            Material=Enum.Material.Neon,Color=main},folder)
        pcall(function() ring.CFrame=hrp.CFrame*CFrame.new(0,-3.05,0)*CFrame.Angles(0,0,math.rad(90)) end)
        table.insert(AuraObjs,ring)

        AC("aura_ring",RunService.Heartbeat:Connect(function()
            if not(RV.Aura.Enabled and RV.Aura.Ring) or not ring.Parent or not hrp.Parent then return end
            pcall(function() ring.CFrame=hrp.CFrame*CFrame.new(0,-3.05,0)*CFrame.Angles(0,0,math.rad(90)) end)
        end))
    end
    if RV.Aura.Trail then
        for _,ln in ipairs({"Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local limb=c:FindFirstChild(ln)
            if limb and limb:IsA("BasePart") then
                local t0=RVNew("Attachment",{Position=Vector3.new(0,0.8,0)},limb)
                local t1=RVNew("Attachment",{Position=Vector3.new(0,-0.8,0)},limb)
                local tr=RVNew("Trail",{
                    Color=ColorSequence.new({ColorSequenceKeypoint.new(0,second),ColorSequenceKeypoint.new(1,main)}),
                    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}),
                    Lifetime=0.45,WidthScale=NumberSequence.new(0.35),LightEmission=1,LightInfluence=0,
                    Attachment0=t0,Attachment1=t1,
                },limb)
                table.insert(AuraObjs,t0); table.insert(AuraObjs,t1); table.insert(AuraObjs,tr)
            end
        end
    end
end

LP.CharacterAdded:Connect(function(c)
    task.wait(0.6)
    if RV.Aura.Enabled then BuildAura(c) end
    if RV.Appearance.Enabled then

        pcall(function()
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                    p.Color=RV.Appearance.Color
                    p.Material=Enum.Material[RV.Appearance.Material] or Enum.Material.ForceField
                    p.Transparency=math.clamp(1-RV.Appearance.Transparency/100,0,1)*0.7
                end
                if RV.Appearance.NoDecal then
                    if p:IsA("Decal") or p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") then
                        pcall(p.Destroy,p)
                    end
                end
            end
        end)
    end
end)

local UNLOCK_SRC = [==[
local RS=game:GetService("ReplicatedStorage"); local LP=game:GetService("Players").LocalPlayer
if not LP then return "no lp" end
local PS=LP:WaitForChild("PlayerScripts",10); if not PS then return "no PS" end
local ctrl=PS:WaitForChild("Controllers",10); if not ctrl then return "no ctrl" end
local U=getgenv().UC_Unlock or {}; getgenv().UC_Unlock=U
U.equipped=U.equipped or {}; U.active=true
local CosLib=require(RS.Modules:WaitForChild("CosmeticLibrary",10))
if U.installed and U.cosLib==CosLib then return U.status or "already on" end
U.cosLib=CosLib
local ItemLib=require(RS.Modules:WaitForChild("ItemLibrary",10))
local DataCtrl=require(ctrl:WaitForChild("PlayerDataController",10))
local steps,ok=0,0; U.stepErr={}
local function step(fn) steps=steps+1; local ok2,err=pcall(fn); if ok2 then ok=ok+1 else U.stepErr["s"..steps]=tostring(err):sub(1,80) end end
local function utype(c,n)
    if c then local t=c.Type; if t=="Skin" or t=="Charm" or t=="Wrap" or t=="Wrapping" or t=="Dance" or t=="Emote" then return true end end
    if type(n)=="string" then local ln=n:lower(); if ln:find("charm") or ln:find("wrap") or ln:find("dance") or ln:find("emote") then return true end end
    return false
end
step(function()
    local m=RS.Modules:FindFirstChild("EnumLibrary"); if m then local el=require(m); U.EnumLib=el; if el and el.WaitForEnumBuilder then el:WaitForEnumBuilder() end end
end)
step(function()
    local cur=CosLib.OwnsCosmetic; assert(type(cur)=="function")
    CosLib.OwnsCosmetic=function(self,inv,name,wep)
        if not name or name=="" or name=="None" or (type(name)=="string" and name:find("MISSING_")) then return cur(self,inv,name,wep) end
        if utype(CosLib.Cosmetics and CosLib.Cosmetics[name],name) then return true end
        return cur(self,inv,name,wep)
    end
end)
step(function()
    local cur=DataCtrl.Get; assert(type(cur)=="function")
    DataCtrl.Get=function(self,key,...)
        if key=="CosmeticInventory" and U.active then return setmetatable({},{__index=function(_,k) return utype(CosLib.Cosmetics and CosLib.Cosmetics[k],k) end}) end
        return cur(self,key,...)
    end
end)
step(function()
    local function equipRemote() local r=RS:FindFirstChild("Remotes"); if not r then return nil end; for _,c in ipairs(r:GetDescendants()) do if c:IsA("RemoteEvent") and (c.Name:lower():find("equip") or c.Name:lower():find("cosmetic")) then return c end end end
    local rem=equipRemote(); if not rem then return end
    local forwarder=function(self,...) local args={...}; local cosType,cosName,wepName,opts=args[1],args[2],args[3],args[4]
        local c=type(cosName)=="string" and CosLib.Cosmetics and CosLib.Cosmetics[cosName] or nil
        if c and utype(c,cosName) then
            U.equipped[wepName]=U.equipped[wepName] or {}
            U.equipped[wepName][cosType]={Name=cosName,Type=cosType}
            task.defer(function() pcall(function() DataCtrl.CurrentData:Replicate("WeaponInventory") end) end)
            return
        end
        return U.trueNamecall and U.trueNamecall(self,...)
    end
    if not U.trueNamecall or U.hookJob~=game.JobId then
        U.trueNamecall=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
            local m=getnamecallmethod()
            if (m=="FireServer" or m=="InvokeServer") and self==rem then return forwarder(self,...) end
            return U.trueNamecall(self,...)
        end))
        U.hookJob=game.JobId
    end
end)
U.installed=true; U.status="ok("..ok.."/"..steps..")"
return U.status
]==]

local unlockActive=false
local function doUnlockAll()
    if not unlockActive then return end
    local fn,err=loadstring(UNLOCK_SRC,"UCUnlock")
    if fn then
        local ok2,res=pcall(fn)
        Notify("Unlock All: "..(ok2 and tostring(res) or tostring(res)),3)
    else
        Notify("Unlock All load err: "..tostring(err),3)
    end
end

local ARM_NAMES={LeftArm=true,RightArm=true,LeftHand=true,RightHand=true,Hand=true}
local VMDirty=false

local function IsArmPart(p)
    if not p or not p:IsA("BasePart") then return false end
    if ARM_NAMES[p.Name] then return true end
    return false
end

local function FindVMParts()
    local cam=workspace.CurrentCamera; if not cam then return {},{} end
    local weapons,arms={},{}
    for _,model in ipairs(cam:GetChildren()) do
        if model:IsA("Model") or model:IsA("Folder") then
            local nm=model.Name:lower()
            if nm:find("itemmodel") or nm:find("viewmodel") or nm:find("_fake") or nm=="weapon" or nm=="gun" or nm=="arms" or model:FindFirstChild("_grip",true) then
                for _,d in ipairs(model:GetDescendants()) do
                    if d:IsA("BasePart") then
                        if IsArmPart(d) then table.insert(arms,d) else table.insert(weapons,d) end
                    end
                end
            end
        end
    end
    return weapons,arms
end

local function BackupPart(p)
    if not p:GetAttribute("UC_OInit") then
        p:SetAttribute("UC_OInit",true)
        pcall(function() p:SetAttribute("UC_OColor",p.Color) end)
        p:SetAttribute("UC_OMat",tostring(p.Material))
        p:SetAttribute("UC_OTrans",p.Transparency)
    end
end

local function RestorePart(p)
    if not p:GetAttribute("UC_OInit") then return end
    pcall(function()
        local c=p:GetAttribute("UC_OColor"); if typeof(c)=="Color3" then p.Color=c end
        local m=p:GetAttribute("UC_OMat"); if typeof(m)=="string" and Enum.Material[m] then p.Material=Enum.Material[m] end
        local t=p:GetAttribute("UC_OTrans"); if typeof(t)=="number" then p.Transparency=t end
        for _,ch in ipairs(p:GetChildren()) do if ch.Name=="UC_Wire" then ch:Destroy() end end
        p:SetAttribute("UC_Overridden",false)
    end)
end

local function ApplyPartLook(part,color,matName,trans,wireframe,noTex,isArm,noClothes)
    BackupPart(part)
    pcall(function()
        part.Color=color
        if Enum.Material[matName] then part.Material=Enum.Material[matName] end
        if wireframe then
            part.Transparency=1
            local w=part:FindFirstChild("UC_Wire")
            if not(w and w:IsA("WireframeHandleAdornment")) then
                if w then w:Destroy() end
                local ok,wf=pcall(function()
                    local x=Instance.new("WireframeHandleAdornment")
                    x.Name="UC_Wire"; x.Adornee=part; x.Color3=color; x.Transparency=0; x.AlwaysOnTop=true; x.Parent=part
                    return x
                end)
                if ok and wf then pcall(function() wf.Color3=color end) end
            end
        else
            part.Transparency=math.clamp(trans,0,1)
            local w=part:FindFirstChild("UC_Wire"); if w then w:Destroy() end
        end
        if noTex then
            for _,ch in ipairs(part:GetChildren()) do
                if ch:IsA("Texture") or ch:IsA("Decal") or ch:IsA("SurfaceAppearance") then ch.Transparency=1 end
            end
        end
        if isArm and noClothes then
            local st=part:FindFirstChildOfClass("ShirtTexture")
            if st then if part:GetAttribute("UC_OShirtT")==nil then part:SetAttribute("UC_OShirtT",st.Transparency) end; st.Transparency=1 end
        end
        part:SetAttribute("UC_Overridden",true)
    end)
end

local function ApplyVMOverride()
    local cam=workspace.CurrentCamera; if not cam then return end
    if not RV.Viewmodel.OverrideEnabled then
        if not VMDirty then return end
        for _,d in ipairs(cam:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("UC_Overridden") then RestorePart(d) end end
        VMDirty=false; return
    end
    VMDirty=true
    local vmT=1-math.clamp(RV.Viewmodel.VMTrans,0,100)/100*0.9
    local armT=1-math.clamp(RV.Viewmodel.ArmTrans,0,100)/100*0.9
    local weapons,arms=FindVMParts()
    for _,p in ipairs(weapons) do
        if not p:GetAttribute("IgnoreTransparency") then
            ApplyPartLook(p,RV.Viewmodel.VMColor,RV.Viewmodel.VMMaterial,1-vmT,RV.Viewmodel.VMWireframe,RV.Viewmodel.VMNoTextures,false,false)
        end
    end
    for _,p in ipairs(arms) do
        ApplyPartLook(p,RV.Viewmodel.ArmColor,RV.Viewmodel.ArmMaterial,1-armT,false,false,true,RV.Viewmodel.ArmNoClothes)
    end
end

local vmTimer=0
AC("vmoverride",RunService.Heartbeat:Connect(function(dt)
    vmTimer = vmTimer + dt; if vmTimer<0.2 then return end; vmTimer=0
    pcall(ApplyVMOverride)
end))

local RVESPGui={}
local visGui=RVNew("ScreenGui",{Name="UC_Vis",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},CoreGui)

local function ClearRVESP(p)
    local f=RVESPGui[p]; if f then pcall(f.Destroy,f); RVESPGui[p]=nil end
    local hl=RVESPGui[p.Name.."_hl"]; if hl then pcall(hl.Destroy,hl); RVESPGui[p.Name.."_hl"]=nil end
    RVESPGui[p.Name.."_refs"]=nil
end

local function MakeRVESP(p)
    ClearRVESP(p)
    local c=p.Character; if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local root=RVNew("BillboardGui",{Name="UC_ESP_"..p.Name,Adornee=hrp,Size=UDim2.new(0,120,0,96),StudsOffset=Vector3.new(0,2.5,0),AlwaysOnTop=true},visGui)
    RVESPGui[p]=root

    local box=RVNew("Frame",{Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0,26),BackgroundTransparency=1,BorderSizePixel=0,Visible=RV.ESP.Box},root)
    local corners={}
    local L0=14; local T0=math.max(1,math.floor(RV.ESP.Thickness))
    local defs={{0,0,L0,T0},{0,0,T0,L0},{60-L0,0,L0,T0},{60-T0,0,T0,L0},{0,60-T0,L0,T0},{0,60-T0,T0,L0},{60-L0,60-T0,L0,T0},{60-T0,60-T0,T0,L0}}
    for _,d in ipairs(defs) do
        local f=RVNew("Frame",{Size=UDim2.new(0,d[3],0,d[4]),Position=UDim2.new(0,d[1],0,d[2]),BackgroundColor3=RV.ESP.BoxFill,BorderSizePixel=0},box)
        table.insert(corners,f)
    end

    local dname=RV.ESP.NameType=="DisplayName" and p.DisplayName or (RV.ESP.NameType=="Both" and p.Name.."["..p.DisplayName.."]" or p.Name)
    local nl=RVNew("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=12,TextColor3=RV.ESP.NameA,TextStrokeTransparency=0.3,Text=dname,Visible=RV.ESP.Name},root)

    local tool=c:FindFirstChildOfClass("Tool")
    local wl=RVNew("TextLabel",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,0,14),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0.4,Text=tool and tool.Name or "",Visible=RV.ESP.Weapon},root)
