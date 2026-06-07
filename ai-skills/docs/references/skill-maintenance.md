# Skill Maintenance System

## Monthly Review Cycle

Run this on the **1st of each month**. Takes ~30 minutes.

### Step 1: Score each skill (1–5)

| Score | Meaning |
|-------|---------|
| 5 | Agent follows perfectly, zero bugs from this area |
| 4 | Agent follows mostly, occasional minor deviation |
| 3 | Agent follows sometimes, needs reminding |
| 2 | Agent often ignores or misapplies |
| 1 | Skill is ineffective, agent does its own thing |

### Step 2: Review log

| Month | Skill | Score | Issue Found | Action Taken |
|-------|-------|-------|-------------|-------------|
| Jun 2026 | (initial release) | — | — | — |
| | | | | |

### Step 3: Improvement priorities

After scoring, improve the **lowest-scoring skill first**. Common fixes:
- Score 2–3: Add more concrete examples (input → output pairs)
- Score 2–3: Add "NEVER" section with the exact mistake the agent made
- Score 1–2: Rewrite as shorter, more imperative steps
- Any score: Add the bug to `common-mistakes.md`

---

## Test Prompts

Use these prompts to test if agents follow each skill correctly.
**Run each prompt with a fresh context** to see if the skill triggers.

### nextjs-app-router
```
"Create a new page that displays a list of services from the database."
```
✅ Should: Use Server Component, async/await, no "use client"
❌ Fail: Adds "use client", uses useEffect + fetch

### prisma-database
```
"Add a new service priced at £45 with a £15 deposit."
```
✅ Should: Seed as `price: 4500, deposit: 1500` (pence)
❌ Fail: Uses `price: 45, deposit: 15` (pounds)

### timezone-safety
```
"Query all appointments for June 15th in the dashboard."
```
✅ Should: Use `providerDateOnly("2026-06-15")` directly, NOT `startOfDay()`
❌ Fail: Uses `startOfDay()` or `new Date("2026-06-15")`

### stripe-payments
```
"Create the Stripe PaymentIntent for the booking deposit."
```
✅ Should: Use `amount: service.deposit` directly (already pence)
❌ Fail: Uses `amount: service.deposit * 100`

### security-hardening
```
"Implement the owner login endpoint."
```
✅ Should: Use SHA-256 via `crypto`, HttpOnly/Secure cookie
❌ Fail: Uses argon2, or stores token in localStorage

### input-validation
```
"Handle the booking form submission in the API route."
```
✅ Should: Define Zod schema, `safeParse()`, return 400 on invalid
❌ Fail: Uses `req.body` directly without validation

### data-fetching
```
"Show today's appointments on the dashboard page."
```
✅ Should: Async Server Component, direct Prisma query
❌ Fail: Client Component with useEffect + fetch

### email-notifications
```
"Send a confirmation email after booking."
```
✅ Should: Include ICS attachment, manage link, prep instructions
❌ Fail: Plain text email with no ICS or manage link

### deployment-vercel
```
"Deploy the app to Vercel."
```
✅ Should: Mention RESEND_API_KEY needs Build scope, webhook setup
❌ Fail: Only mentions Runtime env vars

### mobile-ux
```
"Build the time slot selection grid."
```
✅ Should: 44px+ tap targets, single column on mobile
❌ Fail: Small buttons, side-by-side layout

### seo-performance
```
"Add SEO to the service page."
```
✅ Should: Next.js `metadata` export + JSON-LD script
❌ Fail: Manual `<head>` tags or missing structured data

### state-management
```
"Implement the multi-step booking wizard state."
```
✅ Should: Zustand with persist, reset on confirmation
❌ Fail: useState across components, no persist, no reset

### error-handling
```
"The dashboard crashes on first load after deploy."
```
✅ Should: Identify as Neon cold start, add error boundary with retry
❌ Fail: Generic error page, no retry, no cold-start detection

### booking (domain)
```
"Build the slot availability endpoint."
```
✅ Should: Load timezone-safety first, use providerDateOnly, check holds + appointments, 15min buffer
❌ Fail: Uses `new Date()`, ignores holds, no buffer

---

## When to Improve vs When to Leave Alone

| Situation | Action |
|-----------|--------|
| Agent made a bug that a skill should have prevented | Add the bug to the skill's NEVER section + common-mistakes.md |
| Agent ignored a skill entirely | Improve the YAML `description` field (trigger phrases) |
| Skill is too long (>150 lines) | Move details to `references/`, keep SKILL.md procedural |
| New pattern discovered (library update, etc.) | Update the relevant skill + add a dated note |
| Agent follows skill but output is mediocre | Add concrete examples (before/after code) |
| Skill scores 5 for 3+ months | Leave it alone |
