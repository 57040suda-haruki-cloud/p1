    if show then
        _fovCircle.Position = Camera.ViewportSize/2
        _fovCircle.Radius = Options.KX_FOV and Options.KX_FOV.Value or 120
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
