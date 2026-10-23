--!nocheck
-- UNCODE v2 | Rivals HvH | Single-file, no external dependencies
-- UI style: dark bg (15,15,15), blue border (0,100,255), Code font — like message_2

if getgenv().UNCODE_V2_LOADED then
    warn("[UNCODE] Already loaded, reloading...")
    if getgenv().UNCODE_V2_GUI then pcall(function() getgenv().UNCODE_V2_GUI:Destroy() end) end
    if getgenv().UNCODE_V2_CONNS then
        for _, c in ipairs(getgenv().UNCODE_V2_CONNS) do pcall(function() c:Disconnect() end) end
    end
end
getgenv().UNCODE_V2_LOADED = true
getgenv().UNCODE_V2_CONNS = {}

print("[UNCODE v2] Starting...")

-- ── Services ──────────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting       = game:GetService("Lighting")
local Debris         = game:GetService("Debris")
local CoreGui        = game:GetService("CoreGui")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera

local LocalPlayer    = Players.LocalPlayer
if not game:IsLoaded() then game.Loaded:Wait() end
if not LocalPlayer   then Players:GetPropertyChangedSignal("LocalPlayer"):Wait(); LocalPlayer = Players.LocalPlayer end

-- ── Colors (message_2 aesthetic) ──────────────────────────────────────────────
local C_BG      = Color3.fromRGB(10, 10, 10)
local C_PANEL   = Color3.fromRGB(15, 15, 15)
local C_BUTTON  = Color3.fromRGB(22, 22, 22)
local C_BORDER  = Color3.fromRGB(0, 100, 255)
local C_ACC     = Color3.fromRGB(40, 120, 255)
local C_ACC2    = Color3.fromRGB(80, 160, 255)
local C_ON      = Color3.fromRGB(0, 200, 80)
local C_OFF     = Color3.fromRGB(60, 60, 60)
local C_TXT     = Color3.fromRGB(230, 230, 230)
local C_DIM     = Color3.fromRGB(140, 140, 140)
local C_RED     = Color3.fromRGB(220, 50, 50)
local C_TITLE   = Color3.fromRGB(255, 255, 255)

-- ── Config ────────────────────────────────────────────────────────────────────
local Config = {
    -- Rage
    Rage = {
        Enabled      = false,
        VoidSpam     = false,
        Weapon       = "Knife",
        AimRandomize = 0.35,
    },
    AntiAim = {
        Enabled      = false,
        Pitch        = 0,
        Yaw          = 180,
        FloorHide    = false,
    },
    -- ESP
    ESP = {
        Enabled      = false,
        Box          = true,
        Name         = true,
        Healthbar    = true,
        Distance     = true,
        Skeleton     = false,
        MaxDist      = 1200,
        BoxColor     = Color3.fromRGB(0, 120, 255),
        NameColor    = Color3.fromRGB(230, 230, 230),
        HBColor      = Color3.fromRGB(80, 220, 80),
        SkelColor    = Color3.fromRGB(255, 255, 255),
        TeamCheck    = true,
    },
    -- Visuals
    Visuals = {
        Aura         = false,
        AuraMode     = "Cyber Blue",
        AuraRGB      = false,
        Tracers      = false,
        TracerColor  = Color3.fromRGB(0, 120, 255),
        Crosshair    = false,
        CrossColor   = Color3.fromRGB(255, 255, 255),
        CrossGap     = 8,
        CrossSize    = 17,
        HitFX        = false,
        HitFXStyle   = "dot",
        HitSound     = false,
        WorldFX      = false,
        FOV          = false,
        FOVValue     = 90,
        ChamsEnabled = false,
        ChamsColor   = Color3.fromRGB(255, 0, 100),
        ChamsMat     = "Neon",
        ChamsTrans   = 50,
    },
    -- Misc
    Misc = {
        Watermark    = true,
        ClickTP      = false,
        InfJump      = false,
        UnlockFPS    = false,
        TargetFPS    = 60,
        AvatarSpoof  = false,
    },
}

-- ── State ─────────────────────────────────────────────────────────────────────
local State = {
    Conns         = getgenv().UNCODE_V2_CONNS,
    ESPObjects    = {},
    AuraObjs      = {},
    TracerPool    = {},
    CrosshairObj  = nil,
    WatermarkObj  = nil,
    HitFXPool     = {},
    ChamsMap      = {},
    Ragebot       = {
        attackNum      = 0,
        heavyAttackNum = 0,
        lastAttack     = 0,
        reloadCooldown = 0,
        characters     = {},
        priorities     = {},
    },
    AntiAimBound  = false,
    LastTracerT   = 0,
    LastHUD       = 0,
    Hue           = 0,
}

local function Bind(c)
    table.insert(State.Conns, c)
    return c
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function NewI(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() o[k] = v end) end
    end
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

local function IsEnemy(pl)
    if pl == LocalPlayer then return false end
    if Config.ESP.TeamCheck and pl.Team and pl.Team == LocalPlayer.Team then return false end
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
    local ok, s = pcall(function()
        return Camera:WorldToViewportPoint(pos)
    end)
    if not ok then return nil, nil, nil end
    return s.X, s.Y, s.Z
end

-- ── UI Builder ────────────────────────────────────────────────────────────────
local targetGui = (type(gethui) == "function" and gethui()) or CoreGui
pcall(function()
    local old = targetGui:FindFirstChild("UNCODE_V2")
    if old then old:Destroy() end
end)

