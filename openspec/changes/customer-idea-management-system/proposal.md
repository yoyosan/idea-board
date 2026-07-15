## Why

Our company needs a structured way to collect and prioritize product feature requests from customers. Currently, ideas are scattered across emails, support tickets, and conversations, making it impossible to know what customers actually want. This leads to building features customers don't want while missing opportunities they're asking for.

**Important scope clarification:** This system is for **feature requests only** — it is NOT replacing our existing support system.

## What Changes

- Implement user authentication (email/password accounts) for customers and admins
- Customer-facing portal for submitting feature requests (requires login)
- Upvoting so customers can signal demand for ideas, with vote counts driving prioritization
- Commenting on any idea (public) plus internal admin-only notes
- Track idea lifecycle through a status workflow: Submitted → Under Review → Planned → In Progress → Completed (or Declined)
- Automated email notifications to customers on status changes and comments
- Resilient email delivery with a PostgreSQL-backed retry queue for failed emails
- Internal admin dashboard for viewing, filtering, and managing all ideas
- "My Ideas" page for customers to track their submissions and votes

## Design Principles (from team feedback)

1. **Dead simple for customers** — Standard accounts, no friction beyond a one-time signup
2. **Minimal team overhead** — Not creating more work for ourselves
3. **Helps prioritize** — Vote counts and filtering actually useful for roadmap decisions
4. **Quick delivery** — Working in a few weeks, not perfect in months

## Out of Scope (Explicitly)

The following features are **deliberately excluded** from this project to protect scope and timeline. They are documented here so they are not re-litigated during build. If any become genuinely necessary, they warrant a separate proposal.

**The decision test:** Does this help a customer submit an idea, or an admin decide what to build? If neither, it's out of scope.

### Security Theater
- **2FA / MFA** — Email verification is sufficient for an idea board; TOTP adds auth complexity for ~zero threat-model benefit
- **Password complexity rules** (uppercase + symbol + number) — NIST 874 recommends against these; length (8+) is what matters
- **Device / session management dashboard** — Logout-everywhere on password change covers the real need
- **Full admin audit log** — Status history already covers the important trail; a complete audit log is a maintenance burden

### Engagement Bait
- **Downvotes** — Turns the board into a battleground; upvote-only is the proven model for feedback tools
- **Comment likes / hearts** — Reddit-ification with marginal value; adds counts, race conditions, moderation
- **User profiles and avatars** — Nobody visits an idea board to browse profiles; would require image upload (already cut) and moderation
- **Follow / subscribe to a user** — Creepy on a B2B tool and useless at our scale
- **Leaderboards, reputation, badges** — Gamification that doesn't fit a feedback tool

### AI Temptations
- **AI auto-categorization** — We have 4 categories; humans pick correctly
- **AI summary of comments** — Not enough comments per idea to justify it for months
- **Recommendation engine** — Duplicate detection at submission covers the real need; a recommender is a separate, bigger system
- **Sentiment analysis** — Cool demo, no admin action it would trigger

### Integrations
- **Jira / Linear / Asana sync** — Its own product; explicitly cut and should not creep back
- **Slack notifications** — A separate integration, not core to this system
- **Webhooks / public API** — Adds versioning, auth, docs, rate-limiting, breaking-change management
- **Email-to-idea** (inbound email parsing) — Parsing inbound email is a time sink with little payoff

### Reporting & Analytics
- **Analytics dashboard with charts** — "Vote velocity over time" is a different product
- **CSV export** — Starts simple, grows to column selection, date ranges, filters
- **Weekly email report to admins** — The daily digest is sufficient
- **Time-in-status metrics** — Ops sub-product, not core

### Technical Gold-Plating
- **Real-time updates (WebSockets)** — An idea board doesn't need live updates; polling on refresh is fine
- **GraphQL** — REST was chosen deliberately for an app this size
- **Feature flag system** — Use env vars and config; don't build LaunchDarkly
- **Event sourcing / CQRS** — Massive overkill; status_history is sufficient
- **Kafka / RabbitMQ** — The PostgreSQL email queue is enough; no message broker
- **PWA / offline support** — Submission requires auth and DB; offline makes no sense

### Polish That Becomes Scope
- **Onboarding tour / walkthrough** — The app is ~7 pages; a tour suggests it's confusing
- **Command palette (Cmd+K)** — Lovely on Linear/Notion; premature here
- **Keyboard shortcuts** — Same
- **Dark mode toggle** — A theme system touches every component; defer
- **i18n / multiple languages** — Tempting to "future-proof" but one locale for the foreseeable future
- **Rich text / markdown editor** — A plain textarea is fine; RTEs are a multi-week tar pit (image paste, sanitization, mobile)

### Custom Workflow
- **Configurable status workflow** — The workflow is intentionally fixed and predictable. Configurable state machines break our transition validation and create a maintenance nightmare. If a new status is needed later, it's a one-line code change, not a configurable feature.

## Capabilities

### New Capabilities
- `authentication`: User registration, login, logout, password reset; JWT sessions in HttpOnly cookies
- `idea-submission`: Logged-in customers submit ideas with real-time duplicate detection; edit own ideas; admin can delete
- `idea-management`: Internal dashboard with filtering, search, prioritization views, and status updates (admin only)
- `upvoting`: Logged-in users upvote ideas; one vote per person; public counts
- `commenting-system`: Public comments (logged-in users + admins) and internal notes (admins only)
- `status-tracking`: Workflow with transitions including Declined status; status history timeline
- `notification-system`: Email notifications with PostgreSQL fallback queue, retry logic, and daily admin digest

### Modified Capabilities
<!-- No existing capabilities are being modified as this is a new system -->

## Impact

- New PostgreSQL database with 7 tables (users, password_reset_tokens, ideas, votes, comments, status_history, email_queue)
- New FastAPI backend with async endpoints and JWT auth
- New Next.js frontend with customer portal (login/register/submit/ideas/my-ideas) and admin dashboard
- Email integration via aiosmtplib with retry queue
- Password hashing with bcrypt, JWT sessions, CSRF protection
- Email masking for privacy in customer-facing views; full emails in admin views