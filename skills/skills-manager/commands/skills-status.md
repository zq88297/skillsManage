# Skills Status

你是技能状态检查助手。展示整个技能生态的健康状态。

## 触发

用户输入 `/skills-status` 或说"技能状态"、"检查技能"、"skills status"、"技能仓库状态"。

## 执行流程

### Step 1：检测操作系统

使用当前系统的对应命令。以下是 Linux/macOS 和 Windows 两种版本。

### Step 2：检查源（~/.claude/skills/）

**Linux / macOS：**

```bash
src="$HOME/.claude/skills"
if [ -d "$src" ]; then
    count=$(find "$src" -maxdepth 1 -mindepth 1 -type d -exec test -f {}/SKILL.md \; -print | wc -l | tr -d ' ')
    echo "源 (已安装): $count 个技能"
    echo "路径: $src"
    echo "最后修改: $(stat -c %y "$src" 2>/dev/null || stat -f %Sm "$src")"
else
    echo "源: 未找到 (Claude Code 可能未安装)"
fi
```

**Windows (PowerShell)：**

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

### Step 3：检查仓库

先定位仓库（当前目录包含 `skills/` 和 `skill-catalog.yaml` 则使用，否则询问用户）。

**Linux / macOS：**

```bash
repo="<repo_path>"  # 由 Step 1 确定
if [ -d "$repo/skills" ]; then
    count=$(find "$repo/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    cd "$repo"
    last_commit=$(git log -1 --format="%h %s (%ar)")
    status=$(git status --short)
    echo "仓库: $count 个技能"
    echo "路径: $repo"
    echo "最新提交: $last_commit"
    if [ -n "$status" ]; then echo "未提交更改: 有"; else echo "未提交更改: 无"; fi
else
    echo "仓库: 未找到"
fi
```

**Windows (PowerShell)：**

```powershell
$repo = "<repo_path>"  # 由 Step 1 确定
if (Test-Path "$repo\skills") {
    $count = (Get-ChildItem -Directory "$repo\skills").Count
    Set-Location $repo
    $lastCommit = git log -1 --format="%h %s (%ar)"
    $status = git status --short
    Write-Host "仓库: $count 个技能"
    Write-Host "路径: $repo"
    Write-Host "最新提交: $lastCommit"
    if ($status) { Write-Host "未提交更改: 有" } else { Write-Host "未提交更改: 无" }
} else {
    Write-Host "仓库: 未找到"
}
```

### Step 4：检查当前项目

**Linux / macOS：**

```bash
project_skills="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/skills"
if [ -d "$project_skills" ]; then
    count=$(find "$project_skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    echo "当前项目: $count 个技能已安装"
    echo "路径: $project_skills"
else
    echo "当前项目: 未安装技能"
fi
```

**Windows (PowerShell)：**

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

### Step 5：输出状态面板

```text
╔══════════════════════════════════════════╗
║         📊 技能生态健康状态               ║
╠══════════════════════════════════════════╣
║                                          ║
║  📦 源 (~/.claude/skills/)               ║
║     ├─ 技能数: 20                        ║
║     └─ 最后更新: 2026-07-06              ║
║                                          ║
║  📁 仓库 (skillsManage)                  ║
║     ├─ 技能数: 20                        ║
║     ├─ 最新提交: abc123 feat: ...        ║
║     └─ 状态: ✅ 干净                     ║
║                                          ║
║  🎯 当前项目                             ║
║     ├─ 已安装: 20 / 20                   ║
║     └─ 状态: ✅ 已同步                   ║
║                                          ║
╠══════════════════════════════════════════╣
║  💡 建议: 无需操作，一切就绪              ║
╚══════════════════════════════════════════╝
```

### Step 6：给出建议

根据状态给出操作建议：
- 源有更新而仓库未同步 → 建议 `/skills-sync`
- 当前项目未安装技能 → 建议 `/skills-install`
- 仓库有未提交更改 → 提醒提交
- 一切就绪 → 无需操作
