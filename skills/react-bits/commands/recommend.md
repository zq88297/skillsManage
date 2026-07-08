# /react-bits — Recommend React Bits Components

Match the current design style to React Bits components and present install-ready recommendations.

## Workflow

### Step 1: Detect Input

Check what the user provided in order of priority:

1. **MASTER.md path** — If user mentions "MASTER.md", "design system file", or a file path, read it with the Read tool and extract the style section
2. **Style name** — If user says "glassmorphism", "brutalism", "cyberpunk", etc., use it directly
3. **Implicit from context** — Check if a recent design skill (ui-ux-pro-max, frontend-design) just ran and what style it produced
4. **Ask** — If nothing is clear, ask: "What design style are you working with? (e.g., glassmorphism, brutalism, minimalism)"

### Step 2: Run Match Engine

```bash
python skills/react-bits/scripts/match.py --style "<style-name>"
```

If the user has additional preferences, add flags:
- `--category <text|animation|component|background>` — filter by category
- `--motion <1-10>` — filter by motion intensity
- `--format json` — for structured output

### Step 3: Present Results

Organize the output for the user:

1. **Show the match**: "For [Style Name], here are the recommended React Bits components:"
2. **By category**: Group recommendations by Text Animations / Animations / Components / Backgrounds
3. **Tier priority**: Highlight primary (首选) vs secondary (备选)
4. **Install commands**: Provide copy-paste-ready `npx shadcn@latest add` commands
5. **Integration snippet**: Show how to wire design tokens to the key component props

### Step 4: Offer Follow-ups

- "Want me to install any of these components?"
- "Should I generate a full integration code example for [specific component]?"
- "Need matching components in a different category?"
- "Want me to save these recommendations alongside your MASTER.md?"

## Output Format

Present results as a structured recommendation with:

```
🎨 [Style Name] → React Bits Recommendations

🔤 Text Animations (N components)
| Priority | Component | Install | Motion | Why |
|----------|-----------|---------|--------|-----|
| ⭐ Primary | ComponentName | `npx shadcn...` | X/10 | Description |

✨ Animations (N components)
...

🧩 Components (N components)
...

🌄 Backgrounds (N components)
...

📥 One-Click Install:
(all commands concatenated)

🔗 Integration Example:
(JSX with design token props)
```

## Integration Notes

- Default variant is `TS-TW` (TypeScript + Tailwind) — most projects use this
- Each component has 4 variant suffixes: `-JS-CSS`, `-JS-TW`, `-TS-CSS`, `-TS-TW`
- Components install to `@/components/react-bits/` by default (shadcn convention)
- Check component dependencies (motion, gsap, three) before installing — ensure project compatibility
- Some components need additional setup (e.g., Three.js components need `<Canvas>` wrapper)
