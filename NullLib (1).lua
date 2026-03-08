--[[
    NullLib - Custom Roblox UI Library
    Built from scratch. No external dependencies.
    Supports: PC + Mobile | Draggable | Toggles | Buttons | Sliders | Dropdowns | Multi-Select | Input | Colorpicker | Keybind | Notifications
]]

local NullLib = {}
NullLib.__index = NullLib

-- Services
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Utility
local function tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, style, dir), props):Play()
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function newInstance(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function applyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function applyPadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 6)
    p.PaddingRight  = UDim.new(0, right  or 10)
    p.PaddingBottom = UDim.new(0, bottom or 6)
    p.PaddingLeft   = UDim.new(0, left   or 10)
    p.Parent = parent
    return p
end

local function applyListLayout(parent, padding, dir, halign, valign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, padding or 6)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = valign or Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

-- Color palette
local C = {
    BG          = Color3.fromRGB(12, 12, 16),
    Surface     = Color3.fromRGB(20, 20, 26),
    Surface2    = Color3.fromRGB(28, 28, 36),
    Surface3    = Color3.fromRGB(36, 36, 46),
    Accent      = Color3.fromRGB(99, 102, 241),
    AccentDark  = Color3.fromRGB(67, 70, 190),
    AccentLight = Color3.fromRGB(129, 132, 255),
    Green       = Color3.fromRGB(34, 197, 94),
    Red         = Color3.fromRGB(239, 68, 68),
    Yellow      = Color3.fromRGB(250, 204, 21),
    Text        = Color3.fromRGB(240, 240, 255),
    TextMuted   = Color3.fromRGB(110, 110, 140),
    TextDim     = Color3.fromRGB(70, 70, 90),
    Border      = Color3.fromRGB(45, 45, 60),
    BorderLight = Color3.fromRGB(70, 70, 95),
    Topbar      = Color3.fromRGB(16, 16, 22),
}

-- Flags system (global values)
NullLib.Flags = {}

-- ============================================================
-- DRAGGING
-- ============================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        frame.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotifGui, NotifHolder

local function ensureNotifGui()
    if NotifGui then return end
    NotifGui = newInstance("ScreenGui", {
        Name = "NullLib_Notifs",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
    })
    NotifHolder = newInstance("Frame", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        Parent = NotifGui
    })
    applyListLayout(NotifHolder, 8, Enum.FillDirection.Vertical,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 16)
    pad.Parent = NotifHolder
end

