local addonName, NS = ...
local L = NS.L

local P = {}
NS.SettingsPreview = P

local WHITE = "Interface\\Buttons\\WHITE8x8"
local W, H = 330, 260

local function Font(parent, size, flags, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(size), flags or "")
    text:SetJustifyH("LEFT")
    return text
end

local function Fill(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(WHITE)
    t:SetVertexColor(r or 0, g or 0, b or 0, a or 1)
    return t
end

local function World(view)
    local t = view:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(view)
    t:SetTexture(WHITE)
    t:SetGradientAlpha("VERTICAL", 0.10, 0.13, 0.10, 1, 0.20, 0.26, 0.32, 1)
    local hill = view:CreateTexture(nil, "BACKGROUND")
    hill:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    hill:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    hill:SetHeight(60)
    hill:SetTexture(WHITE)
    hill:SetGradientAlpha("VERTICAL", 0.06, 0.09, 0.05, 1, 0.06, 0.09, 0.05, 0)
    return t
end

local function Accent()
    local A = NS.Styling.ACCENT_GLOW
    return A[1], A[2], A[3]
end

local function Color(value, fallback)
    if value == "accent" then return Accent() end
    value = value or fallback
    return value[1], value[2], value[3], value[4]
end

function P:Host()
    if self.host and self.host:IsShown() then return self.host end
    return NS.settingsFrame
end

function P:Frame()
    if self.frame then return self.frame end
    local S = NS.Styling
    local host = NS.settingsFrame

    local f = CreateFrame("Frame", "NarciSirus_SettingsPreview", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel((host and host:GetFrameLevel() or 240) + 45)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(S.Bg(0.97))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 5, 0.45)

    local head = Font(f, 10, "")
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -9)
    head:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    head:SetText(L["Как это будет выглядеть"])

    local title = Font(f, 13, "OUTLINE")
    title:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -3)
    title:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    local canvas = CreateFrame("Frame", nil, f)
    canvas:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -46)
    canvas:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)

    local failHolder = CreateFrame("Frame", nil, f)
    failHolder:SetAllPoints(f)
    failHolder:SetFrameLevel(canvas:GetFrameLevel() + 40)
    local failGround = failHolder:CreateTexture(nil, "BACKGROUND")
    local fail = Font(failHolder, 9, "", "OVERLAY")
    fail:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    fail:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    failGround:SetPoint("TOPLEFT", fail, "TOPLEFT", -4, 3)
    failGround:SetPoint("BOTTOMRIGHT", fail, "BOTTOMRIGHT", 4, -3)
    failGround:SetTexture(WHITE)
    failGround:SetVertexColor(0, 0, 0, 0.85)
    fail.ground = failGround
    fail:SetTextColor(1, 0.35, 0.3)
    fail:SetJustifyV("BOTTOM")

    f.title, f.canvas, f.views, f.fail = title, canvas, {}, fail
    f:Hide()
    if host then host:HookScript("OnHide", function() f:Hide() end) end
    self.frame = f
    return f
end

function P:IsShown()
    return self.frame and self.frame:IsShown()
end

function P:Place(button)
    local f, host = self.frame, self:Host()
    if not host then return end
    local scale = host:GetEffectiveScale()
    local room = UIParent:GetRight() * UIParent:GetEffectiveScale() - (host:GetRight() or 0) * scale
    local top = button and button:GetTop() or host:GetTop()
    local y = math.min(0, (top or 0) - (host:GetTop() or 0) + 40)
    f:ClearAllPoints()
    if room >= ((f:GetWidth() or W) + 14) * scale then
        f:SetPoint("TOPLEFT", host, "TOPRIGHT", 10, y)
    else
        f:SetPoint("TOPRIGHT", host, "TOPLEFT", -10, y)
    end
end

function P:Show(renderer, key, label, button)
    local f = self:Frame()
    self.token = (self.token or 0) + 1
    local view = f.views[renderer]
    if not view then
        view = CreateFrame("Frame", nil, f.canvas)
        view:SetAllPoints(f.canvas)
        f.views[renderer] = view
    end
    for other, frame in pairs(f.views) do
        if other ~= renderer then frame:Hide() end
    end
    view:Show()
    local size = self.SIZE and self.SIZE[renderer]
    f:SetSize(size and size[1] or W, size and size[2] or H)
    f.title:SetText(NS.L[label or ""] or "")
    self.failure = nil
    local ok, err = pcall(renderer, view, key)
    if not ok then self:Fail(err) end
    f.fail:SetText(self.failure or "")
    f.fail:SetShown(self.failure ~= nil)
    f.fail.ground:SetShown(self.failure ~= nil)
    self:Place(button)
    f:Show()
    if NS.Settings and NS.Settings.hintCard then NS.Settings.hintCard:Hide() end
end

function P:Fail(err)
    self.failure = self.failure or tostring(err)
end

function P:Leave()
    local token = (self.token or 0) + 1
    self.token = token
    NS.After(0.25, function()
        if self.token == token and self.frame then self.frame:Hide() end
    end)
end

function P:Attach(widget, renderer)
    widget.onHover = function(button, key, label) P:Show(renderer, key, label, button) end
    widget.onHoverEnd = function() P:Leave() end
end

local function Centered(view, w, h)
    local frame = CreateFrame("Frame", nil, view)
    frame:SetSize(w, h)
    frame:SetPoint("CENTER", view, "CENTER", 0, 0)
    return frame
end

