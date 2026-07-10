#!/usr/bin/env python3
"""Initialize or sync SKIIS docs/ai-context files for a project."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import subprocess
from pathlib import Path


EXCLUDED_DIRS = {
    ".git",
    ".svn",
    ".hg",
    ".idea",
    ".vscode",
    "__pycache__",
    "assets",
    "build",
    "dist",
    "docs",
    "examples",
    "include",
    "lib",
    "node_modules",
    "public",
    "resources",
    "src",
    "static",
    "target",
    "tests",
    "vendor",
}

BUILD_FILES = {
    "CMakeLists.txt",
    "Makefile",
    "package.json",
    "pyproject.toml",
    "Cargo.toml",
    "go.mod",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
}

MAIN_PATTERNS = {
    "main.c",
    "main.cpp",
    "main.cc",
    "main.go",
    "main.py",
    "index.js",
    "index.ts",
    "main.ts",
    "main.tsx",
    "app.py",
}


def run_git(root: Path, args: list[str]) -> str | None:
    try:
        completed = subprocess.run(
            ["git", "-C", str(root), *args],
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return completed.stdout.strip()


def is_git_repo(root: Path) -> bool:
    return run_git(root, ["rev-parse", "--is-inside-work-tree"]) == "true"


def git_branch(root: Path) -> str:
    branch = run_git(root, ["rev-parse", "--abbrev-ref", "HEAD"]) or "unknown"
    if branch == "HEAD":
        short = run_git(root, ["rev-parse", "--short", "HEAD"]) or "detached"
        return f"detached-{short}"
    return branch


def branch_path_parts(branch: str) -> list[str]:
    parts = []
    for part in re.split(r"[\\/]+", branch):
        safe = re.sub(r'[<>:"|?*\x00-\x1f]', "-", part).strip()
        parts.append(safe or "unnamed")
    return parts or ["unknown"]


def detect_vcs(root: Path) -> str:
    if is_git_repo(root):
        return "git"
    if (root / ".svn").exists() or any((root / name).exists() for name in ("trunk", "branches", "tags")):
        return "svn"
    return "plain"


def context_paths(root: Path, plain_context: bool) -> tuple[Path, Path, str]:
    context_root = root / "docs" / "ai-context"
    vcs = detect_vcs(root)
    if vcs == "git" and not plain_context:
        branch = git_branch(root)
        context_dir = context_root.joinpath(*branch_path_parts(branch))
    else:
        context_dir = context_root
    return context_root, context_dir, vcs


def write_if_missing(path: Path, content: str) -> bool:
    if path.exists():
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def now_text() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M")


def current_task_template() -> str:
    return f"""> 最后更新: {now_text()}

# 当前任务

## 已完成

## 进行中
- [ ] 初始化 SKIIS 上下文系统

## 待完成
- [ ] 根据当前开发目标更新任务清单

## 下次继续
### 第一步
打开当前项目，读取本文件并确认当前开发目标

### 当前状态
上下文系统已初始化

### 关键约束
保存进度时必须写清楚下一步的文件、函数或区域

### 阻塞项
无

