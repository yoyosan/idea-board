## Context

Our company needs a simple way to collect and prioritize customer feature requests. Ideas are currently scattered across emails, support tickets, and conversations, making it impossible to know what customers actually want. We need something working in weeks, not months.

**Important:** This is for feature requests only, NOT replacing our support system.

## Goals / Non-Goals

**Goals:**
- Dead-simple submission for customers (no barriers)
- Minimal overhead for the team
- Actually help prioritize what to build
- Working in 2-3 weeks

**Non-Goals:**
- Replacing support system
- Complex analytics or reporting (future)
- Mobile app (web-responsive only)
- Integration with Jira/Asana (future)
- Threading/nesting comments (keep it flat)
- File attachments (keep it simple)

## Decisions

### 1. Backend: FastAPI (Python 3.14)
**Decision:** Build API with FastAPI framework on Python 3.14.
**Rationale:** Python 3.14 has performance improvements and better async support. FastAPI is fast, modern, auto-generates OpenAPI docs.
**Alternatives considered:** Django (heavier), Express (more setup needed).

### Package Manager: uv
**Decision:** Use uv for Python package management.
**Rationale:** 10-100x faster than pip, handles dependencies and virtual environments, lockfile support.
**Alternatives considered:** pip (slow), poetry (heavier), pip-tools (limited).

### 2. Database: PostgreSQL with Async SQLAlchemy
**Decision:** PostgreSQL with async SQLAlchemy (using asyncpg driver) and Alembic migrations.
**Rationale:** Async SQLAlchemy provides non-blocking database access. asyncpg is the fastest PostgreSQL driver for Python.
**Alternatives considered:** Sync SQLAlchemy (blocks event loop), Raw SQL (more work).

### 3. Authentication: User Accounts (Email/Password) for Everyone
**Decision:** Standard user authentication with email and password. Same mechanism for customers and admins — role differentiates them.
**Rationale:** Simplest mental model. Users register once, log in with credentials, stay logged in. No email dependency for auth (unlike magic links). Reliable and predictable.
**Flow:**
1. Customer visits site → clicks "Sign Up" → enters email + password → account created → logged in
2. Subsequent visits → click "Log In" → enter email + password → logged in
3. All actions (submit, vote, comment, view My Ideas) require a logged-in account
4. Admins use same login, but `role: admin` grants dashboard access
**Security:**
- Passwords hashed with bcrypt (cost factor 12)
- Minimum 8-character password
- JWT in HttpOnly cookie (30-day expiry for customers, 24-hour for admins)
- Password reset via email link (one-time token, 1-hour expiry)
**Alternatives considered:** Magic links (email dependency, slow re-login), OAuth (user said no), no auth (vote manipulation).

### 4. Frontend: Next.js (React) with Bun
**Decision:** Next.js for customer portal and internal dashboard, using Bun as the package manager and runtime.
**Rationale:** Fast, SEO-friendly for public pages, good developer experience. Bun installs deps ~10x faster than npm and pairs naturally with the modern toolchain (Biome, Vitest, Playwright).
**Alternatives considered:** Plain React (slower), Vue.js (team knows React), npm/Yarn/pnpm (slower installs, larger lockfiles).

## Guardrails (Quality Tooling)

Project-wide quality gates set up before Slice 1. The "fast tooling" stack: uv + Ruff (Python), Bun + Biome (frontend).

### Python
| Tool | Role |
|------|------|
| **uv** | Package manager + virtualenv (chosen earlier) |
| **Ruff** | Linter + formatter (replaces flake8 + black + isort) — same team as uv, Rust-fast |
| **Pyright** | Static type checker — Microsoft's tool, powers VS Code Python, excellent FastAPI support |
| **pytest** + pytest-asyncio | Test runner (chosen earlier) |
| **pip-audit** | Dependency vulnerability scanner |

