---
name: brainstorming
description: "Use when starting any creative work - creating features, building components, adding functionality, or modifying behavior. Don't use for bug fixes (use debug) or known tasks with a plan (use executing-plans)."
---

# Brainstorming Ideas Into Designs

Turn ideas into fully formed designs through collaborative dialogue before any code is written.

**Announce at start:** "I'm using the brainstorming workflow to design this before writing any code."

<HARD-GATE>
**⛔ MANDATORY GATE — NO CODE BEFORE DESIGN APPROVAL.**
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Scope Assessment

Before diving in, check if the request should be split:

| Signal | Action |
|--------|--------|
| >3 unrelated API endpoints | Split into separate specs |
| >5 new DB tables | Split by domain boundary |
| >2 frameworks involved | One spec per framework layer |
| "And also..." in the request | Likely 2+ separate features |

## Checklist

Complete these in order:

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to complexity, get user approval per section
5. **Write design doc** — save to `docs/specs/YYYY-MM-DD-<topic>-design.md`
6. **Spec self-review** — check for placeholders, contradictions, ambiguity, scope
7. **User reviews written spec** — ask user to review before proceeding
8. **Transition** — invoke the `plan` workflow to create implementation plan

## The Process

**Understanding the idea:**
- Check current project state first (files, docs, recent commits)
- Assess scope: if the request describes multiple independent subsystems, suggest breaking into separate specs — one per subsystem
- Ask one question at a time. Don't dump 10 questions at once.
- Listen for what they DON'T say — missing requirements cause more bugs than wrong requirements

**Designing the solution:**
- Propose 2-3 approaches with honest trade-offs
- Recommend one. Explain why.
- Present design in digestible sections. Get approval per section.
- If a section is rejected, revise and re-present. Don't proceed.

**Writing the spec:**

Save to `docs/specs/YYYY-MM-DD-<topic>-design.md` using this template:

```markdown
# <Feature Name>

## Problem
What problem does this solve? Who is it for?

## Constraints
- Technical constraints (framework, DB, existing architecture)
- Business constraints (timeline, budget, must-haves vs nice-to-haves)
- Non-functional (performance targets, security requirements)

## Approach
The chosen approach and why.

### Alternatives Considered
| Approach | Pros | Cons | Why rejected |
|----------|------|------|-------------|

## Design
Detailed design — schemas, API endpoints, component tree, state flow.

## Edge Cases
- What happens when X fails?
- What happens with concurrent requests?
- What happens at scale?

## Success Criteria
- [ ] Specific, testable outcomes
- [ ] Not vague ("works well") but measurable ("responds in <200ms")
```

**Self-review the spec:**

<Good>
```
✅ Every section filled — no "TBD" or "TODO" placeholders
✅ Edge cases identified with specific handling strategies
✅ Success criteria are testable (a test could verify them)
✅ No contradictions between sections
```
</Good>

<Bad>
```
❌ "Handle errors appropriately" — what errors? What's appropriate?
❌ "TBD: figure out auth later" — blocking ambiguity left in
❌ "Should be fast" — not measurable
❌ Design says REST but success criteria mentions GraphQL
```
</Bad>

**Load the appropriate domain skill** (`/booking`, `/ecom`, `/chat`) during exploration if the topic matches a domain.

**Load the appropriate framework skill** (`/next`, `/nest`, `/fastapi`, `/turbo`) once the tech stack is clear.

<HARD-GATE>
**⛔ MANDATORY — The ONLY next step after brainstorming is the plan workflow.**
Do NOT invoke any implementation skill directly. brainstorming → plan → build. No shortcuts.
</HARD-GATE>
