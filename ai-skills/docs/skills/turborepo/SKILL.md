---
name: turborepo
description: >
  Turborepo monorepo patterns. ACTIVATE when: setting up or modifying a monorepo,
  configuring turbo.json, sharing packages across apps, managing pnpm workspaces,
  or deploying individual apps from a monorepo.
---

# Turborepo Monorepo Skill

## When to Use
- Setting up a new monorepo or adding apps/packages
- Configuring turbo.json task pipelines
- Sharing code between apps (database, types, UI)
- Deploying from a monorepo (Vercel, Docker)
- CI/CD with remote caching

## Workspace Structure

```
my-monorepo/
├── apps/
│   ├── web/                         # Next.js frontend
│   │   ├── package.json             # name: "@repo/web"
│   │   └── ...
│   ├── api/                         # NestJS backend
│   │   ├── package.json             # name: "@repo/api"
│   │   └── ...
│   └── python-api/                  # FastAPI (not managed by turbo)
│       ├── pyproject.toml
│       └── ...
├── packages/
│   ├── database/                    # Shared Prisma client
│   │   ├── prisma/schema.prisma
│   │   ├── src/index.ts             # export { prisma, Prisma }
│   │   └── package.json             # name: "@repo/database"
│   ├── types/                       # Shared TypeScript types
│   │   ├── src/index.ts
│   │   └── package.json             # name: "@repo/types"
│   ├── ui/                          # Shared React components
│   ├── config/                      # Shared ESLint + TS configs
│   └── utils/                       # Shared utility functions
├── package.json                     # Root — workspaces, devDeps
├── pnpm-workspace.yaml
├── turbo.json
└── tsconfig.base.json
```

## pnpm Workspace

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

```jsonc
// Root package.json
{
  "private": true,
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "test": "turbo test",
    "db:generate": "turbo db:generate",
    "db:migrate": "turbo db:migrate"
  }
}
```

## turbo.json (Turborepo 2)

```jsonc
{
  "$schema": "https://turbo.build/schema.json",
  "globalEnv": ["NODE_ENV"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"],
      "env": ["API_URL", "DATABASE_URL"]
    },
    "dev": {
      "persistent": true,
      "cache": false
    },
    "lint": {
      "dependsOn": []
    },
    "test": {
      "dependsOn": ["build"],
      "env": ["DATABASE_URL"]
    },
    "db:generate": {
      "cache": false
    },
    "db:migrate": {
      "cache": false
    }
  }
}
```

## Shared Database Package

For Prisma 7, generate the client into the package and instantiate with a driver adapter:

```prisma
// packages/database/prisma/schema.prisma
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}
```

```ts
// packages/database/src/index.ts
import { PrismaClient } from "./generated/prisma/client"
import { PrismaPg } from "@prisma/adapter-pg"

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL!,
})

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma ?? new PrismaClient({ adapter })

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma

export * from "./generated/prisma/client"
export { prisma as db }
```

```jsonc
// packages/database/package.json
{
  "name": "@repo/database",
  "main": "./src/index.ts",
  "scripts": {
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:push": "prisma db push"
  },
  "dependencies": {
    "@prisma/client": "^7.x",
    "@prisma/adapter-pg": "^7.x",
    "pg": "^8.x"
  },
  "devDependencies": {
    "prisma": "^7.x"
  }
}
```

```jsonc
// apps/web/package.json — consuming the shared database
{
  "dependencies": {
    "@repo/database": "workspace:*"
  }
}
```

## TypeScript Config Inheritance

```jsonc
// tsconfig.base.json (root)
{
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "target": "ES2022",
    "module": "ES2022",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}

// apps/web/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "jsx": "preserve",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"]
}
```

## Deployment

### Next.js → Vercel
- Point Vercel to `apps/web`
- Vercel auto-detects Turborepo
- Set `TURBO_TEAM` + `TURBO_TOKEN` for remote caching

### NestJS → Docker
```dockerfile
# Build only what the api needs
FROM node:20-alpine AS builder
RUN corepack enable pnpm
WORKDIR /app

# Prune to only api + its dependencies
COPY . .
RUN pnpm turbo prune --scope=@repo/api --docker

# Install + build
FROM node:20-alpine AS installer
RUN corepack enable pnpm
WORKDIR /app
COPY --from=builder /app/out/json/ .
RUN pnpm install --frozen-lockfile
COPY --from=builder /app/out/full/ .
RUN pnpm turbo build --filter=@repo/api

# Run
FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=installer /app/apps/api/dist ./dist
CMD ["node", "dist/main.js"]
```

## CI/CD (GitHub Actions)

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # needed for --affected

      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - name: Build affected
        run: pnpm turbo build --affected
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ vars.TURBO_TEAM }}

      - name: Lint + Test affected
        run: pnpm turbo lint test --affected
```

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| Prisma client not found in consuming app | Run `turbo db:generate` before `turbo build` |
| Stale cache after env change | Add the env var to `turbo.json` `env` array |
| pnpm hoisting conflicts | Use `.npmrc` with `shamefully-hoist=false` (default) |
| `catalog:` not resolving | Ensure pnpm >= 9.x and `pnpm-workspace.yaml` has `catalog` section |

## NEVER
- ❌ Define `schema.prisma` in multiple apps (centralise in `packages/database`)
- ❌ Skip `fetch-depth: 0` in CI (breaks `--affected`)
- ❌ Use `npm` or `yarn` in a pnpm workspace
- ❌ Create a new package for every small utility (start with 3-5 packages)
- ❌ Forget to add env vars to `turbo.json` (stale cache bugs)
