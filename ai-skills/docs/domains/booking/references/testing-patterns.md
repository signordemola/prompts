# Testing Patterns for Booking Systems

## Test Types

| Type | What to test | Tool |
|------|-------------|------|
| **Unit** | Price calc, refund tiers, slot generation, timezone | Vitest/Jest |
| **Integration** | Hold creation + expiry, webhook processing, email | Vitest + Prisma test DB |
| **E2E** | Full booking flow (select → pay → confirm) | Playwright |
| **Time-sensitive** | Hold expiry, reminders, BST/GMT switch | Injectable clock |

## Mock Stripe

```ts
// __mocks__/stripe.ts
export const mockStripe = {
  paymentIntents: {
    create: vi.fn().mockResolvedValue({
      id: "pi_test_123",
      client_secret: "cs_test"
    }),
    list: vi.fn().mockResolvedValue({ data: [] }),
  },
  webhooks: {
    constructEvent: vi.fn().mockReturnValue({
      type: "payment_intent.succeeded",
      data: { object: { id: "pi_test_123", metadata: {} } }
    }),
  },
}
```

## Injectable Clock (Time Travel)

```ts
// lib/clock.ts
let _now: (() => Date) | null = null
export function now(): Date { return _now ? _now() : new Date() }
export function __setNow(fn: () => Date) { _now = fn } // test-only

// In tests:
import { __setNow } from "@/lib/clock"
__setNow(() => new Date("2026-06-15T10:00:00Z"))
const slots = await getAvailableSlots("classic-lash", "2026-06-15")
```

## Key Test Cases

### Availability
- [ ] Returns correct slots for a normal weekday
- [ ] Returns empty for blocked day (AvailabilityOverride)
- [ ] Filters out existing appointments
- [ ] Filters out active holds (not expired)
- [ ] Respects buffer times
- [ ] Handles BST/GMT boundary correctly

### Holds
- [ ] Creates hold with correct TTL
- [ ] Rejects hold for already-held slot (idempotent)
- [ ] Expired holds don't block availability
- [ ] DB unique constraint prevents double-hold

### Webhooks
- [ ] Creates appointment on valid payment
- [ ] Skips duplicate (idempotent)
- [ ] Rejects invalid signature
- [ ] Handles missing hold gracefully

### Cancellation
- [ ] Full refund >48h before
- [ ] Partial refund 24-48h before
- [ ] No refund <24h before
- [ ] Cannot cancel completed/no-show appointments
