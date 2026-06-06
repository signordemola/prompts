# Package Version Registry

Last audited: 2026-06-07

This file tracks every package referenced in the skill library. Run the audit
script weekly to check for newer versions.

## JavaScript / TypeScript

| Package | Documented Version | Skill File |
|---------|--------------------|------------|
| next | 16.x | skills/nextjs-app-router/SKILL.md |
| react | 19.x | skills/nextjs-app-router/SKILL.md |
| typescript | 5.x | skills/code-style/SKILL.md |
| zod | 4.x | skills/input-validation/SKILL.md |
| @tanstack/react-query | 5.x | skills/data-fetching/SKILL.md |
| ai | 5.x (AI SDK) | domains/chatbot/skills/llm-integration/SKILL.md |
| @ai-sdk/react | 5.x | domains/chatbot/skills/chat-ui-and-widget/SKILL.md |
| prisma | 7.x | skills/prisma-database/SKILL.md |
| @prisma/adapter-pg | 7.x | skills/prisma-database/SKILL.md |
| drizzle-orm | 1.x | skills/drizzle-database/SKILL.md |
| drizzle-kit | 1.x | skills/drizzle-database/SKILL.md |
| @nestjs/core | 11.x (12 alpha) | skills/nestjs/SKILL.md |
| zustand | 5.x | skills/nextjs-app-router/SKILL.md |
| vitest | 3.x | workflows/tdd/SKILL.md |
| tailwindcss | 4.3.x | skills/tailwind-css/SKILL.md |
| react-hook-form | 7.77.x | skills/react-hook-form/SKILL.md |
| @hookform/resolvers | latest | skills/react-hook-form/SKILL.md |
| uploadthing | 7.x | skills/uploadthing/SKILL.md |
| @uploadthing/react | 7.x | skills/uploadthing/SKILL.md |
| @playwright/test | 1.60.x | skills/playwright/SKILL.md |
| hono | 4.12.x | skills/hono/SKILL.md |
| @hono/zod-validator | latest | skills/hono/SKILL.md |
| @hono/node-server | latest | skills/hono/SKILL.md |
| react-email | 6.x | skills/email-notifications/SKILL.md |
| resend | latest | skills/email-notifications/SKILL.md |
| react-pdf | latest | skills/invoicing/SKILL.md |
| stripe | latest (Dahlia) | domains/booking/SKILL.md |
| @upstash/redis | latest | skills/nextjs-app-router/SKILL.md |
| date-fns | 4.x | skills/timezone-safety/SKILL.md |
| @date-fns/tz | 1.5.x | skills/timezone-safety/SKILL.md |
| langfuse | 5.x | domains/chatbot/references/analytics-observability.md |
| turbo | 2.x | skills/turborepo/SKILL.md |
| husky | 9.x | skills/project-scripts/SKILL.md |
| lint-staged | latest | skills/project-scripts/SKILL.md |
| oxlint | latest | skills/project-scripts/SKILL.md |

## Python

| Package | Documented Version | Skill File |
|---------|--------------------|------------|
| fastapi | 0.134+ | skills/fastapi/SKILL.md |
| pydantic | 3.x | skills/fastapi/SKILL.md |
| pydantic-settings | latest | skills/fastapi/SKILL.md |
| sqlalchemy | 2.x (async) | skills/fastapi/SKILL.md |
| uvicorn | latest | skills/fastapi/SKILL.md |
| ruff | latest | skills/fastapi/SKILL.md |
| pyright | latest | skills/fastapi/SKILL.md |
| alembic | latest | skills/fastapi/SKILL.md |
| httpx | latest | skills/fastapi/SKILL.md |
| pytest | latest | skills/fastapi/SKILL.md |

## Audit Script

```bash
#!/bin/bash
# Run: bash references/check-versions.sh

echo "=== Checking npm packages ==="
packages=(
  "next" "react" "zod" "@tanstack/react-query" "ai" "@ai-sdk/react"
  "prisma" "drizzle-orm" "drizzle-kit" "@nestjs/core" "zustand" "vitest"
  "tailwindcss" "react-hook-form" "uploadthing" "@playwright/test"
  "hono" "react-email" "resend" "stripe" "date-fns" "@date-fns/tz"
  "langfuse" "turbo" "husky" "oxlint"
)

for pkg in "${packages[@]}"; do
  latest=$(npm view "$pkg" version 2>/dev/null)
  echo "$pkg: $latest"
done

echo ""
echo "=== Checking PyPI packages ==="
py_packages=("fastapi" "pydantic" "pydantic-settings" "sqlalchemy" "uvicorn" "ruff" "pyright" "alembic")

for pkg in "${py_packages[@]}"; do
  latest=$(pip index versions "$pkg" 2>/dev/null | head -1 | grep -oP '\([\d.]+\)' | tr -d '()')
  echo "$pkg: $latest"
done
```

## How to Use

1. Run the audit script to get current latest versions
2. Compare against the "Documented Version" column
3. If a major version changed, research breaking changes
4. Update the affected skill file and this registry
