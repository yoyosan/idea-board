## ADDED Requirements

### Requirement: Customer must be logged in to submit
The system SHALL require a logged-in user account to submit an idea.

#### Scenario: Logged-in customer submits idea
- **WHEN** logged-in customer fills out the submission form and clicks submit
- **THEN** system creates the idea with status `submitted` and shows confirmation with reference number

#### Scenario: Visitor not logged in
- **WHEN** a visitor who isn't logged in tries to access the submission form
- **THEN** system redirects them to the login page with a redirect back to the form after login

### Requirement: Submission form is simple
The system SHALL provide a minimal form for submitting ideas.

#### Scenario: Form fields
- **WHEN** customer views the submission form
- **THEN** system displays: Title (required), Description (required), Category (required, dropdown)

#### Scenario: Missing required fields
- **WHEN** customer submits without title or description
- **THEN** system displays validation errors and does not create the idea

### Requirement: Real-time duplicate detection
The system SHALL detect similar titles as the customer types and suggest upvoting existing ideas instead.

#### Scenario: Similar title detected
- **WHEN** customer types a title with >70% similarity to an existing idea (using PostgreSQL trigram search)
- **THEN** system displays matching ideas with vote counts and an option to upvote instead

#### Scenario: No similar ideas
- **WHEN** customer types a title with no matches
- **THEN** system shows no suggestions and allows submission

### Requirement: Idea categories are predefined
The system SHALL provide a predefined list of categories for idea classification.

#### Scenario: Selecting category during submission
- **WHEN** customer views the submission form
- **THEN** system displays predefined options: Feature Request, Improvement, New Capability, Integration Request

### Requirement: Customer receives confirmation
The system SHALL provide immediate confirmation that the idea was submitted.

#### Scenario: Confirmation displayed
- **WHEN** customer successfully submits an idea
- **THEN** system displays "Thanks! Your idea has been submitted" with idea reference number

#### Scenario: Confirmation email sent
- **WHEN** customer submits an idea
- **THEN** system sends confirmation email with idea reference and link

### Requirement: Customer can edit their own idea
The system SHALL allow customers to edit the title and description of their own ideas.

#### Scenario: Customer edits idea with no engagement
- **WHEN** customer edits their own idea that has no votes or comments
- **THEN** system updates the title and description

#### Scenario: Customer cannot edit idea with engagement
- **WHEN** customer attempts to edit an idea that has votes or comments
- **THEN** system denies the edit and suggests contacting the team

#### Scenario: Customer cannot edit others' ideas
- **WHEN** customer attempts to edit an idea they didn't submit
- **THEN** system denies the action

### Requirement: Admin can delete ideas
The system SHALL allow admins to delete spam or inappropriate ideas.

#### Scenario: Admin deletes an idea
- **WHEN** admin clicks delete on an idea
- **THEN** system asks for confirmation and soft-deletes the idea (sets `deleted_at`), removing it from public and admin views

#### Scenario: Deleted idea not visible
- **WHEN** an idea is soft-deleted
- **THEN** system excludes it from all public and admin list views