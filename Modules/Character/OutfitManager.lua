local addonName, NS = ...
local L = NS.L

local OutfitManager = {}

local format = string.format
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove

local DANGER_COLOR = { 0.85, 0.35, 0.30 }

local OUTFIT_PREVIEW_COUNT = 9
local OUTFIT_PREVIEW_SIZE  = 14
local OUTFIT_PREVIEW_X     = 76

local EQUIP_SLOTS = {
    { id = 1,  name = "Голова" },
    { id = 2,  name = "Шея" },
    { id = 3,  name = "Плечи" },
    { id = 5,  name = "Грудь" },
    { id = 6,  name = "Пояс" },
    { id = 7,  name = "Ноги" },
    { id = 8,  name = "Ступни" },
    { id = 9,  name = "Запястья" },
    { id = 10, name = "Перчатки" },
    { id = 11, name = "Кольцо 1" },
    { id = 12, name = "Кольцо 2" },
    { id = 13, name = "Талисман 1" },
    { id = 14, name = "Талисман 2" },
    { id = 15, name = "Плащ" },
    { id = 16, name = "Правая рука" },
    { id = 17, name = "Левая рука" },
    { id = 18, name = "Дальний бой" },
}

local outfitTooltip

local TOOLTIP_WIDTH   = 260
local TOOLTIP_LINE_H  = 20
local TOOLTIP_TITLE_H = 24
local TOOLTIP_PAD     = 8

local function EnsureTooltip()
    if outfitTooltip then return end
    local S = NS.Styling
    local f = CreateFrame("Frame", "NarcissusSirus_OutfitTooltip", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)
    f:SetWidth(TOOLTIP_WIDTH)
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.95))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 4, 0.5)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", TOOLTIP_PAD, -6)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -TOOLTIP_PAD, -6)
    title:SetJustifyH("LEFT")
    f.title = title

    f.lines = {}
    f:Hide()
    outfitTooltip = f
end

local function ShowOutfitTooltip(outfit, anchor)
    EnsureTooltip()
    local f = outfitTooltip

    for i = 1, #f.lines do f.lines[i]:Hide() end

    f.title:SetText(outfit.name)

    local count = 0
    for _, slotInfo in ipairs(EQUIP_SLOTS) do
        local link = outfit.items[slotInfo.id]
        if link then
            count = count + 1
            local line = f.lines[count]
            if not line then
                line = CreateFrame("Frame", nil, f)
                line:SetHeight(TOOLTIP_LINE_H)

                local icon = line:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", line, "LEFT", 0, 0)
                line.icon = icon

                local name = line:CreateFontString(nil, "OVERLAY")
                name:SetFont(NS.FONT, NS.FS(10), "")
                name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                name:SetPoint("RIGHT", line, "RIGHT", 0, 0)
                name:SetJustifyH("LEFT")
                line.name = name

                f.lines[count] = line
            end

            local itemName, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link)
            local r, g, b = NS.GetQualityColor(quality)

            line.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            line.name:SetText(itemName or "?")
            line.name:SetTextColor(r, g, b)

            local y = -(TOOLTIP_TITLE_H + (count - 1) * TOOLTIP_LINE_H)
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", f, "TOPLEFT", TOOLTIP_PAD, y)
            line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -TOOLTIP_PAD, y)
            line:Show()
        end
    end

    f:SetHeight(TOOLTIP_TITLE_H + count * TOOLTIP_LINE_H + TOOLTIP_PAD)
    f:ClearAllPoints()
    f:SetPoint("RIGHT", anchor, "LEFT", -8, 0)
    f:Show()
end

local function HideOutfitTooltip()
    if outfitTooltip then outfitTooltip:Hide() end
end

local function InitDB()
    if not NarcissusSirusDB then NarcissusSirusDB = {} end
    if not NarcissusSirusDB.outfits then NarcissusSirusDB.outfits = {} end
end

function OutfitManager:CaptureCurrent(name)
    if not name or name == "" then
        NS.Print(L["Введите название набора."])
        return false
    end
    InitDB()
    local outfit = { name = name, timestamp = time(), items = {} }
    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slot.id)
        if link then outfit.items[slot.id] = link end
    end
    for i, existing in ipairs(NarcissusSirusDB.outfits) do
        if existing.name == name then
            NarcissusSirusDB.outfits[i] = outfit
            NS.Print(format(L["Набор '|cff00ccff%s|r' обновлён!"], name))
            return true
        end
    end
    tinsert(NarcissusSirusDB.outfits, outfit)
    NS.Print(format(L["Набор '|cff00ccff%s|r' сохранён!"], name))
    return true
