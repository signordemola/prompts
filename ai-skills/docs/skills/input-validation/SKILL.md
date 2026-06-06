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

### Step 1: Define Zod schemas for ALL inputs
```ts
import { z } from "zod"

export const ClientSchema = z.object({
  name: z.string().min(1, "Name required").max(100).trim(),
  email: z.string().email("Invalid email"),
  phone: z.string().regex(/^[\d\s\+\-\(\)]+$/, "Invalid phone").optional(),
  notes: z.string().max(500).optional(),
})
```

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

## NEVER
- ❌ Trust client-side validation for security
- ❌ Pass raw request body to Prisma `where` clauses
- ❌ Use `dangerouslySetInnerHTML` with user input
- ❌ Accept prices or amounts from the client
