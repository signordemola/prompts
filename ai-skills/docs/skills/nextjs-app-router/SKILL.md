---
name: nextjs-app-router
description: >
  Next.js App Router patterns and conventions. ACTIVATE when: creating new pages,
  routes, layouts, API routes, or deciding between Server and Client Components.
  Covers file conventions, data fetching, Server Actions, and route organisation.
---

# Next.js App Router Skill

## When to Use
- Creating or modifying any page, layout, or API route
- Deciding between Server and Client Components
- Setting up route groups, error boundaries, or loading states
- Implementing data fetching or Server Actions

## Instructions

## Always Load First
- `skills/code-style/SKILL.md`

### Step 1: Default to Server Components
ALWAYS use Server Components unless you specifically need:
- Event listeners (onClick, onChange)
- useState, useEffect, useReducer
- Browser-only APIs (localStorage, window)
- Custom hooks that use the above

```tsx
const Page = async () => {
  const data = await prisma.service.findMany()
  return <ServiceList services={data} />
}

export default Page
```

```tsx
"use client"

export const BookingWizard = () => {
  const [step, setStep] = useState(1)
  return <div onClick={() => setStep(2)}>...</div>
}
```

### Step 2: Use correct file conventions
| File | Purpose |
|------|---------|
| `page.tsx` | Unique UI for a route |
| `layout.tsx` | Shared UI for a segment and children |
| `loading.tsx` | Loading UI (Suspense boundary) |
| `error.tsx` | Error boundary (`"use client"` required) |
| `not-found.tsx` | 404 UI |
| `route.ts` | API endpoint (GET, POST, etc.) |

### Step 3: Organise with route groups
Use `(groupName)` folders to separate concerns without affecting URLs:
```
app/
├── (booking)/        # Public booking flow
├── (manage)/         # Client self-service
├── (owner)/          # Owner dashboard
└── api/              # API routes
```

### Step 4: Data fetching patterns
- Use TanStack Query for client server-state reads
- Use Server Actions (`"use server"`) for mutations
- Call Server Actions from `useMutation`
- Invalidate TanStack Query keys after successful mutations
- Use `cache: "no-store"` for every server `fetch`
- Add `export const dynamic = "force-dynamic"` and `export const fetchCache = "force-no-store"` on uncached request-time pages and route handlers
- Use `loading.tsx` for route-level Suspense fallbacks
- Use `<Suspense>` around slow nested sections for granular streaming
- Use direct DAL/database reads for Server Component prefetch; do not call relative `/api/...` URLs from Server Components

**No Next cache policy:** Do not enable `cacheComponents`. Do not use `"use cache"`, `cacheLife`, `unstable_cache`, `revalidatePath`, `revalidateTag`, `updateTag`, cache tags, or `next.revalidate` for app data. TanStack Query owns client cache freshness.

### Step 5: Suspense and loading UI

Use `loading.tsx` for route transitions:

```tsx
const Loading = () => {
  return <DashboardSkeleton />
}

export default Loading
```

Use component-level Suspense when one slow section should not block the page:

```tsx
import { Suspense } from "react"

const Page = () => {
  return (
    <main>
      <Summary />
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>
    </main>
  )
}

export default Page
```

### Step 6: Keep routing layer thin
- `app/` is for routing ONLY — no business logic
- Components go in `components/`
- Utilities go in `lib/`
- Hooks go in `hooks/`

## NEVER
- ❌ Put `"use client"` on a page that only renders data
- ❌ Import server-only code (Prisma, env vars) in Client Components
- ❌ Prefix sensitive env vars with `NEXT_PUBLIC_`
- ❌ Use `getServerSideProps` or `getStaticProps` (Pages Router patterns)
- ❌ Use Next cache APIs for app data when TanStack Query is the project cache
- ❌ Enable `cacheComponents` in no-Next-cache projects
- ❌ Omit Suspense/loading states around slow routes or slow nested sections
