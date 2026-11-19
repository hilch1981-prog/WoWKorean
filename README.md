# WoWKorean

영문 서버나 리팩에 접속했을 때, 등록된 퀘스트와 이름의 한국어를 게임 기본 화면에 표시하는 일반 유저용 애드온입니다. 클라이언트에 애드온을 설치하면 접속 시 자동으로 적용됩니다. 서버 DB 수정은 필요 없습니다.

| 클라이언트 | 배포 | 설치 안내 |
| --- | --- | --- |
| 리치왕 3.3.5a · 빌드 12340 · koKR | [v0.4.4 게임 테스트판](https://github.com/hilch1981-prog/WoWKorean/releases/tag/v0.4.4) | ZIP의 README |
| 판다리아 5.4.8 · 빌드 18414 | [v0.1.1 테스트판](https://github.com/hilch1981-prog/WoWKorean/releases/tag/mop-5.4.8-v0.1.1) | [판다리아](versions/mop/README.md) |
| 터틀 와우 1.18.1 · 1.12 기반 | [v0.1.0 테스트판](https://github.com/hilch1981-prog/WoWKorean/releases/tag/turtle-1.18.1-v0.1.0) | [터틀 와우](versions/turtle/README.md) |
| CoA Custom 1.9.2 · 3.3.5a 계열 | [v0.2.0 테스트판](https://github.com/hilch1981-prog/WoWKorean/releases/tag/coa-custom-1.9.2-v0.2.0) | [CoA 애드온 및 클라이언트 패치 설치](versions/coa/README.md) |

리팩에 따라 같은 ID의 이름이나 문구가 다를 수 있습니다. WoWKorean은 화면의 영문이 사전의 기준과 일치하는 필드에 번역을 표시합니다. 영문이 바뀌었거나 사전에 없는 부분은 서버에서 보내는 문구가 표시됩니다.

## 소스와 ZIP 재생성

공통 Lua 소스는 `addon`에, 사전과 출처는 `versions`에 있습니다. Python 3.10 이상에서 `python tools/package.py all`을 실행하면 `dist`에 설치 ZIP 세 개와 CoA 글꼴 ZIP이 생성됩니다. CoA 전용 MPQ를 만들고 패치 ZIP에 넣는 방법은 CoA 설치 안내를 참고하세요. [CoA 패키지 재생성](versions/coa/README.md#패키지-재생성)

패키지의 TOC, 압축 무결성과 Lua 화면 동작은 `python tools/verify_packages.py`로 확인할 수 있습니다. 이 검증 스크립트에는 `lupa`가 필요합니다. `--lua50 path/to/lua.exe`를 지정하면 터틀 와우를 Lua 5.0에서도 검사합니다.

버그를 제보할 때는 클라이언트와 리팩 버전, WoWKorean 버전, 퀘스트나 대상 이름과 가능한 경우 ID, 화면 캡처를 알려 주세요.
