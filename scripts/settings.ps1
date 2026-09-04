# scripts/settings.ps1
# Interactive Settings Manager for Antigravity-Claude Suite

$ErrorActionPreference = "Continue"

$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$claudeDir = Join-Path $userProfile ".claude"
$skillsDir = Join-Path $claudeDir "skills"
$disabledDir = Join-Path $claudeDir "skills-disabled"
$catalogDir = Join-Path $claudeDir "skills-catalog"
$binDir = Join-Path $claudeDir "bin"
$configFile = Join-Path $claudeDir "antigravity.json"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoDir = Split-Path -Parent $scriptDir

if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null }
if (-not (Test-Path $disabledDir)) { New-Item -ItemType Directory -Force -Path $disabledDir | Out-Null }
if (-not (Test-Path $catalogDir)) { New-Item -ItemType Directory -Force -Path $catalogDir | Out-Null }
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Force -Path $binDir | Out-Null }

$allSkillNames = @(
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

function Load-Config {
    if (Test-Path $configFile) {
        try {
            return Get-Content $configFile -Raw | ConvertFrom-Json
        } catch {}
    }
    $cfg = [ordered]@{
        prompt_caching_1h = $true
        rtk_proxy = $true
        graphify = $false
        skills = [ordered]@{}
    }
    foreach ($s in $allSkillNames) {
        $cfg.skills[$s] = $true
    }
    return [pscustomobject]$cfg
}

function Save-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 5 | Set-Content $configFile -Encoding UTF8
}

function Sync-SkillsToConfig($cfg) {
    foreach ($s in $allSkillNames) {
        $enabledPath = Join-Path $skillsDir $s
        $disabledPath = Join-Path $disabledDir $s
        $catalogPath = Join-Path $catalogDir $s
        $repoPath = Join-Path (Join-Path $repoDir "skills") $s

        $isEnabled = $true
        if ($cfg.skills -and ($cfg.skills.PSObject.Properties[$s])) {
            $isEnabled = [bool]$cfg.skills.$s
        }

        if ($isEnabled) {
            if (-not (Test-Path $enabledPath)) {
                if (Test-Path $disabledPath) {
                    Move-Item -Path $disabledPath -Destination $enabledPath -Force
                } elseif (Test-Path $catalogPath) {
                    Copy-Item -Path $catalogPath -Destination $enabledPath -Recurse -Force
                } elseif (Test-Path $repoPath) {
                    Copy-Item -Path $repoPath -Destination $enabledPath -Recurse -Force
                }
            }
        } else {
            if (Test-Path $enabledPath) {
                Move-Item -Path $enabledPath -Destination $disabledPath -Force
            }
        }
    }
}

function Toggle-Skill($name, $cfg) {
    $current = $true
    if ($cfg.skills -and ($cfg.skills.PSObject.Properties[$name])) {
        $current = [bool]$cfg.skills.$name
    }
    $cfg.skills.$name = (-not $current)
    Sync-SkillsToConfig $cfg
    Save-Config $cfg
}

function Toggle-Caching($cfg) {
    $current = [bool]$cfg.prompt_caching_1h
    $newVal = -not $current
    $cfg.prompt_caching_1h = $newVal
    if ($newVal) {
        [System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', '1', 'User')
        $env:ENABLE_PROMPT_CACHING_1H = '1'
    } else {
        [System.Environment]::SetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', $null, 'User')
        $env:ENABLE_PROMPT_CACHING_1H = $null
    }
    Save-Config $cfg
}

function Toggle-RTK($cfg) {
    $rtkCmd = Get-Command rtk -ErrorAction SilentlyContinue
    $rtkLocal = Join-Path $binDir "rtk.exe"

    if ((-not $rtkCmd) -and (-not (Test-Path $rtkLocal))) {
        Write-Host "`nRTK is not installed yet. Would you like to install it now? (y/N): " -ForegroundColor Yellow -NoNewline
        $ans = Read-Host
        if ($ans -eq 'y' -or $ans -eq 'Y') {
            $rtkInstaller = Join-Path $scriptDir "install-rtk.ps1"
            if (-not (Test-Path $rtkInstaller)) {
                $rtkInstaller = Join-Path (Join-Path $repoDir "scripts") "install-rtk.ps1"
            }
            if (Test-Path $rtkInstaller) {
                & $rtkInstaller
            } else {
                Write-Host "Could not locate install-rtk.ps1." -ForegroundColor Red
            }
            $cfg.rtk_proxy = $true
            Save-Config $cfg
            Start-Sleep -Seconds 2
        }
        return
    }

    $current = [bool]$cfg.rtk_proxy
    $cfg.rtk_proxy = (-not $current)
    
    # Toggle hook in settings.json
    $settingsJson = Join-Path $claudeDir "settings.json"
    if (Test-Path $settingsJson) {
        try {
            $cCfg = Get-Content $settingsJson -Raw | ConvertFrom-Json
            if ($cfg.rtk_proxy) {
                $hookObj = [pscustomobject]@{
                    matcher = "Bash"
                    hooks = @([pscustomobject]@{ type = "command"; command = "rtk hook claude" })
                }
                if ($cCfg.hooks) {
                    $cCfg.hooks.PreToolUse = @($hookObj)
                } else {
                    $cCfg | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{ PreToolUse = @($hookObj) }) -Force
                }
            } else {
                if ($cCfg.hooks) {
                    $cCfg.PSObject.Properties.Remove("hooks")
                }
            }
            $cCfg | ConvertTo-Json -Depth 10 | Set-Content $settingsJson -Encoding UTF8
        } catch {}
    }
    
    Save-Config $cfg
}

