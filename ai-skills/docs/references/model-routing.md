# Model Routing Guide

Which AI model to use for which task.

## Routing Table

| Task | Best model | Why |
|------|-----------|-----|
| UI/UX, user testing, quick prototypes | Gemini Flash | Fast iteration, good at visual |
| Daily implementation, bug fixes | Claude Sonnet (Thinking) | Balanced speed + reasoning |
| Hard architecture, deep debugging | Claude Opus (Thinking) | Best reasoning, catches edge cases |
| End-to-end autonomous builds | Codex 5.5 | Long-running, full autonomy |
| High-volume backend, refactoring | DeepSeek V4 Pro | Fast, cheap, good at patterns |
| Local/offline coding | Ollama + Qwen3-Coder | No network dependency |

## Tips

- **Debugging timezone/currency bugs:** Use Opus with extended thinking. These bugs are subtle.
- **Scaffolding a new demo:** Use Codex or Sonnet. Follow `docs/domains/booking/SKILL.md`.
- **UI polish pass:** Use Gemini Flash for rapid iteration.
- **Security review:** Use Sonnet with `docs/skills/security-hardening/SKILL.md` loaded.
