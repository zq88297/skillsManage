#!/usr/bin/env bash
# new-skill.sh — Scaffold a new skill in this repository (Unix)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"
CATALOG_FILE="$REPO_ROOT/skill-catalog.yaml"

usage() {
    echo "Usage: new-skill.sh --name <name> --description <desc> [--dependencies dep1,dep2] [--layer foundation|workflow|orchestration]"
    exit 1
}

NAME=""
DESCRIPTION=""
DEPS=""
LAYER="workflow"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --dependencies) DEPS="$2"; shift 2 ;;
        --layer) LAYER="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

if [[ -z "$NAME" ]] || [[ -z "$DESCRIPTION" ]]; then
    usage
fi

# Validate name format
if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
    echo "Error: Name must be lowercase-hyphenated (e.g., 'my-skill')"
    exit 1
fi

if [[ -d "$SKILLS_DIR/$NAME" ]]; then
    echo "Error: Skill '$NAME' already exists"
    exit 1
fi

echo "=== New Skill Scaffold ==="
echo "Name:         $NAME"
echo "Description:  $DESCRIPTION"
echo "Layer:        $LAYER"
echo ""

# Create directories
SKILL_PATH="$SKILLS_DIR/$NAME"
mkdir -p "$SKILL_PATH/commands"

# Generate SKILL.md
TITLE=$(echo "$NAME" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
cat > "$SKILL_PATH/SKILL.md" << EOF
---
name: $NAME
description: "$DESCRIPTION"
---

# $TITLE

TODO: Describe what this skill does and the key behaviors the AI should follow.

## Overview

TODO: High-level description of the skill's purpose and workflow.

## Rules

TODO: Define the rules and behaviors the AI should follow when this skill is active.

## Commands

TODO: List the slash commands this skill provides (if any).

| Command | Purpose |
|---------|---------|
| (none yet) | |

## Dependencies

This skill has no dependencies.

---

*Created: $(date +%Y-%m-%d) | Version: 0.1.0*
EOF

echo "Created: skills/$NAME/SKILL.md"

# Generate DESIGN.md
cat > "$SKILL_PATH/DESIGN.md" << EOF
# $NAME — Design Rationale

## Motivation
TODO: Why was this skill created? What problem does it solve?

## Design Decisions
TODO: Key architectural and behavioral decisions.

## Evolution
TODO: Track major changes and the reasoning behind them.

---

*Created: $(date +%Y-%m-%d)*
EOF

echo "Created: skills/$NAME/DESIGN.md"

echo ""
echo "=== Scaffold Complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit skills/$NAME/SKILL.md — fill in rules and behavior"
echo "  2. Edit skills/$NAME/DESIGN.md — document design rationale"
echo "  3. Add commands to skills/$NAME/commands/"
echo "  4. Update skill-catalog.yaml with commands, keywords, and tags"
echo "  5. Commit: git add skills/$NAME/ && git commit -m 'feat($NAME): add initial implementation'"
