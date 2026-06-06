# AGENT.md - Strict Coding Rules

Any AI coding agent working in this repository must follow these rules strictly.

## Rule 0 - Load Workflow Skills First

**Before doing ANY work, read `docs/ROUTER.md`.** It contains the workflow skill index. If a skill applies to your task (even a 1% chance), you MUST read and follow the full `SKILL.md` before starting. This is not optional. Skills override your default behavior. User instructions in this file override skills.

## Rule 1 - Think Before Coding

State assumptions explicitly. Ask rather than guess.  
Push back when a simpler approach exists. Stop and ask when confused.

## Rule 2 - Simplicity First

Write the minimum code that solves the problem.  
Nothing speculative. No abstractions for single-use code.

## Rule 3 - Surgical Changes

Touch only what the task requires.  
Do not improve, rewrite, or refactor adjacent code unless necessary for the task.  
Match existing style exactly.

## Rule 4 - Goal-Driven Execution

Define clear success criteria before changing code.  
Loop until the goal is fully handled or a real blocker is reported.

## Rule 5 - Read Before Writing

Before editing, read the relevant files, exports, immediate callers, schemas, hooks, and shared utilities.  
If existing structure is unclear, ask before changing it.

## Rule 6 - Research First When Knowledge Can Be Stale

Do not rely only on trained/cutoff knowledge for APIs, libraries, frameworks, tools, security practices, or best practices that may have changed.

When current knowledge matters:

- Prefer official documentation first.
- Then GitHub source or reputable technical sources.
- State what was researched and cite sources when possible.
- Flag anything that could not be verified.

Do not do unnecessary online research for purely local code questions.

## Rule 7 - Surface Conflicts

If repo rules, docs, code patterns, or user instructions conflict, pick the safest/current one, explain the conflict, and flag what should be cleaned up.

## Rule 8 - No Secret or Env Changes Without Permission

Do not open, edit, print, copy, or summarize `.env` files unless explicitly asked in the current task.  
Do not expose secrets in any form.

## Rule 9 - Quality Gate (Run Only When Requested)

The Quality Gate is **not** run automatically after every task.  
Running typecheck/lint to verify your own changes during a task is fine — that's verification, not a quality gate.  

The `/quality` command runs the full quality gate: ruff + pyright + compileall for Python, react-doctor (must score 100/100) for React. Only run these when the founder explicitly asks ("/quality", "run quality gate", "check quality", "run ruff and react-doctor", etc.).

**Python / FastAPI Quality Gate**:

Run from the Python/API project root.
In a Turborepo, this is usually `apps/api`.
In a standalone backend project, this is the folder that contains `pyproject.toml`, `ruff.toml`, or the FastAPI app package.

```bash
uv run ruff check --fix .
uv run ruff format .
uv run python -m compileall -q app
uv run pyright app
```

`uv` must be installed as a CLI and available on `PATH`. Do not rely on
`python3 -m uv` inside an activated virtualenv.

Report any files changed by Ruff.
Ruff passing is not enough. For FastAPI routes, return annotations must match the actual Python return value. Use `response_model` for the serialized API contract.
If Pyright is not installed or configured, report that static type checking is missing and do not claim full FastAPI quality verification.

**React / Next.js Quality Gate**:

Run from the React/Next.js project root.
In a Turborepo, this is usually `apps/web`.
In a standalone frontend project, this is the folder that contains `package.json` and `next.config.*`.

```bash
npx -y react-doctor@latest .
```

The score must be 100/100. If it is not 100/100, fix the issues or report every remaining issue with the reason it could not be fixed safely.

For mixed frontend/backend changes, run both relevant quality gates.

If a quality tool cannot run because of dependencies, network, sandbox, missing virtualenv, or local environment problems, report:

- the exact command attempted
- the exact failure
- what remains unverified
- the exact command the founder should run locally

Do not suppress quality tool rules with inline comments (`# noqa:`), per-file-ignores,
or config-based ignores unless a documented, project-specific reason exists that
cannot be addressed by fixing the code. If you are unsure how to fix an issue,
research the official docs for the tool and the relevant framework before proposing
a fix. Ask before suppressing anything.

## Rule 10 - Fail Loud

"Completed" is wrong if anything was skipped silently.  
"Tests pass" is wrong if checks were not run.  
"Fixed" is wrong if the behavior was not verified.

Finish with:

- what changed
- what was verified
- what was skipped
- remaining risks
