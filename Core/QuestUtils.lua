local addonName, NS = ...

function NS.Cut(text, maxBytes)
    text = tostring(text or "")
    if #text <= maxBytes then return text end
    local cut = maxBytes
    while cut > 0 do
        local byte = string.byte(text, cut)
        if byte < 128 or byte >= 192 then break end
        cut = cut - 1
    end
    local byte = string.byte(text, cut)
    if byte and byte >= 192 then cut = cut - 1 end
    return string.sub(text, 1, cut)
end

function NS.Trim(text)
    return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
end

function NS.PlayerName()
    return (UnitName("player"))
end

function NS.ClassColor(class)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.8, 0.8, 0.85
end

function NS.InParty()
    return (GetNumPartyMembers() or 0) > 0
end

function NS.InRaid()
    return (GetNumRaidMembers() or 0) > 0
end

function NS.GroupChannel()
    if NS.InRaid() then return "RAID" end
    if NS.InParty() then return "PARTY" end
    return nil
end

function NS.UnitForName(name)
    if name == NS.PlayerName() then return "player" end
    if NS.InRaid() then
        for index = 1, GetNumRaidMembers() do
            local unit = "raid" .. index
            if UnitName(unit) == name then return unit end
        end
    elseif NS.InParty() then
        for index = 1, GetNumPartyMembers() do
            local unit = "party" .. index
            if UnitName(unit) == name then return unit end
        end
    end
    return nil
end
