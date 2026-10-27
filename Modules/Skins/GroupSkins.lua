local addonName, NS = ...
local L = NS.L

local GroupSkins = {}
NS.GroupSkins = GroupSkins

local WHITE = "Interface\\Buttons\\WHITE8x8"
local NUM_ROLL_FRAMES = 4
local MAX_REWARDS = 6

local function Kit()
    return NS.SkinKit
end

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinGroup ~= false
end

local function Hide(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

local panels = {}

local function PanelAlpha()
    return ((NS.db and NS.db.groupPanelAlpha) or 97) / 100
end

local GROUP_STYLES = { modern = true, classic = true, pixel = true, glass = true }

local DIALOG_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
}

local function GroupStyle()
    local style = NS.db and NS.db.groupStyle
    return GROUP_STYLES[style] and style or "modern"
end

local function Tint(frame)
    local alpha = PanelAlpha()
    local style = GroupStyle()
    local S = Style()
    local ground, rim = frame.narciGround, frame.narciRim or {}

    if style == "classic" and frame.SetBackdrop then
        pcall(frame.SetBackdrop, frame, DIALOG_BACKDROP)
        pcall(frame.SetBackdropColor, frame, 1, 1, 1, alpha)
        pcall(frame.SetBackdropBorderColor, frame, 1, 1, 1, 1)
        frame.narciClassic = true
        if ground then ground:SetAlpha(0) end
        for _, line in ipairs(rim) do line:SetAlpha(0) end
    else
        if frame.narciClassic then
            frame.narciClassic = nil
            if frame.SetBackdrop then pcall(frame.SetBackdrop, frame, nil) end
        end

        local r, g, b, a = 0.022, 0.025, 0.034, alpha
        local er, eg, eb, ea = S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9
        if style == "pixel" then
            r, g, b = 0.07, 0.07, 0.075
            er, eg, eb, ea = 0, 0, 0, 1
        elseif style == "glass" then
            r, g, b, a = 0.05, 0.07, 0.11, alpha * 0.65
            er, eg, eb, ea = S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.95
        end

        if ground then
            ground:SetAlpha(1)
            ground:SetVertexColor(r, g, b, a)
        end
        for _, line in ipairs(rim) do
            line:SetAlpha(1)
            line:SetVertexColor(er, eg, eb, ea)
        end
        if frame.SetBackdropColor then pcall(frame.SetBackdropColor, frame, r, g, b, a) end
        if frame.SetBackdropBorderColor then pcall(frame.SetBackdropBorderColor, frame, er, eg, eb, ea) end
    end

    local chrome = style == "modern" or style == "glass"
    if frame.narciTopBorder then frame.narciTopBorder:SetShown(chrome) end
    if frame.narciShadowFrame then frame.narciShadowFrame:SetShown(chrome or style == "pixel") end
end

local function Panel(frame)
    if not frame or frame.narciPanel then return end
    frame.narciPanel = true

    local S = Style()
    Kit().Ground(frame)
    frame.narciShadowFrame = S.CreateShadow(frame, 6, 0.5)
    frame.narciTopBorder = S.CreateGradientTopBorder(frame, 2)

    panels[#panels + 1] = frame
    Tint(frame)
end

local function Restore(frame)
    if frame and frame.narciPanel then
        Kit().Ensure(frame)
        Tint(frame)
    end
end

function GroupSkins:ApplyPanelAlpha()
    for _, frame in ipairs(panels) do Tint(frame) end
end

local function Edges(frame, r, g, b, a)
    local S = Style()
    return S.CreateEdges(frame, "OVERLAY", r or S.BORDER[1], g or S.BORDER[2], b or S.BORDER[3], a or 0.9)
end

local function Paint(edges, r, g, b, a)
    if not edges then return end
    for _, line in ipairs(edges) do line:SetVertexColor(r, g, b, a or 0.9) end
end

local function FlatButton(button, accent)
    if not button or button.narciFlat then return end
    button.narciFlat = true

    local S = Style()

    for _, region in ipairs({ button:GetRegions() }) do
        if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    if accent then
        ground:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.55)
    else
        ground:SetVertexColor(0.045, 0.050, 0.070, 0.95)
    end
    ground:SetAlpha(1)

    local edges = Edges(button)
    if accent then Paint(edges, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95) end
    for _, line in ipairs(edges) do line:SetAlpha(1) end

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)

    local text = button.GetFontString and button:GetFontString()
    if text then
        text:SetFont(NS.FONT, NS.FS(12), "")
        text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end
end

local function Title(fontString, size)
    if not fontString then return end
    local S = Style()
    fontString:SetFont(NS.FONT, NS.FS(size or 13), "")
    fontString:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
end

local function TexturePath(region)
    local ok, path = pcall(region.GetTexture, region)
    return ok and type(path) == "string" and path:lower() or ""
end

