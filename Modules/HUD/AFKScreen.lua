local addonName, NS = ...
local L = NS.L

local AFK = {}
NS.AFKScreen = AFK

local WHITE = "Interface\\Buttons\\WHITE8x8"
local CLASS_ICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local PANEL_H = 120
local TIP_SECONDS = 15
local CHAT_EVENTS = {
    "CHAT_MSG_WHISPER", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
}
local PASS_KEYS = { LALT = true, RALT = true, LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true }
local TINTS = {
    gold = { 1, 0.80, 0.32 },
    silver = { 0.80, 0.84, 0.90 },
}
local TIPS = {
    "/narci config открывает настройки, а поиск над списком страниц находит любую опцию по слову.",
    "Страница «Части аддона» возвращает любой элемент к виду клиента.",
    "В окне персонажа левая кнопка мыши поворачивает модель, колесо приближает, правая кнопка сдвигает её.",
    "Профиль настроек можно передать другу одной строкой на странице «Профили».",
    "Раскладки под роль могут переключаться сами при смене специализации.",
    "Вкладка «Персонажи» в сумках показывает предметы всех ваших персонажей.",
    "«Цвета NarciUI» задают общий цвет рамок и фона всех элементов интерфейса.",
    "Валюты в окне сумок выбираются на странице «Валюта в сумке».",
    "Фон, туман, искры и позу модели в окне персонажа меняет страница «Сцена».",
    "Своё название, девиз и эмблему интерфейса задаёт страница «Подпись и эмблема».",
    "Плагины NarciUI добавляют свои вкладки, формы слотов и подсветки.",
}

local PANEL_STYLES = {
    narci = {},
    glass = { box = "glass" },
    classic = { box = "gold" },
    night = { scene = "night" },
    dawn = { scene = "dawn" },
    scroll = { scene = "parchment" },
    arcane = { bg = { 0.06, 0.02, 0.10 }, mark = { file = "MessengerRunes", color = { 0.7, 0.5, 1 }, alpha = 0.4, spin = 0.05 } },
}
AFK.PANEL_STYLES = PANEL_STYLES
AFK.PANEL_STYLE_ORDER = { "narci", "glass", "classic", "night", "dawn", "scroll", "arcane" }
AFK.PANEL_STYLE_LABELS = {
    narci = "NarciUI", glass = "Стекло", classic = "Золото", night = "Ночное небо",
    dawn = "Рассвет", scroll = "Пергамент", arcane = "Аркана",
}

local function Settings()
    if not NS.db then return end
    if type(NS.db.afk) ~= "table" then NS.db.afk = {} end
    local db = NS.db.afk
    if db.enabled == nil then db.enabled = true end
    if db.spin == nil then db.spin = true end
    if db.chat == nil then db.chat = true end
    if db.model == nil then db.model = true end
    db.spinSpeed = db.spinSpeed or 4
    return db
end
AFK.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local function Clock(seconds)
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor(seconds / 60) % 60
    local s = seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function Font(text, size, flags)
    text:SetFont(NS.FONT, NS.FS(size), flags or "")
    text:SetShadowColor(0, 0, 0, 0.9)
    text:SetShadowOffset(1, -1)
end

local function TintColors(key)
    local S = NS.Styling
    if key == "brand" and S.BrandColor then
        return S.BrandColor()
    elseif key == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then
            return c.r, c.g, c.b, math.min(1, c.r * 0.7 + 0.3), math.min(1, c.g * 0.7 + 0.3), math.min(1, c.b * 0.7 + 0.3)
        end
    end
    local c = TINTS[key]
    if c then return c[1], c[2], c[3], c[1], c[2], c[3] end
    local A, G = S.ACCENT, S.ACCENT_GLOW
    return A[1], A[2], A[3], G[1], G[2], G[3]
end

