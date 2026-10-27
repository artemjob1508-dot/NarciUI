local addonName, NS = ...
local L = NS.L

local ChatSkin = {}
NS.ChatSkin = ChatSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local MAX_FRAMES = 10

local function FillSettings()
    if not NS.db then return end

    if not NS.db.chat then NS.db.chat = {} end

    local db = NS.db.chat
    if db.enabled == nil then db.enabled = false end
    if db.hideButtons == nil then db.hideButtons = true end
    if db.plainTabs == nil then db.plainTabs = true end
    db.fontSize = db.fontSize or 12
    if db.panel == nil then db.panel = true end
    if db.editTop == nil then db.editTop = true end
    db.editPos = db.editPos or (db.editTop == false and "bottom" or "top")
    db.panelAlpha = db.panelAlpha or 60
    if db.fade == nil then db.fade = true end
    db.fadeTime = db.fadeTime or 120
    if db.hideTabs == nil then db.hideTabs = false end
    db.font = db.font or "default"
    if db.outline == nil then db.outline = false end
    if db.shortChannels == nil then db.shortChannels = false end
    if db.links == nil then db.links = true end
    if db.hoverItems == nil then db.hoverItems = true end
    if db.hoverGroups == nil then db.hoverGroups = true end
    db.style = db.style or "panel"

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.chat
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local FONTS = {
    default = "Fonts\\FRIZQT__.TTF",
    narrow = "Fonts\\ARIALN.TTF",
    pt = "PTSansNarrow.ttf",
}

local function ChatFont(key)
    local path = FONTS[key] or FONTS.default
    if not path:find("\\", 1, true) then path = NS.OwnFont(path) end
    return path
end

ChatSkin.FONTS = FONTS

local LINK_COLOR = "|cff5fb4ff"

local function WrapLink(word)
    local lead, body, tail = word:match("^([%(%[\"']*)(.-)([%)%]\"'%.,!%?;:]*)$")
    if not body or body == "" then return nil end

    local lower = body:lower()
    local isLink = lower:match("^https?://") or lower:match("^www%.[%w%-]")
        or lower:match("^discord%.gg/") or lower:match("^[%w%-]+%.[%a][%a][%a]?/")

    if not isLink then return nil end

    ChatSkin:HookLinks()
    return lead .. LINK_COLOR .. "|Hnarciurl:" .. body .. "|h[" .. body .. "]|h|r" .. tail
end

local function Transform(text)
    local db = Settings()
    if type(text) ~= "string" or not db then return text end

    if db.shortChannels then
        text = text:gsub("(|Hchannel:[^|]+|h)%[(%d+)%.[^%]]*%](|h)", "%1[%2]%3")
    end

    if db.links and text:find("[%w%-]%.[%a][%a]") then
        text = text:gsub("(%S+)", function(word)
            if word:find("|", 1, true) then return nil end
            return WrapLink(word)
        end)
    end

    return text
end

function ChatSkin:ShowLink(url)
    local S = NS.Styling
    local box = self.linkBox

    if not box then
        box = CreateFrame("Frame", "NarciSirus_LinkCopy", UIParent)
        box:SetFrameStrata("DIALOG")
        box:SetSize(440, 76)
        box:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
        box:EnableMouse(true)

        local ground = box:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(box)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(0.02, 0.022, 0.032, 0.97)
        S.CreateEdges(box, "BORDER", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
        if S.CreateSoftShadow then S.CreateSoftShadow(box, 8, 0.5) end

        local title = box:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(title, "chat", NS.FS(12), "")
        title:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -10)
        title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        title:SetText(L["Ссылка: Ctrl+C - скопировать, Esc - закрыть"])

        local edit = CreateFrame("EditBox", nil, box)
        edit:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -32)
        edit:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -12, 12)
        edit:SetAutoFocus(false)
        NS.LSetFont(edit, "chat", NS.FS(13), "")
        edit:SetTextInsets(8, 8, 0, 0)

        local field = edit:CreateTexture(nil, "BACKGROUND")
        field:SetAllPoints(edit)
        field:SetTexture(WHITE)
        field:SetVertexColor(0.05, 0.055, 0.08, 1)

        edit:SetScript("OnEscapePressed", function() box:Hide() end)
        edit:SetScript("OnEnterPressed", function() box:Hide() end)
        edit:SetScript("OnTextChanged", function(self, user)
            if user and box.url then
                self:SetText(box.url)
                self:HighlightText()
            end
        end)

        box.edit = edit
        self.linkBox = box
    end

    box.url = url
    box:Show()
    box.edit:SetText(url)
    box.edit:SetFocus()
    box.edit:HighlightText()
end

