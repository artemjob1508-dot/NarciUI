local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local SHIELD = "Interface\\AchievementFrame\\UI-Achievement-Shields"
local SHIELD_NOPOINTS = "Interface\\AchievementFrame\\UI-Achievement-Shields-NoPoints"
local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local PANEL_W = 900
local PANEL_H = 620
local PAD = 18
local CAT_W = 232
local CAT_ROW_H = 24
local CAT_ROWS = 20
local ROW_H = 56
local ROWS = 8
local STAT_ROWS = 18

NS.Densify("NarcissusSirus_Achievements", function(f)
    CAT_ROW_H, CAT_ROWS = NS.DensityRows(24, 20, f)
    ROW_H, ROWS = NS.DensityRows(56, 8, f)
end)
local SUMMARY_MAX = 5
local FEAT_OF_STRENGTH_ID = 81

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Caption(parent, text)
    local S = NS.Styling
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(NS.FONT, NS.FS(10), "")
    font:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end

local function Chrome(frame)
    local S = NS.Styling

    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(NS.Styling.Panel(0.035, 0.04, 0.055, 0.92))
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    local grad = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    grad:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    grad:SetTexture(WHITE)
    grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    return frame
end

function Panel:FilterCounts(categoryID)
    local numAchievements, numCompleted = GetCategoryNumAchievements(categoryID)
    numAchievements = numAchievements or 0
    numCompleted = numCompleted or 0

    if self.filter == "complete" then
        return numCompleted, numCompleted, 0
    elseif self.filter == "incomplete" then
        return numAchievements - numCompleted, 0, numCompleted
    end

    return numAchievements, numCompleted, 0
end

function Panel:CategoryTotals(id)
    local total, completed = GetCategoryNumAchievements(id, true)
    total = total or 0
    completed = completed or 0

    for _, category in ipairs(self.categories or {}) do
        if category.parent == id then
            local sub, subDone = GetCategoryNumAchievements(category.id, true)
            total = total + (sub or 0)
            completed = completed + (subDone or 0)
        end
    end

    return total, completed
end

