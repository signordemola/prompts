---
name: order-lifecycle
description: >
  Order state machine and fulfillment workflow. ACTIVATE when: creating orders,
  implementing status transitions, building fulfillment/packing flow, handling
  cancellations, partial fulfillment, or split shipments.
---

# Order Lifecycle Skill

## When to Use
- Creating order from cart/checkout
- Implementing status transitions
- Building fulfillment workflow (pick/pack/ship)
- Handling cancellations or partial fulfillment

## State Machine

```
PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED → COMPLETED
                                                        → RETURNED
                   → CANCELLED
```

| Status | Meaning | Can cancel? | Can refund? |
|--------|---------|------------|------------|
| PENDING | Payment not yet confirmed | ✅ (free) | N/A |
| CONFIRMED | Payment captured | ✅ (full refund) | ✅ |
| PROCESSING | Being picked/packed | ✅ (full refund) | ✅ |
| SHIPPED | In transit | ❌ (must return) | After return |
| DELIVERED | Arrived | ❌ (must return) | After return |
| COMPLETED | Finalized, review period passed | ❌ | ❌ |
| CANCELLED | Cancelled before shipping | — | Already refunded |
| RETURNED | Items returned post-delivery | — | Processed |

## Order Creation (Atomic)

```ts
async function createOrder(cart: Cart, address: Address, market: Market) {
  return prisma.$transaction(async (tx) => {
    // 1. Snapshot prices from variants
    const lineItems = await Promise.all(cart.items.map(async (item) => {
      const variant = await tx.productVariant.findUnique({
        where: { id: item.variantId },
        include: { product: true }
      })
      
      const price = variant[`price${market}`] // priceGBP, priceUSD, priceCAD
      
      return {
        variantId: variant.id,
        productName: variant.product.name,
        variantName: variant.name,
        sku: variant.sku,
        unitPrice: price,
        quantity: item.quantity,
        totalPrice: price * item.quantity,
      }
    }))
    
    // 2. Decrement inventory
    for (const item of lineItems) {
      const result = await tx.$executeRaw`
        UPDATE "ProductVariant"
        SET "inventoryQuantity" = "inventoryQuantity" - ${item.quantity}
        WHERE id = ${item.variantId}
        AND "inventoryQuantity" >= ${item.quantity}
      `
      if (result === 0) throw new Error(`Insufficient stock: ${item.sku}`)
    }
    
    // 3. Create order + line items
    const subtotal = lineItems.reduce((sum, li) => sum + li.totalPrice, 0)
    
    const order = await tx.order.create({
      data: {
        customerEmail: address.email,
        customerName: `${address.firstName} ${address.lastName}`,
        currency: CURRENCIES[market].code,
        subtotal,
        shippingAmount: shippingRate,
        taxAmount: calculateTax(subtotal, market),
        total: subtotal + shippingRate + taxAmount - discountAmount,
        shippingAddress: { connect: { id: address.id } },
        lineItems: { create: lineItems },
      }
    })
    
    // 4. Clear cart
    await tx.cart.delete({ where: { id: cart.id } })
    
    return order
  })
}
```

## Order Numbering

```ts
// Auto-increment starting at 1001
model Order {
  orderNumber Int @unique @default(autoincrement())
}
// Display: "#1001", "#1002"
// Config: set sequence start in seed:
// ALTER SEQUENCE "Order_orderNumber_seq" RESTART WITH 1001;
```

## Fulfillment Workflow

```
Owner Dashboard:
┌────────────────────────────────────────┐
│  Order #1042  ·  3 items  ·  CONFIRMED │
│                                        │
│  [x] Classic T-Shirt (S/Black) × 1    │
│  [x] Hoodie (M/Navy) × 1              │
│  [ ] Beanie (OS/Grey) × 1  (backorder)│
│                                        │
│  Tracking: ________________            │
│  Carrier:  [Royal Mail ▾]              │
│                                        │
│  [Fulfill Selected Items]              │
└────────────────────────────────────────┘
```

### Partial Fulfillment

```ts
// Fulfillment = subset of line items in one shipment
const fulfillment = await prisma.fulfillment.create({
  data: {
    orderId: order.id,
    status: "SHIPPED",
    trackingNumber: "RM123456789GB",
    carrier: "royal-mail",
    trackingUrl: "https://www.royalmail.com/track/RM123456789GB",
    shippedAt: new Date(),
    items: [
      { lineItemId: "...", quantity: 1 },
      { lineItemId: "...", quantity: 1 },
    ]
  }
})

// Update line item fulfilled quantities
// Update order status:
//   All items fulfilled → SHIPPED
//   Some items fulfilled → PROCESSING (partial)
```

## Cancellation

```ts
async function cancelOrder(orderId: string, cancelledBy: string) {
  const order = await prisma.order.findUnique({ where: { id: orderId } })
  
  if (["SHIPPED", "DELIVERED", "COMPLETED"].includes(order.status)) {
    return { error: "Cannot cancel shipped orders. Please initiate a return." }
  }
  
  await prisma.$transaction([
    // Restore inventory
    ...order.lineItems.map(li =>
      prisma.productVariant.update({
        where: { id: li.variantId },
        data: { inventoryQuantity: { increment: li.quantity } }
      })
    ),
    // Refund payment
    prisma.order.update({
      where: { id: orderId },
      data: { status: "CANCELLED", cancelledAt: new Date(), cancelledBy }
    }),
  ])
  
  // Process Stripe refund
  if (order.stripePaymentId) {
    await stripe.refunds.create({ payment_intent: order.stripePaymentId })
  }
}
```

## Audit Trail

```ts
// Every status change:
await logAudit({
  entityType: "order",
  entityId: order.id,
  action: "status_changed",
  oldData: { status: "CONFIRMED" },
  newData: { status: "SHIPPED", trackingNumber: "RM123..." },
  performedBy: "owner",
})
```

## References
- `references/database-schema.md` — Order, LineItem, Fulfillment models
- `references/returns-and-rma.md` — return flow after delivery
- `references/email-sequences.md` — order confirmation, shipping notification

## NEVER
- ❌ Skip atomic transaction for order creation
- ❌ Reference current product price in existing orders
- ❌ Allow cancellation after shipping (must return)
- ❌ Delete orders (only cancel)
- ❌ Skip inventory restoration on cancellation