function Run-Diagnostics {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "                 ANTIGRAVITY SYSTEM DIAGNOSTICS                           " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    # Claude CLI
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        $cVer = (claude --version 2>&1) -join " "
        Write-Host "  [+] Claude Code CLI:       Found ($cVer)" -ForegroundColor Green
    } else {
        Write-Host "  [!] Claude Code CLI:       Not found in PATH (Install via: npm i -g @anthropic-ai/claude-code)" -ForegroundColor Yellow
    }

    # Prompt Caching
    $cacheVar = [System.Environment]::GetEnvironmentVariable('ENABLE_PROMPT_CACHING_1H', 'User')
    if ($cacheVar -eq '1') {
        Write-Host "  [+] 1-Hour Prompt Caching: ACTIVE (ENABLE_PROMPT_CACHING_1H=1)" -ForegroundColor Green
    } else {
        Write-Host "  [!] 1-Hour Prompt Caching: INACTIVE" -ForegroundColor DarkGray
    }

    # RTK
    $rtkCmd = Get-Command rtk -ErrorAction SilentlyContinue
    $rtkLocal = Join-Path $binDir "rtk.exe"
    if ($rtkCmd -or (Test-Path $rtkLocal)) {
        $rtkVer = (& (if ($rtkCmd) { "rtk" } else { $rtkLocal }) --version 2>&1) -join " "
        Write-Host "  [+] RTK Binary:            Installed ($rtkVer)" -ForegroundColor Green
    } else {
        Write-Host "  [!] RTK Binary:            Not installed" -ForegroundColor Yellow
    }

    # Hook in settings.json
    $settingsJson = Join-Path $claudeDir "settings.json"
    if (Test-Path $settingsJson) {
        $sContent = Get-Content $settingsJson -Raw
        if ($sContent -like "*rtk hook claude*") {
            Write-Host "  [+] Claude RTK Hook:       CONFIGURED in settings.json" -ForegroundColor Green
        } else {
            Write-Host "  [!] Claude RTK Hook:       Not registered in settings.json" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [!] Claude settings.json:  Not found" -ForegroundColor DarkGray
    }

    # CLAUDE.md
    $claudeMd = Join-Path $claudeDir "CLAUDE.md"
    if (Test-Path $claudeMd) {
        Write-Host "  [+] Global CLAUDE.md:      PRESENT (~/.claude/CLAUDE.md)" -ForegroundColor Green
    } else {
        Write-Host "  [!] Global CLAUDE.md:      MISSING" -ForegroundColor Red
    }

    # Skills count
    $activeCount = 0
    $disabledCount = 0
    foreach ($s in $allSkillNames) {
        if (Test-Path (Join-Path $skillsDir $s)) { $activeCount++ }
        if (Test-Path (Join-Path $disabledDir $s)) { $disabledCount++ }
    }
    Write-Host "  [+] Active Skills:         $activeCount of $($allSkillNames.Count) enabled" -ForegroundColor Green
    if ($disabledCount -gt 0) {
        Write-Host "  [!] Disabled Skills:       $disabledCount disabled" -ForegroundColor Yellow
    }

    # Global Command Check
    $agyCmd = Get-Command agy-settings -ErrorAction SilentlyContinue
    if ($agyCmd -or (Test-Path (Join-Path $binDir "agy-settings.bat"))) {
        Write-Host "  [+] Global agy-settings:   AVAILABLE ('agy-settings' in any terminal)" -ForegroundColor Green
    } else {
        Write-Host "  [!] Global agy-settings:   Not linked" -ForegroundColor Yellow
    }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "`nPress any key to return to settings..." -ForegroundColor Yellow
    $null = [System.Console]::ReadKey($true)
}

