# WoWKorean · 판다리아 5.4.8

빌드 **18414** 전용 v0.1.0 테스트판입니다. 게임을 종료한 뒤 ZIP의 `WoWKorean_MoP` 폴더를 `Interface/AddOns`에 넣고 접속하세요. 애드온 목록에 **와우 한글화 · 판다리아 5.4.8**이 표시됩니다. 영문 클라이언트에서는 번역하는 글자에 함께 들어 있는 한글 글꼴을 적용합니다.

## 표시 범위

- 기본 퀘스트 창과 일지의 제목, 본문, 목표 요약, 진행·보상 대사. 기본 퀘스트 목록과 추적기에는 등록된 제목을 표시합니다.
- 기본 대상 프레임과 툴팁의 NPC·몬스터 이름, 아이템 툴팁의 이름과 등록된 설명. 표시 가능한 곳에서는 NPC 부제도 번역합니다.
- `coverage.json`에서 사전 등록 수를 볼 수 있습니다. 리팩 전용 문구, 추적기의 개별 처치·수집 문구, 주문 설명, 커스텀 UI는 원문이 남을 수 있습니다.

## 번역 데이터와 재생성

취미연구가의 2026-09-23 **5.3.8 MoP V2 Repack 한글 언어팩**의 `db` 폴더와 판다리아 월드 기준 덤프 `world_548_20240722.sql`을 대조했습니다. 리팩 이름에 들어 있는 5.3.8은 서버 패키지 버전이며 애드온 대상 빌드는 5.4.8 (18414)입니다. 원본 SQL은 빌드 입력이며 설치 ZIP에는 Lua 사전과 출처만 들어갑니다.

```sh
python tools/build_data.py mop world_548_20240722.sql path/to/locale-export/db
python tools/package.py mop
```

글꼴은 [나눔고딕](https://github.com/google/fonts/tree/main/ofl/nanumgothic)입니다. SIL Open Font License 전문은 `Fonts/OFL.txt`에 들어 있습니다.
