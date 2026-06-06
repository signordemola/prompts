---
name: stripe-payments
description: >
  Stripe payment integration patterns. ACTIVATE when: implementing checkout,
  creating PaymentIntents, handling webhooks, processing refunds, or any
  code touching Stripe APIs. Works for booking deposits, ecommerce checkout,
  subscription billing, and one-time payments.
---

# Stripe Payments Skill

## When to Use
- Implementing any payment flow
- Creating or modifying webhook handlers
- Processing refunds or disputes
- Setting up Stripe env vars

## Instructions

### Step 1: Choose the right flow
| Use case | Pattern |
|----------|---------|
| Booking deposit | PaymentIntent + metadata + webhook |
| Ecommerce cart | Embedded Checkout Session |
| Subscription | Stripe Billing + Customer Portal |
| One-time product | Checkout Session (redirect) |

### Step 2: Store ALL state in Stripe metadata
Client-side state (Zustand, localStorage) is cleared on redirect.
```ts
const paymentIntent = await stripe.paymentIntents.create({
  amount: service.deposit,  // already pence — NEVER multiply by 100
  currency: "gbp",
  metadata: {
    holdToken, serviceSlug, clientName,
    clientEmail, clientPhone, startsAt: startsAt.toISOString()
  },
  idempotencyKey: `booking_${holdToken}`
})
```

### Step 3: Webhook handler pattern

**Next.js (App Router):**
```ts
// app/api/stripe/webhook/route.ts
export async function POST(req: Request) {
  const body = await req.text()
  const sig = req.headers.get("stripe-signature")!
  const event = stripe.webhooks.constructEvent(body, sig, WEBHOOK_SECRET)

  if (event.type !== "payment_intent.succeeded") {
    return NextResponse.json({ received: true })
  }

  // Idempotency check
  const existing = await prisma.appointment.findFirst({
    where: { stripePaymentId: event.data.object.id }
  })
  if (existing) return NextResponse.json({ received: true })

  // Create record in DB transaction
  // Delete hold
  // Send confirmation email

  return NextResponse.json({ received: true })
}
```

**NestJS:**
```ts
// modules/stripe/stripe.controller.ts
@Controller("stripe")
export class StripeController {
  @Post("webhook")
  async handleWebhook(@Req() req: RawBodyRequest<Request>) {
    const sig = req.headers["stripe-signature"]
    const event = this.stripe.webhooks.constructEvent(
      req.rawBody, sig, this.configService.get("STRIPE_WEBHOOK_SECRET"),
    )

    if (event.type !== "payment_intent.succeeded") return { received: true }

    // Same idempotency + DB transaction pattern as above
    return { received: true }
  }
}
// NOTE: Enable raw body parsing in main.ts: app.useBodyParser("raw", { type: "application/json" })
```

**FastAPI:**
```python
# routers/stripe.py
@router.post("/webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig = request.headers.get("stripe-signature")
    event = stripe.Webhook.construct_event(payload, sig, WEBHOOK_SECRET)

    if event["type"] != "payment_intent.succeeded":
        return {"received": True}

    # Same idempotency + DB transaction pattern as above
    return {"received": True}
```

### Step 4: Env vars required
```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...          # NEXT_PUBLIC_ prefix only for Next.js
STRIPE_WEBHOOK_SECRET=whsec_...
```

## NEVER
- ❌ Accept price from client — calculate server-side
- ❌ Multiply DB values by 100 — they're already pence
- ❌ Skip webhook signature verification
- ❌ Process webhooks without idempotency checks
- ❌ Store card numbers — use Stripe Elements
