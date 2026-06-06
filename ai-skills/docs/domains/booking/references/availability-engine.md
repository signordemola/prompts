# Availability Engine

## Slot Generation Algorithm

```
For each requested date:
  1. Check weekly availability (dayOfWeek → open/close hours)
  2. Check blocked dates (holidays, personal days)
  3. Generate candidate slots at interval (every 15 minutes)
  4. For each candidate slot:
     a. Is it in the past? → skip
     b. Is it within minimum booking notice (120 min from now)? → skip
     c. Does the service duration fit before closing time? → skip
     d. Does it overlap with any CONFIRMED appointment + buffer? → skip
     e. Does it overlap with any active SlotHold? → skip
  5. Remaining candidates = available slots
```

## Buffer Times (Industry Standard)

| Business type | Buffer before | Buffer after |
|---------------|--------------|-------------|
| Lash extensions | 10–15 min | 10–15 min |
| Hair salon | 5–10 min | 5–10 min |
| Massage/spa | 15–30 min | 15–30 min |
| Nails | 5–10 min | 5–10 min |
| Brows/waxing | 5 min | 5 min |

Buffer accounts for: cleanup, sanitisation, client changeover, brief consultation.
This project uses 15 minutes before and after.

## Overlap Detection

Use `areIntervalsOverlapping` from date-fns:
- Intervals sharing only an endpoint do NOT overlap (e.g., 10:00–12:00 and 12:00–14:00 are fine)
- Include buffer in the appointment interval before checking

## Slot Grid

- Default interval: 15 minutes
- Slots start at availability `startTime`, end when service no longer fits before `endTime`
- Display format: "10:00", "10:15", "10:30", etc.

## Query Pattern (Timezone-Safe)

```ts
const date = londonDateOnly(dateStr)
const [y, mo, dy] = dateStr.split("-").map(Number)
const dayOfWeek = new Date(y, mo - 1, dy).getDay()
const dayEnd = new Date(date.getTime() + 86400000)

// Query appointments for this London day
prisma.appointment.findMany({
  where: {
    startsAt: { gte: date, lt: dayEnd },
    status: "CONFIRMED",
  },
})
```

**Never use `startOfDay()` or `getDay()` on the `londonDateOnly()` result.**
See 05_TIMEZONE_HANDLING.md for why.

## Multi-Provider (Future)

Add `providerId` to Service and Appointment. Filter slot queries by provider.
Each provider has their own WeeklyAvailability and BlockedDate records.
