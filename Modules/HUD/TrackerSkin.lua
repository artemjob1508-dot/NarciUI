local addonName, NS = ...
local L = NS.L

local Tracker = {}
NS.TrackerSkin = Tracker

local WHITE = "Interface\\Buttons\\WHITE8x8"

Tracker.STYLES = { "fade", "clean", "panel", "glass", "neon", "gold" }
Tracker.STYLE_LABELS = {
    fade = "тающий фон", clean = "без фона", panel = "панель", glass = "стекло", neon = "неон", gold = "золото",
}
local BOX = { panel = "flat", glass = "glass", neon = "neon", gold = "gold" }
Tracker.EXTRA = {}

function Tracker:AddStyle(key, label, row)
    if type(key) ~= "string" or key == "" or Tracker.STYLE_LABELS[key] or type(row) ~= "table" then return false end
    Tracker.EXTRA[key] = row
    BOX[key] = row.box
    Tracker.STYLE_LABELS[key] = label or key
    table.insert(Tracker.STYLES, key)
    return true
end

local function Settings()
    if not NS.db then return end
    if type(NS.db.tracker) ~= "table" then NS.db.tracker = {} end
    local db = NS.db.tracker
    if db.enabled == nil then db.enabled = true end
    db.style = db.style or "fade"
    db.headerColor = db.headerColor or "accent"
    db.fontSize = db.fontSize or 12
    db.alpha = db.alpha or 70
    if db.outline == nil then db.outline = true end
    return db
end
Tracker.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function HeaderColor()
    local db = Settings()
    local S = NS.Styling
    if db.headerColor == "gold" then return 1, 0.82, 0.25 end
    if db.headerColor == "white" then return 0.95, 0.95, 0.97 end
    if db.headerColor == "class" then
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2, UnitClass("player"))]
        if c then return c.r, c.g, c.b end
    end
    return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
end

local function FontArgs(size)
    local db = Settings()
    return NS.FONT, db.fontSize + (size - 12), db.outline and "OUTLINE" or ""
end

function Tracker:ApplyFonts()
    local db = Settings()
    for size = 12, 22 do
        local font = _G["ObjectiveTrackerFont" .. size]
        if font and font.SetFont then font:SetFont(FontArgs(size)) end
    end
    for name, size in pairs({ ObjectiveTrackerLineFont = 12, ObjectiveTrackerHeaderFont = 14 }) do
        local font = _G[name]
        if font and font.SetFont then
            font:SetFont(FontArgs(size))
            font:SetShadowColor(0, 0, 0, db.outline and 0 or 1)
            font:SetShadowOffset(1, -1)
        end
    end
end

local function Glyph(button)
    if button.narciGlyph then return button.narciGlyph end
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }) do
        local texture = button[getter] and button[getter](button)
        if texture then texture:SetAlpha(0) end
    end
    local glyph = button:CreateTexture(nil, "OVERLAY")
    glyph:SetSize(11, 11)
    glyph:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.narciGlyph = glyph
    button:HookScript("OnEnter", function() glyph:SetVertexColor(1, 1, 1, 1) end)
    button:HookScript("OnLeave", function() Tracker:PaintGlyph(button) end)
    return glyph
end

function Tracker:PaintGlyph(button)
    local glyph = button.narciGlyph
    if not glyph then return end
    local r, g, b = HeaderColor()
    glyph:SetVertexColor(r, g, b, 0.9)
end

function Tracker:SkinHeader(header, main, collapsed)
    if not header then return end
    local S = NS.Styling
    for _, key in ipairs({ "Background", "Shine", "Glow" }) do
        if header[key] then header[key]:SetAlpha(0) end
    end

    local n = header.narci
    if not n then
        n = {}
        n.glow = header:CreateTexture(nil, "BACKGROUND")
        n.glow:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -5)
        n.glow:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -30, 5)
        n.glow:SetTexture(WHITE)
        n.line = header:CreateTexture(nil, "BORDER")
        n.line:SetHeight(1)
        n.line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 2, 4)
        n.line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 4)
        n.line:SetTexture(WHITE)
        n.bar = header:CreateTexture(nil, "BORDER")
        n.bar:SetWidth(2)
        n.bar:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -6)
        n.bar:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 2, 6)
        n.bar:SetTexture(WHITE)
        header.narci = n
    end

    local r, g, b = HeaderColor()
    n.glow:SetGradientAlpha("HORIZONTAL", r, g, b, main and 0.2 or 0.1, r, g, b, 0)
    n.line:SetGradientAlpha("HORIZONTAL", r, g, b, main and 0.9 or 0.45, r, g, b, 0)
    n.bar:SetVertexColor(r, g, b, 1)
    n.bar:SetShown(not main)

    if header.Text then
        if main then
            header.Text:SetTextColor(r, g, b)
        else
            header.Text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end

    if header.MinimizeButton then
        local glyph = Glyph(header.MinimizeButton)
        glyph:SetTexture(S.Media(collapsed and "IconPlus" or "IconMinus"))
        self:PaintGlyph(header.MinimizeButton)
    end
    if header.FilterButton then
        local glyph = Glyph(header.FilterButton)
        glyph:SetTexture(S.Media("IconDown"))
        self:PaintGlyph(header.FilterButton)
    end