local function Separators(frame)
    if not frame then return end
    local S = Style()

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" and TexturePath(region):find("separator") then
            region:SetTexture(WHITE)
            region:SetHeight(1)
            region:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.45)
        end
    end
end

local REWARD_SIZE, REWARD_GAP = 28, 5
local COIN_ICON = "Interface\\Icons\\inv_misc_coin_02"

local function RewardIcon(reward)
    if not reward or reward.narciReward then return end
    reward.narciReward = true

    Hide(_G[reward:GetName() .. "Border"])

    local texture = reward.texture or _G[reward:GetName() .. "Texture"]
    if not texture then return end

    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", reward, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", reward, "BOTTOMRIGHT", -1, 1)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local frame = CreateFrame("Frame", nil, reward)
    frame:SetAllPoints(reward)
    Edges(frame)
end

function GroupSkins:LayoutRewards(dungeonID)
    local parent = _G.LFDDungeonReadyDialogRewardsFrame
    if not parent then return end
    local shown = {}
    for index = 1, MAX_REWARDS do
        local reward = _G["LFDDungeonReadyDialogRewardsFrameReward" .. index]
        if not reward then break end
        RewardIcon(reward)
        if reward:IsShown() then shown[#shown + 1] = reward end
    end
    if #shown == 0 then return end

    for _, reward in ipairs(shown) do
        local path
        if reward.rewardID == 0 then
            path = COIN_ICON
        elseif dungeonID and reward.rewardType == "shortage" and GetLFGDungeonShortageRewardInfo then
            path = select(2, GetLFGDungeonShortageRewardInfo(dungeonID, reward.rewardID))
        elseif dungeonID and GetLFGDungeonRewardInfo then
            path = select(2, GetLFGDungeonRewardInfo(dungeonID, reward.rewardID))
        end
        local texture = reward.texture or _G[reward:GetName() .. "Texture"]
        if texture and path then
            texture:SetTexture(path)
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    local perRow = #shown <= 4 and #shown or math.ceil(#shown / 2)
    local rows = math.ceil(#shown / perRow)
    local top = 5 + (rows * REWARD_SIZE + (rows - 1) * REWARD_GAP) / 2
    for index, reward in ipairs(shown) do
        local row = math.floor((index - 1) / perRow)
        local column = (index - 1) % perRow
        local inRow = math.min(perRow, #shown - row * perRow)
        local width = inRow * REWARD_SIZE + (inRow - 1) * REWARD_GAP
        reward:SetSize(REWARD_SIZE, REWARD_SIZE)
        reward:ClearAllPoints()
        reward:SetPoint("TOPLEFT", parent, "CENTER", -width / 2 + column * (REWARD_SIZE + REWARD_GAP),
            top - row * (REWARD_SIZE + REWARD_GAP))
    end
end

function GroupSkins:Rewards(prefix)
    for index = 1, MAX_REWARDS do
        local reward = _G[prefix .. index]
        if not reward then break end
        RewardIcon(reward)
    end
end

function GroupSkins:SkinReadyDialog()
    local dialog = _G.LFDDungeonReadyDialog
    if not dialog or dialog.narciSkinned then return end
    dialog.narciSkinned = true

    local S = Style()
    Panel(dialog)

    Hide(_G.LFDDungeonReadyDialogFiligree)
    Hide(_G.LFDDungeonReadyDialogBottomArt)

    local art = dialog.background or _G.LFDDungeonReadyDialogBackground
    if art then
        art:SetAlpha(0.55)
        art:ClearAllPoints()
        art:SetPoint("TOPLEFT", dialog, "TOPLEFT", 1, -1)
        art:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -1, -1)
        art:SetHeight(118)

        local fade = dialog:CreateTexture(nil, "BORDER")
        fade:SetPoint("BOTTOMLEFT", art, "BOTTOMLEFT", 0, 0)
        fade:SetPoint("BOTTOMRIGHT", art, "BOTTOMRIGHT", 0, 0)
        fade:SetHeight(70)
        fade:SetTexture(WHITE)
        fade:SetGradientAlpha("VERTICAL", 0.020, 0.023, 0.032, 1, 0.020, 0.023, 0.032, 0)
    end

    Title(dialog.label or _G.LFDDungeonReadyDialogLabel, 13)

    local roleLabel = _G.LFDDungeonReadyDialogRoleLabel
    if roleLabel then
        roleLabel:SetFont(NS.FONT, NS.FS(15), "OUTLINE")
        roleLabel:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    end

    local roleDescription = _G.LFDDungeonReadyDialogYourRoleDescription
    if roleDescription then roleDescription:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]) end

    FlatButton(_G.LFDDungeonReadyDialogEnterDungeonButton, true)
    FlatButton(_G.LFDDungeonReadyDialogLeaveQueueButton)
    Kit().Close(_G.LFDDungeonReadyDialogCloseButton)

    Separators(dialog.randomInProgress)
    Separators(dialog.instanceInfo)

    self:Rewards("LFDDungeonReadyDialogRewardsFrameReward")
    dialog:HookScript("OnShow", function(self)
        Restore(self)
        GroupSkins:Rewards("LFDDungeonReadyDialogRewardsFrameReward")
    end)
    if type(_G.LFDDungeonReadyDialog_UpdateRewards) == "function" then
        hooksecurefunc("LFDDungeonReadyDialog_UpdateRewards", function(dungeonID)
            GroupSkins:LayoutRewards(dungeonID)
        end)
    end
