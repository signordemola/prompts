---
name: hono
description: >
  Hono API framework for edge and multi-runtime environments. ACTIVATE when:
  building lightweight APIs, edge functions, or multi-runtime TypeScript
  backends. Covers middleware, Zod validation, RPC client, and deployment.
---

# Hono Skill

## When to Use
- Building lightweight TypeScript APIs
- Creating edge functions (Vercel, Cloudflare Workers)
- Building multi-runtime backends (Node.js, Bun, Deno)
- Need end-to-end type-safe API calls without codegen

## Basic API

```ts
import { Hono } from "hono"
import { logger } from "hono/logger"
import { cors } from "hono/cors"

const app = new Hono()

app.use("*", logger())
app.use("/api/*", cors())

app.get("/api/health", (c) => c.json({ ok: true }))

app.get("/api/services", async (c) => {
  const services = await getServices()
  return c.json(services)
})

app.get("/api/services/:id", async (c) => {
  const id = c.req.param("id")
  const service = await getServiceById(id)

  if (!service) {
    return c.json({ error: "Not found" }, 404)
  }

  return c.json(service)
})

export default app
```

## Zod Validation

```ts
import { Hono } from "hono"
import { zValidator } from "@hono/zod-validator"
import { z } from "zod"

const app = new Hono()

const CreateBookingSchema = z.object({
  serviceId: z.string().min(1),
  date: z.string().datetime(),
  name: z.string().trim().min(1),
  email: z.email(),
})

app.post(
  "/api/bookings",
  zValidator("json", CreateBookingSchema),
  async (c) => {
    const data = c.req.valid("json")
    const booking = await createBooking(data)
    return c.json(booking, 201)
  }
)
```

## Middleware

```ts
import { bearerAuth } from "hono/bearer-auth"
import { jwt } from "hono/jwt"

app.use("/api/admin/*", bearerAuth({ token: process.env.ADMIN_TOKEN! }))

app.use("/api/dashboard/*", jwt({ secret: process.env.JWT_SECRET! }))

app.use("/api/*", async (c, next) => {
  const start = Date.now()
  await next()
  const duration = Date.now() - start
  c.header("X-Response-Time", `${duration}ms`)
})
```

## Route Groups

```ts
const api = new Hono()
  .get("/services", async (c) => c.json(await getServices()))
  .get("/services/:id", async (c) => c.json(await getService(c.req.param("id"))))
  .post("/bookings", zValidator("json", BookingSchema), async (c) => {
    const data = c.req.valid("json")
    return c.json(await createBooking(data), 201)
  })

const app = new Hono().route("/api", api)

export default app
```

## RPC Client (End-to-End Type Safety)

```ts
// server.ts
const routes = app
  .get("/api/services", async (c) => {
    const services = await getServices()
    return c.json(services)
  })
  .post("/api/bookings", zValidator("json", BookingSchema), async (c) => {
    const data = c.req.valid("json")
    return c.json(await createBooking(data), 201)
  })

export type AppRoutes = typeof routes
```

```ts
// client.ts
import { hc } from "hono/client"
import type { AppRoutes } from "./server"

const client = hc<AppRoutes>("http://localhost:3000")

const services = await client.api.services.$get()
const data = await services.json()
```

## Deploy: Vercel

```ts
// api/index.ts
import { handle } from "hono/vercel"
import app from "../server"

export const GET = handle(app)
export const POST = handle(app)
```

## Deploy: Node.js

```ts
import { serve } from "@hono/node-server"
import app from "./server"

serve({ fetch: app.fetch, port: 3000 })
```

## Error Handling

```ts
import { HTTPException } from "hono/http-exception"

app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return c.json({ error: err.message }, err.status)
  }
  return c.json({ error: "Internal server error" }, 500)
})

app.notFound((c) => c.json({ error: "Not found" }, 404))
```

## NEVER
- ❌ Use Express patterns (`req.body`, `res.json()`) — use `c.req.json()`, `c.json()`
- ❌ Forget `c.json()` for JSON responses (don't return raw objects)
- ❌ Mix runtime-specific code in handlers (keep handlers portable)
- ❌ Use Hono's built-in JWT for production auth without rate limiting
- ❌ Skip Zod validation on input (use `zValidator`)
