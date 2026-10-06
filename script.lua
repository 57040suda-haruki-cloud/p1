
print("[UNCODE v1] Script loaded OK -- starting")
task.wait(0.1)
do

    if not getgenv().__UC_HooksApplied then
        getgenv().__UC_HooksApplied = true
        pcall(function() if setthreadidentity then setthreadidentity(8) end end)
        print("[UNCODE v1] Hooks applied (safe mode)")
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
            print("[UNCODE v1] Kicia bypass done")
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

-- [LUAHOOK] キャッシュ付きプレイヤーリスト (GetPlayers()の繰り返し呼び出しを回避)
local _safePlayersCache = nil
local function getSafePlayers()
    if _safePlayersCache then return _safePlayersCache end
    local list = {}
    for _, p in ipairs(Players:GetChildren()) do
        if p:IsA("Player") then list[#list + 1] = p end
    end
    _safePlayersCache = list
    return list
end
Players.PlayerAdded:Connect(function() _safePlayersCache = nil end)
Players.PlayerRemoving:Connect(function() _safePlayersCache = nil end)

-- [LUAHOOK] 統一入力チェック (モバイル/デスクトップ両対応)
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function isInputActive(key)
    if key == "MB1" then return isMobile or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if key == "MB2" then return isMobile or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if key == "Always" then return true end
    local kc = not isMobile and Enum.KeyCode[key]
    return kc ~= false and kc and UIS:IsKeyDown(kc) or false
end

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

    -- [Harion] GetMouse偽装フック: MiscellaneousControllerが実マウス位置を読めないようにする
    local function HookGetMouse()
        pcall(function()
            if not hookfunction then return end
            local oldGM; oldGM = hookfunction(LP.GetMouse, newcclosure(function(self, ...)
                if self == LP then
                    local ok, trace = pcall(debug.traceback)
                    if ok and type(trace) == "string" and trace:find("MiscellaneousController", 1, true) then
                        local realMouse = oldGM(self, ...)
                        return setmetatable({}, {
                            __index = function(_, key)
                                if key == "X" or key == "Y" then
                                    local loc = UIS:GetMouseLocation()
                                    return key == "X" and loc.X or loc.Y
                                end
                                local val = realMouse[key]
                                return type(val) == "function"
                                    and function(_, ...) return val(realMouse, ...) end
                                    or val
                            end,
                            __newindex = function(_, key, value) realMouse[key] = value end,
                        })
                    end
                end
                return oldGM(self, ...)
            end))
        end)
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
            HookGetMouse()
            pcall(function() ac.Enabled=false end)
            stateAC.bypassed=true
        end
    end
end)

-- [Harion] setmetatableバイパス: CameraSecurity/AnalyticsPipelineの検出をブロック
pcall(function()
    if not hookfunction then return end
    local ok, renv = pcall(getrenv)
    if not ok or not renv then return end
    local smt = rawget(renv, "setmetatable")
    if not smt then return end
    local oldSMT; oldSMT = hookfunction(smt, newcclosure(function(Table, Metatable)
        if type(Metatable) == "table" then
            local mode = rawget(Metatable, "__mode")
            if mode == "kv" or mode == "v" or mode == "k" then
                local ok2, trace = pcall(debug.traceback)
                if ok2 and type(trace) == "string" then
                    if trace:find("MiscellaneousController", 1, true)
                    or trace:find("CameraSecurity", 1, true)
                    or trace:find("AnalyticsPipelineController", 1, true) then
                        return oldSMT({1, 2, 3}, {})
                    end
                end
            end
        end
        return oldSMT(Table, Metatable)
    end))
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
                pcall(function()
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
                end)
                return old(self,data,...)
            end
        end
    end
end
task.spawn(hookRemotes)
RS.DescendantAdded:Connect(function(d) if d:IsA("RemoteEvent") then task.delay(0.1,hookRemotes) end end)

-- [LUAHOOK] AutoCollect: firetouchinterestでワークスペースの_dropオブジェクトを自動回収
local ACCFG = {enabled=false, interval=0.1}
local _accTimer = 0
local _accConn = nil
local function startAutoCollect()
    if _accConn then _accConn:Disconnect(); _accConn=nil end
    _accTimer = 0
    _accConn = RunService.Heartbeat:Connect(function(dt)
        if not ACCFG.enabled then _accConn:Disconnect(); _accConn=nil; return end
        _accTimer = _accTimer + dt
        if _accTimer < ACCFG.interval then return end
        _accTimer = 0
        pcall(function()
            if not root then return end
            local hrp = root
            for _, obj in ipairs(workspace:GetChildren()) do
                if not obj:IsA("BasePart") then continue end
                local n = obj.Name
                if not (n:find("_drop", 1, true) or n:find("Drop", 1, true) or n:find("drop", 1, true)) then continue end
                if obj:FindFirstChild("Health") or obj:FindFirstChild("Ammo")
                   or obj:FindFirstChild("Coin") or obj:FindFirstChild("Item") then
                    if firetouchinterest then
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end
                end
            end
        end)
    end)
end
local function stopAutoCollect()
    ACCFG.enabled = false
    if _accConn then _accConn:Disconnect(); _accConn=nil end
end

-- ============================================================
-- [uncode] Module helpers: 接続プール + モジュール名前空間
-- ============================================================
local _ucPool = {}
local function _ucConn(key, c)
    if not _ucPool[key] then _ucPool[key] = {} end
    table.insert(_ucPool[key], c); return c
end
local function _ucStop(key)
    for _, c in ipairs(_ucPool[key] or {}) do pcall(function() c:Disconnect() end) end
    _ucPool[key] = {}
end
local _UM = {} -- 全新規モジュールの名前空間

do -- [uncode] Chat Spam: チャットにメッセージを連続送信
local CS = {}; CS.Enabled=false; CS.Interval=2.0; CS.MsgIdx=0
CS.Messages={"gg","uncode","lol","🔥"}
local function _csSend(text)
    pcall(function()
        local tcs=cloneref(game:GetService("TextChatService"))
        local ch=tcs:FindFirstChild("TextChannels")
        ch=ch and (ch:FindFirstChild("RBXGeneral") or ch:FindFirstChild("RBXSystem"))
        if ch and ch.SendAsync then ch:SendAsync(tostring(text));return end
        local ev=RS:FindFirstChild("DefaultChatSystemChatEvents")
        ev=ev and ev:FindFirstChild("SayMessageRequest")
        if ev then ev:FireServer(tostring(text),"All") end
    end)
end
function CS.enable()
    CS.Enabled=true
    task.spawn(function()
        while CS.Enabled do
            if #CS.Messages>0 then CS.MsgIdx=(CS.MsgIdx%#CS.Messages)+1; _csSend(CS.Messages[CS.MsgIdx]) end
            task.wait(math.max(0.5,CS.Interval))
        end
    end)
end
function CS.disable() CS.Enabled=false end
function CS.setMessages(list) CS.Messages=list or CS.Messages; CS.MsgIdx=0 end
_UM.CS=CS
end -- CS

do -- [uncode] Auto Queue: マッチメイキングに自動再キュー
local AQ={}; AQ.Enabled=false; AQ.Mode="1v1"; AQ.Interval=6.0
local function _aqQueue()
    pcall(function()
        local ok,ctrl=pcall(function()
            local ps=LP:FindFirstChild("PlayerScripts")
            local c=ps and ps:FindFirstChild("Controllers",true)
            local mc=c and c.Parent:FindFirstChild("MatchmakingController")
            return mc and require(mc) or nil
        end)
        if ok and ctrl and ctrl.QueueInto then ctrl:QueueInto(AQ.Mode);return end
        local r=RS:FindFirstChild("Remotes"); if not r then return end
        local mm=r:FindFirstChild("Matchmaking"); if not mm then return end
        local jq=mm:FindFirstChild("JoinQueue"); if jq then jq:InvokeServer(AQ.Mode) end
    end)
end
function AQ.enable()
    AQ.Enabled=true
    task.spawn(function() while AQ.Enabled do _aqQueue(); task.wait(AQ.Interval) end end)
end
function AQ.disable()
    AQ.Enabled=false
    pcall(function()
        local r=RS:FindFirstChild("Remotes"); if not r then return end
        local mm=r:FindFirstChild("Matchmaking"); if not mm then return end
        local lq=mm:FindFirstChild("LeaveQueue"); if lq then lq:FireServer() end
    end)
end
_UM.AQ=AQ
end -- AQ

do -- [uncode] Animation Player: エモートアニメーション再生
local ANIM={}; ANIM.Enabled=false; ANIM.Speed=1.0; ANIM.Selected="Dance"
ANIM._track=nil; ANIM._aobj=nil
local _animList={
    ["Dance"]="507771019",["Floss"]="507776697",["Take the L"]="507776727",
    ["Samba"]="507776826",["Rock Out"]="507776870",["Gangnam Style"]="5647368185",
    ["Bodybuilder"]="3994130516",["Twirl"]="3716633898",["Still Standing"]="11435177473",
    ["The Worm"]="5432681162",["Hype Dance"]="6869813008",["Line Dance"]="4049646104",
    ["Dolphin Dance"]="5938365243",["Zesty"]="9032595690",["Frosty Flair"]="10214406616",
}
ANIM.List={}; for k in pairs(_animList) do ANIM.List[#ANIM.List+1]=k end; table.sort(ANIM.List)
local function _animStop()
    ANIM.Enabled=false
    if ANIM._track then pcall(function() ANIM._track:Stop(0.1) end); ANIM._track=nil end
    if ANIM._aobj  then pcall(function() ANIM._aobj:Destroy()  end); ANIM._aobj=nil  end
end
local function _animPlay(name)
    _animStop(); ANIM.Enabled=true
    local id=_animList[name]; if not id then return end
    task.spawn(function()
        local char=LP.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local anir=hum:FindFirstChildOfClass("Animator"); if not anir then return end
        local aobj=Instance.new("Animation"); aobj.AnimationId="rbxassetid://"..id
        local ok,t=pcall(function() return anir:LoadAnimation(aobj) end)
        if not ok then aobj:Destroy();return end
        ANIM._aobj=aobj; ANIM._track=t
        t.Priority=Enum.AnimationPriority.Action4; t.Looped=true; t:Play(0.1,1,ANIM.Speed)
        while ANIM.Enabled and t.IsPlaying do t:AdjustSpeed(ANIM.Speed); RunService.Heartbeat:Wait() end
        _animStop()
    end)
end
function ANIM.enable()  _animPlay(ANIM.Selected) end
function ANIM.disable() _animStop() end
function ANIM.setAnim(name) ANIM.Selected=name; if ANIM.Enabled then _animPlay(name) end end
_UM.ANIM=ANIM
end -- ANIM

do -- [uncode] Desync / Anti-Aim: サーバー側カメラ角度を偽装
local DESYNC={}; DESYNC.Enabled=false; DESYNC.PitchMode="disabled"; DESYNC.YawMode="disabled"
DESYNC.SpinSpeed=5.0; DESYNC.Underground=false; DESYNC._spinAngle=0
local function _dsFireCam(pitch,yaw)
    pcall(function()
        local rems=RS:FindFirstChild("Remotes"); if not rems then return end
        local repl=rems:FindFirstChild("Replication"); if not repl then return end
        local figh=repl:FindFirstChild("Fighter"); if not figh then return end
        local ucr=figh:FindFirstChild("UpdateCameraRotation"); if not ucr then return end
        ucr:FireServer(CFrame.fromEulerAnglesYXZ(math.rad(pitch),math.rad(yaw),0))
    end)
end
function DESYNC.enable()
    DESYNC.Enabled=true
    local _dsT=0
    _ucConn("DESYNC",RunService.Heartbeat:Connect(function(dt)
        if not DESYNC.Enabled then return end
        _dsT=_dsT+dt; if _dsT<0.05 then return end; _dsT=0 -- 20 Hz throttle (was every frame)
        local pitch=0
        if     DESYNC.PitchMode=="up"     then pitch=-89
        elseif DESYNC.PitchMode=="down"   then pitch=89
        elseif DESYNC.PitchMode=="zero"   then pitch=0
        elseif DESYNC.PitchMode=="random" then pitch=math.random(-89,89) end
        DESYNC._spinAngle=(DESYNC._spinAngle+DESYNC.SpinSpeed)%360
        local yaw=DESYNC._spinAngle
        if     DESYNC.YawMode=="disabled"  then
            yaw=0; if Camera then local lv=Camera.CFrame.LookVector; yaw=math.deg(math.atan2(-lv.X,-lv.Z)) end
        elseif DESYNC.YawMode=="backwards" then yaw=yaw+180
        elseif DESYNC.YawMode=="random"    then yaw=math.random(0,360) end
        _dsFireCam(DESYNC.PitchMode~="disabled" and pitch or 0,yaw)
        if DESYNC.Underground then
            pcall(function()
                local char=LP.Character; if not char then return end
                local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
                root.CFrame=root.CFrame*CFrame.new(0,-500,0)
            end)
        end
    end))
end
function DESYNC.disable() DESYNC.Enabled=false; _ucStop("DESYNC") end
_UM.DESYNC=DESYNC
end -- DESYNC

do -- [uncode] VFX: Color Correction / Bloom / Sun Rays
local VFXCFG={
    CC=false,CCBright=0,CCContrast=0,CCSat=0,CCTint=Color3.new(1,1,1),
    Bloom=false,BloomInt=0.5,BloomSize=24,BloomThresh=0.95,
    SunRays=false,SRInt=0.25,SRSpread=0.5,_cc=nil,_bl=nil,_sr=nil
}
local function _vfxCC()
    if not VFXCFG.CC then if VFXCFG._cc then VFXCFG._cc:Destroy();VFXCFG._cc=nil end;return end
    if not VFXCFG._cc then VFXCFG._cc=Instance.new("ColorCorrectionEffect",Lighting) end
    VFXCFG._cc.Brightness=VFXCFG.CCBright; VFXCFG._cc.Contrast=VFXCFG.CCContrast
    VFXCFG._cc.Saturation=VFXCFG.CCSat; VFXCFG._cc.TintColor=VFXCFG.CCTint
end
local function _vfxBloom()
    if not VFXCFG.Bloom then if VFXCFG._bl then VFXCFG._bl:Destroy();VFXCFG._bl=nil end;return end
    if not VFXCFG._bl then VFXCFG._bl=Instance.new("BloomEffect",Lighting) end
    VFXCFG._bl.Intensity=VFXCFG.BloomInt; VFXCFG._bl.Size=VFXCFG.BloomSize; VFXCFG._bl.Threshold=VFXCFG.BloomThresh
end
local function _vfxSunRays()
    if not VFXCFG.SunRays then if VFXCFG._sr then VFXCFG._sr:Destroy();VFXCFG._sr=nil end;return end
    if not VFXCFG._sr then VFXCFG._sr=Instance.new("SunRaysEffect",Lighting) end
    VFXCFG._sr.Intensity=VFXCFG.SRInt; VFXCFG._sr.Spread=VFXCFG.SRSpread
end
VFXCFG.applyCC=_vfxCC; VFXCFG.applyBloom=_vfxBloom; VFXCFG.applySunRays=_vfxSunRays
_UM.VFXCFG=VFXCFG
end -- VFXCFG

do -- [uncode] Rage Silent: UseItemリモートをフックして頭部に誘導 + FOVサークル
local RSAI={}
RSAI.Enabled    = false
RSAI.Prediction = 0.12
RSAI.HeadOffset = Vector3.new(0,0.1,0)
RSAI.FOV        = 180   -- degrees; 180 = unlimited
RSAI.ShowCircle = true  -- FOVサークル描画
RSAI.Part       = "Head" -- "Head" | "HumanoidRootPart" | "closest"
RSAI._conn      = nil
RSAI._circ      = nil

-- FOVサークル作成
local function _rsaiMakeCirc()
    pcall(function()
        if not Drawing then return end
        local c = Drawing.new("Circle")
        c.Color     = Color3.fromRGB(255,255,255)
        c.Thickness = 1
        c.Filled    = false
        c.Transparency = 0.6
        c.Visible   = false
        RSAI._circ  = c
    end)
end
pcall(_rsaiMakeCirc)

-- スクリーン中心からのFOVピクセル半径を返す
local function _fovPixelRadius(fovDeg)
    local cam = workspace.CurrentCamera
    local h   = cam.ViewportSize.Y
    local scale = (h * 0.5) / math.tan(math.rad(cam.FieldOfView) * 0.5)
    return scale * math.tan(math.rad(fovDeg * 0.5))
end

-- 指定ワールド位置がFOV内かチェック
local function _inFOV(worldPos, fovDeg)
    if fovDeg >= 180 then return true end
    local cam   = workspace.CurrentCamera
    local sp, onSc = cam:WorldToViewportPoint(worldPos)
    if not onSc then return false end
    local c  = cam.ViewportSize * 0.5
    local dx = sp.X - c.X; local dy = sp.Y - c.Y
    local r  = _fovPixelRadius(fovDeg)
    return (dx*dx + dy*dy) <= r*r
end

-- 最も近い対象Partを返す
local function _rsaiClosestPart()
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local partName = RSAI.Part
    local best, bestDist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local target
            if partName == "closest" then
                -- キャラクター全パーツから最近傍
                for _,bp in ipairs(p.Character:GetDescendants()) do
                    if bp:IsA("BasePart") then
                        local d = (bp.Position - myRoot.Position).Magnitude
                        if d < bestDist then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                bestDist = d; best = bp
                            end
                        end
                    end
                end
            else
                target = p.Character:FindFirstChild(partName == "Head" and "Head" or "HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if target and hum and hum.Health > 0 then
                    local d = (target.Position - myRoot.Position).Magnitude
                    if d < bestDist then bestDist = d; best = target end
                end
            end
        end
    end
    -- FOV内チェック
    if best and not _inFOV(best.Position, RSAI.FOV) then return nil end
    return best
end

-- キャッシュ: require()は初回のみ実行、以後は再利用
local _rsaiUtil=nil; local _rsaiEnums=nil; local _rsaiFc=nil
local _rsaiUseItem=nil; local _rsaiFire_t=0
function RSAI.enable()
    RSAI.Enabled = true
    if RSAI._conn then RSAI._conn:Disconnect() end
    -- FOVサークルを表示
    if RSAI._circ and RSAI.ShowCircle then
        local r = _fovPixelRadius(RSAI.FOV)
        local cam = workspace.CurrentCamera
        local c   = cam.ViewportSize * 0.5
        RSAI._circ.Position = Vector2.new(c.X, c.Y)
        RSAI._circ.Radius   = math.max(1, r)
        RSAI._circ.Visible  = RSAI.FOV < 180
    end
    _rsaiFire_t = 0
    RSAI._conn = RunService.Heartbeat:Connect(function(dt)
        if not RSAI.Enabled then return end
        -- FOVサークル位置更新 (毎フレーム・軽量)
        pcall(function()
            if RSAI._circ and RSAI.ShowCircle and RSAI.FOV < 180 then
                local cam = workspace.CurrentCamera
                local c   = cam.ViewportSize * 0.5
                local r   = _fovPixelRadius(RSAI.FOV)
                RSAI._circ.Position = Vector2.new(c.X, c.Y)
                RSAI._circ.Radius   = math.max(1, r)
                RSAI._circ.Visible  = true
            elseif RSAI._circ then
                RSAI._circ.Visible = false
            end
        end)
        -- UseItemは15Hz上限 (毎フレーム送信による負荷軽減)
        _rsaiFire_t = _rsaiFire_t + dt
        if _rsaiFire_t < 0.067 then return end
        _rsaiFire_t = 0
        local myChar = LP.Character; if not myChar then return end
        pcall(function()
            -- requireをキャッシュ: 初回のみ取得
            if not _rsaiUseItem then
                local rs_  = RS:FindFirstChild("Remotes"); if not rs_ then return end
                local repl = rs_:FindFirstChild("Replication"); if not repl then return end
                local figh = repl:FindFirstChild("Fighter"); if not figh then return end
                _rsaiUseItem = figh:FindFirstChild("UseItem")
            end
            if not _rsaiUseItem then return end
            if not _rsaiUtil  then pcall(function() _rsaiUtil  = require(RS.Modules.Utility) end) end
            if not _rsaiEnums then pcall(function() _rsaiEnums = require(RS.Modules.EnumLibrary) end) end
            if not _rsaiFc    then pcall(function() _rsaiFc    = require(LP.PlayerScripts.Controllers.FighterController) end) end
            if not (_rsaiUtil and _rsaiEnums and _rsaiFc) then return end
            if not _rsaiFc.LocalFighter then return end
            local item   = _rsaiFc.LocalFighter.EquippedItem; if not item then return end
            local part   = _rsaiClosestPart(); if not part then return end
            local vel     = part.Velocity or Vector3.zero
            local predicted = part.Position + vel * RSAI.Prediction + RSAI.HeadOffset
            local cam    = workspace.CurrentCamera.CFrame
            local finalCF = CFrame.new(cam.Position, cam.Position + (predicted - cam.Position).Unit)
            local cameradata = {}
            cameradata[utf8.char(1)] = {
                [utf8.char(0)] = _rsaiUtil:EncodeCFrame(finalCF),
                [utf8.char(1)] = _rsaiUtil:EncodeCFrame(finalCF),
                [utf8.char(2)] = part,
                [utf8.char(3)] = _rsaiUtil:EncodeCFrame(part.CFrame:ToObjectSpace(CFrame.new(predicted)))
            }
            _rsaiUseItem:FireServer(item:Get("ObjectID"), _rsaiEnums:ToEnum("StartShooting"), cameradata, nil)
        end)
    end)
end
function RSAI.disable()
    RSAI.Enabled = false
    if RSAI._conn then RSAI._conn:Disconnect(); RSAI._conn = nil end
    if RSAI._circ then pcall(function() RSAI._circ.Visible = false end) end
end
_UM.RSAI = RSAI
end -- RSAI

do -- [uncode] Projectile TP: 飛び道具を最近敵の頭に吸着
local PTP={}; PTP.Enabled=false
local _ptpConns={}; local _ptpAttached=setmetatable({},{__mode="k"})
local _ptpFolders={["Daggers"]=true,["Bow"]=true,["Slingshot"]=true,["Arrow"]=true,["Kunai"]=true}
local function _ptpClosestHead()
    local myChar=LP.Character; local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best,bestDist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local head=p.Character:FindFirstChild("Head")
            if head then local d=(head.Position-myRoot.Position).Magnitude; if d<bestDist then bestDist=d;best=head end end
        end
    end
    return best
end
local function _ptpAttachPart(part)
    if not PTP.Enabled or not part or not part:IsA("BasePart") or _ptpAttached[part] then return end
    _ptpAttached[part]=true; pcall(function() part.CanCollide=false;part.Massless=true end)
    task.spawn(function()
        while part and part.Parent and PTP.Enabled do
            local head=_ptpClosestHead()
            if head and head.Parent then
                pcall(function() part.AssemblyAngularVelocity=Vector3.zero; part.CFrame=CFrame.new(head.Position+Vector3.new(0,0.25,0)) end)
            end
            RunService.Heartbeat:Wait()
        end
    end)
end
local function _ptpHookFolder(folder)
    for _,d in ipairs(folder:GetDescendants()) do if d:IsA("BasePart") then _ptpAttachPart(d) end end
    table.insert(_ptpConns,folder.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then _ptpAttachPart(d) end end))
end
function PTP.enable()
    PTP.Enabled=true
    for _,child in ipairs(workspace:GetChildren()) do if _ptpFolders[child.Name] then _ptpHookFolder(child) end end
    table.insert(_ptpConns,workspace.ChildAdded:Connect(function(child) if _ptpFolders[child.Name] then _ptpHookFolder(child) end end))
end
function PTP.disable()
    PTP.Enabled=false
    for _,c in ipairs(_ptpConns) do pcall(function() c:Disconnect() end) end
    _ptpConns={}; table.clear(_ptpAttached)
end
_UM.PTP=PTP
end -- PTP

do -- [uncode] Anti Katana: 刀デフレクト中は射撃をブロック
local AKT={}; AKT.Enabled=false; AKT._deflecting={}; AKT._hooked=false; AKT._origFS=nil
local function _aktIsDeflecting(userId)
    local now=tick()
    if AKT._deflecting[userId] and AKT._deflecting[userId]>now then return true end
    AKT._deflecting[userId]=nil; return false
end
function AKT.enable()
    AKT.Enabled=true; if AKT._hooked then return end
    pcall(function()
        local useItem=RS.Remotes.Replication.Fighter.UseItem
        local enumLib=require(RS.Modules.EnumLibrary)
        local startShooting=enumLib:ToEnum("StartShooting")
        AKT._origFS=hookfunction(useItem.FireServer,newcclosure(function(self,obj,action,cameradata,...)
            if AKT.Enabled and action==startShooting then
                for _,p in ipairs(Players:GetPlayers()) do if p~=LP and _aktIsDeflecting(p.UserId) then return nil end end
            end
            return AKT._origFS(self,obj,action,cameradata,...)
        end))
        AKT._hooked=true
        local ok,katana=pcall(function()
            for _,item in ipairs(RS:GetDescendants()) do
                if item.Name=="Katana" and item:IsA("ModuleScript") then return require(item) end
            end
        end)
        if ok and katana and katana.ReplicateFromServer then
            local origRep=katana.ReplicateFromServer
            hookfunction(katana.ReplicateFromServer,newcclosure(function(self,action,...)
                local actionStr=tostring(action):lower()
                if actionStr:find("deflect") or actionStr=="startaiming" or actionStr=="startblocking" then
                    local player=rawget(self,"ClientFighter") and rawget(self,"ClientFighter").Player
                    if player and player~=LP then AKT._deflecting[player.UserId]=tick()+1.2 end
                end
                return origRep(self,action,...)
            end))
        end
    end)
end
function AKT.disable() AKT.Enabled=false; table.clear(AKT._deflecting) end
_UM.AKT=AKT
end -- AKT

do -- [uncode] Highlight ESP: Highlightインスタンスで敵を強調
local HESP={}
HESP.Enabled=false; HESP.FillColor=Color3.fromRGB(255,50,50); HESP.OutlineColor=Color3.fromRGB(255,255,255)
HESP.FillTrans=0.35; HESP.OutlineTrans=0.0; HESP.ThroughWalls=true; HESP._highlights={}
local function _hespApply(player)
    if not HESP.Enabled then return end
    local char=player.Character; if not char then return end
    if HESP._highlights[player] then
        if HESP._highlights[player].Parent then return end
        HESP._highlights[player]:Destroy()
    end
    local h=Instance.new("Highlight")
    h.FillColor=HESP.FillColor; h.OutlineColor=HESP.OutlineColor
    h.FillTransparency=HESP.FillTrans; h.OutlineTransparency=HESP.OutlineTrans
    h.DepthMode=HESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.Adornee=char; h.Parent=CoreGui; HESP._highlights[player]=h
end
local function _hespRemove(player)
    local h=HESP._highlights[player]; if h then pcall(function() h:Destroy() end) end; HESP._highlights[player]=nil
end
local function _hespRefresh()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then _hespApply(p) end end
end
function HESP.enable()
    HESP.Enabled=true; _hespRefresh()
    _ucConn("HESP_char",Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5);_hespApply(p) end)
    end))
    _ucConn("HESP_rm",Players.PlayerRemoving:Connect(_hespRemove))
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then p.CharacterAdded:Connect(function() task.wait(0.5);_hespApply(p) end) end
    end
    local _hespT=0
    _ucConn("HESP_hb",RunService.Heartbeat:Connect(function(dt)
        if not HESP.Enabled then return end
        _hespT=_hespT+dt; if _hespT<0.2 then return end; _hespT=0 -- 5 Hz十分 (Highlightの復元確認)
        for p,h in pairs(HESP._highlights) do if not h.Parent then _hespApply(p) end end
    end))
end
function HESP.disable()
    HESP.Enabled=false
    _ucStop("HESP_char");_ucStop("HESP_rm");_ucStop("HESP_hb")
    for p in pairs(HESP._highlights) do _hespRemove(p) end
end
function HESP.refresh()
    for p in pairs(HESP._highlights) do _hespRemove(p) end
    if HESP.Enabled then _hespRefresh() end
end
_UM.HESP=HESP
end -- HESP

do -- [uncode] Override Appearance: 敵キャラのマテリアル/透明度を上書き
local OAPP={}
OAPP.Enabled=false; OAPP.Material=Enum.Material.ForceField; OAPP.Transparency=0.0
OAPP.Color=nil; OAPP._origProps={}
local function _oappApplyChar(char)
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if not OAPP._origProps[part] then
                OAPP._origProps[part]={Material=part.Material,Transparency=part.Transparency,Color=part.Color}
            end
            pcall(function()
                part.Material=OAPP.Material; part.Transparency=OAPP.Transparency
                if OAPP.Color then part.Color=OAPP.Color end
            end)
        end
    end
end
local function _oappRestoreChar(char)
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and OAPP._origProps[part] then
            local orig=OAPP._origProps[part]
            pcall(function() part.Material=orig.Material;part.Transparency=orig.Transparency;part.Color=orig.Color end)
            OAPP._origProps[part]=nil
        end
    end
end
function OAPP.enable()
    OAPP.Enabled=true
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then _oappApplyChar(p.Character) end end
    _ucConn("OAPP_pa",Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c) task.wait(0.5);if OAPP.Enabled then _oappApplyChar(c) end end)
    end))
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then p.CharacterAdded:Connect(function(c) task.wait(0.5);if OAPP.Enabled then _oappApplyChar(c) end end) end
    end
end
function OAPP.disable()
    OAPP.Enabled=false; _ucStop("OAPP_pa")
    for _,p in ipairs(Players:GetPlayers()) do _oappRestoreChar(p.Character) end
    table.clear(OAPP._origProps)
end
_UM.OAPP=OAPP
end -- OAPP

do -- [uncode] XRay: 全オブジェクトを半透明にして透視
local XRAY={}
XRAY.Enabled=false; XRAY.Transparency=0.85; XRAY._modified=setmetatable({},{__mode="k"})
local function _xrayMod(obj)
    if not obj or not obj:IsA("BasePart") or obj.Anchored then return end
    if Players:GetPlayerFromCharacter(obj.Parent) then return end
    if Players:GetPlayerFromCharacter(obj.Parent and obj.Parent.Parent) then return end
    XRAY._modified[obj]=true; pcall(function() obj.LocalTransparencyModifier=1-XRAY.Transparency end)
end
local function _xrayClear()
    for obj in pairs(XRAY._modified) do
        pcall(function() if obj and obj.Parent then obj.LocalTransparencyModifier=0 end end)
    end
    table.clear(XRAY._modified)
end
function XRAY.enable()
    XRAY.Enabled=true
    for _,v in ipairs(workspace:GetDescendants()) do _xrayMod(v) end
    _ucConn("XRAY_add",workspace.DescendantAdded:Connect(_xrayMod))
end
function XRAY.disable() XRAY.Enabled=false; _ucStop("XRAY_add"); _xrayClear() end
_UM.XRAY=XRAY
end -- XRAY

do -- [uncode] Atmosphere: カスタム大気エフェクト
local ATMO={}
ATMO.Enabled=false; ATMO.Density=0.3; ATMO.Offset=0.2; ATMO.Haze=1.0; ATMO.Glare=0.5
ATMO.Color=Color3.fromRGB(199,199,199); ATMO._inst=nil
local function _atmoApply()
    if not ATMO.Enabled then if ATMO._inst then ATMO._inst.Parent=nil end;return end
    if not ATMO._inst then ATMO._inst=Instance.new("Atmosphere"); ATMO._inst.Name="UCAtmosphere" end
    ATMO._inst.Density=ATMO.Density; ATMO._inst.Offset=ATMO.Offset
    ATMO._inst.Haze=ATMO.Haze; ATMO._inst.Glare=ATMO.Glare
    ATMO._inst.Color=ATMO.Color; ATMO._inst.Parent=Lighting
end
function ATMO.enable()  ATMO.Enabled=true;  _atmoApply() end
function ATMO.disable() ATMO.Enabled=false; _atmoApply() end
ATMO._apply=_atmoApply
_UM.ATMO=ATMO
end -- ATMO

do -- [uncode] Lighting Override: 霧・時間・明度などを操作
local LGHT={}
LGHT.Enabled=false; LGHT.FogEnabled=false; LGHT.FogEnd=1000; LGHT.FogStart=0
LGHT.FogColor=Color3.fromRGB(200,200,200); LGHT.ClockEnabled=false; LGHT.ClockTime=12
LGHT.Brightness=2; LGHT.BrightEnabled=false; LGHT._orig={}
local function _lghtSave(p) if LGHT._orig[p]==nil then LGHT._orig[p]=Lighting[p] end end
local function _lghtRestore(p)
    if LGHT._orig[p]~=nil then pcall(function() Lighting[p]=LGHT._orig[p] end);LGHT._orig[p]=nil end
end
local function _lghtApply()
    if not LGHT.Enabled then
        _lghtRestore("FogEnd");_lghtRestore("FogStart");_lghtRestore("FogColor")
        _lghtRestore("ClockTime");_lghtRestore("Brightness");return
    end
    if LGHT.FogEnabled then
        _lghtSave("FogEnd");_lghtSave("FogStart");_lghtSave("FogColor")
        pcall(function() Lighting.FogEnd=LGHT.FogEnd;Lighting.FogStart=LGHT.FogStart;Lighting.FogColor=LGHT.FogColor end)
    else _lghtRestore("FogEnd");_lghtRestore("FogStart");_lghtRestore("FogColor") end
    if LGHT.ClockEnabled then _lghtSave("ClockTime"); pcall(function() Lighting.ClockTime=LGHT.ClockTime end)
    else _lghtRestore("ClockTime") end
    if LGHT.BrightEnabled then _lghtSave("Brightness"); pcall(function() Lighting.Brightness=LGHT.Brightness end)
    else _lghtRestore("Brightness") end
