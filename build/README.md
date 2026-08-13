# 결정적 빌드

전제:

- Windows PowerShell
- MiKTeX XeLaTeX
- Python 3
- pypdf 6.12.2
- Poppler pdftotext와 pdffonts
- 설치된 Malgun Gothic 및 Times New Roman 글꼴

실행:

    powershell -ExecutionPolicy Bypass -File BUILD.ps1

source/build.py는 publication.tex, 기존 누적 reader.tex,
prov12.csv와 47개 본문 입력의 바이트/해시를 먼저 확인한다. 이어
SOURCE_DATE_EPOCH=1786579200, UTC에서 XeLaTeX를 4회 직렬 실행하고
3·4회 PDF가 바이트 동일한지 검사한다. source/fix.py는 고전 수학
글꼴 7개에 고정 CMap을 결정적으로 주입하되 페이지 스트림·기하·글꼴
프로그램·메타데이터를 바꾸지 않는다. 마지막으로 Poppler와 pypdf
추출에서 금지 C0, NUL, U+FFFD가 0인지 확인한다.

성공 출력은 source/reader.pdf; 원시 XeLaTeX 출력은
source/raw.pdf; 기계 판독 영수증은 source/build.json과
source/fix.json이다.
