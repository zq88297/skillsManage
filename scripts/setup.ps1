<#
.SYNOPSIS
    One-liner skill installer for Claude Code (Windows).

.DESCRIPTION
    Downloads and installs skills from the central repository.
    Run from any project directory.

.EXAMPLE
    # Install all skills to current directory
    irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex

    # Then call the function
    Install-Skills

.EXAMPLE
    # Install to specific path with selected skills
    Install-Skills -TargetPath "F:\MyProject" -Skills "gsap-core,gsap-timeline"

.EXAMPLE
    # One-liner from any project
    Install-Skills -TargetPath "F:\MyProject"
#>
function Install-Skills {
    param(
        [string]$TargetPath = (Get-Location).Path,
        [string[]]$Skills = @()
    )

    $RepoUrl = "https://github.com/zq88297/skillsManage.git"
    $Branch = "master"

    Write-Host "=== Claude Code Skills Installer ===" -ForegroundColor Cyan
    Write-Host ""

    # Validate target
    if (-not (Test-Path $TargetPath)) {
        Write-Error "Target path does not exist: $TargetPath"
        return
    }
    $TargetPath = (Resolve-Path $TargetPath).Path

    # Check git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required but not installed."
        return
    }

    # Clone to temp directory
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-$(Get-Random)"
    try {
        Write-Host "Cloning skills repository..." -ForegroundColor Yellow
        $env:GIT_TERMINAL_PROMPT = 0
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        git clone --depth 1 --branch $Branch $RepoUrl $tmpDir 2>&1 | Out-Null
        $ErrorActionPreference = $prevEAP

        $installScript = Join-Path $tmpDir "scripts\install.ps1"
        if (-not (Test-Path $installScript)) {
            Write-Error "install.ps1 not found in repository"
            return
        }

        # Build arguments
        $installArgs = @{
            TargetPath = $TargetPath
        }
        if ($Skills.Count -gt 0) {
            $installArgs['Skills'] = $Skills
        }

        # Run installer
        & $installScript @installArgs

        Write-Host ""
        Write-Host "Done! Restart Claude Code to load the new skills." -ForegroundColor Green
    }
    finally {
        # Cleanup temp directory
        if (Test-Path $tmpDir) {
            Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        }
    }
}

# Auto-execute when invoked via irm | iex
# If not being piped, show usage
if ($MyInvocation.InvocationName -ne '&') {
    Write-Host "Skills installer loaded. Run:" -ForegroundColor Cyan
    Write-Host "  Install-Skills" -ForegroundColor White
    Write-Host "  Install-Skills -TargetPath 'F:\MyProject'" -ForegroundColor White
    Write-Host "  Install-Skills -TargetPath 'F:\MyProject' -Skills 'gsap-core,gsap-timeline'" -ForegroundColor White
    Write-Host ""
}
