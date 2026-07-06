<#
.SYNOPSIS
    Scaffold a new skill in this repository.

.DESCRIPTION
    Creates the directory structure for a new skill, generates SKILL.md
    from a template, creates an empty commands/ directory, and adds
    an entry to skill-catalog.yaml.

.PARAMETER Name
    Skill identifier (lowercase, hyphenated, e.g., "my-awesome-skill").

.PARAMETER Description
    One-line description (used for triggering). Be specific about when to use.

.PARAMETER Dependencies
    Comma-separated list of skill names this skill depends on.

.PARAMETER Layer
    foundation | workflow | orchestration. Default: workflow.

.EXAMPLE
    .\new-skill.ps1 -Name "code-formatter" -Description "Auto-format code on save using project conventions."
    .\new-skill.ps1 -Name "api-tester" -Description "Test REST APIs with structured test cases." -Dependencies session-context
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]*[a-z0-9]$')]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string[]]$Dependencies = @(),

    [Parameter(Mandatory = $false)]
    [ValidateSet("foundation", "workflow", "orchestration")]
    [string]$Layer = "workflow"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$SkillsDir = Join-Path $RepoRoot "skills"
$CatalogFile = Join-Path $RepoRoot "skill-catalog.yaml"
$TemplatesDir = Join-Path $RepoRoot "shared\templates"

# Validate not a duplicate
if (Test-Path (Join-Path $SkillsDir $Name)) {
    Write-Error "Skill '$Name' already exists at skills/$Name/"
    exit 1
}

# Validate dependencies are known skills
$knownSkills = Get-ChildItem -Directory $SkillsDir | ForEach-Object { $_.Name }
foreach ($dep in $Dependencies) {
    if ($dep -notin $knownSkills) {
        Write-Warning "Dependency '$dep' is not an existing skill directory. Continuing anyway."
    }
}

Write-Host "=== New Skill Scaffold ===" -ForegroundColor Cyan
Write-Host "Name:         $Name"
Write-Host "Description:  $Description"
Write-Host "Layer:        $Layer"
Write-Host "Dependencies: $($Dependencies -join ', ')"
Write-Host ""

# --- Create directory structure ---
$skillPath = Join-Path $SkillsDir $Name
$commandsPath = Join-Path $skillPath "commands"
New-Item -ItemType Directory -Force -Path $commandsPath | Out-Null

# --- Generate SKILL.md ---
$depsYaml = if ($Dependencies.Count -gt 0) {
    ($Dependencies | ForEach-Object { "`n  - $_" }) -join ''
} else { " []" }

$skillContent = @"
---
name: $Name
description: "$Description"
---

# $(($Name -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' ')

TODO: Describe what this skill does and the key behaviors the AI should follow.

## Overview

TODO: High-level description of the skill's purpose and workflow.

## Rules

TODO: Define the rules and behaviors the AI should follow when this skill is active.

## Commands

TODO: List the slash commands this skill provides (if any).

| Command | Purpose |
|---------|---------|
| (none yet) | |

## Dependencies

$(if ($Dependencies.Count -gt 0) { "This skill depends on: $($Dependencies -join ', ')" } else { "This skill has no dependencies." })

---

*Created: $(Get-Date -Format 'yyyy-MM-dd') | Version: 0.1.0*
"@

Set-Content -Path (Join-Path $skillPath "SKILL.md") -Value $skillContent -Encoding UTF8
Write-Host "Created: skills/$Name/SKILL.md" -ForegroundColor Green

# --- Generate DESIGN.md ---
$designContent = @"
# $Name — Design Rationale

## Motivation
TODO: Why was this skill created? What problem does it solve?

## Design Decisions
TODO: Key architectural and behavioral decisions.

## Evolution
TODO: Track major changes and the reasoning behind them.

---

*Created: $(Get-Date -Format 'yyyy-MM-dd')*
"@

Set-Content -Path (Join-Path $skillPath "DESIGN.md") -Value $designContent -Encoding UTF8
Write-Host "Created: skills/$Name/DESIGN.md" -ForegroundColor Green

# --- Update skill-catalog.yaml ---
$catalogContent = Get-Content $CatalogFile -Raw -Encoding UTF8

# Find the last skill entry's end (before dependency_order)
$insertMarker = "dependency_order:"
$catalogEntry = @"

  $Name`:
    version: "0.1.0"
    display_name: "$(($Name -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' ')"
    layer: $Layer
    description: >
      $Description
    dependencies:$depsYaml
    commands: []
    triggers_keywords: []
    tags: []
"@

$newCatalog = $catalogContent -replace $insertMarker, "$catalogEntry`n$insertMarker"
Set-Content -Path $CatalogFile -Value $newCatalog -Encoding UTF8
Write-Host "Updated: skill-catalog.yaml (added $Name entry)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Scaffold Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Edit skills/$Name/SKILL.md — fill in rules and behavior"
Write-Host "  2. Edit skills/$Name/DESIGN.md — document design rationale"
Write-Host "  3. Add commands to skills/$Name/commands/"
Write-Host "  4. Update skill-catalog.yaml with commands, keywords, and tags"
Write-Host "  5. Run .\scripts\validate.ps1 to check structure"
Write-Host "  6. Commit: git add skills/$Name/ && git commit -m 'feat($Name): add initial implementation'"
