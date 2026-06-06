---
name: security-hardening
description: >
  Security patterns for web applications. ACTIVATE when: implementing auth,
  handling user input, reviewing security, setting up headers, or hardening
  API routes. Covers OWASP Top 10, auth patterns, CSRF, rate limiting, and
  security headers.
---

# Security Hardening Skill

## When to Use
- Implementing authentication or authorization
- Handling any user input (forms, query params, API bodies)
- Setting up middleware or security headers
- Reviewing code for vulnerabilities
- Deploying to production

## Instructions

### Step 1: Authentication
- Single-owner demos: SHA-256 via Node `crypto` + HttpOnly cookie
- Multi-user: Auth.js (NextAuth.js) or Better Auth
- **NEVER use argon2** on serverless — native bindings fail on Vercel
- `bcryptjs` (pure JS) is safe for serverless

```ts
// SHA-256 hash generation
import { createHash } from "crypto"
const hash = createHash("sha256").update(password).digest("hex")
```

### Step 2: Validate ALL input server-side with Zod
```ts
import { z } from "zod"

const BookingSchema = z.object({
  name: z.string().min(1).max(100).trim(),
  email: z.string().email(),
  phone: z.string().optional(),
})

// In API route or Server Action
const result = BookingSchema.safeParse(body)
if (!result.success) return NextResponse.json({ error: "Invalid input" }, { status: 400 })
```

### Step 3: Security headers (next.config)
```ts
headers: [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
]
```

### Step 4: Cookie security
```ts
cookies().set("owner-token", token, {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
  path: "/",
  maxAge: 60 * 60 * 24, // 24 hours
})
```

### Step 5: Rate limiting
- Rate limit slot hold endpoints (prevent slot exhaustion attacks)
- Rate limit checkout endpoints (prevent payment spam)
- Rate limit login endpoints (prevent brute force)

### Step 6: OWASP checklist
- [ ] All queries parameterised (Prisma does this by default)
- [ ] No raw user objects in `where` clauses
- [ ] Secrets in env vars, never in code
- [ ] Error messages generic (no stack traces in production)
- [ ] CORS properly configured
- [ ] HTTPS enforced

## NEVER
- ❌ Use `NEXT_PUBLIC_` for sensitive keys (DB URL, API secrets)
- ❌ Use `eval()` or `innerHTML` with user input
- ❌ Trust client-side validation alone
- ❌ Log sensitive data (passwords, tokens, card numbers)
- ❌ Use sequential IDs for manage tokens (use cuid/nanoid)
