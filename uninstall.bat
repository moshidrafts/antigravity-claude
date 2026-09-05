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
$catalogDir = Join-Path $claudeDir "skills-catalog"
$binDir = Join-Path $claudeDir "bin"

$skillsToRemove = @(
    "antigravity",
    "antigravity-planner",
    "caveman",
    "graphify",
    "frontend-design",
    "test-driven-development",
    "systematic-debugging",
    "verification-before-completion",
    "web-artifacts-builder",
    "xlsx",
    "pdf",
    "docx"
)

Write-Host "`n[1/5] Removing Antigravity skills and catalog..." -ForegroundColor Cyan
foreach ($s in $skillsToRemove) {
    $p1 = Join-Path $skillsDir $s
    $p2 = Join-Path $disabledDir $s
    $p3 = Join-Path $catalogDir $s
    if (Test-Path $p1) { Remove-Item -Path $p1 -Recurse -Force; Write-Host "  -> Removed: $s" -ForegroundColor Gray }
    if (Test-Path $p2) { Remove-Item -Path $p2 -Recurse -Force; Write-Host "  -> Removed disabled: $s" -ForegroundColor Gray }
    if (Test-Path $p3) { Remove-Item -Path $p3 -Recurse -Force }
}
if (Test-Path $catalogDir) { Remove-Item -Path $catalogDir -Recurse -Force }

Write-Host "`n[2/5] Restoring CLAUDE.md..." -ForegroundColor Cyan
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
$claudeBak = Join-Path $claudeDir "CLAUDE.md.bak"

if (Test-Path $claudeBak) {
    Move-Item $claudeBak $claudeMd -Force
    Write-Host "  -> Restored original CLAUDE.md from backup." -ForegroundColor Green
} elseif (Test-Path $claudeMd) {
    $content = Get-Content $claudeMd -Raw
    if ($content -like "*ANTIGRAVITY OPERATING SYSTEM DIRECTIVE*") {
        Remove-Item $claudeMd -Force
        Write-Host "  -> Removed Antigravity CLAUDE.md." -ForegroundColor Green
    } else {
        Write-Host "  -> Custom CLAUDE.md preserved." -ForegroundColor Yellow
    }
}

Write-Host "`n[3/5] Cleaning up RTK hooks & files..." -ForegroundColor Cyan
$rtkMd = Join-Path $claudeDir "RTK.md"
if (Test-Path $rtkMd) { Remove-Item $rtkMd -Force }

$settingsJson = Join-Path $claudeDir "settings.json"
if (Test-Path $settingsJson) {
    try {
        $cCfg = Get-Content $settingsJson -Raw | ConvertFrom-Json
        if ($cCfg.hooks) {
            $cCfg.PSObject.Properties.Remove("hooks")
            $cCfg | ConvertTo-Json -Depth 10 | Set-Content $settingsJson -Encoding UTF8
            Write-Host "  -> Removed RTK hook from settings.json." -ForegroundColor Green
        }
    } catch {}
}

# Remove global command launchers & settings
$agyBat = Join-Path $binDir "agy-settings.bat"
$antigravityBat = Join-Path $binDir "antigravity-settings.bat"
$settingsPs1 = Join-Path $binDir "settings.ps1"
if (Test-Path $agyBat) { Remove-Item $agyBat -Force }
if (Test-Path $antigravityBat) { Remove-Item $antigravityBat -Force }
if (Test-Path $settingsPs1) { Remove-Item $settingsPs1 -Force }

Write-Host "`n[4/5] Removing Prompt Caching Environment Variable..." -ForegroundColor Cyan
[System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', $null, 'User')
$env:ENABLE_PROMPT_CACHING_1H = $null
Write-Host "  -> Cleared ENABLE_PROMPT_CACHING_1H." -ForegroundColor Green

Write-Host "`n[5/5] Removing configuration files..." -ForegroundColor Cyan
$cfg = Join-Path $claudeDir "antigravity.json"
if (Test-Path $cfg) { Remove-Item $cfg -Force }

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Antigravity Suite has been cleanly uninstalled.                " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
