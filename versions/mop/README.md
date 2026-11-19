# WoWKorean · 판다리아 5.4.8

빌드 **18414** 전용 v0.1.1 테스트판입니다. 게임을 종료한 뒤 ZIP의 `WoWKorean_MoP` 폴더를 `Interface/AddOns`에 넣고 접속하세요. v0.1.0 사용자는 같은 이름의 기존 폴더를 교체하면 됩니다. 애드온 목록에 **와우 한글화 · 판다리아 5.4.8**이 표시됩니다. 영문 클라이언트에서는 번역하는 글자에 함께 들어 있는 한글 글꼴을 적용합니다.

## 표시 범위

- 기본 퀘스트 창과 일지의 제목, 본문, 목표 요약, 진행·보상 대사. 기본 퀘스트 목록과 추적기에는 등록된 제목을 표시합니다.
- 기본 대상 프레임과 툴팁의 NPC·몬스터 이름, 아이템 툴팁의 이름과 등록된 설명. 표시 가능한 곳에서는 NPC 부제도 번역합니다.
- v0.1.1에서 기본 주문과 강화·약화 효과 툴팁을 추가했습니다. 주문 이름 92,910개, 주문 설명 43,534개, 강화·약화 효과 설명 22,901개가 사전에 등록되어 있습니다. 영문 설명을 대조해 피해량, 회복량, 지속시간 등 게임에 표시된 수치를 한글 문장에 옮깁니다.
- 복잡한 조건식이나 다른 주문 설명을 불러오는 문장, 리팩이 바꾼 문구와 커스텀 UI에는 영문이 남을 수 있습니다. `coverage.json`의 수치는 사전 등록 수입니다. 설치 ZIP과 Lua 모의 화면에서 검증했으며 실클라이언트에서의 표시 범위는 확인이 필요합니다.

## 번역 데이터와 재생성

취미연구가의 2026-09-23 **5.3.8 MoP V2 Repack 한글 언어팩**의 `db` 폴더와 판다리아 월드 기준 덤프 `world_548_20240722.sql`을 대조했습니다. 리팩 이름에 들어 있는 5.3.8은 서버 패키지 버전이며 애드온 대상 빌드는 5.4.8 (18414)입니다. 원본 SQL은 빌드 입력이며 설치 ZIP에는 Lua 사전과 출처만 들어갑니다.

주문 사전의 원본은 WER MoP의 `Server/Data/dbc/Spell.dbc`와 `Server/Data/dbc/koKR/Spell.dbc`입니다. 두 파일의 94,842개 주문 ID 및 숫자 필드가 일치하는 것을 확인하고 이름과 설명 필드를 대조했습니다. 설치 ZIP에는 DBC에서 추출한 표시용 Lua 사전이 들어 있습니다.

| Spell.dbc | SHA-256 |
| --- | --- |
| 영문 | `72b5b6756843ec151d10578f90f2eff12e000e3dab616222d21ae41b1d890e9c` |
| koKR | `6d0862a6a8228a6e49486ef452ba421da2cde2282a684b73bce84dab12a50671` |

```sh
python tools/build_data.py mop world_548_20240722.sql path/to/locale-export/db --mop-spell-dbc path/to/dbc/Spell.dbc path/to/dbc/koKR/Spell.dbc
python tools/package.py mop
```

글꼴은 [나눔고딕](https://github.com/google/fonts/tree/main/ofl/nanumgothic)입니다. SIL Open Font License 전문은 `Fonts/OFL.txt`에 들어 있습니다.
