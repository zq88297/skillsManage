<#
.SYNOPSIS
    One-liner skill installer for Claude Code (Windows).

.DESCRIPTION
    Downloads and installs skills from the central repository.
    Supports project-level and global installation.

.EXAMPLE
    # Install globally (all projects) — default
    irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex; Install-Skills

.EXAMPLE
    # Install to current project only
    irm ... | iex; Install-Skills -Scope project

.EXAMPLE
    # Install specific skills globally
    irm ... | iex; Install-Skills -Skills "gsap-core,gsap-timeline"

.EXAMPLE
    # Install to specific project
    irm ... | iex; Install-Skills -Scope project -TargetPath "F:\MyProject"
#>
function Install-Skills {
    param(
        [ValidateSet("project", "global")]
        [string]$Scope = "global",
        [string]$TargetPath = "",
        [string[]]$Skills = @()
    )

    $RepoUrl = "https://github.com/zq88297/skillsManage.git"
    $Branch = "master"
    $GlobalDir = Join-Path $env:USERPROFILE ".claude\skills"

    # Determine target path
    if ($Scope -eq "global") {
        $TargetPath = $GlobalDir
    } elseif ([string]::IsNullOrEmpty($TargetPath)) {
        $TargetPath = (Get-Location).Path
    }

    Write-Host "=== Claude Code Skills Installer ===" -ForegroundColor Cyan
    Write-Host "Scope:  $Scope" -ForegroundColor Yellow
    Write-Host "Target: $TargetPath" -ForegroundColor Yellow
    Write-Host ""

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

        if ($Scope -eq "global") {
            # Global: install to temp, then copy skills to global dir
            $globalArgs = @{ TargetPath = $tmpDir }
            if ($Skills.Count -gt 0) {
                $globalArgs['Skills'] = $Skills
            }
            & $installScript @globalArgs
            $installedSkills = Join-Path $tmpDir ".claude\skills"
            if (Test-Path $installedSkills) {
                New-Item -ItemType Directory -Force -Path $GlobalDir | Out-Null
                Copy-Item -Recurse -Force "$installedSkills\*" $GlobalDir
            }
        } else {
            # Project: install directly to target
            $installArgs = @{ TargetPath = $TargetPath }
            if ($Skills.Count -gt 0) {
                $installArgs['Skills'] = $Skills
            }
            & $installScript @installArgs
        }

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

# Show usage when loaded
if ($MyInvocation.InvocationName -ne '&') {
    Write-Host "Skills installer loaded. Usage:" -ForegroundColor Cyan
    Write-Host "  Install-Skills                                    # Install globally (default)" -ForegroundColor White
    Write-Host "  Install-Skills -Scope project                     # Install to current project" -ForegroundColor White
    Write-Host "  Install-Skills -Skills 'gsap-core,gsap-timeline'  # Install specific skills" -ForegroundColor White
    Write-Host ""
}
