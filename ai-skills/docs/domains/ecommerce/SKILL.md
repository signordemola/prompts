---
name: ecommerce-platform
description: >
  Ecommerce platform orchestrator. ACTIVATE when: building any ecommerce feature.
  This skill routes you to the right sub-skill based on what you're implementing.
  Load general skills first, then the relevant ecommerce sub-skill.
---

# Ecommerce Platform Domain Skill

## When to Use
- Building a new ecommerce store (any product niche)
- Any ecommerce-specific feature

## Pre-Requisites — Always Load First
- `docs/skills/prisma-database/SKILL.md` (or `docs/skills/drizzle-database/SKILL.md` if using Drizzle)
- `docs/skills/stripe-payments/SKILL.md`
- Load the framework skill matching your project's stack:
  - Next.js → `docs/skills/nextjs-app-router/SKILL.md`
  - NestJS → `docs/skills/nestjs/SKILL.md`
  - FastAPI → `docs/skills/fastapi/SKILL.md`

## Sub-Skill Routing

| When you're working on... | Load sub-skill |
|--------------------------|---------------|
| Products, variants, SKUs, categories, images, pricing | `skills/product-catalog/SKILL.md` |
| Cart, checkout flow, guest merge, abandonment | `skills/cart-and-checkout/SKILL.md` |
| Stock tracking, reservations, overselling, backorders | `skills/inventory-management/SKILL.md` |
| Order creation, fulfillment, status transitions, cancellation | `skills/order-lifecycle/SKILL.md` |
| Stripe checkout, discounts, coupons, multi-currency, tax | `skills/payment-and-pricing/SKILL.md` |
| Shipping rates, carriers, zones, returns, RMA | `skills/shipping-and-delivery/SKILL.md` |

## Reference Files

| Reference | Read when... |
|-----------|-------------|
| `references/database-schema.md` | Designing or modifying the DB schema |
| `references/discount-system.md` | BXGY logic, automatic discounts, stacking rules |
| `references/search-and-filtering.md` | Product listing, faceted search, sorting |
| `references/email-sequences.md` | Order confirmation, shipping, review, abandonment emails |
| `references/seo-structured-data.md` | Product JSON-LD, canonical URLs, sitemap |
| `references/returns-and-rma.md` | Return state machine, disposition, refund timing |
| `references/edge-cases.md` | Double-purchase, price change mid-checkout, OOS |
| `references/reviews-and-ratings.md` | Review schema, moderation, aggregate ratings |
| `references/performance-images.md` | Image optimization, CDN, gallery, lazy loading |
| `references/analytics-funnel.md` | Conversion funnel events, AOV, metrics |
| `references/wishlist-saved.md` | Wishlist schema and toggle pattern |
| `references/testing-patterns.md` | Mocking Stripe, race conditions, price snapshots |

## Shared With Booking Domain

| Topic | Cross-reference |
|-------|---------------|
| Multi-currency (GBP/USD/CAD) | `../booking/references/multi-currency.md` |
| Tax handling (VAT/GST/sales tax) | `../booking/references/tax-handling.md` |
| Data privacy / GDPR | `../booking/references/data-privacy.md` |
| Accessibility patterns | `../booking/references/accessibility-walkins.md` |
| API design conventions | `../booking/references/api-design.md` |

## End-to-End Purchase Flow

```
1. Client browses products → adds to cart (server-side)
2. Client enters checkout → email + address + shipping method
3. POST /api/checkout → Stripe Checkout Session (prices frozen)
4. Stripe hosted payment page → client pays
5. Webhook: checkout.session.completed →
   → Validate stock → Snapshot prices → Create order + line items
   → Decrement inventory → Clear cart → Send confirmation email
6. Confirmation page shows order details
7. Owner fulfills → enters tracking → customer notified
```

## Order State Machine

```
PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED → COMPLETED
                                                        → RETURNED
                   → CANCELLED (before shipping)
```

## What Changes Per Store

| File | What to update |
|------|---------------|
| Products/seed data | Product names, variants, prices per market |
| Categories | Store-specific taxonomy |
| Shipping config | Rates, thresholds, carriers per market |
| Email templates | Brand-specific content, logo |
| Landing page | Store-specific hero, featured products |
| Currency/market config | GBP/USD/CAD per deployment |

## Full Coverage (32 Sections)

| # | Topic | Location |
|---|-------|---------|
| 1 | Product → Variant → SKU hierarchy | `skills/product-catalog` |
| 2 | Options system (size/color/material) | `skills/product-catalog` |
| 3 | Multi-currency variant pricing | `skills/product-catalog` |
| 4 | Categories & tags | `skills/product-catalog` |
| 5 | Product images & alt text | `skills/product-catalog` |
| 6 | Product status (draft/active/archived) | `skills/product-catalog` |
| 7 | Server-side cart & persistence | `skills/cart-and-checkout` |
| 8 | Guest cart → account merge | `skills/cart-and-checkout` |
| 9 | Checkout flow (3-step) | `skills/cart-and-checkout` |
| 10 | Cart abandonment recovery | `skills/cart-and-checkout` |
| 11 | Price snapshot at checkout | `skills/cart-and-checkout` |
| 12 | Atomic stock decrement | `skills/inventory-management` |
| 13 | Inventory reservations & TTL | `skills/inventory-management` |
| 14 | Backorder / pre-order handling | `skills/inventory-management` |
| 15 | Low stock alerts | `skills/inventory-management` |
| 16 | Order state machine | `skills/order-lifecycle` |
| 17 | Atomic order creation | `skills/order-lifecycle` |
| 18 | Fulfillment workflow (pick/pack/ship) | `skills/order-lifecycle` |
| 19 | Partial fulfillment & split shipments | `skills/order-lifecycle` |
| 20 | Cancellation & inventory restoration | `skills/order-lifecycle` |
| 21 | Stripe Checkout Sessions | `skills/payment-and-pricing` |
| 22 | Discount/coupon system (%, fixed, BXGY) | `skills/payment-and-pricing` |
| 23 | Automatic discounts & stacking | `skills/payment-and-pricing` |
| 24 | Webhook idempotency | `skills/payment-and-pricing` |
| 25 | Shipping strategies & rates | `skills/shipping-and-delivery` |
| 26 | Free shipping threshold | `skills/shipping-and-delivery` |
| 27 | Carriers per market (UK/US/CA) | `skills/shipping-and-delivery` |
| 28 | Returns/RMA flow | `skills/shipping-and-delivery` |
| 29 | Product search & faceted filtering | `references/search-and-filtering` |
| 30 | SEO & JSON-LD structured data | `references/seo-structured-data` |
| 31 | Reviews & ratings | `references/reviews-and-ratings` |
| 32 | Analytics & conversion funnel | `references/analytics-funnel` |