### Frontend
| Tool | Role |
|------|------|
| **Bun** | Package manager + runtime |
| **Biome** | Linter + formatter (replaces ESLint + Prettier) — one tool, Rust-fast, zero config |
| **Vitest** | Unit/component test runner |
| **Playwright** | E2E tests (chosen earlier) |
| **bun audit** | Dependency vulnerability scanner |

### Cross-cutting
| Tool | Role |
|------|------|
| **pre-commit** | Runs all checks locally before each commit (ruff, biome, gitleaks, pyright, type check) |
| **gitleaks** | Scans staged files for committed secrets before they reach history |
| **commitlint** + **commitizen** | Enforces Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.) — enables auto-generated changelogs |
| **GitHub branch protection** | No direct pushes to `main`; PR review required; CI must pass before merge |

### CI Pipeline (runs on every PR)
```
1. Python:   uv run ruff check . && uv run ruff format --check . && uv run pyright && uv run pytest
2. Frontend: bun install --frozen-lockfile && biome ci . && bun run test && bun run test:e2e
3. Security: gitleaks scan + uv run pip-audit + bun audit
4. Block merge until all green
```

### 5. Notifications: Async Email with PostgreSQL Fallback Queue
**Decision:** Send emails using aiosmtplib. If sending fails, store in a PostgreSQL queue and retry with exponential backoff.
**Rationale:** Simple, no external service, and resilient. Failed emails are visible in the admin dashboard so the team knows when the mail service is down.
**Alternatives considered:** SendGrid (external service), Celery (overkill), in-process retries only (silent failures).

### Email Queue Design

```sql
CREATE TABLE email_queue (
  id SERIAL PRIMARY KEY,
  to_email VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- submission, status_change, comment
  idea_id INTEGER REFERENCES ideas(id),
  retry_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending', -- pending, sent, failed
  error_message TEXT,
  next_retry_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Retry Logic

```python
async def send_email_with_retry(to_email, subject, body, type, idea_id):
    try:
        await send_email_async(to_email, subject, body)
        return {"status": "sent"}
    except Exception as e:
        # Store in queue
        queue_item = EmailQueue(
            to_email=to_email,
            subject=subject,
            body=body,
            type=type,
            idea_id=idea_id,
            retry_count=0,
            status="pending",
            error_message=str(e),
            next_retry_at=now() + timedelta(minutes=1)
        )
        await db.add(queue_item)
        await db.commit()

async def process_email_queue():
    pending = await db.execute(
        select(EmailQueue).where(
            EmailQueue.status == "pending",
            EmailQueue.next_retry_at <= now()
        )
    )
    for item in pending.scalars():
        try:
            await send_email_async(item.to_email, item.subject, item.body)
            item.status = "sent"
        except Exception as e:
            item.retry_count += 1
            item.error_message = str(e)
            if item.retry_count >= 3:
                item.status = "failed"
            else:
                delays = [1, 5, 15]  # minutes
                item.next_retry_at = now() + timedelta(minutes=delays[item.retry_count - 1])
        await db.commit()
```

**Admin visibility:** Dashboard shows count of failed notifications. Admin can view and retry them.

## Architecture

```
Customer → [Next.js] → [FastAPI] → [PostgreSQL]
                ↓           ↓           ↓
Team    → [Next.js] → [FastAPI] → [asyncpg] → [PostgreSQL]
                        ↓
Emails  ← [aiosmtplib] (async)
                        ↓
Failed emails → [PostgreSQL email_queue]
```

### Async Patterns

```python
# All endpoints are async
@router.post("/api/ideas")
async def create_idea(idea: IdeaCreate, db: AsyncSession = Depends(get_db)):
    # Async database operations
    result = await db.execute(select(Idea).where(...))
    await db.commit()
    
    # Async email with fallback queue
    await send_email_with_retry(
        to_email=idea.email,
        subject="Idea received",
        body="...",
        type="submission",
        idea_id=idea.id
    )
    
    return {"status": "success"}

# Async database session
async def get_db():
    async with AsyncSession(engine) as session:
        yield session

