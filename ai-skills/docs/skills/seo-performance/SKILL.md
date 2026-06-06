---
name: seo-performance
description: >
  SEO and Core Web Vitals patterns. ACTIVATE when: adding meta tags, JSON-LD,
  Open Graph, optimising images/fonts, or debugging LCP/INP/CLS issues.
---

# SEO & Performance Skill

## When to Use
- Adding meta tags, OG tags, or JSON-LD structured data
- Optimising images, fonts, or page load speed
- Debugging Core Web Vitals issues

## Instructions

### Step 1: Metadata in layout/page
```tsx
export const metadata = {
  title: "Classic Lash Set — Book Online | Studio Name",
  description: "Book a classic eyelash extension set (90 min, from £65).",
  openGraph: { title: "...", description: "...", images: ["/og-image.jpg"] },
}
```

### Step 2: JSON-LD for services
```tsx
<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify({
  "@context": "https://schema.org",
  "@type": "Service",
  name: "Classic Lash Set",
  provider: { "@type": "BeautySalon", name: "Studio Name" },
  offers: { "@type": "Offer", price: "65.00", priceCurrency: "GBP" }
}) }} />
```

### Step 3: Image and font optimisation
```tsx
import Image from "next/image"
<Image src="/hero.jpg" alt="..." width={800} height={600} priority />

import { Inter } from "next/font/google"
const inter = Inter({ subsets: ["latin"] })
```

### Step 4: Performance targets
| Metric | Target |
|--------|--------|
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| Slot API | < 500ms |
| Hold creation | < 300ms |
