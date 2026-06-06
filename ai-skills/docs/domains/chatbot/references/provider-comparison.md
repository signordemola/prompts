# Provider Comparison

## Model Comparison (June 2026)

| Model | Context | Input $/1M | Output $/1M | Strengths |
|-------|---------|-----------|------------|-----------|
| **GPT-4o** | 128k | $2.50 | $10.00 | Balanced, great tool calling, wide ecosystem |
| **GPT-4o-mini** | 128k | $0.15 | $0.60 | Cheapest, fast, good for simple tasks |
| **Claude Sonnet 4** | 200k | $3.00 | $15.00 | Best reasoning, coding, lowest hallucination |
| **Claude Haiku 3.5** | 200k | $0.80 | $4.00 | Fast + cheap Anthropic option |
| **Gemini 2.0 Flash** | 1M | $0.10 | $0.40 | Massive context, multimodal, cheapest |

## When to Use Each

| Use case | Best model | Why |
|----------|-----------|-----|
| Customer support chatbot | GPT-4o | Reliable, good tool calling |
| Code assistance | Claude Sonnet | Best code understanding |
| FAQ / simple questions | GPT-4o-mini | Cheap, fast, good enough |
| Long document Q&A | Gemini Flash | 1M context window |
| Sensitive / compliance | Claude Sonnet | Lowest hallucination rate |

## Rate Limits (Default Tiers)

| Provider | Requests/min | Tokens/min |
|----------|-------------|-----------|
| OpenAI (Tier 1) | 500 | 200,000 |
| Anthropic (Build) | 1,000 | 400,000 |
| Google (Free) | 15 | 1,000,000 |

## Embedding Models

| Model | Dimensions | $/1M tokens | Best for |
|-------|-----------|------------|---------|
| `text-embedding-3-small` | 1536 | $0.02 | Default, demos |
| `text-embedding-3-large` | 3072 | $0.13 | Higher accuracy |
| Gemini Embedding | 768 | $0.00 (free tier) | Budget |

## Multi-Provider Setup

```ts
// .env
AI_PROVIDER=openai           // or "anthropic" or "google"
AI_MODEL=gpt-4o              // specific model
AI_FALLBACK_PROVIDER=anthropic
AI_FALLBACK_MODEL=claude-3-5-haiku

// lib/ai.ts
const providers = {
  openai: (model: string) => openai(model),
  anthropic: (model: string) => anthropic(model),
  google: (model: string) => google(model),
}

export function getModel() {
  return providers[process.env.AI_PROVIDER](process.env.AI_MODEL)
}
```
