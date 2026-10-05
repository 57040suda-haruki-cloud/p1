    BurstFire.Rate  = 0.03; BurstFire.enable()
end

function MaxMode.disable()
    MaxMode.Enabled = false
    SilentShot.disable()
    AimSmooth.disable()
    AutoShoot.disable()
    BurstFire.disable()
    SilentShot.FOV = 120
    AimSmooth.Speed = 6; AimSmooth.FOV = 150
    AutoShoot.Delay = 0.08
    BurstFire.Rate  = 0.05
end

local SkinSwap = {}
SkinSwap.Enabled = false
SkinSwap.Preset  = "neon_red"

local _skinPresets = {
    neon_red   = {color = Color3.fromRGB(255, 50,  50),  mat = Enum.Material.Neon},
    neon_blue  = {color = Color3.fromRGB( 50, 100, 255), mat = Enum.Material.Neon},
    neon_green = {color = Color3.fromRGB( 50, 255,  80), mat = Enum.Material.Neon},
    chrome     = {color = Color3.fromRGB(180, 200, 220), mat = Enum.Material.SmoothPlastic},
    gold       = {color = Color3.fromRGB(255, 200,  40), mat = Enum.Material.SmoothPlastic},
}
local _skinOrig = {}
local _skinHue  = 0

local function _applySkin(col, mat)
    local c = _char(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            if not _skinOrig[p] then
                _skinOrig[p] = {color = p.Color, mat = p.Material}
            end
            pcall(function() p.Color = col; p.Material = mat end)
        end
    end
end

local function _restoreSkin()
    for p, orig in pairs(_skinOrig) do
        pcall(function() p.Color = orig.color; p.Material = orig.mat end)
    end
    table.clear(_skinOrig)
end

local function _skinApplyPreset()
    local pr = _skinPresets[SkinSwap.Preset]
    if pr then _applySkin(pr.color, pr.mat) end
end

function SkinSwap.enable()
    SkinSwap.Enabled = true
    if SkinSwap.Preset ~= "rainbow" then _skinApplyPreset() end
    _conn("SkinSwap", RN_.Heartbeat:Connect(function(dt)
        if not SkinSwap.Enabled then return end
        if SkinSwap.Preset == "rainbow" then
            _skinHue = (_skinHue + dt * 0.25) % 1
            local col = Color3.fromHSV(_skinHue, 1, 1)
            local c = _char(); if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    if not _skinOrig[p] then
                        _skinOrig[p] = {color = p.Color, mat = p.Material}
                    end
                    pcall(function() p.Color = col; p.Material = Enum.Material.Neon end)
                end
            end
        end
    end))
    _conn("SkinSwap", LP_.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not SkinSwap.Enabled then return end
        table.clear(_skinOrig)
        if SkinSwap.Preset ~= "rainbow" then _skinApplyPreset() end
    end))
end

