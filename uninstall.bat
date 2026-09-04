<# :
@echo off
title Uninstall Antigravity Suite
cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content -Raw '%~f0')"
pause
exit /b %ERRORLEVEL%
: #>

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "             UNINSTALL ANTIGRAVITY PROTOCOL SUITE                         " -ForegroundColor Red
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "`nThis will safely remove Antigravity skills, configuration, and prompt caching." -ForegroundColor Yellow
Write-Host "(Your personal custom skills outside this suite will NOT be touched)`n" -ForegroundColor Gray

Write-Host -NoNewline "Are you sure you want to proceed? (y/N): " -ForegroundColor Red
$confirm = Read-Host

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "`nUninstall cancelled." -ForegroundColor Green
    return
}

$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$claudeDir = Join-Path $userProfile ".claude"
$skillsDir = Join-Path $claudeDir "skills"
$disabledDir = Join-Path $claudeDir "skills-disabled"

$skillsToRemove = @(
    "antigravity",
    "antigravity-planner",
    "frontend-design",
    "test-driven-development",
    "systematic-debugging",
    "verification-before-completion",
    "web-artifacts-builder",
    "xlsx",
    "pdf",
    "docx"
)

Write-Host "`n[1/4] Removing Antigravity skills..." -ForegroundColor Cyan
foreach ($s in $skillsToRemove) {
    $p1 = Join-Path $skillsDir $s
    $p2 = Join-Path $disabledDir $s
    if (Test-Path $p1) { Remove-Item -Path $p1 -Recurse -Force; Write-Host "  -> Removed: $s" -ForegroundColor Gray }
    if (Test-Path $p2) { Remove-Item -Path $p2 -Recurse -Force; Write-Host "  -> Removed disabled: $s" -ForegroundColor Gray }
}

Write-Host "`n[2/4] Restoring / Cleaning CLAUDE.md..." -ForegroundColor Cyan
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) {
    $content = Get-Content $claudeMd -Raw
    if ($content -like "*ANTIGRAVITY OPERATING SYSTEM DIRECTIVE*") {
        Remove-Item $claudeMd -Force
        Write-Host "  -> Removed Antigravity CLAUDE.md." -ForegroundColor Green
    } else {
        Write-Host "  -> Custom CLAUDE.md detected; preserved." -ForegroundColor Yellow
    }
}

Write-Host "`n[3/4] Removing Prompt Caching Environment Variable..." -ForegroundColor Cyan
[System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', $null, 'User')
$env:ENABLE_PROMPT_CACHING_1H = $null
Write-Host "  -> Cleared ENABLE_PROMPT_CACHING_1H." -ForegroundColor Green

Write-Host "`n[4/4] Removing configuration files..." -ForegroundColor Cyan
$cfg = Join-Path $claudeDir "antigravity.json"
if (Test-Path $cfg) { Remove-Item $cfg -Force }

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Antigravity Suite has been cleanly uninstalled.                " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
