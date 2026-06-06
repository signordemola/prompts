---
name: dispatching-parallel-agents
description: "Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies"
---

# Dispatching Parallel Agents

When you have multiple unrelated problems, investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other (editing same files)

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:
- File A tests: Authentication flow
- File B tests: Payment processing
- File C tests: Email notifications

Each domain is independent — fixing auth doesn't affect email tests.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** one test file or subsystem
- **Clear goal:** make these tests pass / fix this bug
- **Constraints:** don't change code outside your scope
- **Expected output:** summary of what you found and fixed

### 3. Dispatch in Parallel

```
Agent 1: "Fix authentication flow tests in auth.test.ts"
Agent 2: "Fix payment processing tests in payment.test.ts"  
Agent 3: "Fix email notification tests in email.test.ts"
```

### 4. Collect Results

After all agents complete:
- Review each agent's changes for conflicts
- Run full test suite to check for interference
- If conflicts exist: resolve manually, don't re-dispatch
- If all clean: merge and verify

### 5. Handle Failures

If an agent fails:
- Check if failure is related to another agent's domain
- If related → combine into single sequential investigation
- If independent → retry with more context
