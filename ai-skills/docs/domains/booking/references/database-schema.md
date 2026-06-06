# Full Database Schema Reference

## Complete Prisma Schema (Solo Provider)

```prisma
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ═══════════════════════════════════════════
// CORE MODELS
// ═══════════════════════════════════════════

model Service {
  id              String        @id @default(cuid())
  slug            String        @unique
  name            String
  description     String
  durationMinutes Int
  bufferMinutes   Int           @default(15)
  price           Int           // pence/cents — NEVER pounds/dollars
  depositPercent  Float         @default(0.20)
  category        String?       // "lashes" | "brows" | "nails"
  sortOrder       Int           @default(0)
  isActive        Boolean       @default(true)
  requiresPatchTest Boolean     @default(false)
  
  addOns          ServiceAddOn[]
  appointments    Appointment[]
  holds           SlotHold[]
  waitlistEntries WaitlistEntry[]
  
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  deletedAt       DateTime?
}

model ServiceAddOn {
  id              String   @id @default(cuid())
  serviceId       String
  service         Service  @relation(fields: [serviceId], references: [id])
  name            String   // "Bond Builder", "Lash Seal"
  price           Int      // pence — added to service price
  durationMinutes Int      @default(0)
  isActive        Boolean  @default(true)
}

model Client {
  id              String        @id @default(cuid())
  email           String        @unique
  name            String
  phone           String?
  appointmentCount Int          @default(0)
  noShowCount      Int          @default(0)
  lastVisitAt      DateTime?
  notes            String?      // owner's private notes
  
  appointments    Appointment[]
  intakeResponses IntakeResponse[]
  
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  deletedAt       DateTime?
}

model Appointment {
  id              String   @id @default(cuid())
  manageToken     String   @unique @default(cuid())
  
  clientId        String
  client          Client   @relation(fields: [clientId], references: [id])
  serviceId       String
  service         Service  @relation(fields: [serviceId], references: [id])
  
  startsAt        DateTime // ALWAYS timestamptz (UTC)
  endsAt          DateTime
  
  status          String   @default("CONFIRMED")
  // CONFIRMED | COMPLETED | CANCELLED | NO_SHOW | RESCHEDULED
  
  depositAmount   Int
  totalPrice      Int
  stripePaymentId String?  @unique
  refundAmount    Int?
  stripeRefundId  String?
  
  promoCodeId     String?
  discountAmount  Int      @default(0)
  
  addOnIds        String[]
  addOnTotal      Int      @default(0)
  
  reminder24hSent Boolean  @default(false)
  reminder2hSent  Boolean  @default(false)
  followUpSent    Boolean  @default(false)
  
  intakeData      Json?
  
  cancelledAt     DateTime?
  cancelledBy     String?  // "client" | "owner"
  cancelReason    String?
  completedAt     DateTime?
  noShowMarkedAt  DateTime?
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  deletedAt       DateTime?

  @@unique([startsAt, serviceId])
  @@index([clientId])
  @@index([status])
  @@index([startsAt])
  @@index([stripePaymentId])
}

model SlotHold {
  id         String   @id @default(cuid())
  serviceId  String
  service    Service  @relation(fields: [serviceId], references: [id])
  startsAt   DateTime
  endsAt     DateTime
  sessionId  String
  expiresAt  DateTime
  createdAt  DateTime @default(now())
  
  @@unique([startsAt, serviceId])
  @@index([expiresAt])
}

model IntakeResponse {
  id        String   @id @default(cuid())
  clientId  String
  client    Client   @relation(fields: [clientId], references: [id])
  data      Json
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

// ═══════════════════════════════════════════
// AVAILABILITY
// ═══════════════════════════════════════════

model AvailabilityRule {
  id        String  @id @default(cuid())
  dayOfWeek Int     // 0=Sun ... 6=Sat
  startTime String  // "09:00" in PROVIDER_TZ
  endTime   String  // "17:00" in PROVIDER_TZ
  isActive  Boolean @default(true)
}

model AvailabilityOverride {
  id        String   @id @default(cuid())
  date      String   // "2026-06-15"
  isBlocked Boolean
  startTime String?
  endTime   String?
  reason    String?
  createdAt DateTime @default(now())
}

// ═══════════════════════════════════════════
// PROMOS & PACKAGES
// ═══════════════════════════════════════════

model PromoCode {
  id            String   @id @default(cuid())
  code          String   @unique
  discountType  String   // "PERCENT" | "FIXED"
  discountValue Int
  maxUses       Int?
  usedCount     Int      @default(0)
  validFrom     DateTime
  validUntil    DateTime
  minSpend      Int?
  serviceIds    String[]
  isActive      Boolean  @default(true)
  createdAt     DateTime @default(now())
}

model PrepaidPackage {
  id              String   @id @default(cuid())
  clientId        String
  name            String
  serviceId       String
  totalSessions   Int
  usedSessions    Int      @default(0)
  priceTotal      Int
  stripePaymentId String?
  expiresAt       DateTime
  createdAt       DateTime @default(now())
}

// ═══════════════════════════════════════════
// WAITLIST
// ═══════════════════════════════════════════

model WaitlistEntry {
  id          String    @id @default(cuid())
  serviceId   String
  service     Service   @relation(fields: [serviceId], references: [id])
  date        String
  clientName  String
  clientEmail String
  position    Int
  status      String    @default("QUEUED")
  notifiedAt  DateTime?
  expiresAt   DateTime?
  createdAt   DateTime  @default(now())
}

// ═══════════════════════════════════════════
// AUDIT TRAIL
// ═══════════════════════════════════════════

model AuditLog {
  id          String   @id @default(cuid())
  entityType  String
  entityId    String
  action      String
  oldData     Json?
  newData     Json?
  performedBy String
  createdAt   DateTime @default(now())

  @@index([entityType, entityId])
  @@index([createdAt])
}
```

