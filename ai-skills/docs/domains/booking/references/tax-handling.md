# Tax Handling

## Tax Rules by Market

| Market | Tax | Rate | Applies to | Threshold |
|--------|-----|------|-----------|-----------|
| **UK** | VAT | 20% | All beauty services | £90,000/year turnover |
| **US** | Sales tax | Varies by state | Usually products only, NOT services | Varies |
| **Canada** | GST/HST | 5–15% by province | All beauty services | $30,000 CAD/year |

## Decision: When to Build Tax

| Scenario | Build? | Why |
|----------|--------|-----|
| Demo project | ❌ | Show prices as "inc. VAT" or "plus tax" |
| Live client under threshold | ❌ | Not registered, no obligation |
| Live client over threshold | ✅ | Legal requirement |
| Multi-region production | ✅ | Use Stripe Tax |

## Implementation Levels

### Level 0: Tax-Inclusive Display (Demos)

```ts
// Prices already include tax. Just display:
// UK: "£85.00 (inc. VAT)"
// US: "$100.00" (no tax on services in most states)
// CA: "C$135.00 + GST"
```

### Level 1: Manual Tax Calculation

```ts
const TAX_RATES = {
  UK: 0.20,    // 20% VAT (included in price)
  US: 0,       // No sales tax on services in most states
  CA_ON: 0.13, // Ontario HST
  CA_BC: 0.12, // BC GST+PST
  CA_AB: 0.05, // Alberta GST only
}

// UK: prices are VAT-inclusive by convention
// To extract VAT from inclusive price:
const vatAmount = Math.round(price - (price / 1.20))

// Canada: prices are tax-exclusive by convention
// To add tax:
const taxAmount = Math.round(price * TAX_RATES.CA_ON)
const totalWithTax = price + taxAmount
```

### Level 2: Stripe Tax (Production)

```ts
const paymentIntent = await stripe.paymentIntents.create({
  amount: deposit,
  currency: "gbp",
  automatic_tax: { enabled: true }, // Stripe calculates
})
```

> Requires Stripe Tax setup in Dashboard → Settings → Tax.

## Display Patterns

| Market | Convention | Show as |
|--------|-----------|---------|
| UK | Prices include VAT | "£85.00 (inc. VAT)" |
| US | No tax on services | "$100.00" |
| Canada | Prices exclude tax | "C$135.00 + tax" |

## Receipt/Invoice Requirements

| Market | Must show |
|--------|----------|
| UK | VAT number, VAT amount, gross/net |
| US | Sales tax amount (if applicable) |
| Canada | GST/HST number, tax amount |

## NEVER
- ❌ Calculate tax client-side
- ❌ Assume tax rules are the same across markets
- ❌ Show "inc. VAT" when price doesn't include it
- ❌ Charge VAT if under the registration threshold
