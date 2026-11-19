local addon = WoWKoreanClient
if not addon.active then return end
local text = addon.worldText.gossipConfirmation
if not text then
    text = { values = {}, templates = {} }
    addon.worldText.gossipConfirmation = text
end
local rows = text.values
rows["101:956274266"]="정말 거북기술 전문성을 배워서 모든 레시피를 잃고 싶니?"
rows["102:1215548059"]="정말 그노미스 공학 전문성을 배워서 관련 레시피를 잃고 싶니?"
rows["27:1786011007"]="기부금이 필요합니다."
rows["28:686857571"]="떠날 준비가 되었습니다, 듀르코트."
rows["33:2129118263"]="정말 올거를 뇌물수수하고 싶니?"
rows["52:944491811"]="경험은 그만두고 싶다고 확신하십니까?"
rows["59:152316292"]="다시 경험 쌓기 시작하겠다고 확신하십니까?"
rows["63:1208561608"]="정말 이중 특성 전문화를 구매하시겠습니까?"
rows["84:467470218"]="지식 을 잊는 것 은 비싼 노력 이다. 그 비용 을 지불 할 의 가 있습니까?"
rows["92:1928678186"]="정말 가죽공업 전문성을 배워서 관련 레시피를 모두 잃고 싶습니까?"
