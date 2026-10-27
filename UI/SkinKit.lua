local addonName, NS = ...

local Kit = {}
NS.SkinKit = Kit

local WHITE = "Interface\\Buttons\\WHITE8x8"
Kit.WHITE = WHITE

local REGION_KEYS = {
    "Bg", "Bgs", "Background", "BackgroundBottom", "BackgroundTop",
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopBorder", "BottomBorder", "LeftBorder", "RightBorder",
    "InsetBorderTopLeft", "InsetBorderTopRight",
    "InsetBorderBottomLeft", "InsetBorderBottomRight",
    "InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
    "NineSlice", "NineSliceInset", "NineSliceBorder", "NineSliceGlow",
    "Left", "Center", "Right", "Middle",
    "LeftHighlight", "CenterHighlight", "RightHighlight",
    "TopTileStreaks", "PortraitFrame",
    "DescriptionBG", "DescriptionBGBottom",
    "ShadowOverlay", "ShadowBackground",
}

local CHROME_PATTERNS = {
    "dialogframe\\",
    "framegeneral\\",
    "optionsframe\\",
    "helpframe\\",
    "helpsidebar",
    "knowledgebase",
    "ui%-panel%-button",
    "ui%-sliderbar",
    "ui%-tooltip%-background",
    "ui%-tooltip%-border",
    "ui%-background%-marble",
    "ui%-background%-rock",
    "chatframebackground",
    "paperoverlay",
    "paperheader",
    "encounterjournal",
    "ui%-ej%-",
    "ui%-frame%-",
    "questframe\\",
    "uipanelbackground",
    "achievement%-parchment",
    "charactercreate%-labelframe",
    "ui%-dialogbox%-",
    "ui%-panel%-minimizebutton",
    "collapsiblebg",
    "bigpaperbutton",
    "navmenu%-",
}

local MAX_DEPTH = 8
local MAX_NODES = 5000

local function IsObject(value)
    return type(value) == "table" and type(value.GetObjectType) == "function"
end

Kit.IsObject = IsObject

local function Style()
    return NS.Styling
end

Kit.Style = Style

local function TexturePath(region)
    if not region.GetTexture then return end
    local ok, path = pcall(region.GetTexture, region)
    if not ok or type(path) ~= "string" then return end
    return path:lower()
end

local function IsChrome(region)
    local path = TexturePath(region)
    if not path then return false end

    for _, pattern in ipairs(CHROME_PATTERNS) do
        if path:find(pattern) then return true end
    end

    return false
end

local STATE_GETTERS = {
    "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture",
    "GetHighlightTexture", "GetCheckedTexture", "GetDisabledCheckedTexture",
}

function Kit.ClearStates(button)
    for _, getter in ipairs(STATE_GETTERS) do
        if button[getter] then
            local ok, region = pcall(button[getter], button)

            if ok and IsObject(region) and not region.narciKeepVisible then
                if IsChrome(region) then
                    pcall(region.SetTexture, region, nil)
                    region:SetAlpha(0)
                end
            end
        end
    end
end

function Kit.Dim(region)
    if IsObject(region) and region.SetAlpha then region:SetAlpha(0) end
end

function Kit.StripRegions(frame)
    if not IsObject(frame) or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if IsObject(region) and not region.narciKeepVisible
            and region:GetObjectType() == "Texture" and IsChrome(region) then
            region:SetAlpha(0)
        end
    end
end

function Kit.StripKeys(frame)
    for _, key in ipairs(REGION_KEYS) do
        local region = frame[key]
        if IsObject(region) and region.SetAlpha and not region.narciKeepVisible then
            region:SetAlpha(0)
        end
    end
end

function Kit.StripElv(frame)
    local backdrop = rawget(frame, "backdrop")
    if IsObject(backdrop) and backdrop.SetAlpha then backdrop:SetAlpha(0) end

    if frame.narciGround or not frame.GetBackdrop then return end

    local ok, current = pcall(frame.GetBackdrop, frame)
    if ok and current then pcall(frame.SetBackdrop, frame, nil) end
