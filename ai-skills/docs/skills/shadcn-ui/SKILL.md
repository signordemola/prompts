---
name: shadcn-ui
description: >
  shadcn/ui component installation and theming. ACTIVATE when: adding UI
  components, setting up a design system, customising themes, or using the
  shadcn CLI. Covers presets, registries, and component patterns.
---

# shadcn/ui Skill

## When to Use
- Adding shadcn/ui components to a project
- Setting up a design system with presets
- Customising theme colors or typography
- Installing components from external registries

## Always Load First
- `skills/tailwind-css/SKILL.md`
- `skills/code-style/SKILL.md`

## Setup

```bash
npx shadcn@latest init
```

With a preset:

```bash
npx shadcn@latest init --preset <code>
```

## Adding Components

```bash
npx shadcn@latest add button
npx shadcn@latest add card dialog form input
```

From a GitHub registry:

```bash
npx shadcn@latest add <user>/<repo>/<item>
```

## Safe Updates

```bash
npx shadcn@latest add button --diff
npx shadcn@latest add button --dry-run
```

## Presets

Apply or switch a preset on an existing project:

```bash
npx shadcn@latest apply --preset <code>
```

Presets package colors, fonts, radius, and icon libraries into a single code string.

## Theming

Theme with CSS variables in your globals.css:

```css
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 222.2 47.4% 11.2%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96.1%;
  --secondary-foreground: 222.2 47.4% 11.2%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --accent: 210 40% 96.1%;
  --accent-foreground: 222.2 47.4% 11.2%;
  --destructive: 0 84.2% 60.2%;
  --border: 214.3 31.8% 91.4%;
  --radius: 0.5rem;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
}
```

## Theme Switching

```tsx
"use client"

import { useTheme } from "next-themes"
import { Button } from "@/components/ui/button"

export const ThemeToggle = () => {
  const { theme, setTheme } = useTheme()

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
    >
      {theme === "dark" ? "☀️" : "🌙"}
    </Button>
  )
}
```

## RTL Support

```bash
npx shadcn@latest migrate rtl
```

Converts `ml-4` → `ms-4`, `text-left` → `text-start` automatically.

## Component Customisation

shadcn components live in your codebase (`components/ui/`). Edit them directly. Do not modify anything in `node_modules`.

```tsx
import { Button } from "@/components/ui/button"

<Button variant="default">Save</Button>
<Button variant="outline">Cancel</Button>
<Button variant="destructive">Delete</Button>
<Button variant="ghost" size="icon">×</Button>
```

## CLI Commands

| Command | Purpose |
|---------|---------|
| `npx shadcn@latest init` | Scaffold project |
| `npx shadcn@latest init --preset <id>` | Scaffold with preset |
| `npx shadcn@latest apply --preset <id>` | Switch preset |
| `npx shadcn@latest add <component>` | Install component |
| `npx shadcn@latest add <user>/<repo>/<item>` | Install from registry |
| `npx shadcn@latest add <component> --diff` | View changes |
| `npx shadcn@latest migrate rtl` | Convert to RTL |

## NEVER
- ❌ Modify shadcn source in `node_modules`
- ❌ Use raw Radix/Base UI when shadcn has the component
- ❌ Hardcode colors instead of using CSS variable tokens
- ❌ Skip `--diff` when updating components with local changes
