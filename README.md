# 에미 뇌터 — 수학 저작집 한국어판

에미 뇌터(Emmy Noether, 1882–1935)의 수학 저작집 한국어 번역본이다. 논문 1–43, M. Deuring이 기록한 1929/30년 겨울학기 강의 「초복소량의 대수학」, H. Kapferer의 논문과 E. Noether가 공동 집필한 보충문, 그리고 참고문헌과 단신·서평·공동 편집서 목록을 수록한다. 불변식, 아이디얼, 체, 대수와 표현론을 다룬다. PDF와 편집 가능한 LaTeX로 제공한다.

[**기본 본문 PDF 읽기 (519쪽)**](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/01-noether-ko-base.pdf) · [교정 본문 PDF (525쪽)](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/04-noether-ko-emendations.pdf) · [2026년 10월 27일 판의 모든 파일](https://github.com/KokunoYumeto/emmy-noether-ko/releases/tag/noether-ko-2026-10-27-r4)

## 제작 방식

한국어 본문은 AI가 번역하였다. 번역은 OpenAI Codex 모델이 하였으며, 어느 모델이 번역했는지는 기록되어 있지 않다. 이 판의 본문은 2026년 8월 13일의 한국어판 v1.0.0을 저본으로 하며, v1.0.0은 AI가 원래 인쇄본에서 전사한 독일어 본문 ED0011/v047(2026년 8월 8일)을 번역한 것이다. 이 판의 수정과 조판은 OpenAI Codex — GPT-6 Astra(Ultra 추론 설정)와 Claude Opus 5.5(Anthropic, 2026년 10월 26–27일)가 제작하였다. Claude Opus 5.5는 수식을 Noether의 인쇄면에서 읽은 독일어 본문과 대조하여 맞추었다.

## 현황

위에 적은 저작이 모두 수록되어 있다. 번역은 사람이 검토하지 않았으므로 오류가 남아 있을 수 있다. 또한 번역이 문장을 독자적으로 옮긴 곳에서는 일부 수식이 아직 이전 독일어 전사본을 따를 수 있다. 오류 제보와 수정 제안은 [GitHub issues](https://github.com/KokunoYumeto/emmy-noether-ko/issues)로 보내 주십시오.

## 내용과 읽는 법

이 판은 두 가지 본문으로 제공되며, 본문마다 PDF, LaTeX 파일 하나, 조판 소스 ZIP이 있다.

| 본문 | PDF | LaTeX | 소스 |
|---|---|---|---|
| 기본 본문: 원래 인쇄본의 읽기를 유지하고, 해당 읽기를 편집 주석에서 논의한다 | [PDF, 519쪽](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/01-noether-ko-base.pdf) | [LaTeX](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/02-noether-ko-base.tex) | [ZIP](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/03-noether-ko-base-sources.zip) |
| 교정 본문: 편집상의 교정을 적용하고, 각 교정의 근거를 편집 주석으로 설명한다 | [PDF, 525쪽](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/04-noether-ko-emendations.pdf) | [LaTeX](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/05-noether-ko-emendations.tex) | [ZIP](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/06-noether-ko-emendations-sources.zip) |

[SHA-256 목록](https://github.com/KokunoYumeto/emmy-noether-ko/releases/download/noether-ko-2026-10-27-r4/07-SHA256SUMS.txt). 같은 파일이 [`editions/2026-10-24/ko/reader-edition/`](editions/2026-10-24/ko/reader-edition/)에도 있다.

각 LaTeX 파일에는 해당 본문 전체가 들어 있다. 각 ZIP에는 같은 전체 본문 파일, 원래의 분할 구조, 필요한 조판 절차와 스크립트가 들어 있다. 조판에는 XeLaTeX와 소스에 지정된 글꼴 및 패키지가 필요하며, 글꼴 파일은 동봉하지 않는다.

2026년 8월의 한국어판 v1.0.0은 [`reader/`](reader/)(PDF)와 [`source/`](source/)(LaTeX)에 있고, 그 기록은 [`evidence/`](evidence/)에 있다. [v1.0.0 릴리스](https://github.com/KokunoYumeto/emmy-noether-ko/releases/tag/v1.0.0)에서도 받을 수 있다. 독일어 본문과 다른 언어판, 판본 사이의 알려진 차이는 [중앙 페이지](https://kokunoyumeto.github.io/emmy-noether/)에 정리되어 있다.

## 원저자와 출처

- 원저자는 Emmy Noether 및 각 저작에 명시된 공동 저자이다: Werner Schmeidler(논문 17), R. Brauer(논문 32), R. Brauer와 H. Hasse(논문 38). 1929/30년 강의는 M. Deuring이 기록하였다. 저작 45는 H. Kapferer의 논문이며, E. Noether가 공동 집필한 보충문이 붙어 있다. 각 저작의 원래 출판 정보, 저자 표시 및 인용은 본문에 있다.
- 저본: 한국어판 v1.0.0(2026년 8월 13일, Manuscript Typesetting Project / OpenAI Codex)과 그 독일어 저본 ED0011/v047(2026년 8월 8일). 수식은 원래 인쇄본과 쪽마다 대조한 독일어 본문([noether-de-2026-10-26](https://github.com/KokunoYumeto/modern-latex-manuscripts/releases/tag/noether-de-2026-10-26))을 따른다.
- [저자·출처·권리](editions/2026-10-24/ko/reader-edition/RIGHTS.md) · [이전 판본의 권리 표시](editions/2026-10-24/ko/reader-edition/NOTICE_HISTORIQUE.md)

## 권리

Emmy Noether의 저작은 퍼블릭 도메인에 속한다. 발행자가 AI가 제작한 번역·수정·조판에 대하여 권리를 가지는 범위에서, 그 권리는 [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/deed.ko)에 따라 퍼블릭 도메인에 기증된다. M. Deuring이 기록한 강의, H. Kapferer의 논문과 명시된 공동 저자의 기여는 각자의 법적 지위를 유지한다.
