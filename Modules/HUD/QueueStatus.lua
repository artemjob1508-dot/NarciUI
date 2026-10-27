local addonName, NS = ...
local L = NS.L

local QS = {}
NS.QueueStatus = QS

local WHITE = "Interface\\Buttons\\WHITE8x8"
local GOLD = { 1, 0.82, 0.42 }
local VIOLET = { 0.68, 0.48, 1 }

QS.STYLE_ORDER = { "crest", "arcane", "radiant", "night", "flat", "pixel", "glass", "neon", "soft", "classic", "gold" }
QS.STYLES = {
    crest = { label = "герб", box = "flat", band = "gold", corners = true, divider = true, title = "gold" },
    arcane = { label = "тайный", box = "neon", tint = VIOLET, ground = { 0.045, 0.02, 0.085 }, band = "violet", mark = true, divider = true, title = "violet" },
    radiant = { label = "сияние", box = "flat", rays = true, divider = true, title = "accent" },
    night = { label = "ночное небо", box = "flat", art = "night", shade = 0.5, divider = true, title = "white" },
    flat = { label = "плоский", box = "flat" },
    pixel = { label = "пиксельный", box = "pixel" },
    glass = { label = "стекло", box = "glass" },
    neon = { label = "неон", box = "neon", title = "accent" },
    soft = { label = "мягкая тень", box = "soft" },
    classic = { label = "клиент", box = "classic" },
    gold = { label = "золото", box = "gold", title = "gold" },
}
QS.ROLE_ORDER = { "crest", "orb", "glyph", "client" }
QS.ROLE_LABELS = {
    crest = "цветные медальоны", orb = "значки на круглой подложке", glyph = "значки в цвете роли", client = "как в клиенте",
}

local ROLES = { "TANK", "HEALER", "DAMAGER" }
local ROLE_FILE = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damager" }
local ROLE_COLOR = { TANK = { 0.38, 0.64, 1 }, HEALER = { 0.38, 1, 0.48 }, DAMAGER = { 1, 0.4, 0.34 } }
local FOUND_KEYS = { TanksFound = "TANK", HealersFound = "HEALER", DamagersFound = "DAMAGER" }
local CORNERS = { { "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 }, { "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 } }

local function Settings()
    if not NS.db then return end
    if type(NS.db.queueStatus) ~= "table" then NS.db.queueStatus = {} end
    local db = NS.db.queueStatus
    if db.enabled == nil then db.enabled = true end
    if not QS.STYLES[db.style] then db.style = "crest" end
    if not QS.ROLE_LABELS[db.roles] then db.roles = "crest" end
    db.alpha = db.alpha or 92
    return db
end
QS.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function Accent()
    local A = NS.Styling.ACCENT_GLOW
    return A[1], A[2], A[3]
end

local function NamedColor(key)
    if key == "gold" then return GOLD[1], GOLD[2], GOLD[3] end
    if key == "violet" then return VIOLET[1], VIOLET[2], VIOLET[3] end
    if key == "white" then return 0.95, 0.96, 1 end
    return Accent()
end

local function RoleOf(texture)
    if type(GetTexCoordsForRole) ~= "function" then return end
    local left, top = texture:GetTexCoord()
    for _, role in ipairs(ROLES) do
        local ok, l, _, t = pcall(GetTexCoordsForRole, role)
        if ok and l and math.abs(left - l) < 0.01 and math.abs(top - t) < 0.01 then return role end
    end
end

local function RoleArt(owner, anchor)
    local art = {}
    art.glow = owner:CreateTexture(nil, "BACKGROUND", nil, 2)
    art.glow:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    art.glow:SetTexture(NS.Styling.Media("Glow"))
    art.glow:SetBlendMode("ADD")
    art.plate = owner:CreateTexture(nil, "ARTWORK", nil, 1)
    art.plate:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    art.plate:SetTexture(NS.Styling.Media("SoftDisc"))
    art.ring = owner:CreateTexture(nil, "ARTWORK", nil, 2)
    art.ring:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    art.ring:SetTexture(NS.Styling.Media("PortraitRing"))
    art.icon = owner:CreateTexture(nil, "ARTWORK", nil, 3)
    art.icon:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    return art
