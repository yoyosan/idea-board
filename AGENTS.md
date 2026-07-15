# AGENTS.md

Guide for AI agents working on this project. Read this before making changes.

## Project

**IdeaBoard** — customer feature request portal. Customers submit ideas, vote, and get notified of progress. Admins triage and manage the pipeline. Feature requests only — does NOT replace the support system.

## Specs Location

All detailed requirements live in `openspec/changes/customer-idea-management-system/`. Read the relevant spec before implementing a feature.

| What you need | Where to read |
|---------------|---------------|
| Why we're building this + what's out of scope | `proposal.md` |
| Architecture, schema, security, email design | `design.md` |
| What a feature must do (requirements + scenarios) | `specs/<capability>/spec.md` |
| Implementation order, TDD task list | `tasks.md` |

**Spec capabilities:**
- `authentication/` — registration, email verification, login, logout, password reset, hCaptcha, disposable email blocking
- `idea-submission/` — submit, duplicate detection, edit own idea, admin delete
- `idea-management/` — dashboard, filters, search, sort, merge, optimistic locking
- `upvoting/` — vote, unvote, one-per-user constraint, public counts
- `commenting-system/` — public comments, internal notes, self-edit/delete, admin moderation
- `status-tracking/` — workflow transitions, declined + reason, status history timeline
- `notification-system/` — email queue, retry, customer prefs, admin digest, failed notifications

## Coding Standards

### Python

- ALL function signatures MUST have complete type annotations
- Use Pydantic models for request/response — never raw dicts
- ALL route handlers, DB queries, email sends are `async def`
- Use `Depends()` for dependency injection (DB session, current user)
- Line length: 100 (Ruff)
- Import order: stdlib → third-party → local (Ruff handles this)
- ALWAYS include `WHERE deleted_at IS NULL` on idea/comment queries
- Atomic increments: `UPDATE ... SET count = count + 1` (not read-modify-write)
- Use specific exception types, not bare `except Exception`

### TypeScript

- NEVER use `any` — use `unknown` if type is truly unknown
- Prefer `interface` over `type` for object shapes
- Use discriminated unions for variant states
- Always type API responses
- Keep components < 200 lines
- Extract complex logic into custom hooks
- Always handle loading and error states in API calls
- Use Next.js App Router features (server components, streaming)

### SQL

- Use snake_case for table and column names
- Use parameterized queries (never string concatenation)
- Avoid N+1 queries — use eager loading
- Paginate large result sets (cursor-based, not offset)

## Development Philosophy

### TDD (Test-Driven Development)

1. **Red:** Write a failing test describing the behavior
2. **Green:** Write minimal code to make it pass
3. **Refactor:** Clean up while keeping tests green

### Simplicity Over Cleverness

- Prefer simple solutions over clever ones
- Write code that is clear and self-explanatory
- If a solution requires explanation, it's probably too complex
- Readability beats performance unless there's a measured bottleneck

### Build for the Long Term

- Write code that future developers can understand and maintain
- Consider how today's decisions affect tomorrow's changes
- Prefer explicit, well-documented approaches over implicit "magic"
- Invest in tests, documentation, and clear naming

### YAGNI

- Don't build features until they're actually needed
- Don't add abstractions until you have 3+ concrete use cases
- Don't optimize until you've measured a real bottleneck

### Fail Fast

- Validate inputs at the boundary (API entry points)
- Use Pydantic for request validation — reject immediately
- Raise specific exceptions with full context

### Separation of Concerns

**Backend:** Routes (HTTP) → Services (logic) → Models (DB) → Schemas (validation)
**Frontend:** Components (UI) → Hooks (logic) → API Client (communication) → Types

### DRY (with caveat)

- Extract shared logic into reusable functions/hooks/components
- BUT: duplication is cheaper than the wrong abstraction — don't abstract too early

### Use What You Have