local TOOLTIP_LINKS = {
    item = true, spell = true, enchant = true, achievement = true,
    quest = true, talent = true, glyph = true,
}

function ChatSkin:GroupTooltip(link, text)
    local _, resultID, activityID = strsplit(":", link)
    resultID, activityID = tonumber(resultID), tonumber(activityID)

    local S = NS.Styling
    local info = resultID and C_LFGList and C_LFGList.GetSearchResultInfo
        and C_LFGList.GetSearchResultInfo(resultID)

    if info and LFGListUtil_SetSearchEntryTooltip
        and pcall(LFGListUtil_SetSearchEntryTooltip, GameTooltip, resultID) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Клик - открыть в поиске групп"], 0.6, 0.62, 0.66)
        return
    end

    local title = text and text:match("%[(.-)%]") or L["Группа"]
    GameTooltip:SetText(title, 1, 1, 1, true)

    local activity = activityID and C_LFGList and C_LFGList.GetActivityInfoTable
        and C_LFGList.GetActivityInfoTable(activityID)
    if activity and activity.fullName then
        GameTooltip:AddLine(activity.fullName, S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end

    GameTooltip:AddLine(" ")

    local state = resultID and self:FetchGroup(resultID, activity)

    if state == "loading" then
        GameTooltip:AddLine(L["Загружаю информацию о группе..."], 0.85, 0.86, 0.9, true)
    elseif state == "missing" then
        GameTooltip:AddLine(L["Группа не найдена: её уже распустили или она скрыта."], 0.95, 0.45, 0.4, true)
    else
        GameTooltip:AddLine(L["Подробностей пока нет. Клик - найти её в поиске групп."], 0.6, 0.62, 0.66, true)
    end
end

function ChatSkin:FetchGroup(resultID, activity)
    self.groupState = self.groupState or {}
    local entry = self.groupState[resultID]
    local now = GetTime()

    if entry and entry.state == "loading" and now - entry.time < 6 then return "loading" end
    if entry and entry.state == "missing" and now - entry.time < 20 then return "missing" end

    if not activity or not activity.categoryID then return nil end
    if not (C_LFGList and C_LFGList.SetSearchToApp and C_LFGList.Search) then return nil end
    if LFGListFrame and LFGListFrame:IsVisible() then return nil end
    if self.lastFetch and now - self.lastFetch < 2 then return "loading" end

    if not self.groupListener then
        local listener = CreateFrame("Frame")
        local register = listener.RegisterCustomEvent or _G.RegisterCustomEvent
        if not register then return nil end

        register(listener, "LFG_LIST_SEARCH_RESULTS_RECEIVED")
        register(listener, "LFG_LIST_SEARCH_FAILED")

        listener:SetScript("OnEvent", function()
            ChatSkin:GroupResults()
        end)

        self.groupListener = listener
    end

    local ok = pcall(function()
        C_LFGList.SetSearchToApp(resultID)
        C_LFGList.Search(activity.categoryID, "", 0)
    end)
    if not ok then return nil end

    self.lastFetch = now
    self.fetchingID = resultID
    self.groupState[resultID] = { state = "loading", time = now }

    return "loading"
end

function ChatSkin:GroupResults()
    local resultID = self.fetchingID
    if not resultID then return end
    self.fetchingID = nil

    local found = C_LFGList.GetSearchResultInfo(resultID)
    self.groupState[resultID] = { state = found and "found" or "missing", time = GetTime() }

    local hover = self.hover
    if hover and hover.resultID == resultID then
        self:LinkEnter(hover.frame, hover.link, hover.text)
    end
end

function ChatSkin:LinkEnter(frame, link, text)
    local db = Settings()
    if not db or type(link) ~= "string" then return end

    local kind = link:match("^([^:]+)")

    self.hover = {
        frame = frame, link = link, text = text,
        resultID = kind == "lfglist" and tonumber((select(2, strsplit(":", link)))) or nil,
    }

    if TOOLTIP_LINKS[kind] and db.hoverItems then
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
            GameTooltip:Show()
            self.linkTooltip = true
        else
            GameTooltip:Hide()
        end
    elseif kind == "lfglist" and db.hoverGroups then
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
        local ok = pcall(self.GroupTooltip, self, link, text)
        if ok then
            GameTooltip:Show()
            self.linkTooltip = true
        else
            GameTooltip:Hide()
        end
    end
end

function ChatSkin:LinkLeave()
    self.hover = nil

    if self.linkTooltip then
        self.linkTooltip = nil
        GameTooltip:Hide()
    end
end

function ChatSkin:HookMessages()
    if self.messagesHooked then return end
    self.messagesHooked = true

    for index = 1, MAX_FRAMES do
        local frame = _G["ChatFrame" .. index]
        if frame and frame.AddMessage and index ~= 2 then
            local original = frame.AddMessage
            frame.AddMessage = function(self, text, ...)
                return original(self, Transform(text), ...)
            end

            frame:HookScript("OnHyperlinkEnter", function(self, link, text)
                ChatSkin:LinkEnter(self, link, text)
            end)
            frame:HookScript("OnHyperlinkLeave", function()
                ChatSkin:LinkLeave()
            end)
        end
    end
end

function ChatSkin:HookLinks()
    if self.linksHooked then return end
    self.linksHooked = true
    local original = SetItemRef
    SetItemRef = function(link, text, button, chatFrame)
        if type(link) == "string" and link:sub(1, 9) == "narciurl:" then
            ChatSkin:ShowLink(link:sub(10))
            return
        end
        return original(link, text, button, chatFrame)
    end
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local function StripTextures(frame)
    if not frame or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end
end

local TAB_STRIP = 24
local PAD = 6

local function Park(region, hide)
    if not region then return end
    if hide then
        if not ChatSkin.parking then
            ChatSkin.parking = CreateFrame("Frame")
            ChatSkin.parking:Hide()
        end
        if region:GetParent() ~= ChatSkin.parking then
            region.narciParent = region:GetParent()
            region:SetParent(ChatSkin.parking)
        end
    elseif region.narciParent then
        region:SetParent(region.narciParent)
        region.narciParent = nil
    end
end

function ChatSkin:SkinScroll(frame)
    local db = Settings()
    local S = NS.Styling
    local holder = frame.buttonFrame2

    Park(frame.buttonFrame, db.hideButtons)
    if not holder then return end

    local bar = holder.ScrollBar
    if bar then
        if not bar.narciSkinned then
            bar.narciSkinned = true
            local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
            if thumb then
                thumb:SetTexture(WHITE)
                thumb:SetTexCoord(0, 1, 0, 1)
                thumb:SetSize(3, 26)
                thumb:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
            end
            local track = bar:CreateTexture(nil, "BACKGROUND")
            track:SetTexture(WHITE)
            track:SetWidth(1)
            track:SetPoint("TOP", bar, "TOP", 0, -2)
            track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 2)
            track:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        end
        Park(bar, db.scrollBar == false)
    end

    local bottom = holder.ScrollToBottomButton
    if bottom and not bottom.narciSkinned then
        bottom.narciSkinned = true
        for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
            local texture = bottom[getter] and bottom[getter](bottom)
            if texture then texture:SetTexture(nil) end
        end
        bottom:SetSize(18, 18)

        local ground = bottom:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(bottom)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(0.02, 0.022, 0.03, 0.85)
        S.CreateEdges(bottom, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

        local icon = bottom:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", bottom, "TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", -3, 3)
        icon:SetTexture(S.Media("IconDown"))
        icon:SetVertexColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 1)
        bottom:HookScript("OnEnter", function()
            icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        end)
        bottom:HookScript("OnLeave", function()
            icon:SetVertexColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 1)
        end)

        local flash = bottom.Flash
        if flash then
            flash:SetTexture(WHITE)
            flash:SetBlendMode("ADD")
            flash:ClearAllPoints()
            flash:SetPoint("TOPLEFT", bottom, "TOPLEFT", 1, -1)
            flash:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", -1, 1)
            flash:SetVertexColor(S.ACCENT[1] * 0.45, S.ACCENT[2] * 0.45, S.ACCENT[3] * 0.45)
        end
    end