end
function LGHT.enable()  LGHT.Enabled=true;  _lghtApply() end
function LGHT.disable() LGHT.Enabled=false; _lghtApply() end
LGHT._apply=_lghtApply
_UM.LGHT=LGHT
end -- LGHT

do -- [uncode] FOV Changer: 視野角を変更
local WFOV={}; WFOV.Enabled=false; WFOV.FOV=90; WFOV._origFOV=nil
function WFOV.enable()
    WFOV.Enabled=true
    if not WFOV._origFOV then WFOV._origFOV=Camera.FieldOfView end
    _ucConn("WFOV",RunService.RenderStepped:Connect(function()
        if not WFOV.Enabled then return end
        pcall(function() Camera.FieldOfView=WFOV.FOV end)
    end))
end
function WFOV.disable()
    WFOV.Enabled=false; _ucStop("WFOV")
    pcall(function() if WFOV._origFOV then Camera.FieldOfView=WFOV._origFOV end end)
    WFOV._origFOV=nil
end
_UM.WFOV=WFOV
end -- WFOV

do -- [uncode] Weapon Picker v5
-- v5: Harion 互換シンプルループ (hookfunction廃止, 0.5s間隔)
-- Harion 検証済み: FireServer({s1,s2,s3,s4}) 形式
local WPK = {}
WPK.Enabled = false
WPK.Slot1   = "Assault Rifle"
WPK.Slot2   = "Handgun"
WPK.Slot3   = "Fists"
WPK.Slot4   = "Grenade"
WPK.List    = {}

local _wpkRemote    = nil
local _wpkLoopAlive = false
local _wpkConns     = {}

local function _wpkClearConns()
    for _, c in ipairs(_wpkConns) do pcall(function() c:Disconnect() end) end
    _wpkConns = {}
end

