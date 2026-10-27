local addonName, NS = ...
local L = NS.L

local M = NS.Messenger
if not M then return end

local WHITE = "Interface\\Buttons\\WHITE8x8"
local SIDE_W = 160
local ROW_H = 30
local MIN_W, MIN_H = 460, 260

local KIND_COLORS = {
    ["in"] = { 1.00, 0.50, 1.00 },
    out = { 0.85, 0.65, 1.00 },
    gm = { 0.25, 0.75, 1.00 },
    sys = { 1.00, 0.85, 0.30 },
    afk = { 0.75, 0.75, 0.80 },
    dnd = { 0.75, 0.75, 0.80 },
}

local DIALOG_BG_DARK = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local GOLD_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"

M.STYLE_ORDER = { "narci", "glass", "classic", "night", "dawn", "letter", "arcane" }

M.STYLES = {
    narci = { label = "NarciUI", native = true },
    glass = {
        label = "Стекло",
        bg = { 0.05, 0.06, 0.09, 0.55 },
        edge = "accent", edgeAlpha = 0.75,
        glow = "accent", glowAlpha = 0.35,
        side = { 0, 0, 0, 0.22 },
        row = { 1, 1, 1, 0.03 }, rowAlt = { 1, 1, 1, 0.07 },
        input = { 0, 0, 0, 0.35 },
        title = "accent",
    },
    classic = {
        label = "Клиент",
        pad = 14,
        backdrop = {
            bgFile = DIALOG_BG_DARK, edgeFile = GOLD_EDGE, tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        },
        art = { file = MARBLE, alpha = 0.22, inset = 11, aspect = 1 },
        side = { 0, 0, 0, 0.45 },
        row = { 0.2, 0.16, 0.08, 0.25 }, rowAlt = { 0.2, 0.16, 0.08, 0.45 },
        active = { 1, 0.82, 0, 0.2 }, bar = { 1, 0.82, 0 }, hover = { 1, 0.82, 0, 0.12 },
        input = { 0, 0, 0, 0.6 }, inputEdge = { 0.55, 0.45, 0.2 }, inputFocus = { 1, 0.82, 0 },
        title = { 1, 0.82, 0 }, dim = { 0.78, 0.72, 0.58 }, stamp = "a89a78",
    },
    night = {
        label = "Ночное небо",
        bg = { 0.02, 0.03, 0.08, 1 },
        art = { file = "MessengerNight", aspect = 2, anchor = "bottom" },
        edge = { 0.42, 0.46, 0.85 }, edgeAlpha = 0.8,
        glow = { 0.35, 0.4, 0.95 }, glowAlpha = 0.25,
        side = { 0.01, 0.01, 0.05, 0.55 },
        row = { 0.6, 0.65, 1, 0.04 }, rowAlt = { 0.6, 0.65, 1, 0.08 },
        active = { 0.55, 0.6, 1, 0.22 }, bar = { 0.75, 0.8, 1 }, hover = { 0.55, 0.6, 1, 0.12 },
        input = { 0.01, 0.01, 0.06, 0.7 }, inputEdge = { 0.3, 0.33, 0.6 }, inputFocus = { 0.7, 0.75, 1 },
        logGround = { 0, 0, 0.04, 0.2 },
        title = { 0.8, 0.84, 1 }, dim = { 0.66, 0.68, 0.85 }, stamp = "8f93c8",
        kinds = { ["in"] = { 0.98, 0.78, 1 }, out = { 0.76, 0.86, 1 } },
    },
    dawn = {
        label = "Рассвет",
        bg = { 0.12, 0.07, 0.14, 1 },
        art = { file = "ArtDawn", aspect = 2 },
        edge = { 0.9, 0.6, 0.5 }, edgeAlpha = 0.8,
        glow = { 1, 0.55, 0.4 }, glowAlpha = 0.2,
        side = { 0.06, 0.03, 0.08, 0.6 },
        row = { 1, 0.7, 0.6, 0.04 }, rowAlt = { 1, 0.7, 0.6, 0.08 },
        active = { 1, 0.6, 0.45, 0.24 }, bar = { 1, 0.75, 0.55 }, hover = { 1, 0.6, 0.45, 0.12 },
        input = { 0.05, 0.02, 0.07, 0.75 }, inputEdge = { 0.55, 0.35, 0.45 }, inputFocus = { 1, 0.75, 0.55 },
        logGround = { 0.03, 0.01, 0.05, 0.35 },
        title = { 1, 0.85, 0.7 }, dim = { 0.88, 0.74, 0.72 }, stamp = "c8a0a0",
        kinds = { ["in"] = { 1, 0.82, 0.95 }, out = { 0.8, 0.9, 1 } },
    },
    letter = {
        label = "Письмо",
        pad = 10,
        bg = { 0.2, 0.13, 0.06, 1 },
        art = { file = "MessengerParchment", aspect = 1 },
        edge = { 0.3, 0.18, 0.08 }, edgeAlpha = 1,
        seal = { file = "MessengerSeal", size = 58 },
        side = { 0.12, 0.07, 0.03, 0.45 },
        row = { 0.25, 0.15, 0.06, 0.18 }, rowAlt = { 0.25, 0.15, 0.06, 0.32 },
        active = { 0.65, 0.18, 0.12, 0.35 }, bar = { 0.85, 0.25, 0.18 }, hover = { 0.9, 0.7, 0.4, 0.12 },
        input = { 0.1, 0.06, 0.02, 0.55 }, inputEdge = { 0.45, 0.3, 0.15 }, inputFocus = { 0.9, 0.7, 0.4 },
        title = { 1, 0.86, 0.6 }, titleX = 38, dim = { 0.85, 0.74, 0.56 }, stamp = "c2a57a",
        kinds = {
            ["in"] = { 1, 0.9, 0.72 }, out = { 0.86, 0.93, 1 }, sys = { 1, 0.78, 0.4 },
            afk = { 0.85, 0.78, 0.66 }, dnd = { 0.85, 0.78, 0.66 },
        },
    },
    arcane = {
        label = "Аркана",
        bg = { 0.05, 0.02, 0.09, 0.96 },
        edge = { 0.62, 0.4, 1 }, edgeAlpha = 0.9,
        glow = { 0.55, 0.3, 1 }, glowAlpha = 0.4,
        mark = { file = "MessengerRunes", color = { 0.7, 0.5, 1 }, alpha = 0.2, scale = 0.95, spin = 0.04 },
        side = { 0.08, 0.03, 0.14, 0.6 },
        row = { 0.6, 0.4, 1, 0.04 }, rowAlt = { 0.6, 0.4, 1, 0.08 },
        active = { 0.6, 0.4, 1, 0.24 }, bar = { 0.85, 0.65, 1 }, hover = { 0.6, 0.4, 1, 0.14 },
        input = { 0.04, 0.01, 0.08, 0.8 }, inputEdge = { 0.4, 0.25, 0.65 }, inputFocus = { 0.8, 0.6, 1 },
        title = { 0.86, 0.72, 1 }, dim = { 0.7, 0.62, 0.85 }, stamp = "9a86c0",
        kinds = { ["in"] = { 0.96, 0.72, 1 }, out = { 0.72, 0.86, 1 } },
    },
}

