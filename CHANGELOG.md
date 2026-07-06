# Changelog

All notable changes to managed skills are documented in this file.
Versions track individual skill changes, not repository versions.

---

## [session-context v2.1.0] - 2026-07-06

### Initial cataloged version

The session-context skill provides automatic context management for every
dev-project conversation. This is the foundation layer that other skills depend on.

**Capabilities:**
- **Rule 0 (Smart Load):** Understands question first, then loads relevant context
- **Rule 1:** Auto-load context on session start
- **Rule 2:** Detect architecture changes, suggest context sync
- **Rule 3:** Self-diagnose context window health (token pressure, accuracy drift)
- **Rule 4:** Auto-archive work products (bug fixes, decisions, completed modules)
- **Rule 4.01:** Auto-detect and process bug files in `.bugs/`
- **Rule 4.5:** Auto-sync execution plans into `current-task.md`
- **Rule 4.51:** Auto-capture new tasks on session-internal task switches
- **Rule 4.55:** Critical File Manifest for cross-session handoff
- **Rule 4.6:** Auto-record build environment installs
- **Rule 4.65:** Safe remote device credential management
- **Rule 4.7:** Cross-project task dispatch with structured task files
- **Rule 4.8:** Hierarchical context for monorepos with submodule auto-detection
- **Rule 5:** Auto-initialization of `.claude/context/` on first encounter
- **Rule 6:** Auto-repair of missing hooks
- **Rule 6.5:** File slimming (archive old decisions/pitfalls, load only recent)
- **Rule 7:** Branch-aware context isolation (SVN directories + Git branch subdirectories)

**6 commands:** context-check, context-sync, session-end, session-load, session-save, task-send

**Source:** User-level `~/.claude/skills/session-context/SKILL.md` (913 lines)
**Supplements:** DESIGN.md, context-sync.md from SKIIS project

---

## [project-workflow v1.3.0] - 2026-07-06

### Initial cataloged version

5-phase project lifecycle manager that orchestrates workflows from requirements
through acceptance.

**Capabilities:**
- 5-phase lifecycle with user confirmation at each stage gate
- Fast-track mode for user-provided requirements/design documents
- Bug-fix automation: monitors `.bugs/`, auto-extracts archives, clusters by root cause
- Frontend auto-beautification integration with frontend-design skill
- Workflow state persisted to `.claude/context/workflow-state.md`

**3 commands:** workflow-start, workflow-status, workflow-review

**Source:** User-level `~/.claude/skills/project-workflow/SKILL.md`
**Supplements:** agents/openai.yaml from SKIIS project

---

## [task-orchestrator v1.1.0] - 2026-07-06

### Initial cataloged version

Parallel task scheduler with dependency analysis and multi-session orchestration.

**Capabilities:**
- Auto-analysis: every multi-step plan gets a parallel execution analysis
- Dependency detection: file conflicts, function conflicts, output dependencies
- Concurrency model: max 3 parallel sessions, claim locks, zombie detection
- Result merging: per-task result files, merged on `/session-load`
- Cross-project task execution via `claude -p`

**2 commands:** task-plan, task-run

**Source:** User-level `~/.claude/skills/task-orchestrator/SKILL.md`

---

## Repository

### 2026-07-06 — Initial setup

- Created monorepo structure: `skills/`, `scripts/`, `shared/`, `adapters/`
- Added `skill-catalog.yaml` manifest with dependency tracking
- `install.ps1` / `install.sh` — skill deployment with dependency resolution
- `sync.ps1` — bidirectional sync with backup
- `validate.ps1` — structure and integrity validation
- `new-skill.ps1` / `new-skill.sh` — skill scaffolding
- `export-cursor.ps1` — Cursor .cursorrules export
- Shared hooks infrastructure in `shared/hooks/`
- Adapter stubs for Cursor, Cline, GitHub Copilot
