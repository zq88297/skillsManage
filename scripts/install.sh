#!/usr/bin/env bash
# install.sh — Install managed skills to a target project (Unix)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILL_SRC="$REPO_ROOT/skills"
SHARED_DIR="$REPO_ROOT/shared"
CATALOG_FILE="$REPO_ROOT/skill-catalog.yaml"

usage() {
    echo "Usage: install.sh <target-path> [--skills skill1,skill2] [--with-hooks] [--force]"
    echo ""
    echo "  target-path    Path to the target project root"
    echo "  --skills       Comma-separated skill names (default: all)"
    echo "  --with-hooks   Also install hooks from shared/hooks/"
    echo "  --force        Skip backup of existing files"
    exit 1
}

TARGET_PATH=""
SELECTED_SKILLS=""
WITH_HOOKS=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skills)
            SELECTED_SKILLS="$2"
            shift 2
            ;;
        --with-hooks)
            WITH_HOOKS=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            if [[ -z "$TARGET_PATH" ]]; then
                TARGET_PATH="$1"
                shift
            else
                echo "Unknown argument: $1"
                usage
            fi
            ;;
    esac
done

if [[ -z "$TARGET_PATH" ]]; then
    usage
fi

if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Error: Target path does not exist: $TARGET_PATH"
    exit 1
fi

TARGET_PATH="$(cd "$TARGET_PATH" && pwd)"
SKILL_DST="$TARGET_PATH/.claude/skills"

echo "=== Skills Installer ==="
echo "Repository: $REPO_ROOT"
echo "Target:      $TARGET_PATH"
echo ""

# --- Resolve skills to install ---
ALL_SKILLS=()
for d in "$SKILL_SRC"/*/; do
    name=$(basename "$d")
    [[ "$name" == ".backup" ]] && continue
    ALL_SKILLS+=("$name")
done

if [[ -z "$SELECTED_SKILLS" ]]; then
    TO_INSTALL=("${ALL_SKILLS[@]}")
else
    IFS=',' read -ra TO_INSTALL <<< "$SELECTED_SKILLS"
fi

get_dependencies() {
    local skill_name="$1"
    awk -v target="$skill_name" '
        $0 == "skills:" { in_skills = 1; next }
        $0 == "dependency_order:" { exit }
        in_skills && $0 == "  " target ":" { in_target = 1; next }
        in_target && /^  [a-z0-9-]+:/ { exit }
        in_target && /^    dependencies:$/ { in_dependencies = 1; next }
        in_target && in_dependencies && /^      - [a-z0-9-]+$/ { print $2; next }
        in_target && in_dependencies && /^    [a-z0-9_-]+:/ { exit }
    ' "$CATALOG_FILE"
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

SORTED=()
VISITING=()

resolve_skill() {
    local skill_name="$1"
    local dependency

    skill_name="${skill_name//[[:space:]]/}"
    [[ -z "$skill_name" ]] && return 0

    if array_contains "$skill_name" "${SORTED[@]}"; then
        return 0
    fi
    if array_contains "$skill_name" "${VISITING[@]}"; then
        echo "Error: Dependency cycle detected at skill: $skill_name"
        exit 1
    fi
    if [[ ! -d "$SKILL_SRC/$skill_name" ]]; then
        echo "Error: Skill source not found: $SKILL_SRC/$skill_name"
        exit 1
    fi

    VISITING+=("$skill_name")
    while IFS= read -r dependency; do
        [[ -n "$dependency" ]] && resolve_skill "$dependency"
    done < <(get_dependencies "$skill_name")
    unset 'VISITING[${#VISITING[@]}-1]'
    SORTED+=("$skill_name")
}

for skill_name in "${TO_INSTALL[@]}"; do
    resolve_skill "$skill_name"
done

echo "Skills to install:"
for s in "${SORTED[@]}"; do
    echo "  $s"
done
echo ""

BACKUP_DIR="$SKILL_DST/.backup/$(date +%Y%m%d-%H%M%S)"
INSTALLED=0

for skill_name in "${SORTED[@]}"; do
    src="$SKILL_SRC/$skill_name"
    dst="$SKILL_DST/$skill_name"

    if [[ ! -d "$src" ]]; then
        echo "  [WARN] Skill source not found: $src — skipping"
        continue
    fi

    # Backup
    if [[ -d "$dst" ]] && [[ "$FORCE" != true ]]; then
        mkdir -p "$BACKUP_DIR/$skill_name"
        cp -r "$dst"/* "$BACKUP_DIR/$skill_name/" 2>/dev/null || true
        echo "  Backed up: $skill_name -> .backup/"
    fi

    # Install
    mkdir -p "$dst"
    cp -r "$src"/* "$dst/"
    file_count=$(find "$dst" -type f | wc -l | tr -d ' ')
    echo "  Installed: $skill_name ($file_count files)"
    INSTALLED=$((INSTALLED + 1))
done

# Install hooks if requested
if [[ "$WITH_HOOKS" == true ]]; then
    HOOKS_SRC="$SHARED_DIR/hooks"
    HOOKS_DST="$TARGET_PATH/.claude/hooks"

    if [[ -d "$HOOKS_SRC" ]]; then
        mkdir -p "$HOOKS_DST"

        # hooks.json
        if [[ -f "$HOOKS_SRC/hooks.json" ]]; then
            cp "$HOOKS_SRC/hooks.json" "$TARGET_PATH/.claude/hooks.json"
            echo "  Installed: hooks.json"
        fi

        # Shell scripts
        for script in "$HOOKS_SRC"/*.sh; do
            [[ ! -f "$script" ]] && continue
            name=$(basename "$script")
            cp "$script" "$HOOKS_DST/$name"
            chmod +x "$HOOKS_DST/$name"
            echo "  Installed: hooks/$name"
        done
    fi
fi

echo ""
echo "=== Installation Complete ==="
echo "$INSTALLED skills installed to $SKILL_DST"
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backup created at: $BACKUP_DIR"
fi
