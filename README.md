# Skills Manager

集中维护、版本控制和部署 AI 编程技能的仓库。`skills/` 是技能定义的唯一真相来源，`skill-catalog.yaml` 记录版本、分类、依赖和安装顺序。

当前 catalog 共管理 **50 个技能**，覆盖项目工作流、代码规范、前端设计、文档处理、动画、数据查询、MCP 和 Web 测试等场景。

## 功能

- 一键安装全部或指定技能到全局目录或当前项目
- 从 catalog 读取技能版本和依赖关系（PowerShell 安装器）
- 单向同步仓库版本到本地或项目，保留目标端独有技能
- 修改前自动备份已有文件
- 校验技能结构、frontmatter、命令引用、catalog 和依赖图
- 导出 Cursor、Cline 等 Agent 可使用的规则格式

## 快速开始

### 一键安装

默认安装到全局 `~/.claude/skills/`，完成后重启 Claude Code。

macOS / Linux：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh)
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex; Install-Skills
```

只安装到当前项目：

```bash
# macOS / Linux
bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh) --scope project
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex; Install-Skills -Scope project
```

只安装指定技能：

```bash
# macOS / Linux
bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh) --skills gsap-core,gsap-timeline
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.ps1 | iex; Install-Skills -Skills "gsap-core,gsap-timeline"
```

> PowerShell 安装器会根据 `skill-catalog.yaml` 解析传递依赖。Unix 安装器当前只安装显式指定的技能；选择有依赖的技能时，请同时列出其依赖。

### 从本地仓库安装

```powershell
git clone https://github.com/zq88297/skillsManage.git skills-manage
cd skills-manage

# 安装全部技能到项目
.\scripts\install.ps1 -TargetPath F:\MyProject

# 按需安装，并自动解析依赖
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow,gsap-core

# 同时安装 shared/hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

```bash
git clone https://github.com/zq88297/skillsManage.git skills-manage
cd skills-manage

# 安装全部技能到项目
bash ./scripts/install.sh /path/to/project

# 按需安装
bash ./scripts/install.sh /path/to/project --skills session-context,project-workflow

# 同时安装 shared/hooks
bash ./scripts/install.sh /path/to/project --with-hooks
```

项目级技能安装到 `<项目>/.claude/skills/`。

## 同步与维护

所有同步都是 **仓库 -> 目标目录** 的单向更新。目标目录中的独有技能会保留，不会反向写入仓库；被覆盖的内容会保存到目标技能目录下的 `.backup/`。

### 更新当前机器的本地技能

`sync-from-source` 会在实际同步前尝试执行 `git pull --ff-only`。默认目标依次为 `$CODEX_HOME/skills`、`~/.codex/skills`、`~/.claude/skills`。

```powershell
# 预览差异
.\scripts\sync-from-source.ps1 -DryRun

# 拉取仓库更新并应用到本地技能目录
.\scripts\sync-from-source.ps1 -Force

# 指定本地技能目录
.\scripts\sync-from-source.ps1 -SourcePath C:\path\to\skills -Force
```

```bash
bash ./scripts/sync-from-source.sh --dry-run
bash ./scripts/sync-from-source.sh --force
bash ./scripts/sync-from-source.sh --source /path/to/skills --force
```

### 更新全局或项目技能

`sync.ps1` 使用当前仓库内容更新目标，不会自动拉取远端提交。

```powershell
# 预览并更新全局 ~/.claude/skills（默认 scope）
.\scripts\sync.ps1 -DryRun
.\scripts\sync.ps1 -Force

# 预览并更新指定项目
.\scripts\sync.ps1 -Scope project -TargetPath F:\MyProject -DryRun
.\scripts\sync.ps1 -Scope project -TargetPath F:\MyProject -Force
```

Windows 可创建定时同步任务：

```powershell
.\scripts\setup-auto-sync.ps1 -Schedule Daily
.\scripts\setup-auto-sync.ps1 -Schedule Hourly
.\scripts\setup-auto-sync.ps1 -Uninstall
```

更多维护说明见 [MAINTENANCE.md](MAINTENANCE.md)。

## 技能目录

| 分类 | 数量 | 示例 |
| --- | ---: | --- |
| 基础与元技能 | 6 | `session-context`、`skill-creator`、`karpathy-guidelines`、`skills-sync` |
| 设计与前端 | 19 | `frontend-design`、`impeccable`、`ui-ux-pro-max`、`react-bits` |
| 文档与内容 | 7 | `docx`、`pdf`、`pptx`、`xlsx`、`doc-coauthoring` |
| GSAP 动画 | 8 | `gsap-core`、`gsap-react`、`gsap-scrolltrigger`、`gsap-timeline` |
| 数据与工具 | 6 | `a-stock-data`、`claude-api`、`mcp-builder`、`webapp-testing` |
| 工作流 | 4 | `project-workflow`、`task-orchestrator`、`skiis-context` |

完整技能名称、版本、描述、依赖和安装顺序以 [skill-catalog.yaml](skill-catalog.yaml) 为准。

## 开发命令

```powershell
# 校验仓库完整性
.\scripts\validate.ps1

# 创建新技能并登记到 catalog
.\scripts\new-skill.ps1 -Name "my-skill" -Description "当用户要求做 X 时触发"

# 导出核心规则到 Cursor
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject

# 导出指定技能到 Cursor
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject -Skills session-context,project-workflow
```

Unix 环境可使用 `scripts/new-skill.sh` 创建技能。Cursor 导出默认包含 `session-context`、`project-workflow` 和 `task-orchestrator`；Cline 的使用方式见 [adapters/cline/README.md](adapters/cline/README.md)。

## 目录结构

```text
skillsManage/
|-- skills/                 # 技能定义，每个目录至少包含 SKILL.md
|-- scripts/                # 安装、同步、校验、脚手架和导出脚本
|-- shared/                 # hooks 与技能模板
|-- adapters/               # Cursor、Cline、Copilot 适配说明
|-- skill-catalog.yaml      # 技能 catalog、版本、依赖和安装顺序
|-- MAINTENANCE.md          # 日常维护指南
|-- CHANGELOG.md            # 版本变更记录
`-- CLAUDE.md               # 仓库开发约定
```

## 约定

- 技能目录使用小写连字符命名，例如 `session-context`
- 每个技能必须包含带 YAML frontmatter 的 `SKILL.md`
- `SKILL.md` 中的 `name` 必须与目录名一致
- 新增或修改技能后运行 `.\scripts\validate.ps1`
- 提交信息格式：`<type>(<skill-name>): <description>`
