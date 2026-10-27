local addonName, NS = ...
local L = NS.L

local ProfessionsPanel = {}

local format = string.format
local max = math.max
local min = math.min

local WHITE = "Interface\\Buttons\\WHITE8x8"

local TITLE_Y      = -12
local HINT_Y       = -34
local SEPARATOR_Y  = -52
local CONTENT_TOP  = -60
local ROW_PITCH    = 44
local BOTTOM_PAD   = 12
local MIN_HEIGHT   = 220
local MAX_HEIGHT   = 470
local PAD          = 14
local ICON_SIZE    = 32
local EXTRA_SIZE   = 28
local BAR_HEIGHT   = 6
local TEXT_Y       = -5
local BAR_Y        = -23
local MAX_ROWS     = 8

local PROFESSION_LIST = {
    { skill = TRADESKILL_ALCHEMY,        open = 2259                },
    { skill = TRADESKILL_BLACKSMITHING,  open = 2018                },
    { skill = TRADESKILL_ENCHANTING,     open = 7411,  extra = 13262 },
    { skill = TRADESKILL_ENGINEERING,    open = 4036                },
    { skill = TRADESKILL_HERBALISM,      open = 2366                },
    { skill = TRADESKILL_INSCRIPTION,    open = 45357, extra = 51005 },
    { skill = TRADESKILL_JEWELCRAFTING,  open = 25229, extra = 31252 },
    { skill = TRADESKILL_LEATHERWORKING, open = 2108                },
    { skill = TRADESKILL_MINING,         open = 2656                },
    { skill = TRADESKILL_SKINNING,       open = 8613                },
    { skill = TRADESKILL_TAILORING,      open = 3908                },
    { skill = PROFESSION_FISHING,        open = 7620,               secondary = true },
    { skill = PROFESSION_COOKING,        open = 2550,  extra = 818,  secondary = true },
    { skill = PROFESSION_FIRST_AID,      open = 3273,               secondary = true },
}

local byName

local function BuildIndex()
    if byName then return byName end
    byName = {}
    for _, p in ipairs(PROFESSION_LIST) do
        if p.skill then byName[p.skill] = p end
    end
    local smelting = GetSpellInfo(2656)
    if smelting and byName[TRADESKILL_MINING] then
        byName[smelting] = byName[TRADESKILL_MINING]
    end
    return byName
end

local function CollectProfessions()
    local index = BuildIndex()
    local found, result = {}, {}

    for i = 1, (GetNumSkillLines() or 0) do
        local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and skillName then
            local entry = index[skillName]
            if entry and skillMaxRank and skillMaxRank > 0 then
                local prev = found[entry]
                if not prev or (prev.maxRank or 0) < skillMaxRank then
                    found[entry] = {
                        entry = entry,
                        rank = skillRank or 0,
                        maxRank = skillMaxRank,
                        modifier = skillModifier or 0,
                    }
                end
            end
        end
    end

    local opts = NS.db and NS.db.profTab or {}
    for _, p in ipairs(PROFESSION_LIST) do
        if found[p] and not (opts.hideSecondary and p.secondary) then result[#result + 1] = found[p] end
    end
    if opts.sort == "rank" then
        table.sort(result, function(a, b) return (a.rank or 0) > (b.rank or 0) end)
    end
    return result
end

local function RowOffsets(index)
    local S = NS.Styling
    local right = S.PANEL_X
    local rowTop = S.PANEL_Y + S.PANEL_HEIGHT / 2 + CONTENT_TOP - (index - 1) * ROW_PITCH
    local holderHeight = ROW_PITCH - 4
    return right - S.PANEL_WIDTH + PAD, rowTop - (holderHeight - ICON_SIZE) / 2,
           right - PAD, rowTop - (holderHeight - EXTRA_SIZE) / 2
end

local function OnIconEnter(self)
    local v = self.visual or self
    if not v.spellID then return end
    local S = NS.Styling
    GameTooltip:SetOwner(v, "ANCHOR_RIGHT")
    local ok = false
    pcall(function()
        local link = GetSpellLink(v.spellID)
        if link then ok = GameTooltip:SetHyperlink(link) end
    end)
    if not ok then
        GameTooltip:AddLine(v.spellName or "", 1, 1, 1)
    end
    if v.hintText then
        GameTooltip:AddLine(v.hintText, 0.6, 0.6, 0.65)
    end
    GameTooltip:Show()
    v.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
    v.glow:Show()
end

local function OnIconLeave(self)
    local v = self.visual or self
    local S = NS.Styling
    GameTooltip:Hide()
    v.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    v.glow:Hide()
end

local function CreateIconVisual(parent, size)
    local S = NS.Styling
    local v = CreateFrame("Frame", nil, parent)
    v:SetSize(size, size)
    v:EnableMouse(true)

    local icon = v:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", v, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    v.icon = icon

    local glow = v:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(icon)
    glow:SetTexture(WHITE)
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.22)
    glow:Hide()
    v.glow = glow

    local border = CreateFrame("Frame", nil, v)
    border:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", 0, 0)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    v.border = border

    v:SetScript("OnEnter", OnIconEnter)
    v:SetScript("OnLeave", OnIconLeave)

    return v
