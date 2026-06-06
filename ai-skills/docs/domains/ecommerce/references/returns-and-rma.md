# Returns & RMA

## Return State Machine

```
REQUESTED → APPROVED → SHIPPED_BACK → RECEIVED → REFUNDED
                                                → REJECTED
          → REJECTED (auto-reject if outside window)
```

## Return Schema

```prisma
model Return {
  id           String   @id @default(cuid())
  orderId      String
  order        Order    @relation(fields: [orderId], references: [id])
  status       String   @default("REQUESTED")
  items        Json     // [{ lineItemId, quantity, reasonCode }]
  refundAmount Int?
  stripeRefundId String?
  internalNote String?
  
  requestedAt  DateTime @default(now())
  approvedAt   DateTime?
  receivedAt   DateTime?
  refundedAt   DateTime?
}
```

## Self-Service Return Portal

```
/orders/[orderNumber]/return
  1. Select items to return (checkbox + quantity)
  2. Select reason per item (dropdown)
  3. Confirm → system auto-approves or queues for review
  4. Show return label (if auto-approved)
```

## Auto-Approve Rules

```ts
function shouldAutoApprove(returnRequest: ReturnRequest, order: Order): boolean {
  const daysSinceDelivery = differenceInDays(new Date(), order.deliveredAt)
  const isWithinWindow = daysSinceDelivery <= 30
  const isLowValue = returnRequest.items.every(i => i.totalPrice < 1000) // < £10
  const hasNoHistory = !hasExcessiveReturns(order.customerEmail)
  
  return isWithinWindow && hasNoHistory
}
```

## Disposition

| Code | Action | Refund |
|------|--------|--------|
| `RESTOCK` | Back to inventory | Full |
| `REFURBISH` | Clean/repair first | Full |
| `SCRAP` | Dispose | Partial or full |
| `RETURNLESS` | Keep item (low value) | Full |

## Returnless Refunds

```ts
// For items under £10 shipping cost:
if (itemValue < 1000) {
  // Don't ask customer to ship back
  await processRefund(order, itemValue)
  await updateReturnStatus(returnId, "REFUNDED")
  // Skip SHIPPED_BACK and RECEIVED states
}
```

## Fraud Prevention

```ts
// Flag serial returners:
const returnRate = await getReturnRate(customerEmail)
if (returnRate > 0.30) { // > 30% of orders returned
  // Queue for manual review instead of auto-approve
  // Consider: require account creation, limit payment methods
}
```