-- PickWeapons リモート取得 (RemoteEvent / RemoteFunction)
local function _wpkGetRemote()
    if _wpkRemote and _wpkRemote.Parent then return _wpkRemote end
    pcall(function()
        local rs = cloneref(game:GetService("ReplicatedStorage"))
        local r = rs:FindFirstChild("Remotes")
        r = r and r:FindFirstChild("Replication")
        r = r and r:FindFirstChild("Fighter")
        r = r and r:FindFirstChild("PickWeapons")
        if r then _wpkRemote = r; return end
        for _, v in ipairs(rs:GetDescendants()) do
            if v.Name == "PickWeapons" and
               (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                _wpkRemote = v; return
            end
        end
    end)
    return _wpkRemote
end

-- Harion 同等: FireServer({s1,s2,s3,s4})
local function _wpkFire()
    pcall(function()
        local r = _wpkGetRemote(); if not r then return end
        local payload = {WPK.Slot1, WPK.Slot2, WPK.Slot3, WPK.Slot4}
        if r:IsA("RemoteFunction") then
            r:InvokeServer(payload)
        else
            r:FireServer(payload)
        end
    end)
end

function WPK.pickOnce() _wpkFire() end

-- 武器リスト構築
local function _wpkBuildList()
    pcall(function()
        local sp = cloneref(game:GetService("StarterPlayer"))
        local wf = sp:FindFirstChild("StarterPlayerScripts")
        wf = wf and wf:FindFirstChild("Assets")
        wf = wf and wf:FindFirstChild("ViewModels")
        wf = wf and wf:FindFirstChild("Weapons")
        if not wf then return end
        for _, v in ipairs(wf:GetChildren()) do
            if v:IsA("Model") then WPK.List[#WPK.List+1] = v.Name end
        end
        local uf = wf:FindFirstChild("Unobtainable")
        if uf then
            for _, v in ipairs(uf:GetChildren()) do
                if v:IsA("Model") then WPK.List[#WPK.List+1] = v.Name end
            end
        end
        table.sort(WPK.List)
    end)
    if #WPK.List == 0 then
        WPK.List = {
            "Assault Rifle","Crossbow","Daggers","Fists","Grenade",
            "Handgun","Katana","Shotgun","SMG","Sniper","Slingshot",
        }
    end
end

function WPK.enable()
    WPK.Enabled = true
    _wpkFire() -- 即 fire
    if not _wpkLoopAlive then
        _wpkLoopAlive = true
        task.spawn(function()
            -- Harion と同じ 0.5s 間隔ループ
            while WPK.Enabled do
                pcall(_wpkFire)
                task.wait(0.5)
            end
            _wpkLoopAlive = false
        end)
    end
    local _wpkLP = cloneref(game:GetService("Players")).LocalPlayer
    -- CharacterRemoving = ラウンド終了→武器選択フェーズ
    pcall(function()
        local c = _wpkLP.CharacterRemoving:Connect(function()
            if not WPK.Enabled then return end
            task.spawn(function()
                for _ = 1, 25 do
                    if not WPK.Enabled then return end
                    pcall(_wpkFire); task.wait(0.2)
                end
            end)
        end)
        _wpkConns[#_wpkConns+1] = c
    end)
    -- PlayerGui.ChildAdded = 選択 UI 出現
    pcall(function()
        local pg = _wpkLP:FindFirstChild("PlayerGui"); if not pg then return end
        local c = pg.ChildAdded:Connect(function(child)
            if not WPK.Enabled or not child:IsA("ScreenGui") then return end
            task.spawn(function()
                for _ = 1, 20 do
                    if not WPK.Enabled then return end
                    pcall(_wpkFire); task.wait(0.15)
                end
            end)
        end)
        _wpkConns[#_wpkConns+1] = c
    end)
end

function WPK.disable()
    WPK.Enabled = false
    _wpkClearConns()
end

task.spawn(_wpkBuildList)
_UM.WPK = WPK
end -- WPK

do -- [uncode] Weapon Mods: NoSpread / FullAuto / FastShoot / FireRate override
local WPNM = {}
WPNM.Enabled = false
WPNM.NoSpread = false
WPNM.FastShoot = false
WPNM.FastProjectile = false
WPNM.FullAuto = false
WPNM.AlwaysBackstab = false
WPNM.FireRate = 100  -- %

local _wst = {
    Installed = false,
    InfoCache = setmetatable({},{__mode="k"}),
    FullAutoItems = setmetatable({},{__mode="k"}),
    ProjectileReloadCache = setmetatable({},{__mode="k"}),
    ClientItem=nil, GunItem=nil, GrenadeItem=nil,
    OriginalInput=nil, OriginalGunStart=nil,
}

local function _wpnRemember(info, key)
    if type(info)~="table" or info[key]==nil then return nil end
    local cache = _wst.InfoCache[info]
    if not cache then cache={}; _wst.InfoCache[info]=cache end
    if cache[key]==nil then cache[key]=info[key] end
    return cache[key]
end

local function _wpnApplyInfo(item)
    local info = item and item.Info
    if type(info)~="table" then return end
    local fast = WPNM.Enabled and WPNM.FastShoot
    local nosp = WPNM.Enabled and WPNM.NoSpread
    for _, key in ipairs({"ShootRecoil","ShootSpread"}) do
        local orig = _wpnRemember(info, key)
        if orig ~= nil then info[key] = (fast or nosp) and 0 or orig end
    end
    local ps = _wpnRemember(info, "ProjectileSpeed")
    if ps ~= nil then
        info.ProjectileSpeed = (WPNM.Enabled and WPNM.FastShoot) and 99999999 or ps
    end
    local fr = math.max((WPNM.FireRate or 100)/100, 0.01)
    for _, key in ipairs({"ShootCooldown","QuickShotCooldown","BurstCooldown","AttackCooldown","HeavyAttackCooldown"}) do
        local orig = _wpnRemember(info, key)
        if orig ~= nil then
            if fast then info[key] = 0
            elseif fr ~= 1 then info[key] = orig / fr
            else info[key] = orig end
        end
    end
end

local function _wpnIsLocal(item)
    if not item then return false end
    local ok, res = pcall(function()
        local f = item.ClientFighter; if not f then return false end
        if f.IsLocalPlayer==true then return true end
        return f.Player == cloneref(game:GetService("Players")).LocalPlayer
    end)
    return ok and res
end

local function _wpnRestoreInfo()
    for info, vals in pairs(_wst.InfoCache) do
        if type(info)=="table" then
            for key, val in pairs(vals) do pcall(function() info[key]=val end) end
        end
    end
end

local function _wpnStartFullAuto(item, input)
    if _wst.FullAutoItems[item] then return end
    _wst.FullAutoItems[item] = true
    task.spawn(function()
        local UIS2 = cloneref(game:GetService("UserInputService"))
        while WPNM.Enabled and WPNM.FullAuto and item and _wpnIsLocal(item)
            and UIS2:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            local info = item.Info
            local cd = info and tonumber(info.ShootCooldown) or (1/60)
            task.wait(math.clamp(cd>0 and cd or (1/60), 1/60, 1))
            if not (WPNM.Enabled and WPNM.FullAuto and _wpnIsLocal(item)) then break end
            if _wst.OriginalInput then pcall(_wst.OriginalInput, item, input) end
        end
        _wst.FullAutoItems[item] = nil
    end)
end

local function _wpnInstall()
    if _wst.Installed then return end
    pcall(function()
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local ps = lp:WaitForChild("PlayerScripts",10); if not ps then return end
        local mods = ps:WaitForChild("Modules",10); if not mods then return end
        local itemTypes = mods:WaitForChild("ItemTypes",10)

        local ok1,ci = pcall(function()
            return require(mods.ClientReplicatedClasses.ClientFighter.ClientItem)
        end)
        if not ok1 or not ci then return end
        _wst.ClientItem = ci

        if itemTypes then
            local ok2,gi = pcall(function() return require(itemTypes:WaitForChild("Gun",5)) end)
            if ok2 and gi then _wst.GunItem = gi end
            local ok5,gri = pcall(function()
                return require(itemTypes:FindFirstChild("Throwable") or itemTypes:FindFirstChild("Grenade"))
            end)
            if ok5 and gri then _wst.GrenadeItem = gri end
        end

        _wst.OriginalInput = ci.Input
        ci.Input = newcclosure(function(self, input, ...)
            if WPNM.Enabled and _wpnIsLocal(self) then _wpnApplyInfo(self) end
            local result = {_wst.OriginalInput(self, input, ...)}
            if WPNM.Enabled and WPNM.FullAuto and input=="StartShooting" and _wpnIsLocal(self) then
                _wpnStartFullAuto(self, input)
            end
            return unpack(result)
        end)

        if _wst.GunItem then
            _wst.OriginalGunStart = _wst.GunItem.StartShooting
            _wst.GunItem.StartShooting = newcclosure(function(self, ...)
                if WPNM.Enabled and _wpnIsLocal(self) then _wpnApplyInfo(self) end
                local result = {_wst.OriginalGunStart(self, ...)}
                if WPNM.Enabled and WPNM.NoSpread and _wpnIsLocal(self) and typeof(result[3])=="table" then
                    result[4] = true
                end
                return unpack(result)
            end)
        end

        _wst.Installed = true
        print("[UNCODE v1] WeaponMods hooks installed")
    end)
end

function WPNM.enable()
    WPNM.Enabled = true
    task.spawn(_wpnInstall)
end

function WPNM.disable()
    WPNM.Enabled = false
    _wpnRestoreInfo()
    if _wst.ClientItem and _wst.OriginalInput then
        pcall(function() _wst.ClientItem.Input = _wst.OriginalInput end)
    end
    if _wst.GunItem and _wst.OriginalGunStart then
        pcall(function() _wst.GunItem.StartShooting = _wst.OriginalGunStart end)
    end
    _wst.Installed = false
    table.clear(_wst.FullAutoItems)
end

_UM.WPNM = WPNM
end -- WPNM


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

-- [Harion] IsWithinPart/IsWithinTaggedPartsバイパス: Void中はOOB検出をブロック
task.spawn(function()
    task.wait(5)
    pcall(function()
        if not hookfunction then return end
        local ok, util = pcall(function()
            for _, v in ipairs(RS:GetDescendants()) do
                if v.Name == "Utility" and v:IsA("ModuleScript") then
                    local s, m = pcall(require, v)
                    if s and type(m) == "table" and m.IsWithinPart then return m end
                end
            end
        end)
        if not ok or not util then return end
        if util.IsWithinPart then
            local origIWP = util.IsWithinPart
            util.IsWithinPart = newcclosure(function(...)
                if VCFG.enabled then return true end
                return origIWP(...)
            end)
        end
        if util.IsWithinTaggedParts then
            local origIWTP = util.IsWithinTaggedParts
            util.IsWithinTaggedParts = newcclosure(function(...)
                if VCFG.enabled then return workspace.Terrain end
                return origIWTP(...)
            end)
        end
    end)
end)

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

print("[UNCODE v1] Starting - loading UI library...")

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
        print("[UNCODE v1] Fetching Obsidian from network...")
        libSrc=fetch("Library.lua")
        if not libSrc then
            pcall(function()
                libSrc=game:HttpGet("https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/Library.lua")
            end)
        end
        if libSrc then
            local fnOk,fn=pcall(loadstring,libSrc)
            libSrc=nil; pcall(collectgarbage,"collect") -- GC: ソース文字列を解放
            if fnOk and fn then
                local ok2,res=pcall(fn)
                fn=nil; pcall(collectgarbage,"collect")
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
        print("[UNCODE v1] UI library loaded - building interface...")
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
for _,nm in ipairs({"Combat","Void","Orbit","AntiAim","Riot","Visuals","Misc","Configs"}) do
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
    BT(CR2,"PB_On","Position Spoof",false,function(v) PB.enabled=v end)
    BT(CR2,"PB_Pred","Prediction",false,function(v) PB.pred=v end)
    CR2:AddSlider("PB_Expand",{Text="Expand",Default=18,Min=0,Max=200,Rounding=0,Callback=function(v) PB.expand=v*0.01 end})
    CR2:AddSlider("PB_Lerp",{Text="Aim Lerp",Default=88,Min=10,Max=100,Rounding=0,Callback=function(v) PB.lerp=v*0.01 end})
    CR2:AddSlider("PB_PredMult",{Text="Pred Mult",Default=1,Min=1,Max=10,Rounding=1,Callback=function(v) PB.predMult=v end})
    CR2:AddButton("Re-hook Remotes",function() hookRemotes(); Notify("Remotes re-hooked",2) end)

    local CL3=Tabs.Combat:AddLeftGroupbox("Weapon Mods"); _ucBoxes.combatWP=CL3
    BT(CL3,"WP_NoSpread","No Spread",false)
    BT(CL3,"WP_FullAuto","Full Auto",false)
    BT(CL3,"WP_InfAmmo","Infinite Ammo",false)
    BT(CL3,"WP_AutoReload","Auto Reload",false)
    BT(CL3,"WP_NoRecoil","No Recoil",false)
    BT(CL3,"WP_NoSwing","No Swing CD",false)
    BT(CL3,"WP_Heavy","Force Heavy Attack",false)
    CL3:AddSlider("WP_Reach",{Text="Reach Extender",Default=1,Min=1,Max=50,Rounding=0})
    CL3:AddSlider("WP_FireRate",{Text="Fire Rate x",Default=1,Min=1,Max=10,Rounding=1})
end)

-- [KX aimbot removed: E.KA handles aimbot in IIFE Part1]


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
    end
end)

-- [Ragebot removed: E.KA + E.AutoShoot handle combat in IIFE Part1]

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

-- [AC("esp") stub removed]
AB("visloop",Enum.RenderPriority.Last.Value,function()
    do local _t=os.clock() if _t-(_vlT or 0)<0.1 then return end; _vlT=_t end
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

-- ThemeManager / SaveManager 初期化 (Settings タブ廃止)
pcall(function()
    if ThemeManager then
        ThemeManager:SetLibrary(Library); ThemeManager:SetFolder("uncode4")
    end
    if SaveManager then
        SaveManager:SetLibrary(Library); SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({}); SaveManager:SetFolder("uncode4/configs")
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
    pcall(function() if nsLoopConn then task.cancel(nsLoopConn) end end)
    pcall(function() if RV then RV:Destroy() end end)
end)

setupMovement()
pcall(function() if setfpscap then setfpscap(0) end end)
Lighting.FogEnd=100000; Lighting.FogStart=100000

Notify("uncode v4 loaded . RShift to toggle . AC bypass active",5)
print("[UNCODE v1] Loaded - RightShift to toggle menu")

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
            do local _t=os.clock() if _t-(_arT or 0)<0.05 then return end; _arT=_t end
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
        local _busy2=false
        local function safeHook(self,...)
            if _busy2 then return U.trueNamecall and U.trueNamecall(self,...) end
            _busy2=true
            local ok4,m=pcall(function() return getnamecallmethod and getnamecallmethod() or "" end)
            m=(ok4 and m) or ""
            if (m=="FireServer" or m=="InvokeServer") and self==rem then
                _busy2=false; return forwarder(self,...)
            end
            _busy2=false; return U.trueNamecall and U.trueNamecall(self,...)
        end
        local wrapHook=(newcclosure and newcclosure(safeHook)) or safeHook
        local hOk,hRes=pcall(hookmetamethod,game,"__namecall",wrapHook)
        if hOk then U.trueNamecall=hRes; U.hookJob=game.JobId end
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

-- [ApplyPartLook/ApplyVMOverride/AC("vmoverride") removed: dead loop (RV.Viewmodel never set via old RV table)]

-- [RVESPGui/MakeRVESP/ClearRVESP/AC("rvESP") removed: visGui was destroyed, no instances can be parented]

-- [Crosshair GUI removed: 11 Roblox instances never rendered; RV module handles crosshair via Drawing API]

local HitSoundIDs={bell="rbxassetid://6518811702",pop="rbxassetid://9106153995",tick="rbxassetid://9106202384",fortnite="rbxassetid://9106232005"}
local TracerPool={}

local function PlayHitSnd()
    local id=HitSoundIDs[RV.HitSound.Selected] or HitSoundIDs.bell
    local s=RVNew("Sound",{SoundId=id,Volume=math.clamp(RV.HitSound.Volume,0,10),PlaybackSpeed=RV.HitSound.Pitch,Parent=SoundSvc})
    pcall(s.Play,s); Debris:AddItem(s,2)
end

local function FortniteDmg(pos,amt)
    if RV.HitFX.DisableNumbers then return end
    local part=RVNew("Part",{Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,Size=Vector3.new(0.5,0.5,0.5),CFrame=CFrame.new(pos)},workspace)
    local bb=RVNew("BillboardGui",{Size=UDim2.new(0,80,0,30),StudsOffset=Vector3.new(math.random(-2,2),3,0),AlwaysOnTop=true,Adornee=part},visGui)
    Debris:AddItem(part,0.9); Debris:AddItem(bb,0.9)
    local tl=RVNew("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.fromRGB(255,220,80),TextStrokeTransparency=0.2,Text=tostring(amt)},bb)
    task.spawn(function()
        for i=1,20 do task.wait(0.03); pcall(function() part.CFrame=part.CFrame+Vector3.new(0,0.15,0); tl.TextTransparency=i/20; tl.TextStrokeTransparency=i/20 end) end
    end)
end

local function SpawnHitClone(c)
    if not RV.HitFX.Enabled then return end
    pcall(function()
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local clone=RVNew("Part",{Size=Vector3.new(2,3,1),CFrame=hrp.CFrame,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=0.3,Material=Enum.Material[RV.HitFX.Material] or Enum.Material.ForceField,Color=Color3.fromRGB(184,172,255)},workspace)
        Debris:AddItem(clone,0.6)
        task.spawn(function() for i=1,10 do task.wait(0.05); pcall(function() clone.Transparency=0.3+i*0.07 end) end end)
    end)
end

local dmgConns={}; local hookedHC={}
local function HookHC(p,c)
    task.spawn(function()
        task.wait(0.3); if not c.Parent then return end
        local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
        local old=dmgConns[p]; if old then pcall(old.Disconnect,old) end
        local last=h.Health
        dmgConns[p]=h.HealthChanged:Connect(function(nh)
            if not c.Parent then return end
            if nh<last then
                local dmg=math.floor(last-nh); last=nh
                if RV.HitFX.Enabled then
                    local hrp=c:FindFirstChild("HumanoidRootPart")
                    if hrp then FortniteDmg(hrp.Position,dmg) end
                    SpawnHitClone(c); PlayHitSnd()
                end
            else last=nh end
        end)
    end)
end

local function HookHP(p)
    if hookedHC[p] then return end; hookedHC[p]=true
    if p.Character then HookHC(p,p.Character) end
    RVBind(p.CharacterAdded:Connect(function(c) HookHC(p,c) end))
end
for _,p in ipairs(Players:GetPlayers()) do HookHP(p) end
RVBind(Players.PlayerAdded:Connect(HookHP))

local function SpawnTracer(fromPos,toPos)
    if not RV.Tracers.Enabled then return end
    if #TracerPool>=30 then local old=table.remove(TracerPool,1); pcall(function() if old and old.Parent then old:Destroy() end end) end
    local life=math.clamp(RV.Tracers.Lifetime,0.05,2)
    local fade=math.clamp(RV.Tracers.Fade,0.05,2)
    local speedMul=5/math.max(RV.Tracers.Speed,0.5); fade=math.clamp(fade*speedMul,0.05,3)
    local lerpK=math.clamp(RV.Tracers.PosLerp,0,1)*0.15
    toPos=fromPos:Lerp(toPos,1-lerpK)
    local st=RV.Tracers.Selected
    local styleW=st=="beam" and 1.5 or st=="trail" and 0.7 or 1
    local styleE=st=="glow" and 3 or st=="energy" and 1.5 or 0
    local wBase=0.25*RV.Tracers.Size*(0.6+RV.Tracers.Length/4)*styleW
    local holder=RVNew("Part",{Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,Size=Vector3.new(0.5,0.5,0.5),CFrame=CFrame.new(fromPos),Name="UC_Trace"},workspace)
    table.insert(TracerPool,holder)
    local a0=RVNew("Attachment",{Position=Vector3.new(0,0,0)},holder)
    local a1=RVNew("Attachment",{Position=Vector3.new(0,0,0)},holder)
    pcall(function() a1.WorldPosition=toPos end)
    local beam=RVNew("Beam",{
        Attachment0=a0,Attachment1=a1,
        Color=ColorSequence.new({ColorSequenceKeypoint.new(0,RV.Tracers.OC1),ColorSequenceKeypoint.new(1,RV.Tracers.OC2)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0)}),
        Width0=wBase+(RV.Tracers.Outline and 0.15 or 0),Width1=wBase+(RV.Tracers.Outline and 0.15 or 0),
        LightEmission=math.clamp(RV.Tracers.Glow+RV.Tracers.Emission+styleE,0,10),LightInfluence=0,FaceCamera=true,
    },holder)
    task.spawn(function()
        local t=0
        while t<fade and beam.Parent do t = t + task.wait(); pcall(function() beam.Transparency=NumberSequence.new(t/fade) end) end
        pcall(holder.Destroy,holder)
    end)
    Debris:AddItem(holder,life+fade+0.5)
end

LP.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            RVBind(child.Activated:Connect(function()
                if not RV.Tracers.Enabled or not root then return end
                local cam=workspace.CurrentCamera; if not cam then return end
                local from=(cam.CFrame*CFrame.new(0.45,-0.35,-1.5)).Position
                local to=cam.CFrame.Position+cam.CFrame.LookVector*300
                SpawnTracer(from,to)
            end))
        end
    end)
end)

-- [HUD/AC("thud") removed: HUD was parentless (visGui destroyed), thud callback was empty]

pcall(function()

    local VT = Tabs.Visuals

    local EL = VT:AddLeftGroupbox("Full ESP")
    EL:AddToggle("RVESP_Box",     {Text="Corner Box",    Default=false,  Callback=function(v) RV.ESP.Box=v end})
    EL:AddToggle("RVESP_Name",    {Text="Name",          Default=false,  Callback=function(v) RV.ESP.Name=v end})
    EL:AddToggle("RVESP_HP",      {Text="Health Bar",    Default=false,  Callback=function(v) RV.ESP.Healthbar=v end})
    EL:AddToggle("RVESP_Dist",    {Text="Distance",      Default=false,  Callback=function(v) RV.ESP.Distance=v end})
    EL:AddToggle("RVESP_Weapon",  {Text="Weapon",        Default=false,  Callback=function(v) RV.ESP.Weapon=v end})
    EL:AddToggle("RVESP_Skel",    {Text="Skeleton (Highlight)", Default=false, Callback=function(v) RV.ESP.Skeleton=v end})
    EL:AddToggle("RVESP_Outline", {Text="Glow Outline",  Default=false,  Callback=function(v) RV.ESP.Outline=v end})
    EL:AddToggle("RVESP_WM",      {Text="Watermark",     Default=true,   Callback=function(v) RV.ESP.Watermark=v end})
    EL:AddSlider("RVESP_MaxD",    {Text="Max Distance",  Default=1200,Min=200,Max=3000,Rounding=0, Callback=function(v) RV.ESP.MaxDistance=v end})
    EL:AddToggle("RVESP_Team",    {Text="Include Team",  Default=false,  Callback=function(v) RV.ESP.IncludeTeam=v end})
    EL:AddDropdown("RVESP_NT",    {Text="Name Type",     Default="DisplayName", Values={"DisplayName","Username","Both"}, Callback=function(v) RV.ESP.NameType=v end})
    EL:AddDropdown("RVESP_HBT",   {Text="HP Bar Type",   Default="gradient",    Values={"gradient","solid","slices"},    Callback=function(v) RV.ESP.HBType=v end})

    local CL2 = VT:AddRightGroupbox("Crosshair")
    CL2:AddToggle("RVCross_On",   {Text="Enable Crosshair",  Default=false, Callback=function(v) RV.Crosshair.Enabled=v end})
    CL2:AddToggle("RVCross_RGB",  {Text="RGB Cycle",          Default=true,  Callback=function(v) RV.Crosshair.RGB=v end})
    CL2:AddToggle("RVCross_Pulse",{Text="Pulse + Spin",        Default=true,  Callback=function(v) RV.Crosshair.Pulse=v end})
    CL2:AddToggle("RVCross_Fol",  {Text="Follow Mouse [M]",   Default=true,  Callback=function(v) RV.Crosshair.FollowMouse=v end})
    CL2:AddToggle("RVCross_Lbl",  {Text="Label",              Default=true,  Callback=function(v) RV.Crosshair.Label=v end})
    CL2:AddInput( "RVCross_LT",   {Text="Label Text",         Default="uncode",Placeholder="text...",ClearTextOnFocus=false, Callback=function(v) RV.Crosshair.LabelText=v end})
    CL2:AddSlider("RVCross_Rot",  {Text="Rotation Speed",Default=150,Min=0,Max=300,Rounding=0, Callback=function(v) RV.Crosshair.RotSpeed=v end})
    CL2:AddSlider("RVCross_Gap",  {Text="Gap",           Default=8,  Min=0,Max=20, Rounding=0, Callback=function(v) RV.Crosshair.Gap=v end})
    CL2:AddSlider("RVCross_Size", {Text="Size",          Default=17, Min=2,Max=30, Rounding=0, Callback=function(v) RV.Crosshair.Size=v end})
    CL2:AddSlider("RVCross_Thick",{Text="Thickness",     Default=1,  Min=1,Max=6,  Rounding=0, Callback=function(v) RV.Crosshair.Thick=v end})
    CL2:AddToggle("RVCross_Dis",  {Text="Disable Game Crosshair", Default=false, Callback=function(v) RV.Crosshair.DisableGame=v end})

    local HL2 = VT:AddLeftGroupbox("Hit FX / Sound")
    HL2:AddToggle("RVHFX_On",    {Text="Hit FX Enabled",   Default=false, Callback=function(v) RV.HitFX.Enabled=v end})
    HL2:AddDropdown("RVHFX_Sel", {Text="FX Type",           Default="fortnite damage", Values={"fortnite damage","sparkles","slash"}, Callback=function(v) RV.HitFX.Selected=v end})
    HL2:AddDropdown("RVHFX_Mat", {Text="Clone Material",    Default="ForceField",      Values={"ForceField","Neon","Glass","Metal"},  Callback=function(v) RV.HitFX.Material=v end})
    HL2:AddToggle("RVHFX_NoDmg", {Text="Disable Numbers",   Default=false, Callback=function(v) RV.HitFX.DisableNumbers=v end})
    HL2:AddDropdown("RVHS_Sel",  {Text="Hit Sound",         Default="bell",Values={"bell","pop","tick","fortnite"},                   Callback=function(v) RV.HitSound.Selected=v end})
    HL2:AddSlider("RVHS_Vol",    {Text="Volume",            Default=5, Min=0,Max=10,Rounding=1, Callback=function(v) RV.HitSound.Volume=v end})
    HL2:AddSlider("RVHS_Pitch",  {Text="Pitch",             Default=1, Min=0.5,Max=2,Rounding=2, Callback=function(v) RV.HitSound.Pitch=v end})
    HL2:AddButton("Test Hit Sound", function() PlayHitSnd() end)

    local TR2 = VT:AddRightGroupbox("Custom Tracers")
    TR2:AddToggle("RVTR_On",     {Text="Tracers Enabled",  Default=false, Callback=function(v) RV.Tracers.Enabled=v end})
    TR2:AddToggle("RVTR_Out",    {Text="Outline",           Default=false, Callback=function(v) RV.Tracers.Outline=v end})
    TR2:AddDropdown("RVTR_Sel",  {Text="Style",             Default="trail",Values={"trail","beam","glow","energy"}, Callback=function(v) RV.Tracers.Selected=v end})
    TR2:AddSlider("RVTR_Life",   {Text="Lifetime (s)",  Default=0.3, Min=0.05,Max=2,   Rounding=2, Callback=function(v) RV.Tracers.Lifetime=v end})
    TR2:AddSlider("RVTR_Fade",   {Text="Fade (s)",      Default=0.4, Min=0.05,Max=2,   Rounding=2, Callback=function(v) RV.Tracers.Fade=v end})
    TR2:AddSlider("RVTR_Size",   {Text="Size",          Default=1,   Min=0.2, Max=5,   Rounding=1, Callback=function(v) RV.Tracers.Size=v end})
    TR2:AddSlider("RVTR_Len",    {Text="Length",        Default=4,   Min=1,   Max=10,  Rounding=1, Callback=function(v) RV.Tracers.Length=v end})
    TR2:AddSlider("RVTR_Glow",   {Text="Glow",         Default=5,   Min=0,   Max=10,  Rounding=1, Callback=function(v) RV.Tracers.Glow=v end})
    TR2:AddSlider("RVTR_Speed",  {Text="Speed",        Default=5,   Min=0.5, Max=20,  Rounding=1, Callback=function(v) RV.Tracers.Speed=v end})

    local THUD2 = VT:AddLeftGroupbox("Target HUD")
    THUD2:AddToggle("RVHUD_On",  {Text="Target HUD",    Default=false, Callback=function(v) RV.TargetHUD.Enabled=v end})
    THUD2:AddSlider("RVHUD_X",   {Text="Offset X %", Default=17,Min=0,Max=100,Rounding=0, Callback=function(v) RV.TargetHUD.OffX=v end})
    THUD2:AddSlider("RVHUD_Y",   {Text="Offset Y %", Default=70,Min=0,Max=100,Rounding=0, Callback=function(v) RV.TargetHUD.OffY=v end})

    local AU2 = VT:AddRightGroupbox("Aura")
    AU2:AddToggle("RVAura_On",   {Text="Aura Enabled", Default=false, Callback=function(v) RV.Aura.Enabled=v; if v then BuildAura(GetRVChar()) else ClearAura() end end})
    AU2:AddToggle("RVAura_RGB",  {Text="RGB Cycle",    Default=false, Callback=function(v) RV.Aura.RGB=v; if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddDropdown("RVAura_Mode",{Text="Preset",Default="Cyber Blue",Values={"Cyber Blue","Blood Red","Venom Green","Royal Purple","Sun God","Shadow"}, Callback=function(v) RV.Aura.Mode=v; if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddSlider("RVAura_Int",  {Text="Intensity",    Default=1,Min=0.3,Max=2,  Rounding=1, Callback=function(v) RV.Aura.Intensity=v; if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddSlider("RVAura_Size", {Text="Size",         Default=1,Min=0.6,Max=1.8,Rounding=2, Callback=function(v) RV.Aura.Size=v;      if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddToggle("RVAura_Light",{Text="Point Light",  Default=true,  Callback=function(v) RV.Aura.Light=v; if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddToggle("RVAura_Ring", {Text="Ring",         Default=true,  Callback=function(v) RV.Aura.Ring=v;  if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})
    AU2:AddToggle("RVAura_Trail",{Text="Limb Trails",  Default=true,  Callback=function(v) RV.Aura.Trail=v; if RV.Aura.Enabled then BuildAura(GetRVChar()) end end})

    local VM2 = VT:AddLeftGroupbox("Viewmodel Override")
    VM2:AddToggle("RVVM_On",     {Text="Override Enabled", Default=false, Callback=function(v) RV.Viewmodel.OverrideEnabled=v; if not v then VMDirty=true end end})
    VM2:AddDropdown("RVVM_Mat",  {Text="Weapon Material",  Default="Neon",Values={"Neon","SmoothPlastic","Glass","ForceField","Metal","DiamondPlate","Ice"}, Callback=function(v) RV.Viewmodel.VMMaterial=v end})
    VM2:AddSlider("RVVM_Trans",  {Text="Weapon Transp %",  Default=95,  Min=0,Max=100,Rounding=0, Callback=function(v) RV.Viewmodel.VMTrans=v end})
    VM2:AddToggle("RVVM_Wire",   {Text="Wireframe",        Default=false, Callback=function(v) RV.Viewmodel.VMWireframe=v end})
    VM2:AddToggle("RVVM_NoTex",  {Text="No Textures",      Default=false, Callback=function(v) RV.Viewmodel.VMNoTextures=v end})
    VM2:AddDropdown("RVVM_ArmMat",{Text="Arm Material",    Default="Neon",Values={"Neon","SmoothPlastic","Glass","ForceField","Metal"}, Callback=function(v) RV.Viewmodel.ArmMaterial=v end})
    VM2:AddSlider("RVVM_ArmTr",  {Text="Arm Transp %",     Default=32,  Min=0,Max=100,Rounding=0, Callback=function(v) RV.Viewmodel.ArmTrans=v end})
    VM2:AddToggle("RVVM_NoClth", {Text="Remove Clothes",   Default=false, Callback=function(v) RV.Viewmodel.ArmNoClothes=v end})

    local WR2 = VT:AddRightGroupbox("World (Advanced)")
    WR2:AddToggle("RVCC_On",    {Text="Color Correction",  Default=false, Callback=function(v) RV.CC.Enabled=v; pcall(RVApplyWorld) end})
    WR2:AddSlider("RVCC_Sat",   {Text="Saturation",   Default=0.1, Min=-1,Max=1,  Rounding=2, Callback=function(v) RV.CC.Saturation=v; pcall(RVApplyWorld) end})
    WR2:AddSlider("RVCC_Cont",  {Text="Contrast",     Default=0,   Min=-1,Max=1,  Rounding=2, Callback=function(v) RV.CC.Contrast=v;   pcall(RVApplyWorld) end})
    WR2:AddSlider("RVCC_Bri",   {Text="Brightness",   Default=0,   Min=-1,Max=1,  Rounding=2, Callback=function(v) RV.CC.Brightness=v; pcall(RVApplyWorld) end})
    WR2:AddToggle("RVSky_On",   {Text="Custom Sky",       Default=false, Callback=function(v) RV.Sky.Enabled=v; pcall(RVApplyWorld) end})
    WR2:AddDropdown("RVSky_Sel",{Text="Sky Preset",Default="Vertical Milky Way",Values={"Vertical Milky Way","Night Stars","Clean Day"}, Callback=function(v) RV.Sky.Selected=v; pcall(RVApplyWorld) end})
    WR2:AddToggle("RVSky_Bloom",{Text="Bloom",            Default=false, Callback=function(v) RV.Sky.Bloom=v; pcall(RVApplyWorld) end})
    WR2:AddSlider("RVSky_BInt", {Text="Bloom Intensity", Default=0.1,Min=0,Max=2,  Rounding=2, Callback=function(v) RV.Sky.BInt=v; pcall(RVApplyWorld) end})
    WR2:AddToggle("RVSky_Sun",  {Text="Sun Rays",         Default=false, Callback=function(v) RV.Sky.SunRays=v; pcall(RVApplyWorld) end})
    WR2:AddButton("Apply World Settings", function() pcall(RVApplyWorld); Notify("World applied",2) end)
    WR2:AddButton("Restore World",        function() pcall(RVRestoreWorld); Notify("World restored",2) end)

    local UK2 = VT:AddRightGroupbox("Unlock All (NOKS)")
    UK2:AddToggle("RVUL_On",    {Text="Unlock All Skins/Charms/Wraps", Default=false, Callback=function(v) unlockActive=v; if v then task.spawn(doUnlockAll) end end})
    UK2:AddLabel("Includes: Skins / Charms / Wraps / Dances")
    UK2:AddLabel("Excludes: Finishers (crash guard)")
    UK2:AddButton("Apply Unlock Now", function() if unlockActive then task.spawn(doUnlockAll) else Notify("Enable unlock toggle first",2) end end)
end)

pcall(function()
    local _oldUnload = Library.OnUnload
    if not _oldUnload then return end
    Library.OnUnload = function(self, cb)
        return _oldUnload(self, function()
            pcall(ClearAura)
            pcall(RVRestoreWorld)
            for _,p in ipairs(Players:GetPlayers()) do pcall(ClearRVESP,p) end
            pcall(function() for _,h in ipairs(TracerPool) do pcall(h.Destroy,h) end end)
            for _,c in pairs(dmgConns) do pcall(c.Disconnect,c) end
            pcall(visGui.Destroy,visGui)
            pcall(crossGui.Destroy,crossGui)
            if GE.UC_Unlock then GE.UC_Unlock.active=false end
            GE.UC4_Loaded=nil; pcall(function() _G.UC4_Loaded=nil end)
            GE.UC4_Running=nil; pcall(function() _G.UC4_Running=nil end)
            if cb then cb() end
        end)
    end
end)

Notify("Rivals Visuals V2 Ready",4)
print("[UNCODE v1] Rivals Visuals V2 integrated")

local _RV_SRC=[==[

local RV = {}

local Players   = game:GetService("Players")
local Lighting  = game:GetService("Lighting")
local RunService= game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local Debris    = game:GetService("Debris")
local CoreGui   = game:GetService("CoreGui")
local SndSrv    = game:GetService("SoundService")
local GuiSvc    = game:GetService("GuiService")
local RS        = game:GetService("ReplicatedStorage")
local HTTP      = game:GetService("HttpService")
local LP        = Players.LocalPlayer

RV.Config = {
    Aura = {
        Enabled=false, Mode="Cyber Blue", RGB=false,
        Intensity=1, Size=1, Light=true, Ring=true, Trail=true, Pulse=true,
    },
    Crosshair = {
        Enabled=false, Gap=8, Size=17, Thick=1,
        C1=Color3.new(1,1,1), C2=Color3.new(1,1,1), C3=Color3.new(1,1,1), C4=Color3.new(1,1,1),
        RGB=true, RotSpeed=150, Pulse=true, FollowMouse=true,
        Label=true, LabelText="uncode", Glow=true, GlowSize=2,
        DisableGame=false,
    },
    ESP = {
        Box=false, BoxFill=Color3.fromRGB(140,230,105),
        Outline=false, Thickness=2,
        Name=false, NameA=Color3.fromRGB(184,172,255),
        Weapon=false, Distance=false,
        Healthbar=false,
        HB_A=Color3.fromRGB(255,120,180), HB_B=Color3.fromRGB(255,255,255),
        HBType="gradient", Slices=1, HBSpeed=1.5, HealthLerp=0.05,
        Watermark=false, WatermarkText="uncode", WatermarkColor=Color3.fromRGB(245,235,130),
        IncludeTeam=false, Bounding="fixed", MaxDistance=1200,
        NameType="DisplayName", Dormant=true,
    },
    HitFX = {
        Enabled=false, Selected="fortnite damage",
        Material="ForceField", DisableMarker=false, DisableNumbers=false,
    },
    HitSound = {
        Selected="bell", Volume=5, Pitch=1,
    },
    Tracers = {
        Enabled=false, Outline=false,
        OC1=Color3.fromRGB(140,90,255), OC2=Color3.fromRGB(80,150,255),
        Selected="trail", Lifetime=0.3, Fade=0.4,
        PosLerp=0, Size=1, Length=4, Emission=1, Glow=5, Speed=5,
    },
    TargetHUD = {
        Enabled=false, OffX=17, OffY=70, ItemScale=150, UIScale=170,
    },
    Viewmodel = {
        OverrideFPS=false, FPS=60, Recoil=100,
        OverrideEnabled=false,
        VMColor=Color3.fromRGB(184,172,255), VMMaterial="Neon",
        VMWireframe=false, VMNoTextures=false, VMTrans=95,
        ArmColor=Color3.fromRGB(255,255,255), ArmMaterial="Neon",
        ArmNoClothes=false, ArmTrans=32,
    },
    Appearance = {
        Enabled=false, Color=Color3.fromRGB(255,0,0),
        Material="ForceField", NoDecal=false, Transparency=100,
        Aura=false,
    },
    World = {
        CC_Enabled=false, Saturation=0.1, Contrast=0, Brightness=0,
        Tint=Color3.fromRGB(255,255,255),
        Ambient=Color3.fromRGB(40,80,255),
        FogColor=Color3.fromRGB(80,40,255),
        UseFogEnd=false, FogEnd=995,
        UseFogStart=false, FogStart=0,
        UseExposure=true, Exposure=-0.2,
        UseBright=true, Bright=3.7,
        UseClock=true, Clock=11.6,
        Shadows=false,
        Sky=false, SkySelected="Vertical Milky Way", NoSunStars=false,
        Bloom=false, BInt=0.1, BSize=0, BThresh=0.88,
        SunRays=false,
    },
}
local C = RV.Config

local State = {
    Conns={}, ESPGui={}, DmgConns={},
    FX={}, SkyObj=nil, Backup=nil,
    TracerPool={}, TracerLast=0, TracerN=0,
    Destroyed=false, Hue=0,
    SliderActive=nil, SliderGlobal=false,
    LastESP=0, LastHUD=0,
    CrossTick=0, CrossMenuMode=false,
}

local function Bind(c) table.insert(State.Conns,c); return c end
local function New(cls,props,parent)
    local o=Instance.new(cls)
    for k,v in pairs(props or {}) do if k~="Parent" then pcall(function() o[k]=v end) end end
    o.Parent=parent; return o
end
local function GetChar(pl)
    pl=pl or LP
    local c=pl and pl.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then return c end
end

local SkyIDs = {
    ["Vertical Milky Way"]={Bk="rbxassetid://159454299",Ft="rbxassetid://159454299",Dn="rbxassetid://159454299",Lf="rbxassetid://159454299",Rt="rbxassetid://159454299",Up="rbxassetid://159454299"},
    ["Night Stars"]={Bk="rbxassetid://151165214",Ft="rbxassetid://151165214",Dn="rbxassetid://151165214",Lf="rbxassetid://151165214",Rt="rbxassetid://151165214",Up="rbxassetid://151165214"},
    ["Clean Day"]={Bk="rbxassetid://252818973",Ft="rbxassetid://252818973",Dn="rbxassetid://252818973",Lf="rbxassetid://252818973",Rt="rbxassetid://252818973",Up="rbxassetid://252818973"},
}

local function BackupL()
    if State.Backup then return end
    State.Backup={
        Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
        Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
        FogColor=Lighting.FogColor, FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart,
        ExposureCompensation=Lighting.ExposureCompensation,
        GlobalShadows=Lighting.GlobalShadows,
        ColorShift_Bottom=Lighting.ColorShift_Bottom,
        ColorShift_Top=Lighting.ColorShift_Top,
    }
end
local function GetFX(cls,name)
    local f=Lighting:FindFirstChild("RV_"..name)
    if f then return f end
    BackupL()
    local e=Instance.new(cls); e.Name="RV_"..name; e.Parent=Lighting; table.insert(State.FX,e); return e
end
local function ApplyWorld()
    BackupL()
    local W=C.World
    local cc=GetFX("ColorCorrectionEffect","CC")
    cc.Enabled=W.CC_Enabled; cc.Saturation=W.Saturation; cc.Contrast=W.Contrast
    cc.Brightness=W.Brightness; cc.TintColor=W.Tint
    pcall(function()
        Lighting.Ambient=W.Ambient; Lighting.FogColor=W.FogColor
    end)
    if W.UseFogEnd then Lighting.FogEnd=W.FogEnd else Lighting.FogEnd=100000 end
    if W.UseFogStart then Lighting.FogStart=W.FogStart else Lighting.FogStart=0 end
    if W.UseExposure then Lighting.ExposureCompensation=W.Exposure end
    if W.UseBright then Lighting.Brightness=W.Bright end
    if W.UseClock then Lighting.ClockTime=W.Clock end
    Lighting.GlobalShadows=W.Shadows
    if State.SkyObj then pcall(function() State.SkyObj:Destroy() end); State.SkyObj=nil end
    for _,v in pairs(Lighting:GetChildren()) do if v.Name=="RV_Sky" then v:Destroy() end end
    if W.Sky then
        local d=SkyIDs[W.SkySelected]
        if d then
            local s=Instance.new("Sky"); s.Name="RV_Sky"
            s.SkyboxBk=d.Bk; s.SkyboxFt=d.Ft; s.SkyboxDn=d.Dn
            s.SkyboxLf=d.Lf; s.SkyboxRt=d.Rt; s.SkyboxUp=d.Up
            s.CelestialBodiesShown=not W.NoSunStars
            s.Parent=Lighting; State.SkyObj=s
        end
    end
    local bl=GetFX("BloomEffect","Bloom")
    bl.Enabled=W.Bloom; bl.Intensity=W.BInt; bl.Size=math.max(W.BSize,1); bl.Threshold=W.BThresh
    local sr=GetFX("SunRaysEffect","Sun")
    sr.Enabled=W.SunRays; sr.Intensity=0.15; sr.Spread=0.7
end
local function RestoreWorld()
    if State.Backup then
        local B=State.Backup
        pcall(function()
            Lighting.Ambient=B.Ambient; Lighting.OutdoorAmbient=B.OutdoorAmbient
            Lighting.Brightness=B.Brightness; Lighting.ClockTime=B.ClockTime
            Lighting.FogColor=B.FogColor; Lighting.FogEnd=B.FogEnd; Lighting.FogStart=B.FogStart
            Lighting.ExposureCompensation=B.ExposureCompensation
            Lighting.GlobalShadows=B.GlobalShadows
            Lighting.ColorShift_Bottom=B.ColorShift_Bottom
            Lighting.ColorShift_Top=B.ColorShift_Top
        end)
    end
    for _,e in pairs(State.FX) do pcall(function() e:Destroy() end) end
    table.clear(State.FX)
    if State.SkyObj then pcall(function() State.SkyObj:Destroy() end); State.SkyObj=nil end
    for _,v in pairs(Lighting:GetChildren()) do if v.Name=="RV_Sky" then v:Destroy() end end
end
RV.ApplyWorld=ApplyWorld; RV.RestoreWorld=RestoreWorld

local AuraObjs={}; local AuraHRP=nil
local AuraPresets = {
    ["Cyber Blue"]  ={Color3.fromRGB(0,170,255),   Color3.fromRGB(0,255,255)},
    ["Blood Red"]   ={Color3.fromRGB(255,20,40),    Color3.fromRGB(255,120,0)},
    ["Venom Green"] ={Color3.fromRGB(0,255,120),    Color3.fromRGB(180,255,0)},
    ["Royal Purple"]={Color3.fromRGB(150,0,255),    Color3.fromRGB(255,0,200)},
    ["Sun God"]     ={Color3.fromRGB(255,200,0),    Color3.fromRGB(255,90,0)},
    ["Shadow"]      ={Color3.fromRGB(20,20,25),     Color3.fromRGB(120,0,255)},
}
local function ClearAura()
    for _,v in pairs(AuraObjs) do pcall(function() if typeof(v)=="Instance" and v.Parent then v:Destroy() end end) end
    table.clear(AuraObjs); AuraHRP=nil
end
local function BuildAura(char)
    ClearAura()
    if not C.Aura.Enabled then return end
    local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local pr=AuraPresets[C.Aura.Mode] or AuraPresets["Cyber Blue"]
    local main,second=pr[1],pr[2]
    if C.Aura.RGB then
        State.Hue=(State.Hue+0.02)%1
        main=Color3.fromHSV(State.Hue,0.9,1)
        second=Color3.fromHSV((State.Hue+0.12)%1,0.9,1)
    end
    local inten=math.clamp(C.Aura.Intensity,0.3,2)
    local sz=math.clamp(C.Aura.Size,0.6,1.8)
    local folder=New("Folder",{Name="RV_Aura"},char); table.insert(AuraObjs,folder)
    if C.Aura.Light then
        local pl=New("PointLight",{Name="RV_L",Color=main,Brightness=2*inten,Range=16*sz,Shadows=false},hrp)
        table.insert(AuraObjs,pl); AuraObjs.L=pl
    end
    local a0=New("Attachment",{Name="RV_A0",Position=Vector3.new(0,-1.2,0)},hrp)
    local a1=New("Attachment",{Name="RV_A1",Position=Vector3.new(0,2.5,0)},hrp)
    table.insert(AuraObjs,a0); table.insert(AuraObjs,a1)
    local p1=New("ParticleEmitter",{
        Texture="rbxassetid://243098098",
        Color=ColorSequence.new({ColorSequenceKeypoint.new(0,second),ColorSequenceKeypoint.new(1,main)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,1)}),
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6*sz),NumberSequenceKeypoint.new(1,0.05)}),
        Speed=NumberRange.new(3*inten,6*inten), Lifetime=NumberRange.new(0.6,1.2),
        Rate=math.floor(26*inten), EmissionDirection=Enum.NormalId.Top,
        SpreadAngle=Vector2.new(35,35), Acceleration=Vector3.new(0,6,0),
    },a0); table.insert(AuraObjs,p1); AuraObjs.P1=p1
    if C.Aura.Ring then
        local ring=New("Part",{Name="RV_Ring",Shape=Enum.PartType.Cylinder,
            Size=Vector3.new(0.2,6.5*sz,6.5*sz),Transparency=0.55,CanCollide=false,
            CanQuery=false,CanTouch=false,Anchored=true,Massless=true,
            Material=Enum.Material.Neon,Color=main},folder)
        pcall(function() ring.CFrame=hrp.CFrame*CFrame.new(0,-3.05,0)*CFrame.Angles(0,0,math.rad(90)) end)
        table.insert(AuraObjs,ring); AuraObjs.Ring=ring; AuraHRP=hrp
    end
    if C.Aura.Trail then
        for _,ln in ipairs({"Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local limb=char:FindFirstChild(ln)
            if limb and limb:IsA("BasePart") then
                local t0=New("Attachment",{Position=Vector3.new(0,0.8,0)},limb)
                local t1=New("Attachment",{Position=Vector3.new(0,-0.8,0)},limb)
                local tr=New("Trail",{
                    Color=ColorSequence.new({ColorSequenceKeypoint.new(0,second),ColorSequenceKeypoint.new(1,main)}),
                    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}),
                    Lifetime=0.45,WidthScale=NumberSequence.new(0.35),
                    LightEmission=1,LightInfluence=0,Attachment0=t0,Attachment1=t1,
                },limb)
                table.insert(AuraObjs,t0); table.insert(AuraObjs,t1); table.insert(AuraObjs,tr)
            end
        end
    end
end
RV.BuildAura=BuildAura; RV.ClearAura=ClearAura

local function ApplyAppearance()
    local ch=GetChar(); if not ch or not C.Appearance.Enabled then return end
    for _,p in pairs(ch:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            pcall(function()
                p.Color=C.Appearance.Color
                p.Material=Enum.Material[C.Appearance.Material] or Enum.Material.ForceField
                p.Transparency=math.clamp(1-C.Appearance.Transparency/100,0,1)*0.7
            end)
        end
        if C.Appearance.NoDecal then
            if p:IsA("Decal") or p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") then
                pcall(function() p:Destroy() end)
            end
        end
    end
end
RV.ApplyAppearance=ApplyAppearance

local ARM_NAMES={LeftArm=true,RightArm=true,LeftHand=true,RightHand=true,Hand=true}
local function IsArmPart(p)
    if not p or not p:IsA("BasePart") then return false end
    return ARM_NAMES[p.Name]
end
local function FindViewmodelParts()
    local cam=workspace.CurrentCamera; if not cam then return {},{} end
    local weapons,arms={},{}
    for _,model in pairs(cam:GetChildren()) do
        if model:IsA("Model") or model:IsA("Folder") then
            for _,d in pairs(model:GetDescendants()) do
                if d:IsA("BasePart") then
                    if IsArmPart(d) then table.insert(arms,d) else table.insert(weapons,d) end
                end
            end
        end
    end
    return weapons,arms
end
local function ApplyViewmodelOverride()
    if not C.Viewmodel.OverrideEnabled then

        local cam=workspace.CurrentCamera; if not cam then return end
        for _,d in pairs(cam:GetDescendants()) do
            if d:IsA("BasePart") and d:GetAttribute("RV_OInit") then
                pcall(function()
                    local col=d:GetAttribute("RV_OColor"); if typeof(col)=="Color3" then d.Color=col end
                    local mat=d:GetAttribute("RV_OMat"); if typeof(mat)=="string" and Enum.Material[mat] then d.Material=Enum.Material[mat] end
                    local trans=d:GetAttribute("RV_OTrans"); if typeof(trans)=="number" then d.Transparency=trans end
                    for _,ch in pairs(d:GetChildren()) do if ch.Name=="RV_Wire" then ch:Destroy() end end
                end)
            end
        end
        return
    end
    local weapons,arms=FindViewmodelParts()
    local function dopart(p,col,mat,trans,wire,noTex,isArm,noCloth)
        if not p:GetAttribute("RV_OInit") then
            p:SetAttribute("RV_OInit",true)
            pcall(function() p:SetAttribute("RV_OColor",p.Color) end)
            p:SetAttribute("RV_OMat",tostring(p.Material))
            p:SetAttribute("RV_OTrans",p.Transparency)
        end
        pcall(function()
            p.Color=col
            if Enum.Material[mat] then p.Material=Enum.Material[mat] end
            if wire then
                p.Transparency=1
                local w=p:FindFirstChild("RV_Wire") or Instance.new("WireframeHandleAdornment")
                w.Name="RV_Wire"; w.Adornee=p; w.Color3=col; w.Transparency=0
                w.AlwaysOnTop=true; w.Parent=p
            else
                p.Transparency=math.clamp(trans/100,0,1)
                local w=p:FindFirstChild("RV_Wire"); if w then w:Destroy() end
            end
        end)
    end
    local VM=C.Viewmodel
    for _,p in pairs(weapons) do dopart(p,VM.VMColor,VM.VMMaterial,VM.VMTrans,VM.VMWireframe,VM.VMNoTextures,false,false) end
    for _,p in pairs(arms)    do dopart(p,VM.ArmColor,VM.ArmMaterial,VM.ArmTrans,false,false,true,VM.ArmNoClothes) end
end
RV.ApplyViewmodelOverride=ApplyViewmodelOverride

local HitSounds={bell="rbxassetid://6518811702",pop="rbxassetid://9106153995",tick="rbxassetid://9106202384",fortnite="rbxassetid://9106232005"}
local function PlayHitSound()
    local id=HitSounds[C.HitSound.Selected] or HitSounds.bell
    local s=New("Sound",{SoundId=id,Volume=math.clamp(C.HitSound.Volume,0,10),PlaybackSpeed=C.HitSound.Pitch,Parent=SndSrv})
    pcall(function() s:Play() end); Debris:AddItem(s,2)
end

local visGui=New("ScreenGui",{Name="RV_Vis",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},gethui and gethui() or CoreGui)
local function FortniteDamage(pos,amount)
    if C.HitFX.DisableNumbers then return end
    local part=New("Part",{Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,Size=Vector3.new(0.5,0.5,0.5),CFrame=CFrame.new(pos)},workspace)
    local bb=New("BillboardGui",{Size=UDim2.new(0,80,0,30),StudsOffset=Vector3.new(math.random(-2,2),3,0),AlwaysOnTop=true,Adornee=part},visGui)
    Debris:AddItem(part,0.9); Debris:AddItem(bb,0.9)
    local tl=New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.fromRGB(255,220,80),TextStrokeTransparency=0.2,Text=tostring(amount)},bb)
    task.spawn(function()
        for i=1,20 do task.wait(0.03)
            pcall(function() part.CFrame=part.CFrame+Vector3.new(0,0.15,0); tl.TextTransparency=i/20; tl.TextStrokeTransparency=i/20 end)
        end
    end)
end
local function SpawnHitClone(char)
    if not C.HitFX.Enabled then return end
    pcall(function()
        local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local clone=New("Part",{Size=Vector3.new(2,3,1),CFrame=hrp.CFrame,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=0.3,
            Material=Enum.Material[C.HitFX.Material] or Enum.Material.ForceField,Color=Color3.fromRGB(184,172,255)},workspace)
        Debris:AddItem(clone,0.6)
        task.spawn(function() for i=1,10 do task.wait(0.05); pcall(function() clone.Transparency=0.3+i*0.07 end) end end)
    end)
end
local hooked={}
local function HookCharDamage(p,ch)
    task.spawn(function()
        task.wait(0.3); if State.Destroyed then return end
        local h=ch and ch:FindFirstChildOfClass("Humanoid"); if not h then return end
        local old=State.DmgConns[p]; if old then pcall(old.Disconnect,old); State.DmgConns[p]=nil end
        local last=h.Health
        local conn=h.HealthChanged:Connect(function(nh)
            if State.Destroyed or not ch.Parent then return end
            if nh<last then
                local dmg=math.floor(last-nh); last=nh
                if C.HitFX.Enabled then
                    local hrp=ch:FindFirstChild("HumanoidRootPart")
                    if hrp then FortniteDamage(hrp.Position,dmg) end
                    SpawnHitClone(ch); PlayHitSound()
                end
            else last=nh end
        end)
        State.DmgConns[p]=conn; table.insert(State.Conns,conn)
    end)
end
local function HookPlayer(p)
    if hooked[p] then return end; hooked[p]=true
    if p.Character then HookCharDamage(p,p.Character) end
    Bind(p.CharacterAdded:Connect(function(ch) HookCharDamage(p,ch) end))
end
for _,p in pairs(Players:GetPlayers()) do HookPlayer(p) end
Bind(Players.PlayerAdded:Connect(HookPlayer))

local function SpawnTracer(fromPos,toPos)
    if not C.Tracers.Enabled then return end
    State.TracerN = State.TracerN + 1
    local life=math.clamp(C.Tracers.Lifetime,0.05,2)
    local fade=math.clamp(C.Tracers.Fade,0.05,2)
    local speedMul=5/math.max(C.Tracers.Speed,0.5); fade=math.clamp(fade*speedMul,0.05,3)
    local lerpK=math.clamp(C.Tracers.PosLerp,0,1)*0.15
    toPos=fromPos:Lerp(toPos,1-lerpK)
    local styleW,styleE=1,0
    local st=C.Tracers.Selected
    if st=="beam" then styleW=1.5 elseif st=="trail" then styleW=0.7
    elseif st=="glow" then styleE=3 elseif st=="energy" then styleW=1.1; styleE=1.5 end
    local wBase=0.25*C.Tracers.Size*(0.6+C.Tracers.Length/4)*styleW
    if #State.TracerPool>=30 then
        local old=table.remove(State.TracerPool,1)
        pcall(function() if old and old.Parent then old:Destroy() end end)
    end
    local holder=New("Part",{Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,Size=Vector3.new(0.5,0.5,0.5),CFrame=CFrame.new(fromPos),Name="RV_Trace"},workspace)
    table.insert(State.TracerPool,holder)
    local a0=New("Attachment",{Position=Vector3.new(0,0,0)},holder)
    local a1=New("Attachment",{Position=Vector3.new(0,0,0)},holder)
    pcall(function() a1.WorldPosition=toPos end)
    local c1=C.Tracers.OC1 or Color3.fromRGB(140,90,255)
    local c2=C.Tracers.OC2 or Color3.fromRGB(80,150,255)
    local beam=New("Beam",{
        Attachment0=a0,Attachment1=a1,
        Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0)}),
        Width0=wBase,Width1=wBase,
        LightEmission=math.clamp(C.Tracers.Glow+C.Tracers.Emission+styleE,0,10),
        LightInfluence=0,FaceCamera=true,
    },holder)
    if C.Tracers.Outline then beam.Width0 = beam.Width0 + 0.15; beam.Width1 = beam.Width1 + 0.15 end
    task.spawn(function()
        local t=0
        while t<fade and beam.Parent do t = t + task.wait()
            pcall(function() beam.Transparency=NumberSequence.new(t/fade) end)
        end
        pcall(function() holder:Destroy() end)
    end)
    Debris:AddItem(holder,life+fade+0.5)
end
RV.SpawnTracer=SpawnTracer

local TraceParams=RaycastParams.new(); TraceParams.FilterType=Enum.RaycastFilterType.Exclude; TraceParams.IgnoreWater=true
Bind(RunService.Heartbeat:Connect(function(dt)
    if State.Destroyed or not C.Tracers.Enabled then return end
    do local _t=os.clock() if _t-(_espRT or 0)<0.033 then return end; _espRT=_t end
    local now=os.clock(); if now-State.TracerLast<0.06 or dt>0.05 then return end
    local pressed=false; pcall(function() pressed=UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
    if not pressed then return end
    local cam=workspace.CurrentCamera; local char=GetChar()
    if not cam or not char then return end
    State.TracerLast=now
    TraceParams.FilterDescendantsInstances={char,cam}
    local origin=cam.CFrame.Position
    local hitPos=origin+cam.CFrame.LookVector*1000
    pcall(function()
        local res=workspace:Raycast(origin,cam.CFrame.LookVector*1000,TraceParams)
        if res and res.Position then hitPos=res.Position end
    end)
    SpawnTracer((cam.CFrame*CFrame.new(0.45,-0.35,-1.5)).Position,hitPos)
end))

local crossGui=New("ScreenGui",{Name="RV_Cross",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},gethui and gethui() or CoreGui)
local crossRoot=New("Frame",{Name="Cross",Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,Visible=false},crossGui)
local crossSpin=New("Frame",{Name="Spin",Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},crossRoot)
local crossTextBox=New("Frame",{Name="TB",Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},crossRoot)
local crossLines={} local crossOutlines={}
for i=1,4 do
    crossOutlines[i]=New("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,AnchorPoint=Vector2.new(0.5,0.5),ZIndex=2},crossSpin)
    crossLines[i]=New("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.white,AnchorPoint=Vector2.new(0.5,0.5),ZIndex=3},crossSpin)
end
local crossLabel=New("TextLabel",{Size=UDim2.new(0,300,0,20),Position=UDim2.new(0,-150,0,22),BackgroundTransparency=1,Font=Enum.Font.Arial,TextSize=14,TextColor3=Color3.white,TextStrokeTransparency=0,TextStrokeColor3=Color3.new(0,0,0),Text="uncode",Visible=false,ZIndex=4},crossTextBox)

Bind(RunService.RenderStepped:Connect(function(dt)
    if State.Destroyed then return end
    crossRoot.Visible=C.Crosshair.Enabled
    crossLabel.Visible=C.Crosshair.Enabled and C.Crosshair.Label
    if not crossRoot.Visible then return end
    dt=math.clamp(dt or 0.016,0,0.1)
    State.CrossTick=(State.CrossTick or 0)+dt
    local tick=State.CrossTick
    local pos
    if C.Crosshair.FollowMouse then
        local ml=UIS:GetMouseLocation()
        local insetY=0; pcall(function() insetY=GuiSvc:GetGuiInset().Y end)
        pos=UDim2.new(0,ml.X,0,ml.Y-insetY)
    else
        pos=UDim2.new(0.5,0,0.5,0)
    end
    crossSpin.Position=pos; crossTextBox.Position=pos
    local pf=C.Crosshair.Pulse and math.sin(tick*3.5) or 0
    local pct=(pf+1)/2
    local rotSpd=(C.Crosshair.RotSpeed or 0)*(0.35+pct*1.4)
    crossSpin.Rotation=(crossSpin.Rotation+rotSpd*dt)%360
    local syncCol=Color3.fromHSV((tick*0.05)%1,1,1)
    local cols=C.Crosshair.RGB and {syncCol,syncCol,syncCol,syncCol} or {C.Crosshair.C1,C.Crosshair.C2,C.Crosshair.C3,C.Crosshair.C4}
    crossLabel.TextColor3=cols[1]; crossLabel.Text=C.Crosshair.LabelText
    local len=math.max(1,C.Crosshair.Size+(C.Crosshair.Pulse and pf*5 or 0))
    local gap=C.Crosshair.Gap; local th=math.max(1,C.Crosshair.Thick)
    local geo={
        {ls=UDim2.new(0,th,0,len),lp=UDim2.new(0,0,0,-gap-len/2)},
        {ls=UDim2.new(0,th,0,len),lp=UDim2.new(0,0,0,gap+len/2)},
        {ls=UDim2.new(0,len,0,th),lp=UDim2.new(0,-gap-len/2,0,0)},
        {ls=UDim2.new(0,len,0,th),lp=UDim2.new(0,gap+len/2,0,0)},
    }
    for i=1,4 do
        local L,O,G=crossLines[i],crossOutlines[i],geo[i]
        L.Size=G.ls; L.Position=G.lp; L.BackgroundColor3=cols[i]
        O.Size=i<=2 and UDim2.new(0,th+2,0,len+2) or UDim2.new(0,len+2,0,th+2)
        O.Position=G.lp
    end
end))

local function ClearESP(p)
    local f=State.ESPGui[p]; if f then pcall(f.Destroy,f); State.ESPGui[p]=nil end
    local hl=State.ESPGui[p.Name.."_hl"]; if hl then pcall(hl.Destroy,hl); State.ESPGui[p.Name.."_hl"]=nil end
    State.ESPGui[p.Name.."_refs"]=nil; State.ESPGui[p.Name.."_char"]=nil
end
local function MakeESP(p)
    ClearESP(p)
    local char=p.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local root=New("BillboardGui",{Name="RV_ESP_"..p.Name,Adornee=hrp,Size=UDim2.new(0,120,0,96),StudsOffset=Vector3.new(0,2.5,0),AlwaysOnTop=true},visGui)
    State.ESPGui[p]=root

    local box=New("Frame",{Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0,26),BackgroundTransparency=1,BorderSizePixel=0,Visible=C.ESP.Box},root)
    local corners={}
    local L0=14; local T0=math.max(1,math.floor(C.ESP.Thickness))
    for _,d in pairs({{0,0,L0,T0},{0,0,T0,L0},{60-L0,0,L0,T0},{60-T0,0,T0,L0},{0,60-T0,L0,T0},{0,60-T0,T0,L0},{60-L0,60-T0,L0,T0},{60-T0,60-T0,T0,L0}}) do
        table.insert(corners,New("Frame",{Size=UDim2.new(0,d[3],0,d[4]),Position=UDim2.new(0,d[1],0,d[2]),BackgroundColor3=C.ESP.BoxFill,BorderSizePixel=0},box))
    end

    local dname=C.ESP.NameType=="DisplayName" and p.DisplayName or C.ESP.NameType=="Both" and p.Name.."["..p.DisplayName.."]" or p.Name
    local nl=New("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=12,TextColor3=C.ESP.NameA,TextStrokeTransparency=0.3,Text=dname,Visible=C.ESP.Name},root)

    local tool=char:FindFirstChildOfClass("Tool")
    local wl=New("TextLabel",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,0,14),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(220,220,220),TextStrokeTransparency=0.4,Text=tool and tool.Name or "",Visible=C.ESP.Weapon},root)

    local dl=New("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-26),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(150,150,150),Text="",Visible=C.ESP.Distance},root)

    local wm=New("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-13),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.ESP.WatermarkColor,TextStrokeTransparency=0.3,Text=C.ESP.WatermarkText,Visible=C.ESP.Watermark},root)

    local hbBG=New("Frame",{Size=UDim2.new(0,4,0,56),Position=UDim2.new(0.5,-37,0,28),BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0,Visible=C.ESP.Healthbar},root)
    local hbFill=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.ESP.HB_A,BorderSizePixel=0},hbBG)

    local hl=nil
    if C.ESP.Outline then
        hl=New("Highlight",{FillColor=C.ESP.BoxFill,OutlineColor=Color3.fromRGB(255,255,255),FillTransparency=0.7,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.Occluded,Adornee=char},visGui)
    end
    State.ESPGui[p.Name.."_hl"]=hl
    State.ESPGui[p.Name.."_refs"]={box=box,corners=corners,name=nl,weap=wl,dist=dl,wmark=wm,hbBG=hbBG,hbFill=hbFill,hl=hl}
    State.ESPGui[p.Name.."_char"]=char
end
local function RefreshESP()
    if State.Destroyed then return end
    local now=os.clock(); if now-State.LastESP<0.1 then return end; State.LastESP=now
    local anyOn=C.ESP.Box or C.ESP.Name or C.ESP.Weapon or C.ESP.Distance or C.ESP.Healthbar or C.ESP.Outline or C.ESP.Watermark
    if not anyOn then
        for _,p in pairs(Players:GetPlayers()) do if State.ESPGui[p] then ClearESP(p) end end
        return
    end
    local myC=GetChar(); local myHrp=myC and myC:FindFirstChild("HumanoidRootPart"); if not myHrp then return end
    for _,p in pairs(Players:GetPlayers()) do
        if p==LP then continue end
        local ch=p.Character; local hrp=ch and ch:FindFirstChild("HumanoidRootPart"); local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then ClearESP(p); continue end
        if hum.Health<=0 then ClearESP(p); continue end
        local dist=(myHrp.Position-hrp.Position).Magnitude
        if dist>C.ESP.MaxDistance then ClearESP(p); continue end
        if State.ESPGui[p.Name.."_char"]~=ch then MakeESP(p) end
        local refs=State.ESPGui[p.Name.."_refs"]; if not refs then MakeESP(p); refs=State.ESPGui[p.Name.."_refs"] end
        if not refs then continue end

        refs.box.Visible=C.ESP.Box
        if refs.dist then refs.dist.Text=math.floor(dist).."m"; refs.dist.Visible=C.ESP.Distance end
        if refs.weap then
            local t=ch:FindFirstChildOfClass("Tool"); refs.weap.Text=t and t.Name or ""; refs.weap.Visible=C.ESP.Weapon
        end
        if refs.hbBG and C.ESP.Healthbar then
            refs.hbBG.Visible=true
            local ratio=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
            refs.hbFill.Size=UDim2.new(1,0,ratio,0)
            refs.hbFill.Position=UDim2.new(0,0,1-ratio,0)
            refs.hbFill.BackgroundColor3=Color3.fromRGB(math.floor((1-ratio)*220),math.floor(ratio*190),60)
        elseif refs.hbBG then refs.hbBG.Visible=false end
        if refs.hl then refs.hl.Enabled=C.ESP.Outline end
    end
    for _,p in pairs(Players:GetPlayers()) do if not p.Parent then ClearESP(p) end end
end
Bind(Players.PlayerRemoving:Connect(ClearESP))

local hud=New("Frame",{Name="THUD",Size=UDim2.new(0,220,0,64),BackgroundColor3=Color3.fromRGB(7,7,7),BorderSizePixel=0,Visible=false},visGui)
New("UIStroke",{Color=Color3.fromRGB(184,172,255),Thickness=1,Transparency=0.4},hud)
local hudName=New("TextLabel",{Size=UDim2.new(1,-10,0,18),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=12,TextColor3=Color3.fromRGB(225,225,225),TextXAlignment=Enum.TextXAlignment.Left,Text="target: -"},hud)
local hudInfo=New("TextLabel",{Size=UDim2.new(1,-10,0,16),Position=UDim2.new(0,5,0,22),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=11,TextColor3=Color3.fromRGB(150,150,150),TextXAlignment=Enum.TextXAlignment.Left,Text="hp: -  dist: -"},hud)
local hudBar=New("Frame",{Size=UDim2.new(1,-10,0,8),Position=UDim2.new(0,5,0,42),BackgroundColor3=Color3.fromRGB(35,35,40),BorderSizePixel=0},hud)
local hudFill=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(184,172,255),BorderSizePixel=0},hudBar)
New("UICorner",{CornerRadius=UDim.new(0,3)},hudBar); New("UICorner",{CornerRadius=UDim.new(0,3)},hudFill)

Bind(RunService.Heartbeat:Connect(function(dt)
    if State.Destroyed then return end
    do local _t=os.clock() if _t-(_espR2T or 0)<0.033 then return end; _espR2T=_t end
    RefreshESP()

    if C.Viewmodel.OverrideFPS then
        local cam=workspace.CurrentCamera; if cam then
            pcall(function() cam.MaxAxisFieldOfView=cam.MaxAxisFieldOfView end) 
        end
    end

    if C.TargetHUD.Enabled then
        local myC=GetChar(); local myHrp=myC and myC:FindFirstChild("HumanoidRootPart")
        if myHrp then
            hud.Visible=true
            hud.Position=UDim2.new(C.TargetHUD.OffX/100,0,C.TargetHUD.OffY/100,0)
            hud.Size=UDim2.new(0,220*C.TargetHUD.UIScale/100,0,64*C.TargetHUD.UIScale/100)
            local best,bd=nil,math.huge
            for _,p in pairs(Players:GetPlayers()) do
                if p==LP or not p.Character then continue end
                local rp=p.Character:FindFirstChild("HumanoidRootPart"); if not rp then continue end
                local d=(myHrp.Position-rp.Position).Magnitude
                if d<bd then bd=d; best=p end
            end
            if best then
                local h=best.Character:FindFirstChildOfClass("Humanoid")
                local hp=h and math.floor(h.Health) or 0; local mx=h and h.MaxHealth or 100
                hudName.Text="target: "..(C.ESP.NameType=="DisplayName" and best.DisplayName or best.Name)
                hudInfo.Text="hp: "..hp.."  dist: "..math.floor(bd).."m"
                hudFill.Size=UDim2.new(math.clamp(hp/mx,0,1),0,1,0)
            else
                hudName.Text="target: -"; hudInfo.Text="hp: -  dist: -"; hudFill.Size=UDim2.new(0,0,1,0)
            end
        else hud.Visible=false end
    else hud.Visible=false end

    if C.Aura.Enabled and AuraObjs.Ring and AuraObjs.Ring.Parent and AuraHRP and AuraHRP.Parent then
        pcall(function()
            AuraObjs.Ring.CFrame=AuraHRP.CFrame*CFrame.new(0,-3.05,0)*CFrame.Angles(0,0,math.rad(90))
            if C.Aura.Pulse then
                local s=6.5*C.Aura.Size*(0.9+0.15*math.sin(os.clock()*4))
                AuraObjs.Ring.Size=Vector3.new(0.2,s,s)
            end
        end)
    end
    if C.Aura.RGB and AuraObjs.L and AuraObjs.L.Parent then
        State.Hue=(State.Hue+0.005)%1
        local cc=Color3.fromHSV(State.Hue,0.9,1)
        pcall(function() AuraObjs.L.Color=cc end)
        if AuraObjs.Ring and AuraObjs.Ring.Parent then pcall(function() AuraObjs.Ring.Color=cc end) end
        if AuraObjs.P1 and AuraObjs.P1.Parent then pcall(function() AuraObjs.P1.Color=ColorSequence.new(cc) end) end
    end
end))

Bind(LP.CharacterAdded:Connect(function(c)
    task.wait(0.6)
    BuildAura(GetChar())
    ApplyAppearance()
end))
task.spawn(function() local c=GetChar(); if c then BuildAura(c) end end)

RV.Unlock = {active=false, equipped={}, favorites={}, trueNamecall=nil}
local U=RV.Unlock

local function setupUnlock()
    pcall(function()
        local modules=RS:WaitForChild("Modules",8)
        local playerScripts=LP:WaitForChild("PlayerScripts",10)
        local controllers=playerScripts:WaitForChild("Controllers",10)
        local CosLib=require(modules:WaitForChild("CosmeticLibrary",6))
        local ItemLib=require(modules:WaitForChild("ItemLibrary",6))
        local DataCtrl=require(controllers:WaitForChild("PlayerDataController",6))

        local EnumLib; pcall(function()
            local m=modules:FindFirstChild("EnumLibrary")
            if m then EnumLib=require(m); if EnumLib.WaitForEnumBuilder then EnumLib:WaitForEnumBuilder() end end
        end)

        local function unlockedType(c,name)
            if c then local t=c.Type; if t=="Skin" or t=="Charm" or t=="Wrap" or t=="Wrapping" or t=="Dance" or t=="Emote" then return true end end
            if type(name)=="string" then
                local ln=string.lower(name)
                if ln:find("charm",1,true) or ln:find("wrap",1,true) or ln:find("dance",1,true) or ln:find("emote",1,true) then return true end
            end
            return false
        end

        local function cloneCosmetic(name,cosType,options)
            local base=CosLib.Cosmetics and CosLib.Cosmetics[name]; if not base then return nil end
            local data={}; for k,v in pairs(base) do data[k]=v end
            data.Name=name; if not data.Type then data.Type=cosType end
            if not data.Seed then data.Seed=math.random(1,1000000) end
            if EnumLib then pcall(function()
                local ok,enumId=pcall(EnumLib.ToEnum,EnumLib,name)
                if ok and enumId then data.Enum=enumId; if not data.ObjectID then data.ObjectID=enumId end end
            end) end
            if type(options)=="table" then
                if options.inverted~=nil then data.Inverted=options.inverted end
                if options.favoritesOnly~=nil then data.OnlyUseFavorites=options.favoritesOnly end
            end
            return data
        end

        local curOwns=CosLib.OwnsCosmetic
        CosLib.OwnsCosmetic=function(self,inventory,name,weapon)
            if U.active and type(name)=="string" and not string.find(name,"MISSING_") then
                local c=CosLib.Cosmetics and CosLib.Cosmetics[name]
                if c and unlockedType(c,name) then return true end
            end
            return curOwns(self,inventory,name,weapon)
        end

        local curGet=DataCtrl.Get
        DataCtrl.Get=function(self,key)
            local data=curGet(self,key)
            if not U.active then return data end
            if key=="CosmeticInventory" then
                local proxy={}
                if type(data)=="table" then for k,v in pairs(data) do proxy[k]=v end end
                return setmetatable(proxy,{__index=function(t,k)
                    if type(k)=="string" then
                        local c=CosLib.Cosmetics and CosLib.Cosmetics[k]
                        if c and unlockedType(c,k) then return true end
                    end
                    return nil
                end})
            end
            if key=="FavoritedCosmetics" then
                local result={}
                if type(data)=="table" then for k,v in pairs(data) do result[k]=v end end
                for w,favs in pairs(U.favorites) do
                    if type(favs)=="table" then result[w]=result[w] or {}; for n,f in pairs(favs) do result[w][n]=f end end
                end
                return result
            end
            return data
        end

        local curGWD=DataCtrl.GetWeaponData
        if curGWD then
            DataCtrl.GetWeaponData=function(self,weaponName)
                local data=curGWD(self,weaponName); if not data or not U.active then return data end
                local eq=U.equipped[weaponName]; if type(eq)~="table" then return data end
                local merged={}; for k,v in pairs(data) do merged[k]=v end
                merged.Name=weaponName
                for ctype,cdata in pairs(eq) do merged[ctype]=cdata end
                return merged
            end
        end

        pcall(function()
            if not hookmetamethod or not getnamecallmethod then return end
            local rems=RS:FindFirstChild("Remotes")
            local dataRems=rems and rems:FindFirstChild("Data")
            local equipRemote=dataRems and dataRems:FindFirstChild("EquipCosmetic")
            local favRemote=dataRems and dataRems:FindFirstChild("FavoriteCosmetic")
            if not equipRemote then return end

            local function storeEquip(wn,ct,cn,options)
                if type(options)~="table" then options={} end
                if not cn or cn=="None" or cn=="" then
                    if U.equipped[wn] then U.equipped[wn][ct]=nil; if not next(U.equipped[wn]) then U.equipped[wn]=nil end end
                    return
                end
                local cloned=cloneCosmetic(cn,ct,{inverted=options.IsInverted,favoritesOnly=options.OnlyUseFavorites})
                if cloned then U.equipped[wn]=U.equipped[wn] or {}; U.equipped[wn][ct]=cloned end
            end

            -- クラッシュ対策: getnamecallmethodをpcallで保護、U.trueNamecallのnilガード追加
            local _fwdBusy = false  -- 再帰防止フラグ
            local function forwarder(self,...)
                if _fwdBusy then return U.trueNamecall and U.trueNamecall(self,...) end
                _fwdBusy = true
                local ok3, meth = pcall(function() return getnamecallmethod and getnamecallmethod() or "" end)
                local m = (ok3 and meth) or ""
                if m~="FireServer" then _fwdBusy=false; return U.trueNamecall and U.trueNamecall(self,...) end
                if not U.active then _fwdBusy=false; return U.trueNamecall and U.trueNamecall(self,...) end
                local args={...}
                if self==equipRemote then
                    local wn,ct,cn,opts=args[1],args[2],args[3],args[4]
                    pcall(storeEquip,wn,ct,cn,opts)
                    task.defer(function()
                        pcall(function() DataCtrl.CurrentData:Replicate("WeaponInventory") end)
                    end)
                    _fwdBusy=false; return
                end
                if favRemote and self==favRemote then
                    local w,cn,fav=args[1],args[2],args[3]
                    U.favorites[w]=U.favorites[w] or {}; U.favorites[w][cn]=fav or nil
                    task.spawn(function() pcall(function() DataCtrl.CurrentData:Replicate("FavoritedCosmetics") end) end)
                    _fwdBusy=false; return
                end
                _fwdBusy=false; return U.trueNamecall and U.trueNamecall(self,...)
            end
            -- Deltaクラッシュ対策: newcclosureでラップしてからhookmetamethod
            if not U.trueNamecall then
                local safeHook = (newcclosure and newcclosure(forwarder)) or forwarder
                local hkOk, hkRes = pcall(hookmetamethod, game, "__namecall", safeHook)
                if hkOk then U.trueNamecall = hkRes end
            end
        end)

        pcall(function()
            local ClientItem=require(playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
            if not ClientItem or not ClientItem._CreateViewModel then return end
            local cur=ClientItem._CreateViewModel
            ClientItem._CreateViewModel=function(self,viewmodelRef)
                pcall(function()
                    if U.active and self.ClientFighter and self.ClientFighter.Player==LP then
                        local wname=self.Name; local eq=U.equipped[wname]
                        if type(eq)=="table" and viewmodelRef then
                            for _,ctype in pairs({"Skin","Charm","Wrap"}) do
                                local cd=eq[ctype]
                                if cd then
                                    if viewmodelRef.Data then viewmodelRef.Data[ctype]=cd; viewmodelRef.Data.Name=cd.Name
                                    else pcall(function()
                                        local dataKey=self:ToEnum("Data")
                                        if dataKey and viewmodelRef[dataKey] then viewmodelRef[dataKey][self:ToEnum(ctype)]=cd end
                                    end) end
                                end
                            end
                        end
                    end
                end)
                return cur(self,viewmodelRef)
            end
        end)
    end)
end
task.spawn(setupUnlock)

function RV:Destroy()
    State.Destroyed=true; State.SliderActive=nil
    for _,c in pairs(State.Conns) do pcall(function() if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end) end
    for _,c in pairs(State.DmgConns) do pcall(function() if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end) end
    table.clear(State.DmgConns)
    for _,h in pairs(State.TracerPool) do pcall(function() if h and h.Parent then h:Destroy() end end) end
    table.clear(State.TracerPool)
    pcall(ClearAura); pcall(RestoreWorld)
    for _,v in pairs(State.ESPGui) do pcall(function() if typeof(v)=="Instance" and v.Parent then v:Destroy() end end) end
    table.clear(State.ESPGui); table.clear(hooked)
    pcall(function() visGui:Destroy() end)
    pcall(function() crossGui:Destroy() end)
end

print("[RV Visuals Module] loaded")
return RV
]==]
local RV
do
    local _ok,_fn=pcall(loadstring,_RV_SRC,"RVModule")
    if _ok and _fn then
        local _ok2,_r=pcall(_fn)
        if _ok2 and type(_r)=="table" then RV=_r end
    end
    if not RV then
        RV={Config={Aura={Enabled=false},Trail={Enabled=false},
            ESP={Enabled=false},Crosshair={Enabled=false}},
            Destroy=function()end}
    end
end
_RV_SRC = nil; pcall(collectgarbage,"collect") -- Free 83KB embedded module source

pcall(function()

    local VT = Tabs.Visuals

    local AUL = VT:AddLeftGroupbox("Aura")
    BT(AUL,"Aura_On","Aura Enabled",false,function(v)
        RV.Config.Aura.Enabled=v
        if v then local c=RV.Config; c=c; task.spawn(function() local ch=LP.Character; if ch then RV.BuildAura(ch) end end)
        else RV.ClearAura() end
    end)
    AUL:AddDropdown("Aura_Mode",{Text="Mode",Default="Cyber Blue",
        Values={"Cyber Blue","Blood Red","Venom Green","Royal Purple","Sun God","Shadow"},
        Callback=function(v) RV.Config.Aura.Mode=v; local ch=LP.Character; if ch then RV.BuildAura(ch) end end})
    AUL:AddToggle("Aura_RGB",{Text="RGB Cycle",Default=false,Callback=function(v) RV.Config.Aura.RGB=v end})
    AUL:AddSlider("Aura_Int",{Text="Intensity",Default=1,Min=0.3,Max=2,Rounding=1,Callback=function(v) RV.Config.Aura.Intensity=v; local ch=LP.Character; if ch then RV.BuildAura(ch) end end})
    AUL:AddSlider("Aura_Size",{Text="Size",Default=1,Min=0.6,Max=1.8,Rounding=1,Callback=function(v) RV.Config.Aura.Size=v; local ch=LP.Character; if ch then RV.BuildAura(ch) end end})
    AUL:AddToggle("Aura_Ring",{Text="Ring",Default=true,Callback=function(v) RV.Config.Aura.Ring=v; local ch=LP.Character; if ch then RV.BuildAura(ch) end end})
    AUL:AddToggle("Aura_Trail",{Text="Limb Trails",Default=true,Callback=function(v) RV.Config.Aura.Trail=v; local ch=LP.Character; if ch then RV.BuildAura(ch) end end})
    AUL:AddToggle("Aura_Pulse",{Text="Pulse",Default=true,Callback=function(v) RV.Config.Aura.Pulse=v end})
    AUL:AddButton("Rebuild Aura",function() local ch=LP.Character; if ch then RV.BuildAura(ch) end end)

    local CHL = VT:AddRightGroupbox("Crosshair")
    BT(CHL,"CH_On","Custom Crosshair",false,function(v) RV.Config.Crosshair.Enabled=v end)
    CHL:AddToggle("CH_DisGame",{Text="Disable Game Crosshair",Default=false,Callback=function(v) RV.Config.Crosshair.DisableGame=v end})
    CHL:AddSlider("CH_Size",{Text="Size",Default=17,Min=4,Max=40,Rounding=0,Callback=function(v) RV.Config.Crosshair.Size=v end})
    CHL:AddSlider("CH_Gap",{Text="Gap",Default=8,Min=0,Max=30,Rounding=0,Callback=function(v) RV.Config.Crosshair.Gap=v end})
    CHL:AddSlider("CH_Thick",{Text="Thickness",Default=1,Min=1,Max=6,Rounding=0,Callback=function(v) RV.Config.Crosshair.Thick=v end})
    CHL:AddToggle("CH_RGB",{Text="RGB",Default=true,Callback=function(v) RV.Config.Crosshair.RGB=v end})
    CHL:AddSlider("CH_RotSpd",{Text="Rotation Speed",Default=150,Min=0,Max=500,Rounding=0,Callback=function(v) RV.Config.Crosshair.RotSpeed=v end})
    CHL:AddToggle("CH_Pulse",{Text="Pulse",Default=true,Callback=function(v) RV.Config.Crosshair.Pulse=v end})
    CHL:AddToggle("CH_Follow",{Text="Follow Mouse",Default=true,Callback=function(v) RV.Config.Crosshair.FollowMouse=v end})
    CHL:AddToggle("CH_Label",{Text="Show Label",Default=true,Callback=function(v) RV.Config.Crosshair.Label=v end})
    CHL:AddInput("CH_LabelTxt",{Text="Label Text",Default="uncode",Placeholder="text...",ClearTextOnFocus=false,Callback=function(v) RV.Config.Crosshair.LabelText=v end})

    local ESL = VT:AddLeftGroupbox("Full ESP")
    BT(ESL,"RVFULL_ESP","Full ESP",false,function(v)
        RV.Config.ESP.Box=v; RV.Config.ESP.Name=v; RV.Config.ESP.Healthbar=v; RV.Config.ESP.Distance=v
    end)
    ESL:AddToggle("RVESP_Box",{Text="Corner Box",Default=false,Callback=function(v) RV.Config.ESP.Box=v end})
    ESL:AddToggle("RVESP_Outline",{Text="Outline / Highlight",Default=false,Callback=function(v) RV.Config.ESP.Outline=v end})
    ESL:AddToggle("RVESP_Name",{Text="Name",Default=true,Callback=function(v) RV.Config.ESP.Name=v end})
    ESL:AddToggle("RVESP_HP",{Text="Health Bar",Default=true,Callback=function(v) RV.Config.ESP.Healthbar=v end})
    ESL:AddToggle("RVESP_Dist",{Text="Distance",Default=true,Callback=function(v) RV.Config.ESP.Distance=v end})
    ESL:AddToggle("RVESP_Weap",{Text="Weapon",Default=false,Callback=function(v) RV.Config.ESP.Weapon=v end})
    ESL:AddToggle("RVESP_WM",{Text="Watermark",Default=false,Callback=function(v) RV.Config.ESP.Watermark=v end})
    ESL:AddInput("RVESP_WMTxt",{Text="Watermark Text",Default="uncode",ClearTextOnFocus=false,Callback=function(v) RV.Config.ESP.WatermarkText=v end})
    ESL:AddSlider("RVESP_MaxD",{Text="Max Distance",Default=1200,Min=100,Max=3000,Rounding=0,Callback=function(v) RV.Config.ESP.MaxDistance=v end})
    ESL:AddDropdown("RVESP_NameType",{Text="Name Type",Default="DisplayName",Values={"Name","DisplayName","Both"},Callback=function(v) RV.Config.ESP.NameType=v end})
    ESL:AddToggle("RVESP_Team",{Text="Include Teammates",Default=false,Callback=function(v) RV.Config.ESP.IncludeTeam=v end})

    local HFL = VT:AddRightGroupbox("Hit FX / Tracers")
    BT(HFL,"HitFX_On","Hit FX",false,function(v) RV.Config.HitFX.Enabled=v end)
    HFL:AddDropdown("HitFX_Sel",{Text="FX Style",Default="fortnite damage",Values={"fortnite damage","ForceField clone"},Callback=function(v) RV.Config.HitFX.Selected=v end})
    HFL:AddDropdown("HitFX_Mat",{Text="Clone Material",Default="ForceField",Values={"ForceField","Neon","Glass"},Callback=function(v) RV.Config.HitFX.Material=v end})
    HFL:AddToggle("HitFX_NoDmg",{Text="No Damage Numbers",Default=false,Callback=function(v) RV.Config.HitFX.DisableNumbers=v end})
    HFL:AddDivider()
    HFL:AddDropdown("HitSnd_Sel",{Text="Hit Sound",Default="bell",Values={"bell","pop","tick","fortnite"},Callback=function(v) RV.Config.HitSound.Selected=v end})
    HFL:AddSlider("HitSnd_Vol",{Text="Volume",Default=5,Min=0,Max=10,Rounding=1,Callback=function(v) RV.Config.HitSound.Volume=v end})
    HFL:AddSlider("HitSnd_Pit",{Text="Pitch",Default=1,Min=0.5,Max=2,Rounding=1,Callback=function(v) RV.Config.HitSound.Pitch=v end})
    HFL:AddDivider()
    BT(HFL,"Tracers_On","Tracers",false,function(v) RV.Config.Tracers.Enabled=v end)
    HFL:AddDropdown("Tracers_Style",{Text="Tracer Style",Default="trail",Values={"trail","beam","glow","energy"},Callback=function(v) RV.Config.Tracers.Selected=v end})
    HFL:AddSlider("Tracers_Fade",{Text="Fade",Default=0.4,Min=0.05,Max=2,Rounding=2,Callback=function(v) RV.Config.Tracers.Fade=v end})
    HFL:AddSlider("Tracers_Glow",{Text="Glow",Default=5,Min=0,Max=10,Rounding=1,Callback=function(v) RV.Config.Tracers.Glow=v end})
    HFL:AddSlider("Tracers_Size",{Text="Size",Default=1,Min=0.5,Max=5,Rounding=1,Callback=function(v) RV.Config.Tracers.Size=v end})

    local HUD = VT:AddLeftGroupbox("Target HUD")
    BT(HUD,"HUD_On","Target HUD",false,function(v) RV.Config.TargetHUD.Enabled=v end)
    HUD:AddSlider("HUD_OffX",{Text="Position X %",Default=17,Min=0,Max=100,Rounding=0,Callback=function(v) RV.Config.TargetHUD.OffX=v end})
    HUD:AddSlider("HUD_OffY",{Text="Position Y %",Default=70,Min=0,Max=100,Rounding=0,Callback=function(v) RV.Config.TargetHUD.OffY=v end})
    HUD:AddSlider("HUD_UIScale",{Text="UI Scale %",Default=170,Min=50,Max=300,Rounding=0,Callback=function(v) RV.Config.TargetHUD.UIScale=v end})

    local WL = VT:AddRightGroupbox("World Extended")
    BT(WL,"W_CC","Color Correction",false,function(v) RV.Config.World.CC_Enabled=v; RV.ApplyWorld() end)
    WL:AddSlider("W_Sat",{Text="Saturation",Default=0.1,Min=-1,Max=1,Rounding=2,Callback=function(v) RV.Config.World.Saturation=v; RV.ApplyWorld() end})
    WL:AddSlider("W_Con",{Text="Contrast",Default=0,Min=-1,Max=1,Rounding=2,Callback=function(v) RV.Config.World.Contrast=v; RV.ApplyWorld() end})
    WL:AddSlider("W_Bri",{Text="Brightness",Default=0,Min=-1,Max=1,Rounding=2,Callback=function(v) RV.Config.World.Brightness=v; RV.ApplyWorld() end})
    BT(WL,"W_Bloom","Bloom",false,function(v) RV.Config.World.Bloom=v; RV.ApplyWorld() end)
    WL:AddSlider("W_BInt",{Text="Bloom Intensity",Default=0.1,Min=0,Max=2,Rounding=2,Callback=function(v) RV.Config.World.BInt=v; RV.ApplyWorld() end})
    BT(WL,"W_SunRays","Sun Rays",false,function(v) RV.Config.World.SunRays=v; RV.ApplyWorld() end)
    BT(WL,"W_Sky","Custom Sky",false,function(v) RV.Config.World.Sky=v; RV.ApplyWorld() end)
    WL:AddDropdown("W_SkyPreset",{Text="Sky Preset",Default="Vertical Milky Way",Values={"Vertical Milky Way","Night Stars","Clean Day"},Callback=function(v) RV.Config.World.SkySelected=v; RV.ApplyWorld() end})
    WL:AddButton("Apply World",function() RV.ApplyWorld(); Notify("World applied",2) end)
    WL:AddButton("Restore World",function() RV.RestoreWorld(); Notify("World restored",2) end)

    local VML = VT:AddLeftGroupbox("Viewmodel Override")
    BT(VML,"VM_On","Override Viewmodel",false,function(v) RV.Config.Viewmodel.OverrideEnabled=v; RV.ApplyViewmodelOverride() end)
    VML:AddDropdown("VM_Mat",{Text="Weapon Material",Default="Neon",Values={"Neon","SmoothPlastic","ForceField","Glass","Metal","DiamondPlate"},Callback=function(v) RV.Config.Viewmodel.VMMaterial=v; if RV.Config.Viewmodel.OverrideEnabled then RV.ApplyViewmodelOverride() end end})
    VML:AddSlider("VM_Trans",{Text="Weapon Transparency",Default=95,Min=0,Max=100,Rounding=0,Callback=function(v) RV.Config.Viewmodel.VMTrans=v; if RV.Config.Viewmodel.OverrideEnabled then RV.ApplyViewmodelOverride() end end})
    VML:AddToggle("VM_Wire",{Text="Wireframe",Default=false,Callback=function(v) RV.Config.Viewmodel.VMWireframe=v; if RV.Config.Viewmodel.OverrideEnabled then RV.ApplyViewmodelOverride() end end})
    VML:AddDropdown("VM_ArmMat",{Text="Arm Material",Default="Neon",Values={"Neon","SmoothPlastic","ForceField","Glass","Metal"},Callback=function(v) RV.Config.Viewmodel.ArmMaterial=v; if RV.Config.Viewmodel.OverrideEnabled then RV.ApplyViewmodelOverride() end end})
    VML:AddSlider("VM_ArmTrans",{Text="Arm Transparency",Default=32,Min=0,Max=100,Rounding=0,Callback=function(v) RV.Config.Viewmodel.ArmTrans=v; if RV.Config.Viewmodel.OverrideEnabled then RV.ApplyViewmodelOverride() end end})
    VML:AddButton("Apply Now",function() RV.ApplyViewmodelOverride(); Notify("Viewmodel applied",2) end)

    local APL = VT:AddRightGroupbox("Appearance / Unlock")
    BT(APL,"App_On","Self Appearance",false,function(v) RV.Config.Appearance.Enabled=v; if v then RV.ApplyAppearance() end end)
    APL:AddDropdown("App_Mat",{Text="Material",Default="ForceField",Values={"ForceField","Neon","Glass","SmoothPlastic"},Callback=function(v) RV.Config.Appearance.Material=v; if RV.Config.Appearance.Enabled then RV.ApplyAppearance() end end})
    APL:AddSlider("App_Trans",{Text="Transparency",Default=100,Min=0,Max=100,Rounding=0,Callback=function(v) RV.Config.Appearance.Transparency=v; if RV.Config.Appearance.Enabled then RV.ApplyAppearance() end end})
    APL:AddToggle("App_NoDecal",{Text="Remove Clothing",Default=false,Callback=function(v) RV.Config.Appearance.NoDecal=v end})
    APL:AddDivider()
    BT(APL,"RV_Unlock","Unlock All (Full System)",false,function(v)
        RV.Unlock.active=v
        if v then Notify("Unlock All: Active (full system)",3) end
    end)
    APL:AddLabel("Hooks CosLib+DataCtrl+__namecall")
    APL:AddLabel("Supports Skin/Wrap/Charm/Dance")
end)

Notify("RV Visuals Ready . Aura/Crosshair/ESP/HitFX/Tracers/UnlockAll",4)

local _UCEngine
task.spawn(function()
    task.wait(2)
    pcall(collectgarbage,"collect") -- GC pass 1: clear setup overhead
    task.wait(0.3)
    pcall(collectgarbage,"collect") -- GC pass 2: ensure freed strings collected
    local _E1; local _ok1,_err1 = pcall(function()
        _E1 = (function()

local RS_  = game:GetService("ReplicatedStorage")
local PL_  = game:GetService("Players")
local RN_  = game:GetService("RunService")
local UI_  = game:GetService("UserInputService")
local LP_  = PL_.LocalPlayer
local WS_  = workspace
local CG_  = game:GetService("CoreGui")

local _util, _enums, _fc
pcall(function() _util  = require(cloneref(RS_).Modules.Utility)    end)
pcall(function() _enums = require(cloneref(RS_).Modules.EnumLibrary) end)
pcall(function() _fc    = require(LP_.PlayerScripts.Controllers.FighterController) end)

local _pool = {}
local function _conn(key, c)
    if not _pool[key] then _pool[key] = {} end
    table.insert(_pool[key], c)
    return c
end
local function _stop(key)
    for _, c in ipairs(_pool[key] or {}) do
        pcall(function() c:Disconnect() end)
    end
    _pool[key] = {}
end

local function _char()  return LP_.Character end
local function _root()
    local c = _char(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function _hum()
    local c = _char(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function _alive()
    local c = _char()
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart") ~= nil
end

local function _enemies()
    local list = {}
    for _, p in ipairs(PL_:GetPlayers()) do
        if p ~= LP_ and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r then table.insert(list, p) end
        end
    end
    return list
end

local function _closestEnemy(fov)
    fov = fov or 9999
    local cam = WS_.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local best, bestD = nil, fov
    for _, p in ipairs(_enemies()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local sp, vis = cam:WorldToViewportPoint(hrp.Position)
            if vis then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < bestD then bestD = d; best = p end
            end
        end
    end
    return best
end

-- 3D距離ベースの敵検索 (viewport可視不要 — 1v1 KA/AutoShoot用)
local function _closestEnemyWorld(maxDist)
    local root = _root(); if not root then return nil end
    local rpos = root.Position
    local best, bestD = nil, maxDist or 9999
    for _, p in ipairs(_enemies()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - rpos).Magnitude
            if d < bestD then bestD = d; best = p end
        end
    end
    return best
end

-- 複数の攻撃手段を試みる (Delta mouse1click → UIS SendMouseButtonEvent)
local function _doAttack()
    if mouse1click then pcall(mouse1click); return end
    pcall(function()
        UIS:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, true, false)
    end)
    task.defer(function()
        pcall(function()
            UIS:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, false, false)
        end)
    end)
end

local _BONE_ORDER = {"Head","UpperTorso","LowerTorso","HumanoidRootPart"}
local function _getBone(char)
    if not char then return nil end
    for _, name in ipairs(_BONE_ORDER) do
        local b = char:FindFirstChild(name)
        if b then return b end
    end
    return nil
end

local _velBuf = {}
local _velIdx = {}

local function _recordEnemy(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not _velBuf[p] then _velBuf[p] = {}; _velIdx[p] = 0 end
    local idx = (_velIdx[p] % 6) + 1
    _velIdx[p] = idx
    _velBuf[p][idx] = {pos = hrp.Position, t = tick()}
end

local function _predictPos(p, bone)
    bone = bone or (p and p.Character and _getBone(p.Character))
    if not bone then return nil end
    local buf = _velBuf[p]
    if not buf then return bone.Position end
    local oldest, newest = nil, nil
    for i = 1, 6 do
        local e = buf[i]
        if e then
            if not oldest or e.t < oldest.t then oldest = e end
            if not newest or e.t > newest.t then newest = e end
        end
    end
    if oldest and newest then
        local dT = newest.t - oldest.t
        if dT > 0.01 then
            local vel = (newest.pos - oldest.pos) / dT
            local lag = tick() - newest.t
            return bone.Position + vel * (lag + 0.05)
        end
    end
    return bone.Position
end

local _useItemRemote = nil
local _origFS = nil
local _saHooked = false
local _hnHooked = false

local function _getRemote()
    if _useItemRemote then return _useItemRemote end
    pcall(function()
        local rp = cloneref(RS_)
        _useItemRemote = rp.Remotes.Replication.Fighter.UseItem
    end)
    return _useItemRemote
end

local function _buildCamData(fromPos, bone, predPos)
    if not _util or not bone then return nil end
    predPos = predPos or bone.Position
    local look = CFrame.new(fromPos, predPos)
    local ok, data = pcall(function()
        local d = {}
        d[utf8.char(1)] = {
            [utf8.char(0)] = _util:EncodeCFrame(look),
            [utf8.char(1)] = _util:EncodeCFrame(look),
            [utf8.char(2)] = bone,
            [utf8.char(3)] = _util:EncodeCFrame(
                bone.CFrame:ToObjectSpace(CFrame.new(predPos))
            ),
        }
        return d
    end)
    return ok and data or nil
end

local _startShoot = nil
local function _getStartShoot()
    if not _startShoot then
        pcall(function()
            if _enums then _startShoot = _enums:ToEnum("StartShooting") end
        end)
    end
    return _startShoot
end

local SilentShot = {}
SilentShot.Enabled = false
SilentShot.FOV     = 120

function SilentShot.enable()
    if _saHooked then SilentShot.Enabled = true; return end
    local remote = _getRemote()
    if not remote or not hookfunction or not newcclosure then return end
    local _ssVT = 0
    _conn("SilentShot_vel", RN_.Heartbeat:Connect(function(dt)
        if not SilentShot.Enabled then return end
        _ssVT = _ssVT + dt; if _ssVT < 0.05 then return end; _ssVT = 0 -- 20 Hz (was every frame)
        local enemy = _closestEnemy(SilentShot.FOV)
        if enemy then _recordEnemy(enemy) end
    end))
    local ok, orig = pcall(function()
        local old
        old = hookfunction(remote.FireServer, newcclosure(function(self, obj, action, camdata, ...)
            pcall(function()
            if SilentShot.Enabled and action == _getStartShoot() then
                local cam = WS_.CurrentCamera
                local enemy = _closestEnemy(SilentShot.FOV)
                if enemy and enemy.Character then
                    local bone    = _getBone(enemy.Character)
                    local predPos = _predictPos(enemy, bone)
                    if bone and predPos then
                        local fromPos = cam and cam.CFrame.Position or bone.Position
                        local newData = _buildCamData(fromPos, bone, predPos)
                        if newData then camdata = newData end
                    end
                end
            end
            end)
            return old(self, obj, action, camdata, ...)
        end))
        _origFS = old
        return old
    end)
    if ok then _saHooked = true; SilentShot.Enabled = true end
end

function SilentShot.disable()
    SilentShot.Enabled = false
    _stop("SilentShot_vel")
end

local AimSmooth = {}
AimSmooth.Enabled = false
AimSmooth.Speed   = 6
AimSmooth.FOV     = 150

local _asEnemyCache = nil  -- 10 Hzでキャッシュ更新
local _asCacheT     = 0

function AimSmooth.enable()
    AimSmooth.Enabled = true
    _asEnemyCache = nil; _asCacheT = 0
    _conn("AimSmooth", RN_.RenderStepped:Connect(function(dt)
        if not AimSmooth.Enabled then return end
        if not mousemoverel then return end
        -- ターゲット検索は10Hz (毎フレーム検索から削減)
        _asCacheT = _asCacheT + dt
        if _asCacheT >= 0.10 then _asCacheT = 0; _asEnemyCache = _closestEnemy(AimSmooth.FOV) end
        local enemy = _asEnemyCache
        if not enemy or not enemy.Character then return end
        local bone = _getBone(enemy.Character)
        if not bone then return end
        local cam = WS_.CurrentCamera
        local facing = cam.CFrame.LookVector
        local dir    = (bone.Position - cam.CFrame.Position).Unit
        if dir == Vector3.zero then return end
        local sens = UserSettings():GetService("UserGameSettings").MouseSensitivity
        local moveC = Vector2.new(1, 0.77) * math.rad(0.5)
        local dyaw   = math.atan2(facing.X,facing.Z) - math.atan2(dir.X,dir.Z)
        dyaw = ((dyaw + math.pi) % (2*math.pi)) - math.pi
        local dpitch = math.asin(math.clamp(facing.Y,-1,1)) - math.asin(math.clamp(dir.Y,-1,1))
        local alpha  = 1 - math.exp(-AimSmooth.Speed * dt)
        local angle  = Vector2.new(dyaw, dpitch) / (moveC * math.max(sens, 0.01)) * alpha
        pcall(mousemoverel, angle.X, angle.Y)
    end))
end

function AimSmooth.disable()
    AimSmooth.Enabled = false
    _stop("AimSmooth")
end

-- Rage (AutoShoot): 最近敵の真下に高速テレポート → UseItem攻撃 → 元の位置に戻る
local AutoShoot = {}
AutoShoot.Enabled        = false
AutoShoot.Delay          = 0.18  -- ハイド: 攻撃サイクル間の待機時間(秒)
AutoShoot.AttackDuration = 0     -- アタック: 敵位置に滞在する時間(秒, 0=即帰還)
AutoShoot.BelowOffset    = 0     -- 敵HRPからのY方向オフセット(0=同位置, 負=真下)

local _asFrames = 0
local _asLock   = false  -- テレポート中フラグ (再入防止)

function AutoShoot.enable()
    AutoShoot.Enabled = true
    _asFrames = 0; _asLock = false
    _conn("AutoShoot", RN_.Heartbeat:Connect(function(dt)
        if not AutoShoot.Enabled or _asLock then return end
        _asFrames = _asFrames + dt
        if _asFrames < AutoShoot.Delay then return end

        local root = _root()
        if not root or not _alive() then return end

        -- 最近敵を取得
        local enemy = _closestEnemyWorld(600)
        if not enemy or not enemy.Character then return end
        local eHRP = enemy.Character:FindFirstChild("HumanoidRootPart")
        if not eHRP then return end

        _asFrames = 0
        _asLock   = true

        -- 1. 現在位置を保存
        local origCF = root.CFrame

        -- 2. 敵の真下にテレポート
        local tpPos = eHRP.Position + Vector3.new(0, AutoShoot.BelowOffset, 0)
        pcall(function() root.CFrame = CFrame.new(tpPos) end)

        -- 3. UseItemリモートで直接攻撃
        pcall(function()
            if not _util or not _enums then return end
            local remote = _getRemote(); if not remote then return end
            local ss = _getStartShoot(); if not ss then return end
            if not _fc then
                pcall(function() _fc = require(LP_.PlayerScripts.Controllers.FighterController) end)
            end
            if not _fc or not _fc.LocalFighter then return end
            local item = _fc.LocalFighter.EquippedItem; if not item then return end
            local objId; pcall(function() objId = item:Get("ObjectID") end); if not objId then return end
            local bone = _getBone(enemy.Character) or eHRP
            local cd   = _buildCamData(tpPos, bone, bone.Position)
            if not cd then return end
            remote:FireServer(objId, ss, cd, nil)
        end)

        -- 4. AttackDuration 後に元の位置に戻る (0=次フレーム即帰還)
        local dur = AutoShoot.AttackDuration or 0
        if dur > 0 then
            task.delay(dur, function()
                pcall(function() root.CFrame = origCF end)
                _asLock = false
            end)
        else
            task.defer(function()
                pcall(function() root.CFrame = origCF end)
                _asLock = false
            end)
        end
    end))
end

function AutoShoot.disable()
    AutoShoot.Enabled = false
    _asFrames = 0; _asLock = false
    _stop("AutoShoot")
end


local MaxMode = {}
MaxMode.Enabled = false

-- RageSnap: クロスヘアカラーインジケーター (赤=ロック中, シアン=未ロック)
local _mmCH = {} -- 4本のDrawingライン
local function _mmBuildCH()
    if _mmCH[1] then return end
    local cols = {"Top","Bot","Left","Right"}
    for i=1,4 do
        local l = Drawing.new("Line")
        l.Thickness = 2; l.Transparency = 1; l.Visible = false
        _mmCH[i] = l
    end
end
local function _mmUpdateCH(locked)
    local cam = WS_.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local g = 7 -- gap, s = arm length
    local s = 12
    local col = locked and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,220,255)
    -- Top, Bottom, Left, Right
    local pts = {
        {Vector2.new(cx,cy-g), Vector2.new(cx,cy-g-s)},
        {Vector2.new(cx,cy+g), Vector2.new(cx,cy+g+s)},
        {Vector2.new(cx-g,cy), Vector2.new(cx-g-s,cy)},
        {Vector2.new(cx+g,cy), Vector2.new(cx+g+s,cy)},
    }
    for i,l in ipairs(_mmCH) do
        l.From = pts[i][1]; l.To = pts[i][2]
        l.Color = col; l.Visible = true
    end
end
local function _mmHideCH()
    for _,l in ipairs(_mmCH) do if l then l.Visible=false end end
end

-- Rage敵キャッシュ (30Hz更新)
local _rageTarget = nil
local _rageCacheT  = 0

function MaxMode.enable()
    MaxMode.Enabled = true
    SilentShot.FOV = 350; SilentShot.enable()
    -- AutoShootを外す: クリック連打になるため。SilentShotが自分で撃った弾をリダイレクト
    _mmBuildCH(); _rageTarget = nil; _rageCacheT = 0
    -- インスタントスナップ: AimSmoothを使わず毎フレームで直接スナップ
    _conn("MaxMode_snap", RN_.RenderStepped:Connect(function(dt)
        if not MaxMode.Enabled then return end
        -- ターゲットを30Hzでリフレッシュ
        _rageCacheT = _rageCacheT + dt
        if _rageCacheT >= 0.033 then
            _rageCacheT = 0
            _rageTarget = _closestEnemy(350)
        end
        local enemy = _rageTarget
        -- クロスヘア更新
        pcall(_mmUpdateCH, enemy ~= nil)
        if not enemy or not enemy.Character then return end
        if not mousemoverel then return end
        local bone = _getBone(enemy.Character)
        if not bone then return end
        local cam = WS_.CurrentCamera
        local facing = cam.CFrame.LookVector
        local predPos = _predictPos(enemy, bone) or bone.Position
        local dir = (predPos - cam.CFrame.Position).Unit
        if dir == Vector3.zero then return end
        local sens = UserSettings():GetService("UserGameSettings").MouseSensitivity
        local moveC = Vector2.new(1, 0.77) * math.rad(0.5)
        local dyaw   = math.atan2(facing.X,facing.Z) - math.atan2(dir.X,dir.Z)
        dyaw = ((dyaw + math.pi) % (2*math.pi)) - math.pi
        local dpitch = math.asin(math.clamp(facing.Y,-1,1)) - math.asin(math.clamp(dir.Y,-1,1))
        -- alpha=1: スムーズなし即スナップ
        local angle  = Vector2.new(dyaw, dpitch) / (moveC * math.max(sens, 0.01))
        pcall(mousemoverel, angle.X, angle.Y)
    end))
end

function MaxMode.disable()
    MaxMode.Enabled = false
    _stop("MaxMode_snap")
    pcall(_mmHideCH)
    _rageTarget = nil
    SilentShot.disable()
    SilentShot.FOV = 120
end

local SkinSwap = {}
SkinSwap.Enabled = false
SkinSwap.Preset  = "neon_red"

-- Highlightインスタンス方式 (BasePart.Color変更はSurfaceAppearanceで上書きされるため)
-- HESPと同じ仕組みでキャラにHighlightを被せて色変更を実現
local _skinColors = {
    neon_red    = Color3.fromRGB(255, 50,  50),
    neon_blue   = Color3.fromRGB( 50, 100, 255),
    neon_green  = Color3.fromRGB( 50, 255,  80),
    chrome      = Color3.fromRGB(180, 200, 220),
    gold        = Color3.fromRGB(255, 200,  40),
    void        = Color3.fromRGB( 10,   0,  30),
    ice         = Color3.fromRGB(150, 230, 255),
    lava        = Color3.fromRGB(255,  80,   0),
    holographic = Color3.fromRGB(130, 255, 230),
    white       = Color3.fromRGB(255, 255, 255),
    black       = Color3.fromRGB( 10,  10,  10),
    pink        = Color3.fromRGB(255,  80, 180),
}
local _skinHL  = nil  -- Highlightインスタンス
local _skinHue = 0

local function _skinGetCol()
    return _skinColors[SkinSwap.Preset] or Color3.fromRGB(255, 50, 50)
end

local function _skinApply()
    local c = _char(); if not c then return end
    -- 既存のHighlightを片付け
    if _skinHL and _skinHL.Parent then pcall(function() _skinHL:Destroy() end) end
    _skinHL = Instance.new("Highlight")
    _skinHL.FillColor          = _skinGetCol()
    _skinHL.OutlineColor       = _skinGetCol()
    _skinHL.FillTransparency   = 0.15   -- 薄く塗りつぶし
    _skinHL.OutlineTransparency = 0.0   -- 縁は不透明
    _skinHL.DepthMode          = Enum.HighlightDepthMode.Occluded
    _skinHL.Adornee            = c
    _skinHL.Parent             = CG_    -- CoreGuiに置く (サーバー保護を回避)
end

function SkinSwap.enable()
    SkinSwap.Enabled = true
    _skinApply()
    _conn("SkinSwap", LP_.CharacterAdded:Connect(function()
        task.wait(0.3)
        if SkinSwap.Enabled then _skinApply() end
    end))
    _conn("SkinSwap", RN_.Heartbeat:Connect(function(dt)
        if not SkinSwap.Enabled then return end
        -- Highlightが消えていたら再適用
        if not _skinHL or not _skinHL.Parent then
            _skinApply(); return
        end
        -- レインボーモード: 色を毎フレーム更新
        if SkinSwap.Preset == "rainbow" then
            _skinHue = (_skinHue + dt * 0.3) % 1
            local col = Color3.fromHSV(_skinHue, 1, 1)
            pcall(function()
                _skinHL.FillColor    = col
                _skinHL.OutlineColor = col
            end)
        end
    end))
end

function SkinSwap.disable()
    SkinSwap.Enabled = false
    _stop("SkinSwap")
    if _skinHL then
        pcall(function() _skinHL:Destroy() end)
        _skinHL = nil
    end
end

-- FLY〜ORB は _E3 IIFE に移動済み (ローカル変数200上限対策)

local KA = {}
KA.Enabled = false
KA.Delay   = 0.08
local _kaAccum = 0

function KA.enable()
    KA.Enabled = true
    _kaAccum = 0
    _conn("KA", RN_.Heartbeat:Connect(function(dt)
        if not KA.Enabled then return end
        _kaAccum = _kaAccum + dt
        if _kaAccum < KA.Delay then return end
        if not _alive() then return end
        -- 範囲チェックなし: 敵が存在すれば即攻撃
        local enemy = _closestEnemyWorld(9999)
        if not enemy or not enemy.Character then return end
        _kaAccum = 0
        _doAttack()
    end))
end

function KA.disable()
    KA.Enabled = false
    _stop("KA")
    _kaAccum = 0
end

local AP = {}
AP.Enabled  = false
AP.Range    = 20
AP.MinSpeed = 40
local _apCooldown = 0

-- AP用プロジェクタイルキャッシュ (GetDescendants毎フレーム呼び出しを回避)
local _apParts = {}
local _apPartCount = 0
local function _apTrackPart(obj)
    if not obj:IsA("BasePart") then return end
    if obj.Anchored then return end
    -- キャラクターパーツは除外
    local m = obj:FindFirstAncestorOfClass("Model")
    if m and WS_.Players:FindFirstChild(m.Name) then return end
    _apPartCount = _apPartCount + 1
    _apParts[obj] = true
    obj.AncestryChanged:Connect(function(_, p)
        if not p then _apParts[obj] = nil end
    end)
end
local _apInitialized = false
local function _apInit()
    if _apInitialized then return end
    _apInitialized = true
    for _, obj in ipairs(WS_:GetDescendants()) do _apTrackPart(obj) end
    _conn("AP_track", WS_.DescendantAdded:Connect(_apTrackPart))
end

function AP.enable()
    AP.Enabled = true
    _apCooldown = 0
    _apInit()
    _conn("AP", RN_.Heartbeat:Connect(function(dt)
        if not AP.Enabled then return end
        _apCooldown = math.max(0, _apCooldown - dt)
        if _apCooldown > 0 then return end
        local root = _root(); if not root then return end
        local rpos = root.Position
        for obj in pairs(_apParts) do
            if not obj or not obj.Parent then _apParts[obj] = nil; continue end
            local d = (obj.Position - rpos).Magnitude
            if d < AP.Range then
                local vel = obj.AssemblyLinearVelocity
                if vel.Magnitude >= AP.MinSpeed then
                    local toPlayer = (rpos - obj.Position)
                    if toPlayer.Magnitude > 0 then
                        local dot = toPlayer.Unit:Dot(vel.Unit)
                        if dot > 0.65 then
                            _apCooldown = 0.4
                            pcall(function() if mouse2click then mouse2click() end end)
                            return
                        end
                    end
                end
            end
        end
    end))
end

function AP.disable()
    AP.Enabled = false
    _apCooldown = 0
    _stop("AP")
end

-- ============================================================
-- [uncode] Triggerbot: クロスヘアに敵が重なったら自動射撃
-- ============================================================
local TRIG = {}
TRIG.Enabled = false
TRIG.ReactionTime = 100   -- ms (反応時間)
TRIG.ForgetTime   = 0.5   -- seconds (ロック保持時間)
TRIG.MaxDistance  = 150   -- studs (最大距離)

local _trigRP = RaycastParams.new()
_trigRP.FilterType  = Enum.RaycastFilterType.Exclude
_trigRP.IgnoreWater = true

local _trigLocked     = nil
local _trigCandidate  = nil
local _trigCandSince  = 0
local _trigLastSeen   = 0
local _trigLastShot   = 0
local _trigShooting   = false

local function _trigCharFromPart(part)
    local node = part
    while node and node ~= workspace do
        if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then return node end
        node = node.Parent
    end
end

local function _trigGetTarget()
    local cam = WS_.CurrentCamera
    if not cam or not LP_.Character then return nil end
    local vp  = cam.ViewportSize
    local ray = cam:ViewportPointToRay(vp.X/2, vp.Y/2)
    local filter = {LP_.Character, cam}
    local vm = workspace:FindFirstChild("ViewModels")
    if vm then table.insert(filter, vm) end
    _trigRP.FilterDescendantsInstances = filter
    local hit = workspace:Raycast(ray.Origin, ray.Direction * TRIG.MaxDistance, _trigRP)
    if not hit or not hit.Instance then return nil end
    local char = _trigCharFromPart(hit.Instance)
    if not char or char == LP_.Character then return nil end
    local player = PL_:GetPlayerFromCharacter(char)
    if not player or player == LP_ then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return char
end

local function _trigGetStable()
    local target = _trigGetTarget()
    local now    = tick()
    if target then
        if target ~= _trigCandidate then
            _trigCandidate = target; _trigCandSince = now
        end
        local reaction = TRIG.ReactionTime / 1000
        if target == _trigLocked or now - _trigCandSince >= reaction then
            _trigLocked = target; _trigLastSeen = now
        end
    else
        _trigCandidate = nil
    end
    if _trigLocked and now - _trigLastSeen <= TRIG.ForgetTime then
        local hum = _trigLocked:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return _trigLocked end
    end
    _trigLocked = nil; return nil
end

function TRIG.enable()
    TRIG.Enabled = true
    _trigLocked = nil; _trigCandidate = nil
    _conn("TRIG", RN_.Heartbeat:Connect(function()
        if not TRIG.Enabled then return end
        if not _trigGetStable() then return end
        if _trigShooting then return end
        local now = tick()
        if now - _trigLastShot < 0.05 then return end
        _trigLastShot = now; _trigShooting = true
        _doAttack()
        task.delay(0.05, function() _trigShooting = false end)
    end))
end

function TRIG.disable()
    TRIG.Enabled = false
    _stop("TRIG")
    _trigLocked = nil; _trigCandidate = nil
end

return {
    SilentShot=SilentShot, AimSmooth=AimSmooth, AutoShoot=AutoShoot,
    MaxMode=MaxMode, TRIG=TRIG,
    SkinSwap=SkinSwap, KA=KA, AP=AP,
}
        end)()
    end)
    if not _ok1 then print("[UNCODE v1] Part1 err:"..tostring(_err1)) end
    pcall(collectgarbage,"collect")
    task.wait(0.8) -- ← 延長: iOS GCがクロージャを回収する時間を確保
    pcall(collectgarbage,"collect")
    local _E2; local _ok2,_err2 = pcall(function()
        _E2 = (function()
local RS_  = game:GetService("ReplicatedStorage")
local PL_  = game:GetService("Players")
local RN_  = game:GetService("RunService")
local UI_  = game:GetService("UserInputService")
local LP_  = PL_.LocalPlayer
local WS_  = workspace
local CG_  = game:GetService("CoreGui")
local _pool = {}
local function _conn(key,c)
    if not _pool[key] then _pool[key]={} end
    table.insert(_pool[key],c); return c
end
local function _stop(key)
    for _,c in ipairs(_pool[key] or {}) do pcall(function() c:Disconnect() end) end
    _pool[key]={}
end
local function _char() return LP_.Character end
local function _root() local c=_char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function _hum()  local c=_char(); return c and c:FindFirstChildOfClass("Humanoid")   end

local ESP = {}
ESP.Enabled  = false
ESP.MaxDist  = 600

local _espDrawings = {}

local function _makeBox()
    local d = {
        box  = Drawing.new("Square"),
        name = Drawing.new("Text"),
        hbar = Drawing.new("Line"),
        hbg  = Drawing.new("Line"),
        trc  = Drawing.new("Line"),
        dist = Drawing.new("Text"),
        weap = Drawing.new("Text"),  -- 武器名
        snapL= Drawing.new("Line"),  -- スナップライン (足元)
    }
    d.box.Filled = false; d.box.Thickness = 1.5
    d.box.Color  = Color3.fromRGB(255,60,60)
    d.name.Size  = 13; d.name.Center = true; d.name.Outline = true
    d.name.Color = Color3.fromRGB(255,255,255)
    d.hbar.Thickness = 3; d.hbar.Color  = Color3.fromRGB(60,200,60)
    d.hbg.Thickness  = 3; d.hbg.Color   = Color3.fromRGB(60,60,60)
    d.trc.Thickness  = 1; d.trc.Color   = Color3.fromRGB(255,60,60)
    d.dist.Size = 11; d.dist.Center = true; d.dist.Outline = true
    d.dist.Color = Color3.fromRGB(200,200,200)
    d.weap.Size = 11; d.weap.Center = true; d.weap.Outline = true
    d.weap.Color = Color3.fromRGB(255,200,60)
    d.snapL.Thickness = 1; d.snapL.Color = Color3.fromRGB(255,100,100)
    for _,v in pairs(d) do v.Visible = false end
    return d
end

local function _removeEspFor(p)
    local d = _espDrawings[p]
    if not d then return end
    for _,v in pairs(d) do pcall(function() v:Remove() end) end
    _espDrawings[p] = nil
end

local _espLT = 0
local function _espLoop()
    if not ESP.Enabled then return end
    do local _t=os.clock() if _t-_espLT<0.05 then return end; _espLT=_t end
    local cam = WS_.CurrentCamera
    local vp  = cam.ViewportSize
    local screenBot = Vector2.new(vp.X/2, vp.Y)
    for _, p in ipairs(PL_:GetPlayers()) do
        if p == LP_ then _removeEspFor(p); continue end
        local c    = p.Character
        local hrp  = c and c:FindFirstChild("HumanoidRootPart")
        local head = c and c:FindFirstChild("Head")
        local hum  = c and c:FindFirstChildOfClass("Humanoid")
        if not hrp or not head or not hum or hum.Health <= 0 then
            _removeEspFor(p); continue
        end
        if not _espDrawings[p] then _espDrawings[p] = _makeBox() end
        local d = _espDrawings[p]
        local sp, vis = cam:WorldToViewportPoint(hrp.Position)
        if not vis then
            for _,v in pairs(d) do v.Visible = false end
            continue
        end
        local myRoot = _root()
        local studs = (hrp.Position - (myRoot and myRoot.Position or hrp.Position)).Magnitude
        -- alpha: 近い=1(不透明), 遠い=0.2(半透明)
        -- Drawing APIはTransparency=0が不透明,1が透明なのでalphaを反転する
        local alpha = math.clamp(1 - studs / ESP.MaxDist, 0.2, 1)
        local transp = 1 - alpha  -- 近い=0(不透明), 遠い=0.8(透明寄り)
        local topSP = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2.5,0))
        local w  = math.clamp(math.abs(sp.Z) * 1.2, 20, 200)
        local h2 = math.abs(Vector2.new(sp.X,sp.Y).Y - Vector2.new(topSP.X,topSP.Y).Y) + 8
        local x, y = sp.X - w/2, topSP.Y - 4
        local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
        -- 体力に応じてボックス色変化: 緑(満タン)→黄→赤(瀕死)
        local hpR = math.floor(255 * math.clamp(2*(1-hp), 0, 1))
        local hpG = math.floor(255 * math.clamp(2*hp,     0, 1))
        local hpCol = Color3.fromRGB(hpR, hpG, 40)
        d.box.Position     = Vector2.new(x, y)
        d.box.Size         = Vector2.new(w, h2)
        d.box.Color        = hpCol
        d.box.Transparency = transp; d.box.Visible = true
        -- 名前 (DisplayName + HP%)
        d.name.Position    = Vector2.new(sp.X, y - 16)
        d.name.Text        = p.DisplayName .. " [" .. math.floor(hp*100) .. "%]"
        d.name.Transparency = transp; d.name.Visible = true
        -- 距離
        d.dist.Position    = Vector2.new(sp.X, y + h2 + 2)
        d.dist.Text        = string.format("%.0fm", studs)
        d.dist.Transparency = transp; d.dist.Visible = true
        -- 武器名
        local tool = c:FindFirstChildOfClass("Tool")
        if tool then
            d.weap.Position    = Vector2.new(sp.X, y - 28)
            d.weap.Text        = "[" .. tool.Name .. "]"
            d.weap.Transparency= transp; d.weap.Visible = true
        else
            d.weap.Visible = false
        end
        -- HPバー (体力色)
        local bx = x - 6
        d.hbg.From  = Vector2.new(bx, y); d.hbg.To = Vector2.new(bx, y+h2)
        d.hbar.From = Vector2.new(bx, y+h2*(1-hp))
        d.hbar.To   = Vector2.new(bx, y+h2)
        d.hbar.Color = hpCol
        d.hbg.Transparency = transp; d.hbar.Transparency = transp
        d.hbg.Visible = true; d.hbar.Visible = true
        -- トレーサー (クロスヘアから敵の足元へ)
        d.trc.From  = screenBot
        d.trc.To    = Vector2.new(sp.X, y + h2)
        d.trc.Color = hpCol
        d.trc.Transparency = math.clamp(transp + 0.35, 0, 0.85)
        d.trc.Visible = true
        -- スナップライン (画面下端→足元)
        d.snapL.From = Vector2.new(vp.X/2, vp.Y)
        d.snapL.To   = Vector2.new(sp.X, y + h2)
        d.snapL.Color = hpCol
        d.snapL.Transparency = 0.7
        d.snapL.Visible = false -- デフォルトOFF、将来のトグル用

    end
end

function ESP.enable()
    ESP.Enabled = true
    _conn("ESP", RN_.RenderStepped:Connect(_espLoop))
end

function ESP.disable()
    ESP.Enabled = false
    _stop("ESP")
    for p in pairs(_espDrawings) do _removeEspFor(p) end
end

local VMR = {}
VMR.Enabled = false

function VMR.enable()
    VMR.Enabled = true
    _conn("VMR", RN_.RenderStepped:Connect(function()
        if not VMR.Enabled then return end
        pcall(function()
            local vms = workspace:FindFirstChild("ViewModels"); if not vms then return end
            for _, vm in ipairs(vms:GetChildren()) do
                local pv = vm:FindFirstChild(tostring(LP_.UserId)) or vm:FindFirstChild(LP_.Name)
                if pv then
                    for _, p in ipairs(pv:GetDescendants()) do
                        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
                    end
                end
            end
        end)
    end))
end

function VMR.disable()
    VMR.Enabled = false
    _stop("VMR")
    pcall(function()
        local vms = workspace:FindFirstChild("ViewModels"); if not vms then return end
        for _, vm in ipairs(vms:GetChildren()) do
            local pv = vm:FindFirstChild(tostring(LP_.UserId)) or vm:FindFirstChild(LP_.Name)
            if pv then
                for _, p in ipairs(pv:GetDescendants()) do
                    if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
                end
            end
        end
    end)
end

local NS = {}
NS.Enabled = false
NS.Name    = "uncode"
local _nsOrigName = nil

local function _nsApply(c)
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("TextLabel") and d.Parent:IsA("BillboardGui") then
            if d.Text == LP_.DisplayName or d.Text == LP_.Name then
                d.Text = NS.Name
            end
        end
    end
end

function NS.enable()
    NS.Enabled = true
    _nsOrigName = LP_.DisplayName
    pcall(function() _nsApply(_char()) end)
    _conn("NS", LP_.CharacterAdded:Connect(function(c)
        task.wait(1); if NS.Enabled then _nsApply(c) end
    end))
end

function NS.disable()
    NS.Enabled = false
    _stop("NS")
    pcall(function()
        local c = _char(); if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("TextLabel") and d.Parent:IsA("BillboardGui") and d.Text == NS.Name then
                d.Text = _nsOrigName or LP_.DisplayName
            end
        end
    end)
end

local HN = {}
HN.Enabled = false
HN.Volume  = 0.5
local _hnGui = nil
local _hnOrig = nil

local function _hnFlash()
    if not HN.Enabled then return end
    pcall(function()
        if not _hnGui then
            _hnGui = Instance.new("ScreenGui")
            _hnGui.Name = "UC_HN"; _hnGui.IgnoreGuiInset = true
            _hnGui.Parent = CG_
            local f = Instance.new("Frame")
            f.BackgroundColor3 = Color3.fromRGB(255,50,50)
            f.BackgroundTransparency = 0.7
            f.Size = UDim2.new(1,0,1,0)
            f.BorderSizePixel = 0; f.Name = "Flash"; f.Parent = _hnGui
        end
        local f = _hnGui.Flash
        f.Visible = true
        game:GetService("TweenService"):Create(f, TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        task.delay(0.35, function() if f then f.Visible=false; f.BackgroundTransparency=0.7 end end)
    end)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6042053626"; s.Volume = HN.Volume
        s.Parent = workspace; s:Play()
        game:GetService("Debris"):AddItem(s, 2)
    end)
end

function HN.enable()
    HN.Enabled = true
    if _hnHooked then return end
    pcall(function()
        local remote = _getRemote()
        if not remote or not hookfunction or not newcclosure then return end
        local old = _hnOrig or remote.FireServer
        _hnOrig = hookfunction(remote.FireServer, newcclosure(function(self, obj, action, ...)
            local result = {old(self, obj, action, ...)}
            if action == _getStartShoot() then task.spawn(_hnFlash) end
            return table.unpack(result)
        end))
        _hnHooked = true
    end)
end

function HN.disable()
    HN.Enabled = false
    pcall(function() if _hnGui then _hnGui:Destroy(); _hnGui = nil end end)
end

local BL = {}
BL.Enabled  = false
BL.Distance = 30
local _blLast = 0

function BL.enable()
    BL.Enabled = true
    _conn("BL", UI_.InputBegan:Connect(function(i, p)
        if p or not BL.Enabled then return end
        if i.KeyCode ~= Enum.KeyCode.F then return end
        if tick() - _blLast < 0.5 then return end
        _blLast = tick()
        local root = _root(); if not root then return end
        pcall(function()
            local fwd = WS_.CurrentCamera.CFrame.LookVector
            root.CFrame = CFrame.new(root.Position + fwd * BL.Distance, root.Position + fwd * (BL.Distance+1))
        end)
    end))
end

function BL.disable()
    BL.Enabled = false
    _stop("BL")
end

local STD = {}
STD.Enabled = false
local _stdKnown = {}
local _staffNames = {"roplex","vixlon","worrior","Roplex","Vixlon"}

local function _isStaff(p)
    for _, name in ipairs(_staffNames) do
        if p.Name:lower() == name:lower() then return true end
    end
    return false
end

function STD.enable()
    STD.Enabled = true
    _conn("STD", RN_.Heartbeat:Connect(function()
        if not STD.Enabled then return end
        for _, p in ipairs(PL_:GetPlayers()) do
            if p ~= LP_ and not _stdKnown[p] and _isStaff(p) then
                _stdKnown[p] = true
                pcall(function() if Notify then Notify("Staff detected: "..p.Name, 6) end end)
                print("[UNCODE v1] Staff detected:", p.Name)
            end
        end
    end))
end

function STD.disable()
    STD.Enabled = false
    _stop("STD")
    table.clear(_stdKnown)
end

local SHD = {}
SHD.Enabled = false
local _shdOrig = {}

function SHD.enable()
    SHD.Enabled = true
    local Lighting = game:GetService("Lighting")
    _shdOrig.Ambient    = Lighting.Ambient
    _shdOrig.Outdoor    = Lighting.OutdoorAmbient
    _shdOrig.Brightness = Lighting.Brightness
    pcall(function()
        Lighting.Ambient         = Color3.fromRGB(40, 40, 80)
        Lighting.OutdoorAmbient  = Color3.fromRGB(50, 50,100)
        Lighting.Brightness      = 2
    end)
end

function SHD.disable()
    SHD.Enabled = false
    pcall(function()
        local L = game:GetService("Lighting")
        L.Ambient        = _shdOrig.Ambient    or Color3.fromRGB(127,127,127)
        L.OutdoorAmbient = _shdOrig.Outdoor    or Color3.fromRGB(127,127,127)
        L.Brightness     = _shdOrig.Brightness or 1
    end)
end

local CMV = {}
CMV.Enabled   = false
CMV.WalkSpeed = 32

function CMV.enable()
    CMV.Enabled = true
    _conn("CMV", RN_.Heartbeat:Connect(function()
        if not CMV.Enabled then return end
        local h = _hum()
        if h and h.WalkSpeed < CMV.WalkSpeed then
            pcall(function() h.WalkSpeed = CMV.WalkSpeed end)
        end
    end))
end

function CMV.disable()
    CMV.Enabled = false
    _stop("CMV")
    pcall(function() local h = _hum(); if h then h.WalkSpeed = 16 end end)
end

local WINGS = {}
WINGS.Enabled = false
local _wingObjs = {}

local function _cleanWings()
    for _, o in ipairs(_wingObjs) do pcall(function() o:Destroy() end) end
    table.clear(_wingObjs)
end

local function _buildWingSide(hrp, mult)
    local function att(px, py, pz)
        local a = Instance.new("Attachment")
        a.Position = Vector3.new(px, py, pz)
        a.Parent = hrp
        table.insert(_wingObjs, a)
        return a
    end
    local function mkBeam(a0, a1, w0, w1, hue)
        local b = Instance.new("Beam")
        b.Attachment0 = a0; b.Attachment1 = a1
        b.Width0 = w0; b.Width1 = w1
        b.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromHSV(hue, 0.5, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.1)%1, 0.7, 1)),
            ColorSequenceKeypoint.new(1,   Color3.fromHSV((hue+0.2)%1, 0.9, 1)),
        })
        b.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0.0),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1,   0.7),
        })
        b.LightEmission = 0.95; b.LightInfluence = 0.05
        b.Segments = 10
        b.Parent = hrp
        table.insert(_wingObjs, b)
        return b
    end
    local orig = att(mult*0.5,  0.6, -0.3)
    local tipU = att(mult*5.2,  3.0, -0.2)
    local tipM = att(mult*5.8,  0.5,  0.0)
    local tipD = att(mult*3.8, -2.0,  0.3)
    local mid1 = att(mult*2.8,  2.2, -0.1)
    local mid2 = att(mult*3.2, -0.4,  0.1)
    mkBeam(orig, tipU, 0.60, 0.06, 0.72)
    mkBeam(orig, tipM, 0.50, 0.05, 0.75)
    mkBeam(orig, tipD, 0.40, 0.05, 0.78)
    mkBeam(orig, mid1, 0.35, 0.04, 0.70)
    mkBeam(orig, mid2, 0.28, 0.04, 0.74)
    mkBeam(tipU, mid1, 0.06, 0.04, 0.68)
    mkBeam(mid1, tipM, 0.05, 0.04, 0.73)
    mkBeam(tipM, mid2, 0.05, 0.03, 0.77)
    mkBeam(mid2, tipD, 0.04, 0.03, 0.80)
