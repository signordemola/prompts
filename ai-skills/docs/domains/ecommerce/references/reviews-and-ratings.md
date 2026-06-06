# Reviews & Ratings

## Schema

```prisma
model Review {
  id          String   @id @default(cuid())
  productId   String
  product     Product  @relation(fields: [productId], references: [id])
  orderId     String?  // verified purchase badge
  authorName  String
  authorEmail String
  rating      Int      // 1-5
  title       String?
  body        String
  status      String   @default("PENDING") // PENDING | APPROVED | REJECTED
  isVerified  Boolean  @default(false)
  createdAt   DateTime @default(now())
}
```

## Aggregate Rating

```ts
async function getProductRating(productId: string) {
  const agg = await prisma.review.aggregate({
    where: { productId, status: "APPROVED" },
    _avg: { rating: true },
    _count: true,
  })
  return {
    average: Math.round((agg._avg.rating ?? 0) * 10) / 10, // 4.3
    count: agg._count,
  }
}
```

## Verified Purchase

```ts
// Mark as verified if orderId links to a real order with this product
const isVerified = await prisma.order.findFirst({
  where: {
    id: review.orderId,
    customerEmail: review.authorEmail,
    lineItems: { some: { variant: { productId: review.productId } } },
    status: { in: ["DELIVERED", "COMPLETED"] },
  }
})
```

## Moderation

| Level | Strategy |
|-------|---------|
| **None** | All reviews published immediately (risky) |
| **Auto + manual** | Auto-approve 4-5 stars, queue 1-3 for review |
| **All manual** | Every review queued (safe, slow) |

> **Default:** Auto-approve verified purchases with 3+ stars. Queue all others.

## Display Patterns

```tsx
// Star rating component
function Stars({ rating }: { rating: number }) {
  return (
    <div role="img" aria-label={`${rating} out of 5 stars`}>
      {[1,2,3,4,5].map(i => (
        <span key={i}>{i <= rating ? '★' : '☆'}</span>
      ))}
    </div>
  )
}

// Rating distribution bar
// 5 ★ ████████████ 45
// 4 ★ ████████     30
// 3 ★ ███          12
// 2 ★ █             4
// 1 ★ █             2
```