function P.Box(kind, opts)
    opts = opts or {}
    return function(view, key)
        local S = NS.Styling
        if not view.built then
            view.built = true
            World(view)
            local sample
            if kind == "bar" then
                sample = Centered(view, 240, 14)
                local fill = CreateFrame("StatusBar", nil, sample)
                fill:SetPoint("TOPLEFT", sample, "TOPLEFT", 1, -1)
                fill:SetPoint("BOTTOMRIGHT", sample, "BOTTOMRIGHT", -1, 1)
                fill:SetStatusBarTexture(WHITE)
                fill:SetMinMaxValues(0, 1)
                fill:SetValue(0.62)
                sample.fill = fill
            elseif kind == "button" then
                sample = Centered(view, 46, 46)
                local icon = sample:CreateTexture(nil, "ARTWORK")
                icon:SetPoint("TOPLEFT", sample, "TOPLEFT", 7, -7)
                icon:SetPoint("BOTTOMRIGHT", sample, "BOTTOMRIGHT", -7, 7)
                icon:SetTexture(opts.icon or S.Media("MicroSocial"))
                if opts.iconCoords then icon:SetTexCoord(unpack(opts.iconCoords)) end
                sample.icon = icon
                if opts.count then
                    local count = Font(sample, 13, "OUTLINE")
                    count:SetPoint("BOTTOMRIGHT", sample, "BOTTOMRIGHT", 2, -2)
                    count:SetText(opts.count)
                end
            elseif kind == "toggle" then
                sample = Centered(view, 110, 22)
                local label = Font(sample, 11, "OUTLINE")
                label:SetPoint("CENTER")
                label:SetText(L["Рейд"])
                sample.label = label
            else
                sample = Centered(view, 230, 150)
                for i = 1, 4 do
                    local row = CreateFrame("Frame", nil, sample)
                    row:SetSize(i < 4 and 100 or 210, 20)
                    if i < 4 then
                        row:SetPoint("TOPLEFT", sample, "TOPLEFT", 10 + ((i - 1) % 2) * 110, -12 - math.floor((i - 1) / 2) * 28)
                    else
                        row:SetPoint("BOTTOMLEFT", sample, "BOTTOMLEFT", 10, 12)
                    end
                    local ground = Fill(row, "BACKGROUND", 0.1, 0.11, 0.14, 0.9)
                    ground:SetAllPoints(row)
                    S.CreateEdges(row, "BORDER", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
                    local text = Font(row, 10, "")
                    text:SetPoint("CENTER")
                    text:SetText(({ L["Готовность"], L["Отсчёт"], L["Проверка ролей"], L["Распустить группу"] })[i])
                end
                local marks = sample:CreateTexture(nil, "ARTWORK")
                marks:SetSize(210, 24)
                marks:SetPoint("LEFT", sample, "LEFT", 10, -4)
                marks:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                marks:SetTexCoord(0, 1, 0, 0.25)
                marks:SetAlpha(0.85)
            end
            view.sample = sample
        end
        local sample = view.sample
        if sample.fill then
            local A = S.ACCENT_GLOW
            sample.fill:SetStatusBarColor(opts.fillColor and opts.fillColor[1] or A[1], opts.fillColor and opts.fillColor[2] or A[2], opts.fillColor and opts.fillColor[3] or A[3])
        end
        if sample.label then sample.label:SetTextColor(Accent()) end
        if key == "theme" then
            if kind == "panel" then
                S.SkinBox(sample, "flat", { alpha = 0.94 })
            else
                S.SkinBox(sample, "flat", { alpha = 0.85, tint = { S.ACCENT[1], S.ACCENT[2], S.ACCENT[3] } })
            end
        else
            S.SkinBox(sample, key, { alpha = 0.92, tint = opts.tint, edgeSize = kind == "panel" and 16 or 12 })
        end
    end
end

function P.ClassPower(field)
    return function(view, key)
        local S = NS.Styling
        local db = NS.db and NS.db.playerUI or {}
        local shapeKey = field == "shape" and key or db.classPowerShape or "bars"
        local style = field == "style" and key or db.classPowerStyle or "flat"
        local shapes = NS.PlayerUI and NS.PlayerUI.CLASS_POWER_SHAPES or {}
        local shape = shapes[shapeKey]
        if not view.built then
            view.built = true
            World(view)
            local frame = Centered(view, 240, 50)
            local hint = Font(view, 10, "")
            hint:SetPoint("TOP", frame, "BOTTOM", 0, -12)
            hint:SetJustifyH("CENTER")
            hint:SetText(L["3 из 5 очков серии"])
            view.segs = {}
            for i = 1, 5 do
                local seg = CreateFrame("Frame", nil, frame)
                seg.bar = CreateFrame("StatusBar", nil, seg)
                seg.bar:SetPoint("TOPLEFT", seg, "TOPLEFT", 1, -1)
                seg.bar:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", -1, 1)
                seg.bar:SetStatusBarTexture(WHITE)
                seg.bar:SetMinMaxValues(0, 1)
                seg.glow = seg:CreateTexture(nil, "BACKGROUND")
                seg.glow:SetTexture(S.GLOW)
                seg.glow:SetPoint("CENTER")
                seg.ground = seg:CreateTexture(nil, "BORDER")
                seg.ground:SetAllPoints(seg)
                seg.orb = CreateFrame("StatusBar", nil, seg)
                seg.orb:SetAllPoints(seg)
                seg.orb:SetMinMaxValues(0, 1)
                seg.orb:SetOrientation("VERTICAL")
                local top = CreateFrame("Frame", nil, seg)
                top:SetAllPoints(seg)
                top:SetFrameLevel(seg.orb:GetFrameLevel() + 1)
                seg.ring = top:CreateTexture(nil, "OVERLAY")
                seg.ring:SetPoint("CENTER")
                view.segs[i] = seg
            end
            view.holder = frame
        end
        local A = S.ACCENT_GLOW
        for i, seg in ipairs(view.segs) do
            local value = i <= 3 and 1 or 0
            seg:ClearAllPoints()
            if shape then
                local size = 30
                seg:SetSize(size, size)
                seg:SetPoint("CENTER", view.holder, "CENTER", (i - 3) * (size + 8), 0)
                S.SkinBox(seg, "none")
                seg.bar:Hide()
                seg.ground:SetTexture(S.Media(shape.fill))
                seg.ground:SetVertexColor(0.02, 0.022, 0.03, 0.92)
                seg.ground:Show()
                seg.orb:SetStatusBarTexture(S.Media(shape.fill))
                seg.orb:SetStatusBarColor(A[1], A[2], A[3])
                seg.orb:SetValue(value)
                seg.orb:Show()
                local r, g, b, a = S.BoxRing(style)
                seg.ring:SetTexture(S.Media(shape.ring))
                seg.ring:SetSize(size * shape.ringScale, size * shape.ringScale)
                if r then seg.ring:SetVertexColor(r, g, b, a) seg.ring:Show() else seg.ring:Hide() end
                seg.glow:SetSize(size * 2, size * 2)
                if style == "neon" then
                    seg.glow:SetBlendMode("ADD")
                    seg.glow:SetVertexColor(A[1], A[2], A[3], 0.45)
                    seg.glow:Show()
                elseif style == "soft" then
                    seg.glow:SetBlendMode("BLEND")
                    seg.glow:SetVertexColor(0, 0, 0, 0.7)
                    seg.glow:Show()
                else
                    seg.glow:Hide()
                end
            else
                seg:SetSize(44, 12)
                seg:SetPoint("CENTER", view.holder, "CENTER", (i - 3) * 47, 0)
                S.SkinBox(seg, style, { alpha = 0.92 })
                seg.bar:SetStatusBarColor(A[1], A[2], A[3])
                seg.bar:SetValue(value)
                seg.bar:Show()
                seg.orb:Hide()
                seg.ground:Hide()
                seg.ring:Hide()
                seg.glow:Hide()
            end
        end
    end
end

local function MockSkin(frame)
    local S = NS.Styling
    local skin = CreateFrame("Frame", nil, frame)
    skin:SetAllPoints(frame)
    skin:SetFrameLevel(frame:GetFrameLevel())
    skin.bg = Fill(skin, "BACKGROUND")
    skin.bg:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
    skin.bg:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
    skin.art = skin:CreateTexture(nil, "BORDER")
    skin.art:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
    skin.art:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
    skin.shade = Fill(skin, "ARTWORK", 0, 0, 0, 0)
    skin.shade:SetAllPoints(skin.art)
    skin.mark = skin:CreateTexture(nil, "ARTWORK")
    skin.mark:SetPoint("CENTER")
    skin.mark:SetBlendMode("ADD")
    skin.seal = skin:CreateTexture(nil, "OVERLAY")
    skin.top = Fill(skin, "OVERLAY")
    skin.top:SetHeight(2)
    skin.top:SetPoint("TOPLEFT", skin, "TOPLEFT", 3, -3)
    skin.top:SetPoint("TOPRIGHT", skin, "TOPRIGHT", -3, -3)
    skin.edges = S.CreateEdges(skin, "OVERLAY", 1, 1, 1, 1)
    skin.glow = S.GlowPieces(skin, 8, "BACKGROUND", "ADD", true)
    return skin
end

local function PaintSkin(skin, spec)
    local S = NS.Styling
    spec = spec or {}
    if spec.native then
        skin.bg:SetVertexColor(S.Bg(0.95))
        skin.bg:Show()
        skin.art:Hide()
        skin.shade:Hide()
        skin.mark:Hide()
        skin.seal:Hide()
        skin.top:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
        skin.top:Show()
        for _, line in ipairs(skin.edges) do
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            line:Show()
        end
        for _, t in ipairs(skin.glow) do t:Hide() end
        skin:SetBackdrop(nil)
        S.SkinBox(skin, "none")
        return
    end
    skin.top:Hide()
    if spec.bg then
        local r, g, b, a = Color(spec.bg)
        skin.bg:SetVertexColor(r, g, b, a or 1)
        skin.bg:Show()
    else
        skin.bg:Hide()
    end
    local art = spec.art
    if art then
        skin.art:SetTexture(S.Media(art.file))
        skin.art:SetVertexColor(1, 1, 1, art.alpha or 1)
        S.CoverArt(skin.art, art.aspect or 1, art.anchor)
        skin.art:Show()
    else
        skin.art:Hide()
    end
    if spec.shade and art then
        skin.shade:SetVertexColor(0, 0, 0, spec.shade)
        skin.shade:Show()
    else
        skin.shade:Hide()
    end
    if spec.mark then
        local size = math.min(skin:GetWidth() or 150, skin:GetHeight() or 150) * 0.9
        skin.mark:SetTexture(S.Media("MessengerRunes"))
        skin.mark:SetSize(size, size)
        skin.mark:SetVertexColor(0.7, 0.5, 1, spec.markAlpha or 0.22)
        skin.mark:Show()
    else
        skin.mark:Hide()
    end
    if spec.seal then
        skin.seal:SetTexture(S.Media("MessengerSeal"))
        skin.seal:SetSize(40, 40)
        skin.seal:ClearAllPoints()
        skin.seal:SetPoint("CENTER", skin, spec.sealPoint or "TOPLEFT", spec.sealPoint == "TOPRIGHT" and -10 or 10, -10)
        skin.seal:Show()
    else
        skin.seal:Hide()
    end
    if spec.backdrop then
        skin:SetBackdrop({ bgFile = spec.backdrop.bgFile, edgeFile = spec.backdrop.edgeFile, tile = true, tileSize = 32, edgeSize = 20,
            insets = { left = 6, right = 6, top = 6, bottom = 6 } })
        skin:SetBackdropColor(1, 1, 1, 1)
    else
        skin:SetBackdrop(nil)
    end
    if spec.edge and not spec.backdrop then
        local r, g, b = Color(spec.edge)
        for _, line in ipairs(skin.edges) do
            line:SetVertexColor(r, g, b, spec.edgeAlpha or 1)
            line:Show()
        end
    else
        for _, line in ipairs(skin.edges) do line:Hide() end
    end
    if spec.glow then
        local r, g, b = Color(spec.glow)
        for _, t in ipairs(skin.glow) do
            t:SetVertexColor(r, g, b, spec.glowAlpha or 0.3)
            t:Show()
        end
    else
        for _, t in ipairs(skin.glow) do t:Hide() end
    end
    S.SkinBox(skin, spec.box or "none", { alpha = 0.92, noGround = true, tint = spec.tint, edgeSize = 14, glowSize = 8 })
end

local MOCK_LINES = {
    { "in", "Привет! Идёшь сегодня в ЦЛК?" },
    { "out", "Да, через десять минут буду." },
    { "in", "Отлично, кидаю приглашение." },
    { "sys", "Игрок Аэлин теперь в сети." },
}

function P.Messenger(view, key)
    local S = NS.Styling
    local M = NS.Messenger
    local style = M and M.STYLES and M.STYLES[key] or { native = true }
    if not view.built then
        view.built = true
        World(view)
        local win = Centered(view, 300, 190)
        win.skin = MockSkin(win)
        local content = CreateFrame("Frame", nil, win)
        content:SetAllPoints(win)
        content:SetFrameLevel(win:GetFrameLevel() + 3)
        win.title = Font(content, 11, "OUTLINE")
        win.title:SetText(L["Сообщения"])
        win.side = Fill(content, "BACKGROUND")
        win.side:SetWidth(84)
        win.rows = {}
        local names = { { "Аэлин", "MAGE" }, { "Торвальд", "PALADIN" }, { "Шейд", "ROGUE" } }
        for i, info in ipairs(names) do
            local row = Fill(content, "BORDER")
            row:SetSize(80, 18)
            local text = Font(content, 9, "")
            text:SetPoint("LEFT", row, "LEFT", 6, 0)
            text:SetText(info[1])
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[info[2]]
            if c then text:SetTextColor(c.r, c.g, c.b) end
            win.rows[i] = row
        end
        win.lines = {}
        for i = 1, #MOCK_LINES do
            local line = Font(content, 9, "")
            line:SetWidth(190)
            win.lines[i] = line
        end
        win.input = Fill(content, "BORDER")
        win.input:SetHeight(16)
        win.content = content
        view.win = win
    end
    local win = view.win
    local pad = style.pad or 8
    PaintSkin(win.skin, style.native and { native = true } or {
        bg = style.bg, art = style.art, edge = style.backdrop and nil or style.edge, edgeAlpha = style.edgeAlpha,
        glow = style.glow, glowAlpha = style.glowAlpha, backdrop = style.backdrop,
        mark = style.mark and true, seal = style.seal and true,
    })
    win.title:ClearAllPoints()
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", pad + 4 + (style.titleX and 24 or 0), -pad)
    win.title:SetTextColor(Color(style.title, S.ACCENT_GLOW))
    win.side:ClearAllPoints()
    win.side:SetPoint("TOPLEFT", win, "TOPLEFT", pad, -(pad + 18))
    win.side:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", pad, pad)
    win.side:SetVertexColor(Color(style.side, { 0.02, 0.022, 0.03, 0.6 }))
    for i, row in ipairs(win.rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", win.side, "TOPLEFT", 2, -(i - 1) * 20 - 2)
        if i == 1 then
            row:SetVertexColor(Color(style.active, { S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18 }))
        else
            row:SetVertexColor(Color(i % 2 == 0 and style.rowAlt or style.row, { 0.03, 0.035, 0.05, 0.4 }))
        end
    end
    local kinds = style.kinds or {}
    local defaults = { ["in"] = { 1, 0.5, 1 }, out = { 0.85, 0.65, 1 }, sys = { 1, 0.85, 0.3 } }
    for i, line in ipairs(win.lines) do
        local data = MOCK_LINES[i]
        local c = kinds[data[1]] or defaults[data[1]]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", win.side, "TOPRIGHT", 8, -(i - 1) * 26 - 4)
        line:SetText(data[2])
        line:SetTextColor(c[1], c[2], c[3])
    end
    win.input:ClearAllPoints()
    win.input:SetPoint("BOTTOMLEFT", win.side, "BOTTOMRIGHT", 8, 0)
    win.input:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -pad, pad)
    win.input:SetVertexColor(Color(style.input, { 0.02, 0.02, 0.04, 0.9 }))
end

function P.Dialogue(view, key)
    local S = NS.Styling
    local D = NS.Dialogue
    local ddb = NS.db and NS.db.dialogue or {}
    local style = D and D.STYLES and D.STYLES[key or ddb.style or "narci"] or {}
    if not view.built then
        view.built = true
        World(view)
        local card = Centered(view, 290, 140)
        card:ClearAllPoints()
        card:SetPoint("TOP", view, "TOP", 0, -8)
        card.skin = MockSkin(card)
        local content = CreateFrame("Frame", nil, card)
        content:SetAllPoints(card)
        content:SetFrameLevel(card:GetFrameLevel() + 3)
        card.name = Font(content, 15, "")
        card.name:SetShadowOffset(1, -1)
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
        card.name:SetText(L["Архимаг Аэлин"])
        card.rule = Fill(content, "ARTWORK")
        card.rule:SetHeight(1)
        card.rule:SetWidth(180)
        card.rule:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
        card.title = Font(content, 11, "")
        card.title:SetPoint("TOPLEFT", card.rule, "BOTTOMLEFT", 0, -5)
        card.title:SetText(L["Тайны Даларана"])
        card.body = Font(content, 10, "")
        card.body:SetShadowOffset(1, -1)
        card.body:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -6)
        card.body:SetWidth(260)
        card.body:SetText(L["Странник, в библиотеке пропали древние свитки. Найди их, пока они не попали в чужие руки."])
        view.card = card
        view.options = {}
        for i = 1, 2 do
            local button = CreateFrame("Frame", nil, view)
            button:SetSize(260, 22)
            button:SetPoint("TOP", card, "BOTTOM", 0, -10 - (i - 1) * 26)
            button.ground = button:CreateTexture(nil, "BACKGROUND")
            button.ground:SetAllPoints(button)
            button.ground:SetTexture(WHITE)
            button.key = Font(button, 10, "")
            button.key:SetPoint("LEFT", button, "LEFT", 8, 0)
            button.key:SetText(i)
            local text = Font(button, 10, "")
            text:SetPoint("LEFT", button, "LEFT", 24, 0)
            text:SetText(i == 1 and L["Я найду свитки."] or L["Прощай."])
            view.options[i] = button
        end
    end
    local card = view.card
    local c = style.card
    local alpha = ((NS.db and NS.db.dialogue and NS.db.dialogue.cardAlpha) or 92) / 100
    if c then
        PaintSkin(card.skin, {
            bg = c.bg and { c.bg[1], c.bg[2], c.bg[3], alpha }, art = c.scene and S.SCENE_ART[c.scene],
            box = c.box, tint = c.tint, mark = c.mark, seal = c.seal, sealPoint = "TOPRIGHT",
        })
        card.skin:Show()
    else
        card.skin:Hide()
    end
    local name = style.name or S.ACCENT_GLOW
    card.name:SetTextColor(name[1], name[2], name[3])
    local rule = style.rule or S.ACCENT_GLOW
    card.rule:SetGradientAlpha("HORIZONTAL", rule[1], rule[2], rule[3], 0.9, rule[1], rule[2], rule[3], 0)
    local title = style.title or S.GOLD
    card.title:SetTextColor(title[1], title[2], title[3])
    local textColors = { white = { 0.94, 0.93, 0.90 }, parchment = { 0.96, 0.88, 0.70 }, silver = { 0.80, 0.84, 0.90 } }
    local tc = ddb.textColor == "theme" and S.ACCENT_GLOW or textColors[ddb.textColor or "white"] or textColors.white
    card.body:SetTextColor(tc[1], tc[2], tc[3])
    for _, button in ipairs(view.options) do
        if style.option then
            button.ground:Hide()
            S.SkinBox(button, style.option, { alpha = 0.88, tint = style.optionTint })
        else
            button.ground:Show()
            button.ground:SetGradientAlpha("HORIZONTAL", 0.030, 0.034, 0.048, 0.92, 0.016, 0.018, 0.026, 0.55)
            S.SkinBox(button, "none")
        end
        button.key:SetTextColor(rule[1], rule[2], rule[3])
    end
