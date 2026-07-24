---
name: session-context
description: "MUST trigger on every coding or project-maintenance conversation in a dev project. Loads and maintains project session memory with user-selected portable or local-only storage: current task, decisions, pitfalls, architecture notes, branch/module context, cross-project and cross-environment handoff, and context health. Trigger on: 修改, 排查, debug, fix, change, investigate, generate, create, 帮我, 实现, 开发, 优化, 重构, 测试, 部署, 编译, 运行, 报错, 失败, 问题, /session-*, /context-*, /task-send, 保存上下文, 加载上下文, 继续工作, 会话接力."
---

# Session Context Management

本技能维护项目上下文，让新会话和新开发环境能快速接续工作。它只记录工程事实、任务状态和可复用经验，不替代代码阅读、测试和用户确认。

## 存储与共享策略

首次初始化时，在使用 Git、SVN 等版本控制的项目中让用户明确选择一次：

1. **可跨环境（推荐）**：使用 `docs/ai-context/`，纳入版本控制，随任务代码一起提交并同步到其他环境可访问的仓库。
2. **仅本机**：使用 `.codex/context/`；兼容已有 `.claude/context/`，并加入 VCS 忽略规则。

规则：

- 用户拥有最终选择权；不要自动提交或推送，除非用户已要求或批准这些 Git/SVN 操作。
- 只询问一次，并把选择写入上下文的 `.sharing-policy`，值为 `portable` 或 `local-only`。
- 已有 `docs/ai-context/` 时优先读取其策略；已有 `.codex/context/` 或 `.claude/context/` 时，先检查是否已被版本控制，再决定沿用或询问是否迁移。
- 用户选择可跨环境时，确保上下文目录未被忽略，并在保存和收尾时检查未提交、未推送或未同步状态。
- 用户选择仅本机时，明确提示：更换开发环境后 AI 无法读取当前进度。不要把它描述为“跨环境接力已就绪”。
- 无版本控制的项目只能使用仅本机模式，并说明可通过用户指定的同步方式迁移。
- 不主动创建新的 `.claude/context/`，除非用户明确要求兼容 Claude 旧项目。
- 后文中的 `{context}` 指已按上述规则选出的目录。

跨环境接力状态分为：

- `已同步`：上下文已纳入版本控制、已提交，且目标环境可以取得该提交。
- `待提交`：上下文已更新但尚未提交。
- `待同步`：已有本地提交，但尚未 push、提交到 SVN 或通过其他方式同步。
- `仅本机`：上下文被忽略或未纳入版本控制。

仅写入文件或仅创建本地 commit，都不等于跨环境接力完成。

推荐文件结构：

```text
{context}/
├── .sharing-policy
├── current-task.md
├── decisions.md
├── pitfalls.md
├── architecture.md
├── reference/
└── tasks/
    └── done/
```

## 禁止行为

- 不自动扫描、导入或处理 `.bugs/` 目录。
- 不要求用户把 Bug 文件放入 `.bugs/`。
- Bug 修复只使用当前对话中用户明确提供的描述、日志、截图、附件或指定路径。
- 不把密码、Token、私钥、Cookie、生产凭据写入 `decisions.md`、`pitfalls.md`、`architecture.md` 或长期 `reference/`。

## 自动加载流程

先理解用户请求，再决定加载范围。

1. 判断任务类型：新需求、修改、Bug、构建、测试、部署、代码解释、上下文命令。
2. 快速识别项目形态：单项目、Git 分支项目、SVN/多目录分支、多模块仓库。
3. 选择上下文目录：
   - 简单项目：加载当前目录 `{context}`。
   - 多模块项目：根据用户请求定位相关模块，只加载相关模块上下文；不递归读取无关模块。
   - Git 项目：默认使用 `{context}/branches/{branch}/` 存放分支任务状态；`architecture.md` 可保留在 `{context}/` 共享。
   - SVN 或物理分支目录：只使用当前工作目录下的 `{context}`。
4. 读取优先级：
   1. `tasks/*.md`：跨项目派发任务。
   2. `current-task.md`：当前任务和继续点。
   3. `decisions.md`：最近决策，优先读末尾近期条目。
   4. `pitfalls.md`：最近踩坑和预防。
   5. `architecture.md`：架构摘要。
   6. `reference/`：仅在当前任务需要时按需读取。
5. 加载后立即把本轮用户请求同步到 `current-task.md`。
6. 报告当前共享策略；可跨环境模式报告同步状态，仅本机模式报告换环境会丢失该进度。

`current-task.md` 模板：

```markdown
> Last updated: YYYY-MM-DD HH:mm

## 已完成
暂无

## 进行中
- [ ] {本轮用户请求}

## 待完成
暂无

## 关键上下文
- {相关模块、文件、约束、环境}

## 下次继续
- 第一步：打开 {文件}，定位到 {函数/位置}，继续 {动作}
- 当前状态：{已完成/未完成/测试状态}

## 关键文件清单
- {path}:{line} - {用途}
```

## 新项目初始化

当选定目录没有上下文文件时，完成一次共享策略选择后直接初始化，不再重复询问：

1. 检测版本控制，并让用户选择“可跨环境”或“仅本机”；无版本控制时说明限制并使用仅本机模式。
2. 创建所选 `{context}/`、`reference/`、`tasks/done/`，写入 `.sharing-policy`。
3. 生成 `current-task.md`、`decisions.md`、`pitfalls.md`。
4. 轻量扫描项目结构，生成或更新 `architecture.md`：
   - 只记录顶层目录、构建文件、入口文件、关键命令和明显模块。
   - 不做全仓库深度代码审计，除非用户请求。
