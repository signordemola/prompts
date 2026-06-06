# Root Cause Tracing

**Load this reference when:** debugging deep call stacks, unclear where invalid data originates.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

## When to Use

- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated

## The Tracing Process

### 1. Observe the Symptom
```
Error: git init failed in ~/project/packages/core
```

### 2. Find Immediate Cause
```typescript
await execFileAsync('git', ['init'], { cwd: projectDir });
// What is projectDir? Where did it come from?
```

### 3. Ask: What Called This?
```
WorktreeManager.createSessionWorktree(projectDir, sessionId)
  → called by Session.initializeWorkspace()
  → called by Session.create()
  → called by test at Project.create()
```

### 4. Keep Tracing Up
```
projectDir = '' (empty string!)
Empty string as cwd resolves to process.cwd()
That's the source code directory — wrong!
```

### 5. Find Original Trigger
```typescript
const context = setupCoreTest(); // Returns { tempDir: '' }
Project.create('name', context.tempDir); // Accessed before beforeEach!
```

**Root cause:** Test setup timing issue — `tempDir` accessed before `beforeEach` sets it.
**Fix at source:** Move access into the test body, after setup completes.
**NOT at symptom:** Don't add a `projectDir` null check in `WorktreeManager`.

## Adding Instrumentation

When you can't trace manually, add temporary logging:

```typescript
// At each layer boundary
console.log(`[Layer 1] projectDir = "${projectDir}"`);
console.log(`[Layer 2] cwd resolved to = "${path.resolve(projectDir)}"`);
```

Run once → read output → identify failing layer → investigate that layer.

**Remove instrumentation after debugging.** Don't commit debug logs.
