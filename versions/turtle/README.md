# WoWKorean · 터틀 와우 1.18.1

터틀 와우 **1.18.1**의 1.12 계열 클라이언트를 대상으로 만든 v0.1.0 테스트판입니다. 게임을 종료한 뒤 ZIP의 `WoWKorean_Turtle` 폴더를 `Interface/AddOns`에 넣고 접속하세요. 애드온 목록에는 **와우 한글화 · 터틀 와우 1.18.1**로 표시됩니다.

퀘스트 화면을 이미 바꾸는 `LaziKoreanQuest`와 `WoWTranslate`를 쓰는 경우 WoWKorean 테스트 중에는 해당 애드온을 끄고 실행하세요. 기본 퀘스트 창, 일지, 기본 추적기를 기준으로 적용합니다. 영문 클라이언트에서 애드온이 쓰는 번역 문구에는 동봉 글꼴이 적용됩니다.

## 표시 범위

- 기본 퀘스트 제목, 본문, 목표 요약, 진행·보상 대사. 기본 목록과 추적기의 퀘스트 제목.
- 기본 대상 프레임과 툴팁의 NPC·몬스터 이름 및 등록된 부제. 아이템 툴팁 이름과 등록된 설명. 주문 ID를 제공하는 툴팁의 이름.
- 퀘스트 ID를 노출하지 않는 화면은 제목과 본문을 대조합니다. 후보 번역이 서로 다른 제목 목록이나 원문 변경이 있는 필드에는 게임이 보내는 글이 표시됩니다.

## 번역 데이터와 재생성

취미연구가의 **TurtleWOW 1.18.1 Bots 한글 언어팩 2026-09-23** 중 `locales_*`의 한국어 필드와 [Tortoise WoW](https://github.com/Shyalya/tortoise-wow/tree/a37f5740ad4ed27a17cf0f297fe69c596f1797f6)의 기준 영문 월드 SQL을 대조했습니다. 플레이어·봇 캐릭터 데이터는 사전 입력에서 제외했습니다.

```sh
python tools/build_data.py turtle path/to/tortoise/sql/base path/to/locale-export/db
python tools/package.py turtle
```

글꼴은 [나눔고딕](https://github.com/google/fonts/tree/main/ofl/nanumgothic)입니다. SIL Open Font License 전문은 `Fonts/OFL.txt`에 들어 있습니다.