end

function GroupSkins:SkinReadyStatus()
    local status = _G.LFDDungeonReadyStatus
    if not status or status.narciSkinned then return end
    status.narciSkinned = true

    Panel(status)
    Title(_G.LFDDungeonReadyStatusLabel, 13)
    Kit().Close(_G.LFDDungeonReadyStatusCloseButton)

    status:HookScript("OnShow", Restore)
end

function GroupSkins:SkinRoleCheck()
    local popup = _G.LFDRoleCheckPopup
    if not popup or popup.narciSkinned then return end
    popup.narciSkinned = true

    local S = Style()
    Panel(popup)

    FlatButton(_G.LFDRoleCheckPopupAcceptButton, true)
    FlatButton(_G.LFDRoleCheckPopupDeclineButton)

    local text = _G.LFDRoleCheckPopupDescriptionText
    if text then text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]) end

    popup:HookScript("OnShow", Restore)
end

function GroupSkins:SkinMiniGame()
    local dialog = _G.MiniGameReadyDialog
    if dialog and not dialog.narciSkinned then
        dialog.narciSkinned = true
        Panel(dialog)
        Title(dialog.Label or _G.MiniGameReadyDialogLabel, 13)
        FlatButton(dialog.EnterButton or _G.MiniGameReadyDialogEnterButton, true)
        FlatButton(dialog.LeaveButton or _G.MiniGameReadyDialogLeaveQueueButton)
        Kit().Close(_G.MiniGameReadyDialogCloseButton)
        self:Rewards("MiniGameReadyDialogRewardsFrameReward")
        dialog:HookScript("OnShow", Restore)
    end

    local status = _G.MiniGameReadyStatus
    if status and not status.narciSkinned then
        status.narciSkinned = true
        Panel(status)
        Title(_G.MiniGameReadyStatusLabel, 13)
        Kit().Close(_G.MiniGameReadyStatusCloseButton)
        status:HookScript("OnShow", Restore)
    end
end

local function RollQuality(frame)
    if not frame.rollID then return end
    local _, _, _, quality, bindOnPickUp = GetLootRollItemInfo(frame.rollID)
    return quality, bindOnPickUp
end

function GroupSkins:PaintRoll(frame)
    local S = Style()
    local name = frame:GetName()

    Restore(frame)
    Hide(_G[name .. "Corner"])
    Hide(_G[name .. "Decoration"])

    local quality, bindOnPickUp = RollQuality(frame)
    local r, g, b = NS.GetQualityColor(quality)

    Paint(frame.narciIconEdges, r, g, b, 1)

    local bar = _G[name .. "Timer"]
    if bar then bar:SetStatusBarColor(r * 0.85, g * 0.85, b * 0.85, 1) end

    if frame.narciBind then
        frame.narciBind:SetShown(bindOnPickUp and true or false)
    end

    if frame.narciRim then
        local edge = bindOnPickUp and S.GOLD_DIM or S.BORDER
        Paint(frame.narciRim, edge[1], edge[2], edge[3], 0.9)
    end
end

function GroupSkins:SkinRoll(frame)
    if not frame or frame.narciSkinned then return end
    frame.narciSkinned = true

    local S = Style()
    local name = frame:GetName()

    Panel(frame)

    Hide(_G[name .. "SlotTexture"])
    Hide(_G[name .. "NameFrame"])
    Hide(_G[name .. "Corner"])
    Hide(_G[name .. "Decoration"])

    local iconFrame = _G[name .. "IconFrame"]
    local icon = _G[name .. "IconFrameIcon"]
    if iconFrame and icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local holder = CreateFrame("Frame", nil, iconFrame)
        holder:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -1, 1)
        holder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
        frame.narciIconEdges = Edges(holder)
    end

    local label = _G[name .. "Name"]
    if label then label:SetFont(NS.FONT, NS.FS(12), "") end

    local bind = frame:CreateFontString(nil, "OVERLAY")
    bind:SetFont(NS.FONT, NS.FS(9), "")
    bind:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    bind:SetText(L["Персональный"])
    if iconFrame then bind:SetPoint("TOPLEFT", iconFrame, "BOTTOMLEFT", 0, -3) end
    bind:Hide()
    frame.narciBind = bind

    local bar = _G[name .. "Timer"]
    if bar then
        bar:SetStatusBarTexture(WHITE)
        for _, region in ipairs({ bar:GetRegions() }) do
            if region:GetObjectType() == "Texture" and TexturePath(region):find("barborder") then
                region:SetAlpha(0)
            end
        end

        local ground = bar:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(bar)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(NS.Styling.Tint(0.04, 0.045, 0.06, 1))

        local holder = CreateFrame("Frame", nil, bar)
        holder:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        holder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        Edges(holder)
    end

    Kit().Close(frame.passButton or _G[name .. "PassButton"])

    frame:HookScript("OnShow", function(self) GroupSkins:PaintRoll(self) end)
    if frame:IsShown() then self:PaintRoll(frame) end