end

local function _setupWings(char)
    _cleanWings()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(_buildWingSide, hrp,  1)
    pcall(_buildWingSide, hrp, -1)
end

function WINGS.enable()
    WINGS.Enabled = true
    _setupWings(_char())
    _conn("WINGS", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if WINGS.Enabled then _setupWings(c) end
    end))
    local hue = 0
    local _wingsT = 0
    _conn("WINGS_col", RN_.Heartbeat:Connect(function(dt)
        if not WINGS.Enabled then return end
        do local _t=os.clock() if _t-_wingsT<0.05 then return end; _wingsT=_t end
        hue = (hue + dt * 0.18) % 1
        for _, o in ipairs(_wingObjs) do
            if o:IsA("Beam") then
                pcall(function()
                    o.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromHSV(hue, 0.4, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.12)%1, 0.7, 1)),
                        ColorSequenceKeypoint.new(1,   Color3.fromHSV((hue+0.25)%1, 0.9, 1)),
                    })
                end)
            end
        end
    end))
end

function WINGS.disable()
    WINGS.Enabled = false
    _stop("WINGS"); _stop("WINGS_col")
    _cleanWings()
end

local AURA = {}
AURA.Enabled = false
local _auraBox = nil
local _auraHue = 0
local _auraT = 0

function AURA.enable()
    AURA.Enabled = true
    _conn("AURA", RN_.Heartbeat:Connect(function(dt)
        if not AURA.Enabled then return end
        do local _t=os.clock() if _t-_auraT<0.05 then return end; _auraT=_t end
        local c = _char()
        if not c then
            if _auraBox then pcall(function() _auraBox:Destroy() end); _auraBox = nil end
            return
        end
        if not _auraBox or not _auraBox.Parent then
            _auraBox = Instance.new("SelectionBox")
            _auraBox.LineThickness = 0.07
            _auraBox.SurfaceTransparency = 0.82
            _auraBox.Adornee = c
            _auraBox.Parent = CG_
        end
        _auraHue = (_auraHue + dt * 0.45) % 1
        local col = Color3.fromHSV(_auraHue, 1, 1)
        pcall(function()
            _auraBox.Color3 = col
            _auraBox.SurfaceColor3 = col
        end)
    end))
    _conn("AURA", LP_.CharacterAdded:Connect(function()
        if _auraBox then pcall(function() _auraBox:Destroy() end); _auraBox = nil end
    end))
