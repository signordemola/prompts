# Cancellation, Rescheduling & No-Shows

## Self-Service Manage Links

Clients should **never need to log in** to manage their booking.

- Confirmation email includes a unique URL: `/appointment/{manageToken}`
- Token is cryptographically random (`cuid()` or `nanoid(21)` minimum)
- Manage page allows: view details, reschedule, cancel
- Cancellation enforces tiered refund policy

## Rescheduling Flow

1. Client clicks "Reschedule" on manage page
2. Existing appointment status → `RESCHEDULING`
3. Client picks new date/time → new hold created
4. On confirmation → old appointment cancelled, new one created
5. If abandoned → old appointment remains, new hold expires

**Key insight:** Rescheduling = "cancel + rebook" atomically, not an in-place update.
Cal.diy and all major platforms use this pattern.

## No-Show Handling

### Flagging System

```
First no-show:  Warning email, record on client profile
Second no-show: Flag client, require full prepayment for future bookings
Third no-show:  Block from online booking (must call)
```

### On No-Show

1. Mark appointment status → `NO_SHOW`
2. Mark `depositStatus` → `FORFEITED`
3. Increment `client.noShowCount`
4. If threshold reached → `client.isFlagged = true`
5. Send email: "You missed your appointment. Your deposit has been forfeited."

## Waitlists (Enhancement)

When all slots on a day are taken:

```prisma
model WaitlistEntry {
  id          String    @id @default(cuid())
  clientEmail String
  clientName  String
  serviceId   String
  date        DateTime
  createdAt   DateTime  @default(now())
  notifiedAt  DateTime?
  status      String    @default("WAITING")  // WAITING | NOTIFIED | BOOKED | EXPIRED
}
```

When a cancellation opens a slot:
1. Check waitlist for that date + service
2. Send "A slot opened up" email with direct booking link
3. Give 30 minutes to book before notifying the next person