function Panel:BuildCategories()
    local list = {}
    local source = self.tab == "stats" and GetStatisticsCategoryList() or GetCategoryList()

    list[#list + 1] = { id = "summary" }

    for _, id in ipairs(source or {}) do
        local _, parent = GetCategoryInfo(id)
        if parent == -1 then
            list[#list + 1] = { id = id }
        end
    end

    for index = #source, 1, -1 do
        local _, parent = GetCategoryInfo(source[index])
        for position, category in ipairs(list) do
            if category.id == parent then
                category.hasChildren = true
                table.insert(list, position + 1, { id = source[index], parent = category.id })
            end
        end
    end

    self.categories = list
    return list
end

function Panel:DisplayCategories()
    local display = {}

    for _, category in ipairs(self.categories or {}) do
        if not category.parent then
            display[#display + 1] = category
            if self.expanded == category.id then
                for _, child in ipairs(self.categories) do
                    if child.parent == category.id then display[#display + 1] = child end
                end
            end
        end
    end

    return display
end

function Panel:SelectCategory(id, parent)
    self.category = id
    self.selection = nil
    self.offset = 0
    self.statOffset = 0

    if parent then
        self.expanded = parent
    elseif id ~= "summary" then
        local hasChildren
        for _, category in ipairs(self.categories or {}) do
            if category.parent == id then hasChildren = true end
        end
        self.expanded = hasChildren and id or nil
    end

    self:Update()
end

function Panel:CreateCategoryRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(CAT_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * CAT_ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * CAT_ROW_H)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
    plate:Hide()
    row.plate = plate

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(12), "")
    label:SetPoint("LEFT", row, "LEFT", 8, 0)
    label:SetJustifyH("LEFT")
    row.label = label

    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(10), "")
    count:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    count:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    count:SetJustifyH("RIGHT")
    row.count = count

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)

    row:SetScript("OnClick", function(self)
        if not self.categoryID then return end
        Panel:SelectCategory(self.categoryID, self.parentID)
    end)

    row:SetScript("OnEnter", function(self)
        if not self.categoryID or self.categoryID == "summary" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label:GetText() or "", 1, 1, 1)
        if self.categoryID == FEAT_OF_STRENGTH_ID then
            GameTooltip:AddLine(Global("FEAT_OF_STRENGTH_DESCRIPTION", ""), 0.9, 0.9, 0.9, true)
        elseif self.total then
            GameTooltip:AddLine(string.format("%d / %d", self.completed or 0, self.total), 0.8, 0.8, 0.85)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row:Hide()
    return row
end

function Panel:CreateAchievementRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", parent, "LEFT", 8, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)
    row.plate = plate

    local border = CreateFrame("Frame", nil, row)
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.5)
    border:EnableMouse(false)
    row.border = border

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -8)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local iconBorder = CreateFrame("Frame", nil, row)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    iconBorder:SetBackdropBorderColor(0, 0, 0, 0.85)
    iconBorder:EnableMouse(false)

    local shield = row:CreateTexture(nil, "ARTWORK")
    shield:SetSize(34, 34)
    shield:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
    shield:SetTexture(SHIELD)
    row.shield = shield

    local points = row:CreateFontString(nil, "OVERLAY")
    points:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    points:SetPoint("CENTER", shield, "CENTER", 0, 2)
    row.points = points

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(13), "")
    label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    label:SetPoint("RIGHT", shield, "LEFT", -8, 0)
    label:SetJustifyH("LEFT")
    row.label = label

    local description = row:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    description:SetPoint("RIGHT", shield, "LEFT", -8, 0)
    description:SetJustifyH("LEFT")
    row.description = description

    local date = row:CreateFontString(nil, "OVERLAY")
    date:SetFont(NS.FONT, NS.FS(10), "")
    date:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    date:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 6)
    row.date = date

    local reward = row:CreateFontString(nil, "OVERLAY")
    reward:SetFont(NS.FONT, NS.FS(11), "")
    reward:SetTextColor(0.55, 0.78, 0.58)
    reward:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -6)
    reward:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    reward:SetJustifyH("LEFT")
    reward:Hide()
    row.reward = reward

    local track = CreateFrame("Button", nil, row)
    track:SetSize(16, 16)
    track:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, -18)

    local trackBox = track:CreateTexture(nil, "ARTWORK")
    trackBox:SetAllPoints()
    trackBox:SetTexture(WHITE)
    trackBox:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local trackCheck = track:CreateTexture(nil, "OVERLAY")
    trackCheck:SetAllPoints()
    trackCheck:SetTexture(CHECK)
    trackCheck:Hide()
    track.check = trackCheck

    local trackLabel = track:CreateFontString(nil, "OVERLAY")
    trackLabel:SetFont(NS.FONT, NS.FS(10), "")
    trackLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    trackLabel:SetPoint("LEFT", track, "RIGHT", 6, 0)
    trackLabel:SetText(Global("TRACK_ACHIEVEMENT", "Отслеживать"))

    track:SetScript("OnClick", function(self)
        local id = self:GetParent().id
        if not id then return end

        if IsTrackedAchievement(id) then
            RemoveTrackedAchievement(id)
        else
            if GetNumTrackedAchievements() >= (MAX_TRACKED_ACHIEVEMENTS or 10) then
                NS.Print(Global("ACHIEVEMENT_WATCH_TOO_MANY", "отслеживается слишком много достижений"))
                return
            end
            AddTrackedAchievement(id)
        end

        Panel:Update()
    end)
    track:Hide()
    row.track = track
    row.trackLabel = trackLabel

    row.criteria = {}
    row.bars = {}

    row:SetScript("OnClick", function(self)
        if not self.id then return end

        if IsModifiedClick("CHATLINK") then
            local link = GetAchievementLink(self.id)
            if link then ChatEdit_InsertLink(link) end
            return
        end

        Panel.selection = Panel.selection ~= self.id and self.id or nil
        Panel:Update()
    end)

    row:Hide()
    return row
end

function Panel:CriteriaLine(row, index)
    local S = NS.Styling

    if row.criteria[index] then return row.criteria[index] end

    local line = row:CreateFontString(nil, "OVERLAY")
    line:SetFont(NS.FONT, NS.FS(11), "")
    line:SetJustifyH("LEFT")
    line:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    row.criteria[index] = line

    return line
end

