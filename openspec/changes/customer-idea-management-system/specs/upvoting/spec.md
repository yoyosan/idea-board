## ADDED Requirements

### Requirement: Voting requires login
The system SHALL only allow upvoting from logged-in users.

#### Scenario: Logged-in user upvotes an idea
- **WHEN** logged-in user clicks upvote button on an idea
- **THEN** system increments vote count and records their user ID

#### Scenario: Visitor tries to upvote without login
- **WHEN** a visitor who isn't logged in clicks upvote
- **THEN** system prompts them to log in or register

### Requirement: One vote per user
The system SHALL enforce one vote per user per idea.

#### Scenario: User upvotes an idea
- **WHEN** logged-in user clicks upvote button on an idea
- **THEN** system increments vote count and records their user ID

#### Scenario: User tries to upvote twice
- **WHEN** user attempts to upvote same idea twice
- **THEN** system prevents duplicate vote and shows "Already upvoted" state

#### Scenario: User removes upvote
- **WHEN** user clicks upvote on already-upvoted idea
- **THEN** system decrements vote count and removes their vote

### Requirement: Admin sees vote counts for prioritization
The system SHALL display vote counts to admins for roadmap prioritization.

#### Scenario: Vote count in dashboard
- **WHEN** admin views idea list
- **THEN** system displays vote count for each idea (sorted by votes by default)

#### Scenario: Voter list with full emails (admin)
- **WHEN** admin views idea details
- **THEN** system displays total vote count and list of voter emails (full, for follow-up)

### Requirement: Public vote visibility
The system SHALL display vote counts publicly to show customers their voice matters.

#### Scenario: Customer sees vote count
- **WHEN** customer views any idea
- **THEN** system displays current vote count (but not voter identities)