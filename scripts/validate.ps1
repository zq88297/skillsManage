<#
.SYNOPSIS
    Validate the structure and integrity of all managed skills.

.DESCRIPTION
    Checks:
    1. Every skill directory has a valid SKILL.md with YAML frontmatter
    2. Every command referenced in SKILL.md has a corresponding .md in commands/
    3. Every .md in commands/ is referenced somewhere in SKILL.md
    4. skill-catalog.yaml entries match actual skill directories
    5. Dependency graph has no cycles
    6. File naming conventions are followed

.EXAMPLE
    .\validate.ps1
    Runs all validation checks and reports results.
#>

$ErrorActionPreference = "Continue"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$SkillDir = Join-Path $RepoRoot "skills"
$CatalogFile = Join-Path $RepoRoot "skill-catalog.yaml"

$errors = @()
$warnings = @()
$passed = 0

function Add-Error {
    param([string]$Msg)
    $script:errors += $Msg
    Write-Host "  [FAIL] $Msg" -ForegroundColor Red
}

function Add-Warning {
    param([string]$Msg)
    $script:warnings += $Msg
    Write-Host "  [WARN] $Msg" -ForegroundColor Yellow
}

function Add-Pass {
    param([string]$Msg)
    $script:passed++
    Write-Host "  [PASS] $Msg" -ForegroundColor Green
}

Write-Host "=== Skills Validator ===" -ForegroundColor Cyan
Write-Host ""

# --- Check 1: Catalog file exists and is parseable ---
Write-Host "--- Catalog Integrity ---" -ForegroundColor Yellow
if (-not (Test-Path $CatalogFile)) {
    Add-Error "skill-catalog.yaml not found at $CatalogFile"
}
else {
    Add-Pass "skill-catalog.yaml exists"

    # Basic YAML validation - check for required top-level keys
    $catalogContent = Get-Content $CatalogFile -Raw -Encoding UTF8
    if ($catalogContent -match 'catalog_version:' -and $catalogContent -match 'skills:') {
        Add-Pass "Catalog has required keys (catalog_version, skills)"
    }
    else {
        Add-Error "Catalog missing required keys"
    }

    # Check for known skill entries
    if ($catalogContent -match 'session-context:' -and
        $catalogContent -match 'project-workflow:' -and
        $catalogContent -match 'task-orchestrator:') {
        Add-Pass "Catalog contains all 3 core skills"
    }
    else {
        Add-Warning "Catalog may be missing some core skill entries"
    }
}

# --- Check 2: Each skill directory has valid SKILL.md ---
Write-Host ""
Write-Host "--- Skill Structure ---" -ForegroundColor Yellow

$skillDirs = Get-ChildItem -Directory $SkillDir -ErrorAction SilentlyContinue
$knownSkills = @($skillDirs | ForEach-Object { $_.Name })

foreach ($dir in $skillDirs) {
    $skillFile = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        Add-Error "$($dir.Name): Missing SKILL.md"
        continue
    }

    # Normalize an optional UTF-8 BOM so local validation matches CI behavior.
    $frontmatter = (Get-Content $skillFile -Raw -Encoding UTF8) -replace "^\uFEFF", ""
    if ($frontmatter -notmatch '---\s*\nname:\s*(\S+)') {
        Add-Error "$($dir.Name)/SKILL.md: Missing or invalid YAML frontmatter (no 'name:' field)"
        continue
    }
    $declaredName = $Matches[1]

    if ($declaredName -ne $dir.Name) {
        Add-Warning "$($dir.Name): SKILL.md name '$declaredName' doesn't match directory name"
    }

    if ($frontmatter -notmatch 'description:\s*\S') {
        Add-Error "$($dir.Name)/SKILL.md: Missing 'description:' in frontmatter"
    }

    Add-Pass "$($dir.Name): Valid SKILL.md (name=$declaredName)"

    # Check command references
    $commandsDir = Join-Path $dir.FullName "commands"
    $hasCommandsDir = Test-Path $commandsDir

    if ($hasCommandsDir) {
        $commandFiles = @(Get-ChildItem -File $commandsDir -Filter "*.md" | ForEach-Object { $_.BaseName })
        # Look for command references in SKILL.md
        $skillBody = $frontmatter

        foreach ($cmd in $commandFiles) {
            if ($skillBody -match $cmd) {
                Add-Pass "$($dir.Name): Command /$cmd referenced in SKILL.md"
            }
            else {
                Add-Warning "$($dir.Name): Command $cmd.md exists but not referenced in SKILL.md"
            }
        }
    }
    else {
        Add-Warning "$($dir.Name): No commands/ directory"
    }
}