function M:Style()
    local key = self:Settings().style
    return self.STYLES[key] or self.STYLES.narci
end

local function Accent(value, fallback)
    local S = NS.Styling
    if value == "accent" then return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3] end
    value = value or fallback
    return value[1], value[2], value[3], value[4]
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function ClassColor(contact)
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local color = contact and contact.class and colors and colors[contact.class]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.86, 0.9
end

local function Linkify(text)
    text = text:gsub("(%s?)(https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+)", function(space, url)
        return space .. "|cff6fb8ff|Hnarciurl:" .. url .. "|h[" .. url .. "]|h|r"
    end)
    text = text:gsub("(%s?)(www%.[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+)", function(space, url)
        return space .. "|cff6fb8ff|Hnarciurl:" .. url .. "|h[" .. url .. "]|h|r"
    end)
    return text
end

local function FormatEntry(contact, entry)
    local db = M:Settings()
    local style = M:Style()
    local stamp, kind, text = entry[1], entry[2], entry[3] or ""
    local kinds = style.kinds or KIND_COLORS
    local color = kinds[kind] or KIND_COLORS[kind] or KIND_COLORS["in"]
    local prefix = ""
    if db.timestamps then
        prefix = "|cff" .. (style.stamp or "8a8c94") .. date("%H:%M", stamp) .. "|r "
    end
    if kind == "sys" then
        return prefix .. Hex(color[1], color[2], color[3]) .. text .. "|r"
    end
    local who
    if kind == "out" then
        who = UnitName("player") or ""
    else
        who = contact.name or ""
    end
    local r, g, b
    if kind == "out" then
        local _, class = UnitClass("player")
        local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
        local c = class and colors and colors[class]
        if c then r, g, b = c.r, c.g, c.b else r, g, b = 1, 1, 1 end
    else
        r, g, b = ClassColor(contact)
    end
    local tag = ""
    if kind == "gm" then tag = "|cff40c0ff<GM>|r " end
    if kind == "afk" then tag = "|cffaaaaaa<" .. L["Отошёл"] .. ">|r " end
    if kind == "dnd" then tag = "|cffaaaaaa<" .. L["Не беспокоить"] .. ">|r " end
    local name = Hex(r, g, b) .. "|Hplayer:" .. who .. "|h" .. who .. "|h|r"
    return prefix .. tag .. name .. ": " .. Hex(color[1], color[2], color[3]) .. Linkify(text) .. "|r"
end

