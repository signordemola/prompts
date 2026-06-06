# OpenCode Skills & Plugins — Usage Guide

## Quick Reference: When to Use What

### A. Superpowers (workflow skills — always active)

| Skill | Triggers When | Skip If |
|-------|--------------|---------|
| brainstorming | "build", "create", "add feature", "new app" | Trivial 1-line change, fix typo |
| writing-plans | After design approval | Already have a clear plan |
| test-driven-development | Any code change | It's a config file, HTML, or CSS-only |
| systematic-debugging | "bug", "fix", "broken", "not working", "error" | You already know the exact fix |
| verification-before-completion | Claiming something is "done" | Never skip this |
| requesting-code-review | Between implementation tasks | Trivial changes |
| finishing-a-development-branch | "done", "finished", "complete" | Never skip if you merged code |
| using-git-worktrees | New feature branch needed | Already on correct branch |
| subagent-driven-development | Multi-task implementation | Single-file change |
| executing-plans | Batch execution with checkpoints | Prefer subagent for speed |
| dispatching-parallel-agents | 2+ independent tasks | Tasks share state or dependencies |
| receiving-code-review | Getting review feedback | Feedback is trivial |
| using-superpowers | Session start (auto) | N/A |
| writing-skills | Creating custom skills | N/A |

### B. Power-Pack Slash Commands (`/command`)

| Command | What It Does | Use For | Too Heavy For |
|---------|-------------|---------|---------------|
| `/code-review` | Multi-agent PR review with cross-checks | PR review, branch review | "Does this look ok?" quick ask |
| `/security-review` | OWASP-bucketed audit, requires PoC | Auth flows, payment code, user data handling | Simple form input, static pages |
| `/feature-dev` | 7-phase guided workflow (discovery→summary) | Any non-trivial feature | Bug fixes, typos, config changes |
| `/frontend-design` | Distinctive, production-grade UI generation | New pages, redesigns | Tweaking padding/colors |
| `/code-explorer` | Deep codebase trace end-to-end | Understanding complex flows | "Where is this variable defined?" |
| `/code-architect` | Architecture blueprint with file-level plan | Before building large features | Small changes |
| `/code-reviewer` | Two-pass adversarial review | Each completed task | Trivial changes |
| `/mcp-builder` | Guide MCP server creation | Building MCP integrations | N/A |
| `/skill-creator` | Author new custom skills | Creating reusable skill files | N/A |
| `/agents-md-improver` | Audit & update project rules file | Out of date AGENTS.md/CLAUDE.md | Fresh project with no rules |
| `/agents-md-revise` | Capture session learnings into rules | After a productive session | Nothing learned this session |

### C. Custom Skills (auto-triggered)

| Skill | Triggers When | Content |
|-------|--------------|---------|
| booking-platform | "booking", "reservation", "appointment", "schedule", "availability", "calendar booking", "event booking", "double-booking", "round-robin", "seat-based", "recurring event", "time slot", "confirmation flow" | 1,125 lines: DB schema, concurrency, timezone, payments, compliance, testing. 20+ cal.diy reference URLs |
| vercel-react-best-practices | Any React/Next.js code | 45 rules with code examples: waterfalls, bundle size, server perf, re-render, JS optimizations |
| web-design-guidelines | "review my UI", "check accessibility", "audit design", "review UX" | Fetches live Vercel Web Interface Guidelines |

---

## Typical Workflows

### Workflow A: Building a New Feature

```
1. "I want to build a booking system" → brainstorming triggers
2. Approve design → writing-plans triggers
3. "go" → subagent-driven-development triggers
4. Each task: test-driven-development + code-reviewer
5. Between tasks: requesting-code-review
6. "done" → finishing-a-development-branch triggers
```

### Workflow B: Fixing a Bug

```
1. "The booking confirmation email shows wrong time" → systematic-debugging triggers
2. Write failing test → test-driven-development triggers
3. Fix → verification-before-completion triggers
4. "done" → requesting-code-review triggers
```