end

function P.AFK(view, key)
    local S = NS.Styling
    local A = NS.AFKScreen
    local adb = NS.db and NS.db.afk or {}
    local style = A and A.PANEL_STYLES and A.PANEL_STYLES[key or adb.panelStyle or "narci"] or {}
    if not view.built then
        view.built = true
        World(view)
        local strip = CreateFrame("Frame", nil, view)
        strip:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 10)
        strip:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 10)
        strip:SetHeight(80)
        strip.skin = MockSkin(strip)
        strip.ground = Fill(strip, "BACKGROUND")
        strip.ground:SetAllPoints(strip)
        strip.line = Fill(strip, "OVERLAY")
        strip.line:SetHeight(2)
        strip.line:SetPoint("TOPLEFT", strip, "TOPLEFT", 0, 0)
        strip.line:SetPoint("TOPRIGHT", strip, "TOPRIGHT", 0, 0)
        local logo = CreateFrame("Frame", nil, strip)
        logo:SetAllPoints(strip)
        logo:SetFrameLevel(strip:GetFrameLevel() + 5)
        strip.emblem = logo:CreateTexture(nil, "OVERLAY")
        strip.emblem:SetSize(56, 56)
        strip.emblem:SetPoint("CENTER", strip, "TOP", 0, 6)
        strip.away = Font(logo, 12, "OUTLINE")
        strip.away:SetPoint("BOTTOM", strip, "BOTTOM", 0, 22)
        strip.away:SetText(L["Вы отошли"])
        strip.timer = Font(logo, 10, "")
        strip.timer:SetPoint("BOTTOM", strip, "BOTTOM", 0, 8)
        strip.timer:SetText("04:12")
        view.strip = strip
    end
    local strip = view.strip
    local alpha = (adb.panelAlpha or 96) / 100
    local r, g, b = Accent()
    local tint = adb.tint or "accent"
    if tint == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS[class]
        if c then r, g, b = c.r, c.g, c.b end
    elseif tint == "gold" then
        r, g, b = 1, 0.80, 0.32
    elseif tint == "silver" then
        r, g, b = 0.80, 0.84, 0.90
    elseif tint == "brand" and S.BrandColor then
        local _, _, _, br, bg, bb = S.BrandColor()
        r, g, b = br, bg, bb
    end
    local layout = adb.layout or "bottom"
    strip:ClearAllPoints()
    if layout == "top" then
        strip:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -10)
        strip:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -10)
    else
        strip:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 10)
        strip:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 10)
    end
    strip.emblem:ClearAllPoints()
    if layout == "minimal" then
        strip.emblem:SetPoint("CENTER", view, "CENTER", 0, 20)
    elseif layout == "top" then
        strip.emblem:SetPoint("CENTER", strip, "BOTTOM", 0, -6)
    else
        strip.emblem:SetPoint("CENTER", strip, "TOP", 0, 6)
    end
    strip.line:SetVertexColor(r, g, b, 0.9)
    strip.emblem:SetTexture(S.Media("LogoEmblem"))
    strip.emblem:SetVertexColor(r, g, b, 1)
    strip.timer:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    strip.line:SetShown(layout ~= "minimal")
    if layout == "minimal" then
        strip.ground:Hide()
        strip.skin:Hide()
    elseif style.box or style.scene or style.mark then
        strip.ground:Hide()
        PaintSkin(strip.skin, {
            bg = style.bg and { style.bg[1], style.bg[2], style.bg[3], alpha }, art = style.scene and S.SCENE_ART[style.scene],
            box = style.box, mark = style.mark and true, markAlpha = 0.35,
        })
        strip.skin:Show()
    else
        strip.skin:Hide()
        strip.ground:Show()
        local c = style.bg or S.BG_DARK
        strip.ground:SetGradientAlpha("VERTICAL", c[1], c[2], c[3], alpha, c[1] + 0.03, c[2] + 0.03, c[3] + 0.04, alpha * 0.94)
    end
