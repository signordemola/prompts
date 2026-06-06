---
name: requesting-review
description: "Use when completing tasks, implementing major features, or before merging to verify work meets requirements"
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context — never your session's history.

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

## How to Request

### 1. Get git SHAs

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

### 2. Dispatch Code Reviewer Subagent

```
You are a Senior Code Reviewer. Review completed work against
its requirements and identify issues before they cascade.

## What Was Implemented
{brief description of what was built}

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

## Calibration
Categorize by actual severity. Not everything is Critical.
Acknowledge what was done well before listing issues.
```

### 3. Act on Feedback

- **Critical** — fix immediately
- **Important** — fix before proceeding
- **Minor** — note for later
- **Push back** — if reviewer is wrong, explain with technical reasoning
