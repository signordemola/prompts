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

### Step 4: Vercel deployment — CRITICAL
`RESEND_API_KEY` must be in **BOTH** Runtime AND Build environment variables.
Module-level instantiation runs at build time — missing key = build crash.

## Env vars
```
RESEND_API_KEY=re_...
EMAIL_FROM=Studio Name <noreply@yourdomain.com>
NEXT_PUBLIC_BASE_URL=https://your-domain.vercel.app
```