end

function Kit.StripOne(frame)
    if not IsObject(frame) then return end

    Kit.StripKeys(frame)
    Kit.StripRegions(frame)
    Kit.StripElv(frame)
end

function Kit.Walk(frame, depth, fn, state)
    if not IsObject(frame) or frame.narciOwn then return end

    state = state or { count = 0 }
    depth = depth or MAX_DEPTH

    state.count = state.count + 1
    if state.count > MAX_NODES then return end

    fn(frame)

    if depth <= 0 or not frame.GetChildren then return end

    for _, child in ipairs({ frame:GetChildren() }) do
        Kit.Walk(child, depth - 1, fn, state)
    end
end

function Kit.Strip(frame, depth)
    Kit.Walk(frame, depth or MAX_DEPTH, Kit.StripOne)
end

function Kit.Ground(frame)
    if frame.narciGround then return frame.narciGround end

    if frame.SetBackdrop then pcall(frame.SetBackdrop, frame, nil) end

    local base = frame:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints(frame)
    base:SetTexture(WHITE)
    base:SetVertexColor(NS.Styling.Panel(0.022, 0.025, 0.034, 0.97))
    base.narciKeepVisible = true

    local S = Style()
    local rim = {}

    for index = 1, 4 do
        local line = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        line:SetTexture(WHITE)
        line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        line.narciKeepVisible = true
        rim[index] = line
    end

    rim[1]:SetHeight(1)
    rim[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    rim[1]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    rim[2]:SetHeight(1)
    rim[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    rim[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    rim[3]:SetWidth(1)
    rim[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    rim[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    rim[4]:SetWidth(1)
    rim[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rim[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    frame.narciGround = base
    frame.narciRim = rim

    Kit.Ensure(frame)

    return base
end

function Kit.Ensure(frame)
    if not IsObject(frame) or not frame.narciGround then return end

    local S = Style()

    frame.narciGround:SetAlpha(1)

    for _, line in ipairs(frame.narciRim or {}) do
        line:SetAlpha(1)
    end

    if not frame.SetBackdrop then return end

    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(NS.Styling.Panel(0.020, 0.023, 0.032, 0.97))
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
end

function Kit.Inset(frame, alpha)
    if frame.narciInset then return frame.narciInset end

    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetAllPoints(frame)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(0.000, 0.000, 0.000, alpha or 0.28)

    frame.narciInset = fill
    return fill
end

function Kit.Edge(frame, edge, inset, strength)
    local S = Style()
    inset = inset or 14
    strength = strength or 0.32

    local first = frame:CreateTexture(nil, "BORDER")
    local second = frame:CreateTexture(nil, "BORDER")
    first:SetTexture(WHITE)
    second:SetTexture(WHITE)

    if edge == "LEFT" or edge == "RIGHT" then
        local anchor = edge == "LEFT" and "LEFT" or "RIGHT"
        first:SetWidth(1)
        second:SetWidth(1)
        first:SetPoint("TOP", frame, "TOP" .. anchor, 0, -inset)
        first:SetPoint("BOTTOM", frame, anchor, 0, 0)
        second:SetPoint("TOP", frame, anchor, 0, 0)
        second:SetPoint("BOTTOM", frame, "BOTTOM" .. anchor, 0, inset)
        first:SetGradientAlpha("VERTICAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], strength,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
        second:SetGradientAlpha("VERTICAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], strength)
    else
        local anchor = edge == "TOP" and "TOP" or "BOTTOM"
        first:SetHeight(1)
        second:SetHeight(1)
        first:SetPoint("LEFT", frame, anchor .. "LEFT", inset, 0)
        first:SetPoint("RIGHT", frame, anchor, 0, 0)
        second:SetPoint("LEFT", frame, anchor, 0, 0)
        second:SetPoint("RIGHT", frame, anchor .. "RIGHT", -inset, 0)
        first:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], strength)
        second:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], strength,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
    end

    return first, second
end

function Kit.Edges(frame, inset, strength)
    if frame.narciEdges then return end
    frame.narciEdges = true

    Kit.Edge(frame, "TOP", inset, strength)
    Kit.Edge(frame, "BOTTOM", inset, strength)
    Kit.Edge(frame, "LEFT", inset, strength)
    Kit.Edge(frame, "RIGHT", inset, strength)
end

function Kit.Rule(frame, width, point, relativeTo, relativePoint, x, y)
    local S = Style()

    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetWidth(width or 240)
    line:SetPoint(point or "TOPLEFT", relativeTo or frame, relativePoint or "TOPLEFT", x or 0, y or 0)
    line:SetTexture(WHITE)
    line:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)

    return line
end

function Kit.Highlight(button, alpha, inset)
    if not button.SetHighlightTexture then return end

    local S = Style()
    inset = inset or 2

    button:SetHighlightTexture(WHITE)
    local highlight = button:GetHighlightTexture()
    if not highlight then return end

    highlight:SetAlpha(1)
    highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], alpha or 0.12)
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
end

function Kit.Underline(button, height, inset)
    local S = Style()

    local under = button:CreateTexture(nil, "BORDER")
    under:SetHeight(height or 1)
    under:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", inset or 6, 3)
    under:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(inset or 6), 3)
    under:SetTexture(WHITE)
    under:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.75)

    return under
end

function Kit.Button(button, plain)
    if not IsObject(button) or button.narciButton then return end
    button.narciButton = true

    Kit.StripOne(button)

    Kit.ClearStates(button)

    if not plain then Kit.Underline(button) end
    Kit.Highlight(button, 0.12)

    local text = button.GetFontString and button:GetFontString()
    if text then
        local S = Style()
        text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end
end

function Kit.Row(button)
    if not IsObject(button) or button.narciRow then return end
    button.narciRow = true
    button.narciButton = true

    local S = Style()

    Kit.StripOne(button)

    Kit.ClearStates(button)

    local current = button.GetHighlightTexture and button:GetHighlightTexture()
    local label = button.GetFontString and button:GetFontString()
    local tied = false
    if IsObject(current) and label and label.GetNumPoints then
        for index = 1, label:GetNumPoints() do
            local _, relativeTo = label:GetPoint(index)
            if relativeTo == current then tied = true end
        end
    end

    if tied then
        pcall(current.SetTexture, current, nil)
        current:SetAlpha(0)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(button)
        highlight:SetTexture(WHITE)
        highlight:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.01)
    elseif button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE)
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:ClearAllPoints()
            highlight:SetAllPoints(button)
            highlight:SetAlpha(1)
            highlight:SetGradientAlpha("HORIZONTAL",
                S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22,
                S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.01)
        end
    end

    local bar = button:CreateTexture(nil, "BORDER")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -1)
    bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 1)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    bar:Hide()

    button.narciBar = bar

    button:HookScript("OnEnter", function(self)
        self.narciBar:Show()
    end)

    button:HookScript("OnLeave", function(self)
        if self.narciSelected then return end
        self.narciBar:Hide()
    end)
