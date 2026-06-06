---
name: concurrency-and-holds
description: >
  Prevents double-bookings and race conditions. ACTIVATE when: creating slot holds,
  processing booking confirmations, handling concurrent requests, implementing
  idempotency, or debugging race conditions. Covers locking strategies, hold
  patterns, idempotency keys, webhook reliability, and payment recovery.
---

# Concurrency & Holds Skill

## When to Use
- Creating or modifying slot hold logic
- Processing webhook confirmations
- Debugging double-booking or race conditions
- Implementing retry or reconciliation logic

## Double-Booking Prevention

<HARD-GATE>
**⛔ MANDATORY — EVERY SLOT MUTATION MUST HAVE A UNIQUE CONSTRAINT.**
Add `@@unique([startsAt, serviceId])` on SlotHold and Appointment models. Do not rely on application-level checks alone — the database MUST enforce uniqueness. Also: every mutation endpoint MUST have an idempotency key.
</HARD-GATE>

### Decision: Locking Strategy

| | Optimistic (version column) | Pessimistic (`SELECT FOR UPDATE`) |
|---|---|---|
| **How** | Check version at commit time | Lock row on read |
| **Throughput** | High — no blocking | Lower — serialised |
| **Failure mode** | Retry on version mismatch | Deadlock risk if locks held too long |
| **Best for** | Solo provider (~1 booking/min) | High contention (popular slots) |

> **Default:** DB unique constraints as safety net. `@@unique([startsAt, serviceId])` on SlotHold and Appointment models. Solo-provider demos have near-zero contention.

> **Upgrade trigger:** >10 concurrent bookings for the same slot → add `SELECT FOR UPDATE`.

### Decision: Where to Store Holds

| | Database (Prisma) | Redis (TTL keys) |
|---|---|---|
| **TTL expiry** | Manual cleanup (check-on-read) | Native `EXPIRE` |
| **Persistence** | Survives restarts | Lost on restart |
| **Complexity** | Low (one data store) | Medium (two stores) |
| **Best for** | Solo provider, demos | Multi-provider, high concurrency |

> **Default:** Database holds. Delete expired holds when querying availability:
```ts
// In availability query — clean up expired holds first
await prisma.slotHold.deleteMany({
  where: { expiresAt: { lt: new Date() } }
})
```

> **Upgrade trigger:** Hold check latency >100ms or >50 concurrent users → add Redis.

## Idempotency Keys

Every mutation endpoint needs idempotency:

| Endpoint | Key | Pattern |
|----------|-----|---------|
| `POST /api/slots/hold` | `hold_${serviceSlug}_${startsAt}_${sessionId}` | Upsert — return existing hold |
| `POST /api/stripe/checkout` | `booking_${holdToken}` | Pass to Stripe `idempotencyKey` |
| `POST /api/stripe/webhook` | `paymentIntent.id` | Check `stripePaymentId` exists |
| `POST /api/appointments/cancel` | `cancel_${manageToken}` | Check status before mutating |

```ts
// Pattern: idempotent webhook
const existing = await prisma.appointment.findFirst({
  where: { stripePaymentId: paymentIntent.id }
})
if (existing) return NextResponse.json({ received: true })
```

## Webhook Reliability

### Decision: Processing Strategy

| | Inline (in handler) | Queue (fast-ack) |
|---|---|---|
| **Stripe timeout risk** | Yes (if DB/email slow) | Never — respond <100ms |
| **Complexity** | Low | Higher (queue infra) |
| **Best for** | Demos | Production |

> **Default for demos:** Inline with idempotency check.

### Missed Webhook Reconciliation

```ts
// GET /api/admin/reconcile (owner-only, daily cron)
const intents = await stripe.paymentIntents.list({
  created: { gte: oneDayAgo }, status: "succeeded"
})
for (const intent of intents.data) {
  const exists = await prisma.appointment.findFirst({
    where: { stripePaymentId: intent.id }
  })
  if (!exists) {
    await createAppointmentFromMetadata(intent.metadata)
    console.warn(`[RECONCILE] Created missing appointment for ${intent.id}`)
  }
}
```

### Payment Failure Recovery

| Failure | Recovery |
|---------|---------|
| Card declined | Show error → user retries with different card |
| 3DS abandoned | Hold expires naturally → slot freed |
| Webhook never arrives | Reconciliation job catches it |
| DB write fails after payment | Reconciliation + manual refund path |

## Rate Limiting & Spam Protection

### What to Rate Limit

| Endpoint | Limit | Why |
|----------|-------|-----|
| `GET /api/slots` | 30/min per IP | Prevent availability scraping |
| `POST /api/slots/hold` | 5/min per session | Prevent slot exhaustion |
| `POST /api/stripe/checkout` | 3/min per session | Prevent payment spam |
| `POST /api/auth/login` | 5/min per IP | Brute force protection |

### Implementation

```ts
// lib/rate-limit.ts
const rateLimitMap = new Map<string, { count: number; resetAt: number }>()

export function rateLimit(key: string, limit: number, windowMs: number): boolean {
  const now = Date.now()
  const entry = rateLimitMap.get(key)
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(key, { count: 1, resetAt: now + windowMs })
    return true
  }
  if (entry.count >= limit) return false
  entry.count++
  return true
}

// In API route:
const ip = request.headers.get("x-forwarded-for") ?? "unknown"
if (!rateLimit(`hold:${ip}`, 5, 60_000)) {
  return NextResponse.json({ error: "Too many requests" }, { status: 429 })
}
```

> **For demos:** In-memory map (resets on deploy). **Production:** Redis.

### Anti-Slot-Exhaustion

```ts
// Max concurrent holds per session
const activeHolds = await prisma.slotHold.count({
  where: { sessionId, expiresAt: { gt: new Date() } }
})
if (activeHolds >= 2) {
  return { error: "You can only hold 2 slots at a time" }
}
```

### Honeypot Field (Anti-Bot)

```tsx
// Hidden field in intake form — bots will fill it
<input name="website" type="text" style={{ display: "none" }} tabIndex={-1} />

// Server: if (formData.website) return { error: "Spam detected" }
```

## References
- `references/database-schema.md` — full schema with indexes
- `references/edge-cases.md` — DST, midnight, hold expiry during payment

## NEVER
- ❌ Skip idempotency on ANY mutation endpoint
- ❌ Process webhooks without signature verification
- ❌ Assume webhooks always arrive (build reconciliation)
- ❌ Hold locks longer than necessary (5 min max for demos)
- ❌ Allow unlimited holds per session (cap at 2)

