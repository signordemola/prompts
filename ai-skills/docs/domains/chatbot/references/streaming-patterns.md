# Streaming Patterns

## SSE with AI SDK v5

```ts
// Server: streamText returns a ReadableStream
import { convertToModelMessages, streamText } from "ai"

export async function POST(req: Request) {
  const { messages } = await req.json()
  
  const result = streamText({
    model: getModel("standard"),
    messages: convertToModelMessages(messages),
    onFinish: async ({ text, usage }) => {
      await saveMessages(conversationId, text, usage)
    },
  })
  
  // Returns AI SDK UI message stream response
  return result.toUIMessageStreamResponse()
}
```

## Client: useChat handles everything (AI SDK v5)

```tsx
import { useState } from "react"
import { useChat } from "@ai-sdk/react"

const { messages, sendMessage, status, stop, regenerate, error } = useChat()
const [input, setInput] = useState("")

function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault()
  if (!input.trim()) return
  sendMessage({ text: input })
  setInput("")
}

// status = "ready" | "submitted" | "streaming" | "error"
// messages auto-update as UIMessage parts arrive
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
const { messages, regenerate, error } = useChat()  // from @ai-sdk/react

{error && (
  <div className="error">
    <p>Something went wrong.</p>
    <button onClick={() => regenerate()}>Retry</button>
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
