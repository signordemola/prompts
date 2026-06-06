# Gift Cards & Vouchers

## When to Build

| Scenario | Build? |
|----------|--------|
| Demo project | ❌ Skip |
| Client requests gift cards | ✅ |
| Revenue diversification feature | ✅ |

## Schema

```prisma
model GiftCard {
  id             String   @id @default(cuid())
  code           String   @unique // random 12-char alphanumeric
  initialAmount  Int      // pence/cents
  currentBalance Int      // decremented on redemption
  status         String   @default("ACTIVE") // ACTIVE | EXPIRED | REDEEMED | CANCELLED
  currency       String   // "gbp" | "usd" | "cad"
  
  purchaserEmail String
  recipientEmail String
  recipientName  String?
  message        String?  // gift message
  
  stripePaymentId String? // payment for purchase
  expiresAt       DateTime // 12 months from purchase
  createdAt       DateTime @default(now())
  
  transactions   GiftCardTransaction[]
}

model GiftCardTransaction {
  id          String   @id @default(cuid())
  giftCardId  String
  giftCard    GiftCard @relation(fields: [giftCardId], references: [id])
  amount      Int      // positive = credit, negative = debit
  type        String   // "PURCHASE" | "REDEMPTION" | "REFUND"
  appointmentId String?
  createdAt   DateTime @default(now())
}
```

## Purchase Flow

```
1. Buyer selects amount (£25, £50, £100, custom)
2. Buyer enters recipient email + optional message
3. Stripe PaymentIntent for full amount
4. Webhook → create GiftCard + send email to recipient
```

## Redemption Flow

```ts
async function redeemGiftCard(code: string, bookingAmount: number) {
  const card = await prisma.giftCard.findUnique({ where: { code } })
  
  if (!card) return { error: "Invalid gift card" }
  if (card.status !== "ACTIVE") return { error: "Card is no longer active" }
  if (card.expiresAt < new Date()) return { error: "Card has expired" }
  if (card.currentBalance <= 0) return { error: "No balance remaining" }
  
  const deduction = Math.min(card.currentBalance, bookingAmount)
  const remaining = bookingAmount - deduction
  
  await prisma.$transaction([
    prisma.giftCard.update({
      where: { id: card.id },
      data: {
        currentBalance: { decrement: deduction },
        status: card.currentBalance - deduction <= 0 ? "REDEEMED" : "ACTIVE",
      }
    }),
    prisma.giftCardTransaction.create({
      data: { giftCardId: card.id, amount: -deduction, type: "REDEMPTION" }
    }),
  ])
  
  return {
    deduction,           // amount covered by gift card
    remainingToPay: remaining, // charge via Stripe if > 0
    newBalance: card.currentBalance - deduction,
  }
}
```

## Checkout Integration

```ts
// If gift card covers full amount:
//   → Skip Stripe, create appointment directly
// If partial:
//   → Stripe PaymentIntent for (bookingAmount - giftCardDeduction)
//   → Webhook creates appointment with both payment references
```

## Code Generation

```ts
import { randomBytes } from "crypto"

function generateGiftCardCode(): string {
  return randomBytes(6).toString("hex").toUpperCase().slice(0, 12)
  // e.g., "A3F8B2C9D1E4"
}
```

## NEVER
- ❌ Use sequential or guessable codes
- ❌ Allow redemption after expiry
- ❌ Skip the transaction ledger (just updating balance is not auditable)
- ❌ Allow cross-currency redemption (GBP card on USD booking)
