# Context Sync

同步当前项目或模块的架构快照。

当用户运行 `/context-sync`、新增顶层模块、依赖或构建配置变化，或 `architecture.md` 明显过期时使用。

## Step 1：确定范围

默认只处理当前目录。除非用户明确指定其他路径，不要扫描其他项目或上级目录。

如果 `$ARGUMENTS` 包含 `--deps`，额外关注依赖清单和工具链配置。

## Step 2：收集结构信号

先读取低成本结构信息：

- 一级目录和一级文件
- 构建或依赖文件，如 `Makefile`、`CMakeLists.txt`、`package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod`、`pom.xml`
- 入口文件，如 `main.*`、`index.*`、`app.*`
- 已存在的 `.claude/context/architecture.md`

除非用户要求深度同步，不要递归扫描源码。

## Step 3：识别模块

目录具有独立构建配置、入口文件、明确领域名称，或局部 `src`/`lib`/`include` 结构时，可标记为候选模块。

排除通用或生成目录：

- `.git`、`.svn`、`.claude`、`.vscode`、`.idea`
- `src`、`lib`、`include`、`tests`、`docs`、`examples`
- `node_modules`、`dist`、`build`、`target`、`__pycache__`
- `assets`、`static`、`public`、`resources`

无法确定时标记为 `possible`，不要编造职责。

## Step 4：写入架构文档

覆盖写入 `.claude/context/architecture.md`：

```markdown
# Architecture

> Last synced: YYYY-MM-DD HH:MM

## Project
- Root: {path}
- VCS: {git/svn/none}
- Active branch: {branch if git}
- Primary stack: {inferred stack}

## Modules
| Path | Status | Evidence | Responsibility |
| --- | --- | --- | --- |
| module-a/ | confirmed | CMakeLists.txt + main.c | {summary} |
| module-b/ | possible | domain name only | {summary or unknown} |

## Key Config Files
- `package.json` - dependency manifest
- `CMakeLists.txt` - build entry

## Dependencies
Only include this section when `--deps` is requested or dependency files changed.

## Recent Structural Changes
- Added/removed/renamed modules compared with previous architecture, if known.
```

如果 `.claude/context/` 不存在，先创建目录。

## Step 5：报告结果

简要说明：

- 架构文件路径
- 已确认模块
- 需要用户确认的候选模块
- 依赖或构建配置变化