end

function AURA.disable()
    AURA.Enabled = false
    _stop("AURA")
    if _auraBox then pcall(function() _auraBox:Destroy() end); _auraBox = nil end
end

local TRAIL = {}
TRAIL.Enabled = false
local _trailClean = {}

local function _setupTrail(char)
    for _, o in ipairs(_trailClean) do pcall(function() o:Destroy() end) end
    table.clear(_trailClean)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 1, 0); a0.Parent = hrp
    local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0,-1, 0); a1.Parent = hrp
    local tr = Instance.new("Trail")
    tr.Attachment0 = a0; tr.Attachment1 = a1
    tr.Lifetime = 1.2; tr.MinLength = 0
    tr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 80, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB( 80,160,255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB( 80,255,160)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,210, 80)),
    })
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    tr.LightEmission = 0.9
    tr.Parent = hrp
    table.insert(_trailClean, a0)
    table.insert(_trailClean, a1)
    table.insert(_trailClean, tr)
end

function TRAIL.enable()
    TRAIL.Enabled = true
    _setupTrail(_char())
    _conn("TRAIL", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if TRAIL.Enabled then _setupTrail(c) end
    end))
end

function TRAIL.disable()
    TRAIL.Enabled = false
    _stop("TRAIL")
    for _, o in ipairs(_trailClean) do pcall(function() o:Destroy() end) end
    table.clear(_trailClean)
