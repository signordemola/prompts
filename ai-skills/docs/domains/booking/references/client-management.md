# Client Management Patterns

## Duplicate Prevention

```ts
// Always findOrCreate — never blind create
async function findOrCreateClient(email: string, name: string, phone?: string) {
  const existing = await prisma.client.findUnique({ where: { email } })
  if (existing) {
    return prisma.client.update({
      where: { id: existing.id },
      data: { name, phone: phone ?? existing.phone }
    })
  }
  return prisma.client.create({ data: { email, name, phone } })
}
```

## Client Tracking (Auto-Updated)

```ts
// After marking appointment COMPLETED:
await prisma.client.update({
  where: { id: appointment.clientId },
  data: {
    appointmentCount: { increment: 1 },
    lastVisitAt: new Date()
  }
})

// After marking NO_SHOW:
await prisma.client.update({
  where: { id: appointment.clientId },
  data: { noShowCount: { increment: 1 } }
})
```

## Dashboard Segments

| Segment | Query | Use |
|---------|-------|-----|
| **New clients** | `appointmentCount === 1` | Welcome sequence |
| **Returning** | `appointmentCount >= 2` | Loyalty rewards |
| **VIP** | `appointmentCount >= 10` | Priority booking |
| **At risk** | `lastVisitAt < 60 days ago` | Win-back email |
| **Frequent no-shows** | `noShowCount >= 3` | Require full prepayment |

## Owner Notes

```ts
// Private notes — visible only in dashboard, never in client-facing pages
// Use for: "Allergic to latex glue", "Prefers silence during treatment",
//          "Formula: C-curl 0.15mm, 11-13mm"
```

## Health Data Separation

- Store allergies/medical in `IntakeResponse` table (not on Client)
- Link to Client via `clientId`
- Don't expose in list APIs — only on individual client detail page
- Provide deletion endpoint for data erasure requests (GDPR)

## Merge Strategy (When Duplicates Found)

```ts
// Admin-only — merge sourceClient into targetClient
async function mergeClients(targetId: string, sourceId: string) {
  await prisma.$transaction([
    // Move all appointments
    prisma.appointment.updateMany({
      where: { clientId: sourceId },
      data: { clientId: targetId }
    }),
    // Move intake responses
    prisma.intakeResponse.updateMany({
      where: { clientId: sourceId },
      data: { clientId: targetId }
    }),
    // Merge counts
    prisma.client.update({
      where: { id: targetId },
      data: {
        appointmentCount: { increment: sourceClient.appointmentCount },
        noShowCount: { increment: sourceClient.noShowCount },
      }
    }),
    // Soft-delete source
    prisma.client.update({
      where: { id: sourceId },
      data: { deletedAt: new Date() }
    }),
    // Audit
    prisma.auditLog.create({
      data: {
        entityType: "client", entityId: targetId,
        action: "merged",
        oldData: { mergedFrom: sourceId },
        performedBy: "owner"
      }
    })
  ])
}
```