function SkinSwap.disable()
    SkinSwap.Enabled = false
    _stop("SkinSwap")
    _restoreSkin()
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
        WS_.CurrentCamera.CameraType = Enum.CameraType.Custom
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
    if UI_:GetFocusedTextBox() then return end
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
    _conn("FLY", UI_.InputBegan:Connect(function(i,p) if not p then _flyKey(i,true) end end))
    _conn("FLY", UI_.InputEnded:Connect( function(i)  _flyKey(i,false) end))
    _conn("FLY", LP_.CharacterAdded:Connect(function()
        task.wait(0.25); if FLY.Enabled then _flyStart() end
    end))
    _conn("FLY", RN_.RenderStepped:Connect(function()
        if not _alive() then return end
        if not _flyGyro or not _flyVel or not _flyGyro.Parent then _flyStart(); return end
        local cam = WS_.CurrentCamera
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
    _conn("PH", RN_.Stepped:Connect(function()
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
    _conn("TP3", RN_.RenderStepped:Connect(function()
        if not TP3.Enabled then return end
        local cam = WS_.CurrentCamera
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
    pcall(function() WS_.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local FC = {}
FC.Enabled = false
FC.Speed   = 40
local _fcPart
local _ffw,_ffb,_ffl,_ffr,_ffu,_ffd = 0,0,0,0,0,0

function FC.enable()
    FC.Enabled = true
    local cam = WS_.CurrentCamera
    _fcPart = Instance.new("Part")
    _fcPart.Anchored = true; _fcPart.CanCollide = false
    _fcPart.Transparency = 1; _fcPart.Size = Vector3.new(0.1,0.1,0.1)
    _fcPart.CFrame = cam.CFrame; _fcPart.Parent = workspace
    pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    _conn("FC", UI_.InputBegan:Connect(function(i,p)
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
    _conn("FC", UI_.InputEnded:Connect(function(i)
        local k = i.KeyCode
        if k==Enum.KeyCode.W then _ffw=0
        elseif k==Enum.KeyCode.S then _ffb=0
        elseif k==Enum.KeyCode.A then _ffl=0
        elseif k==Enum.KeyCode.D then _ffr=0
        elseif k==Enum.KeyCode.E or k==Enum.KeyCode.Space then _ffu=0
        elseif k==Enum.KeyCode.Q or k==Enum.KeyCode.LeftControl then _ffd=0
        end
    end))
    _conn("FC", RN_.RenderStepped:Connect(function()
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
    pcall(function() WS_.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local SB = {}
SB.Enabled = false
SB.Speed   = 10

function SB.enable()
    SB.Enabled = true
    local ang = 0
    _conn("SB", RN_.RenderStepped:Connect(function(dt)
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
    _conn("ANT", RN_.RenderStepped:Connect(function()
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
    _conn("AJ", UI_.InputBegan:Connect(function(i, p)
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
    _conn("AJ", LP_.CharacterAdded:Connect(function() _ajUsed = false end))
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
    _conn("TGS", RN_.Heartbeat:Connect(function(dt)
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
    _conn("ORB", RN_.Heartbeat:Connect(function(dt)
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

local KA = {}
KA.Enabled = false
KA.Range   = 15
KA.Delay   = 0.1
local _kaAccum = 0

function KA.enable()
    KA.Enabled = true
    _kaAccum = 0
    _conn("KA", RN_.Heartbeat:Connect(function(dt)
        if not KA.Enabled then return end
        _kaAccum = _kaAccum + dt
        if _kaAccum < KA.Delay then return end
        if not _alive() then return end
        local root = _root(); if not root then return end
        local enemy = _closestEnemy(800)
        if not enemy or not enemy.Character then return end
        local eHRP = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eHRP then return end
        if (root.Position - eHRP.Position).Magnitude > KA.Range then return end
        _kaAccum = 0
        pcall(function() if mouse1click then mouse1click() end end)
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

function AP.enable()
    AP.Enabled = true
    _apCooldown = 0
    _conn("AP", RN_.Heartbeat:Connect(function(dt)
        if not AP.Enabled then return end
        _apCooldown = math.max(0, _apCooldown - dt)
        if _apCooldown > 0 then return end
        local root = _root(); if not root then return end
        local rpos = root.Position
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Anchored and obj.CanCollide then
                local d = (obj.Position - rpos).Magnitude
                if d < AP.Range then
                    local vel = obj.AssemblyLinearVelocity
                    if vel.Magnitude >= AP.MinSpeed then
                        local toPlayer = (rpos - obj.Position)
                        if toPlayer.Magnitude > 0 then
                            local dot = toPlayer.Unit:Dot(vel.Unit)
                            if dot > 0.65 then
                                _apCooldown = 0.4
                                pcall(function()
                                    if mouse2click then mouse2click() end
                                end)
                                return
                            end
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
    }
    d.box.Filled = false; d.box.Thickness = 1
    d.box.Color  = Color3.fromRGB(255,60,60)
    d.name.Size  = 13; d.name.Center = true; d.name.Outline = true
    d.name.Color = Color3.fromRGB(255,255,255)
    d.hbar.Thickness = 3; d.hbar.Color  = Color3.fromRGB(60,200,60)
    d.hbg.Thickness  = 3; d.hbg.Color   = Color3.fromRGB(180,60,60)
    d.trc.Thickness  = 1; d.trc.Color   = Color3.fromRGB(255,60,60)
    d.dist.Size = 11; d.dist.Center = true; d.dist.Outline = true
    d.dist.Color = Color3.fromRGB(220,220,220)
    for _,v in pairs(d) do v.Visible = false end
    return d
end

local function _removeEspFor(p)
    local d = _espDrawings[p]
    if not d then return end
    for _,v in pairs(d) do pcall(function() v:Remove() end) end
    _espDrawings[p] = nil
end

local function _espLoop()
    if not ESP.Enabled then return end
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
        local fade  = math.clamp(1 - studs / ESP.MaxDist, 0.1, 1)
        local topSP = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2.5,0))
        local w  = math.clamp(math.abs(sp.Z) * 1.2, 20, 200)
        local h2 = math.abs(Vector2.new(sp.X,sp.Y).Y - Vector2.new(topSP.X,topSP.Y).Y) + 8
        local x, y = sp.X - w/2, topSP.Y - 4
        d.box.Position     = Vector2.new(x, y)
        d.box.Size         = Vector2.new(w, h2)
        d.box.Transparency = fade; d.box.Visible = true
        d.name.Position    = Vector2.new(sp.X, y - 16)
        d.name.Text        = p.DisplayName
        d.name.Transparency = fade; d.name.Visible = true
        d.dist.Position    = Vector2.new(sp.X, y + h2 + 2)
        d.dist.Text        = string.format("%.0f", studs)
        d.dist.Transparency = fade; d.dist.Visible = true
        local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
        local bx = x - 5
        d.hbg.From  = Vector2.new(bx, y);      d.hbg.To = Vector2.new(bx, y+h2)
        d.hbar.From = Vector2.new(bx, y+h2*(1-hp))
        d.hbar.To   = Vector2.new(bx, y+h2)
        d.hbg.Transparency = fade; d.hbar.Transparency = fade
        d.hbg.Visible = true; d.hbar.Visible = true
        d.trc.From  = screenBot
        d.trc.To    = Vector2.new(sp.X, y + h2/2)
        d.trc.Transparency = fade * 0.6
        d.trc.Visible = true

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
                print("[UNCODE v8] Staff detected:", p.Name)
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
    _conn("WINGS_col", RN_.Heartbeat:Connect(function(dt)
        if not WINGS.Enabled then return end
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

function AURA.enable()
    AURA.Enabled = true
    _conn("AURA", RN_.Heartbeat:Connect(function(dt)
        if not AURA.Enabled then return end
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

    SilentShot=SilentShot, AimSmooth=AimSmooth, AutoShoot=AutoShoot,
    BurstFire=BurstFire,   MaxMode=MaxMode,
    SkinSwap=SkinSwap, KA=KA, AP=AP,

    FLY=FLY, PH=PH, TP3=TP3, FC=FC,
    SB=SB,   ANT=ANT, AJ=AJ, TGS=TGS, ORB=ORB,

    ESP=ESP, VMR=VMR, NS=NS, HN=HN, BL=BL,
    STD=STD, SHD=SHD, CMV=CMV,

    WINGS=WINGS, AURA=AURA, TRAIL=TRAIL,
    GLOW=GLOW, SPARKLE=SPARKLE, HALO=HALO, FLAM=FLAM,
}
        end)()
    end)
    if not _loadOk then
        print("[UNCODE v8] Engine error: " .. tostring(_loadErr))
    end
end
print("[UNCODE v8] Feature engine ready (" .. tostring(_UCEngine ~= nil) .. ")")

pcall(function()
    local E = _UCEngine
    if not E then return end
    local B = _ucBoxes

    task.wait()

    pcall(function()
        if Toggles.KX_Silent then
            local _orig = Toggles.KX_Silent.Callback
            Toggles.KX_Silent.Callback = function(v)
                if v then E.SilentShot.enable() else E.SilentShot.disable() end
                if _orig then pcall(_orig, v) end
            end
        end
        if not B.combatKX then return end
        BT(B.combatKX,"UC_AimSmooth","Aim Smooth",   false,function(v) if v then E.AimSmooth.enable() else E.AimSmooth.disable() end end)
        BT(B.combatKX,"UC_AutoShoot","Auto Shoot",   false,function(v) if v then E.AutoShoot.enable() else E.AutoShoot.disable() end end)
        BT(B.combatKX,"UC_KA",       "Kill Aura",    false,function(v) if v then E.KA.enable()        else E.KA.disable()        end end)
        BT(B.combatKX,"UC_AP",       "Auto Parry",   false,function(v) if v then E.AP.enable()        else E.AP.disable()        end end)
        B.combatKX:AddDivider()
        BT(B.combatKX,"UC_MaxMode",  "Max Mode",     false,function(v) if v then E.MaxMode.enable()   else E.MaxMode.disable()   end end)
    end)

    pcall(function()
        if Toggles.WP_Rapid then
            local _orig = Toggles.WP_Rapid.Callback
            Toggles.WP_Rapid.Callback = function(v)
                if v then E.BurstFire.enable() else E.BurstFire.disable() end
                if _orig then pcall(_orig, v) end
            end
        end
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
        BT(B.visLeft,"UC_SKIN",  "Enable Skin",  false,function(v) if v then E.SkinSwap.enable()  else E.SkinSwap.disable()  end end)
        BT(B.visLeft,"UC_SK_RD", "Neon Red",     false,function(v) if v then E.SkinSwap.Preset="neon_red";   if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
        BT(B.visLeft,"UC_SK_BL", "Neon Blue",    false,function(v) if v then E.SkinSwap.Preset="neon_blue";  if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
        BT(B.visLeft,"UC_SK_GN", "Neon Green",   false,function(v) if v then E.SkinSwap.Preset="neon_green"; if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
        BT(B.visLeft,"UC_SK_CR", "Chrome",        false,function(v) if v then E.SkinSwap.Preset="chrome";     if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
        BT(B.visLeft,"UC_SK_GD", "Gold",          false,function(v) if v then E.SkinSwap.Preset="gold";       if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
        BT(B.visLeft,"UC_SK_RB", "Rainbow",       false,function(v) if v then E.SkinSwap.Preset="rainbow";    if E.SkinSwap.Enabled then E.SkinSwap.enable() end end end)
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
    end)

    pcall(function()
        if not B.miscRight then return end
        B.miscRight:AddDivider()
        BT(B.miscRight,"UC_HN", "Hit Notifier",  true, function(v) if v then E.HN.enable()  else E.HN.disable()  end end)
        BT(B.miscRight,"UC_STD","Staff Detector", false,function(v) if v then E.STD.enable() else E.STD.disable() end end)
        BT(B.miscRight,"UC_NS", "Name Spoof",     false,function(v) if v then E.NS.enable()  else E.NS.disable()  end end)
    end)

    task.spawn(function() E.HN.enable() end)
    print("[UNCODE v8] Features wired OK")
end)

GE.UC4_Loaded=true; pcall(function() _G.UC4_Loaded=true end)
GE.UC4_Running=nil;  pcall(function() _G.UC4_Running=nil end)
pcall(function() if Notify then Notify("uncode v6 ready", 4) end end)
print("[UNCODE v8] Ready")
