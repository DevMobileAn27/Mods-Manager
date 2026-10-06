param(
    [string]$PrivateKeyPath = '',
    [string]$Repository = 'DevMobileAn27/visual-mods-manager',
    [string]$Tag = '',
    [string]$OutputDirectory = 'dist'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

# `dart run` may invoke Git while resolving the signing tool. Flutter bundles
# Git in its SDK, but `dart.bat` does not add that directory to PATH itself.
$dartCommand = Get-Command dart.exe -ErrorAction SilentlyContinue
if (-not $dartCommand) {
    $dartCommand = Get-Command dart -ErrorAction SilentlyContinue
}
if ($dartCommand) {
    $dartBin = Split-Path $dartCommand.Source
    $flutterRoot = Split-Path (Split-Path (Split-Path $dartBin))
    $bundledGit = Join-Path $flutterRoot 'bin\mingit\cmd'
    if ((Test-Path (Join-Path $bundledGit 'git.exe')) -and
        -not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $env:PATH = "$bundledGit;$env:PATH"
    }
}
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    throw 'Không tìm thấy git.exe. Hãy cài Git hoặc thêm Git vào PATH trước khi build.'
}

if ([string]::IsNullOrWhiteSpace($PrivateKeyPath)) {
    $PrivateKeyPath = Join-Path $repoRoot '.local-keys\windows-update\dsa_priv.pem'
}
$PrivateKeyPath = [IO.Path]::GetFullPath($PrivateKeyPath)

$versionLine = Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
if (-not $versionLine) { throw 'Không tìm thấy version trong pubspec.yaml.' }
$version = $versionLine.Matches[0].Groups[1].Value
if ($version -notmatch '^(\d+)\.(\d+)\.(\d+)\+(\d+)$') {
    throw "Version '$version' phải có dạng MAJOR.MINOR.PATCH+BUILD."
}
$windowsVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
if ([string]::IsNullOrWhiteSpace($Tag)) { $Tag = "v$version" }

function Invoke-Step([string]$Command, [string[]]$Arguments) {
    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor Cyan
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command thất bại với mã $LASTEXITCODE." }
}

if (-not (Test-Path $PrivateKeyPath -PathType Leaf)) {
    throw "Không tìm thấy dsa_priv.pem tại '$PrivateKeyPath'. Không đưa khóa riêng vào Git."
}

$outputPath = Join-Path $repoRoot $OutputDirectory
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

Invoke-Step 'flutter' @('pub', 'get')
Invoke-Step 'flutter' @('analyze')
Invoke-Step 'flutter' @('test')
Invoke-Step 'flutter' @('build', 'windows', '--release')
& (Join-Path $repoRoot 'scripts\prepare_7zip.ps1')

$pathIscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Source -First 1
$isccCandidates = @(
    $env:INNO_SETUP_ISCC,
    $pathIscc,
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
) | Where-Object { $_ -and (Test-Path $_ -PathType Leaf) }
$isccCandidates = @($isccCandidates)
if ($isccCandidates.Count -eq 0) {
    throw 'Không tìm thấy ISCC.exe. Hãy cài Inno Setup 6 hoặc đặt biến INNO_SETUP_ISCC.'
}
$iscc = $isccCandidates[0]
Invoke-Step $iscc @(
    "/DAppVersion=$version",
    "/DWindowsVersion=$windowsVersion",
    (Join-Path $repoRoot 'windows\installer\XXMI-Manager.iss')
)

$installer = Join-Path $outputPath 'Visual-Mods-Manager-Setup.exe'
if (-not (Test-Path $installer -PathType Leaf)) {
    throw "Inno Setup không tạo được '$installer'."
}

Write-Host '> dart run auto_updater:sign_update ...' -ForegroundColor Cyan
$signatureOutput = (& dart run auto_updater:sign_update $installer $PrivateKeyPath 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw "Ký installer thất bại.`n$signatureOutput" }
if ($signatureOutput -notmatch 'sparkle:dsaSignature="([^"]+)"') {
    throw "Không đọc được chữ ký WinSparkle từ kết quả ký.`n$signatureOutput"
}
$signature = $Matches[1]

$appcast = Join-Path $outputPath 'appcast.xml'
Invoke-Step 'python' @(
    (Join-Path $repoRoot 'scripts\create_appcast.py'),
    '--repository', $Repository,
    '--tag', $Tag,
    '--version', $version,
    '--signature', $signature,
    '--installer', $installer,
    '--output', $appcast
)

Write-Host "Đã tạo bản phát hành $version" -ForegroundColor Green
Write-Host "Installer: $installer"
Write-Host "Appcast:   $appcast"
Write-Host "Mở thư mục dist..." -ForegroundColor Cyan
Start-Process -FilePath 'explorer.exe' -ArgumentList @($outputPath)