end

function ChatSkin:KillTextures(frame)
    local name = frame:GetName()
    if not name then return end

    for _, suffix in ipairs(_G.CHAT_FRAME_TEXTURES or {}) do
        local region = _G[name .. suffix]
        if region and region.SetTexture then region:SetTexture(nil) end
    end
end

local function Edge(parent, layer, r, g, b, a)
    local line = parent:CreateTexture(nil, layer)
    line:SetTexture(WHITE)
    line:SetVertexColor(r, g, b, a)
    return line
end

function ChatSkin:BuildPanel(parent)
    local S = NS.Styling

    local panel = CreateFrame("Frame", nil, parent or UIParent)
    if not parent then
        panel:SetFrameStrata("BACKGROUND")
        panel:SetFrameLevel(1)
    end

    local fill = panel:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints(panel)
    fill:SetTexture(WHITE)

    local band = panel:CreateTexture(nil, "BORDER")
    band:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    band:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    band:SetHeight(TAB_STRIP - 1)
    band:SetTexture(WHITE)
    band:SetVertexColor(0, 0, 0, 0.35)

    local rule = Edge(panel, "ARTWORK", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, 0)
    rule:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, 0)

    local top = Edge(panel, "ARTWORK", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.75)
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", panel, "TOPLEFT")
    top:SetPoint("TOPRIGHT", panel, "TOPRIGHT")

    local bottom = Edge(panel, "ARTWORK", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.75)
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")

    local left = Edge(panel, "ARTWORK", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.75)
    left:SetWidth(1)
    left:SetPoint("TOPLEFT", panel, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")

    local right = Edge(panel, "ARTWORK", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.75)
    right:SetWidth(1)
    right:SetPoint("TOPRIGHT", panel, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")

    local glow = panel:CreateTexture(nil, "OVERLAY")
    glow:SetHeight(1)
    glow:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, 0)
    glow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, 0)
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    local topBar = panel:CreateTexture(nil, "OVERLAY")
    topBar:SetHeight(2)
    topBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    topBar:SetTexture(WHITE)
    topBar:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)

    local sideBar = panel:CreateTexture(nil, "OVERLAY")
    sideBar:SetWidth(2)
    sideBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    sideBar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    sideBar:SetTexture(WHITE)
    sideBar:SetGradientAlpha("VERTICAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.15,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)

    local sheen = panel:CreateTexture(nil, "BORDER")
    sheen:SetHeight(40)
    sheen:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    sheen:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    sheen:SetTexture(WHITE)
    sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.07)

    panel.fill = fill
    panel.band, panel.rule, panel.glow = band, rule, glow
    panel.edges = { top, bottom, left, right }
    panel.shadow = S.CreateSoftShadow(panel, 8, 0.5)
    panel.topBar, panel.sideBar, panel.sheen = topBar, sideBar, sheen
    return panel
