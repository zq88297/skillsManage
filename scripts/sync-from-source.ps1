<#
.SYNOPSIS
    双向同步 ~/.claude/skills/ 和 Git 仓库。

.DESCRIPTION
    流程：
    1. git pull 拉取 GitHub 最新
    2. 比较 ~/.claude/skills/ 和 repo/skills/
    3. 本地缺少的 → 从仓库复制到本地
    4. 本地多出来的 → 复制到仓库
    5. 自动提交并推送

.PARAMETER SourcePath
    本地技能目录。默认: ~/.claude/skills/

.PARAMETER AutoCommit
    自动提交并推送到远程。

.PARAMETER DryRun
    仅预览，不执行修改。

.PARAMETER Force
    跳过确认提示。

.EXAMPLE
    .\sync-from-source.ps1 -DryRun
    预览同步差异。

.EXAMPLE
    .\sync-from-source.ps1 -AutoCommit
    双向同步并自动提交推送。
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
$RepoSkillsDir = Join-Path $RepoRoot "skills"
$CatalogFile = Join-Path $RepoRoot "skill-catalog.yaml"

# 验证目录
if (-not (Test-Path $SourcePath)) {
    Write-Error "本地技能目录不存在: $SourcePath"
    Write-Error "请确认 Claude Code 已安装。"
    exit 1
}
if (-not (Test-Path $RepoSkillsDir)) {
    Write-Error "仓库技能目录不存在: $RepoSkillsDir"
    exit 1
}

Write-Host "=== 技能双向同步 ===" -ForegroundColor Cyan
Write-Host "本地: $SourcePath"
Write-Host "仓库: $RepoSkillsDir"
if ($DryRun) { Write-Host "【预览模式】不会执行任何修改" -ForegroundColor Yellow }
Write-Host ""

# ============================================================
# Step 1: git pull 拉取最新
# ============================================================
if (-not $DryRun) {
    Write-Host "--- Step 1: 从 GitHub 拉取最新 ---" -ForegroundColor Cyan
    Set-Location $RepoRoot
    if (Test-Path (Join-Path $RepoRoot ".git")) {
        try {
            $remoteUrl = git remote get-url origin 2>$null
            if ($remoteUrl) {
                Write-Host "执行 git pull..."
                git pull --rebase origin master 2>$null
                if (-not $?) { Write-Host "警告: git pull 失败，将继续使用本地仓库" -ForegroundColor Yellow }
            } else {
                Write-Host "未配置远程仓库，跳过 git pull"
            }
        } catch {
            Write-Host "git pull 跳过" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# ============================================================
# 计算目录哈希
# ============================================================
function Get-SkillHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    $files = Get-ChildItem -Recurse -File $Path -ErrorAction SilentlyContinue | Sort-Object FullName
    $combined = ($files | ForEach-Object {
        $rel = $_.FullName.Substring($Path.Length + 1)
        "$rel:$($_.Name):$([System.IO.File]::ReadAllBytes($_.FullName).Length)"
    }) -join "`n"
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($combined)
    )
    return [BitConverter]::ToString($hash) -replace '-', ''
}

# ============================================================
# Step 2: 收集技能目录
# ============================================================
$localSkills = @{}
Get-ChildItem -Directory $SourcePath -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName "SKILL.md")) {
        $localSkills[$_.Name] = $_.FullName
    }
}

$repoSkills = @{}
Get-ChildItem -Directory $RepoSkillsDir -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName "SKILL.md")) {
        $repoSkills[$_.Name] = $_.FullName
    }
}

# ============================================================
# Step 3: 比较差异
# ============================================================
$pullSkills = @()    # 仓库有、本地没有 → 从仓库拉取到本地
$pushSkills = @()    # 本地有、仓库没有 → 从本地推送到仓库
$updateSkills = @()  # 都有但不同 → 以仓库为准更新本地
$identicalSkills = @()

$allNames = @($localSkills.Keys) + @($repoSkills.Keys) | Select-Object -Unique | Sort-Object

foreach ($name in $allNames) {
    $inLocal = $localSkills.ContainsKey($name)
    $inRepo = $repoSkills.ContainsKey($name)

    if (-not $inLocal -and $inRepo) {
        $pullSkills += $name
    }
    elseif ($inLocal -and -not $inRepo) {
        $pushSkills += $name
    }
    elseif ($inLocal -and $inRepo) {
        $localHash = Get-SkillHash -Path $localSkills[$name]
        $repoHash = Get-SkillHash -Path $repoSkills[$name]
        if ($localHash -ne $repoHash) {
            $updateSkills += $name
        } else {
            $identicalSkills += $name
        }
    }
}

# ============================================================
# Step 4: 报告差异
# ============================================================
$totalChanges = $pullSkills.Count + $pushSkills.Count + $updateSkills.Count

if ($totalChanges -eq 0) {
    Write-Host "✅ 所有技能已同步，无需操作。" -ForegroundColor Green
    exit 0
}

Write-Host "--- 差异分析 ---" -ForegroundColor Cyan

if ($pullSkills.Count -gt 0) {
    Write-Host "📥 需要从仓库拉取到本地 ($($pullSkills.Count) 个):" -ForegroundColor Green
    $pullSkills | ForEach-Object {
        $count = (Get-ChildItem -Recurse -File $repoSkills[$_]).Count
        Write-Host "  + $_ ($count 个文件)" -ForegroundColor Green
    }
}

