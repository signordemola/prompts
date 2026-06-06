# Testing Anti-Patterns

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

**Core principle:** Test what the code does, not what the mocks do.

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

<Bad>
```typescript
// Testing that the mock exists — tells you nothing
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```
You're verifying the mock works, not that the component works.
</Bad>

<Good>
```typescript
// Test real component behavior
test('renders sidebar', () => {
  render(<Page />);  // Don't mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```
</Good>

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real behavior or just mock existence?"
  IF testing mock existence:
    STOP — Delete the assertion or unmock the component
```

## Anti-Pattern 2: Test-Only Methods in Production

<Bad>
```typescript
// destroy() only used in tests — pollutes production class
class Session {
  async destroy() {
    await this._workspaceManager?.destroyWorkspace(this.id);
  }
}
afterEach(() => session.destroy());
```
</Bad>

<Good>
```typescript
// Test utilities handle test cleanup — Session stays clean
// In test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) await workspaceManager.destroyWorkspace(workspace.id);
}
afterEach(() => cleanupSession(session));
```
</Good>

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"
  IF yes: STOP — Put it in test utilities instead

  Ask: "Does this class own this resource's lifecycle?"
  IF no: STOP — Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

<Bad>
```typescript
// Mock prevents config write that test depends on!
vi.mock('ToolCatalog', () => ({
  discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
}));
// Later: test fails because config file was never written
```
</Bad>

### Gate Function

```
BEFORE adding any mock:
  1. Trace what the mocked function does
  2. List ALL side effects being suppressed
  3. Ask: "Does the test depend on any suppressed side effect?"
  IF yes: Don't mock it, or mock more precisely
```
