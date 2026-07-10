# Skills Status

你是技能状态检查助手。展示整个技能生态的健康状态。

## 触发

用户输入 `/skills-status` 或说"技能状态"、"检查技能"、"skills status"、"技能仓库状态"。

## 执行流程

### Step 1：检查源（~/.claude/skills/）

**Linux/macOS:**
```bash
SRC="$HOME/.claude/skills"
if [[ -d "$SRC" ]]; then
    count=$(find "$SRC" -maxdepth 1 -mindepth 1 -type d | wc -l)
    echo "源 (已安装): $count 个技能"
    echo "路径: $SRC"
    echo "最后修改: $(stat -c %y "$SRC" 2>/dev/null || stat -f %m "$SRC")"
else
    echo "源: 未找到 (Claude Code 可能未安装)"
fi
```

**Windows (PowerShell):**
```powershell
$src = "$env:USERPROFILE\.claude\skills"
if (Test-Path $src) {
    $count = (Get-ChildItem -Directory $src | Where-Object { Test-Path "$_\SKILL.md" }).Count
    Write-Host "源 (已安装): $count 个技能"
    Write-Host "路径: $src"
    Write-Host "最后修改: $((Get-Item $src).LastWriteTime)"
} else {
    Write-Host "源: 未找到 (Claude Code 可能未安装)"
}
```

### Step 2：检查仓库

检查本地是否有仓库克隆，或者直接从 GitHub 获取状态：

**Linux/macOS:**
```bash
# 检查本地常见路径
REPO=""
for path in ~/skillsManage ~/AICode/skillsManage ~/work/skillsManage; do
    if [[ -d "$path/.git" ]]; then
        REPO="$path"
        break
    fi
done

if [[ -n "$REPO" ]]; then
    count=$(find "$REPO/skills" -maxdepth 1 -mindepth 1 -type d | wc -l)
    cd "$REPO"
    last_commit=$(git log -1 --format="%h %s (%ar)")
    status=$(git status --short)
    echo "仓库: $count 个技能"
    echo "路径: $REPO"
    echo "最新提交: $last_commit"
    if [[ -n "$status" ]]; then
        echo "未提交更改: 有"
    else
        echo "未提交更改: 无"
    fi
else
    echo "仓库: 未找到本地克隆"
    echo "GitHub: https://github.com/zq88297/skillsManage"
fi
```

**Windows (PowerShell):**
```powershell
# 检查本地常见路径
$repoPaths = @(
    "$env:USERPROFILE\skillsManage",
    "$env:USERPROFILE\AICode\skillsManage",
    "$env:USERPROFILE\work\skillsManage"
)
$repo = ""
foreach ($path in $repoPaths) {
    if (Test-Path "$path\.git") {
        $repo = $path
        break
    }
}

if ($repo -ne "") {
    $count = (Get-ChildItem -Directory "$repo\skills").Count
    Set-Location $repo
    $lastCommit = git log -1 --format="%h %s (%ar)"
    $status = git status --short
    Write-Host "仓库: $count 个技能"
    Write-Host "路径: $repo"
    Write-Host "最新提交: $lastCommit"
    if ($status) { Write-Host "未提交更改: 有" } else { Write-Host "未提交更改: 无" }
} else {
    Write-Host "仓库: 未找到本地克隆"
    Write-Host "GitHub: https://github.com/zq88297/skillsManage"
}
```

### Step 3：检查当前项目

**Linux/macOS:**
```bash
PROJECT_SKILLS="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/skills"
if [[ -d "$PROJECT_SKILLS" ]]; then
    count=$(find "$PROJECT_SKILLS" -maxdepth 1 -mindepth 1 -type d | wc -l)
    echo "当前项目: $count 个技能已安装"
    echo "路径: $PROJECT_SKILLS"
else
    echo "当前项目: 未安装技能"
fi
```

**Windows (PowerShell):**
```powershell
$projectSkills = "$env:CLAUDE_PROJECT_DIR\.claude\skills"
if (Test-Path $projectSkills) {
    $count = (Get-ChildItem -Directory $projectSkills -ErrorAction SilentlyContinue).Count
    Write-Host "当前项目: $count 个技能已安装"
    Write-Host "路径: $projectSkills"
} else {
    Write-Host "当前项目: 未安装技能"
}
```

### Step 4：输出状态面板

```
╔══════════════════════════════════════════╗
║         📊 技能生态健康状态               ║
╠══════════════════════════════════════════╣
║                                          ║
║  📦 源 (~/.claude/skills/)               ║
║     ├─ 技能数: 36                        ║
║     └─ 最后更新: 2026-07-06              ║
║                                          ║
║  📁 仓库 (skillsManage)                  ║
║     ├─ 技能数: 36                        ║
║     ├─ 最新提交: abc123 feat: ...        ║
║     └─ 状态: ✅ 干净                     ║
║                                          ║
║  🎯 当前项目                             ║
║     ├─ 已安装: 25 / 36                   ║
║     └─ 状态: ⚠️ 需要更新                 ║
║                                          ║
╠══════════════════════════════════════════╣
║  💡 建议: 运行 /skills-install 更新项目  ║
╚══════════════════════════════════════════╝
```

### Step 5：给出建议

根据状态给出操作建议：
- 源有更新而仓库未同步 → 建议 `/skills-sync`
- 当前项目未安装技能 → 建议 `/skills-install`
- 仓库有未提交更改 → 提醒提交
- 一切就绪 → 无需操作
