---
name: code-style
description: >
  Project code style and anti-bloat rules. ACTIVATE before writing or editing
  source code in any JavaScript, TypeScript, React, Next.js, NestJS, or Node
  project. Enforces no comments, const-first ES module style, and minimal code.
---

# Code Style Skill

## When to Use
- Writing or editing project source code
- Creating components, hooks, actions, utilities, services, or tests
- Refactoring existing JavaScript or TypeScript

<HARD-GATE>
**⛔ MANDATORY — GENERATED PROJECT CODE MUST HAVE ZERO COMMENTS.**
Do not add comments to source code. No explanatory comments, section comments,
TODO comments, JSDoc comments, commented-out code, or inline notes. If code needs
a comment to make sense, rename things or simplify the code.
</HARD-GATE>

## Function Style

Use `const` arrow functions by default:

```ts
export const getUser = async (id: string) => {
  return db.user.findUnique({ where: { id } })
}
```

For React components:

```tsx
const ProductCard = ({ product }: ProductCardProps) => {
  return <article>{product.name}</article>
}

export default ProductCard
```

For Next.js route handlers:

```ts
export const GET = async () => {
  return Response.json({ ok: true })
}
```

For Next.js pages:

```tsx
const Page = async () => {
  return <main />
}

export default Page
```

## Variable Style

- Use `const` by default
- Use `let` only when reassignment is required
- Never use `var`
- Prefer named exports for utilities, hooks, actions, schemas, and services
- Avoid default anonymous exports

## Anti-Bloat Rules

- Do not add speculative abstractions
- Do not add helpers used only once unless they remove real complexity
- Do not add wrapper layers around framework APIs without a concrete need
- Do not add future-proofing code
- Do not add unused states, props, options, branches, or config
- Do not create folders before there are real files that belong in them
- Delete dead code instead of commenting it out

## Exceptions

Only break `const` arrow style when a framework or runtime requires another form.
Examples: class-based framework APIs, generated files, migration DSLs, or existing
files that already follow a different local convention.

## NEVER
- ❌ Add comments to generated source code
- ❌ Add tutorial-style code
- ❌ Add commented-out code
- ❌ Use `function` declarations unless required
- ❌ Use `var`
- ❌ Add abstractions for imagined future requirements
