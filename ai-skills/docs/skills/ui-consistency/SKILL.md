---
name: ui-consistency
description: >
  Captures and enforces visual patterns across sessions. ACTIVATE after building
  any UI component, or when UI looks inconsistent across the project. Maintains
  ui-registry.md so every future component matches what already exists.
---

# UI Consistency Skill

## When to Use
- After building or modifying any UI component
- When UI looks visually inconsistent across the project
- At the start of a project with existing UI that was not tracked

## Always Load First
- `skills/code-style/SKILL.md`

## The Problem

AI builds each component in isolation. It does not remember what it built three
sessions ago. Spacing drifts. Colors vary. Border radius is inconsistent. The app
looks like it was built by multiple people with different tastes.

## Capture Mode

After building any UI component:

### Step 1: Find what was just built

Read the component that was just created or modified.

### Step 2: Extract visual patterns

Extract only what affects consistency across the interface:

| Extract | Skip |
|---------|------|
| Background classes | Width and height |
| Border color, width, style | Flex and grid layout |
| Border radius | Positioning (absolute, z-index) |
| Text colors (primary, secondary, muted) | Animation timing |
| Text sizes and weights | Responsive breakpoint variants |
| Spacing (padding, gap) | |
| Interactive states (hover, focus, active) | |
| Shadow | |
| Accent or brand color usage | |

### Step 3: Write to ui-registry.md

Open `ui-registry.md` in the project root. Create it if it does not exist.
Append a new entry. If an entry for this component type exists, update it.

```markdown
### [Component Name]

File: [filepath]
Last updated: [date]

| Property       | Value         |
|----------------|---------------|
| Background     | [class/token] |
| Border         | [class/token] |
| Border radius  | [class/token] |
| Text primary   | [class/token] |
| Text secondary | [class/token] |
| Spacing        | [class/token] |
| Hover state    | [class/token] |
| Shadow         | [class or none] |
| Accent usage   | [class or none] |
```

### Step 4: Confirm

```
Captured [Component Name] → ui-registry.md
```

Flag anything that looked inconsistent with existing entries.

## Audit Mode

Run when UI already exists and consistency is uncertain.

### Step 1: Scan all UI components

Read every component file. Build a picture of all visual patterns in use.

### Step 2: Identify conflicts

For each visual property, list every variation found:

- Border radius variants and which components use each
- Background color classes and any hardcoded hex values
- Text color classes
- Spacing variations
- Border color classes
- Interactive state patterns

### Step 3: Wait for confirmation

Present the audit report. Do not fix anything. Do not update ui-registry.md.

Ask which recommendations to accept and which conflicts to resolve differently.

### Step 4: Write the confirmed baseline

After confirmation, write the agreed baseline to `ui-registry.md` as the foundation.

### Step 5: List what needs fixing

Produce a list of every component that deviates from the baseline:

```
- [Component file] — [what is wrong] → [what it should be]
```

## How It Gets Used

At the start of any session involving UI work, read `ui-registry.md` before
writing any component. Match existing patterns exactly. The registry grows as
the project grows.

## NEVER
- ❌ Skip capturing after building a UI component
- ❌ Ignore existing registry entries when building new components
- ❌ Use hardcoded hex values when design tokens exist
- ❌ Fix audit findings without developer confirmation
