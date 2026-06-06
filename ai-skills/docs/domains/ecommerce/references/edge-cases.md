# Ecommerce Edge Cases

## Double-Purchase Prevention

```ts
// Client clicks "Pay" twice
// Solution 1: Disable button after first click
// Solution 2: Stripe idempotency key = cartId
// Solution 3: Webhook checks for existing order with stripeSessionId

const existing = await prisma.order.findFirst({
  where: { stripeSessionId: session.id }
})
if (existing) return // already processed
```

## Price Change Mid-Checkout

```
Problem: Product price changes while customer is in checkout.
  Customer sees £25, owner changes to £30, payment charges £30.

Solution: Snapshot prices when creating Stripe session.
  Stripe line_items.price_data.unit_amount is frozen at session creation.
  If customer takes >24h, Checkout Session expires → they restart.
```

## Out-of-Stock During Checkout

```
Problem: Customer adds last item to cart. Another customer buys it
  while first customer fills in address.

Solution:
  1. Re-validate stock at checkout submission (before Stripe)
  2. Show clear error: "Sorry, X is no longer available"
  3. Offer alternatives or waitlist
```

## Payment Fails With Reserved Inventory

```
Problem: Stock decremented on checkout start. Payment fails.
  Stock is now blocked.

Solution:
  - If using "reserve at payment success": not an issue
  - If using soft reservations: TTL expires → stock released
  - Reconciliation cron: release expired reservations hourly
```

## Coupon Applied But Expired Between Cart and Payment

```ts
// Re-validate coupon at order creation:
const coupon = await prisma.coupon.findUnique({ where: { code: appliedCode } })
if (!coupon || now > coupon.endsAt || coupon.usedCount >= coupon.maxUses) {
  return { error: "Discount no longer valid. Your updated total is..." }
}
```

## Address Validation Failures

```
Problem: Customer enters invalid address. Carrier rejects.

Solution:
  - Format validation (postcode regex per country)
  - UK: postcodes.io API (free)
  - US: USPS Address API
  - CA: Canada Post AddressComplete
  - Show suggestions, don't hard-block
```

## Partial Fulfillment + Return

```
Problem: Order has 3 items. 2 shipped. Customer returns 1 shipped item.
  Remaining 1 item still pending.

Solution: Track per-line-item:
  - fulfilledQty on LineItem
  - Return references specific lineItemIds
  - Order status = PROCESSING until all items shipped
```

## Currency Mismatch

```
Problem: Customer starts checkout in GBP, switches VPN → sees USD.

Solution: Currency determined at session creation and frozen.
  env MARKET=UK → all prices in GBP. No mid-session switching.
```

## Zero-Quantity Cart Items

```ts
// Prevent:
if (quantity <= 0) await removeFromCart(variantId)
// Never allow 0 or negative quantities in DB
```

## Webhook Retry After Order Already Fulfilled

```ts
// Stripe retries webhooks for up to 3 days
// Always check idempotency:
const existing = await prisma.order.findFirst({
  where: { stripeSessionId: session.id }
})
if (existing) return NextResponse.json({ received: true })
```