end

local CHAT_STYLES = {
    panel = true, gradient = true, card = true, side = true, glass = true,
    tooltip = true, dialog = true, pixel = true, terminal = true, bare = true,
}

local BACKDROPS = {
    tooltip = {
        out = 2,
        bg = { 0.05, 0.05, 0.07 }, border = { 0.55, 0.57, 0.62, 1 },
        backdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
    },
    dialog = {
        out = 8,
        bg = { 1, 1, 1 }, border = { 1, 1, 1, 1 },
        backdrop = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        },
    },
    pixel = {
        out = 0,
        bg = { 0.07, 0.07, 0.075 }, border = { 0, 0, 0, 1 },
        backdrop = {
            bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        },
    },
}

local SCANLINE_STEP = 3

function ChatSkin:Scanlines(panel)
    if panel.scanlines then return panel.scanlines end

    local lines = {}
    for index = 1, 160 do
        local line = panel:CreateTexture(nil, "BORDER")
        line:SetTexture(WHITE)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -index * SCANLINE_STEP)
        line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -index * SCANLINE_STEP)
        line:Hide()
        lines[index] = line
    end

    panel.scanlines = lines
    return lines
end

local function ChatStyle()
    local db = Settings()
    local style = db and db.style
    return CHAT_STYLES[style] and style or "panel"
end