function Panel:CriteriaBar(row, index)
    local S = NS.Styling

    if row.bars[index] then return row.bars[index] end

    local bar = CreateFrame("Frame", nil, row)
    bar:SetHeight(14)

    local track = bar:CreateTexture(nil, "ARTWORK")
    track:SetAllPoints()
    track:SetTexture(WHITE)
    track:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local fill = bar:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    bar.fill = fill

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    text:SetPoint("CENTER")
    bar.text = text

    row.bars[index] = bar
    return bar
end

function Panel:FillAchievement(row, id)
    local S = NS.Styling
    local achievementID, name, points, completed, month, day, year, description, flags, icon, rewardText =
        GetAchievementInfo(id)

    if not achievementID then
        row:Hide()
        return 0
    end

    row.id = achievementID
    row.completed = completed

    row.icon:SetTexture(icon or QUESTION)
    row.icon:SetDesaturated(not completed)

    row.label:SetText(name or "")
    row.label:SetTextColor(
        completed and S.TEXT_BRIGHT[1] or 0.55,
        completed and S.TEXT_BRIGHT[2] or 0.55,
        completed and S.TEXT_BRIGHT[3] or 0.58)

    row.description:SetText(description or "")

    row.shield:SetTexture((points or 0) > 0 and SHIELD or SHIELD_NOPOINTS)
    row.shield:SetTexCoord(0, 0.5, 0, 0.5)
    row.shield:SetDesaturated(not completed)
    row.points:SetText(points or 0)
    row.points:SetTextColor(
        completed and 1 or 0.6,
        completed and 1 or 0.6,
        completed and 1 or 0.6)

    if completed and month then
        row.date:SetText(string.format(SHORTDATE or "%d.%d.%d", day, month, year))
    else
        row.date:SetText("")
    end

    local height = ROW_H
    local expanded = Panel.selection == achievementID

    row.border:SetBackdropBorderColor(
        expanded and S.ACCENT[1] or S.BORDER[1],
        expanded and S.ACCENT[2] or S.BORDER[2],
        expanded and S.ACCENT[3] or S.BORDER[3], expanded and 1 or 0.5)

    for _, line in ipairs(row.criteria) do line:Hide() end
    for _, bar in ipairs(row.bars) do bar:Hide() end
    row.reward:Hide()
    row.track:Hide()
    row.trackLabel:Hide()

    if expanded then
        local y = -ROW_H + 4
        local numCriteria = GetAchievementNumCriteria(achievementID) or 0
        local lines, bars = 0, 0
        local textCount, barCount = 0, 0
        for index = 1, numCriteria do
            local _, _, _, _, _, _, flags = GetAchievementCriteriaInfo(achievementID, index)
            local bar = flags and ACHIEVEMENT_CRITERIA_PROGRESS_BAR
                and bit.band(flags, ACHIEVEMENT_CRITERIA_PROGRESS_BAR) == ACHIEVEMENT_CRITERIA_PROGRESS_BAR
            if bar then barCount = barCount + 1 else textCount = textCount + 1 end
        end
        local fullW = row:GetWidth() - 80
        local columns = barCount > 0 and 1 or textCount > 8 and 3 or textCount > 4 and 2 or 1
        while columns > 1 and fullW / columns < 150 do columns = columns - 1 end
        local columnW = fullW / columns
        local perColumn = math.ceil(textCount / columns)
        local gridTop

        for index = 1, numCriteria do
            local criteriaString, criteriaType, criteriaCompleted, quantity, reqQuantity,
                _, criteriaFlags, assetID, quantityString = GetAchievementCriteriaInfo(achievementID, index)

            local isBar = criteriaFlags and ACHIEVEMENT_CRITERIA_PROGRESS_BAR
                and bit.band(criteriaFlags, ACHIEVEMENT_CRITERIA_PROGRESS_BAR) == ACHIEVEMENT_CRITERIA_PROGRESS_BAR

            if isBar then
                bars = bars + 1
                local bar = self:CriteriaBar(row, bars)
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", row, "TOPLEFT", 58, y)
                bar:SetPoint("RIGHT", row, "RIGHT", -14, 0)

                local ratio = (reqQuantity or 0) > 0 and math.min(1, (quantity or 0) / reqQuantity) or 0
                bar.fill:SetWidth(math.max(1, (row:GetWidth() - 72) * ratio))
                bar.text:SetText(quantityString or string.format("%d / %d", quantity or 0, reqQuantity or 0))
                bar:Show()

                y = y - 18
            else
                lines = lines + 1
                local line = self:CriteriaLine(row, lines)
                line:ClearAllPoints()
                if columns > 1 then
                    gridTop = gridTop or y
                    local column = math.floor((lines - 1) / perColumn)
                    local slot = (lines - 1) % perColumn
                    line:SetPoint("TOPLEFT", row, "TOPLEFT", 58 + column * columnW, gridTop - slot * 15)
                    line:SetWidth(columnW - 8)
                    line:SetHeight(14)
                else
                    line:SetPoint("TOPLEFT", row, "TOPLEFT", 58, y)
                    line:SetWidth(fullW)
                    line:SetHeight(0)
                end

                local text = criteriaString or ""
                if criteriaType == (CRITERIA_TYPE_ACHIEVEMENT or 8) and assetID then
                    local _, metaName = GetAchievementInfo(assetID)
                    if metaName then text = metaName end
                end

                if (reqQuantity or 0) > 1 and not criteriaCompleted then
                    text = string.format("%s  (%d / %d)", text, quantity or 0, reqQuantity)
                end

                line:SetText(text)

                if criteriaCompleted then
                    line:SetTextColor(0.4, 0.85, 0.45)
                else
                    line:SetTextColor(0.6, 0.6, 0.62)
                end

                line:Show()
                if columns == 1 then y = y - 15 end
            end
        end
        if gridTop then y = gridTop - perColumn * 15 end

        if rewardText and rewardText ~= "" then
            row.reward:ClearAllPoints()
            row.reward:SetPoint("TOPLEFT", row, "TOPLEFT", 58, y - 4)
            row.reward:SetPoint("RIGHT", row, "RIGHT", -14, 0)
            row.reward:SetText(rewardText)
            row.reward:Show()
            y = y - row.reward:GetStringHeight() - 8
        end

        if not completed then
            row.track:ClearAllPoints()
            row.track:SetPoint("TOPLEFT", row, "TOPLEFT", 58, y - 4)
            row.track:Show()
            row.trackLabel:Show()
            row.track.check:SetShown(IsTrackedAchievement(achievementID))
            y = y - 22
        end

        height = math.max(ROW_H, -y + 8)
    end

    row:SetHeight(height)
    row:Show()

    return height
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_Achievements", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.97))
    S.WindowSounds(f)
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 6, 0.45)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -16)
    title:SetText(Global("ACHIEVEMENTS", "Достижения"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    local pointsLabel = f:CreateFontString(nil, "OVERLAY")
    pointsLabel:SetFont(NS.FONT, NS.FS(11), "")
    pointsLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pointsLabel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 92, -20)
    pointsLabel:SetText(Global("ACHIEVEMENT_POINTS", "Очки достижений"))

    local pointsValue = f:CreateFontString(nil, "OVERLAY")
    pointsValue:SetFont(NS.FONT, NS.FS(16), "OUTLINE")
    pointsValue:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    pointsValue:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 34, -17)
    f.pointsValue = pointsValue

    S.CreateAnimatedSeparator(f, -72)

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -46)
    search:SetScript("OnTextChanged", function(self)
        Panel:SetSearch(self:GetText() or "")
    end)
    f.search = search

    local categories = CreateFrame("Frame", nil, f)
    categories:SetWidth(CAT_W)
    categories:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -86)
    categories:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, 20)
    Chrome(categories)
    f.categories = categories

    categories:EnableMouseWheel(true)
    categories:SetScript("OnMouseWheel", function(_, delta)
        local total = #Panel:DisplayCategories()
        if total <= CAT_ROWS then return end
        Panel.catOffset = math.max(0, math.min(total - CAT_ROWS, (Panel.catOffset or 0) - delta))
        Panel:Update()
    end)

    f.catRows = {}
    for index = 1, CAT_ROWS do
        f.catRows[index] = self:CreateCategoryRow(categories, index)
    end

    local contentX = PAD + CAT_W + 14

    local filter = NS.Widgets.CreateOptionPicker(f, {
        { key = "all", label = Global("ACHIEVEMENTFRAME_FILTER_ALL", "Все") },
        { key = "complete", label = Global("ACHIEVEMENTFRAME_FILTER_COMPLETED", "Полученные") },
        { key = "incomplete", label = Global("ACHIEVEMENTFRAME_FILTER_INCOMPLETE", "Незавершенные") },
    }, "all", function(key)
        Panel.filter = key
        Panel.offset = 0
        Panel:Update()
    end, 400)
    filter:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -86)
    f.filter = filter

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -112)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 20)
    Chrome(content)
    f.content = content

    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        Panel:Scroll(delta)
    end)

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateAchievementRow(content, index)
    end

    f.statRows = {}
    for index = 1, STAT_ROWS do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8 - (index - 1) * 24)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -8 - (index - 1) * 24)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)
        row.plate = plate

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(12), "")
        label:SetPoint("LEFT", row, "LEFT", 10, 0)
        label:SetJustifyH("LEFT")
        row.label = label

        local value = row:CreateFontString(nil, "OVERLAY")
        value:SetFont(NS.FONT, NS.FS(12), "")
        value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        value:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        value:SetJustifyH("RIGHT")
        row.value = value

        row:Hide()
        f.statRows[index] = row
    end

    self:CreateSummary(f, content)

    f.tabs = {}
    local tabs = {
        { key = "achievements", label = Global("ACHIEVEMENTS", "Достижения") },
        { key = "stats", label = Global("STATISTICS", "Статистика") },
    }

    local x = PAD
    for index, tab in ipairs(tabs) do
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(26)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        button.label = label
        button:SetWidth(math.max(label:GetStringWidth() + 26, 120))

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
        bar:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

        button:SetScript("OnClick", function()
            Panel.tab = tab.key
            Panel.category = "summary"
            Panel.selection = nil
            Panel.expanded = nil
            Panel.offset = 0
            Panel.catOffset = 0
            Panel:BuildCategories()
            Panel:Update()
        end)

        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, -30)
        x = x + button:GetWidth() + 6

        button.tabKey = tab.key
        f.tabs[index] = button
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("ACHIEVEMENT_EARNED")
    events:RegisterEvent("CRITERIA_UPDATE")
    events:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")
    events:SetScript("OnEvent", function()
        if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_Achievements")

    self.frame = f
    self.tab = self.tab or "achievements"
    self.category = self.category or "summary"
    self.filter = self.filter or "all"
    self.offset = 0
    self.catOffset = 0
    self.statOffset = 0

    f:Hide()
end

function Panel:CreateSummary(f, content)
    local S = NS.Styling

    local summary = CreateFrame("Frame", nil, content)
    summary:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    summary:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    f.summary = summary

    local recentCaption = Caption(summary, L["НЕДАВНИЕ ДОСТИЖЕНИЯ"])
    recentCaption:SetPoint("TOPLEFT", summary, "TOPLEFT", 12, -10)

    summary.recent = {}
    for index = 1, SUMMARY_MAX do
        local row = CreateFrame("Button", nil, summary)
        row:SetHeight(44)
        row:SetPoint("TOPLEFT", summary, "TOPLEFT", 12, -26 - (index - 1) * 48)
        row:SetPoint("TOPRIGHT", summary, "TOPRIGHT", -12, -26 - (index - 1) * 48)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.3)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon = icon

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(12), "")
        label:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        label:SetPoint("RIGHT", row, "RIGHT", -118, 0)
        label:SetJustifyH("LEFT")
        row.label = label

        local description = row:CreateFontString(nil, "OVERLAY")
        description:SetFont(NS.FONT, NS.FS(10), "")
        description:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        description:SetPoint("RIGHT", row, "RIGHT", -118, 0)
        description:SetJustifyH("LEFT")
        row.description = description

        local date = row:CreateFontString(nil, "OVERLAY")
        date:SetFont(NS.FONT, NS.FS(10), "")
        date:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        date:SetPoint("RIGHT", row, "RIGHT", -46, 0)
        row.date = date

        local points = row:CreateFontString(nil, "OVERLAY")
        points:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
        points:SetTextColor(1, 1, 1)
        points:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        row.points = points

        row:SetScript("OnClick", function(self)
            if not self.id then return end

            if IsModifiedClick("CHATLINK") then
                local link = GetAchievementLink(self.id)
                if link then ChatEdit_InsertLink(link) end
                return
            end

            local category = GetAchievementCategory and GetAchievementCategory(self.id)
            if category then
                local _, parent = GetCategoryInfo(category)
                Panel:SelectCategory(category, parent ~= -1 and parent or nil)
            end

            Panel.selection = self.id
            Panel:Update()
        end)

        row:Hide()
        summary.recent[index] = row
    end

    local progressCaption = Caption(summary, L["ОБЩИЙ ПРОГРЕСС"])
    progressCaption:SetPoint("TOPLEFT", summary, "TOPLEFT", 12, -26 - SUMMARY_MAX * 48 - 8)

    local totalTrack = summary:CreateTexture(nil, "ARTWORK")
    totalTrack:SetHeight(18)
    totalTrack:SetPoint("TOPLEFT", progressCaption, "BOTTOMLEFT", 0, -6)
    totalTrack:SetPoint("RIGHT", summary, "RIGHT", -12, 0)
    totalTrack:SetTexture(WHITE)
    totalTrack:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))
    summary.totalTrack = totalTrack

    local totalFill = summary:CreateTexture(nil, "OVERLAY")
    totalFill:SetHeight(18)
    totalFill:SetPoint("LEFT", totalTrack, "LEFT", 0, 0)
    totalFill:SetTexture(WHITE)
    totalFill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    summary.totalFill = totalFill

    local totalText = summary:CreateFontString(nil, "OVERLAY")
    totalText:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    totalText:SetPoint("CENTER", totalTrack, "CENTER", 0, 0)
    summary.totalText = totalText

    summary.bars = {}
    for index = 1, 10 do
        local bar = CreateFrame("Frame", nil, summary)
        bar:SetHeight(18)

        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)

        bar:SetPoint("TOPLEFT", totalTrack, "BOTTOMLEFT", column * 268, -8 - row * 24)
        bar:SetWidth(258)

        local track = bar:CreateTexture(nil, "ARTWORK")
        track:SetAllPoints()
        track:SetTexture(WHITE)
        track:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

        local fill = bar:CreateTexture(nil, "OVERLAY")
        fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        fill:SetTexture(WHITE)
        fill:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.95)
        bar.fill = fill

        local label = bar:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
        label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        label:SetPoint("LEFT", bar, "LEFT", 6, 0)
        label:SetPoint("RIGHT", bar, "RIGHT", -56, 0)
        label:SetJustifyH("LEFT")
        bar.label = label

        local count = bar:CreateFontString(nil, "OVERLAY")
        count:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
        count:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        count:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
        bar.count = count

        bar:Hide()
        summary.bars[index] = bar
    end
