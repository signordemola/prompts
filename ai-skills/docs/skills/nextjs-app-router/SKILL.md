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

### Step 1: Default to Server Components
ALWAYS use Server Components unless you specifically need:
- Event listeners (onClick, onChange)
- useState, useEffect, useReducer
- Browser-only APIs (localStorage, window)
- Custom hooks that use the above

```tsx
// ✅ Server Component (default — no directive needed)
export default async function Page() {
  const data = await prisma.service.findMany()
  return <ServiceList services={data} />
}

// ✅ Client Component (only when needed)
"use client"
export function BookingWizard() {
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
- Fetch data in Server Components with `async/await`
- Use Server Actions (`"use server"`) for mutations
- Add `export const dynamic = "force-dynamic"` on pages reading from DB
- Use `fetch()` with `next: { revalidate }` for cached external data

### Step 5: Keep routing layer thin
- `app/` is for routing ONLY — no business logic
- Components go in `components/`
- Utilities go in `lib/`
- Hooks go in `hooks/`

## NEVER
- ❌ Put `"use client"` on a page that only renders data
- ❌ Import server-only code (Prisma, env vars) in Client Components
- ❌ Prefix sensitive env vars with `NEXT_PUBLIC_`
- ❌ Use `getServerSideProps` or `getStaticProps` (Pages Router patterns)
