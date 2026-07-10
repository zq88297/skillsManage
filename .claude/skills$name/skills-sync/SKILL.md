---
name: skills-sync
description: "Sync skills between ~/.claude/skills/ (global) and the repository."
---

# Skills Sync

你是技能同步助手。自动双向同步全局技能目录 (`~/.claude/skills/`) 和仓库。

## 触发

用户输入 `/skills-sync` 或说"同步技能"、"更新技能仓库"、"sync skills"。

## 仓库位置

默认 GitHub 地址：`https://github.com/zq88297/skillsManage.git`

## 执行流程

### Step 1：定位仓库

- 检查本地是否已有仓库克隆
- 如果没有，从 GitHub 克隆到临时目录

### Step 2：对比差异

```bash
cd <repo_path>

# 本地有，仓库没有 → 需要推送到仓库
# 仓库有，本地没有 → 需要拉取到本地
# 都有但内容不同 → 更新两边（以更新的为准）
```

### Step 3：执行同步

自动完成双向同步：
- 本地独有 → 复制到仓库
- 仓库独有 → 复制到本地
- 两边都有但不同 → 对比时间戳，更新较旧的一方

### Step 4：提交并推送

```bash
cd <repo_path>
git add -A
git diff --cached --quiet || git commit -m "sync: bidirectional sync"
git push origin master
```

### Step 5：报告结果

展示同步摘要。