function AFK:Create()
    if self.frame then return self.frame end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarciSirus_AFKScreen")
    f:SetFrameStrata("FULLSCREEN")
    f:SetAllPoints(UIParent)
    f:EnableMouse(true)
    f:EnableKeyboard(true)
    f:Hide()
    self.frame = f

    local veil = f:CreateTexture(nil, "BACKGROUND")
    veil:SetAllPoints(f)
    veil:SetTexture(WHITE)
    f.veil = veil

    local shade = f:CreateTexture(nil, "BACKGROUND")
    shade:SetHeight(160)
    shade:SetTexture(WHITE)
    f.shade = shade

    local panel = CreateFrame("Frame", nil, f)
    panel:SetHeight(PANEL_H)
    f.panel = panel

    local ground = panel:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(panel)
    ground:SetTexture(WHITE)
    f.ground = ground

    local line = panel:CreateTexture(nil, "BORDER")
    line:SetHeight(2)
    line:SetTexture(WHITE)
    f.line = line

    local lineLeft = panel:CreateTexture(nil, "ARTWORK")
    lineLeft:SetHeight(2)
    lineLeft:SetTexture(WHITE)
    f.lineLeft = lineLeft

    local lineRight = panel:CreateTexture(nil, "ARTWORK")
    lineRight:SetHeight(2)
    lineRight:SetTexture(WHITE)
    f.lineRight = lineRight

    local halo = panel:CreateTexture(nil, "BORDER")
    halo:SetSize(900, 70)
    halo:SetPoint("CENTER", line, "CENTER", 0, 0)
    halo:SetTexture(S.GLOW)
    halo:SetBlendMode("ADD")
    f.halo = halo

    local art = panel:CreateTexture(nil, "BACKGROUND")
    art:SetAllPoints(panel)
    art:Hide()
    f.art = art

    local mark = panel:CreateTexture(nil, "ARTWORK")
    mark:SetBlendMode("ADD")
    mark:Hide()
    f.mark = mark

    local logo = CreateFrame("Frame", nil, f)
    logo:SetAllPoints(f)
    logo:SetFrameLevel(panel:GetFrameLevel() + 5)
    f.logo = logo

    local emblemShade = logo:CreateTexture(nil, "BORDER")
    emblemShade:SetSize(128, 128)
    emblemShade:SetTexture(S.Media("LogoEmblemGlow"))
    emblemShade:SetVertexColor(0, 0, 0, 0.9)
    f.emblemShade = emblemShade

    local emblemGlow = logo:CreateTexture(nil, "ARTWORK")
    emblemGlow:SetSize(140, 140)
    emblemGlow:SetPoint("CENTER", emblemShade, "CENTER", 0, 0)
    emblemGlow:SetBlendMode("ADD")
    f.emblemGlow = emblemGlow

    local emblem = logo:CreateTexture(nil, "OVERLAY")
    emblem:SetSize(112, 112)
    emblem:SetPoint("CENTER", emblemShade, "CENTER", 0, 0)
    f.emblem = emblem

    local word = logo:CreateTexture(nil, "OVERLAY")
    word:SetSize(200, 50)
    f.word = word

    local wordText = logo:CreateFontString(nil, "OVERLAY")
    wordText:SetShadowColor(0, 0, 0, 1)
    wordText:SetShadowOffset(1, -1)
    wordText:SetPoint("CENTER", word, "CENTER", 0, 0)
    f.wordText = wordText

    local away = logo:CreateFontString(nil, "OVERLAY")
    Font(away, 11)
    away:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    f.away = away

    local timer = logo:CreateFontString(nil, "OVERLAY")
    Font(timer, 15, "OUTLINE")
    timer:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    f.timer = timer

    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("LEFT", panel, "LEFT", 40, 0)
    icon:SetTexture(CLASS_ICONS)
    f.icon = icon

    local iconFrame = CreateFrame("Frame", nil, panel)
    iconFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    iconFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    f.iconEdges = S.CreateEdges(iconFrame, "OVERLAY", 1, 1, 1, 0.9)
    if S.CreateSoftShadow then S.CreateSoftShadow(iconFrame, 6, 0.6) end
    f.iconFrame = iconFrame

    local name = panel:CreateFontString(nil, "OVERLAY")
    Font(name, 22)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 18, 4)
    f.name = name

    local info = panel:CreateFontString(nil, "OVERLAY")
    Font(info, 13)
    info:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
    info:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    f.info = info

    local guild = panel:CreateFontString(nil, "OVERLAY")
    Font(guild, 13)
    guild:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -4)
    guild:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    f.guild = guild

    local motto = logo:CreateFontString(nil, "OVERLAY")
    Font(motto, 13)
    f.motto = motto

    local clock = panel:CreateFontString(nil, "OVERLAY")
    Font(clock, 30)
    clock:SetPoint("RIGHT", panel, "RIGHT", -440, 10)
    clock:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    f.clock = clock

    local day = panel:CreateFontString(nil, "OVERLAY")
    Font(day, 12)
    day:SetPoint("TOP", clock, "BOTTOM", 0, -4)
    day:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    f.day = day

    local model = CreateFrame("PlayerModel", nil, f)
    model:SetSize(520, 680)
    model:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 30, 4)
    model:SetFrameLevel(panel:GetFrameLevel() + 2)
    model:SetScript("OnUpdate", function(self, elapsed)
        if not self.anim then return end
        self.animTime = (self.animTime or 0) + elapsed * 1000
        pcall(self.SetSequenceTime, self, self.anim, self.animTime)
    end)
    f.model = model

    local chat = CreateFrame("ScrollingMessageFrame", nil, f)
    chat:SetSize(520, 220)
    chat:SetFont(NS.FONT, NS.FS(13), "")
    chat:SetShadowColor(0, 0, 0, 1)
    chat:SetShadowOffset(1, -1)
    chat:SetJustifyH("LEFT")
    chat:SetMaxLines(200)
    chat:SetFading(false)
    chat:EnableMouseWheel(true)
    chat:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    chat:SetScript("OnEvent", function(self, event, ...) AFK:ChatLine(event, ...) end)
    f.chat = chat

    local hint = f:CreateFontString(nil, "OVERLAY")
    Font(hint, 11)
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetText(L["Нажмите любую клавишу, чтобы вернуться"])
    f.hint = hint

    local tip = logo:CreateFontString(nil, "OVERLAY")
    Font(tip, 13)
    tip:SetWidth(760)
    tip:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    f.tip = tip

    f:SetScript("OnKeyDown", function(_, key)
        if PASS_KEYS[key] then return end
        if key == "PRINTSCREEN" then
            Screenshot()
            return
        end
        AFK:Leave(true)
    end)
    f:SetScript("OnMouseDown", function() AFK:Leave(true) end)

    local ticker = CreateFrame("Frame", nil, f)
    local elapsed = 1
    ticker:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.5 then return end
        elapsed = 0
        AFK:Tick()
    end)

    return f
