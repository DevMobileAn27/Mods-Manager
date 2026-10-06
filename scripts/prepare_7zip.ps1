param(
    [string]$BuildDirectory = 'build\windows\x64\runner\Release'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$buildPath = Join-Path $repoRoot $BuildDirectory
if (-not (Test-Path $buildPath -PathType Container)) {
    throw "Không tìm thấy Windows build tại '$buildPath'."
}

$pathCommand = Get-Command 7z.exe -ErrorAction SilentlyContinue
$candidateDirectories = @(
    $env:SEVEN_ZIP_HOME,
    $(if ($pathCommand) { Split-Path $pathCommand.Source }),
    $(if ($env:ProgramFiles) { Join-Path $env:ProgramFiles '7-Zip' }),
    $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} '7-Zip' })
) | Where-Object { $_ -and (Test-Path (Join-Path $_ '7z.exe') -PathType Leaf) -and
    (Test-Path (Join-Path $_ '7z.dll') -PathType Leaf) }
$candidateDirectories = @($candidateDirectories)
if ($candidateDirectories.Count -eq 0) {
    throw 'Không tìm thấy 7z.exe và 7z.dll. Hãy cài 7-Zip hoặc đặt biến SEVEN_ZIP_HOME.'
}

$source = $candidateDirectories[0]
$license = Join-Path $source 'License.txt'
if (-not (Test-Path $license -PathType Leaf)) {
    throw "Không tìm thấy License.txt của 7-Zip tại '$source'."
}

$target = Join-Path $buildPath 'tools\7zip'
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item (Join-Path $source '7z.exe') $target -Force
Copy-Item (Join-Path $source '7z.dll') $target -Force
Copy-Item $license $target -Force
Write-Host "Đã đóng gói 7-Zip tại $target"
