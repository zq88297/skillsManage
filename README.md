# Skills Manager

中央化的 Claude Code 技能管理仓库 —— 20 个技能，400+ 文件，版本控制，一键部署。

## 为什么需要这个？

更换 agent 或开新项目时，需要重新配置所有技能。手动复制容易导致版本不一致、遗漏依赖、丢失改进。

这个仓库作为**唯一真相来源（source of truth）**：

- 📦 **一键安装** — 一条命令部署全部 20 个技能到新项目
- 🔄 **双向同步** — 在项目中改进的技能可以推送回仓库
- 🔗 **自动依赖解析** — 安装 `project-workflow` 会自动带上 `session-context`
- 🤖 **跨 Agent 兼容** — 导出为 Cursor、Cline、Copilot 格式
- 📝 **版本管理** — Git 追踪每个技能的变更历史

## 快速开始

### 一键安装（推荐）

在你的项目目录下运行一条命令即可：

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh)
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex; Install-Skills
```

指定项目路径：
```powershell
# PowerShell
irm ... | iex; Install-Skills -TargetPath "F:\MyProject"

# Bash
bash <(curl -fsSL .../setup.sh) --target /path/to/project
```

只安装部分技能：
```powershell
# PowerShell
irm ... | iex; Install-Skills -TargetPath "F:\MyProject" -Skills "gsap-core,gsap-timeline"

# Bash
bash <(curl -fsSL .../setup.sh) --skills gsap-core,gsap-timeline
```

### 手动安装

```powershell
# 1. 克隆
git clone https://github.com/zq88297/skillsManage.git skills-manage
cd skills-manage

# 2. 安装全部技能到项目
.\scripts\install.ps1 -TargetPath F:\MyProject

# 3. 或按需安装
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow,gsap-core

# 4. 同时安装 hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

重启 Claude Code，技能自动被发现。

## 技能清单（20 个）

### 基础层
| 技能 | 说明 |
|------|------|
| `session-context` | 全局上下文管理器 — 自动加载、任务追踪、决策记录 |

### 元技能
| 技能 | 说明 |
|------|------|
| `skill-creator` | 创建、优化、评估技能 |
| `karpathy-guidelines` | Karpathy 编码规范 — 减少 LLM 编码错误 |

### 设计层
| 技能 | 说明 |
|------|------|
| `canvas-design` | 视觉艺术 — 海报、设计、PNG/PDF 生成（含 82 字体） |
| `frontend-design` | 前端界面设计 — 网站、Dashboard、React 组件 |
| `impeccable` | UI 审查/优化 — 层次、可访问性、动效、主题（v3.9.1） |

### 文档层
| 技能 | 说明 |
|------|------|
| `docx` | Word 文档 — 创建、编辑、格式化、修订跟踪 |
| `pdf` | PDF 工具 — 读取、合并、拆分、表单、OCR |
| `pptx` | PowerPoint — 幻灯片创建、编辑、模板 |
| `xlsx` | Excel 电子表格 — 公式、图表、数据清洗、CSV |

### 动画层（GSAP 生态）
| 技能 | 说明 |
|------|------|
| `gsap-core` | 核心 API — tween、easing、stagger |
| `gsap-frameworks` | Vue/Svelte 集成 |
| `gsap-performance` | 性能优化 — 60fps、layout thrashing |
| `gsap-plugins` | 插件 — Scroll、SVG、Draggable、SplitText |
| `gsap-react` | React 集成 — useGSAP、gsap.context() |
| `gsap-scrolltrigger` | 滚动动画 — parallax、pin、scrub |
| `gsap-timeline` | 时间线 — 序列、编排 |
| `gsap-utils` | 工具函数 — clamp、mapRange、random |

### 工作流层
| 技能 | 说明 |
|------|------|
| `project-workflow` | 项目生命周期 — 需求→设计→实现→测试→验收 |
| `task-orchestrator` | 并行任务调度 — 依赖分析、多会话编排 |

## 日常操作

```powershell
# 同步（预览差异）
.\scripts\sync.ps1 -TargetPath F:\MyProject -DryRun

# 更新项目中的技能
.\scripts\sync.ps1 -TargetPath F:\MyProject

# 把项目中的改进推送回仓库
.\scripts\sync.ps1 -TargetPath F:\MyProject -Mode Push

# 创建新技能
.\scripts\new-skill.ps1 -Name "my-skill" -Description "当用户要求做X时触发"

# 校验仓库完整性
.\scripts\validate.ps1

# 导出到 Cursor
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject
```

## 目录结构

```
skillsManage/
├── skills/                # 20 个技能目录（400+ 文件）
├── scripts/               # setup.ps1/sh (一键安装), install, sync, validate, new-skill, export-cursor
├── shared/                # hooks 模板 + 脚手架模板
├── adapters/              # Cursor / Cline / Copilot 适配器
├── skill-catalog.yaml     # 完整技能清单
├── llms.txt               # GSAP AI 索引
├── session-context.skill  # 打包技能（ZIP 格式）
└── CLAUDE.md / README.md / CHANGELOG.md
```