end

local function Place(region, ...)
    region:ClearAllPoints()
    region:SetPoint(...)
end

function AFK:Layout()
    local f = self.frame
    local db = Settings()
    local layout = db.layout or "bottom"
    local panel = f.panel

    Place(panel, layout == "top" and "TOPLEFT" or "BOTTOMLEFT", f, layout == "top" and "TOPLEFT" or "BOTTOMLEFT", 0, 0)
    panel:SetPoint(layout == "top" and "TOPRIGHT" or "BOTTOMRIGHT", f, layout == "top" and "TOPRIGHT" or "BOTTOMRIGHT", 0, 0)

    local edge = layout == "top" and "BOTTOM" or "TOP"
    Place(f.line, edge .. "LEFT", panel, edge .. "LEFT", 0, 0)
    f.line:SetPoint(edge .. "RIGHT", panel, edge .. "RIGHT", 0, 0)
    Place(f.lineLeft, edge .. "LEFT", panel, edge .. "LEFT", 0, 0)
    f.lineLeft:SetPoint(edge .. "RIGHT", panel, edge, 0, 0)
    Place(f.lineRight, edge .. "LEFT", panel, edge, 0, 0)
    f.lineRight:SetPoint(edge .. "RIGHT", panel, edge .. "RIGHT", 0, 0)

    local bare = layout == "minimal"
    f.ground:SetShown(not bare)
    f.line:SetShown(not bare)
    f.lineLeft:SetShown(not bare)
    f.lineRight:SetShown(not bare)
    f.halo:SetShown(not bare)

    if layout == "top" then
        Place(f.shade, "BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        f.shade:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        f.shade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.5, 0, 0, 0, 0)
        f.veil:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.55)
        Place(f.emblemShade, "CENTER", panel, "BOTTOM", 0, -26)
        Place(f.word, "TOP", panel, "TOP", 0, -8)
        Place(f.timer, "TOP", f.emblemShade, "BOTTOM", 0, 10)
        Place(f.away, "TOP", f.timer, "BOTTOM", 0, -4)
        Place(f.motto, "TOP", f.away, "BOTTOM", 0, -6)
        Place(f.chat, "BOTTOMLEFT", f, "BOTTOMLEFT", 24, 24)
        Place(f.hint, "BOTTOM", f, "BOTTOM", 0, 20)
        Place(f.tip, "BOTTOM", f, "BOTTOM", 0, 60)
    elseif bare then
        Place(f.shade, "TOPLEFT", f, "TOPLEFT", 0, 0)
        f.shade:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        f.shade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.5)
        f.veil:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.65, 0, 0, 0, 0.35)
        Place(f.emblemShade, "CENTER", f, "CENTER", 0, 90)
        Place(f.word, "TOP", f.emblemShade, "BOTTOM", 0, 10)
        Place(f.timer, "TOP", f.word, "BOTTOM", 0, -6)
        Place(f.away, "TOP", f.timer, "BOTTOM", 0, -4)
        Place(f.motto, "TOP", f.away, "BOTTOM", 0, -8)
        Place(f.chat, "TOPLEFT", f, "TOPLEFT", 24, -24)
        Place(f.hint, "TOPRIGHT", f, "TOPRIGHT", -24, -20)
        Place(f.tip, "TOP", f, "TOP", 0, -60)
    else
        Place(f.shade, "TOPLEFT", f, "TOPLEFT", 0, 0)
        f.shade:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        f.shade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.5)
        f.veil:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.55, 0, 0, 0, 0)
        Place(f.emblemShade, "CENTER", panel, "TOP", 0, 26)
        Place(f.word, "TOP", f.emblemShade, "BOTTOM", 0, 24)
        Place(f.away, "BOTTOM", panel, "BOTTOM", 0, 28)
        Place(f.timer, "BOTTOM", panel, "BOTTOM", 0, 9)
        Place(f.motto, "BOTTOM", f.emblemShade, "TOP", 0, 0)
        Place(f.chat, "TOPLEFT", f, "TOPLEFT", 24, -24)
        Place(f.hint, "TOPRIGHT", f, "TOPRIGHT", -24, -20)
        Place(f.tip, "TOP", f, "TOP", 0, -60)
    end