end

local function CreateClickButton(name, size, visual, x, y, point)
    local ui = NS.NarciUI
    local host = ui and ui.slotAnchor
    if not host then return nil end

    local btn = CreateFrame("Button", name, host, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:SetPoint(point, host, "RIGHT", x, y)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:EnableMouse(true)

    local base = ui.mainFrame
    if base then
        btn:SetFrameStrata(base:GetFrameStrata())
        btn:SetFrameLevel(base:GetFrameLevel() + 10)
    end

    btn.visual = visual
    btn:SetScript("OnEnter", OnIconEnter)
    btn:SetScript("OnLeave", OnIconLeave)
    btn:Hide()

    return btn
end

function ProfessionsPanel:EnsureClickButtons(index)
    local row = self.frame and self.frame.rows[index]
    if not row then return end
    if row.openBtn and row.extraBtn then return end
    if InCombatLockdown() then
        self._buildPending = true
        return
    end

    local openX, openY, extraX, extraY = RowOffsets(index)
    if not row.openBtn then
        row.openBtn = CreateClickButton("NarciSirus_ProfOpen" .. index, ICON_SIZE, row.openIcon, openX, openY, "TOPLEFT")
    end
    if not row.extraBtn then
        row.extraBtn = CreateClickButton("NarciSirus_ProfExtra" .. index, EXTRA_SIZE, row.extraIcon, extraX, extraY, "TOPRIGHT")
    end
end

function ProfessionsPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local host = (NS.NarciUI and NS.NarciUI.slotAnchor) or parent

    local f = CreateFrame("Frame", "NarcissusSirus_ProfessionsPanel", host)
    f:SetWidth(S.PANEL_WIDTH)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetPoint("TOPRIGHT", host, "RIGHT", S.PANEL_X, S.PANEL_Y + S.PANEL_HEIGHT / 2)
    f:SetFrameStrata(parent:GetFrameStrata())
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = WHITE,
            edgeFile = WHITE,
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, TITLE_Y)
    title:SetText(L["Профессии"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerProfessions", module = ProfessionsPanel, method = "Update", badge = function()
        return #CollectProfessions(), L["ПРОФЕССИЙ"]
    end }) end

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(11), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("TOP", f, "TOP", 0, HINT_Y)
    hint:SetText(L["Щёлкните по значку, чтобы открыть окно профессии."])
    f.hint = hint

    S.CreateAnimatedSeparator(f, SEPARATOR_Y)

    local empty = f:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOP", f, "TOP", 0, CONTENT_TOP - 20)
    empty:SetText(L["Профессии не изучены."])
    empty:Hide()
    f.empty = empty

    f.rows = {}

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("SKILL_LINES_CHANGED")
    ev:RegisterEvent("LEARNED_SPELL_IN_TAB")
    ev:SetScript("OnEvent", function()
        if ProfessionsPanel.frame and ProfessionsPanel.frame:IsShown() then
            ProfessionsPanel:Update()
        end
    end)
    f.eventFrame = ev

    f:SetScript("OnHide", function()
        ProfessionsPanel:SyncButtons()
    end)

    self.frame = f
    f:Hide()
end

function ProfessionsPanel:CreateRow(index)
    local S = NS.Styling
    local f = self.frame
    local row = {}

    local holder = CreateFrame("Frame", nil, f)
    holder:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, CONTENT_TOP - (index - 1) * ROW_PITCH)
    holder:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, CONTENT_TOP - (index - 1) * ROW_PITCH)
    holder:SetHeight(ROW_PITCH - 4)
    row.holder = holder

    local stripe = holder:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints(holder)
    stripe:SetTexture(WHITE)
    stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.10)
    row.stripe = stripe
    if NS.TabStyle then NS.TabStyle.Row(stripe) end

    local openIcon = CreateIconVisual(holder, ICON_SIZE)
    openIcon:SetPoint("LEFT", holder, "LEFT", 0, 0)
    row.openIcon = openIcon

    local extraIcon = CreateIconVisual(holder, EXTRA_SIZE)
    extraIcon:SetPoint("RIGHT", holder, "RIGHT", 0, 0)
    extraIcon:Hide()
    row.extraIcon = extraIcon

    local name = holder:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    name:SetPoint("TOPLEFT", holder, "TOPLEFT", ICON_SIZE + 8, TEXT_Y)
    name:SetJustifyH("LEFT")
    row.name = name

    local rank = holder:CreateFontString(nil, "OVERLAY")
    rank:SetFont(NS.FONT, NS.FS(11), "")
    rank:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, TEXT_Y)
    rank:SetJustifyH("RIGHT")
    row.rank = rank

    local barBg = holder:CreateTexture(nil, "ARTWORK")
    barBg:SetHeight(BAR_HEIGHT)
    barBg:SetPoint("TOPLEFT", holder, "TOPLEFT", ICON_SIZE + 8, BAR_Y)
    barBg:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, BAR_Y)
    barBg:SetTexture(WHITE)
    barBg:SetVertexColor(0.10, 0.11, 0.14, 0.9)
    row.barBg = barBg

    local barFill = holder:CreateTexture(nil, "OVERLAY")
    barFill:SetHeight(BAR_HEIGHT)
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetTexture(WHITE)
    row.barFill = barFill

    self.frame.rows[index] = row
    self:EnsureClickButtons(index)
    return row
