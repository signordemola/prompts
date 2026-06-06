# Migration Patterns — Database Schema Change Workflows

Safe strategies for evolving database schemas without data loss or downtime.

## Prisma Migrations

```bash
# Dev: generate + apply migration from schema changes
npx prisma migrate dev --name "add_orders_table"

# Production: apply pending migrations (no generation)
npx prisma migrate deploy

# Reset dev DB (drops + recreates + seeds)
npx prisma migrate reset

# Check migration status
npx prisma migrate status
```

### Safe Prisma Workflow
1. Edit `schema.prisma`
2. Run `npx prisma migrate dev --name "descriptive_name"`
3. Review generated SQL in `prisma/migrations/`
4. Test locally
5. Commit migration files with code changes
6. CI runs `npx prisma migrate deploy` on staging/production

## Drizzle Migrations

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply pending migrations
npx drizzle-kit migrate

# Dev shortcut: push schema directly (skips migration files)
npx drizzle-kit push
```

## Alembic Migrations (FastAPI / SQLAlchemy)

```bash
# Generate migration from model changes
uv run alembic revision --autogenerate -m "add orders table"

# Apply migrations
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1

# Show current state
uv run alembic current
```

## Safe Migration Patterns

| Pattern | When | How |
|---------|------|-----|
| **Additive only** | Adding columns, tables, indexes | Just add — no risk to existing data |
| **Expand-contract** | Renaming or removing columns | Add new → migrate data → remove old |
| **Backfill-then-constrain** | Adding NOT NULL to existing column | Add nullable → backfill defaults → add constraint |
| **Shadow column** | Changing column type | Add new column → dual-write → migrate reads → drop old |

## Dangerous Operations

| Operation | Risk | Safe Alternative |
|-----------|------|-----------------|
| **Column rename** | Breaks all queries referencing old name | Expand-contract: add new, copy, drop old |
| **Column type change** | Data loss if incompatible | Shadow column pattern |
| **NOT NULL on existing** | Fails if NULLs exist | Backfill first, then add constraint |
| **Drop column** | Irreversible data loss | Soft-delete: add `deprecated_at`, remove later |
| **Drop table** | Irreversible | Rename to `_deprecated_X` first, drop after verification |
| **Truncate** | Deletes all rows | Almost never correct in production |

## Rollback Strategy

| Framework | Rollback Command | Notes |
|-----------|-----------------|-------|
| **Prisma** | No built-in rollback | Manual: write reverse migration or restore backup |
| **Drizzle** | No built-in rollback | Manual: write reverse SQL migration |
| **Alembic** | `alembic downgrade -1` | Built-in, if `downgrade()` is implemented |

**Rule:** Always test migrations on a staging database before production. Always have a database backup before running migrations in production.

## NEVER
- ❌ Run `migrate dev` or `push` in production
- ❌ Edit a migration file that's already been applied
- ❌ Drop columns without verifying no code references them
- ❌ Add NOT NULL without a default on an existing table with data
- ❌ Run destructive migrations without a backup