end

function AFK:Paint()
    local f = self.frame
    local S = NS.Styling
    local db = Settings()
    local r, g, b, gr, gg, gb = TintColors(db.tint or "accent")
    local alpha = (db.panelAlpha or 96) / 100

    f.ground:SetGradientAlpha("VERTICAL",
        S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], alpha,
        S.BG_DARK[1] + 0.03, S.BG_DARK[2] + 0.03, S.BG_DARK[3] + 0.04, alpha * 0.94)
    f.line:SetGradientAlpha("HORIZONTAL", r, g, b, 0.1, r, g, b, 0.1)
    f.lineLeft:SetGradientAlpha("HORIZONTAL", r, g, b, 0.05, gr, gg, gb, 1)
    f.lineRight:SetGradientAlpha("HORIZONTAL", gr, gg, gb, 1, r, g, b, 0.05)
    f.halo:SetVertexColor(r, g, b, 0.35)
    self:PaintPanelStyle(alpha)
    for _, edge in ipairs(f.iconEdges) do edge:SetVertexColor(r, g, b, 0.9) end

    local showLogo = db.showLogo ~= false
    f.emblemShade:SetShown(showLogo)
    f.emblemGlow:SetShown(showLogo)
    f.emblem:SetShown(showLogo)
    if S.PaintEmblem then
        S.PaintEmblem(f.emblem, f.emblemGlow, 0.3)
        f.emblemShade:SetTexture(f.emblemGlow:GetTexture())
        S.PaintWordmark(f.word, f.wordText)
    else
        f.emblem:SetTexture(S.Media("LogoEmblem"))
        f.emblem:SetVertexColor(gr, gg, gb, 1)
        f.emblemGlow:SetTexture(S.Media("LogoEmblemGlow"))
        f.emblemGlow:SetVertexColor(gr, gg, gb, 0.3)
        f.word:SetTexture(S.Media("LogoText"))
        f.wordText:Hide()
    end
    if not showLogo then
        f.word:Hide()
        f.wordText:Hide()
    end

    local motto = S.BrandMotto and S.BrandMotto()
    if motto and S.Brand().mottoAFK ~= false then
        local _, _, _, mr, mg, mb = S.BrandColor()
        f.motto:SetText("\"" .. motto .. "\"")
        f.motto:SetTextColor(mr, mg, mb, 0.95)
        f.motto:Show()
    else
        f.motto:Hide()
    end

    local showInfo = db.showInfo ~= false
    f.icon:SetShown(showInfo)
    f.iconFrame:SetShown(showInfo)
    f.name:SetShown(showInfo)
    f.info:SetShown(showInfo)
    f.guild:SetShown(showInfo)

    local showClock = db.showClock ~= false
    f.clock:SetShown(showClock)
    f.day:SetShown(showClock)
    f.timer:SetShown(db.showTimer ~= false)
    f.hint:SetShown(db.showHint ~= false)
    f.tip:SetShown(db.tips ~= false)
