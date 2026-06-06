---
name: llm-integration
description: >
  LLM provider integration and streaming. ACTIVATE when: connecting to OpenAI/Anthropic/Google,
  implementing streaming responses, managing context windows, routing between models,
  or handling token budgets and costs.
---

# LLM Integration Skill

## When to Use
- Connecting to LLM providers
- Implementing streaming chat responses
- Managing context windows and token limits
- Choosing/routing between models

## Provider Abstraction (Vercel AI SDK)

```ts
// lib/ai.ts — single entry point, swap via env var
import { openai } from "@ai-sdk/openai"
import { anthropic } from "@ai-sdk/anthropic"
import { google } from "@ai-sdk/google"

const MODELS = {
  fast: openai("gpt-4o-mini"),           // cheap, fast, simple tasks
  standard: openai("gpt-4o"),             // balanced
  reasoning: anthropic("claude-sonnet-4-20250514"), // complex reasoning
  longContext: google("gemini-2.0-flash"), // massive context
} as const

export function getModel(tier: keyof typeof MODELS = "standard") {
  return MODELS[tier]
}
```

**Rule:** Never import provider SDKs directly in route handlers. Always go through `lib/ai.ts`.

## Streaming Response

```ts
// app/api/chat/route.ts
import { streamText } from "ai"

export async function POST(req: Request) {
  const { messages, conversationId } = await req.json()
  
  const result = streamText({
    model: getModel("standard"),
    system: SYSTEM_PROMPT,
    messages,
    maxTokens: 1024,
    onFinish: async ({ text, usage }) => {
      // Persist messages AFTER stream completes
      await saveMessages(conversationId, messages, text, usage)
      await logUsage(usage, "chat")
    },
  })
  
  return result.toDataStreamResponse()
}
```

## Model Routing Decision

| Task complexity | Model | Cost | Why |
|----------------|-------|------|-----|
| FAQ, simple answers | gpt-4o-mini / Haiku | ~$0.0001/msg | Fast, cheap |
| General chat, tool use | gpt-4o / Sonnet | ~$0.005/msg | Balanced |
| Complex reasoning, code | Claude Opus / o1 | ~$0.05/msg | Accuracy |
| Long docs (>100k tokens) | Gemini Flash | ~$0.001/msg | 1M+ context |

```ts
// Simple routing by conversation length or intent
function selectModel(messages: Message[]): ModelTier {
  const lastMessage = messages[messages.length - 1].content
  if (messages.length <= 2) return "fast"           // first exchange
  if (lastMessage.length > 2000) return "longContext" // large input
  return "standard"                                    // default
}
```

## Context Window Management

```ts
// Strategy: sliding window with system prompt protection
function buildContext(
  systemPrompt: string,
  history: Message[],
  ragChunks: string[],
  maxTokens: number = 8000
): Message[] {
  const messages: Message[] = [{ role: "system", content: systemPrompt }]
  
  // RAG context (high priority — always include)
  if (ragChunks.length > 0) {
    messages.push({
      role: "system",
      content: `Relevant context:\n${ragChunks.join("\n\n")}`,
    })
  }
  
  // History: keep recent, summarise old
  const recentHistory = history.slice(-20)  // last 20 messages
  let tokenCount = estimateTokens(messages)
  
  for (const msg of recentHistory.reverse()) {
    const msgTokens = estimateTokens([msg])
    if (tokenCount + msgTokens > maxTokens) break
    messages.splice(1, 0, msg) // insert after system prompt
    tokenCount += msgTokens
  }
  
  return messages
}

function estimateTokens(messages: Message[]): number {
  // ~4 chars per token (rough estimate)
  return messages.reduce((sum, m) => sum + Math.ceil(m.content.length / 4), 0)
}
```

## Error Handling

```ts
import { streamText } from "ai"

try {
  const result = streamText({ model, messages })
  return result.toDataStreamResponse()
} catch (error) {
  if (error.status === 429) {
    // Rate limited — try fallback model
    const fallback = streamText({ model: getModel("fast"), messages })
    return fallback.toDataStreamResponse()
  }
  if (error.status === 500) {
    // Provider down — graceful message
    return NextResponse.json({
      error: "I'm having trouble right now. Please try again in a moment."
    }, { status: 503 })
  }
  throw error
}
```

## References
- `references/provider-comparison.md` — pricing, limits, strengths per provider
- `references/streaming-patterns.md` — SSE, ReadableStream, error recovery

## NEVER
- ❌ Import provider SDKs directly in route handlers (use `lib/ai.ts`)
- ❌ Hardcode model names in components
- ❌ Send unbounded history to the API (always truncate)
- ❌ Skip `onFinish` persistence (messages lost on error)
- ❌ Expose API keys to the client
