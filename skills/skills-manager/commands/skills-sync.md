# Skills Sync

你是技能双向同步助手。在本地全局技能目录 (`~/.claude/skills/`) 和 GitHub 仓库之间进行双向同步。

## 触发

用户输入 `/skills-sync` 或说"同步技能"、"更新技能仓库"、"pull skills"。

## 参数

- `/skills-sync` — 执行双向同步
- `/skills-sync --dry-run` — 仅预览差异，不执行
- `/skills-sync --force` — 跳过确认直接执行

## 同步逻辑

```text
GitHub 仓库  ←git pull→  本地仓库  ←比较/复制→  ~/.claude/skills/
```

1. **git pull** — 从 GitHub 拉取仓库最新版本
2. **比较** — 对比 `~/.claude/skills/` 和仓库中的技能
3. **拉取** — 仓库有但本地没有的 → 复制到本地
4. **推送** — 本地有但仓库没有的 → 复制到仓库
5. **更新** — 都有但内容不同 → 以仓库为准更新本地
6. **提交推送** — 自动 commit 并 push 到 GitHub

## 执行流程

### Step 1：定位仓库

- 如果当前目录包含 `skills/` 和 `skill-catalog.yaml`，使用当前目录
- 否则询问用户仓库路径
- **不要硬编码任何路径**

### Step 2：检查本地目录

验证 `~/.claude/skills/` 存在并列出技能数量。

### Step 3：检测操作系统并执行同步

根据操作系统选择对应的脚本：

**Linux / macOS (Bash)：**

```bash
cd <repo_path>
bash ./scripts/sync-from-source.sh --dry-run
```

**Windows (PowerShell)：**

```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -DryRun
```

将差异分析展示给用户：

- 📥 需要从仓库拉取的技能
- 📤 需要从本地推送到仓库的技能
- 🔄 需要更新的技能（以仓库为准）
- ✅ 已同步的技能

### Step 4：执行同步（完整模式）

如果用户确认同步：

**Linux / macOS：**

```bash
cd <repo_path>
bash ./scripts/sync-from-source.sh --auto-commit --force
```

**Windows：**

```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -AutoCommit -Force
```

### Step 5：报告结果

```text
=== 同步完成 ===
📥 拉取: N 个（仓库 → 本地）
📤 推送: M 个（本地 → 仓库）
🔄 更新: K 个（以仓库为准）
✅ 已同步: J 个
```

---

## 注意事项

- 同步前让用户确认（除非用户明确说"直接执行"）
- 冲突时以仓库为准（仓库是版本控制的真相来源）
- 本地独有的技能会自动推送到仓库并提交
- 如果 git push 失败（没网络），提醒用户稍后手动 push
- 如果本地技能目录不存在，告知用户 Claude Code 可能未安装
