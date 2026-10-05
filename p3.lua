
    local dl=RVNew("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-26),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(150,150,150),Text="",Visible=RV.ESP.Distance},root)

    local wm=RVNew("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-13),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=RV.ESP.WatermarkColor,TextStrokeTransparency=0.3,Text=RV.ESP.WatermarkText,Visible=RV.ESP.Watermark},root)

    local hbBG=RVNew("Frame",{Size=UDim2.new(0,4,0,56),Position=UDim2.new(0.5,-37,0,28),BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0,Visible=RV.ESP.Healthbar},root)
    local hbFill=RVNew("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=RV.ESP.HB_A,BorderSizePixel=0},hbBG)

    local hl=nil
    if RV.ESP.Skeleton or RV.ESP.Outline then
        hl=RVNew("Highlight",{FillColor=RV.ESP.BoxFill,OutlineColor=RV.ESP.SkelC,FillTransparency=0.7,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.Occluded,Adornee=c},visGui)
    end
    RVESPGui[p.Name.."_hl"]=hl
    RVESPGui[p.Name.."_refs"]={box=box,corners=corners,name=nl,weap=wl,dist=dl,wmark=wm,hbBG=hbBG,hbFill=hbFill,hl=hl}
end

local lastESPTime=0
AC("rvESP",RunService.Heartbeat:Connect(function()
    local now=os.clock(); if now-lastESPTime<0.1 then return end; lastESPTime=now
    local anyOn=RV.ESP.Box or RV.ESP.Name or RV.ESP.Weapon or RV.ESP.Distance or RV.ESP.Healthbar or RV.ESP.Skeleton or RV.ESP.Outline
    if not anyOn then for _,p in ipairs(Players:GetPlayers()) do ClearRVESP(p) end; return end
    local myHrp=root
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local c=p.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart"); local hum=c and c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then ClearRVESP(p); continue end
        if myHrp and (myHrp.Position-hrp.Position).Magnitude>RV.ESP.MaxDistance then ClearRVESP(p); continue end
        if not RVESPGui[p] then MakeRVESP(p) end
        local refs=RVESPGui[p.Name.."_refs"]; if not refs then continue end

        if refs.weap then local t=c:FindFirstChildOfClass("Tool"); refs.weap.Text=t and t.Name or ""; refs.weap.Visible=RV.ESP.Weapon end

        if refs.dist and myHrp then refs.dist.Text=math.floor((myHrp.Position-hrp.Position).Magnitude).."m"; refs.dist.Visible=RV.ESP.Distance end

        if refs.box then refs.box.Visible=RV.ESP.Box; for _,seg in ipairs(refs.corners) do seg.BackgroundColor3=RV.ESP.BoxFill end end

        if refs.hbBG then
            refs.hbBG.Visible=RV.ESP.Healthbar
            if RV.ESP.Healthbar then
                local rat=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                local targetSz=UDim2.new(1,0,rat,0)
                refs.hbFill.Size=refs.hbFill.Size:Lerp(targetSz,RV.ESP.HealthLerp)
                refs.hbFill.BackgroundColor3=Color3.fromRGB(math.floor((1-rat)*255),math.floor(rat*200),60)
            end
        end

        if refs.hl then refs.hl.Adornee=(RV.ESP.Skeleton or RV.ESP.Outline) and c or nil end

        if refs.name then refs.name.Visible=RV.ESP.Name end
        if refs.wmark then refs.wmark.Visible=RV.ESP.Watermark end
    end
    for p in pairs(RVESPGui) do
        if type(p)~="string" and (not p.Parent or not p.Character) then ClearRVESP(p) end
    end
end))
Players.PlayerRemoving:Connect(function(p) ClearRVESP(p) end)

local crossGui=RVNew("ScreenGui",{Name="UC_Cross",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
local crossRoot=RVNew("Frame",{Name="Cross",Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,Visible=false},crossGui)
local crossSpin=RVNew("Frame",{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},crossRoot)
local crossTxtBox=RVNew("Frame",{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},crossRoot)
local crossLines,crossOutlines={},{}
for i=1,4 do
    local o=RVNew("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,AnchorPoint=Vector2.new(0.5,0.5),ZIndex=2},crossSpin)
    crossOutlines[i]=o
    local f=RVNew("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=3},crossSpin)
    crossLines[i]=f
end
local crossLabel=RVNew("TextLabel",{Size=UDim2.new(0,300,0,20),Position=UDim2.new(0,-150,0,22),BackgroundTransparency=1,Font=Enum.Font.Arial,TextSize=14,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0,Text="uncode",Visible=false,ZIndex=4},crossTxtBox)
local crossTick=0; local crossMenuMode=false

RVBind(UIS.InputBegan:Connect(function(io,gpe)
    if gpe then return end
    if RV.Crosshair.Enabled and RV.Crosshair.FollowMouse and io.KeyCode==Enum.KeyCode.M then
        crossMenuMode=not crossMenuMode
    end
end))

AB("crosshair",Enum.RenderPriority.Camera.Value+20,function(dt)
    dt=math.clamp(dt or 0.016,0,0.1)
    crossRoot.Visible=RV.Crosshair.Enabled
    crossLabel.Visible=RV.Crosshair.Enabled and RV.Crosshair.Label
    if not RV.Crosshair.Enabled then return end
    crossTick = crossTick + dt
    local pos
    if RV.Crosshair.FollowMouse and not crossMenuMode then
        local ml=UIS:GetMouseLocation()
        local insetY=0; pcall(function() insetY=GuiSvc:GetGuiInset().Y end)
        pos=UDim2.new(0,ml.X,0,ml.Y-insetY)
    else pos=UDim2.new(0.5,0,0.5,0) end
    crossSpin.Position=pos; crossTxtBox.Position=pos
    local pf=RV.Crosshair.Pulse and math.sin(crossTick*3.5) or 0
    local pct=(pf+1)/2
    local rotSpd=(RV.Crosshair.RotSpeed or 0)*(0.35+pct*1.4)
    crossSpin.Rotation=(crossSpin.Rotation+rotSpd*dt)%360
    local syncCol=Color3.fromHSV((crossTick*0.05)%1,1,1)
    local cols=RV.Crosshair.RGB and {syncCol,syncCol,syncCol,syncCol} or {RV.Crosshair.C1,RV.Crosshair.C2,RV.Crosshair.C3,RV.Crosshair.C4}
    crossLabel.TextColor3=cols[1]; crossLabel.Text=RV.Crosshair.LabelText or "uncode"
    local len=math.max(1,RV.Crosshair.Size+(RV.Crosshair.Pulse and pf*5 or 0))
    local gap=RV.Crosshair.Gap; local th=math.max(1,RV.Crosshair.Thick)
    local geo={{ls=UDim2.new(0,th,0,len),lp=UDim2.new(0,0,0,-gap-len/2)},{ls=UDim2.new(0,th,0,len),lp=UDim2.new(0,0,0,gap+len/2)},{ls=UDim2.new(0,len,0,th),lp=UDim2.new(0,-gap-len/2,0,0)},{ls=UDim2.new(0,len,0,th),lp=UDim2.new(0,gap+len/2,0,0)}}
    for i=1,4 do
        local L,O,G=crossLines[i],crossOutlines[i],geo[i]
        L.Size=G.ls; L.Position=G.lp; L.BackgroundColor3=cols[i]
        O.Size=i<=2 and UDim2.new(0,th+2,0,len+2) or UDim2.new(0,len+2,0,th+2)
        O.Position=G.lp
    end
end)

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

local hud=RVNew("Frame",{Name="UC_HUD",Size=UDim2.new(0,220,0,64),BackgroundColor3=Color3.fromRGB(7,7,7),BorderSizePixel=0,Visible=false},visGui)
RVNew("UIStroke",{Color=Color3.fromRGB(184,172,255),Thickness=1,Transparency=0.4},hud)
RVNew("UICorner",{CornerRadius=UDim.new(0,6)},hud)
local hudName=RVNew("TextLabel",{Size=UDim2.new(1,-10,0,18),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=12,TextColor3=Color3.fromRGB(225,225,225),TextXAlignment=Enum.TextXAlignment.Left,Text="target: -"},hud)
local hudInfo=RVNew("TextLabel",{Size=UDim2.new(1,-10,0,16),Position=UDim2.new(0,5,0,22),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=11,TextColor3=Color3.fromRGB(150,150,150),TextXAlignment=Enum.TextXAlignment.Left,Text="hp: -  dist: -"},hud)
local hudBar=RVNew("Frame",{Size=UDim2.new(1,-10,0,8),Position=UDim2.new(0,5,0,42),BackgroundColor3=Color3.fromRGB(35,35,40),BorderSizePixel=0},hud)
RVNew("UICorner",{CornerRadius=UDim.new(0,3)},hudBar)
local hudFill=RVNew("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(184,172,255),BorderSizePixel=0},hudBar)
RVNew("UICorner",{CornerRadius=UDim.new(0,3)},hudFill)

local lastHUDTime=0
AC("thud",RunService.Heartbeat:Connect(function()
    local now=os.clock(); if now-lastHUDTime<0.1 then return end; lastHUDTime=now
    hud.Visible=RV.TargetHUD.Enabled
    if not RV.TargetHUD.Enabled then return end
    local t=getClosest(); local tc=t and t.Character
    local hrp=tc and tc:FindFirstChild("HumanoidRootPart")
    local hm=tc and tc:FindFirstChildOfClass("Humanoid")
    if not hrp or not hm then hudName.Text="target: -"; hudInfo.Text="hp: -  dist: -"; hudFill.Size=UDim2.new(0,0,1,0); return end
    local rat=math.clamp(hm.Health/math.max(hm.MaxHealth,1),0,1)
    hudName.Text="target: "..(t.DisplayName or t.Name)
    hudInfo.Text="hp: "..math.floor(hm.Health).."  dist: "..(root and math.floor((root.Position-hrp.Position).Magnitude) or "?").."m"
    hudFill.Size=hudFill.Size:Lerp(UDim2.new(rat,0,1,0),0.1)

    local vp=Camera.ViewportSize
    hud.Position=UDim2.new(RV.TargetHUD.OffX/100,0,RV.TargetHUD.OffY/100,0)
end))

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
print("[UNCODE v8] Rivals Visuals V2 integrated")

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
        Enabled=true, Mode="Cyber Blue", RGB=false,
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
        Name=true, NameA=Color3.fromRGB(184,172,255),
        Weapon=false, Distance=true,
        Healthbar=true,
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
