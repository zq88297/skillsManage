<#
.SYNOPSIS
    Install managed skills from this repository to a target project.

.DESCRIPTION
    Copies skills from the canonical skills/ directory into the target
    project's .claude/skills/ directory. Resolves transitive dependencies.
    Creates backups of existing files unless -Force.

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
    Installs all 20 skills to F:\MyProject\.claude\skills\

.EXAMPLE
    .\install.ps1 -TargetPath F:\MyProject -Skills project-workflow,gsap-core
    Installs project-workflow + gsap-core (with resolved dependencies).
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

Write-Host "=== Skills Installer ===" -ForegroundColor Cyan
Write-Host "Repository: $RepoRoot"
Write-Host "Target:      $TargetPath"
Write-Host ""

# ===================================================================
# Hardcoded dependency map — source of truth: skill-catalog.yaml
# Update this when adding/removing skills with dependencies.
# ===================================================================
$Script:DependencyMap = @{
    'session-context'      = @()
    'skill-creator'        = @()
    'karpathy-guidelines'  = @()
    'skills-manager'       = @()
    'canvas-design'        = @()
    'frontend-design'      = @()
    'impeccable'           = @()
    'docx'                 = @()
    'pdf'                  = @()
    'pptx'                 = @()
    'xlsx'                 = @()
    'gsap-core'            = @()
    'gsap-frameworks'      = @()
    'gsap-performance'     = @()
    'gsap-plugins'         = @()
    'gsap-react'           = @()
    'gsap-scrolltrigger'   = @()
    'gsap-timeline'        = @()
    'gsap-utils'           = @()
    'project-workflow'     = @('session-context')
    'task-orchestrator'    = @('session-context')
}

# Display versions (read from skill-catalog.yaml for reference)
$Script:SkillVersions = @{
    'session-context'      = '2.1.0'
    'skill-creator'        = '1.0.0'
    'karpathy-guidelines'  = '1.0.0'
    'skills-manager'       = '1.0.0'
    'canvas-design'        = '1.0.0'
    'frontend-design'      = '1.0.0'
    'impeccable'           = '3.9.1'
    'docx'                 = '1.0.0'
    'pdf'                  = '1.0.0'
    'pptx'                 = '1.0.0'
    'xlsx'                 = '1.0.0'
    'gsap-core'            = '1.0.0'
    'gsap-frameworks'      = '1.0.0'
    'gsap-performance'     = '1.0.0'
    'gsap-plugins'         = '1.0.0'
    'gsap-react'           = '1.0.0'
    'gsap-scrolltrigger'   = '1.0.0'
    'gsap-timeline'        = '1.0.0'
    'gsap-utils'           = '1.0.0'
    'project-workflow'     = '1.3.0'
    'task-orchestrator'    = '1.1.0'
}

# Install order (foundation → meta → design → documents → animation → workflow)
$Script:InstallOrder = @(
    'session-context', 'skill-creator', 'karpathy-guidelines', 'skills-manager',
    'canvas-design', 'frontend-design', 'impeccable',
    'docx', 'pdf', 'pptx', 'xlsx',
    'gsap-core', 'gsap-frameworks', 'gsap-performance', 'gsap-plugins',
    'gsap-react', 'gsap-scrolltrigger', 'gsap-timeline', 'gsap-utils',
    'project-workflow', 'task-orchestrator'
)

# ===================================================================
# Resolve dependency closure (BFS transitive closure)
# ===================================================================
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
            foreach ($dep in $Script:DependencyMap[$name]) {
                if ($dep -notin $resolved) {
                    $queue.Add($dep) | Out-Null
                }
            }
        }
    }

    # Topological sort using InstallOrder
    $orderMap = @{}
    for ($i = 0; $i -lt $Script:InstallOrder.Count; $i++) {
        $orderMap[$Script:InstallOrder[$i]] = $i
    }
    $sorted = $resolved | Sort-Object { if ($orderMap.ContainsKey($_)) { $orderMap[$_] } else { 99 } }
    return $sorted
}

function Get-SkillVersion {
    param([string]$skillName)
    if ($Script:SkillVersions.ContainsKey($skillName)) {
        return $Script:SkillVersions[$skillName]
    }
    return "unknown"
}

# ===================================================================
# Main installation
# ===================================================================
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
$totalFiles = 0

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
    }

    # Create target and copy
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item -Recurse -Force "$srcDir\*" $dstDir

    $fileCount = (Get-ChildItem -Recurse -File $dstDir).Count
    Write-Host "  Installed: $skillName ($fileCount files)" -ForegroundColor Green
    $installedCount++
    $totalFiles += $fileCount
}

# Install hooks if requested
if ($WithHooks) {
    $hooksSrc = Join-Path $SharedDir "hooks"
    $hooksDst = Join-Path $TargetPath ".claude\hooks"

    if (Test-Path $hooksSrc) {
        New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null

        $hooksJsonDst = Join-Path $TargetPath ".claude\hooks.json"
        $hooksJsonSrc = Join-Path $hooksSrc "hooks.json"
        if (Test-Path $hooksJsonSrc) {
            if ((Test-Path $hooksJsonDst) -and (-not $Force)) {
                Copy-Item -Force $hooksJsonDst (Join-Path $backupDir "hooks.json")
            }
            Copy-Item -Force $hooksJsonSrc $hooksJsonDst
            Write-Host "  Installed: hooks.json" -ForegroundColor Green
        }

        Get-ChildItem -Path $hooksSrc -Filter "*.sh" | ForEach-Object {
            $dst = Join-Path $hooksDst $_.Name
            if ((Test-Path $dst) -and (-not $Force)) {
                Copy-Item -Force $dst (Join-Path $backupDir $_.Name)
            }
            Copy-Item -Force $_.FullName $dst
            Write-Host "  Installed: hooks/$($_.Name)" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "$installedCount skills, $totalFiles total files installed to $skillTargetDir"
if ($WithHooks) {
    Write-Host "Hooks installed to $($TargetPath)\.claude\hooks\"
}
if (-not $Force -and (Test-Path $backupDir)) {
    Write-Host "Backup created at: $backupDir" -ForegroundColor DarkGray
}