## 关键上下文
- 上下文目录: docs/ai-context/
"""


def decisions_template() -> str:
    return "# 技术决策记录\n"


def pitfalls_template() -> str:
    return "# 踩坑记录\n"


def classify_project(root: Path) -> list[str]:
    hints: list[str] = []
    files = {p.name for p in root.iterdir() if p.is_file()}
    if "package.json" in files:
        hints.append("JavaScript/TypeScript")
    if "pyproject.toml" in files or "requirements.txt" in files:
        hints.append("Python")
    if "go.mod" in files:
        hints.append("Go")
    if "Cargo.toml" in files:
        hints.append("Rust")
    if "CMakeLists.txt" in files or "Makefile" in files:
        hints.append("C/C++")
    if "pom.xml" in files or "build.gradle" in files or "build.gradle.kts" in files:
        hints.append("Java/JVM")
    return hints


def module_signals(path: Path) -> list[str]:
    signals: list[str] = []
    if not path.is_dir() or path.name in EXCLUDED_DIRS:
        return signals
    try:
        children = list(path.iterdir())
    except OSError:
        return signals
    names = {child.name for child in children}
    found_build = sorted(names & BUILD_FILES)
    found_main = sorted(names & MAIN_PATTERNS)
    if found_build:
        signals.append("build: " + ", ".join(found_build[:3]))
    if found_main:
        signals.append("entry: " + ", ".join(found_main[:3]))
    if any((path / name).is_dir() for name in ("src", "lib", "include")):
        signals.append("local source layout")
    if re.search(r"(module|service|api|worker|gateway|core|engine|client|server)", path.name, re.I):
        signals.append("module-like name")
    return signals


def architecture_text(root: Path, context_dir: Path, vcs: str, plain_context: bool) -> str:
    project_types = classify_project(root)
    top_files = sorted(p.name for p in root.iterdir() if p.is_file() and p.name in BUILD_FILES)
    modules: list[tuple[str, list[str]]] = []
    skipped: list[str] = []

    for entry in sorted(root.iterdir(), key=lambda p: p.name.lower()):
        if not entry.is_dir():
            continue
        if entry.name in EXCLUDED_DIRS:
            skipped.append(entry.name)
            continue
        signals = module_signals(entry)
        if signals:
            modules.append((entry.name, signals))

    branch_note = ""
    if vcs == "git" and not plain_context:
        branch_note = f"- Active branch context: `{context_dir.relative_to(root)}`\n"

    lines = [
        f"> 最后更新: {now_text()}",
        "",
        "# 项目架构概览",
        "",
        "## 项目识别",
        f"- 根目录: `{root}`",
        f"- VCS: {vcs}",
        branch_note.rstrip(),
        f"- 类型线索: {', '.join(project_types) if project_types else '未识别'}",
        f"- 顶层构建/配置文件: {', '.join(top_files) if top_files else '无'}",
        "",
        "## 子模块候选",
    ]

    if modules:
        for name, signals in modules:
            lines.append(f"- `{name}/` - {'; '.join(signals)}")
    else:
        lines.append("- 未发现明确子模块候选")

    lines.extend(
        [
            "",
            "## 已排除目录",
            "- " + (", ".join(f"`{name}/`" for name in skipped) if skipped else "无"),
            "",
            "## 同步说明",
            "- 使用 SKIIS context-sync 或 init_context.py --sync-architecture 覆盖更新本文件。",
            "- 大型项目先定位相关模块，再加载该模块自己的 docs/ai-context/。",
        ]
    )
    return "\n".join(line for line in lines if line is not None) + "\n"


def ensure_task_dirs(context_dir: Path) -> None:
    for subdir in ("tasks", "tasks/claims", "tasks/done", "tasks/queue", "tasks/results", "tasks/results/merged"):
        (context_dir / subdir).mkdir(parents=True, exist_ok=True)


def update_gitignore(root: Path) -> bool:
    path = root / ".gitignore"
    entry = "docs/ai-context/"
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    if any(line.strip() == entry for line in existing.splitlines()):
        return False
    prefix = "" if not existing or existing.endswith("\n") else "\n"
    path.write_text(existing + prefix + entry + "\n", encoding="utf-8")
    return True


def initialize(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Root is not a directory: {root}")

    context_root, context_dir, vcs = context_paths(root, args.plain_context)
    context_dir.mkdir(parents=True, exist_ok=True)
    ensure_task_dirs(context_dir)

    created: list[Path] = []
    for path, content in (
        (context_dir / "current-task.md", current_task_template()),
        (context_dir / "decisions.md", decisions_template()),
        (context_dir / "pitfalls.md", pitfalls_template()),
    ):
        if write_if_missing(path, content):
            created.append(path)

    architecture_path = context_root / "architecture.md" if vcs == "git" and not args.plain_context else context_dir / "architecture.md"
    if args.sync_architecture or not architecture_path.exists():
        architecture_path.parent.mkdir(parents=True, exist_ok=True)
        architecture_path.write_text(architecture_text(root, context_dir, vcs, args.plain_context), encoding="utf-8")
        created.append(architecture_path)

    gitignore_updated = False
    if args.update_gitignore and vcs == "git":
        gitignore_updated = update_gitignore(root)

    print(f"SKIIS context ready: {context_dir}")
    print(f"VCS: {vcs}")
    print(f"Architecture: {architecture_path}")
    if created:
        print("Created/updated:")
        for path in created:
            print(f"  - {path}")
    else:
        print("No template files needed changes.")
    if gitignore_updated:
        print("Updated .gitignore with docs/ai-context/")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Initialize SKIIS docs/ai-context files.")
    parser.add_argument("--root", default=os.getcwd(), help="Project root. Defaults to current directory.")
    parser.add_argument("--sync-architecture", action="store_true", help="Overwrite architecture.md.")
    parser.add_argument("--update-gitignore", action="store_true", help="Add docs/ai-context/ to .gitignore in Git repos.")
    parser.add_argument("--plain-context", action="store_true", help="Use docs/ai-context/ directly even in Git repos.")
    return parser


def main() -> int:
    return initialize(build_parser().parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
