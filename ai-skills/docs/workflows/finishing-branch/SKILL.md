---
name: finishing-branch
description: "Use when implementation is complete, all tests pass, and you need to integrate the work. Don't use if tests are still failing — fix them first."
---

# Finishing a Development Branch

Guide completion of development work by verifying tests, cleaning up, and integrating.

**Announce at start:** "I'm using the finishing-branch workflow to complete this work."

## The Iron Law

```
NO MERGE WITHOUT PASSING TESTS
```

<HARD-GATE>
**⛔ MANDATORY GATE — ALL TESTS MUST PASS BEFORE ANY MERGE/PR ACTION.**
If tests fail, you cannot proceed. Fix failures first.
</HARD-GATE>

## Step 0: Run Verification

If you haven't already run the `verification` workflow, do it now. Don't skip this step because you "think" it passes.

## Step 1: Verify Tests

```bash
# Run the project's test suite
npm test        # Next.js / NestJS
npx jest --passWithNoTests   # NestJS alternative
uv run pytest   # FastAPI
```

If tests fail: report failures and stop. Cannot proceed until green.

## Step 2: Pre-Merge Cleanup

Before presenting options, clean up your work:

```
☐ Remove all debug logs (console.log, print, debugger)
☐ Remove all TODO/FIXME comments that were addressed
☐ Remove unused imports
☐ Ensure no hardcoded test values (API keys, URLs, passwords)
☐ Verify .env.example is updated if new env vars were added
```

## Step 3: Commit Message Format

Use conventional commits:

```
feat: add payment webhook handler
fix: prevent double-booking on concurrent requests
chore: update Prisma schema for order status enum
refactor: extract deposit calculation to shared utility
test: add integration tests for cancellation flow
docs: update API endpoint documentation
```

Format: `<type>: <imperative description>`

## Step 4: Detect Environment

Determine workspace state:

```bash
git branch --show-current     # Current branch name (empty if detached)
git worktree list             # Active worktrees
git status                    # Uncommitted changes
```

| State | Menu | Cleanup |
|-------|------|---------|
| Normal repo | 4 options | No worktree |
| Named branch worktree | 4 options | Clean up worktree |
| Detached HEAD | 3 options (no merge) | No cleanup |

## Step 5: Present Options

```
Implementation complete. What would you like to do?

1. Merge back to main locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Don't add explanation — keep options concise.

## Step 6: Execute Choice

### Option 1: Merge Locally
```bash
git checkout main
git merge --no-ff <branch-name> -m "feat: <description>"
```

### Option 2: Push and Create PR
```bash
git push -u origin <branch-name>
```

PR description template:
```markdown
## What
Brief description of what was implemented.

## Why
Link to spec/issue or brief rationale.

## Changes
- List of key changes by component

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual verification done
```

### Option 3: Keep As-Is
Report: branch name, current commit, what was implemented.

### Option 4: Discard
```bash
git checkout main
git branch -D <branch-name>
```

Confirm with user before discarding.

## Step 7: Report

```
## Summary
- Branch: [name]
- Action: [merge/PR/keep/discard]
- Commit: [type: description]
- Tests: [pass count]
- Files changed: [count]
```
