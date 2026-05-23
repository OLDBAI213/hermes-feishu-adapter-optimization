param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "E:\AI\hermes" }),
    [switch]$VerifyOnly,
    [string]$Rollback = ""
)

$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
    param([string]$Message)
    Write-Host "`n== $Message =="
}

function Resolve-HermesHome {
    param([string]$Requested)
    $full = [System.IO.Path]::GetFullPath($Requested)
    if (-not (Test-Path -LiteralPath (Join-Path $full "config.yaml"))) {
        throw "config.yaml not found under HermesHome: $full"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $full "hermes-agent"))) {
        throw "hermes-agent not found under HermesHome: $full"
    }
    return $full
}

function New-SourceBackup {
    param([string]$HermesRoot)
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $dir = Join-Path $HermesRoot "backups\hermes-feishu-adapter-optimization-$stamp"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item -LiteralPath (Join-Path $HermesRoot "config.yaml") -Destination (Join-Path $dir "config.yaml") -Force

    $listPath = Join-Path $PackageRoot "patches\source-files.txt"
    foreach ($relative in Get-Content -LiteralPath $listPath) {
        if (-not $relative.Trim()) { continue }
        $source = Join-Path $HermesRoot $relative
        if (Test-Path -LiteralPath $source) {
            $dest = Join-Path $dir $relative
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
            Copy-Item -LiteralPath $source -Destination $dest -Force
        }
    }
    return $dir
}

function Restore-LatestBackup {
    param([string]$HermesRoot)
    $backupRoot = Join-Path $HermesRoot "backups"
    $latest = Get-ChildItem -LiteralPath $backupRoot -Directory -Filter "hermes-feishu-adapter-optimization-*" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if (-not $latest) { throw "No hermes-feishu-adapter-optimization backup found." }

    $listPath = Join-Path $PackageRoot "patches\source-files.txt"
    foreach ($relative in Get-Content -LiteralPath $listPath) {
        if (-not $relative.Trim()) { continue }
        $backupFile = Join-Path $latest.FullName $relative
        if (Test-Path -LiteralPath $backupFile) {
            $dest = Join-Path $HermesRoot $relative
            Copy-Item -LiteralPath $backupFile -Destination $dest -Force
        }
    }
    $configBackup = Join-Path $latest.FullName "config.yaml"
    if (Test-Path -LiteralPath $configBackup) {
        Copy-Item -LiteralPath $configBackup -Destination (Join-Path $HermesRoot "config.yaml") -Force
    }
    Write-Host "Restored latest backup: $($latest.FullName)"
}

function Apply-Replacements {
    param(
        [string]$JsonPath,
        [string]$RootPath,
        [string]$BackupDir
    )
    if (-not (Test-Path -LiteralPath $JsonPath)) { return }
    $items = Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in $items) {
        $target = Join-Path $RootPath $item.file
        if (-not (Test-Path -LiteralPath $target)) {
            throw "Patch target not found: $target"
        }
        $backupName = ($item.file -replace '[\\/]', '__') + ".bak"
        $backupPath = Join-Path $BackupDir $backupName
        if (-not (Test-Path -LiteralPath $backupPath)) {
            Copy-Item -LiteralPath $target -Destination $backupPath -Force
        }
        $text = Get-Content -LiteralPath $target -Raw -Encoding UTF8
        if ($text.Contains($item.replace)) {
            continue
        }
        if (-not $text.Contains($item.find)) {
            throw "Patch marker not found in $target"
        }
        $text = $text.Replace($item.find, $item.replace)
        Set-Content -LiteralPath $target -Value $text -Encoding UTF8 -NoNewline
    }
}

$HermesHome = Resolve-HermesHome -Requested $HermesHome
$env:HERMES_HOME = $HermesHome

if ($VerifyOnly) {
    & (Join-Path $PackageRoot "verify.ps1") -HermesHome $HermesHome
    exit $LASTEXITCODE
}

if ($Rollback) {
    if ($Rollback -ne "latest") { throw "Only -Rollback latest is supported." }
    Write-Step "Rollback"
    Restore-LatestBackup -HermesRoot $HermesHome
    & (Join-Path $PackageRoot "verify.ps1") -HermesHome $HermesHome
    exit $LASTEXITCODE
}

Write-Step "Backup"
$backup = New-SourceBackup -HermesRoot $HermesHome
Write-Host "Backup created: $backup"

Write-Step "Apply source adapter patch"
Apply-Replacements -JsonPath (Join-Path $PackageRoot "patches\source.replacements.json") -RootPath $HermesHome -BackupDir $backup
Write-Host "Source adapter patch checked/applied"

Write-Step "Verify"
& (Join-Path $PackageRoot "verify.ps1") -HermesHome $HermesHome
exit $LASTEXITCODE
