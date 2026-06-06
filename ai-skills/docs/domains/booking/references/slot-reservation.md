# Slot Reservation & Concurrency

## The Two-Phase Hold Pattern (Industry Standard)

Every production booking system separates "intent" from "confirmation":

### Phase 1: Soft Hold
- Client selects a time slot
- POST `/api/slots/hold` creates a `SlotHold` record with `expiresAt` (2–10 min TTL)
- Returns `holdToken` to the client
- Availability engine treats active holds as blocked slots
- Expired holds are ignored (or cleaned up by sweeper)

### Phase 2: Hard Booking
- Created ONLY after payment succeeds (via Stripe webhook)
- Webhook receives `holdToken` from Stripe metadata
- Atomically: validate hold → create Appointment → delete hold
- If hold expired, reject — client must start over

## Database-Level Safety

Never rely on "check then write" in application code:

```sql
-- ❌ WRONG: Race condition between SELECT and INSERT
SELECT * FROM appointments WHERE starts_at = '10:00';
INSERT INTO appointments ...;

-- ✅ CORRECT: Atomic insert with conflict check
INSERT INTO appointments (starts_at, ...)
SELECT '10:00', ...
WHERE NOT EXISTS (
  SELECT 1 FROM appointments WHERE starts_at = '10:00' AND service_id = :id
);
```

Or use `@@unique([startsAt, serviceId])` in Prisma as a final safety net.

## Locking Strategies

| Strategy | When to use | Trade-off |
|----------|------------|-----------|
| **TTL-based hold** (what we use) | Solo-provider, payment involved | Simple, no deadlocks |
| **Optimistic** (version column) | Low contention | Needs retry logic |
| **Pessimistic** (`SELECT FOR UPDATE`) | High contention (tickets, flash sales) | Can deadlock |
| **Redis distributed lock** | Multi-instance, microservices | Added infrastructure |

For solo-provider beauty studios, **TTL-based holds are ideal.**

## Idempotency

- Stripe PaymentIntent creation uses idempotency key: `booking_${holdToken}`
- Webhook handler checks if appointment already exists for this PaymentIntent ID
- This prevents duplicate bookings on webhook retry

## Hold Cleanup

Expired holds are naturally filtered out by the availability engine (`expiresAt > now()`).
Optionally add a cron job to delete old hold records for DB hygiene.
