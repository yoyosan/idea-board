# IdeaBoard (`idea-board`)

Customer feature request portal. Customers submit ideas, vote on what they want, and get notified when their requests progress. Admins triage, prioritize, and manage the pipeline through a dedicated dashboard.

## Stack

| Layer | Technology |
|-------|------------|
| Backend | FastAPI (Python 3.14, async) |
| Database | PostgreSQL (async via SQLAlchemy + asyncpg) |
| Frontend | Next.js (TypeScript, React, Tailwind, shadcn/ui) |
| Package managers | uv (Python), Bun (frontend) |
| Linting | Ruff (Python), Biome (frontend) |
| Type checking | Pyright (Python), TypeScript (frontend) |
| Testing | pytest (backend), Vitest + Playwright (frontend) |
| Errors | Sentry |

## Quick Start

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
uv run ruff check .
bunx biome ci .
uv run pyright
bunx tsc --noEmit

# All checks
make lint && make typecheck && make test

# Create first admin
uv run python -m app.cli create-admin --email admin@company.com --password <secure>
```

## Architecture

Single FastAPI monolith with Next.js frontend. PostgreSQL is the source of truth — no Redis, no external message queues. Email is sent async via aiosmtplib; failures go to a PostgreSQL retry queue.

Two roles: `customer` (submit, vote, comment) and `admin` (dashboard, status updates, internal notes).

## Live Mockups

Interactive HTML mockups are deployed via GitHub Pages:

| Page | Description |
|------|-------------|
| [Login](https://yourusername.github.io/idea-board/mockups/login.html) | Email/password login |
| [Register](https://yourusername.github.io/idea-board/mockups/register.html) | New account signup |
| [Submit Idea](https://yourusername.github.io/idea-board/mockups/submit.html) | Idea submission form |
| [Browse Ideas](https://yourusername.github.io/idea-board/mockups/ideas.html) | Public ideas list with voting |
| [Idea Detail](https://yourusername.github.io/idea-board/mockups/idea-detail.html) | Full idea view with comments |
| [My Ideas](https://yourusername.github.io/idea-board/mockups/my-ideas.html) | Customer's submitted/voted ideas |
| [Admin Dashboard](https://yourusername.github.io/idea-board/mockups/dashboard.html) | Admin idea management |
| [Admin Detail](https://yourusername.github.io/idea-board/mockups/admin-detail.html) | Status update, internal notes |

> Replace `yourusername` with your GitHub username after enabling Pages.

## Key Documentation

| Document | What it covers |
|----------|---------------|
| `AGENTS.md` | Coding standards, philosophy, verification sequence |
| `openspec/changes/customer-idea-management-system/proposal.md` | Why, scope, out-of-scope list |
| `openspec/changes/customer-idea-management-system/design.md` | Architecture, schema, security, ops |
| `openspec/changes/customer-idea-management-system/specs/` | Detailed requirements per capability |
| `openspec/changes/customer-idea-management-system/tasks.md` | Implementation plan (8 vertical slices, TDD) |
| `mockups/` | HTML mockups for all pages |

## Development

This project uses [OpenSpec](https://github.com/Fission-AI/OpenSpec) for spec-driven development. Run `/opsx:apply` to start implementation — it reads tasks top-to-bottom, one checkbox at a time.

Testing is TDD on the backend (write failing test first, then implement), loosely tested on the frontend. After every code change, the verification sequence runs automatically (lint → typecheck → test).

## Status

**Planning complete. Ready for implementation.**

- 7 specs (authentication, idea submission, idea management, upvoting, commenting, status tracking, notifications)
- 8 vertical slices, 116 tasks
- After Slice 5: shippable product
- Slices 6–8: comments, notification polish, hardening
