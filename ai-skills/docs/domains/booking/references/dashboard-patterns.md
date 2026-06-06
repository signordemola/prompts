# Dashboard Patterns

## Views & Data

| View | Query | Update frequency |
|------|-------|-----------------|
| **Today** | `WHERE DATE(startsAt) = today ORDER BY startsAt` | Poll every 30s |
| **Week** | `WHERE startsAt BETWEEN weekStart AND weekEnd` | On page load |
| **Client list** | `ORDER BY lastVisitAt DESC` | On page load |
| **Revenue** | `SUM(depositAmount) GROUP BY month` | On page load |

## Today View Layout

```
┌─────────────────────────────────────────┐
│  Today: Thursday 15 June   [← →]        │
│  3 appointments · £145 revenue           │
├─────────────────────────────────────────┤
│  09:30  Classic Lash Set     CONFIRMED   │
│         Sarah Johnson                    │
│         [Mark Complete] [No-Show]        │
├─────────────────────────────────────────┤
│  12:00  Lash Fill            CONFIRMED   │
│         Emma Williams                    │
│         [Mark Complete] [No-Show]        │
├─────────────────────────────────────────┤
│  15:30  Volume Lash Set      CONFIRMED   │
│         Lisa Chen                        │
│         [Mark Complete] [No-Show]        │
└─────────────────────────────────────────┘
```

## Real-Time Updates

| Method | When | How |
|--------|------|-----|
| **Polling** | Demo, <10 bookings/day | `refetchInterval: 30_000` via TanStack Query |
| **SSE** | Production, owner dashboard | Server pushes on new booking |
| **WebSocket** | Multi-staff, collaborative | Overkill for solo provider |

**Default for demos:** Polling every 30s:

```ts
const { data: todayAppts } = useQuery({
  queryKey: ["appointments", "today"],
  queryFn: () => fetch("/api/dashboard/today").then(r => r.json()),
  refetchInterval: 30_000,
})
```

## Owner Dashboard Metrics

| Metric | Query pattern |
|--------|-------------|
| Bookings today | `WHERE DATE(startsAt) = today AND status = 'CONFIRMED'` |
| Revenue this month | `SUM(depositAmount) WHERE status IN ('CONFIRMED','COMPLETED')` |
| No-show rate | `COUNT(NO_SHOW) / COUNT(CONFIRMED + COMPLETED + NO_SHOW)` |
| Busiest day | `GROUP BY dayOfWeek ORDER BY COUNT DESC` |
| Average lead time | `AVG(startsAt - createdAt)` |
| Cancellation rate | `COUNT(CANCELLED) / COUNT(all) per month` |
| Returning clients | `WHERE appointmentCount >= 2` |
| At-risk clients | `WHERE lastVisitAt < 60 days ago` |

## Confirmation Page (Post-Payment)

```tsx
// app/(booking)/confirmation/page.tsx
export default async function ConfirmationPage({ searchParams }) {
  const { session_id } = searchParams
  
  // DON'T rely on this page for fulfillment — webhook handles that
  const appointment = await prisma.appointment.findFirst({
    where: { stripePaymentId: session_id },
    include: { service: true, client: true }
  })
  
  if (!appointment) {
    return <ProcessingState sessionId={session_id} />
  }
  
  return (
    <div>
      <h1>Booking Confirmed ✓</h1>
      <p>Reference: {appointment.id.slice(-8).toUpperCase()}</p>
      <p>{appointment.service.name}</p>
      <p>{format(appointment.startsAt, "EEEE d MMMM 'at' h:mm a")}</p>
      <p>Check your email for confirmation + calendar invite</p>
      <a href={`/appointment/${appointment.manageToken}`}>Manage booking →</a>
    </div>
  )
}

function ProcessingState({ sessionId }) {
  // Poll every 2s for up to 30s, then show "check your email"
  return (
    <div>
      <Spinner />
      <p>Finalising your booking...</p>
      <p className="subtle">If this takes more than 30 seconds, check your email.</p>
    </div>
  )
}
```

## DB Cold Start Error Boundary (Neon)

```tsx
"use client"
export default function DashboardError({ error, reset }) {
  const isColdStart = error.message?.includes("connection")
  return (
    <div>
      <h2>{isColdStart ? "Database warming up..." : "Something went wrong"}</h2>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```
