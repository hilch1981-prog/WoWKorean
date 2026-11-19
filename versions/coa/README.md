# WoWKorean · CoA Custom 1.9.2

CoA Custom **1.9.2** 전용 v0.2.0 한글화 테스트판입니다. 애드온과 클라이언트 패치를 설치하면 확인된 퀘스트·NPC·아이템·주문 텍스트와 캐릭터 생성 화면의 번역이 표시됩니다. [CoA Custom 1.9.2 원본 릴리스](https://github.com/ilusixn/azerothcore-wotlk-coa/releases/tag/coa-custom-1.9.2)

## 설치

1. CoA Custom 1.9.2 클라이언트를 제작자의 `INSTALL-GUIDE.txt`에 따라 준비한 후 게임을 종료합니다.
2. 애드온 ZIP의 `WoWKorean_CoA`를 클라이언트의 `Interface/AddOns`에 넣습니다. v0.1.0 사용자라면 기존 폴더를 교체합니다. 같은 화면을 처리하는 `WoWKorean_WotLK`는 CoA 클라이언트의 애드온 목록에서 끕니다.
3. 클라이언트 패치 ZIP의 `Data/patch-ZZZY.MPQ`와 `Fonts`를 `Ascension.exe`가 있는 게임 폴더에 추가합니다. 원래 갖고 있던 같은 이름의 글꼴 및 패치는 보관합니다. [클라이언트 패치와 복구 순서](CLIENT-PATCH.md)
4. 게임을 완전히 다시 시작합니다. 캐릭터 생성 화면, 기본 퀘스트 창, 주문책과 툴팁에서 각각 확인합니다.

## 번역 범위

| 파일 | 적용 화면 |
| --- | --- |
| WoWKorean 애드온 | 기본 퀘스트 창·일지·추적 목표, NPC 이름과 대화, 아이템 이름·설명, 오브젝트 이름, 책, 주문책 및 기본 툴팁의 주문 이름 |
| 클라이언트 패치 | 클라이언트가 읽는 주문·오라 설명, 캐릭터 생성 화면의 등록된 종족·직업명과 종족 설정 문구, 한글 글꼴 |

같은 퀘스트 ID라도 제목과 표시 원문이 맞는 필드에만 번역을 적용합니다. MPQ는 주문 효과 계산에 쓰이는 열과 기존 주문 이름 조회 키를 유지하고 설명 열만 바꿉니다. 캐릭터 화면의 종족·직업 선택 키도 유지합니다.

퀘스트·NPC·아이템 및 주문 사전의 등록 수는 `coverage.json`과 `client-coverage.json`에 있습니다. 리팩별 원문 차이, 외부 서버에서 별도로 보내는 연출 문구, 사전에 없는 문구 및 검증에 실패한 번역은 영문으로 나올 수 있습니다. 사전 수는 실제 플레이 중 화면에 표시된 건수와 다릅니다.

## 번역 자료

- 공통 항목에는 취미연구가의 [WoWKorean 리치왕 v0.4.4](https://github.com/hilch1981-prog/WoWKorean/releases/tag/v0.4.4)와 [AzerothCore koKR 기여 PR #27829](https://github.com/azerothcore/azerothcore-wotlk/pull/27829)의 번역을 우선 재사용했습니다.
- CoA 문구는 1.9.2 소스에 포함된 `coa-world-20260912.zip`과 해당 소스의 월드 업데이트, 1.9.2 `1_world.sql`의 원문을 대조했습니다. 임시 DB에서 재현할 때 일부 업데이트가 스키마 차이로 실패했습니다. 사전의 수치는 추출에 성공한 데이터와 직접 대조한 원문을 기준으로 집계했습니다. [CoA 월드 데이터 형식](https://github.com/Conquest-of-AzerothCore/azerothcore-wotlk-coa/tree/main/data/coa-world)
- 직접 번역한 북녘골 원고와 승천의 길·직업 퀘스트 문구를 사용했습니다. 대량의 새 문구는 로컬 번역 초안에 와우 용어와 서식 검사를 적용했습니다. 주문과 퀘스트의 수치 및 자리표시자를 확인했습니다. 새 전체 문구에 대한 사람 검수와 실게임 검증은 남아 있습니다. [직접 보강한 문구](world-terms-ko.json) · [로컬 번역 모델](https://huggingface.co/mydubber-org/nllb-200-distilled-600M-ct2-int8)
- 클라이언트 원문은 Custom 1.9.2 `Client-5.zip`의 `patch-ZZZF.MPQ`에서 얻었습니다. 한글 글꼴은 나눔고딕입니다. [글꼴과 OFL](https://github.com/google/fonts/tree/main/ofl/nanumgothic)

## 패키지 재생성

Python 3.10 이상에서 아래 명령을 실행합니다. 원본 Client-5 ZIP을 읽는 빌드 도구는 MPQ에서 꺼낸 각 입력 파일의 SHA-256을 확인한 뒤 새 MPQ를 생성합니다.

```sh
python -m pip install mpyq
python tools/coa_client_patch.py CoA-Custom-1.9.2-Client-5.zip versions/coa/client-catalog.json.gz patch-ZZZY.MPQ
python tools/package.py coa --coa-client-patch patch-ZZZY.MPQ
```
