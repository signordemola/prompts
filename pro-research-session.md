# Project Research Session

## Model stack

| Model                | Role                                               |
| -------------------- | -------------------------------------------------- |
| Lovable              | UI/UX design and export                            |
| DeepSeek V4 Flash    | Primary implementation — all standard coding tasks |
| DeepSeek V4 Pro      | Research session, complex logic, debugging         |
| Gemini 3.5 Flash     | UI/UX review, dashboard design, visual polish      |
| Codex 5.5 / Opus 4.6 | Full validation and walkthrough guide              |

One tool, one job. Nothing overlaps.

---

# PART 1 — Lovable

## Before any code is written. Before Pro opens the checklist.

---

You are Lovable. Before you design anything, read the full project
checklist pasted below. Do not treat it as a design spec.
Treat it as context — who this business owner is, what country they
operate in, what their clients experience, and what operational
problem this system solves.

Research the niche yourself. Understand what this type of business
looks like visually, how their clients expect to be treated, what
professionalism means in this industry and country, and what a system
built for this specific owner should feel like to use.

There are three distinct surfaces to design. Understand the difference
before touching any of them:

**Public booking page** — what the client sees when they land.
This is the only public-facing surface. It must convert a visitor
into a booked client without friction. This is what gets designed
with the most visual care.

**Client portal** — private, accessed via a unique link sent after
booking. The client checks their appointment, manages it, pays.
Calm, focused, branded. Not a public page.

**Owner dashboard** — private, password protected. The business
owner's daily control panel. Professional, data-forward, calm.
Not a public page. Not part of the booking experience.

Design all three. But treat them as separate products with separate
jobs — not sections of one website.

---

Design everything guided by these principles:

1. **Provide value through the interface**
   Every screen earns its place. If a screen does not move the client
   closer to booking or the owner closer to running their business,
   it does not exist. No filler. No padding with text.

2. **Visuals carry the weight — always**
   Images, close-up photography, whitespace and typography do the
   communicating. Text is the last resort. A visitor should understand
   what this business offers and feel something before reading a word.
   Full-screen hero imagery above the fold. Work shown through
   photography not described in paragraphs. Every word that exists
   earns its place — short, confident, specific to this business.

3. **One clear action above the fold**
   The booking CTA is visible immediately. No hunting. No scrolling
   to find it. The hero section has one job — get the visitor
   to book. Everything else is secondary.

4. **Make it interactive and memorable**
   Micro-animations at moments that matter — booking confirmation,
   payment success, appointment management actions, dashboard updates.
   Parallax on the public page where it enhances the imagery.
   Animations serve the emotional beat of each moment.

5. **Design for this specific niche and country**
   Typography, colour, spacing, imagery style — all must reflect
   this exact business type and where it operates.
   Research what credibility and luxury look like in this niche
   before choosing a single colour or typeface.
   A UK lash studio has a different visual language from a US bridal
   artist or a Canadian coaching practice.

6. **Design the favicon and logo**
   Based on the niche, the country, and the studio identity in the
   checklist. Not a generic icon. Something this owner would use.

7. **Polish before exporting**
   Review every screen. Ask: would this business owner be proud to
   show the public page to their clients? Would they trust the
   dashboard enough to run their business on it daily?
   If any screen looks like a template with a logo swapped in — fix it.
   Export only when every screen earns a yes.

---

# PART 2 — DeepSeek V4 Pro Research Session

## Run at chat.deepseek.com — Search ON, Deep Think ON

## After Lovable exports. Before OpenCode opens.

---

## What this session is

You are DeepSeek V4 Pro. This is a research and preparation session.
No code gets written here. Your job is to deeply understand this project
before a single file is touched.

You have web search. Use it. Do not rely on training data alone.
Research everything that matters to this project — the niche, the tools,
the business, the industry standards — and produce an AGENTS.md that
the build agent can use throughout the entire project.

The developer reviews and approves everything before building begins.

---

## Step 1 — Read the project checklist

The full project checklist is pasted below. Read it completely before doing
anything else. Understand:

