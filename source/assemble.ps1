param(
    [string]$Repository = 'C:\Users\Floris\Documents\interlanguage'
)

$ErrorActionPreference = 'Stop'
$work = Join-Path $Repository '03_projects\language_management\cjk\03_working_translations'
$out = Join-Path $work 'ko_noether'

function Get-DocumentBody([string]$path) {
    $raw = Get-Content -LiteralPath $path -Raw -Encoding utf8
    $match = [regex]::Match($raw, '(?s)\\begin\{document\}\s*(.*?)\s*\\end\{document\}')
    if (-not $match.Success) {
        throw "No document body in $path"
    }
    return $match.Groups[1].Value.Trim()
}

function Get-FragmentBody([string]$path) {
    $lines = Get-Content -LiteralPath $path -Encoding utf8
    $first = 0
    while ($first -lt $lines.Count -and ($lines[$first] -match '^\s*%' -or $lines[$first] -match '^\s*$')) {
        $first++
    }
    if ($first -ge $lines.Count) {
        throw "No translation body in $path"
    }
    return (($lines[$first..($lines.Count - 1)] -join "`n").Trim())
}

function Write-AssembledPaper([string]$paper, [string[]]$relativePaths) {
    $parts = foreach ($relative in $relativePaths) {
        $path = Join-Path $work $relative
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        "% inherited: $relative`n% sha256: $hash`n$(Get-DocumentBody $path)"
    }
    $text = "% Korean Noether paper $paper — mechanically assembled inherited production body.`n" +
        "% Producer state only; independent checking and certification are outside this file.`n" +
        "% Current scope-rebase authority: ED0011 / NOETH-DE-AUTH-v047-20260808.`n`n" +
        ($parts -join "`n`n") + "`n"
    [System.IO.File]::WriteAllText((Join-Path $out "p$paper.tex"), $text, [System.Text.UTF8Encoding]::new($false))
}

function Write-AssembledFragments([string]$paper, [string[]]$relativePaths) {
    $parts = foreach ($relative in $relativePaths) {
        $path = Join-Path $work $relative
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        "% inherited: $relative`n% sha256: $hash`n$(Get-FragmentBody $path)"
    }
    $text = "% Korean Noether paper $paper — mechanically assembled inherited production body.`n" +
        "% Origin reopened against ED0004; current scope-rebase authority: ED0011 / NOETH-DE-AUTH-v047-20260808.`n`n" +
        ($parts -join "`n`n") + "`n"
    [System.IO.File]::WriteAllText((Join-Path $out "p$paper.tex"), $text, [System.Text.UTF8Encoding]::new($false))
}

Write-AssembledFragments '01' @(
    1..3 | ForEach-Object {
        'noether_paper01_ko_translation_001_20260804\ko\Noether_Paper01_Korean_U{0:D2}_translation_draft_v001.tex' -f $_
    }
)
$p02TargetDir = Join-Path $work 'noether_paper02_ko_translation_001_20260804\targets'
$p02Paths = Get-ChildItem -LiteralPath $p02TargetDir -File -Filter 'Noether_P02_Korean_T*_U*_UNCHECKED.tex' |
    ForEach-Object {
        if ($_.Name -notmatch '^Noether_P02_Korean_(T\d+)_(U(\d+))_UNCHECKED\.tex$') {
            throw "Unexpected P02 base filename: $($_.Name)"
        }
        [pscustomobject]@{
            Base = $_
            Tranche = $Matches[1]
            UnitToken = $Matches[2]
            Unit = [int]$Matches[3]
        }
    } |
    Sort-Object Unit |
    ForEach-Object {
        $r2 = Join-Path $p02TargetDir ('P02_{0}_{1}_r2.tex' -f $_.Tranche, $_.UnitToken)
        $repair = Get-ChildItem -LiteralPath $p02TargetDir -File -Filter ('Noether_P02_Korean_{0}_{1}_UNCHECKED_TEXREPAIR_*.tex' -f $_.Tranche, $_.UnitToken) |
            Sort-Object Name |
            Select-Object -Last 1
        $chosen = if (Test-Path -LiteralPath $r2) {
            Get-Item -LiteralPath $r2
        } elseif ($null -ne $repair) {
            $repair
        } else {
            $_.Base
        }
        [System.IO.Path]::GetRelativePath($work, $chosen.FullName)
    }