function ChatSkin:StylePanel(panel, alpha)
    local S = NS.Styling
    local style = ChatStyle()
    local bg = S.BG_DARK

    local function Show(region, shown) region:SetShown(shown and true or false) end

    local preset = BACKDROPS[style]
    if not panel.skin then
        panel.skin = CreateFrame("Frame", nil, panel)
        panel.skin:SetFrameLevel(panel:GetFrameLevel())
    end

    if preset then
        panel.skin:ClearAllPoints()
        panel.skin:SetPoint("TOPLEFT", panel, "TOPLEFT", -preset.out, preset.out)
        panel.skin:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", preset.out, -preset.out)
        panel.skin:SetBackdrop(preset.backdrop)
        panel.skin:SetBackdropColor(preset.bg[1], preset.bg[2], preset.bg[3], alpha)
        panel.skin:SetBackdropBorderColor(preset.border[1], preset.border[2], preset.border[3], preset.border[4])
        panel.skin:Show()
    else
        panel.skin:SetBackdrop(nil)
        panel.skin:Hide()
    end

    if style == "terminal" or panel.scanlines then
        local lines = self:Scanlines(panel)
        local height = panel:GetHeight() or 0
        local glow = S.ACCENT_GLOW
        for index, line in ipairs(lines) do
            line:SetVertexColor(glow[1], glow[2], glow[3], 0.035)
            line:SetShown(style == "terminal" and index * SCANLINE_STEP < height - 2)
        end
    end

    if preset or style == "bare" then
        panel.fill:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0)
    elseif style == "terminal" then
        local A = S.ACCENT
        panel.fill:SetGradientAlpha("VERTICAL", A[1] * 0.03, A[2] * 0.03, A[3] * 0.03, alpha, A[1] * 0.06, A[2] * 0.06, A[3] * 0.06, alpha)
    elseif style == "gradient" then
        panel.fill:SetGradientAlpha("VERTICAL", bg[1], bg[2], bg[3], math.min(1, alpha * 1.4), bg[1], bg[2], bg[3], 0)
    elseif style == "side" then
        panel.fill:SetGradientAlpha("HORIZONTAL", bg[1], bg[2], bg[3], alpha, bg[1], bg[2], bg[3], alpha * 0.15)
    elseif style == "glass" then
        panel.fill:SetGradientAlpha("VERTICAL", 0.05, 0.07, 0.11, alpha * 0.75, 0.08, 0.10, 0.15, alpha * 0.55)
    else
        panel.fill:SetGradientAlpha("VERTICAL", bg[1], bg[2], bg[3], alpha, bg[1], bg[2], bg[3], alpha)
    end
    local cr, cg, cb = NS.Look:Color("chat", "bg")
    if cr and style ~= "bare" then
        if preset then
            panel.skin:SetBackdropColor(cr, cg, cb, alpha)
        else
            panel.fill:SetGradientAlpha("VERTICAL", cr, cg, cb, alpha, cr, cg, cb, alpha)
        end
    end

    Show(panel.band, style == "panel" or style == "card" or style == "pixel")
    Show(panel.rule, style == "panel" or style == "glass")
    Show(panel.glow, style == "panel" or style == "glass")
    Show(panel.topBar, style == "card")
    Show(panel.sideBar, style == "side")
    Show(panel.sheen, style == "glass")
    Show(panel.shadow, style == "card")

    for _, line in ipairs(panel.edges) do
        Show(line, style == "panel" or style == "card" or style == "glass" or style == "terminal")
        if style == "glass" then
            line:SetVertexColor(S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.9)
        elseif style == "terminal" then
            line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.7)
        else
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.75)
        end
    end
    local er, eg, eb = NS.Look:Color("chat", "border")
    if er then
        for _, line in ipairs(panel.edges) do line:SetVertexColor(er, eg, eb, 0.9) end
        if preset then panel.skin:SetBackdropBorderColor(er, eg, eb, 1) end
    end
end

local SAMPLE_LINES = {
    { "[Гильдия] [Торвальд]: Кто идёт в ЦЛК?", 0.25, 1, 0.25 },
    { "[Аэлин] шепчет: Иду, через 5 минут.", 1, 0.5, 1 },
    { "[Группа] [Шейд]: Готов.", 0.67, 0.67, 1 },
    { "Вы получили предмет: [Ледяная руна].", 0, 0.67, 0 },
    { "Аэлин теперь в сети.", 1, 1, 0 },
}

