---
name: recovery
description: >
  Diagnoses what type of failure occurred before deciding how to respond.
  ACTIVATE when: a build has gone wrong, multiple fix attempts have failed,
  the agent is going in circles, or the implementation approach is fundamentally
  wrong. Three responses: targeted fix, hard reset, or rethink.
---

# Recovery Workflow

## When to Use
- Something broke and you are about to start fixing it
- Multiple fix attempts have made things worse
- The agent is patching patches
- The implementation approach itself seems wrong

## Step 1: Describe what went wrong

Before doing anything, understand:
- What was expected to happen?
- What happened instead?
- How many fix attempts have already been made?

The number of fix attempts determines which failure mode this is.

## Step 2: Identify the failure mode

### Failure Mode 1 — A specific thing is broken

**Signs:**
- Problem is isolated to one component, function, or route
- Rest of the project works
- First or second fix attempt
- Error message or wrong behaviour is clear

**Response:** Targeted fix → Step 3A

### Failure Mode 2 — The session has gone wrong

**Signs:**
- Multiple fix attempts have made things worse or created new problems
- Code is tangled — fixes are patching fixes
- No longer clear what the original problem was
- Context is polluted with failed attempts

**Response:** Hard reset → Step 3B

### Failure Mode 3 — The foundation is wrong

**Signs:**
- Code runs but produces fundamentally wrong behaviour
- A core requirement, library API, or architectural pattern was misunderstood
- Fixing individual pieces will not help
- The approach itself is incorrect

**Response:** Rethink → Step 3C

State which failure mode applies before proceeding:

```
This is Failure Mode [1/2/3] — [name].
[One sentence explaining why.]
```

## Step 3A — Targeted Fix

For Failure Mode 1.

1. Read only the relevant code
2. Identify the root cause (not the symptom)
3. State the root cause clearly before suggesting any fix
4. Suggest a precise fix that addresses the root cause
5. Wait for confirmation before making changes

If the fix does not work, re-examine the root cause. If two diagnoses have both
been wrong, re-evaluate — this may actually be Failure Mode 2 or 3.

## Step 3B — Hard Reset

For Failure Mode 2.

This session cannot be saved by patching. Save what is worth keeping and start
fresh.

Write a reset note:

```markdown
## Reset Note — [Feature Name]

### What we were building
[Original feature description]

### What went wrong
[Honest summary of how things went off track]

### What to avoid next time
[Specific approaches or patterns that did not work]

### Starting point for next session
[Where to begin fresh — what to keep, what to discard]
```

Then:
1. Save the reset note
2. End the current approach completely
3. Start fresh with the reset note as context

## Step 3C — Rethink

For Failure Mode 3.

1. Name the wrong assumption:

```
Assumed: [what was assumed]
Reality: [what is actually true]

The current implementation cannot be fixed by patching.
The approach needs to change.
```

2. Propose the correct approach:
   - What the approach should have been
   - What needs to be discarded
   - What can be kept

3. Wait for confirmation before any rebuilding

## The Principle

Different failures need different responses. The worst thing you can do when
something is broken is keep doing the same thing faster.

Diagnose first. Respond correctly.

## NEVER
- ❌ Start fixing before diagnosing the failure mode
- ❌ Keep patching after two failed fix attempts without re-evaluating
- ❌ Continue in a polluted session when a hard reset is needed
- ❌ Rebuild without confirming the correct approach first