end

function Kit.SetRowSelected(button, selected)
    if not IsObject(button) or not button.narciBar then return end

    button.narciSelected = selected and true or false
    button.narciBar:SetShown(button.narciSelected)
end

function Kit.Close(button)
    if not IsObject(button) or button.narciClose then return end
    button.narciClose = true

    local S = Style()

    Kit.ClearStates(button)

    button:SetSize(22, 22)

    local mark = button:CreateFontString(nil, "OVERLAY")
    mark:SetFont(NS.FONT, NS.FS(15), "")
    mark:SetPoint("CENTER", button, "CENTER", 0, 0)
    mark:SetText("X")
    mark:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    NS.Styling.GlyphIcon(mark)

    button:HookScript("OnEnter", function()
        mark:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end)

    button:HookScript("OnLeave", function()
        mark:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end)
end

function Kit.Tab(button, isActive)
    if not IsObject(button) then return end

    if not button.narciTab then
        button.narciTab = true

        local S = Style()

        Kit.StripOne(button)
    Kit.ClearStates(button)

        local under = button:CreateTexture(nil, "BORDER")
        under:SetHeight(2)
        under:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 8, 2)
        under:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 2)
        under:SetTexture(WHITE)
        under:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
        under:Hide()

        Kit.Highlight(button, 0.10, 0)
        button.narciTabLine = under
    end

    if isActive ~= nil then
        button.narciTabLine:SetShown(isActive and true or false)

        local text = button.GetFontString and button:GetFontString()
        if text then
            local S = Style()
            if isActive then
                text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            else
                text:SetTextColor(S.GOLD_DIM[1], S.GOLD_DIM[2], S.GOLD_DIM[3])
            end
        end
    end