end

function Panel:SetSearch(text)
    text = text or ""
    self.searchText = text

    if text == "" then
        if ClearAchievementSearchString then ClearAchievementSearchString() end
        self.searching = false
        self:Update()
        return
    end

    if not SetAchievementSearchString then return end

    if SwitchAchievementSearchTab then
        SwitchAchievementSearchTab(self.tab == "stats" and 2 or 1)
    end

    SetAchievementSearchString(text)
    self.searching = true
    self.offset = 0
    self:StartSearchTicker()
    self:Update()
end

function Panel:StartSearchTicker()
    if self.searchTicking then return end
    self.searchTicking = true

    local function Step()
        if not self.frame or not self.frame:IsShown() or not self.searching then
            self.searchTicking = false
            return
        end

        if GetAchievementSearchProgress then GetAchievementSearchProgress() end

        self:Update()
        NS.After(0.1, Step)
    end

    NS.After(0.1, Step)
end

function Panel:Scroll(delta)
    if self.tab == "stats" then
        local total = #(self.statList or {})
        if total <= STAT_ROWS then return end
        self.statOffset = math.max(0, math.min(total - STAT_ROWS, (self.statOffset or 0) - delta))
    else
        local total = self.rowCount or 0
        if total <= ROWS then return end
        self.offset = math.max(0, math.min(total - ROWS, (self.offset or 0) - delta))
    end

    self:Update()