end

local GLOW = {}
GLOW.Enabled = false
local _glowLight = nil

local function _setupGlow(char)
    if _glowLight then pcall(function() _glowLight:Destroy() end); _glowLight = nil end
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    _glowLight = Instance.new("PointLight")
    _glowLight.Name = "UC_Glow"
    _glowLight.Range = 22; _glowLight.Brightness = 3
    _glowLight.Parent = hrp
end

function GLOW.enable()
    GLOW.Enabled = true
    _setupGlow(_char())
    _conn("GLOW", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if GLOW.Enabled then _setupGlow(c) end
    end))
    local t = 0
    _conn("GLOW", RN_.Heartbeat:Connect(function(dt)
        if not GLOW.Enabled then return end
        do local _t=os.clock() if _t-(_gT or 0)<0.05 then return end; _gT=_t end
        if not _glowLight or not _glowLight.Parent then return end
        t = t + dt
        pcall(function()
            _glowLight.Brightness = 2 + math.sin(t * 2.2) * 2
            _glowLight.Color = Color3.fromHSV((t * 0.12) % 1, 1, 1)
        end)
    end))
end

function GLOW.disable()
    GLOW.Enabled = false
    _stop("GLOW")
    if _glowLight then pcall(function() _glowLight:Destroy() end); _glowLight = nil end
end

local SPARKLE = {}
SPARKLE.Enabled = false
local _sparkClean = {}

local function _setupSparkle(char)
    for _, o in ipairs(_sparkClean) do pcall(function() o:Destroy() end) end
    table.clear(_sparkClean)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local pe = Instance.new("ParticleEmitter")
    pe.Name = "UC_Sparkle"
    pe.Rate = 38
    pe.Lifetime = NumberRange.new(0.6, 1.8)
    pe.Speed = NumberRange.new(3, 10)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.RotSpeed = NumberRange.new(-120, 120)
    pe.Rotation = NumberRange.new(0, 360)
    pe.LightEmission = 1; pe.LightInfluence = 0
    pe.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,220, 80)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 80,200)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB( 80,200,255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(200,255,120)),
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.0),
        NumberSequenceKeypoint.new(0.6, 0.5),
        NumberSequenceKeypoint.new(1,   1.0),
    })
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.28),
        NumberSequenceKeypoint.new(0.4, 0.18),
        NumberSequenceKeypoint.new(1,   0.0),
    })
    pe.Parent = hrp
    table.insert(_sparkClean, pe)
end

function SPARKLE.enable()
    SPARKLE.Enabled = true
    _setupSparkle(_char())
    _conn("SPARKLE", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if SPARKLE.Enabled then _setupSparkle(c) end
    end))
end

function SPARKLE.disable()
    SPARKLE.Enabled = false
    _stop("SPARKLE")
    for _, o in ipairs(_sparkClean) do pcall(function() o:Destroy() end) end
    table.clear(_sparkClean)
end

local HALO = {}
HALO.Enabled = false
local _haloPart = nil

local function _setupHalo(char)
    if _haloPart then pcall(function() _haloPart:Destroy() end); _haloPart = nil end
    if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    _haloPart = Instance.new("Part")
    _haloPart.Name = "UC_Halo"
    _haloPart.Shape = Enum.PartType.Cylinder
    _haloPart.Size = Vector3.new(0.12, 2.3, 2.3)
    _haloPart.Material = Enum.Material.Neon
    _haloPart.Color = Color3.fromRGB(255, 230, 80)
    _haloPart.CanCollide = false; _haloPart.Anchored = false
    _haloPart.CastShadow = false
    _haloPart.Parent = char
    local weld = Instance.new("Weld")
    weld.Part0 = head; weld.Part1 = _haloPart
    weld.C0 = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
    weld.Parent = _haloPart
end

function HALO.enable()
    HALO.Enabled = true
    _setupHalo(_char())
    _conn("HALO", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if HALO.Enabled then _setupHalo(c) end
    end))
    local t = 0
    _conn("HALO_anim", RN_.Heartbeat:Connect(function(dt)
        if not HALO.Enabled then return end
        do local _t=os.clock() if _t-(_hT or 0)<0.05 then return end; _hT=_t end
        if not _haloPart or not _haloPart.Parent then return end
        t = (t + dt * 0.5) % 1
        pcall(function() _haloPart.Color = Color3.fromHSV(t, 0.88, 1) end)
    end))
end

function HALO.disable()
    HALO.Enabled = false
    _stop("HALO"); _stop("HALO_anim")
    if _haloPart then pcall(function() _haloPart:Destroy() end); _haloPart = nil end
end

local FLAM = {}
FLAM.Enabled = false
local _flamClean = {}

local function _setupFlam(char)
    for _, o in ipairs(_flamClean) do pcall(function() o:Destroy() end) end
    table.clear(_flamClean)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local pe = Instance.new("ParticleEmitter")
    pe.Name = "UC_Flame"
    pe.Rate = 60
    pe.Lifetime = NumberRange.new(0.5, 1.4)
    pe.Speed = NumberRange.new(5, 14)
    pe.SpreadAngle = Vector2.new(22, 22)
    pe.EmissionDirection = Enum.NormalId.Top
    pe.RotSpeed = NumberRange.new(-60, 60)
    pe.Rotation = NumberRange.new(0, 360)
    pe.LightEmission = 1; pe.LightInfluence = 0
    pe.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,  70,   0)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 200,   0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(210, 210, 210)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 255, 255)),
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.1),
        NumberSequenceKeypoint.new(0.6, 0.5),
        NumberSequenceKeypoint.new(1,   1.0),
    })
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.6),
        NumberSequenceKeypoint.new(0.4, 0.38),
        NumberSequenceKeypoint.new(1,   0.0),
    })
    pe.Parent = hrp
    table.insert(_flamClean, pe)
end

function FLAM.enable()
    FLAM.Enabled = true
    _setupFlam(_char())
    _conn("FLAM", LP_.CharacterAdded:Connect(function(c)
        task.wait(0.5); if FLAM.Enabled then _setupFlam(c) end
    end))
end

function FLAM.disable()
    FLAM.Enabled = false
    _stop("FLAM")
    for _, o in ipairs(_flamClean) do pcall(function() o:Destroy() end) end
    table.clear(_flamClean)
end

