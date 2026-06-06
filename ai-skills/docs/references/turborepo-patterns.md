# Turborepo Advanced Patterns

## turbo prune for Docker

```bash
# Generate a minimal directory for a specific app
pnpm turbo prune --scope=@repo/api --docker

# Output structure:
# out/
# ├── json/          # package.json files only (for install layer)
# ├── full/          # full source (for build layer)
# └── pnpm-lock.yaml
```

This enables efficient Docker layer caching: install dependencies first (rarely changes), then copy source (frequently changes).

## Shared TypeScript Config

```
tsconfig.base.json          ← Root: strict, module, target
├── apps/web/tsconfig.json  ← extends + jsx, paths
├── apps/api/tsconfig.json  ← extends + emitDecoratorMetadata (NestJS)
└── packages/*/tsconfig.json ← extends + declaration, composite
```

```jsonc
// packages/types/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src",
    "composite": true,     // enables project references
    "declaration": true
  },
  "include": ["src"]
}
```

## pnpm Catalog (Centralised Versions)

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"

catalog:
  react: "^19.0.0"
  typescript: "^5.7.0"
  "@prisma/client": "^6.4.0"
  vitest: "^3.0.0"
```

```jsonc
// apps/web/package.json
{
  "dependencies": {
    "react": "catalog:",        // resolves to ^19.0.0
    "@prisma/client": "catalog:" // resolves to ^6.4.0
  }
}
```

**Benefit:** Change a version in one place → all packages updated. Eliminates merge conflicts on version bumps.

## Remote Caching

```bash
# Link to Vercel (one-time)
pnpm turbo login
pnpm turbo link

# Or set manually in CI
TURBO_TOKEN=your-token
TURBO_TEAM=your-team

# Self-hosted alternative: ducktape/turborepo-remote-cache
```

## Package Scripts Convention

```jsonc
// packages/database/package.json
{
  "scripts": {
    "build": "tsc",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio"
  }
}
```

Run from root: `pnpm turbo db:generate` runs in all packages that define it.

## Mixed Language Monorepo (TS + Python)

Turborepo only orchestrates Node.js packages. For Python apps:

```jsonc
// apps/python-api/package.json (shim)
{
  "name": "@repo/python-api",
  "scripts": {
    "dev": "uv run uvicorn app.main:app --reload",
    "build": "echo 'Python app - no build step'",
    "test": "uv run pytest -xvs",
    "lint": "uv run ruff check --fix . && uv run pyright app"
  }
}
```

This lets Turborepo orchestrate Python tasks via the same `turbo dev`, `turbo test`, `turbo lint` commands.

## Dependency Graph

```bash
# Visualise the dependency graph
pnpm turbo run build --graph

# Output: opens a browser with the dependency graph
# Useful for debugging "why is this package rebuilding?"
```