end

function P.Window(view, key)
    local S = NS.Styling
    local Mv = NS.Movers
    local style = Mv and Mv.WINDOW_STYLES and Mv.WINDOW_STYLES[key]
    if key == "all" and Mv then
        local db = Mv:WindowPrefs()
        style = Mv.WINDOW_STYLES[db.style or "theme"]
    end
    if not view.built then
        view.built = true
        World(view)
        local win = Centered(view, 290, 196)
        win.skin = MockSkin(win)
        local content = CreateFrame("Frame", nil, win)
        content:SetAllPoints(win)
        content:SetFrameLevel(win:GetFrameLevel() + 3)
        local title = Font(content, 13, "OUTLINE")
        title:SetPoint("TOP", win, "TOP", 0, -10)
        title:SetText(L["Гильдия"])
        win.titleText = title
        local names = { "Аэлин", "Торвальд", "Шейд", "Мирра", "Каэль" }
        for i, name in ipairs(names) do
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(262, 24)
            row:SetPoint("TOP", win, "TOP", 0, -34 - (i - 1) * 30)
            local ground = Fill(row, "BACKGROUND", 0.03, 0.035, 0.05, 0.62)
            ground:SetAllPoints(row)
            local text = Font(row, 10, "")
            text:SetPoint("LEFT", row, "LEFT", 8, 0)
            text:SetText(name)
            local level = Font(row, 10, "")
            level:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            level:SetText("80")
            level:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
        view.win = win
    end
    local win = view.win
    win.titleText:SetTextColor(Accent())
    if not style then
        PaintSkin(win.skin, { native = true })
    else
        local shade = 0.35
        PaintSkin(win.skin, {
            bg = style.bg, art = style.scene and S.SCENE_ART[style.scene], shade = shade,
            box = style.box, tint = style.tint, mark = style.mark,
        })
    end
end

function P.MicroIcons(view, key)
    local S = NS.Styling
    local AB = NS.ActionBars
    if not view.built then
        view.built = true
        World(view)
        local holder = Centered(view, 6 * 40, 2 * 40)
        view.cells = {}
        for i = 1, 12 do
            local cell = CreateFrame("Frame", nil, holder)
            cell:SetSize(36, 36)
            cell:SetPoint("TOPLEFT", holder, "TOPLEFT", ((i - 1) % 6) * 40, -math.floor((i - 1) / 6) * 40)
            local ground = Fill(cell, "BACKGROUND", 0.02, 0.022, 0.03, 0.92)
            ground:SetAllPoints(cell)
            S.CreateEdges(cell, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
            cell.icon = cell:CreateTexture(nil, "ARTWORK")
            cell.icon:SetPoint("TOPLEFT", cell, "TOPLEFT", 4, -4)
            cell.icon:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -4, 4)
            view.cells[i] = cell
        end
    end
    for i, cell in ipairs(view.cells) do
        local name = AB and AB.MICRO_ORDER and AB.MICRO_ORDER[i]
        local path, full = nil, false
        if name and AB.MicroIconPath then path, full = AB:MicroIconPath(key, name) end
        cell.icon:SetTexture(path)
        if full then
            cell.icon:SetVertexColor(1, 1, 1, 1)
        else
            cell.icon:SetVertexColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3], 0.95)
        end
    end
