---
name: tool-calling
description: >
  LLM function/tool calling. ACTIVATE when: defining tools for the chatbot to call
  (order lookup, booking check, etc.), implementing structured output, building
  multi-step agent workflows, or handling tool security.
---

# Tool Calling Skill

## When to Use
- Giving the chatbot actions (look up orders, check bookings, etc.)
- Getting structured JSON responses
- Building multi-step agent workflows

## Defining Tools

```ts
import { tool } from "ai"
import { z } from "zod"

export const chatTools = {
  getOrderStatus: tool({
    description: "Look up the status and tracking info for a customer order",
    parameters: z.object({
      orderNumber: z.number().describe("The order number, e.g. 1042"),
    }),
    execute: async ({ orderNumber }) => {
      const order = await prisma.order.findFirst({
        where: { orderNumber },
        include: { fulfillments: true },
      })
      if (!order) return { error: "Order not found" }
      return {
        status: order.status,
        total: formatCurrency(order.total, "UK"),
        tracking: order.fulfillments[0]?.trackingNumber ?? null,
        carrier: order.fulfillments[0]?.carrier ?? null,
      }
    },
  }),

  checkAvailability: tool({
    description: "Check available appointment slots for a service on a specific date",
    parameters: z.object({
      serviceSlug: z.string().describe("The service slug, e.g. classic-lash"),
      date: z.string().describe("Date in YYYY-MM-DD format"),
    }),
    execute: async ({ serviceSlug, date }) => {
      const slots = await getAvailableSlots(serviceSlug, date)
      return { date, availableSlots: slots.map(s => format(s, "HH:mm")) }
    },
  }),

  getProductInfo: tool({
    description: "Get details about a product including price and availability",
    parameters: z.object({
      productSlug: z.string().describe("The product URL slug"),
    }),
    execute: async ({ productSlug }) => {
      const product = await prisma.product.findUnique({
        where: { slug: productSlug },
        include: { variants: { where: { isActive: true } } },
      })
      if (!product) return { error: "Product not found" }
      return {
        name: product.name,
        description: product.description,
        variants: product.variants.map(v => ({
          name: v.name,
          price: formatCurrency(v.priceGBP, "UK"),
          inStock: v.inventoryQuantity > 0,
        })),
      }
    },
  }),

  createSupportTicket: tool({
    description: "Escalate to human support when the bot cannot resolve the issue",
    parameters: z.object({
      subject: z.string().describe("Brief summary of the issue"),
      customerEmail: z.email().describe("Customer's email address"),
    }),
    execute: async ({ subject, customerEmail }) => {
      const ticket = await prisma.supportTicket.create({
        data: { conversationId, subject, customerEmail },
      })
      return { ticketId: ticket.id, message: "A support agent will contact you within 24 hours." }
    },
  }),
}
```

## Using Tools in streamText

```ts
const result = streamText({
  model: getModel("standard"),
  system: SYSTEM_PROMPT,
  messages,
  tools: chatTools,
  maxSteps: 5,  // allow up to 5 tool calls per request
  onFinish: async ({ text, toolCalls, usage }) => {
    await saveMessages(conversationId, userContent, text, usage)
  },
})
```

## Structured Output

```ts
import { generateObject } from "ai"

// When you need JSON, not natural language
const { object } = await generateObject({
  model: getModel("standard"),
  schema: z.object({
    intent: z.enum(["order_query", "booking_query", "product_query", "general", "escalate"]),
    confidence: z.number().min(0).max(1),
    entities: z.object({
      orderNumber: z.number().optional(),
      productName: z.string().optional(),
      date: z.string().optional(),
    }),
  }),
  prompt: `Classify this user message: "${userMessage}"`,
})
```

## Tool Design Rules

| Rule | Why |
|------|-----|
| Small, composable tools | Easier for model to choose correctly |
| Clear descriptions | Model decides tool selection from description |
| Zod validation on inputs | Prevents malformed calls |
| Read-only by default | Write tools need explicit user confirmation |
| Return structured data | Let the model format for the user |
| Handle errors in tool | Return `{ error: "..." }` not throw |

## Security

```ts
// Write tools: require confirmation
const dangerousTools = {
  cancelOrder: tool({
    description: "Cancel an order. ONLY use after explicit user confirmation.",
    parameters: z.object({
      orderNumber: z.number(),
      confirmCancellation: z.boolean().describe("Must be true to proceed"),
    }),
    execute: async ({ orderNumber, confirmCancellation }) => {
      if (!confirmCancellation) return { error: "Please confirm cancellation first" }
      // proceed...
    },
  }),
}
```

## References
- `references/edge-cases.md` — agent loops, tool errors
- `references/testing-patterns.md` — mocking tool calls

## NEVER
- ❌ Give tools direct DB write access without validation
- ❌ Use vague tool descriptions (model can't choose correctly)
- ❌ Skip `maxSteps` (risk of infinite tool loops)
- ❌ Expose internal IDs to users (use human-readable identifiers)
- ❌ Let tools throw errors (always return error objects)
