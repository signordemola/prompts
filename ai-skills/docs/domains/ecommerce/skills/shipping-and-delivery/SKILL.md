---
name: shipping-and-delivery
description: >
  Shipping rates, carriers, zones, and returns. ACTIVATE when: calculating shipping
  costs, configuring carriers per market (UK/US/CA), implementing free shipping
  thresholds, handling returns/RMA, or building shipment tracking.
---

# Shipping & Delivery Skill

## When to Use
- Calculating shipping rates
- Configuring carriers per market
- Implementing free shipping threshold
- Building return/RMA flow
- Shipment tracking integration

## Shipping Strategy Decision

| Strategy | Pros | Cons | Best for |
|----------|------|------|---------|
| **Flat rate** | Simple, predictable | Over/undercharge | Similar-weight products |
| **Free over threshold** | Boosts AOV | Margin impact | Conversion focus |
| **Calculated** | Accurate | High cart abandonment | Heavy/variable items |
| **Hybrid** | Balanced | More config | Most stores |

> **Default:** Flat rate + free shipping threshold.

## Shipping Configuration

```ts
// lib/shipping.ts
export const SHIPPING_RATES = {
  UK: {
    standard: { price: 500, label: "Standard (3-5 days)", carrier: "Royal Mail" },
    express: { price: 1200, label: "Express (1-2 days)", carrier: "DPD" },
    freeThreshold: 5000, // £50.00 — free standard shipping above this
  },
  US: {
    standard: { price: 800, label: "Standard (5-7 days)", carrier: "USPS" },
    express: { price: 2000, label: "Express (2-3 days)", carrier: "UPS" },
    freeThreshold: 7500, // $75.00
  },
  CA: {
    standard: { price: 1000, label: "Standard (5-10 days)", carrier: "Canada Post" },
    express: { price: 2500, label: "Express (2-4 days)", carrier: "Purolator" },
    freeThreshold: 10000, // C$100.00
  },
}

export function getShippingOptions(market: Market, subtotal: number) {
  const rates = SHIPPING_RATES[market]
  const options = []
  
  if (subtotal >= rates.freeThreshold) {
    options.push({ ...rates.standard, price: 0, label: "Free Standard Shipping" })
  } else {
    options.push(rates.standard)
  }
  options.push(rates.express)
  
  return options
}
```

## Free Shipping Progress Bar

```tsx
const remaining = freeThreshold - subtotal
{remaining > 0 ? (
  <div>
    <p>Add {formatCurrency(remaining, market)} more for free shipping!</p>
    <progress value={subtotal} max={freeThreshold} />
  </div>
) : (
  <p>✓ You qualify for free shipping!</p>
)}
```

## Carriers by Market

| Market | Standard | Express | Tracking |
|--------|----------|---------|----------|
| **UK** | Royal Mail (2nd Class) | DPD / Royal Mail Tracked 24 | royalmail.com/track |
| **US** | USPS Priority Mail | UPS Ground / FedEx | usps.com/tracking |
| **CA** | Canada Post Regular | Canada Post Xpresspost | canadapost.ca/track |

## Weight & DIM Weight

```ts
// Charge the greater of actual weight vs dimensional weight
function calculateDimWeight(l: number, w: number, h: number): number {
  const divisor = 5000 // standard international divisor (cm/g)
  return Math.ceil((l * w * h) / divisor)
}

function getChargeableWeight(variant: ProductVariant): number {
  if (!variant.weightGrams || !variant.lengthCm) return variant.weightGrams ?? 0
  const dimWeight = calculateDimWeight(variant.lengthCm, variant.widthCm!, variant.heightCm!)
  return Math.max(variant.weightGrams, dimWeight)
}
```

## Returns Flow

```
Customer: Initiate Return → Select Items → Reason → Submit
         ↓
System:   Auto-approve (if policy met) → Generate label → Email
         ↓
Customer: Ship back
         ↓
Warehouse: Receive → Inspect → Disposition (restock/scrap)
         ↓
System:   Process refund → Email confirmation
```

### Return Policy by Market

| Market | Statutory | Store policy (typical) |
|--------|----------|----------------------|
| **UK** | 14 days (distance selling regulations) | 30 days |
| **US** | None (store policy only) | 30 days |
| **CA** | Varies by province | 30 days |

### Reason Codes

```ts
export const RETURN_REASONS = [
  { code: "wrong_size", label: "Wrong size" },
  { code: "wrong_item", label: "Received wrong item" },
  { code: "damaged", label: "Arrived damaged" },
  { code: "not_as_described", label: "Not as described" },
  { code: "changed_mind", label: "Changed my mind" },
  { code: "other", label: "Other" },
] as const
```

### Refund Decision

| Disposition | Refund | Restock? |
|------------|--------|---------|
| Perfect condition | Full refund | ✅ |
| Used/worn | Partial or reject | ❌ |
| Damaged by carrier | Full refund + insurance claim | ❌ |
| Wrong item sent | Full refund + new shipment | ✅ (correct item) |
| Low value (<£10) | Returnless refund (no shipping) | ❌ |

## References
- `references/database-schema.md` — Fulfillment, Return models
- `references/returns-and-rma.md` — full RMA state machine, disposition
- `references/edge-cases.md` — address validation failures

## NEVER
- ❌ Hardcode shipping rates in components (use config)
- ❌ Charge for shipping without showing rate before payment
- ❌ Process refund before receiving returned item (unless returnless)
- ❌ Skip reason codes on returns (needed for product improvement)
- ❌ Delete return records (audit trail)
