## ADDED Requirements

### Requirement: Users can comment on any idea after login
The system SHALL allow logged-in users to add public comments to any idea.

#### Scenario: Logged-in user adds comment
- **WHEN** logged-in user submits a comment on an idea
- **THEN** system stores the comment and displays it to both customers and admin

#### Scenario: Visitor tries to comment without login
- **WHEN** a visitor who isn't logged in attempts to submit a comment
- **THEN** system prompts them to log in or register

### Requirement: Admin can add public comments
The system SHALL allow admins to add public comments visible to customers.

#### Scenario: Admin adds public comment
- **WHEN** admin adds comment to any idea
- **THEN** system stores the comment and displays it to both admin and customer

#### Scenario: Public comment triggers notification
- **WHEN** admin posts a comment on an idea
- **THEN** system sends email notification to the idea submitter (if they haven't disabled it)

### Requirement: Admin can add internal notes
The system SHALL allow admins to add private notes visible only to admins.

#### Scenario: Admin adds internal note
- **WHEN** admin selects "Internal Note" option and adds note
- **THEN** system stores the note and displays it only to admins

#### Scenario: Internal note hidden from customers
- **WHEN** customer views an idea with internal notes
- **THEN** system does not display internal notes to the customer

### Requirement: Comments show author and timestamp
The system SHALL display who made each comment and when.

#### Scenario: Comment metadata displayed
- **WHEN** a comment is displayed
- **THEN** system shows author email (masked in customer view, full in admin view), role indicator (Customer/Admin), and relative timestamp

### Requirement: Users can edit their own comments
The system SHALL allow users to edit their own comments within a time window.

#### Scenario: User edits comment within 15 minutes
- **WHEN** user edits their own comment within 15 minutes of posting
- **THEN** system updates the comment and marks it as "edited"

#### Scenario: User cannot edit after 15 minutes
- **WHEN** user attempts to edit their comment after 15 minutes
- **THEN** system denies the edit (encourage contacting admin if needed)

#### Scenario: User cannot edit others' comments
- **WHEN** user attempts to edit a comment they didn't write
- **THEN** system denies the action

#### Scenario: Edited indicator
- **WHEN** a comment has been edited
- **THEN** system displays "(edited)" next to the timestamp

### Requirement: Users can delete their own comments
The system SHALL allow users to delete their own comments within a time window.

#### Scenario: User deletes comment within 15 minutes
- **WHEN** user deletes their own comment within 15 minutes of posting
- **THEN** system removes the comment and shows confirmation

#### Scenario: User cannot delete after 15 minutes
- **WHEN** user attempts to delete their comment after 15 minutes
- **THEN** system denies the deletion

### Requirement: Admins can delete any comment
The system SHALL allow admins to delete inappropriate comments.

#### Scenario: Admin deletes comment
- **WHEN** admin clicks delete on any comment and confirms
- **THEN** system soft-deletes the comment (sets `deleted_at`), removing it from view

#### Scenario: Deleted comment not visible
- **WHEN** a comment is soft-deleted
- **THEN** system excludes it from all views