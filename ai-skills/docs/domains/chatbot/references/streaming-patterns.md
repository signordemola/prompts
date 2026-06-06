# Streaming Patterns

## SSE with Vercel AI SDK

```ts
// Server: streamText returns a ReadableStream
import { streamText } from "ai"

export async function POST(req: Request) {
  const { messages } = await req.json()
  
  const result = streamText({
    model: getModel("standard"),
    messages,
    onFinish: async ({ text, usage }) => {
      await saveMessages(conversationId, text, usage)
    },
  })
  
  // Returns SSE-formatted response
  return result.toDataStreamResponse()
}
```

## Client: useChat handles everything

```tsx
const { messages, input, handleInputChange, handleSubmit, isLoading, stop } = useChat()

// isLoading = true while streaming
// messages auto-update as chunks arrive
// stop() cancels the stream mid-response
```

## Manual SSE (without Vercel AI SDK)

```ts
// Server
export async function POST(req: Request) {
  const encoder = new TextEncoder()
  const stream = new ReadableStream({
    async start(controller) {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages,
        stream: true,
      })
      
      for await (const chunk of response) {
        const text = chunk.choices[0]?.delta?.content ?? ""
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text })}\n\n`))
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"))
      controller.close()
    },
  })
  
  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    },
  })
}

// Client
const eventSource = new EventSource("/api/chat")
eventSource.onmessage = (event) => {
  if (event.data === "[DONE]") { eventSource.close(); return }
  const { text } = JSON.parse(event.data)
  appendToMessage(text)
}
```

## Error Recovery During Stream

```ts
// If stream breaks mid-response:
const { messages, reload, error } = useChat()

{error && (
  <div className="error">
    <p>Something went wrong.</p>
    <button onClick={reload}>Retry</button>
  </div>
)}
```

## Stream vs Wait Decision

| Response type | Stream? | Why |
|--------------|---------|-----|
| Natural language chat | ✅ Yes | Feels conversational |
| Tool call results | ❌ No | Wait for complete data |
| Structured JSON | ❌ No | Parse after complete |
| Long explanations | ✅ Yes | Reduces perceived latency |
