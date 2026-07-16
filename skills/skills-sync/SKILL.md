---
name: skills-sync
description: "检查技能仓库中的 skill 是否有更新，并将仓库版本同步到本地已安装 skill。单向同步：仓库 -> 本地。用于：同步技能、更新本地技能、拉取最新 skill、检查仓库 skill 更新、skills sync。"
---

# Skills Sync

你是技能同步助手。`sync` 只做一件事：检查仓库中的 skill 是否比本地已安装版本更新或更完整，并用仓库版本更新本地 skill。

## 触发

用户输入 `/skills-sync`，或说“同步技能”“更新本地技能”“拉取最新 skill”“检查仓库 skill 更新”“sync skills”。

## 仓库定位

技能仓库路径按优先级查找：

1. 用户指定的路径（通过参数或对话）
2. 当前工作目录如果包含 `skills/` 和 `skill-catalog.yaml`
3. 回退询问用户

**不要硬编码任何路径。**

本地技能目录按优先级查找：

1. `$CODEX_HOME/skills`
2. `~/.codex/skills`
3. 兼容旧环境时使用 `~/.claude/skills`
4. 用户通过 `--target <path>` 指定的技能目录

## 同步逻辑

```text
远程仓库  ->  本地仓库  ->  本地技能目录
```

1. **更新仓库**：如仓库配置了远程，先执行安全拉取（例如 `git pull --ff-only`）。
2. **比较差异**：对比仓库 `skills/` 与本地技能目录。
3. **新增本地**：仓库有但本地没有的 skill，复制到本地。
4. **更新本地**：两边都有但内容不同的 skill，备份本地后用仓库覆盖。
5. **保留本地独有**：本地有但仓库没有的 skill，只报告，不删除、不上传。

禁止行为：

- 不把本地 skill 推送回仓库。
- 不自动 commit。
- 不自动 push。
- 不删除本地独有 skill，除非用户明确要求。

## 参数

- `/skills-sync`：检查差异，确认后同步仓库版本到本地。
- `/skills-sync --dry-run`：仅预览差异，不写入。
- `/skills-sync --force`：跳过确认，直接更新本地。
- `/skills-sync --target <path>`：同步到指定技能目录。

## 执行流程

### Step 1：定位仓库

- 如果当前目录包含 `skills/` 和 `skill-catalog.yaml`，使用当前目录
- 否则询问用户仓库路径

### Step 2：检查本地技能目录

验证本地技能目录存在，列出已安装 skill 数量。

### Step 3：检测操作系统并执行同步

**Windows (PowerShell)：**

```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -DryRun
```

确认后：

```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -Force
```

**Linux / macOS：**

```bash
cd <repo_path>
bash ./scripts/sync-from-source.sh --dry-run
```

确认后：

```bash
bash ./scripts/sync-from-source.sh --force
```

### Step 4：报告结果

展示同步摘要：

```text
=== 技能同步完成 ===
新增到本地: N
更新本地: M
本地独有: K（已保留）
无需变化: J
备份目录: <path，如有>
```
