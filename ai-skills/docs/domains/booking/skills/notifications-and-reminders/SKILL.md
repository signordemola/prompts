---
name: notifications-and-reminders
description: >
  Email, SMS, and reminder system patterns. ACTIVATE when: sending confirmation
  emails, scheduling reminders, generating ICS attachments, implementing follow-up
  sequences, or tracking booking funnel analytics.
---

# Notifications & Reminders Skill

## When to Use
- Sending booking confirmations or reminders
- Generating ICS calendar attachments
- Setting up reminder cron jobs
- Tracking conversion funnel events

## Processing Strategy

| | Inline (in webhook) | Queue (outbox pattern) |
|---|---|---|
| **Reliability** | Email fail = silent loss | Queue retries automatically |
| **Latency** | +1–3s to webhook | Webhook responds instantly |
| **Complexity** | Low | Medium (queue infra) |

> **Default for demos:** Inline with try/catch. Email failure must NOT block appointment creation.

```ts
const appointment = await prisma.appointment.create({ ... })
try {
  await sendConfirmationEmail(appointment)
} catch (e) {
  console.error("[EMAIL] Failed:", e)
  // Appointment created — email can be resent manually
}
```

## Email Sequence

| Trigger | When | Content | Channel |
|---------|------|---------|---------|
| Confirmation | Immediately | Details + ICS + manage link + prep | Email |
| Reminder 1 | 24h before | "Tomorrow at 10am" + reschedule link | Email + SMS |
| Reminder 2 | 2h before | "See you soon" + address | SMS |
| Follow-up | 24h after | "Thank you" + rebook CTA | Email |
| No-show | 1h after missed | "We missed you" + policy | Email |

## ICS Calendar Attachments

Reduces no-shows by 30–40%. Non-negotiable.

```ts
export function generateICS(appt: { id: string; startsAt: Date; endsAt: Date; serviceName: string }) {
  return [
    "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Studio//Booking//EN",
    "BEGIN:VEVENT",
    `UID:${appt.id}@studio.com`,
    `DTSTART:${format(appt.startsAt, "yyyyMMdd'T'HHmmss'Z'")}`,
    `DTEND:${format(appt.endsAt, "yyyyMMdd'T'HHmmss'Z'")}`,
    `SUMMARY:${appt.serviceName}`,
    `LOCATION:${STUDIO_ADDRESS}`,
    "STATUS:CONFIRMED",
    "END:VEVENT", "END:VCALENDAR"
  ].join("\r\n")
}
```

## Reminder Scheduling

| Method | Pros | Cons | Best for |
|--------|------|------|---------|
| **Vercel Cron** (hourly) | No infra, simple | Up to 1h imprecise | Demos |
| **BullMQ delayed job** | Precise timing | Needs Redis | Production |
| **External service** | Zero infra | Provider lock-in | Quick MVP |

> **Default:** Vercel Cron → API route every hour → query appointments needing reminders.

```ts
// api/cron/reminders/route.ts
export async function GET() {
  const in24h = addHours(new Date(), 24)
  const in25h = addHours(new Date(), 25)
  const upcoming = await prisma.appointment.findMany({
    where: { startsAt: { gte: in24h, lt: in25h }, status: "CONFIRMED", reminder24hSent: false }
  })
  for (const appt of upcoming) {
    await sendReminderEmail(appt)
    await prisma.appointment.update({ where: { id: appt.id }, data: { reminder24hSent: true } })
  }
  return NextResponse.json({ sent: upcoming.length })
}
```

## Conversion Funnel Events

```ts
export const FUNNEL_EVENTS = {
  PAGE_VIEW:         "booking.page_view",
  SERVICE_SELECTED:  "booking.service_selected",
  DATE_SELECTED:     "booking.date_selected",
  SLOT_SELECTED:     "booking.slot_selected",
  HOLD_CREATED:      "booking.hold_created",
  FORM_COMPLETED:    "booking.form_completed",
  PAYMENT_STARTED:   "booking.payment_started",
  PAYMENT_COMPLETED: "booking.payment_completed",
  HOLD_EXPIRED:      "booking.hold_expired",      // drop-off signal
  SLOT_UNAVAILABLE:  "booking.slot_unavailable",   // friction signal
} as const
```

## Email Template Checklist

| Check | Why |
|-------|-----|
| Single-column layout | Works on all mobile clients |
| HTML under 102KB | Gmail clips larger emails |
| `color-scheme: light dark` meta | Dark mode support |
| No pure black/white | Harsh contrast in dark mode |
| Inline CSS | Many clients strip `<style>` tags |
| ICS attachment | Calendar invite = 30% fewer no-shows |
| Manage link (not "no-reply") | Reduces support tickets |
| SPF + DKIM + DMARC | Deliverability |

### Confirmation Email Must Include

1. ✅ Success banner ("Booking Confirmed")
2. ✅ Service name, date, time, duration
3. ✅ Deposit paid amount
4. ✅ Reference number (`appointment.id.slice(-8).toUpperCase()`)
5. ✅ Prep instructions (niche-specific)
6. ✅ "Manage Booking" CTA button → manage link
7. ✅ ICS attachment
8. ✅ Studio address + directions

### Dark Mode Pattern

```tsx
// In React Email template
<Head>
  <meta name="color-scheme" content="light dark" />
</Head>
// Use mid-tone colours — avoid #000 and #fff
// Background: #f9fafb (light) / #1a1a1a (dark)
// Text: #111827 (light) / #e5e7eb (dark)
```

## NEVER
- ❌ Let email failure block appointment creation
- ❌ Send reminders without idempotency (`reminder24hSent` flag)
- ❌ Skip ICS attachments in confirmation emails
- ❌ Send marketing in transactional emails (separate streams)
- ❌ Use pure black/white in email templates (dark mode breaks)
- ❌ Use "no-reply" sender address

