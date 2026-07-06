# Skills Manager

中央化的 Claude Code 技能管理仓库。版本控制、一键部署、跨项目同步。

## 为什么需要这个？

当你在多个项目中使用 Claude Code 时，每个项目都需要单独配置技能（skills）。手动复制文件容易导致版本不一致、遗漏依赖、丢失改进。

这个仓库作为技能的**唯一真相来源（source of truth）**，让你可以：
- 📦 **一键安装** — 一条命令部署所有技能到新项目
- 🔄 **双向同步** — 在项目中改进的技能可以推送回仓库
- 🔗 **自动依赖解析** — 安装 `project-workflow` 会自动带上 `session-context`
- 🤖 **跨 Agent 兼容** — 导出为 Cursor、Cline、Copilot 格式
- 📝 **版本管理** — Git 追踪每个技能的变更历史

## 快速开始

### 1. 克隆仓库

```powershell
git clone <your-remote-url> skills-manage
cd skills-manage
```

### 2. 安装技能到项目

```powershell
# 安装全部技能
.\scripts\install.ps1 -TargetPath F:\MyProject

# 选择性安装（自动解析依赖）
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow

# 同时安装 hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

### 3. 在项目中验证

重启 Claude Code，技能会自动被发现。输入 `/session-load` 测试。

## 技能清单

### session-context（基础层）
全局上下文管理器 — 自动加载项目上下文、追踪任务/决策/踩坑、跨项目任务派发、分支隔离。

**命令：** `/session-load`, `/session-save`, `/session-end`, `/context-check`, `/context-sync`, `/task-send`

### project-workflow（工作流层）
项目生命周期管理 — 需求分析 → 方案设计 → 代码实现 → 测试 → 验收。

**命令：** `/workflow:start`, `/workflow:status`, `/workflow:review`

### task-orchestrator（编排层）
并行任务调度 — 依赖分析、多会话编排、任务锁管理。

**命令：** `/task:plan`, `/task:run`

## 日常使用

### 同步变更

```powershell
# 预览差异
.\scripts\sync.ps1 -TargetPath F:\MyProject -DryRun

# 拉取仓库更新到项目
.\scripts\sync.ps1 -TargetPath F:\MyProject

# 把项目中的改进推送回仓库
.\scripts\sync.ps1 -TargetPath F:\MyProject -Mode Push
```

### 创建新技能

```powershell
.\scripts\new-skill.ps1 -Name "my-skill" -Description "当用户要求做X时触发，实现Y功能" -Dependencies session-context
```

### 导出到其他 Agent

```powershell
# Cursor
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject

# 手动：Cline → 复制 .cursorrules 为 .clinerules
# 手动：Copilot → 复制内容到 .github/copilot-instructions.md
```

## 目录结构

```
skillsManage/
├── skills/              # 技能源文件（唯一真相来源）
├── scripts/             # 安装/同步/校验/导出脚本
├── shared/              # 共享资源（hooks、模板）
├── adapters/            # 跨 Agent 适配器
├── skill-catalog.yaml   # 技能清单（版本、依赖、元数据）
├── CHANGELOG.md         # 变更日志
├── CLAUDE.md            # Agent 自文档
└── README.md            # 本文件
```

## 分支策略

- `main` — 稳定分支，始终可用
- `feat/*` — 新技能或功能开发
- `fix/*` — Bug 修复

提交格式：`<type>(<skill-name>): <description>`

## 许可

Private use. Customize as needed.
