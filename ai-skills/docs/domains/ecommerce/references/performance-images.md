# Performance & Images

## Next/Image Optimization

```tsx
import Image from "next/image"

// Product listing (thumbnail)
<Image
  src={product.primaryImage.url}
  alt={product.primaryImage.altText}
  width={400}
  height={400}
  sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
  loading="lazy"
  placeholder="blur"
  blurDataURL={product.primaryImage.blurUrl}
/>

// Product detail (hero)
<Image
  src={selectedImage.url}
  alt={selectedImage.altText}
  width={800}
  height={800}
  sizes="(max-width: 768px) 100vw, 50vw"
  priority  // LCP — load immediately
/>
```

## Image Pipeline

| Stage | Tool | Output |
|-------|------|--------|
| Upload | Cloudinary / Vercel Blob | Original stored |
| Transform | CDN auto-format | WebP/AVIF at request |
| Resize | `next/image` loader | Multiple sizes |
| Placeholder | `plaiceholder` | Base64 blur |
| Serve | CDN edge | Cached globally |

## Product Gallery

```tsx
function ProductGallery({ images }) {
  const [selected, setSelected] = useState(0)
  
  return (
    <div>
      {/* Main image */}
      <Image
        src={images[selected].url}
        alt={images[selected].altText}
        width={800}
        height={800}
        priority={selected === 0}
      />
      
      {/* Thumbnails */}
      <div role="list" aria-label="Product images">
        {images.map((img, i) => (
          <button
            key={img.id}
            onClick={() => setSelected(i)}
            aria-pressed={selected === i}
            aria-label={`View ${img.altText}`}
          >
            <Image src={img.url} alt="" width={80} height={80} />
          </button>
        ))}
      </div>
    </div>
  )
}
```

## Performance Checklist

| Metric | Target | How |
|--------|--------|-----|
| LCP | < 2.5s | Hero image with `priority`, preconnect to CDN |
| CLS | < 0.1 | Explicit `width`/`height` on all images |
| INP | < 200ms | Avoid heavy JS on interaction |
| FCP | < 1.8s | SSR/SSG product pages |

## CDN Configuration

```ts
// next.config.js
module.exports = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "res.cloudinary.com" },
      { protocol: "https", hostname: "cdn.shopify.com" },
    ],
    formats: ["image/avif", "image/webp"],
  },
}
```

## Lazy Loading Strategy

| Content | Loading |
|---------|---------|
| Hero/primary image | `priority` (eager) |
| Gallery thumbnails | `loading="lazy"` |
| Product listing images | `loading="lazy"` |
| Below-fold content | `loading="lazy"` |
