# scripts/install-rtk.ps1
$ErrorActionPreference = "Stop"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "    Installing RTK (Rust Token Killer) for Claude      " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$claudeDir = Join-Path $userProfile ".claude"
$binDir = Join-Path $claudeDir "bin"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
}

$rtkExe = Join-Path $binDir "rtk.exe"

try {
    Write-Host "`n[1/3] Querying latest RTK release from GitHub..." -ForegroundColor Yellow
    $headers = @{ "User-Agent" = "Antigravity-Claude-Installer" }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/rtk-ai/rtk/releases/latest" -Headers $headers
    $asset = $release.assets | Where-Object { $_.name -like "*x86_64-pc-windows-msvc.zip" } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find Windows x86_64 zip in latest RTK release."
    }

    $zipUrl = $asset.browser_download_url
    $tempZip = Join-Path $env:TEMP "rtk-latest.zip"

    Write-Host "  -> Downloading: $($asset.name)..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing

    Write-Host "`n[2/3] Extracting rtk.exe to $binDir..." -ForegroundColor Yellow
    Expand-Archive -Path $tempZip -DestinationPath $binDir -Force
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

    $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($userPath -notlike "*$binDir*") {
        $newUserPath = "$userPath;$binDir"
        [System.Environment]::SetEnvironmentVariable('PATH', $newUserPath, 'User')
        Write-Host "  -> Added $binDir to User PATH." -ForegroundColor Green
    }
    if ($env:PATH -notlike "*$binDir*") {
        $env:PATH = "$env:PATH;$binDir"
    }

    Write-Host "`n[3/3] Initializing RTK hooks for Claude Code..." -ForegroundColor Yellow
    if (Test-Path $rtkExe) {
        & $rtkExe init -g
        
        # Automatically configure ~/.claude/settings.json if present
        $claudeSettings = Join-Path $claudeDir "settings.json"
        if (Test-Path $claudeSettings) {
            try {
                $cCfg = Get-Content $claudeSettings -Raw | ConvertFrom-Json
                $hookObj = [pscustomobject]@{
                    matcher = "Bash"
                    hooks = @([pscustomobject]@{ type = "command"; command = "rtk hook claude" })
                }
                if ($cCfg.hooks) {
                    $cCfg.hooks.PreToolUse = @($hookObj)
                } else {
                    $cCfg | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{ PreToolUse = @($hookObj) }) -Force
                }
                $cCfg | ConvertTo-Json -Depth 10 | Set-Content $claudeSettings -Encoding UTF8
                Write-Host "  -> Automatically patched Claude settings.json with RTK hook." -ForegroundColor Green
            } catch {
                Write-Host "  -> Note: Add RTK hook to $claudeSettings manually." -ForegroundColor Gray
            }
        }

        Write-Host "  -> RTK initialized successfully!" -ForegroundColor Green
        Write-Host "`n[SUCCESS] RTK is active! Command outputs will now be compressed to save tokens." -ForegroundColor Green
    } else {
        throw "rtk.exe not found after extraction."
    }
} catch {
    Write-Host "`n[NOTICE] Automatic binary download encountered: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Fallback: If you have Cargo installed, run: cargo install --git https://github.com/rtk-ai/rtk" -ForegroundColor Yellow
}
