# 에미 뇌터 저작집 — 완전한 한국어판

[완전한 링크형 한국어 누적 리더를 바로 열기](reader/00_NOETHER_ko_COMPLETE_LINKED_READER.pdf)

- 한국어판 고정 DOI: [10.5281/zenodo.21921523](https://doi.org/10.5281/zenodo.21921523)
- 이 판본의 불변 DOI: [10.5281/zenodo.21921524](https://doi.org/10.5281/zenodo.21921524)
- Zenodo 직접 미리보기: [00_NOETHER_ko_COMPLETE_LINKED_READER.pdf](https://zenodo.org/records/21921524/files/00_NOETHER_ko_COMPLETE_LINKED_READER.pdf)
- Zenodo 직접 다운로드: [PDF](https://zenodo.org/records/21921524/files/00_NOETHER_ko_COMPLETE_LINKED_READER.pdf?download=1)
- 다언어 디렉터리: [10.5281/zenodo.20412587](https://doi.org/10.5281/zenodo.20412587)
- 언어: 한국어 (BCP 47: ko; Zenodo/ISO 639-3: kor)
- 판본: 1.0.0 (2026-08-13)
- Git 태그: v1.0.0

이 저장소는 에미 뇌터의 유지 대상 저작 전체를 한 권으로 엮은 독립 한국어판이다. 공개 범위는 번호가 붙은 논문 43편, 번호 뒤의 별도 저작 A와 B, 그리고 참고문헌·판본 부록이다. 독일어 누적 권위의 논리행 1–24,146을 48개의 연속 범위로 나누어 한 번씩 모두 대응시켰다.

P32는 별도 프로젝트가 아니라 이 책의 32번 논문, 「기약표현의 최소 분해체에 관하여」를 뜻한다. P32/U06의 최종 문구 “이들 가운데 하나이다”는 누적 본문에 이미 포함되어 있다.

## 현재 상태

한국어 본문은 활성 원문 권위 NOETH-DE-AUTH-v047-20260808 / ED0011에 대해 완성되었다. 알려진 미번역 구간이나 미해결 한국어 내용 결함은 없다. 47개의 유지 대상 TeX 파일이 동결된 신원과 일치하며, 리더는 46개의 고유 입력 파일을 사용한다. 나머지 p09_tail.tex은 P09 조립 계보를 재현하기 위한 별도 유지 파일이다.

공개 리더는 519쪽이다. DOI·범위 정보를 담은 표지 1쪽과 링크형 목차 2쪽 뒤에 완전한 누적 본문이 이어진다. 고정 시각 XeLaTeX 4회 빌드는 3·4회 출력이 바이트 단위로 같았다. 모든 38개 글꼴은 임베드·서브셋·ToUnicode 상태이고, Poppler와 pypdf 추출 모두 금지 제어문자·NUL·대체문자가 0개다. 519쪽 전부를 21개 연락판으로 렌더해 살폈고, 표지·목차·첫 본문·마지막 두 쪽은 고해상도로 다시 열었다.

## 공개 파일

- reader/: 가장 먼저 읽을 완전 누적 PDF.
- source/: 43개 논문, 두 번호 뒤 저작, 부록, 용어·범위·차이 기록, 결정적 빌드 코드.
- evidence/: 원문 권위, DataCite 관계, QA 상태, 공개물 해시, 미해결 항목 원장.
- Zenodo의 01_...EDITABLE_SOURCES.zip: 편집 가능한 완전 소스.
- Zenodo의 02_...EVIDENCE_AND_PROVENANCE.zip: 번역·교정·조판 의사결정, 원시 작업 기록, 독립 점검 반환, 빌드·추출·렌더 증거.

한국어판은 DataCite 의미에서 같은 범위의 원문에 IsTranslationOf, 다언어 디렉터리에 IsPartOf 관계를 가진다. 현행 Zenodo 관계 어휘가 IsTranslationOf를 제공하지 않으므로 기계 판독 가능한 전체 의도는 [DATACITE_RELATIONS.json](evidence/DATACITE_RELATIONS.json)에 보존한다.

## 재현

Windows, XeLaTeX, Python 3와 pypdf 6.12.2가 있는 환경에서 다음을 실행한다.

    powershell -ExecutionPolicy Bypass -File build/BUILD.ps1

빌드는 동결된 TeX 신원을 먼저 검사하고, 고정 시각 4회 XeLaTeX, 누락된 고전 수학 글꼴 CMap의 결정적 주입, 두 추출기의 문자 건전성 검사를 수행한다. 자세한 전제와 출력은 [build/README.md](build/README.md)에 있다.

## English identification

This is the standalone Korean (ko) edition of the complete maintained Emmy Noether corpus. Its declared object consists of 43 numbered papers, two separately identified post-numbered works/scopes, and the terminal bibliography/editorial apparatus. All 48 source scopes cover logical lines 1–24,146 of active German authority ED0011/v047 exactly once. No unresolved Korean translation span or known Korean content defect remains against that authority.

The 519-page linked reader is the public product. Editable TeX, terminology and delta ledgers, deterministic build code, independent checker returns, complete render evidence, and the raw decision/provenance records are preserved in the source and evidence archives. “Complete” describes the frozen coverage; future substantive corrections will receive new immutable version DOIs inside the stable Korean concept DOI lineage.
