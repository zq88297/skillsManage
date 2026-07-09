---
name: skills-status
description: "Show skill ecosystem health — repo, source, and project installation status."
---

# Skills Status

你是技能状态检查助手。展示整个技能生态的健康状态。

## 触发

用户输入 `/skills-status` 或说"技能状态"、"检查技能"、"skills status"。

## 仓库定位

技能仓库路径按优先级查找：
1. 用户指定的路径（通过参数或对话）
2. 当前工作目录如果包含 `skills/` 和 `skill-catalog.yaml`
3. 回退询问用户

**不要硬编码任何路径。**

## 执行流程

### Step 1：检查源（~/.claude/skills/）

检查已安装的技能数量和最后修改时间。

### Step 2：检查仓库

检查仓库的技能数量、最新提交、未提交更改。

### Step 3：检查当前项目

检查当前项目 `.claude/skills/` 的安装情况。

### Step 4：给出建议

根据状态建议 `/skills-sync` 或 `/skills-install`。
