# Analytics & Observability

## Key Metrics

| Metric | Formula | Good benchmark |
|--------|---------|---------------|
| **Containment rate** | Sessions resolved without human / Total | > 80% |
| **Resolution rate** | Issues fully resolved / Total | > 70% |
| **Escalation rate** | Tickets created / Total sessions | < 15% |
| **CSAT** | Positive ratings / Total ratings | > 85% |
| **Avg response time** | Mean latency per response | < 3s |
| **Cost per conversation** | Total LLM spend / Conversations | < $0.05 |

## Feedback Collection

```tsx
// Thumbs up/down after each assistant message
function FeedbackButtons({ messageId, conversationId }) {
  const [submitted, setSubmitted] = useState(false)
  
  async function submitFeedback(rating: "positive" | "negative") {
    await fetch("/api/feedback", {
      method: "POST",
      body: JSON.stringify({ conversationId, messageId, rating }),
    })
    setSubmitted(true)
  }
  
  if (submitted) return <span className="feedback-thanks">Thanks!</span>
  
  return (
    <div className="feedback-buttons">
      <button onClick={() => submitFeedback("positive")} aria-label="Helpful">👍</button>
      <button onClick={() => submitFeedback("negative")} aria-label="Not helpful">👎</button>
    </div>
  )
}
```

## Dashboard Queries

```ts
// Conversations today
const today = await prisma.conversation.count({
  where: { createdAt: { gte: startOfDay(new Date()) } },
})

// Containment rate (no escalation)
const total = await prisma.conversation.count({ where: { createdAt: { gte: startOfMonth } } })
const escalated = await prisma.supportTicket.count({ where: { createdAt: { gte: startOfMonth } } })
const containmentRate = ((total - escalated) / total * 100).toFixed(1)

// CSAT
const feedback = await prisma.feedback.groupBy({
  by: ["rating"],
  where: { createdAt: { gte: startOfMonth } },
  _count: true,
})

// Cost this month
const cost = await prisma.usageLog.aggregate({
  where: { createdAt: { gte: startOfMonth } },
  _sum: { costMicro: true, totalTokens: true },
})
const costUSD = (cost._sum.costMicro ?? 0) / 100_000_000

// Top unanswered questions (negative feedback)
const poorResponses = await prisma.feedback.findMany({
  where: { rating: "negative", createdAt: { gte: startOfMonth } },
  include: { conversation: { include: { messages: { take: 2 } } } },
  orderBy: { createdAt: "desc" },
  take: 20,
})
```

## LLM Observability (Langfuse v5)

> **Langfuse v5:** Observation-centric data model built on OpenTelemetry. Uses `LangfuseSpanProcessor` instead of manual `trace()`/`span()` calls.

```ts
// Option 1: OpenTelemetry integration (recommended for v5)
import { NodeSDK } from "@opentelemetry/sdk-node"
import { LangfuseSpanProcessor } from "langfuse"

const sdk = new NodeSDK({
  spanProcessors: [new LangfuseSpanProcessor()],
})
sdk.start()
// All AI SDK calls are now automatically traced

// Option 2: Manual tracing (still works in v5)
import { Langfuse } from "langfuse"

const langfuse = new Langfuse({
  publicKey: process.env.LANGFUSE_PUBLIC_KEY,
  secretKey: process.env.LANGFUSE_SECRET_KEY,
})

const trace = langfuse.trace({ name: "chat-turn", userId, sessionId: conversationId })
const span = trace.span({ name: "llm-call", input: messages })
span.end({ output: response, usage: { input: promptTokens, output: completionTokens } })
```
