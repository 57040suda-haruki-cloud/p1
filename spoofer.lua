-- ============================================================
--  Standalone Avatar & Name Spoofer  (Rivals)
--  No external dependencies.  No UE / Kicia / external processes.
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ── state ────────────────────────────────────────────────────────────────
local _avatarOn     = false
local _avatarId     = 0
local _nameOn       = false
local _spoofedName  = ""
local _nameConn     = nil

-- ── avatar spoof ─────────────────────────────────────────────────────────
local function _applyAvatar(userId)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
    end)
    if ok and desc then
        pcall(function() hum:ApplyDescription(desc) end)
    end
end

local function _resetAvatar()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(LocalPlayer.UserId)
    end)
    if ok and desc then
        pcall(function() hum:ApplyDescription(desc) end)
    end
end

-- re-apply after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if not _avatarOn or _avatarId == 0 then return end
    task.delay(1.5, function()
        if _avatarOn and _avatarId ~= 0 then
            _applyAvatar(_avatarId)
        end
    end)
end)

-- ── name spoof ───────────────────────────────────────────────────────────
local function _walkReplace(root, old, new_)
    if not root then return end
    for _, v in ipairs(root:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox"))
            and v.Text == old then
            pcall(function() v.Text = new_ end)
        end
    end
end

local function _patchAll()
    if not _nameOn or _spoofedName == "" then return end
    local targets = { LocalPlayer.Name, LocalPlayer.DisplayName }
    local roots   = {}
    pcall(function()
        for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
            roots[#roots+1] = g
        end
    end)
    pcall(function()
        for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            roots[#roots+1] = g
        end
    end)
    pcall(function()
        local char = LocalPlayer.Character
        if char then roots[#roots+1] = char end
    end)
    for _, root in ipairs(roots) do
        for _, old in ipairs(targets) do
            _walkReplace(root, old, _spoofedName)
        end
    end
end

local function _startNameLoop()
    if _nameConn then _nameConn:Disconnect() end
    local tick_ = 0
    _nameConn = RunService.Heartbeat:Connect(function()
        tick_ = tick_ + 1
        if tick_ % 20 ~= 0 then return end
        _patchAll()
    end)
end

local function _stopNameLoop()
    if _nameConn then _nameConn:Disconnect(); _nameConn = nil end
end

-- ── GUI ──────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name             = "SpoofGui"
gui.ResetOnSpawn     = false
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder     = 999
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer.PlayerGui end

-- window
local win = Instance.new("Frame")
win.Size              = UDim2.new(0, 280, 0, 290)
win.Position          = UDim2.new(0, 20, 0.5, -145)
win.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
win.BorderSizePixel   = 0
win.Active            = true
win.Draggable         = true
win.Parent            = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size            = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = win
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 6)

-- fix bottom corners of title bar
local titleFix = Instance.new("Frame")
titleFix.Size              = UDim2.new(1, 0, 0, 10)
titleFix.Position          = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3  = Color3.fromRGB(10, 10, 10)
titleFix.BorderSizePixel   = 0
titleFix.Parent            = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size            = UDim2.new(1, -8, 1, 0)
titleLbl.Position        = UDim2.new(0, 8, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text            = "Spoofer"
titleLbl.TextColor3      = Color3.fromRGB(220, 220, 220)
titleLbl.TextXAlignment  = Enum.TextXAlignment.Left
titleLbl.Font            = Enum.Font.GothamBold
titleLbl.TextSize        = 13
titleLbl.Parent          = titleBar

-- ── helper builders ──────────────────────────────────────────────────────
local function _label(parent, text, y)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1, -16, 0, 16)
    l.Position           = UDim2.new(0, 8, 0, y)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = Color3.fromRGB(160, 160, 160)
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 11
    l.Parent             = parent
    return l
end

local function _divider(parent, y)
    local d = Instance.new("Frame")
    d.Size               = UDim2.new(1, -16, 0, 1)
    d.Position           = UDim2.new(0, 8, 0, y)
    d.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
    d.BorderSizePixel    = 0
    d.Parent             = parent
end

local function _input(parent, placeholder, y)
    local box = Instance.new("TextBox")
    box.Size               = UDim2.new(1, -16, 0, 26)
    box.Position           = UDim2.new(0, 8, 0, y)
    box.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
    box.BorderSizePixel    = 0
    box.Text               = ""
    box.PlaceholderText    = placeholder
    box.TextColor3         = Color3.fromRGB(230, 230, 230)
    box.PlaceholderColor3  = Color3.fromRGB(90, 90, 90)
    box.Font               = Enum.Font.Gotham
    box.TextSize           = 12
    box.ClearTextOnFocus   = false
    box.Parent             = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    return box
end

local _btnColors = {
    on   = Color3.fromRGB(60, 180, 100),
    off  = Color3.fromRGB(50, 50, 50),
    warn = Color3.fromRGB(180, 70, 70),
}

local function _btn(parent, text, color, y, w, xOff)
    local b = Instance.new("TextButton")
    b.Size               = UDim2.new(0, w or 120, 0, 26)
    b.Position           = UDim2.new(0, xOff or 8, 0, y)
    b.BackgroundColor3   = color
    b.BorderSizePixel    = 0
    b.Text               = text
    b.TextColor3         = Color3.fromRGB(230, 230, 230)
    b.Font               = Enum.Font.GothamBold
    b.TextSize           = 11
    b.AutoButtonColor    = false
    b.Parent             = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.new(
                math.min(color.R + 0.1, 1),
                math.min(color.G + 0.1, 1),
                math.min(color.B + 0.1, 1)
            )
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = color }):Play()
    end)
    return b