if ($pushSkills.Count -gt 0) {
    Write-Host "📤 需要从本地推送到仓库 ($($pushSkills.Count) 个):" -ForegroundColor Yellow
    $pushSkills | ForEach-Object {
        $count = (Get-ChildItem -Recurse -File $localSkills[$_]).Count
        Write-Host "  + $_ ($count 个文件)" -ForegroundColor Yellow
    }
}

if ($updateSkills.Count -gt 0) {
    Write-Host "🔄 需要更新本地技能（以仓库为准）($($updateSkills.Count) 个):" -ForegroundColor Cyan
    $updateSkills | ForEach-Object { Write-Host "  ~ $_" -ForegroundColor Cyan }
}

Write-Host "✅ 已同步 ($($identicalSkills.Count) 个)" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) { exit 0 }

# ============================================================
# Step 5: 确认
# ============================================================
if (-not $Force) {
    Write-Host "--- 操作确认 ---" -ForegroundColor Cyan
    Write-Host "将执行以下操作:"
    if ($pullSkills.Count -gt 0) { Write-Host "  从仓库拉取 $($pullSkills.Count) 个技能到本地" }
    if ($pushSkills.Count -gt 0) { Write-Host "  从本地推送 $($pushSkills.Count) 个技能到仓库" }
    if ($updateSkills.Count -gt 0) { Write-Host "  更新本地 $($updateSkills.Count) 个技能（以仓库为准）" }
    Write-Host ""
    $response = Read-Host "确认执行? [y/N]"
    if ($response -notmatch '^[yY]') {
        Write-Host "已取消。"
        exit 0
    }
}

# ============================================================
# Step 6: 执行同步
# ============================================================
Write-Host ""
Write-Host "--- 执行同步 ---" -ForegroundColor Cyan

$backupDir = Join-Path $RepoRoot ".sync-backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# 6a: 从仓库拉取到本地
foreach ($name in $pullSkills) {
    $dst = Join-Path $SourcePath $name
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force (Join-Path $repoSkills[$name] "\*") $dst
    Write-Host "  📥 已拉取: $name → 本地" -ForegroundColor Green
}

# 6b: 从本地推送到仓库
foreach ($name in $pushSkills) {
    $dst = Join-Path $RepoSkillsDir $name
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force (Join-Path $localSkills[$name] "\*") $dst
    Write-Host "  📤 已推送: $name → 仓库" -ForegroundColor Yellow
}

# 6c: 以仓库为准更新本地
foreach ($name in $updateSkills) {
    # 备份本地版本
    if (Test-Path (Join-Path $SourcePath $name)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $backupDir $name) | Out-Null
        Copy-Item -Recurse -Force (Join-Path $SourcePath $name "\*") (Join-Path $backupDir $name)
    }
    # 用仓库版本覆盖本地
    $dst = Join-Path $SourcePath $name
    Remove-Item -Recurse -Force $dst -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force (Join-Path $repoSkills[$name] "\*") $dst
    Write-Host "  🔄 已更新: $name（以仓库为准）" -ForegroundColor Cyan
}

if (Test-Path $backupDir) {
    Write-Host "  备份目录: $backupDir" -ForegroundColor DarkGray
}

# ============================================================
# Step 7: 自动提交并推送
# ============================================================
if ($AutoCommit) {
    Write-Host ""
    Write-Host "--- 提交到 Git ---" -ForegroundColor Cyan
    Set-Location $RepoRoot

    $commitMsg = "sync: 双向同步技能`n`n"
    if ($pullSkills.Count -gt 0) { $commitMsg += "从仓库拉取: $($pullSkills -join ', ')`n" }
    if ($pushSkills.Count -gt 0) { $commitMsg += "推送到仓库: $($pushSkills -join ', ')`n" }
    if ($updateSkills.Count -gt 0) { $commitMsg += "更新本地: $($updateSkills -join ', ')`n" }

    # 更新 catalog 时间戳
    if (Test-Path $CatalogFile) {
        $catalogContent = Get-Content $CatalogFile -Raw -Encoding UTF8
        $today = Get-Date -Format 'yyyy-MM-dd'
        $catalogContent = $catalogContent -replace 'last_updated:\s*".*"', "last_updated: `"$today`""
        Set-Content -Path $CatalogFile -Value $catalogContent -Encoding UTF8
    }

    git add -A
    git commit -m $commitMsg 2>$null
    if (-not $?) { Write-Host "没有需要提交的更改" }

    Write-Host ""
    Write-Host "推送到 GitHub..." -ForegroundColor Cyan
    git push origin master 2>$null
    if ($?) {
        Write-Host "  ✅ 推送成功" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ 推送失败（可能没网络），请稍后手动执行: git push" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== 同步完成 ===" -ForegroundColor Cyan
Write-Host "本地: $SourcePath"
Write-Host "仓库: $RepoSkillsDir"
if ($pullSkills.Count -gt 0) { Write-Host "📥 拉取: $($pullSkills.Count) 个" -ForegroundColor Green }
if ($pushSkills.Count -gt 0) { Write-Host "📤 推送: $($pushSkills.Count) 个" -ForegroundColor Yellow }
if ($updateSkills.Count -gt 0) { Write-Host "🔄 更新: $($updateSkills.Count) 个" -ForegroundColor Cyan }
Write-Host "✅ 已同步: $($identicalSkills.Count) 个" -ForegroundColor DarkGray
