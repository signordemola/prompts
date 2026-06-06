---
name: drizzle-database
description: >
  Drizzle ORM patterns. ACTIVATE when: using Drizzle for database access,
  defining schemas with pgTable(), running drizzle-kit migrations, or
  querying with the Drizzle query builder. Don't use for Prisma projects —
  use prisma-database skill instead.
---

# Drizzle Database Skill

## When to Use
- Building or modifying a Drizzle ORM data layer
- Defining schemas, relations, or enums
- Running migrations with drizzle-kit
- Writing queries, transactions, or prepared statements

## Project Structure

```
src/db/
├── index.ts              # drizzle() instance + connection
├── schema/               # Table definitions
│   ├── users.ts
│   ├── orders.ts
│   └── index.ts          # Re-exports all tables
├── migrations/           # Generated SQL migrations (never edit manually)
└── seed.ts               # Seed data
```

## Connection Setup

```ts
// src/db/index.ts
import { drizzle } from "drizzle-orm/node-postgres"
import * as schema from "./schema"

export const db = drizzle(process.env.DATABASE_URL!, { schema })
```

For Next.js, use a singleton to survive hot reload:
```ts
const globalForDb = globalThis as unknown as { db: ReturnType<typeof drizzle> }
export const db = globalForDb.db ?? drizzle(process.env.DATABASE_URL!, { schema })
if (process.env.NODE_ENV !== "production") globalForDb.db = db
```

For NestJS, wrap in an injectable service:
```ts
@Injectable()
export class DrizzleService {
  public readonly db: ReturnType<typeof drizzle>
  constructor(private config: ConfigService) {
    this.db = drizzle(config.get("DATABASE_URL"), { schema })
  }
}
```

> **Note:** Drizzle is TypeScript-only. For FastAPI/Python projects, use SQLAlchemy instead.

## Schema Patterns

```ts
// schema/users.ts
import { pgTable, text, integer, timestamp, boolean, pgEnum } from "drizzle-orm/pg-core"

export const roleEnum = pgEnum("role", ["USER", "ADMIN", "OWNER"])

export const users = pgTable("users", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  role: roleEnum("role").notNull().default("USER"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow().$onUpdate(() => new Date()),
})

// schema/orders.ts
export const orders = pgTable("orders", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  userId: text("user_id").notNull().references(() => users.id),
  totalAmount: integer("total_amount").notNull(),  // pence/cents — NEVER floats
  status: text("status", { enum: ["PENDING", "CONFIRMED", "SHIPPED", "DELIVERED"] }).notNull().default("PENDING"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
})
```

## Relations

```ts
// schema/relations.ts
import { relations } from "drizzle-orm"

export const usersRelations = relations(users, ({ many }) => ({
  orders: many(orders),
}))

export const ordersRelations = relations(orders, ({ one }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
}))
```

## Query Patterns

```ts
// Select with filters
const activeUsers = await db.select().from(users)
  .where(eq(users.role, "USER"))
  .orderBy(desc(users.createdAt))
  .limit(10)

// Relational query (requires relations defined)
const userWithOrders = await db.query.users.findFirst({
  where: eq(users.id, userId),
  with: { orders: true },
})

// Insert
const [newUser] = await db.insert(users)
  .values({ email: "jane@example.com", name: "Jane" })
  .returning()

// Update
await db.update(users)
  .set({ name: "Jane Doe" })
  .where(eq(users.id, userId))

// Delete
await db.delete(orders).where(eq(orders.id, orderId))

// Transaction
await db.transaction(async (tx) => {
  const [order] = await tx.insert(orders).values({ ... }).returning()
  await tx.update(inventory).set({ stock: sql`stock - 1` }).where(...)
})

// Prepared statement (reusable, optimized)
const getUser = db.select().from(users).where(eq(users.id, sql.placeholder("id"))).prepare("get_user")
const user = await getUser.execute({ id: "abc-123" })
```

## Migration Workflow

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply pending migrations
npx drizzle-kit migrate

# Push schema directly to DB (dev only — skips migration files)
npx drizzle-kit push

# Open visual DB browser
npx drizzle-kit studio
```

```ts
// drizzle.config.ts
import { defineConfig } from "drizzle-kit"

export default defineConfig({
  schema: "./src/db/schema/index.ts",
  out: "./src/db/migrations",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
})
```

## Drizzle vs Prisma

| | Drizzle | Prisma |
|---|---|---|
| **Philosophy** | SQL-first, thin wrapper | Schema-first, heavy abstraction |
| **Schema** | TypeScript code (`pgTable()`) | `.prisma` DSL file |
| **Queries** | SQL-like builder | Fluent API |
| **Migrations** | SQL files you own | Managed by Prisma |
| **Bundle size** | ~50KB | ~2MB+ (engine binary) |
| **Type safety** | Full, from schema | Full, generated client |
| **Raw SQL** | First-class (`sql` tag) | Escape hatch (`$queryRaw`) |
| **Best for** | Performance-critical, SQL-savvy teams | Rapid prototyping, schema-first teams |

**Pick Drizzle when:** You want SQL control, small bundle, edge runtime compatibility.
**Pick Prisma when:** You want schema DSL, managed migrations, Prisma Studio.

## References
- `references/migration-patterns.md` — safe migration strategies

## NEVER
- ❌ Use `drizzle-kit push` in production (bypasses migration history)
- ❌ Store monetary values as floats (use integers: pence/cents)
- ❌ Skip migration files (they're your DB change history)
- ❌ Use raw SQL without the `sql` template tag (SQL injection risk)
- ❌ Edit generated migration files (regenerate instead)
- ❌ Import from `drizzle-orm/pg-core` AND `drizzle-orm/mysql-core` in the same project
