$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw '找不到 Flutter SDK。請先安裝 Flutter 並將 flutter 加入 PATH。'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidPath = Join-Path $projectRoot 'android'
$iosPath = Join-Path $projectRoot 'ios'
if ((Test-Path -LiteralPath $androidPath) -or (Test-Path -LiteralPath $iosPath)) {
  throw 'android 或 ios 工程已存在。日常更新請使用 flutter pub get，不需再次執行 bootstrap。'
}

$templateRoot = Join-Path ([IO.Path]::GetTempPath()) ('parchment_flutter_' + [guid]::NewGuid().ToString('N'))
$projectLocationPushed = $false
try {
  flutter create --platforms=android,ios --org com.stackbase --project-name parchment $templateRoot
  Copy-Item -LiteralPath (Join-Path $templateRoot 'android') -Destination $androidPath -Recurse
  Copy-Item -LiteralPath (Join-Path $templateRoot 'ios') -Destination $iosPath -Recurse
  Copy-Item -LiteralPath (Join-Path $templateRoot '.metadata') -Destination (Join-Path $projectRoot '.metadata')
  Add-Content -LiteralPath (Join-Path $androidPath 'gradle.properties') -Value @'

# Pub cache and project may live on different Windows drives.
kotlin.incremental=false
'@

  Push-Location $projectRoot
  $projectLocationPushed = $true
  flutter pub get
  flutter analyze
  flutter test
} finally {
  if ($projectLocationPushed) { Pop-Location }
  if (Test-Path -LiteralPath $templateRoot) {
    Remove-Item -LiteralPath $templateRoot -Recurse -Force
  }
}