if ($p02Paths.Count -ne 199) {
    throw "Expected 199 selected P02 unit bodies, found $($p02Paths.Count)"
}
Write-AssembledFragments '02' $p02Paths
$p02 = Join-Path $out 'p02.tex'
$p02Text = Get-Content -LiteralPath $p02 -Raw -Encoding utf8
$p02Text = $p02Text.Replace('Origin reopened against ED0004', 'Origin reopened against ED0005')
$p02Text = $p02Text.Replace("% inherited: noether_paper02_ko_translation_001_20260804\targets\Noether_P02_Korean_T01_U02_UNCHECKED_TEXREPAIR_v002_20260804.tex", "\vspace{3em}`n`n% inherited: noether_paper02_ko_translation_001_20260804\targets\Noether_P02_Korean_T01_U02_UNCHECKED_TEXREPAIR_v002_20260804.tex")
$p02Text = $p02Text.Replace("% inherited: noether_paper02_ko_translation_001_20260804\targets\Noether_P02_Korean_T19_U119_UNCHECKED.tex", "\clearpage`n`n% inherited: noether_paper02_ko_translation_001_20260804\targets\Noether_P02_Korean_T19_U119_UNCHECKED.tex")
$p02Text = $p02Text.Replace('\noindent D) $\A_\nu^3$(C)의 이중 환원을 통한 $a_\eta^3$의 환원.', '\noindent D) C)의 $\A_\nu^3$을 이중 환원하여 $a_\eta^3$을 환원한다.')
[System.IO.File]::WriteAllText($p02, $p02Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledFragments '03' @(
    1..3 | ForEach-Object {
        'noether_paper03_ko_translation_001_20260804\targets\Noether_P03_Korean_U{0:D2}_UNCHECKED.tex' -f $_
    }
)
Write-AssembledFragments '04' @(
    1..50 | ForEach-Object {
        $tranche = switch ($_) {
            { $_ -le 4 } { 'T01'; break }
            { $_ -le 9 } { 'T02'; break }
            { $_ -le 16 } { 'T03'; break }
            { $_ -le 21 } { 'T04'; break }
            { $_ -le 26 } { 'T05'; break }
            { $_ -le 32 } { 'T06'; break }
            { $_ -le 38 } { 'T07'; break }
            { $_ -le 44 } { 'T08'; break }
            default { 'T09' }
        }
        'noether_paper04_ko_translation_001_20260804\targets\Noether_P04_Korean_{0}_U{1:D2}_UNCHECKED.tex' -f $tranche, $_
    }
)
$p04 = Join-Path $out 'p04.tex'
$p04Text = Get-Content -LiteralPath $p04 -Raw -Encoding utf8
$p04Text = $p04Text.Replace('그런데 열 $p_\rho,S^\rho$를 명시적으로 포함하는 기호적 표현은 존재하지 않는다.', '그런데 열 $p_\rho,S^\rho$를 명시적으로\footnote{명시적 표현의 더 정확한 정의는 \S\ 2에 있다.} 포함하는 기호적 표현은 존재하지 않는다.')
$p04Text = $p04Text.Replace('\text{(Mertens, Formel 23))}', '\text{(Mertens, 공식 23))}')
$p04Text = $p04Text.Replace('\text{(Mertens, Formel 9))}', '\text{(Mertens, 공식 9))}')
$p04Text = $p04Text.Replace('\text{also}', '\text{따라서}')
$p04Text = $p04Text.Replace('\text{wo }', '\text{여기서 }')
$p04Text = $p04Text.Replace('\text{\"aquivalent}', '\text{동치}')
$p04Text = $p04Text.Replace('하나의 가군으로 묶여 있다고 하자', '하나의 모듈로 묶여 있다고 하자')
$p04Text = $p04Text.Replace('그 가군의 기호들을', '그 모듈의 기호들을')
$p04Text = $p04Text.Replace('그러면 자기 자신에 대한 수축이 더 높은 형식을 \emph{더 높은 형식}이라 부르고, 자기 자신에 대한 수축이 같은 형식들 가운데서는 특히 정규화된 형식을 그렇게 부른다.', '그러면 자기 자신에 대한 더 높은 차수의 수축으로 생긴 형식을 \emph{더 높은 형식}이라 부르고, 자기수축의 차수가 같은 형식들 가운데서는 특별히 정규화한 형식을 그렇게 부른다.')
$p04Text = $p04Text.Replace('\qquad(\sigma\geqq\tau,\ \lambda=1,2,\ldots,\sigma,n-\tau).', '\qquad(\sigma\geqq\tau,\ \lambda=1,2,\ldots,\tau,n-\sigma).')
[System.IO.File]::WriteAllText($p04, $p04Text, [System.Text.UTF8Encoding]::new($false))
$p03 = Join-Path $out 'p03.tex'
$p03Text = Get-Content -LiteralPath $p03 -Raw -Encoding utf8
$p03Text = $p03Text.Replace('상징적', '기호적')
[System.IO.File]::WriteAllText($p03, $p03Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledFragments '05' @(
    1..4 | ForEach-Object {
        'noether_paper05_ko_translation_001_20260804\targets\Noether_P05_Korean_U{0:D2}_UNCHECKED.tex' -f $_
    }
)
$p06Paths = 1..228 | ForEach-Object {
    $unit = $_
    $tranche = switch ($unit) {
        { $_ -le 6 } { 'T01'; break }
        { $_ -le 14 } { 'T02'; break }
        { $_ -le 22 } { 'T03'; break }
        { $_ -le 34 } { 'T04'; break }
        { $_ -le 46 } { 'T05'; break }
        { $_ -le 63 } { 'T06'; break }
        { $_ -le 74 } { 'T07'; break }
        { $_ -le 106 } { 'T08'; break }
        { $_ -le 122 } { 'T09'; break }
        { $_ -le 143 } { 'T10'; break }
        { $_ -le 157 } { 'T11'; break }
        { $_ -le 170 } { 'T12'; break }
        { $_ -le 189 } { 'T13'; break }
        { $_ -le 195 } { 'T14'; break }
        { $_ -le 214 } { 'T15'; break }
        default { 'T16' }
    }
    $r2 = 'noether_paper06_ko_translation_001_20260804\targets\P06_{0}_U{1:D2}_r2.tex' -f $tranche, $unit
    if (Test-Path -LiteralPath (Join-Path $work $r2)) {
        $r2
    } elseif ($unit -le 74) {
        'noether_paper06_ko_translation_001_20260804\targets\Noether_P06_Korean_{0}_U{1:D2}_UNCHECKED.tex' -f $tranche, $unit
    } else {
        'noether_paper06_ko_translation_001_20260804\targets\{0}_U{1:D2}.tex' -f $tranche, $unit
    }
}
Write-AssembledFragments '06' $p06Paths
$p06 = Join-Path $out 'p06.tex'
$p06Text = Get-Content -LiteralPath $p06 -Raw -Encoding utf8
$p06Text = $p06Text.Replace('Origin reopened against ED0004', 'Origin reopened against ED0005')
$p06Text = $p06Text.Replace('\Psi(z,u)=x_1^2z^2-x_1^2u_1^2-2x_1^2x_2u_1u_2-x_1^2x_2^2u_2^2.', '\Psi(z,u)=x_1^2z^2-x_1^4u_1^2-2x_1^3x_2u_1u_2-x_1^2x_2^2u_2^2.')
$p06Text = $p06Text.Replace('계수(階數)', '랭크')
$p06Text = $p06Text.Replace('대수적 계수', '대수적 랭크')
$p06Text = $p06Text.Replace('가군 기저', '모듈기저')
$p06Text = $p06Text.Replace('가군기저', '모듈기저')
$p06Text = $p06Text.Replace('상대정함수들의 한 부류', '상대적으로 정수적인 함수들의 한 부류')
$p06Text = $p06Text.Replace('\glqq{}상대정함수의 정역\grqq{}', '\glqq{}상대적으로 정수적인 함수들의 정역\grqq{}')
$p06Text = $p06Text.Replace('기약인 정함수', '기약인 다항식')
$p06Text = $p06Text.Replace('기약 정함수 ---', '기약다항식 ---')
$p06Text = $p06Text.Replace('기약인 다항식', '기약다항식')
$p06Text = $p06Text.Replace('기약다항식 --- 이를 포함하는 최소 체 $\Kfield^*_{\rho\rho}$의 인볼루션형식 --- 는', '기약다항식 --- 이를 포함하는 최소 체 $\Kfield^*_{\rho\rho}$의 인볼루션형식 --- 은')
$p06Text = $p06Text.Replace('모든 정유리 결합', '모든 다항식 결합')
$p06Text = $p06Text.Replace('$\Omega$-계수 정유리 결합', '$\Omega$-계수 다항식 결합')
$p06Text = $p06Text.Replace('$\lambda_1\rcdots\lambda_\rho,\mu$의 정유리함수', '$\lambda_1\rcdots\lambda_\rho,\mu$의 다항함수')
$p06Text = $p06Text.Replace('으로 정수 유리적으로 나타낼 수 있다', '으로 다항식적으로 나타낼 수 있다')
$p06Text = $p06Text.Replace('(6)의 정수 유리 결합', '(6)의 다항식 결합')
$p06Text = $p06Text.Replace('계수 $G_{\alpha\alpha_1\ldots\alpha_n}(x)$들의 정수 유리 결합', '계수 $G_{\alpha\alpha_1\ldots\alpha_n}(x)$들의 다항식 결합')
$p06Text = $p06Text.Replace('정유리 사영불변식들', '다항 사영불변식들')
$p06Text = $p06Text.Replace('행렬식 $|a_{ik}|$의 정수 유리 결합', '행렬식 $|a_{ik}|$의 다항식 결합')
$p06Text = $p06Text.Replace('정수계수인 정수 유리 결합', '정수계수 다항식 결합')
$p06Text = $p06Text.Replace('정수계수 다항 결합', '정수계수 다항식 결합')
$p06Text = $p06Text.Replace('H(\xi)\ne0', 'H^*(\xi)\ne0')
$p06Text = $p06Text.Replace('비유리적 해석', '무리적 해석')
$p06Text = $p06Text.Replace('비유리적 표현', '무리적 표현')
$p06Text = $p06Text.Replace('부조건 $H^*(\xi)\ne0$', '부가조건 $H^*(\xi)\ne0$')
$p06Text = $p06Text.Replace('$\Lsys^*$가 $\Kfield^*_{\rho\rho}$의 한 부분이고', '$\Lsys^*$가 $\Kfield^*_{\rho\rho}$의 한 부분체이고')
$p06Text = $p06Text.Replace('$\Kfield_{n\rho}$의 부분 $\Lsys$', '$\Kfield_{n\rho}$의 부분체 $\Lsys$')
$p06Text = $p06Text.Replace('$x$에 켤레인 계열들과', '$x$에 켤레인 열들과')
$p06Text = $p06Text.Replace('결과식', '종결식')
$p06Text = $p06Text.Replace('양들의 행', '양들의 열')
$p06Text = $p06Text.Replace('그 밖의 행들', '그 밖의 열들')
$p06Text = $p06Text.Replace('정수계수 다항 대칭함수', '정수계수 대칭다항식')
$p06Text = $p06Text.Replace('정수계수 대칭다항식가 된다', '정수계수 대칭다항식이 된다')
$p06Text = $p06Text.Replace('최고차항의 계수가 $[\Omega]$의 한 단원이고 나머지 다항식들은 $\Gdom_{n\rho}$에 속하는 어떤 방정식', '최고차항의 계수가 $[\Omega]$의 한 단원이고 나머지 계수들이 $\Gdom_{n\rho}$의 다항식인 어떤 방정식')
$p06Text = $p06Text.Replace('이 정의를 기약방정식을 사용한 정의로부터 얻을 수 있음을 보여 준다', '이로부터 기약방정식에 의한 정의를 얻을 수 있음을 보여 준다')
$p06Text = $p06Text.Replace('$a_{\lambda_2}^{p_{\lambda_2}}a_{\mu}^{p_\mu}\cdots a_{\sigma}^{p_\sigma}$', '$a_{\lambda\lambda}^{p_\lambda}a_{\mu\mu}^{p_\mu}\cdots a_{\sigma\sigma}^{p_\sigma}$')
$p06Text = $p06Text.Replace('$p_\mu=0,\ldots,p_\rho=\tau$', '$p_\mu=0,\ldots,p_\sigma=\tau$')
[System.IO.File]::WriteAllText($p06, $p06Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledFragments '07' @(
    1..8 | ForEach-Object {
        'noether_paper07_ko_translation_001_20260804\targets\Noether_P07_Korean_U{0:D2}_UNCHECKED.tex' -f $_
    }
)
Write-AssembledFragments '08' @(
    1..36 | ForEach-Object {
        $unit = $_
        $tranche = switch ($unit) {
            { $_ -le 3 } { 1; break }
            { $_ -le 7 } { 2; break }
            { $_ -le 13 } { 3; break }
            { $_ -le 17 } { 4; break }
            { $_ -le 21 } { 5; break }
            { $_ -le 26 } { 6; break }
            { $_ -le 31 } { 7; break }
            default { 8 }
        }
        'noether_paper08_ko_translation_001_20260804\targets\T{0:D2}_U{1:D2}.tex' -f $tranche, $unit
    }
)
$p09TargetDir = Join-Path $work 'noether_p09_ko_20260804\targets'
$p09Units = Get-ChildItem -LiteralPath $p09TargetDir -Filter '*.tex' |
    Sort-Object { [int]([regex]::Match($_.BaseName, '_U(\d+)$').Groups[1].Value) } |
    ForEach-Object { 'noether_p09_ko_20260804\targets\' + $_.Name }
Write-AssembledFragments '09' $p09Units

$p09 = Join-Path $out 'p09.tex'
$p09Tail = Join-Path $out 'p09_tail.tex'
$p09TailHash = (Get-FileHash -LiteralPath $p09Tail -Algorithm SHA256).Hash
$p09Text = Get-Content -LiteralPath $p09 -Raw -Encoding utf8
$p09Text += "`n% fresh completion tail: ko_noether\p09_tail.tex`n% sha256: $p09TailHash`n$(Get-FragmentBody $p09Tail)`n"
$p09Text = $p09Text.Replace(
    '$\mathfrak G$의 유한개의 수에 대하여 대수적으로 정수이며 정수적으로 종속되는 모든 수는 $\mathfrak G$에 속한다.',
    '$\mathfrak G$의 유한개의 수에 대하여 대수적으로 정수이고, 그 종속방정식의 계수가 정수적인 모든 수는 $\mathfrak G$에 속한다.'
)
$p09Text = $p09Text.Replace('적어도 하나의 정렬에서는 어떠한 기저의 수도 유한개의 앞선 기저의 수를 써서', '적어도 하나의 정렬순서에서는 어떠한 기저원소도 유한개의 앞선 기저원소를 써서')
$p09Text = $p09Text.Replace('기저의 수', '기저원소')
$p09Text = $p09Text.Replace('정수적 다항식', '정수 계수 다항식')
$p09Text = $p09Text.Replace('그 기저의 모든 정수적 유리함수로 주어진다.', '그 기저의 모든 다항함수로 주어진다.')
$p09Text = $p09Text.Replace('가군 기저의 역할을 맡는다.', '모듈 기저의 역할을 맡는다.')
$p09Text = $p09Text.Replace('임의의 정렬 $\Omega$', '임의의 정렬순서 $\Omega$')
$p09Text = $p09Text.Replace('$\Omega$가 모든 정렬을 두루 취하고', '$\Omega$가 모든 정렬순서를 두루 취하고')
$p09Text = $p09Text.Replace('정수적 초월수의 영역 $\mathfrak G$에 정렬 $\Omega$', '정수적 초월수의 영역 $\mathfrak G$에 정렬순서 $\Omega$')
$p09Text = $p09Text.Replace('역으로 모든 초월기저는, 정렬에서 $H$를 맨 앞에 놓으면', '역으로 모든 초월기저는, 정렬순서에서 $H$를 맨 앞에 놓으면')
$p09Text = $p09Text.Replace('주어진 정렬에 따른 그 구성법', '주어진 정렬순서에 따른 그 구성법')
$p09Text = $p09Text.Replace('기저의 수들의 대수적으로 정수인 함수들', '기저원소들의 대수적으로 정수인 함수들')
$p09Text = $p09Text.Replace('모든 복소수의 체에 정렬 $\Omega$', '모든 복소수의 체에 정렬순서 $\Omega$')
$p09Text = $p09Text.Replace('앞선 기저의 양이 하나도 없으면', '앞선 기저원소가 하나도 없으면')
$p09Text = $p09Text.Replace('앞선 --- 3)에서 재귀적으로 정의되는 --- 기저의 양들', '앞선 --- 3)에서 재귀적으로 정의되는 --- 기저원소들')
$p09Text = $p09Text.Replace('특히 모든 분수형 대수수는 양 $y$에 속한다.', '특히 모든 분수형 대수수는 유형 1의 양 $y$이다.')
$p09Text = $p09Text.Replace('앞으로 기저의 양이라 부를 양 $\vartheta$', '앞으로 기저원소라 부를 양 $\vartheta$')
$p09Text = $p09Text.Replace('그러한 기저의 양이다.', '그러한 기저원소이다.')
$p09Text = $p09Text.Replace('특히 정렬에서 첫 번째 초월수', '특히 정렬순서에서 첫 번째 초월수')
$p09Text = $p09Text.Replace('모든 기저의 양 $\vartheta$', '모든 기저원소 $\vartheta$')
$p09Text = $p09Text.Replace('앞선 기저의 양들에 유리적으로', '앞선 기저원소들에 유리적으로')
$p09Text = $p09Text.Replace('역으로 정렬에서 $\Theta$를 맨 앞에 두면', '역으로 정렬순서에서 $\Theta$를 맨 앞에 두면')
$p09Text = $p09Text.Replace('Math. Ann. 75, 484쪽 (1914).', 'Math. Ann. 75, 434쪽 (1914).')
[System.IO.File]::WriteAllText($p09, $p09Text, [System.Text.UTF8Encoding]::new($false))

$p10 = Join-Path $out 'p10.tex'
$p10Text = Get-Content -LiteralPath $p10 -Raw -Encoding utf8
$p10Text = $p10Text.Replace('대수적 기저', '초월기저')
[System.IO.File]::WriteAllText($p10, $p10Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledFragments '41' @(
    1..12 | ForEach-Object {
        'noether_paper41_ko_translation_001_20260804\targets\Noether_P41_Korean_U{0:D2}_UNCHECKED.tex' -f $_
    }
)
Write-AssembledFragments '42' @(
    1..12 | ForEach-Object {
        'noether_paper42_ko_translation_001_20260804\ko\Noether_Paper42_Korean_U{0:D2}_translation_draft_v001.tex' -f $_
    }
)

$p05 = Join-Path $out 'p05.tex'
$p05Text = Get-Content -LiteralPath $p05 -Raw -Encoding utf8
$p05Text = $p05Text.Replace('정칙 유리결합, 곧 다항식적 결합', '다항식적 결합')
$p05Text = $p05Text.Replace('상대 정칙 함수의 문제', '상대적으로 정수적인 함수의 문제')
$p05Text = $p05Text.Replace('모든 정칙 유리 사영불변식은 판별식의 정칙 함수', '모든 다항 사영불변식은 판별식의 다항함수')
$p05Text = $p05Text.Replace('이면군', '이면체군')
[System.IO.File]::WriteAllText($p05, $p05Text, [System.Text.UTF8Encoding]::new($false))

$p41 = Join-Path $out 'p41.tex'
$p41Text = Get-Content -LiteralPath $p41 -Raw -Encoding utf8
$p41Text = $p41Text.Replace('\(A\)를 \(K\)에 대한 계수 \(n\)의 선형형식 가군으로 둔다', '\(A\)를 \(K\) 위에서 랭크 \(n\)인 선형형식 모듈로 둔다')
$p41Text = $p41Text.Replace('따라서 \(k\) 위에서 계수 \(n^2\)인 대수', '따라서 \(k\) 위에서 차원 \(n^2\)인 대수')
$p41Text = $p41Text.Replace('모든 (정칙) 원소', '모든 (가역) 원소')
$p41Text = $p41Text.Replace('슈어 지표', '슈어 지수')
$p41Text = $p41Text.Replace('\text{also}', '\text{따라서}')
$p41Text = $p41Text.Replace('극대차수', '극대 오더')
[System.IO.File]::WriteAllText($p41, $p41Text, [System.Text.UTF8Encoding]::new($false))

$p42 = Join-Path $out 'p42.tex'
$p42Text = Get-Content -LiteralPath $p42 -Raw -Encoding utf8
$p42Text = $p42Text.Replace('그 계수는 $K$의 계수와 일치한다. 왜냐하면 $\bar K E_\Hh$의 $\bar k$ 위 계수는 $n$이고', '그 랭크는 $K$의 랭크와 일치한다. 왜냐하면 $\bar K E_\Hh$의 $\bar k$ 위 랭크는 $n$이고')
$p42Text = $p42Text.Replace('$\bar K$의 $\bar k$ 위 계수는 $nh$', '$\bar K$의 $\bar k$ 위 랭크는 $nh$')
$p42Text = $p42Text.Replace('전계수', '최대 랭크')
$p42Text = $p42Text.Replace('$\mathfrak L$이 정칙인 경우에는 $a$의 계수가 $n$', '$\mathfrak L$이 정칙(최대 랭크)인 경우에는 $a$의 랭크가 $n$')
$p42Text = $p42Text.Replace('가군 $\mathfrak C$의 계수에 관하여 아무 가정도 하지 않는다는', '가군 $\mathfrak C$의 랭크에 관하여 아무 가정도 하지 않는다는')
[System.IO.File]::WriteAllText($p42, $p42Text, [System.Text.UTF8Encoding]::new($false))

Write-AssembledPaper '26' @(
    'noether_paper26_cjk_tranche_002_20260717\ko\Noether_Paper26_Korean_v001.tex'
)
Write-AssembledPaper '27' @(
    'noether_paper27_ko_tranche_001_20260718\ko\Noether_Paper27_Korean_v001.tex'
)
Write-AssembledPaper '28' @(
    'noether_paper28_cjk_tranche_003_20260718\ko\Noether_Paper28_Korean_v001.tex'
)
$p28 = Join-Path $out 'p28.tex'
$p28Text = Get-Content -LiteralPath $p28 -Raw -Encoding utf8
$p28Text = $p28Text.Replace('완전가약환(오늘날의 반단순환)', '완전가약환')
[System.IO.File]::WriteAllText($p28, $p28Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledPaper '29' @(
    'noether_paper29_ko_tranche_001_20260718\ko\Noether_Paper29_Korean_U01_v001.tex',
    'noether_paper29_ko_tranche_001_20260718\ko\Noether_Paper29_Korean_U02_v001.tex',
    'noether_paper29_ko_tranche_001_20260718\ko\Noether_Paper29_Korean_U03_v001.tex',
    'noether_paper29_ko_tranche_001_20260718\ko\Noether_Paper29_Korean_U04_v001.tex',
    'noether_paper29_ko_tranche_001_20260718\ko\Noether_Paper29_Korean_U05_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U06_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U07_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U08_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U09_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U10_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U11_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U12_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U13_translation_draft_v001.tex',
    'noether_paper29_ko_tranche_002_20260722\ko\Noether_Paper29_Korean_U14_translation_draft_v001.tex'
)
Write-AssembledPaper '32' @(
    1..19 | ForEach-Object {
        'noether_paper32_ko_translation_001_20260722\ko\Noether_Paper32_Korean_U{0:D2}_translation_draft_v001.tex' -f $_
    }
)
Write-AssembledPaper '33' @(
    1..8 | ForEach-Object {
        'noether_paper33_ko_translation_001_20260722\ko\Noether_Paper33_Korean_U{0:D2}_translation_draft_v001.tex' -f $_
    }
)
$p33 = Join-Path $out 'p33.tex'
$p33Text = Get-Content -LiteralPath $p33 -Raw -Encoding utf8
$p33Text = $p33Text.Replace("\renewcommand{\thefootnote}{(\arabic{footnote})}", "\begingroup`n\renewcommand{\thefootnote}{(\arabic{footnote})}")
$p33Text = $p33Text.TrimEnd() + "`n`n\endgroup`n"
[System.IO.File]::WriteAllText($p33, $p33Text, [System.Text.UTF8Encoding]::new($false))
Write-AssembledPaper '36' @(
    'noether_paper36_cjk_tranche_001_20260717\ko\Noether_Paper36_Korean_v001.tex'
)

$p29 = Join-Path $out 'p29.tex'
$p29Text = Get-Content -LiteralPath $p29 -Raw -Encoding utf8
$p29Text = $p29Text.Replace('\mathfrak K$는 $\mathfrak R$의 분수체\footnote{원논문 28쪽 각주 2 참조.}', '\mathfrak K$는 $\mathfrak R$의 분수체\footnotemark[\value{footnote}]')
$p29Text = $p29Text.Replace('갈루아 분해식', '갈루아 레졸벤트')
$p29Text = $p29Text.Replace('정유리(整有理) (절대) 불변식', '다항 (절대)불변식')
$p29Text = $p29Text.Replace('정유리 함수(곧 다항함수)', '다항함수')
[System.IO.File]::WriteAllText($p29, $p29Text, [System.Text.UTF8Encoding]::new($false))

$p32 = Join-Path $out 'p32.tex'
$p32Text = Get-Content -LiteralPath $p32 -Raw -Encoding utf8
$p32Old = '최소 차수의 모든 분해체는 그들 가운데 하나에 포함된다.'
$p32New = '최소 차수의 모든 분해체는 이들 가운데 하나이다.'
$p32OldCount = ([regex]::Matches($p32Text, [regex]::Escape($p32Old))).Count
$p32NewCount = ([regex]::Matches($p32Text, [regex]::Escape($p32New))).Count
if ($p32OldCount -eq 1 -and $p32NewCount -eq 0) {
    $p32Text = $p32Text.Replace($p32Old, $p32New)
} elseif ($p32OldCount -ne 0 -or $p32NewCount -ne 1) {
    throw "Unexpected P32 U06 correction state: old=$p32OldCount new=$p32NewCount"
}
[System.IO.File]::WriteAllText($p32, $p32Text, [System.Text.UTF8Encoding]::new($false))