end

function P.Nameplate(view, key)
    local plates = NS.Nameplates
    if not plates or not plates.CreatePreview then return end
    if not view.built then
        view.built = true
        World(view)
        local keep = plates.preview
        local holder = plates:CreatePreview(view)
        holder:SetPoint("CENTER", view, "CENTER", 0, 0)
        holder:SetScale(1.15)
        view.plate = plates.preview
        plates.preview = keep
    end
    local db = plates.Settings and plates.Settings()
    if not db or not view.plate then return end
    local old = db.style
    db.style = key
    pcall(plates.ApplyStyle, plates, view.plate)
    pcall(plates.UpdateAll, plates, view.plate)
    db.style = old
end

local function Resolve(path)
    local node = NS.db
    if type(path) == "function" then return path() end
    for part in string.gmatch(path or "", "[^%.]+") do
        if type(node) ~= "table" then return end
        node = node[part]
    end
    return node
end

function P.Sample(module, path, field, opts)
    opts = opts or {}
    return function(view, key)
        local M = NS[module]
        if not M or not M.CreateSample or not M.PaintSample then return end
        if not view.built then
            view.built = true
            if not opts.noWorld and not view.world then view.world = World(view) end
            local made, sample = pcall(M.CreateSample, M, view, opts)
            if not made then view.failed = tostring(sample) end
            if made and not sample then view.built = nil end
            if made and sample then
                sample:ClearAllPoints()
                sample:SetPoint(opts.point or "CENTER", view, opts.point or "CENTER", opts.x or 0, opts.y or 0)
                view.sample = sample
            end
        end
        if view.failed then return P:Fail(view.failed) end
        if not view.sample then return end
        local db = Resolve(path)
        local old
        local swap = field and type(db) == "table"
        if swap then
            old = db[field]
            db[field] = key
        end
        local ok, err = pcall(M.PaintSample, M, view.sample, opts)
        if swap then db[field] = old end
        if not ok then P:Fail(err) end
    end
end

function P.With(path, field, base)
    return function(view, key)
        local db = Resolve(path)
        if type(db) ~= "table" then return base(view) end
        local old = db[field]
        db[field] = key
        local ok, err = pcall(base, view)
        db[field] = old
        if not ok then P:Fail(err) end
    end
end

local function ThemeWindow(view, radius)
    local S = NS.Styling
    view.themeWins = view.themeWins or {}
    local win = view.themeWins[radius]
    if win then return win end
    win = CreateFrame("Frame", nil, view)
    win:SetSize(270, 170)
    win:SetPoint("CENTER", view, "CENTER", 0, 0)
    local backdrop = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
    win:SetBackdrop(backdrop)
    if radius > 0 then
        local keep = S.CORNER_RADIUS
        S.CORNER_RADIUS = radius
        S.RoundCorners(win, radius, backdrop)
        S.CORNER_RADIUS = keep
    end
    win.shadow = S.CreateHalo(win, 14 + radius, 0, 0, 0, 0.5, nil, nil, radius)
    win.title = Font(win, 13, "OUTLINE")
    win.title:SetPoint("TOP", win, "TOP", 0, -12)
    win.title:SetText(L["Персонаж"])
    win.line = Fill(win, "ARTWORK")
    win.line:SetHeight(2)
    win.line:SetPoint("TOPLEFT", win, "TOPLEFT", math.max(4, radius), -3)
    win.line:SetPoint("TOPRIGHT", win, "TOPRIGHT", -math.max(4, radius), -3)
    win.rows = {}
    for i = 1, 3 do
        local row = CreateFrame("Frame", nil, win)
        row:SetSize(240, 26)
        row:SetPoint("TOP", win, "TOP", 0, -36 - (i - 1) * 32)
        row.ground = Fill(row, "BACKGROUND")
        row.ground:SetAllPoints(row)
        row.name = Font(row, 11, "")
        row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.name:SetText(({ L["Сила"], L["Ловкость"], L["Выносливость"] })[i])
        row.value = Font(row, 11, "")
        row.value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.value:SetText(({ "1 204", "342", "2 610" })[i])
        win.rows[i] = row
    end
    win.hint = Font(win, 10, "")
    win.hint:SetPoint("BOTTOM", win, "BOTTOM", 0, 10)
    win.hint:SetText(L["Подсказка внизу окна"])
    view.themeWins[radius] = win
    return win
end

function P.Theme(view)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
    end
    local palette = S.ThemePalette and S.ThemePalette(NS.db and NS.db.theme or {})
    if not palette then return end
    for _, other in pairs(view.themeWins or {}) do other:Hide() end
    local win = ThemeWindow(view, palette.radius)
    win:Show()
    local bg = palette.bg
    win:SetBackdropColor(bg[1], bg[2], bg[3], 0.95 * palette.density)
    win:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], palette.border[4])
    win.shadow:SetAlpha(math.min(1, palette.shadow))
    win.shadow:SetShown(palette.shadow > 0)
    local A, G = S.ACCENT, S.ACCENT_GLOW
    win.title:SetTextColor(G[1], G[2], G[3])
    win.line:SetVertexColor(A[1], A[2], A[3], 0.9)
    for index, row in ipairs(win.rows) do
        local slot = palette.slot
        row.ground:SetVertexColor(slot[1], slot[2], slot[3], index % 2 == 0 and 0.9 * palette.density or 0.5 * palette.density)
        row.name:SetTextColor(palette.normal[1], palette.normal[2], palette.normal[3])
        row.value:SetTextColor(palette.bright[1], palette.bright[2], palette.bright[3])
    end
    win.hint:SetTextColor(palette.dim[1], palette.dim[2], palette.dim[3])
end

function P.FontSample(view, key)
    if not view.built then
        view.built = true
        World(view)
        view.lines = {}
        for index, size in ipairs({ 22, 15, 12 }) do
            local line = view:CreateFontString(nil, "OVERLAY")
            line:SetPoint("TOP", view, "TOP", 0, -24 - (index - 1) * 42)
            view.lines[index] = { line, size }
        end
    end
    local path = NS.FONT
    for _, option in ipairs(NS.FontOptions and NS.FontOptions() or {}) do
        if option.key == key then path = option.path end
    end
    local texts = { "NarciUI", L["Персонаж 80 уровня, Даларан"], L["Подсказки, кнопки и списки в этом шрифте"] }
    local S = NS.Styling
    for index, entry in ipairs(view.lines) do
        entry[1]:SetFont(path, entry[2], index == 1 and "OUTLINE" or "")
        entry[1]:SetText(texts[index])
        if index == 1 then
            entry[1]:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            entry[1]:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end
end

function P.LookBar(field, element)
    return function(view, key)
        local S = NS.Styling
        local Look = NS.Look
        if not view.built then
            view.built = true
            World(view)
            view.bars = {}
            local colors = { { 0.2, 0.8, 0.3 }, { 0.25, 0.45, 0.95 }, { 0.85, 0.3, 0.25 } }
            for index = 1, 3 do
                local holder = CreateFrame("Frame", nil, view)
                holder:SetSize(260, 22)
                holder:SetPoint("TOP", view, "TOP", 0, -30 - (index - 1) * 50)
                local ground = Fill(holder, "BACKGROUND", 0.02, 0.022, 0.03, 0.92)
                ground:SetAllPoints(holder)
                S.CreateEdges(holder, "BORDER", 0, 0, 0, 1)
                local bar = CreateFrame("StatusBar", nil, holder)
                bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
                bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(({ 0.86, 0.6, 0.35 })[index])
                bar.color = colors[index]
                local text = bar:CreateFontString(nil, "OVERLAY")
                text:SetPoint("LEFT", bar, "LEFT", 6, 0)
                text:SetFont(NS.FONT, 11, "OUTLINE")
                text:SetText(({ L["Здоровье 24 310 / 28 200"], L["Мана 9 120"], L["Ярость 35"] })[index])
                bar.text = text
                view.bars[index] = bar
            end
        end
        local db = NS.db and NS.db.elementLook or {}
        local own = element and db.elements and db.elements[element] or {}
        local function Pick(name)
            if field == name then return key end
            local value = own[name]
            if value == nil or value == "default" then value = db[name] end
            return value
        end
        local texture = WHITE
        for _, entry in ipairs(Look and Look.TEXTURES or {}) do
            if entry.key == Pick("texture") and entry.path then texture = NS.Styling.Media(entry.path) end
        end
        local font = NS.FONT
        for _, option in ipairs(NS.FontOptions and NS.FontOptions() or {}) do
            if option.key == Pick("font") then font = option.path end
        end
        local flags = "OUTLINE"
        for _, entry in ipairs(Look and Look.OUTLINES or {}) do
            if entry.key == Pick("outline") and entry.flags then flags = entry.flags end
        end
        for _, bar in ipairs(view.bars) do
            bar:SetStatusBarTexture(texture)
            bar:SetStatusBarColor(bar.color[1], bar.color[2], bar.color[3])
            bar.text:SetFont(font, 11, flags)
            bar.text:SetTextColor(1, 1, 1)
        end
    end
