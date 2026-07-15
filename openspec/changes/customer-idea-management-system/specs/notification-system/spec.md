## ADDED Requirements

### Requirement: Email on status change
The system SHALL send email to customers when their idea status changes (unless they've opted out).

#### Scenario: Status update notification
- **WHEN** admin changes idea status
- **THEN** system sends email to submitter with friendly update (e.g., "Your idea is now Planned!") if they haven't disabled status notifications

#### Scenario: Decline notification includes reason
- **WHEN** admin declines an idea
- **THEN** notification email includes the reason note from the admin

### Requirement: Email on team comment
The system SHALL send email to customers when admin adds a public comment (unless opted out).

#### Scenario: Comment notification
- **WHEN** admin adds public comment to an idea
- **THEN** system sends email to submitter with comment preview and link (if they haven't disabled comment notifications)

### Requirement: Confirmation email on submission
The system SHALL send brief confirmation when idea is submitted.

#### Scenario: Submission confirmation
- **WHEN** customer successfully submits idea
- **THEN** system sends email confirming receipt with idea reference number

### Requirement: Customer notification preferences
The system SHALL allow customers to manage which emails they receive.

#### Scenario: Granular toggles
- **WHEN** customer visits notification settings
- **THEN** system displays separate toggles: "Status changes on my ideas", "Comments on my ideas"

#### Scenario: Disable status notifications
- **WHEN** customer turns off "Status changes" toggle
- **THEN** system stops sending status change emails but keeps comment notifications on

#### Scenario: Disable all notifications
- **WHEN** customer turns off all toggles
- **THEN** system stops sending all notification emails (except password reset and verification, which are always sent)

#### Scenario: Re-enable notifications
- **WHEN** customer turns a toggle back on
- **THEN** system resumes sending that type of email

### Requirement: Failed emails are retried
The system SHALL retry failed emails and notify admins if the mail service is down.

#### Scenario: Email fails on first attempt
- **WHEN** email fails to send
- **THEN** system stores the failed email in a queue with retry count and error message

#### Scenario: Retry with exponential backoff
- **WHEN** email is in the failed queue
- **THEN** system retries up to 3 times with delays of 1 minute, 5 minutes, and 15 minutes

#### Scenario: Email eventually succeeds
- **WHEN** retry attempt succeeds
- **THEN** system marks email as sent and removes it from failed queue

#### Scenario: All retries exhausted
- **WHEN** email fails after 3 retry attempts
- **THEN** system marks it as permanently failed and shows it in the admin dashboard

### Requirement: Admin sees failed notifications
The system SHALL display failed email notifications in the admin dashboard.

#### Scenario: Failed notification count
- **WHEN** admin views dashboard
- **THEN** system shows a count of failed notifications requiring attention

#### Scenario: Retry failed email
- **WHEN** admin clicks retry on a failed notification
- **THEN** system attempts to send it again immediately

### Requirement: Admin receives daily digest of new ideas
The system SHALL send admins a daily email summarizing new idea submissions.

#### Scenario: Daily digest sent
- **WHEN** 24 hours have passed since the last digest
- **THEN** system sends an email to all admins listing new ideas submitted in the last 24 hours with vote counts

#### Scenario: No new ideas
- **WHEN** 24 hours pass with no new ideas
- **THEN** system does not send a digest

#### Scenario: Admin can disable digest
- **WHEN** admin disables daily digest in settings
- **THEN** system stops sending digest emails to that admin