return {
    ESP=ESP, VMR=VMR, NS=NS, HN=HN, BL=BL,
    STD=STD, SHD=SHD, CMV=CMV,
    WINGS=WINGS, AURA=AURA, TRAIL=TRAIL,
    GLOW=GLOW, SPARKLE=SPARKLE, HALO=HALO, FLAM=FLAM,
}
        end)()
    end)
    if not _ok2 then print("[UNCODE v1] Part2 err:"..tostring(_err2)) end
    pcall(collectgarbage,"collect"); task.wait(0.5)
    pcall(collectgarbage,"collect")
    -- ============================================================
    -- [uncode] Chat Spam (from Harion)
    -- ============================================================
    do
    local CSPM = {}
    CSPM.Enabled = false
    CSPM.Interval = 1.5
    CSPM.Mode = "custom"
    CSPM.Custom = "..."
    local _cspmRunning = false
    local _cspmMsgs = {
        smol     = {"tiny wins still count","small text big result","smol but locked in"},
        corny    = {"that round was nacho average duel","you just got served with extra cheese","corny line, clean win"},
        wholesome= {"good fight","nice shot","well played"},
        ["auto ban"]={"ban phase handled","voting the loadout","random ban locked"},
    }
    local function _cspmSend(text)
        text = tostring(text or "")
        if text=="" then return end
        local ok = pcall(function()
            local tcs = cloneref(game:GetService("TextChatService"))
            local chs = tcs:FindFirstChild("TextChannels")
            local ch  = chs and (chs:FindFirstChild("RBXGeneral") or chs:FindFirstChild("RBXSystem"))
            if ch and ch.SendAsync then ch:SendAsync(text) end
        end)
        if not ok then
            pcall(function()
                RS.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text,"All")
            end)
        end
    end
    local function _cspmMsg()
        if CSPM.Mode=="custom" then return CSPM.Custom end
        local list = _cspmMsgs[CSPM.Mode] or {}
        if #list==0 then return CSPM.Custom end
        return list[math.random(1,#list)]
    end
    function CSPM.enable()
        CSPM.Enabled = true
        if not _cspmRunning then
            _cspmRunning = true
            task.spawn(function()
                while CSPM.Enabled do
                    pcall(_cspmSend, _cspmMsg())
                    task.wait(math.max(CSPM.Interval, 0.5))
                end
                _cspmRunning = false
            end)
        end
    end
    function CSPM.disable() CSPM.Enabled = false end
    _UM.CSPM = CSPM
    end

    -- ============================================================
    -- [uncode] Box ESP v2 (コーナーボックス + ヘッドドット + 距離 + スケルトン)
    -- ============================================================
    do
    local DESP = {}
    DESP.Enabled      = false
    DESP.ShowName     = true
    DESP.ShowHealth   = true
    DESP.ShowDist     = true
    DESP.ShowHeadDot  = true
    DESP.CornerStyle  = true   -- true=コーナーボックス / false=フルボックス
    DESP.Color        = Color3.fromRGB(255, 50, 50)
    DESP.NameColor    = Color3.fromRGB(255, 255, 255)
    DESP.CornerLen    = 0.25   -- ボックス辺の何割をコーナーにするか
    local _despConns = {}
    local _despObjs  = {}  -- [Player] = {lines={Line×8}, txt, dist, hdot, hbg, hfg, box}

    local function _despNewLine()
        local l = Drawing.new("Line")
        l.Thickness=1.5; l.Transparency=1; l.ZIndex=5; l.Visible=false
        return l
    end
    local function _despNewSq()
        local s = Drawing.new("Square")
        s.Filled=false; s.Thickness=1.5; s.ZIndex=4; s.Visible=false
        return s
    end
    local function _despNewText(sz)
        local t = Drawing.new("Text")
        t.Size=sz or 13; t.Center=true; t.Outline=true; t.ZIndex=6; t.Visible=false
        return t
    end
    local function _despNewCircle()
        local c = Drawing.new("Circle")
        c.Thickness=1.5; c.NumSides=16; c.Radius=3; c.Filled=true
        c.Transparency=1; c.ZIndex=7; c.Visible=false
        return c
    end
    local function _despNewFilledSq()
        local s = Drawing.new("Square"); s.Filled=true; s.ZIndex=4; s.Visible=false
        return s
    end

    local function _despGetOrCreate(p)
        if _despObjs[p] then return _despObjs[p] end
        local T = {}
        T.lines = {}
        for _ = 1,8 do T.lines[#T.lines+1] = _despNewLine() end
        T.box  = _despNewSq()
        T.txt  = _despNewText(13)
        T.dist = _despNewText(11)
        T.hdot = _despNewCircle()
        T.hbg  = _despNewFilledSq()
        T.hfg  = _despNewFilledSq()
        T.hbg.Color = Color3.fromRGB(0,0,0); T.hbg.Transparency=0.6
        _despObjs[p] = T
        return T
    end

    local function _despHide(T)
        for _,l in ipairs(T.lines) do l.Visible=false end
        T.box.Visible=false; T.txt.Visible=false; T.dist.Visible=false
        T.hdot.Visible=false; T.hbg.Visible=false; T.hfg.Visible=false
    end

    local function _despDrawCorner(lines, bx, by, bw, bh, col, clen)
        -- 8本のLineでコーナーボックスを描く (TL, TR, BL, BR 各2本)
        local cx = clen
        local cy_h = math.floor(bh * cx)
        local cx_w = math.floor(bw * cx)
        -- TL
        lines[1].From=Vector2.new(bx,by);           lines[1].To=Vector2.new(bx+cx_w,by)
        lines[2].From=Vector2.new(bx,by);           lines[2].To=Vector2.new(bx,by+cy_h)
        -- TR
        lines[3].From=Vector2.new(bx+bw,by);        lines[3].To=Vector2.new(bx+bw-cx_w,by)
        lines[4].From=Vector2.new(bx+bw,by);        lines[4].To=Vector2.new(bx+bw,by+cy_h)
        -- BL
        lines[5].From=Vector2.new(bx,by+bh);        lines[5].To=Vector2.new(bx+cx_w,by+bh)
        lines[6].From=Vector2.new(bx,by+bh);        lines[6].To=Vector2.new(bx,by+bh-cy_h)
        -- BR
        lines[7].From=Vector2.new(bx+bw,by+bh);     lines[7].To=Vector2.new(bx+bw-cx_w,by+bh)
        lines[8].From=Vector2.new(bx+bw,by+bh);     lines[8].To=Vector2.new(bx+bw,by+bh-cy_h)
        for _,l in ipairs(lines) do
            l.Color=col; l.Transparency=1; l.Visible=true
        end
    end

    local function _despUpdate()
        if not DESP.Enabled then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local lrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local seen = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            if not hrp or not hum or hum.Health<=0 then
                if _despObjs[p] then _despHide(_despObjs[p]) end
                continue
            end
            local topPos = head and (head.Position+Vector3.new(0,0.75,0)) or (hrp.Position+Vector3.new(0,3.2,0))
            local botPos = hrp.Position - Vector3.new(0,3.2,0)
            local sp1,v1 = cam:WorldToViewportPoint(topPos)
            local sp2,_  = cam:WorldToViewportPoint(botPos)
            if not v1 or sp1.Z<=0 then
                if _despObjs[p] then _despHide(_despObjs[p]) end
                continue
            end
            seen[p]=true
            local T  = _despGetOrCreate(p)
            local col = DESP.Color
            local bh = math.abs(sp2.Y - sp1.Y)
            local bw = math.max(bh * 0.45, 10)
            local cx_scr = (sp1.X+sp2.X)*0.5
            local by = math.min(sp1.Y, sp2.Y)
            local bx = cx_scr - bw*0.5
            -- Box
            if DESP.CornerStyle then
                for _,l in ipairs(T.lines) do l.Visible=false end
                T.box.Visible=false
                _despDrawCorner(T.lines, bx, by, bw, bh, col, DESP.CornerLen)
            else
                for _,l in ipairs(T.lines) do l.Visible=false end
                T.box.Position=Vector2.new(bx,by); T.box.Size=Vector2.new(bw,bh)
                T.box.Color=col; T.box.Transparency=1; T.box.Visible=true
            end
            -- Head dot
            if DESP.ShowHeadDot and head then
                local hsp,hv = cam:WorldToViewportPoint(head.Position)
                if hv and hsp.Z>0 then
                    T.hdot.Position=Vector2.new(hsp.X,hsp.Y)
                    T.hdot.Color=col; T.hdot.Visible=true
                else T.hdot.Visible=false end
            else T.hdot.Visible=false end
            -- Name
            if DESP.ShowName then
                T.txt.Position=Vector2.new(cx_scr, by-15)
                T.txt.Text=p.Name; T.txt.Color=DESP.NameColor; T.txt.Transparency=1; T.txt.Visible=true
            else T.txt.Visible=false end
            -- Distance
            if DESP.ShowDist and lrp then
                local dist = math.floor((hrp.Position-lrp.Position).Magnitude)
                T.dist.Position=Vector2.new(cx_scr, by+bh+2)
                T.dist.Text=tostring(dist).."m"; T.dist.Color=col; T.dist.Transparency=1; T.dist.Visible=true
            else T.dist.Visible=false end
            -- Health bar (left)
            if DESP.ShowHealth then
                local hp = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
                local barH = bh * hp
                local barX = bx - 5
                local hcol = Color3.fromRGB(math.floor((1-hp)*255), math.floor(hp*220), 0)
                T.hbg.Position=Vector2.new(barX-1,by-1); T.hbg.Size=Vector2.new(4,bh+2); T.hbg.Visible=true
                T.hfg.Position=Vector2.new(barX,by+bh-barH); T.hfg.Size=Vector2.new(2,barH)
                T.hfg.Color=hcol; T.hfg.Transparency=1; T.hfg.Filled=true; T.hfg.Visible=true
            else T.hbg.Visible=false; T.hfg.Visible=false end
        end
        for p,T in pairs(_despObjs) do if not seen[p] then _despHide(T) end end
    end

    local function _despClearAll()
        for _,T in pairs(_despObjs) do
            for _,l in ipairs(T.lines) do pcall(function() l:Remove() end) end
            for _,k in ipairs({"box","txt","dist","hdot","hbg","hfg"}) do
                pcall(function() T[k]:Remove() end)
            end
        end
        table.clear(_despObjs)
        for _,c in ipairs(_despConns) do pcall(function() c:Disconnect() end) end
        table.clear(_despConns)
    end

    function DESP.enable()
        DESP.Enabled = true
        _despConns[#_despConns+1] = RunService.RenderStepped:Connect(_despUpdate)
    end
    function DESP.disable()
        DESP.Enabled = false
        _despClearAll()
    end
    _UM.DESP = DESP
    end

    -- ============================================================
    -- [uncode] Tracers v2 (起点選択 + 太さ + 距離フェード)
    -- ============================================================
    do
    local TRAC = {}
    TRAC.Enabled   = false
    TRAC.Color     = Color3.fromRGB(255, 50, 50)
    TRAC.Thickness = 1.5
    TRAC.Origin    = "bottom"  -- "bottom" | "center" | "crosshair"
    TRAC.DistFade  = false     -- 距離が遠いほど透明に
    local _tracConns = {}
    local _tracLines = {}   -- [Player] = Line

    local function _tracGetLine(p)
        if _tracLines[p] then return _tracLines[p] end
        local l = Drawing.new("Line")
        l.Thickness=TRAC.Thickness; l.Transparency=1; l.ZIndex=5; l.Visible=false
        _tracLines[p] = l
        return l
    end

    local function _tracClearAll()
        for _,l in pairs(_tracLines) do pcall(function() l:Remove() end) end
        table.clear(_tracLines)
        for _,c in ipairs(_tracConns) do pcall(function() c:Disconnect() end) end
        table.clear(_tracConns)
    end

    function TRAC.enable()
        TRAC.Enabled = true
        local lrp_cache = nil
        _tracConns[#_tracConns+1] = RunService.RenderStepped:Connect(function()
            if not TRAC.Enabled then return end
            local cam = workspace.CurrentCamera; if not cam then return end
            local vp  = cam.ViewportSize
            local orig
            if TRAC.Origin == "center" then
                orig = Vector2.new(vp.X*0.5, vp.Y*0.5)
            elseif TRAC.Origin == "crosshair" then
                orig = Vector2.new(vp.X*0.5, vp.Y*0.5)
            else
                orig = Vector2.new(vp.X*0.5, vp.Y)
            end
            local lChar = LP.Character
            lrp_cache = lChar and lChar:FindFirstChild("HumanoidRootPart")
            local seen = {}
            for _,p in ipairs(Players:GetPlayers()) do
                if p==LP then continue end
                local char = p.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    if _tracLines[p] then _tracLines[p].Visible=false end
                    continue
                end
                local sp,vis = cam:WorldToViewportPoint(hrp.Position)
                if not vis or sp.Z<=0 then
                    if _tracLines[p] then _tracLines[p].Visible=false end
                    continue
                end
                seen[p]=true
                local line = _tracGetLine(p)
                line.From  = orig
                line.To    = Vector2.new(sp.X, sp.Y)
                line.Color = TRAC.Color
                line.Thickness = TRAC.Thickness
                if TRAC.DistFade and lrp_cache then
                    local dist = (hrp.Position - lrp_cache.Position).Magnitude
                    line.Transparency = math.clamp(1 - dist/200, 0.1, 1)
                else
                    line.Transparency = 1
                end
                line.Visible = true
            end
            for p,l in pairs(_tracLines) do
                if not seen[p] then l.Visible=false end
            end
        end)
    end

    function TRAC.disable()
        TRAC.Enabled = false
        _tracClearAll()
    end
    _UM.TRAC = TRAC
    end

    -- ============================================================
    -- [uncode] FOV Circle v2 (二重リング + 塗り + 透明度)
    -- ============================================================
    do
    local FOVC = {}
    FOVC.Enabled      = false
    FOVC.Radius       = 120
    FOVC.Color        = Color3.fromRGB(255, 255, 255)
    FOVC.Thickness    = 1.5
    FOVC.DoubleRing   = false   -- 外側に薄いリングを追加
    FOVC.RingGap      = 4       -- 二重リングのギャップ
    local _fovcInner  = nil
    local _fovcOuter  = nil
    local _fovcConns  = {}
    local function _fovcMakeCircle(th)
        local c = Drawing.new("Circle")
        c.NumSides=72; c.Filled=false
        c.Thickness=th; c.Transparency=1; c.Visible=false
        return c
    end
    function FOVC.enable()
        FOVC.Enabled = true
        if not _fovcInner then _fovcInner = _fovcMakeCircle(FOVC.Thickness) end
        if not _fovcOuter  then _fovcOuter  = _fovcMakeCircle(1) end
        local cam = workspace.CurrentCamera
        local c = RunService.RenderStepped:Connect(function()
            if not FOVC.Enabled then return end
            local vp  = cam.ViewportSize
            local cen = Vector2.new(vp.X*0.5, vp.Y*0.5)
            _fovcInner.Position    = cen
            _fovcInner.Radius      = FOVC.Radius
            _fovcInner.Color       = FOVC.Color
            _fovcInner.Thickness   = FOVC.Thickness
            _fovcInner.Visible     = true
            if FOVC.DoubleRing then
                _fovcOuter.Position   = cen
                _fovcOuter.Radius     = FOVC.Radius + FOVC.RingGap
                _fovcOuter.Color      = FOVC.Color
                _fovcOuter.Transparency = 0.4
                _fovcOuter.Visible    = true
            else
                _fovcOuter.Visible = false
            end
        end)
        _fovcConns[#_fovcConns+1] = c
    end
    function FOVC.disable()
        FOVC.Enabled = false
        if _fovcInner then _fovcInner.Visible=false end
        if _fovcOuter  then _fovcOuter.Visible=false end
        for _,c in ipairs(_fovcConns) do pcall(function() c:Disconnect() end) end
        _fovcConns = {}
    end
    _UM.FOVC = FOVC
    end

    -- ============================================================
    -- [uncode] Chams v2 (HP連動 + アウトラインのみモード + 自動リフレッシュ)
    -- ============================================================
    do
    local CHMS = {}
    CHMS.Enabled          = false
    CHMS.FillColor        = Color3.fromRGB(255, 50, 50)
    CHMS.OutlineColor     = Color3.fromRGB(255, 255, 255)
    CHMS.FillTransparency = 0.5
    CHMS.ThroughWall      = true
    CHMS.HPTint           = false  -- HPに応じて赤→緑でFillColorを変化
    CHMS.OutlineOnly      = false  -- 塗り無し輪郭のみ
    local _chmsHLs   = {}  -- [Player] = Highlight
    local _chmsConns = {}

    local function _chmsGetHP(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.MaxHealth<=0 then return 1 end
        return math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    end

    local function _chmsApply(p, char)
        local hl = _chmsHLs[p]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Adornee = char; hl.Parent = char
            _chmsHLs[p] = hl
        end
        local hp   = CHMS.HPTint and _chmsGetHP(char) or 1
        local fill = CHMS.HPTint
            and Color3.fromRGB(math.floor((1-hp)*255), math.floor(hp*200), 0)
            or  CHMS.FillColor
        hl.FillColor        = fill
        hl.OutlineColor     = CHMS.OutlineColor
        hl.FillTransparency = CHMS.OutlineOnly and 1 or CHMS.FillTransparency
        hl.DepthMode        = CHMS.ThroughWall
            and Enum.HighlightDepthMode.AlwaysOnTop
            or  Enum.HighlightDepthMode.Occluded
    end

    local function _chmsClean(p)
        if _chmsHLs[p] then
            pcall(function() _chmsHLs[p]:Destroy() end)
            _chmsHLs[p] = nil
        end
    end

    local function _chmsUpdate()
        if not CHMS.Enabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health>0 then
                _chmsApply(p, char)
            else
                _chmsClean(p)
            end
        end
        -- 孤立ハイライトを削除
        for p in pairs(_chmsHLs) do
            if not p.Character then _chmsClean(p) end
        end
    end

    function CHMS.enable()
        CHMS.Enabled = true
        _chmsUpdate()
        -- キャラ変更時に即再適用
        local c1 = Players.PlayerRemoving:Connect(function(p) _chmsClean(p) end)
        local c2 = RunService.Heartbeat:Connect(function()
            if CHMS.Enabled then _chmsUpdate() end
        end)
        _chmsConns[#_chmsConns+1] = c1
        _chmsConns[#_chmsConns+1] = c2
    end

    function CHMS.disable()
        CHMS.Enabled = false
        for p in pairs(_chmsHLs) do _chmsClean(p) end
        for _,c in ipairs(_chmsConns) do pcall(function() c:Disconnect() end) end
        _chmsConns = {}
    end
    _UM.CHMS = CHMS
    end

    -- ============================================================
    -- [uncode] BunnyHop: 着地即ジャンプ
    -- ============================================================
    do
    local BHOP = {}
    BHOP.Enabled = false
    local _bhopConns = {}
    function BHOP.enable()
        BHOP.Enabled = true
        local c = RunService.Heartbeat:Connect(function()
            if not BHOP.Enabled then return end
            local char = LP.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            if hum.Health <= 0 then return end
            if hum.FloorMaterial ~= Enum.Material.Air
            and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end)
        _bhopConns[#_bhopConns+1] = c
    end
    function BHOP.disable()
        BHOP.Enabled = false
        for _, c in ipairs(_bhopConns) do pcall(function() c:Disconnect() end) end
        _bhopConns = {}
    end
    _UM.BHOP = BHOP
    end

    -- ============================================================
    -- [uncode] Infinite Double Jump (from Harion)
    -- ============================================================
    do
    local IJMP = {}
    IJMP.Enabled = false
    local _ijmpConns = {}
    local function _ijmpPatch()
        pcall(function()
            local mech = require(LP.PlayerScripts.Controllers.MechanicsController)
            if not mech or not mech.LocalFighter then return end
            local item = mech.LocalFighter.EquippedItem
            local info = item and item.Info
            if info then
                info.MaxDoubleJumps = math.huge
                local objectId
                pcall(function() objectId = item:Get("ObjectID") end)
                if objectId and mech._double_jumps_used then
                    mech._double_jumps_used[objectId] = 0
                end
            end
        end)
    end
    function IJMP.enable()
        IJMP.Enabled = true
        local c = RunService.Heartbeat:Connect(function()
            if IJMP.Enabled then _ijmpPatch() end
        end)
        _ijmpConns[#_ijmpConns+1] = c
    end
    function IJMP.disable()
        IJMP.Enabled = false
        for _, c in ipairs(_ijmpConns) do pcall(function() c:Disconnect() end) end
        _ijmpConns = {}
    end
    _UM.IJMP = IJMP
    end

    do -- [uncode] Auto Ban v1 (Harion互換: Duels.Vote:FireServer(weapon))
    local AUBA = {}
    AUBA.Enabled = false; AUBA.Slot1 = "None"; AUBA.Slot2 = "None"; AUBA.Delay = 1.0
    local _aubaLoop = false; local _aubaRemote = nil
    local function _aubaGetRemote()
        if _aubaRemote and _aubaRemote.Parent then return _aubaRemote end
        pcall(function()
            local rs = cloneref(game:GetService("ReplicatedStorage"))
            local r = rs:FindFirstChild("Remotes")
            r = r and r:FindFirstChild("Duels")
            r = r and r:FindFirstChild("Vote")
            if r then _aubaRemote = r end
        end)
        return _aubaRemote
    end
    local function _aubaFire(name)
        if not name or name == "None" or name == "" then return end
        pcall(function() local r = _aubaGetRemote(); if r then r:FireServer(name) end end)
    end
    function AUBA.enable()
        AUBA.Enabled = true
        if not _aubaLoop then
            _aubaLoop = true
            task.spawn(function()
                while AUBA.Enabled do
                    _aubaFire(AUBA.Slot1)
                    task.wait(math.max(AUBA.Delay * 0.5, 0.1))
                    if not AUBA.Enabled then break end
                    _aubaFire(AUBA.Slot2)
                    task.wait(math.max(AUBA.Delay * 0.5, 0.1))
                end
                _aubaLoop = false
            end)
        end
    end
    function AUBA.disable() AUBA.Enabled = false end
    _UM.AUBA = AUBA
    end -- AUBA

    do -- [uncode] Auto Respawn v1 (Harion互換: Duels.RespawnNow:FireServer())
    local ARSP = {}
    ARSP.Enabled = false
    local _arspConns = {}
    local function _arspClear()
        for _, c in ipairs(_arspConns) do pcall(function() c:Disconnect() end) end
        _arspConns = {}
    end
    local function _arspGetRemote()
        local rs = cloneref(game:GetService("ReplicatedStorage"))
        local r = rs:FindFirstChild("Remotes")
        r = r and r:FindFirstChild("Duels")
        return r and r:FindFirstChild("RespawnNow")
    end
    local function _arspSetup(char)
        if not ARSP.Enabled or not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local c = hum.Died:Connect(function()
            if not ARSP.Enabled then return end
            task.wait(0.1)
            pcall(function() local rem = _arspGetRemote(); if rem then rem:FireServer() end end)
        end)
        _arspConns[#_arspConns+1] = c
    end
    function ARSP.enable()
        ARSP.Enabled = true
        _arspClear()
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        _arspSetup(lp.Character)
        local c = lp.CharacterAdded:Connect(function(char) task.wait(0.2); _arspSetup(char) end)
        _arspConns[#_arspConns+1] = c
    end
    function ARSP.disable() ARSP.Enabled = false; _arspClear() end
    _UM.ARSP = ARSP
    end -- ARSP

    do -- [uncode] Device Spoofer v1 (Harion互換: Fighter.SetControls:FireServer(mode))
    local DVSP = {}
    DVSP.Enabled = false; DVSP.Mode = "Touch"
    local _dvspConns = {}
    local function _dvspFire()
        pcall(function()
            local rs = cloneref(game:GetService("ReplicatedStorage"))
            local r = rs:FindFirstChild("Remotes")
            r = r and r:FindFirstChild("Replication")
            r = r and r:FindFirstChild("Fighter")
            r = r and r:FindFirstChild("SetControls")
            if r then r:FireServer(DVSP.Mode) end
        end)
    end
    function DVSP.enable()
        DVSP.Enabled = true
        _dvspFire()
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local c = lp.CharacterAdded:Connect(function()
            if not DVSP.Enabled then return end
            task.wait(0.5); _dvspFire()
        end)
        _dvspConns[#_dvspConns+1] = c
    end
    function DVSP.disable()
        DVSP.Enabled = false
        for _, c in ipairs(_dvspConns) do pcall(function() c:Disconnect() end) end
        _dvspConns = {}
    end
    _UM.DVSP = DVSP
    end -- DVSP

    do -- [uncode] Collect Drops v1 (Harion互換: firetouchinterest on _drop parts)
    local CDROP = {}
    CDROP.Enabled = false
    local _cdropConns = {}; local _cdropTracked = {}
    local function _cdropTrack(obj)
        if obj.Name == "_drop" and obj:IsA("BasePart") then _cdropTracked[obj] = true end
    end
    local function _cdropUntrack(obj) _cdropTracked[obj] = nil end
    function CDROP.enable()
        CDROP.Enabled = true
        _cdropTracked = {}
        pcall(function() for _, obj in ipairs(workspace:GetChildren()) do _cdropTrack(obj) end end)
        local c1 = workspace.ChildAdded:Connect(_cdropTrack)
        local c2 = workspace.ChildRemoved:Connect(_cdropUntrack)
        _cdropConns[#_cdropConns+1] = c1; _cdropConns[#_cdropConns+1] = c2
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local _next = 0
        local c3 = RunService.Heartbeat:Connect(function()
            if not CDROP.Enabled then return end
            local now = os.clock(); if now < _next then return end
            _next = now + 0.2
            local char = lp.Character; if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local needHP = hum and hum.Health < hum.MaxHealth
            for obj in next, _cdropTracked do
                if not obj.Parent then
                    _cdropTracked[obj] = nil
                else
                    local isAmmo   = obj:FindFirstChild("Ammo")   ~= nil
                    local isHealth = obj:FindFirstChild("Health")  ~= nil
                    if isAmmo or (isHealth and needHP) then
                        pcall(function() firetouchinterest(hrp, obj, 0) end)
                        pcall(function() firetouchinterest(hrp, obj, 1) end)
                    end
                end
            end
        end)
        _cdropConns[#_cdropConns+1] = c3
    end
    function CDROP.disable()
        CDROP.Enabled = false
        for _, c in ipairs(_cdropConns) do pcall(function() c:Disconnect() end) end
        _cdropConns = {}; _cdropTracked = {}
    end
    _UM.CDROP = CDROP
    end -- CDROP

    do -- [uncode] Custom Crosshair v2 (スタイル選択 + センタードット + アウトライン + 動的展開)
    local CXHR = {}
    CXHR.Enabled   = false
    CXHR.Size      = 12
    CXHR.Gap       = 4
    CXHR.Thickness = 2
    CXHR.Color     = Color3.fromRGB(255, 255, 255)
    CXHR.OutlineColor = Color3.fromRGB(0, 0, 0)
    CXHR.Outline   = true    -- 黒縁
    CXHR.CenterDot = true    -- 中心ドット
    CXHR.TStyle    = false   -- T字型 (上線なし)
    CXHR.Dynamic   = false   -- 移動で展開
    local _cxhrLines = {}    -- 4 inner + 4 outline + 2 center dot
    local _cxhrConns = {}
    local function _cxhrMakeLine(th, zi)
        local l = Drawing.new("Line")
        l.Thickness=th; l.ZIndex=zi or 8; l.Transparency=1; l.Visible=false
        return l
    end
    local function _cxhrMakeDot(col, r)
        local d = Drawing.new("Circle")
        d.NumSides=12; d.Filled=true; d.Radius=r or 2.5
        d.Color=col; d.Transparency=1; d.ZIndex=9; d.Visible=false
        return d
    end
    local function _cxhrInit()
        if #_cxhrLines > 0 then return end
        for _ = 1, 4 do _cxhrLines[#_cxhrLines+1] = _cxhrMakeLine(CXHR.Thickness+2, 7) end  -- outline
        for _ = 1, 4 do _cxhrLines[#_cxhrLines+1] = _cxhrMakeLine(CXHR.Thickness, 8) end     -- inner
        _cxhrLines[9]  = _cxhrMakeDot(Color3.fromRGB(0,0,0), 3.5)  -- dot outline
        _cxhrLines[10] = _cxhrMakeDot(CXHR.Color, 2.5)              -- dot fill
    end
    local function _cxhrDynGap(cam)
        if not CXHR.Dynamic then return CXHR.Gap end
        local char = LP.Character; if not char then return CXHR.Gap end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return CXHR.Gap end
        local vel  = hrp.AssemblyLinearVelocity
        local speed = Vector3.new(vel.X,0,vel.Z).Magnitude
        return CXHR.Gap + math.clamp(speed*0.15, 0, 20)
    end
    local function _cxhrSet(l, from, to, col, th)
        l.From=from; l.To=to; l.Color=col; l.Thickness=th; l.Visible=true
    end
    local function _cxhrDraw(vp)
        local cx = vp.X*0.5; local cy = vp.Y*0.5
        local s  = CXHR.Size; local g = _cxhrDynGap(nil)
        local col = CXHR.Color; local oc = CXHR.OutlineColor
        local th  = CXHR.Thickness; local oth = th+2
        -- 4方向の From/To (left, right, top, bottom)
        local pts = {
            {Vector2.new(cx-g-s,cy), Vector2.new(cx-g,cy)},   -- L
            {Vector2.new(cx+g,cy),   Vector2.new(cx+g+s,cy)},  -- R
            {Vector2.new(cx,cy-g-s), Vector2.new(cx,cy-g)},    -- U
            {Vector2.new(cx,cy+g),   Vector2.new(cx,cy+g+s)},  -- D
        }
        for i=1,4 do
            local skip = CXHR.TStyle and i==3  -- T字型=上線を消す
            local ol = _cxhrLines[i]; local il = _cxhrLines[i+4]
            if skip then ol.Visible=false; il.Visible=false; continue end
            if CXHR.Outline then _cxhrSet(ol, pts[i][1], pts[i][2], oc, oth)
            else ol.Visible=false end
            _cxhrSet(il, pts[i][1], pts[i][2], col, th)
        end
        -- center dot
        local cen = Vector2.new(cx,cy)
        if CXHR.CenterDot then
            _cxhrLines[9].Position=cen;  _cxhrLines[9].Color=oc;  _cxhrLines[9].Visible=CXHR.Outline
            _cxhrLines[10].Position=cen; _cxhrLines[10].Color=col; _cxhrLines[10].Visible=true
        else
            _cxhrLines[9].Visible=false; _cxhrLines[10].Visible=false
        end
    end
    function CXHR.enable()
        CXHR.Enabled = true
        _cxhrInit()
        local cam = workspace.CurrentCamera
        local c = RunService.RenderStepped:Connect(function()
            if not CXHR.Enabled then return end
            _cxhrDraw(cam.ViewportSize)
        end)
        _cxhrConns[#_cxhrConns+1] = c
    end
    function CXHR.disable()
        CXHR.Enabled = false
        for _, obj in ipairs(_cxhrLines) do pcall(function() obj.Visible=false end) end
        for _, c in ipairs(_cxhrConns) do pcall(function() c:Disconnect() end) end
        _cxhrConns = {}
    end
    _UM.CXHR = CXHR
    end -- CXHR

    do -- [uncode] Disable Viewmodel v1 (LocalTransparencyModifier)
    local DVM = {}
    DVM.Enabled = false
    local _dvmConns = {}
    local function _dvmHide()
        pcall(function()
            local cam = workspace.CurrentCamera
            for _, v in ipairs(cam:GetChildren()) do
                if v:IsA("Model") then
                    for _, p in ipairs(v:GetDescendants()) do
                        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
                    end
                end
            end
        end)
    end
    local function _dvmRestore()
        pcall(function()
            local cam = workspace.CurrentCamera
            for _, v in ipairs(cam:GetChildren()) do
                if v:IsA("Model") then
                    for _, p in ipairs(v:GetDescendants()) do
                        if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
                    end
                end
            end
        end)
    end
    function DVM.enable()
        DVM.Enabled = true
        _dvmHide()
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local c1 = lp.CharacterAdded:Connect(function()
            task.wait(0.5); if DVM.Enabled then _dvmHide() end
        end)
        local cam = workspace.CurrentCamera
        local c2  = cam.ChildAdded:Connect(function()
            task.wait(0.2); if DVM.Enabled then _dvmHide() end
        end)
        _dvmConns[#_dvmConns+1] = c1; _dvmConns[#_dvmConns+1] = c2
    end
    function DVM.disable()
        DVM.Enabled = false
        for _, c in ipairs(_dvmConns) do pcall(function() c:Disconnect() end) end
        _dvmConns = {}; _dvmRestore()
    end
    _UM.DVM = DVM
    end -- DVM

    do -- [uncode] Remove Vignette v1 (PlayerGui内vignetteを非表示)
    local NOVIG = {}
    NOVIG.Enabled = false
    local _novigConns = {}; local _novigHidden = {}
    local function _novigApply(gui)
        local n = gui.Name:lower()
        if not (n:find("vignette") or n:find("vig") or n:find("blood") or n:find("overlay")) then return end
        if _novigHidden[gui] ~= nil then return end
        if gui:IsA("ScreenGui") then
            _novigHidden[gui] = gui.Enabled; gui.Enabled = false
        elseif gui:IsA("GuiObject") then
            _novigHidden[gui] = gui.Visible; gui.Visible = false
        end
    end
    local function _novigScan()
        pcall(function()
            local lp = cloneref(game:GetService("Players")).LocalPlayer
            local pg = lp:FindFirstChildOfClass("PlayerGui"); if not pg then return end
            for _, d in ipairs(pg:GetDescendants()) do _novigApply(d) end
        end)
    end
    local function _novigRestore()
        for obj, val in pairs(_novigHidden) do
            pcall(function()
                if obj:IsA("ScreenGui") then obj.Enabled = val
                elseif obj:IsA("GuiObject") then obj.Visible = val end
            end)
        end
        _novigHidden = {}
    end
    function NOVIG.enable()
        NOVIG.Enabled = true
        _novigScan()
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            local c = pg.DescendantAdded:Connect(function(obj)
                if not NOVIG.Enabled then return end
                task.wait(0.1); _novigApply(obj)
            end)
            _novigConns[#_novigConns+1] = c
        end
    end
    function NOVIG.disable()
        NOVIG.Enabled = false
        for _, c in ipairs(_novigConns) do pcall(function() c:Disconnect() end) end
        _novigConns = {}; _novigRestore()
    end
    _UM.NOVIG = NOVIG
    end -- NOVIG

    -- Part3: Movement features (FLY, PH, TP3, FC, SB, ANT, AJ, TGS, ORB)
    -- _E1のローカル変数200上限対策として分離
    local _E3; local _ok3,_err3 = pcall(function()
        _E3 = (function()
local PL_3 = cloneref(game:GetService("Players"))
local RN_3 = game:GetService("RunService")
local UI_3 = game:GetService("UserInputService")
local LP_3 = PL_3.LocalPlayer
local WS_3 = workspace
local _pool3 = {}
local function _conn(key,c) if not _pool3[key] then _pool3[key]={} end table.insert(_pool3[key],c); return c end
local function _stop(key) for _,c in ipairs(_pool3[key] or {}) do pcall(function() c:Disconnect() end) end _pool3[key]={} end
local function _char() return LP_3.Character end
local function _root() local c=_char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function _hum() local c=_char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function _alive() local c=_char(); local h=c and c:FindFirstChildOfClass("Humanoid"); return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")~=nil end
local function _closestEnemy(fov)
    fov=fov or 9999
    local cam=WS_3.CurrentCamera
    local center=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    local best,bestD=nil,fov
    for _,p in ipairs(PL_3:GetPlayers()) do
        if p~=LP_3 and p.Character then
            local hrp=p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sp,vis=cam:WorldToViewportPoint(hrp.Position)
                if vis then local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude; if d<bestD then bestD=d;best=p end end
            end
        end
    end
    return best
end

local FLY = {}
FLY.Enabled = false
FLY.Speed   = 60
local _flyGyro, _flyVel
local _fw, _fb, _fl, _fr, _fu, _fd = 0,0,0,0,0,0

local function _flyClean()
    pcall(function() if _flyGyro then _flyGyro:Destroy() end end)
    pcall(function() if _flyVel  then _flyVel:Destroy()  end end)
    _flyGyro, _flyVel = nil, nil
    _fw,_fb,_fl,_fr,_fu,_fd = 0,0,0,0,0,0
    pcall(function()
        local h = _hum(); if h then h.PlatformStand = false end
        WS_3.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
end

local function _flyStart()
    _flyClean()
    if not _alive() then return end
    local root = _root(); if not root then return end
    _flyGyro = Instance.new("BodyGyro")
    _flyGyro.P = 9e4; _flyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
    _flyGyro.CFrame = root.CFrame; _flyGyro.Parent = root
    _flyVel = Instance.new("BodyVelocity")
    _flyVel.MaxForce = Vector3.new(9e9,9e9,9e9); _flyVel.Velocity = Vector3.zero
    _flyVel.Parent = root
    local h = _hum(); if h then h.PlatformStand = true end
end

local function _flyKey(inp, on)
    if UI_3:GetFocusedTextBox() then return end
    local k = inp.KeyCode
    if     k==Enum.KeyCode.W then _fw = on and 1 or 0
    elseif k==Enum.KeyCode.S then _fb = on and 1 or 0
    elseif k==Enum.KeyCode.A then _fl = on and 1 or 0
    elseif k==Enum.KeyCode.D then _fr = on and 1 or 0
    elseif k==Enum.KeyCode.Space or k==Enum.KeyCode.E then _fu = on and 1 or 0
    elseif k==Enum.KeyCode.LeftControl or k==Enum.KeyCode.Q then _fd = on and 1 or 0
    end
end

function FLY.enable()
    FLY.Enabled = true
    _flyStart()
    _conn("FLY", UI_3.InputBegan:Connect(function(i,p) if not p then _flyKey(i,true) end end))
    _conn("FLY", UI_3.InputEnded:Connect( function(i)  _flyKey(i,false) end))
    _conn("FLY", LP_3.CharacterAdded:Connect(function()
        task.wait(0.25); if FLY.Enabled then _flyStart() end
    end))
    _conn("FLY", RN_3.RenderStepped:Connect(function()
        if not _alive() then return end
        if not _flyGyro or not _flyVel or not _flyGyro.Parent then _flyStart(); return end
        local cam = WS_3.CurrentCamera
        local h = _hum(); if h then h.PlatformStand = true end
        pcall(function() cam.CameraType = Enum.CameraType.Track end)
        _flyGyro.CFrame = cam.CFrame
        local mv = (cam.CFrame.LookVector*(_fw-_fb))
                 + (cam.CFrame.RightVector*(_fr-_fl))
                 + (cam.CFrame.UpVector   *(_fu-_fd))
        _flyVel.Velocity = mv.Magnitude > 0 and (mv.Unit * FLY.Speed) or Vector3.zero
    end))
end

function FLY.disable()
    FLY.Enabled = false
    _stop("FLY")
    _flyClean()
end

local PH = {}
PH.Enabled = false
local _phModified = {}

function PH.enable()
    PH.Enabled = true
    _conn("PH", RN_3.Stepped:Connect(function()
        if not PH.Enabled then return end
        local c = _char()
        if not c then table.clear(_phModified); return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false; _phModified[p] = true
            end
        end
    end))
end

function PH.disable()
    PH.Enabled = false
    _stop("PH")
    for p in pairs(_phModified) do
        pcall(function() p.CanCollide = true end)
    end
    table.clear(_phModified)
end

local TP3 = {}
TP3.Enabled  = false
TP3.Distance = 8

function TP3.enable()
    TP3.Enabled = true
    _conn("TP3", RN_3.RenderStepped:Connect(function()
        if not TP3.Enabled then return end
        local cam = WS_3.CurrentCamera
        if not _root() then return end
        pcall(function()
            cam.CameraType = Enum.CameraType.Custom
            local cf   = cam.CFrame
            local back = cf.LookVector * -TP3.Distance
            cam.CFrame = CFrame.new(cf.Position + back, cf.Position + back + cf.LookVector)
        end)
    end))
end

function TP3.disable()
    TP3.Enabled = false
    _stop("TP3")
    pcall(function() WS_3.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local FC = {}
FC.Enabled = false
FC.Speed   = 40
local _fcPart
local _ffw,_ffb,_ffl,_ffr,_ffu,_ffd = 0,0,0,0,0,0

function FC.enable()
    FC.Enabled = true
    local cam = WS_3.CurrentCamera
    _fcPart = Instance.new("Part")
    _fcPart.Anchored = true; _fcPart.CanCollide = false
    _fcPart.Transparency = 1; _fcPart.Size = Vector3.new(0.1,0.1,0.1)
    _fcPart.CFrame = cam.CFrame; _fcPart.Parent = WS_3
    pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    _conn("FC", UI_3.InputBegan:Connect(function(i,p)
        if p then return end
        local k = i.KeyCode
        if k==Enum.KeyCode.W then _ffw=1
        elseif k==Enum.KeyCode.S then _ffb=1
        elseif k==Enum.KeyCode.A then _ffl=1
        elseif k==Enum.KeyCode.D then _ffr=1
        elseif k==Enum.KeyCode.E or k==Enum.KeyCode.Space then _ffu=1
        elseif k==Enum.KeyCode.Q or k==Enum.KeyCode.LeftControl then _ffd=1
        end
    end))
    _conn("FC", UI_3.InputEnded:Connect(function(i)
        local k = i.KeyCode
        if k==Enum.KeyCode.W then _ffw=0
        elseif k==Enum.KeyCode.S then _ffb=0
        elseif k==Enum.KeyCode.A then _ffl=0
        elseif k==Enum.KeyCode.D then _ffr=0
        elseif k==Enum.KeyCode.E or k==Enum.KeyCode.Space then _ffu=0
        elseif k==Enum.KeyCode.Q or k==Enum.KeyCode.LeftControl then _ffd=0
        end
    end))
    _conn("FC", RN_3.RenderStepped:Connect(function()
        if not FC.Enabled or not _fcPart then return end
        local cf = cam.CFrame
        local mv = (cf.LookVector*(_ffw-_ffb))+(cf.RightVector*(_ffr-_ffl))+(cf.UpVector*(_ffu-_ffd))
        pcall(function()
            _fcPart.CFrame = CFrame.new(
                _fcPart.CFrame.Position + (mv.Magnitude>0 and mv.Unit*FC.Speed*0.016 or Vector3.zero),
                _fcPart.CFrame.Position + (mv.Magnitude>0 and mv.Unit*FC.Speed*0.016 or Vector3.zero) + cf.LookVector
            )
            cam.CFrame = CFrame.new(_fcPart.CFrame.Position, _fcPart.CFrame.Position + cf.LookVector)
        end)
    end))
end

function FC.disable()
    FC.Enabled = false
    _stop("FC")
    pcall(function() if _fcPart then _fcPart:Destroy() end end)
    _fcPart = nil
    _ffw,_ffb,_ffl,_ffr,_ffu,_ffd = 0,0,0,0,0,0
    pcall(function() WS_3.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local SB = {}
SB.Enabled = false
SB.Speed   = 10

function SB.enable()
    SB.Enabled = true
    local ang = 0
    _conn("SB", RN_3.RenderStepped:Connect(function(dt)
        if not SB.Enabled then return end
        local root = _root(); if not root then return end
        ang = (ang + SB.Speed * dt * 360) % 360
        pcall(function()
            local cf = root.CFrame
            root.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(ang), 0)
        end)
    end))
end

function SB.disable()
    SB.Enabled = false
    _stop("SB")
end

local ANT = {}
ANT.Enabled = false
ANT.Jitter  = 180

function ANT.enable()
    ANT.Enabled = true
    _conn("ANT", RN_3.RenderStepped:Connect(function()
        if not ANT.Enabled then return end
        local root = _root(); if not root then return end
        pcall(function()
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(ANT.Jitter), 0)
        end)
    end))
end

function ANT.disable()
    ANT.Enabled = false
    _stop("ANT")
end

local AJ = {}
AJ.Enabled = false
local _ajUsed = false

function AJ.enable()
    AJ.Enabled = true
    _conn("AJ", UI_3.InputBegan:Connect(function(i, p)
        if p or not AJ.Enabled then return end
        if i.KeyCode ~= Enum.KeyCode.Space then return end
        local h = _hum(); if not h then return end
        local state = h:GetState()
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
            if not _ajUsed then
                _ajUsed = true
                local root = _root()
                if root then
                    local vel = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, 50, vel.Z)
                end
            end
        else
            _ajUsed = false
        end
    end))
    _conn("AJ", LP_3.CharacterAdded:Connect(function() _ajUsed = false end))
end

function AJ.disable()
    AJ.Enabled = false
    _stop("AJ")
    _ajUsed = false
end

local TGS = {}
TGS.Enabled = false
TGS.Speed   = 3
TGS.Radius  = 12
local _tgsAngle = 0

function TGS.enable()
    TGS.Enabled = true
    _conn("TGS", RN_3.Heartbeat:Connect(function(dt)
        if not TGS.Enabled then return end
        local root = _root(); if not root then return end
        local enemy = _closestEnemy(800)
        if not enemy or not enemy.Character then return end
        local eHRP = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eHRP then return end
        _tgsAngle = _tgsAngle + TGS.Speed * dt
        local offset = Vector3.new(math.cos(_tgsAngle)*TGS.Radius, 0, math.sin(_tgsAngle)*TGS.Radius)
        pcall(function() root.CFrame = CFrame.new(eHRP.Position + offset, eHRP.Position) end)
    end))
end

function TGS.disable()
    TGS.Enabled = false
    _stop("TGS")
end

local ORB = {}
ORB.Enabled = false
ORB.Speed   = 2
ORB.Radius  = 20
ORB.YOffset = 3
local _orbAngle = 0

function ORB.enable()
    ORB.Enabled = true
    _conn("ORB", RN_3.Heartbeat:Connect(function(dt)
        if not ORB.Enabled then return end
        local root = _root(); if not root then return end
        local enemy = _closestEnemy(9999)
        if not enemy or not enemy.Character then return end
        local eHRP = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eHRP then return end
        _orbAngle = _orbAngle + ORB.Speed * dt
        local ePos = eHRP.Position
        local offset = Vector3.new(math.cos(_orbAngle)*ORB.Radius, ORB.YOffset, math.sin(_orbAngle)*ORB.Radius)
        pcall(function() root.CFrame = CFrame.new(ePos + offset, ePos) end)
    end))
end

function ORB.disable()
    ORB.Enabled = false
    _stop("ORB")
end

return {FLY=FLY,PH=PH,TP3=TP3,FC=FC,SB=SB,ANT=ANT,AJ=AJ,TGS=TGS,ORB=ORB}
        end)()
    end)
    if not _ok3 then print("[UNCODE v1] Part3 err:"..tostring(_err3)) end
    pcall(collectgarbage,"collect"); task.wait(0.5)
    pcall(collectgarbage,"collect")
    -- 全パーツを統合して _UCEngine を完成
    _UCEngine = {}
    if _E1 then for k,v in pairs(_E1) do _UCEngine[k]=v end end
    if _E2 then for k,v in pairs(_E2) do _UCEngine[k]=v end end
    if _E3 then for k,v in pairs(_E3) do _UCEngine[k]=v end end
    print("[UNCODE v1] Feature engine ready (" .. tostring(_UCEngine ~= nil) .. ")")
    pcall(collectgarbage,"collect"); task.wait(0.3)

    pcall(function()
        local E = _UCEngine
    if not E then return end
    local B = _ucBoxes

    -- 外側スコープ用コネクション管理 (_conn/_stopはIIFE内のみ有効)
    local _ucx_c = {}
    local function _ucx_conn(k, c)
        if _ucx_c[k] then pcall(function() _ucx_c[k]:Disconnect() end) end
        _ucx_c[k] = c
    end
    local function _ucx_stop(k)
        if _ucx_c[k] then pcall(function() _ucx_c[k]:Disconnect() end) end
        _ucx_c[k] = nil
    end

    -- _UM モジュールのローカルエイリアス (do-endブロック外から参照するため)
    local CS     = _UM.CS;    local AQ    = _UM.AQ;    local ANIM   = _UM.ANIM
    local DESYNC = _UM.DESYNC; local VFXCFG= _UM.VFXCFG
    local RSAI   = _UM.RSAI;  local PTP   = _UM.PTP;   local AKT    = _UM.AKT
    local HESP   = _UM.HESP;  local OAPP  = _UM.OAPP;  local XRAY   = _UM.XRAY
    local ATMO   = _UM.ATMO;  local LGHT  = _UM.LGHT;  local WFOV   = _UM.WFOV
    local WPK    = _UM.WPK;   local WPNM  = _UM.WPNM   -- 新規: 武器ピック / 武器MOD
    local CSPM   = _UM.CSPM;  local DESP  = _UM.DESP;  local TRAC  = _UM.TRAC
    local FOVC   = _UM.FOVC;  local CHMS  = _UM.CHMS
    local BHOP   = _UM.BHOP;  local IJMP  = _UM.IJMP
    local AUBA   = _UM.AUBA;  local ARSP  = _UM.ARSP;  local DVSP  = _UM.DVSP
    local CDROP  = _UM.CDROP; local CXHR  = _UM.CXHR;  local DVM   = _UM.DVM
    local NOVIG  = _UM.NOVIG
    -- VFX内部ヘルパーのエイリアス
    local _vfxCC       = VFXCFG and VFXCFG.applyCC
    local _vfxBloom    = VFXCFG and VFXCFG.applyBloom
    local _vfxSunRays  = VFXCFG and VFXCFG.applySunRays
    local _atmoApply   = ATMO  and ATMO._apply
    local _lghtApply   = LGHT  and LGHT._apply

    task.wait()

    pcall(function()
        -- Wire KX_On → E.KA (old KX aimbot loop removed)
        if Toggles.KX_On then
            local _origKX = Toggles.KX_On.Callback
            Toggles.KX_On.Callback = function(v)
                if v then E.KA.enable() else E.KA.disable() end
                if _origKX then pcall(_origKX, v) end
            end
        end
        -- Wire RB_On → E.KA + E.AutoShoot (old ragebot loop removed)
        if Toggles.RB_On then
            local _origRB = Toggles.RB_On.Callback
            Toggles.RB_On.Callback = function(v)
                if v then E.KA.enable(); E.AutoShoot.enable() else E.KA.disable(); E.AutoShoot.disable() end
                if _origRB then pcall(_origRB, v) end
            end
        end
        if Toggles.KX_Silent then
            local _orig = Toggles.KX_Silent.Callback
            Toggles.KX_Silent.Callback = function(v)
                if v then E.SilentShot.enable() else E.SilentShot.disable() end
                if _orig then pcall(_orig, v) end
            end
        end
        if not B.combatKX then return end
        BT(B.combatKX,"UC_AimSmooth","Aim Smooth",   false,function(v) if v then E.AimSmooth.enable() else E.AimSmooth.disable() end end)
        BT(B.combatKX,"UC_AutoShoot","Rage",false,function(v) if v then E.AutoShoot.enable() else E.AutoShoot.disable() end end)
        B.combatKX:AddSlider("UC_AS_Hide",{Text="Hide (ms)",Default=180,Min=50,Max=2000,Rounding=0,
            Callback=function(v) if E.AutoShoot then E.AutoShoot.Delay=v/1000 end end})
        B.combatKX:AddSlider("UC_AS_Atk",{Text="Attack (ms)",Default=0,Min=0,Max=500,Rounding=0,
            Callback=function(v) if E.AutoShoot then E.AutoShoot.AttackDuration=v/1000 end end})
        BT(B.combatKX,"UC_KA",       "Kill Aura",    false,function(v) if v then E.KA.enable()        else E.KA.disable()        end end)
        BT(B.combatKX,"UC_AP",       "Auto Parry",   false,function(v) if v then E.AP.enable()        else E.AP.disable()        end end)
        B.combatKX:AddDivider()
        BT(B.combatKX,"UC_MaxMode",  "Max Mode",     false,function(v) if v then E.MaxMode.enable()   else E.MaxMode.disable()   end end)
        -- Triggerbot
        B.combatKX:AddDivider()
        BT(B.combatKX,"UC_TRIG","Triggerbot",false,function(v)
            if v then E.TRIG.enable() else E.TRIG.disable() end
        end)
        B.combatKX:AddSlider("UC_TRIG_RT",{Text="Reaction (ms)",Default=100,Min=0,Max=300,Rounding=0,
            Callback=function(v) E.TRIG.ReactionTime=v end})
        B.combatKX:AddSlider("UC_TRIG_FT",{Text="Forget Time (s)",Default=5,Min=0,Max=100,Rounding=0,
            Callback=function(v) E.TRIG.ForgetTime=v/10 end})
        B.combatKX:AddSlider("UC_TRIG_MD",{Text="Max Distance",Default=150,Min=25,Max=500,Rounding=0,
            Callback=function(v) E.TRIG.MaxDistance=v end})
        -- Weapon Mods
        B.combatKX:AddDivider()
        BT(B.combatKX,"UC_WPNM_NS","No Spread",      false,function(v) if WPNM then WPNM.NoSpread=v; if v and not WPNM.Enabled then WPNM.enable() end end end)
        BT(B.combatKX,"UC_WPNM_FS","Fast Shoot",     false,function(v) if WPNM then WPNM.FastShoot=v; if v and not WPNM.Enabled then WPNM.enable() end end end)
        BT(B.combatKX,"UC_WPNM_FP","Fast Projectile",false,function(v) if WPNM then WPNM.FastProjectile=v; if v and not WPNM.Enabled then WPNM.enable() end end end)
        BT(B.combatKX,"UC_WPNM_FA","Full Auto",      false,function(v) if WPNM then WPNM.FullAuto=v; if v and not WPNM.Enabled then WPNM.enable() end end end)
        B.combatKX:AddSlider("UC_WPNM_FR",{Text="Fire Rate %",Default=100,Min=1,Max=100,Rounding=0,
            Callback=function(v) if WPNM then WPNM.FireRate=v; if WPNM.Enabled then pcall(function() end) end end end})
    end)


    task.wait()

    pcall(function()
        if not B.aaLeft then return end
        B.aaLeft:AddDivider()
        BT(B.aaLeft,"UC_ANT","Yaw Flip",  false,function(v) if v then E.ANT.enable() else E.ANT.disable() end end)
        BT(B.aaLeft,"UC_SB", "Spin Bot",  false,function(v) if v then E.SB.enable()  else E.SB.disable()  end end)
    end)

    task.wait()

    pcall(function()
        if not B.orbitLeft then return end
        B.orbitLeft:AddDivider()
        BT(B.orbitLeft,"UC_ORB","Orbit Enemy",   false,function(v) if v then E.ORB.enable() else E.ORB.disable() end end)
        BT(B.orbitLeft,"UC_TGS","Target Strafe", false,function(v) if v then E.TGS.enable() else E.TGS.disable() end end)
    end)

    task.wait()

    pcall(function()
        if not B.visLeft then return end
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_SKIN","Skin Changer",false,function(v)
            if v then E.SkinSwap.enable() else E.SkinSwap.disable() end
        end)
        B.visLeft:AddDropdown("UC_SK_PRESET",{
            Text="Skin Preset",
            Default="neon_red",
            Values={"neon_red","neon_blue","neon_green","chrome","gold","rainbow",
                    "void","ice","lava","holographic","white","black","pink"},
            Callback=function(v)
                E.SkinSwap.Preset = v
                if E.SkinSwap.Enabled then
                    -- table.clear(_skinOrig) → done inside enable()
                    E.SkinSwap.enable()
                end
            end
        })
    end)

    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_ESP","Player ESP",      false,function(v) if v then E.ESP.enable()  else E.ESP.disable()  end end)
        BT(B.visRight,"UC_TP3","Third Person",    false,function(v) if v then E.TP3.enable()  else E.TP3.disable()  end end)
        BT(B.visRight,"UC_FC", "Freecam",         false,function(v) if v then E.FC.enable()   else E.FC.disable()   end end)
        BT(B.visRight,"UC_VMR","Hide Viewmodel",  false,function(v) if v then E.VMR.enable()  else E.VMR.disable()  end end)
        BT(B.visRight,"UC_SHD","Night Shader",    false,function(v) if v then E.SHD.enable()  else E.SHD.disable()  end end)
        B.visRight:AddDivider()
        BT(B.visRight,"UC_WINGS",  "Wings",       false,function(v) if v then E.WINGS.enable()   else E.WINGS.disable()   end end)
        BT(B.visRight,"UC_AURA",   "Aura",        false,function(v) if v then E.AURA.enable()    else E.AURA.disable()    end end)
        BT(B.visRight,"UC_TRAIL",  "Trail",       false,function(v) if v then E.TRAIL.enable()   else E.TRAIL.disable()   end end)
        BT(B.visRight,"UC_GLOW",   "Glow",        false,function(v) if v then E.GLOW.enable()    else E.GLOW.disable()    end end)
        BT(B.visRight,"UC_SPARKLE","Sparkle",     false,function(v) if v then E.SPARKLE.enable() else E.SPARKLE.disable() end end)
        BT(B.visRight,"UC_HALO",   "Halo",        false,function(v) if v then E.HALO.enable()    else E.HALO.disable()    end end)
        BT(B.visRight,"UC_FLAM",   "Flames",      false,function(v) if v then E.FLAM.enable()    else E.FLAM.disable()    end end)
    end)

    task.wait()

    pcall(function()
        if not B.miscLeft then return end
        B.miscLeft:AddDivider()
        BT(B.miscLeft,"UC_FLY","Fly (WASD+E/Q)", false,function(v) if v then E.FLY.enable() else E.FLY.disable() end end)
        BT(B.miscLeft,"UC_PH", "Phase / Noclip", false,function(v) if v then E.PH.enable()  else E.PH.disable()  end end)
        BT(B.miscLeft,"UC_AJ", "Air Jump",        false,function(v) if v then E.AJ.enable()  else E.AJ.disable()  end end)
        BT(B.miscLeft,"UC_CMV","Speed Boost",     false,function(v) if v then E.CMV.enable() else E.CMV.disable() end end)
        BT(B.miscLeft,"UC_BL", "Blink (F key)",   false,function(v) if v then E.BL.enable()  else E.BL.disable()  end end)
        -- Weapon Picker (WPK)
        if WPK then
            B.miscLeft:AddDivider()
            BT(B.miscLeft,"UC_WPK_AUTO","Auto Pick Weapons",false,function(v)
                if v then WPK.enable() else WPK.disable() end
            end)
            -- Build weapon list (may be populated async, use fallback if empty)
            local _wpkList = #WPK.List > 0 and WPK.List or {
                "Assault Rifle","Crossbow","Daggers","Fists","Grenade",
                "Handgun","Katana","Shotgun","SMG","Sniper","Slingshot",
            }
            B.miscLeft:AddDropdown("UC_WPK_S1",{
                Text="Primary",Default="Assault Rifle",Values=_wpkList,
                Callback=function(v) WPK.Slot1=v; if not WPK.Enabled then WPK.pickOnce() end end})
            B.miscLeft:AddDropdown("UC_WPK_S2",{
                Text="Secondary",Default="Handgun",Values=_wpkList,
                Callback=function(v) WPK.Slot2=v; if not WPK.Enabled then WPK.pickOnce() end end})
            B.miscLeft:AddDropdown("UC_WPK_S3",{
                Text="Melee",Default="Fists",Values=_wpkList,
                Callback=function(v) WPK.Slot3=v; if not WPK.Enabled then WPK.pickOnce() end end})
            B.miscLeft:AddDropdown("UC_WPK_S4",{
                Text="Utility",Default="Grenade",Values=_wpkList,
                Callback=function(v) WPK.Slot4=v; if not WPK.Enabled then WPK.pickOnce() end end})
        end
    end)

    pcall(function()
        if not B.miscRight then return end
        B.miscRight:AddDivider()
        BT(B.miscRight,"UC_HN", "Hit Notifier",  false, function(v) if v then E.HN.enable()  else E.HN.disable()  end end)
        BT(B.miscRight,"UC_STD","Staff Detector", false,function(v) if v then E.STD.enable() else E.STD.disable() end end)
        BT(B.miscRight,"UC_NS", "Name Spoof",     false,function(v) if v then E.NS.enable()  else E.NS.disable()  end end)
    end)

    task.spawn(function() E.HN.enable() end)

    -- ============================================================
    -- 機能強化: キルトラッカー / オートリスポーン / 連打 / ESPオプション
    -- ============================================================
    pcall(function()
        -- キルトラッカー: 敵のHPが0になったらカウント
        local _kills = 0; local _deaths = 0
        local function _trackPlayers()
            for _,p in ipairs(Players:GetPlayers()) do
                if p == LP then continue end
                local c = p.Character; if not c then continue end
                local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then continue end
                if not c:GetAttribute("_uc_tracked") then
                    c:SetAttribute("_uc_tracked", true)
                    hum.Died:Connect(function()
                        _kills = _kills + 1
                        print("[UNCODE v1] Kill #".._kills.." D:"..tostring(_deaths))
                    end)
                end
            end
        end
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function() task.wait(0.5); _trackPlayers() end)
        end)
        LP.CharacterAdded:Connect(function()
            task.wait(2)
            _deaths = _deaths + 1
            print("[UNCODE v1] Death #".._deaths.." K:"..tostring(_kills))
        end)
        task.spawn(function() task.wait(2); _trackPlayers() end)
        -- ミッションタブ / miscRightにキルカウント表示
        pcall(function()
            if B.miscRight then
                B.miscRight:AddDivider()
                B.miscRight:AddLabel("Kill Tracker: K/D tracked in console")
                BT(B.miscRight,"UC_AR","Auto Respawn",false,function(v)
                    if v then
                        _ucx_conn("AR", LP.CharacterRemoving:Connect(function()
                            task.wait(0.3)
                            pcall(function()
                                local SpawnedChar = LP.Character
                                if not SpawnedChar then
                                    local respawnRemote = RS:FindFirstChild("Remotes")
                                    if respawnRemote then
                                        for _,r in ipairs(respawnRemote:GetDescendants()) do
                                            if r:IsA("RemoteEvent") and r.Name:lower():find("resp") then
                                                pcall(function() r:FireServer() end)
                                                return
                                            end
                                        end
                                    end
                                    -- Roblox標準リスポーン
                                    pcall(function() LP:LoadCharacter() end)
                                end
                            end)
                        end))
                    else
                        _ucx_stop("AR")
                    end
                end)
            end
        end)
    end)

    -- ============================================================
    -- 機能強化: AutoCollect (ドロップ自動回収)
    -- ============================================================
    pcall(function()
        if B.miscLeft then
            B.miscLeft:AddDivider()
            BT(B.miscLeft,"UC_ACOLL","Auto Collect",false,function(v)
                ACCFG.enabled = v
                if v then startAutoCollect() else stopAutoCollect() end
            end)
        end
    end)

    -- ============================================================
    -- 機能強化: ESP拡張スライダー (最大距離)
    -- ============================================================
    pcall(function()
        if B.visRight and E.ESP then
            B.visRight:AddSlider("UC_ESP_DIST",{Text="ESP Max Distance",Default=600,Min=50,Max=3000,Rounding=0,
                Callback=function(v) E.ESP.MaxDist=v end})
        end
    end)

    -- ============================================================
    -- [uncode] Chat Spam UI
    -- ============================================================
    pcall(function()
        if not B.miscRight then return end
        B.miscRight:AddDivider()
        BT(B.miscRight,"UC_CS","Chat Spam",false,function(v)
            if v then _UM.CS.enable() else _UM.CS.disable() end
        end)
        B.miscRight:AddSlider("UC_CS_INT",{Text="Spam Interval (s)",Default=2,Min=0.5,Max=10,Rounding=1,
            Callback=function(v) _UM.CS.Interval=v end})
    end)

    -- ============================================================
    -- [uncode] Auto Queue UI
    -- ============================================================
    pcall(function()
        if not B.miscLeft then return end
        B.miscLeft:AddDivider()
        BT(B.miscLeft,"UC_AQ","Auto Queue",false,function(v)
            if v then _UM.AQ.enable() else _UM.AQ.disable() end
        end)
        B.miscLeft:AddDropdown("UC_AQ_MODE",{Text="Queue Mode",Default="1v1",
            Values={"1v1","2v2","3v3","4v4","Casual","Ranked"},
            Callback=function(v) _UM.AQ.Mode=v end})
    end)

    -- ============================================================
    -- [uncode] Animation Player UI
    -- ============================================================
    pcall(function()
        if not B.miscRight then return end
        B.miscRight:AddDivider()
        BT(B.miscRight,"UC_ANIM","Animation Player",false,function(v)
            if v then _UM.ANIM.enable() else _UM.ANIM.disable() end
        end)
        B.miscRight:AddDropdown("UC_ANIM_SEL",{Text="Emote",Default="Dance",
            Values=_UM.ANIM.List,
            Callback=function(v) _UM.ANIM.setAnim(v) end})
        B.miscRight:AddSlider("UC_ANIM_SPD",{Text="Anim Speed",Default=1,Min=0.1,Max=4,Rounding=1,
            Callback=function(v) _UM.ANIM.Speed=v; if _UM.ANIM._track then pcall(function() _UM.ANIM._track:AdjustSpeed(v) end) end end})
    end)

    -- ============================================================
    -- [uncode] Desync / Anti-Aim UI (強化版)
    -- ============================================================
    pcall(function()
        if not B.miscLeft then return end
        B.miscLeft:AddDivider()
        BT(B.miscLeft,"UC_DESYNC","Desync / Anti-Aim",false,function(v)
            if v then _UM.DESYNC.enable() else _UM.DESYNC.disable() end
        end)
        B.miscLeft:AddDropdown("UC_DS_PITCH",{Text="Pitch Mode",Default="disabled",
            Values={"disabled","up","down","zero","random"},
            Callback=function(v) _UM.DESYNC.PitchMode=v end})
        B.miscLeft:AddDropdown("UC_DS_YAW",{Text="Yaw Mode",Default="disabled",
            Values={"disabled","backwards","spin","random"},
            Callback=function(v) _UM.DESYNC.YawMode=v end})
        B.miscLeft:AddSlider("UC_DS_SPD",{Text="Spin Speed",Default=5,Min=1,Max=30,Rounding=0,
            Callback=function(v) _UM.DESYNC.SpinSpeed=v end})
        BT(B.miscLeft,"UC_DS_UG","Underground",false,function(v) _UM.DESYNC.Underground=v end)
    end)

    -- ============================================================
    -- [uncode] Color Correction / Bloom / Sun Rays UI
    -- ============================================================
    pcall(function()
        if not B.visLeft then return end
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_CC","Color Correction",false,function(v)
            VFXCFG.CC=v; _vfxCC()
        end)
        B.visLeft:AddSlider("UC_CC_BR",{Text="CC Brightness",Default=0,Min=-1,Max=1,Rounding=2,
            Callback=function(v) VFXCFG.CCBright=v; if VFXCFG.CC then _vfxCC() end end})
        B.visLeft:AddSlider("UC_CC_CT",{Text="CC Contrast",Default=0,Min=-1,Max=1,Rounding=2,
            Callback=function(v) VFXCFG.CCContrast=v; if VFXCFG.CC then _vfxCC() end end})
        B.visLeft:AddSlider("UC_CC_SA",{Text="CC Saturation",Default=0,Min=-2,Max=2,Rounding=2,
            Callback=function(v) VFXCFG.CCSat=v; if VFXCFG.CC then _vfxCC() end end})
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_BLM","Bloom",false,function(v)
            VFXCFG.Bloom=v; _vfxBloom()
        end)
        B.visLeft:AddSlider("UC_BLM_INT",{Text="Bloom Intensity",Default=50,Min=1,Max=200,Rounding=0,
            Callback=function(v) VFXCFG.BloomInt=v/100; if VFXCFG.Bloom then _vfxBloom() end end})
        B.visLeft:AddSlider("UC_BLM_SZ",{Text="Bloom Size",Default=24,Min=1,Max=56,Rounding=0,
            Callback=function(v) VFXCFG.BloomSize=v; if VFXCFG.Bloom then _vfxBloom() end end})
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_SR","Sun Rays",false,function(v)
            VFXCFG.SunRays=v; _vfxSunRays()
        end)
        B.visLeft:AddSlider("UC_SR_INT",{Text="Sun Rays Intensity",Default=25,Min=1,Max=100,Rounding=0,
            Callback=function(v) VFXCFG.SRInt=v/100; if VFXCFG.SunRays then _vfxSunRays() end end})
        B.visLeft:AddSlider("UC_SR_SPR",{Text="Sun Rays Spread",Default=50,Min=1,Max=100,Rounding=0,
            Callback=function(v) VFXCFG.SRSpread=v/100; if VFXCFG.SunRays then _vfxSunRays() end end})
    end)

    -- ============================================================
    -- [uncode] Rage: Rage Silent UI
    -- ============================================================
    pcall(function()
        if not B.combatKX then return end
        B.combatKX:AddDivider()
        BT(B.combatKX,"UC_RSAI","Rage Silent",false,function(v)
            if v then _UM.RSAI.enable() else _UM.RSAI.disable() end
        end)
        B.combatKX:AddSlider("UC_RSAI_PRED",{Text="Silent Prediction",Default=12,Min=0,Max=50,Rounding=0,
            Callback=function(v) _UM.RSAI.Prediction=v/100 end})
        B.combatKX:AddSlider("UC_RSAI_FOV",{Text="Silent FOV",Default=180,Min=10,Max=180,Rounding=0,
            Callback=function(v)
                _UM.RSAI.FOV=v
                if _UM.RSAI._circ then
                    _UM.RSAI._circ.Visible = _UM.RSAI.Enabled and _UM.RSAI.ShowCircle and v<180
                end
            end})
        BT(B.combatKX,"UC_RSAI_CIRC","Silent FOV Circle",true,function(v)
            _UM.RSAI.ShowCircle=v
            if _UM.RSAI._circ and (not v or not _UM.RSAI.Enabled) then
                _UM.RSAI._circ.Visible=false
            end
        end)
        B.combatKX:AddDropdown("UC_RSAI_PART",{Text="Target Part",Default="Head",
            Values={"Head","HumanoidRootPart","closest"},
            Callback=function(v) _UM.RSAI.Part=v end})
    end)

    -- ============================================================
    -- [uncode] Rage: Projectile TP UI
    -- ============================================================
    pcall(function()
        if not B.combatKX then return end
        BT(B.combatKX,"UC_PTP","Projectile TP",false,function(v)
            if v then _UM.PTP.enable() else _UM.PTP.disable() end
        end)
    end)

    -- ============================================================
    -- [uncode] Rage: Anti Katana UI
    -- ============================================================
    pcall(function()
        if not B.combatKX then return end
        BT(B.combatKX,"UC_AKT","Anti Katana",false,function(v)
            if v then _UM.AKT.enable() else _UM.AKT.disable() end
        end)
    end)

    -- ============================================================
    -- [uncode] Visual: Highlight ESP UI
    -- ============================================================
    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_HESP","Highlight ESP",false,function(v)
            if v then _UM.HESP.enable() else _UM.HESP.disable() end
        end)
        BT(B.visRight,"UC_HESP_TW","Through Walls",true,function(v)
            _UM.HESP.ThroughWalls=v; _UM.HESP.refresh()
        end)
        B.visRight:AddSlider("UC_HESP_FT",{Text="Fill Trans",Default=35,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.HESP.FillTrans=v/100; _UM.HESP.refresh() end})
        B.visRight:AddSlider("UC_HESP_OT",{Text="Outline Trans",Default=0,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.HESP.OutlineTrans=v/100; _UM.HESP.refresh() end})
    end)

    -- ============================================================
    -- [uncode] Visual: Override Appearance UI
    -- ============================================================
    pcall(function()
        if not B.visLeft then return end
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_OAPP","Override Appearance",false,function(v)
            if v then _UM.OAPP.enable() else _UM.OAPP.disable() end
        end)
        B.visLeft:AddDropdown("UC_OAPP_MAT",{Text="Material",Default="ForceField",
            Values={"ForceField","Neon","Glass","SmoothPlastic","Metal","Ice","Foil","Fabric"},
            Callback=function(v)
                local ok, m = pcall(function() return Enum.Material[v] end)
                if ok then _UM.OAPP.Material=m end
                if _UM.OAPP.Enabled then _UM.OAPP.disable(); _UM.OAPP.enable() end
            end})
        B.visLeft:AddSlider("UC_OAPP_TR",{Text="Transparency",Default=0,Min=0,Max=90,Rounding=0,
            Callback=function(v) _UM.OAPP.Transparency=v/100; if _UM.OAPP.Enabled then _UM.OAPP.disable(); _UM.OAPP.enable() end end})
    end)

    -- ============================================================
    -- [uncode] Visual: XRay UI
    -- ============================================================
    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_XRAY","X-Ray",false,function(v)
            if v then _UM.XRAY.enable() else _UM.XRAY.disable() end
        end)
        B.visRight:AddSlider("UC_XRAY_TR",{Text="Wall Transparency",Default=85,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.XRAY.Transparency=v/100 end})
    end)

    -- ============================================================
    -- [uncode] Visual: Atmosphere UI
    -- ============================================================
    pcall(function()
        if not B.visLeft then return end
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_ATMO","Atmosphere",false,function(v)
            if v then _UM.ATMO.enable() else _UM.ATMO.disable() end
        end)
        B.visLeft:AddSlider("UC_ATMO_DEN",{Text="Density",Default=30,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.ATMO.Density=v/100; if _UM.ATMO.Enabled then _UM.ATMO._apply() end end})
        B.visLeft:AddSlider("UC_ATMO_HZ",{Text="Haze",Default=10,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.ATMO.Haze=v/10; if _UM.ATMO.Enabled then _UM.ATMO._apply() end end})
        B.visLeft:AddSlider("UC_ATMO_GL",{Text="Glare",Default=5,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.ATMO.Glare=v/10; if _UM.ATMO.Enabled then _UM.ATMO._apply() end end})
    end)

    -- ============================================================
    -- [uncode] Visual: Lighting Override UI
    -- ============================================================
    pcall(function()
        if not B.visLeft then return end
        B.visLeft:AddDivider()
        BT(B.visLeft,"UC_LGHT","Lighting Override",false,function(v)
            if v then _UM.LGHT.enable() else _UM.LGHT.disable() end
        end)
        BT(B.visLeft,"UC_LGHT_FOG","Enable Fog",false,function(v)
            _UM.LGHT.FogEnabled=v; if _UM.LGHT.Enabled then _UM.LGHT._apply() end
        end)
        B.visLeft:AddSlider("UC_LGHT_FE",{Text="Fog End",Default=1000,Min=0,Max=5000,Rounding=0,
            Callback=function(v) _UM.LGHT.FogEnd=v; if _UM.LGHT.Enabled then _UM.LGHT._apply() end end})
        BT(B.visLeft,"UC_LGHT_CLK","Override Time",false,function(v)
            _UM.LGHT.ClockEnabled=v; if _UM.LGHT.Enabled then _UM.LGHT._apply() end
        end)
        B.visLeft:AddSlider("UC_LGHT_TIME",{Text="Clock Time",Default=12,Min=0,Max=24,Rounding=1,
            Callback=function(v) _UM.LGHT.ClockTime=v; if _UM.LGHT.Enabled then _UM.LGHT._apply() end end})
        BT(B.visLeft,"UC_LGHT_BRT","Override Brightness",false,function(v)
            _UM.LGHT.BrightEnabled=v; if _UM.LGHT.Enabled then _UM.LGHT._apply() end
        end)
        B.visLeft:AddSlider("UC_LGHT_BV",{Text="Brightness",Default=20,Min=0,Max=100,Rounding=0,
            Callback=function(v) _UM.LGHT.Brightness=v/10; if _UM.LGHT.Enabled then _UM.LGHT._apply() end end})
    end)

    -- ============================================================
    -- [uncode] FOV Circle v2 UI
    -- ============================================================
    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_FOVC","FOV Circle",false,function(v)
            if FOVC then if v then FOVC.enable() else FOVC.disable() end end
        end)
        B.visRight:AddSlider("UC_FOVC_R",{Text="  Radius",Default=120,Min=20,Max=500,Rounding=0,
            Callback=function(v) if FOVC then FOVC.Radius=v end end})
        B.visRight:AddSlider("UC_FOVC_TH",{Text="  Thickness",Default=2,Min=1,Max=5,Rounding=1,
            Callback=function(v) if FOVC then FOVC.Thickness=v end end})
        BT(B.visRight,"UC_FOVC_DR","  Double Ring",false,function(v)
            if FOVC then FOVC.DoubleRing=v end
        end)
        B.visRight:AddDivider()
        -- Chams v2
        BT(B.visRight,"UC_CHMS","Chams (Highlight)",false,function(v)
            if CHMS then if v then CHMS.enable() else CHMS.disable() end end
        end)
        BT(B.visRight,"UC_CHMS_TW","  Through Walls",true,function(v)
            if CHMS then CHMS.ThroughWall=v end
        end)
        BT(B.visRight,"UC_CHMS_OO","  Outline Only",false,function(v)
            if CHMS then CHMS.OutlineOnly=v end
        end)
        BT(B.visRight,"UC_CHMS_HP","  HP Tint",false,function(v)
            if CHMS then CHMS.HPTint=v end
        end)
        B.visRight:AddSlider("UC_CHMS_TR",{Text="  Fill Trans",Default=50,Min=0,Max=100,Rounding=0,
            Callback=function(v) if CHMS then CHMS.FillTransparency=v/100 end end})
    end)

    -- ============================================================
    -- [uncode] BunnyHop + Inf Double Jump UI (Misc tab)
    -- ============================================================
    pcall(function()
        if not B.miscLeft then return end
        B.miscLeft:AddDivider()
        BT(B.miscLeft,"UC_BHOP","BunnyHop",false,function(v)
            if BHOP then if v then BHOP.enable() else BHOP.disable() end end
        end)
        BT(B.miscLeft,"UC_IJMP","Infinite D-Jump",false,function(v)
            if IJMP then if v then IJMP.enable() else IJMP.disable() end end
        end)
    end)

    -- ============================================================
    -- [uncode] Visual: FOV Changer UI
    -- ============================================================
    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_WFOV","FOV Changer",false,function(v)
            if v then _UM.WFOV.enable() else _UM.WFOV.disable() end
        end)
        B.visRight:AddSlider("UC_WFOV_V",{Text="Field of View",Default=90,Min=30,Max=120,Rounding=0,
            Callback=function(v) _UM.WFOV.FOV=v; if _UM.WFOV.Enabled then pcall(function() Camera.FieldOfView=v end) end end})
    end)

    -- ============================================================
    -- [uncode] Tracers v2 UI
    -- ============================================================
    pcall(function()
        if not B.visRight or not TRAC then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_TRAC","Tracers",false,function(v)
            if v then TRAC.enable() else TRAC.disable() end
        end)
        B.visRight:AddDropdown("UC_TRAC_OR",{Text="  Origin",Default="bottom",
            Values={"bottom","center","crosshair"},
            Callback=function(v) if TRAC then TRAC.Origin=v end end})
        B.visRight:AddSlider("UC_TRAC_TH",{Text="  Thickness",Default=2,Min=1,Max=6,Rounding=1,
            Callback=function(v) if TRAC then TRAC.Thickness=v end end})
        BT(B.visRight,"UC_TRAC_DF","  Dist Fade",false,function(v)
            if TRAC then TRAC.DistFade=v end
        end)
    end)

    -- ============================================================
    -- [uncode] Box ESP v2 UI (コーナー + ヘッドドット + 距離)
    -- ============================================================
    pcall(function()
        if not B.visRight or not DESP then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_DESP","Box ESP",false,function(v)
            if v then DESP.enable() else DESP.disable() end
        end)
        BT(B.visRight,"UC_DESP_CR","  Corner Style",true,function(v)
            if DESP then DESP.CornerStyle=v end
        end)
        B.visRight:AddSlider("UC_DESP_CL",{Text="  Corner Len",Default=25,Min=10,Max=50,Rounding=0,
            Callback=function(v) if DESP then DESP.CornerLen=v/100 end end})
        BT(B.visRight,"UC_DESP_NM","  Show Name",true,function(v)
            if DESP then DESP.ShowName=v end
        end)
        BT(B.visRight,"UC_DESP_HP","  Show Health",true,function(v)
            if DESP then DESP.ShowHealth=v end
        end)
        BT(B.visRight,"UC_DESP_DS","  Show Distance",true,function(v)
            if DESP then DESP.ShowDist=v end
        end)
        BT(B.visRight,"UC_DESP_HD","  Head Dot",true,function(v)
            if DESP then DESP.ShowHeadDot=v end
        end)
    end)

    -- ============================================================
    -- [uncode] Chat Spam UI (Misc tab)
    -- ============================================================
    pcall(function()
        if not B.miscRight or not CSPM then return end
        B.miscRight:AddDivider()
        BT(B.miscRight,"UC_CSPM","Chat Spam",false,function(v)
            if v then CSPM.enable() else CSPM.disable() end
        end)
        B.miscRight:AddDropdown("UC_CSPM_MODE",{
            Text="Chat Mode",Default="custom",
            Values={"custom","smol","corny","wholesome","auto ban"},
            Callback=function(v) if CSPM then CSPM.Mode=v end end})
        B.miscRight:AddSlider("UC_CSPM_INT",{
            Text="Interval (s)",Default=15,Min=5,Max=100,Rounding=0,
            Callback=function(v) if CSPM then CSPM.Interval=v/10 end end})
    end)

    -- ============================================================
    -- [uncode] Custom Crosshair v2 UI + Disable VM + No Vignette
    -- ============================================================
    pcall(function()
        if not B.visRight then return end
        B.visRight:AddDivider()
        BT(B.visRight,"UC_CXHR","Custom Crosshair",false,function(v)
            if CXHR then if v then CXHR.enable() else CXHR.disable() end end
        end)
        B.visRight:AddSlider("UC_CXHR_SZ",{Text="  Size",Default=12,Min=2,Max=50,Rounding=0,
            Callback=function(v) if CXHR then CXHR.Size=v end end})
        B.visRight:AddSlider("UC_CXHR_GP",{Text="  Gap",Default=4,Min=0,Max=25,Rounding=0,
            Callback=function(v) if CXHR then CXHR.Gap=v end end})
        B.visRight:AddSlider("UC_CXHR_TH",{Text="  Thickness",Default=2,Min=1,Max=6,Rounding=0,
            Callback=function(v) if CXHR then CXHR.Thickness=v end end})
        BT(B.visRight,"UC_CXHR_CD","  Center Dot",true,function(v)
            if CXHR then CXHR.CenterDot=v end
        end)
        BT(B.visRight,"UC_CXHR_OL","  Outline",true,function(v)
            if CXHR then CXHR.Outline=v end
        end)
        BT(B.visRight,"UC_CXHR_TS","  T-Style",false,function(v)
            if CXHR then CXHR.TStyle=v end
        end)
        BT(B.visRight,"UC_CXHR_DY","  Dynamic",false,function(v)
            if CXHR then CXHR.Dynamic=v end
        end)
        B.visRight:AddDivider()
        BT(B.visRight,"UC_DVM","Disable Viewmodel",false,function(v)
            if DVM then if v then DVM.enable() else DVM.disable() end end
        end)
        BT(B.visRight,"UC_NOVIG","Remove Vignette",false,function(v)
            if NOVIG then if v then NOVIG.enable() else NOVIG.disable() end end
        end)
    end)

    -- ============================================================
    -- [uncode] Auto Ban + Collect Drops + Auto Respawn + Device Spoofer (Misc)
    -- ============================================================
    pcall(function()
        if not B.miscRight then return end
        B.miscRight:AddDivider()
        -- Auto Ban
        BT(B.miscRight,"UC_AUBA","Auto Ban",false,function(v)
            if AUBA then if v then AUBA.enable() else AUBA.disable() end end
        end)
        if B.miscRight.AddInput then
            B.miscRight:AddInput("UC_AUBA_S1",{Text="  Ban Weapon 1",Default="None",
                Callback=function(v) if AUBA then AUBA.Slot1=v end end})
            B.miscRight:AddInput("UC_AUBA_S2",{Text="  Ban Weapon 2",Default="None",
                Callback=function(v) if AUBA then AUBA.Slot2=v end end})
        else
            B.miscRight:AddDropdown("UC_AUBA_S1",{Text="  Ban Slot 1",Default="None",
                Values={"None","Assault Rifle","Shotgun","SMG","Sniper Rifle","Handgun","Fists","Grenade"},
                Callback=function(v) if AUBA then AUBA.Slot1=v end end})
            B.miscRight:AddDropdown("UC_AUBA_S2",{Text="  Ban Slot 2",Default="None",
                Values={"None","Assault Rifle","Shotgun","SMG","Sniper Rifle","Handgun","Fists","Grenade"},
                Callback=function(v) if AUBA then AUBA.Slot2=v end end})
        end
        B.miscRight:AddSlider("UC_AUBA_DL",{Text="  Interval (s)",Default=10,Min=2,Max=60,Rounding=0,
            Callback=function(v) if AUBA then AUBA.Delay=v/10 end end})
        B.miscRight:AddDivider()
        -- Auto Respawn
        BT(B.miscRight,"UC_ARSP","Auto Respawn",false,function(v)
            if ARSP then if v then ARSP.enable() else ARSP.disable() end end
        end)
        -- Collect Drops
        BT(B.miscRight,"UC_CDROP","Collect Drops",false,function(v)
            if CDROP then if v then CDROP.enable() else CDROP.disable() end end
        end)
        B.miscRight:AddDivider()
        -- Device Spoofer
        BT(B.miscRight,"UC_DVSP","Device Spoofer",false,function(v)
            if DVSP then if v then DVSP.enable() else DVSP.disable() end end
        end)
        B.miscRight:AddDropdown("UC_DVSP_MD",{Text="  Device Mode",Default="Touch",
            Values={"Touch","Gamepad","MouseKeyboard","VR"},
            Callback=function(v)
                if DVSP then
                    DVSP.Mode = v
                    if DVSP.Enabled then pcall(function()
                        local rs = cloneref(game:GetService("ReplicatedStorage"))
                        local r = rs:FindFirstChild("Remotes")
                        r = r and r:FindFirstChild("Replication")
                        r = r and r:FindFirstChild("Fighter")
                        r = r and r:FindFirstChild("SetControls")
                        if r then r:FireServer(v) end
                    end) end
                end
            end})
    end)

    print("[UNCODE v1] Features wired OK")
    end)

    pcall(collectgarbage,"collect"); task.delay(1,function() pcall(collectgarbage,"collect") end)
    GE.UC4_Loaded=true; pcall(function() _G.UC4_Loaded=true end)
    GE.UC4_Running=nil;  pcall(function() _G.UC4_Running=nil end)
    pcall(function() if Notify then Notify("uncode v8 ready", 5) end end)
    print("[UNCODE v1] Ready")
end) -- task.spawn: エンジン遅延ロード完了