function Copy-CustomInstructions {
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
    try {
        Set-Clipboard -Value $instructions
        Write-Host "`n[COPIED] Custom Instructions copied to Windows Clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "`n[NOTE] Clipboard unavailable. Please copy instructions from README or CLAUDE.md." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

# Main Loop
$cfg = Load-Config
Sync-SkillsToConfig $cfg

while ($true) {
    Clear-Host
    $cachingActive = [bool]$cfg.prompt_caching_1h
    $rtkActive = [bool]$cfg.rtk_proxy
    $graphifyActive = [bool]$cfg.graphify

    $rtkInstalled = (Get-Command rtk -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $binDir "rtk.exe"))

    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "                 ANTIGRAVITY CONFIGURATION & SETTINGS                     " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  Customize token-saving flags, companion proxies, and active skills.      " -ForegroundColor DarkGray
    Write-Host "  (All changes take effect immediately across Claude sessions)            `n" -ForegroundColor DarkGray

    Write-Host " TOKEN OPTIMIZATIONS & COMPANIONS:" -ForegroundColor Yellow
    
    $cColor = if ($cachingActive) { "Green" } else { "DarkGray" }
    $cText  = if ($cachingActive) { "[ ENABLED  ]" } else { "[ DISABLED ]" }
    Write-Host "  [1] 1-Hour Prompt Caching           $cText  (ENABLE_PROMPT_CACHING_1H)" -ForegroundColor $cColor

    $rColor = if ($rtkActive -and $rtkInstalled) { "Green" } elseif ($rtkInstalled) { "DarkGray" } else { "Yellow" }
    $rText  = if (-not $rtkInstalled) { "[ NOT INSTALLED ]" } elseif ($rtkActive) { "[ ENABLED  ]" } else { "[ DISABLED ]" }
    Write-Host "  [2] RTK (Rust Token Killer)          $rText  (Compresses noisy CLI output)" -ForegroundColor $rColor

    $gColor = if ($graphifyActive) { "Green" } else { "DarkGray" }
    $gText  = if ($graphifyActive) { "[ ENABLED  ]" } else { "[ DISABLED ]" }
    Write-Host "  [3] Graphify AST Codebase Graph     $gText  (Knowledge graph mapper)" -ForegroundColor $gColor

    Write-Host "`n ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " BUNDLED SKILLS DIRECTORY:" -ForegroundColor Yellow

    $i = 4
    foreach ($s in $allSkillNames) {
        $skillOn = $true
        if ($cfg.skills -and ($cfg.skills.PSObject.Properties[$s])) {
            $skillOn = [bool]$cfg.skills.$s
        }
        $sColor = if ($skillOn) { "Green" } else { "DarkGray" }
        $sText  = if ($skillOn) { "[ ENABLED  ]" } else { "[ DISABLED ]" }
        $idxStr = if ($i -lt 10) { " [$i] " } else { "[$i] " }
        Write-Host "  $idxStr$($s.PadRight(30)) $sText" -ForegroundColor $sColor
        $i++
    }

    Write-Host "`n ------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " ACTIONS:" -ForegroundColor Yellow
    Write-Host "  [T] Run System Diagnostics" -ForegroundColor Green
    Write-Host "  [C] Copy Claude Desktop Instructions to Clipboard" -ForegroundColor Cyan
    Write-Host "  [U] Uninstall Antigravity Suite" -ForegroundColor Red
    Write-Host "  [0] Exit Settings" -ForegroundColor White
    Write-Host "==========================================================================" -ForegroundColor Cyan

    Write-Host -NoNewline "`nSelect an option to toggle (0-13, T, C, U): "
    $choice = Read-Host

    switch ($choice.ToUpper().Trim()) {
        "1" { Toggle-Caching $cfg }
        "2" { Toggle-RTK $cfg }
        "3" { 
            $cfg.graphify = (-not $cfg.graphify)
            Save-Config $cfg 
        }
        "4"  { Toggle-Skill "antigravity" $cfg }
        "5"  { Toggle-Skill "antigravity-planner" $cfg }
        "6"  { Toggle-Skill "frontend-design" $cfg }
        "7"  { Toggle-Skill "test-driven-development" $cfg }
        "8"  { Toggle-Skill "systematic-debugging" $cfg }
        "9"  { Toggle-Skill "verification-before-completion" $cfg }
        "10" { Toggle-Skill "web-artifacts-builder" $cfg }
        "11" { Toggle-Skill "xlsx" $cfg }
        "12" { Toggle-Skill "pdf" $cfg }
        "13" { Toggle-Skill "docx" $cfg }
        "T"  { Run-Diagnostics }
        "C"  { Copy-CustomInstructions }
        "U"  {
            $uninstaller = Join-Path $repoDir "uninstall.bat"
            if (-not (Test-Path $uninstaller)) {
                $uninstaller = Join-Path $binDir "uninstall.bat"
            }
            if (Test-Path $uninstaller) {
                & $uninstaller
            } else {
                Write-Host "Uninstaller script not found." -ForegroundColor Red
            }
            exit
        }
        "0"  { exit }
        default {
            Write-Host "Invalid option. Press any key..." -ForegroundColor Yellow
            $null = [System.Console]::ReadKey($true)
        }
    }
}
