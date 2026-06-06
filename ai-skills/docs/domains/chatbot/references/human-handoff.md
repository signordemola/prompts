# Human Handoff & Escalation

## Escalation Triggers

| Trigger | Detection | Action |
|---------|-----------|--------|
| Explicit request | "talk to a human" keyword match | Immediate handoff |
| Repeated failure | Same question asked 3+ times | Suggest handoff |
| Negative sentiment | Frustration detected | Suggest handoff |
| Complex issue | Model confidence low | Suggest handoff |
| Sensitive topic | Complaint, legal, billing dispute | Auto-escalate |

## Implementation

```ts
// Tool-based escalation (model decides)
createSupportTicket: tool({
  description: "Create a support ticket when you cannot resolve the issue or the customer requests a human agent",
  parameters: z.object({
    subject: z.string(),
    customerEmail: z.string().email(),
    priority: z.enum(["LOW", "NORMAL", "HIGH", "URGENT"]),
  }),
  execute: async ({ subject, customerEmail, priority }) => {
    const ticket = await prisma.supportTicket.create({
      data: {
        conversationId,
        subject,
        customerEmail,
        priority,
        transcript: await getConversationTranscript(conversationId),
      }
    })
    
    // Notify support team
    await sendEmail({
      to: process.env.SUPPORT_EMAIL,
      subject: `[${priority}] New ticket: ${subject}`,
      body: `Ticket #${ticket.id}\nCustomer: ${customerEmail}\n\nConversation transcript attached.`,
    })
    
    return {
      ticketId: ticket.id,
      message: `I've created ticket #${ticket.id}. Our team will reach out to ${customerEmail} within 24 hours.`,
    }
  },
})
```

## Graceful Handoff Message

```ts
const HANDOFF_MESSAGE = `I understand this needs personal attention. I've created a support ticket for you, and our team will contact you within 24 hours at the email you provided.

In the meantime, you can:
- Reply to this chat if you have other questions I can help with
- Check your email for updates on your ticket
- Call us at [phone number] during business hours`
```

## Ticket Schema

```prisma
model SupportTicket {
  id              String   @id @default(cuid())
  conversationId  String
  subject         String
  customerEmail   String?
  status          String   @default("OPEN") // OPEN | IN_PROGRESS | RESOLVED | CLOSED
  priority        String   @default("NORMAL")
  transcript      Json     // conversation snapshot
  assignedTo      String?
  resolvedAt      DateTime?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}
```
