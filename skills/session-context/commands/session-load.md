# Session Load

你是上下文恢复器。目标是在最少读取量下恢复项目状态。

## 1. 选择共享策略和上下文目录

按顺序判断：

1. 已有 `docs/ai-context/.sharing-policy`：使用 `docs/ai-context/`。
2. 已有 `.codex/context/` 或 `.claude/context/`：读取 `.sharing-policy` 并检查 VCS 跟踪或忽略状态。
3. 没有上下文：版本控制项目让用户选择一次“可跨环境”或“仅本机”；无版本控制时使用仅本机并说明限制。

选择可跨环境时使用 `docs/ai-context/`；选择仅本机时使用 `.codex/context/`。用户有最终选择权，不自动 commit 或 push。

Git 项目可把分支任务状态放在 `{context}/branches/{branch}/`；SVN 或物理分支目录只使用当前目录的 `{context}`。

## 2. 初始化（如需要）

若上下文不存在，在用户完成共享策略选择后初始化：

1. 创建 `{context}/reference/` 和 `{context}/tasks/done/`。
2. 创建：
   - `.sharing-policy`
   - `current-task.md`
   - `decisions.md`
   - `pitfalls.md`
   - `architecture.md`
3. 轻量扫描项目顶层结构，记录构建文件、入口文件、主要目录和常用命令。
4. 按策略处理版本控制：可跨环境时确保 `docs/ai-context/` 可被跟踪；仅本机时忽略 `.codex/context/`，兼容旧目录时也忽略 `.claude/context/`。

## 3. 加载顺序

只读取当前任务需要的内容：

1. `{context}/tasks/*.md`
2. `{context}/current-task.md`
3. `{context}/decisions.md` 最近 10 条或末尾约 80 行
4. `{context}/pitfalls.md` 最近 10 条或末尾约 80 行
5. `{context}/architecture.md`
6. `reference/` 中与当前任务相关的文件

如用户指定范围，例如“只看当前任务”，只加载对应内容。

## 4. 同步本轮请求

加载后立即把用户当前请求写入 `current-task.md`：

- 若当前任务未完成：追加到“进行中”或“待完成”。
- 若旧任务已完成：归档旧任务后开启新任务。
- 更新“关键上下文”“下次继续”“关键文件清单”。

## 5. 输出摘要

```markdown
## 上下文已加载

- 上下文目录：`{context}`
- 共享策略：可跨环境 / 仅本机
- 同步状态：已同步 / 待提交 / 待同步 / 仅本机
- 当前任务：{一句话}
- 已完成：{最多 3 条}
- 进行中：{最多 3 条}
- 下次继续：{文件 + 位置 + 动作}
- 关键文件：{最多 5 个}
- 风险/阻塞：{如有}
```

仅本机模式必须补充：“切换开发环境后 AI 无法读取本次进度。”摘要要短，随后继续处理用户的实际请求。
