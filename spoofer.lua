-- ============================================================
--  Standalone Avatar & Name Spoofer  (Rivals)
--  No external dependencies.  No UE / Kicia / external processes.
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer

-- ── state ────────────────────────────────────────────────────────────────
local _avatarOn    = false
local _avatarId    = 0
local _nameOn      = false
local _spoofedName = ""
local _nameConn    = nil

-- ── avatar spoof ─────────────────────────────────────────────────────────
-- Strategy 1: hook __namecall on Players so any call to
--   Players:GetHumanoidDescriptionFromUserIdAsync(id)
-- transparently returns the spoofed id's description instead.
-- Strategy 2: direct ApplyDescription as fallback / for immediate effect.

local _hookActive = false
local _origNamecall

local function _tryInstallHook()
    -- executor must expose getrawmetatable / setrawmetatable / getnamecallmethod
    if not (getrawmetatable and setrawmetatable and getnamecallmethod) then
        return false
    end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local prev = mt.__namecall
        _origNamecall = prev
        local wrapped = newcclosure and newcclosure(function(self, ...)
            if getnamecallmethod() == "GetHumanoidDescriptionFromUserIdAsync"
                and self == Players
                and _avatarOn
                and _avatarId ~= 0
            then
                return prev(self, _avatarId)
            end
            return prev(self, ...)
        end) or function(self, ...)
            if getnamecallmethod() == "GetHumanoidDescriptionFromUserIdAsync"
                and self == Players
                and _avatarOn
                and _avatarId ~= 0
            then
                return prev(self, _avatarId)
            end
            return prev(self, ...)
        end
        mt.__namecall = wrapped
    end)
    return ok
end

local function _applyDirect(userId, statusFn)
    task.spawn(function()
        local char = LocalPlayer.Character
        if not char then
            statusFn("Status: no character found")
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 5)
        if not hum then
            statusFn("Status: Humanoid not found")
            return
        end
        task.wait(0.3)
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
        end)
        if not ok or not desc then
            statusFn("Status: API error — " .. tostring(desc):sub(1, 40))
            return
        end
        local ok2, err2 = pcall(function()
            hum:ApplyDescription(desc)
        end)
        if ok2 then
            statusFn("Status: applied  (ID " .. tostring(userId) .. ")")
        else
            statusFn("Status: ApplyDescription failed\n" .. tostring(err2):sub(1, 50))
        end
    end)
end

-- re-apply on respawn (hook handles future loads; direct call handles immediate)
LocalPlayer.CharacterAdded:Connect(function()
    if not _avatarOn or _avatarId == 0 then return end
    task.delay(1.5, function()
        if _avatarOn and _avatarId ~= 0 then
            _applyDirect(_avatarId, function() end)
        end
    end)
end)

-- ── name spoof ───────────────────────────────────────────────────────────
-- Keep strong references to patched labels so we can re-patch immediately
-- when the game tries to reset them.
local _watchedLabels = {}  -- [label] = connection

local function _patchLabel(lbl, spoofed)
    if _watchedLabels[lbl] then return end
    pcall(function() lbl.Text = spoofed end)
    -- reconnect whenever the game resets the text
    local conn = lbl:GetPropertyChangedSignal("Text"):Connect(function()
        if _nameOn and lbl.Text ~= spoofed then
            pcall(function() lbl.Text = spoofed end)
        end
    end)
    _watchedLabels[lbl] = conn
end

local function _unpatchAll()
    for lbl, conn in pairs(_watchedLabels) do
        pcall(function() conn:Disconnect() end)
    end
    _watchedLabels = {}
end

local function _scanAndPatch(root, origNames, spoofed)
    if not root then return end
    pcall(function()
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
                for _, old in ipairs(origNames) do
                    -- partial match so display names with clan tags still match
                    if v.Text:find(old, 1, true) then
                        _patchLabel(v, spoofed)
                        break
                    end
                end
            end
        end
    end)
end

local _addedConns = {}

