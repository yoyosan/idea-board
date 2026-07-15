# Implementation Plan

Slices are ordered by dependency. Each slice is a **reviewable vertical increment**: backend + frontend + tests for one feature. After Slice 5 you have a working product. Slices 6–8 are enhancements that can be deferred or cut.

**Testing approach:** Test-driven development (TDD) on the backend — write the failing test first (Red), implement to make it pass (Green), then refactor. Frontend is tested loosely: component tests for key interactions plus end-to-end tests at the end of each slice. Pure scaffolding tasks (install, config) are not test-first.

---

## 1. Foundation

Goal: empty app skeleton that boots, talks to the DB, has a working test harness, and has all quality guardrails in place. Nothing user-facing yet.

**Scaffolding (not test-driven):**
- [ ] 1.1 Create FastAPI project with uv (Python 3.14), add core dependencies (fastapi, uvicorn, sqlalchemy[asyncio], asyncpg, alembic, pydantic, email-validator)
- [ ] 1.2 Configure async SQLAlchemy engine + session, create Alembic setup
- [ ] 1.3 Create all database tables (users, tokens, ideas, votes, comments, status_history, email_queue) via initial migration
- [ ] 1.4 Add full-text search index on ideas (title + description)
- [ ] 1.5 Create Next.js project with TypeScript using Bun, API client, basic layout
- [ ] 1.6 Set up Sentry (backend + frontend SDKs)
- [ ] 1.7 Create admin bootstrap CLI command (`uv run python -m app.cli create-admin`)
- [ ] 1.8 Create custom 404 and 500 error pages

**Guardrails (set up before any feature work):**
- [ ] 1.9 Add Ruff (Python linter + formatter): `uv add --dev ruff`, configure `pyproject.toml` (line-length 100, select lint rules), add `make lint` and `make format`
- [ ] 1.10 Add Pyright (Python type checker): `uv add --dev pyright`, configure strict mode in `pyproject.toml`, add `make typecheck`
- [ ] 1.11 Add Biome (frontend linter + formatter): `bun add -D @biomejs/biome`, configure `biome.json`, add scripts to `package.json`
- [ ] 1.12 Add pre-commit hooks: install `pre-commit`, create `.pre-commit-config.yaml` running Ruff, Biome, gitleaks, Pyright on staged files
- [ ] 1.13 Add gitleaks config (`.gitleaks.toml`) — scan staged files for secrets before commit
- [ ] 1.14 Add commitlint + commitizen: enforce Conventional Commits (`feat:`, `fix:`, `chore:`, etc.) on commit messages
- [ ] 1.15 Set up GitHub branch protection: no direct pushes to main, require PR review, require CI to pass

**Testing infrastructure:**
- [ ] 1.16 Install Python test dependencies (pytest, pytest-asyncio, httpx, factory-boy)
- [ ] 1.17 Install frontend test dependencies via Bun (Vitest, @testing-library/react, Playwright)
- [ ] 1.18 Create test database (separate from dev), conftest with async fixtures for DB session and test client
- [ ] 1.19 Write smoke test: `GET /health` returns 200 — run it, watch it fail, implement the endpoint, watch it pass
- [ ] 1.20 Add `make test` (backend) and `bun run test` (frontend) commands, verify they run the smoke test

**CI pipeline:**
- [ ] 1.21 Create CI workflow: Python job (ruff check + ruff format --check + pyright + pytest), frontend job (biome ci + vitest), security job (gitleaks + pip-audit + bun audit)
- [ ] 1.22 Verify CI fails on a deliberately broken commit (e.g., add a type error, confirm pyright blocks it)

## 2. Authentication

Goal: a real human can register, verify email, log in, log out, reset password. Nothing else works without auth.

**Scaffolding:**
- [ ] 2.1 Implement bcrypt password hashing utility (cost factor 12) + unit test for hash/verify roundtrip

**Disposable email check (TDD):**
- [ ] 2.2 Write failing tests: reject mailinator.com, allow gmail.com, allow simplelogin alias
- [ ] 2.3 Implement disposable email check (`is-disposable-email` + allow-list of legit aliases)

