<#
.SYNOPSIS
    Install managed skills from this repository to a target project.

.DESCRIPTION
    Copies skills from the canonical skills/ directory into the target
    project's .claude/skills/ directory. Resolves transitive dependencies
    from skill-catalog.yaml. Creates backups of existing files unless -Force.

.PARAMETER TargetPath
    Path to the target project root (where .claude/ directory lives or will be created).

.PARAMETER Skills
    Specific skills to install (comma-separated). Default: all skills in catalog.

.PARAMETER WithHooks
    Also install hooks from shared/hooks/ into the target's .claude/hooks/.

.PARAMETER Force
    Skip backup of existing files.

.EXAMPLE
    .\install.ps1 -TargetPath F:\MyProject
    Installs all skills to F:\MyProject\.claude\skills\

.EXAMPLE
    .\install.ps1 -TargetPath F:\MyProject -Skills session-context,project-workflow -WithHooks
    Installs session-context and project-workflow (with resolved dependencies) plus hooks.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [Parameter(Mandatory = $false)]
    [string[]]$Skills = @(),

    [Parameter(Mandatory = $false)]
    [switch]$WithHooks,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$SkillSourceDir = Join-Path $RepoRoot "skills"
$CatalogFile = Join-Path $RepoRoot "skill-catalog.yaml"
$SharedDir = Join-Path $RepoRoot "shared"

# Validate target exists
if (-not (Test-Path $TargetPath)) {
    Write-Error "Target path does not exist: $TargetPath"
    exit 1
}
$TargetPath = (Resolve-Path $TargetPath).Path

# Validate catalog exists
if (-not (Test-Path $CatalogFile)) {
    Write-Error "Catalog file not found: $CatalogFile"
    exit 1
}

Write-Host "=== Skills Installer ===" -ForegroundColor Cyan
Write-Host "Repository: $RepoRoot"
Write-Host "Target:      $TargetPath"
Write-Host ""

# --- Hardcoded dependency map (source of truth: skill-catalog.yaml) ---
$Script:DependencyMap = @{
    'session-context'    = @()
    'project-workflow'   = @('session-context')
    'task-orchestrator'  = @('session-context')
}

$Script:SkillVersions = @{
    'session-context'    = '2.1.0'
    'project-workflow'   = '1.3.0'
    'task-orchestrator'  = '1.1.0'
}

$Script:InstallOrder = @('session-context', 'project-workflow', 'task-orchestrator')

# --- Resolve dependency closure ---
function Resolve-Dependencies {
    param([string[]]$requested)

    $allSkills = $Script:InstallOrder
    $selected = if ($requested.Count -eq 0) { $allSkills } else { $requested }

    # Validate requested skills
    foreach ($s in $selected) {
        if ($s -notin $Script:DependencyMap.Keys) {
            Write-Warning "Unknown skill '$s' - skipping"
        }
    }
    $selected = $selected | Where-Object { $_ -in $Script:DependencyMap.Keys }

    # BFS to resolve transitive closure
    $resolved = [System.Collections.ArrayList]@()
    $queue = [System.Collections.ArrayList]@($selected)
    while ($queue.Count -gt 0) {
        $name = $queue[0]
        $queue.RemoveAt(0)
        if ($name -notin $resolved) {
            $resolved.Add($name) | Out-Null
            $deps = $Script:DependencyMap[$name]
            foreach ($dep in $deps) {
                if ($dep -notin $resolved) {
                    $queue.Add($dep) | Out-Null
                }
            }
        }
    }

    # Topological sort: foundation first, then dependents
    $sorted = $resolved | Sort-Object {
        for ($i = 0; $i -lt $Script:InstallOrder.Count; $i++) {
            if ($_ -eq $Script:InstallOrder[$i]) { return $i }
        }
        return 99
    }
    return $sorted
}

function Get-SkillVersion {
    param([string]$skillName)
    if ($Script:SkillVersions.ContainsKey($skillName)) {
        return $Script:SkillVersions[$skillName]
    }
    return "unknown"
}

# --- Main installation ---
$toInstall = Resolve-Dependencies -requested $Skills

Write-Host "Skills to install (dependency order):" -ForegroundColor Yellow
foreach ($s in $toInstall) {
    $ver = Get-SkillVersion -skillName $s
    Write-Host "  $s v$ver"
}
Write-Host ""

$skillTargetDir = Join-Path $TargetPath ".claude\skills"
$backupDir = Join-Path $skillTargetDir ".backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$installedCount = 0
$commandCount = 0

foreach ($skillName in $toInstall) {
    $srcDir = Join-Path $SkillSourceDir $skillName
    $dstDir = Join-Path $skillTargetDir $skillName

    if (-not (Test-Path $srcDir)) {
        Write-Warning "Skill source directory not found: $srcDir - skipping"
        continue
    }

    # Backup existing skill if present
    if ((Test-Path $dstDir) -and (-not $Force)) {
        $skillBackupDir = Join-Path $backupDir $skillName
        New-Item -ItemType Directory -Force -Path $skillBackupDir | Out-Null
        Copy-Item -Recurse -Force "$dstDir\*" $skillBackupDir
        Write-Host "  Backed up: $skillName -> .backup\" -ForegroundColor DarkGray
    }

    # Create target and copy
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item -Recurse -Force "$srcDir\*" $dstDir

    $fileCount = (Get-ChildItem -Recurse -File $dstDir).Count
    Write-Host "  Installed: $skillName ($fileCount files)" -ForegroundColor Green
    $installedCount++
    $commandCount += (Get-ChildItem -Path (Join-Path $dstDir "commands") -File -ErrorAction SilentlyContinue).Count
}

# Install hooks if requested
if ($WithHooks) {
    $hooksSrc = Join-Path $SharedDir "hooks"
    $hooksDst = Join-Path $TargetPath ".claude\hooks"

    if (Test-Path $hooksSrc) {
        New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null

        # hooks.json
        $hooksJsonSrc = Join-Path $hooksSrc "hooks.json"
        $hooksJsonDst = Join-Path $TargetPath ".claude\hooks.json"
        if (Test-Path $hooksJsonSrc) {
            if ((Test-Path $hooksJsonDst) -and (-not $Force)) {
                Copy-Item -Force $hooksJsonDst (Join-Path $backupDir "hooks.json")
            }
            Copy-Item -Force $hooksJsonSrc $hooksJsonDst
            Write-Host "  Installed: hooks.json" -ForegroundColor Green
        }

        # Shell scripts
        Get-ChildItem -Path $hooksSrc -Filter "*.sh" | ForEach-Object {
            $dst = Join-Path $hooksDst $_.Name
            if ((Test-Path $dst) -and (-not $Force)) {
                Copy-Item -Force $dst (Join-Path $backupDir $_.Name)
            }
            Copy-Item -Force $_.FullName $dst
            Write-Host "  Installed: hooks/$($_.Name)" -ForegroundColor Green
        }

        # Make shell scripts executable on Unix
        if ($IsLinux -or $IsMacOS) {
            Get-ChildItem -Path $hooksDst -Filter "*.sh" | ForEach-Object {
                chmod +x $_.FullName
            }
        }
    }
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "$installedCount skills, ~$commandCount commands installed to $skillTargetDir"
if ($WithHooks) {
    Write-Host "Hooks installed to $($TargetPath)\.claude\hooks\"
}
if (-not $Force -and (Test-Path $backupDir)) {
    Write-Host "Backup created at: $backupDir" -ForegroundColor DarkGray
}