local function _startNameLoop()
    -- disconnect previous
    for _, c in ipairs(_addedConns) do pcall(function() c:Disconnect() end) end
    _addedConns = {}
    if _nameConn then _nameConn:Disconnect(); _nameConn = nil end
    _unpatchAll()

    local origNames = { LocalPlayer.Name, LocalPlayer.DisplayName }

    -- initial full scan
    local function fullScan()
        pcall(function()
            for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
                _scanAndPatch(g, origNames, _spoofedName)
            end
        end)
        pcall(function()
            for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                _scanAndPatch(g, origNames, _spoofedName)
            end
        end)
        pcall(function()
            local char = LocalPlayer.Character
            if char then _scanAndPatch(char, origNames, _spoofedName) end
        end)
    end
    fullScan()

    -- also watch for newly added labels (Rivals creates nametags dynamically)
    local function watchRoot(root)
        if not root then return end
        local c = root.DescendantAdded:Connect(function(v)
            if not _nameOn then return end
            if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
                task.defer(function()
                    for _, old in ipairs(origNames) do
                        if v.Text:find(old, 1, true) then
                            _patchLabel(v, _spoofedName)
                            break
                        end
                    end
                end)
            end
        end)
        _addedConns[#_addedConns+1] = c
    end

    pcall(function() watchRoot(game:GetService("CoreGui")) end)
    pcall(function() watchRoot(LocalPlayer.PlayerGui) end)
    pcall(function()
        local char = LocalPlayer.Character
        if char then watchRoot(char) end
    end)

    -- periodic rescan every 2 seconds for anything that slipped through
    local tick_ = 0
    _nameConn = RunService.Heartbeat:Connect(function()
        tick_ = tick_ + 1
        if tick_ % 120 ~= 0 then return end
        fullScan()
    end)
end

local function _stopNameLoop()
    for _, c in ipairs(_addedConns) do pcall(function() c:Disconnect() end) end
    _addedConns = {}
    if _nameConn then _nameConn:Disconnect(); _nameConn = nil end
    _unpatchAll()
end

-- ── GUI ──────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "SpoofGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 999
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer.PlayerGui end

local win = Instance.new("Frame")
win.Size             = UDim2.new(0, 280, 0, 310)
win.Position         = UDim2.new(0, 20, 0.5, -155)
win.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
win.BorderSizePixel  = 0
win.Active           = true
win.Draggable        = true
win.Parent           = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = win
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 6)

local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0, 10)
titleFix.Position         = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleFix.BorderSizePixel  = 0
titleFix.Parent           = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                = UDim2.new(1, -8, 1, 0)
titleLbl.Position            = UDim2.new(0, 8, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                = "Spoofer"
titleLbl.TextColor3          = Color3.fromRGB(220, 220, 220)
titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
titleLbl.Font                = Enum.Font.GothamBold
titleLbl.TextSize            = 13
titleLbl.Parent              = titleBar

-- ── helpers ──────────────────────────────────────────────────────────────
local function _label(parent, text, y, h)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1, -16, 0, h or 16)
    l.Position           = UDim2.new(0, 8, 0, y)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = Color3.fromRGB(160, 160, 160)
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.TextYAlignment     = Enum.TextYAlignment.Top
    l.TextWrapped        = true
    l.Font               = Enum.Font.Gotham
    l.TextSize           = 11
    l.Parent             = parent
    return l
end

local function _divider(parent, y)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1, -16, 0, 1)
    d.Position         = UDim2.new(0, 8, 0, y)
    d.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    d.BorderSizePixel  = 0
    d.Parent           = parent
end

local function _input(parent, placeholder, y)
    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -16, 0, 26)
    box.Position          = UDim2.new(0, 8, 0, y)
    box.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    box.BorderSizePixel   = 0
    box.Text              = ""
    box.PlaceholderText   = placeholder
    box.TextColor3        = Color3.fromRGB(230, 230, 230)
    box.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 12
    box.ClearTextOnFocus  = false
    box.Parent            = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    return box
end

