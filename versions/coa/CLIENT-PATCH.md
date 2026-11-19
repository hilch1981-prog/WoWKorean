# CoA Custom 1.9.2 클라이언트 한글 패치

CoA Custom **1.9.2** 클라이언트 게임 폴더에 적용하는 테스트판입니다. 주문 설명·오라 설명과 캐릭터 생성 화면의 등록 문구를 표시합니다. 퀘스트, NPC, 아이템 및 주문 이름에는 같은 릴리스의 WoWKorean 애드온을 사용합니다.

1. CoA Custom 1.9.2 원본 클라이언트 패키지를 먼저 설치합니다. [제작자 설치 안내](https://github.com/ilusixn/azerothcore-wotlk-coa/releases/tag/coa-custom-1.9.2)
2. 게임을 종료합니다. ZIP의 `Data/patch-ZZZY.MPQ`를 `Ascension.exe` 옆 `Data`에 추가합니다. 같은 이름의 MPQ가 이미 있는 설치에는 그 파일을 먼저 다른 위치에 보관합니다.
3. 패치에 동봉된 `Fonts`를 게임 폴더의 `Fonts`에 넣습니다. 이미 쓰고 있는 글꼴은 복원할 수 있도록 보관합니다.
4. 애드온 ZIP의 `WoWKorean_CoA`를 `Interface/AddOns`에 넣고 게임을 실행합니다.

번역 패치를 되돌리려면 게임을 종료하고 추가한 `patch-ZZZY.MPQ`와 동봉 글꼴을 게임 폴더 밖으로 옮긴 후 보관한 파일을 되돌립니다.

빌드 도구는 원본 MPQ에서 꺼낸 텍스트 파일의 SHA-256을 확인합니다. 주문 속성·효과 수치와 이름 조회 키는 원본 DBC에서 그대로 읽힙니다. 캐릭터 화면에서는 종족·직업의 화면 표시 문구를 번역합니다. 렌더링, 패치 로드 순서와 리팩 조합은 실게임 검증 범위에 남아 있습니다.

글꼴은 [나눔고딕](https://github.com/google/fonts/tree/main/ofl/nanumgothic)입니다. 글꼴 저작권과 라이선스 전문은 ZIP의 `OFL.txt`에 있습니다.
