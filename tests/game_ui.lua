local function Widget()
    local widget = {value = "", shown = false, font = "Fonts\\FRIZQT__.TTF", id = 1}
    function widget:GetText() return self.value end
    function widget:SetText(value) self.value = value end
    function widget:IsVisible() return self.shown end
    function widget:GetFont() return self.font, 12, "" end
    function widget:SetFont(path) self.font = path; return true end
    function widget:GetID() return self.id end
    return widget
end

function GetBuildInfo()
    return "test", TEST_BUILD, "", TEST_INTERFACE
end
function GetLocale() return "enUS" end
function UnitRace() return "Human", "Human" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitSex() return 2 end
function UnitName(unit)
    if unit == "player" then return "Testname" end
    return TestUnitName
end
function UnitIsPlayer() return TestIsPlayer end
function UnitGUID() return TestGUID end
function CreateFrame()
    return {SetScript = function(_, _, callback) Tick = callback end}
end

SlashCmdList = {}
QuestFrame, QuestFrameDetailPanel = Widget(), Widget()
QuestFrameProgressPanel, QuestFrameRewardPanel = Widget(), Widget()
QuestFrameGreetingPanel, QuestLogFrame = Widget(), Widget()
QuestLogListScrollFrame, QuestLogScrollFrame = Widget(), {buttons = {}}
QuestLogTitle1, QuestLogTitle2 = Widget(), Widget()
QuestWatchFrame, QuestWatchLine1, QuestWatchLine2 = Widget(), Widget(), Widget()
WatchFrame = Widget()
QUESTS_DISPLAYED = 2
GossipFrame = Widget()
GossipFrame.buttonIndex = 3
GossipTitleButton1, GossipTitleButton2 = Widget(), Widget()
GossipTitleButton1.type, GossipTitleButton2.type = "Available", "Active"
TargetFrameTextureFrameName, GameTooltip = Widget(), Widget()
GameTooltipTextLeft1, GameTooltipTextLeft2 = Widget(), Widget()
function GameTooltip:GetName() return "GameTooltip" end
function GameTooltip:NumLines() return 2 end
function GameTooltip:GetUnit() return TestUnitName, "target" end
function GameTooltip:GetItem() return TestItemName, TestItemLink end
function GameTooltip:GetSpell() return TestSpellName, nil, TestSpellID end
function GameTooltip:SetUnitAura()
    self.shown = true
    GameTooltipTextLeft1.value = TestAuraName
    GameTooltipTextLeft2.value = TestAuraText
end
function UnitAura()
    return TestAuraName, nil, nil, nil, nil, nil, nil, nil, nil, nil, TestAuraID
end
function hooksecurefunc(object, method, after)
    local original = object[method]
    object[method] = function(self, unit, index, filter)
        original(self, unit, index, filter)
        after(self, unit, index, filter)
    end
end
function GetTitleText() return TestTitle end
function GetQuestID() return TestID end
function GetQuestText() return TestDescription end
function GetObjectiveText() return TestObjectives end
function GetProgressText() return TestProgress end
function GetRewardText() return TestReward end
function GetQuestLogSelection() return 1 end
function GetQuestLogQuestText() return TestDescription, TestObjectives end
function GetQuestLogTitle(index)
    if TEST_INTERFACE == 11200 then return TestTitle, 1, nil, index == 2, nil, nil, nil, nil, TestID end
    return TestTitle, 1, nil, 0, index == 2, nil, nil, nil, TestID
end
function FauxScrollFrame_GetOffset() return 0 end
function GetNumQuestWatches() return 1 end
function GetQuestIndexForWatch() return 1 end
function GetNumQuestLeaderBoards() return 1 end
function GetGossipAvailableQuests() return TestTitle end
function GetGossipActiveQuests() return TestTitle end

if TEST_INTERFACE == 11200 then
    QuestTitleText, QuestDescription, QuestObjectiveText = Widget(), Widget(), Widget()
    QuestRewardTitleText, QuestRewardText = Widget(), Widget()
    QuestLogQuestTitle, QuestLogQuestDescription, QuestLogObjectivesText = Widget(), Widget(), Widget()