function ChatSkin:CreateSample(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(290, 140)
    local panel = self:BuildPanel(holder)
    panel:SetAllPoints(holder)
    holder.panel = panel
    local content = CreateFrame("Frame", nil, holder)
    content:SetAllPoints(holder)
    content:SetFrameLevel(panel:GetFrameLevel() + 3)
    holder.tabs = {}
    for index, label in ipairs({ "Общий", "Журнал боя", "Шёпот" }) do
        local tab = content:CreateFontString(nil, "OVERLAY")
        tab:SetPoint("TOPLEFT", holder, "TOPLEFT", 8 + (index - 1) * 74, -6)
        NS.LSetFont(tab, "chat", 11, "")
        tab:SetText(L[label])
        holder.tabs[index] = tab
    end
    holder.lines = {}
    for index, data in ipairs(SAMPLE_LINES) do
        local line = content:CreateFontString(nil, "OVERLAY")
        line:SetPoint("TOPLEFT", holder, "TOPLEFT", 8, -TAB_STRIP - 6 - (index - 1) * 18)
        line:SetPoint("RIGHT", holder, "RIGHT", -8, 0)
        line:SetJustifyH("LEFT")
        line:SetFont(FONTS.default or NS.FONT, 12, "")
        line:SetText(L[data[1]])
        line:SetTextColor(data[2], data[3], data[4])
        holder.lines[index] = line
    end
    return holder
end

function ChatSkin:PaintSample(holder)
    local db = Settings()
    if not db or not holder then return end
    local S = NS.Styling
    holder.panel:SetShown(db.panel ~= false)
    self:StylePanel(holder.panel, (db.panelAlpha or 60) / 100)
    local size = db.fontSize or 12
    local flags = db.outline and "OUTLINE" or ""
    local font = ChatFont(db.font)
    local stamp = ""
    if db.timestamps and db.timestamps ~= "none" then stamp = date(db.timestamps, time()) end
    for index, line in ipairs(holder.lines) do
        line:SetFont(font, size, flags)
        line:SetText(stamp .. L[SAMPLE_LINES[index][1]])
    end
    for index, tab in ipairs(holder.tabs) do
        NS.LSetFont(tab, "chat", 11, "")
        if index == 1 then
            tab:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            tab:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
        tab:SetShown(not db.hideTabs)
    end
end

function ChatSkin:PanelFor(frame)
    if not frame.narciPanel then
        frame.narciPanel = self:BuildPanel()

        frame:HookScript("OnShow", function() ChatSkin:LayoutPanels() end)
        frame:HookScript("OnHide", function() ChatSkin:LayoutPanels() end)
    end

    return frame.narciPanel
end

function ChatSkin:LayoutPanels()
    local db = Settings()
    if not db then return end

    local S = NS.Styling
    local alpha = (db.panelAlpha or 60) / 100

    local dockShown = false

    for index = 1, MAX_FRAMES do
        local frame = _G["ChatFrame" .. index]
        if frame and (index == 1 or frame.isDocked) and frame:IsShown() then
            dockShown = true
        end
    end

    for index = 1, MAX_FRAMES do
        local frame = _G["ChatFrame" .. index]

        if frame then
            local owner = index == 1 or not frame.isDocked
            local panel = frame.narciPanel

            if owner and db.panel and Enabled() then
                panel = self:PanelFor(frame)

                panel:ClearAllPoints()
                panel:SetPoint("TOPLEFT", frame, "TOPLEFT", -PAD, TAB_STRIP + PAD)
                panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", PAD, -PAD)
                self:StylePanel(panel, alpha)

                local visible = index == 1 and dockShown or (index ~= 1 and frame:IsShown())
                panel:SetShown(visible)
            elseif panel then
                panel:Hide()
            end
        end
    end
end

function ChatSkin:HookDock()
    if self.dockHooked then return end
    self.dockHooked = true

    for _, name in ipairs({ "FCF_DockFrame", "FCF_UnDockFrame", "FCF_DockUpdate" }) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function()
                if NS.After then
                    NS.After(0, function() ChatSkin:LayoutPanels() end)
                end
            end)
        end
    end
end

function ChatSkin:InputHolder()
    if self.inputHolder then return self.inputHolder end

    local holder = CreateFrame("Frame", "NarciSirus_ChatInput", UIParent)
    holder:SetSize(440, 30)

    if NS.Movers then
        NS.Movers:Register(holder, L["Строка ввода"], function(point, _, x, y)
            local db = Settings()
            db.inputPoint, db.inputX, db.inputY = point, x, y
            db.editPos = "free"
        end, "chat")
    end

    self.inputHolder = holder
    return holder
end

function ChatSkin:PlaceInputHolder()
    local db = Settings()
    local holder = self:InputHolder()
    local chat = _G.ChatFrame1

    if chat then
        local width = chat:GetWidth()
        if width and width > 0 then holder:SetWidth(width + (PAD + 2) * 2) end
    end

    if not db.inputX and chat then
        local left, top = chat:GetLeft(), chat:GetTop()

        if left and top then
            db.inputPoint = "BOTTOMLEFT"
            db.inputX = math.floor(left - PAD - 2 + 0.5)
            db.inputY = math.floor(top + TAB_STRIP + PAD + 2 + 0.5)
        end
    end

    holder:ClearAllPoints()

    if db.inputX then
        holder:SetPoint(db.inputPoint or "BOTTOMLEFT", UIParent, db.inputPoint or "BOTTOMLEFT", db.inputX, db.inputY)
    elseif chat then
        holder:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", -PAD - 2, TAB_STRIP + PAD + 2)
    end

    holder:SetShown(db.editPos == "free")
end

function ChatSkin:PlaceInput(box, frame)
    local db = Settings()
    if not box or not frame then return end

    box:ClearAllPoints()

    if db.editPos == "bottom" then
        box:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -PAD - 2, -PAD - 2)
        box:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", PAD + 2, -PAD - 2)
    elseif db.editPos == "free" then
        box:SetAllPoints(self:InputHolder())
    else
        box:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -PAD - 2, TAB_STRIP + PAD + 2)
        box:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", PAD + 2, TAB_STRIP + PAD + 2)
    end
end

function ChatSkin:RegisterChatMover()
    local chat = _G.ChatFrame1
    if not chat or not NS.Movers or chat.narciMoverOverlay then return end

    NS.Movers:Register(chat, L["Чат"], function()
        if type(_G.FCF_SavePositionAndDimensions) == "function" then
            pcall(_G.FCF_SavePositionAndDimensions, chat)
        end
        ChatSkin:LayoutPanels()
    end, "chat")
