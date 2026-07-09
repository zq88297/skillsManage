#!/usr/bin/env bash
# sync-from-source.sh — 双向同步 ~/.claude/skills/ 和 Git 仓库
#
# 流程：
#   1. git pull 拉取 GitHub 最新
#   2. 比较 ~/.claude/skills/ 和 repo/skills/
#   3. 本地缺少的 → 从仓库复制到本地
#   4. 本地多出来的 → 复制到仓库
#   5. 自动提交并推送
#
# 用法：
#   ./sync-from-source.sh [options]
#
# 选项：
#   --source <path>   本地技能目录（默认: ~/.claude/skills/）
#   --dry-run         仅预览，不执行
#   --auto-commit     自动提交并推送
#   --force           跳过确认提示
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_SKILLS_DIR="$REPO_ROOT/skills"
CATALOG_FILE="$REPO_ROOT/skill-catalog.yaml"

# --- 默认值 ---
LOCAL_SKILLS_DIR="$HOME/.claude/skills"
AUTO_COMMIT=false
DRY_RUN=false
FORCE=false

# --- 解析参数 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            LOCAL_SKILLS_DIR="$2"
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
            echo "用法: sync-from-source.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --source <path>   本地技能目录（默认: ~/.claude/skills/）"
            echo "  --dry-run         仅预览，不执行"
            echo "  --auto-commit     自动提交并推送"
            echo "  --force           跳过确认提示"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# --- 验证目录 ---
if [[ ! -d "$LOCAL_SKILLS_DIR" ]]; then
    echo "错误: 本地技能目录不存在: $LOCAL_SKILLS_DIR"
    echo "请确认 Claude Code 已安装。"
    exit 1
fi

if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
    echo "错误: 仓库技能目录不存在: $REPO_SKILLS_DIR"
    exit 1
fi

echo "=== 技能双向同步 ==="
echo "本地: $LOCAL_SKILLS_DIR"
echo "仓库: $REPO_SKILLS_DIR"
if [[ "$DRY_RUN" == true ]]; then
    echo "【预览模式】不会执行任何修改"
fi
echo ""

# ============================================================
# Step 1: git pull 拉取最新
# ============================================================
if [[ "$DRY_RUN" != true ]]; then
    echo "--- Step 1: 从 GitHub 拉取最新 ---"
    cd "$REPO_ROOT"
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        # 检查是否有远程
        if git remote get-url origin &>/dev/null 2>&1; then
            echo "执行 git pull..."
            git pull --rebase origin master 2>/dev/null || echo "警告: git pull 失败，将继续使用本地仓库"
        else
            echo "未配置远程仓库，跳过 git pull"
        fi
    fi
    echo ""
fi

# ============================================================
# Step 2: 计算目录哈希（用于比较）
# ============================================================
get_skill_hash() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo ""
        return
    fi
    local combined=""
    while IFS= read -r -d '' file; do
        local rel="${file#"$dir"/}"
        local h
        h=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
        combined+="$rel:$h"$'\n'
    done < <(find "$dir" -type f -print0 | sort -z)
    echo "$combined" | sha256sum | cut -d' ' -f1
}

# ============================================================
# Step 3: 收集技能目录
# ============================================================
declare -A local_skills
while IFS= read -r -d '' dir; do
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]]; then
        local_skills["$name"]="$dir"
    fi
