local addonName, NS = ...

local UIScale = {}
NS.UIScale = UIScale

local MIN_SCALE = 0.40
local MAX_SCALE = 1.15

local function Settings()
    if not NS.db then return end

    if not NS.db.uiScale then NS.db.uiScale = {} end

    local db = NS.db.uiScale
    if db.enabled == nil then db.enabled = false end
    if db.auto == nil then db.auto = true end
    db.value = db.value or 1

    return db
end

local function Clamp(scale)
    if not scale or scale ~= scale then return 1 end
    if scale < MIN_SCALE then return MIN_SCALE end
    if scale > MAX_SCALE then return MAX_SCALE end
    return scale
end

function UIScale:ScreenHeight()
    local resolution = GetCVar and GetCVar("gxResolution")
    local height = resolution and tonumber(string.match(resolution, "%d+x(%d+)"))

    if height and height > 0 then return height end

    local fallback = GetScreenHeight() * UIParent:GetEffectiveScale()
    return math.floor(fallback + 0.5)
end

function UIScale:Best()
    return Clamp(768 / self:ScreenHeight())
end

function UIScale:Current()
    local db = Settings()
    if not db or not db.enabled then return UIParent:GetScale() end
    return db.auto and self:Best() or Clamp(db.value)
end

function UIScale:Apply()
    local db = Settings()
    if not db then return end

    if InCombatLockdown() then
        self.pending = true
        return
    end

    self.pending = nil

    if not db.enabled then
        if self.applied then
            self.applied = nil
            UIParent:SetScale(self.original or 1)
            self:RestoreChat()
        end
        return
    end

    if not self.original then self.original = UIParent:GetScale() end

    local scale = self:Current()
    local before = UIParent:GetScale()

    UIParent:SetScale(scale)
    self.applied = scale

    if math.abs(before - scale) > 0.0001 then self:RestoreChat() end

    if NS.NarciUI and NS.NarciUI.ApplyScale then
        NS.NarciUI:ApplyScale()
    end
end

function UIScale:RestoreChat()
    local restore = _G.FCF_RestorePositionAndDimensions
    if type(restore) ~= "function" then return end
    for index = 1, (_G.NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. index]
        if frame and (index == 1 or (not frame.isDocked and frame:IsShown())) then
            pcall(restore, frame)
        end
    end
    if NS.ChatSkin and NS.ChatSkin.LayoutPanels then pcall(NS.ChatSkin.LayoutPanels, NS.ChatSkin) end
end

function UIScale:SetEnabled(value)
    local db = Settings()
    if not db then return end

    db.enabled = value and true or false
    self:Apply()
end

function UIScale:SetAuto(value)
    local db = Settings()
    if not db then return end

    db.auto = value and true or false

    if db.auto then db.value = self:Best() end

    self:Apply()
end

function UIScale:SetValue(value)
    local db = Settings()
    if not db then return end

    db.value = Clamp(tonumber(value) or 1)
    db.auto = false
    self:Apply()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")
driver:RegisterEvent("UI_SCALE_CHANGED")

driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" and not UIScale.pending then return end

    if event == "PLAYER_LOGIN" then
        if NS.After then
            NS.After(0.1, function() UIScale:Apply() end)
        else
            UIScale:Apply()
        end
        return
    end

    UIScale:Apply()
end)
