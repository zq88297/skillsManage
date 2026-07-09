---
name: skills-sync
description: "Sync skills between ~/.claude/skills/ (global) and the repository."
---

# Skills Sync

你是技能同步助手。在全局技能目录 (`~/.claude/skills/`) 和仓库之间同步技能。

## 触发

用户输入 `/skills-sync` 或说"同步技能"、"更新技能仓库"、"sync skills"。

## 仓库定位

技能仓库路径按优先级查找：
1. 用户指定的路径（通过参数或对话）
2. 当前工作目录如果包含 `skills/` 和 `skill-catalog.yaml`
3. 回退询问用户

**不要硬编码任何路径。**

## 参数

- `/skills-sync` — 同步全局 skills（默认）
- `/skills-sync --scope project --target /path/to/project` — 同步指定项目
- `/skills-sync --dry-run` — 仅预览，不执行
- `/skills-sync --mode push` — 把全局的改动推送到仓库

## 执行流程

### Step 1：定位仓库

- 如果当前目录包含 `skills/` 和 `skill-catalog.yaml`，使用当前目录
- 否则询问用户仓库路径

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

根据操作系统选择对应的脚本：

**Linux / macOS (Bash)：**

```bash
cd <repo_path>
bash ./scripts/sync-from-source.sh [--dry-run] [--auto-commit] [--force]
```

**Windows (PowerShell)：**

```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 [-DryRun] [-AutoCommit] [-Force]
```

### Step 5：推送到远程（Push 模式时）

```bash
cd <repo_path>
git push origin master
```

### Step 6：报告结果

展示同步摘要：新增 N 个，更新 M 个，已推送到 remote。

---

## 注意事项

- 同步前让用户确认（除非用户明确说"直接执行"）
- 如果 git push 失败（没网络），提醒用户稍后手动 push
- 如果源目录不存在，告知用户 Claude Code 可能未安装
