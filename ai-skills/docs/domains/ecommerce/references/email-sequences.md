# Ecommerce Email Sequences

## Transactional Emails

| Email | Trigger | Send within | Must include |
|-------|---------|-------------|-------------|
| Order confirmation | `checkout.session.completed` | Immediately | Order #, items, total, shipping address, tracking page link |
| Shipping notification | Fulfillment created | Immediately | Tracking #, carrier, tracking URL, estimated delivery |
| Delivered | Carrier webhook or manual | Immediately | "Your order has arrived", review CTA |
| Review request | 7 days post-delivery | 7 days | Product image, 1-click star rating, review link |

## Recovery Emails

| Email | Trigger | Send after | Content |
|-------|---------|-----------|---------|
| Cart abandonment 1 | Cart with email, no order | 1 hour | "You left items in your cart" + cart contents |
| Cart abandonment 2 | Still no order | 24 hours | Social proof + testimonials |
| Cart abandonment 3 | Still no order | 72 hours | Incentive (10% off or free shipping) |
| Browse abandonment | Viewed product, no ATC | 2 hours | "Still interested in X?" |
| Back in stock | Variant stock > 0 | Immediately | "X is back!" + direct buy link |

## Order Confirmation Template

```tsx
// Must include:
// 1. Order number (human-readable)
// 2. Line items with images, names, quantities, prices
// 3. Subtotal, shipping, tax, discount, total
// 4. Shipping address
// 5. Estimated delivery date
// 6. "Track your order" CTA
// 7. "Need help?" contact link

<Section>
  <Heading>Order Confirmed ✓</Heading>
  <Text>Order #{order.orderNumber}</Text>
  
  {order.lineItems.map(item => (
    <Row key={item.id}>
      <Img src={item.imageUrl} width={64} />
      <Column>
        <Text>{item.productName}</Text>
        <Text>{item.variantName} × {item.quantity}</Text>
      </Column>
      <Text>{formatCurrency(item.totalPrice, market)}</Text>
    </Row>
  ))}
  
  <Hr />
  <Row><Text>Subtotal</Text><Text>{formatCurrency(order.subtotal)}</Text></Row>
  <Row><Text>Shipping</Text><Text>{formatCurrency(order.shippingAmount)}</Text></Row>
  {order.discountAmount > 0 && (
    <Row><Text>Discount</Text><Text>-{formatCurrency(order.discountAmount)}</Text></Row>
  )}
  <Row><Text><strong>Total</strong></Text><Text><strong>{formatCurrency(order.total)}</strong></Text></Row>
</Section>
```

## Shipping Notification

```tsx
<Section>
  <Heading>Your order is on its way! 📦</Heading>
  <Text>Tracking: {fulfillment.trackingNumber}</Text>
  <Text>Carrier: {fulfillment.carrier}</Text>
  <Button href={fulfillment.trackingUrl}>Track Your Package →</Button>
</Section>
```

## Review Request (7 Days Post-Delivery)

```tsx
<Section>
  <Heading>How was your order?</Heading>
  <Img src={product.primaryImage} width={120} />
  <Text>Tell us about your {product.name}</Text>
  {[1,2,3,4,5].map(star => (
    <Link href={`/review/${order.id}?rating=${star}`}>{'⭐'.repeat(star)}</Link>
  ))}
</Section>
```

## Cart Abandonment (Requires Server-Side Cart)

```ts
// Cron: every hour, find abandoned carts
const abandoned = await prisma.cart.findMany({
  where: {
    updatedAt: { lt: subHours(new Date(), 1) },
    // No order exists for this cart
    // Email captured at checkout step 1
  },
  include: { items: { include: { variant: { include: { product: true } } } } }
})
```

## NEVER
- ❌ Send from "no-reply" address
- ❌ Skip order number in confirmation
- ❌ Show current prices instead of purchase prices in order emails
- ❌ Send review request before delivery
- ❌ Send abandonment email without unsubscribe link
