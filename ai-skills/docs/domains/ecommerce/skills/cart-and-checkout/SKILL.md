---
name: cart-and-checkout
description: >
  Cart management and checkout flow. ACTIVATE when: building cart functionality,
  implementing checkout, handling guest vs account, cart abandonment, address
  validation, or price snapshot logic.
---

# Cart & Checkout Skill

## When to Use
- Building or modifying cart UI/logic
- Implementing checkout flow
- Handling guest ↔ account transitions
- Cart abandonment recovery

## Cart Storage Decision

| | Server-side DB | Client-side (localStorage) | Hybrid |
|---|---|---|---|
| **Persistence** | Cross-device, survives clear | Device-only | Server = truth, client = cache |
| **Abandonment recovery** | ✅ (email the user) | ❌ | ✅ |
| **Guest merge** | ✅ | Manual | ✅ |
| **Complexity** | Medium | Low | Medium |

> **Default:** Server-side DB. Cart identified by `sessionId` cookie (guest) or `userId` (authenticated).

## Cart Operations

```ts
// Server Actions (Next.js App Router)

async function addToCart(variantId: string, quantity: number) {
  const sessionId = getOrCreateSessionId(cookies())
  const cart = await getOrCreateCart(sessionId)
  
  await prisma.cartItem.upsert({
    where: { cartId_variantId: { cartId: cart.id, variantId } },
    create: { cartId: cart.id, variantId, quantity },
    update: { quantity: { increment: quantity } },
  })
  
  // Extend cart expiry
  await prisma.cart.update({
    where: { id: cart.id },
    data: { expiresAt: addDays(new Date(), 30) }
  })
  
  revalidatePath("/")
}

async function updateQuantity(variantId: string, quantity: number) {
  if (quantity <= 0) return removeFromCart(variantId)
  // Validate against stock
  const variant = await prisma.productVariant.findUnique({ where: { id: variantId } })
  if (variant.trackInventory && quantity > variant.inventoryQuantity) {
    return { error: `Only ${variant.inventoryQuantity} available` }
  }
  await prisma.cartItem.update({
    where: { cartId_variantId: { cartId: cart.id, variantId } },
    data: { quantity },
  })
}

async function removeFromCart(variantId: string) {
  await prisma.cartItem.delete({
    where: { cartId_variantId: { cartId: cart.id, variantId } },
  })
}
```

## Guest Cart → Account Merge

```ts
// Triggered on login/signup
async function mergeCarts(guestSessionId: string, userId: string) {
  const guestCart = await prisma.cart.findUnique({
    where: { sessionId: guestSessionId },
    include: { items: true }
  })
  if (!guestCart || guestCart.items.length === 0) return

  let userCart = await prisma.cart.findFirst({ where: { userId } })
  if (!userCart) {
    // Just reassign the guest cart
    await prisma.cart.update({
      where: { id: guestCart.id },
      data: { userId, sessionId: null }
    })
    return
  }

  // Merge: sum quantities for same variant
  for (const item of guestCart.items) {
    await prisma.cartItem.upsert({
      where: { cartId_variantId: { cartId: userCart.id, variantId: item.variantId } },
      create: { cartId: userCart.id, variantId: item.variantId, quantity: item.quantity },
      update: { quantity: { increment: item.quantity } },
    })
  }
  // Delete guest cart
  await prisma.cart.delete({ where: { id: guestCart.id } })
}
```

## Checkout Flow

```
Step 1: Information     Step 2: Shipping     Step 3: Payment
┌─────────────────┐    ┌──────────────┐     ┌──────────────┐
│ Email            │    │ Standard £5  │     │ Stripe       │
│ Shipping address │    │ Express  £12 │     │ Elements     │
│ Phone (optional) │    │ Free (>£50)  │     │              │
│ [Continue →]     │    │ [Continue →] │     │ [Pay now →]  │
└─────────────────┘    └──────────────┘     └──────────────┘
```

> **Default:** 3-step. For returning customers with saved address: collapse to 1 step.

### Checkout Validation (Server-Side)

```ts
async function validateCheckout(cart: Cart, address: Address) {
  const errors = []
  
  for (const item of cart.items) {
    const variant = await prisma.productVariant.findUnique({ where: { id: item.variantId } })
    if (!variant || !variant.isActive) errors.push(`${item.variantId} no longer available`)
    if (variant.trackInventory && item.quantity > variant.inventoryQuantity) {
      errors.push(`Only ${variant.inventoryQuantity} of ${variant.name} in stock`)
    }
  }
  
  if (!address.postalCode) errors.push("Postal code required")
  if (!["GB", "US", "CA"].includes(address.country)) errors.push("Unsupported country")
  
  return errors
}
```

## Cart Abandonment

| Trigger | When | Channel |
|---------|------|---------|
| Reminder 1 | 1 hour after abandonment | Email |
| Reminder 2 | 24 hours | Email |
| Reminder 3 | 72 hours (with incentive) | Email |

**Requires:** Server-side cart + email captured at checkout step 1.

## Cart Expiration Cleanup

```ts
// Cron job: delete carts older than 30 days
await prisma.cart.deleteMany({
  where: { expiresAt: { lt: new Date() } }
})
```

## References
- `references/database-schema.md` — Cart/CartItem models
- `references/edge-cases.md` — price change mid-checkout, OOS during checkout
- `references/email-sequences.md` — cart abandonment emails

## NEVER
- ❌ Force account creation before checkout
- ❌ Accept quantities from client without stock validation
- ❌ Reference current product price for existing orders (snapshot at purchase)
- ❌ Show cart count from localStorage as source of truth
- ❌ Skip re-validation at checkout (prices/stock may have changed)