end

local function ListStyle()
    return Enabled() and NS.db and NS.db.rollStyle == "list"
end

local ROW_W = 340

local function RowWidth()
    return (NS.db and NS.db.rollWidth) or ROW_W
end
local ROW_H = 34
local ROW_GAP = 4
local TILE_W = 72

local LOOK_HEIGHT = { rows = 34, cards = 58, minimal = 26, fill = 34, tiles = 132 }

local function RollLook()
    local look = NS.db and NS.db.rollLook
    return LOOK_HEIGHT[look] and look or "rows"
end

local ROLL_CHOICES = {
    { id = 1, texture = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", label = "NEED" },
    { id = 2, texture = "Interface\\Buttons\\UI-GroupLoot-Coin-Up", label = "GREED" },
    { id = 3, texture = "Interface\\Buttons\\UI-GroupLoot-DE-Up", label = "ROLL_DISENCHANT" },
    { id = 0, label = "PASS" },
}

function GroupSkins:RollHolder()
    if self.rollHolder then return self.rollHolder end

    local holder = CreateFrame("Frame", "NarciSirus_LootRollHolder", UIParent)
    holder:SetSize(RowWidth(), ROW_H)
    holder:SetFrameStrata("DIALOG")

    local db = NS.db or {}
    if db.rollPoint then
        holder:SetPoint(db.rollPoint, UIParent, db.rollRelativePoint or db.rollPoint, db.rollX or 0, db.rollY or 0)
    else
        holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 330)
    end

    if NS.Movers then
        NS.Movers:Register(holder, L["Ролл добычи"], function(point, relativePoint, x, y)
            if not NS.db then return end
            NS.db.rollPoint, NS.db.rollRelativePoint, NS.db.rollX, NS.db.rollY = point, relativePoint, x, y
        end, "lootroll")
    end

    self.rollHolder = holder
    self.rows = {}
    return holder
end

local function ChoiceButton(row, choice)
    local S = Style()

    local button = CreateFrame("Button", nil, row)
    button:SetSize(24, 24)
    button.choice = choice

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.05, 0.055, 0.075, 1)

    button.edges = Edges(button)

    if choice.texture then
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        icon:SetTexture(choice.texture)
        button.icon = icon
    else
        local mark = button:CreateFontString(nil, "OVERLAY")
        mark:SetFont(NS.FONT, NS.FS(13), "")
        mark:SetPoint("CENTER", button, "CENTER", 0, 0)
        mark:SetText("X")
        mark:SetTextColor(0.85, 0.40, 0.40)
        NS.Styling.GlyphIcon(mark)
        button.mark = mark
    end

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.3)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(_G[choice.label] or "")
        if self.reason then GameTooltip:AddLine(self.reason, 1, 0.3, 0.3, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function(self)
        local rollID = row.rollID
        if not rollID or not self.usable then return end
        if not row.preview then RollOnLoot(rollID, choice.id) end
        GroupSkins:RemoveRow(rollID)
    end)

    return button
end

