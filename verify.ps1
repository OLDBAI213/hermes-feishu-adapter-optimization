param(
    [string]$HermesHome = $(if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "" }),
    [switch]$Full,
    [switch]$SkipGatewayStatus
)

$ErrorActionPreference = "Stop"
$totalPass = 0
$totalFail = 0
$totalWarn = 0

function Write-Check {
    param([string]$Name, [bool]$Pass, [string]$Detail = "")
    if ($Pass) {
        $script:totalPass++
        Write-Host "  [OK] $Name" -ForegroundColor Green
    } else {
        $script:totalFail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
    if ($Detail) {
        Write-Host "       $Detail" -ForegroundColor DarkGray
    }
}

function Write-WarnCheck {
    param([string]$Name, [string]$Detail = "")
    $script:totalWarn++
    Write-Host "  [WARN] $Name" -ForegroundColor Yellow
    if ($Detail) {
        Write-Host "       $Detail" -ForegroundColor DarkGray
    }
}

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Test-CommandSuccess {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }
        $psi.WorkingDirectory = $WorkingDirectory
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        $ok = $proc.ExitCode -eq 0
        $detail = if ($ok) { ($stdout -split "`r?`n" | Select-Object -Last 4) -join " " } else { (($stdout + "`n" + $stderr) -split "`r?`n" | Select-Object -Last 8) -join " " }
        Write-Check $Name $ok $detail.Trim()
        return $ok
    } catch {
        Write-Check $Name $false $_.Exception.Message
        return $false
    }
}

$AgentRoot = Join-Path $HermesHome "hermes-agent"
$ConfigYaml = Join-Path $HermesHome "config.yaml"
$GatewayLog = Join-Path $HermesHome "logs\gateway.log"
$BasePy = Join-Path $AgentRoot "gateway\platforms\base.py"
$FeishuPy = Join-Path $AgentRoot "gateway\platforms\feishu.py"
$RunPy = Join-Path $AgentRoot "gateway\run.py"
$RunAgentPy = Join-Path $AgentRoot "run_agent.py"
$StreamConsumerPy = Join-Path $AgentRoot "gateway\stream_consumer.py"
$ImageRoutingPy = Join-Path $AgentRoot "agent\image_routing.py"
$AuxiliaryClientPy = Join-Path $AgentRoot "agent\auxiliary_client.py"
$GatewayWindowsPy = Join-Path $AgentRoot "hermes_cli\gateway_windows.py"
$SendMessageTests = if (Test-Path -LiteralPath (Join-Path $AgentRoot "tests\tools\test_send_message_tool.py")) { Join-Path $AgentRoot "tests\tools\test_send_message_tool.py" } else { Join-Path $AgentRoot "tests\gateway\test_send_message_tool.py" }
$BaseTests = Join-Path $AgentRoot "tests\gateway\test_platform_base.py"
$BusyTests = Join-Path $AgentRoot "tests\gateway\test_busy_session_ack.py"
$FeishuTests = Join-Path $AgentRoot "tests\gateway\test_feishu.py"
$RunProgressTests = Join-Path $AgentRoot "tests\gateway\test_run_progress_topics.py"
$ImageRoutingTests = Join-Path $AgentRoot "tests\agent\test_image_routing.py"
$VisionResolvedArgsTests = Join-Path $AgentRoot "tests\agent\test_vision_resolved_args.py"
$VisionAwareTests = Join-Path $AgentRoot "tests\run_agent\test_vision_aware_preprocessing.py"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResearchNote = Join-Path $ProjectRoot "docs\research.md"
$AcceptanceMatrix = Join-Path $ProjectRoot "docs\acceptance-matrix.md"
$PreflightDoc = Join-Path $ProjectRoot "docs\preflight.md"
$ManualCases = Join-Path $ProjectRoot "examples\manual-feishu-cases.md"
$AcceptanceHarness = Join-Path $ProjectRoot "tests\feishu_acceptance_harness.py"