local ScreenGui = NewI("ScreenGui", {
    Name           = "UNCODE_V2",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, targetGui)
getgenv().UNCODE_V2_GUI = ScreenGui

-- Main window
local WIN_W, WIN_H = 420, 320
local MainFrame = NewI("Frame", {
    Name            = "MainFrame",
    Size            = UDim2.new(0, WIN_W, 0, WIN_H),
    Position        = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = C_PANEL,
    BorderColor3    = C_BORDER,
    BorderSizePixel = 2,
    Active          = true,
    Draggable       = true,
}, ScreenGui)

-- Title bar
local TitleBar = NewI("Frame", {
    Name            = "TitleBar",
    Size            = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = C_BG,
    BorderSizePixel = 0,
}, MainFrame)
NewI("TextLabel", {
    Name            = "Title",
    Size            = UDim2.new(1, -50, 1, 0),
    Position        = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text            = "UNCODE v2 | Rivals HvH",
    TextColor3      = C_TITLE,
    TextSize        = 13,
    Font            = Enum.Font.Code,
    TextXAlignment  = Enum.TextXAlignment.Left,
}, TitleBar)

-- Toggle button (minimize)
local Visible = true
local ToggleBtn = NewI("TextButton", {
    Name            = "ToggleBtn",
    Size            = UDim2.new(0, 40, 1, 0),
    Position        = UDim2.new(1, -40, 0, 0),
    BackgroundColor3 = C_BUTTON,
    BorderSizePixel = 0,
    Text            = "_",
    TextColor3      = C_DIM,
    TextSize        = 14,
    Font            = Enum.Font.Code,
}, TitleBar)
ToggleBtn.MouseButton1Click:Connect(function()
    Visible = not Visible
    MainFrame.Size = Visible
        and UDim2.new(0, WIN_W, 0, WIN_H)
        or  UDim2.new(0, WIN_W, 0, 28)
    ToggleBtn.Text = Visible and "_" or "^"
end)

-- Tab bar
local TAB_H = 26
local TabBar = NewI("Frame", {
    Name            = "TabBar",
    Size            = UDim2.new(1, 0, 0, TAB_H),
    Position        = UDim2.new(0, 0, 0, 28),
    BackgroundColor3 = C_BG,
    BorderSizePixel = 0,
}, MainFrame)

-- Content area
local ContentArea = NewI("Frame", {
    Name            = "ContentArea",
    Size            = UDim2.new(1, 0, 1, -(28 + TAB_H)),
    Position        = UDim2.new(0, 0, 0, 28 + TAB_H),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, MainFrame)

-- Tab system
local TABS = {}
local ActiveTab = nil
local TAB_NAMES = {"RAGE", "ESP", "VISUAL", "MISC"}
local TAB_W = WIN_W / #TAB_NAMES

local function CreateTabPage(name)
    return NewI("ScrollingFrame", {
        Name            = name .. "_Page",
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C_BORDER,
        Visible         = false,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, ContentArea)
end

local function SelectTab(name)
    if ActiveTab == name then return end
    ActiveTab = name
    for n, t in pairs(TABS) do
        t.Page.Visible = (n == name)
        t.Btn.BackgroundColor3 = (n == name) and C_ACC or C_BUTTON
        t.Btn.TextColor3 = (n == name) and C_TITLE or C_DIM
    end
end

for i, name in ipairs(TAB_NAMES) do
    local page = CreateTabPage(name)
    local btn = NewI("TextButton", {
        Name            = name .. "_Tab",
        Size            = UDim2.new(0, TAB_W, 1, 0),
        Position        = UDim2.new(0, (i-1) * TAB_W, 0, 0),
        BackgroundColor3 = C_BUTTON,
        BorderSizePixel = 0,
        Text            = name,
        TextColor3      = C_DIM,
        TextSize        = 11,
        Font            = Enum.Font.Code,
    }, TabBar)
    TABS[name] = { Btn = btn, Page = page }
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end
SelectTab("RAGE")

-- ── UI Controls ───────────────────────────────────────────────────────────────
local function AddPadding(page)
    NewI("UIPadding", {
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    }, page)
    NewI("UIListLayout", {
        SortOrder   = Enum.SortOrder.LayoutOrder,
        Padding     = UDim.new(0, 4),
    }, page)
end

local function SectionLabel(page, text, order)
    local lbl = NewI("TextLabel", {
        Name            = "Section_" .. text,
        Size            = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text            = "── " .. text .. " ──",
        TextColor3      = C_ACC2,
        TextSize        = 10,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Left,
        LayoutOrder     = order or 0,
    }, page)
    return lbl
end

local function MakeToggle(page, label, getter, setter, order)
    local row = NewI("Frame", {
        Name            = label .. "_Row",
        Size            = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = C_BUTTON,
        BorderColor3    = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 1,
        LayoutOrder     = order or 0,
    }, page)
    NewI("TextLabel", {
        Name            = "Label",
        Size            = UDim2.new(1, -54, 1, 0),
        Position        = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text            = label,
        TextColor3      = C_TXT,
        TextSize        = 11,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, row)
    local btn = NewI("TextButton", {
        Name            = "Toggle",
        Size            = UDim2.new(0, 46, 0, 18),
        Position        = UDim2.new(1, -50, 0.5, -9),
        BackgroundColor3 = getter() and C_ON or C_OFF,
        BorderSizePixel = 0,
        Text            = getter() and "ON" or "OFF",
        TextColor3      = getter() and C_TITLE or C_DIM,
        TextSize        = 10,
        Font            = Enum.Font.Code,
    }, row)
    local function refresh()
        local v = getter()
        btn.BackgroundColor3 = v and C_ON or C_OFF
        btn.Text = v and "ON" or "OFF"
        btn.TextColor3 = v and C_TITLE or C_DIM
    end
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)
    return row, refresh
end

local function MakeSlider(page, label, min, max, getter, setter, order)
    local SLIDER_W = WIN_W - 16
    local TRACK_W  = SLIDER_W - 80
    local row = NewI("Frame", {
        Name            = label .. "_SlRow",
        Size            = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = C_BUTTON,
        BorderColor3    = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 1,
        LayoutOrder     = order or 0,
    }, page)
    NewI("TextLabel", {
        Name            = "Label",
        Size            = UDim2.new(0, 70, 1, 0),
        Position        = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text            = label,
        TextColor3      = C_TXT,
        TextSize        = 10,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, row)
    local track = NewI("Frame", {
        Name            = "Track",
        Size            = UDim2.new(1, -90, 0, 6),
        Position        = UDim2.new(0, 78, 0.5, -3),
        BackgroundColor3 = C_OFF,
        BorderSizePixel = 0,
    }, row)
    local fill = NewI("Frame", {
        Name            = "Fill",
        Size            = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C_ACC,
        BorderSizePixel = 0,
    }, track)
    local valLbl = NewI("TextLabel", {
        Name            = "Val",
        Size            = UDim2.new(0, 36, 1, 0),
        Position        = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text            = tostring(getter()),
        TextColor3      = C_DIM,
        TextSize        = 10,
        Font            = Enum.Font.Code,
    }, row)
    local function setVal(v)
        v = math.clamp(math.round(v), min, max)
        setter(v)
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valLbl.Text = tostring(v)
    end
    setVal(getter())
    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            setVal(min + pct * (max - min))
        end
    end)
    return row
end

-- ── Build Tab: RAGE ───────────────────────────────────────────────────────────
do
    local page = TABS["RAGE"].Page
    AddPadding(page)

    SectionLabel(page, "Ragebot", 1)
    MakeToggle(page, "Ragebot Enabled", function() return Config.Rage.Enabled end, function(v) Config.Rage.Enabled = v end, 2)
    MakeToggle(page, "Void Spam", function() return Config.Rage.VoidSpam end, function(v) Config.Rage.VoidSpam = v end, 3)
    MakeSlider(page, "Aim Rand", 0, 100,
        function() return math.floor(Config.Rage.AimRandomize * 100) end,
        function(v) Config.Rage.AimRandomize = v / 100 end, 4)

    SectionLabel(page, "Anti-Aim", 10)
    MakeToggle(page, "Anti-Aim", function() return Config.AntiAim.Enabled end, function(v) Config.AntiAim.Enabled = v end, 11)
    MakeSlider(page, "Pitch", -90, 90,
        function() return Config.AntiAim.Pitch end,
        function(v) Config.AntiAim.Pitch = v end, 12)
    MakeSlider(page, "Yaw", 0, 360,
        function() return Config.AntiAim.Yaw end,
        function(v) Config.AntiAim.Yaw = v end, 13)
    MakeToggle(page, "Floor Hide", function() return Config.AntiAim.FloorHide end, function(v) Config.AntiAim.FloorHide = v end, 14)
end

-- ── Build Tab: ESP ────────────────────────────────────────────────────────────
do
    local page = TABS["ESP"].Page
    AddPadding(page)

    SectionLabel(page, "ESP", 1)
    MakeToggle(page, "ESP Enabled", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end, 2)
    MakeToggle(page, "Box", function() return Config.ESP.Box end, function(v) Config.ESP.Box = v end, 3)
    MakeToggle(page, "Name", function() return Config.ESP.Name end, function(v) Config.ESP.Name = v end, 4)
    MakeToggle(page, "Health Bar", function() return Config.ESP.Healthbar end, function(v) Config.ESP.Healthbar = v end, 5)
    MakeToggle(page, "Distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance = v end, 6)
    MakeToggle(page, "Skeleton", function() return Config.ESP.Skeleton end, function(v) Config.ESP.Skeleton = v end, 7)
    MakeToggle(page, "Team Check", function() return Config.ESP.TeamCheck end, function(v) Config.ESP.TeamCheck = v end, 8)
    MakeSlider(page, "Max Dist", 100, 3000,
        function() return Config.ESP.MaxDist end,
        function(v) Config.ESP.MaxDist = v end, 9)
end

-- ── Build Tab: VISUAL ─────────────────────────────────────────────────────────
do
    local page = TABS["VISUAL"].Page
    AddPadding(page)

    SectionLabel(page, "Aura", 1)
    MakeToggle(page, "Aura", function() return Config.Visuals.Aura end, function(v) Config.Visuals.Aura = v end, 2)
    MakeToggle(page, "Aura RGB", function() return Config.Visuals.AuraRGB end, function(v) Config.Visuals.AuraRGB = v end, 3)

    SectionLabel(page, "Tracers", 10)
    MakeToggle(page, "Tracers", function() return Config.Visuals.Tracers end, function(v) Config.Visuals.Tracers = v end, 11)

    SectionLabel(page, "Crosshair", 20)
    MakeToggle(page, "Crosshair", function() return Config.Visuals.Crosshair end, function(v) Config.Visuals.Crosshair = v end, 21)
    MakeSlider(page, "CH Gap", 2, 30,
        function() return Config.Visuals.CrossGap end,
        function(v) Config.Visuals.CrossGap = v end, 22)
    MakeSlider(page, "CH Size", 5, 50,
        function() return Config.Visuals.CrossSize end,
        function(v) Config.Visuals.CrossSize = v end, 23)

    SectionLabel(page, "Chams", 30)
    MakeToggle(page, "Chams (Enemies)", function() return Config.Visuals.ChamsEnabled end, function(v) Config.Visuals.ChamsEnabled = v end, 31)
    MakeSlider(page, "Chams Trans", 0, 100,
        function() return Config.Visuals.ChamsTrans end,
        function(v) Config.Visuals.ChamsTrans = v end, 32)

    SectionLabel(page, "Hit FX", 40)
    MakeToggle(page, "Hit FX", function() return Config.Visuals.HitFX end, function(v) Config.Visuals.HitFX = v end, 41)
    MakeToggle(page, "Hit Sound", function() return Config.Visuals.HitSound end, function(v) Config.Visuals.HitSound = v end, 42)

    SectionLabel(page, "World", 50)
    MakeToggle(page, "World FX (Night)", function() return Config.Visuals.WorldFX end, function(v)
        Config.Visuals.WorldFX = v
        pcall(function()
            if v then
                Lighting.Ambient = Color3.fromRGB(40, 80, 255)
                Lighting.Brightness = 3.7
                Lighting.ClockTime = 0
            else
                Lighting.Ambient = Color3.fromRGB(127, 127, 127)
                Lighting.Brightness = 1
                Lighting.ClockTime = 14
            end
        end)
    end, 51)
    MakeToggle(page, "Unlock FPS", function() return Config.Misc.UnlockFPS end, function(v)
        Config.Misc.UnlockFPS = v
        pcall(function()
            if v then
                setfpscap(Config.Misc.TargetFPS)
            else
                setfpscap(60)
            end
        end)
    end, 52)
    MakeSlider(page, "FPS Cap", 30, 240,
        function() return Config.Misc.TargetFPS end,
        function(v) Config.Misc.TargetFPS = v; if Config.Misc.UnlockFPS then pcall(setfpscap, v) end end, 53)
end

-- ── Build Tab: MISC ───────────────────────────────────────────────────────────
do
    local page = TABS["MISC"].Page
    AddPadding(page)

    SectionLabel(page, "Player", 1)
    MakeToggle(page, "Inf Jump", function() return Config.Misc.InfJump end, function(v)
        Config.Misc.InfJump = v
    end, 2)
    MakeToggle(page, "Click TP", function() return Config.Misc.ClickTP end, function(v)
        Config.Misc.ClickTP = v
    end, 3)

    SectionLabel(page, "UI", 10)
    MakeToggle(page, "Watermark", function() return Config.Misc.Watermark end, function(v)
        Config.Misc.Watermark = v
        if State.WatermarkObj then State.WatermarkObj.Visible = v end
    end, 11)
end

-- ── Watermark ────────────────────────────────────────────────────────────────
local WmFrame = NewI("Frame", {
    Name            = "Watermark",
    Size            = UDim2.new(0, 220, 0, 22),
    Position        = UDim2.new(1, -228, 0, 4),
    BackgroundColor3 = C_PANEL,
    BorderColor3    = C_BORDER,
    BorderSizePixel = 1,
    Visible         = Config.Misc.Watermark,
}, ScreenGui)
State.WatermarkObj = WmFrame
local WmLabel = NewI("TextLabel", {
    Name            = "Text",
    Size            = UDim2.new(1, -8, 1, 0),
    Position        = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1,
    Text            = "UNCODE v2 | Rivals",
    TextColor3      = C_ACC2,
    TextSize        = 11,
    Font            = Enum.Font.Code,
    TextXAlignment  = Enum.TextXAlignment.Left,
}, WmFrame)

-- ── Ragebot Logic ─────────────────────────────────────────────────────────────
local function RandVec()
    return Random.new():NextUnitVector()
end
local function GUID()
    return HttpService:GenerateGUID(false)
end

-- Track characters
local function TrackChars()
    local function add(plr, char)
        State.Ragebot.characters[plr] = char
    end
    local function rem(plr)
        State.Ragebot.characters[plr] = nil
        State.Ragebot.priorities[plr] = nil
    end
    local function hook(plr)
        if plr.Character then add(plr, plr.Character) end
        Bind(plr.CharacterAdded:Connect(function(c) add(plr, c) end))
        Bind(plr.CharacterRemoving:Connect(function() rem(plr) end))
    end
    for _, p in ipairs(Players:GetPlayers()) do hook(p) end
    Bind(Players.PlayerAdded:Connect(hook))
end
TrackChars()

local function IsAlive(char)
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function GetHitbox(char)
    if not char then return nil end
    return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function GetPriorityTarget()
    local origin = Camera and Camera.CFrame.Position
    if not origin then return nil end
    local best, bestDist = nil, math.huge
    for plr, char in pairs(State.Ragebot.characters) do
        if plr ~= LocalPlayer and IsEnemy(plr) and IsAlive(char) then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - origin).Magnitude
                local prio = State.Ragebot.priorities[plr] or 0
                local score = dist - prio * 100
                if score < bestDist then
                    bestDist = score
                    best = char
                end
            end
        end
    end
    return best
end

local UseItemRemote = nil
pcall(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if Remotes then
        local Fighter = Remotes:FindFirstChild("Fighter")
        if Fighter then UseItemRemote = Fighter:FindFirstChild("UseItem") end
    end
end)

local function FireUseItem(payload)
    if not UseItemRemote then return false end
    local ok = pcall(function() UseItemRemote:FireServer(payload) end)
    return ok
end

local function GetEquipped(char)
    return char and char:FindFirstChild("EquippedItem")
end

local function VoidSpamMelee(char, target)
    local item = GetEquipped(char)
    if not item then return false end
    local info = item:FindFirstChild("Info") and item.Info
    if info and info:GetAttribute and info:GetAttribute("Type") ~= "Melee" then return false end

    local now = tick()
    local cooldown = 0.2
    if now - State.Ragebot.lastAttack < cooldown then return false end
    State.Ragebot.lastAttack = now

    State.Ragebot.heavyAttackNum = State.Ragebot.heavyAttackNum + 1
    local hb = GetHitbox(target)
    if not hb then return false end
    local aimPos = hb.Position + RandVec() * Config.Rage.AimRandomize

    FireUseItem({
        id            = GUID(),
        objectId      = GUID(),
        item          = Config.Rage.Weapon,
        position      = aimPos,
        heavyAttackNum = State.Ragebot.heavyAttackNum,
        rotation      = hb.CFrame.Rotation,
        one           = Vector3.one,
        startAiming   = true,
        packed        = {"\x00", "\x01", "\x02", "\x03"},
    })
    pcall(function() item:StartAiming(aimPos) end)
    pcall(function() item:HeavyAttack(aimPos) end)
    return true
end

local function VoidSpamRanged(char, target)
    local item = GetEquipped(char)
    if not item then return false end

    State.Ragebot.attackNum = State.Ragebot.attackNum + 1
    local hb = GetHitbox(target)
    if not hb then return false end
    local aimPos = hb.Position + RandVec() * Config.Rage.AimRandomize

    FireUseItem({
        id         = GUID(),
        objectId   = GUID(),
        item       = Config.Rage.Weapon,
        position   = aimPos,
        attackNum  = State.Ragebot.attackNum,
        rotation   = hb.CFrame.Rotation,
        one        = Vector3.one,
        packed     = {"\x00", "\x01", "\x02", "\x03"},
    })
    pcall(function() item:StartShooting(aimPos) end)
    return true
end

local function RagebotLoop()
    if not Config.Rage.Enabled or not Config.Rage.VoidSpam then return end
    local myChar = GetChar()
    if not myChar then return end
    local target = GetPriorityTarget()
    if not target then return end
    local item = GetEquipped(myChar)
    if not item then return end
    local info = item:FindFirstChild("Info")
    local wType = info and info:GetAttribute and info:GetAttribute("Type") or ""
    if wType == "Melee" then
        VoidSpamMelee(myChar, target)
    elseif wType == "Gun" then
        VoidSpamRanged(myChar, target)
    end
end

-- Anti-Aim
local function BindAntiAim()
    if State.AntiAimBound then return end
    State.AntiAimBound = true
    pcall(function()
        RunService:BindToRenderStep("UNCODEAntiAim", Enum.RenderPriority.Camera.Value, function()
            if not Config.AntiAim.Enabled then
                State.AntiAimBound = false
                pcall(function() RunService:UnbindFromRenderStep("UNCODEAntiAim") end)
                return
            end
            local char = GetChar()
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local rep = char:FindFirstChild("PhysicsRepRootPart") or hrp
            if Config.AntiAim.FloorHide and hrp.Position.Y < 8 then
                rep.CFrame = hrp.CFrame * CFrame.new(0, -3, 0)
                return
            end
            local yaw   = math.rad(Config.AntiAim.Yaw)
            local pitch = math.rad(Config.AntiAim.Pitch)
            local base  = hrp.CFrame
            rep.CFrame  = CFrame.new(base.Position)
                * CFrame.Angles(0, yaw, 0)
                * CFrame.Angles(pitch, 0, 0)
        end)
    end)
end

-- ── ESP Logic ─────────────────────────────────────────────────────────────────
local ESPGui = NewI("ScreenGui", {
    Name           = "UNCODE_ESP",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, targetGui)

local function CreateESPForPlayer(plr)
    if State.ESPObjects[plr] then return end
    local obj = {
        Box     = NewI("SelectionBox", { Color3 = Config.ESP.BoxColor, LineThickness = 0.04, SurfaceTransparency = 1 }, Camera),
        BoxLine = nil,
        NameLbl = NewI("BillboardGui", {
            Name          = plr.Name .. "_ESPBB",
            Size          = UDim2.new(0, 80, 0, 14),
            AlwaysOnTop   = true,
            ResetOnSpawn  = false,
        }, ESPGui),
        HBFrame  = nil,
        HBFill   = nil,
        DistLbl  = nil,
        SkelLines = {},
    }

    local nameLabel = NewI("TextLabel", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = plr.Name,
        TextColor3      = Config.ESP.NameColor,
        TextSize        = 11,
        Font            = Enum.Font.Code,
    }, obj.NameLbl)

    -- Health bar (frame-based, not billboard)
    obj.HBGui = NewI("BillboardGui", {
        Name          = plr.Name .. "_ESPHB",
        Size          = UDim2.new(0, 6, 0, 40),
        AlwaysOnTop   = true,
        ResetOnSpawn  = false,
    }, ESPGui)
    obj.HBBg = NewI("Frame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
    }, obj.HBGui)
    obj.HBFill = NewI("Frame", {
        Size            = UDim2.new(1, 0, 1, 0),
        Position        = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.ESP.HBColor,
        BorderSizePixel = 0,
    }, obj.HBBg)

    -- Distance label
    obj.DistGui = NewI("BillboardGui", {
        Name          = plr.Name .. "_ESPD",
        Size          = UDim2.new(0, 60, 0, 12),
        AlwaysOnTop   = true,
        ResetOnSpawn  = false,
    }, ESPGui)
    obj.DistLbl = NewI("TextLabel", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = "",
        TextColor3      = C_DIM,
        TextSize        = 9,
        Font            = Enum.Font.Code,
    }, obj.DistGui)

    State.ESPObjects[plr] = obj
end

local function RemoveESPForPlayer(plr)
    local obj = State.ESPObjects[plr]
    if not obj then return end
    pcall(function() obj.Box:Destroy() end)
    pcall(function() obj.NameLbl:Destroy() end)
    pcall(function() obj.HBGui:Destroy() end)
    pcall(function() obj.DistGui:Destroy() end)
    State.ESPObjects[plr] = nil
end

local function UpdateESP()
    if not Config.ESP.Enabled then
        for plr in pairs(State.ESPObjects) do
            RemoveESPForPlayer(plr)
        end
        return
    end

    local myHRP = GetHRP()
    local myPos = myHRP and myHRP.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            local char = GetChar(plr)
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if char and hrp then
                local dist = myPos and (hrp.Position - myPos).Magnitude or 0
                if dist <= Config.ESP.MaxDist then
                    if not State.ESPObjects[plr] then CreateESPForPlayer(plr) end
                    local obj = State.ESPObjects[plr]
                    -- Box
                    if Config.ESP.Box then
                        obj.Box.Adornee = char
                        obj.Box.Visible = true
                        obj.Box.Color3  = Config.ESP.BoxColor
                    else
                        obj.Box.Visible = false
                    end
                    -- Name
                    obj.NameLbl.Visible  = Config.ESP.Name
                    obj.NameLbl.Adornee  = hrp
                    obj.NameLbl.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
                    -- Health
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if Config.ESP.Healthbar and hum then
                        obj.HBGui.Visible = true
                        obj.HBGui.Adornee = hrp
                        obj.HBGui.StudsOffsetWorldSpace = Vector3.new(-2, 0, 0)
                        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        obj.HBFill.Size = UDim2.new(1, 0, pct, 0)
                        obj.HBFill.Position = UDim2.new(0, 0, 1 - pct, 0)
                        local g = pct
                        local r = 1 - pct
                        obj.HBFill.BackgroundColor3 = Color3.new(r, g, 0.1)
                    else
                        obj.HBGui.Visible = false
                    end
                    -- Distance
                    if Config.ESP.Distance then
                        obj.DistGui.Visible = true
                        obj.DistGui.Adornee = hrp
                        obj.DistGui.StudsOffsetWorldSpace = Vector3.new(0, -2.5, 0)
                        obj.DistLbl.Text = math.floor(dist) .. "m"
                    else
                        obj.DistGui.Visible = false
                    end
                    goto continue
                end
            end
            RemoveESPForPlayer(plr)
        else
            RemoveESPForPlayer(plr)
        end
        ::continue::
    end

    -- Clean disconnected players
    for plr in pairs(State.ESPObjects) do
        if not plr.Parent then RemoveESPForPlayer(plr) end
    end
end

Bind(Players.PlayerRemoving:Connect(function(plr)
    RemoveESPForPlayer(plr)
end))

-- ── Chams (enemy highlight) ───────────────────────────────────────────────────
local function ApplyChams(char, enable)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            pcall(function()
                if enable then
                    if not part:GetAttribute("UNCODE_OColor") then
                        part:SetAttribute("UNCODE_OColor", part.Color)
                        part:SetAttribute("UNCODE_OMat", tostring(part.Material))
                        part:SetAttribute("UNCODE_OTrans", part.Transparency)
                    end
                    part.Color = Config.Visuals.ChamsColor
                    if Enum.Material[Config.Visuals.ChamsMat] then
                        part.Material = Enum.Material[Config.Visuals.ChamsMat]
                    end
                    part.Transparency = math.clamp(1 - Config.Visuals.ChamsTrans / 100, 0, 1)
                else
                    if part:GetAttribute("UNCODE_OColor") then
                        local c = part:GetAttribute("UNCODE_OColor")
                        if typeof(c) == "Color3" then part.Color = c end
                        local m = part:GetAttribute("UNCODE_OMat")
                        if Enum.Material[m] then part.Material = Enum.Material[m] end
                        local t = part:GetAttribute("UNCODE_OTrans")
                        if type(t) == "number" then part.Transparency = t end
                        part:SetAttribute("UNCODE_OColor", nil)
                    end
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
                local ok = Config.Visuals.ChamsEnabled
                local prev = State.ChamsMap[plr]
                if ok ~= prev then
                    State.ChamsMap[plr] = ok
                    ApplyChams(char, ok)
                end
            end
        end
    end
end

-- ── Aura ──────────────────────────────────────────────────────────────────────
local AuraPresets = {
    ["Cyber Blue"]   = {Color3.fromRGB(0, 170, 255),   Color3.fromRGB(0, 255, 255)},
    ["Blood Red"]    = {Color3.fromRGB(255, 20, 40),   Color3.fromRGB(255, 120, 0)},
    ["Venom Green"]  = {Color3.fromRGB(0, 255, 120),   Color3.fromRGB(180, 255, 0)},
    ["Royal Purple"] = {Color3.fromRGB(150, 0, 255),   Color3.fromRGB(255, 0, 200)},
    ["Shadow"]       = {Color3.fromRGB(20, 20, 25),    Color3.fromRGB(120, 0, 255)},
}

local AuraActive = false

local function ClearAura()
    for _, v in ipairs(State.AuraObjs) do
        pcall(function() if typeof(v) == "Instance" and v.Parent then v:Destroy() end end)
    end
    State.AuraObjs = {}
    AuraActive = false
end

local function BuildAura()
    ClearAura()
    if not Config.Visuals.Aura then return end
    local char = GetChar()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pr = AuraPresets[Config.Visuals.AuraMode] or AuraPresets["Cyber Blue"]
    local main, second = pr[1], pr[2]
    if Config.Visuals.AuraRGB then
        State.Hue = (State.Hue + 0.04) % 1
        main   = Color3.fromHSV(State.Hue, 0.9, 1)
        second = Color3.fromHSV((State.Hue + 0.15) % 1, 0.9, 1)
    end

    local folder = NewI("Folder", {Name = "UNCODE_Aura"}, char)
    table.insert(State.AuraObjs, folder)

    local pl = NewI("PointLight", {Name = "UNCODE_L", Color = main, Brightness = 2, Range = 16, Shadows = false}, hrp)
    table.insert(State.AuraObjs, pl)

    local a0 = NewI("Attachment", {Name = "UNCODE_A0", Position = Vector3.new(0, -1.2, 0)}, hrp)
    local a1 = NewI("Attachment", {Name = "UNCODE_A1", Position = Vector3.new(0, 2.5, 0)}, hrp)
    table.insert(State.AuraObjs, a0)
    table.insert(State.AuraObjs, a1)

    local pe = NewI("ParticleEmitter", {
        Texture       = "rbxassetid://243098098",
        Color         = ColorSequence.new({ColorSequenceKeypoint.new(0, second), ColorSequenceKeypoint.new(1, main)}),
        Transparency  = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)}),
        Size          = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.05)}),
        Speed         = NumberRange.new(3, 6),
        Lifetime      = NumberRange.new(0.6, 1.2),
        Rate          = 26,
        EmissionDirection = Enum.NormalId.Top,
        SpreadAngle   = Vector2.new(35, 35),
        Acceleration  = Vector3.new(0, 6, 0),
        LightEmission = 1,
    }, a0)
    table.insert(State.AuraObjs, pe)

    local ring = NewI("Part", {
        Name          = "UNCODE_Ring",
        Shape         = Enum.PartType.Cylinder,
        Size          = Vector3.new(0.2, 6.5, 6.5),
        Transparency  = 0.55,
        CanCollide    = false,
        CanQuery      = false,
        CanTouch      = false,
        Anchored      = true,
        Massless      = true,
        Material      = Enum.Material.Neon,
        Color         = main,
    }, folder)
    table.insert(State.AuraObjs, ring)
    State.AuraRing = ring
    State.AuraHRP  = hrp

    -- Limb trails
    for _, ln in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
        local limb = char:FindFirstChild(ln)
        if limb and limb:IsA("BasePart") then
            local t0 = NewI("Attachment", {Position = Vector3.new(0, 0.8, 0)}, limb)
            local t1 = NewI("Attachment", {Position = Vector3.new(0, -0.8, 0)}, limb)
            local tr = NewI("Trail", {
                Color        = ColorSequence.new({ColorSequenceKeypoint.new(0, second), ColorSequenceKeypoint.new(1, main)}),
                Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}),
                Lifetime     = 0.45,
                LightEmission = 1,
                LightInfluence = 0,
                Attachment0  = t0,
                Attachment1  = t1,
            }, limb)
            table.insert(State.AuraObjs, t0)
            table.insert(State.AuraObjs, t1)
            table.insert(State.AuraObjs, tr)
        end
    end

    AuraActive = true