end

function Panel:UpdateCategories()
    local S = NS.Styling
    local f = self.frame
    local display = self:DisplayCategories()
    local offset = math.max(0, math.min(self.catOffset or 0, math.max(0, #display - CAT_ROWS)))
    self.catOffset = offset

    for index = 1, CAT_ROWS do
        local row = f.catRows[index]
        local entry = display[index + offset]

        if entry then
            row.categoryID = entry.id
            row.parentID = entry.parent

            if entry.id == "summary" then
                row.label:SetText(Global("ACHIEVEMENT_SUMMARY_CATEGORY", "Сводка"))
                local total, completed = GetNumCompletedAchievements()
                row.total, row.completed = total, completed
                row.count:SetText("")
            else
                local name = GetCategoryInfo(entry.id)
                row.label:SetText(name or "")

                if self.tab == "stats" then
                    row.total, row.completed = nil, nil
                    row.count:SetText("")
                else
                    local total, completed = self:CategoryTotals(entry.id)
                    row.total, row.completed = total, completed
                    row.count:SetText(string.format("%d/%d", completed, total))
                end
            end

            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row, "LEFT", entry.parent and 22 or 8, 0)
            row.label:SetPoint("RIGHT", row.count, "LEFT", -6, 0)
            row.label:SetTextColor(
                entry.parent and S.TEXT_NORMAL[1] or S.TEXT_BRIGHT[1],
                entry.parent and S.TEXT_NORMAL[2] or S.TEXT_BRIGHT[2],
                entry.parent and S.TEXT_NORMAL[3] or S.TEXT_BRIGHT[3])

            row.plate:SetShown(entry.id == self.category)
            row:Show()
        else
            row.categoryID = nil
            row:Hide()
        end
    end
end

function Panel:UpdateSummary()
    local f = self.frame
    local summary = f.summary

    local latest = { GetLatestCompletedAchievements() }

    for index = 1, SUMMARY_MAX do
        local row = summary.recent[index]
        local id = latest[index]

        if id then
            local achievementID, name, points, completed, month, day, year, description, _, icon =
                GetAchievementInfo(id)

            row.id = achievementID
            row.icon:SetTexture(icon or QUESTION)
            row.label:SetText(name or "")
            row.description:SetText(description or "")
            row.points:SetText(points or 0)
            row.date:SetText(completed and month
                and string.format(SHORTDATE or "%d.%d.%d", day, month, year) or "")
            row:Show()
        else
            row.id = nil
            row:Hide()
        end
    end

    local total, completed = GetNumCompletedAchievements()
    total = total or 0
    completed = completed or 0

    local width = summary.totalTrack:GetWidth() or 1
    summary.totalFill:SetWidth(math.max(1, width * (total > 0 and completed / total or 0)))
    summary.totalText:SetText(string.format("%d / %d", completed, total))

    local index = 0
    for _, category in ipairs(self.categories or {}) do
        if category.id ~= "summary" and not category.parent and index < #summary.bars then
            index = index + 1
            local bar = summary.bars[index]
            local name = GetCategoryInfo(category.id)
            local categoryTotal, categoryDone = self:CategoryTotals(category.id)

            bar.label:SetText(name or "")
            bar.count:SetText(string.format("%d/%d", categoryDone, categoryTotal))
            bar.fill:SetWidth(math.max(1, 258 * (categoryTotal > 0 and categoryDone / categoryTotal or 0)))
            bar:Show()
        end
    end

    for position = index + 1, #summary.bars do summary.bars[position]:Hide() end
end

function Panel:AchievementIDs()
    local ids = {}

    if self.searching and self.searchText ~= "" and GetNumFilteredAchievements then
        for index = 1, GetNumFilteredAchievements() do
            ids[#ids + 1] = GetFilteredAchievementID(index)
        end
        return ids
    end

    if self.category == "summary" then return ids end

    local numAchievements, _, completedOffset = self:FilterCounts(self.category)

    for index = 1, numAchievements do
        local id = GetAchievementInfo(self.category, index + completedOffset)
        if id then ids[#ids + 1] = id end
    end

    return ids
end

function Panel:UpdateAchievements()
    local f = self.frame
    local ids = self:AchievementIDs()

    self.rowCount = #ids

    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #ids - ROWS)))
    self.offset = offset

    local limit = (f.content:GetHeight() or 0) - 8

    local function Lay(start)
        local y = -8
        local fits = true
        for index = 1, ROWS do
            local row = f.rows[index]
            local id = ids[index + start]
            if id and fits then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", f.content, "TOPLEFT", 8, y)
                row:SetPoint("TOPRIGHT", f.content, "TOPRIGHT", -8, y)
                local height = self:FillAchievement(row, id)
                if index > 1 and limit > 0 and -y + height > limit then
                    row:Hide()
                    fits = false
                    if id == self.selection then return false end
                else
                    y = y - height - 4
                end
            else
                row.id = nil
                row:Hide()
            end
        end
        return true
    end

    if not Lay(offset) and self.selection then
        for index = 1, #ids do
            if ids[index] == self.selection then
                offset = index - 1
                break
            end
        end
        self.offset = offset
        Lay(offset)
    end
end

function Panel:BuildStatList()
    local list = {}
    local category = self.category

    if category == "summary" then
        for _, entry in ipairs(self.categories or {}) do
            if entry.id ~= "summary" and not entry.parent then
                list[#list + 1] = { header = true, id = entry.id }
                local count = GetCategoryNumAchievements(entry.id) or 0
                for index = 1, count do
                    list[#list + 1] = { id = GetAchievementInfo(entry.id, index) }
                end
            end
        end
    else
        list[#list + 1] = { header = true, id = category }

        local count = GetCategoryNumAchievements(category) or 0
        for index = 1, count do
            list[#list + 1] = { id = GetAchievementInfo(category, index) }
        end

        for _, entry in ipairs(self.categories or {}) do
            if entry.parent == category then
                list[#list + 1] = { header = true, id = entry.id }
                local subCount = GetCategoryNumAchievements(entry.id) or 0
                for index = 1, subCount do
                    list[#list + 1] = { id = GetAchievementInfo(entry.id, index) }
                end
            end
        end
    end

    self.statList = list
    return list
end

function Panel:UpdateStats()
    local S = NS.Styling
    local f = self.frame
    local list = self:BuildStatList()
    local offset = math.max(0, math.min(self.statOffset or 0, math.max(0, #list - STAT_ROWS)))
    self.statOffset = offset

    for index = 1, STAT_ROWS do
        local row = f.statRows[index]
        local entry = list[index + offset]

        if entry then
            if entry.header then
                local name = GetCategoryInfo(entry.id)
                row.label:SetText(string.upper(name or ""))
                row.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                row.value:SetText("")
                row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
            else
                local id, name = GetAchievementInfo(entry.id)
                row.label:SetText(name or "")
                row.label:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                row.value:SetText(id and GetStatistic(id) or "--")
                row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                    index % 2 == 0 and 0.30 or 0.12)
            end

            row:Show()
        else
            row:Hide()
        end
    end
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling

    if not self.categories then self:BuildCategories() end

    for _, button in ipairs(f.tabs) do
        local active = button.tabKey == self.tab
        button:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or S.BORDER[4])
        button.bar:SetShown(active)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_DIM[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_DIM[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_DIM[3])
    end

    f.pointsValue:SetText(GetTotalAchievementPoints() or 0)

    local searching = self.searching and self.searchText and self.searchText ~= ""

    if self.category == "summary" and not searching then
        f.subtitle:SetText(Global("ACHIEVEMENT_SUMMARY_CATEGORY", "Сводка"))
    elseif searching then
        f.subtitle:SetText(string.format(L["поиск: %s"], self.searchText))
    else
        f.subtitle:SetText(GetCategoryInfo(self.category) or "")
    end

    self:UpdateCategories()

    local stats = self.tab == "stats" and not searching
    local summaryView = self.category == "summary" and not searching and not stats

    f.filter:SetShown(not stats and not summaryView)
    f.summary:SetShown(summaryView)

    for _, row in ipairs(f.statRows) do row:SetShown(stats) end

    if summaryView then
        for _, row in ipairs(f.rows) do row:Hide() end
        self:UpdateSummary()
    elseif stats then
        for _, row in ipairs(f.rows) do row:Hide() end
        self:UpdateStats()
    else
        f.filter:Refresh(self.filter)
        self:UpdateAchievements()
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self:BuildCategories()
    self.frame:Show()
    self:Update()
end

function Panel:Hide()
    if self.frame then self.frame:Hide() end
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.AchievementsPanel = Panel
