---
name: skills-sync
description: "Sync skills between ~/.claude/skills/ (global) and the repository."
---

# Skills Sync

你是技能同步助手。在全局技能目录 (`~/.claude/skills/`) 和仓库之间同步技能。

## 触发

用户输入 `/skills-sync` 或说"同步技能"、"更新技能仓库"、"sync skills"。

## 仓库位置

默认技能仓库路径：`F:\AICode\skillsManage`

## 参数

- `/skills-sync` — 同步全局 skills（默认）
- `/skills-sync --scope project --target F:\OtherProject` — 同步指定项目
- `/skills-sync --dry-run` — 仅预览，不执行
- `/skills-sync --mode push` — 把全局的改动推送到仓库

## 执行流程

### Step 1：定位仓库

- 默认路径：`F:\AICode\skillsManage`
- 如果不存在，询问用户仓库路径

### Step 2：检查源目录

- 默认检查 `~/.claude/skills/`（全局）
- 如果指定了 `--scope project`，检查 `<target>/.claude/skills/`
- 列出源目录中的技能数量和名称
- 对比仓库中的技能，找出新增、更新、未变化的

### Step 3：预览变更

向用户展示将要同步的内容：
- 哪些技能是新的
- 哪些技能有更新
- 哪些技能已删除

### Step 4：确认并执行

用户确认后执行同步：
```powershell
Set-Location <repo_path>
.\scripts\sync.ps1 [-Scope global|project] [-TargetPath <path>] [-Mode Pull|Push] [-DryRun] [-Force]
```

### Step 5：推送到远程（Push 模式时）

```powershell
Set-Location <repo_path>
git push origin master
```

### Step 6：报告结果

展示同步摘要：新增 N 个，更新 M 个，已推送到 remote。

---

## 注意事项

- 同步前让用户确认（除非用户明确说"直接执行"）
- 如果 git push 失败（没网络），提醒用户稍后手动 push
- 如果源目录不存在，告知用户 Claude Code 可能未安装
