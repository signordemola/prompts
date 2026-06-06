# Prompts & AI Skills

A personal knowledge base for AI coding agents + reusable prompt templates.

## Structure

```
├── ai-skills/           ← Portable AI skills library (install into client projects)
│   ├── AGENTS.md        ← Agent rules (Karpathy principles)
│   ├── USAGE.md         ← How to install, update, and extend
│   ├── install.sh       ← Bootstrap script
│   └── docs/            ← Skills, workflows, domains, references
├── templates/           ← Standalone prompt templates
│   ├── pro-research-session.md
│   ├── user-testing-flow.md
│   └── opencode-skills-guide.md
├── reference/           ← Personal reference docs
│   └── linux-mint-commands.md
└── scratch/             ← Drafts and scratch files
```

## AI Skills Library

The main product — a portable knowledge base you install into client projects so AI agents follow your engineering workflows.

**Install into any project:**
```bash
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
```

**Update an existing project:**
```bash
bash scripts/ai-skills-update.sh
```

See [ai-skills/USAGE.md](ai-skills/USAGE.md) for full documentation.

### What's included

| Component | Count | What |
|-----------|-------|------|
| Workflows | 12 | Engineering process (brainstorm → plan → build → verify → ship + self-improvement) |
| Skills | 17 | Framework & library patterns (Next.js, NestJS, FastAPI, Prisma, Drizzle, Stripe, etc.) |
| Domains | 3 | Business logic (booking, ecommerce, chatbot) |
| References | 5 | Deep reference docs (API design, migrations, validation, debugging) |

### Automation

- **Auto-sync**: GitHub Action creates PRs in client projects when skills are updated
- **Self-learning**: Agents log mistakes to `LESSONS.md`, weekly review creates issues
- **Cross-agent**: Works with Antigravity, Claude Code, OpenCode, CommandCode, Codex

## Templates

Standalone prompts for specific tasks — not installed into projects, just referenced when needed.

## License

Personal use.