end

-- ── Crosshair ─────────────────────────────────────────────────────────────────
local CrosshairGui = NewI("ScreenGui", {
    Name          = "UNCODE_CH",
    ResetOnSpawn  = false,
}, targetGui)
local CrossLines = {}
for i = 1, 4 do
    CrossLines[i] = NewI("Frame", {
        BackgroundColor3 = Config.Visuals.CrossColor,
        BorderSizePixel  = 0,
        Visible          = false,
    }, CrosshairGui)
end

local function UpdateCrosshair()
    local en = Config.Visuals.Crosshair
    local vp = Camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local g  = Config.Visuals.CrossGap
    local sz = Config.Visuals.CrossSize
    -- Top, Bottom, Left, Right
    local offsets = {
        {x = cx - 1, y = cy - g - sz, w = 2,  h = sz},
        {x = cx - 1, y = cy + g,      w = 2,  h = sz},
        {x = cx - g - sz, y = cy - 1, w = sz, h = 2},
        {x = cx + g,      y = cy - 1, w = sz, h = 2},
    }
    for i, line in ipairs(CrossLines) do
        line.Visible = en
        if en then
            local o = offsets[i]
            line.Position = UDim2.new(0, o.x, 0, o.y)
            line.Size     = UDim2.new(0, o.w, 0, o.h)
            line.BackgroundColor3 = Config.Visuals.CrossColor
        end
    end
