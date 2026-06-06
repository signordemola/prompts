---
name: subagent-driven-development
description: "Use when executing implementation plans with independent tasks in the current session"
---

# Subagent-Driven Development

Execute plans by dispatching a fresh subagent per task, with two-stage review after each: spec compliance first, then code quality.

**Why subagents:** Fresh context per task prevents pollution. Precisely crafted instructions ensure focus. Preserves your own context for coordination.

**Announce at start:** "I'm using the subagent-driven-development workflow to execute this plan."

<HARD-GATE>
**⛔ MANDATORY — DO NOT STOP BETWEEN TASKS.**
Continuous execution. Do not pause to check in with the user between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts waste their time — they asked you to execute the plan, so execute it.
</HARD-GATE>

## When to Use

- Have an implementation plan with independent tasks
- Tasks can be worked on without shared state
- You want high-quality output with automated review

**vs. executing-plans:** Use this when subagents are available. Use executing-plans when they're not.

## The Process

### Step 1: Load and Prepare

1. Read the plan file
2. Extract ALL tasks with full text
3. Note context and dependencies between tasks
4. Create a task checklist

### Step 2: Per-Task Cycle

For EACH task in the plan:

**2a. Dispatch Implementer Subagent**

Give the subagent ONLY what it needs (not your full conversation):
- Full text of the task (paste it, don't make them read the file)
- Context: where this fits, dependencies, architecture
- Working directory
- Instructions: implement, test (TDD if specified), commit, self-review, report back

**2b. Handle Questions**

If the implementer asks questions: answer them with context, then let them continue.

If the implementer can't proceed: mark task as BLOCKED, move to next task.

**2c. Dispatch Spec Reviewer Subagent**

<HARD-GATE>
**⛔ MANDATORY — DO NOT TRUST THE IMPLEMENTER'S REPORT.**
The implementer finished suspiciously quickly. Their report may be incomplete, inaccurate, or optimistic. The spec reviewer MUST verify everything independently.

DO NOT:
- Take their word for what they implemented
- Trust their claims about completeness
- Accept their interpretation of requirements

DO:
- Read the actual code they wrote
- Compare against the task requirements line by line
- Run the tests yourself
- Check edge cases mentioned in the spec
</HARD-GATE>

If spec review fails → implementer fixes gaps.

**2d. Dispatch Code Quality Reviewer Subagent**

Only dispatch AFTER spec compliance passes. Check:
- Clean separation of concerns
- Proper error handling
- Tests verify real behavior (not mocks)
- DRY without premature abstraction
- Each file has one clear responsibility

If quality review fails → implementer fixes issues.

**2e. Mark Task Complete**

Mark task as done in checklist. Move to next task without pausing.

### Step 3: Final Review

After ALL tasks complete:
1. Dispatch a final code reviewer for the entire implementation
2. Invoke the `verification-before-completion` workflow
3. Invoke the `finishing-branch` workflow

## Subagent Prompt Templates

### Implementer

```
You are implementing Task N: [task name]

## Task Description
[FULL TEXT of task from plan]

## Context
[Where this fits, dependencies, architecture]

## Your Job
1. Implement exactly what the task specifies
2. Write tests (following TDD if task says to)
3. Verify implementation works
4. Commit your work
5. Self-review: did you do exactly what was asked?
6. Report back: what you built, what you tested, any concerns

If anything is unclear: ASK. Don't guess.
```

### Spec Reviewer

```
You are reviewing whether an implementation matches its specification.

## What Was Requested
[FULL TEXT of task requirements]

## What Implementer Claims
[From implementer's report]

Verify EVERYTHING independently. Read the actual code. Don't trust the report.

Verdict: PASS (matches spec) or FAIL (with specific gaps)
```

### Code Quality Reviewer

```
You are reviewing code quality for completed work.

Review the git diff. Check: separation of concerns, error handling,
test quality (real behavior not mocks), DRY, edge cases.

Categorize: Critical (must fix) / Important (should fix) / Minor (nice to fix)
```
