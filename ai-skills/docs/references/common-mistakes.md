# Common Mistakes (Do Not Repeat)

These are real bugs encountered during development. Every one cost hours to debug.

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| `setHours()` in seed script | Wrong UTC timestamps, seeded appointments don't block slots | Use `providerDate()` from `lib/dayjs.ts` |
| `startOfDay(londonMidnight)` in Prisma queries | Queries wrong UTC day, misses all appointments for that day | Use `date` directly (already London midnight) |
| `getDay(londonMidnight)` for availability lookup | Returns previous day's weekday during BST | Parse from dateStr: `new Date(y, mo-1, d).getDay()` |
| `formatCurrency()` on studio-data values | Shows £0.20 instead of £20 (studio-data is already pounds) | Use `£${value}` directly for static data |
| `amount: service.deposit * 100` in Stripe | 100× overcharge (deposit is already in pence) | Use `service.deposit` directly |
| `new Resend()` at module level | Build crash on Vercel (API key not present at build time) | Add `RESEND_API_KEY` to Build env vars |
| Using `argon2` for password hashing | Native binding compilation fails on Vercel/serverless | Use Node `crypto` SHA-256 or `bcryptjs` |
| Seeding locally, deploying remotely | Timestamps use machine's local timezone, not London | Always seed on server or use `providerDate()` |
| Missing `RESEND_API_KEY` in Build scope | Next.js page data collection phase crashes | Add to both Runtime AND Build in Vercel |
| Renaming `proxy.ts` to `middleware.ts` | Middleware stops working (wired via next.config) | Keep as `proxy.ts` |
| Relying on Zustand state after Stripe redirect | State cleared on page redirect, booking data lost | Store everything in Stripe `metadata` |
| Not verifying webhook signature | Anyone can fake a booking confirmation | Always use `stripe.webhooks.constructEvent()` |
| Missing `export const dynamic = "force-dynamic"` | Stale data on server-rendered pages | Add to all pages reading from DB |
| FK constraint violation during seed reset | Seed fails because of dependent records | Delete in order: holds → appointments → clients → services |
