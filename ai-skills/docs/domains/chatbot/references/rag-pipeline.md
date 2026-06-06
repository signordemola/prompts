# RAG Pipeline Deep Dive

## End-to-End Flow

```
Ingest: Document → Extract → Chunk → Embed → Store (pgvector)
Query:  User msg → Embed → Search → Rerank → Inject → LLM → Respond + Sources
```

## Chunking Comparison

| Strategy | Chunk size | Overlap | Best for |
|----------|-----------|---------|---------|
| Fixed character | 2000 chars | 200 | Quick/dirty |
| Recursive split | 500 tokens | 100 | **Default — best balance** |
| Semantic | Variable | N/A | High-quality, slower |
| Markdown headers | Per section | None | Structured docs |

## Hybrid Retrieval (Vector + Keyword)

```sql
-- Combine semantic similarity with keyword matching
SELECT id, content,
  (0.7 * (1 - (embedding <=> $1::vector))) +
  (0.3 * ts_rank(to_tsvector('english', content), plainto_tsquery('english', $2)))
  AS combined_score
FROM "DocumentChunk"
WHERE to_tsvector('english', content) @@ plainto_tsquery('english', $2)
   OR (embedding <=> $1::vector) < 0.5
ORDER BY combined_score DESC
LIMIT 10
```

## Reranking

```ts
// Retrieve top 20 → rerank to top 5
async function retrieveWithReranking(query: string): Promise<Chunk[]> {
  const candidates = await retrieveChunks(query, 20)
  
  // Simple relevance reranking using LLM
  const { object } = await generateObject({
    model: getModel("fast"),
    schema: z.object({
      rankings: z.array(z.object({
        chunkId: z.string(),
        relevance: z.number().min(0).max(1),
      }))
    }),
    prompt: `Rate the relevance of each chunk to the query: "${query}"\n\n${
      candidates.map((c, i) => `[${c.id}]: ${c.content.slice(0, 200)}`).join("\n")
    }`,
  })
  
  return object.rankings
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, 5)
    .map(r => candidates.find(c => c.id === r.chunkId)!)
}
```

## Metadata Filtering

```ts
// Filter by document category before vector search
const chunks = await prisma.$queryRaw`
  SELECT dc.*, 1 - (dc.embedding <=> ${embedding}::vector) AS similarity
  FROM "DocumentChunk" dc
  JOIN "KnowledgeDocument" kd ON dc."documentId" = kd.id
  WHERE kd.category = ${category}  -- pre-filter
    AND kd.status = 'READY'
  ORDER BY dc.embedding <=> ${embedding}::vector
  LIMIT ${topK}
`
```

## Quality Metrics

| Metric | What it measures | Target |
|--------|-----------------|--------|
| **Recall@K** | Did we retrieve the right chunk? | > 0.8 |
| **Precision@K** | How many retrieved chunks are relevant? | > 0.6 |
| **Faithfulness** | Does the response match the retrieved context? | > 0.9 |
| **Answer relevancy** | Does the response actually answer the question? | > 0.8 |