### Workflow C: Quick Change (Skip Everything)

```
1. "Add a console.log to debug X" → Just do it. No skills needed.
2. "Fix this typo in README" → Just do it. No skills needed.
3. "Change the button color to blue" → Just do it. No skills needed.
```

### Workflow D: Booking Platform Specific

```
1. "Build a hotel booking system" → brainstorming + booking-platform trigger
2. Booking skill injects: DB schema patterns, double-booking prevention, timezone rules
3. Every API route you write follows the patterns
4. "Add Stripe payment" → booking skill guides idempotent charges
5. "Review the payment flow" → /security-review catches PCI issues
6. "Review my booking UI" → web-design-guidelines checks accessibility
```

---

## When NOT to Use Skills (Save Tokens)

Skip skills when:
- **Typo fixes** — Just fix it
- **Config changes** — No logic involved
- **CSS-only changes** — TDD is overkill
- **Documentation updates** — No code to test
- **"Explain this code to me"** — No action needed
- **"What does git status show?"** — Informational only
- **Simple console.log / debug additions** — No verification needed
- **Trivial HTML changes** — No state/logic involved
- **Single-line logic changes** — The fix is obvious and minimal

---

## Command Reference

### In-Session Phrases (auto-trigger skills)

| Say This | Triggers |
|----------|----------|
| "Build me a booking platform" | brainstorming → booking-platform → writing-plans → TDD |
| "Fix the double-booking bug" | systematic-debugging → booking-platform → TDD |
| "Review this PR" | /code-review |
| "Audit security" | /security-review |
| "Improve the project rules" | /agents-md-improver |
| "Capture what we learned" | /agents-md-revise |
| "Design a new dashboard" | /frontend-design |
| "Check my UI accessibility" | web-design-guidelines |
| "Optimize my React bundle" | vercel-react-best-practices |
| "Create a custom skill for X" | /skill-creator |

### File Locations

```
~/.config/opencode/
├── opencode.jsonc              # Plugin config
├── commands/                   # 11 slash commands (symlinks)
│   ├── code-review.md
│   ├── security-review.md
│   ├── feature-dev.md
│   ├── frontend-design.md
│   └── ... (7 more)
└── skills/                     # 3 custom skills
    ├── booking-platform/
    │   └── SKILL.md            (1,125 lines, 41KB)
    ├── vercel-react-best-practices/
    │   ├── SKILL.md
    │   ├── AGENTS.md           (60KB)
    │   └── rules/              (45 rule files)
    └── web-design-guidelines/
        └── SKILL.md

~/code/opencode-power-pack/     # Power-pack source (for git pull updates)
```

### Updating Skills

```bash
# Update power-pack
cd ~/code/opencode-power-pack && git pull
rm -rf ~/.cache/opencode/node_modules/opencode-power-pack

# Update custom skills (edit directly)
vim ~/.config/opencode/skills/booking-platform/SKILL.md

# Create a new custom skill
# Say: "Help me create a custom skill for X" → /skill-creator triggers
```

### Disabling for a Project

Add to your project's `opencode.json`:
```json
{ "plugin": [] }
```
Or to temporarily skip a specific skill just say: "Skip the brainstorming step, just do it."

---

## When This Becomes Overkill

If you find yourself waiting for skills to finish before every tiny change, you're:

1. **Using too many slash commands for small tasks** — Most changes don't need `/feature-dev` or `/code-review`. Use judgment.

2. **Not overriding when appropriate** — You can always say "skip the plan, just fix the bug." Superpowers respects your override.

3. **Not using the booking skill correctly** — It auto-injects on booking keywords. If you're just discussing booking theory (not coding), the skill loads unnecessarily. Say "This is just discussion, don't load the booking skill."

4. **Doing too much in one session** — Break work into focused sessions. One feature per session keeps context clean.

---

*Last updated: June 2026 — Created with superpowers + opencode-power-pack + cal.diy skills*
