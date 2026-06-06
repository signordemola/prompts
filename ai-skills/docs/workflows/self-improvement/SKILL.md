---
name: self-improvement
description: "Use AFTER completing any task where the agent made a mistake, hit a gap in the library, or discovered a pattern worth preserving. Also use when the user says 'log this', 'remember this', or 'update the skills'."
---

# Self-Improvement — Feedback Loop

When you make a mistake, discover a gap, or learn something new, **log it** so the library improves over time.

**Announce at start:** "I'm logging a lesson learned for the ai-skills library."

## The Iron Law

```
EVERY MISTAKE BECOMES A LIBRARY UPDATE — NOT JUST A CODE FIX
```

<HARD-GATE>
**⛔ MANDATORY — DO NOT SILENTLY FIX AND MOVE ON.**
When you hit a gap or make a mistake that the library should have prevented, you MUST log it. Fixing only the code means the next agent will make the same mistake.
</HARD-GATE>

## When to Trigger

- You made a mistake the library should have caught
- You discovered a pattern not covered by any skill
- A HARD-GATE didn't fire when it should have
- A skill's code examples were wrong or outdated
- The user says "remember this" or "log this" or "update the skills"
- You wasted time because context was missing

## Step 1: Log the Lesson

Append to `docs/LESSONS.md` in the project (create if it doesn't exist):

```markdown
## [DATE] — [Category]

**What happened:** [Brief description of the mistake or gap]
**Root cause:** [Why the library didn't prevent this]
**Which skill should have caught it:** [skill name or "NONE — new skill needed"]
**Proposed fix:**
- [ ] [Specific change to make to the skill/reference]

**Severity:** [CRITICAL / IMPORTANT / MINOR]
```

### Categories

| Category | Examples |
|----------|---------|
| `GATE-MISS` | HARD-GATE didn't fire, wrong trigger conditions |
| `PATTERN-GAP` | No skill covers this pattern |
| `STALE-EXAMPLE` | Code example is outdated or wrong |
| `FRAMEWORK-BIAS` | Skill assumed Next.js but project uses NestJS |
| `MISSING-EDGE-CASE` | Skill covers the happy path but not the edge case |
| `NEW-PATTERN` | Discovered a reusable pattern worth preserving |

## Step 2: Propose the Fix

After logging, propose the specific skill change:

<Good>
```
LESSONS.md entry:
  What: Agent used float for price calculation, caused rounding errors
  Root cause: prisma-database skill says "use Int for money" but drizzle-database skill didn't
  Fix: Add monetary values rule to drizzle-database/SKILL.md NEVER section
  Severity: CRITICAL
```
</Good>

<Bad>
```
LESSONS.md entry:
  What: Something went wrong with prices
  Fix: Be more careful next time
  — Vague, no actionable fix, will happen again
```
</Bad>

## Step 3: Apply Upstream (if access)

If you have write access to the master repo (`signordemola/prompts`):

1. Make the skill change directly
2. Remove the lesson from `LESSONS.md` (it's now in the skill)
3. Commit: `fix(skills): [skill-name] — [what was fixed]`

If you DON'T have write access (client project):

1. Keep the lesson in project-local `docs/LESSONS.md`
2. At the end of the session, summarize pending lessons for the user
3. The user can apply them to the master repo later

## Step 4: Periodic Review

At the **start of every new project session**, check if `docs/LESSONS.md` exists:

- If it has entries → read them before starting work
- Unresolved lessons are context you need
- CRITICAL lessons should be applied immediately

## Lesson → Skill Mapping

| If the lesson is about... | Update this... |
|---------------------------|---------------|
| A workflow that didn't fire | The `description` field in YAML frontmatter |
| Missing code pattern | Add to the relevant skill's examples |
| Framework-specific issue | Add framework section to the skill |
| Edge case not covered | Add to the skill's edge cases / NEVER section |
| Entirely new topic | Create a new skill or reference file |
| Wrong architecture advice | Update the domain orchestrator |