function GroupSkins:BuildRow(parent)
    local S = Style()
    local holder = parent or self:RollHolder()

    local row = CreateFrame("Frame", nil, holder)
    row:SetSize(RowWidth(), ROW_H)
    row:EnableMouse(true)

    local ground = row:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(row)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Tint(0.020, 0.023, 0.032, 0.94))

    row.ground = ground
    row.edges = Edges(row)
    row.shadow = S.CreateShadow(row, 4, 0.4)

    local fill = CreateFrame("StatusBar", nil, row)
    fill:SetStatusBarTexture(WHITE)
    fill:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
    fill:SetMinMaxValues(0, 1)
    fill:SetFrameLevel(row:GetFrameLevel() + 1)
    fill:Hide()
    row.fill = fill

    local textLayer = CreateFrame("Frame", nil, row)
    textLayer:SetAllPoints(row)
    textLayer:SetFrameLevel(row:GetFrameLevel() + 3)

    local stripe = row:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    stripe:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
    stripe:SetWidth(2)
    stripe:SetTexture(WHITE)
    row.stripe = stripe

    local item = CreateFrame("Button", nil, row)
    item:SetSize(ROW_H - 8, ROW_H - 8)
    item:SetPoint("LEFT", row, "LEFT", 7, 0)
    item:SetFrameLevel(row:GetFrameLevel() + 3)

    local icon = item:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    item.icon = icon
    item.edges = Edges(item)

    local count = item:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 1)
    item.count = count

    item:SetScript("OnEnter", function(self)
        if not row.rollID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if row.preview then
            GameTooltip:SetHyperlink(row.preview)
        else
            GameTooltip:SetLootRollItem(row.rollID)
        end
        GameTooltip:Show()
    end)
    item:SetScript("OnLeave", function() GameTooltip:Hide() end)
    item:SetScript("OnClick", function()
        local link = row.previewLink or (row.rollID and GetLootRollItemLink(row.rollID))
        if link and HandleModifiedItemClick then HandleModifiedItemClick(link) end
    end)
    row.item = item

    row.choices = {}
    local previous
    for index = #ROLL_CHOICES, 1, -1 do
        local button = ChoiceButton(row, ROLL_CHOICES[index])
        button:SetFrameLevel(row:GetFrameLevel() + 3)
        if previous then
            button:SetPoint("RIGHT", previous, "LEFT", -3, 0)
        else
            button:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        end
        previous = button
        row.choices[ROLL_CHOICES[index].id] = button
    end

    local name = textLayer:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", item, "RIGHT", 8, 3)
    name:SetPoint("RIGHT", previous, "LEFT", -8, 3)
    name:SetJustifyH("LEFT")
    row.name = name

    local bind = textLayer:CreateFontString(nil, "OVERLAY")
    bind:SetFont(NS.FONT, NS.FS(9), "")
    bind:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    bind:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    bind:SetText(L["Персональный"])
    row.bind = bind

    local timer = CreateFrame("StatusBar", nil, row)
    timer:SetStatusBarTexture(WHITE)
    timer:SetPoint("BOTTOMLEFT", item, "BOTTOMRIGHT", 8, -3)
    timer:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 2)
    timer:SetHeight(2)
    timer:SetMinMaxValues(0, 1)

    local track = timer:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(timer)
    track:SetTexture(WHITE)
    track:SetVertexColor(1, 1, 1, 0.08)
    row.timer = timer

    row:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.1 then return end
        self.elapsed = 0

        if not self.rollID then return end
        local left
        if self.preview then
            left = math.max(0, (self.previewEnd - GetTime()) * 1000)
        else
            left = GetLootRollTimeLeft(self.rollID) or 0
        end
        self.timer:SetValue(left)
        if self.fill:IsShown() then
            self.fill:SetMinMaxValues(self.timer:GetMinMaxValues())
            self.fill:SetValue(left)
        end
        if left <= 0 then GroupSkins:RemoveRow(self.rollID) end
    end)

    if not parent then self.rows[#self.rows + 1] = row end
    return row
end

function GroupSkins:FillRow(row, rollID, rollTime)
    local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant,
        reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired = GetLootRollItemInfo(rollID)
    if not name then return false end

    local r, g, b = NS.GetQualityColor(quality)

    row.rollID = rollID
    row.item.icon:SetTexture(texture)
    row.item.count:SetText((count and count > 1) and count or "")
    Paint(row.item.edges, r, g, b, 1)
    row.stripe:SetVertexColor(r, g, b, 1)

    row.name:SetText(name)
    row.name:SetTextColor(r, g, b)
    row.bind:SetShown(bindOnPickUp and true or false)

    if bindOnPickUp then
        local S = Style()
        Paint(row.edges, S.GOLD_DIM[1], S.GOLD_DIM[2], S.GOLD_DIM[3], 0.9)
    else
        local S = Style()
        Paint(row.edges, S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end

    row.timer:SetMinMaxValues(0, rollTime or GetLootRollTimeLeft(rollID) or 60000)
    row.timer:SetValue(GetLootRollTimeLeft(rollID) or 0)
    row.timer:SetStatusBarColor(r * 0.85, g * 0.85, b * 0.85, 1)
    row.fill:SetStatusBarColor(r, g, b, 0.26)
    row.fill:SetMinMaxValues(row.timer:GetMinMaxValues())
    row.fill:SetValue(GetLootRollTimeLeft(rollID) or 0)

    local allowed = {
        [1] = { canNeed, reasonNeed },
        [2] = { canGreed, reasonGreed },
        [3] = { canDisenchant, reasonDisenchant },
    }

    for id, button in pairs(row.choices) do
        local state = allowed[id]
        local usable = not state or state[1]
        button.usable = usable and true or false
        button:SetAlpha(usable and 1 or 0.3)
        if button.icon then button.icon:SetDesaturated(not usable) end

        if state and not usable and state[2] then
            local text = _G["LOOT_ROLL_INELIGIBLE_REASON" .. state[2]]
            if text and id == 3 then text = string.format(text, deSkillRequired or 0) end
            button.reason = text
        else
            button.reason = nil
        end
    end

    return true
end

function GroupSkins:ApplyLook(row, look, width)
    if row.look == look and row.lookWidth == width then return end
    row.look, row.lookWidth = look, width

    local tiles = look == "tiles"
    local minimal = look == "minimal"
    row:SetSize(tiles and TILE_W or width, LOOK_HEIGHT[look])

    row.ground:SetShown(not minimal)
    row.shadow:SetShown(not minimal)
    for _, line in ipairs(row.edges) do line:SetShown(not minimal) end
    row.stripe:SetShown(look == "rows" or look == "cards" or look == "fill")
    row.fill:SetShown(look == "fill")
    row.bind:SetAlpha((tiles or minimal) and 0 or 1)

    local item, name, bind, timer = row.item, row.name, row.bind, row.timer
    local need, greed, de, pass = row.choices[1], row.choices[2], row.choices[3], row.choices[0]
    item:ClearAllPoints()
    name:ClearAllPoints()
    bind:ClearAllPoints()
    timer:ClearAllPoints()

    local choiceSize = (look == "rows" or look == "fill" or look == "cards") and 24 or minimal and 20 or 22
    for _, button in pairs(row.choices) do
        button:SetSize(choiceSize, choiceSize)
        button:ClearAllPoints()
    end

    if tiles then
        item:SetSize(38, 38)
        item:SetPoint("TOP", row, "TOP", 0, -8)
        name:SetFont(NS.FONT, NS.FS(10), "")
        name:SetWidth(TILE_W - 8)
        name:SetHeight(24)
        name:SetJustifyH("CENTER")
        name:SetJustifyV("TOP")
        name:SetPoint("TOP", item, "BOTTOM", 0, -4)
        bind:SetPoint("TOP", name, "BOTTOM", 0, 0)
        need:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 32)
        greed:SetPoint("LEFT", need, "RIGHT", 4, 0)
        de:SetPoint("TOPLEFT", need, "BOTTOMLEFT", 0, -4)
        pass:SetPoint("LEFT", de, "RIGHT", 4, 0)
        timer:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
        timer:SetPoint("TOPRIGHT", row, "TOPRIGHT", -1, -1)
        timer:SetHeight(2)
        return
    end

    name:SetJustifyV("MIDDLE")
    name:SetJustifyH("LEFT")
    name:SetHeight(16)

    if look == "cards" then
        item:SetSize(42, 42)
        item:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -7)
        name:SetFont(NS.FONT, NS.FS(13), "")
        name:SetPoint("TOPLEFT", item, "TOPRIGHT", 10, 0)
        name:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        need:SetPoint("BOTTOMLEFT", item, "BOTTOMRIGHT", 10, 0)
        greed:SetPoint("LEFT", need, "RIGHT", 4, 0)
        de:SetPoint("LEFT", greed, "RIGHT", 4, 0)
        pass:SetPoint("LEFT", de, "RIGHT", 4, 0)
        bind:SetPoint("LEFT", pass, "RIGHT", 10, 0)
        timer:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
        timer:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
        timer:SetHeight(3)
        return
    end

    local iconSize = minimal and 22 or 26
    local lift = minimal and 0 or 3
    item:SetSize(iconSize, iconSize)
    item:SetPoint("LEFT", row, "LEFT", minimal and 2 or 7, 0)
    pass:SetPoint("RIGHT", row, "RIGHT", minimal and -2 or -6, 0)
    de:SetPoint("RIGHT", pass, "LEFT", -3, 0)
    greed:SetPoint("RIGHT", de, "LEFT", -3, 0)
    need:SetPoint("RIGHT", greed, "LEFT", -3, 0)
    name:SetFont(NS.FONT, NS.FS(12), minimal and "OUTLINE" or "")
    name:SetPoint("LEFT", item, "RIGHT", 8, lift)
    name:SetPoint("RIGHT", need, "LEFT", -8, lift)
    bind:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    timer:SetHeight(2)

    if minimal then
        timer:SetPoint("BOTTOMLEFT", item, "BOTTOMRIGHT", 8, 0)
        timer:SetPoint("BOTTOMRIGHT", need, "BOTTOMLEFT", -8, 0)
    else
        timer:SetPoint("BOTTOMLEFT", item, "BOTTOMRIGHT", 8, -3)
        timer:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 2)
    end
