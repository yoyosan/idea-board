## ADDED Requirements

### Requirement: Email verification required before login
The system SHALL require email verification before a new account can be used.

#### Scenario: Registration creates pending account
- **WHEN** visitor enters email and password on the register page
- **THEN** system creates account with status `pending_verification` and sends a verification email

#### Scenario: Verification link activates account
- **WHEN** user clicks the verification link in the email
- **THEN** system sets account status to `active`, logs the user in, and redirects to intended page

#### Scenario: Unverified account cannot log in
- **WHEN** unverified user attempts to log in
- **THEN** system displays "Please verify your email" and offers to resend the link

#### Scenario: Verification link expired
- **WHEN** user clicks a verification link older than 24 hours
- **THEN** system displays error and offers to resend

#### Scenario: Resend verification
- **WHEN** user requests a new verification email
- **THEN** system invalidates the old token and sends a new one

### Requirement: Customers can register an account
The system SHALL allow anyone to create a customer account with email and password.

#### Scenario: Successful registration
- **WHEN** visitor enters email and password (8+ chars) and passes hCaptcha
- **THEN** system creates a pending account and sends verification email

#### Scenario: Email already registered
- **WHEN** visitor attempts to register with an email that already exists
- **THEN** system displays error and offers to log in instead

#### Scenario: Password too short
- **WHEN** visitor enters a password shorter than 8 characters
- **THEN** system displays validation error and does not create the account

### Requirement: Users can log in
The system SHALL allow registered, verified users to log in with email and password.

#### Scenario: Successful login
- **WHEN** verified user enters correct email and password
- **THEN** system creates a session (JWT in HttpOnly cookie) and redirects to intended page

#### Scenario: Incorrect password
- **WHEN** user enters wrong password
- **THEN** system displays generic "Invalid email or password" error (no email enumeration)

#### Scenario: Admin login
- **WHEN** admin enters correct credentials
- **THEN** system creates an admin session (24-hour expiry) and redirects to dashboard

### Requirement: Users can log out
The system SHALL allow users to log out, ending their session.

#### Scenario: Logout
- **WHEN** user clicks logout
- **THEN** system clears the session cookie and redirects to the public ideas page

### Requirement: Users can reset password
The system SHALL allow users to reset a forgotten password via email.

#### Scenario: Request reset
- **WHEN** user clicks "Forgot password" and enters email
- **THEN** system sends a password reset link (1-hour expiry, single-use token)

#### Scenario: Reset password
- **WHEN** user clicks reset link and enters new password
- **THEN** system updates the password, invalidates the token, and logs out all existing sessions

#### Scenario: Expired reset link
- **WHEN** user clicks a reset link older than 1 hour
- **THEN** system displays error and offers to request a new link

### Requirement: Users can change password and email
The system SHALL allow logged-in users to change their password and email.

#### Scenario: Change password
- **WHEN** user enters current password and new password
- **THEN** system verifies current password, updates to new password, and logs out all other sessions

#### Scenario: Change email
- **WHEN** user enters a new email address
- **THEN** system sends verification to the new email; old email remains active until new one is verified

#### Scenario: Wrong current password
- **WHEN** user enters incorrect current password when changing password
- **THEN** system rejects the change with error

### Requirement: Sessions persist across visits
The system SHALL keep users logged in across browser sessions.

#### Scenario: Returning user
- **WHEN** a customer returns to the site within 30 days
- **THEN** system recognizes their session and keeps them logged in

#### Scenario: Admin session expiry
- **WHEN** an admin's 24-hour session expires
- **THEN** system redirects them to login on next dashboard action

### Requirement: Protected actions require login
The system SHALL require authentication for submit, vote, comment, and My Ideas.

#### Scenario: Unauthenticated user attempts action
- **WHEN** a visitor tries to submit, vote, comment, or view My Ideas
- **THEN** system redirects to login with redirect back to the intended page after login

### Requirement: hCaptcha on registration
The system SHALL require hCaptcha verification on the registration form to prevent bots.

#### Scenario: Bot attempts registration
- **WHEN** an automated script submits the register form without solving captcha
- **THEN** system rejects the submission

#### Scenario: Human registers
- **WHEN** a human solves the hCaptcha and submits the form
- **THEN** system processes the registration normally

### Requirement: Disposable email domains blocked
The system SHALL block registration with known disposable/temporary email domains while allowing legitimate alias services.

#### Scenario: Disposable domain rejected
- **WHEN** visitor attempts to register with an email from a known disposable domain (e.g., mailinator.com, 10minutemail.com, guerrillamail.com)
- **THEN** system rejects registration with "Please use a real email address"

#### Scenario: Legitimate alias allowed
- **WHEN** visitor registers with an email from an allowed alias service (SimpleLogin, DuckDuckGo, Apple Hide My Email, Fastmail aliases)
- **THEN** system processes registration normally

#### Scenario: Normal provider allowed
- **WHEN** visitor registers with a mainstream provider (Gmail, Outlook, company domains)
- **THEN** system processes registration normally

#### Scenario: List maintained
- **WHEN** new disposable domains emerge
- **THEN** admins can update the blocked domains list via configuration (no code deploy needed)