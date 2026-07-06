<#
.SYNOPSIS
    Export managed skills as Cursor .cursorrules format.

.DESCRIPTION
    Reads all skills from skills/ and generates a single .cursorrules file
    by concatenating SKILL.md content (minus YAML frontmatter) and command
    files, organized in dependency order (foundation skills first).

.PARAMETER OutputPath
    Path to write the .cursorrules file. Default: current directory.

.PARAMETER Skills
    Specific skills to export (comma-separated). Default: all.

.EXAMPLE
    .\export-cursor.ps1 -OutputPath F:\MyProject
    Exports all skills to F:\MyProject\.cursorrules
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".",

    [Parameter(Mandatory = $false)]
    [string[]]$Skills = @()
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$SkillSourceDir = Join-Path $RepoRoot "skills"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
}
$OutputPath = (Resolve-Path $OutputPath).Path
$OutputFile = Join-Path $OutputPath ".cursorrules"

# Distribution order: foundation skills first
$skillOrder = @(
    "session-context",
    "project-workflow",
    "task-orchestrator"
)

if ($Skills.Count -gt 0) {
    $skillOrder = $Skills
}

Write-Host "=== Export Cursor Rules ===" -ForegroundColor Cyan
Write-Host "Output: $OutputFile"
Write-Host ""

$output = @()
$output += "# Cursor Rules"
$output += "# Generated from skills-manage repository on $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$output += "# Source: $RepoRoot"
$output += ""

foreach ($skillName in $skillOrder) {
    $skillPath = Join-Path $SkillSourceDir $skillName
    $skillFile = Join-Path $skillPath "SKILL.md"

    if (-not (Test-Path $skillFile)) {
        Write-Warning "Skill not found: $skillName — skipping"
        continue
    }

    Write-Host "Exporting: $skillName" -ForegroundColor Green

    $content = Get-Content $skillFile -Raw -Encoding UTF8
    $content = $content -replace "`r`n", "`n"

    # Strip YAML frontmatter
    if ($content -match '^---\s*\n(.*?)\n---\s*\n(.*)$') {
        $body = $Matches[2]
    }
    else {
        $body = $content
    }

    $output += "## Skill: $skillName"
    $output += $body
    $output += ""

    # Append commands
    $commandsDir = Join-Path $skillPath "commands"
    if (Test-Path $commandsDir) {
        Get-ChildItem -Path $commandsDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
            $cmdContent = Get-Content $_.FullName -Raw -Encoding UTF8
            $cmdContent = $cmdContent -replace "`r`n", "`n"
            $cmdName = $_.BaseName
            $output += "### Command: /$cmdName"
            $output += $cmdContent
            $output += ""
        }
    }

    $output += "---"
    $output += ""
}

$finalOutput = $output -join "`n"
Set-Content -Path $OutputFile -Value $finalOutput -Encoding UTF8

Write-Host ""
Write-Host "=== Export Complete ===" -ForegroundColor Cyan
Write-Host "Wrote: $OutputFile"
Write-Host "Lines: $($output.Count)"
