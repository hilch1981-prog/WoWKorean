# WoWKorean · Conquest of AzerothCore

CoA 전용 **3.3.5a 계열** 클라이언트용 v0.1.0 테스트판입니다. 기존 리치왕판의 번역을 기준 영문이 같은 화면에 적용하고, CoA 북녘골·골드샤이어·엘윈 숲 전용 퀘스트 35개의 번역을 추가했습니다. 북녘골 퀘스트 8개는 본문과 대사도 포함합니다. 그 밖의 CoA 직업·특성·주문 및 전용 UI에는 영문이 남을 수 있습니다.

## 적용 순서

1. 사용하는 리팩이 지정한 CoA 클라이언트를 먼저 준비하세요. **CoA Custom 1.9.2**를 쓰는 경우 제작자의 클라이언트 패키지와 `INSTALL-GUIDE.txt`를 사용하세요. 제작자 안내의 최신 패치 MPQ와 `CoAQuestSafe`가 필요한 구성이라면 그 순서대로 먼저 설치합니다. [CoA Custom 1.9.2 원본 릴리스](https://github.com/ilusixn/azerothcore-wotlk-coa/releases/tag/coa-custom-1.9.2)
2. 게임을 종료하고 `WoWKorean_CoA` 폴더를 CoA 클라이언트의 `Interface/AddOns`에 넣습니다. 같은 화면을 처리하는 예전 `WoWKorean_WotLK`가 설치되어 있다면 CoA 클라이언트에서는 애드온 목록에서 끄고 테스트하세요.
3. 접속하면 번역이 적용됩니다. ZIP 안의 글꼴은 애드온이 번역한 문구에 사용됩니다. 기본 UI의 다른 글자까지 한글 글리프가 필요할 때는 [선택 글꼴 패치 안내](FONT-PATCH.md)를 확인하세요.

CoA 코어와 Custom은 별도의 배포 계열입니다. 원본 MPQ와 실행 파일은 각 제작자의 배포에서 받습니다. WoWKorean의 CoA 글꼴 패치는 글꼴 파일만 적용합니다.

## 표시 범위와 출처

- 퀘스트 창과 일지의 제목·본문·목표 요약·진행·보상, 기본 목록·추적기의 제목, 기본 대상 프레임과 툴팁의 NPC 이름, 아이템 툴팁 이름과 등록된 설명을 지원합니다. 리팩이 기준 영문을 바꾼 필드는 해당 화면에 서버 원문이 표시됩니다.
- 공통 퀘스트와 이름 번역은 취미연구가의 [WoWKorean WotLK v0.4.4](https://github.com/hilch1981-prog/WoWKorean/releases/tag/v0.4.4)와 [AzerothCore koKR 기여 PR #27829](https://github.com/azerothcore/azerothcore-wotlk/pull/27829)를 사용했습니다. CoA 번역의 원문은 [CoA 코어 4430f0d](https://github.com/Conquest-of-AzerothCore/azerothcore-wotlk-coa/tree/4430f0d6271600a439b0d7850031be3af817357b/data/sql/updates/pending_db_world)의 북녘골·골드샤이어·엘윈 퀘스트 SQL입니다. 클라이언트 호환성은 리팩별로 확인이 필요합니다.

## 재생성

v0.4.4 설치 ZIP에서 `WoWKorean_WotLK` 폴더를 추출합니다. 위 CoA 코어 리비전에서 `rev_20260922_00_coa_northshire_quests.sql`, `rev_20260923_00_coa_goldshire_quests.sql`, `rev_20260923_01_coa_elwynn_quests.sql`을 받아 한 폴더에 둡니다.

```sh
python -m pip install lupa
python tools/build_data.py coa path/to/WoWKorean_WotLK versions/coa/coakorean.json --coa-sql path/to/coa-sql
python tools/package.py coa
```
