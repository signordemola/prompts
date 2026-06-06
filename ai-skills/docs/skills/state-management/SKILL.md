---
name: state-management
description: >
  Client-side state management patterns. ACTIVATE when: implementing multi-step
  wizards, persisting state across pages, managing booking/cart/chat state, or
  using Zustand or TanStack Query.
---

# State Management Skill

## When to Use
- Building multi-step wizards (booking, checkout, onboarding)
- Persisting state in localStorage
- Managing server state with TanStack Query
- Handling state across Stripe redirects

## Instructions

### Step 1: Zustand for wizard/flow state
```ts
import { create } from "zustand"
import { persist } from "zustand/middleware"

export const useBookingStore = create(persist((set) => ({
  selectedService: null,
  selectedDate: null,
  selectedSlot: null,
  holdToken: null,
  clientInfo: null,
  setService: (s) => set({ selectedService: s }),
  reset: () => set({ selectedService: null, selectedDate: null, ... }),
}), { name: "booking-state" }))
```

### Step 2: Reset after completion
```ts
// On confirmation page
useEffect(() => { useBookingStore.getState().reset() }, [])
```

### Step 3: Don't trust persisted state after redirects
Stripe redirects clear JS state. Store everything in Stripe `metadata`.

### Step 4: TanStack Query for server state
```ts
const { data: slots } = useQuery({
  queryKey: ["slots", date, serviceSlug],
  queryFn: () => fetch(`/api/slots?date=${date}&service=${serviceSlug}`).then(r => r.json()),
  enabled: !!date && !!serviceSlug,
})
```

## NEVER
- ❌ Store sensitive data (tokens, passwords) in Zustand/localStorage
- ❌ Trust persisted state after page redirects
- ❌ Forget to reset wizard state after completion
