---
name: tailwind-css
description: >
  Tailwind CSS v4 patterns and configuration. ACTIVATE when: setting up Tailwind,
  customising design tokens, migrating from v3, or writing utility classes.
  Covers CSS-first config, @theme directive, and modern utility patterns.
---

# Tailwind CSS Skill

## When to Use
- Setting up Tailwind CSS in a new project
- Migrating from Tailwind v3 to v4
- Customising colors, fonts, spacing, or breakpoints
- Writing responsive or dark mode styles

## Always Load First
- `skills/code-style/SKILL.md`

<HARD-GATE>
**⛔ MANDATORY — TAILWIND V4 USES CSS-FIRST CONFIGURATION.**
Do not create `tailwind.config.js`. Define all design tokens inside `@theme {}`
in your main CSS file. Do not use `@tailwind base/components/utilities` directives.
</HARD-GATE>

## Setup

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
  --color-primary-foreground: #ffffff;
  --color-secondary: #64748b;
  --color-accent: #f59e0b;
  --color-background: #ffffff;
  --color-foreground: #0f172a;
  --color-muted: #f1f5f9;
  --color-muted-foreground: #64748b;
  --color-destructive: #ef4444;
  --color-border: #e2e8f0;

  --font-family-sans: "Inter", sans-serif;
  --font-family-display: "Outfit", sans-serif;
  --font-family-mono: "JetBrains Mono", monospace;

  --breakpoint-3xl: 1920px;
  --radius-lg: 0.75rem;
  --radius-md: 0.5rem;
  --radius-sm: 0.25rem;
}
```

## Dark Mode

```css
@import "tailwindcss";

@theme {
  --color-background: #ffffff;
  --color-foreground: #0f172a;
}

@theme dark {
  --color-background: #0f172a;
  --color-foreground: #f8fafc;
}
```

```tsx
<html className="dark">
```

## Migration from v3

```bash
npx @tailwindcss/upgrade
```

This handles ~90% of the migration automatically:

| v3 | v4 |
|----|----|
| `tailwind.config.js` | `@theme {}` in CSS |
| `@tailwind base` | `@import "tailwindcss"` |
| `bg-gradient-to-r` | `bg-linear-to-r` |
| `postcss-import` | Remove (auto-handled) |
| `autoprefixer` | Remove (auto-handled) |

## PostCSS Config

```js
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
}
```

No other plugins needed. Tailwind v4 handles imports and vendor prefixes.

## Custom Utilities

```css
@utility scrollbar-hidden {
  &::-webkit-scrollbar {
    display: none;
  }
  scrollbar-width: none;
}
```

## Container Queries

```html
<div class="@container">
  <div class="@sm:grid-cols-2 @lg:grid-cols-3">
  </div>
</div>
```

## NEVER
- ❌ Create `tailwind.config.js` (v3 pattern)
- ❌ Use `@tailwind base`, `@tailwind components`, `@tailwind utilities`
- ❌ Install `postcss-import` or `autoprefixer` (auto-handled in v4)
- ❌ Use `bg-gradient-to-*` (renamed to `bg-linear-to-*`)
- ❌ Use hardcoded color values instead of `@theme` tokens
