---
name: project-scripts
description: >
  Project scripts, git hooks, and quality gates. ACTIVATE when: setting up
  package.json scripts, Husky git hooks, pre-commit, lint-staged, typecheck,
  or CI quality checks. Covers Next.js, NestJS, FastAPI, and monorepo setups.
---

# Project Scripts Skill

## When to Use
- Setting up a new project's package.json scripts
- Adding Husky git hooks
- Configuring lint, typecheck, or format scripts
- Setting up predev/prebuild lifecycle scripts
- Adding CI quality gates

## Next.js Scripts

```json
{
  "scripts": {
    "predev": "prisma generate",
    "dev": "next dev --turbopack",
    "prebuild": "prisma generate",
    "build": "next build",
    "start": "next start",
    "lint": "oxlint .",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio",
    "db:seed": "tsx prisma/seed.ts"
  }
}
```

## Turborepo Monorepo Scripts

```json
{
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "typecheck": "turbo typecheck",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,md}\""
  }
}
```

Per-package scripts follow the same pattern (each app/package has its own `lint`, `typecheck`, `build`).

## Husky + lint-staged

```bash
npx husky init
npm install -D lint-staged
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "oxlint --fix",
      "prettier --write"
    ],
    "*.{json,md,css}": [
      "prettier --write"
    ]
  }
}
```

```bash
# .husky/pre-commit
npx lint-staged
```

```bash
# .husky/pre-push
npm run typecheck
npm run test
```

## FastAPI Scripts (pyproject.toml)

```toml
[project.scripts]
dev = "uvicorn app.main:app --reload --port 8000"

[tool.ruff]
target-version = "py312"
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "RUF"]

[tool.pyright]
venvPath = "."
venv = ".venv"
typeCheckingMode = "strict"
```

```bash
uv run ruff check --fix .
uv run ruff format .
uv run pyright app
uv run pytest
```

### FastAPI pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.11.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: local
    hooks:
      - id: pyright
        name: pyright
        entry: uv run pyright app
        language: system
        types: [python]
        pass_filenames: false
```

```bash
pip install pre-commit
pre-commit install
```

## NestJS Scripts

```json
{
  "scripts": {
    "dev": "nest start --watch",
    "build": "nest build",
    "start": "node dist/main",
    "lint": "oxlint .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "vitest run --config vitest.e2e.config.ts"
  }
}
```

## CI Quality Gate (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm build
      - run: pnpm test
```

## NEVER
- ❌ Skip `prisma generate` in prebuild (causes build failures)
- ❌ Run `tsc` without `--noEmit` for type checking (it will emit files)
- ❌ Use `eslint` when `oxlint` is available (faster, fewer configs)
- ❌ Commit without running lint-staged (set up Husky)
- ❌ Skip typecheck in CI (catches errors that tests miss)