Write-Host "hermes-feishu-adapter-optimization audit"
if (-not $HermesHome) {
    Write-Host "  [ERROR] HERMES_HOME not set and not provided as parameter." -ForegroundColor Red
    Write-Host "  Usage: .\verify.ps1 -HermesHome C:\path\to\hermes" -ForegroundColor Yellow
    exit 1
}
Write-Host "HERMES_HOME: $HermesHome"
Write-Host "Mode: $(if ($Full) { 'Full' } else { 'Static' })"
Write-Host ""

Write-Host "1. Direction and project files"
Write-Check "Hermes agent root exists" (Test-Path -LiteralPath $AgentRoot) $AgentRoot
if (Test-Path -LiteralPath $ResearchNote) {
    Write-Check "Feishu adapter project research note exists" $true $ResearchNote
} else {
    Write-Host "  [WARN] Research note not found (optional): $ResearchNote" -ForegroundColor Yellow
}
Write-Check "Hermes config exists" (Test-Path -LiteralPath $ConfigYaml) $ConfigYaml
Write-Check "adapter acceptance matrix exists" ((Test-Path -LiteralPath $AcceptanceMatrix) -and (Read-Text $AcceptanceMatrix).Contains("模块矩阵") -and (Read-Text $AcceptanceMatrix).Contains("显示增强负责")) $AcceptanceMatrix
Write-Check "preflight map, risk matrix, and self-check exist" ((Test-Path -LiteralPath $PreflightDoc) -and (Read-Text $PreflightDoc).Contains("能力地图") -and (Read-Text $PreflightDoc).Contains("风险矩阵") -and (Read-Text $PreflightDoc).Contains("验收样例") -and (Read-Text $PreflightDoc).Contains("自省自检")) $PreflightDoc
Write-Check "manual Feishu cases exist" ((Test-Path -LiteralPath $ManualCases) -and (Read-Text $ManualCases).Contains("图文混排") -and (Read-Text $ManualCases).Contains("重启 Gateway")) $ManualCases
Write-Check "independent behavior harness exists" ((Test-Path -LiteralPath $AcceptanceHarness) -and (Read-Text $AcceptanceHarness).Contains("behavior fixtures")) $AcceptanceHarness

$baseSource = Read-Text $BasePy
$feishuSource = Read-Text $FeishuPy
$runSource = Read-Text $RunPy
$runAgentSource = Read-Text $RunAgentPy
$streamSource = Read-Text $StreamConsumerPy
$imageRoutingSource = Read-Text $ImageRoutingPy
$auxiliaryClientSource = Read-Text $AuxiliaryClientPy
$gatewayWindowsSource = Read-Text $GatewayWindowsPy
$configSource = Read-Text $ConfigYaml
$feishuTestsText = Read-Text $FeishuTests
$runProgressTestsText = Read-Text $RunProgressTests
$imageRoutingTestsText = Read-Text $ImageRoutingTests
$visionResolvedArgsTestsText = Read-Text $VisionResolvedArgsTests
$visionAwareTestsText = Read-Text $VisionAwareTests
$baseTestsText = Read-Text $BaseTests
$sendMessageTestsText = Read-Text $SendMessageTests
$busyTestsText = Read-Text $BusyTests
$acceptanceMatrixText = Read-Text $AcceptanceMatrix
$manualCasesText = Read-Text $ManualCases
$manifestText = Read-Text (Join-Path $ProjectRoot "manifest.json")