end

local function HideArt(art)
    art.glow:Hide()
    art.plate:Hide()
    art.ring:Hide()
    art.icon:Hide()
end

local function PaintRole(art, role, size, needed, mode)
    if not role or mode == "client" then
        HideArt(art)
        return
    end
    local c = ROLE_COLOR[role]
    local S = NS.Styling
    art.icon:SetDesaturated(needed and true or false)
    art.icon:Show()
    if mode == "crest" then
        art.plate:Hide()
        art.ring:Hide()
        art.icon:SetTexture(S.Media("RoleCrest" .. ROLE_FILE[role]))
        art.icon:SetSize(size * 1.08, size * 1.08)
        art.icon:SetVertexColor(1, 1, 1, needed and 0.5 or 1)
    else
        art.icon:SetTexture(S.Media("RoleGlyph" .. ROLE_FILE[role]))
        local scale = mode == "orb" and 0.6 or 0.92
        art.icon:SetSize(size * scale, size * scale)
        if needed then
            art.icon:SetVertexColor(0.5, 0.5, 0.55, 0.65)
        else
            art.icon:SetVertexColor(c[1], c[2], c[3], 1)
        end
        if mode == "orb" then
            art.plate:SetSize(size * 1.12, size * 1.12)
            art.plate:SetVertexColor(0.02, 0.022, 0.03, 0.95)
            art.plate:Show()
            art.ring:SetSize(size * 1.04, size * 1.04)
            if needed then
                art.ring:SetVertexColor(0.4, 0.4, 0.44, 0.8)
            else
                art.ring:SetVertexColor(c[1] * 0.85, c[2] * 0.85, c[3] * 0.85, 1)
            end
            art.ring:Show()
        else
            art.plate:Hide()
            art.ring:Hide()
        end
    end
    if needed then
        art.glow:Hide()
    else
        art.glow:SetSize(size * 1.9, size * 1.9)
        art.glow:SetVertexColor(c[1], c[2], c[3], 0.28)
        art.glow:Show()
    end
end

function QS:SkinFrame(frame)
    if frame.narciQS then return frame.narciQS end
    local S = NS.Styling
    if frame.SetBackdropColor then
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    local skin = CreateFrame("Frame", nil, frame)
    skin:SetAllPoints(frame)
    skin:SetFrameLevel(frame:GetFrameLevel())

    skin.art = skin:CreateTexture(nil, "BACKGROUND", nil, 2)
    skin.art:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
    skin.art:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
    skin.shade = skin:CreateTexture(nil, "BACKGROUND", nil, 3)
    skin.shade:SetAllPoints(skin.art)
    skin.shade:SetTexture(WHITE)

    skin.rays = skin:CreateTexture(nil, "BORDER", nil, 1)
    skin.rays:SetPoint("TOPRIGHT", skin, "TOPRIGHT", -1, -1)
    skin.rays:SetSize(220, 220)
    skin.rays:SetTexture(S.Media("QueueRays"))
    skin.rays:SetBlendMode("ADD")

    skin.mark = skin:CreateTexture(nil, "BORDER", nil, 1)
    skin.mark:SetPoint("CENTER", skin, "CENTER", 0, 0)
    skin.mark:SetSize(150, 150)
    skin.mark:SetTexture(S.Media("MessengerRunes"))
    skin.mark:SetBlendMode("ADD")

    skin.band = skin:CreateTexture(nil, "BORDER", nil, 2)
    skin.band:SetPoint("TOPLEFT", skin, "TOPLEFT", 2, -2)
    skin.band:SetPoint("TOPRIGHT", skin, "TOPRIGHT", -2, -2)
    skin.band:SetHeight(38)
    skin.band:SetTexture(S.Media("QueueBand"))

    skin.corners = {}
    for index, spec in ipairs(CORNERS) do
        local t = skin:CreateTexture(nil, "BORDER", nil, 3)
        t:SetPoint(spec[1], skin, spec[1], 0, 0)
        t:SetSize(24, 24)
        t:SetTexture(S.Media("DecorCorner"))
        t:SetTexCoord(spec[2], spec[3], spec[4], spec[5])
        skin.corners[index] = t
    end

    skin:SetScript("OnUpdate", function(self, elapsed)
        if not self.spin then return end
        self.turn = ((self.turn or 0) + elapsed * 0.12) % (math.pi * 2)
        self.mark:SetRotation(self.turn)
    end)

    frame.narciQS = skin
    return skin
