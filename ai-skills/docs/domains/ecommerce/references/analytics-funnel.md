# Analytics & Conversion Funnel

## Funnel Events

```ts
export const ECOM_EVENTS = {
  PAGE_VIEW:        "ecom.page_view",
  PRODUCT_VIEWED:   "ecom.product_viewed",
  ADD_TO_CART:      "ecom.add_to_cart",
  REMOVE_FROM_CART: "ecom.remove_from_cart",
  CART_VIEWED:      "ecom.cart_viewed",
  CHECKOUT_STARTED: "ecom.checkout_started",
  CHECKOUT_STEP:    "ecom.checkout_step",     // step 1, 2, 3
  PAYMENT_STARTED:  "ecom.payment_started",
  ORDER_COMPLETED:  "ecom.order_completed",
  COUPON_APPLIED:   "ecom.coupon_applied",
  SEARCH_PERFORMED: "ecom.search_performed",
} as const
```

## Key Metrics

| Metric | Formula | Good benchmark |
|--------|---------|---------------|
| **Conversion rate** | Orders / Visitors | 2-3% |
| **AOV** (Avg Order Value) | Revenue / Orders | Market-dependent |
| **Cart abandonment rate** | 1 - (Orders / Carts created) | 60-70% typical |
| **Add-to-cart rate** | ATC events / PDP views | 8-12% |
| **Checkout abandonment** | 1 - (Orders / Checkouts started) | 25-40% |

## Dashboard Queries

```ts
// Revenue this month
const revenue = await prisma.order.aggregate({
  where: {
    status: { in: ["CONFIRMED", "PROCESSING", "SHIPPED", "DELIVERED", "COMPLETED"] },
    createdAt: { gte: startOfMonth },
  },
  _sum: { total: true },
  _count: true,
})

// AOV
const aov = revenue._sum.total / revenue._count

// Top products
const topProducts = await prisma.lineItem.groupBy({
  by: ["productName"],
  where: { order: { createdAt: { gte: startOfMonth } } },
  _sum: { quantity: true, totalPrice: true },
  orderBy: { _sum: { quantity: "desc" } },
  take: 10,
})
```

## Event Tracking Pattern

```ts
// Client-side (use analytics provider or custom)
function trackEvent(event: string, data?: Record<string, any>) {
  // Google Analytics 4
  if (typeof gtag !== "undefined") {
    gtag("event", event, data)
  }
  // Custom analytics endpoint
  fetch("/api/analytics", {
    method: "POST",
    body: JSON.stringify({ event, data, timestamp: Date.now() }),
  }).catch(() => {}) // fire and forget
}

// Usage:
trackEvent(ECOM_EVENTS.ADD_TO_CART, {
  productId: product.id,
  variantId: variant.id,
  price: variant.priceGBP,
  quantity: 1,
})
```
