# Defense in Depth — Multi-Layer Validation Patterns

Validate at EVERY boundary, not just the edge. Each layer assumes the previous layer failed.

## The 4 Layers

| Layer | Purpose | Enforced By | Trusts Previous Layer? |
|-------|---------|-------------|----------------------|
| **1. Client** | UX feedback (instant errors) | Form validation, JS | ❌ Never security |
| **2. API** | Input sanitization | Zod / class-validator / Pydantic | ❌ No |
| **3. Service** | Business rule enforcement | Application code | ❌ No |
| **4. Database** | Data integrity (last line) | CHECK, UNIQUE, NOT NULL, FK | ❌ No |

**Core principle:** If you remove any single layer, the system should still reject invalid data. Each layer is independent.

## Worked Example: Price Validation

A booking deposit must be a positive integer (pence/cents), matching the calculated amount.

### Layer 1 — Client
```tsx
// Form prevents submission of bad values (UX only — not security)
<input type="number" min="1" step="1" required />
```

### Layer 2 — API Route / Controller

**Next.js (Zod):**
```ts
const schema = z.object({ amount: z.number().int().min(1) })
const parsed = schema.parse(body) // throws on invalid
```

**NestJS (class-validator):**
```ts
export class CreatePaymentDto {
  @IsInt() @Min(1) amount: number
}
// Global ValidationPipe rejects invalid DTOs automatically
```

**FastAPI (Pydantic):**
```python
class CreatePayment(BaseModel):
    amount: int = Field(gt=0)
# FastAPI validates automatically from type hints
```

### Layer 3 — Service
```ts
// Business logic: amount must match calculated deposit
const expected = calculateDeposit(service)
if (amount !== expected) {
  throw new Error(`Amount mismatch: got ${amount}, expected ${expected}`)
}
```

### Layer 4 — Database
```prisma
model Appointment {
  depositAmount Int // Prisma enforces Int type
  // Add CHECK constraint via migration:
  // ALTER TABLE "Appointment" ADD CONSTRAINT "deposit_positive" CHECK ("depositAmount" > 0);
}
```

## Common Mistakes

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| Trusting client validation as security | Client JS can be bypassed | Always validate server-side |
| Skipping service validation ("DB will catch it") | DB constraints can't enforce business logic | Validate business rules in service layer |
| Not validating between internal services | Internal APIs can be called with bad data too | Validate at every boundary, even internal |
| Using floats for money | `0.1 + 0.2 !== 0.3` | Use integers (pence/cents) everywhere |
| Validating only on create, not update | Updates can introduce invalid state | Validate on every mutation |

## When to Add Each Layer

- **Starting a new feature:** Add all 4 layers from day one
- **Found a bug:** Trace which layer failed → add validation there AND every layer below it
- **Performance concern:** Never skip validation for speed. Optimize the validation itself instead.
