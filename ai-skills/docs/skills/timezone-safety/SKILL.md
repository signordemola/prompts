---
name: timezone-safety
description: >
  Prevents timezone bugs in date/time logic. ACTIVATE when: writing any code
  involving dates, times, scheduling, availability, seeding, or Prisma date
  queries. Works for ANY timezone — configure the provider timezone in your
  project's lib/dayjs.ts. Uses Day.js with timezone plugin.
---

# Timezone Safety Skill

## When to Use
- Any date/time logic (scheduling, availability, queries)
- Writing Prisma queries with date filters
- Seeding the database with timestamps
- Any code touching `startsAt`, `endsAt`, `date`, or `dayOfWeek`

## Configure Your Timezone

Each project sets its provider timezone in `lib/dayjs.ts`:

```ts
import dayjs from "dayjs"
import utc from "dayjs/plugin/utc"
import timezone from "dayjs/plugin/timezone"

dayjs.extend(utc)
dayjs.extend(timezone)

export const PROVIDER_TZ = "Europe/London"

export const providerDate = (dateStr: string, timeStr: string) =>
  dayjs.tz(`${dateStr} ${timeStr}`, PROVIDER_TZ).toDate()

export const providerDateOnly = (dateStr: string) =>
  dayjs.tz(`${dateStr} 00:00`, PROVIDER_TZ).toDate()

export const providerNow = () => dayjs().tz(PROVIDER_TZ)

export const formatProvider = (date: Date, fmt: string) =>
  dayjs(date).tz(PROVIDER_TZ).format(fmt)

export default dayjs
```

Common timezone values:

```ts
export const PROVIDER_TZ = "Europe/London"       // BST/GMT auto-switch
export const PROVIDER_TZ = "America/New_York"    // EST/EDT auto-switch
export const PROVIDER_TZ = "America/Toronto"     // EST/EDT auto-switch
export const PROVIDER_TZ = "Asia/Dubai"          // GST (no DST)
export const PROVIDER_TZ = "Australia/Sydney"    // AEST/AEDT auto-switch
```

**Rule:** ALWAYS use IANA timezone names. NEVER use abbreviations ("BST", "EST").

## Instructions

### Step 1: Import correct utilities
```ts
import dayjs, { providerDate, providerDateOnly, providerNow, formatProvider, PROVIDER_TZ } from "@/lib/dayjs"
```

### Step 2: NEVER use these on timezone-adjusted dates
- ❌ `setHours()` — uses machine timezone, not provider timezone
- ❌ `startOfDay()` — strips timezone, reverts to UTC midnight
- ❌ `getDay()` — returns wrong weekday when provider midnight ≠ UTC midnight
- ❌ `new Date()` for scheduling — has no timezone context

### Step 3: Use these patterns instead

**Midnight for a date string:**
```ts
const midnight = providerDateOnly("2026-06-05")
```

**Specific provider time:**
```ts
const appt = providerDate("2026-06-05", "10:00")
```

**Add/subtract time:**
```ts
const oneHourLater = dayjs(appt).tz(PROVIDER_TZ).add(1, "hour").toDate()
const tomorrow = dayjs(appt).tz(PROVIDER_TZ).add(1, "day").toDate()
```

**Format for display:**
```ts
const display = formatProvider(appt, "ddd D MMM, h:mm A")
```

**Day range query (Prisma):**
```ts
const dayStart = providerDateOnly(dateStr)
const dayEnd = dayjs(dayStart).add(1, "day").toDate()

prisma.appointment.findMany({
  where: { startsAt: { gte: dayStart, lt: dayEnd } },
})
```

**Day of week from date string (NOT from Date object):**
```ts
const dayOfWeek = dayjs.tz(dateStr, PROVIDER_TZ).day()
```

**Seed script helper:**
```ts
const seedDate = (offsetDays: number, hours: number, minutes = 0) => {
  const base = providerNow().add(offsetDays, "day")
  const dateStr = base.format("YYYY-MM-DD")
  const timeStr = `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`
  return providerDate(dateStr, timeStr)
}
```

### Step 4: Multi-timezone clients (future)
If clients book from different timezones than the provider:
1. Detect client timezone: `Intl.DateTimeFormat().resolvedOptions().timeZone`
2. Display slots in client's timezone: `dayjs(slot).tz(clientTz).format("h:mm A")`
3. Store in UTC — always
4. Confirmation email shows both: "10:00 AM BST (2:00 AM PST)"

### Step 5: Verify
- [ ] All date construction uses `providerDate()` or `providerDateOnly()`
- [ ] No `setHours()`, `startOfDay()`, or `getDay()` on Date objects
- [ ] Seed timestamps use the `seedDate()` helper
- [ ] DB stores `timestamptz` (Prisma `DateTime`)
- [ ] `PROVIDER_TZ` is an IANA name, not an abbreviation

## Why This Matters (The Trap)

Any timezone with DST has a period where local midnight ≠ UTC midnight:

| Timezone | DST period | Midnight local = | `getDay()` returns |
|----------|-----------|-----------------|-------------------|
| Europe/London | Mar–Oct (BST) | 23:00 UTC **previous day** | Wrong weekday |
| America/New_York | Mar–Nov (EDT) | 04:00 UTC **same day** | Correct (usually) |
| Asia/Dubai | None | 20:00 UTC **previous day** | Wrong weekday |
| Australia/Sydney | Oct–Apr (AEDT) | 13:00 UTC **previous day** | Wrong weekday |

**Most timezones are affected.** The pattern in this skill is universal.

## NEVER
- ❌ `setHours()` anywhere — always use `providerDate()`
- ❌ `startOfDay()` on a timezone-adjusted Date
- ❌ `getDay()` on a timezone-adjusted Date (use `dayjs.tz(dateStr, TZ).day()`)
- ❌ `new Date()` for scheduling — use `dayjs.tz()`
- ❌ Use timezone abbreviations ("BST", "EST") — use IANA names
- ❌ Assume UTC midnight = local midnight
- ❌ Import `dayjs` directly — always import from `@/lib/dayjs`
