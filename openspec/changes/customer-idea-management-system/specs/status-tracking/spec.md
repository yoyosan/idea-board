## ADDED Requirements

### Requirement: Customers can see idea status
The system SHALL display idea status prominently so customers know where their request stands.

#### Scenario: Status visible on idea page
- **WHEN** customer views their submitted idea
- **THEN** system displays current status with friendly label (e.g., "We're reviewing this", "Planned for next quarter", "In progress", "Completed!", "Not planned")

#### Scenario: Status visible in confirmation
- **WHEN** customer submits new idea
- **THEN** system shows "Status: Submitted" in confirmation

### Requirement: Status workflow with transitions
The system SHALL support a predefined set of statuses with defined transitions.

#### Scenario: Status flow
- **WHEN** admin updates idea status
- **THEN** system only allows valid transitions:

```
submitted → under_review → planned → in_progress → completed
submitted → under_review → declined
under_review → declined
planned → declined (rare, but allowed)
```

#### Scenario: Default status on submission
- **WHEN** customer submits a new idea
- **THEN** system assigns status `submitted`

#### Scenario: Decline requires reason
- **WHEN** admin sets status to `declined`
- **THEN** system requires a note explaining why (e.g., "Out of scope", "Not aligned with roadmap")

#### Scenario: Invalid status transition
- **WHEN** admin attempts an invalid transition (e.g., `completed` → `submitted`)
- **THEN** system rejects the change with error message

### Requirement: Status changes trigger email notifications
The system SHALL notify customers when their idea status changes.

#### Scenario: Status change notification
- **WHEN** admin changes idea status
- **THEN** system sends email to customer with friendly status update (e.g., "Great news! Your idea is now Planned")

#### Scenario: Decline notification includes reason
- **WHEN** admin declines an idea
- **THEN** notification email includes the reason note from the admin

#### Scenario: Optional note to customer
- **WHEN** admin changes status and adds a note
- **THEN** notification email includes the note from the admin

### Requirement: Status history is visible
The system SHALL show customers the timeline of status changes for their ideas.

#### Scenario: Viewing status history
- **WHEN** customer views their idea details
- **THEN** system displays timeline showing each status change with date and friendly label