else
    QuestInfoTitleHeader, QuestInfoDescriptionText, QuestInfoObjectivesText = Widget(), Widget(), Widget()
    QuestInfoRewardText = Widget()
end
QuestProgressTitleText, QuestProgressText = Widget(), Widget()

local function Show(widget, value)
    widget.shown = true
    widget.value = value
end

local function Frame()
    Tick(nil, .2)
end

function Verify()
    assert(WoWKoreanClient.active and Tick)
    local addon = WoWKoreanClient
    local count = 0
    for _ in pairs(addon.quests) do count = count + 1 end
    assert(count == EXPECTED_QUESTS)
    TestTitle, TestID = "A Threat Within", 783
    assert(addon.quests[783], "real quest data")
    QuestFrame.shown, QuestFrameDetailPanel.shown = true, true
    local title = QuestTitleText or QuestInfoTitleHeader
    Show(title, TestTitle)
    Frame()
    assert(title.value == addon.quests[783].title[2], "registered quest title")
    assert(string.find(title.font, "NanumGothic", 1, true), "per-widget Hangul font")
    Show(title, "Different quest")
    TestTitle = "Different quest"
    Frame()
    assert(title.value == TestTitle and title.font == "Fonts\\FRIZQT__.TTF", "custom source retained")

    local id = 9900001
    addon.quests[id] = {
        title = {"Recruiting Testname", "테스트 제목"},
        description = {"Welcome, $N!$B$BGood luck, $C.", "반갑습니다, $N 님!$B$B행운을 빕니다, $C 님."},
        objectives = {"Collect 3 Widgets.", "시험 물품 3개를 모으세요."},
        progress = {"Any progress?", "진전이 있나요?"},
        completion = {"Well done, $N.", "잘했습니다, $N 님."},
    }
    TestTitle, TestID = "Recruiting Testname", id
    TestDescription = "Welcome, Testname!\r\n\r\nGood luck, Warrior."
    TestObjectives = "Collect 5 Widgets."
    Show(title, TestTitle)
    local description = QuestDescription or QuestInfoDescriptionText
    local objectives = QuestObjectiveText or QuestInfoObjectivesText
    Show(description, TestDescription)
    Show(objectives, TestObjectives)
    Frame()
    assert(description.value == "반갑습니다, Testname 님!\n\n행운을 빕니다, 전사 님.", "dynamic body")
    assert(objectives.value == TestObjectives, "custom quantity")

    QuestFrameDetailPanel.shown, QuestFrameProgressPanel.shown = false, true
    TestProgress = "Any progress?"
    Show(QuestProgressTitleText, TestTitle)
    Show(QuestProgressText, TestProgress)
    Frame()
    assert(QuestProgressText.value == "진전이 있나요?", "progress")
    QuestFrameProgressPanel.shown, QuestFrameRewardPanel.shown = false, true
    TestReward = "Well done, Testname."
    Show(QuestRewardTitleText or QuestInfoTitleHeader, TestTitle)
    local reward = QuestRewardText or QuestInfoRewardText
    Show(reward, TestReward)
    Frame()
    assert(reward.value == "잘했습니다, Testname 님.", "reward")
    if TEST_INTERFACE == 11200 then
        -- Vanilla can omit quest IDs. Verify the displayed body before choosing a title.
        TestID = nil
        Show(reward, TestReward)
        Frame()
        assert(reward.value == "잘했습니다, Testname 님.", "no-ID source fallback")
    end

    QuestFrame.shown = false
    QuestLogFrame.shown, GossipFrame.shown = true, true
    local row = Widget()
    Show(row, "  " .. TestTitle)
    QuestLogTitle1 = row
    QuestLogScrollFrame.buttons[1] = row
    Show(GossipTitleButton1, TestTitle)
    Show(GossipTitleButton2, TestTitle)
    Show(QuestLogQuestTitle or QuestInfoTitleHeader, TestTitle)
    Show(QuestLogQuestDescription or QuestInfoDescriptionText, TestDescription)
    if TEST_INTERFACE == 11200 then
        Show(QuestWatchLine1, TestTitle)
        QuestWatchFrame.shown = true
    else
        Show(QuestWatchLine1, TestTitle)
        WatchFrame.shown = true
        local button = Widget()
        button.shown, button.index, button.startLine, button.type = true, 1, 1, "QUEST"
        button.lines = {{text = QuestWatchLine1}}
        WATCHFRAME_LINKBUTTONS = {button}
    end
    Frame()
    assert(row.value == "  테스트 제목", "quest list")
    assert(QuestWatchLine1.value == "테스트 제목", "quest tracker")
    assert(GossipTitleButton1.value == "테스트 제목" and GossipTitleButton2.value == "테스트 제목", "gossip quest titles")

    TestUnitName, TestGUID = "Kobold Vermin", "0xF130000006000001"
    Show(TargetFrameTextureFrameName, TestUnitName)
    Show(GameTooltipTextLeft1, TestUnitName)
    GameTooltip.shown = true
    Frame()
    assert(GameTooltipTextLeft1.value == addon.units[6].title[2], "NPC tooltip")
    assert(TargetFrameTextureFrameName.value == addon.units[6].title[2], "target frame")
    TestIsPlayer = true
    Show(GameTooltipTextLeft1, TestUnitName)
    Frame()
    assert(GameTooltipTextLeft1.value == TestUnitName, "player excluded")
    TestIsPlayer = false
    TestItemName, TestItemLink = "Worn Shortsword", "|Hitem:25:0:0|h[Worn Shortsword]|h"
    Show(GameTooltipTextLeft1, TestItemName)
    Frame()
    assert(GameTooltipTextLeft1.value == addon.items[25].title[2], "item tooltip")
    TestItemLink = "|Hitem:650000:0:0|h[Worn Shortsword]|h"
    Show(GameTooltipTextLeft1, TestItemName)
    Frame()
    assert(GameTooltipTextLeft1.value == TestItemName, "unknown item ID")

    local spellCount = 0
    for _ in pairs(addon.spells) do spellCount = spellCount + 1 end
    assert(spellCount == EXPECTED_SPELLS)
    if TEST_INTERFACE == 50400 then
        TestItemName, TestItemLink = nil, nil
        TestSpellName, TestSpellID = "Fireball", 133
        Show(GameTooltipTextLeft1, TestSpellName)
        Show(GameTooltipTextLeft2, "Hurls a fiery ball that causes 1,234.5 Fire damage.")
        Frame()
        assert(GameTooltipTextLeft1.value == "화염구", "MoP spell name")
        assert(GameTooltipTextLeft2.value == "적에게 불타는 구체를 날려 1,234.5의 화염 피해를 입힙니다.", "MoP spell damage")
        Show(GameTooltipTextLeft2, "Hurls a fiery ball that causes 1,234 to 1,456 Fire damage.")
        Frame()
        assert(GameTooltipTextLeft2.value == "적에게 불타는 구체를 날려 1,234~1,456의 화염 피해를 입힙니다.", "MoP spell damage range")
        Show(GameTooltipTextLeft2, "Hurls two fiery balls that cause 1,234.5 Shadow damage.")
        Frame()
        assert(GameTooltipTextLeft2.value == "Hurls two fiery balls that cause 1,234.5 Shadow damage.", "changed spell description")

        TestSpellName, TestSpellID = "Frostbolt", 116
        Show(GameTooltipTextLeft1, TestSpellName)
        Show(GameTooltipTextLeft2, "Launches a bolt of frost at the enemy, causing 152 Frost damage and slowing movement speed by 50% for 8 sec.")
        Frame()
        assert(GameTooltipTextLeft2.value == "적에게 얼음 화살을 날려 152의 냉기 피해를 입히고 8초 동안 이동 속도를 50%만큼 감소시킵니다.", "MoP reordered duration and percentage")

        TestSpellName, TestSpellID = nil, nil
        TestAuraName, TestAuraID = "Rejuvenation", 774
        TestAuraText = "Heals 1,174 damage every 3 seconds."
        GameTooltip:SetUnitAura("target", 1, "HELPFUL")
        assert(GameTooltipTextLeft1.value == "회복", "MoP aura name")
        assert(GameTooltipTextLeft2.value == "3초마다 1,174의 생명력 회복", "MoP aura periodic effect")
    end
    print("PASS: " .. addon.folder .. " (" .. _VERSION .. ")")
end