# Atomic vote increment (prevents race conditions)
@router.post("/api/ideas/{idea_id}/vote")
async def vote(idea_id: int, customer: Customer = Depends(get_current_customer), db: AsyncSession = Depends(get_db)):
    # Try to insert vote (unique constraint prevents duplicates)
    vote = Vote(idea_id=idea_id, customer_id=customer.id)
    db.add(vote)
    try:
        await db.commit()
    except IntegrityError:
        raise HTTPException(400, "Already voted")
    
    # Atomic increment — no read-modify-write
    await db.execute(
        update(Idea)
        .where(Idea.id == idea_id)
        .values(votes_count=Idea.votes_count + 1)
    )
    await db.commit()
    return {"status": "voted"}
```

### Database Schema (Minimal)

```sql
-- Users (customers and admins, differentiated by role)
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  role VARCHAR(20) DEFAULT 'customer', -- 'customer' or 'admin'
  status VARCHAR(20) DEFAULT 'pending_verification', -- 'pending_verification' or 'active'
  notify_status_changes BOOLEAN DEFAULT TRUE,
  notify_comments BOOLEAN DEFAULT TRUE,
  notify_digest BOOLEAN DEFAULT TRUE, -- admins only
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Verification and reset tokens (shared table)
CREATE TABLE tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  token_hash VARCHAR(255) UNIQUE NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'email_verification', 'password_reset'
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Ideas table
CREATE TABLE ideas (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'submitted',
  submitted_by INTEGER REFERENCES users(id),
  votes_count INTEGER DEFAULT 0,
  merged_into INTEGER REFERENCES ideas(id),
  deleted_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Votes table (one per user per idea)
CREATE TABLE votes (
  id SERIAL PRIMARY KEY,
  idea_id INTEGER REFERENCES ideas(id),
  user_id INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(idea_id, user_id)
);

-- Comments table (flat, no threading)
CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  idea_id INTEGER REFERENCES ideas(id),
  user_id INTEGER REFERENCES users(id),
  content TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMP NULL,
  deleted_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Status history
CREATE TABLE status_history (
  id SERIAL PRIMARY KEY,
  idea_id INTEGER REFERENCES ideas(id),
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  changed_by INTEGER REFERENCES users(id),
  note TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Email queue
CREATE TABLE email_queue (
  id SERIAL PRIMARY KEY,
  to_email VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  idea_id INTEGER REFERENCES ideas(id),
  retry_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',
  error_message TEXT,
  next_retry_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints (FastAPI)

```
POST   /api/auth/register      - Create customer account (email/password)
POST   /api/auth/login         - Login (email/password) - customers and admins
POST   /api/auth/logout        - Logout (clear session)
POST   /api/auth/forgot-password - Request password reset email
POST   /api/auth/reset-password - Reset password with token
GET    /api/auth/me            - Get current user session

POST   /api/ideas              - Submit new idea (requires login)
GET    /api/ideas              - List ideas (public, sorted by votes)
GET    /api/ideas/{id}         - Get idea details
PATCH  /api/ideas/{id}         - Edit own idea (customer, before engagement)
POST   /api/ideas/{id}/vote    - Upvote an idea (requires login)
DELETE /api/ideas/{id}/vote    - Remove upvote (requires login)
POST   /api/ideas/{id}/comments - Add comment (requires login)
GET    /api/ideas/{id}/comments - List comments (public comments only)

GET    /api/dashboard/ideas    - List all ideas (admin, with filters)
PATCH  /api/dashboard/ideas/{id}/status - Update status (admin)
POST   /api/dashboard/ideas/{id}/internal-note - Add internal note (admin)
DELETE /api/dashboard/ideas/{id} - Soft delete idea (admin)
GET    /api/dashboard/failed-emails - Failed notifications (admin)
POST   /api/dashboard/failed-emails/{id}/retry - Retry failed email (admin)
```

## UI Design System

A simple, clean design system focused on readability and minimal cognitive load.

### Colors
- **Primary**: `#2563eb` (blue) — buttons, links, active states
- **Primary Hover**: `#1d4ed8`
- **Background**: `#f8fafc` (light gray-blue)
- **Surface**: `#ffffff` — cards and forms
- **Text Primary**: `#0f172a` — headings, important text
- **Text Secondary**: `#64748b` — meta text, labels
- **Text Muted**: `#94a3b8` — placeholders, disabled
- **Border**: `#e2e8f0` — inputs, dividers
- **Success**: `#22c55e` — completed, positive actions
- **Warning**: `#f59e0b` — under review
- **Info**: `#3b82f6` — submitted
- **Purple**: `#a855f7` — in progress
- **Green Dark**: `#15803d` — planned

### Typography
- Font: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif
- Headings: 600-800 weight, tight line-height
- Body: 400 weight, 1.6 line-height
- Small/Meta: 0.875rem

### Spacing Scale
- 4px, 8px, 12px, 16px, 20px, 24px, 32px, 48px

### Components

#### Buttons
- Primary: blue background, white text, 8px border-radius
- Ghost/outline: transparent with blue border
- Hover: slightly darker background

#### Cards
- White background, 12px border-radius
- Subtle shadow: `0 1px 3px rgba(0,0,0,0.1)`
- Hover shadow: `0 4px 12px rgba(0,0,0,0.1)`

#### Status Badges
- Rounded pills with background tint
- Colors: submitted (blue), under review (amber), planned (green), in progress (purple), completed (success green)

#### Vote Button
- Arrow icon + count stacked vertically
- Ghost style by default, filled when voted
- Hover changes background

#### Inputs
- 1px border, 10px border-radius
- Focus ring with primary color

### Layout
- Max width: 1200px for dashboard, 640px for forms, 800px for lists
- Mobile-first: stack columns on small screens
- Consistent page header with logo + primary action

### Responsive
- Breakpoints: 640px (sm), 768px (md), 1024px (lg)
- Single column on mobile, grid on desktop where applicable

## UI Mockups

Interactive HTML mockups are available in `mockups/`:

| File | Page | Description |
|------|------|-------------|
| `login.html` | Login | Email/password login form |
| `register.html` | Register | New customer account signup |
| `submit.html` | Customer Submission | Idea submission form (requires login) |
| `my-ideas.html` | My Ideas | Customer's submitted and voted ideas |
| `ideas.html` | Browse Ideas | Popular ideas list with upvote buttons |
| `idea-detail.html` | Idea Detail | Customer view of idea with status, comments |
| `dashboard.html` | Admin Dashboard | Admin view with filters and idea list |
| `admin-detail.html` | Admin Idea Detail | Status update, internal notes, voter list |

Open in browser: `open mockups/login.html`

## Security

### Admin Bootstrap
The first admin account is created via a CLI command during deployment:

```bash
uv run python -m app.cli create-admin --email admin@company.com --password <secure>
```

This prevents lockout on first deploy. Additional admins can be promoted from the dashboard (future enhancement).

### Password Security
- **Hashing:** bcrypt with cost factor 12
- **Minimum length:** 8 characters
- **No complexity rules** (per NIST guidance — length over special chars)
- **Breach check:** Reject passwords found in known breaches (HaveIBeenPwned API, optional)
- **Storage:** Only the bcrypt hash is stored; plaintext never logged

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### Password Reset
- User clicks "Forgot password" → enters email → reset link sent
- Token: `secrets.token_urlsafe(32)`, hashed with SHA-256 in DB
- Expiry: 1 hour, single-use
- On reset: invalidate all existing sessions for that user

### Session Management
- **Customer JWT:** 30-day expiry, refreshable
- **Admin JWT:** 24-hour expiry, requires re-login
- **JWT stored:** HttpOnly cookie (not localStorage — prevents XSS theft)
- **Refresh:** Customer sessions auto-refresh on activity

### CSRF Protection
- All state-changing requests require `X-CSRF-Token` header
- Token issued on login, stored in HttpOnly cookie with `SameSite=Strict`
- FastAPI middleware validates token on POST/PATCH/DELETE

### CORS
- Allowed origins: production frontend URL + localhost (dev only)
- Credentials allowed (for cookies)
- Preflight cache: 1 hour

### XSS Prevention
- All user-generated content (titles, descriptions, comments) is HTML-escaped on render
- React auto-escapes by default; no `dangerouslySetInnerHTML`
- Content-Security-Policy header on all responses

### Rate Limiting
- Login attempts: 10/hour per IP (prevents brute force)
- Register attempts: 5/hour per IP
- Password reset requests: 3/hour per email
- Idea submissions: 10/hour per user
- Comments: 30/hour per user
- Votes: 100/hour per user
- Implemented via FastAPI middleware with Redis or in-memory (MVP: in-memory)

### Bot Protection
- hCaptcha on registration page only (privacy-friendly alternative to reCAPTCHA)
- Server-side verification of captcha token before account creation
- Logged-in users don't see captcha on submit/comment/vote

### Disposable Email Blocking
Block known disposable domains at registration. Use the `disposable-email-domains` list (community-maintained, ~100k domains) loaded into a Python set on startup.

```python
# config/blocked_domains.txt — one domain per line, editable without redeploy
# mailinator.com
# 10minutemail.com
# guerrillamail.com
# ... (synced from https://github.com/disposable-email-domains/disposable-email-domains)

ALLOWED_ALIAS_DOMAINS = {
    "aleeas.com",       # SimpleLogin
    "simplelogin.com",
    "duck.com",         # DuckDuckGo
    "duckmail.com",
    "privaterelay.appleid.com",  # Apple Hide My Email
    "fastmail.com",     # Fastmail aliases (user subdomains)
}

def is_blocked_email(email: str) -> bool:
    domain = email.split("@")[-1].lower()
    if domain in ALLOWED_ALIAS_DOMAINS:
        return False
    return domain in BLOCKED_DOMAINS  # loaded from file on startup
```

**Updates:** Admin edits `config/blocked_domains.txt` and restarts app — no deploy needed. Optional: auto-sync from GitHub weekly via cron.

### Accessibility (WCAG 2.1 AA)
- Semantic HTML throughout (proper headings, landmarks, buttons vs links)
- All interactive elements keyboard-navigable with visible focus states
- Color contrast ratio ≥ 4.5:1 for text, ≥ 3:1 for large text
- ARIA labels on icon-only buttons (vote, delete, etc.)
- Form inputs have associated `<label>` elements
- Error messages announced via `aria-live` regions
- Skip-to-content link on every page
- Tested with screen reader (VoiceOver/NVDA) before launch

## Search and Sorting

### Search (PostgreSQL Full-Text)
```sql
-- Create search index on ideas
CREATE INDEX ideas_search_idx ON ideas 
  USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '')));

-- Query with relevance ranking (title weighted 2x description)
SELECT *, ts_rank(setweight(to_tsvector(title), 'A') || setweight(to_tsvector(description), 'B'), query) AS rank
FROM ideas, plainto_tsquery('english', $1) query
WHERE to_tsvector(title || ' ' || description) @@ query
ORDER BY rank DESC;
```

### Sort Options
- **Top:** `ORDER BY votes_count DESC, created_at DESC`
- **Recent:** `ORDER BY created_at DESC`
- **Trending:** `ORDER BY (votes in last 7 days) DESC` — requires `votes` table query with date filter

## Pagination (Cursor-based)
```python
# Infinite scroll using cursor-based pagination
@router.get("/api/ideas")
async def list_ideas(
    sort: str = "top",
    cursor: str | None = None,  # base64 encoded "id:votecount" or "id:createdat"
    limit: int = 20,
    db: AsyncSession = Depends(get_db)
):
    # Decode cursor, build WHERE clause based on sort strategy
    # Return items + next_cursor (null if no more)
    ...
```

## Idea Merging

When admin marks idea B as duplicate of idea A:
```sql
-- Transfer unique votes
INSERT INTO votes (idea_id, user_id, created_at)
SELECT $primary_id, user_id, NOW() FROM votes
WHERE idea_id = $duplicate_id
ON CONFLICT (idea_id, user_id) DO NOTHING;

-- Update vote count on primary
UPDATE ideas SET votes_count = (
  SELECT COUNT(*) FROM votes WHERE idea_id = $primary_id
) WHERE id = $primary_id;

-- Soft-delete duplicate
UPDATE ideas SET deleted_at = NOW(), merged_into = $primary_id WHERE id = $duplicate_id;

-- Record in status history
INSERT INTO status_history (idea_id, old_status, new_status, changed_by, note)
VALUES ($duplicate_id, $old_status, 'merged', $admin_id, 'Merged into: ' || $primary_title);
```

## Concurrent Edit Protection (Optimistic Locking)

```python
@router.patch("/api/dashboard/ideas/{idea_id}/status")
async def update_status(
    idea_id: int,
    update: StatusUpdate,
    expected_updated_at: datetime,  # client sends the updated_at they loaded
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        update(Idea)
        .where(Idea.id == idea_id, Idea.updated_at == expected_updated_at)
        .values(status=update.status, updated_at=datetime.now())
    )
    if result.rowcount == 0:
        raise HTTPException(409, "This idea was modified by another admin. Refresh to see changes.")
    await db.commit()
```

## Operations

### Backups
- **Daily** automated PostgreSQL backups (managed by hosting provider, e.g., Railway/Render)
- **Point-in-time recovery** (PITR) enabled — restore to any point in last 7 days
- **Restore drill** performed once before launch to verify backups work

### Error Tracking
- **Sentry** integrated in both FastAPI (backend errors) and Next.js (frontend errors)
- Errors captured with stack trace, user context, and request data
- Alerts to team Slack/email on new errors above threshold

### Testing
- **pytest** for API endpoint tests (FastAPI TestClient)
- Target: 80% coverage on critical paths (auth, submission, voting, status updates)
- E2E tests for key flows: register → verify → submit → vote → admin status update
- Run in CI before deploy

### Error Pages
- Custom branded 404 page: "This idea wasn't found" with link to browse ideas
- Custom branded 500 page: "Something went wrong — we've been notified" with link home
- Next.js `error.tsx` and `not-found.tsx` boundaries

Emails are masked in **customer-facing** views to protect privacy. Admin views show full emails since the team needs them for follow-up.

```python
def mask_email(email: str) -> str:
    """Mask email for display: j***@***.com"""
    local, domain = email.split("@")
    masked_local = local[0] + "***" if local else "***"
    domain_parts = domain.split(".")
    masked_domain = "***." + domain_parts[-1] if domain_parts else "***"
    return f"{masked_local}@{masked_domain}"

# Examples:
# john@example.com    -> j***@***.com
# sarah@company.com  -> s***@***.com
# admin@co.uk        -> a***@***.uk
```

**Masked (customer-facing views):**
- Comment author email on public idea pages
- Any email shown to non-admin users

**Full email shown (admin views):**
- Submitter email in admin dashboard and admin idea detail
- Voter list in admin idea detail
- Internal note authors
- Admin can click to copy full email for follow-up

**Never exposed:**
- Voter emails to other customers (only vote count is public)
- Admin account emails to customers

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Email delivery delays | Store in queue, retry with backoff, admin dashboard shows failures |
| Vote manipulation (fake emails) | Magic link verification required for voting |
| Team adoption | Keep dashboard dead simple, demonstrate value in standup |
| Scale beyond 10k ideas | Add pagination and indexing when needed |
| Mail service down | PostgreSQL email queue + retry + admin alerts |

## Timeline

| Week | Deliverable |
|------|-------------|
| 1 | FastAPI setup + PostgreSQL + Basic submission API |
| 2 | Auth + Internal dashboard API + Status updates |
| 3 | Voting + Comments + Email notifications + failed email queue |
| 4 | Next.js frontend + Testing + Launch |

**Rollback:** If issues, point customers to email feature@company.com instead.