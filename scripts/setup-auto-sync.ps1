<#
.SYNOPSIS
    Register a scheduled task to automatically update local skills from this repository.

.DESCRIPTION
    Creates a Windows Scheduled Task that runs sync-from-source.ps1 on a
    schedule (daily by default). The sync is one-way: repository -> local
    installed skills. It does not commit or push.

.PARAMETER Schedule
    One of: Daily, Weekly, Hourly. Default: Daily at 9:57 AM.

.PARAMETER Uninstall
    Remove the scheduled task.

.EXAMPLE
    .\setup-auto-sync.ps1
    Set up daily automatic sync from the repo to the local skills directory.

.EXAMPLE
    .\setup-auto-sync.ps1 -Schedule Hourly
    Check for repository updates every hour.

.EXAMPLE
    .\setup-auto-sync.ps1 -Uninstall
    Remove the scheduled task.
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Hourly")]
    [string]$Schedule = "Daily",

    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$TaskName = "ClaudeSkillsSync"

if ($Uninstall) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Removed scheduled task: $TaskName" -ForegroundColor Green
    }
    catch {
        Write-Host "Task '$TaskName' not found (already removed)."
    }
    exit 0
}

# Build the script path and arguments
$syncScript = Join-Path $RepoRoot "scripts\sync-from-source.ps1"
$powershellPath = "powershell.exe"
$arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location '$RepoRoot'; & '$syncScript' -Force`""

# Determine schedule trigger
$trigger = switch ($Schedule) {
    "Hourly" {
        New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    }
    "Daily" {
        New-ScheduledTaskTrigger -Daily -At "09:57"
    }
    "Weekly" {
        New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:57"
    }
}

$action = New-ScheduledTaskAction -Execute $powershellPath -Argument $arguments
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -MultipleInstances IgnoreNew

try {
    # Remove existing task if present
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Auto-sync local skills from the skills-manage repository."

    Write-Host "=== Auto-Sync Scheduled ===" -ForegroundColor Cyan
    Write-Host "Task name:  $TaskName"
    Write-Host "Schedule:   $Schedule"
    Write-Host ""
    Write-Host "The task will run sync-from-source.ps1 on schedule."
    Write-Host "Check Task Scheduler (taskschd.msc) to view or modify."
}
catch {
    Write-Error "Failed to register scheduled task: $_"
    Write-Host ""
    Write-Host "Manual alternative — add this to your PowerShell profile:"
    Write-Host ""
    Write-Host "  # Auto-check skills once per session"
    Write-Host "  `$repo = 'F:\AICode\skillsManage'"
    Write-Host "  if (Test-Path `$repo) {"
    Write-Host "      & `$repo\scripts\sync-from-source.ps1 -Force"
    Write-Host "  }"
}