local function notify(title, body, duration, ntype)
    ensureNotifGui()
    duration = duration or 4
    ntype = ntype or "info"

    local accentColor = ntype == "success" and C.Green
        or ntype == "error" and C.Red
        or ntype == "warn"  and C.Yellow
        or C.Accent

    local card = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Surface,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = NotifHolder
    })
    applyCorner(card, 10)

    local stroke = newInstance("UIStroke", {
        Color = accentColor,
        Thickness = 1,
        Transparency = 0.5,
        Parent = card
    })

    local bar = newInstance("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = card
    })
    applyCorner(bar, 3)

    local content = newInstance("Frame", {
        Size = UDim2.new(1, -11, 0, 0),
        Position = UDim2.new(0, 11, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card
    })
    applyPadding(content, 10, 10, 10, 8)
    applyListLayout(content, 3)

    newInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = content
    })

    if body and body ~= "" then
        newInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = body,
            TextColor3 = C.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = content
        })
    end

    -- Animate in
    card.BackgroundTransparency = 1
    tween(card, {BackgroundTransparency = 0}, 0.25)

    task.delay(duration, function()
        tween(card, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        card:Destroy()
    end)

    return card
end

-- ============================================================
-- WINDOW
-- ============================================================
function NullLib:CreateWindow(config)
    config = config or {}
    local title    = config.Title    or "NullLib"
    local subtitle = config.Subtitle or ""
    local size     = config.Size     or UDim2.fromOffset(540, 520)
    local keybind  = config.Keybind  or Enum.KeyCode.RightControl

    local gui = newInstance("ScreenGui", {
        Name = "NullLib_" .. title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
    })

    -- Shadow
    local shadow = newInstance("ImageLabel", {
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0, -30, 0, -30),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0,0,0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
    })

    -- Main window frame
    local win = newInstance("Frame", {
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = gui
    })
    applyCorner(win, 12)

    shadow.Parent = win

    local winStroke = newInstance("UIStroke", {
        Color = C.Border,
        Thickness = 1,
        Parent = win
    })

    -- Topbar
    local topbar = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = C.Topbar,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = win
    })
    applyCorner(topbar, 12)

    -- Fix bottom corners of topbar
    newInstance("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.Topbar,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = topbar
    })

    -- Accent line
    local accentLine = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = topbar
    })

    -- Title
    newInstance("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = title .. (subtitle ~= "" and ("  ·  " .. subtitle) or ""),
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = topbar
    })

    -- Close button
    local closeBtn = newInstance("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(239, 68, 68),
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })
    applyCorner(closeBtn, 6)
    newInstance("TextLabel", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 5,
        Parent = closeBtn
    })

    -- Minimize button
    local minBtn = newInstance("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = C.Surface3,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })
    applyCorner(minBtn, 6)
    newInstance("TextLabel", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "–",
        TextColor3 = C.TextMuted,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 5,
        Parent = minBtn
    })

    makeDraggable(win, topbar)

    local minimized = false
    local contentArea -- defined below

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(win, {Size = UDim2.new(0, size.X.Offset, 0, 50)}, 0.3)
        else
            tween(win, {Size = size}, 0.3)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        tween(win, {Size = UDim2.new(0, size.X.Offset, 0, 0)}, 0.25)
        task.wait(0.3)
        gui:Destroy()
    end)

    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(200,40,40)}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(239,68,68)}, 0.15) end)

    -- Tab bar
    local tabBar = newInstance("Frame", {
        Size = UDim2.new(0, 150, 1, -52),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = C.Topbar,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = win
    })

    -- Fix right corners of tabbar
    newInstance("Frame", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C.Topbar,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = tabBar
    })

    applyCorner(tabBar, 12)

    local tabList = newInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
        Parent = tabBar
    })
    applyPadding(tabList, 0, 8, 0, 8)
    applyListLayout(tabList, 4)

    -- Content area
    contentArea = newInstance("Frame", {
        Size = UDim2.new(1, -158, 1, -58),
        Position = UDim2.new(0, 154, 0, 54),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = win
    })

    -- Divider between tabbar and content
    newInstance("Frame", {
        Size = UDim2.new(0, 1, 1, -58),
        Position = UDim2.new(0, 150, 0, 54),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = win
    })

    -- Entrance animation
    win.Size = UDim2.fromOffset(0, 0)
    tween(win, {Size = size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == keybind then
            win.Visible = not win.Visible
        end
    end)

    -- Window object
    local Window = {
        _gui = gui,
        _win = win,
        _tabList = tabList,
        _contentArea = contentArea,
        _tabs = {},
        _activeTab = nil,
        Notify = notify
    }

    function Window:CreateTab(name, icon)
        local tab = {}
        tab._name = name
        tab._sections = {}

        -- Tab button
        local btn = newInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = C.Surface2,
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            ZIndex = 4,
            Parent = tabList
        })
        applyCorner(btn, 8)

        local indicator = newInstance("Frame", {
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = btn
        })
        applyCorner(indicator, 2)

        local iconLabel
        if icon then
            iconLabel = newInstance("ImageLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 12, 0.5, -8),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = C.TextMuted,
                ZIndex = 5,
                Parent = btn
            })
        end

        local textOffset = icon and 36 or 14
        local textLabel = newInstance("TextLabel", {
            Size = UDim2.new(1, -(textOffset + 8), 1, 0),
            Position = UDim2.new(0, textOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = C.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = btn
        })

        -- Tab page
        local page = newInstance("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 2,
            Parent = contentArea
        })
        applyPadding(page, 8, 8, 8, 8)
        applyListLayout(page, 8)

        tab._btn = btn
        tab._page = page
        tab._textLabel = textLabel
        tab._iconLabel = iconLabel
        tab._indicator = indicator

        local function activate()
            -- Deactivate all
            for _, t in pairs(Window._tabs) do
                t._page.Visible = false
                tween(t._btn, {BackgroundTransparency = 1}, 0.15)
                tween(t._textLabel, {TextColor3 = C.TextMuted, Font = Enum.Font.Gotham}, 0.15)
                tween(t._indicator, {BackgroundTransparency = 1}, 0.15)
                if t._iconLabel then tween(t._iconLabel, {ImageColor3 = C.TextMuted}, 0.15) end
            end
            -- Activate this
            page.Visible = true
            tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = C.Surface2}, 0.15)
            tween(textLabel, {TextColor3 = C.Text}, 0.15)
            tween(indicator, {BackgroundTransparency = 0}, 0.15)
            if iconLabel then tween(iconLabel, {ImageColor3 = C.AccentLight}, 0.15) end
            textLabel.Font = Enum.Font.GothamBold
            Window._activeTab = tab
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if Window._activeTab ~= tab then
                tween(btn, {BackgroundTransparency = 0.7, BackgroundColor3 = C.Surface2}, 0.1)
            end
        end)
        btn.MouseLeave:Connect(function()
            if Window._activeTab ~= tab then
                tween(btn, {BackgroundTransparency = 1}, 0.1)
            end
        end)

        table.insert(Window._tabs, tab)
        if #Window._tabs == 1 then activate() end

        tab.Select = activate

        -- ============================================================
        -- SECTION
        -- ============================================================
        function tab:CreateSection(name)
            local sec = {}

            local sectionFrame = newInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = page
            })

            if name and name ~= "" then
                local labelRow = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = sectionFrame
                })
                newInstance("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Text = string.upper(name),
                    TextColor3 = C.Accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = labelRow
                })
                local divLine = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = C.Border,
                    BorderSizePixel = 0,
                    Parent = sectionFrame
                })
            end

            local itemList = newInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = sectionFrame
            })
            applyListLayout(itemList, 5)

            -- --------------------------------------------------------
            -- Element helpers
            -- --------------------------------------------------------
            local function makeElement(height)
                local el = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, height or 38),
                    BackgroundColor3 = C.Surface,
                    BorderSizePixel = 0,
                    Parent = itemList
                })
                applyCorner(el, 8)
                newInstance("UIStroke", {
                    Color = C.Border,
                    Thickness = 1,
                    Parent = el
                })
                return el
            end

            local function makeLabel(parent, text, x, y, w, h, color, size, font, align)
                return newInstance("TextLabel", {
                    Size = UDim2.new(w or 0.6, 0, 0, h or 38),
                    Position = UDim2.new(x or 0, 12, y or 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = color or C.Text,
                    Font = font or Enum.Font.Gotham,
                    TextSize = size or 13,
                    TextXAlignment = align or Enum.TextXAlignment.Left,
                    Parent = parent
                })
            end

            -- --------------------------------------------------------
            -- BUTTON
            -- --------------------------------------------------------
            function sec:CreateButton(config)
                config = config or {}
                local el = makeElement(38)
                el.BackgroundColor3 = C.Surface2

                makeLabel(el, config.Name or "Button")

                local descLabel
                if config.Description then
                    el.Size = UDim2.new(1, 0, 0, 54)
                    descLabel = makeLabel(el, config.Description, 0, 0, 0.75, 54, C.TextMuted, 11)
                    descLabel.Position = UDim2.new(0, 12, 0, 20)
                    descLabel.Size = UDim2.new(0.75, 0, 0, 18)
                end

                local ripple = newInstance("Frame", {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BackgroundTransparency = 0.85,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = el
                })
                applyCorner(ripple, 100)
                el.ClipsDescendants = true

                local btn = newInstance("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = el
                })

                btn.MouseEnter:Connect(function()
                    tween(el, {BackgroundColor3 = C.Surface3}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    tween(el, {BackgroundColor3 = C.Surface2}, 0.15)
                end)
                btn.MouseButton1Click:Connect(function()
                    tween(ripple, {Size = UDim2.new(2,0,2,0), Position = UDim2.new(-0.5,0,-0.5,0), BackgroundTransparency = 1}, 0.4)
                    task.delay(0.4, function()
                        ripple.Size = UDim2.new(0,0,0,0)
                        ripple.Position = UDim2.new(0.5,0,0.5,0)
                        ripple.BackgroundTransparency = 0.85
                    end)
                    if config.Callback then
                        task.spawn(config.Callback)
                    end
                end)

                return btn
            end

            -- --------------------------------------------------------
            -- TOGGLE
            -- --------------------------------------------------------
            function sec:CreateToggle(config)
                config = config or {}
                local value = config.CurrentValue or false
                if config.Flag then NullLib.Flags[config.Flag] = value end

                local el = makeElement(38)

                makeLabel(el, config.Name or "Toggle")
                if config.Description then
                    el.Size = UDim2.new(1, 0, 0, 54)
                    makeLabel(el, config.Description, 0, 0, 0.75, 54, C.TextMuted, 11).Position = UDim2.new(0, 12, 0, 22)
                end

                -- Switch track
                local trackBG = newInstance("Frame", {
                    Size = UDim2.new(0, 40, 0, 22),
                    Position = UDim2.new(1, -52, 0.5, -11),
                    BackgroundColor3 = value and C.Accent or C.Surface3,
                    BorderSizePixel = 0,
                    Parent = el
                })
                applyCorner(trackBG, 11)
                newInstance("UIStroke", {Color = C.Border, Thickness = 1, Parent = trackBG})

                local thumb = newInstance("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = value and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    Parent = trackBG
                })
                applyCorner(thumb, 8)

                local btn = newInstance("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 2,
                    Parent = el
                })

                local togObj = {}
                function togObj:Set(v)
                    value = v
                    if config.Flag then NullLib.Flags[config.Flag] = v end
                    tween(trackBG, {BackgroundColor3 = v and C.Accent or C.Surface3}, 0.2)
                    tween(thumb, {Position = v and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.2)
                    if config.Callback then task.spawn(config.Callback, v) end
                end

                btn.MouseButton1Click:Connect(function()
                    togObj:Set(not value)
                end)

                return togObj
            end

            -- --------------------------------------------------------
            -- SLIDER
            -- --------------------------------------------------------
            function sec:CreateSlider(config)
                config = config or {}
                local min = config.Min or config.Range and config.Range[1] or 0
                local max = config.Max or config.Range and config.Range[2] or 100
                local inc = config.Increment or 1
                local suffix = config.Suffix or ""
                local currentVal = config.CurrentValue or min
                if config.Flag then NullLib.Flags[config.Flag] = currentVal end

                local el = makeElement(56)

                -- Top row
                local nameLabel = makeLabel(el, config.Name or "Slider", 0, 0, 0.7, 26)
                local valLabel = newInstance("TextLabel", {
                    Size = UDim2.new(0.3, -12, 0, 26),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(currentVal) .. " " .. suffix,
                    TextColor3 = C.Accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = el
                })

                -- Track
                local trackFrame = newInstance("Frame", {
                    Size = UDim2.new(1, -24, 0, 6),
                    Position = UDim2.new(0, 12, 0, 36),
                    BackgroundColor3 = C.Surface3,
                    BorderSizePixel = 0,
                    Parent = el
                })
                applyCorner(trackFrame, 3)

                local fill = newInstance("Frame", {
                    Size = UDim2.new((currentVal - min)/(max - min), 0, 1, 0),
                    BackgroundColor3 = C.Accent,
                    BorderSizePixel = 0,
                    Parent = trackFrame
                })
                applyCorner(fill, 3)

                local thumb = newInstance("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new((currentVal - min)/(max - min), -7, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = trackFrame
                })
                applyCorner(thumb, 7)
                newInstance("UIStroke", {Color = C.Accent, Thickness = 2, Parent = thumb})

                local sliderObj = {}
                local sliding = false

                local function setValue(v)
                    v = math.clamp(v, min, max)
                    v = math.round(v / inc) * inc
                    currentVal = v
                    if config.Flag then NullLib.Flags[config.Flag] = v end
                    local pct = (v - min) / (max - min)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    thumb.Position = UDim2.new(pct, -7, 0.5, -7)
                    valLabel.Text = tostring(v) .. " " .. suffix
                    if config.Callback then task.spawn(config.Callback, v) end
                end

                local function getValueFromInput(input)
                    local absPos = trackFrame.AbsolutePosition.X
                    local absSize = trackFrame.AbsoluteSize.X
                    local relX = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
                    return min + relX * (max - min)
                end

                local inputBtn = newInstance("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = trackFrame
                })

                inputBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        setValue(getValueFromInput(input))
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        setValue(getValueFromInput(input))
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                function sliderObj:Set(v)
                    setValue(v)
                end

                return sliderObj
            end

            -- --------------------------------------------------------
            -- DROPDOWN (single & multi)
            -- --------------------------------------------------------
            function sec:CreateDropdown(config)
                config = config or {}
                local options = config.Options or {}
                local multi = config.MultipleOptions or config.Multi or false
                local selected = {}
                local open = false

                if config.CurrentOption then
                    for _, v in ipairs(config.CurrentOption) do selected[v] = true end
                elseif config.Default then
                    if type(config.Default) == "table" then
                        for _, v in ipairs(config.Default) do selected[v] = true end
                    else
                        selected[config.Default] = true
                    end
                end

                local function getDisplayText()
                    local t = {}
                    for v, _ in pairs(selected) do table.insert(t, v) end
                    if #t == 0 then return "Select..." end
                    return table.concat(t, ", ")
                end

                local el = makeElement(38)
                el.ClipsDescendants = false
                el.ZIndex = 10

                local nameLabel = makeLabel(el, config.Name or "Dropdown", 0, 0, 0.45, 38)

                local selLabel = newInstance("TextLabel", {
                    Size = UDim2.new(0.45, 0, 0, 38),
                    Position = UDim2.new(0.45, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = getDisplayText(),
                    TextColor3 = C.Accent,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 2,
                    Parent = el
                })

                local chevron = newInstance("TextLabel", {
                    Size = UDim2.new(0, 20, 0, 38),
                    Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▾",
                    TextColor3 = C.TextMuted,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 2,
                    Parent = el
                })

                -- Dropdown panel
                local panel = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = C.Surface2,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                    ClipsDescendants = true,
                    Visible = false,
                    Parent = el
                })
                applyCorner(panel, 8)
                newInstance("UIStroke", {Color = C.BorderLight, Thickness = 1, Parent = panel})

                local panelList = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    ZIndex = 21,
                    Parent = panel
                })
                applyListLayout(panelList, 2)
                applyPadding(panelList, 4, 4, 4, 4)

                local optionBtns = {}
                for _, opt in ipairs(options) do
                    local optBtn = newInstance("TextButton", {
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = selected[opt] and C.Surface3 or Color3.fromRGB(0,0,0),
                        BackgroundTransparency = selected[opt] and 0 or 1,
                        Text = "",
                        BorderSizePixel = 0,
                        ZIndex = 22,
                        Parent = panelList
                    })
                    applyCorner(optBtn, 6)

                    local checkIcon = newInstance("TextLabel", {
                        Size = UDim2.new(0, 20, 1, 0),
                        Position = UDim2.new(1, -24, 0, 0),
                        BackgroundTransparency = 1,
                        Text = selected[opt] and "✓" or "",
                        TextColor3 = C.Accent,
                        Font = Enum.Font.GothamBold,
                        TextSize = 12,
                        ZIndex = 23,
                        Parent = optBtn
                    })

                    newInstance("TextLabel", {
                        Size = UDim2.new(1, -32, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = opt,
                        TextColor3 = C.Text,
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 23,
                        Parent = optBtn
                    })

                    optBtn.MouseEnter:Connect(function()
                        tween(optBtn, {BackgroundTransparency = 0, BackgroundColor3 = C.Surface3}, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if not selected[opt] then
                            tween(optBtn, {BackgroundTransparency = 1}, 0.1)
                        end
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        if not multi then
                            for k in pairs(selected) do selected[k] = nil end
                            for _, ob in pairs(optionBtns) do
                                ob.checkIcon.Text = ""
                                tween(ob.btn, {BackgroundTransparency = 1}, 0.1)
                            end
                        end
                        selected[opt] = not selected[opt] or (not multi and true)
                        checkIcon.Text = selected[opt] and "✓" or ""
                        tween(optBtn, {BackgroundTransparency = selected[opt] and 0 or 1, BackgroundColor3 = C.Surface3}, 0.1)

                        selLabel.Text = getDisplayText()

                        if config.Callback then
                            if multi then
                                local t = {}
                                for v, _ in pairs(selected) do table.insert(t, v) end
                                task.spawn(config.Callback, t)
                            else
                                local t = {}
                                for v, _ in pairs(selected) do table.insert(t, v) end
                                task.spawn(config.Callback, t)
                            end
                        end

                        if not multi then
                            open = false
                            tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            task.delay(0.2, function() panel.Visible = false end)
                            tween(chevron, {Rotation = 0}, 0.2)
                        end
                    end)

                    optionBtns[opt] = {btn = optBtn, checkIcon = checkIcon}
                end

                local toggleBtn = newInstance("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 5,
                    Parent = el
                })

                toggleBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        panel.Visible = true
                        local targetH = math.min(#options * 34 + 8, 200)
                        panel.Size = UDim2.new(1, 0, 0, 0)
                        tween(panel, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
                        tween(chevron, {Rotation = 180}, 0.2)
                    else
                        tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        task.delay(0.2, function() panel.Visible = false end)
                        tween(chevron, {Rotation = 0}, 0.2)
                    end
                end)

                local dropObj = {}
                function dropObj:UpdateOptions(newOpts)
                    for _, child in pairs(panelList:GetChildren()) do
                        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                            child:Destroy()
                        end
                    end
                    options = newOpts
                    optionBtns = {}
                    -- (re-create options - simplified for brevity)
                end
                function dropObj:SetSelected(opts)
                    selected = {}
                    if type(opts) == "table" then
                        for _, v in ipairs(opts) do selected[v] = true end
                    else
                        selected[opts] = true
                    end
                    selLabel.Text = getDisplayText()
                end

                if config.Flag then
                    NullLib.Flags[config.Flag] = selected
                end

                return dropObj
            end

            -- --------------------------------------------------------
            -- INPUT / TEXTBOX
            -- --------------------------------------------------------
            function sec:CreateInput(config)
                config = config or {}
                local el = makeElement(54)

                makeLabel(el, config.Name or "Input", 0, 0, 1, 22)

                local inputFrame = newInstance("Frame", {
                    Size = UDim2.new(1, -24, 0, 26),
                    Position = UDim2.new(0, 12, 0, 22),
                    BackgroundColor3 = C.Surface3,
                    BorderSizePixel = 0,
                    Parent = el
                })
                applyCorner(inputFrame, 6)

                local inputStroke = newInstance("UIStroke", {
                    Color = C.Border,
                    Thickness = 1,
                    Parent = inputFrame
                })

                local box = newInstance("TextBox", {
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    PlaceholderText = config.Placeholder or "Type here...",
                    PlaceholderColor3 = C.TextDim,
                    Text = config.Default or "",
                    TextColor3 = C.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = config.ClearOnFocus ~= false,
                    Parent = inputFrame
                })

                box.Focused:Connect(function()
                    tween(inputStroke, {Color = C.Accent}, 0.15)
                end)
                box.FocusLost:Connect(function(enter)
                    tween(inputStroke, {Color = C.Border}, 0.15)
                    if config.Callback then
                        task.spawn(config.Callback, box.Text)
                    end
                end)

                if config.onChanged then
                    box:GetPropertyChangedSignal("Text"):Connect(function()
                        task.spawn(config.onChanged, box.Text)
                    end)
                end

                local inputObj = {}
                function inputObj:Set(v)
                    box.Text = v
                end
                function inputObj:Get()
                    return box.Text
                end
                return inputObj
            end

            -- --------------------------------------------------------
            -- KEYBIND
            -- --------------------------------------------------------
            function sec:CreateKeybind(config)
                config = config or {}
                local currentKey = config.Default or Enum.KeyCode.Unknown
                local listening = false
                if config.Flag then NullLib.Flags[config.Flag] = currentKey end

                local el = makeElement(38)

                makeLabel(el, config.Name or "Keybind")

                local keyBtn = newInstance("TextButton", {
                    Size = UDim2.new(0, 80, 0, 24),
                    Position = UDim2.new(1, -92, 0.5, -12),
                    BackgroundColor3 = C.Surface3,
                    Text = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name,
                    TextColor3 = C.Accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = el
                })
                applyCorner(keyBtn, 6)
                newInstance("UIStroke", {Color = C.Border, Thickness = 1, Parent = keyBtn})

                keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                    tween(keyBtn, {BackgroundColor3 = C.AccentDark}, 0.1)
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if listening and not gp then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            if config.Flag then NullLib.Flags[config.Flag] = currentKey end
                            keyBtn.Text = currentKey.Name
                            listening = false
                            tween(keyBtn, {BackgroundColor3 = C.Surface3}, 0.1)
                            if config.onBinded then task.spawn(config.onBinded, currentKey) end
                        end
                    elseif not gp and input.KeyCode == currentKey and not listening then
                        if config.Callback then task.spawn(config.Callback, currentKey) end
                    end
                end)

                local kbObj = {}
                function kbObj:Set(key)
                    currentKey = key
                    keyBtn.Text = key.Name
                    if config.Flag then NullLib.Flags[config.Flag] = key end
                end
                return kbObj
            end

            -- --------------------------------------------------------
            -- COLORPICKER
            -- --------------------------------------------------------
            function sec:CreateColorpicker(config)
                config = config or {}
                local color = config.Default or Color3.fromRGB(255,255,255)
                local alpha = config.Alpha or 1
                local pickerOpen = false
                if config.Flag then NullLib.Flags[config.Flag] = color end

                local el = makeElement(38)
                el.ClipsDescendants = false

                makeLabel(el, config.Name or "Color")

                local preview = newInstance("Frame", {
                    Size = UDim2.new(0, 26, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = color,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = el
                })
                applyCorner(preview, 5)
                newInstance("UIStroke", {Color = C.BorderLight, Thickness = 1, Parent = preview})

                -- Color picker panel (simplified HSV picker)
                local panel = newInstance("Frame", {
                    Size = UDim2.new(0, 220, 0, 180),
                    Position = UDim2.new(1, -220, 1, 6),
                    BackgroundColor3 = C.Surface2,
                    BorderSizePixel = 0,
                    ZIndex = 30,
                    Visible = false,
                    ClipsDescendants = true,
                    Parent = el
                })
                applyCorner(panel, 10)
                newInstance("UIStroke", {Color = C.BorderLight, Thickness = 1, Parent = panel})

                -- SV gradient box
                local svFrame = newInstance("Frame", {
                    Size = UDim2.new(1, -16, 0, 110),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 31,
                    Parent = panel
                })
                applyCorner(svFrame, 6)

                -- White overlay
                local whiteGrad = newInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Parent = svFrame
                })

                -- Black overlay
                local blackOverlay = newInstance("Frame", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundColor3 = Color3.fromRGB(0,0,0),
                    BorderSizePixel = 0,
                    ZIndex = 32,
                    Parent = svFrame
                })
                newInstance("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0)
                    }),
                    Parent = blackOverlay
                })
                applyCorner(blackOverlay, 6)

                local svThumb = newInstance("Frame", {
                    Size = UDim2.new(0, 12, 0, 12),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    ZIndex = 34,
                    Parent = svFrame
                })
                applyCorner(svThumb, 6)
                newInstance("UIStroke", {Color = Color3.fromRGB(0,0,0), Thickness = 1.5, Parent = svThumb})

                -- Hue bar
                local hueBar = newInstance("Frame", {
                    Size = UDim2.new(1, -16, 0, 14),
                    Position = UDim2.new(0, 8, 0, 124),
                    BorderSizePixel = 0,
                    ZIndex = 31,
                    Parent = panel
                })
                applyCorner(hueBar, 4)
                newInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,1,1)),
                    }),
                    Parent = hueBar
                })

                local hueThumb = newInstance("Frame", {
                    Size = UDim2.new(0, 6, 1, 2),
                    Position = UDim2.new(0, -3, 0, -1),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    ZIndex = 33,
                    Parent = hueBar
                })
                applyCorner(hueThumb, 3)
                newInstance("UIStroke", {Color = Color3.fromRGB(0,0,0), Thickness = 1.5, Parent = hueThumb})

                local h, s, v = Color3.toHSV(color)

                local function updateColor()
                    color = Color3.fromHSV(h, s, v)
                    preview.BackgroundColor3 = color
                    svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    svThumb.Position = UDim2.new(s, -6, 1-v, -6)
                    hueThumb.Position = UDim2.new(h, -3, 0, -1)
                    if config.Flag then NullLib.Flags[config.Flag] = color end
                    if config.Callback then task.spawn(config.Callback, color, alpha) end
                end

                -- SV interaction
                local svDragging = false
                local svBtn = newInstance("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 35,
                    Parent = svFrame
                })
                svBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        svDragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        svDragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if svDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        local abs = svFrame.AbsolutePosition
                        local sz = svFrame.AbsoluteSize
                        s = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - abs.Y) / sz.Y, 0, 1)
                        updateColor()
                    end
                end)

                -- Hue interaction
                local hueDragging = false
                local hueBtn = newInstance("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 35,
                    Parent = hueBar
                })
                hueBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        local abs = hueBar.AbsolutePosition
                        local sz = hueBar.AbsoluteSize
                        h = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                        updateColor()
                    end
                end)

                -- Toggle picker
                local toggleBtn = newInstance("TextButton", {
                    Size = UDim2.new(0, 36, 0, 30),
                    Position = UDim2.new(1, -44, 0.5, -15),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 5,
                    Parent = el
                })
                toggleBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    panel.Visible = pickerOpen
                end)

                updateColor()

                local cpObj = {}
                function cpObj:SetColor(c)
                    h, s, v = Color3.toHSV(c)
                    color = c
                    updateColor()
                end
                function cpObj:GetColor()
                    return color
                end
                return cpObj
            end

            -- --------------------------------------------------------
            -- LABEL
            -- --------------------------------------------------------
            function sec:CreateLabel(config)
                config = config or {}
                local el = makeElement(30)
                el.BackgroundTransparency = 1

                newInstance("UIStroke", {Color = Color3.fromRGB(0,0,0), Thickness = 0, Parent = el})

                newInstance("TextLabel", {
                    Size = UDim2.new(1, -24, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text = config.Text or config.Name or "Label",
                    TextColor3 = config.Color or C.TextMuted,
                    Font = Enum.Font.Gotham,
                    TextSize = config.TextSize or 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = el
                })
            end

            -- --------------------------------------------------------
            -- PARAGRAPH
            -- --------------------------------------------------------
            function sec:CreateParagraph(config)
                config = config or {}
                local el = makeElement(0)
                el.AutomaticSize = Enum.AutomaticSize.Y
                applyPadding(el, 10, 12, 10, 12)
                applyListLayout(el, 4)

                if config.Header or config.Title then
                    newInstance("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Text = config.Header or config.Title,
                        TextColor3 = C.Text,
                        Font = Enum.Font.GothamBold,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true,
                        Parent = el
                    })
                end

                newInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text = config.Body or config.Text or "",
                    TextColor3 = C.TextMuted,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = el
                })
            end

            -- --------------------------------------------------------
            -- DIVIDER
            -- --------------------------------------------------------
            function sec:CreateDivider()
                newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = C.Border,
                    BorderSizePixel = 0,
                    Parent = itemList
                })
            end

            return sec
        end

        return tab
    end

    return Window
end

return NullLib