end

function AFK:PaintPanelStyle(alpha)
    local f = self.frame
    local S = NS.Styling
    local db = Settings()
    local style = PANEL_STYLES[db.panelStyle or "narci"] or PANEL_STYLES.narci
    local bare = (db.layout or "bottom") == "minimal"

    if style.bg then
        local c = style.bg
        f.ground:SetGradientAlpha("VERTICAL", c[1], c[2], c[3], alpha, c[1] + 0.03, c[2] + 0.02, c[3] + 0.05, alpha * 0.94)
    end
    S.SkinBox(f.panel, (style.box and not bare) and style.box or "none", { alpha = alpha, edgeSize = 16 })

    local scene = style.scene and not bare and S.SceneArt(f.art, style.scene)
    if scene then
        f.art:SetVertexColor(1, 1, 1, alpha)
        f.art:Show()
    else
        f.art:Hide()
    end
    f.ground:SetShown(not bare and not style.box and not scene)

    local mark = style.mark
    if mark then
        local c = mark.color
        f.mark:SetTexture(S.Media(mark.file))
        f.mark:SetVertexColor(c[1], c[2], c[3], mark.alpha)
        f.mark:ClearAllPoints()
        f.mark:SetPoint("CENTER", f.emblemShade, "CENTER", 0, 0)
        f.mark:SetSize(PANEL_H * 2.2, PANEL_H * 2.2)
        f.mark:Show()
        if mark.spin and f.mark.SetRotation then
            local angle = 0
            f.panel:SetScript("OnUpdate", function(_, elapsed)
                angle = (angle + elapsed * mark.spin) % (math.pi * 2)
                f.mark:SetRotation(angle)
            end)
        end
    else
        f.mark:Hide()
        f.panel:SetScript("OnUpdate", nil)
    end
end

function AFK:Fill()
    local f = self.frame
    local db = Settings()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]

    f.name:SetText(UnitName("player") or "")
    if color then f.name:SetTextColor(color.r, color.g, color.b) end

    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
        f.icon:SetTexCoord(coords[1] + 0.015, coords[2] - 0.015, coords[3] + 0.015, coords[4] - 0.015)
    else
        f.icon:Hide()
    end

    f.info:SetText(string.format(L["%d уровень, %s, %s"], UnitLevel("player") or 0,
        UnitRace("player") or "", UnitClass("player") or ""))

    local guildName, rankName = GetGuildInfo("player")
    if guildName then
        f.guild:SetText("<" .. guildName .. ">  " .. (rankName or ""))
    else
        f.guild:SetText(L["Без гильдии"])
    end

    local custom = db.awayText
    if type(custom) == "string" and custom:match("%S") then
        f.away:SetText(custom)
    else
        f.away:SetText(L["Вы отошли"])
    end
end

