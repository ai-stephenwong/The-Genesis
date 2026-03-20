# Functional Specifications — [Project Name]

> Produced by the `solution-architect` agent. This is a mandatory deliverable before development starts.
> Translates raw client requirements into precise, developer-ready specifications.
> Each feature section is the single source of truth for what must be built.

<!-- last-updated: YYYY-MM-DD -->

---

## How to Use This Document

- **Developers** — implement exactly what is specified here. Raise a change request if anything is unclear or impossible.
- **Testers** — derive test cases from the acceptance criteria in each section.
- **Code reviewers** — verify implementation matches the spec before approving.
- **Compliance officer** — verify all features in this doc have corresponding test results.

---

## FS-01 — Authentication

### FS-01.1 — User Registration

**Description:** New users can create an account with email and password.

**User Flow:**
1. User navigates to `/register`
2. User fills in: full name, email, password, role (candidate / employer)
3. System validates all fields
4. System creates the user account and sends a verification email
5. User is redirected to a "Please verify your email" page
6. User clicks the link in the email → account is activated
7. User is redirected to their dashboard

**Business Rules:**
- Email must be unique across all users
- Password minimum 8 characters, must contain at least one number
- Role cannot be changed after registration
- Verification link expires after 24 hours
- Unverified accounts cannot log in

**Acceptance Criteria:**
- [ ] Registration form validates all fields client-side and server-side
- [ ] Duplicate email returns `409 CONFLICT` with error code `EMAIL_ALREADY_EXISTS`
- [ ] Password is hashed (never stored plain)
- [ ] Verification email is sent within 30 seconds of registration
- [ ] Expired verification links show a clear error and offer resend option

**API endpoints used:** `POST /api/v1/auth/register`, `GET /api/v1/auth/verify-email`

---

### FS-01.2 — User Login

**Description:** Registered and verified users can log in with email and password.

**User Flow:**
1. User navigates to `/login`
2. User enters email and password
3. System validates credentials
4. On success: access token returned in response body; refresh token set as httpOnly cookie
5. User is redirected to their dashboard

**Business Rules:**
- Unverified accounts receive `403 FORBIDDEN` with error code `EMAIL_NOT_VERIFIED`
- After 5 consecutive failed attempts: account is locked for 15 minutes
- Access token expires in 15 minutes; refresh token expires in 7 days

**Acceptance Criteria:**
- [ ] Valid credentials return `200` with access token
- [ ] Invalid credentials return `401` with error code `INVALID_CREDENTIALS`
- [ ] Refresh token is set as httpOnly, Secure, SameSite=Strict cookie
- [ ] Account lockout triggers after 5 failed attempts
- [ ] Lockout error returns `429` with `ACCOUNT_LOCKED` and a retry-after duration

**API endpoints used:** `POST /api/v1/auth/login`

---

## FS-02 — [Next Feature Module]

<!-- Copy the structure above for each feature module:
     Description, User Flow, Business Rules, Acceptance Criteria, API endpoints used -->

---

## Open Items

| # | Question | Raised by | Status |
|---|---|---|---|
| 1 | <!-- e.g. Should employers be able to see candidate profiles before shortlisting? --> | architect | Open |