end

function QS:PaintFrame(frame, db)
    local skin = self:SkinFrame(frame)
    local row = self.STYLES[db.style] or self.STYLES.flat
    local S = NS.Styling
    local alpha = (db.alpha or 92) / 100
    S.SkinBox(skin, row.box, { alpha = alpha, tint = row.tint, borderLevel = 12 })
    local box = skin.narciBox
    if row.ground and box and box.ground then
        box.ground:SetVertexColor(row.ground[1], row.ground[2], row.ground[3], alpha)
    end

    local r, g, b = NamedColor(row.band or row.title)

    if row.art and S.SceneArt(skin.art, row.art) then
        skin.art:SetVertexColor(1, 1, 1, alpha)
        skin.art:Show()
        skin.shade:SetVertexColor(0, 0, 0, row.shade or 0.4)
        skin.shade:Show()
    else
        skin.art:Hide()
        skin.shade:Hide()
    end

    if row.band then
        skin.band:SetVertexColor(r, g, b, 0.2)
        skin.band:Show()
    else
        skin.band:Hide()
    end

    if row.rays then
        local ar, ag, ab = Accent()
        skin.rays:SetVertexColor(ar, ag, ab, 0.32)
        skin.rays:Show()
    else
        skin.rays:Hide()
    end

    skin.spin = row.mark and true or nil
    if row.mark then
        skin.mark:SetVertexColor(r, g, b, 0.16)
        skin.mark:Show()
    else
        skin.mark:Hide()
    end

    for _, t in ipairs(skin.corners) do
        if row.corners then
            t:SetVertexColor(r, g, b, 0.85)
            t:Show()
        else
            t:Hide()
        end
    end
end

function QS:SkinEntry(entry)
    if entry.narciQS then return end
    entry.narciQS = true
    local function Font(fs, size, flags)
        if fs and fs.SetFont then fs:SetFont(NS.FONT, NS.FS(size), flags or "") end
    end
    Font(entry.Title, 15)
    Font(entry.Status, 12)
    Font(entry.SubTitle, 12)
    Font(entry.TimeInQueue, 12)
    Font(entry.AverageWait, 12)
    Font(entry.ExtraText, 10)

    entry.narciRoles = {}
    for index = 1, 3 do
        local icon = entry["RoleIcon" .. index]
        if icon then entry.narciRoles[index] = RoleArt(entry, icon) end
    end
    for key in pairs(FOUND_KEYS) do
        local f = entry[key]
        if f then
            f.narciArt = RoleArt(f, f)
            Font(f.Count, 11, "OUTLINE")
        end
    end
end

local function Lerp(a, b, t) return a + (b - a) * t end