## Index Decisions

| Index | Why | Without it |
|-------|-----|-----------|
| `@@unique([startsAt, serviceId])` on Appointment | DB-level double-booking prevention | Race condition → overlapping bookings |
| `@@unique([startsAt, serviceId])` on SlotHold | Prevent two users holding same slot | Two holds for one slot |
| `@@index([expiresAt])` on SlotHold | Fast expired hold cleanup | Full table scan on every availability query |
| `@@index([startsAt])` on Appointment | Fast "today's appointments" query | Slow dashboard load |
| `@@index([status])` on Appointment | Fast status filtering | Slow "all confirmed" queries |
| `@@index([clientId])` on Appointment | Fast client history lookup | Slow client profile page |
| `@@unique([stripePaymentId])` on Appointment | Idempotent webhook processing | Duplicate appointments from webhook retry |

## Soft Delete Pattern

```ts
// Every query on deletable models:
const services = await prisma.service.findMany({
  where: { deletedAt: null, isActive: true }
})

// "Delete" — never use prisma.*.delete():
await prisma.service.update({
  where: { id },
  data: { deletedAt: new Date(), isActive: false }
})
```

**Rule:** Never `prisma.*.delete()` on Service, Client, or Appointment. Always soft-delete.
SlotHold and AuditLog CAN be hard-deleted (ephemeral/append-only).

## Audit Trail Helper

```ts
// lib/audit.ts
export async function logAudit(params: {
  entityType: string
  entityId: string
  action: string
  oldData?: any
  newData?: any
  performedBy: string
}) {
  await prisma.auditLog.create({ data: params })
}

// Usage:
await logAudit({
  entityType: "appointment",
  entityId: appointment.id,
  action: "status_changed",
  oldData: { status: "HOLD" },
  newData: { status: "CONFIRMED" },
  performedBy: "webhook"
})
```
