---
name: availability-and-calendar
description: >
  Slot availability engine and provider schedule management. ACTIVATE when:
  generating available time slots, managing provider hours, implementing
  buffer times, handling holidays/overrides, or integrating external calendars.
---

# Availability & Calendar Skill

## When to Use
- Building or modifying the slot availability endpoint
- Setting up provider working hours
- Adding holidays, breaks, or schedule overrides
- Implementing buffer times between appointments
- Calendar integration decisions

## Slot Generation: On-Demand (Default)

<HARD-GATE>
**⛔ MANDATORY — ALL SLOT TIMES MUST BE TIMEZONE-SAFE.**
Store all times in UTC. Convert to provider timezone only for display and slot generation. Always filter expired holds before returning available slots. Never return past time slots.
</HARD-GATE>

Generate slots at request time from rules + bookings + holds:

```
1. AvailabilityOverride for date? (highest priority)
   → blocked: return empty
   → custom hours: use override times
2. AvailabilityRule for day of week
   → Generate slots between startTime and endTime at SCHEDULING.slotInterval
3. Filter out:
   → Existing appointments (with buffer)
   → Active holds (not expired)
   → Past slots (before minAdvanceNotice)
4. Return available slots
```

### Pre-Compute vs On-Demand

| | Pre-compute (DB table) | On-demand (calculate) |
|---|---|---|
| **Speed** | Fast SELECT | Slower compute |
| **Accuracy** | Can go stale | Always current |
| **Storage** | Grows with time | Zero |
| **Best for** | High-traffic marketplace | Solo provider, demos |

> **Default:** On-demand. <50ms for solo-provider even without caching.

## Provider Availability Schema

```prisma
model AvailabilityRule {
  id        String  @id @default(cuid())
  dayOfWeek Int     // 0=Sun, 1=Mon, ..., 6=Sat
  startTime String  // "09:00"
  endTime   String  // "17:00"
  isActive  Boolean @default(true)
}

model AvailabilityOverride {
  id        String  @id @default(cuid())
  date      String  // "2026-06-15"
  isBlocked Boolean // true = day off
  startTime String? // null if blocked
  endTime   String?
  reason    String? // "Holiday", "Training", "Sick"
}
```

## Buffer Times

| Niche | Buffer | Why |
|-------|--------|-----|
| Lashes | 15 min | Cleanup, client transition |
| Hair | 10 min | Quick cleanup |
| Massage/spa | 15–30 min | Room flip, linen change |
| Nails | 5–10 min | Minimal cleanup |
| Tattoo | 30 min | Sterilisation |

Store as `bufferMinutes` on Service model:

```ts
// When checking conflicts, extend the appointment window
const conflictStart = subMinutes(slotStart, service.bufferMinutes)
const conflictEnd = addMinutes(slotEnd, service.bufferMinutes)

const conflicts = await prisma.appointment.findMany({
  where: {
    status: { in: ["CONFIRMED", "HOLD"] },
    startsAt: { lt: conflictEnd },
    endsAt: { gt: conflictStart },
  }
})
```

## Calendar Integration Levels

| Level | What | Effort | Best for |
|-------|------|--------|---------|
| **0: None** | Manage in your dashboard | Zero | Demos |
| **1: ICS export** | Generate feed URL for owner | Low | Solo provider |
| **2: Google read** | Block busy slots from Google Cal | Medium | Prevents conflicts |
| **3: Two-way sync** | Full Google Calendar API | High | Production only |

> **Default for demos:** Level 0. Level 3 requires OAuth, token refresh, webhook registration — not demo scope.

## Dashboard Metrics

| Metric | Query pattern |
|--------|-------------|
| Bookings today | `WHERE DATE(startsAt) = today AND status = 'CONFIRMED'` |
| Revenue this month | `SUM(depositAmount) WHERE status IN ('CONFIRMED','COMPLETED')` |
| No-show rate | `COUNT(NO_SHOW) / COUNT(all non-cancelled)` |
| Busiest day | `GROUP BY dayOfWeek ORDER BY COUNT DESC` |
| Cancellation rate | `COUNT(CANCELLED) / COUNT(all) per month` |

## Performance & Caching

### What to Cache

| Data | Cache? | TTL |
|------|--------|-----|
| Service list | ✅ | 5 min |
| Available slots | ❌ | — (must be real-time) |
| Today's appointments | ❌ | — (changes frequently) |
| Studio config (static) | ✅ | 1 hour |

### Last Valid Slot

```ts
// Don't show slots that can't fit the service before closing
const lastSlotStart = subMinutes(closeTime, service.durationMinutes + service.bufferMinutes)
// 5:00 PM close - 90 min service - 15 min buffer = 3:15 PM last slot
```

### Connection Pooling (Neon/Serverless)

```ts
// lib/prisma.ts — Prisma 6 / prisma-client-js singleton
const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }
export const prisma = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma
```

For Prisma 7, use the generated-client output path and driver adapter pattern from `docs/skills/prisma-database/SKILL.md`.

## References
- `references/edge-cases.md` — DST transitions, midnight boundary
- `references/dashboard-patterns.md` — metrics queries, cold start handling
- `references/multi-staff.md` — per-provider availability (when needed)

## NEVER
- ❌ Hardcode buffer times (store on Service model)
- ❌ Forget to filter expired holds from availability
- ❌ Return past time slots
- ❌ Ignore AvailabilityOverride when generating slots
- ❌ Show slots past closing time minus service duration
