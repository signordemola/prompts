# Wishlist & Saved Items

## Schema

```prisma
model WishlistItem {
  id        String   @id @default(cuid())
  userId    String
  productId String
  createdAt DateTime @default(now())

  @@unique([userId, productId])
}
```

## Implementation

```ts
// Toggle wishlist (add/remove)
async function toggleWishlist(userId: string, productId: string) {
  const existing = await prisma.wishlistItem.findUnique({
    where: { userId_productId: { userId, productId } }
  })
  if (existing) {
    await prisma.wishlistItem.delete({ where: { id: existing.id } })
    return { wishlisted: false }
  }
  await prisma.wishlistItem.create({ data: { userId, productId } })
  return { wishlisted: true }
}

// Get wishlist with product data
async function getWishlist(userId: string) {
  return prisma.wishlistItem.findMany({
    where: { userId },
    include: {
      product: {
        include: {
          variants: { where: { isActive: true }, take: 1 },
          images: { where: { isPrimary: true }, take: 1 },
        }
      }
    },
    orderBy: { createdAt: "desc" },
  })
}
```

## UI Pattern

```tsx
<button
  onClick={() => toggleWishlist(productId)}
  aria-pressed={isWishlisted}
  aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
>
  {isWishlisted ? '❤️' : '🤍'}
</button>
```

## Notes
- Requires authenticated user (no guest wishlist)
- "Back in stock" emails use wishlist data
- Guest users: show "Sign in to save" tooltip
