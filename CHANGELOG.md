# Changelog

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
