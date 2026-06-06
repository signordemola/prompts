---
name: finishing-branch
description: "Use when implementation is complete, all tests pass, and you need to integrate the work"
---

# Finishing a Development Branch

Guide completion of development work by verifying tests, presenting options, and executing the chosen workflow.

**Announce at start:** "I'm using the finishing-branch workflow to complete this work."

## The Iron Law

```
NO MERGE WITHOUT PASSING TESTS
```

<HARD-GATE>
If tests fail, you cannot proceed to merge/PR options. Fix failures first.
</HARD-GATE>

## Step 1: Verify Tests

```bash
# Run the project's test suite
npm test        # Next.js / NestJS
uv run pytest   # FastAPI
```

If tests fail: report failures and stop. Cannot proceed until green.

## Step 2: Detect Environment

Determine workspace state:

| State | Menu | Cleanup |
|-------|------|---------|
| Normal repo | 4 options | No worktree |
| Named branch worktree | 4 options | Clean up worktree |
| Detached HEAD | 3 options (no merge) | No cleanup |

## Step 3: Present Options

**Normal repo:**
```
Implementation complete. What would you like to do?

1. Merge back to main locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Don't add explanation — keep options concise.

## Step 4: Execute Choice

### Option 1: Merge Locally
```bash
git checkout main
git merge --no-ff <branch-name>
```

### Option 2: Push and Create PR
```bash
git push -u origin <branch-name>
# Create PR with summary of changes
```

### Option 3: Keep As-Is
Report: branch name, current commit, what was implemented.

### Option 4: Discard
```bash
git checkout main
git branch -D <branch-name>
```

Confirm with user before discarding.

## Step 5: Report

After completing the chosen option:

```
## Summary
- Branch: [name]
- Action: [merge/PR/keep/discard]
- Tests: [pass count]
- Files changed: [count]
```