Write-Host ""
Write-Host "2. Input and media routing"
Write-Check "shared MEDIA_TAG_RE parser exists" ($baseSource.Contains("MEDIA_TAG_RE"))
Write-Check "Windows drive MEDIA parsing supported" ($baseSource.Contains("[A-Za-z]:"))
Write-Check "gateway run reuses MEDIA_TAG_RE" ($runSource.Contains("MEDIA_TAG_RE"))
Write-Check "stream display strips MEDIA markers" ($streamSource.Contains("MEDIA_TAG_RE") -and $streamSource.Contains("Strip MEDIA"))
Write-Check "Feishu downloads image resources" ($feishuSource.Contains("async def _download_feishu_image") -and $feishuSource.Contains("message_resource.get"))
Write-Check "Feishu downloads file/audio/video resources" ($feishuSource.Contains("async def _download_feishu_message_resource"))
Write-Check "native image text does not expose local cache paths" ($imageRoutingSource.Contains("must not expose local cache paths") -and $imageRoutingSource.Contains("image_url"))
Write-Check "native image regression tests exist" ($imageRoutingTestsText.Contains("[Image attached at:") -and $imageRoutingTestsText.Contains("vision_analyze"))
Write-Check "image routing refuses known text-only models even when native is requested" ($imageRoutingSource.Contains("known text-only") -and $imageRoutingSource.Contains("falling back to text image routing"))
Write-Check "run_agent honors image_input_mode without forcing known text-only models" ($runAgentSource.Contains("forced_image_mode") -and $runAgentSource.Contains('forced_image_mode == "text"') -and $runAgentSource.Contains('return forced_image_mode == "native"'))
Write-Check "forced native image mode regression tests exist" ($visionAwareTestsText.Contains("test_forced_native_image_mode_overrides_unknown_capability_metadata") -and $visionAwareTestsText.Contains("test_known_text_only_model_is_not_forced_to_native") -and $visionAwareTestsText.Contains("test_vision_capable_model_keeps_image_parts_with_native_mode"))
Write-Check "vision provider base_url keeps provider credential resolution" ($auxiliaryClientSource.Contains('not in {"auto", "custom"}') -and $visionResolvedArgsTestsText.Contains("test_task_provider_model_keeps_provider_with_base_url"))

Write-Host ""
Write-Host "3. Failure handling"
$downloadNoticeMatches = [regex]::Matches($feishuSource, "if\s+download_notices\s*:")
Write-Check "download failure notice is appended once" ($downloadNoticeMatches.Count -eq 1) "count=$($downloadNoticeMatches.Count)"
Write-Check "image download failure is visible to user" ($feishuSource.Contains("图片下载失败") -and $feishuSource.Contains("权限不足"))
Write-Check "file download failure is visible to user" ($feishuSource.Contains("文件下载失败") -and $feishuSource.Contains("文件过大"))
Write-Check "download failure duplicate regression tests exist" ($feishuTestsText.Contains('text.count("图片下载失败")') -and $feishuTestsText.Contains('text.count("文件下载失败")'))

Write-Host ""
Write-Host "4. Display compatibility gates"
Write-Check "Feishu post converts Markdown to native elements" ($feishuSource.Contains("_build_markdown_post_rows") -and $feishuSource.Contains("_parse_inline_markdown_post_elements"))
Write-Check "Feishu post update payload shape is guarded" ($feishuSource.Contains('"title": ""') -and $feishuSource.Contains('text if text else " "') -and $feishuTestsText.Contains("test_build_post_payload_never_emits_empty_text_elements"))
Write-Check "raw Markdown fallback strips formatting" ($feishuSource.Contains("_strip_markdown_to_plain_text"))
Write-Check "tool progress title exists" ($runSource.Contains("工具调用记录"))
Write-Check "tool progress realtime count exists" ($runSource.Contains("_progress_tool_call_count") -and $runSource.Contains("工具调用记录（"))
Write-Check "tool progress count regression test exists" ($runProgressTestsText.Contains('工具调用记录（1次）') -and $runProgressTestsText.Contains('工具调用记录（2次）'))

Write-Host ""
Write-Host "5. Lifecycle and config"
Write-Check "Windows gateway restart lifecycle notice exists" ($gatewayWindowsSource.Contains("网关正在重启") -and $gatewayWindowsSource.Contains("网关已上线"))
Write-Check "model config keeps a provider and default model" ($configSource.Contains("model:") -and $configSource.Contains("provider:") -and $configSource.Contains("default:"))
Write-Check "auxiliary vision config exists or native image routing is available" ($configSource.Contains("vision:") -or $imageRoutingSource.Contains("build_native_content_parts"))
Write-Check "Feishu home channel configured" ($configSource.Contains("home_channel:") -and $configSource.Contains("platform: feishu"))
Write-Check "Feishu status card runtime footer disabled" ($configSource.Contains("runtime_footer:") -and $configSource.Contains("enabled: false"))
Write-Check "Feishu outbound audit hook enabled locally" ($feishuSource.Contains("_audit_outbound_message") -and $configSource.Contains("outbound_audit: true"))
Write-Check "cross-platform continuity is not claimed by this package" ($manifestText.Contains('"cross-platform continuity"') -and $manifestText.Contains('"TUI to Feishu handoff"') -and -not $manifestText.Contains('"CLI to Feishu continuity"'))

