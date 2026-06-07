---
name: chat-ui-and-widget
description: >
  Chat interface and embeddable widget. ACTIVATE when: building the chat UI,
  implementing streaming message display, creating an embeddable widget for
  third-party sites, or handling mobile/accessibility for chat.
---

# Chat UI & Widget Skill

## When to Use
- Building the chat interface
- Implementing streaming message display
- Creating an embeddable chat widget
- Mobile responsiveness and accessibility

## useChat Hook (AI SDK v6)

> **AI SDK v6 note:** `useChat` lives in `@ai-sdk/react` (not `ai/react`). Messages are `UIMessage` (client) vs `ModelMessage` (server). `useChat` does not manage input state — keep your own input state and call `sendMessage()`.

```tsx
"use client"
import { useState } from "react"
import { useChat } from "@ai-sdk/react"

export function ChatPanel() {
  const {
    messages,       // UIMessage[] — client-side conversation state
    sendMessage,    // send a user message
    status,         // "ready" | "submitted" | "streaming" | "error"
    error,
    regenerate,     // retry last assistant message
    stop,           // cancel streaming
  } = useChat({
    api: "/api/chat",
    body: { conversationId },
    onError: (err) => console.error("Chat error:", err),
  })
  const [input, setInput] = useState("")
  const isLoading = status === "submitted" || status === "streaming"

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const text = input.trim()
    if (!text || isLoading) return
    sendMessage({ text })
    setInput("")
  }

  return (
    <div className="chat-container">
      <MessageList messages={messages} isLoading={isLoading} />
      <ChatInput
        input={input}
        onChange={(e) => setInput(e.currentTarget.value)}
        onSubmit={handleSubmit}
        isLoading={isLoading}
      />
    </div>
  )
}
```

## Message Components

```tsx
function MessageList({ messages, isLoading }) {
  const bottomRef = useRef<HTMLDivElement>(null)
  
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages])

  return (
    <div className="message-list" role="log" aria-live="polite">
      {messages.map(msg => (
        <MessageBubble key={msg.id} message={msg} />
      ))}
      {isLoading && <TypingIndicator />}
      <div ref={bottomRef} />
    </div>
  )
}

function MessageBubble({ message }) {
  const isUser = message.role === "user"
  const text = message.parts
    .filter(part => part.type === "text")
    .map(part => part.text)
    .join("")

  return (
    <div className={`message ${isUser ? "message--user" : "message--assistant"}`}>
      <div className="message__content">
        {isUser ? text : <Markdown>{text}</Markdown>}
      </div>
      {message.metadata?.sources && <SourceCitations sources={message.metadata.sources} />}
    </div>
  )
}

function TypingIndicator() {
  return (
    <div className="typing-indicator" aria-label="Assistant is typing">
      <span /><span /><span />
    </div>
  )
}
```

## Chat Input

```tsx
function ChatInput({ input, onChange, onSubmit, isLoading }) {
  return (
    <form onSubmit={onSubmit} className="chat-input">
      <textarea
        value={input}
        onChange={onChange}
        placeholder="Type a message..."
        disabled={isLoading}
        rows={1}
        onKeyDown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault()
            e.currentTarget.form?.requestSubmit()
          }
        }}
        aria-label="Chat message"
      />
      <button type="submit" disabled={isLoading || !input.trim()}>
        {isLoading ? "..." : "Send"}
      </button>
    </form>
  )
}
```

## Floating Widget

```tsx
function ChatWidget() {
  const [isOpen, setIsOpen] = useState(false)
  
  return (
    <>
      {isOpen && (
        <div className="chat-widget">
          <div className="chat-widget__header">
            <h2>Chat with us</h2>
            <button onClick={() => setIsOpen(false)} aria-label="Close chat">×</button>
          </div>
          <ChatPanel />
        </div>
      )}
      
      <button
        className="chat-widget__trigger"
        onClick={() => setIsOpen(!isOpen)}
        aria-label={isOpen ? "Close chat" : "Open chat"}
      >
        💬
      </button>
    </>
  )
}
```

## Widget CSS

```css
.chat-widget {
  position: fixed;
  bottom: 80px;
  right: 20px;
  width: 380px;
  height: 560px;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  z-index: 9999;
  background: var(--chat-bg, #fff);
}

.chat-widget__trigger {
  position: fixed;
  bottom: 20px;
  right: 20px;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: none;
  font-size: 24px;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(0,0,0,0.2);
  z-index: 9999;
}

@media (max-width: 480px) {
  .chat-widget {
    inset: 0;
    width: 100%;
    height: 100%;
    border-radius: 0;
  }
}
```

## Embed for Third-Party Sites

```html
<!-- Script tag embed -->
<script src="https://your-domain.com/widget.js" data-bot-id="abc123"></script>

<!-- Or iframe -->
<iframe
  src="https://your-domain.com/embed/chat?botId=abc123"
  style="position:fixed;bottom:0;right:0;width:400px;height:600px;border:none;"
  allow="clipboard-write"
></iframe>
```

## Accessibility Checklist
- [x] `role="log"` on message container
- [x] `aria-live="polite"` for new messages
- [x] `aria-label` on all buttons
- [x] Keyboard: Enter to send, Shift+Enter for newline
- [x] Focus trap in widget when open
- [x] Escape to close widget
- [x] High contrast text in bubbles
- [x] Reduced motion for typing indicator

## References
- `references/widget-embed.md` — cross-origin, postMessage, theming
- `references/streaming-patterns.md` — SSE display patterns

## NEVER
- ❌ Auto-open widget on page load (annoying)
- ❌ Block scrolling on the page when widget is open
- ❌ Skip mobile full-screen treatment
- ❌ Render raw HTML from LLM (XSS risk — use Markdown renderer)
