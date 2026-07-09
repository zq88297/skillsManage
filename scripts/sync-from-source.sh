#!/usr/bin/env bash
# sync-from-source.sh — Sync skills FROM live Claude Code installation INTO this repo (Unix)
#
# Compares ~/.claude/skills/ against skills/, copies changes, optionally auto-commits.
#
# Usage:
#   ./sync-from-source.sh [options]
#
# Options:
#   --source <path>   Source skills directory (default: ~/.claude/skills/)
#   --dry-run         Show what would change without making changes
#   --auto-commit     Auto-commit with generated message
#   --force           Skip confirmation prompt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEST_SKILLS_DIR="$REPO_ROOT/skills"
CATALOG_FILE="$REPO_ROOT/skill-catalog.yaml"

# --- Defaults ---
SOURCE_PATH="$HOME/.claude/skills"
AUTO_COMMIT=false
DRY_RUN=false
FORCE=false

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --auto-commit)
            AUTO_COMMIT=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Usage: sync-from-source.sh [options]"
            echo ""
            echo "Options:"
            echo "  --source <path>   Source skills directory (default: ~/.claude/skills/)"
            echo "  --dry-run         Preview changes without applying"
            echo "  --auto-commit     Auto-commit with generated message"
            echo "  --force           Skip confirmation prompt"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# --- Validate source ---
if [[ ! -d "$SOURCE_PATH" ]]; then
    echo "Error: Source skills directory not found: $SOURCE_PATH"
    echo "Are you sure Claude Code is installed?"
    exit 1
fi

echo "=== Sync from Source ==="
echo "Source: $SOURCE_PATH"
echo "Repo:   $DEST_SKILLS_DIR"
if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN — no changes will be made"
fi
echo ""

# --- Compute directory hash (all files combined SHA256) ---
get_skill_hash() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo ""
        return
    fi
    # Sort files, hash each, combine
    local combined=""
    while IFS= read -r -d '' file; do
        local rel="${file#"$dir"/}"
        local h
        h=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
        combined+="$rel:$h"$'\n'
    done < <(find "$dir" -type f -print0 | sort -z)
    echo "$combined" | sha256sum | cut -d' ' -f1
}

# --- Collect source skills (dirs with SKILL.md) ---
declare -A source_skills
while IFS= read -r -d '' dir; do
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]]; then
        source_skills["$name"]="$dir"
    fi
done < <(find "$SOURCE_PATH" -maxdepth 1 -mindepth 1 -type d -print0)

# --- Collect repo skills ---
declare -A repo_skills
if [[ -d "$DEST_SKILLS_DIR" ]]; then
    while IFS= read -r -d '' dir; do
        name=$(basename "$dir")
        repo_skills["$name"]="$dir"
    done < <(find "$DEST_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)
fi

# --- Compare ---
new_skills=()
modified_skills=()
identical_skills=()

# Get all unique skill names
all_names=()
for name in "${!source_skills[@]}"; do all_names+=("$name"); done
for name in "${!repo_skills[@]}"; do
    [[ -z "${source_skills[$name]+x}" ]] && all_names+=("$name")
done

# Sort names
IFS=$'\n' sorted_names=($(sort <<< "${all_names[*]}")); unset IFS

for name in "${sorted_names[@]}"; do
    in_source=$([[ -n "${source_skills[$name]+x}" ]] && echo true || echo false)
    in_repo=$([[ -n "${repo_skills[$name]+x}" ]] && echo true || echo false)

    if [[ "$in_source" == true ]] && [[ "$in_repo" == false ]]; then
        new_skills+=("$name")
    elif [[ "$in_source" == true ]] && [[ "$in_repo" == true ]]; then
        src_hash=$(get_skill_hash "${source_skills[$name]}")
        repo_hash=$(get_skill_hash "${repo_skills[$name]}")
        if [[ "$src_hash" != "$repo_hash" ]]; then
            modified_skills+=("$name")
        else
            identical_skills+=("$name")
        fi
    fi
done

# --- Report ---
total_changes=$(( ${#new_skills[@]} + ${#modified_skills[@]} ))

if [[ $total_changes -eq 0 ]]; then
    echo "All skills are in sync. Nothing to do."
    exit 0
fi

if [[ ${#new_skills[@]} -gt 0 ]]; then
    echo "NEW (${#new_skills[@]} skills):"
    for name in "${new_skills[@]}"; do
        count=$(find "${source_skills[$name]}" -type f | wc -l | tr -d ' ')
        echo "  + $name ($count files)"
    done
fi
if [[ ${#modified_skills[@]} -gt 0 ]]; then
    echo "MODIFIED (${#modified_skills[@]} skills):"
    for name in "${modified_skills[@]}"; do
        echo "  ~ $name"
    done
fi
echo "IDENTICAL (${#identical_skills[@]} skills)"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi

# --- Confirm ---
if [[ "$FORCE" != true ]] && [[ "$AUTO_COMMIT" != true ]]; then
    read -rp "Sync these changes into the repo? [y/N] " response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# --- Apply ---
BACKUP_DIR="$REPO_ROOT/.sync-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy new skills
for name in "${new_skills[@]}"; do
    cp -r "${source_skills[$name]}" "$DEST_SKILLS_DIR/$name"
    echo "  Copied: $name"
done

# Update modified skills (backup old first)
for name in "${modified_skills[@]}"; do
    cp -r "${repo_skills[$name]}" "$BACKUP_DIR/$name"
    rm -rf "${repo_skills[$name]}"
    cp -r "${source_skills[$name]}" "${repo_skills[$name]}"
    echo "  Updated: $name"
done

echo "Backup at: $BACKUP_DIR"

# --- Auto-commit ---
if [[ "$AUTO_COMMIT" == true ]]; then
    cd "$REPO_ROOT"
    COMMIT_MSG="sync: pull updates from live installation"$'\n\n'
    if [[ ${#new_skills[@]} -gt 0 ]]; then
        COMMIT_MSG+="Added: $(IFS=', '; echo "${new_skills[*]}")"$'\n'
    fi
    if [[ ${#modified_skills[@]} -gt 0 ]]; then
        COMMIT_MSG+="Modified: $(IFS=', '; echo "${modified_skills[*]}")"$'\n'
    fi

    # Update catalog timestamp
    if [[ -f "$CATALOG_FILE" ]]; then
        TODAY=$(date +%Y-%m-%d)
        sed -i "s/last_updated: \".*\"/last_updated: \"$TODAY\"/" "$CATALOG_FILE"
    fi

    git add -A
    git commit -m "$COMMIT_MSG"
    echo ""
    echo "Committed: $COMMIT_MSG"
    echo "Run 'git push' to push changes to remote."
fi

echo ""
echo "=== Sync Complete ==="
