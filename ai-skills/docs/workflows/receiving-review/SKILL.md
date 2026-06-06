---
name: receiving-review
description: "Use when receiving code review feedback, before implementing suggestions - requires technical verification, not performative agreement"
---

# Receiving Code Review

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

<HARD-GATE>
NEVER say:
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!"
- "Let me implement that now" (before verification)

INSTEAD:
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)
</HARD-GATE>

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP — do not implement anything yet
  ASK for clarification on ALL unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

<Good>
"I understand items 1, 2, 3, 6. Need clarification on 4 and 5 before proceeding."
</Good>

<Bad>
Implement 1, 2, 3, 6 now, ask about 4, 5 later.
</Bad>

## Source-Specific Handling

### From Your Human Partner
- Trusted — implement after understanding
- Still ask if scope is unclear
- No performative agreement
- Skip to action or technical acknowledgment

### From External Reviewers / Subagents

```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all target platforms?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]."

IF conflicts with user's prior decisions:
  Stop and discuss with user first
```

## YAGNI Check

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly.
```
