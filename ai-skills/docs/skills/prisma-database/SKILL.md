---
name: prisma-database
description: >
  Prisma ORM and PostgreSQL patterns. ACTIVATE when: modifying schema.prisma,
  writing database queries, handling currency/prices, seeding data, or setting
  up migrations. Covers type-safe queries, currency in smallest unit, connection
  pooling, and serverless PostgreSQL (Neon) patterns.
---

# Prisma Database Skill

## When to Use
- Creating or modifying `schema.prisma`
- Writing any Prisma query (findMany, create, update, etc.)
- Handling prices, deposits, or currency values
- Seeding the database
- Debugging connection issues (cold starts, timeouts)

## Instructions

### Step 1: Currency is ALWAYS in smallest unit (pence/cents)
| Source | Unit | Example |
|--------|------|---------|
| DB `price` / `deposit` fields | pence | `2000` = £20 |
| Stripe `amount` | pence (direct from DB) | `2000` |
| `studio-data.ts` (display only) | pounds | `20` = £20 |

```ts
// ✅ CORRECT — DB value goes directly to Stripe
stripe.paymentIntents.create({ amount: service.deposit })

// ❌ WRONG — double conversion, charges £2000 instead of £20
stripe.paymentIntents.create({ amount: service.deposit * 100 })

// ✅ CORRECT — formatCurrency expects pence
formatCurrency(appointment.depositAmount)  // "£20.00"

// ❌ WRONG — studio-data is already pounds
formatCurrency(studioService.price)  // "£0.20" ← bug
```

### Step 2: Centralise queries in `lib/` not API routes
```ts
// lib/services.ts — reusable, testable
export async function getServiceBySlug(slug: string) {
  return prisma.service.findUnique({ where: { slug } })
}
```

### Step 3: Use Prisma's type safety
- Import generated types: `import type { Service, Appointment } from "@prisma/client"`
- Never cast to `any` — let Prisma's types catch errors at build time
- Use `select` to fetch only needed fields

### Step 4: Seed safely
- All seed prices/deposits MUST be in pence
- Use timezone-safe timestamps (see timezone-safety skill)
- Delete in FK-safe order: holds → appointments → clients → services

### Step 5: Serverless (Neon) patterns
- First query after cold start: 2–5s (unavoidable on free tier)
- Add error boundary: `app/(owner)/dashboard/error.tsx`
- Use `@neondatabase/serverless` with WebSocket pooling
- Add `export const dynamic = "force-dynamic"` to all DB-reading pages

## NEVER
- ❌ Pass raw user objects to `where` clauses (operator injection risk)
- ❌ Use `$queryRaw` with string concatenation
- ❌ Forget `prisma generate` before `next build` (add to `prebuild` script)
- ❌ Use superuser connection strings in application config
