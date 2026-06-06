---
name: data-fetching
description: >
  Data fetching patterns for Next.js App Router. ACTIVATE when: fetching data
  in Server Components, implementing Server Actions, caching strategies, or
  setting up a Data Access Layer.
---

# Data Fetching Skill

## When to Use
- Fetching data in pages or components
- Creating Server Actions for mutations
- Setting up caching or revalidation
- Deciding between static and dynamic rendering

## Instructions

### Step 1: Fetch in Server Components
```tsx
// ✅ Direct async/await in Server Components
export default async function ServicesPage() {
  const services = await prisma.service.findMany({ orderBy: { displayOrder: "asc" } })
  return <ServiceGrid services={services} />
}
```

### Step 2: Use Server Actions for mutations
```tsx
"use server"
export async function cancelAppointment(token: string) {
  const appt = await prisma.appointment.findUnique({ where: { manageToken: token } })
  if (!appt) throw new Error("Not found")
  await prisma.appointment.update({ where: { id: appt.id }, data: { status: "CANCELLED" } })
  revalidatePath("/dashboard")
}
```

### Step 3: Centralise in a Data Access Layer
```ts
// lib/dal.ts — single source of truth
export const dal = {
  services: { getAll: () => prisma.service.findMany(), getBySlug: (slug: string) => ... },
  appointments: { getForDate: (date: Date) => ..., create: (data) => ... },
}
```

### Step 4: Mark dynamic pages
```tsx
// Any page that reads from DB at request time
export const dynamic = "force-dynamic"
```

## NEVER
- ❌ Fetch data in Client Components (use Server Components or TanStack Query)
- ❌ Import Prisma in files with `"use client"`
- ❌ Forget `revalidatePath` after mutations