end

function GroupSkins:LayoutRows()
    local db = NS.db or {}
    local width = RowWidth()
    local down = db.rollGrow == "down"
    local holder = self.rollHolder
    local look = RollLook()
    local tiles = look == "tiles"
    local height = LOOK_HEIGHT[look]

    if holder then
        holder:SetSize(tiles and TILE_W or width, height)
        holder:SetScale((db.rollListScale or 100) / 100)
    end

    local index = 0
    for _, row in ipairs(self.rows or {}) do
        if row.rollID then
            self:ApplyLook(row, look, width)
            row.timer:SetShown(db.rollTimer ~= false)
            row:ClearAllPoints()
            if tiles then
                if down then
                    row:SetPoint("RIGHT", holder, "RIGHT", -index * (TILE_W + ROW_GAP), 0)
                else
                    row:SetPoint("LEFT", holder, "LEFT", index * (TILE_W + ROW_GAP), 0)
                end
            elseif down then
                row:SetPoint("TOP", holder, "TOP", 0, -index * (height + ROW_GAP))
            else
                row:SetPoint("BOTTOM", holder, "BOTTOM", 0, index * (height + ROW_GAP))
            end
            row:Show()
            index = index + 1
        else
            row:Hide()
        end
    end
end

function GroupSkins:ApplyRollScale()
    local scale = ((NS.db and NS.db.rollScale) or 100) / 100
    for index = 1, NUM_ROLL_FRAMES do
        local frame = _G["GroupLootFrame" .. index]
        if frame then frame:SetScale(scale) end
    end
