#!/usr/bin/env python3
"""
React Bits Component Matcher - Maps design styles to React Bits components.

Usage:
    python match.py --style "glassmorphism"
    python match.py --style "brutalism" --category components
    python match.py --style "cyberpunk" --motion 8 --format json
    python match.py --design-system path/to/MASTER.md
    python match.py --tokens '{"style":"Minimalism","motion":3}'
    python match.py --all --category backgrounds
    python match.py --list-styles
    python match.py --list-categories
"""

import argparse
import csv
import json
import os
import re
import sys
from pathlib import Path

# Fix Windows console encoding for emoji output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ── Paths ──────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / "data"
COMPONENTS_CSV = DATA_DIR / "components.csv"
STYLE_MAPPINGS_CSV = DATA_DIR / "style_mappings.csv"

# ── Constants ──────────────────────────────────────────────────────
CATEGORIES = ["Text Animations", "Animations", "Components", "Backgrounds"]
CATEGORY_ALIASES = {
    "text": "Text Animations",
    "animation": "Animations",
    "component": "Components",
    "background": "Backgrounds",
    "textanimations": "Text Animations",
    "all": None,
}
VARIANT_SUFFIX = "TS-TW"  # Default variant: TypeScript + Tailwind

# ── Data Loading ───────────────────────────────────────────────────