**Registration (TDD):**
- [ ] 2.4 Write failing tests: POST /api/auth/register creates pending user; rejects duplicate email; rejects short password; rejects disposable email
- [ ] 2.5 Implement register endpoint + Pydantic schema (creates pending account, queues verification email)
- [ ] 2.6 Write failing test: hCaptcha token is validated server-side (mock hCaptcha in test, assert rejected when invalid)
- [ ] 2.7 Integrate hCaptcha verification on register

**Email verification (TDD):**
- [ ] 2.8 Write failing tests: GET /verify-email?token=X activates account; expired token rejected; already-used token rejected
- [ ] 2.9 Implement verify-email endpoint (activates account, logs in, invalidates token)

**Login / logout (TDD):**
- [ ] 2.10 Write failing tests: POST /api/auth/login succeeds for verified user; fails for unverified; fails for wrong password; returns JWT cookie
- [ ] 2.11 Implement login endpoint (blocks unverified accounts, sets JWT HttpOnly cookie)
- [ ] 2.12 Write failing tests: POST /api/auth/logout clears cookie; GET /api/auth/me returns current user
- [ ] 2.13 Implement logout endpoint and `/me` endpoint

**Password reset (TDD):**
- [ ] 2.14 Write failing tests: POST /api/auth/forgot-password creates token + queues email; POST /api/auth/reset-password updates password, invalidates token, logs out other sessions; expired token rejected
- [ ] 2.15 Implement forgot-password and reset-password endpoints

**Auth middleware (TDD):**
- [ ] 2.16 Write failing tests: protected endpoint returns 401 without cookie; returns 200 with valid customer cookie; admin-only endpoint returns 403 for customer
- [ ] 2.17 Implement JWT middleware + `get_current_user` dependency + admin-only decorator

**Resend verification:**
- [ ] 2.18 Write failing test: POST /api/auth/resend-verification issues new token, invalidates old
- [ ] 2.19 Implement resend-verification endpoint

**Email templates:**
- [ ] 2.20 Create verification email and password reset email templates

**Frontend (loosely tested):**
- [ ] 2.21 Build register page (with hCaptcha), login page (with redirect-back), "check your email" pending page, verification callback page, forgot-password and reset-password pages
- [ ] 2.22 Build auth guard wrapper for protected routes on frontend
- [ ] 2.23 Component tests: register form shows validation errors for short password; login form shows error on wrong credentials

**E2E checkpoint:**
- [ ] 2.24 E2E: register → check email → click verification link → login → logout loop (Playwright)

## 3. Idea Submission & Browsing

Goal: logged-in user submits an idea, it appears in the public list, anyone can view details.

**Duplicate detection (TDD):**
- [ ] 3.1 Write failing tests: GET /api/ideas/similar?title=X returns matches >70% similarity; returns nothing for unique title
- [ ] 3.2 Implement duplicate detection (PostgreSQL trigram search)

**Submission (TDD):**
- [ ] 3.3 Write failing tests: POST /api/ideas requires login; creates idea with status=submitted; rejects missing fields; rejects invalid category
- [ ] 3.4 Implement POST /api/ideas endpoint + Pydantic validation
- [ ] 3.5 Create submission confirmation email template

**List + detail (TDD):**
- [ ] 3.6 Write failing tests: GET /api/ideas returns public ideas sorted by votes; cursor pagination returns next cursor; hides soft-deleted ideas; excludes ideas with no verified submitter
- [ ] 3.7 Implement GET /api/ideas with cursor-based pagination
- [ ] 3.8 Write failing tests: sort=top returns by votes desc; sort=recent returns by created_at desc; sort=trending returns by votes in last 7 days
- [ ] 3.9 Implement sort options
- [ ] 3.10 Write failing tests: GET /api/ideas?q=dark returns matches ranked by relevance; title match ranks higher than description match
- [ ] 3.11 Implement full-text search with relevance ranking
- [ ] 3.12 Write failing test: GET /api/ideas/{id} returns idea detail; 404 for missing; 404 for soft-deleted
- [ ] 3.13 Implement GET /api/ideas/{id}