end

local PREVIEW_ITEMS = {
    { link = "item:6948:0:0:0:0:0:0:0", quality = 4, bind = true, count = 1 },
    { link = "item:6948:0:0:0:0:0:0:0", quality = 3, bind = false, count = 1 },
    { link = "item:6948:0:0:0:0:0:0:0", quality = 2, bind = false, count = 5 },
}

function GroupSkins:Preview()
    self:RollHolder()
    local S = Style()

    for index, data in ipairs(PREVIEW_ITEMS) do
        local key = "preview" .. index
        self:RemoveRow(key)

        local row
        for _, candidate in ipairs(self.rows) do
            if not candidate.rollID then row = candidate break end
        end
        row = row or self:BuildRow()

        local name, fullLink, _, _, _, _, _, _, _, texture = GetItemInfo(data.link)
        local r, g, b = NS.GetQualityColor(data.quality)

        row.rollID = key
        row.preview = data.link
        row.previewLink = fullLink
        row.previewEnd = GetTime() + 20 + index * 5

        row.item.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.item.count:SetText(data.count > 1 and data.count or "")
        Paint(row.item.edges, r, g, b, 1)
        row.stripe:SetVertexColor(r, g, b, 1)
        row.name:SetText(name or L["Пример предмета"])
        row.name:SetTextColor(r, g, b)
        row.bind:SetShown(data.bind)

        local edge = data.bind and S.GOLD_DIM or S.BORDER
        Paint(row.edges, edge[1], edge[2], edge[3], 0.9)

        row.timer:SetMinMaxValues(0, (20 + index * 5) * 1000)
        row.timer:SetStatusBarColor(r * 0.85, g * 0.85, b * 0.85, 1)
        row.fill:SetStatusBarColor(r, g, b, 0.26)
        row.fill:SetMinMaxValues(0, (20 + index * 5) * 1000)
        row.fill:SetValue((20 + index * 5) * 1000)

        for id, button in pairs(row.choices) do
            local usable = not (id == 3 and index == 3)
            button.usable = true
            button:SetAlpha(usable and 1 or 0.3)
            if button.icon then button.icon:SetDesaturated(not usable) end
            button.reason = nil
        end
    end

    self:LayoutRows()
end

function GroupSkins:CreateSample(parent, opts)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(280, 180)
    if opts and opts.kind == "roll" then
        holder.rows = {}
        for index = 1, 2 do
            local row = self:BuildRow(holder)
            row:SetScript("OnUpdate", nil)
            holder.rows[index] = row
        end
        return holder
    end
    local panel = CreateFrame("Frame", nil, holder)
    panel:SetSize(250, 150)
    panel:SetPoint("CENTER")
    Panel(panel)
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", panel, "TOP", 0, -14)
    Title(title, 14)
    title:SetText(L["Группа набрана"])
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -12)
    text:SetText(L["Подземелье: Кузня Душ"])
    for index, label in ipairs({ L["Войти"], L["Покинуть очередь"] }) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(100, 22)
        button:SetPoint("BOTTOM", panel, "BOTTOM", (index - 1.5) * 112, 16)
        button:SetText(label)
        button:EnableMouse(false)
        FlatButton(button, index == 1)
    end
    holder.panel = panel
    return holder
end

