local addonName, NS = ...

local Options = {}
NS.QuestOptions = Options

local WIDTH = 320
local frame

local EVENT_LABELS = {
    { key = "accept",   label = "взятие задания" },
    { key = "progress", label = "прогресс по цели" },
    { key = "objdone",  label = "цель выполнена" },
    { key = "complete", label = "задание завершено" },
    { key = "turnin",   label = "задание сдано" },
    { key = "abandon",  label = "задание брошено" },
    { key = "fail",     label = "задание провалено" },
}

local function S()
    return NS.QuestStyle
end

local function AddCheck(parent, caption, offset, get, set)
    local check = S().CheckBox(parent, caption, WIDTH - 40)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -offset)
    check:SetChecked(get())
    check:SetScript("OnClick", function(self)
        set(not get())
        self:SetChecked(get())
    end)
    return check
end

function Options:Create()
    if frame then return frame end
    local st = S()
    local db = NS.questDB

    frame = CreateFrame("Frame", "NarcissusSirus_QuestOptions", UIParent)
    frame:SetWidth(WIDTH)
    frame:SetHeight(430)
    frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    st.Backdrop(frame, st.BG[1], st.BG[2], st.BG[3], st.BG[4])
    NS.Styling.RoundCorners(frame)
    tinsert(UISpecialFrames, "NarcissusSirus_QuestOptions")

    local title = st.Label(frame, 14, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12)
    title:SetText("Задания: настройки")
    title:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])

    local close = st.Button(frame, "X", 22, 20)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() frame:Hide() end)

    local offset = 44

    AddCheck(frame, "заменять штатный журнал заданий", offset,
        function() return db.replaceLog end,
        function(value) db.replaceLog = value end)
    offset = offset + 22

    AddCheck(frame, "оформлять карту мира в стиле аддона", offset,
        function() return db.skinWorldMap ~= false end,
        function(value)
            db.skinWorldMap = value
            if NS.WorldMapSkin then
                if value then NS.WorldMapSkin:Apply() else NS.WorldMapSkin:Remove() end
            end
        end)
    offset = offset + 22

    AddCheck(frame, "показывать неисследованные области карты", offset,
        function() return db.revealMap end,
        function(value)
            db.revealMap = value
            if NS.QuestLog and NS.QuestLog:IsShown() then NS.QuestLog:Refresh() end
        end)
    offset = offset + 30

    local section = st.Label(frame, 11)
    section:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -offset)
    section:SetText("Куда отправлять")
    section:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
    offset = offset + 20

    AddCheck(frame, "группа", offset,
        function() return db.channels.party end,
        function(value) db.channels.party = value end)
    offset = offset + 22

    AddCheck(frame, "рейд", offset,
        function() return db.channels.raid end,
        function(value) db.channels.raid = value end)
    offset = offset + 22

    AddCheck(frame, "гильдия", offset,
        function() return db.channels.guild end,
        function(value) db.channels.guild = value end)
    offset = offset + 30

    local section2 = st.Label(frame, 11)
    section2:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -offset)
    section2:SetText("Оповещения")
    section2:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
    offset = offset + 20

    AddCheck(frame, "баннеры на экране", offset,
        function() return db.banners end,
        function(value) db.banners = value end)
    offset = offset + 22

    AddCheck(frame, "дублировать в чат", offset,
        function() return db.chatOutput end,
        function(value) db.chatOutput = value end)
    offset = offset + 22

    AddCheck(frame, "показывать свои события", offset,
        function() return db.ownBanners end,
        function(value) db.ownBanners = value end)
    offset = offset + 22

    AddCheck(frame, "писать о своих в чат группы", offset,
        function() return db.announce end,
        function(value) db.announce = value end)
    offset = offset + 22

    AddCheck(frame, "сообщать, когда все закончили", offset,
        function() return db.everyoneNotice end,
        function(value) db.everyoneNotice = value end)
    offset = offset + 30

    local section3 = st.Label(frame, 11)
    section3:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -offset)
    section3:SetText("Какие события показывать")
    section3:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
    offset = offset + 20

    for _, entry in ipairs(EVENT_LABELS) do
        AddCheck(frame, entry.label, offset,
            function() return db.events[entry.key] ~= false end,
            function(value) db.events[entry.key] = value end)
        offset = offset + 22
    end

    frame:SetHeight(offset + 20)
    frame:Hide()
    return frame
end

function Options:Toggle()
    self:Create()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