end

local function PoseModel(view, size)
    local model = CreateFrame("PlayerModel", nil, view)
    model:SetSize(size, size * 1.4)
    model:SetScript("OnUpdate", function(self, elapsed)
        if not self.anim then return end
        self.time = (self.time or 0) + elapsed * 1000
        if self.SetSequenceTime then pcall(self.SetSequenceTime, self, self.anim, self.time) end
    end)
    return model
end

local function SetPose(model, key)
    local anims = NS.NarciUI and NS.NarciUI.POSE_ANIMS or {}
    if key == "random" then key = "dance" end
    model.anim = anims[key]
    model.time = 0
    if not model.anim or model.anim == 0 then
        model.anim = nil
        pcall(model.SetSequence, model, 0)
    end
end

function P.Pose(path, field)
    return function(view, key)
        if not view.built then
            view.built = true
            World(view)
            view.model = PoseModel(view, 150)
            view.model:SetPoint("BOTTOM", view, "BOTTOM", 0, 6)
        end
        local model = view.model
        model:ClearModel()
        if key == "none" then
            model:Hide()
            return
        end
        model:Show()
        if key == "lichking" then
            model:SetModel("Creature\\ArthasLichKing\\ArthasLichKing.m2")
            model.anim = nil
        else
            model:SetUnit("player")
            if key == "player" then model.anim = nil else SetPose(model, key) end
        end
        pcall(model.SetFacing, model, -0.3)
    end
end

local SCENE_SLOTS = { { 1, -1, 1 }, { 5, -1, 0 }, { 16, 1, 1 }, { 10, 1, 0 } }

function P.Scene(view)
    local S = NS.Styling
    local UI = NS.NarciUI
    if not UI then return end
    local db = NS.db or {}
    if not view.built then
        view.built = true
        view.back = view:CreateTexture(nil, "BACKGROUND")
        view.back:SetAllPoints(view)
        view.back:SetTexture(WHITE)
        view.world = World(view)
        view.light = view:CreateTexture(nil, "BORDER")
        view.light:SetPoint("CENTER", view, "CENTER", 0, 10)
        view.light:SetBlendMode("ADD")
        view.floor = view:CreateTexture(nil, "ARTWORK")
        view.floor:SetPoint("CENTER", view, "BOTTOM", 0, 26)
        view.floor:SetBlendMode("ADD")
        view.model = PoseModel(view, 120)
        view.model:SetPoint("BOTTOM", view, "BOTTOM", 0, 8)
        view.model:SetFrameLevel(view:GetFrameLevel() + 2)
        view.slots = {}
        for index, data in ipairs(SCENE_SLOTS) do
            local slot = CreateFrame("Frame", nil, view)
            slot:SetSize(34, 34)
            slot:SetPoint("CENTER", view, "CENTER", data[2] * 112, data[3] == 1 and 40 or -20)
            slot:SetFrameLevel(view:GetFrameLevel() + 4)
            slot.fill = slot:CreateTexture(nil, "BACKGROUND")
            slot.fill:SetPoint("CENTER")
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetPoint("CENTER")
            slot.ring = slot:CreateTexture(nil, "OVERLAY")
            slot.ring:SetPoint("CENTER")
            slot.edges = S.CreateEdges(slot, "OVERLAY", 1, 1, 1, 1)
            slot.id = data[1]
            view.slots[index] = slot
        end
    end
    local kind = db.sceneBackdrop or "none"
    local backdrops = UI.SCENE_BACKDROPS or {}
    local c = backdrops[kind]
    if kind == "accent" or kind == "class" then
        local cr, cg, cb = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
        if kind == "class" then
            local _, class = UnitClass("player")
            local cc = class and RAID_CLASS_COLORS[class]
            if cc then cr, cg, cb = cc.r, cc.g, cc.b end
        end
        c = { cr * 0.32, cg * 0.32, cb * 0.32, cr * 0.03, cg * 0.03, cb * 0.03 }
    end
    if c then
        view.back:SetGradientAlpha("VERTICAL", c[4], c[5], c[6], 1, c[1], c[2], c[3], 1)
        view.back:Show()
        view.world:Hide()
    else
        view.back:Hide()
        view.world:Show()
    end
    local r, g, b = UI:BacklightColor()
    local styles = UI.BACKLIGHT_STYLES or {}
    local light = styles[db.backlightStyle or "glow"] or styles.glow or {}
    view.light:SetTexture(light.path and S.Media(light.path) or S.GLOW)
    view.light:SetSize(210, 230)
    view.light:SetVertexColor(r, g, b, math.min(1, (light.alpha or 0.2) * 2.2 * (db.backlightPower or 100) / 100))
    local floors = UI.FLOORS or {}
    local floor = floors[db.modelFloor or "none"]
    if floor then
        view.floor:SetTexture(floor.path and S.Media(floor.path) or S.GLOW)
        if floor.path then view.floor:SetSize(150, 50) else view.floor:SetSize(150, 40) end
        view.floor:SetVertexColor(r, g, b, floor.alpha or 0.4)
        view.floor:Show()
    else
        view.floor:Hide()
    end
    local model = view.model
    model:ClearModel()
    model:SetUnit("player")
    pcall(model.SetFacing, model, 0)
    SetPose(model, db.modelPose or "stand")
    local shapes = UI.SHAPE_ART or {}
    local shapeKey = db.slotShape or "square"
    local art = shapes[shapeKey]
    for _, slot in ipairs(view.slots) do
        local path = GetInventoryItemTexture("player", slot.id)
        local quality = GetInventoryItemQuality and GetInventoryItemQuality("player", slot.id)
        local qr, qg, qb = 0.6, 0.6, 0.6
        if quality and GetItemQualityColor then qr, qg, qb = GetItemQualityColor(quality) end
        if db.slotRingColor == "accent" then qr, qg, qb = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3] end
        local scale = 34 / 58
        if art then
            for _, line in ipairs(slot.edges) do line:Hide() end
            slot.fill:SetTexture(S.Media(art.fill))
            slot.fill:SetSize(art.size * scale, art.size * scale)
            slot.fill:SetVertexColor(0.03, 0.03, 0.04, 0.95)
            slot.fill:Show()
            slot.ring:SetTexture(S.Media(art.ring))
            local ring = (art.ringSize or art.size) * scale
            slot.ring:SetSize(ring, ring)
            slot.ring:SetVertexColor(qr, qg, qb, 1)
            slot.ring:Show()
            slot.icon:SetSize(art.icon * scale, art.icon * scale)
            if path and (shapeKey == "circle" or shapeKey == "hex") and SetPortraitToTexture then
                SetPortraitToTexture(slot.icon, path)
                slot.icon:SetTexCoord(0, 1, 0, 1)
            else
                slot.icon:SetTexture(path)
                slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
        elseif shapeKey == "classic" then
            for _, line in ipairs(slot.edges) do line:Hide() end
            slot.fill:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            slot.fill:SetSize(58, 58)
            slot.fill:SetVertexColor(1, 1, 1, 1)
            slot.fill:Show()
            slot.ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            slot.ring:SetBlendMode("ADD")
            slot.ring:SetSize(62, 62)
            slot.ring:SetVertexColor(qr, qg, qb, 0.9)
            slot.ring:Show()
            slot.icon:SetSize(32, 32)
            slot.icon:SetTexture(path)
            slot.icon:SetTexCoord(0, 1, 0, 1)
        else
            slot.fill:SetTexture(WHITE)
            slot.fill:SetSize(34, 34)
            slot.fill:SetVertexColor(0.03, 0.03, 0.04, 0.95)
            slot.fill:Show()
            slot.ring:Hide()
            slot.icon:SetSize(32, 32)
            slot.icon:SetTexture(path)
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            for _, line in ipairs(slot.edges) do
                line:SetVertexColor(qr, qg, qb, 1)
                line:Show()
            end
        end
    end
