# SKIIS Context Format

Use these formats when creating or updating `docs/ai-context/` files.

## Directory Layout

Git branch-isolated layout:

```text
docs/ai-context/
├── architecture.md
├── {branch}/
│   ├── current-task.md
│   ├── decisions.md
│   ├── pitfalls.md
│   └── tasks/
│       ├── claims/
│       ├── done/
│       ├── queue/
│       └── results/
```

SVN/plain layout:

```text
docs/ai-context/
├── current-task.md
├── decisions.md
├── pitfalls.md
├── architecture.md
└── tasks/
    ├── claims/
    ├── done/
    ├── queue/
    └── results/
```

## Update Rules

- Overwrite `current-task.md`.
- Overwrite `architecture.md`.
- Append to `decisions.md`.
- Append to `pitfalls.md`.
- Create task, claim, and result files per task; do not append unrelated task history to `current-task.md`.

## current-task.md

```markdown
> 最后更新: {YYYY-MM-DD HH:mm}

# 当前任务

## 已完成
- [x] {completed item}

## 进行中
- [ ] {active item} - {status detail}

## 待完成
- [ ] {pending item}

## 下次继续
### 第一步
打开 {file}，在 {function-or-section} 中 {specific action}

### 当前状态
{build/test/runtime status}

### 关键约束
{non-negotiable requirements}

### 阻塞项
{blocked item, or "无"}

## 关键上下文
- {file/interface/dependency/decision}
```

The first step must be concrete enough that a fresh session can start immediately.

## decisions.md

```markdown
# 技术决策记录

## D{YYYY-MM-DD}-{N}: {title}
- **背景**: {why the decision was needed}
- **选项**: {considered options}
- **选择**: {chosen option}
- **原因**: {why this option}
- **明确拒绝**: {rejected options and reasons}
- **取舍**: {tradeoffs}
```

Increment `{N}` by scanning existing decision IDs for the same date.

## pitfalls.md

```markdown
# 踩坑记录

## P{YYYY-MM-DD}-{N}: {title}
- **现象**: {symptom}
- **根因**: {root cause}
- **解决**: {fix or workaround}
- **命令**: `{useful command or diff reference}`
- **预防**: {how to avoid repeat failure}
```

Increment `{N}` by scanning existing pitfall IDs for the same date.

## Cross-Project Task

```markdown
# 来自「{source project}」的排查任务

> 派发时间: {YYYY-MM-DD HH:mm} | 来源: {source path}

## 问题背景
{what happened in the source project}

## 交互关系
- 调用方式: {API/socket/shared memory/etc.}
- 关键接口: {interfaces/functions}
- 数据流: {inputs and outputs}

## 排查范围
- [ ] {check item}

## 已知线索
{logs, observations, packet captures, stack traces, return values}

## 相关文件
- `{path}`: {why it matters}

## 排查记录
```

When the task is partially investigated, append dated entries under `## 排查记录`. When complete or excluded, append the conclusion and move the task file to `tasks/done/`.

## Parallel Claim

```markdown
# Task Claim: {task-id}

- Started: {YYYY-MM-DD HH:mm}
- Session: {session identifier}
- Task: {short title}
- Files: {expected file list}
- Status: in-progress
```

## Parallel Result

```markdown
# 任务结果: {task title}

- 完成时间: {YYYY-MM-DD HH:mm}
- 执行会话: {session identifier}
- 修改的文件: {files}

## 结果摘要
{summary}

## 决策记录
{decision entries, if any}

## 踩坑记录
{pitfall entries, if any}
```
