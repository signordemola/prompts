# Discount System Deep Dive

## Coupon Types

### PERCENTAGE

```ts
const discount = Math.round(subtotal * coupon.value / 100)
// Cap if maxDiscountAmount set:
const capped = coupon.maxDiscountAmount
  ? Math.min(discount, coupon.maxDiscountAmount)
  : discount
```

### FIXED_AMOUNT

```ts
const discount = Math.min(coupon.value, subtotal) // never exceed subtotal
```

### FREE_SHIPPING

```ts
// Set shippingAmount = 0 for the order
// Only applies to standard shipping (not express)
```

### BUY_X_GET_Y

```ts
function applyBXGY(cart: CartItem[], coupon: Coupon): number {
  // Find qualifying items
  const qualifyingItems = cart.filter(i =>
    coupon.productIds.length === 0 || coupon.productIds.includes(i.variantId)
  )
  const totalQualifyingQty = qualifyingItems.reduce((sum, i) => sum + i.quantity, 0)
  
  // How many "sets" of X qualify?
  const sets = Math.floor(totalQualifyingQty / coupon.buyQuantity!)
  const freeItems = sets * coupon.getQuantity!
  
  // Discount = price of cheapest N items (the "free" ones)
  const prices = qualifyingItems
    .flatMap(i => Array(i.quantity).fill(i.variant.price))
    .sort((a, b) => a - b)
  
  return prices.slice(0, freeItems).reduce((sum, p) => sum + p, 0)
}
```

## Automatic Discounts

```ts
// Applied without a code. `code` is null, `isAutomatic` is true.
// During checkout, query all active automatic discounts:
const autoDiscounts = await prisma.coupon.findMany({
  where: {
    isAutomatic: true,
    isActive: true,
    startsAt: { lte: now },
    endsAt: { gte: now },
  },
  orderBy: { priority: "desc" },
})

// Apply all that meet conditions (they stack)
for (const discount of autoDiscounts) {
  if (subtotal >= (discount.minOrderAmount ?? 0)) {
    totalDiscount += calculateDiscount(discount, subtotal)
  }
}
```

## First-Order Discount

```ts
// Check if customer has previous orders:
const previousOrders = await prisma.order.count({
  where: { customerEmail: email, status: { not: "CANCELLED" } }
})
const isFirstOrder = previousOrders === 0

// Coupon: add `isFirstOrderOnly: true` flag
// Validation: if (coupon.isFirstOrderOnly && !isFirstOrder) return { error: "First order only" }
```

## Usage Tracking

```ts
// Atomic increment in order creation transaction:
await tx.coupon.update({
  where: { id: coupon.id },
  data: { usedCount: { increment: 1 } }
})

// Per-user limit check:
const userUses = await tx.order.count({
  where: { couponId: coupon.id, customerEmail: email }
})
if (coupon.maxUsesPerUser && userUses >= coupon.maxUsesPerUser) {
  return { error: "You've already used this code" }
}
```

## Display Pattern

```tsx
// Cart page:
<div className="coupon-input">
  <input placeholder="Discount code" value={code} onChange={...} />
  <button onClick={applyCoupon}>Apply</button>
</div>

{appliedDiscount && (
  <div className="discount-line">
    <span>Discount ({appliedCoupon.code})</span>
    <span>-{formatCurrency(appliedDiscount, market)}</span>
    <button onClick={removeCoupon}>×</button>
  </div>
)}
```
