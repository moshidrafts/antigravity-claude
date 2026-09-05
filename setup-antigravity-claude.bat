<# :
@echo off
title Antigravity Protocol Suite for Claude (Setup)
cls
set "ANTIGRAVITY_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$scriptDir = $env:ANTIGRAVITY_DIR.TrimEnd('\'); Invoke-Expression (Get-Content -Raw '%~f0')"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Setup encountered an unexpected error.
    pause
)
exit /b %ERRORLEVEL%
: #>

$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "               ANTIGRAVITY PROTOCOL SUITE FOR CLAUDE                      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$claudeDir = Join-Path $userProfile ".claude"
$skillsDir = Join-Path $claudeDir "skills"
$catalogDir = Join-Path $claudeDir "skills-catalog"
$binDir = Join-Path $claudeDir "bin"

if (-not $scriptDir) {
    if ($env:ANTIGRAVITY_DIR) {
        $scriptDir = $env:ANTIGRAVITY_DIR.TrimEnd('\')
    } elseif ($PSScriptRoot) {
        $scriptDir = $PSScriptRoot
    } else {
        $scriptDir = (Get-Location).Path
    }
}
$localSkills = Join-Path $scriptDir "skills"

# 1. Directories
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
New-Item -ItemType Directory -Force -Path $catalogDir | Out-Null
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

# 2. Deploy Skills & Catalog
Write-Host "`n[1/6] Deploying 12 skills to $skillsDir and $catalogDir..." -ForegroundColor Yellow -NoNewline
if (Test-Path $localSkills) {
    Get-ChildItem -Path $localSkills -Directory | ForEach-Object {
        $target = Join-Path $skillsDir $_.Name
        $catTarget = Join-Path $catalogDir $_.Name
        Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
        Copy-Item -Path $_.FullName -Destination $catTarget -Recurse -Force
    }
}
Write-Host " [DONE]" -ForegroundColor Green

# 3. Global CLAUDE.md Handling (Conflict Resolution: Overwrite / Append / Cancel)
Write-Host "[2/6] Configuring global CLAUDE.md..." -ForegroundColor Yellow
$claudeMdSource = Join-Path $scriptDir "CLAUDE.md"
$claudeMdDest = Join-Path $claudeDir "CLAUDE.md"

if (Test-Path $claudeMdDest) {
    $existingContent = Get-Content $claudeMdDest -Raw
    if ($existingContent -notlike "*ANTIGRAVITY OPERATING SYSTEM DIRECTIVE*") {
        Write-Host "`n  [!] An existing CLAUDE.md was detected at: $claudeMdDest" -ForegroundColor Magenta
        Write-Host "      How would you like to handle this?" -ForegroundColor Yellow
        Write-Host "      [O] Overwrite (recommended - backs up existing file to CLAUDE.md.bak)" -ForegroundColor White
        Write-Host "      [A] Append Antigravity Protocol to the end of existing file" -ForegroundColor White
        Write-Host "      [C] Cancel / Exit setup without modifying CLAUDE.md" -ForegroundColor White
        
        $mdChoice = ""
        while ($mdChoice -notmatch '^[OAC]$') {
            Write-Host -NoNewline "      Select an option (O/A/C): " -ForegroundColor Yellow
            $rawInput = Read-Host
            if ($rawInput -eq $null) {
                $mdChoice = 'O'
                break
            }
            $mdChoice = $rawInput.Trim().ToUpper()
        }
        
        if ($mdChoice -eq 'C') {
            Write-Host "`nSetup cancelled. No modifications were made to CLAUDE.md." -ForegroundColor Yellow
            exit 0
        } elseif ($mdChoice -eq 'A') {
            Copy-Item $claudeMdDest "$claudeMdDest.bak" -Force
            $sourceContent = Get-Content $claudeMdSource -Raw
            $merged = $existingContent + "`n`n" + $sourceContent
            [System.IO.File]::WriteAllText($claudeMdDest, $merged, [System.Text.Encoding]::UTF8)
            Write-Host "  -> Antigravity appended to existing CLAUDE.md (backup: CLAUDE.md.bak)" -ForegroundColor Green
        } elseif ($mdChoice -eq 'O') {
            Copy-Item $claudeMdDest "$claudeMdDest.bak" -Force
            Copy-Item $claudeMdSource $claudeMdDest -Force
            Write-Host "  -> CLAUDE.md overwritten (original backed up to CLAUDE.md.bak)" -ForegroundColor Green
        }
    } else {
        Copy-Item $claudeMdSource $claudeMdDest -Force
        Write-Host "  -> Updated existing Antigravity CLAUDE.md." -ForegroundColor Green
    }
} else {
    Copy-Item $claudeMdSource $claudeMdDest -Force
    Write-Host "  -> Global CLAUDE.md deployed successfully." -ForegroundColor Green
}

# 4. Prompt Caching
Write-Host "[3/6] Enabling 1-Hour Prompt Caching (ENABLE_PROMPT_CACHING_1H=1)..." -ForegroundColor Yellow -NoNewline
[System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', '1', 'User')
$env:ENABLE_PROMPT_CACHING_1H = '1'
Write-Host " [DONE]" -ForegroundColor Green

# 5. Global CLI Commands (agy-settings & antigravity-settings in PATH)
Write-Host "[4/6] Registering global 'agy-settings' command in PATH..." -ForegroundColor Yellow -NoNewline
$settingsPs1Source = Join-Path $scriptDir "scripts\settings.ps1"
$settingsPs1Dest = Join-Path $binDir "settings.ps1"
Copy-Item $settingsPs1Source $settingsPs1Dest -Force

$agyBatContent = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0settings.ps1`""
Set-Content -Path (Join-Path $binDir "agy-settings.bat") -Value $agyBatContent
Set-Content -Path (Join-Path $binDir "antigravity-settings.bat") -Value $agyBatContent

$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$binDir*") {
    $newUserPath = "$userPath;$binDir"
    [System.Environment]::SetEnvironmentVariable('PATH', $newUserPath, 'User')
}
if ($env:PATH -notlike "*$binDir*") {
    $env:PATH = "$env:PATH;$binDir"
}
Write-Host " [DONE]" -ForegroundColor Green

# 6. Default Config JSON
$configFile = Join-Path $claudeDir "antigravity.json"
if (-not (Test-Path $configFile)) {
    $cfg = [ordered]@{
        prompt_caching_1h = $true
        rtk_proxy = $true
        graphify = $true
        skills = [ordered]@{
            "antigravity" = $true
            "antigravity-planner" = $true
            "caveman" = $true
            "graphify" = $true
            "frontend-design" = $true
            "test-driven-development" = $true
            "systematic-debugging" = $true
            "verification-before-completion" = $true
            "web-artifacts-builder" = $true
            "xlsx" = $true
            "pdf" = $true
            "docx" = $true
        }
    }
    $cfg | ConvertTo-Json -Depth 5 | Set-Content $configFile -Encoding UTF8
}

# 7. Configure Marketplaces & Recommended Plugins (if Claude CLI is present)
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCmd) {
    Write-Host "[5/6] Registering Claude Marketplaces & Recommended Plugins..." -ForegroundColor Yellow
    try {
        & claude plugin marketplace add centminmod/claude-plugins 2>&1 | Out-Null
        & claude plugin marketplace add anthropics/claude-plugins-community 2>&1 | Out-Null
        $recommendedPlugins = @(
            "session-metrics@centminmod",
            "session-report@claude-plugins-official",
            "receipts@claude-plugins-official",
            "commit-commands@claude-plugins-official",
            "pr-review-toolkit@claude-plugins-official",
            "pyright-lsp@claude-plugins-official",
            "typescript-lsp@claude-plugins-official"
        )
        foreach ($p in $recommendedPlugins) {
            & claude plugin install $p 2>&1 | Out-Null
        }
        Write-Host "  -> Marketplaces and recommended plugins configured successfully." -ForegroundColor Green
    } catch {
        Write-Host "  -> Plugin configuration skipped." -ForegroundColor DarkGray
    }
}

# 8. Instructions Copy with Safety
$instructions = @"
# ANTIGRAVITY PROTOCOL & ARTIFACT DIRECTIVE

Act as an autonomous AI engineer under the Antigravity Protocol:

1. ZERO CONVERSATIONAL FLUFF:
- Omit pleasantries, conversational intros, and wrap-ups. Keep chat text strictly for 1-2 sentence status updates.

2. RIPPLE IMPACT & MANDATORY ARTIFACTS:
Never dump long plans, task checklists, or extensive code into chat. Always generate dedicated Artifacts in the side panel:
- Ripple Check: If a change touches another function/feature, first trace the full picture. Disclose: (1) What is currently there, (2) What intends to change, (3) Why.
- Phase 1 (Plan): Create an Artifact titled "Implementation Plan: [Feature]". Include file tags ([NEW], [MODIFY], [DELETE]) and verification steps.
- VISUAL DIAGRAMS: Never output Mermaid diagrams as raw code blocks in chat. Always trigger a dedicated Mermaid Artifact so the visual diagram renders interactively in the side pane.
- HALT FOR APPROVAL (NO CHAINING): After outputting the Phase 1 plan artifact, you must YIELD THE TURN IMMEDIATELY. Do not generate Phase 2/3 artifacts or write code until I explicitly say "proceed" or "approved".
- Phase 2 (Tasks): Create an Artifact titled "Task Checklist: [Feature]" with `- [ ]` and `- [x]` checkboxes.
- Phase 3 (Walkthrough): Create an Artifact titled "Walkthrough: [Feature]" with test verification results.

3. STYLING & FORMATTING STANDARDS:
- If an explanation exceeds 3 sentences, convert to bullet points, GFM alerts, or a table.
- Never use the section symbol '§' (silcrow). Use normal numbers (1, 2) or markdown headers.
- Use Markdown tables for comparisons or multi-attribute specs.
- Always use language identifiers on code blocks with file paths on line 1.
- Use targeted chunk edits rather than dumping entire files.
"@

try {
    Set-Clipboard -Value $instructions
    Write-Host "[6/6] Copying Custom Instructions to Windows Clipboard... [COPIED]" -ForegroundColor Green
} catch {
    Write-Host "[6/6] Copying Custom Instructions to Windows Clipboard... [MANUAL COPY]" -ForegroundColor Yellow
}

# -------------------------------------------------------------
# STEP 1: DISPLAY CUSTOM INSTRUCTIONS
# -------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "           1. CLAUDE DESKTOP CUSTOM INSTRUCTIONS (IN CLIPBOARD!)          " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host @"
+------------------------------------------------------------------------+
|                                                                        |
|  * ZERO CONVERSATIONAL FLUFF (Immediate engineering answers)           |
|  * MANDATORY ARTIFACTS (Plans, tasks, and walkthroughs in side panel)  |
|  * INTERACTIVE MERMAID DIAGRAMS (Rendered visually, not raw code)      |
|  * RIPPLE IMPACT DISCLOSURE (Blast radius check before code changes)   |
|  * HALT FOR APPROVAL GATE (Strict stop after planning)                 |
|  * TARGETED CHUNK DIFFS (Never dump entire files)                      |
|                                                                        |
+------------------------------------------------------------------------+
"@ -ForegroundColor Yellow

# -------------------------------------------------------------
# STEP 2: WHAT TO DO NEXT
# -------------------------------------------------------------
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                      2. WHAT TO DO NEXT                                  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  1. Open Claude Desktop (or Claude.ai web)." -ForegroundColor White
Write-Host "  2. Go to: Settings -> Custom Instructions." -ForegroundColor White
Write-Host "  3. Press Ctrl + V to paste the copied instructions." -ForegroundColor White
Write-Host "  4. Click Save." -ForegroundColor White
Write-Host "  5. Open your terminal, run 'claude', and start building!" -ForegroundColor White

# -------------------------------------------------------------
# STEP 3: SETTINGS & CUSTOMIZATION
# -------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                    3. SETTINGS & GLOBAL COMMAND                          " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  * All 12 skills and 1-hour prompt caching are ENABLED by default." -ForegroundColor Green
Write-Host "  * You can now run 'agy-settings' from ANY terminal on your computer!" -ForegroundColor Yellow
Write-Host "  * Or run 'settings.bat' right here in this folder." -ForegroundColor Gray
Write-Host "==========================================================================" -ForegroundColor Cyan

Write-Host "`nPress [S] to open Settings now, or press Enter to finish: " -ForegroundColor Yellow -NoNewline
$opt = Read-Host
if ($opt -eq 's' -or $opt -eq 'S') {
    & "$binDir\settings.ps1"
} else {
    Write-Host "`nInstallation complete! Enjoy Antigravity for Claude.`n" -ForegroundColor Green
}
