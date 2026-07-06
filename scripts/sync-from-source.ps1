<#
.SYNOPSIS
    Sync skills FROM the live Claude Code installation (~/.claude/skills/)
    INTO this repository. Detects new, modified, and removed skills.

.DESCRIPTION
    This is the "pull from source" script for continuous maintenance. When
    Claude Code updates built-in skills (like impeccable, gsap, etc.) or you
    install new ones, this script pulls those changes into the repo.

    Workflow:
    1. Compares ~/.claude/skills/ against skills/
    2. Shows what's added, changed, or removed
    3. Copies updated files into the repo
    4. Optionally auto-commits with a changelog message

.PARAMETER SourcePath
    Path to the live Claude Code skills directory.
    Default: ~/.claude/skills/

.PARAMETER AutoCommit
    Automatically commit changes with a generated message.

.PARAMETER DryRun
    Show what would change without making changes.

.PARAMETER Force
    Skip confirmation prompt.

.EXAMPLE
    .\sync-from-source.ps1 -DryRun
    Preview what's changed in the live installation.

.EXAMPLE
    .\sync-from-source.ps1 -AutoCommit
    Pull all changes from live skills and auto-commit.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "$env:USERPROFILE\.claude\skills",

    [Parameter(Mandatory = $false)]
    [switch]$AutoCommit,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$DestSkillsDir = Join-Path $RepoRoot "skills"
$CatalogFile = Join-Path $RepoRoot "skill-catalog.yaml"

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source skills directory not found: $SourcePath"
    Write-Error "Are you sure Claude Code is installed?"
    exit 1
}
$SourcePath = (Resolve-Path $SourcePath).Path

Write-Host "=== Sync from Source ===" -ForegroundColor Cyan
Write-Host "Source: $SourcePath"
Write-Host "Repo:   $DestSkillsDir"
if ($DryRun) { Write-Host "DRY RUN — no changes will be made" -ForegroundColor Yellow }
Write-Host ""

# --- Collect skill directories from source (exclude non-skill files) ---
$sourceSkills = @{}
Get-ChildItem -Directory $SourcePath | ForEach-Object {
    $name = $_.Name
    if (Test-Path (Join-Path $_.FullName "SKILL.md")) {
        $sourceSkills[$name] = $_.FullName
    }
}

$repoSkills = @{}
if (Test-Path $DestSkillsDir) {
    Get-ChildItem -Directory $DestSkillsDir | ForEach-Object {
        $repoSkills[$_.Name] = $_.FullName
    }
}

$allNames = @($sourceSkills.Keys) + @($repoSkills.Keys) | Select-Object -Unique | Sort-Object

$newSkills = @()
$removedSkills = @()
$modifiedSkills = @()
$identicalSkills = @()

foreach ($name in $allNames) {
    $inSource = $sourceSkills.ContainsKey($name)
    $inRepo = $repoSkills.ContainsKey($name)

    if ($inSource -and -not $inRepo) {
        $newSkills += $name
    }
    elseif (-not $inSource -and $inRepo) {
        # Skill exists in repo but not in source — skip (user may have source configured differently)
        # Don't auto-delete; user would need to manually remove from repo
    }
    elseif ($inSource -and $inRepo) {
        # Compare file hashes
        $srcHash = Get-SkillHash -Path $sourceSkills[$name]
        $repoHash = Get-SkillHash -Path $repoSkills[$name]
        if ($srcHash -ne $repoHash) {
            $modifiedSkills += $name
        }
        else {
            $identicalSkills += $name
        }
    }
}

function Get-SkillHash {
    param([string]$Path)
    $files = Get-ChildItem -Recurse -File $Path -ErrorAction SilentlyContinue | Sort-Object FullName
    $combined = ($files | ForEach-Object {
        "$($_.FullName.Substring($Path.Length)):$(Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash"
    }) -join "`n"
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($combined)
    )
    return [BitConverter]::ToString($hash) -replace '-', ''
}

# --- Report ---
$totalChanges = $newSkills.Count + $modifiedSkills.Count

if ($totalChanges -eq 0) {
    Write-Host "All skills are in sync. Nothing to do." -ForegroundColor Green
    exit 0
}

if ($newSkills.Count -gt 0) {
    Write-Host "NEW ($($newSkills.Count) skills):" -ForegroundColor Green
    $newSkills | ForEach-Object {
        $count = (Get-ChildItem -Recurse -File $sourceSkills[$_]).Count
        Write-Host "  + $_ ($count files)" -ForegroundColor Green
    }
}
if ($modifiedSkills.Count -gt 0) {
    Write-Host "MODIFIED ($($modifiedSkills.Count) skills):" -ForegroundColor Yellow
    $modifiedSkills | ForEach-Object { Write-Host "  ~ $_" -ForegroundColor Yellow }
}
Write-Host "IDENTICAL ($($identicalSkills.Count) skills)" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) { exit 0 }

# --- Confirm ---
if (-not $Force -and -not $AutoCommit) {
    $response = Read-Host "Sync these changes into the repo? [y/N]"
    if ($response -notmatch '^[yY]') {
        Write-Host "Cancelled."
        exit 0
    }
}

# --- Apply ---
$backupDir = Join-Path $RepoRoot ".sync-backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Copy new skills
foreach ($name in $newSkills) {
    $src = $sourceSkills[$name]
    $dst = Join-Path $DestSkillsDir $name
    Copy-Item -Recurse -Force $src $dst
    Write-Host "  Copied: $name" -ForegroundColor Green
}

# Update modified skills (backup old first)
foreach ($name in $modifiedSkills) {
    $repoPath = $repoSkills[$name]
    # Backup
    Copy-Item -Recurse -Force $repoPath (Join-Path $backupDir $name)
    # Remove old, copy new
    Remove-Item -Recurse -Force $repoPath
    Copy-Item -Recurse -Force $sourceSkills[$name] $repoPath
    Write-Host "  Updated: $name" -ForegroundColor Yellow
}

Write-Host "Backup at: $backupDir" -ForegroundColor DarkGray

# --- Auto-commit if requested ---
if ($AutoCommit) {
    Set-Location $RepoRoot
    $commitMsg = "sync: pull updates from live installation`n`n"
    if ($newSkills.Count -gt 0) {
        $commitMsg += "Added: $($newSkills -join ', ')`n"
    }
    if ($modifiedSkills.Count -gt 0) {
        $commitMsg += "Modified: $($modifiedSkills -join ', ')`n"
    }

    # Also update skill-catalog.yaml timestamp
    $catalogContent = Get-Content $CatalogFile -Raw -Encoding UTF8
    $today = Get-Date -Format 'yyyy-MM-dd'
    $catalogContent = $catalogContent -replace 'last_updated:\s*".*"', "last_updated: `"$today`""
    Set-Content -Path $CatalogFile -Value $catalogContent -Encoding UTF8

    git add -A
    git commit -m $commitMsg
    Write-Host ""
    Write-Host "Committed: $commitMsg" -ForegroundColor Green
    Write-Host "Run 'git push' to push changes to remote." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Sync Complete ===" -ForegroundColor Cyan