function AFK:NextTip()
    local f = self.frame
    if not f then return end
    local index = math.random(#TIPS)
    if index == self.tipIndex and #TIPS > 1 then index = index % #TIPS + 1 end
    self.tipIndex = index
    self.tipTime = GetTime()
    f.tip:SetText(L[TIPS[index]])
end

function AFK:Tick()
    local f = self.frame
    if not f then return end
    f.timer:SetText(Clock(GetTime() - (self.startTime or GetTime())))
    f.clock:SetText(date("%H:%M"))
    f.day:SetText(date("%d.%m.%Y"))
    if GetTime() - (self.tipTime or 0) >= TIP_SECONDS then self:NextTip() end
end

function AFK:ChatLine(event, message, sender)
    local f = self.frame
    if not f or not message then return end
    local kind = event:sub(10)
    local info = ChatTypeInfo and ChatTypeInfo[kind]
    local r, g, b = 1, 1, 1
    if info then r, g, b = info.r, info.g, info.b end
    local who = sender and sender ~= "" and ("[" .. sender .. "]: ") or ""
    f.chat:AddMessage("|cff808080" .. date("%H:%M") .. "|r " .. who .. message, r, g, b)
end

function AFK:StartModel()
    local f = self.frame
    local db = Settings()
    local model = f.model
    model.anim = nil
    model:SetShown(db.model ~= false)
    if db.model == false then return end
    model:ClearModel()
    pcall(model.SetUnit, model, "player")
    pcall(model.SetFacing, model, -0.45)

    local anims = NS.NarciUI and NS.NarciUI.POSE_ANIMS
    local key = db.emote or "stand"
    if key == "random" and anims then
        local keys = {}
        for k in pairs(anims) do
            if k ~= "stand" then keys[#keys + 1] = k end
        end
        table.sort(keys)
        key = keys[math.random(#keys)]
    end
    local anim = anims and anims[key]
    if anim and anim > 0 then
        model.anim = anim
        model.animTime = 0
    end
end

function AFK:CanEnter()
    if not Enabled() or self.active then return false end
    if InCombatLockdown() then return false end
    if UnitCastingInfo and UnitCastingInfo("player") then return false end
    if CinematicFrame and CinematicFrame:IsShown() then return false end
    if MovieFrame and MovieFrame:IsShown() then return false end
    if NS.NarciUI and NS.NarciUI.isShown then return false end
    return true
end

function AFK:Enter(test)
    if not test and not self:CanEnter() then return end
    if self.active or InCombatLockdown() then return end

    local db = Settings()
    local f = self:Create()
    self.active = true
    self.test = test
    self.startTime = GetTime()

    self:Layout()
    self:Paint()
    self:Fill()
    self:NextTip()
    self:Tick()

    f:SetScale(UIParent:GetScale())
    f.chat:Clear()
    f.chat:SetShown(db.chat ~= false)
    if db.chat ~= false then
        for _, event in ipairs(CHAT_EVENTS) do f.chat:RegisterEvent(event) end
    end

    self:StartModel()

    self.uiAlpha = UIParent:GetAlpha()
    UIParent:SetAlpha(0)

    if db.spin ~= false and MoveViewLeftStart then
        pcall(MoveViewLeftStart, (db.spinSpeed or 4) / 100)
        self.spinning = true
    end

    f:SetAlpha(0)
    f:Show()
    if NS.Styling.FadeIn then NS.Styling.FadeIn(f, 0.6) else f:SetAlpha(1) end
end

function AFK:Leave(byKey)
    if not self.active then return end
    self.active = nil

    local f = self.frame
    if f then
        for _, event in ipairs(CHAT_EVENTS) do f.chat:UnregisterEvent(event) end
        f.model.anim = nil
        f:Hide()
    end

    UIParent:SetAlpha(self.uiAlpha or 1)

    if self.spinning and MoveViewLeftStop then
        pcall(MoveViewLeftStop)
        self.spinning = nil
    end

    if byKey and not self.test and NS.After then
        NS.After(60, function() AFK:Check() end)
    end
    self.test = nil
end

function AFK:Check()
    if UnitIsAFK("player") then
        if UnitCastingInfo and UnitCastingInfo("player") then
            if NS.After then NS.After(30, function() AFK:Check() end) end
            return
        end
        self:Enter(false)
    elseif not self.test then
        self:Leave(false)
    end
end

function AFK:Test()
    if self.active then
        self:Leave(false)
    else
        self:Enter(true)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_FLAGS_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("LFG_PROPOSAL_SHOW")
driver:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
driver:RegisterEvent("READY_CHECK")
driver:RegisterEvent("PLAYER_LEAVING_WORLD")
driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_FLAGS_CHANGED" then
        if arg1 == "player" then AFK:Check() end
        return
    end
    if event == "UPDATE_BATTLEFIELD_STATUS" then
        if arg1 and GetBattlefieldStatus and GetBattlefieldStatus(arg1) == "confirm" then AFK:Leave(false) end
        return
    end
    AFK:Leave(false)
end)
