# Widget Embedding

## Script Tag Embed

```ts
// public/widget.js — lightweight loader
(function() {
  const config = document.currentScript.dataset
  const iframe = document.createElement("iframe")
  iframe.src = `${config.origin || "https://your-domain.com"}/embed/chat?botId=${config.botId}`
  iframe.style.cssText = "position:fixed;bottom:0;right:0;width:0;height:0;border:none;z-index:99999;"
  iframe.allow = "clipboard-write"
  document.body.appendChild(iframe)
  
  // Toggle button
  const btn = document.createElement("button")
  btn.innerHTML = "💬"
  btn.style.cssText = "position:fixed;bottom:20px;right:20px;width:56px;height:56px;border-radius:50%;border:none;font-size:24px;cursor:pointer;z-index:99999;box-shadow:0 4px 16px rgba(0,0,0,0.2);"
  btn.onclick = () => {
    const isOpen = iframe.style.width !== "0px"
    iframe.style.width = isOpen ? "0px" : "400px"
    iframe.style.height = isOpen ? "0px" : "600px"
    iframe.style.bottom = isOpen ? "0" : "80px"
    iframe.style.right = isOpen ? "0" : "20px"
    iframe.style.borderRadius = "16px"
  }
  document.body.appendChild(btn)
})()
```

```html
<!-- Usage on any website -->
<script src="https://your-domain.com/widget.js" data-bot-id="abc123"></script>
```

## Cross-Origin Communication

```ts
// Parent page ↔ iframe communication via postMessage

// From widget (iframe):
window.parent.postMessage({ type: "chat:open" }, "*")
window.parent.postMessage({ type: "chat:close" }, "*")
window.parent.postMessage({ type: "chat:resize", height: 600 }, "*")

// From parent page:
window.addEventListener("message", (event) => {
  if (event.origin !== "https://your-domain.com") return
  if (event.data.type === "chat:resize") {
    iframe.style.height = event.data.height + "px"
  }
})
```

## Theming

```ts
// Pass theme via URL params or postMessage
// /embed/chat?botId=abc&theme=dark&primaryColor=%23FF6B6B

const theme = {
  mode: searchParams.get("theme") ?? "light",
  primaryColor: searchParams.get("primaryColor") ?? "#6366F1",
  fontFamily: searchParams.get("font") ?? "Inter",
}

// Apply via CSS custom properties
document.documentElement.style.setProperty("--chat-primary", theme.primaryColor)
```

## Security
- Validate `origin` in postMessage handlers
- Use `Content-Security-Policy` frame-ancestors to restrict embedding
- Never expose API keys in widget.js
- Rate limit by origin domain