end

function ChatSkin:ResetPosition()
    local chat = _G.ChatFrame1
    if not chat or InCombatLockdown() then return false end
    chat:ClearAllPoints()
    chat:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 95)
    chat:SetSize(430, 120)
    if type(_G.FCF_SavePositionAndDimensions) == "function" then
        pcall(_G.FCF_SavePositionAndDimensions, chat)
    end
    self:LayoutPanels()
    return true
end

function ChatSkin:SetChatSize(width, height)
    local chat = _G.ChatFrame1
    if not chat or InCombatLockdown() then return false end
    chat:SetSize(width or chat:GetWidth(), height or chat:GetHeight())
    if type(_G.FCF_SavePositionAndDimensions) == "function" then
        pcall(_G.FCF_SavePositionAndDimensions, chat)
    end
    self:LayoutPanels()
    return true
end

function ChatSkin:Move()
    if NS.Movers then NS.Movers:Toggle() end
end

function ChatSkin:PrepareMove()
    if not NS.Movers or not Enabled() then return end

    self:PlaceInputHolder()

    if self.inputHolder then self.inputHolder:Show() end

    if not self.moveHooked then
        self.moveHooked = true
        table.insert(NS.Movers.finish, function() ChatSkin:Apply() end)
    end
end

function ChatSkin:SkinEditBox(box)
    if not box or box.narciChat then return end
    box.narciChat = true

    local S = NS.Styling
    local name = box:GetName()

    for _, suffix in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
        local region = name and _G[name .. suffix]
        if region then region:SetAlpha(0) end
    end

    local ground = box:CreateTexture(nil, "BACKGROUND")
    ground:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -2)
    ground:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -6, 2)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.022, 0.025, 0.034, 0.92)

    local line = box:CreateTexture(nil, "BORDER")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", ground, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", ground, "BOTTOMRIGHT", 0, 0)
    line:SetTexture(WHITE)
    line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)

    box:HookScript("OnEditFocusGained", function()
        line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    end)

    box:HookScript("OnEditFocusLost", function()
        line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)
    end)
end

function ChatSkin:SkinTab(tab, index)
    if not tab or tab.narciChat then return end
    tab.narciChat = true

    local S = NS.Styling
    local name = tab:GetName()

    for _, suffix in ipairs({ "Left", "Middle", "Right",
        "SelectedLeft", "SelectedMiddle", "SelectedRight",
        "HighlightLeft", "HighlightMiddle", "HighlightRight" }) do
        local region = name and _G[name .. suffix]
        if region then region:SetAlpha(0) end
    end

    local text = _G[name .. "Text"]
    if text then
        NS.LSetFont(text, "chat", NS.FS(12), "")
        text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    end

    local under = tab:CreateTexture(nil, "OVERLAY")
    under:SetHeight(2)

    if text then
        under:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
        under:SetPoint("TOPRIGHT", text, "BOTTOMRIGHT", 0, -3)
    else
        under:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 10, 2)
        under:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -10, 2)
    end
    under:SetTexture(WHITE)
    under:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    under:Hide()

    tab.narciUnder = under

    local pill = tab:CreateTexture(nil, "BACKGROUND")
    pill:SetPoint("TOPLEFT", tab, "TOPLEFT", 4, -4)
    pill:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, 2)
    pill:SetTexture(WHITE)
    pill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
    pill:Hide()
    tab.narciPill = pill

    local marker = tab:CreateTexture(nil, "OVERLAY")
    marker:SetSize(2, 12)
    if text then
        marker:SetPoint("RIGHT", text, "LEFT", -4, 0)
    else
        marker:SetPoint("LEFT", tab, "LEFT", 6, 0)
    end
    marker:SetTexture(WHITE)
    marker:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    marker:Hide()
    tab.narciMarker = marker

    tab:HookScript("OnEnter", function(self)
        if text then
            text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        end
    end)

    tab:HookScript("OnLeave", function(self)
        if text and _G.SELECTED_CHAT_FRAME ~= _G["ChatFrame" .. index] then
            text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
    end)

    tab:HookScript("OnClick", function()
        ChatSkin:UpdateTabs()
    end)
end

