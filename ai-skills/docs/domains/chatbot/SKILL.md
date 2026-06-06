---
name: chatbot-platform
description: >
  AI chatbot platform orchestrator. ACTIVATE when: building any chatbot feature.
  This skill routes you to the right sub-skill based on what you're implementing.
  Covers LLM integration, RAG, tool calling, chat UI, and safety.
---

# Chatbot Platform Domain Skill

## When to Use
- Building a new AI chatbot (customer support, knowledge assistant, etc.)
- Any chatbot-specific feature

## Pre-Requisites — Always Load First
- `docs/skills/prisma-database/SKILL.md` (or `docs/skills/drizzle-database/SKILL.md` if using Drizzle)
- Load the framework skill matching your project's stack:
  - Next.js → `docs/skills/nextjs-app-router/SKILL.md`
  - NestJS → `docs/skills/nestjs/SKILL.md`
  - FastAPI → `docs/skills/fastapi/SKILL.md`

## Sub-Skill Routing

| When you're working on... | Load sub-skill |
|--------------------------|---------------|
| LLM providers, streaming, model routing, context windows | `skills/llm-integration/SKILL.md` |
| Chat history, sessions, persistence, multi-turn state | `skills/conversation-management/SKILL.md` |
| Document ingestion, embeddings, vector search, RAG | `skills/rag-and-knowledge/SKILL.md` |
| Function calling, tools, structured output, agents | `skills/tool-calling/SKILL.md` |
| Chat interface, widget, message UI, mobile, a11y | `skills/chat-ui-and-widget/SKILL.md` |
| Moderation, rate limiting, cost, prompt injection, escalation | `skills/safety-and-ops/SKILL.md` |

## Reference Files

| Reference | Read when... |
|-----------|-------------|
| `references/database-schema.md` | Designing or modifying the DB schema |
| `references/streaming-patterns.md` | SSE, ReadableStream, error recovery |
| `references/prompt-engineering.md` | System prompts, few-shot, persona design |
| `references/rag-pipeline.md` | Chunking, embedding, retrieval, reranking |
| `references/provider-comparison.md` | Choosing models, pricing, rate limits |
| `references/widget-embed.md` | Embedding chat on third-party sites |
| `references/human-handoff.md` | Escalation triggers, ticket creation |
| `references/analytics-observability.md` | CSAT, containment, cost tracking, Langfuse |
| `references/edge-cases.md` | Token overflow, hallucination, injection, loops |
| `references/testing-patterns.md` | Mocking LLMs, golden sets, tool testing |

## Shared With Other Domains

| Topic | Cross-reference |
|-------|---------------|
| Data privacy / GDPR | `../booking/references/data-privacy.md` |
| Multi-currency | `../booking/references/multi-currency.md` |
| Accessibility | `../booking/references/accessibility-walkins.md` |
| API design | `../booking/references/api-design.md` |

## End-to-End Chat Flow

```
1. User opens widget → session created (cookie or userId)
2. User types message → POST /api/chat
3. API route:
   a. Sanitise input (injection check, length limit)
   b. Rate limit check (per-user, per-IP)
   c. Load conversation history from DB
   d. If RAG: embed query → retrieve chunks → inject into context
   e. Build messages: [system prompt, RAG context, history, user message]
   f. streamText() → SSE to client
   g. onFinish → save messages + log usage
4. Client renders streaming response with typing indicator
5. If tool call: model requests tool → execute → feed result → continue
6. User can: rate response (👍/👎), continue, start new conversation
```

## Full Coverage (30 Sections)

| # | Topic | Location |
|---|-------|---------|
| 1 | Provider abstraction (OpenAI/Anthropic/Google) | `skills/llm-integration` |
| 2 | Model routing (fast/standard/reasoning) | `skills/llm-integration` |
| 3 | Streaming responses (SSE) | `skills/llm-integration` |
| 4 | Context window management | `skills/llm-integration` |
| 5 | Token budgeting & cost tracking | `skills/llm-integration` |
| 6 | Error handling & provider fallback | `skills/llm-integration` |
| 7 | Conversation persistence (DB) | `skills/conversation-management` |
| 8 | Session management (cookie/userId) | `skills/conversation-management` |
| 9 | Multi-turn state & context injection | `skills/conversation-management` |
| 10 | Auto-title generation | `skills/conversation-management` |
| 11 | Document ingestion pipeline | `skills/rag-and-knowledge` |
| 12 | Chunking strategy | `skills/rag-and-knowledge` |
| 13 | Embedding models | `skills/rag-and-knowledge` |
| 14 | Vector storage (pgvector) | `skills/rag-and-knowledge` |
| 15 | Similarity search & hybrid retrieval | `skills/rag-and-knowledge` |
| 16 | Source citations | `skills/rag-and-knowledge` |
| 17 | Tool definition (Zod schemas) | `skills/tool-calling` |
| 18 | Domain tools (orders, bookings, products) | `skills/tool-calling` |
| 19 | Structured output (generateObject) | `skills/tool-calling` |
| 20 | Multi-step agents & stop conditions | `skills/tool-calling` |
| 21 | useChat hook & message components | `skills/chat-ui-and-widget` |
| 22 | Typing indicator & auto-scroll | `skills/chat-ui-and-widget` |
| 23 | Floating widget & embed | `skills/chat-ui-and-widget` |
| 24 | Mobile responsive & accessibility | `skills/chat-ui-and-widget` |
| 25 | Input sanitisation & injection prevention | `skills/safety-and-ops` |
| 26 | System prompt protection | `skills/safety-and-ops` |
| 27 | Rate limiting | `skills/safety-and-ops` |
| 28 | Cost management & budget alerts | `skills/safety-and-ops` |
| 29 | Content moderation | `skills/safety-and-ops` |
| 30 | Human escalation | `skills/safety-and-ops` |