end

function OutfitManager:FindItemInBags(targetLink)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                if GetContainerItemLink(bag, slot) == targetLink then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function OutfitManager:EquipOutfit(name)
    InitDB()
    for _, outfit in ipairs(NarcissusSirusDB.outfits) do
        if outfit.name == name then
            local equipped, failed = 0, 0
            for slotId, link in pairs(outfit.items) do
                local bag, slot = self:FindItemInBags(link)
                if bag and slot then
                    PickupContainerItem(bag, slot)
                    EquipCursorItem(slotId)
                    equipped = equipped + 1
                else
                    local currentLink = GetInventoryItemLink("player", slotId)
                    if currentLink == link then
                        equipped = equipped + 1
                    else
                        failed = failed + 1
                    end
                end
            end
            if failed > 0 then
                NS.Print(format(L["Набор '|cff00ccff%s|r': надето %d, |cffff4444не найдено %d|r"], name, equipped, failed))
            else
                NS.Print(format(L["Набор '|cff00ccff%s|r': надето предметов - %d!"], name, equipped))
            end
            return true
        end
    end
    return false
end

function OutfitManager:DeleteOutfit(name)
    InitDB()
    for i, outfit in ipairs(NarcissusSirusDB.outfits) do
        if outfit.name == name then
            tremove(NarcissusSirusDB.outfits, i)
            NS.Print(format(L["Набор '|cff00ccff%s|r' удалён."], name))
            return true
        end
    end
    return false
end

