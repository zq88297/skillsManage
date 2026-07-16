# CLAUDE.md — Skills Management Repository

## Purpose
Central version-controlled repository for managed Claude Code skills.
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

## Complete Skill Inventory

Use `skill-catalog.yaml` as the source of truth for skill names, versions,
layers, dependencies, and install order. Do not maintain a second hand-written
inventory in this file.

---

## Common Operations

### Installing skills to a project

```bash
# Linux/macOS — Full install
bash ./scripts/install.sh /path/to/project

# Linux/macOS — Selective install
bash ./scripts/install.sh /path/to/project --skills project-workflow,gsap-core

# Linux/macOS — With hooks
bash ./scripts/install.sh /path/to/project --with-hooks
```

```powershell
# Windows — Full install
.\scripts\install.ps1 -TargetPath F:\MyProject

# Windows — Selective install
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow,gsap-core

# Windows — With hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

### Syncing (from repository to local skills)

```bash
# Linux/macOS — Preview changes
bash ./scripts/sync-from-source.sh --dry-run

# Linux/macOS — Apply updates
bash ./scripts/sync-from-source.sh --force
```

```powershell
# Windows — Preview changes
.\scripts\sync-from-source.ps1 -DryRun

# Windows — Apply updates
.\scripts\sync-from-source.ps1 -Force
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

### Skill Sync

`skills-sync` checks whether the repository has newer or missing skills and
updates the local installed skills from the repository. It does not push local
changes back to the repo and does not auto-commit.

---

## Key Files
- `skill-catalog.yaml` — Complete manifest: skills, versions, layers, dependencies
- `skills/*/SKILL.md` — Canonical skill definitions (400+ total files)
- `scripts/install.ps1` / `scripts/install.sh` — Deploy with dependency resolution (Windows / Unix)
- `scripts/sync-from-source.ps1` / `scripts/sync-from-source.sh` — Update local installed skills from this repo (Windows / Unix)
- `scripts/sync.ps1` — Update target project/global skills from this repo with backup (Windows)
- `llms.txt` — GSAP skills index for AI agents
- `session-context.skill` — Packaged skill archive (ZIP format)
