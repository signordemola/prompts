---
name: self-improvement
description: "Use in TWO situations: (1) DURING WORK when you hit a gap or make a mistake — log it to .ai-skills/LESSONS.md. (2) WHEN USER SAYS 'reflect' — generate REFLECTION.md and PROPOSED-CHANGES.md summarizing all lessons from the project."
---

# Self-Improvement — Log & Reflect

This workflow has two modes: **logging** (during work) and **reflecting** (end of project).

## Mode 1: Logging (During Work)

When you make a mistake, hit a gap, or discover a pattern — append to `.ai-skills/LESSONS.md`.

**Trigger:** Rule 8 in AGENTS.md fires automatically.

**Format:** Append this block to `.ai-skills/LESSONS.md` (create if missing):

```markdown
## [DATE] — [CATEGORY]
**What happened:** [Brief description]
**Root cause:** [Why the library didn't prevent this]
**Which skill:** [skill name or "NONE — new skill needed"]
**Severity:** CRITICAL | IMPORTANT | MINOR
```

### Categories

| Category | When |
|----------|------|
| `GATE-MISS` | A HARD-GATE didn't fire when it should have |
| `PATTERN-GAP` | No skill covers this pattern |
| `STALE-EXAMPLE` | Code example is outdated or wrong |
| `FRAMEWORK-BIAS` | Skill assumed wrong framework |
| `MISSING-EDGE-CASE` | Happy path only, edge case missing |
| `NEW-PATTERN` | Discovered a reusable pattern |

<HARD-GATE>
**⛔ MANDATORY — LOG, DON'T JUST FIX.**
When you fix a bug that the library should have prevented, you MUST log it. Fixing only the code means the next agent makes the same mistake.
</HARD-GATE>

---

## Mode 2: Reflecting (End of Project)

**Trigger:** User says "reflect", "generate lessons", or "what did we learn?"

**Announce:** "I'm generating a project reflection and proposed skill changes."

### Step 1: Read Context

Read these files:
- `.ai-skills/LESSONS.md` (accumulated during work)
- Your own session history (what you built, what struggled)
- Which skills from `.ai-skills/docs/` you actually used

### Step 2: Generate REFLECTION.md

Write `.ai-skills/REFLECTION.md`:

```markdown
# Reflection — [Project Name] ([Date])

## What Worked
- [Skill/pattern that saved time or prevented bugs]
- [Workflow that improved quality]

## What Didn't Work
- [Skill gap that caused a bug or wasted time]
- [Pattern that was wrong or outdated]

## Mistakes Made
- [Each mistake from LESSONS.md, summarized]

## New Patterns Discovered
- [Pattern worth adding to the library]
- [Include code examples if relevant]

## Recommendations
- [Specific skills to update, with priority]
```

### Step 3: Generate PROPOSED-CHANGES.md

Write `.ai-skills/PROPOSED-CHANGES.md` with **specific, actionable diffs**:

```markdown
# Proposed Skill Changes

## 1. [skill-name/SKILL.md] — [What to change]
**Priority:** CRITICAL | IMPORTANT | MINOR
**Action:** UPDATE | NEW SECTION | NEW SKILL

### Current (what's there now):
\```
[existing code/text]
\```

### Proposed (what it should be):
\```
[updated code/text]
\```

### Why:
[What went wrong because this was missing/wrong]
```

<HARD-GATE>
**⛔ MANDATORY — PROPOSED CHANGES MUST BE SPECIFIC.**
Every proposed change must include the exact file, the exact section, and the exact replacement text. "Update the stripe skill" is not acceptable. "Add Luxon section after line 45 of timezone-safety/SKILL.md with this code: ..." is acceptable.
</HARD-GATE>

### Step 4: Report to User

After generating both files, tell the user:

```
✅ Reflection complete.

Files generated:
  .ai-skills/REFLECTION.md         — Summary of what we learned
  .ai-skills/PROPOSED-CHANGES.md   — Specific skill updates to review

To push these lessons to GitHub:
  bash .ai-skills/push-lessons.sh

Then open ~/Documents/prompts with a good model and say:
  "Apply approved lessons from issue #N"
```
