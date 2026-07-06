<#
.SYNOPSIS
    Synchronize skills between the repository and a target project.

.DESCRIPTION
    In Pull mode (default), compares skills in the target project against
    the canonical versions in this repo. Shows what's new, modified,
    removed, or identical. Backs up existing files before overwriting.

    In Push mode, copies changes from a target project back to this repo
    (useful when refining a skill in the field).

.PARAMETER TargetPath
    Path to the target project root.

.PARAMETER Mode
    "Pull" (default): update target from repo.
    "Push": update repo from target.

.PARAMETER Force
    Apply changes without confirmation prompt.

.PARAMETER DryRun
    Show what would change without actually changing anything.

.EXAMPLE
    .\sync.ps1 -TargetPath F:\MyProject
    Shows diff and prompts before applying.

.EXAMPLE
    .\sync.ps1 -TargetPath F:\MyProject -Mode Push -DryRun
    Shows what would be pushed back to the repo.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Pull", "Push")]
    [string]$Mode = "Pull",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$RepoSkillsDir = Join-Path $RepoRoot "skills"

if (-not (Test-Path $TargetPath)) {
    Write-Error "Target path does not exist: $TargetPath"
    exit 1
}
$TargetPath = (Resolve-Path $TargetPath).Path
$TargetSkillsDir = Join-Path $TargetPath ".claude\skills"

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
Write-Host "Mode:        $Mode"
if ($DryRun) { Write-Host "DRY RUN - no changes will be made" -ForegroundColor Yellow }
Write-Host ""

$repoMap = Get-SkillFileMap -BaseDir $RepoSkillsDir
$targetMap = Get-SkillFileMap -BaseDir $TargetSkillsDir

$allPaths = @($repoMap.Keys) + @($targetMap.Keys) | Select-Object -Unique | Sort-Object

$newFiles = @()
$modifiedFiles = @()
$removedFiles = @()
$identicalFiles = @()

foreach ($path in $allPaths) {
    $inRepo = $repoMap.ContainsKey($path)
    $inTarget = $targetMap.ContainsKey($path)

    if ($inRepo -and -not $inTarget) {
        $newFiles += $path
    }
    elseif (-not $inRepo -and $inTarget) {
        $removedFiles += $path
    }
    elseif ($repoMap[$path] -ne $targetMap[$path]) {
        $modifiedFiles += $path
    }
    else {
        $identicalFiles += $path
    }
}

# --- Report ---
if ($newFiles.Count -eq 0 -and $modifiedFiles.Count -eq 0 -and $removedFiles.Count -eq 0) {
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
if ($removedFiles.Count -gt 0) {
    Write-Host "REMOVED ($($removedFiles.Count) files):" -ForegroundColor Red
    $removedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
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
$sourceDir = if ($Mode -eq "Pull") { $RepoSkillsDir } else { $TargetSkillsDir }
$destDir   = if ($Mode -eq "Pull") { $TargetSkillsDir } else { $RepoSkillsDir }

Write-Host "Creating backup at: $backupDir" -ForegroundColor DarkGray
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Backup files that will be modified/removed
$toBackup = $modifiedFiles + $removedFiles
foreach ($path in $toBackup) {
    $srcFile = Join-Path $destDir $path
    if (Test-Path $srcFile) {
        $backupFile = Join-Path $backupDir $path
        $backupParent = Split-Path -Parent $backupFile
        New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
        Copy-Item -Force $srcFile $backupFile
    }
}

# --- Apply: Pull mode ---
if ($Mode -eq "Pull") {
    # Copy new and modified files from repo to target
    $toCopy = $newFiles + $modifiedFiles
    foreach ($path in $toCopy) {
        $src = Join-Path $RepoSkillsDir $path
        $dst = Join-Path $TargetSkillsDir $path
        $dstParent = Split-Path -Parent $dst
        New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
        Copy-Item -Force $src $dst
    }
    Write-Host "Pulled $($toCopy.Count) files from repo to target." -ForegroundColor Green
}
else {
    # Push mode: copy new and modified files from target to repo
    $toCopy = $newFiles + $modifiedFiles
    foreach ($path in $toCopy) {
        $src = Join-Path $TargetSkillsDir $path
        $dst = Join-Path $RepoSkillsDir $path
        $dstParent = Split-Path -Parent $dst
        New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
        Copy-Item -Force $src $dst
    }
    Write-Host "Pushed $($toCopy.Count) files from target to repo." -ForegroundColor Green
    Write-Host "Remember to commit the changes in the repo!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Sync Complete ===" -ForegroundColor Cyan
if (Test-Path $backupDir) {
    Write-Host "Backup saved at: $backupDir" -ForegroundColor DarkGray
}
