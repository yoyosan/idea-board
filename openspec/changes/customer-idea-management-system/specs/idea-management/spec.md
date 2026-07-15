## ADDED Requirements

### Requirement: Internal dashboard displays all ideas
The system SHALL provide an internal dashboard that displays all submitted ideas prioritized by votes.

#### Scenario: Viewing idea list
- **WHEN** admin accesses the internal dashboard
- **THEN** system displays a list of ideas sorted by vote count (highest first) with title, status, votes, and category

#### Scenario: Empty state
- **WHEN** admin accesses the dashboard and no ideas exist
- **THEN** system displays an empty state with link to share submission form

### Requirement: Admin can filter and search ideas
The system SHALL provide filtering and search capabilities for finding specific ideas.

#### Scenario: Filter by status
- **WHEN** admin selects a status filter (e.g., "Submitted", "Under Review", "Declined")
- **THEN** system displays only ideas with that status

#### Scenario: Filter by category
- **WHEN** admin selects a category filter
- **THEN** system displays only ideas in that category

#### Scenario: Full-text search
- **WHEN** admin enters search terms in the search box
- **THEN** system displays ideas ranked by relevance using PostgreSQL full-text search (title weighted higher than description)

#### Scenario: Combined filters
- **WHEN** admin applies multiple filters simultaneously
- **THEN** system displays ideas matching all selected criteria

### Requirement: Sort options
The system SHALL offer multiple sort options for the ideas list.

#### Scenario: Top (default)
- **WHEN** admin selects "Top" sort
- **THEN** system displays ideas sorted by all-time vote count descending

#### Scenario: Recent
- **WHEN** admin selects "Recent" sort
- **THEN** system displays ideas sorted by submission date descending

#### Scenario: Trending
- **WHEN** admin selects "Trending" sort
- **THEN** system displays ideas sorted by votes received in the last 7 days descending

### Requirement: Admin can view idea details
The system SHALL provide a detailed view for each idea with all associated information.

#### Scenario: Opening idea details
- **WHEN** admin clicks on an idea in the dashboard
- **THEN** system displays full idea details including title, description, category, status, submitter email (full, for follow-up), vote count, and comments

### Requirement: Admin can update status
The system SHALL allow admins to change the status of ideas.

#### Scenario: Admin updates status
- **WHEN** admin changes idea status
- **THEN** system updates the status and records the change with timestamp and user

#### Scenario: Valid status transitions
- **WHEN** admin attempts to change status
- **THEN** system only allows valid transitions: Submitted → Under Review → Planned → In Progress → Completed (or Declined)

### Requirement: Optimistic locking on idea edits
The system SHALL prevent silent overwrites when multiple admins edit the same idea.

#### Scenario: Concurrent edit detected
- **WHEN** admin saves an idea that was modified by another admin since they opened it
- **THEN** system rejects the save and displays "This idea was updated by another admin. Refresh to see their changes."

#### Scenario: No conflict
- **WHEN** admin saves an idea that hasn't been modified since they opened it
- **THEN** system applies the change normally

### Requirement: Admin can merge duplicate ideas
The system SHALL allow admins to merge duplicate ideas, combining their votes.

#### Scenario: Merge ideas
- **WHEN** admin marks an idea as duplicate of another and confirms merge
- **THEN** system transfers all votes from the duplicate to the primary idea, soft-deletes the duplicate, and notifies the duplicate's submitter

#### Scenario: Merge preserves unique voters
- **WHEN** a user voted on both the duplicate and the primary
- **THEN** system counts their vote only once on the primary

#### Scenario: Merge shows on history
- **WHEN** ideas are merged
- **THEN** system records the merge in the primary idea's status history with the duplicate's title

### Requirement: Dashboard helps prioritize
The system SHALL provide views that help the admin decide what to build next.

#### Scenario: Status breakdown
- **WHEN** admin views dashboard
- **THEN** system shows count of ideas in each status at top (e.g., "12 Submitted, 5 Under Review, 3 Planned")