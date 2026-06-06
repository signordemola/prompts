---
name: product-catalog
description: >
  Product catalog management. ACTIVATE when: creating products, managing variants/SKUs,
  handling categories/tags, product images, pricing per variant, or product status
  transitions (draft/active/archived).
---

# Product Catalog Skill

## When to Use
- Creating or modifying product models
- Implementing variant/option logic
- Managing categories and tags
- Building product listing or detail pages

## Product → Variant → SKU Hierarchy

```
Product: "Classic T-Shirt"
  ├── Variant: "Small / Black"  (SKU: TSH-SM-BLK, £25, stock: 12)
  ├── Variant: "Small / White"  (SKU: TSH-SM-WHT, £25, stock: 8)
  ├── Variant: "Medium / Black" (SKU: TSH-MD-BLK, £25, stock: 15)
  └── Variant: "Large / Black"  (SKU: TSH-LG-BLK, £28, stock: 3)
```

**Rule:** Every product has ≥1 variant (even if "Default"). Price, stock, and SKU live on the variant, never on the product.

## Options System

```ts
// Max 3 option axes (Shopify convention)
const OPTIONS = {
  option1: "Size",    // "Small", "Medium", "Large"
  option2: "Color",   // "Black", "White", "Navy"
  option3: null,      // unused
}

// Variants = cartesian product of options
// Small×Black, Small×White, Medium×Black, Medium×White...
```

### Decision: Option Storage

| Approach | Pros | Cons | Best for |
|----------|------|------|---------|
| **Flat columns** (option1, option2, option3) | Simple queries, type-safe | Max 3 axes | Most stores |
| **JSONB** | Unlimited axes | Harder to query/filter | Massive catalogs |
| **EAV** (entity-attribute-value) | Fully dynamic | Complex joins, slow | Enterprise only |

> **Default:** Flat columns. 3 axes covers 99% of cases.

## Pricing

```ts
// All prices in smallest currency unit
const variant = {
  priceGBP: 2500,           // £25.00
  priceUSD: 3000,           // $30.00
  priceCAD: 4000,           // C$40.00
  compareAtPriceGBP: 3500,  // "Was £35.00" — null if not on sale
}

// Display:
function formatPrice(price: number, market: Market): string {
  return new Intl.NumberFormat(CURRENCIES[market].locale, {
    style: "currency",
    currency: CURRENCIES[market].code,
  }).format(price / 100)
}

// Sale badge:
const isOnSale = variant.compareAtPriceGBP && variant.compareAtPriceGBP > variant.priceGBP
```

## Product Status

```
DRAFT → ACTIVE → ARCHIVED
```

| Status | Visible in store? | Editable? | Can be ordered? |
|--------|-------------------|-----------|-----------------|
| DRAFT | ❌ | ✅ | ❌ |
| ACTIVE | ✅ | ✅ | ✅ |
| ARCHIVED | ❌ | ✅ | ❌ (but existing orders preserved) |

## Categories & Tags

```ts
// Categories: hierarchical (tree)
// "Women > Tops > T-Shirts"
// Store as flat string or parent-child model

// Tags: flat, cross-cutting
// ["new-arrival", "sale", "bestseller", "organic"]
// Store as String[] on Product
```

### Decision: Category Storage

| Approach | Best for |
|----------|---------|
| **String field** ("Women > Tops") | Small catalog, demos |
| **Category model** with `parentId` | Browsable hierarchy, breadcrumbs |
| **Materialized path** ("women.tops.tshirts") | Fast ancestor queries |

> **Default for demos:** String field. Add Category model when navigation requires it.

## Product Images

```ts
// Multiple images per product. Primary flagged. Alt text required.
const image = {
  url: "https://cdn.example.com/products/tshirt-black-front.webp",
  altText: "Classic T-Shirt in Black, front view",
  isPrimary: true,
  sortOrder: 0,
}
```

**Rules:**
- Primary image = thumbnail in listings
- Alt text = SEO + accessibility (never empty)
- Serve via CDN (Cloudinary, Vercel Image Optimization)
- WebP format, responsive `srcset`

## Slug Generation

```ts
import slugify from "slugify"

function generateSlug(name: string): string {
  return slugify(name, { lower: true, strict: true })
}
// "Classic T-Shirt" → "classic-t-shirt"
// Ensure unique via DB constraint
```

## References
- `references/database-schema.md` — full Product/Variant/Image models
- `references/performance-images.md` — image optimization patterns
- `references/seo-structured-data.md` — Product JSON-LD
- `references/search-and-filtering.md` — product listing page

## NEVER
- ❌ Store price on the Product model (always on Variant)
- ❌ Allow a product with zero variants
- ❌ Skip alt text on images
- ❌ Use sequential IDs in public URLs (use slugs)
- ❌ Hard-delete products with existing orders
