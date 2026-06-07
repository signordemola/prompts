#!/bin/bash
# Run: bash references/check-versions.sh

echo "=== Checking npm packages ==="
packages=(
  "next" "react" "zod" "@tanstack/react-query" "ai" "@ai-sdk/react"
  "prisma" "drizzle-orm" "drizzle-kit" "@nestjs/core" "zustand" "vitest"
  "tailwindcss" "react-hook-form" "uploadthing" "@playwright/test"
  "hono" "react-email" "resend" "stripe" "dayjs"
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
