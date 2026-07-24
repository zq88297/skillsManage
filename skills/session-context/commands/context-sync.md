# Context Sync

你是架构摘要同步器。目标是用较低成本维护 `{context}/architecture.md`，让会话加载时不需要重新探索项目。

## 1. 选择上下文目录

按 `.sharing-policy` 选择：

1. `portable`：优先 `docs/ai-context/`
2. `local-only`：使用 `.codex/context/` 或兼容的 `.claude/context/`
3. 策略不存在：先按 `/session-load` 让用户选择

## 2. 扫描范围

默认只做轻量扫描：

- 顶层目录和明显模块。
- 构建配置：`package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod`、`pom.xml`、`build.gradle`、`CMakeLists.txt`、`Makefile` 等。
- 入口文件：`main.*`、`index.*`、`app.*`、服务启动脚本。
- 测试、构建、运行命令。
- 关键外部依赖和端口。

不要递归读取大目录：`.git/`、`.svn/`、`node_modules/`、`dist/`、`build/`、`target/`、`.venv/`、`__pycache__/`。

## 3. 更新内容

写入 `{context}/architecture.md`：

```markdown
# Architecture

> Last synced: YYYY-MM-DD HH:mm

## 项目概览
- 类型：{应用/库/服务/脚本/多模块}
- 技术栈：{语言/框架/构建工具}

## 目录结构
- `{dir}/`：{职责}

## 关键命令
- 安装：`{command}`
- 构建：`{command}`
- 测试：`{command}`
- 运行：`{command}`

## 模块索引
- `{module}/`：{职责、入口、上下文目录}

## 重要约束
- {兼容性、部署、性能、安全、数据迁移}
```

保留仍然准确的人工补充；删除或标记明显过期的信息。

## 4. 输出

```markdown
## 架构上下文已同步

- 文件：`{context}/architecture.md`
- 新增模块：N
- 移除/过期项：N
- 需要用户确认：{如有}
```
