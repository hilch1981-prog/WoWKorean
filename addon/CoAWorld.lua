local addon = WoWKoreanClient
if not addon.active or not addon.worldText then return end

local dynamic = {}
local function Translate(kind, original)
    if type(original) ~= "string" or original == "" then return end
    local translations = addon.worldText[kind]
    if not translations then return end
    local key = addon.textKey(original)
    local direct = translations.values[key]
    if direct then return addon.expandText(direct, true) end
    if not UnitName("player") then return end
    if not dynamic[kind] then
        local index = {}
        local function Register(expanded, korean)
            local entry = addon.textKey(expanded)
            if index[entry] == nil then index[entry] = korean
            elseif index[entry] ~= korean then index[entry] = false end
        end
        for _, pair in ipairs(translations.templates) do
            Register(addon.expandText(pair[1], false), pair[2])
            Register(addon.expandText(pair[1], false, true, true), pair[2])
        end
        dynamic[kind] = index
    end
    local translated = dynamic[kind][key]
    if translated then return addon.expandText(translated, true) end
end

local function Widget(kind, widget)
    if addon.isVisible(widget) and widget.GetText and widget.SetText then
        local original = widget:GetText()
        return addon.displayText(widget, original, Translate(kind, original))
    end
end

local function ObjectTooltip()
    if not addon.isVisible(GameTooltip) or not GameTooltipTextLeft1 then return end
    if GameTooltip:GetItem() or GameTooltip:GetSpell() or GameTooltip:GetUnit() then return end
    Widget("object", GameTooltipTextLeft1)
end

local function SpellTooltip(tooltip)
    if not addon.isVisible(tooltip) or not tooltip.GetSpell then return end
    local name, rank = tooltip:GetSpell()
    if not name then return end
    local prefix = tooltip:GetName() .. "Text"
    Widget("spell", _G[prefix .. "Left1"])
    if rank and rank ~= "" then
        for _, suffix in ipairs({"Left2", "Right1"}) do
            local widget = _G[prefix .. suffix]
            if widget and widget:GetText() == rank then Widget("spellRank", widget) end
        end
    end
end

local function ItemTooltip(tooltip)
    if not addon.isVisible(tooltip) or not tooltip.GetItem then return end
    local original = tooltip:GetItem()
    local name = Translate("itemName", original)
    if not name then return end
    local prefix = tooltip:GetName() .. "TextLeft"
    local title = _G[prefix .. "1"]
    if title then addon.displayText(title, original, name) end
    for index = 2, tooltip:NumLines() do
        local line = _G[prefix .. index]
        local text = line and line:GetText()
        local translated = Translate("itemDescription", text)
        if not translated and text and string.sub(text, 1, 1) == '"' and string.sub(text, -1) == '"' then
            local body = Translate("itemDescription", string.sub(text, 2, -2))
            if body then translated = '"' .. body .. '"' end
        end
        addon.displayText(line, text, translated)
    end
end

local function ObjectiveLabel(label)
    local name = Translate("objective", label) or Translate("itemName", label)
        or Translate("object", label) or Translate("unitName", label)
    if name then return name end
    local target = string.match(label, "^(.+) slain$")
    local unit = target and Translate("unitName", target)
    if unit then return unit .. " 처치" end
end

local function Objective(widget)
    if not addon.isVisible(widget) then return end
    local original = widget:GetText()
    if not original then return end
    local source, suffix = original, ""
    if COMPLETE then
        local marker = " (" .. COMPLETE .. ")"
        if string.sub(source, -#marker) == marker then
            source, suffix = string.sub(source, 1, -#marker - 1), " (완료)"
        end
    end
    local translated = Translate("objective", source)
    if not translated then
        local label, count = string.match(source, "^(.-)(:%s*%d+%s*/%s*%d+)$")
        if label then
            local name = ObjectiveLabel(label)
            if name then translated = name .. count end
        else
            local prefix, target = string.match(source, "^(%d+%s*/%s*%d+%s+)(.+)$")
            local name = target and ObjectiveLabel(target)
            if name then translated = prefix .. name end
        end
    end
    if translated then addon.displayText(widget, original, translated .. suffix) end
end

if GameTooltip and hooksecurefunc then
    local function HookAura(method, query)
        if not GameTooltip[method] or not query then return end
        hooksecurefunc(GameTooltip, method, function(tooltip, unit, index, filter)
            if query(unit, index, filter) then
                Widget("spell", _G[tooltip:GetName() .. "TextLeft1"])
            end
        end)
    end
    HookAura("SetUnitAura", UnitAura)
    HookAura("SetUnitBuff", UnitBuff)
    HookAura("SetUnitDebuff", UnitDebuff)
end

addon.updateWorldText = function()
    if not Widget("greeting", GossipGreetingText) then Widget("speech", GossipGreetingText) end
    Widget("questGreeting", GreetingText)
    Widget("page", ItemTextPageText)
    Widget("trainer", ClassTrainerGreetingText)
    Widget("poi", WorldMapFrameAreaLabel)
    if addon.isVisible(GossipFrame) and GossipFrame.buttonIndex then
        for index = 1, GossipFrame.buttonIndex - 1 do
            local button = _G["GossipTitleButton" .. index]
            if button and button.type == "Gossip" and Widget("option", button) and GossipResize then
                GossipResize(button)
            end
        end
    end
    for index = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local popup = _G["StaticPopup" .. index]
        if popup and (popup.which == "GOSSIP_CONFIRM" or popup.which == "GOSSIP_CONFIRM_CANCEL") then
            Widget("gossipConfirmation", _G[popup:GetName() .. "Text"])
        end
    end
    if addon.isVisible(QuestLogFrame) then
        local selection = GetQuestLogSelection()
        for index = 1, selection and GetNumQuestLeaderBoards(selection) or 0 do
            Objective(_G["QuestInfoObjective" .. index])
        end
    end
    if WATCHFRAME_LINKBUTTONS and addon.isVisible(WatchFrame) then
        for _, button in ipairs(WATCHFRAME_LINKBUTTONS) do
            if button.type == "QUEST" and addon.isVisible(button) and button.lines
                and button.startLine and button.lastLine then
                for index = button.startLine + 1, button.lastLine do
                    local line = button.lines[index]
                    if line then Objective(line.text) end
                end
            end
        end
    end
    SpellTooltip(GameTooltip)
    SpellTooltip(ItemRefTooltip)
    ItemTooltip(GameTooltip)
    ItemTooltip(ItemRefTooltip)
    if addon.isVisible(SpellBookFrame) then
        for index = 1, SPELLS_PER_PAGE or 12 do
            Widget("spell", _G["SpellButton" .. index .. "SpellName"])
            Widget("spellRank", _G["SpellButton" .. index .. "SubSpellName"])
        end
    end
    ObjectTooltip()
end

if ChatFrame_AddMessageEventFilter then
    local function Filter(_, _, message, ...)
        local translated = Translate("speech", message)
        if translated then return false, translated, ... end
        return false
    end
    for _, event in ipairs({"MONSTER_SAY", "MONSTER_YELL", "MONSTER_WHISPER", "MONSTER_EMOTE",
        "RAID_BOSS_EMOTE", "RAID_BOSS_WHISPER"}) do
        ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. event, Filter)
    end
end
