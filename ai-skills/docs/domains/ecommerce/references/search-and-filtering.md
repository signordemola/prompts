# Search & Filtering

## Decision: Search Engine

| | PostgreSQL FTS | Meilisearch | Algolia |
|---|---|---|---|
| **Best for** | < 100k products, demos | Modern instant search | Enterprise, AI merch |
| **Typo tolerance** | Manual (`pg_trgm`) | Built-in | Built-in |
| **Faceted search** | SQL aggregations | Zero-config | Advanced |
| **Cost** | Free (DB only) | Free/low | $$$$ |
| **Infra** | None | 1 service | SaaS |

> **Default:** PostgreSQL FTS. Upgrade to Meilisearch when facet complexity or typo tolerance becomes painful.

## PostgreSQL Full-Text Search

```ts
// Product search with ranking
const products = await prisma.$queryRaw`
  SELECT *,
    ts_rank(
      to_tsvector('english', name || ' ' || COALESCE(description, '')),
      plainto_tsquery('english', ${query})
    ) AS rank
  FROM "Product"
  WHERE to_tsvector('english', name || ' ' || COALESCE(description, ''))
    @@ plainto_tsquery('english', ${query})
  AND status = 'ACTIVE'
  AND "deletedAt" IS NULL
  ORDER BY rank DESC
  LIMIT ${limit}
  OFFSET ${offset}
`
```

### Add GIN Index

```sql
CREATE INDEX idx_product_search ON "Product"
  USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '')));
```

### Fuzzy Search (Typo Tolerance)

```sql
-- Enable pg_trgm extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_product_name_trgm ON "Product" USING GIN (name gin_trgm_ops);

-- Query:
SELECT * FROM "Product"
WHERE name % 'tshirt'  -- similarity match
ORDER BY similarity(name, 'tshirt') DESC;
```

## Faceted Filtering

```ts
// GET /api/products?category=tops&minPrice=2000&maxPrice=5000&color=black&sort=price_asc

async function getProducts(filters: ProductFilters) {
  const where: Prisma.ProductWhereInput = {
    status: "ACTIVE",
    deletedAt: null,
  }
  
  if (filters.category) where.category = filters.category
  if (filters.tags?.length) where.tags = { hasSome: filters.tags }
  
  // Price filtering requires joining variants
  const products = await prisma.product.findMany({
    where,
    include: {
      variants: {
        where: {
          isActive: true,
          ...(filters.minPrice && { priceGBP: { gte: filters.minPrice } }),
          ...(filters.maxPrice && { priceGBP: { lte: filters.maxPrice } }),
          ...(filters.color && { option1: filters.color }),
        }
      },
      images: { where: { isPrimary: true }, take: 1 },
    },
    orderBy: getSortOrder(filters.sort),
    take: filters.limit ?? 24,
    skip: filters.offset ?? 0,
  })
  
  return products.filter(p => p.variants.length > 0) // Only show products with matching variants
}

function getSortOrder(sort?: string) {
  switch (sort) {
    case "price_asc": return { variants: { _min: { priceGBP: "asc" } } }
    case "price_desc": return { variants: { _min: { priceGBP: "desc" } } }
    case "newest": return { createdAt: "desc" }
    default: return { sortOrder: "asc" } // manual/popularity
  }
}
```

## Facet Counts

```ts
// Show: "Black (12) | White (8) | Navy (5)"
const colorFacets = await prisma.productVariant.groupBy({
  by: ["option1"],
  where: { product: { status: "ACTIVE", category: filters.category } },
  _count: true,
})
```

## Pagination

| Pattern | Pros | Cons | Best for |
|---------|------|------|---------|
| **Offset/limit** | Simple, SEO-friendly | Slow at high offsets | Product listings |
| **Cursor-based** | Fast, consistent | No "jump to page X" | Infinite scroll |
| **Keyset** | Very fast | Complex | Large datasets |

> **Default:** Offset/limit with numbered pages. 24 items per page.

## URL Structure

```
/products?category=tops&color=black&sort=price_asc&page=2
```
- Filter params in URL (shareable, SEO)
- Canonical URL points to unfiltered page
- `noindex` on deep filter combinations (prevent index bloat)
