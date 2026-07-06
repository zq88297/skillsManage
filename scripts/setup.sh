#!/usr/bin/env bash
# setup.sh — One-liner skill installer for Claude Code
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/zq88297/skillsManage/master/scripts/setup.sh)
#
# With options:
#   bash <(curl -fsSL ...) --target /path/to/project
#   bash <(curl -fsSL ...) --skills gsap-core,gsap-timeline
#   bash <(curl -fsSL ...) --target /path/to/project --skills project-workflow
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
TARGET_PATH=""
SELECTED_SKILLS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET_PATH="$2"
            shift 2
            ;;
        --skills)
            SELECTED_SKILLS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: setup.sh [--target <path>] [--skills <skill1,skill2>]"
            echo ""
            echo "  --target    Install to this project path (default: current directory)"
            echo "  --skills    Comma-separated skill names (default: all)"
            echo ""
            echo "Examples:"
            echo "  bash <(curl -fsSL .../setup.sh)"
            echo "  bash <(curl -fsSL .../setup.sh) --target ~/my-project"
            echo "  bash <(curl -fsSL .../setup.sh) --skills gsap-core,gsap-timeline"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Default target: current directory
if [[ -z "$TARGET_PATH" ]]; then
    TARGET_PATH="$(pwd)"
fi

if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Error: Target path does not exist: $TARGET_PATH"
    exit 1
fi

echo "=== Claude Code Skills Installer ==="
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

# Build install command
INSTALL_ARGS="-TargetPath $TARGET_PATH"
if [[ -n "$SELECTED_SKILLS" ]]; then
    # Convert comma-separated to PowerShell array format
    IFS=',' read -ra SKILLS_ARRAY <<< "$SELECTED_SKILLS"
    PSKILLS=$(printf "'%s'," "${SKILLS_ARRAY[@]}" | sed 's/,$//')
    INSTALL_ARGS="$INSTALL_ARGS -Skills $PSKILLS"
fi

# Detect shell and run installer
SCRIPTS_DIR="$TMP_DIR/skillsManage/scripts"

if [[ -f "$SCRIPTS_DIR/install.sh" ]]; then
    # Unix: use bash installer
    BASH_ARGS="$TARGET_PATH"
    if [[ -n "$SELECTED_SKILLS" ]]; then
        BASH_ARGS="$BASH_ARGS --skills $SELECTED_SKILLS"
    fi
    bash "$SCRIPTS_DIR/install.sh" $BASH_ARGS
else
    echo "Error: install.sh not found in repository"
    exit 1
fi

echo ""
echo "Done! Restart Claude Code to load the new skills."
