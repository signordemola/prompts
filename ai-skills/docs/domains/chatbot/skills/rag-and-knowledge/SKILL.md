---
name: rag-and-knowledge
description: >
  RAG pipeline and knowledge base management. ACTIVATE when: ingesting documents,
  chunking text, generating embeddings, storing vectors, implementing retrieval,
  reranking results, or showing source citations.
---

# RAG & Knowledge Base Skill

## When to Use
- Ingesting documents (PDF, text, URLs)
- Building the embedding/chunking pipeline
- Implementing similarity search
- Adding source citations to responses

## RAG Pipeline Overview

```
Upload → Extract Text → Chunk → Embed → Store in pgvector
                                              ↓
User Query → Embed Query → Similarity Search → Top K Chunks
                                              ↓
                              Inject into Prompt → LLM → Response with Sources
```

## Document Ingestion

```ts
// POST /api/knowledge/upload
async function ingestDocument(file: File) {
  // 1. Extract text
  const rawContent = await extractText(file) // pdf-parse, mammoth, etc.
  
  // 2. Create document record
  const doc = await prisma.knowledgeDocument.create({
    data: {
      title: file.name,
      sourceType: "upload",
      mimeType: file.type,
      rawContent,
      status: "PROCESSING",
    }
  })
  
  // 3. Chunk
  const chunks = chunkText(rawContent, { maxTokens: 500, overlap: 100 })
  
  // 4. Embed all chunks
  const embeddings = await embedBatch(chunks.map(c => c.content))
  
  // 5. Store chunks with embeddings
  for (let i = 0; i < chunks.length; i++) {
    await prisma.$executeRaw`
      INSERT INTO "DocumentChunk" (id, "documentId", content, embedding, "chunkIndex", "tokenCount", "createdAt")
      VALUES (${cuid()}, ${doc.id}, ${chunks[i].content}, ${embeddings[i]}::vector, ${i}, ${chunks[i].tokenCount}, NOW())
    `
  }
  
  // 6. Mark ready
  await prisma.knowledgeDocument.update({
    where: { id: doc.id },
    data: { status: "READY" },
  })
}
```

## Chunking Strategy

```ts
function chunkText(text: string, opts: { maxTokens: number; overlap: number }): Chunk[] {
  const { maxTokens, overlap } = opts
  const maxChars = maxTokens * 4 // ~4 chars per token
  const overlapChars = overlap * 4
  const chunks: Chunk[] = []
  
  // Split by paragraphs first, then by sentences
  const paragraphs = text.split(/\n\n+/)
  let current = ""
  
  for (const para of paragraphs) {
    if ((current + para).length > maxChars && current.length > 0) {
      chunks.push({
        content: current.trim(),
        tokenCount: Math.ceil(current.length / 4),
      })
      // Overlap: keep tail of previous chunk
      current = current.slice(-overlapChars) + "\n\n" + para
    } else {
      current += (current ? "\n\n" : "") + para
    }
  }
  if (current.trim()) {
    chunks.push({ content: current.trim(), tokenCount: Math.ceil(current.length / 4) })
  }
  
  return chunks
}
```

| Parameter | Default | Tuning |
|-----------|---------|--------|
| Chunk size | 500 tokens | Smaller = more precise, larger = more context |
| Overlap | 100 tokens | Prevents splitting mid-thought |
| Split method | Paragraph → sentence | Preserves semantic units |

## Embedding

```ts
import { embed, embedMany } from "ai"
import { openai } from "@ai-sdk/openai"

const embeddingModel = openai.embedding("text-embedding-3-small")

// Single query
async function embedQuery(text: string): Promise<number[]> {
  const { embedding } = await embed({ model: embeddingModel, value: text })
  return embedding
}

// Batch (for ingestion)
async function embedBatch(texts: string[]): Promise<number[][]> {
  const { embeddings } = await embedMany({ model: embeddingModel, values: texts })
  return embeddings
}
```

| Model | Dimensions | Cost | Best for |
|-------|-----------|------|---------|
| `text-embedding-3-small` | 1536 | $0.02/1M tokens | Default, demos |
| `text-embedding-3-large` | 3072 | $0.13/1M tokens | Higher accuracy |

## Retrieval

```ts
async function retrieveChunks(query: string, topK: number = 5): Promise<RetrievedChunk[]> {
  const queryEmbedding = await embedQuery(query)
  
  const chunks = await prisma.$queryRaw<RetrievedChunk[]>`
    SELECT
      dc.id,
      dc.content,
      dc.metadata,
      kd.title AS "documentTitle",
      kd.id AS "documentId",
      1 - (dc.embedding <=> ${queryEmbedding}::vector) AS similarity
    FROM "DocumentChunk" dc
    JOIN "KnowledgeDocument" kd ON dc."documentId" = kd.id
    WHERE kd.status = 'READY'
    ORDER BY dc.embedding <=> ${queryEmbedding}::vector
    LIMIT ${topK}
  `
  
  // Filter by minimum similarity threshold
  return chunks.filter(c => c.similarity > 0.7)
}
```

## Injecting into Prompt

```ts
function buildRagContext(chunks: RetrievedChunk[]): string {
  if (chunks.length === 0) return ""
  
  const context = chunks
    .map((c, i) => `[Source ${i + 1}: ${c.documentTitle}]\n${c.content}`)
    .join("\n\n---\n\n")
  
  return `Use the following context to answer the user's question. If the answer is not in the context, say so honestly.\n\n${context}`
}
```

## Source Citations

```ts
// Return sources with the response
const sources = chunks.map(c => ({
  documentId: c.documentId,
  chunkId: c.id,
  title: c.documentTitle,
  score: c.similarity,
}))

// Display in UI:
// "Based on: FAQ → Shipping Policy, Returns Guide"
```

## References
- `references/database-schema.md` — KnowledgeDocument, DocumentChunk
- `references/rag-pipeline.md` — full end-to-end pipeline details

## NEVER
- ❌ Embed user queries with a different model than documents
- ❌ Skip overlap in chunking (loses context at boundaries)
- ❌ Return chunks below similarity threshold (hallucination risk)
- ❌ Send all chunks to LLM (select top K only)
- ❌ Store embeddings without the source text (can't debug)