end

function Kit.Arrow(button)
    if not IsObject(button) or button.narciArrow then return end
    button.narciArrow = true

    local S = Style()

    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local region = button[getter] and button[getter](button)
        if region then
            region:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3])
            region:SetAlpha(1)
        end
    end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0.35) end
end

function Kit.ScrollBar(bar)
    if not IsObject(bar) or bar.narciScroll then return end
    bar.narciScroll = true

    local S = Style()

    Kit.StripOne(bar)

    local name = bar.GetName and bar:GetName()
    if name then
        Kit.Arrow(_G[name .. "ScrollUpButton"])
        Kit.Arrow(_G[name .. "ScrollDownButton"])
    end
    Kit.Arrow(bar.ScrollUpButton)
    Kit.Arrow(bar.ScrollDownButton)

    for _, key in ipairs({ "Track", "Top", "Bottom" }) do
        Kit.Dim(bar[key])
    end

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", bar, "TOPLEFT", 3, 0)
    track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -3, 0)
    track:SetTexture(WHITE)
    track:SetVertexColor(0.085, 0.092, 0.120, 0.95)

    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture(WHITE)
        thumb:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        thumb:SetAlpha(1)
        thumb:SetWidth(5)
    end
end

function Kit.EditBox(box)
    if not IsObject(box) or box.narciEdit then return end
    box.narciEdit = true

    local host = box

    if box.IsMultiLine and box:IsMultiLine() then
        local parent = box:GetParent()
        if IsObject(parent) and parent:GetObjectType() == "ScrollFrame" then host = parent end
    end

    local S = Style()

    Kit.StripOne(box)

    local name = box.GetName and box:GetName()
    if name then
        for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
            Kit.Dim(_G[name .. suffix])
        end
    end

    local plate = Kit.Plate(host, 2)

    box:HookScript("OnEditFocusGained", function()
        plate.Light(true)
    end)

    box:HookScript("OnEditFocusLost", function()
        plate.Light(false)
    end)
end

function Kit.Plate(frame, padding)
    local S = Style()
    padding = padding or 0

    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(0.085, 0.092, 0.118, 0.95)

    local edges = {}

    for index = 1, 4 do
        local line = frame:CreateTexture(nil, "BORDER")
        line:SetTexture(WHITE)
        line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.75)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)

    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)

    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 0)

    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)

    local plate = { Fill = fill, Edges = edges }

    function plate.Light(lit)
        for _, line in ipairs(edges) do
            if lit then
                line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
            else
                line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.75)
            end
        end
    end

    return plate
end

function Kit.PlateBox(parent, width, height, x, y)
    local S = Style()

    local fill = parent:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetSize(width, height)
    fill:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(0.085, 0.092, 0.118, 0.95)

    local edges = {}

    for index = 1, 4 do
        local line = parent:CreateTexture(nil, "BACKGROUND", nil, 3)
        line:SetTexture(WHITE)
        line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.75)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)

    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)

    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 0)

    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)

    return fill
