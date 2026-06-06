---
name: input-validation
description: >
  Input validation and sanitisation patterns. ACTIVATE when: handling form data,
  API request bodies, query parameters, or any user-provided input. Covers Zod
  schemas, XSS prevention, and server-side validation.
---

# Input Validation Skill

## When to Use
- Processing form submissions
- Handling API request bodies or query parameters
- Rendering user-generated content
- Building intake forms

## Instructions

### Step 1: Define Zod schemas for ALL inputs (Zod v4)
```ts
import { z } from "zod"

export const ClientSchema = z.object({
  name: z.string().check(
    z.minLength(1, "Name required"),
    z.maxLength(100),
    z.trim()
  ),
  email: z.email("Invalid email"),
  phone: z.string().check(z.regex(/^[\d\s\+\-\(\)]+$/, "Invalid phone")).optional(),
  notes: z.string().check(z.maxLength(500)).optional(),
})
```

> **Zod v4 changes:** `z.email()` and `z.url()` are standalone constructors. Use `.check()` for chaining validations. Errors use unified `error` param.

### Step 2: Validate server-side ALWAYS
```ts
const result = ClientSchema.safeParse(await req.json())
if (!result.success) {
  return NextResponse.json(
    { error: "Invalid input", details: result.error.flatten() },
    { status: 400 }
  )
}
const { name, email, phone } = result.data  // typed + sanitised
```

### Step 3: Sanitise before rendering
- React auto-escapes JSX by default (safe from XSS)
- ❌ NEVER use `dangerouslySetInnerHTML` with user content
- If you must render HTML (CMS content), use `isomorphic-dompurify`

### Step 4: Client-side validation is UX only
```tsx
<input required minLength={1} maxLength={100} autoComplete="name" />
```
Client validation improves UX but is NOT security. Server validates.

### Step 5: Use correct React 19 event types
```tsx
// ✅ React 19+ — use semantically correct types
function onSubmit(e: SubmitEvent<HTMLFormElement>) { ... }
function onChange(e: ChangeEvent<HTMLInputElement>) { ... }

// ❌ DEPRECATED — FormEvent doesn't exist in the DOM
// function onSubmit(e: React.FormEvent<HTMLFormElement>) { ... }
```

## NEVER
- ❌ Trust client-side validation for security
- ❌ Pass raw request body to Prisma `where` clauses
- ❌ Use `dangerouslySetInnerHTML` with user input
- ❌ Accept prices or amounts from the client
