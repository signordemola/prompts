---
name: booking-flow-and-ux
description: >
  Booking wizard flow, scheduling rules, and intake forms. ACTIVATE when: building
  the multi-step booking wizard, configuring booking windows, implementing intake
  forms, or deciding wizard step count and hold timing.
---

# Booking Flow & UX Skill

## When to Use
- Building or modifying the booking wizard
- Configuring min/max booking windows
- Implementing intake or consultation forms
- Deciding hold timing or TTL

## Wizard Steps

<HARD-GATE>
**⛔ MANDATORY — SERVER-SIDE VALIDATION ON ALL BOOKING INPUTS.**
Never accept duration from the client (calculate from service). Validate booking windows server-side (minAdvanceHours, maxAdvanceDays). Re-verify slot availability at confirmation, not just at wizard start.
</HARD-GATE>

| Steps | Flow | Conversion |
|-------|------|-----------|
| **3** | Service → DateTime → Payment | Highest (~25%) |
| **4** | Service → DateTime → IntakeForm → Payment | Standard for beauty (~20%) |
| **5** | Service → DateTime → Intake → Policy → Payment | Safest, ~10% more abandonment |

> **Default:** 4 steps. Combine policy agreement as a checkbox in the intake form.

## Hold Timing

### When to Create

| Timing | Pros | Cons |
|--------|------|------|
| **On slot selection** | Reserved while filling form | May expire before payment |
| **On form submission** | Hold has client data | Slot could be taken while filling |
| **On payment initiation** | No wasted holds | "Slot taken" after filling form |

> **Default:** On slot selection. Show countdown timer (4:30). If expired, prompt re-select.

### TTL Duration

| Duration | Best for | Risk |
|----------|---------|------|
| **3 min** | Events, flash sales | Too short for forms |
| **5 min** | Solo provider, beauty | Sweet spot |
| **10 min** | Complex intake, medical | Blocks slots too long |
| **15 min** | Multi-provider | Only if inventory deep |

> **Default:** 5 minutes for solo-provider demos.

## Scheduling Rules

```ts
// lib/scheduling-rules.ts
export const SCHEDULING = {
  minAdvanceNotice: 4,       // hours
  maxAdvanceDays: 60,        // days
  slotInterval: 15,          // minutes
  allowSameDayBooking: true,
  autoConfirm: true,         // false = owner must approve
}
```

### Booking Window Validation (Server-Side)

```ts
const minTime = addHours(now, SCHEDULING.minAdvanceNotice)
const maxTime = addDays(now, SCHEDULING.maxAdvanceDays)
if (requestedDate < minTime) return { error: "Too short notice" }
if (requestedDate > maxTime) return { error: "Too far in advance" }
```

### Auto-Confirm vs Manual Approve

| | Auto-confirm | Manual approve |
|---|---|---|
| **UX** | Instant confirmation | "Pending" until owner approves |
| **State machine** | HOLD → CONFIRMED | HOLD → PENDING → CONFIRMED |
| **Best for** | Solo provider, demos | New clients, group bookings |

> **Default:** Auto-confirm. Manual approve adds PENDING state + owner notification UI.

## Intake Forms

### Static vs Dynamic

| | Static (hardcoded JSX) | Dynamic (config-driven) |
|---|---|---|
| **Flexibility** | Code change to update | Config change |
| **Complexity** | Low | Medium |
| **Best for** | Single-niche demo | Multi-niche platform |

> **Default:** Static. Each niche has different needs (lashes = allergies, massage = injuries).

### Conditional Fields

```tsx
const [hasAllergies, setHasAllergies] = useState(false)

<label>
  <input type="checkbox" onChange={(e) => setHasAllergies(e.target.checked)} />
  I have known allergies
</label>
{hasAllergies && (
  <textarea name="allergyDetails" required placeholder="Please describe..." />
)}
```

### Patch Test Gate (Lash/Brow Services)

```tsx
const [hasPatchTest, setHasPatchTest] = useState<boolean | null>(null)

{hasPatchTest === false && (
  <Alert>Patch test required 48h before. <a href="/patch-test">Book one →</a></Alert>
)}
{hasPatchTest === true && <SlotPicker />}
```

### Health Data Storage

- Separate `IntakeResponse` table (not on Appointment)
- Link to Client, not individual appointment
- Don't expose in API responses by default
- Provide deletion endpoint for data erasure

## Multi-Service Bookings (When Needed)

### Sequential Services

```ts
// Lashes (90min) + Brow Lamination (45min)
// Total: 90 + 15 (buffer) + 45 = 150 min
function calculateMultiServiceSlot(services: Service[], startTime: Date) {
  let cursor = startTime
  const blocks = []
  for (const service of services) {
    const end = addMinutes(cursor, service.durationMinutes)
    blocks.push({ serviceId: service.id, startsAt: cursor, endsAt: end })
    cursor = addMinutes(end, service.bufferMinutes)
  }
  return { blocks, totalEnd: cursor }
}
```

> **When to skip:** Solo-provider demos rarely need multi-service. Build only if client asks.

### Add-Ons

```tsx
// Checkboxes after service selection
{addOns.map(addOn => (
  <label key={addOn.id}>
    <input type="checkbox" value={addOn.id} onChange={() => toggleAddOn(addOn.id)} />
    {addOn.name} (+{formatCurrency(addOn.price)}, +{addOn.durationMinutes}min)
  </label>
))}

// Server-side total:
const addOnTotal = selectedAddOns.reduce((sum, a) => sum + a.price, 0)
const extraDuration = selectedAddOns.reduce((sum, a) => sum + a.durationMinutes, 0)
const totalPrice = service.price + addOnTotal
const totalDuration = service.durationMinutes + extraDuration
```

## References
- `references/edge-cases.md` — hold expiry during payment, DST, midnight
- `references/dashboard-patterns.md` — confirmation page after payment

## NEVER
- ❌ Skip server-side validation of booking windows
- ❌ Let clients book in the past
- ❌ Store health data directly on the Appointment model
- ❌ Pre-check the policy agreement checkbox
- ❌ Accept duration from the client (always calculate server-side)

