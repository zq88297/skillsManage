#!/usr/bin/env bash
# setup.sh — One-liner skill installer for Claude Code
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh)
#
# Options:
#   --scope project|global   Install scope (default: global)
#   --skills skill1,skill2   Only install specific skills
#
# Examples:
#   # Install globally (all projects) — default
#   bash <(curl -fsSL .../setup.sh)
#
#   # Install to current project only
#   bash <(curl -fsSL .../setup.sh) --scope project
#
#   # Install specific skills globally
#   bash <(curl -fsSL .../setup.sh) --skills gsap-core,gsap-timeline
#
set -euo pipefail

REPO_URL="https://github.com/zq88297/skillsManage.git"
BRANCH="master"
TMP_DIR=""

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

# Parse arguments
SCOPE="global"
SELECTED_SKILLS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --skills)
            SELECTED_SKILLS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: setup.sh [--scope project|global] [--skills <skill1,skill2>]"
            echo ""
            echo "Options:"
            echo "  --scope    Install scope: global (default) or project"
            echo "  --skills   Comma-separated skill names (default: all)"
            echo ""
            echo "Examples:"
            echo "  bash <(curl -fsSL .../setup.sh)"
            echo "  bash <(curl -fsSL .../setup.sh) --scope project"
            echo "  bash <(curl -fsSL .../setup.sh) --skills gsap-core,gsap-timeline"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Validate scope
if [[ "$SCOPE" != "project" && "$SCOPE" != "global" ]]; then
    echo "Error: --scope must be 'project' or 'global'"
    exit 1
fi

# Determine target path
GLOBAL_DIR="$HOME/.claude/skills"
if [[ "$SCOPE" == "global" ]]; then
    TARGET_PATH="$GLOBAL_DIR"
else
    TARGET_PATH="$(pwd)"
fi

echo "=== Claude Code Skills Installer ==="
echo "Scope:  $SCOPE"
echo "Target: $TARGET_PATH"
echo ""

# Check dependencies
if ! command -v git &>/dev/null; then
    echo "Error: git is required but not installed."
    exit 1
fi

# Clone to temp directory
echo "Cloning skills repository..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR/skillsManage" 2>/dev/null

SCRIPTS_DIR="$TMP_DIR/skillsManage/scripts"

if [[ "$SCOPE" == "global" ]]; then
    # Global: install to temp project, then copy skills to global dir
    GLOBAL_ARGS="$TMP_DIR"
    if [[ -n "$SELECTED_SKILLS" ]]; then
        GLOBAL_ARGS="$GLOBAL_ARGS --skills $SELECTED_SKILLS"
    fi
    bash "$SCRIPTS_DIR/install.sh" $GLOBAL_ARGS
    mkdir -p "$GLOBAL_DIR"
    cp -r "$TMP_DIR/.claude/skills/"* "$GLOBAL_DIR/" 2>/dev/null || true
else
    # Project: install directly to target project
    BASH_ARGS="$TARGET_PATH"
    if [[ -n "$SELECTED_SKILLS" ]]; then
        BASH_ARGS="$BASH_ARGS --skills $SELECTED_SKILLS"
    fi
    bash "$SCRIPTS_DIR/install.sh" $BASH_ARGS
fi

echo ""
echo "Done! Restart Claude Code to load the new skills."