end

function P.Brand(view)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
        view.glow = view:CreateTexture(nil, "BORDER")
        view.glow:SetSize(150, 150)
        view.glow:SetPoint("CENTER", view, "CENTER", 0, 30)
        view.glow:SetBlendMode("ADD")
        view.emblem = view:CreateTexture(nil, "ARTWORK")
        view.emblem:SetSize(110, 110)
        view.emblem:SetPoint("CENTER", view, "CENTER", 0, 30)
        view.word = view:CreateTexture(nil, "ARTWORK")
        view.word:SetSize(200, 50)
        view.word:SetPoint("TOP", view.emblem, "BOTTOM", 0, -4)
        view.wordText = view:CreateFontString(nil, "OVERLAY")
        view.wordText:SetPoint("TOP", view.emblem, "BOTTOM", 0, -10)
    end
    if S.PaintEmblem then S.PaintEmblem(view.emblem, view.glow, 0.45) end
    if S.PaintWordmark then S.PaintWordmark(view.word, view.wordText) end
end

local FOG_PREVIEW = {
    grey = { 0.62, 0.62, 0.70 }, bright = { 1, 1, 1 }, dark = { 0.30, 0.30, 0.36 }, sepia = { 0.80, 0.66, 0.46 },
}

function P.Fog(view, key)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
        view.map = view:CreateTexture(nil, "ARTWORK")
        view.map:SetSize(260, 180)
        view.map:SetPoint("CENTER")
        view.map:SetTexture(S.Media("SampleMap"))
        view.patches = {}
        for index, rect in ipairs({ { -80, 40, 110, 90 }, { 70, -50, 120, 70 } }) do
            local patch = view:CreateTexture(nil, "OVERLAY")
            patch:SetSize(rect[3], rect[4])
            patch:SetPoint("CENTER", view, "CENTER", rect[1], rect[2])
            patch:SetTexture(S.Media("SampleMap"))
            patch:SetTexCoord(index * 0.3, index * 0.3 + 0.4, 0.2, 0.55)
            patch:SetDesaturated(true)
            view.patches[index] = patch
        end
    end
    local db = NS.questDB or {}
    key = key or db.fogColor or "grey"
    local c = key == "theme" and S.ACCENT or FOG_PREVIEW[key] or FOG_PREVIEW.grey
    for _, patch in ipairs(view.patches) do patch:SetVertexColor(c[1], c[2], c[3], (db.fogAlpha or 85) / 100) end
end

function P.Light(view, key)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
        view.light = view:CreateTexture(nil, "BORDER")
        view.light:SetTexture(S.GLOW)
        view.light:SetBlendMode("ADD")
        view.light:SetSize(220, 240)
        view.light:SetPoint("CENTER", view, "CENTER", 0, 10)
        view.model = PoseModel(view, 120)
        view.model:SetPoint("BOTTOM", view, "BOTTOM", 0, 8)
    end
    view.model:ClearModel()
    view.model:SetUnit("player")
    if key == "off" then
        view.light:Hide()
        return
    end
    local r, g, b = 0.34, 0.44, 0.62
    if key == "theme" then
        r, g, b = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
    elseif key == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS[class]
        if c then r, g, b = c.r, c.g, c.b end
    end
    local db = NS.db and NS.db.inspect or {}
    view.light:SetVertexColor(r, g, b, math.min(1, (db.lightPower or 20) / 100 * 2.5))
    view.light:Show()
end

function P.Highlight(view, key)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
        view.lines = {}
        for index = 1, 3 do
            local line = Font(view, 12, "")
            line:SetPoint("TOPLEFT", view, "TOPLEFT", 14, -30 - (index - 1) * 26)
            view.lines[index] = line
        end
    end
    local c = S.ACCENT_GLOW
    if key == "gold" then c = S.GOLD elseif key == "red" then c = { 1, 0.35, 0.35 } elseif key == "white" then c = { 1, 1, 1 } end
    local hex = string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
    view.lines[1]:SetText("|cff40ff40[" .. L["Гильдия"] .. "] [Торвальд]:|r " .. L["кто идёт в"] .. " " .. hex .. "ЦЛК|r?")
    view.lines[2]:SetText("|cffff80ff[Аэлин] " .. L["шепчет"] .. ":|r " .. L["нужен"] .. " " .. hex .. L["хил"] .. "|r " .. L["на героик"])
    view.lines[3]:SetText("|cffaaaaff[" .. L["Группа"] .. "] [Шейд]:|r " .. L["готов"])
end

local ESC_ITEMS = { "Продолжить", "Настройки", "Аддоны", "Макросы", "Выход из игры" }

function P.EscMenu(view, key)
    local S = NS.Styling
    if not view.built then
        view.built = true
        World(view)
        local panel = CreateFrame("Frame", nil, view)
        panel:SetSize(150, 170)
        panel:SetPoint("CENTER")
        panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        S.CreateShadow(panel, 5, 0.4)
        S.CreateGradientTopBorder(panel)
        panel.buttons = {}
        for index, label in ipairs(ESC_ITEMS) do
            local button = NS.Widgets.CreateThemedButton(panel, L[label], 126, 22, function() end)
            button:SetPoint("TOP", panel, "TOP", 0, -14 - (index - 1) * 30)
            button:EnableMouse(false)
        end
        view.panel = panel

        local scene = CreateFrame("Frame", nil, view)
        scene:SetAllPoints(view)
        local dim = Fill(scene, "BACKGROUND", 0, 0, 0, 0.82)
        dim:SetAllPoints(scene)
        scene.model = PoseModel(scene, 130)
        scene.model:SetPoint("BOTTOMRIGHT", scene, "BOTTOMRIGHT", 0, 0)
        scene.logo = scene:CreateTexture(nil, "ARTWORK")
        scene.logo:SetSize(46, 46)
        scene.logo:SetPoint("TOPLEFT", scene, "TOPLEFT", 16, -10)
        scene.items = {}
        for index, label in ipairs(ESC_ITEMS) do
            local text = Font(scene, 13, "OUTLINE")
            text:SetPoint("TOPLEFT", scene, "TOPLEFT", 20, -64 - (index - 1) * 24)
            text:SetText(L[label])
            scene.items[index] = text
        end
        view.scene = scene
    end
    local db = NS.db or {}
    key = key or (db.gameMenuStyle == "cinematic" and "cinematic" or "panel")
    if key == "cinematic" then
        view.panel:Hide()
        local scene = view.scene
        scene:Show()
        local kind = db.escModel or "lichking"
        scene.model:ClearModel()
        if kind == "none" then
            scene.model:Hide()
        else
            scene.model:Show()
            if kind == "player" then
                scene.model:SetUnit("player")
            else
                scene.model:SetModel("Creature\\ArthasLichKing\\ArthasLichKing.m2")
            end
            pcall(scene.model.SetFacing, scene.model, -0.35)
        end
        scene.logo:SetShown(db.escLogo ~= false)
        if S.PaintEmblem then S.PaintEmblem(scene.logo) end
        for index, text in ipairs(scene.items) do
            if index == 1 then
                text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            else
                text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            end
        end
    else
        view.scene:Hide()
        view.panel:Show()
        view.panel:SetBackdropColor(S.Bg(0.95))
        view.panel:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
end

