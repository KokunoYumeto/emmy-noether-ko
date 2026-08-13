# 편집 가능한 한국어 소스

publication.tex이 공개 리더의 최상위 파일이다. p01.tex–p43.tex,
post_a.tex, post_b.tex, back.tex은 완성된 한국어 본문이다.
p09_tail.tex은 P09 조립 계보를 재현하기 위해 별도로 유지된다.

prov12.csv는 47개 유지 대상 TeX 신원을, sp11.csv는 독일어 권위의
48개 연속 원문 범위를, coverage.csv는 사람에게 읽히는 범위와 역할을,
terms.csv와 deltas.csv는 용어 및 번역·교정 결정을 기록한다.

빌드 진입점은 상위의 build/BUILD.ps1이다. 생성 PDF, 로그, 추출문 및
보조 파일은 소스 ZIP에 포함하지 않는다. 재현된 영수증과 QA 결과는
증거 ZIP에 보존된다.
