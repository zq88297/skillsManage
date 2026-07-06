<#
.SYNOPSIS
    Register a scheduled task to automatically sync skills from the live
    Claude Code installation into this repository.

.DESCRIPTION
    Creates a Windows Scheduled Task that runs sync-from-source.ps1 on a
    schedule (daily by default). When changes are detected, they are
    auto-committed and pushed to the remote.

    Also can set up a Git post-commit hook to auto-push after each sync.

.PARAMETER Schedule
    One of: Daily, Weekly, Hourly. Default: Daily at 9:57 AM.

.PARAMETER AutoPush
    If set, the sync will also auto-push to the remote after committing.

.PARAMETER Uninstall
    Remove the scheduled task.

.EXAMPLE
    .\setup-auto-sync.ps1
    Set up daily automatic sync from ~/.claude/skills/ to the repo.

.EXAMPLE
    .\setup-auto-sync.ps1 -Schedule Hourly -AutoPush
    Check for changes every hour and push to remote.

.EXAMPLE
    .\setup-auto-sync.ps1 -Uninstall
    Remove the scheduled task.
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Hourly")]
    [string]$Schedule = "Daily",

    [Parameter(Mandatory = $false)]
    [switch]$AutoPush,

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

if ($AutoPush) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location '$RepoRoot'; & '$syncScript' -AutoCommit -Force; git push origin master`""
}
else {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location '$RepoRoot'; & '$syncScript' -AutoCommit -Force`""
}

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
        -Description "Auto-sync Claude Code skills from ~/.claude/skills/ to the skills-manage repository."

    Write-Host "=== Auto-Sync Scheduled ===" -ForegroundColor Cyan
    Write-Host "Task name:  $TaskName"
    Write-Host "Schedule:   $Schedule"
    Write-Host "Auto-push:  $AutoPush"
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
    Write-Host "      & `$repo\scripts\sync-from-source.ps1 -AutoCommit -Force"
    Write-Host "  }"
}