function P.Accent(view, key)
    local S = NS.Styling
    local preset
    for _, entry in ipairs(S.ACCENT_PRESETS or {}) do
        if entry.key == key then preset = entry end
    end
    if not preset then return P.Theme(view) end
    local keep = {
        { S.ACCENT[1], S.ACCENT[2], S.ACCENT[3] },
        { S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3] },
        { S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3] },
    }
    for i = 1, 3 do
        S.ACCENT[i], S.ACCENT_DIM[i], S.ACCENT_GLOW[i] = preset.base[i], preset.dim[i], preset.glow[i]
    end
    local ok, err = pcall(P.Theme, view)
    for i = 1, 3 do
        S.ACCENT[i], S.ACCENT_DIM[i], S.ACCENT_GLOW[i] = keep[1][i], keep[2][i], keep[3][i]
    end
    if not ok then P:Fail(err) end
end

function P.Overlay(data, fn, ...)
    local undo = {}
    local function Walk(from, into)
        for key, value in pairs(from) do
            if type(value) == "table" then
                if type(into[key]) ~= "table" then
                    undo[#undo + 1] = { into, key, into[key] }
                    into[key] = {}
                end
                Walk(value, into[key])
            else
                undo[#undo + 1] = { into, key, into[key] }
                into[key] = value
            end
        end
    end
    if NS.db and type(data) == "table" then Walk(data, NS.db) end
    local ok, err = pcall(fn, ...)
    for index = #undo, 1, -1 do
        local entry = undo[index]
        entry[1][entry[2]] = entry[3]
    end
    if not ok then P:Fail(err) end
end

local PRESET_PARTS = {
    { module = "PlayerUI",   share = 0.42 },
    { module = "CastBar",    share = 0.20 },
    { module = "ActionBars", share = 0.38 },
}

function P.LookPreset(view, key)
    if not view.built then
        view.built = true
        World(view)
        view.parts = {}
        local width, height = view:GetWidth(), view:GetHeight()
        if not width or width < 50 then width, height = W - 20, H - 56 end
        local y = 0
        for _, part in ipairs(PRESET_PARTS) do
            local slot = CreateFrame("Frame", nil, view)
            slot:SetSize(width, height * part.share)
            slot:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -y)
            y = y + height * part.share
            local M = NS[part.module]
            if M and M.CreateSample and M.PaintSample then
                local ok, sample = pcall(M.CreateSample, M, slot, {})
                if not ok then
                    P:Fail(sample)
                elseif sample then
                    sample:ClearAllPoints()
                    sample:SetPoint("CENTER", slot, "CENTER", 0, 0)
                    local w, h = sample:GetWidth() or 1, sample:GetHeight() or 1
                    local scale = math.min(1, (width - 12) / math.max(w, 1), (height * part.share - 6) / math.max(h, 1))
                    if scale > 0 then sample:SetScale(scale) end
                    view.parts[#view.parts + 1] = { module = M, sample = sample }
                end
            end
        end
    end
    local data = key and NS.Look and NS.Look.PresetTable and NS.Look:PresetTable(key) or {}
    P.Overlay(data, function()
        for _, part in ipairs(view.parts) do
            local ok, err = pcall(part.module.PaintSample, part.module, part.sample, {})
            if not ok then P:Fail(err) end
        end
    end)
end

function P.WithAccent(key, fn, ...)
    local S = NS.Styling
    local keep = {}
    for _, tbl in ipairs({ S.ACCENT, S.ACCENT_DIM, S.ACCENT_GLOW }) do
        keep[#keep + 1] = { tbl[1], tbl[2], tbl[3] }
    end
    if key and S.ApplyAccent then pcall(S.ApplyAccent, key) end
    local ok, err = pcall(fn, ...)
    for index, tbl in ipairs({ S.ACCENT, S.ACCENT_DIM, S.ACCENT_GLOW }) do
        tbl[1], tbl[2], tbl[3] = keep[index][1], keep[index][2], keep[index][3]
    end
    if not ok then P:Fail(err) end
end

local function DecorWindow(view, styled)
    local S = NS.Styling
    local keep = S.DECOR
    S.DECOR = styled
    local win = CreateFrame("Frame", nil, view)
    win:SetSize(280, 180)
    win:SetPoint("CENTER", view, "CENTER", 0, 0)
    local ok, err = pcall(function()
        S.ApplyPanelStyle(win, 280, 180)
        local title = Font(win, 14, "")
        title:SetPoint("TOP", win, "TOP", 0, -14)
        title:SetText(L["Персонаж"])
        win.title = title
        if S.CreateAnimatedSeparator then S.CreateAnimatedSeparator(win, -36) end
        win.rows = {}
        for i = 1, 3 do
            local row = CreateFrame("Frame", nil, win)
            row:SetSize(240, 22)
            row:SetPoint("TOP", win, "TOP", 0, -48 - (i - 1) * 26)
            row.ground = Fill(row, "BACKGROUND")
            row.ground:SetAllPoints(row)
            if styled and S.RoundTexture then S.RoundTexture(row.ground, 5) end
            row.name = Font(row, 11, "")
            row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.name:SetText(({ L["Сила"], L["Ловкость"], L["Выносливость"] })[i])
            row.value = Font(row, 11, "")
            row.value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            row.value:SetText(({ "1 204", "342", "2 610" })[i])
            win.rows[i] = row
        end
        local button = NS.Widgets.CreateThemedButton(win, L["Применить"], 110, 22)
        button:SetPoint("BOTTOM", win, "BOTTOM", 0, 14)
        button:EnableMouse(false)
    end)
    S.DECOR = keep
    if not ok then P:Fail(err) end
    return win
end

local function PaintThemeLook(view)
    local S = NS.Styling
    local theme = NS.db and NS.db.theme or {}
    local styled = theme.decor ~= "classic"
    local A = S.ACCENT
    local id = string.format("%s|%.3f|%.3f|%.3f", styled and "s" or "c", A[1], A[2], A[3])
    view.wins = view.wins or {}
    if not view.wins[id] then view.wins[id] = DecorWindow(view, styled) end
    for other, win in pairs(view.wins) do win:SetShown(other == id) end
    local win = view.wins[id]
    local palette = S.ThemePalette and S.ThemePalette(theme)
    if palette then
        win:SetBackdropColor(palette.bg[1], palette.bg[2], palette.bg[3], 0.95 * palette.density)
        win:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], palette.border[4])
    end
    local G = S.ACCENT_GLOW
    if win.title then win.title:SetTextColor(G[1], G[2], G[3]) end
    for index, row in ipairs(win.rows or {}) do
        local slot = palette and palette.slot or S.BG_SLOT
        row.ground:SetVertexColor(slot[1], slot[2], slot[3], index % 2 == 0 and 0.9 or 0.5)
        local normal = palette and palette.normal or S.TEXT_NORMAL
        local bright = palette and palette.bright or S.TEXT_BRIGHT
        row.name:SetTextColor(normal[1], normal[2], normal[3])
        row.value:SetTextColor(bright[1], bright[2], bright[3])
    end
end

function P.ThemeLook(view)
    if not view.built then
        view.built = true
        World(view)
    end
    P.WithAccent(NS.db and NS.db.accentColor, PaintThemeLook, view)
end

function P.Decor(view, key)
    local theme = NS.db and NS.db.theme
    if type(theme) ~= "table" then return P.ThemeLook(view) end
    local keep = theme.decor
    theme.decor = key
    local ok, err = pcall(P.ThemeLook, view)
    theme.decor = keep
    if not ok then P:Fail(err) end
end

P.SIZE = {}

function P.Profile(view)
    if not view.built then
        view.built = true
        World(view)
        local width, height = view:GetWidth(), view:GetHeight()
        if not width or width < 100 then width, height = 380, 344 end
        local top = CreateFrame("Frame", nil, view)
        top:SetSize(width / 0.8, 190 / 0.8)
        top:SetScale(0.8)
        top:SetPoint("TOP", view, "TOP", 0, 0)
        view.top = top
        local bottom = CreateFrame("Frame", nil, view)
        bottom:SetSize(width, height - 194)
        bottom:SetPoint("BOTTOM", view, "BOTTOM", 0, 0)
        view.bottom = bottom
    end
    local ok, err = pcall(P.ThemeLook, view.top)
    if not ok then P:Fail(err) end
    local preset = NS.db and NS.db.elementLook and NS.db.elementLook.preset
    ok, err = pcall(P.LookPreset, view.bottom, preset)
    if not ok then P:Fail(err) end
end