end

function Tracker:Panel(frame)
    local db = Settings()
    local panel = frame.narciPanel
    if not panel then
        panel = CreateFrame("Frame", nil, frame)
        panel:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 4)
        panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -8)
        panel:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
        panel.fade = panel:CreateTexture(nil, "BACKGROUND")
        panel.fade:SetAllPoints(panel)
        panel.fade:SetTexture(WHITE)
        frame.narciPanel = panel
    end
    local alpha = (db.alpha or 70) / 100
    panel.fade:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, alpha * 0.85)
    local extra = Tracker.EXTRA[db.style]
    panel.fade:SetShown(db.style == "fade" or (extra ~= nil and extra.fade == true))
    NS.Styling.SkinBox(panel, BOX[db.style] or "none", { alpha = alpha, edgeSize = 12, glowSize = 6, shadowSize = 10 })
    panel:SetShown(db.style ~= "clean")
    if extra and type(extra.paint) == "function" then pcall(extra.paint, panel, db) end
end

function Tracker:SkinBar(holder)
    local bar = holder and holder.Bar
    if not bar then return end
    if not bar.narciSkinned then
        bar.narciSkinned = true
        for _, key in ipairs({ "BorderLeft", "BorderRight", "BorderMid", "Background" }) do
            if bar[key] then bar[key]:SetAlpha(0) end
        end
        local ground = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
        ground:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        ground:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(0, 0, 0, 0.75)
        bar.narciEdges = NS.Styling.CreateEdges(bar, "OVERLAY", 0, 0, 0, 1)
        for _, line in ipairs(bar.narciEdges) do
            line:ClearAllPoints()
        end
        local e = bar.narciEdges
        e[1]:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        e[1]:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 1, 1)
        e[2]:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -1, -1)
        e[2]:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        e[3]:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        e[3]:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -1, -1)
        e[4]:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 1, 1)
        e[4]:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    end
    bar:SetStatusBarTexture(NS.Styling.Media("BarSoft"))
    if bar.Label then bar.Label:SetFont(FontArgs(12)) end
    if holder.Label then holder.Label:SetFont(FontArgs(12)) end
end

function Tracker:SkinItem(button)
    if not button or button.narciSkinned or not button.icon or not button.GetNormalTexture then return end
    button.narciSkinned = true
    local normal = button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    NS.Styling.CreateEdges(button, "OVERLAY", 0, 0, 0, 1)
end

