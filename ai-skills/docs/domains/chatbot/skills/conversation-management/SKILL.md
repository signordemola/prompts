---
name: conversation-management
description: >
  Conversation persistence and state. ACTIVATE when: storing chat history,
  managing sessions, implementing multi-turn conversations, injecting user
  context, or building conversation lists/sidebar.
---

# Conversation Management Skill

## When to Use
- Persisting chat history to database
- Managing user sessions (anonymous + authenticated)
- Injecting user-specific context into conversations
- Building conversation UI (sidebar, history)

## Conversation Lifecycle

```
User opens widget → Session created → Conversation created
  → Messages exchanged → Persisted on each turn
  → User closes widget → Conversation remains (resumable)
  → 30 days idle → Auto-archive
```

## Session Management

```ts
// Anonymous users: session cookie
function getOrCreateSession(cookies: ReadonlyRequestCookies): string {
  let sessionId = cookies.get("chat-session")?.value
  if (!sessionId) {
    sessionId = crypto.randomUUID()
    cookies.set("chat-session", sessionId, {
      httpOnly: true,
      secure: true,
      sameSite: "lax",
      maxAge: 60 * 60 * 24 * 30, // 30 days
    })
  }
  return sessionId
}

// Authenticated users: merge on login (same as cart merge pattern)
async function mergeConversations(sessionId: string, userId: string) {
  await prisma.conversation.updateMany({
    where: { sessionId, userId: null },
    data: { userId, sessionId: null },
  })
}
```

## Message Persistence

```ts
// Save on streamText's onFinish callback
async function saveMessages(
  conversationId: string,
  userContent: string,
  assistantContent: string,
  usage: { promptTokens: number; completionTokens: number },
  model: string,
  sources?: RagSource[]
) {
  await prisma.message.createMany({
    data: [
      {
        conversationId,
        role: "user",
        content: userContent,
      },
      {
        conversationId,
        role: "assistant",
        content: assistantContent,
        model,
        inputTokens: usage.promptTokens,
        outputTokens: usage.completionTokens,
        sources: sources ? JSON.stringify(sources) : null,
      },
    ],
  })
  
  // Update conversation timestamp
  await prisma.conversation.update({
    where: { id: conversationId },
    data: { updatedAt: new Date() },
  })
}
```

## Loading History

```ts
// GET /api/conversations/[id]/messages
async function getConversationMessages(conversationId: string) {
  return prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: "asc" },
    select: {
      id: true,
      role: true,
      content: true,
      sources: true,
      createdAt: true,
    },
  })
}

// For API context: only pass role + content (not metadata)
function toApiMessages(messages: Message[]): CoreMessage[] {
  return messages
    .filter(m => m.role !== "system") // system prompt injected separately
    .map(m => ({ role: m.role, content: m.content }))
}
```

## Dynamic Context Injection

```ts
// Inject user-specific data into system prompt
function buildSystemPrompt(user?: User, context?: PageContext): string {
  let prompt = BASE_SYSTEM_PROMPT
  
  if (user) {
    prompt += `\n\nUser context:
- Name: ${user.name}
- Email: ${user.email}
- Account created: ${user.createdAt}
- Total orders: ${user.orderCount}`
  }
  
  if (context?.currentPage) {
    prompt += `\n\nThe user is currently on: ${context.currentPage}`
  }
  
  return prompt
}
```

## Auto-Title Generation

```ts
// Generate title from first user message
async function generateTitle(firstMessage: string): Promise<string> {
  const { text } = await generateText({
    model: getModel("fast"),
    prompt: `Summarise this message in 5 words or less as a conversation title. No quotes.\n\n"${firstMessage}"`,
    maxTokens: 20,
  })
  return text.trim()
}
```

## Conversation Cleanup

```ts
// Cron: archive old conversations
await prisma.conversation.updateMany({
  where: {
    updatedAt: { lt: subDays(new Date(), 30) },
    status: "ACTIVE",
  },
  data: { status: "ARCHIVED" },
})
```

## References
- `references/database-schema.md` — Conversation, Message models

## NEVER
- ❌ Store messages only on the client (DB is source of truth)
- ❌ Send all history to LLM without truncation
- ❌ Expose conversation IDs in URLs without auth check
- ❌ Hard-delete conversations (archive instead)
