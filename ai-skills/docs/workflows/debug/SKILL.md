---
name: debug
description: "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes"
---

# Systematic Debugging

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Announce at start:** "I'm using the systematic debugging workflow."

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

<HARD-GATE>
**⛔ MANDATORY GATE — NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**
If you haven't completed Phase 1, you cannot propose fixes. "Just one quick fix" is not a phase. Guessing is not investigating. An obvious fix you haven't verified is still a guess.
</HARD-GATE>

## When to Use

Use for ANY technical issue: test failures, bugs, unexpected behavior, performance problems, build failures, integration issues.

**Use this ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- You don't fully understand the issue

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - `git log -5`, `git diff`
   - New dependencies, config changes
   - Environmental differences (dev vs prod)

4. **Gather Evidence in Multi-Component Systems**
   For EACH component boundary:
   - Log what data enters the component
   - Log what data exits the component
   - Run once to see WHERE it breaks
   - THEN investigate that specific component

5. **Trace Data Flow** (see `references/root-cause-tracing.md`)
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

1. **Find Working Examples** — locate similar working code in the codebase
2. **Compare Against References** — read reference implementation COMPLETELY, don't skim
3. **Identify Differences** — list every difference, however small
4. **Understand Dependencies** — what does this component need? What assumptions does it make?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** — "I think X is the root cause because Y"
2. **Write it down** — be specific, not vague
3. **Test Minimally** — make the SMALLEST possible change to test your hypothesis
4. **If wrong** → go back to Phase 1 with new information. Don't guess again.
5. **If correct** → proceed to Phase 4

### Phase 4: Fix and Verify

1. **Apply minimum fix** — only what resolves the root cause
2. **Write a regression test** — Red-Green: test should fail without fix, pass with fix
3. **Run full test suite** — confirm no new breakage
4. **If new failures** → the fix is wrong. Go back to Phase 3.

## Framework-Specific Debug Tools

| Framework | Debugger | Logging |
|-----------|----------|---------|
| **Next.js** | Chrome DevTools, `debugger` | `console.log`, React DevTools |
| **NestJS** | `--inspect` flag, VS Code | Pino logger, `Logger` service |
| **FastAPI** | `debugpy`, VS Code | `structlog`, `logging` module |

## Companion Files

- `references/root-cause-tracing.md` — backward tracing technique
- `references/defense-in-depth.md` — multi-layer validation patterns
