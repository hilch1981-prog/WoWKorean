local addon = WoWKoreanClient
if not addon.active then return end

local G = _G or getfenv(0)
local vanilla = addon.interface == 11200
local remainder = math.fmod or math.mod
local fontPath = "Interface\\AddOns\\" .. addon.folder .. "\\Fonts\\NanumGothic-Regular.ttf"
local fontChanges = setmetatable({}, { __mode = "k" })

local function Normalize(text)
    if type(text) ~= "string" then return "" end
    text = string.lower(text)
    text = string.gsub(text, "’", "'")
    text = string.gsub(text, "‘", "'")
    text = string.gsub(text, "“", '"')
    text = string.gsub(text, "”", '"')
    text = string.gsub(text, " ", " ")
    text = string.gsub(text, "%$[bB]", " ")
    text = string.gsub(text, "|n", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^ ", "")
    return (string.gsub(text, " $", ""))
end

local races = { Scourge = "Undead", NightElf = "Night Elf", BloodElf = "Blood Elf" }
local classes = { DEATHKNIGHT = "Death Knight" }
local koRaces = {
    Human = "인간", Dwarf = "드워프", NightElf = "나이트 엘프", Gnome = "노움",
    Draenei = "드레나이", Worgen = "늑대인간", Orc = "오크", Scourge = "언데드",
    Tauren = "타우렌", Troll = "트롤", BloodElf = "블러드 엘프", Goblin = "고블린",
    Pandaren = "판다렌",
}
local koClasses = {
    WARRIOR = "전사", PALADIN = "성기사", HUNTER = "사냥꾼", ROGUE = "도적",
    PRIEST = "사제", DEATHKNIGHT = "죽음의 기사", SHAMAN = "주술사", MAGE = "마법사",
    WARLOCK = "흑마법사", MONK = "수도사", DRUID = "드루이드",
}

local function Expand(text, korean, localizedRace, localizedClass)
    if not string.find(text, "$", 1, true) then return text end
    local race, raceToken = UnitRace("player")
    local class, classToken = UnitClass("player")
    local englishClass = classToken and (classes[classToken] or
        string.sub(classToken, 1, 1) .. string.lower(string.sub(classToken, 2)))
    local characterNames = addon.characterNames
    local values = {
        b = "\n", n = UnitName("player"),
        r = korean and ((characterNames and characterNames[race]) or koRaces[raceToken] or race) or
            localizedRace and race or races[raceToken] or raceToken or race,
        c = korean and ((characterNames and characterNames[class]) or koClasses[classToken] or class) or
            localizedClass and class or englishClass or class,
    }
    text = string.gsub(text, "%$[gG]([^:;]*):([^;]*);", function(male, female)
        if UnitSex and UnitSex("player") == 3 then return female end
        return male
    end)
    local out, start = {}, 1
    local first, last, token = string.find(text, "%$([bBnNcCrR])", start)
    while first do
        table.insert(out, string.sub(text, start, first - 1))
        table.insert(out, values[string.lower(token)] or string.sub(text, first, last))
        start = last + 1
        first, last, token = string.find(text, "%$([bBnNcCrR])", start)
    end
    table.insert(out, string.sub(text, start))
    return table.concat(out)
end

local function Digest(key)
    local digest = 0
    for index = 1, string.len(key) do
        digest = remainder(digest * 131 + string.byte(key, index), 2147483647)
    end
    return digest
end

local function LookupKey(guard)
    if type(guard) == "table" then return guard[1] .. ":" .. guard[2] end
    local key = Normalize(guard)
    return string.len(key) .. ":" .. Digest(key)
end

local function Matches(guard, key)
    if type(guard) == "table" then
        return string.len(key) == guard[1] and Digest(key) == guard[2]
    end
    if key == Normalize(guard) then return true end
    if not string.find(guard, "$", 1, true) then return false end
    return key == Normalize(Expand(guard, false))
        or key == Normalize(Expand(guard, false, true, false))
        or key == Normalize(Expand(guard, false, false, true))
        or key == Normalize(Expand(guard, false, true, true))
end

local function SelectText(pair, original)
    if not pair or type(original) ~= "string" or original == "" then return end
    if Matches(pair[1], Normalize(original)) then return Expand(pair[2], true) end
end

local function Visible(frame)
    if not frame then return end
    if frame.IsVisible then return frame:IsVisible() end
    return frame:IsShown()
end

local function Display(widget, original, translated)
    if not widget or not translated or translated == original or widget:GetText() ~= original then return end
    local text = (widget.GetFontString and widget:GetFontString()) or widget
    if addon.useFont and text.GetFont and text.SetFont then
        local path, size, flags = text:GetFont()
        if path and size and path ~= fontPath and text:SetFont(fontPath, size, flags or "") then
            fontChanges[text] = {path, size, flags, translated}
        elseif fontChanges[text] then
            fontChanges[text][4] = translated
        end
    end
    widget:SetText(translated)
    return true
end

local titleIndex
local function Candidates(title, id)
    if not title or title == "" then return end
    local key = string.gsub(Normalize(title), "^%[deprecated%] ", "")
    if id and id > 0 then
        local quest = addon.quests[id]
        if quest and (key == Normalize(quest.title[2]) or Matches(quest.title[1], key)) then
            return {quest}
        end
        return
    end
    if not titleIndex then
        titleIndex = {}
        for _, quest in pairs(addon.quests) do
            local source = LookupKey(quest.title[1])
            if not titleIndex[source] then titleIndex[source] = {} end
            table.insert(titleIndex[source], quest)
        end
    end
    return titleIndex[string.len(key) .. ":" .. Digest(key)]
end

local function LogEntry(index)
    if not index or index < 1 then return end
    local title, _, _, fourth, fifth, _, _, _, id = GetQuestLogTitle(index)
    if vanilla then
        if not fourth then
            if not id and GetQuestLink then
                local link = GetQuestLink(index)
                if link then
                    local _, _, linkId = string.find(link, "quest:(%d+)")
                    id = tonumber(linkId)
                end
            end
            return title, tonumber(id)
        end
    elseif not fifth then
        return title, tonumber(id)
    end
end

local function Label(widget, title, korean)
    if not Visible(widget) or not title or not korean then return end
    local text = widget:GetText()
    if not text then return end
    local first, last = string.find(text, title, 1, true)
    if first then
        return Display(widget, text, string.sub(text, 1, first - 1) .. korean .. string.sub(text, last + 1))
    end
end

local function ListTitle(widget, title, id)
    if not Visible(widget) then return end
    local choices = Candidates(title, id)
    if not choices then return end
    local translation
    for _, row in ipairs(choices) do
        if translation and translation ~= row.title[2] then return end
        translation = row.title[2]
    end
    return Label(widget, title, translation)
end

local function Page(title, id, titleWidget, fields)
    local choices = Candidates(title, id)
    if not choices then return end
    local agreed, conflicts = {}, {}
    for _, row in ipairs(choices) do
        local verified = id and id > 0
        for _, field in ipairs(fields) do
            local key, source = field[1], field[3]
            local translated = SelectText(row[key], source)
            if translated then
                verified = true
                conflicts[key] = conflicts[key] or (agreed[key] and agreed[key] ~= translated)
                agreed[key] = translated
            end
        end
        if verified then
            local translated = row.title[2]
            conflicts.title = conflicts.title or (agreed.title and agreed.title ~= translated)
            agreed.title = translated
        end
    end
    local changed
    if not conflicts.title then changed = Label(titleWidget, title, agreed.title) end
    for _, field in ipairs(fields) do
        if not conflicts[field[1]] and Visible(field[2]) then
            changed = Display(field[2], field[3], agreed[field[1]]) or changed
        end
    end
    return changed
end

local function ResizeScroll(scroll)
    if scroll and scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
end

local function QuestFrameText()
    if not Visible(QuestFrame) then return end
    local title = GetTitleText()
    local id = GetQuestID and tonumber(GetQuestID())
    if Visible(QuestFrameDetailPanel) then
        if Page(title, id, QuestTitleText or QuestInfoTitleHeader, {
            {"description", QuestDescription or QuestInfoDescriptionText, GetQuestText()},
            {"objectives", QuestObjectiveText or QuestInfoObjectivesText, GetObjectiveText()},
        }) then ResizeScroll(QuestDetailScrollFrame) end
    elseif Visible(QuestFrameProgressPanel) then
        if Page(title, id, QuestProgressTitleText, {
            {"progress", QuestProgressText, GetProgressText()},
        }) then ResizeScroll(QuestProgressScrollFrame) end
    elseif Visible(QuestFrameRewardPanel) then
        if Page(title, id, QuestRewardTitleText or QuestInfoTitleHeader, {
            {"completion", QuestRewardText or QuestInfoRewardText, GetRewardText()},
        }) then ResizeScroll(QuestRewardScrollFrame) end
    elseif Visible(QuestFrameGreetingPanel) and GetNumActiveQuests and GetNumAvailableQuests then
        local active, available = GetNumActiveQuests(), GetNumAvailableQuests()
        for index = 1, active + available do
            local button = G["QuestTitleButton" .. index]
            local caption
            if index <= active then caption = GetActiveTitle(index)
            else caption = GetAvailableTitle(index - active) end
            if ListTitle(button, caption) and button.GetTextHeight then
                button:SetHeight(button:GetTextHeight() + 2)
            end
        end
    end
end

local function LogText()
    if not Visible(QuestLogFrame) then return end
    local title, id = LogEntry(GetQuestLogSelection())
    if title then
        local description, objectives = GetQuestLogQuestText()
        if Page(title, id, QuestLogQuestTitle or QuestInfoTitleHeader, {
            {"description", QuestLogQuestDescription or QuestInfoDescriptionText, description},
            {"objectives", QuestLogObjectivesText or QuestInfoObjectivesText, objectives},
        }) then ResizeScroll(QuestLogDetailScrollFrame) end
    end
    if vanilla and QuestLogListScrollFrame and QUESTS_DISPLAYED then
        local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
        for index = 1, QUESTS_DISPLAYED do
            ListTitle(G["QuestLogTitle" .. index], LogEntry(index + offset))
        end
    elseif QuestLogScrollFrame and QuestLogScrollFrame.buttons then
        for _, button in ipairs(QuestLogScrollFrame.buttons) do
            if Visible(button) and ListTitle(button, LogEntry(button:GetID())) and QuestLogTitleButton_Resize then
                QuestLogTitleButton_Resize(button)
            end
        end
    end
end

local function GossipText()
    if not Visible(GossipFrame) or not GossipFrame.buttonIndex then return end
    local available, active = {GetGossipAvailableQuests()}, {GetGossipActiveQuests()}
    local availableStride, activeStride = 5, 4
    if vanilla then availableStride, activeStride = 2, 2
    elseif addon.interface == 50400 then availableStride, activeStride = 6, 5 end
    for index = 1, GossipFrame.buttonIndex - 1 do
        local button = G["GossipTitleButton" .. index]
        if Visible(button) then
            local offset = button:GetID() - 1
            local title
            if button.type == "Available" then title = available[offset * availableStride + 1]
            elseif button.type == "Active" then title = active[offset * activeStride + 1] end
            if type(title) == "string" and ListTitle(button, title) and GossipResize then GossipResize(button) end
        end
    end
end

local function WatchText()
    if WATCHFRAME_LINKBUTTONS and Visible(WatchFrame) then
        for _, button in ipairs(WATCHFRAME_LINKBUTTONS) do
            if button.type == "QUEST" and Visible(button) and button.lines and button.startLine then
                local line = button.lines[button.startLine]
                if line then ListTitle(line.text, LogEntry(GetQuestIndexForWatch(button.index))) end
            end
        end
    elseif vanilla and Visible(QuestWatchFrame) then
        local line = 1
        for index = 1, GetNumQuestWatches() do
            local questIndex = GetQuestIndexForWatch(index)
            if questIndex then
                local objectives = GetNumQuestLeaderBoards(questIndex)
                if objectives and objectives > 0 then
                    ListTitle(G["QuestWatchLine" .. line], LogEntry(questIndex))
                    line = line + objectives + 1
                end
            end
        end
    end
end

local unitIndex
local function UnitRow(unit)
    if not unit or UnitIsPlayer(unit) then return end
    local name = UnitName(unit)
    if not name or name == "" then return end
    local guid = UnitGUID and UnitGUID(unit)
    local id
    if type(guid) == "string" then
        if string.find(string.upper(guid), "^0XF1[35][0-9A-F]") then
            id = tonumber(string.sub(guid, 7, 12), 16)
        else
            local _, _, entry = string.find(guid, "^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
            id = tonumber(entry)
        end
    end
    if id and id > 0 then return addon.units[id], name end
    if not vanilla then return end
    if not unitIndex then
        unitIndex = {}
        for _, row in pairs(addon.units) do
            local original = LookupKey(row.title[1])
            local previous = unitIndex[original]
            if previous == nil then unitIndex[original] = row
            elseif previous and previous.title[2] ~= row.title[2] then unitIndex[original] = false end
        end
    end
    return unitIndex[LookupKey(name)], name
end

local function UnitLabel(widget, unit)
    if not Visible(widget) then return end
    local row, original = UnitRow(unit)
    if row then Display(widget, original, SelectText(row.title, original)) end
end

local durationUnits = {
    sec = "초", secs = "초", second = "초", seconds = "초",
    min = "분", mins = "분", minute = "분", minutes = "분",
    hr = "시간", hrs = "시간", hour = "시간", hours = "시간",
    day = "일", days = "일",
}
local renderedNumber = "[%+%-]?%d[%d,.]*"
local rangeEnd = "(" .. renderedNumber .. ")$"
local rangeStart = "^(" .. renderedNumber .. ")"

local function TooltipDescription(pair, original)
    if not pair[3] then return SelectText(pair, original) end
    if not original or original == "" then return end
    local values = {string.match(Normalize(original), pair[1])}
    if not values[1] then return end
    local durations, repeated = pair[3], pair[4]
    for slot, first in ipairs(repeated) do
        if values[slot] ~= values[first] then return end
    end
    for slot, duration in ipairs(durations) do
        if duration == 1 then
            local number, unit = string.match(values[slot], "^(%S+) (%a+)$")
            if not durationUnits[unit] then return end
            values[slot] = number .. durationUnits[unit]
        elseif not string.match(values[slot], "^" .. renderedNumber .. "$") then
            local value = string.gsub(values[slot], "–", "-")
            local low, high = string.match(value, rangeStart .. " to " .. rangeEnd)
            if not low then low, high = string.match(value, rangeStart .. " *%- *" .. rangeEnd) end
            if not low then return end
            values[slot] = low .. "~" .. high
        end
    end
    return (string.gsub(pair[2], "\031(%d+)\031", function(slot)
        return values[tonumber(slot)]
    end))
end

local function TooltipLabel(tooltip, row, original, field)
    if not row or not original then return end
    local name = SelectText(row.title, original)
    if not name then return end
    local prefix = tooltip:GetName() .. "TextLeft"
    Display(G[prefix .. "1"], original, name)
    local description = field and row[field]
    if not description then return end
    for index = 2, tooltip:NumLines() do
        local line = G[prefix .. index]
        local text = line and line:GetText()
        local value = TooltipDescription(description, text)
        if not value and text and string.sub(text, 1, 1) == '"' and string.sub(text, -1) == '"' then
            value = TooltipDescription(description, string.sub(text, 2, -2))
            if value then value = '"' .. value .. '"' end
        end
        Display(line, text, value)
    end
end

local function TooltipText(tooltip)
    if not Visible(tooltip) then return end
    if tooltip.GetItem then
        local name, link = tooltip:GetItem()
        if type(link) == "string" then
            local _, _, id = string.find(link, "item:(%d+)")
            TooltipLabel(tooltip, addon.items[tonumber(id)], name, "description")
            return
        end
    end
    if tooltip.GetSpell then
        local name, _, id = tooltip:GetSpell()
        if name then
            TooltipLabel(tooltip, addon.spells[tonumber(id)], name, "description")
            return
        end
    end
    local unit
    if tooltip.GetUnit then
        local _, token = tooltip:GetUnit()
        unit = token
    elseif vanilla then unit = "mouseover" end
    local row, name = UnitRow(unit)
    TooltipLabel(tooltip, row, name, "description")
end

if addon.interface == 50400 and GameTooltip and hooksecurefunc then
    local function HookAura(method, query)
        if not GameTooltip[method] or not query then return end
        hooksecurefunc(GameTooltip, method, function(tooltip, unit, index, filter)
            local name, _, _, _, _, _, _, _, _, _, id = query(unit, index, filter)
            TooltipLabel(tooltip, addon.spells[tonumber(id)], name, "aura")
        end)
    end
    HookAura("SetUnitAura", UnitAura)
    HookAura("SetUnitBuff", UnitBuff)
    HookAura("SetUnitDebuff", UnitDebuff)
end

local function UpdateText()
    for widget, original in pairs(fontChanges) do
        if widget:GetText() ~= original[4] then
            local font = widget:GetFont()
            if font == fontPath then widget:SetFont(original[1], original[2], original[3] or "") end
            fontChanges[widget] = nil
        end
    end
    QuestFrameText()
    LogText()
    GossipText()
    WatchText()
    UnitLabel(TargetFrameTextureFrameName or TargetFrameName, "target")
    if Visible(GossipFrame) then UnitLabel(GossipFrameNpcNameText or GossipNpcNameFrameText, "npc") end
    if Visible(QuestFrame) then UnitLabel(QuestFrameNpcNameText, "questnpc") end
    if Visible(MerchantFrame) then UnitLabel(MerchantNameText, "npc") end
    TooltipText(GameTooltip)
    TooltipText(ItemRefTooltip)
    if addon.updateWorldText then addon.updateWorldText() end
end

if addon.worldText then
    addon.displayText = Display
    addon.textKey = LookupKey
    addon.expandText = Expand
    addon.isVisible = Visible
end

local elapsed = 0
local updates = CreateFrame("Frame")
updates:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + (delta or arg1 or 0)
    if elapsed >= 0.12 then
        elapsed = 0
        UpdateText()
    end
end)

SLASH_WOWKOREANCLIENT1 = "/wowkorean"
SlashCmdList.WOWKOREANCLIENT = function()
    DEFAULT_CHAT_FRAME:AddMessage("WoWKorean · " .. addon.label .. " · " .. addon.version)
end
