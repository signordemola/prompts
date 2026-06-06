# Ecommerce SEO & Structured Data

## Product JSON-LD

```tsx
// app/products/[slug]/page.tsx
const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Product",
  name: product.name,
  description: product.description,
  image: product.images.map(i => i.url),
  sku: product.variants[0].sku,
  brand: { "@type": "Brand", name: "Store Name" },
  offers: product.variants.map(v => ({
    "@type": "Offer",
    price: (v.priceGBP / 100).toFixed(2),
    priceCurrency: "GBP",
    availability: v.inventoryQuantity > 0
      ? "https://schema.org/InStock"
      : "https://schema.org/OutOfStock",
    url: `https://store.com/products/${product.slug}`,
  })),
  ...(product.reviews.length > 0 && {
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: avgRating,
      reviewCount: product.reviews.length,
    }
  }),
}

export default function ProductPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(jsonLd).replace(/</g, '\\u003c')
        }}
      />
      {/* page content */}
    </>
  )
}
```

## BreadcrumbList

```tsx
const breadcrumbLd = {
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Home", item: "https://store.com" },
    { "@type": "ListItem", position: 2, name: "Tops", item: "https://store.com/collections/tops" },
    { "@type": "ListItem", position: 3, name: product.name },
  ]
}
```

## Canonical URLs for Variants

```tsx
// Single canonical for all variants:
export const metadata = {
  alternates: {
    canonical: `/products/${product.slug}`,
    // NOT: /products/tshirt?color=black (duplicate)
  }
}
```

**Rule:** Variants are UI state (query params or client-side), not separate pages. One canonical per product.

## Next.js Metadata API

```tsx
export async function generateMetadata({ params }) {
  const product = await getProduct(params.slug)
  return {
    title: `${product.name} | Store Name`,
    description: product.metaDescription || product.description.slice(0, 160),
    openGraph: {
      title: product.name,
      description: product.description.slice(0, 160),
      images: [product.images[0]?.url],
      type: "product",
    },
  }
}
```

## Sitemap Generation

```ts
// app/sitemap.ts
export default async function sitemap() {
  const products = await prisma.product.findMany({
    where: { status: "ACTIVE", deletedAt: null },
    select: { slug: true, updatedAt: true },
  })
  
  return [
    { url: "https://store.com", lastModified: new Date(), priority: 1 },
    { url: "https://store.com/products", lastModified: new Date(), priority: 0.8 },
    ...products.map(p => ({
      url: `https://store.com/products/${p.slug}`,
      lastModified: p.updatedAt,
      priority: 0.7,
    })),
  ]
}
```

## Filtered Pages SEO

```tsx
// Add noindex for deep filter combos:
export const metadata = {
  robots: hasMultipleFilters ? "noindex, follow" : "index, follow",
}
```

## Checklist
- [ ] Product JSON-LD on every PDP
- [ ] BreadcrumbList on every page
- [ ] Unique title + meta description per product
- [ ] Self-referencing canonical on all pages
- [ ] `noindex` on filtered/sorted pages
- [ ] Sitemap includes all active products
- [ ] OpenGraph images for social sharing
- [ ] Alt text on all product images
