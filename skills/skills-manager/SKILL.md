---
name: skills-manager
description: "Manage the Claude Code skills repository — sync, install, status. Trigger when the user wants to sync skills, update the skills repo, install skills to a project, or check skills status. Use for: 同步技能, 更新技能仓库, 安装技能, 技能状态, skills sync, skills install, skills update."
---

# Skills Manager

管理 Claude Code 技能仓库的日常操作。当用户提到"同步技能"、"更新技能"、"安装技能"、"检查技能"时自动触发。

## 仓库位置

默认技能仓库路径：`F:\AICode\skillsManage`

如果仓库在其他位置，在首次使用时告知 AI 正确路径。

## 命令

| 命令 | 用途 |
|------|------|
| `/skills-sync` | 从 ~/.claude/skills/ 同步更新到仓库并推送 |
| `/skills-install` | 安装技能到当前项目 |
| `/skills-status` | 查看仓库、源、当前项目的技能状态 |

---

## 自动规则

### 规则 1：检测到官方技能更新时主动提醒

当 AI 注意到 Claude Code 的内置技能（如 impeccable、skill-creator 等）有版本更新提示时，主动询问用户是否需要运行 `/skills-sync` 拉取更新。

### 规则 2：新项目自动建议安装

当在未安装技能的项目中开始工作时，主动建议运行 `/skills-install`。
