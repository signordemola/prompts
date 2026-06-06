---
name: email-notifications
description: >
  Email and notification patterns. ACTIVATE when: sending transactional emails,
  building email templates, generating ICS calendar attachments, or setting up
  reminder sequences. Covers Resend, ICS generation, and SMS.
---

# Email Notifications Skill

## When to Use
- Sending confirmation, reminder, or follow-up emails
- Generating ICS calendar attachments
- Setting up Resend or any email provider
- Deploying email functionality to Vercel

## Instructions

### Step 1: Email sequence (industry standard)
| Trigger | When | Content |
|---------|------|---------|
| Confirmation | Immediately | Service, date, time, manage link, prep, ICS |
| Reminder 1 | 24h before | "Tomorrow" + reschedule/cancel link |
| Reminder 2 | 2h before | "See you soon" + address |
| Follow-up | 24h after | Thank you + rebooking CTA |

### Step 2: Always include ICS attachments
ICS files reduce no-shows by 30–40%.
```ts
// lib/ics.ts
export function generateICS(appt: { startsAt: Date; endsAt: Date; ... }) {
  return [
    "BEGIN:VCALENDAR", "VERSION:2.0",
    "BEGIN:VEVENT",
    `DTSTART:${formatUTC(appt.startsAt)}`,
    `DTEND:${formatUTC(appt.endsAt)}`,
    `SUMMARY:${appt.serviceName}`,
    `LOCATION:${STUDIO_ADDRESS}`,
    "END:VEVENT", "END:VCALENDAR"
  ].join("\r\n")
}
```

### Step 3: Resend setup
```ts
import { Resend } from "resend"
const resend = new Resend(process.env.RESEND_API_KEY!)
```

### Step 4: Email templates (React Email 6)

Import components from the unified `react-email` package:

```tsx
import { Html, Head, Body, Container, Text, Button, render } from "react-email"

const BookingConfirmation = ({ name, service, date }: Props) => {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: "Inter, sans-serif" }}>
        <Container>
          <Text>Hi {name},</Text>
          <Text>Your {service} on {date} is confirmed.</Text>
          <Button href={manageUrl}>Manage Booking</Button>
        </Container>
      </Body>
    </Html>
  )
}

export default BookingConfirmation
```

Send with Resend:

```ts
import BookingConfirmation from "@/emails/booking-confirmation"
import { render } from "react-email"

await resend.emails.send({
  from: process.env.EMAIL_FROM!,
  to: client.email,
  subject: `Booking confirmed — ${service.name}`,
  html: await render(<BookingConfirmation name={client.name} service={service.name} date={formattedDate} />),
  attachments: [{ filename: "booking.ics", content: icsContent }],
})
```

### Step 5: Vercel deployment — CRITICAL
`RESEND_API_KEY` must be in **BOTH** Runtime AND Build environment variables.
Module-level instantiation runs at build time — missing key = build crash.

## Env vars
```
RESEND_API_KEY=re_...
EMAIL_FROM=Studio Name <noreply@yourdomain.com>
NEXT_PUBLIC_BASE_URL=https://your-domain.vercel.app
```

## NEVER
- ❌ Import from `@react-email/components` (deprecated — use `react-email`)
- ❌ Send emails without ICS attachments for appointments
- ❌ Hardcode email addresses in templates
- ❌ Skip the Vercel build env var step (causes build crashes)

