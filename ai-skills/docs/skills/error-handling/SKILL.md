---
name: error-handling
description: >
  Error handling and resilience patterns. ACTIVATE when: adding error boundaries,
  handling cold starts, implementing retry logic, or setting up logging.
---

# Error Handling Skill

## When to Use
- Adding error boundaries to route groups
- Handling Neon/serverless cold starts gracefully
- Implementing retry logic for flaky operations
- Setting up structured logging

## Instructions

### Step 1: Error boundaries for every DB-reading route
```tsx
// app/(owner)/dashboard/error.tsx
"use client"
export default function DashboardError({ error, reset }: { error: Error; reset: () => void }) {
  const isColdStart = error.message?.includes("ETIMEDOUT") || error.message?.includes("P1001")
  return (
    <div>
      <h2>{isColdStart ? "Database is warming up..." : "Something went wrong"}</h2>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

### Step 2: Graceful cold start handling
First query to Neon after idle: 2–5s. Handle with:
- Error boundary (catches and shows retry button)
- Loading states (`loading.tsx`)
- Optimistic retries in TanStack Query

### Step 3: API route error pattern
```ts
try {
  // ... business logic
} catch (error) {
  console.error("[API] /api/slots/hold:", error)
  return NextResponse.json(
    { error: "Something went wrong" },  // generic for client
    { status: 500 }
  )
}
```

### Step 4: Correlation IDs for debugging
```ts
const correlationId = crypto.randomUUID()
console.log(`[${correlationId}] Booking attempt:`, { serviceSlug, date, slot })
```

## NEVER
- ❌ Expose stack traces or DB errors to the client
- ❌ Silently swallow errors (log them)
- ❌ Return 200 for error conditions
