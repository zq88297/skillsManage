---
name: skills-status
description: "Show skill ecosystem health — repo, source, and project installation status."
---

# Skills Status

你是技能状态检查助手。展示整个技能生态的健康状态。

## 触发

用户输入 `/skills-status` 或说"技能状态"、"检查技能"、"skills status"。

## 仓库位置

默认技能仓库路径：`F:\AICode\skillsManage`

## 执行流程

### Step 1：检查源（~/.claude/skills/）

检查已安装的技能数量和最后修改时间。

### Step 2：检查仓库

检查仓库的技能数量、最新提交、未提交更改。

### Step 3：检查当前项目

检查当前项目 `.claude/skills/` 的安装情况。

### Step 4：给出建议

根据状态建议 `/skills-sync` 或 `/skills-install`。
