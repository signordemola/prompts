---
name: deployment-vercel
description: >
  Vercel deployment patterns. ACTIVATE when: deploying, configuring env vars,
  debugging build failures, setting up webhooks, seeding production databases,
  or handling Neon/serverless cold starts.
---

# Deployment (Vercel) Skill

## When to Use
- Deploying to Vercel for the first time
- Debugging build or runtime failures
- Setting up env vars or webhooks
- Seeding a production database

## Instructions

### Step 1: Env vars checklist
| Variable | Scope |
|----------|-------|
| `DATABASE_URL` | Runtime + Build |
| `STRIPE_SECRET_KEY` | Runtime |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Runtime |
| `STRIPE_WEBHOOK_SECRET` | Runtime |
| `RESEND_API_KEY` | **Runtime + Build** (critical!) |
| `EMAIL_FROM` | Runtime |
| `NEXT_PUBLIC_BASE_URL` | Runtime (no trailing slash) |
| `OWNER_EMAIL` | Runtime |
| `OWNER_PASSWORD_HASH` | Runtime |

### Step 2: Post-deploy
1. Create Stripe webhook → `/api/stripe/webhook` → event: `payment_intent.succeeded`
2. Copy `whsec_...` to Vercel env vars
3. Seed production DB with timezone-safe timestamps
4. Test booking flow with Stripe test card `4242 4242 4242 4242`

### Step 3: Password hash generation
```bash
echo -n "yourpassword" | sha256sum
# or
node -e "console.log(require('crypto').createHash('sha256').update('yourpassword').digest('hex'))"
```

### Step 4: Common build failures
| Error | Cause | Fix |
|-------|-------|-----|
| `RESEND_API_KEY` undefined | Not in Build scope | Add to Build env vars |
| Prisma client not generated | Missing prebuild | Add `"prebuild": "prisma generate"` |
| argon2 native binding | Native module on serverless | Use SHA-256 or bcryptjs |
| ETIMEDOUT / P1001 | Neon cold start | Add error boundary |

## NEVER
- ❌ Seed locally for remote DB (timezone mismatch)
- ❌ Use trailing slash in `NEXT_PUBLIC_BASE_URL`
- ❌ Skip webhook setup (bookings won't confirm)