end

-- ── Tracers ───────────────────────────────────────────────────────────────────
local TracerGui = NewI("ScreenGui", {
    Name          = "UNCODE_Tracers",
    ResetOnSpawn  = false,
}, targetGui)

local function SpawnTracer(fromPos, toPos)
    if not Config.Visuals.Tracers then return end
    local now = os.clock()
    if now - State.LastTracerT < 0.05 then return end
    State.LastTracerT = now

    local x1, y1, z1 = W2S(fromPos)
    local x2, y2, z2 = W2S(toPos)
    if not x1 or not x2 or z1 < 0 or z2 < 0 then return end

    local line = NewI("Frame", {
        BackgroundColor3 = Config.Visuals.TracerColor,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0),
        ZIndex           = 5,
    }, TracerGui)

    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    local angle = math.atan2(dy, dx)

    line.Position = UDim2.new(0, x1, 0, y1)
    line.Size     = UDim2.new(0, dist, 0, 1)
    line.Rotation = math.deg(angle)

    Debris:AddItem(line, 0.12)
    table.insert(State.TracerPool, line)
    if #State.TracerPool > 20 then
        local old = table.remove(State.TracerPool, 1)
        pcall(function() if old and old.Parent then old:Destroy() end end)
    end
end

-- ── Hit FX ────────────────────────────────────────────────────────────────────
local HitGui = NewI("ScreenGui", {
    Name          = "UNCODE_HitFX",
    ResetOnSpawn  = false,
}, targetGui)

