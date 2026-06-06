---
name: payment-and-pricing
description: >
  Payment integration and pricing logic. ACTIVATE when: implementing Stripe checkout,
  calculating deposits, processing refunds, building promo/discount systems, or
  any code touching money. Covers pre-auth vs capture, deposit strategies, promo
  codes, and server-side pricing.
---

# Payment & Pricing Skill

## When to Use
- Implementing Stripe PaymentIntents or Checkout
- Calculating deposits or discounts
- Building promo code systems
- Processing refunds

## Pre-Auth vs Immediate Capture

<HARD-GATE>
**⛔ MANDATORY — ALL PRICES MUST BE CALCULATED SERVER-SIDE.**
Never accept price, amount, or discount values from the client. Read prices from the database. Store amounts in smallest currency unit (pence/cents). Never multiply DB values by 100.
</HARD-GATE>

| | Pre-Auth (hold → capture) | Immediate Capture |
|---|---|---|
| **How** | `capture_method: "manual"` → capture later | Default — charges immediately |
| **Refund** | Release hold (no refund needed) | Full refund required |
| **Hold duration** | 7 days max (Stripe) | N/A |
| **Complexity** | Higher (two API calls) | Lower (one call) |
| **Best for** | Hotels, events, variable pricing | Deposits, same-day services |

> **Default:** Immediate capture. Deposits are non-refundable by design.

> **Use pre-auth when:** Service price changes after booking, or charge only after delivery.

## Deposit Strategy

| Strategy | When | Tradeoff |
|----------|------|---------|
| **Fixed** (£10–20) | Low-value services | Simple, doesn't scale |
| **Percentage** (20–50%) | Most platforms | Scales with price |
| **Full prepayment** | Premium/luxury | Max protection, higher friction |
| **Card-on-file** (no deposit) | Loyal clients | Low friction, dispute risk |

> **Default:** Percentage-based, configurable per service:
```prisma
model Service {
  price          Int     // pence/cents
  depositPercent Float   @default(0.20) // 20%
}
```

Calculate server-side only:
```ts
export function calculateDeposit(service: Service): number {
  return Math.round(service.price * service.depositPercent)
}
```

## Price Calculation

**ALWAYS server-side.** Never accept `amount` from the client.

```ts
// In POST /api/stripe/checkout
const service = await prisma.service.findUnique({ where: { slug } })
const deposit = calculateDeposit(service)

const paymentIntent = await stripe.paymentIntents.create({
  amount: deposit,  // already pence — NEVER multiply by 100
  currency: "gbp",
  metadata: { holdToken, serviceSlug, clientName, clientEmail, startsAt },
  idempotencyKey: `booking_${holdToken}`
})
```

## Promo Codes (When Needed)

### Schema

```prisma
model PromoCode {
  id            String   @id @default(cuid())
  code          String   @unique
  discountType  String   // "PERCENT" | "FIXED"
  discountValue Int      // 10 = 10%, or 500 = £5.00
  maxUses       Int?     // null = unlimited
  usedCount     Int      @default(0)
  validFrom     DateTime
  validUntil    DateTime
  minSpend      Int?     // pence
  serviceIds    String[] // empty = all services
}
```

### Validation (Server-Side Only)

```ts
const promo = await prisma.promoCode.findUnique({ where: { code } })
if (!promo) return { error: "Invalid code" }
if (now < promo.validFrom || now > promo.validUntil) return { error: "Expired" }
if (promo.maxUses && promo.usedCount >= promo.maxUses) return { error: "Fully redeemed" }

const discount = promo.discountType === "PERCENT"
  ? Math.round(deposit * promo.discountValue / 100)
  : Math.min(promo.discountValue, deposit)

// Increment usage atomically in booking transaction
await prisma.promoCode.update({
  where: { id: promo.id },
  data: { usedCount: { increment: 1 } }
})
```

> **When to skip:** Build booking flow first. Add promo codes only if client requests.

## Stripe Refund API

```ts
// lib/refund.ts
export async function processRefund(appointment: Appointment, amount: number) {
  if (!appointment.stripePaymentId) throw new Error("No payment to refund")
  if (amount <= 0) return null
  
  const refund = await stripe.refunds.create({
    payment_intent: appointment.stripePaymentId,
    amount, // pence — partial or full
  })
  
  await prisma.appointment.update({
    where: { id: appointment.id },
    data: {
      refundAmount: amount,
      stripeRefundId: refund.id,
      status: "CANCELLED",
      cancelledAt: new Date(),
    }
  })
  
  return refund
}
```

## Payment Edge Cases

| Scenario | What happens | Your code must |
|----------|-------------|---------------|
| Card declined | `card_declined` error | Show friendly error, let retry |
| 3DS required | `requires_action` | Client completes 3DS in Elements |
| 3DS abandoned | User closes popup | Hold expires, slot freed |
| Insufficient funds | `insufficient_funds` | Suggest different card |
| Stripe outage | Network error | Catch, show "try again", NO appointment |
| Webhook arrives twice | Same `payment_intent.id` | Idempotency → skip |
| Webhook never arrives | Payment ok, no appointment | Reconciliation cron |
| Refund low balance | Refund enters `pending` | Show "processing" not "refunded" |
| Dispute/chargeback | `charge.dispute.created` | Log, notify owner, don't auto-cancel |

## Prepaid Packages (When Needed)

```ts
// Redemption: client books with a package
const pkg = await prisma.prepaidPackage.findFirst({
  where: { clientId, serviceId, expiresAt: { gt: new Date() } }
})
if (!pkg || pkg.usedSessions >= pkg.totalSessions) {
  return { error: "No sessions remaining" }
}
// Create appointment with zero deposit
const appointment = await prisma.appointment.create({
  data: { ...bookingData, depositAmount: 0, totalPrice: 0 }
})
// Decrement package
await prisma.prepaidPackage.update({
  where: { id: pkg.id },
  data: { usedSessions: { increment: 1 } }
})
```

> **When to skip:** Build for demos only if client specifically requests packages.

## References
- `references/database-schema.md` — full schema with PrepaidPackage model
- `references/dashboard-patterns.md` — confirmation page implementation

## NEVER
- ❌ Accept price/amount from the client
- ❌ Multiply DB values by 100 (already pence)
- ❌ Read price from Zustand/localStorage
- ❌ Discount more than the deposit amount
- ❌ Apply promo without incrementing `usedCount` atomically
- ❌ Assume refund is instant (can be `pending` with low Stripe balance)

