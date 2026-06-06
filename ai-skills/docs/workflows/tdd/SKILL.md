---
name: tdd
description: "Use when implementing any feature or bugfix, before writing implementation code"
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

<HARD-GATE>
Write code before the test? Delete it. Start over. Don't keep it as "reference". Don't "adapt" it while writing tests. Don't look at it. Delete means delete. Implement fresh from tests. Period.
</HARD-GATE>

## When to Use

**Always:** New features, bug fixes, refactoring, behavior changes.

**Exceptions (ask your human partner):** Throwaway prototypes, generated code, configuration files.

Thinking "skip TDD just this once"? Stop. That's rationalization.

## Red-Green-Refactor

### RED — Write Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };
  const result = await retryOperation(operation);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing.
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});
```
Vague name, tests mock not code.
</Bad>

**Requirements:** One behavior. Clear name. Real code (no mocks unless unavoidable).

### Verify RED — Watch It Fail

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

Test passes immediately? You're testing existing behavior. Fix the test.

### GREEN — Minimal Code

Write the simplest code to pass the test.

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try { return await fn(); }
    catch (e) { if (i === 2) throw e; }
  }
  throw new Error('unreachable');
}
```
Just enough to pass.
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: { maxRetries?: number; backoff?: 'linear' | 'exponential'; }
): Promise<T> { /* YAGNI */ }
```
Over-engineered. No test asked for options.
</Bad>

Don't add features, refactor other code, or "improve" beyond the test.

### Verify GREEN — Watch It Pass

**MANDATORY.**

Confirm: test passes, other tests still pass, output clean.

Test fails? Fix code, not test. Other tests fail? Fix now.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers.

Keep tests green. Don't add behavior.

### Repeat

Next failing test for next behavior.

## Framework-Specific Commands

| Framework | Run tests | Watch mode |
|-----------|----------|------------|
| **Next.js** | `npx vitest run` | `npx vitest` |
| **NestJS** | `npx jest --passWithNoTests` | `npx jest --watch` |
| **FastAPI** | `uv run pytest -xvs` | `uv run ptw -- -xvs` |

## Anti-Patterns (see references/testing-anti-patterns.md)

- ❌ Testing mock behavior instead of real behavior
- ❌ Adding test-only methods to production classes
- ❌ Mocking without understanding dependencies
