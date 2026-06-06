---
name: brainstorming
description: "Use when starting any creative work - creating features, building components, adding functionality, or modifying behavior"
---

# Brainstorming Ideas Into Designs

Turn ideas into fully formed designs through collaborative dialogue before any code is written.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

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
- Save to `docs/specs/YYYY-MM-DD-<topic>-design.md`
- Self-review: search for "TBD", "TODO", placeholder values, contradictions
- Ask user to review the written spec (not just the verbal design)

**Load the appropriate domain skill** (`/booking`, `/ecom`, `/chat`) during exploration if the topic matches a domain.

**Load the appropriate framework skill** (`/next`, `/nest`, `/fastapi`, `/turbo`) once the tech stack is clear.

<HARD-GATE>
The terminal state is invoking the plan workflow. Do NOT invoke any implementation skill directly. The ONLY next step after brainstorming is planning.
</HARD-GATE>