Write-Host ""
Write-Host "6. Existing test markers"
Write-Check "Windows MEDIA path extraction test exists" ($baseTestsText.Contains("windows") -and $baseTestsText.Contains("MEDIA:E"))
Write-Check "send_message Windows MEDIA attachment test exists" ($sendMessageTestsText.Contains("test_windows_media_path_is_sent_as_attachment_not_text"))
Write-Check "busy queue media preservation test exists" ($busyTestsText.Contains("queued.media_urls") -or $busyTestsText.Contains("media_urls"))

Write-Host ""
Write-Host "7. Independent behavior fixtures"
Test-CommandSuccess -Name "fixed Feishu behavior fixtures pass" -FilePath "uv" -Arguments @("run", "python", $AcceptanceHarness) -WorkingDirectory $AgentRoot | Out-Null

if (-not $SkipGatewayStatus) {
    Write-Host ""
    Write-Host "8. Current gateway status"
    $GatewayProcesses = @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "hermes_cli.main gateway run" -and $_.Name -match "pythonw" })
    $GatewayIds = @($GatewayProcesses | ForEach-Object { $_.ProcessId })
    $GatewayRootCount = @($GatewayProcesses | Where-Object { -not ($GatewayIds -contains $_.ParentProcessId) }).Count
    Write-Check "current machine has one gateway process tree" ($GatewayRootCount -le 1) "roots=$GatewayRootCount processes=$($GatewayProcesses.Count)"
    $HermesExe = Join-Path $AgentRoot "venv\Scripts\hermes.exe"
    if (Test-Path -LiteralPath $HermesExe) {
        $statusOk = Test-CommandSuccess -Name "hermes gateway status succeeds" -FilePath $HermesExe -Arguments @("gateway", "status") -WorkingDirectory $AgentRoot
        if (Test-Path -LiteralPath $GatewayLog) {
            $tail = Get-Content -LiteralPath $GatewayLog -Tail 500 -Encoding UTF8
            $connected = ($tail -join "`n").Contains("✓ feishu connected") -or ($tail -join "`n").Contains("[Feishu] Connected")
            Write-Check "recent gateway log shows Feishu connected" $connected
        } else {
            Write-WarnCheck "gateway log not found" $GatewayLog
        }
    } else {
        Write-WarnCheck "hermes.exe not found; gateway status skipped" $HermesExe
    }
}

if ($Full) {
    Write-Host ""
    Write-Host "9. Full pytest audit"
    $env:HERMES_HOME = $HermesHome
    $pytestArgs = @(
        "run", "python", "-m", "pytest", "-q", "-n0", "--timeout-method=thread",
        "tests\gateway\test_feishu.py",
        "tests\gateway\test_feishu_outbound_audit.py",
        "tests\gateway\test_feishu_zh_progress.py",
        "tests\gateway\test_run_progress_topics.py::test_feishu_keeps_one_progress_bubble_across_interim_messages",
        "tests\gateway\test_run_progress_topics.py::test_feishu_zh_progress_appends_failed_tool_line",
        "tests\agent\test_vision_resolved_args.py",
        "tests\agent\test_image_routing.py",
        "tests\gateway\test_native_image_buffer_isolation.py",
        "tests\run_agent\test_vision_aware_preprocessing.py"
    )
    Test-CommandSuccess -Name "full Feishu optimization pytest audit" -FilePath "uv" -Arguments $pytestArgs -WorkingDirectory $AgentRoot | Out-Null
}

Write-Host ""
Write-Host "SUMMARY"
Write-Host "  Passed: $totalPass"
Write-Host "  Failed: $totalFail"
Write-Host "  Warnings: $totalWarn"

if ($totalFail -gt 0) { exit 1 }
