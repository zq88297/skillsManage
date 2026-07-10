# Skills Sync

你是技能同步助手。从 Claude Code 实时安装目录 (`~/.claude/skills/`) 拉取技能更新到仓库，并自动提交推送。

## 触发

用户输入 `/skills-sync` 或说"同步技能"、"更新技能仓库"、"pull skills"。

## 参数

用户可指定：`/skills-sync --dry-run`（仅预览，不执行）

## 执行流程

### Step 1：定位仓库

- 默认路径：`F:\AICode\skillsManage`
- 如果不存在，询问用户仓库路径
- 如果用户之前指定过其他路径，使用那个路径

### Step 2：检查源目录

- 验证 `$env:USERPROFILE\.claude\skills\` 存在
- 列出源目录中的技能数量和名称

### Step 3：执行同步（Dry Run 模式）

如果用户指定了 `--dry-run` 或只是询问状态：
```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -DryRun
```
将输出结果展示给用户：哪些技能是新的、变更的、相同的。

### Step 4：执行同步（完整模式）

如果用户确认同步：
```powershell
Set-Location <repo_path>
.\scripts\sync-from-source.ps1 -AutoCommit -Force
```

### Step 5：推送到远程

```powershell
Set-Location <repo_path>
git push origin master
```

### Step 6：报告结果

```
✅ 技能同步完成
- 仓库：<repo_path>
- 新增：N 个技能
- 更新：M 个技能
- 已推送到：<remote_url>
```

---

## 注意事项

- 同步前让用户确认（除非用户明确说"直接执行"）
- 如果 git push 失败（没网络），提醒用户稍后手动 push
- 如果源目录不存在，告知用户 Claude Code 可能未安装