function QS:PaintEntry(entry, db)
    self:SkinEntry(entry)
    local row = self.STYLES[db.style] or self.STYLES.flat
    local S = NS.Styling
    local mode = db.roles or "crest"

    local tr, tg, tb = NamedColor(row.title or "white")
    if not row.title then tr, tg, tb = S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3] end
    entry.Title:SetTextColor(tr, tg, tb)
    local ar, ag, ab = Accent()
    if entry.Status then entry.Status:SetTextColor(ar, ag, ab) end
    if entry.SubTitle then entry.SubTitle:SetTextColor(0.78, 0.8, 0.86) end
    local nr, ng, nb = S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]
    if entry.AverageWait then entry.AverageWait:SetTextColor(nr, ng, nb) end
    if entry.TimeInQueue then entry.TimeInQueue:SetTextColor(Lerp(nr, tr, 0.5), Lerp(ng, tg, 0.5), Lerp(nb, tb, 0.5)) end
    if entry.ExtraText then entry.ExtraText:SetTextColor(0.55, 0.56, 0.62) end

    local sep = entry.EntrySeparator
    if sep then
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, row.divider and 4 or 0)
        sep:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -10, row.divider and 4 or 0)
        if row.divider then
            local dr, dg, db2 = NamedColor(row.band or row.title)
            sep:SetTexture(S.Media("QueueDivider"))
            sep:SetHeight(8)
            sep:SetVertexColor(dr, dg, db2, 0.85)
        else
            local B = S.BORDER
            sep:SetTexture(WHITE)
            sep:SetHeight(1)
            sep:SetVertexColor(B[1], B[2], B[3], 0.7)
        end
    end

    for index, art in ipairs(entry.narciRoles or {}) do
        local icon = entry["RoleIcon" .. index]
        if icon and icon:IsShown() and mode ~= "client" then
            icon:SetAlpha(0)
            PaintRole(art, RoleOf(icon), 22, false, mode)
        else
            if icon then icon:SetAlpha(1) end
            HideArt(art)
        end
    end

    for key, role in pairs(FOUND_KEYS) do
        local f = entry[key]
        if f and f.narciArt then
            local needed = f.Cover and f.Cover:IsShown()
            if mode == "client" then
                if f.Texture then f.Texture:SetAlpha(1) end
                if f.Cover then f.Cover:SetAlpha(0.3) end
                HideArt(f.narciArt)
                if f.Count then f.Count:SetTextColor(1, 1, 1) end
            else
                if f.Texture then f.Texture:SetAlpha(0) end
                if f.Cover then f.Cover:SetAlpha(0) end
                PaintRole(f.narciArt, role, 36, needed, mode)
                if f.Count then
                    local c = ROLE_COLOR[role]
                    if needed then
                        f.Count:SetTextColor(0.6, 0.6, 0.65)
                    else
                        f.Count:SetTextColor(Lerp(c[1], 1, 0.45), Lerp(c[2], 1, 0.45), Lerp(c[3], 1, 0.45))
                    end
                end
            end
        end
    end
end

function QS:Refresh()
    local frame = _G.QueueStatusFrame
    if not frame or not frame.narciQS then return end
    local db = Settings()
    self:PaintFrame(frame, db)
    if frame.statusEntriesPool then
        for entry in frame.statusEntriesPool:EnumerateActive() do self:PaintEntry(entry, db) end
    end
end

function QS:SetOption(field, value)
    local db = Settings()
    if not db then return end
    db[field] = value
    self:Refresh()
end

function QS:Apply()
    if self.applied or not Enabled() then return end
    local frame = _G.QueueStatusFrame
    if not frame or not frame.statusEntriesPool or type(QueueStatusFrame_Update) ~= "function" then return end
    self.applied = true
    if type(QueueStatusFrame_GetEntry) == "function" then
        hooksecurefunc("QueueStatusFrame_GetEntry", function(owner, index)
            if owner ~= frame then return end
            for entry in frame.statusEntriesPool:EnumerateActive() do
                if entry.orderIndex == index then QS:SkinEntry(entry) end
            end
        end)
    end
    hooksecurefunc("QueueStatusFrame_Update", function(owner)
        if owner == frame then QS:Refresh() end
    end)
    self:PaintFrame(frame, Settings())
    pcall(QueueStatusFrame_Update, frame)
end

function QS:CreateSample(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(275, 160)
    holder:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    local entry = CreateFrame("Frame", nil, holder, "QueueStatusEntryTemplate")
    entry:SetPoint("TOP", holder, "TOP", 0, 0)
    entry.EntrySeparator:Hide()
    holder.entry = entry
    self:SkinEntry(entry)
    QueueStatusEntry_SetFullDisplay(entry, L["Поиск подземелий"], GetTime() - 253, 4, false, false, true, 1, 1, 3, 1, 0, 0)
    entry:SetScript("OnUpdate", nil)
    entry:Show()
    QueueStatusEntry_RecaluculateHeight(entry, true)
    holder:SetHeight(entry:GetHeight() + 4)
    return holder
end

function QS:PaintSample(holder)
    if not holder then return end
    local db = Settings()
    self:PaintFrame(holder, db)
    self:PaintEntry(holder.entry, db)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function()
    if not Enabled() then return end
    if NS.After then
        NS.After(1, function() QS:Apply() end)
    else
        QS:Apply()
    end
end)