def load_components():
    """Load the full component catalog from CSV."""
    components = []
    if not COMPONENTS_CSV.exists():
        print(f"Error: components.csv not found at {COMPONENTS_CSV}", file=sys.stderr)
        return components

    with open(COMPONENTS_CSV, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row["Motion Level"] = int(row.get("Motion Level", 5))
            components.append(row)
    return components


def load_style_mappings():
    """Load style-to-component mappings from CSV."""
    mappings = []
    if not STYLE_MAPPINGS_CSV.exists():
        print(f"Error: style_mappings.csv not found at {STYLE_MAPPINGS_CSV}", file=sys.stderr)
        return mappings

    with open(STYLE_MAPPINGS_CSV, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            mappings.append(row)
    return mappings


# ── Matching Engine ────────────────────────────────────────────────

def normalize_style_name(name):
    """Normalize style name for fuzzy matching."""
    return name.lower().strip().replace(" & ", " ").replace("  ", " ")


def find_style_mapping(style_name, mappings):
    """Find the best matching style mapping entry."""
    normalized = normalize_style_name(style_name)

    # Exact match first
    for m in mappings:
        if normalize_style_name(m["Style Name"]) == normalized:
            return m

    # Partial match (style name contains query or vice versa)
    for m in mappings:
        mn = normalize_style_name(m["Style Name"])
        if normalized in mn or mn in normalized:
            return m

    # Keyword match in style name
    words = normalized.split()
    for m in mappings:
        mn = normalize_style_name(m["Style Name"])
        if any(w in mn for w in words if len(w) > 3):
            return m

    return None


def find_component(name, components):
    """Find a component by name (case-insensitive)."""
    name_lower = name.strip().lower()
    for c in components:
        if c["Component Name"].strip().lower() == name_lower:
            return c
    return None


def match_components(style_name, components, mappings, motion_level=None, category=None):
    """Match components to a design style.

    Returns a dict with style info and categorized component recommendations.
    """
    result = {
        "style_name": style_name,
        "matched_style": None,
        "recommendations": {},
        "install_commands": [],
        "notes": {"color": "", "motion": ""},
    }

    # Find style mapping
    mapping = find_style_mapping(style_name, mappings)

    if mapping:
        result["matched_style"] = mapping["Style Name"]
        result["notes"]["color"] = mapping.get("Color Notes", "")
        result["notes"]["motion"] = mapping.get("Motion Notes", "")

        primary = [s.strip() for s in mapping["Primary Components"].split(";") if s.strip()]
        secondary = [s.strip() for s in mapping["Secondary Components"].split(";") if s.strip()]
        avoid = [s.strip() for s in mapping.get("Avoid Components", "").split(";") if s.strip()]

        # Categorize and look up full component info
        for comp_name in primary:
            comp = find_component(comp_name, components)
            if comp:
                cat = comp["Category"]
                if cat not in result["recommendations"]:
                    result["recommendations"][cat] = {"primary": [], "secondary": []}
                result["recommendations"][cat]["primary"].append({**comp, "tier": "primary"})

        for comp_name in secondary:
            comp = find_component(comp_name, components)
            if comp:
                cat = comp["Category"]
                if cat not in result["recommendations"]:
                    result["recommendations"][cat] = {"primary": [], "secondary": []}
                result["recommendations"][cat]["secondary"].append({**comp, "tier": "secondary"})
    else:
        # No mapping found - fall back to keyword search
        result["matched_style"] = style_name
        keywords = normalize_style_name(style_name).replace("-", " ").split()
        result["notes"]["color"] = "No curated mapping found. Using keyword-based search."
        result["notes"]["motion"] = "No curated mapping found. Default motion level (5) used."

        for comp in components:
            comp_text = f"{comp['Component Name']} {comp['Keywords']} {comp['Visual Style']}".lower()
            score = sum(1 for kw in keywords if kw in comp_text)
            if score > 0:
                cat = comp["Category"]
                if cat not in result["recommendations"]:
                    result["recommendations"][cat] = {"primary": [], "secondary": []}
                tier = "primary" if score >= 2 else "secondary"
                result["recommendations"][cat][tier].append({**comp, "tier": tier})

    # Filter by motion level if specified
    if motion_level is not None:
        for cat in list(result["recommendations"].keys()):
            for tier in ["primary", "secondary"]:
                if tier in result["recommendations"][cat]:
                    result["recommendations"][cat][tier] = [
                        c for c in result["recommendations"][cat][tier]
                        if abs(c["Motion Level"] - motion_level) <= 3
                    ]
            # Remove empty categories
            if not result["recommendations"][cat].get("primary") and not result["recommendations"][cat].get("secondary"):
                del result["recommendations"][cat]

    # Filter by category if specified
    if category:
        filtered = {}
        for cat in result["recommendations"]:
            if category.lower() in cat.lower():
                filtered[cat] = result["recommendations"][cat]
        result["recommendations"] = filtered

    # Generate install commands
    for cat, tiers in result["recommendations"].items():
        for comp in tiers.get("primary", []) + tiers.get("secondary", []):
            cmd = f"npx shadcn@latest add @react-bits/{comp['Component Name']}-{VARIANT_SUFFIX}"
            if cmd not in result["install_commands"]:
                result["install_commands"].append(cmd)

    return result


# ── Output Formatters ──────────────────────────────────────────────

def format_markdown(result):
    """Format recommendations as Markdown."""
    lines = []
    style = result.get("matched_style", result["style_name"])

    lines.append(f"## 🎨 {style} → React Bits 组件推荐")
    lines.append("")

    if result["notes"]["color"]:
        lines.append(f"**色彩适配**: {result['notes']['color']}")
        lines.append("")
    if result["notes"]["motion"]:
        lines.append(f"**动效适配**: {result['notes']['motion']}")
        lines.append("")

    if not result["recommendations"]:
        lines.append("> ⚠️ 未找到匹配的组件。请尝试不同的风格名称或使用 `--list-styles` 查看所有可用风格。")
        return "\n".join(lines)

    category_emoji = {
        "Text Animations": "🔤",
        "Animations": "✨",
        "Components": "🧩",
        "Backgrounds": "🌄",
    }

    for cat in CATEGORIES:
        if cat not in result["recommendations"]:
            continue

        emoji = category_emoji.get(cat, "📦")
        lines.append(f"### {emoji} {cat}")
        lines.append("")

        # Primary first
        primary = result["recommendations"][cat].get("primary", [])
        if primary:
            lines.append("| 优先级 | 组件 | 安装命令 | 动效等级 | 匹配理由 |")
            lines.append("|--------|------|---------|---------|---------|")
            for comp in primary:
                lines.append(
                    f"| ⭐ 首选 | **{comp['Component Name']}** | "
                    f"`npx shadcn@latest add @react-bits/{comp['Component Name']}-{VARIANT_SUFFIX}` | "
                    f"{comp['Motion Level']}/10 | {comp['Description']} |"
                )
            lines.append("")

        secondary = result["recommendations"][cat].get("secondary", [])
        if secondary:
            if not primary:
                lines.append("| 优先级 | 组件 | 安装命令 | 动效等级 | 匹配理由 |")
                lines.append("|--------|------|---------|---------|---------|")
            for comp in secondary:
                lines.append(
                    f"| 备选 | **{comp['Component Name']}** | "
                    f"`npx shadcn@latest add @react-bits/{comp['Component Name']}-{VARIANT_SUFFIX}` | "
                    f"{comp['Motion Level']}/10 | {comp['Description']} |"
                )
            lines.append("")

    # Install all commands
    lines.append("---")
    lines.append("")
    lines.append("### 📥 一键安装所有推荐组件")
    lines.append("")
    lines.append("```bash")
    for cmd in result["install_commands"][:15]:  # Limit to avoid overwhelming
        lines.append(cmd)
    lines.append("```")
    lines.append("")

    # Integration code
    lines.append("---")
    lines.append("")
    lines.append("### 🔗 设计 Token 集成示例")
    lines.append("")
    lines.append("```tsx")
    lines.append("// 将设计系统 CSS 变量注入 React Bits 组件")

    # Pick a representative primary component for example
    example_comp = None
    for cat in CATEGORIES:
        if cat in result["recommendations"]:
            primary = result["recommendations"][cat].get("primary", [])
            if primary:
                example_comp = primary[0]
                break

    if example_comp:
        comp_name = example_comp["Component Name"]
        lines.append(f"import {comp_name} from '@/components/react-bits/{comp_name}';")
        lines.append("")
        lines.append(f"<{comp_name}")
        lines.append("  style={{")

        if "glass" in style.lower() or "glass" in str(example_comp.get("Visual Style", "")).lower():
            lines.append("    backgroundColor: 'rgba(var(--color-primary-rgb), 0.15)',")
            lines.append("    backdropFilter: 'blur(12px)',")
            lines.append("    borderColor: 'rgba(255, 255, 255, 0.2)',")
        elif "dark" in style.lower():
            lines.append("    backgroundColor: 'var(--color-background)',")
            lines.append("    color: 'var(--color-foreground)',")
        else:
            lines.append("    '--color-primary': 'var(--color-primary)',")
            lines.append("    '--color-background': 'var(--color-background)',")

        lines.append("    borderRadius: 'var(--radius-lg)',")
        lines.append("  }}")
        lines.append("/>")
    else:
        lines.append("// 将设计系统的 CSS 自定义属性传递给组件")
        lines.append("// 参考上方推荐表中的具体安装命令")

    lines.append("```")
    lines.append("")

    return "\n".join(lines)


def format_json(result):
    """Format recommendations as JSON."""
    # Clean up for JSON serialization
    output = {
        "style_name": result["style_name"],
        "matched_style": result["matched_style"],
        "notes": result["notes"],
        "recommendations": {},
        "install_commands": result["install_commands"],
    }

    for cat, tiers in result["recommendations"].items():
        output["recommendations"][cat] = {
            "primary": [
                {
                    "name": c["Component Name"],
                    "description": c["Description"],
                    "motion_level": c["Motion Level"],
                    "dependencies": c["Dependencies"],
                    "install": f"npx shadcn@latest add @react-bits/{c['Component Name']}-{VARIANT_SUFFIX}",
                }
                for c in tiers.get("primary", [])
            ],
            "secondary": [
                {
                    "name": c["Component Name"],
                    "description": c["Description"],
                    "motion_level": c["Motion Level"],
                    "dependencies": c["Dependencies"],
                    "install": f"npx shadcn@latest add @react-bits/{c['Component Name']}-{VARIANT_SUFFIX}",
                }
                for c in tiers.get("secondary", [])
            ],
        }

    return json.dumps(output, ensure_ascii=False, indent=2)


def format_text(result):
    """Format recommendations as plain text."""
    lines = []
    style = result.get("matched_style", result["style_name"])
    lines.append(f"[{style}] React Bits Component Recommendations")
    lines.append("=" * 60)

    for cat in CATEGORIES:
        if cat not in result["recommendations"]:
            continue
        lines.append(f"\n--- {cat} ---")
        primary = result["recommendations"][cat].get("primary", [])
        secondary = result["recommendations"][cat].get("secondary", [])

        for comp in primary:
            lines.append(f"  [PRIMARY] {comp['Component Name']} (Motion: {comp['Motion Level']}/10)")
            lines.append(f"    {comp['Description']}")
            lines.append(f"    npx shadcn@latest add @react-bits/{comp['Component Name']}-{VARIANT_SUFFIX}")

        for comp in secondary:
            lines.append(f"  [SECONDARY] {comp['Component Name']} (Motion: {comp['Motion Level']}/10)")
            lines.append(f"    {comp['Description']}")
            lines.append(f"    npx shadcn@latest add @react-bits/{comp['Component Name']}-{VARIANT_SUFFIX}")

    return "\n".join(lines)


# ── MASTER.md Parser ───────────────────────────────────────────────

def parse_master_md(filepath):
    """Extract style name and motion level from a MASTER.md file."""
    path = Path(filepath)
    if not path.exists():
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        return None

    content = path.read_text(encoding="utf-8")

    # Extract style name from markdown headers or Style section
    style_patterns = [
        r'##\s+Style\s*\n.*?\*\*Name\*\*:\s*([^\n]+)',  # MASTER.md style section
        r'###\s+Style\s*\n.*?\*\*Name\*\*:\s*([^\n]+)',
        r'Style:\s*([^\n]+)',  # Simple key-value
        r'style:\s*([^\n]+)',
        r'\*\*Style\*\*:\s*([^\n]+)',
        r'##\s+🎨\s+([^\n]+)',  # Emoji-marked style header
    ]

    style_name = None
    for pattern in style_patterns:
        match = re.search(pattern, content, re.IGNORECASE)
        if match:
            style_name = match.group(1).strip()
            # Clean up common suffixes
            style_name = re.sub(r'\s*\(.*?\)', '', style_name).strip()
            break

    # Extract motion level
    motion_level = None
    motion_patterns = [
        r'--motion\s+(\d+)',
        r'Motion\s*(?:Level|Dial|Intensity)?:\s*(\d+)',
        r'motion:\s*(\d+)',
        r'\*\*Motion\*\*:\s*(\d+)',
    ]
    for pattern in motion_patterns:
        match = re.search(pattern, content, re.IGNORECASE)
        if match:
            motion_level = int(match.group(1))
            break

    return {
        "style_name": style_name,
        "motion_level": motion_level,
        "filepath": str(path),
    }


# ── CLI ────────────────────────────────────────────────────────────

def list_styles():
    """Print all available style names."""
    mappings = load_style_mappings()
    print("Available Design Styles:")
    print("=" * 40)
    for i, m in enumerate(mappings, 1):
        print(f"  {i:2d}. {m['Style Name']}")


def list_categories():
    """Print all component categories with counts."""
    components = load_components()
    print("React Bits Component Categories:")
    print("=" * 40)
    for cat in CATEGORIES:
        count = len([c for c in components if c["Category"] == cat])
        print(f"  {cat}: {count} components")


def list_all_components(category=None):
    """Print all React Bits components."""
    components = load_components()
    if category:
        cat_name = CATEGORY_ALIASES.get(category.lower(), category)
        components = [c for c in components if c["Category"].lower() == cat_name.lower()]

    for cat in CATEGORIES:
        cat_comps = [c for c in components if c["Category"] == cat]
        if not cat_comps:
            continue
        print(f"\n--- {cat} ({len(cat_comps)}) ---")
        for c in cat_comps:
            print(f"  {c['Component Name']} [{c['Motion Level']}/10] - {c['Description']}")


def main():
    parser = argparse.ArgumentParser(
        description="React Bits Component Matcher - Maps design styles to React Bits components",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python match.py --style "glassmorphism"
  python match.py --style "brutalism" --category components --format json
  python match.py --design-system design-system/my-project/MASTER.md
  python match.py --tokens '{"style_name":"Minimalism","motion_level":3}'
  python match.py --all --category backgrounds
  python match.py --list-styles
        """,
    )

    # Input sources (mutually exclusive group logic handled manually)
    parser.add_argument("--style", "-s", type=str, help="Design style name (e.g., 'glassmorphism', 'brutalism')")
    parser.add_argument("--design-system", "-d", type=str, help="Path to MASTER.md generated by ui-ux-pro-max --persist")
    parser.add_argument("--tokens", "-t", type=str, help="JSON string with design tokens (style_name, motion_level)")
    parser.add_argument("--all", "-a", action="store_true", help="List all React Bits components")
    parser.add_argument("--output-file", "-o", type=str, help="Save recommendations to file (e.g., .claude/context/components.md)")
    parser.add_argument("--context-dir", "-C", type=str, help="Path to .claude/context/ for reading design.md + writing components.md")

    # Filters
    parser.add_argument("--category", "-c", type=str, help="Filter by category: text, animation, component, background")
    parser.add_argument("--motion", "-m", type=int, help="Target motion level (1-10)")

    # Output
    parser.add_argument("--format", "-f", type=str, choices=["markdown", "json", "text"], default="markdown",
                        help="Output format (default: markdown)")

    # Info
    parser.add_argument("--list-styles", action="store_true", help="List all available design styles")
    parser.add_argument("--list-categories", action="store_true", help="List component categories with counts")

    args = parser.parse_args()

    # Handle info commands
    if args.list_styles:
        list_styles()
        return
    if args.list_categories:
        list_categories()
        return

    # Load data
    components = load_components()
    mappings = load_style_mappings()

    if not components:
        print("Error: No components loaded. Check components.csv.", file=sys.stderr)
        sys.exit(1)

    # Handle --all
    if args.all:
        list_all_components(args.category)
        return

    # Determine input source
    style_name = None
    motion_level = args.motion

    if args.design_system:
        parsed = parse_master_md(args.design_system)
        if parsed:
            style_name = parsed["style_name"]
            if parsed["motion_level"] and not args.motion:
                motion_level = parsed["motion_level"]
            if not style_name:
                print(f"Warning: Could not extract style name from {args.design_system}", file=sys.stderr)
                print("Falling back to keyword search with filename...", file=sys.stderr)
                style_name = Path(args.design_system).stem
    elif args.tokens:
        try:
            tokens = json.loads(args.tokens)
            style_name = tokens.get("style_name") or tokens.get("style") or tokens.get("name")
            if not motion_level:
                motion_level = tokens.get("motion_level") or tokens.get("motion")
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in --tokens: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.style:
        style_name = args.style

    # If --context-dir provided, try reading design.md for style info
    if args.context_dir:
        context_path = Path(args.context_dir)
        design_md = context_path / "design.md"
        if design_md.exists() and not style_name:
            print(f"Reading design context from {design_md}...", file=sys.stderr)
            parsed = parse_master_md(str(design_md))
            if parsed and parsed.get("style_name"):
                style_name = style_name or parsed["style_name"]
                if not motion_level and parsed.get("motion_level"):
                    motion_level = parsed["motion_level"]
                print(f"  → Detected style: {style_name}, motion: {motion_level}", file=sys.stderr)
            else:
                # Fallback: search for style keywords in design.md
                content = design_md.read_text(encoding="utf-8")
                for m in mappings:
                    mn = m["Style Name"].lower()
                    if mn in content.lower():
                        style_name = style_name or m["Style Name"]
                        print(f"  → Detected style from content: {style_name}", file=sys.stderr)
                        break

    if not style_name:
        print("Error: No style specified. Use --style, --design-system, --tokens, --all, or --context-dir.", file=sys.stderr)
        parser.print_help()
        sys.exit(1)

    # Resolve category alias
    category = None
    if args.category:
        category = CATEGORY_ALIASES.get(args.category.lower(), args.category)

    # Match
    result = match_components(style_name, components, mappings, motion_level, category)

    # Determine output format content
    if args.format == "json":
        output_content = format_json(result)
    elif args.format == "text":
        output_content = format_text(result)
    else:
        output_content = format_markdown(result)

    # Print to stdout
    print(output_content)

    # Write to output file if specified
    output_file = args.output_file
    if args.context_dir and not output_file:
        output_file = str(Path(args.context_dir) / "components.md")

    if output_file:
        out_path = Path(output_file)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        timestamp = __import__('datetime').datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        header = f"# React Bits 组件推荐报告\n> 匹配时间: {timestamp}\n> 设计风格: {result.get('matched_style', style_name)}\n\n"
        out_path.write_text(header + output_content, encoding="utf-8")
        print(f"\n> 📄 推荐报告已保存到: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