local function SpawnHitFX(worldPos)
    if not Config.Visuals.HitFX then return end
    local x, y, z = W2S(worldPos)
    if not x or z < 0 then return end
    local dot = NewI("Frame", {
        Size            = UDim2.new(0, 8, 0, 8),
        Position        = UDim2.new(0, x - 4, 0, y - 4),
        BackgroundColor3 = Color3.fromRGB(255, 60, 60),
        BorderSizePixel = 0,
    }, HitGui)
    NewI("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
    Debris:AddItem(dot, 0.3)

    if Config.Visuals.HitSound then
        pcall(function()
            local s = NewI("Sound", {SoundId = "rbxassetid://0", Volume = 0.6, RollOffMaxDistance = 0}, Workspace)
            -- bell-like click
            s.SoundId = "rbxassetid://5784438386"
            s:Play()
            Debris:AddItem(s, 1)
        end)
    end
end

-- ── Inf Jump ──────────────────────────────────────────────────────────────────
Bind(UserInputService.JumpRequest:Connect(function()
    if not Config.Misc.InfJump then return end
    local char = GetChar()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end))

-- ── Click TP ──────────────────────────────────────────────────────────────────
Bind(UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if not Config.Misc.ClickTP then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    local hrp = GetHRP()
    if not hrp then return end
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit then
        hrp.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
    end
end))

