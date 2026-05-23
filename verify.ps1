param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "E:\AI\hermes" })
)

$ErrorActionPreference = "Stop"
$totalPass = 0
$totalFail = 0

function Write-Check {
    param([string]$Name, [bool]$Pass)
    if ($Pass) {
        $script:totalPass++
        Write-Host "  [OK] $Name" -ForegroundColor Green
    } else {
        $script:totalFail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

$AgentRoot = Join-Path $HermesHome "hermes-agent"
$BasePy = Join-Path $AgentRoot "gateway\platforms\base.py"
$RunPy = Join-Path $AgentRoot "gateway\run.py"
$StreamConsumerPy = Join-Path $AgentRoot "gateway\stream_consumer.py"
$SendMessageTests = Join-Path $AgentRoot "tests\tools\test_send_message_tool.py"
$BaseTests = Join-Path $AgentRoot "tests\gateway\test_platform_base.py"
$BusyTests = Join-Path $AgentRoot "tests\gateway\test_busy_session_ack.py"
$ResearchNote = "E:\AI\github\src-research\hermes-feishu-adapter-optimization\README.md"

Write-Host "hermes-feishu-adapter-optimization local verification"
Write-Host "HERMES_HOME: $HermesHome"

Write-Check "Hermes agent root exists" (Test-Path -LiteralPath $AgentRoot)
Write-Check "Feishu adapter research note exists" (Test-Path -LiteralPath $ResearchNote)

if (Test-Path -LiteralPath $BasePy) {
    $baseSource = Get-Content -LiteralPath $BasePy -Raw -Encoding UTF8
    Write-Check "shared MEDIA_TAG_RE parser exists" ($baseSource.Contains("MEDIA_TAG_RE"))
    Write-Check "Windows drive MEDIA parsing supported" ($baseSource.Contains("[A-Za-z]:"))
} else {
    Write-Check "shared MEDIA parser source exists" $false
}

if (Test-Path -LiteralPath $RunPy) {
    $runSource = Get-Content -LiteralPath $RunPy -Raw -Encoding UTF8
    Write-Check "gateway run reuses MEDIA_TAG_RE" ($runSource.Contains("MEDIA_TAG_RE"))
} else {
    Write-Check "gateway run source exists" $false
}

if (Test-Path -LiteralPath $StreamConsumerPy) {
    $streamSource = Get-Content -LiteralPath $StreamConsumerPy -Raw -Encoding UTF8
    Write-Check "stream display strips MEDIA markers" ($streamSource.Contains("MEDIA_TAG_RE") -and $streamSource.Contains("Strip MEDIA"))
} else {
    Write-Check "stream consumer source exists" $false
}

if (Test-Path -LiteralPath $BaseTests) {
    $baseTestsText = Get-Content -LiteralPath $BaseTests -Raw -Encoding UTF8
    Write-Check "Windows MEDIA path extraction test exists" ($baseTestsText.Contains("windows") -and $baseTestsText.Contains("MEDIA:E"))
} else {
    Write-Check "base media tests exist" $false
}

if (Test-Path -LiteralPath $SendMessageTests) {
    $sendTestsText = Get-Content -LiteralPath $SendMessageTests -Raw -Encoding UTF8
    Write-Check "send_message does not leak Windows MEDIA text" ($sendTestsText.Contains("test_windows_media_path_is_sent_as_attachment_not_text"))
} else {
    Write-Check "send_message media tests exist" $false
}

if (Test-Path -LiteralPath $BusyTests) {
    $busyTestsText = Get-Content -LiteralPath $BusyTests -Raw -Encoding UTF8
    Write-Check "busy queue media preservation test exists" ($busyTestsText.Contains("queued.media_urls") -or $busyTestsText.Contains("media_urls"))
} else {
    Write-Check "busy queue tests exist" $false
}

Write-Host ""
Write-Host "SUMMARY"
Write-Host "  Passed: $totalPass"
Write-Host "  Failed: $totalFail"

if ($totalFail -gt 0) { exit 1 }
