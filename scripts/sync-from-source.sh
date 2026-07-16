#!/usr/bin/env bash
# sync-from-source.sh — update locally installed skills from this repository.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_SKILLS_DIR="$REPO_ROOT/skills"

if [[ -n "${CODEX_HOME:-}" ]]; then
  LOCAL_SKILLS_DIR="$CODEX_HOME/skills"
elif [[ -d "$HOME/.codex/skills" ]]; then
  LOCAL_SKILLS_DIR="$HOME/.codex/skills"
else
  LOCAL_SKILLS_DIR="$HOME/.claude/skills"
fi

DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source|--target)
      LOCAL_SKILLS_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --help|-h)
      echo "Usage: sync-from-source.sh [--source path] [--dry-run] [--force]"
      echo "One-way sync: repository -> local installed skills."
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
  echo "Error: repository skills directory does not exist: $REPO_SKILLS_DIR"
  exit 1
fi
if [[ ! -d "$LOCAL_SKILLS_DIR" ]]; then
  echo "Error: local skills directory does not exist: $LOCAL_SKILLS_DIR"
  exit 1
fi

echo "=== Skills Sync Check (repo -> local) ==="
echo "Repository: $REPO_SKILLS_DIR"
echo "Local:      $LOCAL_SKILLS_DIR"
if [[ "$DRY_RUN" == true ]]; then
  echo "DRY RUN - no changes will be made"
fi
echo ""

if [[ "$DRY_RUN" != true ]]; then
  cd "$REPO_ROOT"
  if git rev-parse --is-inside-work-tree &>/dev/null && git remote get-url origin &>/dev/null; then
    echo "--- Pull remote updates ---"
    git pull --ff-only || echo "Warning: git pull --ff-only failed; using current local repository"
    echo ""
  fi
fi

skill_hash() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo ""
    return
  fi
  find "$dir" -type f ! -path "*/.backup/*" -print0 |
    sort -z |
    while IFS= read -r -d '' file; do
      local rel="${file#"$dir"/}"
      local h
      h="$(sha256sum "$file" | cut -d' ' -f1)"
      printf '%s:%s\n' "$rel" "$h"
    done |
    sha256sum |
    cut -d' ' -f1
}

declare -A local_skills=()
while IFS= read -r -d '' dir; do
  name="$(basename "$dir")"
  [[ "$name" == ".backup" ]] && continue
  [[ -f "$dir/SKILL.md" ]] && local_skills["$name"]="$dir"
done < <(find "$LOCAL_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

declare -A repo_skills=()
while IFS= read -r -d '' dir; do
  name="$(basename "$dir")"
  [[ "$name" == ".backup" ]] && continue
  [[ -f "$dir/SKILL.md" ]] && repo_skills["$name"]="$dir"
done < <(find "$REPO_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

add_skills=()
update_skills=()
local_only=()
identical=()

all_names=()
for name in "${!local_skills[@]}"; do all_names+=("$name"); done
for name in "${!repo_skills[@]}"; do all_names+=("$name"); done
mapfile -t sorted_names < <(printf '%s\n' "${all_names[@]}" | sort -u)

for name in "${sorted_names[@]}"; do
  in_local=false
  in_repo=false
  [[ -n "${local_skills[$name]+x}" ]] && in_local=true
  [[ -n "${repo_skills[$name]+x}" ]] && in_repo=true

  if [[ "$in_local" == false && "$in_repo" == true ]]; then
    add_skills+=("$name")
  elif [[ "$in_local" == true && "$in_repo" == false ]]; then
    local_only+=("$name")
  elif [[ "$in_local" == true && "$in_repo" == true ]]; then
    if [[ "$(skill_hash "${local_skills[$name]}")" != "$(skill_hash "${repo_skills[$name]}")" ]]; then
      update_skills+=("$name")
    else
      identical+=("$name")
    fi
  fi
done

echo "--- Difference Summary ---"
echo "Add to local: ${#add_skills[@]}"
echo "Update local: ${#update_skills[@]}"
echo "Local only:   ${#local_only[@]} (kept, not uploaded)"
echo "Unchanged:    ${#identical[@]}"
for name in "${add_skills[@]}"; do echo "  + $name"; done
for name in "${update_skills[@]}"; do echo "  ~ $name"; done
for name in "${local_only[@]}"; do echo "  local-only: $name"; done
echo ""

if [[ $(( ${#add_skills[@]} + ${#update_skills[@]} )) -eq 0 ]]; then
  echo "Nothing to sync."
  exit 0
fi
if [[ "$DRY_RUN" == true ]]; then
  exit 0
fi

if [[ "$FORCE" != true ]]; then
  read -rp "Apply repository versions to local skills? [y/N] " response
  if [[ ! "$response" =~ ^[yY]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

backup_dir="$LOCAL_SKILLS_DIR/.backup/sync-$(date +%Y%m%d-%H%M%S)"

for name in "${add_skills[@]}"; do
  mkdir -p "$LOCAL_SKILLS_DIR/$name"
  cp -R "${repo_skills[$name]}"/. "$LOCAL_SKILLS_DIR/$name/"
  echo "  added: $name"
done

for name in "${update_skills[@]}"; do
  mkdir -p "$backup_dir"
  cp -R "$LOCAL_SKILLS_DIR/$name" "$backup_dir/$name"
  rm -rf "$LOCAL_SKILLS_DIR/$name"
  mkdir -p "$LOCAL_SKILLS_DIR/$name"
  cp -R "${repo_skills[$name]}"/. "$LOCAL_SKILLS_DIR/$name/"
  echo "  updated: $name"
done

echo ""
echo "=== Skills Sync Complete ==="
echo "Added to local: ${#add_skills[@]}"
echo "Updated local:  ${#update_skills[@]}"
echo "Local only:     ${#local_only[@]} (kept)"
[[ -d "$backup_dir" ]] && echo "Backup:         $backup_dir"