end

local content = win  -- everything inside the window

-- ── AVATAR SPOOF section ─────────────────────────────────────────────────
_label(content, "AVATAR SPOOF", 42)

local avatarInput = _input(content, "Target User ID  (e.g. 1)", 62)

local avatarApplyBtn = _btn(content, "Apply", _btnColors.off, 96, 120, 8)
local avatarResetBtn = _btn(content, "Reset", _btnColors.warn, 96, 120, 140)

local avatarStatusLbl = _label(content, "Status: off", 130)
avatarStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)

avatarApplyBtn.MouseButton1Click:Connect(function()
    local raw = avatarInput.Text:match("^%s*(%d+)%s*$")
    if not raw then
        avatarStatusLbl.Text      = "Status: invalid user ID"
        avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 80, 80)
        return
    end
    _avatarId  = tonumber(raw)
    _avatarOn  = true
    avatarStatusLbl.Text       = "Status: applying..."
    avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 180, 60)
    avatarApplyBtn.BackgroundColor3 = _btnColors.on
    task.spawn(function()
        _applyAvatar(_avatarId)
        avatarStatusLbl.Text       = "Status: active  (ID " .. raw .. ")"
        avatarStatusLbl.TextColor3 = Color3.fromRGB(80, 200, 100)
    end)
end)

avatarResetBtn.MouseButton1Click:Connect(function()
    _avatarOn = false
    _avatarId = 0
    avatarApplyBtn.BackgroundColor3 = _btnColors.off
    avatarStatusLbl.Text       = "Status: resetting..."
    avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 180, 60)
    task.spawn(function()
        _resetAvatar()
        avatarStatusLbl.Text       = "Status: off"
        avatarStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
    end)
end)

-- ── divider ──────────────────────────────────────────────────────────────
_divider(content, 158)

-- ── NAME SPOOF section ───────────────────────────────────────────────────
_label(content, "NAME SPOOF", 168)

local nameInput = _input(content, "Spoofed name", 188)

local nameOnBtn  = _btn(content, "Enable",  _btnColors.off,  222, 120, 8)
local nameOffBtn = _btn(content, "Disable", _btnColors.warn,  222, 120, 140)

local nameStatusLbl = _label(content, "Status: off", 256)
nameStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)

nameOnBtn.MouseButton1Click:Connect(function()
    local v = nameInput.Text
    if v == "" then
        nameStatusLbl.Text       = "Status: enter a name first"
        nameStatusLbl.TextColor3 = Color3.fromRGB(200, 80, 80)
        return
    end
    _spoofedName = v
    _nameOn      = true
    nameOnBtn.BackgroundColor3 = _btnColors.on
    nameStatusLbl.Text       = "Status: active  (" .. v .. ")"
    nameStatusLbl.TextColor3 = Color3.fromRGB(80, 200, 100)
    _startNameLoop()
    _patchAll()
end)

nameOffBtn.MouseButton1Click:Connect(function()
    _nameOn = false
    _stopNameLoop()
    nameOnBtn.BackgroundColor3 = _btnColors.off
    nameStatusLbl.Text       = "Status: off"
    nameStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
end)

-- ── toggle window with RightAlt ──────────────────────────────────────────
game:GetService("UserInputService").InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightAlt then
        win.Visible = not win.Visible
    end
end)
