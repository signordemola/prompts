# Booking Edge Cases

Every weird scenario and how to handle it.

## DST: Spring Forward (Clocks Skip Ahead)

```
UK: Last Sunday in March, 1:00 AM → 2:00 AM (skips 1:00–1:59)

Problem: Client books "1:30 AM" on March 30 → that time doesn't exist.
```

```ts
// Day.js + timezone plugin
import dayjs from "dayjs"
import utc from "dayjs/plugin/utc"
import timezone from "dayjs/plugin/timezone"
dayjs.extend(utc)
dayjs.extend(timezone)

function validateSlotExists(localTime: string, date: string, tz: string): boolean {
  const parsed = dayjs.tz(`${date} ${localTime}`, tz)
  const roundTrip = parsed.format("HH:mm")
  return roundTrip === localTime // false if DST gap
}
```

## DST: Fall Back (Clocks Repeat)

```
UK: Last Sunday in October, 2:00 AM → 1:00 AM (repeats 1:00–1:59)

Problem: "1:30 AM" exists twice.
Solution: Non-issue for beauty — no one books at 1 AM.
  If needed: store UTC, display with offset.
```

## Midnight Boundary (Cross-Timezone)

```
Problem: Client sees "Monday 11 PM" (US EST).
  Provider sees "Tuesday 4 AM" (UK GMT).
  Slot appears on wrong day in dashboard.

Solution: Generate slots in PROVIDER_TZ. Display in client's TZ. Store UTC.
```

## Appointment Spanning Midnight

```
Problem: Service starts 11:30 PM, ends 12:30 AM next day.

Solution: Assign to START date. Query by startsAt range:
  WHERE startsAt >= dayStart AND startsAt < dayEnd
```

## Leap Year / Feb 29

```
Problem: Recurring "every 4 weeks" from Jan 31.
  addWeeks(jan31, 4) = Feb 28 or Feb 29.

Solution: Day.js handles this. For "same day each month":
  clamp to last day of month.
```

## Hold Expires During Payment

```
Problem: User clicks "Pay" at 4:59. Hold expires at 5:00.
  Payment succeeds at 5:01. Webhook fires. Hold is gone.
```

```ts
// In webhook handler:
const hold = await prisma.slotHold.findFirst({
  where: { serviceId, startsAt, expiresAt: { gt: new Date() } }
})

if (!hold) {
  // Hold expired — check if slot is still free
  const conflict = await prisma.appointment.findFirst({
    where: { serviceId, startsAt, status: { in: ["CONFIRMED"] } }
  })
  if (conflict) {
    // Slot taken — refund and notify
    await stripe.refunds.create({ payment_intent: paymentIntent.id })
    await sendSlotTakenEmail(clientEmail)
    return
  }
  // Slot still free — create appointment anyway
}
```

## Same Client Books Twice (Double-Click)

```
Problem: Client submits payment twice.

Solution:
  1. Disable button after first click (UI)
  2. Stripe idempotency key = holdToken (same hold = same payment)
  3. Webhook idempotency check (stripePaymentId unique constraint)
```

## Owner Changes Hours After Client Holds Slot

```
Problem: Client holds 4 PM slot. Owner changes closing to 3 PM.

Solution: Holds are 5 min. Not a real problem.
  If needed: validate hold's time against current availability at payment.
```

## Client in Different Timezone Than Provider

```
Problem: Provider in London (GMT+1 summer). Client in NYC (GMT-4).
  Client sees "3 PM" — is that their time or London time?

Solution: 
  - Generate slots in PROVIDER_TZ
  - Detect client TZ via Intl.DateTimeFormat().resolvedOptions().timeZone
  - Display: "3:00 PM BST (10:00 AM your time)"
  - Store: UTC always
```

## Service Duration Longer Than Remaining Hours

```
Problem: Provider closes at 5 PM. Service is 90 min.
  Should we show a 4:30 PM slot?

Solution: No. Last slot = closeTime - serviceDuration - bufferMinutes.
  5:00 PM - 90 min - 15 min buffer = 3:15 PM is the last slot.
```

## Multiple Browser Tabs

```
Problem: Client opens two tabs, selects two different slots,
  fills form in tab 1, pays. Tab 2 still shows hold.

Solution: Holds are tied to sessionId (same across tabs).
  Max 2 concurrent holds per session. Second hold replaces first.
```

## Webhook Arrives Before Redirect

```
Problem: Webhook fires and creates appointment BEFORE client 
  lands on confirmation page. Confirmation page can't find 
  the appointment because client's browser is still redirecting.

Solution: This is actually the DESIRED flow. Confirmation page
  looks up appointment by stripePaymentId from query param.
  If found: show details. If not yet: show "processing" spinner
  with 2s polling for up to 30s.
```

## Email Delivery Failure

```
Problem: Appointment created but confirmation email bounces.

Solution: 
  1. Email failure never blocks appointment creation (try/catch)
  2. Log failed emails
  3. Owner can resend from dashboard
  4. Client sees confirmation on success page regardless
```