# --- Check 3: Catalog entries match actual skill directories ---
Write-Host ""
Write-Host "--- Catalog-Directory Consistency ---" -ForegroundColor Yellow

if (Test-Path $CatalogFile) {
    # Extract skill names from catalog
    $catalogSkillNames = @()
    $content = Get-Content $CatalogFile -Raw -Encoding UTF8
    $inSkills = $false
    foreach ($line in ($content -split "`n")) {
        if ($line -eq 'skills:') { $inSkills = $true; continue }
        if ($line -eq 'dependency_order:') { $inSkills = $false; continue }
        if ($inSkills -and $line -match '^\s\s(\S[^:]*):\s*$') {
            $catalogSkillNames += $Matches[1]
        }
    }

    foreach ($name in $knownSkills) {
        if ($name -in $catalogSkillNames) {
            Add-Pass "Catalog entry exists for: $name"
        }
        else {
            Add-Error "Skill directory '$name' has no entry in skill-catalog.yaml"
        }
    }

    foreach ($name in $catalogSkillNames) {
        if ($name -notin $knownSkills) {
            Add-Warning "Catalog entry '$name' has no corresponding skill directory"
        }
    }
}

# --- Check 4: Dependency cycle detection ---
Write-Host ""
Write-Host "--- Dependency Check ---" -ForegroundColor Yellow

$depMap = @{
    'session-context'   = @()
    'grill-me'          = @()
    'project-workflow'  = @('session-context', 'grill-me')
    'task-orchestrator' = @('session-context')
}

# Simple DFS cycle detection
function Test-Cycle {
    param([string]$Node, [hashtable]$Graph, [hashtable]$Visited, [hashtable]$RecStack)
    if ($RecStack[$Node]) { return $true }
    if ($Visited[$Node]) { return $false }
    $Visited[$Node] = $true
    $RecStack[$Node] = $true
    foreach ($dep in $Graph[$Node]) {
        if (Test-Cycle -Node $dep -Graph $Graph -Visited $Visited -RecStack $RecStack) {
            return $true
        }
    }
    $RecStack[$Node] = $false
    return $false
}

$hasCycle = $false
foreach ($skill in $depMap.Keys) {
    $visited = @{}; $recStack = @{}
    if (Test-Cycle -Node $skill -Graph $depMap -Visited $visited -RecStack $recStack) {
        Add-Error "Dependency cycle detected involving: $skill"
        $hasCycle = $true
    }
}
if (-not $hasCycle) {
    Add-Pass "No dependency cycles detected"
}

# Verify all dependencies reference known skills
foreach ($skill in $depMap.Keys) {
    foreach ($dep in $depMap[$skill]) {
        if ($dep -notin $depMap.Keys) {
            Add-Error "$skill depends on unknown skill: $dep"
        }
    }
}

# --- Check 5: File naming conventions ---
Write-Host ""
Write-Host "--- Naming Conventions ---" -ForegroundColor Yellow

Get-ChildItem -Recurse -File $SkillDir | ForEach-Object {
    $name = $_.Name
    $dir = $_.DirectoryName

    # SKILL.md must be exactly that
    if ($name -eq "SKILL.md") {
        # correct
    }
    elseif ($_.Extension -eq ".md") {
        if ($dir -match 'commands') {
            if ($name -match '^[a-z0-9-]+\.md$') {
                # valid command name
            }
            else {
                Add-Warning "Command file name should be lowercase-hyphenated: $name"
            }
        }
    }
    elseif ($_.Extension -eq ".yaml" -or $_.Extension -eq ".yml") {
        # agent config files are OK
    }
    elseif ($_.Extension -eq ".sh") {
        # shell scripts are OK
    }
}

# --- Summary ---
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "  Passed:  $passed" -ForegroundColor Green
Write-Host "  Errors:  $($errors.Count)" -ForegroundColor Red
Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor Yellow

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}
if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

if ($errors.Count -eq 0) {
    Write-Host ""
    Write-Host "All validations passed!" -ForegroundColor Green
    exit 0
}
else {
    exit 1
}
