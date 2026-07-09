# Package a Windows Flutter release build for distribution.
#
# Usage:
#   pwsh scripts/windows/package_release.ps1 `
#     -SourceDir build/windows/x64/runner/Release `
#     -Version 1.0.3 `
#     -OutputZip VibePaint-1.0.3-win-x64.zip `
#     -InstallerOutput VibePaint-1.0.3-win-x64-setup.exe
param(
  [Parameter(Mandatory = $true)]
  [string]$SourceDir,

  [Parameter(Mandatory = $true)]
  [string]$Version,

  [Parameter(Mandatory = $true)]
  [string]$OutputZip,

  [string]$InstallerOutput
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SourceDir)) {
  throw "Source directory not found: $SourceDir"
}

$exePath = Join-Path $SourceDir 'VibePaint.exe'
if (-not (Test-Path $exePath)) {
  throw "Expected VibePaint.exe in $SourceDir"
}

$tempRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
$stageRoot = Join-Path $tempRoot "vibepaint-win-$Version"
$bundleName = "VibePaint-$Version-win-x64"
$stageDir = Join-Path $stageRoot $bundleName
$appDir = Join-Path $stageDir 'VibePaint'

Remove-Item -Recurse -Force $stageRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $appDir -Force | Out-Null

Copy-Item -Path (Join-Path $SourceDir '*') -Destination $appDir -Recurse -Force

$readme = @"
VibePaint $Version for Windows (64-bit)
=======================================

Recommended install
-------------------
Use VibePaint-$Version-win-x64-setup.exe for a normal Windows install
(Start menu shortcut, Add/Remove Programs uninstall).

Portable zip
------------
1. Open the VibePaint folder next to this file.
2. Double-click VibePaint.exe.

First launch
------------
This build is not code-signed. Windows SmartScreen may show
"Windows protected your PC".

  1. Click "More info"
  2. Click "Run anyway"

You only need to do this once per download.

Portable uninstall
------------------
Delete the VibePaint folder.

More help: https://github.com/merklegroot/vibepaint
"@

Set-Content -Path (Join-Path $stageDir 'README.txt') -Value $readme -Encoding utf8NoBOM

if (Test-Path $OutputZip) {
  Remove-Item -Force $OutputZip
}

Compress-Archive -Path $stageDir -DestinationPath $OutputZip
Write-Host "Wrote $OutputZip"
Get-Item $OutputZip | Format-List Name, Length, LastWriteTime

if ($InstallerOutput) {
  $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
  if (-not (Test-Path $iscc)) {
    throw "Inno Setup not found at $iscc. Install Inno Setup 6 to build the installer."
  }

  $iss = Join-Path $PSScriptRoot 'vibepaint.iss'
  $installerName = [System.IO.Path]::GetFileName($InstallerOutput)
  $outputBase = [System.IO.Path]::GetFileNameWithoutExtension($installerName)
  $installerParent = Split-Path -Parent $InstallerOutput
  $outputDir = if ($installerParent) {
    (Resolve-Path $installerParent).Path
  } else {
    (Get-Location).Path
  }
  $installerPath = Join-Path $outputDir $installerName

  & $iscc `
    "/DAppVersion=$Version" `
    "/DSourceDir=$appDir" `
    "/DOutputDir=$outputDir" `
    "/DOutputBaseFilename=$outputBase" `
    $iss

  if (-not (Test-Path $installerPath)) {
    throw "Installer build did not produce $installerPath"
  }

  Write-Host "Wrote $installerPath"
  Get-Item $installerPath | Format-List Name, Length, LastWriteTime
}
