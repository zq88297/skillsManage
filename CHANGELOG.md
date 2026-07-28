# Changelog

## 2026-07-28 — project-workflow v1.6.0

### Changed
- Required either a clear requirements document or a completed `grill-me` interview before entering solution design.
- Prohibited the workflow from inventing product decisions when requirements are missing, conflicting, or unverifiable.
- Added `grill-me` trace identifiers and log paths to the requirements artifact for decision traceability.
- Declared `grill-me` as a `project-workflow` dependency and added catalog-driven dependency resolution to the Unix installer.

---

## 2026-07-27 — grill-me v1.2.0

### Changed
- Localized the `grill-me` trigger metadata and workflow instructions into Chinese.

### Added
- Added append-only communication traces with stable round and decision identifiers.
- Added decision supersession links, source references, timestamps, and final trace-path reporting.
- Added mandatory redaction for credentials and other sensitive values.
- Added explicit single-choice, multiple-choice, and free-answer question modes with a text fallback when tools only support single selection.

---

## 2026-07-27 — session-context v2.3.1 and project-workflow v1.5.1

### Changed
- Narrowed `session-context` activation to explicit context operations and work that must continue across sessions or environments.
- Narrowed `project-workflow` activation to substantial, multi-stage, ambiguous, or high-risk engineering work.
- Excluded one-shot questions, routine edits, isolated tests, straightforward bugs, and ordinary development commands from both skills.
- Removed obsolete `.bugs/` directory handling guidance from `session-context`.

---

## 2026-07-24 — session-context v2.3.0

### Changed
- Let users choose once between portable, version-controlled context and local-only context.
- Added explicit `已同步`, `待提交`, `待同步`, and `仅本机` handoff states.
- Added warnings when uncommitted or local-only context cannot follow the user to another development environment.
- Prevented credentials and other secrets from being written to any session-context file.
- Updated all session-context commands to use the same sharing policy and sync checks.

---

## 2026-07-06 — Repository v2.0: Complete skill ecosystem

### Added (17 skills)
All skills from `~/.claude/skills/` now cataloged:

**Meta (2):** skill-creator, karpathy-guidelines
**Design (3):** canvas-design (82 fonts), frontend-design, impeccable (v3.9.1, 96 files)
**Documents (4):** docx (61 files), pdf (12 files), pptx (59 files), xlsx (54 files)
**Animation (8):** gsap-core, gsap-frameworks, gsap-performance, gsap-plugins, gsap-react, gsap-scrolltrigger, gsap-timeline, gsap-utils

### Changed
- `skill-catalog.yaml`: Expanded from 3 to 20 skills with detailed layer taxonomy
- `install.ps1`: Updated dependency map for all 20 skills
- `CLAUDE.md`, `README.md`: Full inventory tables
- `.gitignore`: Added `__pycache__/`, `*.pyc`, `*.pyo`

### Assets
- `llms.txt`: GSAP skills index for AI agents
- `session-context.skill`: Packaged ZIP archive

---

## 2026-07-06 — Repository v1.0: Initial custom skills

### Added
- Repository structure: `skills/`, `scripts/`, `shared/`, `adapters/`
- 3 core custom skills: session-context (v2.1.0), project-workflow (v1.3.0), task-orchestrator (v1.1.0)
- `skill-catalog.yaml` with dependency tracking
- PowerShell + Bash scripts: install, sync, validate, new-skill, export-cursor
- Shared hooks and skill templates
- Adapter docs for Cursor, Cline, GitHub Copilot
