# Maintenance Guide

保持技能仓库与 Claude Code 实时安装同步的最佳实践。

## 日常维护工作流

### 1. 拉取官方更新

当 Claude Code 更新内置技能（如 impeccable、gsap、skill-creator 等）后：

```bash
# Linux/macOS — 预览变化
bash ./scripts/sync-from-source.sh --dry-run

# Linux/macOS — 拉取变化到仓库并自动提交
bash ./scripts/sync-from-source.sh --auto-commit
```

```powershell
# Windows — 预览变化
.\scripts\sync-from-source.ps1 -DryRun

# Windows — 拉取变化到仓库并自动提交
.\scripts\sync-from-source.ps1 -AutoCommit
```

```bash
# 推送到 GitHub
git push
```

### 2. 推送到目标项目

```bash
# Linux/macOS
bash ./scripts/install.sh /path/to/project
```

```powershell
# Windows
.\scripts\install.ps1 -TargetPath F:\MyProject
```

### 3. 设置自动同步（Windows）

```powershell
# 每天自动检查 ~/.claude/skills/ 的变化
.\scripts\setup-auto-sync.ps1 -Schedule Daily -AutoPush

# 或每小时检查
.\scripts\setup-auto-sync.ps1 -Schedule Hourly -AutoPush

# 取消自动同步
.\scripts\setup-auto-sync.ps1 -Uninstall
```

### 4. 手动添加新技能

```bash
# 场景：安装了新技能到 ~/.claude/skills/
bash ./scripts/sync-from-source.sh --dry-run     # 先预览
bash ./scripts/sync-from-source.sh --auto-commit  # 拉取到仓库
git push
```

## 数据流

```text
┌─────────────────────┐
│ ~/.claude/skills/    │  ← Claude Code 实时安装，官方更新在这里
│ （20 个技能目录）     │
└────────┬────────────┘
         │ sync-from-source (拉取)
         ▼
┌─────────────────────┐
│ skills-manage repo   │  ← Git 版本控制仓库，唯一真相来源
└────────┬────────────┘
         │ install / sync (推送)
         ▼
┌─────────────────────┐
│ 项目/.claude/skills/ │  ← 目标项目中的技能部署
│ （N 个开发项目）      │
└─────────────────────┘
```

## 检查清单

每月执行一次：

- [ ] `bash ./scripts/sync-from-source.sh --dry-run` — 检查有无官方更新
- [ ] `.\scripts\validate.ps1` — 校验仓库完整性
- [ ] 检查 GitHub Actions CI 状态
- [ ] 确认自动同步任务在运行（Windows: `Get-ScheduledTask -TaskName "ClaudeSkillsSync"`）