-- ── Notification ──────────────────────────────────────────────────────────────
local function Notify(text, duration)
    duration = duration or 3
    local notifGui = NewI("ScreenGui", {
        Name          = "UNCODE_Notif",
        ResetOnSpawn  = false,
    }, targetGui)
    local frame = NewI("Frame", {
        Size            = UDim2.new(0, 240, 0, 36),
        Position        = UDim2.new(0, 8, 1, -44),
        BackgroundColor3 = C_PANEL,
        BorderColor3    = C_BORDER,
        BorderSizePixel = 1,
    }, notifGui)
    NewI("TextLabel", {
        Size            = UDim2.new(1, -8, 1, 0),
        Position        = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text            = text,
        TextColor3      = C_TXT,
        TextSize        = 11,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextWrapped     = true,
    }, frame)
    Debris:AddItem(notifGui, duration)
end

-- ── Keyboard shortcut: Insert = toggle UI ─────────────────────────────────────
Bind(UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end))

-- ── Main render loop ──────────────────────────────────────────────────────────
local lastAntiAimCheck = 0
local lastAura = 0
local lastESP  = 0
local lastChams = 0
local lastRage  = 0

Bind(RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Ragebot (fast)
    if now - lastRage > 0.02 then
        lastRage = now
        pcall(RagebotLoop)
    end

    -- Anti-Aim
    if Config.AntiAim.Enabled and not State.AntiAimBound then
        pcall(BindAntiAim)
    end

    -- ESP (8Hz)
    if now - lastESP > 0.125 then
        lastESP = now
        pcall(UpdateESP)
    end

    -- Chams (4Hz)
    if now - lastChams > 0.25 then
        lastChams = now
        pcall(UpdateChams)
    end

    -- Aura (low freq)
    if now - lastAura > 0.5 then
        lastAura = now
        if Config.Visuals.Aura then
            if not AuraActive then pcall(BuildAura) end
            -- Update ring follow
            if State.AuraRing and State.AuraHRP and State.AuraRing.Parent then
                pcall(function()
                    State.AuraRing.CFrame = State.AuraHRP.CFrame
                        * CFrame.new(0, -3.05, 0)
                        * CFrame.Angles(0, 0, math.rad(90))
                end)
            end
            -- RGB update
            if Config.Visuals.AuraRGB then pcall(BuildAura) end
        else
            if AuraActive then ClearAura() end
        end
    end
end))

