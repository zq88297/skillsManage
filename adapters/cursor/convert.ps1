<#
.SYNOPSIS
    Convert skills to Cursor .cursorrules format.
    This is a convenience wrapper around scripts/export-cursor.ps1.

.EXAMPLE
    .\convert.ps1 -OutputPath F:\MyProject
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoScript = Join-Path $ScriptDir "..\..\scripts\export-cursor.ps1"

if (-not (Test-Path $RepoScript)) {
    Write-Error "Export script not found: $RepoScript"
    exit 1
}

& $RepoScript -OutputPath $OutputPath
