# CLAUDE.md — Skills Management Repository

## Purpose
Central version-controlled repository for Claude Code custom skills.
Source of truth for all managed skills — install them into any project with one command.

## Repository Conventions

### Skill Structure
```
skills/<name>/
├── SKILL.md          # Required: YAML frontmatter (name, description) + Markdown instructions
├── DESIGN.md         # Optional: Design rationale and evolution notes
├── commands/         # Optional: Slash commands as .md files
│   ├── command-1.md
│   └── command-2.md
└── agents/           # Optional: Agent-specific configuration (e.g., OpenAI)
```

### Naming
- Skill directories: `lowercase-hyphenated` (e.g., `session-context`)
- Command files: `lowercase-hyphenated.md` (e.g., `context-check.md`)
- SKILL.md `name` field must match directory name

### Commit Format
Conventional commits scoped to skill name:
```
<type>(<skill-name>): <description>

Types: feat, fix, docs, refactor, chore
Examples:
  feat(session-context): add Rule 4.8 for layered context
  fix(task-orchestrator): handle empty task queue
  docs(project-workflow): update workflow-status output format
```

### Versioning
Each skill has its own semver in `skill-catalog.yaml`. Per-skill tags:
```
v<version>-<skill-name>
Example: v2.1.0-session-context
```

## Skill Inventory

| Skill | Layer | Version | Dependencies | Commands |
|-------|-------|---------|--------------|----------|
| session-context | foundation | 2.1.0 | — | context-check, context-sync, session-end, session-load, session-save, task-send |
| project-workflow | workflow | 1.3.0 | session-context | workflow-start, workflow-status, workflow-review |
| task-orchestrator | orchestration | 1.1.0 | session-context | task-plan, task-run |

**Dependency chain:** `task-orchestrator` → `session-context`, `project-workflow` → `session-context`

## Common Operations

### Installing skills to a project
```powershell
# Full install (all skills)
.\scripts\install.ps1 -TargetPath F:\MyProject

# Selective install with auto-dependency resolution
.\scripts\install.ps1 -TargetPath F:\MyProject -Skills project-workflow

# With hooks
.\scripts\install.ps1 -TargetPath F:\MyProject -WithHooks
```

### Syncing skills
```powershell
# Check for differences
.\scripts\sync.ps1 -TargetPath F:\MyProject -DryRun

# Pull updates from repo to project
.\scripts\sync.ps1 -TargetPath F:\MyProject

# Push field improvements back to repo
.\scripts\sync.ps1 -TargetPath F:\MyProject -Mode Push
```

### Creating a new skill
```powershell
.\scripts\new-skill.ps1 -Name "my-skill" -Description "Does X when user asks Y" -Dependencies session-context
# Then: edit SKILL.md, add commands, update catalog
```

### Validating
```powershell
.\scripts\validate.ps1
```

### Exporting for other agents
```powershell
# Export all skills as Cursor rules
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject
```

## When to Update Skills
- Found a workflow pattern worth codifying → new skill
- Skill triggers too often / not often enough → tune `description` frontmatter
- Fixed a bug that others will hit → add to `pitfalls.md` pattern in skill
- Made a technology choice worth remembering → document in skill rules

## Key Files
- `skill-catalog.yaml` — Manifest: versions, dependencies, commands, keywords, tags
- `skills/*/SKILL.md` — Canonical skill definitions
- `scripts/install.ps1` — Primary deployment tool (PowerShell)
- `scripts/install.sh` — Primary deployment tool (Unix)
- `scripts/sync.ps1` — Bidirectional sync
- `shared/hooks/` — Reusable hook infrastructure deployed with any project