end

function Kit.Field(button)
    if not IsObject(button) or button.narciField then return end
    button.narciField = true
    button.narciButton = true
    button.narciSkipAuto = true

    Kit.StripOne(button)

    Kit.ClearStates(button)

    local plate = Kit.Plate(button, 0)

    button:HookScript("OnEnter", function() plate.Light(true) end)
    button:HookScript("OnLeave", function() plate.Light(false) end)
end

function Kit.Check(button)
    if not IsObject(button) or button.narciCheck then return end
    button.narciCheck = true

    local S = Style()

    Kit.ClearStates(button)

    local edge = button:CreateTexture(nil, "BORDER")
    edge:SetPoint("CENTER", button, "CENTER", 0, 0)
    edge:SetSize(14, 14)
    edge:SetTexture(WHITE)
    edge:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local box = button:CreateTexture(nil, "ARTWORK")
    box:SetPoint("CENTER", button, "CENTER", 0, 0)
    box:SetSize(12, 12)
    box:SetTexture(WHITE)
    box:SetVertexColor(0.045, 0.050, 0.068, 0.95)

    if button.SetCheckedTexture then
        button:SetCheckedTexture(WHITE)
        local checked = button:GetCheckedTexture()
        if checked then
            checked:SetAlpha(1)
            checked:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            checked:ClearAllPoints()
            checked:SetPoint("CENTER", button, "CENTER", 0, 0)
            checked:SetSize(7, 7)
        end
    end

    if button.SetDisabledCheckedTexture then
        button:SetDisabledCheckedTexture(WHITE)
        local disabled = button:GetDisabledCheckedTexture()
        if disabled then
            disabled:SetAlpha(1)
            disabled:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.6)
            disabled:ClearAllPoints()
            disabled:SetPoint("CENTER", button, "CENTER", 0, 0)
            disabled:SetSize(7, 7)
        end
    end

    button:HookScript("OnEnter", function()
        edge:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    end)

    button:HookScript("OnLeave", function()
        edge:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end)
end

function Kit.Slider(slider)
    if not IsObject(slider) or slider.narciSlider then return end
    slider.narciSlider = true

    local S = Style()

    Kit.StripOne(slider)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(2)
    track:SetPoint("LEFT", slider, "LEFT", 2, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", -2, 0)
    track:SetTexture(WHITE)
    track:SetVertexColor(0.08, 0.09, 0.12, 0.95)

    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    if thumb then
        thumb:SetTexture(WHITE)
        thumb:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        thumb:SetSize(6, 14)
        thumb:SetAlpha(1)
    end
end

function Kit.Dropdown(frame)
    if not IsObject(frame) or frame.narciDropdown then return end
    frame.narciDropdown = true

    local S = Style()

    local name = frame.GetName and frame:GetName()
    if name then
        for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
            Kit.Dim(_G[name .. suffix])
        end

        local button = _G[name .. "Button"]
        if button then
            Kit.Arrow(button)
            local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
            if highlight then highlight:SetAlpha(0) end
        end

        local text = _G[name .. "Text"]
        if text then text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]) end
    end

    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -5)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 7)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(NS.Styling.Tint(0.030, 0.034, 0.046, 0.92))

    local under = frame:CreateTexture(nil, "BORDER")
    under:SetHeight(1)
    under:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 0)
    under:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
    under:SetTexture(WHITE)
    under:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)
end

function Kit.StatusBar(bar)
    if not IsObject(bar) or bar.narciBar then return end
    bar.narciBar = true

    local S = Style()

    if bar.SetStatusBarTexture then
        bar:SetStatusBarTexture(WHITE)
        local texture = bar:GetStatusBarTexture()
        if texture then texture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9) end
    end