end

local function SetIconSpell(visual, button, spellID, hintText)
    local spellName, _, texture = GetSpellInfo(spellID)
    visual.spellID = spellID
    visual.spellName = spellName
    visual.hintText = hintText
    visual.icon:SetTexture(texture)

    if not button then return end
    button.visual = visual
    if button._spellSet == spellName then return end
    if InCombatLockdown() then
        ProfessionsPanel._bindPending = true
        return
    end
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", spellName)
    button._spellSet = spellName
end

function ProfessionsPanel:SyncButtons()
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then
        self._syncPending = true
        return
    end

    local panelShown = f:IsShown()
    for index = 1, #f.rows do
        local row = f.rows[index]
        local rowShown = panelShown and row.holder:IsShown()
        if row.openBtn then
            if rowShown and row.openIcon:IsShown() and row.openBtn._spellSet then
                row.openBtn:Show()
            else
                row.openBtn:Hide()
            end
        end
        if row.extraBtn then
            if rowShown and row.extraIcon:IsShown() and row.extraBtn._spellSet then
                row.extraBtn:Show()
            else
                row.extraBtn:Hide()
            end
        end
    end
end

function ProfessionsPanel:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local f = self.frame

    local list = CollectProfessions()
    local shown = min(#list, MAX_ROWS)

    for i = 1, max(shown, #f.rows) do
        local row = f.rows[i]
        if i <= shown and not row then row = self:CreateRow(i) end
        if not row then break end

        self:EnsureClickButtons(i)

        if i > shown then
            row.holder:Hide()
        else
            local data = list[i]
            local entry = data.entry
            row.holder:Show()
            row.stripe:SetAlpha(i % 2 == 0 and 1 or 0)

            SetIconSpell(row.openIcon, row.openBtn, entry.open, L["Открыть окно профессии"])

            local rightPad = 0
            if entry.extra then
                SetIconSpell(row.extraIcon, row.extraBtn, entry.extra)
                row.extraIcon:Show()
                rightPad = -(EXTRA_SIZE + 8)
            else
                row.extraIcon:Hide()
            end
            row.rank:SetPoint("TOPRIGHT", row.holder, "TOPRIGHT", rightPad, TEXT_Y)
            row.barBg:SetPoint("TOPRIGHT", row.holder, "TOPRIGHT", rightPad, BAR_Y)

            row.name:SetText(entry.skill or "")

            local rank, maxRank = data.rank, data.maxRank
            local capped = rank >= maxRank
            if data.modifier and data.modifier > 0 then
                row.rank:SetText(format("%d|cff40c040+%d|r / %d", rank, data.modifier, maxRank))
            else
                row.rank:SetText(format("%d / %d", rank, maxRank))
            end
            if capped then
                row.rank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
                row.barFill:SetVertexColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.9)
            else
                row.rank:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                row.barFill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            end

            local trackWidth = row.barBg:GetWidth() or 0
            local ratio = maxRank > 0 and (rank / maxRank) or 0
            if trackWidth > 1 and ratio > 0 then
                row.barFill:SetWidth(max(1, trackWidth * min(ratio, 1)))
                row.barFill:Show()
            else
                row.barFill:Hide()
            end
        end
    end

    if shown == 0 then
        f.empty:Show()
        f:SetHeight(MIN_HEIGHT)
    else
        f.empty:Hide()
        local height = -CONTENT_TOP + shown * ROW_PITCH + BOTTOM_PAD
        f:SetHeight(max(MIN_HEIGHT, min(MAX_HEIGHT, height)))
    end

    if InCombatLockdown() then
        f.hint:SetText(L["в бою профессию можно только посмотреть"])
    else
        f.hint:SetText(L["Щёлкните по значку, чтобы открыть окно профессии."])
    end

    self:SyncButtons()
end

function ProfessionsPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
        self:SyncButtons()
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
        self:SyncButtons()
        NS.After(0.05, function()
            if ProfessionsPanel.frame and ProfessionsPanel.frame:IsShown() then
                ProfessionsPanel:Update()
            end
        end)
    end
end

function ProfessionsPanel:Hide()
    if not self.frame then return end
    NS.Styling.PanelHideNow(self.frame)
    self:SyncButtons()
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function()
        local panel = ProfessionsPanel
        if not panel.frame then return end
        local rebuild = panel._buildPending or panel._bindPending
        panel._buildPending = nil
        panel._bindPending = nil
        panel._syncPending = nil
        if rebuild then
            for index = 1, #panel.frame.rows do
                panel:EnsureClickButtons(index)
            end
            panel:Update()
        else
            panel:SyncButtons()
        end
    end)
end

ProfessionsPanel.Collect = CollectProfessions

NS.ProfessionsPanel = ProfessionsPanel
