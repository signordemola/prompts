---
name: data-fetching
description: >
  Data fetching patterns for Next.js App Router with TanStack Query and Server
  Actions. ACTIVATE when: fetching data, creating mutations, adding loading
  states, invalidating client server-state, or avoiding Next.js caching.
---

# Data Fetching Skill

## When to Use
- Fetching data in pages or components
- Creating Server Actions for mutations
- Using TanStack Query for reads, mutations, invalidation, or optimistic UI
- Adding Suspense/loading states
- Preventing Next.js Data Cache usage

## Always Load First
- `skills/code-style/SKILL.md`
- `skills/nextjs-app-router/SKILL.md`

<HARD-GATE>
**⛔ MANDATORY — TANSTACK QUERY OWNS SERVER-STATE CACHE.**
Do not use Next.js cache APIs for app data. Reads use TanStack Query. Writes use
Server Actions called from TanStack Query mutations. Freshness comes from query
invalidation, refetching, optimistic updates, and direct cache updates.
</HARD-GATE>

## Project Policy

- Do not enable `cacheComponents`
- Do not use `"use cache"`
- Do not use `cacheLife`
- Do not use `unstable_cache`
- Do not use `next.revalidate`
- Do not use `revalidatePath`
- Do not use `revalidateTag`
- Do not use `updateTag`
- Do not use cache tags
- Use `cache: "no-store"` for every server `fetch`
- Use `dynamic = "force-dynamic"` and `fetchCache = "force-no-store"` on uncached request-time pages and route handlers

## Provider Setup

```tsx
"use client"

import { QueryClient, QueryClientProvider } from "@tanstack/react-query"

const makeQueryClient = () => {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 0,
        refetchOnWindowFocus: true,
        refetchOnReconnect: true,
      },
    },
  })
}

let browserQueryClient: QueryClient | undefined

const getQueryClient = () => {
  if (typeof window === "undefined") {
    return makeQueryClient()
  }

  if (!browserQueryClient) {
    browserQueryClient = makeQueryClient()
  }

  return browserQueryClient
}

const Providers = ({ children }: { children: React.ReactNode }) => {
  const queryClient = getQueryClient()

  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}

export default Providers
```

## Read Pattern

Use Route Handlers or DAL-backed endpoints for reads that Client Components consume through TanStack Query.

```ts
export const getProducts = async () => {
  const response = await fetch("/api/products", {
    cache: "no-store",
  })

  if (!response.ok) {
    throw new Error("Failed to fetch products")
  }

  return response.json()
}
```

```tsx
"use client"

import { useQuery } from "@tanstack/react-query"
import { getProducts } from "@/lib/api/products"

export const ProductsList = () => {
  const query = useQuery({
    queryKey: ["products"],
    queryFn: getProducts,
  })

  if (query.isLoading) {
    return <ProductsSkeleton />
  }

  if (query.error) {
    return <ProductsError />
  }

  return (
    <div>
      {query.data.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}
```

## Mutation Pattern

Server Actions perform writes and validation:

```ts
"use server"

import { z } from "zod"
import { prisma } from "@/lib/prisma"

const CreateProductSchema = z.object({
  name: z.string().trim().min(1),
  price: z.number().int().positive(),
})

export const createProduct = async (input: unknown) => {
  const data = CreateProductSchema.parse(input)

  const product = await prisma.product.create({
    data,
  })

  return { product }
}
```

Client Components call Server Actions through `useMutation`:

```tsx
"use client"

import { useMutation, useQueryClient } from "@tanstack/react-query"
import { createProduct } from "@/app/actions/products"

export const CreateProductForm = () => {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: createProduct,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["products"] })
    },
  })

  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget)

    mutation.mutate({
      name: String(formData.get("name") ?? ""),
      price: Number(formData.get("price") ?? 0),
    })
  }

  return (
    <form onSubmit={onSubmit}>
      <input name="name" />
      <input name="price" type="number" />
      <button disabled={mutation.isPending}>Save</button>
    </form>
  )
}
```

## Suspense Pattern

Use `loading.tsx` for route-level loading UI:

```tsx
const Loading = () => {
  return <ProductsSkeleton />
}

export default Loading
```

Use component Suspense for slow nested areas:

```tsx
import { Suspense } from "react"

const Page = () => {
  return (
    <main>
      <ProductFilters />
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductsList />
      </Suspense>
    </main>
  )
}

export default Page
```

For TanStack Query Suspense mode, use `useSuspenseQuery` only inside a Suspense boundary and pair it with an error boundary.

## Server Prefetch and Hydration

Use server prefetch only when SSR is needed. Query functions used during prefetch must not use Next caching.

```tsx
import { HydrationBoundary, QueryClient, dehydrate } from "@tanstack/react-query"
import { ProductsList } from "@/components/products-list"
import { getProductsForHydration } from "@/lib/dal/products"

const Page = async () => {
  const queryClient = new QueryClient()

  await queryClient.prefetchQuery({
    queryKey: ["products"],
    queryFn: getProductsForHydration,
  })

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ProductsList />
    </HydrationBoundary>
  )
}

export default Page
```

## Folder Structure

```text
app/
  actions/
    products.ts
  api/
    products/
      route.ts
  providers.tsx
components/
  products-list.tsx
  products-skeleton.tsx
hooks/
  use-products.ts
lib/
  api/
    products.ts
  dal/
    products.ts
```

## NEVER
- ❌ Use Next cache APIs for app data
- ❌ Call `revalidatePath` or `revalidateTag` after Server Actions
- ❌ Use Server Actions as general read/query functions
- ❌ Fetch from Client Components without TanStack Query
- ❌ Import Prisma in files with `"use client"`
- ❌ Omit loading UI for slow queries
- ❌ Put mutation logic directly in components
- ❌ Trust client input in Server Actions
