# API Design — REST Conventions Across Frameworks

Consistent API design patterns for Next.js, NestJS, and FastAPI projects.

## Resource Naming

| ✅ Good | ❌ Bad | Why |
|---------|--------|-----|
| `GET /api/users` | `GET /api/getUsers` | Verbs are in HTTP methods, not URLs |
| `GET /api/users/123` | `GET /api/user/123` | Plurals for collections |
| `POST /api/users/123/orders` | `POST /api/createOrder` | Nested resources show relationship |
| `PATCH /api/users/123` | `POST /api/updateUser` | Use PATCH for partial updates |

## HTTP Methods

| Method | Purpose | Idempotent? | Body? |
|--------|---------|-------------|-------|
| `GET` | Read resource(s) | Yes | No |
| `POST` | Create resource | No | Yes |
| `PUT` | Replace entire resource | Yes | Yes |
| `PATCH` | Partial update | Yes | Yes |
| `DELETE` | Remove resource | Yes | No |

## Status Codes

| Code | When | Example |
|------|------|---------|
| `200` | Success with data | GET, PATCH, PUT responses |
| `201` | Resource created | POST response |
| `204` | Success, no content | DELETE response |
| `400` | Bad request (client error) | Validation failure |
| `401` | Not authenticated | Missing/invalid token |
| `403` | Not authorized | Valid token, wrong role |
| `404` | Resource not found | ID doesn't exist |
| `409` | Conflict | Duplicate email, race condition |
| `422` | Unprocessable entity | Valid syntax, invalid semantics |
| `429` | Rate limited | Too many requests |
| `500` | Server error | Unhandled exception |

## Error Response Format

Use the same shape everywhere — clients should never guess the error format.

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email address",
    "details": [
      { "field": "email", "message": "Must be a valid email" }
    ]
  }
}
```

### Framework Implementation

**Next.js:**
```ts
return NextResponse.json(
  { error: { code: "NOT_FOUND", message: "User not found" } },
  { status: 404 }
)
```

**NestJS:**
```ts
throw new NotFoundException({ code: "NOT_FOUND", message: "User not found" })
// Or use a global ExceptionFilter for consistent formatting
```

**FastAPI:**
```python
raise HTTPException(
    status_code=404,
    detail={"code": "NOT_FOUND", "message": "User not found"}
)
```

## Pagination

Use **cursor-based** pagination for real-time data. Use **offset** only for admin/backoffice.

```
GET /api/orders?cursor=abc123&limit=20
```

Response:
```json
{
  "data": [...],
  "pagination": {
    "nextCursor": "def456",
    "hasMore": true
  }
}
```

## Rate Limiting Headers

Always include these in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1717632000
Retry-After: 60           // Only on 429 responses
```

## Versioning

Prefer **URL path versioning** for simplicity:
```
/api/v1/users
/api/v2/users
```

Keep old versions running until all clients migrate. Never break existing endpoints.

## NEVER
- ❌ Return 200 for errors (use proper status codes)
- ❌ Accept price/amounts from the client (calculate server-side)
- ❌ Expose internal IDs (database auto-increment) — use UUIDs or cuid
- ❌ Return stack traces in production error responses
- ❌ Use GET for mutations (GET must be safe and idempotent)
- ❌ Nest resources more than 2 levels deep (`/users/123/orders` is fine, `/users/123/orders/456/items/789` is not)
