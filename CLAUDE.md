# CLAUDE.md — Skills Management Repository

## Purpose
Central version-controlled repository for ALL Claude Code skills (21 skills, 400+ files).
Source of truth — install the complete skill ecosystem into any project with one command.

## Repository Conventions

### Skill Structure
```
skills/<name>/
├── SKILL.md          # Required: YAML frontmatter (name, description) + Markdown body
├── LICENSE.txt       # Optional: License file
├── DESIGN.md         # Optional: Design rationale (custom skills only)
├── commands/         # Optional: Slash commands (.md files)
├── scripts/          # Optional: Executable scripts (Python, JS)
├── references/       # Optional: Reference docs loaded on demand
├── assets/           # Optional: Templates, icons, fonts
├── agents/           # Optional: Sub-agent definitions
└── canvas-fonts/     # Optional: Design fonts (canvas-design)
```

### Naming
- Skill directories: `lowercase-hyphenated` (e.g., `session-context`, `gsap-core`)
- SKILL.md `name` field must match directory name

### Commit Format
```
<type>(<skill-name>): <description>
Types: feat, fix, docs, refactor, chore
```

### Versioning
Each skill has its own semver in `skill-catalog.yaml`.

---

## Complete Skill Inventory (20 skills)

| # | Skill | Layer | Version | Has Dependencies | Special Resources |
|---|-------|-------|---------|-----------------|-------------------|
| 1 | session-context | foundation | 2.1.0 | — | 6 commands |
| 2 | skill-creator | meta | 1.0.0 | — | scripts/, agents/, assets/, eval-viewer/ |
| 3 | karpathy-guidelines | meta | 1.0.0 | — | — |
| 4 | canvas-design | design | 1.0.0 | — | canvas-fonts/ (82 fonts) |
| 5 | frontend-design | design | 1.0.0 | — | — |
| 6 | impeccable | design | 3.9.1 | — | reference/ (28 docs), scripts/ (70+ tools) |
| 7 | docx | documents | 1.0.0 | — | scripts/ (52 files, OOXML schemas) |
| 8 | pdf | documents | 1.0.0 | — | scripts/ (8 Python), forms.md, reference.md |
| 9 | pptx | documents | 1.0.0 | — | scripts/ (47 files), editing.md, pptxgenjs.md |
| 10 | xlsx | documents | 1.0.0 | — | scripts/ (46 files, OOXML schemas) |
| 11 | gsap-core | animation | 1.0.0 | — | — |
| 12 | gsap-frameworks | animation | 1.0.0 | — | — |
| 13 | gsap-performance | animation | 1.0.0 | — | — |
| 14 | gsap-plugins | animation | 1.0.0 | — | — |
| 15 | gsap-react | animation | 1.0.0 | — | — |
| 16 | gsap-scrolltrigger | animation | 1.0.0 | — | — |
| 17 | gsap-timeline | animation | 1.0.0 | — | — |
| 18 | gsap-utils | animation | 1.0.0 | — | — |
| 19 | project-workflow | workflow | 1.3.0 | → session-context | 3 commands, agents/ |
| 20 | task-orchestrator | workflow | 1.1.0 | → session-context | 2 commands |
| 21 | skills-manager | meta | 1.0.0 | — | 3 commands |

**Dependency chain:** Only `project-workflow` and `task-orchestrator` have dependencies (both → `session-context`). All other 18 skills are independent.

---

## Common Operations

### Installing skills to a project

```bash
# Linux/macOS — Full install (all 20 skills)
bash ./scripts/install.sh /path/to/project

# Linux/macOS — Selective install
bash ./scripts/install.sh /path/to/project --skills project-workflow,gsap-core

# Linux/macOS — With hooks
bash ./scripts/install.sh /path/to/project --with-hooks
```

```powershell
# Windows — Full install (all 20 skills)
.\scripts\install.ps1 -TargetPath F:\MyProject

# Windows — Selective install
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow,gsap-core

# Windows — With hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

### Syncing (from live installation to repo)

```bash
# Linux/macOS — Preview changes
bash ./scripts/sync-from-source.sh --dry-run

# Linux/macOS — Pull and auto-commit
bash ./scripts/sync-from-source.sh --auto-commit --force
```

```powershell
# Windows — Preview changes
.\scripts\sync-from-source.ps1 -DryRun

# Windows — Pull and auto-commit
.\scripts\sync-from-source.ps1 -AutoCommit -Force
```

### Creating a new skill

```bash
# Linux/macOS
bash ./scripts/new-skill.sh --name "my-skill" --description "Does X when Y"
```

```powershell
# Windows
.\scripts\new-skill.ps1 -Name "my-skill" -Description "Does X when Y" -Dependencies session-context
```

### Validating

```bash
# Linux/macOS
bash ./scripts/validate.sh   # if available, otherwise use PowerShell
```

```powershell
# Windows
.\scripts\validate.ps1
```

### Exporting for other agents

```powershell
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject
```

### Slash Commands (skills-manager)

| Command | Purpose |
|---------|---------|
| `/skills-status` | Check health of repo, source, and current project |
| `/skills-sync` | Pull updates from ~/.claude/skills/ → repo → push |
| `/skills-install` | Install skills from repo to current project |

---

## Key Files
- `skill-catalog.yaml` — Complete manifest: 20 skills, versions, layers, dependencies
- `skills/*/SKILL.md` — Canonical skill definitions (400+ total files)
- `scripts/install.ps1` / `scripts/install.sh` — Deploy with dependency resolution (Windows / Unix)
- `scripts/sync-from-source.ps1` / `scripts/sync-from-source.sh` — Pull from live `~/.claude/skills/` into repo (Windows / Unix)
- `scripts/sync.ps1` — Bidirectional sync with backup (Windows)
- `llms.txt` — GSAP skills index for AI agents
- `session-context.skill` — Packaged skill archive (ZIP format)
