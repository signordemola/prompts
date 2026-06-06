---
name: subdomain-architecture
description: >
  Connect booking/payment systems as subdomains to existing client websites 
  (Squarespace, Wix, WordPress). ACTIVATE when: setting up booking.clientdomain.com,
  configuring DNS for Vercel subdomains, building multi-tenant subdomain routing,
  or white-labeling a booking system for multiple clients.
---

# Subdomain Architecture Skill

## When to Use
- Connecting a Next.js booking system to client's existing website
- Setting up booking.clientdomain.com on Vercel
- Building multi-tenant architecture (one codebase, many clients)
- White-labeling the booking UI to match client's brand

<HARD-GATE>
**⛔ MANDATORY — NEVER REPLACE THE CLIENT'S EXISTING WEBSITE.**
The booking system connects as a subdomain. The client's main site stays on Squarespace/Wix/WordPress. Do not build a full website unless explicitly requested.
</HARD-GATE>

## DNS Setup: Subdomain → Vercel

### Step 1: Add domain in Vercel
```
Vercel Dashboard → Project → Settings → Domains
Add: booking.clientdomain.com
Vercel provides: CNAME → cname.vercel-dns.com
```

### Step 2: Add DNS record on client's platform

**Squarespace:**
```
Settings → Domains → [Domain] → DNS Settings → Add Record
Type: CNAME
Host: booking
Value: cname.vercel-dns.com
```

**Wix:**
```
Dashboard → Domains → [Domain] → Manage DNS Records
Type: CNAME
Host: booking
Value: cname.vercel-dns.com
```

**Cloudflare (if client uses it):**
```
DNS → Add Record
Type: CNAME
Name: booking
Target: cname.vercel-dns.com
Proxy: OFF (DNS only) — required for Vercel SSL
```

> **Important:** Do NOT use domain forwarding on the subdomain. It will conflict with the CNAME record. SSL is automatically provisioned by Vercel.

### Step 3: Verify
```bash
# Check DNS propagation (may take up to 48 hours, usually minutes)
dig booking.clientdomain.com CNAME
nslookup booking.clientdomain.com
```

## Multi-Tenant Middleware

One codebase serving multiple client booking pages:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Map subdomains to tenant configs
const TENANT_MAP: Record<string, string> = {
  'booking.hemstudios.com': 'hem-studios',
  'booking.clientb.com': 'client-b',
  'booking.clientc.com': 'client-c',
};

export function middleware(request: NextRequest) {
  const hostname = request.headers.get('host') || '';
  const tenantSlug = TENANT_MAP[hostname];
  
  if (!tenantSlug) {
    // Unknown subdomain — show 404 or default
    return NextResponse.next();
  }
  
  // Set tenant header for downstream use
  const response = NextResponse.next();
  response.headers.set('x-tenant-slug', tenantSlug);
  
  // Or rewrite to tenant-specific route
  const url = request.nextUrl.clone();
  url.pathname = `/${tenantSlug}${url.pathname}`;
  return NextResponse.rewrite(url);
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Tenant Configuration

```prisma
model Tenant {
  id            String   @id @default(cuid())
  slug          String   @unique  // "hem-studios"
  name          String   // "H.E.M Studios"
  
  // Domain
  subdomain     String   @unique  // "booking.hemstudios.com"
  
  // Branding
  primaryColor  String   @default("#000000")
  logoUrl       String?
  faviconUrl    String?
  
  // Business info (for invoices, emails)
  businessName  String
  businessEmail String
  timezone      String   @default("America/Toronto")
  currency      String   @default("cad")
  
  // Stripe (each client has their own Stripe account via Connect)
  stripeAccountId String?
  
  // Relations
  services      Service[]
  appointments  Appointment[]
  
  createdAt     DateTime @default(now())
}
```

## White-Labeling Pattern

```tsx
// app/layout.tsx — load tenant branding dynamically
import { getTenantByHostname } from '@/lib/tenant';
import { headers } from 'next/headers';

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const headersList = await headers();
  const hostname = headersList.get('host') || '';
  const tenant = await getTenantByHostname(hostname);
  
  return (
    <html lang="en">
      <head>
        <link rel="icon" href={tenant?.faviconUrl || '/favicon.ico'} />
        <style>{`
          :root {
            --primary: ${tenant?.primaryColor || '#000'};
          }
        `}</style>
      </head>
      <body>
        {tenant?.logoUrl && (
          <header>
            <img src={tenant.logoUrl} alt={tenant.name} />
          </header>
        )}
        {children}
      </body>
    </html>
  );
}
```

## Navigation Between Main Site and Booking

```html
<!-- On client's Squarespace site — link to booking subdomain -->
<a href="https://booking.hemstudios.com" class="book-now-btn">
  Book Now
</a>

<!-- On booking subdomain — link back to main site -->
<a href="https://hemstudios.com">
  ← Back to main site
</a>
```

> **Important:** These are cross-domain links. Cookies are NOT shared between domains. Auth on the booking subdomain is independent of the main site.

## Stripe Connect (Multi-Client Payments)

If you manage booking systems for multiple clients, use Stripe Connect:

```typescript
// Each client has their own Stripe account
// You are the platform, clients are connected accounts

// Creating a checkout session for a specific client
const session = await stripe.checkout.sessions.create({
  line_items: [{ price: priceId, quantity: 1 }],
  mode: 'payment',
  success_url: `https://booking.${clientDomain}/success`,
  cancel_url: `https://booking.${clientDomain}/cancel`,
}, {
  stripeAccount: tenant.stripeAccountId,  // Route payment to client's account
});
```

## Vercel Project Configuration

```json
// vercel.json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/$1"
    }
  ]
}
```

Add all client subdomains in Vercel:
```
Settings → Domains
  booking.hemstudios.com ✅
  booking.clientb.com ✅
  booking.clientc.com ✅
```

## NEVER
- ❌ Replace the client's existing website (subdomain only)
- ❌ Use domain forwarding on the booking subdomain (breaks CNAME)
- ❌ Assume cookies are shared between main site and subdomain
- ❌ Hardcode tenant config (store in database, load dynamically)
- ❌ Use Stripe Connect without separate connected accounts per client
- ❌ Skip SSL verification (Vercel handles this automatically)
