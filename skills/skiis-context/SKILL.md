---
name: skiis-context
description: Persist coding-session memory in SKIIS `docs/ai-context/` markdown files. Use when Codex needs to load or save work progress across sessions, continue a previous coding task, initialize a new project's AI context, record technical decisions or pitfalls, sync architecture notes, dispatch cross-project debugging tasks, or manage parallel task claims/results. Trigger on explicit SKIIS commands such as session-load, session-save, session-end, context-check, context-sync, task-send, or Chinese equivalents like 保存进度, 加载上下文, 继续工作, 健康检查, 架构同步, 派发任务.
---

# SKIIS Context

Use SKIIS to preserve task progress, decisions, pitfalls, and cross-project debugging state in plain markdown under `docs/ai-context/`.

## First Move

Understand the user's request before loading context. Do a cheap top-level scan first, then load only the context needed for the current task.

1. Detect the context path:
   - Git repo: use `git rev-parse --abbrev-ref HEAD`; read/write branch context under `docs/ai-context/{branch}/`. Keep shared `architecture.md` at `docs/ai-context/architecture.md`.
   - SVN repo or plain directory: read/write `docs/ai-context/` in the current working directory only.
2. If the context directory exists, read `current-task.md`, recent `decisions.md`, recent `pitfalls.md`, pending `tasks/*.md`, and unmerged `tasks/results/*.result.md` as needed.
3. If the context directory is missing for a coding project, initialize it before continuing. Prefer running `scripts/init_context.py --root <project>` from this skill.
4. In large multi-module repos, list only the current directory's first-level entries first. Pick the relevant module from the user's request before reading module context.

When writing or initializing context files, read `references/context-format.md` for exact templates and append/overwrite rules.

## Core Files

- `current-task.md`: overwrite with the current task state, checkboxes, concrete next step, constraints, blockers, and key context.
- `decisions.md`: append technical decisions only. Use IDs like `D2026-06-02-1`.
- `pitfalls.md`: append bug roots, failure modes, and fixes only. Use IDs like `P2026-06-02-1`.
- `architecture.md`: overwrite when syncing architecture.
- `tasks/`: store cross-project or cross-module debugging tasks.
- `tasks/claims/`: store task claim files before parallel work starts.
- `tasks/results/`: store independent parallel task outputs, then merge them during load or planning.

## Session Load

On "load context", "continue", `session-load`, or similar:

1. Resolve the active SKIIS context path.
2. If missing, initialize it.
3. Prefer the `## 下次继续` / `## Next Continue` section from `current-task.md`.
4. Summarize only the relevant recent decisions and pitfalls.
5. Surface pending inbound tasks from `tasks/*.md`.
6. If `tasks/results/*.result.md` exists, merge results into `current-task.md`, append decision/pitfall records when present, and move merged results to `tasks/results/merged/`.

## Session Save

On "save progress", `session-save`, before ending a long session, or after a substantial plan:

1. Overwrite `current-task.md`.
2. Include completed, in-progress, and pending checkbox sections.
3. Always include a concrete next-continue block:
   - First step: exact file, function/area, and action.
   - Current state: build/test/runtime status.
   - Constraints: non-negotiable requirements.
   - Blockers: items waiting on user, external systems, or missing information.
4. Append to `decisions.md` if a technical choice was made.
5. Append to `pitfalls.md` if a bug, failure, or workaround was discovered.

## Auto Reminders

Prompt the user to archive work when these happen:

- Bug fixed: ask whether to append root cause and fix to `pitfalls.md`.
- Technical decision made: ask whether to append to `decisions.md`.
- Feature/module completed: ask whether to update `current-task.md`.
- Multi-step plan created: convert it to checkboxes in `current-task.md`.
- Toolchain/dependency installed or changed: record the choice in `decisions.md`; record install failures in `pitfalls.md`.
- Long or unstable conversation: remind the user to save progress, especially after roughly 15 back-and-forth turns.

## Cross-Project Tasks

When the user asks to send a task to another project/module:

1. Confirm or infer the target path. Ask only if the path is ambiguous.
2. Initialize the target context if missing.
3. Create `tasks/from-{source}-{date}.md` in the target context with problem background, source-to-target interaction, known clues, related files, and an investigation checklist.
4. Update the source `current-task.md` with the dispatched task path.
5. If this session investigates the target directly, always write progress back to the target task file. Move it to `tasks/done/` when complete or excluded.

## Parallel Work

When a plan has two or more steps:

1. Classify each step as serial or parallel.
2. Treat edits to the same file/function or output dependencies as serial.
3. Treat different modules, different projects, and read-only tasks as parallel.
4. Limit concurrent sessions/tasks to 3.
5. Before starting a parallel task, create `tasks/claims/{task-id}.claim`.
6. On completion, write `tasks/results/{task-id}.result.md` instead of directly competing for shared files.

## Context Sync

On `context-sync`, architecture changes, new top-level modules, or dependency/build config changes:

1. Scan first-level directories and project config files.
2. Identify likely modules by independent build files, main entry points, meaningful module names, or local `src`/`lib`/`include` structure.
3. Exclude generic or generated directories such as `.git`, `.svn`, `src`, `tests`, `docs`, `node_modules`, `dist`, `build`, `target`, and `__pycache__`.
4. Overwrite `architecture.md` with module list, project type hints, key config files, and recent structural changes.

## Script

Run the initializer when deterministic setup is useful:

```bash
python <skill-dir>/scripts/init_context.py --root <project-path>
```

Useful options:

- `--sync-architecture`: rewrite `architecture.md`.
- `--update-gitignore`: add `docs/ai-context/` to `.gitignore` in Git repos.
- `--plain-context`: ignore Git branch isolation and use `docs/ai-context/` directly.
