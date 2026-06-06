# Prompts & AI Skills

A personal knowledge base for AI coding agents + reusable prompt templates.

## Structure

```
├── ai-skills/           ← Portable AI skills library (install into client projects)
│   ├── AGENTS.md        ← Agent rules (11 rules, Karpathy-inspired)
│   ├── USAGE.md         ← How to install, update, and extend
│   ├── install.sh       ← Bootstrap script
│   ├── push-lessons.sh  ← Push project lessons to GitHub
│   └── docs/            ← Skills, workflows, domains, references
├── templates/           ← Standalone prompt templates
├── reference/           ← Personal reference docs
└── .github/workflows/   ← Automation
```

## AI Skills Library

Install into any project — everything goes into `.ai-skills/` (gitignored). Zero git footprint.

**Install:**
```bash
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
```

**Update:**
```bash
bash .ai-skills/update.sh
```

**Push lessons to GitHub:**
```bash
bash .ai-skills/push-lessons.sh
```

See [ai-skills/USAGE.md](ai-skills/USAGE.md) for full documentation.

### What's included

| Component | Count | What |
|-----------|-------|------|
| Workflows | 12 | Engineering process (brainstorm → plan → build → verify → ship + self-improvement) |
| Skills | 17 | Framework & library patterns (Next.js, NestJS, FastAPI, Prisma, Drizzle, Stripe) |
| Domains | 3 | Business logic (booking, ecommerce, chatbot) |
| References | 5 | Deep reference docs (API design, migrations, validation, debugging) |

### The Learning Loop

```
Work on project → Agent logs mistakes → You say "reflect"
→ Agent generates reflection + proposed changes
→ You push to GitHub as an issue → Review
→ Apply with a good model → Push → All projects get the fix
```

### Cross-agent compatible

Works with Antigravity, Claude Code, OpenCode, Codex, Cursor.

## License

Personal use.
