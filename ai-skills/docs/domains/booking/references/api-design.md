# API Design Patterns

## Endpoint Naming

```
GET    /api/services                    → list active services
GET    /api/services/:slug              → get single service
GET    /api/slots?serviceId=X&date=Y    → available slots for date
POST   /api/slots/hold                  → create hold
POST   /api/stripe/checkout             → create PaymentIntent
POST   /api/stripe/webhook              → handle Stripe webhook
GET    /api/appointments/:token         → get by manage token
PATCH  /api/appointments/:token         → cancel/reschedule
POST   /api/promo/validate              → validate promo code
GET    /api/dashboard/today             → owner: today's appointments
GET    /api/dashboard/stats             → owner: metrics
GET    /api/dashboard/clients           → owner: client list
PATCH  /api/dashboard/appointments/:id  → owner: mark complete/no-show
```

## Rules

- Plural nouns (`/appointments` not `/appointment`)
- No verbs in URLs (`POST /slots/hold` not `POST /slots/create-hold`)
- Lowercase with hyphens (`/promo-codes` not `/promoCodes`)
- HTTP methods define action (GET=read, POST=create, PATCH=update, DELETE=remove)

## Standard Error Format

```ts
// lib/api-error.ts
export function apiError(status: number, message: string, field?: string) {
  return NextResponse.json(
    { error: { message, field, status } },
    { status }
  )
}

// Usage:
return apiError(422, "Slot no longer available", "startsAt")
return apiError(429, "Too many requests")
return apiError(400, "Invalid promo code", "promoCode")
return apiError(401, "Unauthorised")
return apiError(404, "Appointment not found")
```

## Standard Success Format

```ts
// Single resource:
return NextResponse.json({ data: appointment })

// List:
return NextResponse.json({
  data: slots,
  meta: { count: slots.length, date, serviceId }
})
```

## HTTP Status Codes

| Code | When |
|------|------|
| `200` | Successful read or update |
| `201` | Resource created (hold, appointment) |
| `400` | Invalid input (bad date format, missing field) |
| `401` | Not authenticated (owner routes) |
| `404` | Resource not found |
| `409` | Conflict (slot already booked) |
| `422` | Valid format but business rule violation (slot unavailable) |
| `429` | Rate limited |
| `500` | Server error |

## Request Validation Pattern

```ts
import { z } from "zod"

const HoldSchema = z.object({
  serviceSlug: z.string().check(z.minLength(1)),
  startsAt: z.iso.datetime(),
  sessionId: z.string().check(z.minLength(1)),
})

export async function POST(req: Request) {
  const body = await req.json()
  const result = HoldSchema.safeParse(body)
  
  if (!result.success) {
    return apiError(400, result.error.issues[0].message, result.error.issues[0].path[0])
  }
  
  const { serviceSlug, startsAt, sessionId } = result.data
  // ... business logic
}
```