function OutfitManager:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_OutfitManager", parent)
    f:SetWidth(S.PANEL_WIDTH)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
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
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText(L["Быстрые наборы"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerOutfits", height = 34, module = OutfitManager, method = "UpdateList", badge = function()
        return #(NarcissusSirusDB.outfits or {}), L["НАБОРОВ"]
    end }) end

    local saveLabel = f:CreateFontString(nil, "OVERLAY")
    saveLabel:SetFont(NS.FONT, NS.FS(11), "")
    saveLabel:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    saveLabel:SetPoint("TOP", title, "BOTTOM", 0, -12)
    saveLabel:SetText(L["Сохранить текущий набор:"])

    local editBox = NS.Widgets.CreateThemedEditBox(f, 160, 22, 30)
    editBox:SetPoint("TOP", saveLabel, "BOTTOM", -30, -4)
    f.editBox = editBox

    local function SaveFromEditBox()
        local name = editBox:GetText()
        if not name or strtrim(name) == "" then return end
        if OutfitManager:CaptureCurrent(strtrim(name)) then
            editBox:SetText("")
            editBox:ClearFocus()
            OutfitManager:UpdateList()
        end
    end

    editBox:SetScript("OnEnterPressed", SaveFromEditBox)

    local saveBtn = NS.Widgets.CreateThemedButton(f, L["Сохранить"], 66, 22, SaveFromEditBox)
    saveBtn:SetPoint("LEFT", editBox, "RIGHT", 8, 0)

    local emptyHint = f:CreateFontString(nil, "OVERLAY")
    emptyHint:SetFont(NS.FONT, NS.FS(11), "")
    emptyHint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    emptyHint:SetPoint("TOP", f, "TOP", 0, -170)
    emptyHint:SetWidth(360)
    emptyHint:SetText(L["Наборов пока нет.\nНаденьте нужные вещи, введите название и нажмите \"Сохранить\"."])
    emptyHint:Hide()
    f.emptyHint = emptyHint

    S.CreateAnimatedSeparator(f, -118)

    local scrollFrame = CreateFrame("ScrollFrame", "NarcissusSirus_OutfitScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -128)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(400)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)
    f.scrollChild = scrollChild
    f.scrollFrame = scrollFrame

    self.frame = f
    self.buttons = {}
    f:Hide()
end

function OutfitManager:UpdateList()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local f = self.frame

    for _, btn in pairs(self.buttons) do btn:Hide() end

    InitDB()
    local yOffset = 0
    local outfits = NarcissusSirusDB.outfits

    if f.emptyHint then
        if #outfits == 0 then f.emptyHint:Show() else f.emptyHint:Hide() end
    end

    local opts = NS.db and NS.db.outfitTab or {}
    local list = outfits
    if opts.sort == "alpha" then
        list = {}
        for index, outfit in ipairs(outfits) do list[index] = outfit end
        table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    end

    for i, outfit in ipairs(list) do
        if not self.buttons[i] then
            local btn = CreateFrame("Button", nil, f.scrollChild)
            btn:SetHeight(36)
            btn:SetWidth(400)

            if btn.SetBackdrop then
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 },
                })
                btn:SetBackdropColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.8)
                btn:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            end

            local strip = btn:CreateTexture(nil, "OVERLAY")
            strip:SetSize(2, 28)
            strip:SetPoint("LEFT", btn, "LEFT", 1, 0)
            strip:SetTexture("Interface\\Buttons\\WHITE8x8")
            strip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.6)

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
            highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.08)

            local nameLabel = btn:CreateFontString(nil, "OVERLAY")
            nameLabel:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
            nameLabel:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            nameLabel:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -4)
            btn.nameLabel = nameLabel

            local infoLabel = btn:CreateFontString(nil, "OVERLAY")
            infoLabel:SetFont(NS.FONT, NS.FS(9), "")
            infoLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            infoLabel:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 10, 4)
            btn.infoLabel = infoLabel

            btn.preview = {}
            for p = 1, OUTFIT_PREVIEW_COUNT do
                local tex = btn:CreateTexture(nil, "ARTWORK")
                tex:SetSize(OUTFIT_PREVIEW_SIZE, OUTFIT_PREVIEW_SIZE)
                tex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT",
                    OUTFIT_PREVIEW_X + (p - 1) * (OUTFIT_PREVIEW_SIZE + 2), 3)
                tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                tex:Hide()
                btn.preview[p] = tex
            end

            local equipBtn = NS.Widgets.CreateThemedButton(btn, L["Надеть"], 56, 20, function()
                OutfitManager:EquipOutfit(btn.outfitName)
            end)
            equipBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -66, -5)

            local delBtn = NS.Widgets.CreateThemedButton(btn, L["Удалить"], 56, 20, function()
                local name = btn.outfitName
                local function Delete()
                    OutfitManager:DeleteOutfit(name)
                    OutfitManager:UpdateList()
                end
                if NS.db and NS.db.outfitTab and NS.db.outfitTab.confirm and NS.Widgets.ShowConfirm then
                    NS.Widgets.ShowConfirm(format(L["Удалить набор «%s»?"], name or ""), L["Удалить"], Delete)
                else
                    Delete()
                end
            end, DANGER_COLOR)
            delBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -4, -5)

            self.buttons[i] = btn
        end

        local btn = self.buttons[i]
        btn.outfitName = outfit.name
        btn.outfitData = outfit
        btn.nameLabel:SetText(outfit.name)

        local count = 0
        for _ in pairs(outfit.items) do count = count + 1 end
        btn.infoLabel:SetText(format(L["%d предм."], count))

        local shown = 0
        for _, slotInfo in ipairs(EQUIP_SLOTS) do
            local link = outfit.items[slotInfo.id]
            if link and shown < OUTFIT_PREVIEW_COUNT then
                shown = shown + 1
                local tex = btn.preview[shown]
                local icon = select(10, GetItemInfo(link))
                tex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                tex:Show()
            end
        end
        for p = shown + 1, OUTFIT_PREVIEW_COUNT do
            btn.preview[p]:Hide()
        end
        if opts.icons == false then
            for p = 1, OUTFIT_PREVIEW_COUNT do btn.preview[p]:Hide() end
        end

        btn:SetScript("OnEnter", function(self)
            if self.outfitData then
                ShowOutfitTooltip(self.outfitData, self)
            end
        end)
        btn:SetScript("OnLeave", function()
            HideOutfitTooltip()
        end)

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -yOffset)
        btn:Show()
        yOffset = yOffset + 40
    end

    f.scrollChild:SetHeight(math.max(yOffset, 1))
end

function OutfitManager:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:UpdateList()
        NS.Styling.PanelIn(self.frame)
    end
end

function OutfitManager:Hide()
    NS.Styling.PanelHideNow(self.frame)
end

NS.OutfitManager = OutfitManager
