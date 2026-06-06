---
name: payment-and-pricing
description: >
  Ecommerce payment integration and pricing. ACTIVATE when: implementing Stripe
  checkout for products, building discount/coupon systems, handling multi-currency
  pricing, tax calculation, or saved payment methods.
---

# Payment & Pricing Skill

## When to Use
- Integrating Stripe for product checkout
- Building discount/coupon systems
- Multi-currency product pricing
- Tax calculation per market

## Stripe: Checkout Sessions vs PaymentIntents

| | Checkout Sessions (Default) | PaymentIntents (Custom) |
|---|---|---|
| **Effort** | Low — pre-built UI | High — build everything |
| **Tax/shipping** | Automatic via Stripe Tax | Manual calculation |
| **Saved cards** | Built-in consent UI | Build yourself |
| **PCI scope** | Minimal (hosted) | Higher |
| **Best for** | Most stores, demos | Fully branded checkout |

> **Default:** Stripe Checkout Sessions.

```ts
// POST /api/checkout
const session = await stripe.checkout.sessions.create({
  mode: "payment",
  currency: CURRENCIES[market].code,
  line_items: cart.items.map(item => ({
    price_data: {
      currency: CURRENCIES[market].code,
      unit_amount: item.variant[`price${market}`],
      product_data: {
        name: item.variant.product.name,
        description: item.variant.name,
        images: [item.variant.product.images[0]?.url],
      },
    },
    quantity: item.quantity,
  })),
  shipping_options: shippingRates,
  automatic_tax: { enabled: true },
  customer_email: customerEmail,
  metadata: { cartId: cart.id, market },
  success_url: `${origin}/order/confirmation?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${origin}/cart`,
})
```

## Webhook Handler

```ts
// POST /api/stripe/webhook
const event = stripe.webhooks.constructEvent(body, sig, webhookSecret)

if (event.type === "checkout.session.completed") {
  const session = event.data.object
  
  // Idempotency: check if order already exists
  const existing = await prisma.order.findFirst({
    where: { stripeSessionId: session.id }
  })
  if (existing) return NextResponse.json({ received: true })
  
  // Create order from cart
  const cart = await prisma.cart.findUnique({
    where: { id: session.metadata.cartId },
    include: { items: { include: { variant: { include: { product: true } } } } }
  })
  
  const order = await createOrder(cart, session)
  await sendOrderConfirmationEmail(order)
}
```

## Discount System

### Types

| Type | Example | Value field |
|------|---------|------------|
| PERCENTAGE | "20% off" | `value: 20` |
| FIXED_AMOUNT | "£10 off" | `value: 1000` (pence) |
| FREE_SHIPPING | "Free delivery" | `value: 0` |
| BUY_X_GET_Y | "Buy 2 get 1 free" | `buyQuantity: 2, getQuantity: 1` |

### Validation

```ts
async function validateCoupon(code: string, cart: Cart, market: Market) {
  const coupon = await prisma.coupon.findUnique({ where: { code } })
  if (!coupon) return { error: "Invalid code" }
  if (!coupon.isActive) return { error: "Inactive" }
  if (new Date() < coupon.startsAt || new Date() > coupon.endsAt) return { error: "Expired" }
  if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) return { error: "Fully redeemed" }
  
  const subtotal = calculateSubtotal(cart, market)
  if (coupon.minOrderAmount && subtotal < coupon.minOrderAmount) {
    return { error: `Minimum spend: ${formatCurrency(coupon.minOrderAmount, market)}` }
  }
  
  // Calculate discount
  let discount = 0
  if (coupon.type === "PERCENTAGE") {
    discount = Math.round(subtotal * coupon.value / 100)
    if (coupon.maxDiscountAmount) discount = Math.min(discount, coupon.maxDiscountAmount)
  } else if (coupon.type === "FIXED_AMOUNT") {
    discount = Math.min(coupon.value, subtotal)
  }
  
  return { valid: true, discount, coupon }
}
```

### Stacking Rules

| Rule | Default |
|------|---------|
| Max 1 coupon code per order | ✅ |
| Automatic discounts can stack with coupon | ✅ |
| Multiple automatic discounts can stack | ✅ (by priority) |
| Discount > subtotal | ❌ (cap at subtotal) |

## Multi-Currency Pricing

```ts
// Fixed prices per variant per currency (not dynamic conversion)
const variant = {
  priceGBP: 2500,  // £25.00
  priceUSD: 3000,  // $30.00
  priceCAD: 4000,  // C$40.00
}

// Get price for market:
function getPrice(variant: ProductVariant, market: Market): number {
  const key = `price${market}` as keyof ProductVariant
  return variant[key] as number
}
```

> Cross-reference: `../booking/references/multi-currency.md` for full currency formatting patterns.

## References
- `references/database-schema.md` — Coupon model
- `references/discount-system.md` — BXGY logic, automatic discounts, stacking deep dive
- `references/edge-cases.md` — price change mid-checkout, double-purchase prevention
- Cross-ref: `../booking/references/tax-handling.md` — VAT/GST/sales tax

## NEVER
- ❌ Accept price from the client
- ❌ Skip webhook signature verification
- ❌ Allow discount > subtotal
- ❌ Apply coupon without incrementing `usedCount` atomically
- ❌ Use dynamic currency conversion (use fixed prices per market)
