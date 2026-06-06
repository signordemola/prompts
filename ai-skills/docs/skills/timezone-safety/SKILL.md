---
name: timezone-safety
description: >
  Prevents timezone bugs in date/time logic. ACTIVATE when: writing any code
  involving dates, times, scheduling, availability, seeding, or Prisma date
  queries. Works for ANY timezone — configure the provider timezone in your
  project's lib/time.ts. Covers date-fns-tz patterns and known traps.
---

# Timezone Safety Skill

## When to Use
- Any date/time logic (scheduling, availability, queries)
- Writing Prisma queries with date filters
- Seeding the database with timestamps
- Any code touching `startsAt`, `endsAt`, `date`, or `dayOfWeek`

## Configure Your Timezone

Each project sets its provider timezone in `lib/time.ts`:

```ts
// UK studio
export const PROVIDER_TZ = "Europe/London"    // BST/GMT auto-switch

// US East Coast
export const PROVIDER_TZ = "America/New_York" // EST/EDT auto-switch

// UAE
export const PROVIDER_TZ = "Asia/Dubai"       // GST (no DST)

// Australia
export const PROVIDER_TZ = "Australia/Sydney"  // AEST/AEDT auto-switch
```

**Rule:** ALWAYS use IANA timezone names. NEVER use abbreviations ("BST", "EST").

## Instructions

### Step 1: Import correct utilities
```ts
import { providerDate, providerDateOnly, PROVIDER_TZ } from "@/lib/time"
import { formatInTimeZone } from "date-fns-tz"
```

If your project uses `londonDate` / `londonDateOnly` names, those are
aliases for `providerDate` / `providerDateOnly` with `Europe/London` hardcoded.

### Step 2: NEVER use these on timezone-adjusted dates
- ❌ `setHours()` — uses machine timezone, not provider timezone
- ❌ `startOfDay()` — strips timezone, reverts to UTC midnight
- ❌ `getDay()` — returns wrong weekday when provider midnight ≠ UTC midnight

### Step 3: Use these patterns instead

**Midnight for a date string:**
```ts
const midnight = providerDateOnly("2026-06-05")
```

**Specific provider time:**
```ts
const appt = providerDate("2026-06-05", "10:00")
```

**Day range query (Prisma):**
```ts
const date = providerDateOnly(dateStr)
const dayEnd = new Date(date.getTime() + 86400000)
prisma.appointment.findMany({
  where: { startsAt: { gte: date, lt: dayEnd } }
})
```

**Day of week from date string (NOT from Date object):**
```ts
const [y, mo, d] = dateStr.split("-").map(Number)
const dayOfWeek = new Date(y, mo - 1, d).getDay()
```

**Seed script helper:**
```ts
function d(offsetDays: number, hours: number, minutes = 0): Date {
  const base = new Date(now.getTime() + offsetDays * 86400000)
  const dateStr = formatInTimeZone(base, PROVIDER_TZ, "yyyy-MM-dd")
  const timeStr = `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`
  return providerDate(dateStr, timeStr)
}
```

### Step 4: Multi-timezone clients (future)
If clients book from different timezones than the provider:
1. Detect client timezone: `Intl.DateTimeFormat().resolvedOptions().timeZone`
2. Display slots in client's timezone, calculate in provider's timezone
3. Store in UTC — always
4. Confirmation email shows both: "10:00 AM BST (2:00 AM PST)"

### Step 5: Verify
- [ ] All `new Date()` calls use `providerDate()` or `providerDateOnly()`
- [ ] No `startOfDay()` or `getDay()` on `providerDateOnly()` results
- [ ] Seed timestamps use the `d()` helper
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
- ❌ `getDay()` on a timezone-adjusted Date
- ❌ Use timezone abbreviations ("BST", "EST") — use IANA names
- ❌ Assume UTC midnight = local midnight