5. 根据选择处理版本控制：
   - 可跨环境：确认 `{context}` 未被忽略；若旧的忽略规则覆盖它，在用户选择该模式后移除或收窄该规则。
   - 仅本机：确保 `.codex/context/` 或兼容的 `.claude/context/` 被忽略。
6. 如存在 `AGENTS.md`、`CLAUDE.md` 或项目说明文件，读取其约定；不要无理由创建重复说明文件。

## 任务同步规则

在以下时机更新 `current-task.md`：

- 加载上下文后记录本轮请求。
- 生成实施计划后，把计划转为 checkbox。
- 完成一个步骤后，移动到“已完成”或打勾。
- 工作中发现新阻塞、关键文件、验证结果或下一步时，写入对应段落。
- 用户说“继续”“还有”“另外”“接下来”时，根据当前任务是否完成决定追加任务或归档旧任务后开启新任务。

任务完成归档：

1. 将稳定技术事实移入 `reference/context-YYYY-MM-DD.md`。
2. 将重要方案选择追加到 `decisions.md`。
3. 将根因、踩坑和预防方式追加到 `pitfalls.md`。
4. 从 `current-task.md` 删除临时凭据和过期任务状态。
5. 为下一轮保留清晰的“下次继续”和“关键文件清单”。

## 决策与踩坑记录

`decisions.md` 只记录会影响后续工作的选择：

```markdown
## D-YYYY-MM-DD-N: {决策标题}
- 背景：{为什么要决策}
- 选择：{最终方案}
- 理由：{关键依据}
- 放弃：{未采用方案及原因}
- 影响：{兼容性、迁移、风险、回滚}
```

`pitfalls.md` 记录已发生问题和预防：

```markdown
## P-YYYY-MM-DD-N: {问题标题}
- 现象：{报错/异常/失败表现}
- 根因：{可验证原因}
- 修复：{采取的动作}
- 验证：{如何确认}
- 预防：{提示词、流程、测试、监控或代码结构优化}
```

Bug 修复复盘时，额外总结：

- 历史同类 Bug 是否重复出现。
- 经常出错的 Bug 类型。
- 减少该类 Bug 的优化手段，例如提示词约束、流程检查点、测试模板、代码审查清单、监控告警或自动化校验。

## 上下文健康检查

持续监控以下信号：

- 出现 conversation summary 或上下文压缩。
- 路径、函数、变量、决策开始记不准。
- 重复读取已读文件。
- 用户多次纠正同一类事实。
- 单轮读入大量日志或代码。
- `current-task.md` 明显落后于当前工作。

轻微风险：提示保存 checkpoint。严重风险：建议 `/session-save` 后开新会话，并把“下次继续”和“关键文件清单”写完整。准备换开发环境时，还必须检查共享策略和同步状态。

## 上下文瘦身

- `current-task.md` 完整读取和覆盖更新。
- `decisions.md`、`pitfalls.md` 默认只读取最近 10 条或末尾约 80 行。
- 超过 200 行时提示归档旧条目到 `decisions-archive.md`、`pitfalls-archive.md`。
- `reference/` 只按当前任务需要读取，不在每次加载时全量读入。

## 多模块与跨项目

多模块项目：

- 只在根目录维护模块索引和架构摘要。
- 模块有独立构建配置、入口文件或清晰职责时，可拥有自己的 `{context}`。
- 新增/删除模块时，提示是否更新 `architecture.md`。
- 不跨模块读上下文，除非当前任务需要或用户指定。

跨项目派发：

- `/task-send <路径>` 是首选方式。
- 在目标项目的上下文目录创建 `tasks/from-{source}-{date}-{summary}.md`。
- 来源项目在 `current-task.md` 记录派发状态。
- 如果当前会话直接帮目标项目排查，必须回写目标任务文件的排查记录，避免下个会话重复劳动。

## 远程调试与敏感信息

- 密码、Token、私钥、Cookie、临时账号等敏感信息不得写入任何上下文文件，包括 `current-task.md`。
- 敏感信息只保留在用户批准的凭据管理器、环境变量或会话内存中；上下文只记录变量名或获取方式，不记录值。
- 归档只保留非敏感技术事实，例如设备类型、拓扑、调试方式和验证命令。

## 提交与跨环境接力

在 `/session-save`、`/session-end` 或用户准备切换开发环境时：

1. 先更新上下文并检查敏感信息。
2. 检查 `.sharing-policy` 和 VCS 状态。
3. 可跨环境模式下，让用户决定是否把上下文纳入本次提交；不要擅自 commit 或 push。
4. 用户选择提交时，把上下文与对应代码改动放在同一个任务提交中，或使用独立的 `docs(session-context): ...` 提交。
5. 检查目标环境能否取得该提交；未 push 或未同步时状态仍是“待同步”。
6. 用户选择不提交时保留文件，但明确输出“仅当前环境可恢复；切换环境后 AI 不知道最新进度”。

## 命令

命令详细流程在 `commands/` 下：

- `/session-load`：加载或初始化上下文。
- `/session-save`：保存当前进度、决策和踩坑。
- `/session-end`：结束会话前做健康检查和收尾保存。
- `/context-check`：输出上下文健康报告。
- `/context-sync`：同步架构摘要。
- `/task-send <路径>`：向其他项目或模块派发任务。
