<# :
@echo off
title Antigravity Protocol Suite for Claude (Setup)
cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content -Raw '%~f0')"
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
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$localSkills = Join-Path $scriptDir "skills"

# 1. Directories
Write-Host "`n[+] Deploying 10 skills to $skillsDir..." -ForegroundColor Yellow -NoNewline
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

if (Test-Path $localSkills) {
    Get-ChildItem -Path $localSkills -Directory | ForEach-Object {
        $target = Join-Path $skillsDir $_.Name
        Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
    }
}
Write-Host " [DONE]" -ForegroundColor Green

# 2. CLAUDE.md
Write-Host "[+] Configuring global CLAUDE.md..." -ForegroundColor Yellow -NoNewline
$claudeMdSource = Join-Path $scriptDir "CLAUDE.md"
$claudeMdDest = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMdSource) {
    Copy-Item -Path $claudeMdSource -Destination $claudeMdDest -Force
}
Write-Host "           [DONE]" -ForegroundColor Green

# 3. Prompt Caching
Write-Host "[+] Enabling 1-Hour Prompt Caching (ENABLE_PROMPT_CACHING_1H=1)..." -ForegroundColor Yellow -NoNewline
[System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', '1', 'User')
$env:ENABLE_PROMPT_CACHING_1H = '1'
Write-Host " [DONE]" -ForegroundColor Green

# 4. Default Config JSON
$configFile = Join-Path $claudeDir "antigravity.json"
$cfg = [ordered]@{
    prompt_caching_1h = $true
    rtk_proxy = $true
    graphify = $false
    skills = [ordered]@{
        "antigravity" = $true
        "antigravity-planner" = $true
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

# 5. Instructions Copy
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
- Use Markdown tables for comparisons or multi-attribute specs.
- Always use language identifiers on code blocks with file paths on line 1.
- Use targeted chunk edits rather than dumping entire files.
"@
Set-Clipboard -Value $instructions
Write-Host "[+] Copying Custom Instructions to Windows Clipboard..." -ForegroundColor Yellow -NoNewline
Write-Host "  [COPIED]" -ForegroundColor Green

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
Write-Host "                    3. SETTINGS & CUSTOMIZATION                           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  * All 10 skills and 1-hour prompt caching are ENABLED by default." -ForegroundColor Green
Write-Host "  * Want to toggle individual skills, disable caching, or install RTK?" -ForegroundColor Gray
Write-Host "  * Simply run 'settings.bat' anytime from this folder!" -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Cyan

Write-Host "`nPress [S] to open Settings now, or press Enter to finish: " -ForegroundColor Yellow -NoNewline
$opt = Read-Host
if ($opt -eq 's' -or $opt -eq 'S') {
    & "$scriptDir\scripts\settings.ps1"
} else {
    Write-Host "`nInstallation complete! Enjoy Antigravity for Claude.`n" -ForegroundColor Green
}