function ChatSkin:UpdateTabs()
    local S = NS.Styling

    for index = 1, MAX_FRAMES do
        local tab = _G["ChatFrame" .. index .. "Tab"]
        local frame = _G["ChatFrame" .. index]

        if tab and tab.narciUnder then
            local active = _G.SELECTED_CHAT_FRAME == frame
            local style = ChatStyle()
            tab.narciUnder:SetShown(active and style ~= "card" and style ~= "side")
            tab.narciPill:SetShown(active and style == "card")
            tab.narciMarker:SetShown(active and style == "side")

            local text = _G["ChatFrame" .. index .. "TabText"]
            if text then
                if active then
                    text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                else
                    text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                end
            end
        end
    end
end

function ChatSkin:ApplyBehaviour()
    local db = Settings()
    if not db or not Enabled() then return end

    self:HookMessages()

    if db.classNames ~= nil and ToggleChatColorNamesByClassGroup and CHAT_CONFIG_CHAT_LEFT then
        for _, entry in ipairs(CHAT_CONFIG_CHAT_LEFT) do
            if entry.type then pcall(ToggleChatColorNamesByClassGroup, db.classNames, entry.type) end
        end
        for channel = 1, 10 do
            pcall(ToggleChatColorNamesByClassGroup, db.classNames, "CHANNEL" .. channel)
        end
    end

    if db.timestamps then
        SetCVar("showTimestamps", db.timestamps)
        _G.CHAT_TIMESTAMP_FORMAT = db.timestamps ~= "none" and db.timestamps or nil
    end

    for index = 1, MAX_FRAMES do
        local frame = _G["ChatFrame" .. index]
        if frame then
            frame:SetFading(db.fade and true or false)
            frame:SetTimeVisible(db.fadeTime or 120)
        end
    end

    if db.hideTabs then
        _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0
        _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0
    elseif Enabled() then
        _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 1
        _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.7
    else
        _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0.4
        _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.2
    end

    for index = 1, MAX_FRAMES do
        local tab = _G["ChatFrame" .. index .. "Tab"]
        if tab and tab.noMouseAlpha ~= nil then
            tab.noMouseAlpha = db.hideTabs and 0 or (_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA or tab.noMouseAlpha)
            if db.hideTabs and not tab:IsMouseOver() then tab:SetAlpha(0) end
        end
    end
end

function ChatSkin:Apply()
    self:ApplyBehaviour()

    if not Enabled() then return end

    local db = Settings()

    for index = 1, MAX_FRAMES do
        local frame = _G["ChatFrame" .. index]

        if frame then
            StripTextures(frame)
            self:KillTextures(frame)

            local font, _, flags = frame:GetFont()
            if db.font ~= "default" or db.outline then
                font = ChatFont(db.font)
                flags = db.outline and "OUTLINE" or ""
            end
            if font then frame:SetFont(font, db.fontSize, flags) end

            frame:SetClampRectInsets(0, 0, 0, 0)

            self:SkinTab(_G["ChatFrame" .. index .. "Tab"], index)

            local box = _G["ChatFrame" .. index .. "EditBox"]
            self:SkinEditBox(box)
            self:PlaceInput(box, frame)

            self:SkinScroll(frame)
        end
    end

    if db.hideButtons then
        for _, name in ipairs({ "ChatFrameMenuButton", "FriendsMicroButton" }) do
            local button = _G[name]
            if button then
                button:SetAlpha(0)
                button:EnableMouse(false)
            end
        end
    end

    if not db.hideTabs then
        _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 1
        _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.7
    end
    _G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 1

    self:HookDock()
    self:UpdateTabs()
    self:LayoutPanels()
    self:RegisterChatMover()
    self:PlaceToasts()

    if not (NS.Movers and NS.Movers:IsActive()) then
        self:PlaceInputHolder()
    end
end

function ChatSkin:PlaceToasts()
    local anchor = _G.SocialToastAnchorFrame
    local chat = _G.ChatFrame1
    if not anchor or not chat or not Enabled() then return end

    anchor:SetClampedToScreen(true)

    if not anchor.narciHooked and type(anchor.UpdatePosition) == "function" then
        anchor.narciHooked = true
        hooksecurefunc(anchor, "UpdatePosition", function() ChatSkin:PlaceToasts() end)
    end

    local saved = GetCVar("toastPoint")
    if saved and saved ~= "" then return end

    local db = Settings()
    local top = TAB_STRIP + PAD
    if db and db.editPos == "top" then
        local box = _G.ChatFrame1EditBox
        top = top + (box and box:GetHeight() or 24) + 4
    end

    anchor:ClearAllPoints()
    anchor:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", -PAD, top + 8)
end

function ChatSkin:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Apply()
        NS.Print("чат в стиле аддона")
    else
        NS.Print("чат вернётся к клиентскому после /reload")
    end
end

function ChatSkin:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value
    self:Apply()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function()
    if NS.After then
        NS.After(2, function() ChatSkin:Apply() end)
    end
end)
