---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing - requires running verification commands and confirming output before making any success claims"
---

# Verification Before Completion

Claiming work is complete without verification is dishonesty, not efficiency.

**Announce at start:** "I'm using the verification-before-completion workflow."

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

<HARD-GATE>
Skip any step = lying, not verifying.
</HARD-GATE>

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim
```

## Common Failures

| Claim | Requires | NOT Sufficient |
|-------|----------|----------------|
| "Tests pass" | Test command output: 0 failures | Previous run, "should pass" |
| "Linter clean" | Linter output: 0 errors | Partial check, extrapolation |
| "Build succeeds" | Build command: exit 0 | Linter passing, "logs look good" |
| "Bug fixed" | Test original symptom: passes | Code changed, assumed fixed |
| "Regression test works" | Red-green cycle verified | Test passes once |
| "Agent completed" | VCS diff shows changes | Agent reports "success" |
| "Requirements met" | Line-by-line checklist | Tests passing |

## Red Flags — STOP Immediately

If you catch yourself doing any of these, STOP:

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit/push/PR without verification
- Trusting agent success reports without checking
- Relying on a previous run instead of a fresh one
- Extrapolating from partial results ("3 tests pass so all 10 probably do")

## Framework-Specific Verification

| Framework | Test | Lint | Build |
|-----------|------|------|-------|
| **Next.js** | `npx vitest run` | `npx -y react-doctor@latest .` | `npm run build` |
| **NestJS** | `npx jest --passWithNoTests` | `npx tsc --noEmit` | `npm run build` |
| **FastAPI** | `uv run pytest -xvs` | `uv run ruff check . && uv run pyright app` | `uv run python -m compileall -q app` |

## After Verification

Report honestly:

```
## What Changed
- [list]

## What Was Verified
- [exact commands run, exact output]

## What Was Skipped
- [anything not tested]

## Remaining Risks
- [known edge cases, areas without coverage]
```

## Next Step

After verification passes → invoke the `finishing-branch` workflow to integrate the work.