end

function Kit.KeepVisible(region, alpha, r, g, b)
    if not IsObject(region) then return end

    region.narciKeepVisible = true
    region:SetAlpha(alpha or 1)
    if r then region:SetVertexColor(r, g, b) end
end

function Kit.Html(frame, tone)
    if not IsObject(frame) or frame.narciHtml then return end
    frame.narciHtml = true

    local S = Style()
    tone = tone or S.TEXT_BRIGHT

    pcall(frame.SetTextColor, frame, tone[1], tone[2], tone[3])

    for _, element in ipairs({ "p", "h1", "h2", "h3" }) do
        pcall(frame.SetTextColor, frame, element, tone[1], tone[2], tone[3])
    end
end

function Kit.Title(frame, text, size)
    if frame.narciTitle then
        frame.narciTitle:SetText(text)
        return frame.narciTitle
    end

    local S = Style()

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(size or 15), "")
    label:SetPoint("TOP", frame, "TOP", 0, -14)
    label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    label:SetText(text)

    frame.narciTitle = label
    return label
end

function Kit.Window(frame, options)
    if not IsObject(frame) then return end
    options = options or {}

    if not frame.narciWindow then
        frame.narciWindow = true

        Kit.Ground(frame)
        Kit.Edges(frame, options.inset or 18)
        Style().CreateShadow(frame, 6, 0.5)
        Style().Decorate(frame, true)
        Style().CreateGradientTopBorder(frame, 2)
    end

    Kit.Strip(frame, options.depth or MAX_DEPTH)
end

local function NameHas(frame, needle)
    local name = frame.GetName and frame:GetName()
    return name and name:find(needle) and true or false
end

Kit.NameHas = NameHas

function Kit.Classify(frame)
    if not IsObject(frame) or frame.narciSkipAuto then return end

    local kind = frame:GetObjectType()

    if kind == "EditBox" then
        Kit.EditBox(frame)
    elseif kind == "Slider" then
        if NameHas(frame, "ScrollBar") then Kit.ScrollBar(frame) else Kit.Slider(frame) end
    elseif kind == "StatusBar" then
        Kit.StatusBar(frame)
    elseif kind == "CheckButton" then
        Kit.Check(frame)
    elseif kind == "Button" then
        local width, height = frame:GetWidth() or 0, frame:GetHeight() or 0

        if NameHas(frame, "CloseButton") then
            Kit.Close(frame)
        elseif width <= 24 and height <= 24 then
            Kit.Arrow(frame)
        else
            local label = frame.GetFontString and frame:GetFontString()
            local listed = not label or (label.GetJustifyH and label:GetJustifyH() == "LEFT")

            if width >= 140 and height <= 30 and listed then
                Kit.Row(frame)
            else
                local square = width <= 72 and math.abs(width - height) <= 10
                Kit.Button(frame, square)
            end
        end
    elseif kind == "Frame" and NameHas(frame, "DropDown") and not NameHas(frame, "Button") then
        Kit.Dropdown(frame)
    end
end

local function Note(node, err)
    Kit.errors = (Kit.errors or 0) + 1
    Kit.lastError = tostring(err)
    Kit.lastErrorFrame = (node.GetName and node:GetName()) or node:GetObjectType()
end

function Kit.Auto(frame, depth)
    Kit.Walk(frame, depth or MAX_DEPTH, function(node)
        local stripped, stripError = pcall(Kit.StripOne, node)
        if not stripped then Note(node, stripError) end

        local classified, classifyError = pcall(Kit.Classify, node)
        if not classified then Note(node, classifyError) end
    end)
end

function Kit.KeepClear(frame, depth, extra)
    if not IsObject(frame) or frame.narciKeep then return end
    frame.narciKeep = true

    frame:HookScript("OnShow", function(self)
        Kit.Strip(self, depth or MAX_DEPTH)
        if extra then pcall(extra, self) end
    end)
end