-- Crosshair and tracers — render stepped (per frame)
Bind(RunService.RenderStepped:Connect(function()
    pcall(UpdateCrosshair)

    -- Tracers: draw from bottom of screen to each enemy HRP
    if Config.Visuals.Tracers then
        local vp = Camera.ViewportSize
        local fromPos = Camera:ScreenPointToRay(vp.X / 2, vp.Y).Origin
        for _, plr in ipairs(GetEnemies()) do
            local hrp = GetHRP(plr)
            if hrp then
                local dist = (hrp.Position - fromPos).Magnitude
                if dist < Config.ESP.MaxDist then
                    SpawnTracer(fromPos, hrp.Position)
                end
            end
        end
    end

    -- Watermark update
    if State.WatermarkObj and State.WatermarkObj.Visible then
        local now = os.clock()
        local rage_on = Config.Rage.Enabled and "ON" or "OFF"
        WmLabel.Text = string.format("UNCODE v2 | Rage: %s | %.1fs", rage_on, now % 86400)
    end
end))

-- ── Character hooks for aura + chams reset ────────────────────────────────────
local function OnCharAdded(char)
    ClearAura()
    State.ChamsMap = {}
end
if LocalPlayer.Character then OnCharAdded(LocalPlayer.Character) end
Bind(LocalPlayer.CharacterAdded:Connect(OnCharAdded))

-- ── Hit detection hook (for HitFX) ───────────────────────────────────────────
pcall(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if not Remotes then return end
    local rep = Remotes:FindFirstChild("Replication")
    if not rep then return end
    local fighter = rep:FindFirstChild("FighterUnreliable") or rep:FindFirstChild("Fighter")
    if not fighter then return end
    -- Watch for hit events coming from server
    Bind(fighter.OnClientEvent:Connect(function(data)
        if not Config.Visuals.HitFX then return end
        pcall(function()
            if type(data) == "table" and data.Position then
                SpawnHitFX(data.Position)
            end
        end)
    end))
end)

-- ── Done ──────────────────────────────────────────────────────────────────────
Notify("UNCODE v2 loaded | Insert = toggle UI", 5)
print("[UNCODE v2] ===== LOADED =====")
print("[UNCODE v2] Loader: loadstring(game:HttpGet('https://raw.githubusercontent.com/57040suda-haruki-cloud/p1/main/script.lua'))()")