local function SortedContacts(filter)
    local list = {}
    local query = filter and filter ~= "" and NS.Lower(filter) or nil
    for key, contact in pairs(M:Contacts()) do
        if not query or NS.Lower(contact.name or key):find(query, 1, true) then
            list[#list + 1] = { key = key, contact = contact }
        end
    end
    table.sort(list, function(a, b)
        local ua, ub = (a.contact.unread or 0) > 0, (b.contact.unread or 0) > 0
        if ua ~= ub then return ua end
        return (a.contact.last or 0) > (b.contact.last or 0)
    end)
    return list
end

local urlBox

local function ShowURL(url)
    local S = NS.Styling
    if not urlBox then
        local f = CreateFrame("Frame", "NarciSirus_MessengerURL", UIParent)
        f:SetSize(420, 70)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        f:SetBackdropColor(S.Bg(0.97))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        f:EnableMouse(true)
        S.CreateShadow(f, 5, 0.4)
        local title = f:CreateFontString(nil, "OVERLAY")
        title:SetFont(NS.FONT, NS.FS(11), "")
        title:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
        title:SetText(L["Скопируйте ссылку: Ctrl+C"])
        local box = NS.Widgets.CreateThemedEditBox(f, 400, 22, 500)
        box:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
        box:SetScript("OnEscapePressed", function() f:Hide() end)
        box:SetScript("OnEnterPressed", function() f:Hide() end)
        box:SetScript("OnTextChanged", function(self, user)
            if user and f.url then
                self:SetText(f.url)
                self:HighlightText()
            end
        end)
        local close = NS.Widgets.CreateCloseButton(f, 16, function() f:Hide() end)
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
        f.box = box
        tinsert(UISpecialFrames, "NarciSirus_MessengerURL")
        urlBox = f
    end
    urlBox.url = url
    urlBox:Show()
    urlBox.box:SetText(url)
    urlBox.box:SetFocus()
    urlBox.box:HighlightText()
end

function M:BuildWindow()
    if self.frame then return self.frame end
    local S = NS.Styling
    local db = self:Settings()

    local f = CreateFrame("Frame", "NarciSirus_Messenger", UIParent)
    f:SetSize(math.max(db.width or 600, MIN_W), math.max(db.height or 380, MIN_H))
    if db.point then
        f:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    end
    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetMinResize(MIN_W, MIN_H)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        local store = M:Settings()
        store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
    end)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    f:SetBackdropColor(S.Bg((db.alpha or 95) / 100))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 6, 0.45)
    local topBorder = S.CreateGradientTopBorder(f)
    f:Hide()

    local base = f:GetFrameLevel()
    local skin = CreateFrame("Frame", nil, f)
    skin:SetAllPoints(f)
    skin:SetFrameLevel(base + 1)
    skin.bg = skin:CreateTexture(nil, "BACKGROUND")
    skin.bg:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
    skin.bg:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
    skin.bg:SetTexture(WHITE)
    skin.art = skin:CreateTexture(nil, "BORDER")
    skin.mark = skin:CreateTexture(nil, "ARTWORK")
    skin.edges = S.CreateEdges(skin, "OVERLAY", 1, 1, 1, 1)
    skin.glow = S.GlowPieces(skin, 10, "BACKGROUND", "ADD", true)

    local head = CreateFrame("Frame", nil, f)
    head:SetAllPoints(f)
    head:SetFrameLevel(base + 6)
    skin.seal = head:CreateTexture(nil, "OVERLAY")

    local title = head:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    title:SetText(L["Сообщения"])

    local close = NS.Widgets.CreateCloseButton(f, 18, function() M:Hide() end)
    close:SetFrameLevel(base + 7)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -7)

    local side = CreateFrame("Frame", nil, f)
    side:SetFrameLevel(base + 3)
    side:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -34)
    side:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
    side:SetWidth(SIDE_W)
    local sideGround = side:CreateTexture(nil, "BACKGROUND")
    sideGround:SetAllPoints(side)
    sideGround:SetTexture(WHITE)
    sideGround:SetVertexColor(S.Tint(0.02, 0.022, 0.03, 0.6))

    local search = NS.Widgets.CreateThemedEditBox(side, SIDE_W - 8, 20, 30)
    search:SetPoint("TOP", side, "TOP", 0, -4)
    search:SetScript("OnTextChanged", function() M:RefreshList() end)
    local hint = search:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("LEFT", search, "LEFT", 7, 0)
    hint:SetText(L["Поиск"])
    search:HookScript("OnEditFocusGained", function() hint:Hide() end)
    search:HookScript("OnEditFocusLost", function(self) hint:SetShown((self:GetText() or "") == "") end)

    local list = CreateFrame("Frame", nil, side)
    list:SetPoint("TOPLEFT", side, "TOPLEFT", 0, -28)
    list:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 30)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        M.listOffset = math.max(0, (M.listOffset or 0) - delta)
        M:RefreshList()
    end)

    local newButton = NS.Widgets.CreateThemedButton(side, L["Написать..."], SIDE_W - 8, 22, function()
        M:AskName()
    end)
    newButton:SetPoint("BOTTOM", side, "BOTTOM", 0, 4)

    local main = CreateFrame("Frame", nil, f)
    main:SetFrameLevel(base + 3)
    main:SetPoint("TOPLEFT", side, "TOPRIGHT", 8, 0)
    main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

    local nameText = main:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(NS.FONT, NS.FS(14), "OUTLINE")
    nameText:SetPoint("TOPLEFT", main, "TOPLEFT", 4, -4)
    nameText:SetJustifyH("LEFT")

    local infoText = main:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(NS.FONT, NS.FS(10), "")
    infoText:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
    infoText:SetPoint("RIGHT", main, "RIGHT", -4, 0)
    infoText:SetJustifyH("LEFT")

    local actions = {}
    local function Action(label, width, fn, tip)
        local button = NS.Widgets.CreateThemedButton(main, label, width, 18, function()
            local contact = M:ActiveContact()
            if contact then fn(contact) end
        end)
        if tip then
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        local previous = actions[#actions]
        if previous then
            button:SetPoint("RIGHT", previous, "LEFT", -4, 0)
        else
            button:SetPoint("TOPRIGHT", main, "TOPRIGHT", -2, -4)
        end
        actions[#actions + 1] = button
        return button
    end
    Action(L["Очистить"], 70, function(contact)
        NS.Widgets.ShowConfirm(L["Удалить всю переписку с этим игроком?"], L["Удалить"], function()
            M:Remove(contact.name)
        end)
    end)
    Action(L["Игнор"], 56, function(contact)
        if AddOrDelIgnore then AddOrDelIgnore(contact.name) elseif AddIgnore then AddIgnore(contact.name) end
    end, L["Добавить в список игнорирования или убрать из него"])
    Action(L["Кто"], 44, function(contact)
        if SendWho then SendWho('n-"' .. contact.name .. '"') end
    end, L["Запросить уровень, класс и зону через /кто"])
    Action(L["В друзья"], 70, function(contact)
        if AddFriend then AddFriend(contact.name) end
    end)
    Action(L["Пригласить"], 80, function(contact)
        if InviteUnit then InviteUnit(contact.name) end
    end)

    local log = CreateFrame("ScrollingMessageFrame", nil, main)
    log:SetPoint("TOPLEFT", main, "TOPLEFT", 4, -40)
    log:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -4, 34)
    local logGround = main:CreateTexture(nil, "BACKGROUND")
    logGround:SetPoint("TOPLEFT", log, "TOPLEFT", -4, 4)
    logGround:SetPoint("BOTTOMRIGHT", log, "BOTTOMRIGHT", 4, -4)
    logGround:SetTexture(WHITE)
    logGround:Hide()
    log:SetFont(NS.FONT, NS.FS(db.fontSize or 12), "")
    log:SetJustifyH("LEFT")
    log:SetFading(false)
    log:SetMaxLines(math.max((db.keepCount or 300) + 20, 100))
    if log.SetHyperlinksEnabled then log:SetHyperlinksEnabled(true) end
    log:EnableMouseWheel(true)
    log:SetScript("OnMouseWheel", function(self, delta)
        if IsShiftKeyDown() then
            if delta > 0 then self:ScrollToTop() else self:ScrollToBottom() end
        elseif delta > 0 then
            self:ScrollUp()
            self:ScrollUp()
        else
            self:ScrollDown()
            self:ScrollDown()
        end
        M:UpdateBottom()
    end)
    log:SetScript("OnHyperlinkClick", function(self, link, text, button)
        local url = link:match("^narciurl:(.+)$")
        if url then
            ShowURL(url)
            return
        end
        SetItemRef(link, text, button, self)
    end)
    log:SetScript("OnHyperlinkEnter", function(self, link)
        if link:match("^item:") or link:match("^spell:") or link:match("^achievement:") or link:match("^enchant:") or link:match("^quest:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            GameTooltip:Show()
        end
    end)
    log:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

    local bottom = CreateFrame("Button", nil, main)
    bottom:SetSize(18, 18)
    bottom:SetPoint("BOTTOMRIGHT", log, "BOTTOMRIGHT", 0, 2)
    local bottomIcon = bottom:CreateTexture(nil, "ARTWORK")
    bottomIcon:SetAllPoints(bottom)
    bottomIcon:SetTexture(S.Media("IconDown"))
    bottomIcon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    bottom:SetScript("OnClick", function()
        log:ScrollToBottom()
        M:UpdateBottom()
    end)
    bottom:Hide()

    local input = CreateFrame("EditBox", "NarciSirus_MessengerInput", main)
    input:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 0, 2)
    input:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", 0, 2)
    input:SetHeight(24)
    input:SetAutoFocus(false)
    input:SetMaxLetters(1000)
    input:SetFont(NS.FONT, NS.FS(12), "")
    input:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    input:SetTextInsets(8, 8, 0, 0)
    input:SetAltArrowKeyMode(false)
    input:SetHistoryLines(30)
    local inputGround = input:CreateTexture(nil, "BACKGROUND")
    inputGround:SetAllPoints(input)
    inputGround:SetTexture(WHITE)
    inputGround:SetVertexColor(S.Tint(0.02, 0.02, 0.04, 0.9))
    local inputEdges = S.CreateEdges(input, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    input:SetScript("OnEditFocusGained", function() M:PaintInput(true) end)
    input:SetScript("OnEditFocusLost", function() M:PaintInput(false) end)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function(self)
        local contact = M:ActiveContact()
        local text = self:GetText() or ""
        if contact and text ~= "" then
            self:AddHistoryLine(text)
            M:Send(contact.name, text)
        end
        self:SetText("")
    end)
    input:SetScript("OnTabPressed", function()
        M:CycleContact(IsShiftKeyDown() and -1 or 1)
    end)

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(f:GetFrameLevel() + 10)
    local gripTexture = grip:CreateTexture(nil, "OVERLAY")
    gripTexture:SetAllPoints(grip)
    gripTexture:SetTexture(WHITE)
    gripTexture:SetGradientAlpha("HORIZONTAL", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        local store = M:Settings()
        store.width, store.height = math.floor(f:GetWidth() + 0.5), math.floor(f:GetHeight() + 0.5)
        local point, _, relativePoint, x, y = f:GetPoint()
        store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
        M:RefreshList()
    end)

    f:SetScript("OnSizeChanged", function()
        M:FitArt()
        M:RefreshList()
    end)
    log:HookScript("OnSizeChanged", function() M:FitArt() end)
    f:SetScript("OnShow", function() M:UpdateButton() end)
    f:SetScript("OnHide", function()
        input:ClearFocus()
        M:UpdateButton()
    end)

    tinsert(UISpecialFrames, "NarciSirus_Messenger")

    f.list, f.rows, f.search = list, {}, search
    f.nameText, f.infoText, f.log, f.bottom = nameText, infoText, log, bottom
    f.actions = actions
    f.skin, f.head, f.title, f.close, f.side, f.main = skin, head, title, close, side, main
    f.sideGround, f.logGround, f.inputGround, f.inputEdges = sideGround, logGround, inputGround, inputEdges
    f.newButton, f.topBorder = newButton, topBorder
    f.preview = {}
    self.input = input
    self.frame = f
    self:ApplyStyle()
    return f
end

function M:Row(index)
    local f = self.frame
    local row = f.rows[index]
    if row then return row end
    local S = NS.Styling
    row = CreateFrame("Button", nil, f.list)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", f.list, "TOPLEFT", 2, -(index - 1) * (ROW_H + 2))
    row:SetPoint("TOPRIGHT", f.list, "TOPRIGHT", -2, -(index - 1) * (ROW_H + 2))
    row:RegisterForClicks("AnyUp")
    local ground = row:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(row)
    ground:SetTexture(WHITE)
    local bar = row:CreateTexture(nil, "BORDER")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(6, 6)
    dot:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -7)
    dot:SetTexture(S.Media("RoundFill"))
    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("TOPLEFT", row, "TOPLEFT", 17, -3)
    name:SetPoint("RIGHT", row, "RIGHT", -26, 0)
    name:SetJustifyH("LEFT")
    local preview = row:CreateFontString(nil, "OVERLAY")
    preview:SetFont(NS.FONT, NS.FS(9), "")
    preview:SetTextColor(Accent(self:Style().dim, S.TEXT_DIM))
    preview:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 17, 3)
    preview:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    preview:SetJustifyH("LEFT")
    local badge = row:CreateFontString(nil, "OVERLAY")
    badge:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    badge:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    badge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -4)
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row)
    hover:SetTexture(WHITE)
    local style = self:Style()
    if style.hover then
        hover:SetVertexColor(Accent(style.hover))
    else
        hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
    end
    row:SetScript("OnClick", function(self, button)
        if not self.key then return end
        if button == "RightButton" then
            local contact = M:Contacts()[self.key]
            if contact then
                NS.Widgets.ShowConfirm(L["Удалить всю переписку с этим игроком?"], L["Удалить"], function()
                    M:Remove(contact.name)
                end)
            end
            return
        end
        M:Select(self.key)
    end)
    row.ground, row.bar, row.dot, row.name, row.preview, row.badge, row.hover = ground, bar, dot, name, preview, badge, hover
    f.rows[index] = row
    return row