local function Containers()
    local list = {}
    local manager = _G.ObjectiveTrackerManager
    if manager and type(manager.containers) == "table" then
        for container in pairs(manager.containers) do list[#list + 1] = container end
    end
    if #list == 0 and _G.ObjectiveTrackerFrame then list[1] = _G.ObjectiveTrackerFrame end
    return list
end

function Tracker:SkinContainer(frame)
    if not frame then return end
    if frame.NineSlice then frame.NineSlice:SetAlpha(0) end
    self:Panel(frame)
    self:SkinHeader(frame.Header, true, frame.IsCollapsed and frame:IsCollapsed())
    for _, module in ipairs(frame.modules or {}) do
        self:SkinHeader(module.Header, false, module.IsCollapsed and module:IsCollapsed())
        for _, bar in pairs(module.usedProgressBars or {}) do self:SkinBar(bar) end
        for _, bar in pairs(module.usedTimerBars or {}) do self:SkinBar(bar) end
        for _, item in pairs(module.usedRightEdgeFrames or {}) do self:SkinItem(item) end
        if not module.narciHooked and module.Header and module.Header.SetCollapsed then
            module.narciHooked = true
            hooksecurefunc(module.Header, "SetCollapsed", function(header, collapsed)
                if Enabled() then Tracker:SkinHeader(header, false, collapsed) end
            end)
        end
    end
end

function Tracker:Refresh()
    if not Enabled() then return end
    for _, frame in ipairs(Containers()) do
        local ok = pcall(self.SkinContainer, self, frame)
        if not ok then break end
    end
end

function Tracker:Hook()
    if self.hooked or not Enabled() then return end
    local frames = Containers()
    if #frames == 0 then return end
    self.hooked = true
    self:ApplyFonts()
    for _, frame in ipairs(frames) do
        if frame.Update then
            hooksecurefunc(frame, "Update", function() Tracker:Refresh() end)
        end
        if frame.SetBackgroundAlpha then
            hooksecurefunc(frame, "SetBackgroundAlpha", function(f)
                if f.NineSlice then f.NineSlice:SetAlpha(0) end
            end)
        end
        if frame.Header and frame.Header.SetCollapsed then
            hooksecurefunc(frame.Header, "SetCollapsed", function(header, collapsed)
                Tracker:SkinHeader(header, true, collapsed)
            end)
        end
    end
    local manager = _G.ObjectiveTrackerManager
    if manager and manager.UpdateAll then pcall(manager.UpdateAll, manager) end
    self:Refresh()
end

function Tracker:SetOption(field, value)
    local db = Settings()
    if not db then return end
    db[field] = value
    if field == "fontSize" or field == "outline" then
        self:ApplyFonts()
        local manager = _G.ObjectiveTrackerManager
        if manager and manager.UpdateAll then pcall(manager.UpdateAll, manager) end
    end
    self:Refresh()
end

local SAMPLE_LINES = {
    { "Марвин", true }, { "Фалрик", true }, { "Побег от Артаса", false },
}

function Tracker:CreateSample(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(240, 168)

    local function Header(y, main)
        local header = CreateFrame("Frame", nil, f)
        header:SetSize(240, main and 30 or 26)
        header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)
        header.Text = header:CreateFontString(nil, "ARTWORK")
        header.Text:SetPoint("LEFT", header, "LEFT", 9, 0)
        header.MinimizeButton = CreateFrame("Button", nil, header)
        header.MinimizeButton:SetSize(18, 19)
        header.MinimizeButton:SetPoint("RIGHT", header, "RIGHT", -1, 0)
        header.MinimizeButton:EnableMouse(false)
        return header
    end

    f.main = Header(0, true)
    f.module = Header(-34, false)
    f.lines = {}
    for index = 1, #SAMPLE_LINES do
        local line = f:CreateFontString(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -64 - (index - 1) * 18)
        local check = f:CreateTexture(nil, "ARTWORK")
        check:SetSize(12, 12)
        check:SetPoint("RIGHT", line, "LEFT", -4, 0)
        check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        line.check = check
        f.lines[index] = line
    end
    local holder = CreateFrame("Frame", nil, f)
    holder:SetSize(200, 16)
    holder:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -126)
    holder.Bar = CreateFrame("StatusBar", nil, holder)
    holder.Bar:SetAllPoints(holder)
    holder.Bar:SetMinMaxValues(0, 100)
    holder.Bar:SetValue(62)
    holder.Bar:SetStatusBarTexture(WHITE)
    holder.Bar:SetStatusBarColor(0.26, 0.42, 1)
    holder.Bar.Label = holder.Bar:CreateFontString(nil, "OVERLAY")
    holder.Bar.Label:SetPoint("CENTER", holder.Bar, "CENTER", 0, 0)
    f.progress = holder
    return f
end

function Tracker:PaintSample(f)
    local db = Settings()
    if not db or not f then return end
    self:Panel(f)
    for _, pair in ipairs({ { f.main, 16, "Все задачи", true }, { f.module, 14, "Подземелье", false } }) do
        pair[1].Text:SetFont(FontArgs(pair[2]))
        pair[1].Text:SetShadowColor(0, 0, 0, db.outline and 0 or 1)
        pair[1].Text:SetShadowOffset(1, -1)
        pair[1].Text:SetText(L[pair[3]])
        self:SkinHeader(pair[1], pair[4], false)
    end
    for index, line in ipairs(f.lines) do
        local data = SAMPLE_LINES[index]
        line:SetFont(FontArgs(12))
        line:SetText((data[2] and "1/1 " or "0/1 ") .. L[data[1]])
        if data[2] then
            line:SetTextColor(0.6, 0.6, 0.6)
        else
            line:SetTextColor(0.8, 0.8, 0.8)
        end
        line.check:SetShown(data[2])
    end
    self:SkinBar(f.progress)
    f.progress.Bar.Label:SetText("62%")
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent", function(self, event)
    if not Enabled() then return end
    Tracker:Hook()
    if Tracker.hooked then
        if NS.After then NS.After(1, function() Tracker:Refresh() end) end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
