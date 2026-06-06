---
name: cancellation-and-lifecycle
description: >
  Booking lifecycle management. ACTIVATE when: implementing cancellation flows,
  rescheduling, no-show handling, waitlists, recurring bookings, or managing
  booking state transitions.
---

# Cancellation & Lifecycle Skill

## When to Use
- Implementing cancel/reschedule flows
- Building manage links
- Handling no-shows
- Adding waitlist or recurring booking support
- Managing booking state transitions

## Booking State Machine

```
HOLD → CONFIRMED → COMPLETED
                 → CANCELLED
                 → NO_SHOW
                 → RESCHEDULING → (new HOLD)
```

Log every transition with timestamp + reason.

## Manage Links

| | Tokenised link | Client login |
|---|---|---|
| **UX** | Click → immediate access | Create account → login → find booking |
| **Security** | Unguessable token in URL | Session-based |
| **Best for** | One-off bookings, beauty | Multi-location, loyalty |

> **Default:** Tokenised manage link (cuid/nanoid). In confirmation email. Links to `/appointment/{token}`.

## Rescheduling

| Approach | Pros | Cons |
|----------|------|------|
| **Cancel + redirect** (pre-filled) | Reuses all existing code | Two records |
| **Cancel + rebook** (atomic) | Simple transaction | Client re-enters form |
| **Modify in place** | Preserves history | Complex conflict checks |

> **Default:** Cancel old → redirect to booking flow with pre-filled client data from manage token lookup.

## Refund Tiers

Configurable, not hardcoded:

```ts
export const REFUND_TIERS = [
  { hoursBeforeMin: 48, hoursBeforeMax: Infinity, refundPercent: 1.0 },
  { hoursBeforeMin: 24, hoursBeforeMax: 48, refundPercent: 0.5 },
  { hoursBeforeMin: 0, hoursBeforeMax: 24, refundPercent: 0 },
]

export function calculateRefund(appointment: Appointment) {
  const hoursUntil = differenceInHours(appointment.startsAt, new Date())
  const tier = REFUND_TIERS.find(t => hoursUntil >= t.hoursBeforeMin && hoursUntil < t.hoursBeforeMax)
  return {
    amount: Math.round(appointment.depositAmount * (tier?.refundPercent ?? 0)),
    reason: `${(tier?.refundPercent ?? 0) * 100}% refund`
  }
}
```

## No-Show Handling

1. Owner marks as NO_SHOW in dashboard (or auto after 30 min past `startsAt`)
2. Deposit is forfeited (no refund)
3. Send "We missed you" email with rebook link
4. Track no-show count on Client model
5. Optional: after 3 no-shows, require full prepayment

## Waitlists

### When to Build

| Scenario | Build? |
|----------|--------|
| Solo provider, few services | ❌ Show "next available" instead |
| Popular slots consistently full | ✅ Yes |
| Demo project | ❌ Skip unless client asks |

### State Machine

```
QUEUED → NOTIFIED → CLAIMED → (becomes HOLD)
                  → EXPIRED → notify next
```

### Notification Window

When a slot opens (cancellation):
1. Find first QUEUED entry for that service + date
2. Send email: "Slot opened! 2 hours to claim"
3. Set `expiresAt` = now + 2h
4. If claimed → normal hold flow. If expired → notify next.

```prisma
model WaitlistEntry {
  id          String    @id @default(cuid())
  serviceId   String
  date        String
  clientEmail String
  position    Int
  status      String    @default("QUEUED")
  expiresAt   DateTime?
  createdAt   DateTime  @default(now())
}
```

## Recurring Bookings

### Storage Decision

| Approach | Best for |
|----------|---------|
| **Individual rows** | Beauty/wellness (finite series) |
| **RRULE pattern** | Infinite recurring ("every Monday forever") |

> **Default:** Individual rows. Batch-create when client books "weekly for 6 weeks."

```ts
for (let i = 0; i < weekCount; i++) {
  const date = addWeeks(selectedDate, i)
  const available = await checkSlotAvailable(serviceId, date, time)
  if (!available) return { error: `${format(date, "MMM d")} unavailable` }
  appointments.push({ date, time })
}
// Create all holds in one transaction
```

<HARD-GATE>
**⛔ MANDATORY — SECURE MANAGE TOKENS + POLICY-CHECKED REFUNDS.**
Use cuid/nanoid for manage tokens (never sequential IDs). Always check cancellation tier policy before issuing refunds. Never allow cancellation of completed appointments.
</HARD-GATE>

## NEVER
- ❌ Use sequential IDs for manage tokens (use cuid/nanoid)
- ❌ Hardcode refund percentages (use config)
- ❌ Allow cancellation of already-completed appointments
- ❌ Auto-refund without checking tier policy