end

local function Preview(contact)
    local last = contact.messages and contact.messages[#contact.messages]
    if not last then return "" end
    local text = (last[3] or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
    if last[2] == "out" then text = L["Вы"] .. ": " .. text end
    return text
end

function M:RefreshList()
    local f = self.frame
    if not f or not f:IsShown() then return end
    local S = NS.Styling
    local style = self:Style()
    local entries = SortedContacts(f.search:GetText())
    local height = f.list:GetHeight() or 0
    local visible = math.max(1, math.floor(height / (ROW_H + 2)))
    local maxOffset = math.max(0, #entries - visible)
    self.listOffset = math.min(self.listOffset or 0, maxOffset)

    for index = 1, visible do
        local row = self:Row(index)
        local item = entries[index + self.listOffset]
        if item then
            local contact = item.contact
            row.key = item.key
            row.name:SetText(contact.name or item.key)
            row.name:SetTextColor(ClassColor(contact))
            row.preview:SetText(Preview(contact))
            local unread = contact.unread or 0
            row.badge:SetText(unread > 0 and unread or "")
            if contact.online == true then
                row.dot:SetVertexColor(0.3, 0.9, 0.4, 1)
            elseif contact.online == false then
                row.dot:SetVertexColor(0.5, 0.5, 0.55, 1)
            else
                row.dot:SetVertexColor(0.8, 0.75, 0.3, 0.8)
            end
            local active = item.key == self.active
            row.bar:SetShown(active)
            if style.bar then
                row.bar:SetVertexColor(Accent(style.bar))
            else
                row.bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
            end
            row.preview:SetTextColor(Accent(style.dim, S.TEXT_DIM))
            if style.hover then
                row.hover:SetVertexColor(Accent(style.hover))
            else
                row.hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
            end
            if active then
                if style.active then
                    row.ground:SetVertexColor(Accent(style.active))
                else
                    row.ground:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
                end
            elseif style.row then
                row.ground:SetVertexColor(Accent(index % 2 == 0 and style.rowAlt or style.row))
            else
                row.ground:SetVertexColor(S.Tint(0.03, 0.035, 0.05, index % 2 == 0 and 0.55 or 0.3))
            end
            row:Show()
        else
            row.key = nil
            row:Hide()
        end
    end
    for index = visible + 1, #f.rows do f.rows[index]:Hide() end
end

function M:ActiveContact()
    return self.active and self:Contacts()[self.active]
end

function M:RefreshHeader()
    local f = self.frame
    local contact = self:ActiveContact()
    if not contact then
        f.nameText:SetText(L["Нет переписки"])
        f.nameText:SetTextColor(0.6, 0.6, 0.65)
        f.infoText:SetText(L["Шёпот появится здесь. Чтобы написать, нажмите Написать... или R."])
        for _, button in ipairs(f.actions) do button:Hide() end
        return
    end
    for _, button in ipairs(f.actions) do button:Show() end
    f.nameText:SetText(contact.name or "")
    f.nameText:SetTextColor(ClassColor(contact))
    local parts = {}
    if contact.level then parts[#parts + 1] = L["уровень"] .. " " .. contact.level end
    if contact.race then parts[#parts + 1] = contact.race end
    if contact.class then
        local localized = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[contact.class]) or contact.class
        parts[#parts + 1] = localized
    end
    if contact.guild then parts[#parts + 1] = "<" .. contact.guild .. ">" end
    if contact.zone and contact.zone ~= "" then parts[#parts + 1] = contact.zone end
    if contact.gm then parts[#parts + 1] = "|cff40c0ffGM|r" end
    f.infoText:SetText(table.concat(parts, "  "))
end

function M:RefreshLog()
    local f = self.frame
    f.log:Clear()
    local contact = self:ActiveContact()
    if contact then
        for _, entry in ipairs(contact.messages or {}) do
            f.log:AddMessage(FormatEntry(contact, entry))
        end
    end
    f.log:ScrollToBottom()
    self:UpdateBottom()
end

function M:UpdateBottom()
    local f = self.frame
    if not f then return end
    f.bottom:SetShown(not f.log:AtBottom())
end

function M:Select(key, focus)
    self.active = key
    local contact = self:ActiveContact()
    if contact then contact.unread = 0 end
    self:RefreshHeader()
    self:RefreshLog()
    self:RefreshList()
    self:UpdateButton()
    if focus then self.input:SetFocus() end
end

function M:CycleContact(step)
    local entries = SortedContacts(self.frame.search:GetText())
    if #entries == 0 then return end
    local position = 1
    for index, item in ipairs(entries) do
        if item.key == self.active then position = index break end
    end
    position = ((position - 1 + step) % #entries) + 1
    self:Select(entries[position].key, true)
end

function M:Show(name, focus)
    local f = self:BuildWindow()
    local key
    if name then
        local contact
        contact, key = self:Contact(name, true)
        if contact and not contact.name then contact.name = name end
    end
    if not key and not self.active then
        local entries = SortedContacts()
        key = entries[1] and entries[1].key
    end
    f:Show()
    self:Select(key or self.active, focus)
end

function M:Hide()
    if self.frame then self.frame:Hide() end
end

function M:Toggle()
    if self:IsOpen() then self:Hide() else self:Show() end
end

function M:SetInput(text)
    if self.input then
        self.input:SetText(text)
        self.input:SetFocus()
    end
end

function M:AskName()
    local f = self.frame
    if not f then return end
    if not f.ask then
        local S = NS.Styling
        local ask = CreateFrame("Frame", nil, f)
        ask:SetSize(SIDE_W, 50)
        ask:SetPoint("BOTTOMLEFT", f.side, "BOTTOMLEFT", 0, 28)
        ask:SetFrameLevel(f:GetFrameLevel() + 20)
        ask:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        ask:SetBackdropColor(S.Bg(0.98))
        ask:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.8)
        local label = ask:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "")
        label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        label:SetPoint("TOPLEFT", ask, "TOPLEFT", 6, -5)
        label:SetText(L["Имя игрока и Enter"])
        local box = NS.Widgets.CreateThemedEditBox(ask, SIDE_W - 12, 20, 40)
        box:SetPoint("BOTTOM", ask, "BOTTOM", 0, 5)
        box:SetScript("OnEnterPressed", function(self)
            local name = (self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
            self:SetText("")
            ask:Hide()
            if name ~= "" then M:Show(name, true) end
        end)
        box:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            ask:Hide()
        end)
        ask.box = box
        f.ask = ask
    end
    f.ask:Show()
    f.ask.box:SetFocus()
end

function M:OnChanged(contact, entry)
    local f = self.frame
    if f and f:IsShown() then
        if contact and entry and self.active and self:Contacts()[self.active] == contact then
            local atBottom = f.log:AtBottom()
            f.log:AddMessage(FormatEntry(contact, entry))
            if atBottom then f.log:ScrollToBottom() end
            self:UpdateBottom()
            self:RefreshHeader()
        elseif self.active and not self:Contacts()[self.active] then
            self.active = nil
            self:RefreshHeader()
            self:RefreshLog()
        end
        self:RefreshList()
    end
    self:UpdateButton()
end

function M:BuildButton()
    if self.button then return self.button end
    local S = NS.Styling
    local db = self:Settings()

    local button = CreateFrame("Button", "NarciSirus_MessengerButton", UIParent)
    button:SetSize(34, 34)
    button:SetFrameStrata("MEDIUM")
    if db.buttonPoint then
        button:SetPoint(db.buttonPoint, UIParent, db.buttonRelative or db.buttonPoint, db.buttonX or 0, db.buttonY or 0)
    else
        button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 470, 200)
    end
    button:RegisterForClicks("AnyUp")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
    icon:SetTexture(S.Media("MicroSocial"))
    local count = button:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    local glow = S.GlowPieces(button, 6, "BACKGROUND", "ADD", true)

    button:SetScript("OnClick", function() M:Toggle() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Сообщения"], 1, 1, 1)
        local unread = M:Unread()
        if unread > 0 then GameTooltip:AddLine(L["Непрочитанных"] .. ": " .. unread, 1, 0.82, 0) end
        GameTooltip:AddLine(L["Клик - открыть или закрыть окно"], 0.7, 0.7, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local pulse = 0
    button:SetScript("OnUpdate", function(self, elapsed)
        if not self.flashing then return end
        pulse = pulse + elapsed
        local alpha = 0.35 + 0.35 * math.sin(pulse * 4)
        for _, texture in ipairs(glow) do texture:SetAlpha(alpha) end
    end)

    if NS.Movers then
        NS.Movers:Register(button, L["Сообщения"], function(point, relativePoint, x, y)
            local store = M:Settings()
            store.buttonPoint, store.buttonRelative, store.buttonX, store.buttonY = point, relativePoint, x, y
        end, "chat")
    end

    button.icon, button.count, button.glow = icon, count, glow
    self.button = button
    self:StyleButton()
    self:UpdateButton()
    return button
end

function M:StyleButton()
    local button = self.button
    if not button then return end
    local db = self:Settings()
    local size = db.buttonSize or 34
    button:SetSize(size, size)
    NS.Styling.SkinBox(button, db.buttonStyle or "flat", { alpha = 0.85 })
    local inset = math.floor(size * 0.15 + 0.5)
    button.icon:ClearAllPoints()
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
end

function M:UpdateButton()
    local button = self.button
    if not button then return end
    local S = NS.Styling
    local db = self:Settings()
    local unread = self:Unread()
    button:SetShown(db.showButton ~= false and self:Enabled())
    button.count:SetText(unread > 0 and unread or "")
    local lit = unread > 0 and not self:IsOpen()
    button.flashing = lit
    for _, texture in ipairs(button.glow) do
        texture:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        texture:SetShown(lit)
    end
    if lit then
        button.icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    else
        button.icon:SetVertexColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end
end

function M:PrepareMove()
    if self:Enabled() then self:BuildButton():Show() end
end

local function NativeChrome(f, on)
    local list = {}
    local decor = f.narciDecor
    if decor then
        list[#list + 1] = decor.shade
        list[#list + 1] = decor.sheen
        for _, t in ipairs(decor.corners or {}) do list[#list + 1] = t end
    end
    local top = f.topBorder
    if top then
        list[#list + 1] = top
        list[#list + 1] = top.crest
        list[#list + 1] = top.pattern
        list[#list + 1] = top.glow
    end
    for _, t in pairs(list) do
        if t.narciMsgAlpha == nil then t.narciMsgAlpha = t:GetAlpha() end
        t:SetAlpha(on and t.narciMsgAlpha or 0)
    end
    if decor and decor.pattern then
        if on then decor.pattern:Show() else decor.pattern:Hide() end
    end
end

function M:FitArt()
    local f = self.frame
    if not f then return end
    local style = self:Style()
    local skin = f.skin
    local art = style.art
    if art and art.aspect then
        local w, h = skin.art:GetWidth() or 0, skin.art:GetHeight() or 0
        if w > 0 and h > 0 then
            local ratio = w / h
            if ratio > art.aspect then
                local v = art.aspect / ratio
                local top = art.anchor == "bottom" and (1 - v) or (1 - v) / 2
                skin.art:SetTexCoord(0, 1, top, top + v)
            else
                local u = ratio / art.aspect
                skin.art:SetTexCoord((1 - u) / 2, (1 + u) / 2, 0, 1)
            end
        end
    end
    local mark = style.mark
    if mark then
        local size = math.min(f.log:GetWidth() or 0, f.log:GetHeight() or 0) * (mark.scale or 0.9)
        skin.mark:SetSize(math.max(size, 1), math.max(size, 1))
    end
end

function M:PaintInput(focused)
    local f = self.frame
    if not f then return end
    local S = NS.Styling
    local style = self:Style()
    local r, g, b
    if focused then
        r, g, b = Accent(style.inputFocus, S.ACCENT)
    else
        r, g, b = Accent(style.inputEdge, S.BORDER)
    end
    for _, line in ipairs(f.inputEdges) do line:SetVertexColor(r, g, b, 0.9) end
end

function M:ApplyStyle()
    local f = self.frame
    if not f then return end
    local S = NS.Styling
    local db = self:Settings()
    local style = self:Style()
    local skin = f.skin
    local opacity = (db.alpha or 95) / 100
    local native = style.native

    NativeChrome(f, native)
    if native then
        f:SetBackdropColor(S.Bg(opacity))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        skin:Hide()
    else
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0, 0, 0, 0)
        skin:Show()
    end

    skin:SetBackdrop(style.backdrop)
    if style.backdrop then skin:SetBackdropColor(1, 1, 1, opacity) end

    if style.bg then
        local r, g, b, a = Accent(style.bg)
        skin.bg:SetVertexColor(r, g, b, (a or 1) * opacity)
        skin.bg:Show()
    else
        skin.bg:Hide()
    end

    local art = style.art
    if art then
        local inset = art.inset or 1
        skin.art:ClearAllPoints()
        skin.art:SetPoint("TOPLEFT", skin, "TOPLEFT", inset, -inset)
        skin.art:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -inset, inset)
        skin.art:SetTexture(S.Media(art.file))
        skin.art:SetVertexColor(1, 1, 1, (art.alpha or 1) * (db.artAlpha or 100) / 100 * opacity)
        skin.art:Show()
    else
        skin.art:Hide()
    end

    local mark = style.mark
    if mark then
        local c = mark.color or { 1, 1, 1 }
        skin.mark:ClearAllPoints()
        skin.mark:SetPoint("CENTER", f.log, "CENTER", 0, 0)
        skin.mark:SetTexture(S.Media(mark.file))
        skin.mark:SetBlendMode("ADD")
        skin.mark:SetVertexColor(c[1], c[2], c[3], (mark.alpha or 0.2) * (db.artAlpha or 100) / 100)
        skin.mark:Show()
    else
        skin.mark:Hide()
    end
    if mark and mark.spin and skin.mark.SetRotation then
        local angle = 0
        skin:SetScript("OnUpdate", function(_, elapsed)
            angle = (angle + elapsed * mark.spin) % (math.pi * 2)
            skin.mark:SetRotation(angle)
        end)
    else
        skin:SetScript("OnUpdate", nil)
        if skin.mark.SetRotation then skin.mark:SetRotation(0) end
    end

    if style.edge and not style.backdrop then
        local r, g, b = Accent(style.edge)
        for _, line in ipairs(skin.edges) do
            line:SetVertexColor(r, g, b, style.edgeAlpha or 1)
            line:Show()
        end
    else
        for _, line in ipairs(skin.edges) do line:Hide() end
    end

    if style.glow then
        local r, g, b = Accent(style.glow)
        for _, t in ipairs(skin.glow) do
            t:SetVertexColor(r, g, b, style.glowAlpha or 0.3)
            t:Show()
        end
    else
        for _, t in ipairs(skin.glow) do t:Hide() end
    end

    local seal = style.seal
    if seal then
        skin.seal:SetTexture(S.Media(seal.file))
        skin.seal:SetSize(seal.size, seal.size)
        skin.seal:ClearAllPoints()
        skin.seal:SetPoint("CENTER", f, "TOPLEFT", seal.size * 0.22, -seal.size * 0.22)
        skin.seal:SetVertexColor(1, 1, 1, 1)
        skin.seal:Show()
    else
        skin.seal:Hide()
    end

    local pad = style.pad or 8
    f.title:ClearAllPoints()
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", pad + 4 + (style.titleX or 0), -(pad + 2))
    f.title:SetTextColor(Accent(style.title, S.ACCENT_GLOW))
    f.close:ClearAllPoints()
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -pad, -(pad - 1))
    f.side:ClearAllPoints()
    f.side:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -(pad + 26))
    f.side:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", pad, pad)
    f.main:ClearAllPoints()
    f.main:SetPoint("TOPLEFT", f.side, "TOPRIGHT", 8, 0)
    f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -pad, pad)

    if style.side then
        f.sideGround:SetVertexColor(Accent(style.side))
    else
        f.sideGround:SetVertexColor(S.Tint(0.02, 0.022, 0.03, 0.6))
    end
    if style.input then
        f.inputGround:SetVertexColor(Accent(style.input))
    else
        f.inputGround:SetVertexColor(S.Tint(0.02, 0.02, 0.04, 0.9))
    end
    if style.logGround then
        f.logGround:SetVertexColor(Accent(style.logGround))
        f.logGround:Show()
    else
        f.logGround:Hide()
    end
    f.infoText:SetTextColor(Accent(style.dim, S.TEXT_DIM))
    self:PaintInput(self.input and self.input:HasFocus())
    self:FitArt()
end

function M:ApplyLook()
    self:StyleButton()
    local f = self.frame
    if not f then return end
    local db = self:Settings()
    self:ApplyStyle()
    self:StyleButton()
    f.log:SetFont(NS.FONT, NS.FS(db.fontSize or 12), "")
    self:RefreshHeader()
    self:RefreshLog()
    self:RefreshList()
    self:UpdateButton()
end
