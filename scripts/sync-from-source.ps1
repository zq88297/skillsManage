<#
.SYNOPSIS
    Update locally installed skills from this repository.

.DESCRIPTION
    One-way sync from repo/skills/ to a local installed skills directory.
    The repository is the source of truth. Local-only skills are reported and
    preserved; they are not pushed back to the repository.

.PARAMETER SourcePath
    Local installed skills directory. Defaults to $CODEX_HOME/skills,
    then ~/.codex/skills, then ~/.claude/skills.

.PARAMETER DryRun
    Preview differences without writing files.

.PARAMETER Force
    Apply changes without confirmation.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$RepoSkillsDir = Join-Path $RepoRoot "skills"

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    if ($env:CODEX_HOME) {
        $SourcePath = Join-Path $env:CODEX_HOME "skills"
    }
    elseif (Test-Path (Join-Path $env:USERPROFILE ".codex\skills")) {
        $SourcePath = Join-Path $env:USERPROFILE ".codex\skills"
    }
    else {
        $SourcePath = Join-Path $env:USERPROFILE ".claude\skills"
    }
}

if (-not (Test-Path $RepoSkillsDir)) {
    Write-Error "仓库技能目录不存在: $RepoSkillsDir"
    exit 1
}
if (-not (Test-Path $SourcePath)) {
    Write-Error "本地技能目录不存在: $SourcePath"
    exit 1
}

Write-Host "=== 技能同步检查（仓库 -> 本地）===" -ForegroundColor Cyan
Write-Host "仓库: $RepoSkillsDir"
Write-Host "本地: $SourcePath"
if ($DryRun) { Write-Host "【预览模式】不会执行任何修改" -ForegroundColor Yellow }
Write-Host ""

Set-Location $RepoRoot
if (-not $DryRun -and (Test-Path (Join-Path $RepoRoot ".git"))) {
    try {
        if (git remote get-url origin 2>$null) {
            Write-Host "--- 拉取远端更新 ---" -ForegroundColor Cyan
            git pull --ff-only 2>$null
            if (-not $?) { Write-Host "警告: git pull --ff-only 失败，将使用当前本地仓库版本" -ForegroundColor Yellow }
            Write-Host ""
        }
    }
    catch {
        Write-Host "跳过远端拉取: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Get-SkillHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    $files = Get-ChildItem -Recurse -File $Path -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\.backup\\|/\\.backup/' } |
        Sort-Object FullName
    $combined = ($files | ForEach-Object {
        $rel = $_.FullName.Substring($Path.Length + 1)
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        "${rel}:${hash}"
    }) -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combined)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '')
}

$localSkills = @{}
Get-ChildItem -Directory $SourcePath -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -ne ".backup" -and (Test-Path (Join-Path $_.FullName "SKILL.md"))) {
        $localSkills[$_.Name] = $_.FullName
    }
}

$repoSkills = @{}
Get-ChildItem -Directory $RepoSkillsDir -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -ne ".backup" -and (Test-Path (Join-Path $_.FullName "SKILL.md"))) {
        $repoSkills[$_.Name] = $_.FullName
    }
}

$addSkills = @()
$updateSkills = @()
$localOnlySkills = @()
$identicalSkills = @()

$allNames = @($localSkills.Keys) + @($repoSkills.Keys) | Select-Object -Unique | Sort-Object
foreach ($name in $allNames) {
    $inLocal = $localSkills.ContainsKey($name)
    $inRepo = $repoSkills.ContainsKey($name)

    if (-not $inLocal -and $inRepo) {
        $addSkills += $name
    }
    elseif ($inLocal -and -not $inRepo) {
        $localOnlySkills += $name
    }
    elseif ($inLocal -and $inRepo) {
        if ((Get-SkillHash $localSkills[$name]) -ne (Get-SkillHash $repoSkills[$name])) {
            $updateSkills += $name
        }
        else {
            $identicalSkills += $name
        }
    }
}

Write-Host "--- 差异分析 ---" -ForegroundColor Cyan
Write-Host "新增到本地: $($addSkills.Count)"
Write-Host "更新本地:   $($updateSkills.Count)"
Write-Host "本地独有:   $($localOnlySkills.Count)（保留，不上传）"
Write-Host "无变化:     $($identicalSkills.Count)"

if ($addSkills.Count) { $addSkills | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green } }
if ($updateSkills.Count) { $updateSkills | ForEach-Object { Write-Host "  ~ $_" -ForegroundColor Cyan } }
if ($localOnlySkills.Count) { $localOnlySkills | ForEach-Object { Write-Host "  local-only: $_" -ForegroundColor Yellow } }
Write-Host ""

if ($addSkills.Count + $updateSkills.Count -eq 0) {
    Write-Host "无需同步。" -ForegroundColor Green
    exit 0
}
if ($DryRun) { exit 0 }

if (-not $Force) {
    $response = Read-Host "确认用仓库版本更新本地技能? [y/N]"
    if ($response -notmatch '^[yY]') {
        Write-Host "已取消。"
        exit 0
    }
}

$backupDir = Join-Path $SourcePath ".backup\sync-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

foreach ($name in $addSkills) {
    $dst = Join-Path $SourcePath $name
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force (Join-Path $repoSkills[$name] "*") $dst
    Write-Host "  新增: $name" -ForegroundColor Green
}

foreach ($name in $updateSkills) {
    $srcLocal = Join-Path $SourcePath $name
    $backup = Join-Path $backupDir $name
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    Copy-Item -Recurse -Force (Join-Path $srcLocal "*") $backup
    Remove-Item -Recurse -Force $srcLocal
    New-Item -ItemType Directory -Force -Path $srcLocal | Out-Null
    Copy-Item -Recurse -Force (Join-Path $repoSkills[$name] "*") $srcLocal
    Write-Host "  更新: $name" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== 技能同步完成 ===" -ForegroundColor Cyan
Write-Host "新增到本地: $($addSkills.Count)"
Write-Host "更新本地:   $($updateSkills.Count)"
Write-Host "本地独有:   $($localOnlySkills.Count)（已保留）"
if (Test-Path $backupDir) { Write-Host "备份目录:   $backupDir" }
