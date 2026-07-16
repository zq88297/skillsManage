# 项目工作流状态

汇总当前项目生命周期状态。

## 步骤

1. 定位上下文目录：
   - 优先使用已有 `.codex/context/`。
   - 否则使用已有 `.claude/context/`。
   - 如果两者都不存在，说明当前尚未创建工作流状态。

2. 读取可用产物：
   - `workflow-state.md`
   - `requirements.md`
   - `design.md`
   - `implementation-plan.md`
   - `bugfix-report.md`
   - `project-review.md`

3. 输出：
   - 项目名称
   - 当前阶段和状态
   - 已完成阶段
   - 未决问题或阻塞项
   - 相关文件
   - 下一步具体动作
   - 如果处于实现阶段，说明对抗式审查和三个月运行排查是否已完成
   - 如果处于验收/复盘阶段，说明历史 Bug 数据来源是否明确

## 输出格式

```markdown
**工作流状态**
项目: {名称}
阶段: {阶段}
状态: {状态}
最后更新: {datetime}

已完成:
- {phase or artifact}

未决:
- {question, blocker, or none}

下一步:
- {one concrete action}
```
