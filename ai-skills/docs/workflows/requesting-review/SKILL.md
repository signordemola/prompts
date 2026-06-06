---
name: requesting-review
description: "Use when completing tasks, implementing major features, or before merging to verify work meets requirements. Don't use during implementation — finish the task first, then request review."
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context — never your session's history.

**Announce at start:** "I'm requesting a code review before proceeding."

**Core principle:** Review early, review often.

## When to Request

**Mandatory:**
- After each task in subagent-driven-development
- After completing a major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## Step 1: Self-Review First

Before dispatching a reviewer, run through this checklist yourself. Don't waste a reviewer's time on things you can catch:

```
☐ Code compiles / lints without errors
☐ All tests pass
☐ No debug logs, console.log, or TODO comments left in
☐ No hardcoded values (API keys, test data, magic numbers)
☐ No unused imports or dead code
☐ Changes match the spec — nothing extra, nothing missing
```

## Step 2: Assess Diff Size

| Diff Size | Action |
|-----------|--------|
| <200 lines | Single review pass |
| 200-500 lines | Split review by component if possible |
| >500 lines | **Must split** — review in logical chunks (e.g., schema changes → API → UI) |

Large diffs get shallow reviews. Split them for quality feedback.

## Step 3: Get Git SHAs

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

## Step 4: Dispatch Code Reviewer Subagent

Use this template — adapt the domain/framework context to the specific project:

```
You are a Senior Code Reviewer. Review completed work against
its requirements and identify issues before they cascade.

## What Was Implemented
{brief description of what was built}

## Domain Context
This is a {booking/ecommerce/chatbot} project using {Next.js/NestJS/FastAPI}.
Key domain rules: {e.g., "prices in pence, never accept amount from client"}

## Requirements
{what it should do — from the plan or spec}

## Git Range
Base: {BASE_SHA}
Head: {HEAD_SHA}

## What to Check
- Plan alignment: does implementation match spec?
- Code quality: clean separation, error handling, type safety?
- Architecture: sound design, security, scalability?
- Testing: tests verify real behavior (not mocks)? Edge cases?
- Production readiness: migrations, backward compat, docs?
- Domain rules: are domain-specific patterns followed?

## Calibration
Categorize by actual severity. Not everything is Critical.
Acknowledge what was done well before listing issues.
```

## Step 5: Act on Feedback

- **Critical** — fix immediately, re-request review
- **Important** — fix before proceeding
- **Minor** — note for later, don't block on these
- **Push back** — if reviewer is wrong, explain with technical reasoning. Don't blindly accept all feedback.

<HARD-GATE>
**⛔ MANDATORY — CRITICAL ISSUES MUST BE FIXED BEFORE PROCEEDING.**
You cannot dismiss Critical findings without the user's explicit approval.
</HARD-GATE>
