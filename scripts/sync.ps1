<#
.SYNOPSIS
    Update target skills from this repository.

.DESCRIPTION
    Compares skills in the target against the canonical versions in this repo.
    Shows what's new, modified, target-only, or identical. Backs up existing
    target files before overwriting.

    Use -Scope global to sync with ~/.claude/skills/ instead of a project.

.PARAMETER TargetPath
    Path to the target project root. Not needed when -Scope global.

.PARAMETER Scope
    "project" (default): sync with a specific project's .claude/skills/.
    "global": sync with ~/.claude/skills/.

.PARAMETER Force
    Apply changes without confirmation prompt.

.PARAMETER DryRun
    Show what would change without actually changing anything.

.EXAMPLE
    .\sync.ps1
    Sync global ~/.claude/skills/ with repo (default).

.EXAMPLE
    .\sync.ps1 -Scope project -TargetPath F:\MyProject
    Sync a specific project.

#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TargetPath = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("project", "global")]
    [string]$Scope = "global",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$RepoSkillsDir = Join-Path $RepoRoot "skills"
$GlobalSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

# Resolve target directory
if ($Scope -eq "global") {
    $TargetSkillsDir = $GlobalSkillsDir
    if (-not (Test-Path $TargetSkillsDir)) {
        Write-Error "Global skills directory does not exist: $TargetSkillsDir"
        exit 1
    }
} else {
    if ([string]::IsNullOrEmpty($TargetPath)) {
        $TargetPath = (Get-Location).Path
    }
    if (-not (Test-Path $TargetPath)) {
        Write-Error "Target path does not exist: $TargetPath"
        exit 1
    }
    $TargetPath = (Resolve-Path $TargetPath).Path
    $TargetSkillsDir = Join-Path $TargetPath ".claude\skills"
}

# --- Compute file hash ---
function Get-FileHashSafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    return $hash
}

# --- Walk skill directory and collect file->hash map ---
function Get-SkillFileMap {
    param([string]$BaseDir)
    if (-not (Test-Path $BaseDir)) { return @{} }
    $map = @{}
    Get-ChildItem -Recurse -File $BaseDir | ForEach-Object {
        $relPath = $_.FullName.Substring($BaseDir.Length + 1) -replace '\\', '/'
        $map[$relPath] = Get-FileHashSafe -Path $_.FullName
    }
    return $map
}

Write-Host "=== Skills Sync ===" -ForegroundColor Cyan
Write-Host "Repository: $RepoSkillsDir"
Write-Host "Target:      $TargetSkillsDir"
Write-Host "Direction:   repository -> target"
if ($DryRun) { Write-Host "DRY RUN - no changes will be made" -ForegroundColor Yellow }
Write-Host ""

$repoMap = Get-SkillFileMap -BaseDir $RepoSkillsDir
$targetMap = Get-SkillFileMap -BaseDir $TargetSkillsDir

$allPaths = @($repoMap.Keys) + @($targetMap.Keys) | Select-Object -Unique | Sort-Object

$newFiles = @()
$modifiedFiles = @()
$targetOnlyFiles = @()
$identicalFiles = @()

foreach ($path in $allPaths) {
    $inRepo = $repoMap.ContainsKey($path)
    $inTarget = $targetMap.ContainsKey($path)

    if ($inRepo -and -not $inTarget) {
        $newFiles += $path
    }
    elseif (-not $inRepo -and $inTarget) {
        $targetOnlyFiles += $path
    }
    elseif ($repoMap[$path] -ne $targetMap[$path]) {
        $modifiedFiles += $path
    }
    else {
        $identicalFiles += $path
    }
}

# --- Report ---
if ($newFiles.Count -eq 0 -and $modifiedFiles.Count -eq 0 -and $targetOnlyFiles.Count -eq 0) {
    Write-Host "All files are identical. Nothing to sync." -ForegroundColor Green
    exit 0
}

if ($newFiles.Count -gt 0) {
    Write-Host "NEW ($($newFiles.Count) files):" -ForegroundColor Green
    $newFiles | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
}
if ($modifiedFiles.Count -gt 0) {
    Write-Host "MODIFIED ($($modifiedFiles.Count) files):" -ForegroundColor Yellow
    $modifiedFiles | ForEach-Object { Write-Host "  ~ $_" -ForegroundColor Yellow }
}
if ($targetOnlyFiles.Count -gt 0) {
    Write-Host "TARGET ONLY ($($targetOnlyFiles.Count) files, kept):" -ForegroundColor Yellow
    $targetOnlyFiles | ForEach-Object { Write-Host "  local-only: $_" -ForegroundColor Yellow }
}
Write-Host "IDENTICAL ($($identicalFiles.Count) files)" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) { exit 0 }

# --- Confirm ---
if (-not $Force) {
    $response = Read-Host "Apply these changes? [y/N]"
    if ($response -notmatch '^[yY]') {
        Write-Host "Sync cancelled."
        exit 0
    }
}

# --- Backup before applying ---
$backupDir = Join-Path $TargetSkillsDir ".backup\sync-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "Creating backup at: $backupDir" -ForegroundColor DarkGray
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Backup files that will be modified
$toBackup = $modifiedFiles
foreach ($path in $toBackup) {
    $srcFile = Join-Path $TargetSkillsDir $path
    if (Test-Path $srcFile) {
        $backupFile = Join-Path $backupDir $path
        $backupParent = Split-Path -Parent $backupFile
        New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
        Copy-Item -Force $srcFile $backupFile
    }
}

# Copy new and modified files from repo to target
$toCopy = $newFiles + $modifiedFiles
foreach ($path in $toCopy) {
    $src = Join-Path $RepoSkillsDir $path
    $dst = Join-Path $TargetSkillsDir $path
    $dstParent = Split-Path -Parent $dst
    New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
    Copy-Item -Force $src $dst
}
Write-Host "Updated $($toCopy.Count) files from repo to target." -ForegroundColor Green
if ($targetOnlyFiles.Count -gt 0) {
    Write-Host "Target-only files were preserved: $($targetOnlyFiles.Count)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Sync Complete ===" -ForegroundColor Cyan
if (Test-Path $backupDir) {
    Write-Host "Backup saved at: $backupDir" -ForegroundColor DarkGray
}
