---
name: booking-platform
description: >
  Beauty/wellness booking platform orchestrator. ACTIVATE when: building any
  booking feature. This skill routes you to the right sub-skill based on
  what you're implementing. Load general skills first, then the relevant
  booking sub-skill.
---

# Booking Platform Domain Skill

## When to Use
- Building a new booking demo (any beauty/wellness niche)
- Any booking-specific feature

## Pre-Requisites — Always Load First
- `docs/skills/timezone-safety/SKILL.md`
- `docs/skills/prisma-database/SKILL.md`
- `docs/skills/stripe-payments/SKILL.md`

## Sub-Skill Routing

| When you're working on... | Load sub-skill |
|--------------------------|---------------|
| Slot holds, race conditions, idempotency, webhooks, rate limiting | `skills/concurrency-and-holds/SKILL.md` |
| Stripe checkout, deposits, pricing, promo codes, refunds, packages | `skills/payment-and-pricing/SKILL.md` |
| Wizard steps, hold timing, intake forms, scheduling rules, add-ons, multi-service | `skills/booking-flow-and-ux/SKILL.md` |
| Emails, SMS, reminders, ICS, funnel analytics, email templates | `skills/notifications-and-reminders/SKILL.md` |
| Cancel, reschedule, no-shows, waitlists, recurring | `skills/cancellation-and-lifecycle/SKILL.md` |
| Slot generation, buffer times, availability, calendar, caching | `skills/availability-and-calendar/SKILL.md` |

## Reference Files

| Reference | Read when... |
|-----------|-------------|
| `references/database-schema.md` | Designing or modifying the DB schema |
| `references/edge-cases.md` | Debugging weird time/payment/race issues |
| `references/dashboard-patterns.md` | Building owner dashboard or confirmation page |
| `references/client-management.md` | Client dedup, merge, tracking, segments |
| `references/multi-staff.md` | Adding multiple providers/staff |
| `references/api-design.md` | Designing API endpoints or error formats |
| `references/testing-patterns.md` | Writing tests, mocking Stripe, time travel |
| `references/common-mistakes.md` | Debugging any issue |
| `references/availability-engine.md` | Deep dive into slot generation algorithm |
| `references/slot-reservation.md` | Deep dive into hold/lock mechanics |
| `references/cancellation-noshows.md` | Refund tiers, no-show policy details |
| `references/multi-currency.md` | GBP/USD/CAD pricing, currency formatting |
| `references/tax-handling.md` | UK VAT, US sales tax, Canada GST/HST |
| `references/data-privacy.md` | GDPR, health data consent, right to erasure |
| `references/gift-cards.md` | Gift card schema, purchase, redemption flow |
| `references/accessibility-walkins.md` | Booking wizard a11y, keyboard nav, walk-ins |

## What Changes Per Demo

| File | What to update |
|------|---------------|
| `lib/studio-data.ts` | Services, prices (per market), durations |
| `prisma/seed.ts` | Prices/deposits (smallest unit), sample data |
| Intake form fields | Niche-specific questions |
| Email templates | Prep instructions, studio address |
| Policy wording | Cancellation windows, deposit rules |
| Availability hours | Days of week, open/close times |
| Landing page | Entirely niche-specific |
| Currency/market config | GBP/USD/CAD per deployment |

## End-to-End Booking Flow

```
1. Client selects service → date → time slot
2. POST /api/slots/hold → creates SlotHold (TTL 5 min)
3. Client fills intake form → agrees to policy + health consent
4. POST /api/stripe/checkout → PaymentIntent (metadata has everything)
5. Stripe Elements → confirmPayment() → redirects to confirmation page
6. Webhook: payment_intent.succeeded → validate hold → create Appointment
   → delete hold → send confirmation email with ICS
7. Confirmation page polls until appointment found → shows details
```

## State Machine

```
HOLD → CONFIRMED → COMPLETED
                 → CANCELLED
                 → NO_SHOW
                 → RESCHEDULING → (new HOLD)
```

## Full Coverage (32 Sections)

| # | Topic | Location |
|---|-------|---------|
| 1 | Locking strategies | `skills/concurrency-and-holds` |
| 2 | DB vs Redis holds | `skills/concurrency-and-holds` |
| 3 | Idempotency keys | `skills/concurrency-and-holds` |
| 4 | Rate limiting & spam | `skills/concurrency-and-holds` |
| 5 | Pre-auth vs capture | `skills/payment-and-pricing` |
| 6 | Deposit strategies | `skills/payment-and-pricing` |
| 7 | Promo codes | `skills/payment-and-pricing` |
| 8 | Stripe refund API | `skills/payment-and-pricing` |
| 9 | Prepaid packages | `skills/payment-and-pricing` |
| 10 | Payment edge cases | `skills/payment-and-pricing` |
| 11 | Wizard steps | `skills/booking-flow-and-ux` |
| 12 | Hold timing & TTL | `skills/booking-flow-and-ux` |
| 13 | Scheduling rules | `skills/booking-flow-and-ux` |
| 14 | Intake forms | `skills/booking-flow-and-ux` |
| 15 | Multi-service & add-ons | `skills/booking-flow-and-ux` |
| 16 | Email sequence | `skills/notifications-and-reminders` |
| 17 | ICS generation | `skills/notifications-and-reminders` |
| 18 | Reminder scheduling | `skills/notifications-and-reminders` |
| 19 | Email templates | `skills/notifications-and-reminders` |
| 20 | Funnel analytics | `skills/notifications-and-reminders` |
| 21 | Cancel/reschedule | `skills/cancellation-and-lifecycle` |
| 22 | Refund tiers | `skills/cancellation-and-lifecycle` |
| 23 | Waitlists | `skills/cancellation-and-lifecycle` |
| 24 | Recurring bookings | `skills/cancellation-and-lifecycle` |
| 25 | Slot generation | `skills/availability-and-calendar` |
| 26 | Buffer times | `skills/availability-and-calendar` |
| 27 | Performance & caching | `skills/availability-and-calendar` |
| 28 | Multi-currency (GBP/USD/CAD) | `references/multi-currency` |
| 29 | Tax handling (VAT/sales tax/GST) | `references/tax-handling` |
| 30 | Data privacy & GDPR | `references/data-privacy` |
| 31 | Gift cards & vouchers | `references/gift-cards` |
| 32 | Accessibility & walk-ins | `references/accessibility-walkins` |