**Frontend (loosely tested):**
- [ ] 3.14 Build submission form page (with live duplicate suggestions)
- [ ] 3.15 Build ideas list page (infinite scroll, sort tabs, search, category/status filters)
- [ ] 3.16 Build idea detail page (title, description, status, submitter)
- [ ] 3.17 Build "My Ideas" page
- [ ] 3.18 Component test: submission form shows duplicate suggestion when title matches

**E2E checkpoint:**
- [ ] 3.19 E2E: login → submit idea → see it in list → click to view detail → see confirmation email queued

## 4. Voting

Goal: logged-in user upvotes an idea, count changes, can't double-vote.

**Vote endpoints (TDD):**
- [ ] 4.1 Write failing tests: POST /api/ideas/{id}/vote requires login; increments votes_count; returns 409 on duplicate vote from same user; DELETE removes vote and decrements
- [ ] 4.2 Implement vote/unvote endpoints with atomic count increment and unique constraint
- [ ] 4.3 Write failing test: two simultaneous votes do not lose a count (concurrency test using two async clients)
- [ ] 4.4 Verify atomic increment holds under concurrent votes (adjust transaction isolation if test fails)

**Frontend (loosely tested):**
- [ ] 4.5 Add vote button to ideas list and detail pages (toggles, shows voted state)
- [ ] 4.6 Component test: vote button toggles between unvoted and voted states

**E2E checkpoint:**
- [ ] 4.7 E2E: login → upvote idea → count increments → refresh → still voted → unvote → count decrements

## 5. Admin Dashboard & Status Workflow

Goal: admin logs in, sees all ideas filtered/sorted, updates status, customer sees status change + gets email. **This is the core product — reviewable end-to-end.**

**Dashboard list (TDD):**
- [ ] 5.1 Write failing tests: GET /api/dashboard/ideas requires admin; returns all ideas with filters (status, category); supports search; supports sort (top/recent/trending); returns status breakdown counts
- [ ] 5.2 Implement dashboard list endpoint with filters, search, sort, status counts

**Status update (TDD):**
- [ ] 5.3 Write failing tests: PATCH /api/dashboard/ideas/{id}/status requires admin; valid transition succeeds and records history; invalid transition returns 400; declined requires note; concurrent edit returns 409
- [ ] 5.4 Implement status update endpoint with transition validation, history recording, optimistic locking
- [ ] 5.5 Create status change notification email template (respect customer prefs)

**Frontend (loosely tested):**
- [ ] 5.6 Build admin dashboard page (idea list, status breakdown counts, filters, search, sort)
- [ ] 5.7 Build admin idea detail page (status update dropdown, note field, submit + notify)
- [ ] 5.8 Show status banner + friendly label on customer-facing idea detail
- [ ] 5.9 Show status history timeline on idea detail (both customer and admin views)
- [ ] 5.10 Component test: status update form rejects invalid transitions client-side

**E2E checkpoint:**
- [ ] 5.11 E2E: admin updates status → history recorded → customer sees new status on detail page → customer notification email queued

## 6. Comments

Goal: logged-in users comment publicly; admins add internal notes; admins comment → customer notified.

**Comments (TDD):**
- [ ] 6.1 Write failing tests: POST /api/ideas/{id}/comments requires login; creates public comment; is_internal flag creates admin note; GET /api/ideas/{id}/comments hides internal notes from non-admins
- [ ] 6.2 Implement comments endpoints (POST with is_internal, GET with role-based filtering)
- [ ] 6.3 Create comment notification email template (respect customer prefs)
- [ ] 6.4 Write failing test: admin public comment queues notification email to submitter; submitter with comments disabled does not get email
- [ ] 6.5 Wire notification prefs into comment email send

