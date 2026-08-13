$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'source'
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'build.py'))) {
    throw 'source/build.py is missing'
}
Push-Location $sourceRoot
try {
    py build.py
}
finally {
    Pop-Location
}