- **Always check existing libraries first** before writing custom code. The specs and design document list the libraries in use — use their built-in features.
- If a library offers the functionality you need, use it. Don't reinvent.
- If you can't find existing functionality, **ask before implementing**. Don't assume — confirm with the user first.
- If you must evaluate a new solution, research the best available option and present it with trade-offs before proceeding.
- Never implement a custom solution when a library feature exists, and never add a new dependency without asking.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | FastAPI (Python 3.14, async) |
| Database | PostgreSQL (async via SQLAlchemy + asyncpg) |
| Migrations | Alembic |
| Package manager (Python) | uv |
| Package manager (Frontend) | Bun |
| Frontend | Next.js (TypeScript, React, Tailwind, shadcn/ui) |
| Lint + format (Python) | Ruff |
| Lint + format (Frontend) | Biome |
| Type check (Python) | Pyright (strict) |
| Type check (Frontend) | TypeScript (`bunx tsc --noEmit`) |
| Test runner (Backend) | pytest + pytest-asyncio + httpx |
| Test runner (Frontend) | Vitest + @testing-library/react |
| E2E tests | Playwright |
| Commits | Conventional Commits (`feat:`, `fix:`, `chore:`, etc.) |
| Secrets | gitleaks |
| Errors | Sentry (backend + frontend) |

## MANDATORY: Verification Sequence After Every Change

**After making ANY code change, run this sequence in order before moving on:**

```bash
# 1. LINTING — catch style issues, formatting, import order
uv run ruff check .
bunx biome ci .

# 2. STATIC ANALYSIS — catch type errors, null safety, dead code
uv run pyright
bunx tsc --noEmit

# 3. TESTS — catch regressions, verify behavior
uv run pytest
bun run test
```

**Why this order:** Linting is fastest (~1s), static analysis next (~2s), tests slowest (~10s). Fail early.

**This sequence is NON-NEGOTIABLE.** Do not skip steps. Do not move on if any step fails. Fix it immediately.

## Development Workflow

### Before Starting Work
1. Pull latest from `main`
2. Create feature branch: `feat/short-description` or `fix/issue-description`
3. Run `make setup` (install deps + migrations)

### While Working
1. Write failing test first (TDD)
2. Implement minimal code to pass
3. Refactor for clarity
4. Run verification sequence (lint → typecheck → test) after every change
5. Commit with Conventional Commits format
6. Run full sequence again before pushing

### Commit Message Format
```
feat(voting): add unvote endpoint with atomic decrement
fix(auth): block unverified users from logging in
test(ideas): add failing tests for duplicate detection
refactor(email): extract sending logic into service layer
```

## Agent Behavior Guidelines

### Do
- Read the relevant spec file before implementing any feature
- Follow TDD: write failing test first, then implement
- Use type annotations everywhere (Python) and strict TypeScript
- Keep changes focused (one feature per PR)
- Run the verification sequence after every change
- Ask for clarification if requirements are unclear
- Document complex logic with comments explaining "why" not "what"
- **Use existing library features** before writing custom code — check docs first
- **Ask before adding new dependencies** or implementing custom solutions

### Don't
- Add features not in the spec without asking
- Skip tests or write tests after implementation
- Use `any` type in TypeScript or bare `except` in Python
- Commit secrets, API keys, or credentials
- Bypass guardrails (linters, type checkers, pre-commit hooks)
- Over-abstract or add unnecessary design patterns
- Optimize prematurely without measuring
- **Reinvent functionality** that already exists in the chosen libraries
- **Add new dependencies** without confirming with the user first

### When Stuck
1. Read the relevant spec (`openspec/changes/.../specs/<capability>/spec.md`)
2. Check `design.md` for architectural decisions
3. Look at existing code for patterns and conventions
4. **Search the library docs** for existing functionality before writing custom code
5. Ask for help rather than guessing — present options with trade-offs

## Running the Project

```bash
# Backend
uv run uvicorn app.main:app --reload

# Frontend
bun install && bun dev

# Tests
uv run pytest          # backend
bun run test           # frontend
bun run test:e2e       # end-to-end

# Linting + types
uv run ruff check .    # python lint
bunx biome ci .        # frontend lint
uv run pyright         # python types
bunx tsc --noEmit      # frontend types

# All checks
make lint && make typecheck && make test

# Admin bootstrap (first deploy)
uv run python -m app.cli create-admin --email admin@company.com --password <secure>
```