**Frontend (loosely tested):**
- [ ] 6.6 Build comment list and comment form on idea detail (both views)
- [ ] 6.7 Internal note toggle on admin view, internal notes hidden on customer view
- [ ] 6.8 Component test: internal note checkbox toggles visibility indicator

**E2E checkpoint:**
- [ ] 6.9 E2E: customer comments on idea → comment appears → admin adds internal note → customer can't see it → admin adds public comment → customer gets email

## 7. Notifications & Email Resilience

Goal: every email respects preferences, failures retry, admin sees failures, daily admin digest works.

**Email queue (TDD):**
- [ ] 7.1 Write failing tests: send_email_with_retry queues on SMTP failure; retry attempts succeed; exhausted retries mark as failed; successful send removes from queue
- [ ] 7.2 Implement email queue + retry logic (1/5/15 min exponential backoff)
- [ ] 7.3 Write failing test: queue processor endpoint picks up pending emails with past next_retry_at
- [ ] 7.4 Implement queue processor endpoint (called by cron or on read)

**Preferences + digest (TDD):**
- [ ] 7.5 Write failing tests: status email skipped when notify_status_changes=false; comment email skipped when notify_comments=false; verification/reset emails always sent regardless of prefs
- [ ] 7.6 Wire notification prefs checks into all email sends
- [ ] 7.7 Write failing tests: daily digest email includes new ideas from last 24h; sends nothing when no new ideas; skipped when admin has digest disabled
- [ ] 7.8 Implement daily admin digest (template + scheduler hook)

**Failed notifications UI (TDD):**
- [ ] 7.9 Write failing tests: GET /api/dashboard/failed-emails returns failed queue items (admin only); POST retry re-queues immediately
- [ ] 7.10 Implement failed-emails list + retry endpoints

**Frontend (loosely tested):**
- [ ] 7.11 Build account settings page (change password, change email, notification toggles)
- [ ] 7.12 Build failed notifications panel in admin dashboard with manual retry button

**E2E checkpoint:**
- [ ] 7.13 E2E: trigger failed email (stop mock SMTP) → appears in admin failed panel → restart SMTP → click retry → email sends

## 8. Hardening & Polish

Goal: merge duplicates, comment moderation, accessibility, ops. Can be deferred or partially shipped.

**Idea merging (TDD):**
- [ ] 8.1 Write failing tests: POST /api/dashboard/ideas/{id}/merge transfers unique votes; voter on both ideas counted once; duplicate soft-deleted; submitter notified; history records merge
- [ ] 8.2 Implement merge endpoint (transfer votes, soft-delete duplicate, notify, record history)
- [ ] 8.3 Build merge UI in admin idea detail

**Comment moderation (TDD):**
- [ ] 8.4 Write failing tests: PATCH /api/comments/{id} works within 15 min for author, fails after, fails for non-author; DELETE same rules + admin can delete any; edited_at set on edit
- [ ] 8.5 Implement comment edit/delete endpoints + "(edited)" indicator

**Idea edit + delete (TDD):**
- [ ] 8.6 Write failing tests: PATCH /api/ideas/{id} works for author with no engagement, fails with votes/comments, fails for non-author; DELETE by admin soft-deletes
- [ ] 8.7 Implement idea edit (author, pre-engagement) and soft-delete (admin)

**Accessibility:**
- [ ] 8.8 WCAG 2.1 AA audit: keyboard nav, focus states, ARIA labels, color contrast, screen reader test (VoiceOver)

**Ops:**
- [ ] 8.9 Verify backup + restore drill (restore to a scratch DB, confirm data intact)
- [ ] 8.10 CSRF protection middleware, CORS config, rate limiting middleware
- [ ] 8.11 Mobile-responsive pass on all pages

---

**Ship milestone:** After Slice 5, the product is usable — customers submit/vote, admins triage and update status, customers get notified. Slices 6–8 add comments, notification polish, and hardening. Each can be reviewed and shipped independently.

**TDD rhythm:** For each feature pair, the apply phase runs the test task (Red) then the implementation task (Green). Scaffold, frontend-build, and E2E tasks are not test-first by design.