- Who this system is for and what real operational problem it solves
- The business rules the system must enforce accurately
- Every database model and its relationships
- Every API route and what it does
- Every lib function and the logic it encapsulates

Do not move to Step 2 until you have read and understood the full checklist.

---

## Step 2 — Research the tech stack

Research the current state of every tool this project uses.
Find the latest official documentation, current best practices,
current folder structure conventions, current caching model,
current code splitting patterns, and any breaking changes
from versions the checklist may reference.

For each tool: find what is current, what has changed recently,
and what the community considers best practice right now.
This includes but is not limited to the framework, ORM, payment provider,
email provider, auth library, UI library, validation library,
and any third-party APIs the checklist uses.

Produce a summary of what you found per tool — current version, key patterns
to follow, and anything that would cause problems if done the old way.

---

## Step 3 — Research the niche and industry

This is the research that makes the demo credible to a real client.

Based on what you read in the checklist — the country, the business type,
the services offered, the client journey — research:

- The current pain points and operational challenges real businesses
  in this niche face right now
- The industry standards for deposits, cancellations, contracts,
  client data, and any licensing or legal requirements relevant
  to this country and profession
- What tools real businesses in this niche currently use and why
  they outgrow them
- Any regulatory or compliance requirements that must be reflected
  in the system — data protection, professional licensing, consent,
  health and safety depending on the niche

Use official industry bodies, regulatory authorities, professional
associations, and government sources as your primary references.
Flag anything in the checklist that does not align with what you find.

---

## Step 4 — Produce the AGENTS.md file

Based on everything you researched, write the AGENTS.md for this project.
This is what OpenCode reads before every build session.

It must cover:

**What this system is**
One paragraph. Specific — the niche, the country, the operational
problem being solved, and who the real client of this demo is.

**Tech stack**
Every tool with its current version and official documentation URL.
Based on your research — not the checklist's version if it is outdated.

**Folder structure and conventions**
The correct folder structure for this framework based on current
best practices. Where routing lives, where business logic lives,
where components live, where schemas and types live, and how
the dependency graph flows. Be specific — not generic.

**Non-negotiable rules**

- How money is stored (integers — state the unit: pence or cents)
- Auth pattern and where it is enforced
- Validation — Zod on every input before any database write
- UI library — which folder is never edited manually
- Tokens — database IDs never exposed in client URLs
- Caching — current model for this framework version
- Any project-specific rule from the checklist that cannot be broken

**Business rules**
The three to five most critical rules this codebase must enforce.
Stated as facts. Example: "An appointment is only created inside
the Stripe webhook on payment confirmation — never before."

**What the agent must not do**
Specific actions that would break this project.
Based on the research — common mistakes with these tools right now.

**Industry accuracy notes**
What you found in Step 3 that the implementation must reflect.
The details that make a real business owner say this system
understands their industry.

---

## Step 5 — Readiness confirmation

Before this session ends:

1. Confirm you have read and understood the full checklist.
2. State what you found for each tool — current version and
   any important changes from what the checklist assumed.
3. State what you found about the niche — the key industry
   standards and requirements this system must reflect.
4. State whether the checklist is accurate or whether
   anything needs to be updated before building begins.
5. Confirm the AGENTS.md is complete and ready.

Do not say ready if anything is unclear or potentially wrong.
Flag it and ask the developer first.

---

## How Part 2 feeds into Part 3

Once the developer approves the AGENTS.md:

1. AGENTS.md is committed to the project root
2. Gemini 3.5 Flash runs the UI sessions alongside the build
3. OpenCode opens — reads AGENTS.md — building begins with Flash
4. Pro is called back during the build for complex logic,
   industry accuracy questions, and bugs Flash cannot resolve

---

# PART 3 — Gemini 3.5 Flash UI/UX Session

## Run at gemini.google.com — Thinking Level: HIGH

## Runs across the build — never before Part 2 is approved

---

## Session 1 — Dashboard Research and Design

### When: before the owner dashboard phases are built

