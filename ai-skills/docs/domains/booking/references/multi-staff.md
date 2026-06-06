# Multi-Staff / Provider Management

> Only implement when client has multiple staff. Skip for solo-provider demos.

## When to Build

| Scenario | Build? |
|----------|--------|
| Solo provider demo | ❌ |
| 2-3 staff, same services | ✅ Add providerId |
| Marketplace (many providers) | ✅ Full multi-tenancy |

## Schema Addition

```prisma
model Provider {
  id              String        @id @default(cuid())
  name            String
  email           String        @unique
  specialisations String[]      // ["lashes", "brows"]
  commissionRate  Float         @default(0.40) // 40%
  isActive        Boolean       @default(true)
  
  appointments    Appointment[]
  availability    AvailabilityRule[]
}

// Add to Appointment:
// providerId String?
// provider   Provider? @relation(...)

// Add to AvailabilityRule:
// providerId String?
// provider   Provider? @relation(...)
```

## Booking Flow Change

```
Solo provider:    Service → Date → Time → Form → Pay
Multi-provider:   Service → Provider → Date → Time → Form → Pay
```

## Staff Selection Logic

```ts
// Option A: Client chooses ("I want Sarah")
// → Show provider picker after service selection

// Option B: Auto-assign ("Any available")
// → System picks provider with earliest availability
async function autoAssignProvider(serviceId: string, date: string) {
  const providers = await prisma.provider.findMany({
    where: { specialisations: { has: service.category }, isActive: true }
  })
  // Find first provider with available slot on that date
  for (const provider of providers) {
    const slots = await getAvailableSlots(serviceId, date, provider.id)
    if (slots.length > 0) return { provider, slots }
  }
  return null
}
```

## Commission Calculation

```ts
function calculateCommission(appointment: Appointment, provider: Provider) {
  return Math.round(appointment.totalPrice * provider.commissionRate)
}

// Dashboard: "Staff earnings this month"
const earnings = appointments
  .filter(a => a.status === "COMPLETED" && a.providerId === provider.id)
  .reduce((sum, a) => sum + calculateCommission(a, provider), 0)
```

## Availability Per Provider

```ts
// Each provider has their own AvailabilityRules
// Slot generation filters by providerId
const rules = await prisma.availabilityRule.findMany({
  where: { providerId, dayOfWeek, isActive: true }
})
```
