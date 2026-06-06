---
name: playwright
description: >
  E2E testing with Playwright. ACTIVATE when: writing end-to-end tests,
  testing user flows, setting up CI test pipelines, or mocking API responses
  in browser tests. Covers locators, assertions, auth, and Page Object Model.
---

# Playwright Skill

## When to Use
- Writing end-to-end tests for Next.js apps
- Testing user-facing flows (booking, checkout, auth)
- Setting up E2E tests in CI
- Mocking network requests in browser tests

## Setup

```bash
npm init playwright@latest
```

For Next.js:

```bash
pnpm create next-app --example with-playwright
```

## Config

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test"

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "mobile", use: { ...devices["iPhone 14"] } },
  ],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
})
```

## Locators

ALWAYS use semantic locators:

```ts
page.getByRole("button", { name: "Book Now" })
page.getByLabel("Email address")
page.getByPlaceholder("Search services...")
page.getByText("Booking confirmed")
page.getByTestId("booking-calendar")
```

## Basic Test

```ts
import { test, expect } from "@playwright/test"

test("user can view services", async ({ page }) => {
  await page.goto("/services")

  await expect(page.getByRole("heading", { name: "Our Services" })).toBeVisible()
  await expect(page.getByRole("article")).toHaveCount(5)
})
```

## Form Test

```ts
test("user can submit booking form", async ({ page }) => {
  await page.goto("/book")

  await page.getByLabel("Name").fill("Jane Smith")
  await page.getByLabel("Email").fill("jane@example.com")
  await page.getByRole("button", { name: "Next" }).click()

  await page.getByRole("combobox", { name: "Service" }).selectOption("Lash Lift")
  await page.getByRole("button", { name: "Confirm" }).click()

  await expect(page.getByText("Booking confirmed")).toBeVisible()
})
```

## API Mocking

```ts
test("handles API errors gracefully", async ({ page }) => {
  await page.route("**/api/services", (route) =>
    route.fulfill({
      status: 500,
      contentType: "application/json",
      body: JSON.stringify({ error: "Server error" }),
    })
  )

  await page.goto("/services")

  await expect(page.getByText("Something went wrong")).toBeVisible()
})

test("mocks service data", async ({ page }) => {
  await page.route("**/api/services", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        { id: "1", name: "Lash Lift", price: 4500 },
      ]),
    })
  )

  await page.goto("/services")
  await expect(page.getByText("Lash Lift")).toBeVisible()
})
```

## Auth Setup

```ts
// e2e/auth.setup.ts
import { test as setup, expect } from "@playwright/test"

const authFile = "e2e/.auth/user.json"

setup("authenticate", async ({ page }) => {
  await page.goto("/login")
  await page.getByLabel("Email").fill("owner@studio.com")
  await page.getByLabel("Password").fill("password123")
  await page.getByRole("button", { name: "Sign in" }).click()

  await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible()

  await page.context().storageState({ path: authFile })
})
```

```ts
// playwright.config.ts — add to projects
{
  name: "setup",
  testMatch: /.*\.setup\.ts/,
},
{
  name: "authenticated",
  use: { storageState: "e2e/.auth/user.json" },
  dependencies: ["setup"],
},
```

## Page Object Model

```ts
// e2e/pages/booking.page.ts
import { type Page, type Locator } from "@playwright/test"

export class BookingPage {
  readonly nameInput: Locator
  readonly emailInput: Locator
  readonly submitButton: Locator

  constructor(readonly page: Page) {
    this.nameInput = page.getByLabel("Name")
    this.emailInput = page.getByLabel("Email")
    this.submitButton = page.getByRole("button", { name: "Confirm" })
  }

  goto = async () => {
    await this.page.goto("/book")
  }

  fillContact = async (name: string, email: string) => {
    await this.nameInput.fill(name)
    await this.emailInput.fill(email)
  }

  submit = async () => {
    await this.submitButton.click()
  }
}
```

## CI Sharding

```bash
npx playwright test --shard=1/3
npx playwright test --shard=2/3
npx playwright test --shard=3/3
```

## NEVER
- ❌ Use CSS selectors or XPath (use `getByRole`, `getByLabel`, `getByText`)
- ❌ Use `waitForTimeout` (use web-first assertions that auto-retry)
- ❌ Share state between tests (each test gets a fresh context)
- ❌ Test implementation details (test user-facing behavior)
- ❌ Hardcode URLs (use `baseURL` from config)
