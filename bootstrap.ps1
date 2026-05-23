<# 
.SYNOPSIS
    hermes-feishu-adapter-optimization 一键安装引导脚本
.DESCRIPTION
    从 GitHub 下载 hermes-feishu-adapter-optimization 并执行安装。
    用法：iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-adapter-optimization/main/bootstrap.ps1)
#>

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/OLDBAI213/hermes-feishu-adapter-optimization.git"
$TempDir = Join-Path $env:TEMP "hermes-feishu-adapter-optimization-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    Write-Host "📥 下载 hermes-feishu-adapter-optimization..." -ForegroundColor Cyan
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "需要安装 Git。请先安装 Git: https://git-scm.com/"
    }
    
    git clone --depth 1 $RepoUrl $TempDir 2>&1 | Out-Null
    
    if (-not (Test-Path (Join-Path $TempDir "install.ps1"))) {
        throw "下载失败：找不到 install.ps1"
    }
    
    Write-Host "🔧 开始安装..." -ForegroundColor Cyan
    
    $installScript = Join-Path $TempDir "install.ps1"
    & $installScript @args
    
} catch {
    Write-Host "❌ 安装失败: $_" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