local _C = {
    on   = Color3.fromRGB(60, 180, 100),
    off  = Color3.fromRGB(50, 50, 50),
    warn = Color3.fromRGB(180, 70, 70),
}

local function _btn(parent, text, color, y, w, xOff)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, w or 120, 0, 26)
    b.Position         = UDim2.new(0, xOff or 8, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(230, 230, 230)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.AutoButtonColor  = false
    b.Parent           = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.new(
                math.min(color.R + 0.1, 1),
                math.min(color.G + 0.1, 1),
                math.min(color.B + 0.1, 1))
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = color }):Play()
    end)
    return b
end

-- ── AVATAR section ───────────────────────────────────────────────────────
_label(win, "AVATAR SPOOF", 42)

-- show whether hook is available
local hookNote = _label(win, "", 58, 14)

local avatarInput = _input(win, "Target User ID  (e.g. 1)", 76)

local avatarApplyBtn = _btn(win, "Apply", _C.off,  108, 120, 8)
local avatarResetBtn = _btn(win, "Reset", _C.warn, 108, 120, 140)

local avatarStatusLbl = _label(win, "Status: off", 142, 28)
avatarStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)

local function _setAvatarStatus(txt)
    avatarStatusLbl.Text = txt
end

-- check hook availability on load
local hookOk = _tryInstallHook()
if hookOk then
    _hookActive = true
    hookNote.Text       = "Hook: active (deep spoof)"
    hookNote.TextColor3 = Color3.fromRGB(80, 200, 100)
else
    hookNote.Text       = "Hook: unavailable (surface only)"
    hookNote.TextColor3 = Color3.fromRGB(200, 160, 60)
end

avatarApplyBtn.MouseButton1Click:Connect(function()
    local raw = avatarInput.Text:match("^%s*(%d+)%s*$")
    if not raw then
        _setAvatarStatus("Status: invalid user ID")
        avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 80, 80)
        return
    end
    _avatarId = tonumber(raw)
    _avatarOn = true
    avatarApplyBtn.BackgroundColor3 = _C.on
    _setAvatarStatus("Status: applying...")
    avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 180, 60)
    _applyDirect(_avatarId, function(msg)
        _setAvatarStatus(msg)
        avatarStatusLbl.TextColor3 = msg:find("applied") and
            Color3.fromRGB(80, 200, 100) or Color3.fromRGB(200, 80, 80)
    end)
end)

avatarResetBtn.MouseButton1Click:Connect(function()
    _avatarOn = false
    _avatarId = 0
    avatarApplyBtn.BackgroundColor3 = _C.off
    _setAvatarStatus("Status: resetting...")
    avatarStatusLbl.TextColor3 = Color3.fromRGB(200, 180, 60)
    _applyDirect(LocalPlayer.UserId, function(msg)
        _setAvatarStatus("Status: off")
        avatarStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
    end)
end)

-- ── divider ──────────────────────────────────────────────────────────────
_divider(win, 178)

-- ── NAME section ─────────────────────────────────────────────────────────
_label(win, "NAME SPOOF", 188)

local nameInput = _input(win, "Spoofed name", 206)

local nameOnBtn  = _btn(win, "Enable",  _C.off,  240, 120, 8)
local nameOffBtn = _btn(win, "Disable", _C.warn, 240, 120, 140)

local nameStatusLbl = _label(win, "Status: off", 274, 28)
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
    nameOnBtn.BackgroundColor3 = _C.on
    nameStatusLbl.Text       = "Status: active  (" .. v .. ")"
    nameStatusLbl.TextColor3 = Color3.fromRGB(80, 200, 100)
    _startNameLoop()
end)

nameOffBtn.MouseButton1Click:Connect(function()
    _nameOn = false
    _stopNameLoop()
    nameOnBtn.BackgroundColor3 = _C.off
    nameStatusLbl.Text       = "Status: off"
    nameStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
end)

-- ── RightAlt toggle ──────────────────────────────────────────────────────
game:GetService("UserInputService").InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightAlt then
        win.Visible = not win.Visible
    end
end)