done < <(find "$LOCAL_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

declare -A repo_skills
while IFS= read -r -d '' dir; do
    name=$(basename "$dir")
    if [[ -f "$dir/SKILL.md" ]]; then
        repo_skills["$name"]="$dir"
    fi
done < <(find "$REPO_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

# ============================================================
# Step 4: 比较差异
# ============================================================
pull_skills=()   # 仓库有、本地没有 → 从仓库拉取到本地
push_skills=()   # 本地有、仓库没有 → 从本地推送到仓库
update_skills=() # 都有但内容不同 → 以仓库为准更新本地
identical=()     # 完全相同

all_names=()
for name in "${!local_skills[@]}"; do all_names+=("$name"); done
for name in "${!repo_skills[@]}"; do
    [[ -z "${local_skills[$name]+x}" ]] && all_names+=("$name")
done

IFS=$'\n' sorted_names=($(sort <<< "${all_names[*]}")); unset IFS

for name in "${sorted_names[@]}"; do
    in_local=$([[ -n "${local_skills[$name]+x}" ]] && echo true || echo false)
    in_repo=$([[ -n "${repo_skills[$name]+x}" ]] && echo true || echo false)

    if [[ "$in_local" == false ]] && [[ "$in_repo" == true ]]; then
        # 仓库有，本地没有 → 需要拉取
        pull_skills+=("$name")
    elif [[ "$in_local" == true ]] && [[ "$in_repo" == false ]]; then
        # 本地有，仓库没有 → 需要推送
        push_skills+=("$name")
    elif [[ "$in_local" == true ]] && [[ "$in_repo" == true ]]; then
        local_hash=$(get_skill_hash "${local_skills[$name]}")
        repo_hash=$(get_skill_hash "${repo_skills[$name]}")
        if [[ "$local_hash" != "$repo_hash" ]]; then
            # 内容不同 → 以仓库为准更新本地
            update_skills+=("$name")
        else
            identical+=("$name")
        fi
    fi
done

# ============================================================
# Step 5: 报告差异
# ============================================================
total_changes=$(( ${#pull_skills[@]} + ${#push_skills[@]} + ${#update_skills[@]} ))

if [[ $total_changes -eq 0 ]]; then
    echo "✅ 所有技能已同步，无需操作。"
    exit 0
fi

echo "--- 差异分析 ---"

if [[ ${#pull_skills[@]} -gt 0 ]]; then
    echo "📥 需要从仓库拉取到本地 (${#pull_skills[@]} 个):"
    for name in "${pull_skills[@]}"; do
        count=$(find "${repo_skills[$name]}" -type f | wc -l | tr -d ' ')
        echo "  + $name ($count 个文件)"
    done
fi

if [[ ${#push_skills[@]} -gt 0 ]]; then
    echo "📤 需要从本地推送到仓库 (${#push_skills[@]} 个):"
    for name in "${push_skills[@]}"; do
        count=$(find "${local_skills[$name]}" -type f | wc -l | tr -d ' ')
        echo "  + $name ($count 个文件)"
    done
fi

if [[ ${#update_skills[@]} -gt 0 ]]; then
    echo "🔄 需要更新本地技能（以仓库为准）(${#update_skills[@]} 个):"
    for name in "${update_skills[@]}"; do
        echo "  ~ $name"
    done
fi

echo "✅ 已同步 (${#identical[@]} 个)"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi

# ============================================================
# Step 6: 确认
# ============================================================
if [[ "$FORCE" != true ]]; then
    echo "--- 操作确认 ---"
    echo "将执行以下操作:"
    [[ ${#pull_skills[@]} -gt 0 ]] && echo "  从仓库拉取 ${#pull_skills[@]} 个技能到本地"
    [[ ${#push_skills[@]} -gt 0 ]] && echo "  从本地推送 ${#push_skills[@]} 个技能到仓库"
    [[ ${#update_skills[@]} -gt 0 ]] && echo "  更新本地 ${#update_skills[@]} 个技能（以仓库为准）"
    echo ""
    read -rp "确认执行? [y/N] " response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo "已取消。"
        exit 0
    fi
fi

# ============================================================
# Step 7: 执行同步
# ============================================================
echo ""
echo "--- 执行同步 ---"

# 备份目录
BACKUP_DIR="$REPO_ROOT/.sync-backup/$(date +%Y%m%d-%H%M%S)"

# 7a: 从仓库拉取到本地（本地缺少的）
for name in "${pull_skills[@]}"; do
    mkdir -p "$LOCAL_SKILLS_DIR/$name"
    cp -r "${repo_skills[$name]}"/* "$LOCAL_SKILLS_DIR/$name/"
    echo "  📥 已拉取: $name → 本地"
done

# 7b: 从本地推送到仓库（本地多出来的）
for name in "${push_skills[@]}"; do
    mkdir -p "$REPO_SKILLS_DIR/$name"
    cp -r "${local_skills[$name]}"/* "$REPO_SKILLS_DIR/$name/"
    echo "  📤 已推送: $name → 仓库"
done

# 7c: 以仓库为准更新本地（内容不同）
for name in "${update_skills[@]}"; do
    # 备份本地版本
    mkdir -p "$BACKUP_DIR"
    if [[ -d "$LOCAL_SKILLS_DIR/$name" ]]; then
        cp -r "$LOCAL_SKILLS_DIR/$name" "$BACKUP_DIR/$name"
    fi
    # 用仓库版本覆盖本地
    rm -rf "$LOCAL_SKILLS_DIR/$name"
    mkdir -p "$LOCAL_SKILLS_DIR/$name"
    cp -r "${repo_skills[$name]}"/* "$LOCAL_SKILLS_DIR/$name/"
    echo "  🔄 已更新: $name（以仓库为准）"
done

if [[ -d "$BACKUP_DIR" ]]; then
    echo "  备份目录: $BACKUP_DIR"
fi

# ============================================================
# Step 8: 自动提交并推送
# ============================================================
if [[ "$AUTO_COMMIT" == true ]]; then
    echo ""
    echo "--- 提交到 Git ---"
    cd "$REPO_ROOT"

    # 构建提交信息
    COMMIT_MSG="sync: 双向同步技能"$'\n\n'
    [[ ${#pull_skills[@]} -gt 0 ]] && COMMIT_MSG+="从仓库拉取: $(IFS=', '; echo "${pull_skills[*]}")"$'\n'
    [[ ${#push_skills[@]} -gt 0 ]] && COMMIT_MSG+="推送到仓库: $(IFS=', '; echo "${push_skills[*]}")"$'\n'
    [[ ${#update_skills[@]} -gt 0 ]] && COMMIT_MSG+="更新本地: $(IFS=', '; echo "${update_skills[*]}")"$'\n'

    # 更新 catalog 时间戳
    if [[ -f "$CATALOG_FILE" ]]; then
        TODAY=$(date +%Y-%m-%d)
        sed -i "s/last_updated: \".*\"/last_updated: \"$TODAY\"/" "$CATALOG_FILE"
    fi

    git add -A
    git commit -m "$COMMIT_MSG" 2>/dev/null || echo "没有需要提交的更改"

    # 推送到远程
    echo ""
    echo "推送到 GitHub..."
    if git push origin master 2>/dev/null; then
        echo "  ✅ 推送成功"
    else
        echo "  ⚠️ 推送失败（可能没网络），请稍后手动执行: git push"
    fi
fi

echo ""
echo "=== 同步完成 ==="
echo "本地: $LOCAL_SKILLS_DIR"
echo "仓库: $REPO_SKILLS_DIR"
[[ ${#pull_skills[@]} -gt 0 ]] && echo "📥 拉取: ${#pull_skills[@]} 个"
[[ ${#push_skills[@]} -gt 0 ]] && echo "📤 推送: ${#push_skills[@]} 个"
[[ ${#update_skills[@]} -gt 0 ]] && echo "🔄 更新: ${#update_skills[@]} 个"
echo "✅ 已同步: ${#identical[@]} 个"
