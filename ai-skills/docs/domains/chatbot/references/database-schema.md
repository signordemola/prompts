# Chatbot Database Schema

## Complete Prisma Schema

```prisma
// ═══════════════════════════════════════════
// CONVERSATIONS
// ═══════════════════════════════════════════

model Conversation {
  id          String    @id @default(cuid())
  sessionId   String?   // anonymous users (cookie)
  userId      String?   // authenticated users
  title       String?   // auto-generated from first message
  status      String    @default("ACTIVE") // ACTIVE | ARCHIVED | ESCALATED
  
  // Context
  metadata    Json?     // { market, page, referrer, userAgent }
  
  messages    Message[]
  feedback    Feedback[]
  
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  @@index([sessionId])
  @@index([userId])
  @@index([status])
  @@index([createdAt])
}

model Message {
  id              String       @id @default(cuid())
  conversationId  String
  conversation    Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  
  role            String       // "system" | "user" | "assistant" | "tool"
  content         String
  
  // LLM metadata
  model           String?      // "gpt-4o" | "claude-3-5-sonnet" | null for user
  inputTokens     Int?
  outputTokens    Int?
  latencyMs       Int?
  
  // Tool calling
  toolCalls       Json?        // [{ name, arguments, result }]
  toolCallId      String?      // for tool result messages
  
  // RAG
  sources         Json?        // [{ documentId, chunkId, score, title }]
  
  createdAt       DateTime     @default(now())

  @@index([conversationId])
  @@index([createdAt])
}

// ═══════════════════════════════════════════
// KNOWLEDGE BASE (RAG)
// ═══════════════════════════════════════════

model KnowledgeDocument {
  id          String   @id @default(cuid())
  title       String
  sourceType  String   // "upload" | "url" | "text"
  sourceUrl   String?
  mimeType    String?  // "application/pdf" | "text/plain" | "text/markdown"
  rawContent  String   // original extracted text
  status      String   @default("PROCESSING") // PROCESSING | READY | ERROR
  
  // Metadata for filtering
  category    String?
  tags        String[]
  
  chunks      DocumentChunk[]
  
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model DocumentChunk {
  id          String            @id @default(cuid())
  documentId  String
  document    KnowledgeDocument @relation(fields: [documentId], references: [id], onDelete: Cascade)
  
  content     String            // chunk text
  embedding   Unsupported("vector(1536)")? // pgvector
  
  // Position
  chunkIndex  Int               // 0, 1, 2... order within document
  
  // Metadata for retrieval
  metadata    Json?             // { section, page, heading }
  tokenCount  Int
  
  createdAt   DateTime          @default(now())

  @@index([documentId])
}

// ═══════════════════════════════════════════
// FEEDBACK & ANALYTICS
// ═══════════════════════════════════════════

model Feedback {
  id              String       @id @default(cuid())
  conversationId  String
  conversation    Conversation @relation(fields: [conversationId], references: [id])
  messageId       String?      // specific message rated
  
  rating          String       // "positive" | "negative"
  comment         String?      // optional freeform
  
  createdAt       DateTime     @default(now())

  @@index([conversationId])
}

model UsageLog {
  id          String   @id @default(cuid())
  
  // Attribution
  sessionId   String?
  userId      String?
  model       String
  
  // Tokens
  inputTokens  Int
  outputTokens Int
  totalTokens  Int
  
  // Cost (micro-cents for precision)
  costMicro   Int      // 1 micro-cent = 0.000001 USD
  
  // Performance
  latencyMs   Int
  
  // Context
  feature     String?  // "chat" | "rag_query" | "tool_call"
  
  createdAt   DateTime @default(now())

  @@index([createdAt])
  @@index([userId])
  @@index([model])
}

// ═══════════════════════════════════════════
// ESCALATION
// ═══════════════════════════════════════════

model SupportTicket {
  id              String   @id @default(cuid())
  conversationId  String
  
  subject         String   // auto-generated from conversation
  customerEmail   String?
  status          String   @default("OPEN") // OPEN | IN_PROGRESS | RESOLVED | CLOSED
  priority        String   @default("NORMAL") // LOW | NORMAL | HIGH | URGENT
  
  // Transcript snapshot
  transcript      Json     // snapshot of conversation at escalation time
  
  assignedTo      String?
  resolvedAt      DateTime?
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@index([status])
}
```

## pgvector Setup

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create index for similarity search (after data loaded)
CREATE INDEX idx_chunk_embedding ON "DocumentChunk"
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- For small datasets (<10k chunks), use exact search:
CREATE INDEX idx_chunk_embedding_exact ON "DocumentChunk"
  USING hnsw (embedding vector_cosine_ops);
```

## Key Queries

```ts
// Similarity search
const results = await prisma.$queryRaw`
  SELECT id, content, metadata,
    1 - (embedding <=> ${queryEmbedding}::vector) AS similarity
  FROM "DocumentChunk"
  WHERE "documentId" IN (${Prisma.join(activeDocIds)})
  ORDER BY embedding <=> ${queryEmbedding}::vector
  LIMIT ${topK}
`

// Cost tracking
const dailyCost = await prisma.usageLog.aggregate({
  where: { createdAt: { gte: startOfDay } },
  _sum: { costMicro: true, totalTokens: true },
})
```