function GroupSkins:PaintSample(holder, opts)
    if not holder then return end
    if opts and opts.kind == "roll" then
        local S = Style()
        local look = RollLook()
        local width = math.min(RowWidth(), 270)
        local y = 0
        for index, row in ipairs(holder.rows) do
            local data = PREVIEW_ITEMS[index]
            row.look = nil
            self:ApplyLook(row, look, width)
            local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(data.link)
            local r, g, b = NS.GetQualityColor(data.quality)
            row.item.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.item.count:SetText(data.count > 1 and data.count or "")
            Paint(row.item.edges, r, g, b, 1)
            row.stripe:SetVertexColor(r, g, b, 1)
            row.name:SetText(name or L["Пример предмета"])
            row.name:SetTextColor(r, g, b)
            row.bind:SetShown(data.bind)
            local edge = data.bind and S.GOLD_DIM or S.BORDER
            Paint(row.edges, edge[1], edge[2], edge[3], 0.9)
            row.timer:SetMinMaxValues(0, 1)
            row.timer:SetValue(0.7 - index * 0.2)
            row.timer:SetStatusBarColor(r * 0.85, g * 0.85, b * 0.85, 1)
            row.fill:SetStatusBarColor(r, g, b, 0.26)
            row.fill:SetMinMaxValues(0, 1)
            row.fill:SetValue(0.7 - index * 0.2)
            row:ClearAllPoints()
            if look == "tiles" then
                row:SetPoint("TOPLEFT", holder, "TOPLEFT", (index - 1) * (TILE_W + ROW_GAP), 0)
            else
                row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -y)
                y = y + LOOK_HEIGHT[look] + ROW_GAP
            end
            row:Show()
        end
        return
    end
    Tint(holder.panel)
end

function GroupSkins:AddRow(rollID, rollTime)
    self:RollHolder()

    for _, row in ipairs(self.rows) do
        if row.rollID == rollID then return end
    end

    local row
    for _, candidate in ipairs(self.rows) do
        if not candidate.rollID then row = candidate break end
    end
    row = row or self:BuildRow()

    if not self:FillRow(row, rollID, rollTime) then
        row.rollID = nil
        return
    end

    self:LayoutRows()
end

function GroupSkins:RemoveRow(rollID)
    for _, row in ipairs(self.rows or {}) do
        if row.rollID == rollID then
            row.rollID = nil
            row.preview = nil
            row.previewLink = nil
            if GameTooltip:IsOwned(row.item) then GameTooltip:Hide() end
        end
    end
    self:LayoutRows()
end

function GroupSkins:HookRolls()
    if self.rollsHooked or type(_G.GroupLootFrame_OpenNewFrame) ~= "function" then return end
    self.rollsHooked = true

    hooksecurefunc("GroupLootFrame_OpenNewFrame", function(rollID, rollTime)
        if not ListStyle() then return end

        for index = 1, NUM_ROLL_FRAMES do
            local frame = _G["GroupLootFrame" .. index]
            if frame and frame.rollID == rollID and frame:IsShown() then frame:Hide() end
        end

        GroupSkins:AddRow(rollID, rollTime)
    end)
end

local POPUP_BUTTONS = { "Button1", "Button2", "Button3", "ButtonSpecific" }

local function HideCloseArt(button)
    if not button then return end
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
        local region = button[getter] and button[getter](button)
        if region then region:SetAlpha(0) end
    end
end

function GroupSkins:SkinPopup(popup)
    if not popup or popup.narciSkinned then return end
    popup.narciSkinned = true

    local name = popup:GetName()
    Panel(popup)

    for index, key in ipairs(POPUP_BUTTONS) do
        FlatButton(_G[name .. key], index == 1)
    end

    local close = _G[name .. "CloseButton"]
    if close then
        Kit().Close(close)
        HideCloseArt(close)
    end

    local edit = _G[name .. "EditBox"]
    if edit and Kit().EditBox then pcall(Kit().EditBox, edit) end

    Hide(_G[name .. "ItemFrameNameFrame"])

    local itemFrame = _G[name .. "ItemFrame"]
    if itemFrame and not itemFrame.narciEdges then
        local icon = _G[name .. "ItemFrameIconTexture"]
        if icon then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        Hide(_G[name .. "ItemFrameNormalTexture"])
        itemFrame.narciEdges = Edges(itemFrame)
    end

    popup:HookScript("OnShow", function(self)
        Restore(self)
        HideCloseArt(_G[self:GetName() .. "CloseButton"])
    end)
end

function GroupSkins:Apply()
    if not Enabled() then return end

    pcall(self.SkinReadyDialog, self)
    pcall(self.SkinReadyStatus, self)
    pcall(self.SkinRoleCheck, self)
    pcall(self.SkinMiniGame, self)

    for index = 1, NUM_ROLL_FRAMES do
        pcall(self.SkinRoll, self, _G["GroupLootFrame" .. index])
    end
    self:RollHolder()
    self:HookRolls()
    self:ApplyRollScale()
    self:LayoutRows()

    if NS.db and NS.db.skinPopups ~= false then
        for index = 1, (STATICPOPUP_NUMDIALOGS or 4) do
            pcall(self.SkinPopup, self, _G["StaticPopup" .. index])
        end
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("CANCEL_LOOT_ROLL")
driver:SetScript("OnEvent", function(self, event, rollID)
    if event == "CANCEL_LOOT_ROLL" then
        GroupSkins:RemoveRow(rollID)
        return
    end

    GroupSkins:Apply()
end)
