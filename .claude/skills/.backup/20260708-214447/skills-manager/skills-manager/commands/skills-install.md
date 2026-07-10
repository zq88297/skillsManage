# Skills Install

你是技能安装助手。从技能仓库安装技能到当前项目或指定项目。

## 触发

用户输入 `/skills-install` 或说"安装技能"、"部署技能"、"install skills"、"给这个项目装技能"。

## 参数

用户可指定：
- `/skills-install` — 安装全部技能到当前项目
- `/skills-install --select gsap-core,docx,pdf` — 选择性安装
- `/skills-install --target /path/to/project` — 安装到指定项目
- `/skills-install --with-hooks` — 同时安装 hooks

## 执行流程

### Step 1：确定目标

- 默认目标：当前 Claude Code 项目根目录
- 如果用户指定了 `--target`，使用指定路径
- 如果无法确定项目目录，询问用户

### Step 2：确认安装范围

- 如果用户未指定 `--select`，询问：全部安装还是选择性安装？
- 展示技能分类让用户选择：
  ```
  1. 全部
  2. 基础 + 工作流 (session-context, project-workflow, task-orchestrator)
  3. 设计类 (canvas-design, frontend-design, impeccable)
  4. 文档类 (docx, pdf, pptx, xlsx)
  5. 动画类 (gsap-* 8 个)
  6. 自定义选择
  ```

### Step 3：定位仓库

- 检查本地是否已有仓库克隆
- 如果没有本地克隆，从 GitHub 克隆到临时目录：
  ```bash
  TMP_DIR=$(mktemp -d)
  git clone --depth 1 https://github.com/zq88297/skillsManage.git "$TMP_DIR/skillsManage"
  REPO_PATH="$TMP_DIR/skillsManage"
  ```

### Step 4：执行安装

**Linux/macOS:**
```bash
cd <repo_path>
bash scripts/install.sh <target_path> [--skills <list>] [--with-hooks] [--force]
```

**Windows (PowerShell):**
```powershell
Set-Location <repo_path>
.\scripts\install.ps1 -TargetPath <target_path> [-Skills <list>] [-WithHooks] [-Force]
```

### Step 5：报告结果

```
✅ 已安装 N 个技能到 <target_path>/.claude/skills/
- 总文件数：M
- 重启 Claude Code 后生效
```

### Step 6：验证（可选）

如果当前就在目标项目中：
```bash
ls <target_path>/.claude/skills/
```
确认技能目录已创建。

---

## 注意事项

- 安装会备份已有技能到 `.claude/skills/.backup/`
- 如果目标项目已有同名技能且用户未加 `--force`，先展示差异再确认
- 优先使用 GitHub 仓库地址作为默认源，避免依赖本地路径