Research current shadcn/ui dashboard patterns and best practices.
Read the shadcn/ui docs and shadcnblocks admin dashboard examples.

Then read the project checklist and AGENTS.md in this codebase.

Based on what this specific business owner needs to see daily,
design the owner dashboard: KPI cards, charts, tables, navigation.
Every element must map to a real data point in this project.
No generic SaaS patterns. This is a service business owner's tool.

---

## Session 2 — Data Fetching and Skeleton Loaders

### When: after dashboard UI exists, before logic is wired in

Read the current dashboard components in this codebase.

Refactor using best-practice Server Component data fetching
for the current framework version. Add skeleton loaders that
mirror the final layout exactly. Prevent layout shift completely.
Add error states for every data section. Full TypeScript.

---

## Session 3 — Theme and Color

### When: after dashboard structure is complete

Read globals.css and all CSS variables in this codebase.

Research and apply a professional color palette using semantic
shadcn/ui tokens suited to this specific business type and niche.
Not a generic SaaS aesthetic — this studio's industry and brand.
Output updated globals.css and any changed component files.

---

## Session 4 — Full Polish

### When: before Part 4 — final visual gate

Read the entire dashboard directory in this codebase.

Remove all AI-looking elements and template aesthetics.
Strengthen visual hierarchy, spacing and consistency.
Ensure the aesthetic matches this business type specifically.

Refactor the overview page: correct Server Component data fetching
with Suspense, skeleton loaders that prevent layout shift,
KPI cards and tables tailored to this project's real data.
Full TypeScript. Nothing moves to Part 4 until this passes.

---

# PART 4 — Codex 5.5 / Opus 4.6

## Two jobs: full validation then walkthrough guide

## Runs after all build and polish phases are complete

---

## Job 1 — Full Project Validation

Read the entire codebase and the project checklist.

### Checklist validation

Go through every item in the checklist phase by phase.
Mark each one: IMPLEMENTED / MISSING / WRONG.
Do not skip any. Do not assume something works without verifying it.

### Business rules

Verify every business rule in AGENTS.md is enforced in code.
Check the actual implementation — not just that a function exists
but that it enforces the rule correctly in every path.

### Edge cases

For every critical flow — booking, payment, cancellation,
no-show, refund, role-based access, reminder scheduling —
identify and verify every edge case is handled.
Flag any path where the system could behave incorrectly.

### Data integrity

Verify the seed file produces realistic demo data that
covers every state the system can be in.
No placeholder names, no zero-value prices, no missing
relationships. The demo must look like a real working studio.

### End to end

Trace the full client journey from first interaction to final
state for at least two different client types:
a new client and a returning client.
Confirm every step works without errors or broken states.

### Owner dashboard

Verify every number on the dashboard is calculated correctly
from the seeded data. Every stat card, every table, every chart.
If a number is wrong the demo is wrong.

Output: a verdict per section — PASS or FAIL with specific findings.
Nothing moves to Job 2 until every section passes.

---

## Job 2 — Demo Walkthrough Guide

The developer will record a video demo of this project.
Your job is to plan that recording so it is not improvised.

Read the completed, validated codebase.
Understand every screen, every state, every interaction.

Produce a step-by-step recording guide structured as three parts:

**Part A — The client journey**
Every screen the client sees from first interaction to final state.
For each screen: what to show, what to click, what data to use,
what the viewer should notice and why it matters.
Ordered to tell a story — the problem being solved should be
obvious to someone watching without narration.

**Part B — The owner dashboard**
Every section of the owner view in a logical sequence.
For each section: what to open, what to demonstrate,
what specific data to point to, what it proves to a potential client.
The dashboard demo should answer the question:
"Would I trust this person to build my studio's system?"

**Part C — The niche moment**
One moment in the demo — one screen, one interaction, one detail —
that shows this system was built for this specific industry
and not just adapted from a generic template.
Identify it, explain why it matters to this niche,
and tell the developer exactly how to present it.

Format the guide as a numbered sequence the developer follows
while recording. Screen by screen. No ambiguity.
