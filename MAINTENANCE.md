# Maintenance Guide

保持本地已安装技能与技能仓库同步的最佳实践。

## 日常维护工作流

### 1. 更新本地技能

当仓库中的技能更新后：

```bash
# Linux/macOS — 预览变化
bash ./scripts/sync-from-source.sh --dry-run

# Linux/macOS — 用仓库版本更新本地技能
bash ./scripts/sync-from-source.sh --force
```

```powershell
# Windows — 预览变化
.\scripts\sync-from-source.ps1 -DryRun

# Windows — 用仓库版本更新本地技能
.\scripts\sync-from-source.ps1 -Force
```

### 2. 更新目标项目

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
# 每天自动检查仓库更新并更新本地技能
.\scripts\setup-auto-sync.ps1 -Schedule Daily

# 或每小时检查
.\scripts\setup-auto-sync.ps1 -Schedule Hourly

# 取消自动同步
.\scripts\setup-auto-sync.ps1 -Uninstall
```

### 4. 手动添加新技能

```powershell
# 场景：在仓库中新增了技能
.\scripts\validate.ps1
.\scripts\sync-from-source.ps1 -DryRun
.\scripts\sync-from-source.ps1 -Force
```

## 数据流

```text
┌─────────────────────┐
│ 远程 Git 仓库        │  ← 团队共享版本
└────────┬────────────┘
         │ git pull --ff-only
         ▼
┌─────────────────────┐
│ skills-manage repo   │  ← Git 版本控制仓库，唯一真相来源
└────────┬────────────┘
         │ sync-from-source / sync / install
         ▼
┌─────────────────────┐
│ 本地 skills 目录     │  ← 当前机器的已安装技能
└────────┬────────────┘
         │ install / sync
         ▼
┌─────────────────────┐
│ 项目/.claude/skills/ │  ← 目标项目中的技能部署
│ （N 个开发项目）      │
└─────────────────────┘
```

## 检查清单

每月执行一次：

- [ ] `bash ./scripts/sync-from-source.sh --dry-run` — 检查仓库与本地技能差异
- [ ] `.\scripts\validate.ps1` — 校验仓库完整性
- [ ] 检查 GitHub Actions CI 状态
- [ ] 确认自动同步任务在运行（Windows: `Get-ScheduledTask -TaskName "ClaudeSkillsSync"`）
