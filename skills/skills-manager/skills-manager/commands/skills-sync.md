# Skills Sync

自动双向同步技能。执行 `/skills-sync` 即可。

## 执行流程

### Step 1：定位仓库

- 默认 GitHub：`https://github.com/zq88297/skillsManage.git`
- 没有本地克隆则自动克隆

### Step 2：对比并同步

```bash
cd <repo_path>

# 遍历本地技能
for skill in ~/.claude/skills/*/; do
    name=$(basename "$skill")
    [[ "$name" == "skills.zip" ]] && continue
    
    if [[ ! -d "skills/$name" ]]; then
        # 本地有，仓库没有 → 推送
        cp -r "$skill" "skills/$name"
        echo "📤 推送: $name"
    elif ! diff -rq "$skill" "skills/$name" >/dev/null 2>&1; then
        # 都有但不同 → 用时间戳判断方向
        local_time=$(stat -c %Y "$skill/SKILL.md" 2>/dev/null || echo 0)
        repo_time=$(stat -c %Y "skills/$name/SKILL.md" 2>/dev/null || echo 0)
        if [[ $local_time -gt $repo_time ]]; then
            cp -r "$skill" "skills/$name"
            echo "📤 更新仓库: $name"
        else
            cp -r "skills/$name" "$skill"
            echo "📥 更新本地: $name"
        fi
    fi
done

# 遍历仓库技能
for skill in skills/*/; do
    name=$(basename "$skill")
    if [[ ! -d "$HOME/.claude/skills/$name" ]]; then
        # 仓库有，本地没有 → 拉取
        cp -r "$skill" "$HOME/.claude/skills/$name"
        echo "📥 拉取: $name"
    fi
done
```

### Step 3：提交推送

```bash
cd <repo_path>
git add -A
git diff --cached --quiet || git commit -m "sync: bidirectional sync"
git push origin master
```

### Step 4：报告

```
✅ 同步完成
- 推送: N 个技能到仓库
- 拉取: M 个技能到本地
- 已推送到 GitHub
```
