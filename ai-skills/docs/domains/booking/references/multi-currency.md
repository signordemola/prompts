# Multi-Currency & Internationalisation

## Currency Strategy Per Market

| Market | Currency | Stripe currency code | Smallest unit |
|--------|----------|---------------------|---------------|
| UK | GBP (£) | `gbp` | pence |
| US | USD ($) | `usd` | cents |
| Canada | CAD (C$) | `cad` | cents |

## Decision: Pricing Approach

| Approach | Pros | Cons | Best for |
|----------|------|------|---------|
| **Fixed prices per currency** | Clean prices (£50, $60, C$80) | Manual price setting | Demos, solo brands |
| **Dynamic conversion** | One price auto-converts | Weird amounts ($48.73) | Marketplaces |
| **Stripe Adaptive Pricing** | Automatic, Stripe handles it | Less control | Quick international |

> **Default:** Fixed prices per currency. Store all three in config:

```ts
// lib/studio-data.ts
export const CURRENCIES = {
  UK: { code: "gbp", symbol: "£", locale: "en-GB" },
  US: { code: "usd", symbol: "$", locale: "en-US" },
  CA: { code: "cad", symbol: "C$", locale: "en-CA" },
} as const

export type Market = keyof typeof CURRENCIES

export const SERVICES = {
  "classic-lash": {
    name: "Classic Lash Set",
    durationMinutes: 90,
    prices: { UK: 8500, US: 10000, CA: 13500 }, // smallest unit per currency
    depositPercent: 0.20,
  },
}
```

## Currency Formatting

```ts
export function formatCurrency(amount: number, market: Market): string {
  const { code, locale } = CURRENCIES[market]
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: code,
  }).format(amount / 100)
}
// formatCurrency(8500, "UK") → "£85.00"
// formatCurrency(10000, "US") → "$100.00"
// formatCurrency(13500, "CA") → "CA$135.00"
```

## Stripe Integration

```ts
const market = detectMarket(request) // from env or subdomain
const currency = CURRENCIES[market]
const price = service.prices[market]
const deposit = Math.round(price * service.depositPercent)

const paymentIntent = await stripe.paymentIntents.create({
  amount: deposit,
  currency: currency.code, // "gbp" | "usd" | "cad"
  metadata: { market, serviceSlug, holdToken },
})
```

## Market Detection

| Strategy | How | Best for |
|----------|-----|---------|
| **Env variable** | `MARKET=UK` in `.env` | Single-market demos |
| **Subdomain** | `uk.studio.com` / `us.studio.com` | Multi-region |
| **URL prefix** | `/uk/book` / `/us/book` | Simple multi-region |
| **Auto-detect** | `Intl.DateTimeFormat().resolvedOptions()` | Client convenience |

> **Default for demos:** Env variable. Each deployment is one market.

## DB Schema

```prisma
model Service {
  // ... existing fields
  priceGBP  Int  // pence
  priceUSD  Int  // cents
  priceCAD  Int  // cents
}
```

> **Alternative:** JSON field `prices Json` with `{ UK: 8500, US: 10000, CA: 13500 }`. Simpler for demos but less type-safe.

## NEVER
- ❌ Multiply by 100 at payment time (prices already in smallest unit)
- ❌ Hardcode currency symbol ("£") — use `Intl.NumberFormat`
- ❌ Mix currencies in the same transaction
- ❌ Assume all markets use pence (USD/CAD use cents)
