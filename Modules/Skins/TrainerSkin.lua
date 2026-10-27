local addonName, NS = ...

local TrainerSkin = {}
NS.TrainerSkin = TrainerSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local ROWS = 11

local DIM_PATHS = {
    "ui%-classtrainer%-",
    "ui%-questlogsorttab",
    "ui%-emptyslot",
    "ui%-listbox%-highlight",
}

local function Kit()
    return NS.SkinKit
end

local function Mail()
    return NS.MailSkin
end

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinTrainer ~= false
end

local function DimTextures(frame)
    if not frame or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" and not region.narciKeepVisible then
            local ok, path = pcall(region.GetTexture, region)
            path = ok and type(path) == "string" and path:lower()

            if path then
                for _, pattern in ipairs(DIM_PATHS) do
                    if path:find(pattern) then
                        region:SetAlpha(0)
                        break
                    end
                end
            end
        end
    end
end

local function Panel(anchor, left, top, right, bottom)
    local S = Style()

    local panel = CreateFrame("Frame", nil, anchor:GetParent() or anchor)
    panel:SetPoint("TOPLEFT", anchor, "TOPLEFT", left, top)
    panel:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", right, bottom)
    panel:SetFrameLevel(math.max(anchor:GetFrameLevel() - 1, 1))

    local fill = panel:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints(panel)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(0, 0, 0, 0.30)

    S.CreateEdges(panel, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)

    return panel
end

local function SkinIcon()
    local icon = _G.ClassTrainerSkillIcon
    if not icon or icon.narciTrainerIcon then return end
    icon.narciTrainerIcon = true

    Mail().Slot(icon, true)
end

local function PaintIcon()
    local icon = _G.ClassTrainerSkillIcon
    if not icon then return end

    local texture = icon:GetNormalTexture()
    if texture then
        texture:SetAlpha(1)
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
        texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

local function SkinSelection()
    local S = Style()
    local highlight = _G.ClassTrainerSkillHighlight
    local holder = _G.ClassTrainerSkillHighlightFrame
    if not highlight or not holder or holder.narciSelection then return end
    holder.narciSelection = true

    highlight:SetTexture(WHITE)
    highlight:SetAlpha(((NS.db and NS.db.trainerSelect) or 22) / 100)

    local bar = holder:CreateTexture(nil, "OVERLAY")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
end

local function SkinRow(button)
    if not button or button.narciTrainerRow then return end
    button.narciTrainerRow = true
    button.narciOwn = true

    local S = Style()

    local hover = button:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.14,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
    hover:Hide()

    button:HookScript("OnEnter", function() hover:Show() end)
    button:HookScript("OnLeave", function() hover:Hide() end)
end

function TrainerSkin:Skin()
    local frame = _G.ClassTrainerFrame
    if not frame or frame.narciTrainer then return end
    frame.narciTrainer = true

    local K = Kit()
    local S = Style()

    for _, key in ipairs({ "ClassTrainerMoneyFrame", "ClassTrainerDetailMoneyFrame" }) do
        local own = _G[key]
        if own then own.narciOwn = true end
    end

    local shell = CreateFrame("Frame", nil, frame)
    shell:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -12)
    shell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 76)
    shell:SetFrameLevel(frame:GetFrameLevel())
    shell.narciOwn = true

    K.Ground(shell)
    K.Edges(shell, 20)
    S.CreateShadow(shell, 6, 0.5)
    S.CreateGradientTopBorder(shell, 2)

    DimTextures(frame)
    Mail().Hide(_G.ClassTrainerFramePortrait)

    local expand = _G.ClassTrainerExpandButtonFrame
    if expand then DimTextures(expand) end

    for _, key in ipairs({ "ClassTrainerListScrollFrame", "ClassTrainerDetailScrollFrame" }) do
        local scroll = _G[key]
        if scroll then
            DimTextures(scroll)
            Panel(scroll, -4, 4, 2, -4)
        end
    end

    for index = 1, ROWS do SkinRow(_G["ClassTrainerSkill" .. index]) end
    SkinRow(_G.ClassTrainerCollapseAllButton)

    SkinSelection()
    SkinIcon()

    K.Auto(frame, 6)

    local close = _G.ClassTrainerFrameCloseButton
    if close then
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", shell, "TOPRIGHT", -4, -4)
    end

    local title = _G.ClassTrainerNameText
    if title then title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]) end

    local greeting = _G.ClassTrainerGreetingText
    if greeting then greeting:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]) end

    local skill = _G.ClassTrainerSkillName
    if skill then skill:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3]) end

    local cost = _G.ClassTrainerCostLabel
    if cost then cost:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3]) end

    PaintIcon()
end

function TrainerSkin:Hook()
    if self.hooked then return end
    if type(_G.ClassTrainer_SetSelection) ~= "function" then return end
    self.hooked = true

    hooksecurefunc("ClassTrainer_SetSelection", function()
        if Enabled() and _G.ClassTrainerFrame and _G.ClassTrainerFrame.narciTrainer then PaintIcon() end
    end)
end

function TrainerSkin:ApplyFilters()
    local filters = NS.db and NS.db.trainerFilter
    if type(filters) ~= "table" or type(SetTrainerServiceTypeFilter) ~= "function" then return end
    local changed = false
    for _, kind in ipairs({ "available", "unavailable", "used" }) do
        if filters[kind] ~= nil then
            pcall(SetTrainerServiceTypeFilter, kind, filters[kind] and 1 or 0)
            changed = true
        end
    end
    if changed and type(_G.ClassTrainerFrame_Update) == "function" then
        NS.After(0, function() pcall(_G.ClassTrainerFrame_Update) end)
    end
end

function TrainerSkin:Apply()
    if not Enabled() or not Kit() or not Mail() or not Mail().Slot then return end
    if not _G.ClassTrainerFrame then return end

    self:Hook()

    local ok, err = pcall(function() TrainerSkin:Skin() end)
    if not ok and NS.Print then NS.Print("учитель: " .. tostring(err)) end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("TRAINER_SHOW")
driver:RegisterEvent("ADDON_LOADED")

driver:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_TrainerUI" then return end

    if event == "TRAINER_SHOW" and NS.After then
        TrainerSkin:ApplyFilters()
        NS.After(0, function() TrainerSkin:Apply() end)
        return
    end

    TrainerSkin:Apply()
end)
