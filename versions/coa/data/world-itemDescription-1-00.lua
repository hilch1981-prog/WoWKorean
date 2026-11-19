local addon = WoWKoreanClient
if not addon.active then return end
local text = addon.worldText.itemDescription
if not text then
    text = { values = {}, templates = {} }
    addon.worldText.itemDescription = text
end
local rows = text.templates
rows[#rows+1]={"Place down an Ebon Blade Banner.  Range is $r yards.","에본 블레이드 배너를 내려 놓아 $r - 야드"}
