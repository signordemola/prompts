# Ecommerce Testing Patterns

## What to Test

| Area | Test type | Priority |
|------|----------|----------|
| Order creation | Integration | Critical |
| Inventory decrement | Unit | Critical |
| Coupon validation | Unit | High |
| Cart merge | Integration | High |
| Webhook idempotency | Unit | Critical |
| Price snapshot | Unit | High |
| Checkout validation | Integration | High |
| Return flow | Integration | Medium |

## Mocking Stripe

```ts
// Mock Stripe Checkout Session
const mockSession = {
  id: "cs_test_123",
  metadata: { cartId: "cart_123", market: "UK" },
  payment_intent: "pi_test_456",
  amount_total: 3500,
  currency: "gbp",
}

// Mock webhook event
const mockEvent = {
  type: "checkout.session.completed",
  data: { object: mockSession },
}
```

## Inventory Race Condition Test

```ts
test("concurrent purchases don't oversell", async () => {
  // Set stock to 1
  await prisma.productVariant.update({
    where: { id: variantId },
    data: { inventoryQuantity: 1 }
  })
  
  // Two concurrent purchase attempts
  const [result1, result2] = await Promise.allSettled([
    purchaseVariant(variantId, 1),
    purchaseVariant(variantId, 1),
  ])
  
  // Exactly one should succeed
  const successes = [result1, result2].filter(r => r.status === "fulfilled")
  expect(successes).toHaveLength(1)
  
  // Stock should be 0
  const variant = await prisma.productVariant.findUnique({ where: { id: variantId } })
  expect(variant.inventoryQuantity).toBe(0)
})
```

## Price Snapshot Test

```ts
test("order preserves price at purchase time", async () => {
  // Create order at £25
  const order = await createOrder(cart)
  expect(order.lineItems[0].unitPrice).toBe(2500)
  
  // Change product price to £30
  await prisma.productVariant.update({
    where: { id: variantId },
    data: { priceGBP: 3000 }
  })
  
  // Order should still show £25
  const savedOrder = await prisma.order.findUnique({
    where: { id: order.id },
    include: { lineItems: true }
  })
  expect(savedOrder.lineItems[0].unitPrice).toBe(2500)
})
```

## Coupon Edge Cases

```ts
test("expired coupon rejected", async () => {
  const result = await validateCoupon("EXPIRED10", cart, "UK")
  expect(result.error).toBe("Expired")
})

test("over-limit coupon rejected", async () => {
  const result = await validateCoupon("MAXED_OUT", cart, "UK")
  expect(result.error).toBe("Fully redeemed")
})

test("discount never exceeds subtotal", async () => {
  const result = await validateCoupon("BIG_DISCOUNT", smallCart, "UK")
  expect(result.discount).toBeLessThanOrEqual(smallCart.subtotal)
})
```
