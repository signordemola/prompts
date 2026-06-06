---
name: inventory-management
description: >
  Stock tracking and overselling prevention. ACTIVATE when: managing inventory,
  implementing stock reservations during checkout, preventing overselling,
  handling backorders, or configuring low-stock alerts.
---

# Inventory Management Skill

## When to Use
- Tracking stock levels per variant
- Preventing overselling during concurrent checkouts
- Implementing inventory reservations
- Handling backorder/pre-order logic

## Stock Tracking

```ts
// Stock lives on ProductVariant
model ProductVariant {
  trackInventory    Boolean @default(true)
  inventoryQuantity Int     @default(0)
  lowStockThreshold Int     @default(5)
  allowBackorder    Boolean @default(false)
}
```

| `trackInventory` | `allowBackorder` | Behaviour |
|-------------------|-------------------|-----------|
| `false` | — | Always purchasable (digital, made-to-order) |
| `true` | `false` | Block purchase when stock = 0 |
| `true` | `true` | Allow purchase, show "Pre-order" with ETA |

## Atomic Stock Decrement (Critical)

```ts
// CORRECT: atomic DB operation
const result = await prisma.$executeRaw`
  UPDATE "ProductVariant"
  SET "inventoryQuantity" = "inventoryQuantity" - ${quantity}
  WHERE id = ${variantId}
  AND "inventoryQuantity" >= ${quantity}
`
if (result === 0) {
  throw new Error("Insufficient stock")
}

// WRONG: read → modify → write (race condition)
// const variant = await prisma.productVariant.findUnique(...)
// if (variant.inventoryQuantity >= quantity) {
//   await prisma.productVariant.update({ data: { inventoryQuantity: variant.inventoryQuantity - quantity } })
// }
```

## Inventory Reservation (During Checkout)

### Decision: When to Reserve

| Timing | Pros | Cons | Best for |
|--------|------|------|---------|
| **Add to cart** | Client sees accurate stock | Carts block inventory for days | Never (too aggressive) |
| **Checkout start** | Reserved while paying | 5-10 min TTL needed | High-demand items |
| **Payment success** | No phantom reserves | Could be OOS after entering address | Most stores |

> **Default:** Reserve at payment success (atomic decrement in webhook). For flash sales / limited drops: reserve at checkout start with 10-min TTL.

### Soft Reservation Pattern

```ts
model InventoryReservation {
  id        String   @id @default(cuid())
  variantId String
  quantity  Int
  sessionId String
  expiresAt DateTime // 10 minutes from checkout start
  createdAt DateTime @default(now())

  @@unique([variantId, sessionId])
  @@index([expiresAt])
}

// Available stock = inventoryQuantity - SUM(active reservations)
async function getAvailableStock(variantId: string): Promise<number> {
  const variant = await prisma.productVariant.findUnique({ where: { id: variantId } })
  const reserved = await prisma.inventoryReservation.aggregate({
    where: { variantId, expiresAt: { gt: new Date() } },
    _sum: { quantity: true }
  })
  return variant.inventoryQuantity - (reserved._sum.quantity ?? 0)
}
```

## Low Stock Alerts

```ts
// After any stock decrement, check threshold
if (variant.inventoryQuantity <= variant.lowStockThreshold) {
  await notifyOwner({
    type: "LOW_STOCK",
    message: `${variant.sku} has ${variant.inventoryQuantity} remaining`,
  })
}
```

## Stock Display on Storefront

| Stock level | Show |
|------------|------|
| > threshold | Nothing (don't show number) |
| 1–threshold | "Only X left!" (urgency) |
| 0 + backorder | "Pre-order — ships in 2 weeks" |
| 0, no backorder | "Out of stock" + notify button |

## Restock on Return

```ts
// When return is received and approved for restock:
await prisma.productVariant.update({
  where: { id: variantId },
  data: { inventoryQuantity: { increment: returnedQuantity } }
})
```

## References
- `references/database-schema.md` — ProductVariant inventory fields
- `references/edge-cases.md` — OOS during checkout, concurrent purchase

## NEVER
- ❌ Decrement stock with read-modify-write (use atomic SQL)
- ❌ Reserve at add-to-cart (blocks inventory for idle carts)
- ❌ Show exact stock counts publicly (show urgency messaging instead)
- ❌ Allow negative stock without `allowBackorder` flag
- ❌ Skip stock re-validation at payment time
