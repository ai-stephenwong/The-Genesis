# ER Diagram — [Project Name]

> Produced by the `solution-architect` agent. **Do not edit manually** — update via the architect.
> This is a mandatory deliverable before development starts.
> Full database schema in Mermaid `erDiagram` format.

<!-- last-updated: YYYY-MM-DD -->

## Entity-Relationship Diagram

```mermaid
erDiagram

    %% ── Example — replace with actual entities ──

    USER {
        uuid        id          PK
        string      email
        string      password_hash
        string      role            "candidate | employer | admin"
        timestamp   created_at
        timestamp   updated_at
        timestamp   deleted_at      "soft delete"
    }

    PROFILE {
        uuid        id          PK
        uuid        user_id     FK
        string      full_name
        string      phone
        text        bio
        timestamp   created_at
    }

    JOB_LISTING {
        uuid        id          PK
        uuid        employer_id FK
        string      title
        text        description
        string      status          "draft | active | closed"
        timestamp   published_at
        timestamp   created_at
        timestamp   updated_at
    }

    APPLICATION {
        uuid        id              PK
        uuid        job_listing_id  FK
        uuid        candidate_id    FK
        string      status          "pending | reviewed | shortlisted | rejected"
        text        cover_letter
        timestamp   applied_at
    }

    USER        ||--o| PROFILE        : "has one"
    USER        ||--o{ JOB_LISTING    : "posts (employer)"
    USER        ||--o{ APPLICATION    : "submits (candidate)"
    JOB_LISTING ||--o{ APPLICATION    : "receives"
```

## Entity Descriptions

| Entity | Description | Key Business Rules |
|---|---|---|
| `USER` | All system users (candidates, employers, admins) | Role determines access level; soft-delete only |
| `PROFILE` | Extended profile info for a user | One-to-one with USER |
| `JOB_LISTING` | A job posted by an employer | Only `active` listings are visible to candidates |
| `APPLICATION` | A candidate's application to a job listing | One candidate can apply to one listing only once |

## Indexes

| Table | Index | Columns | Reason |
|---|---|---|---|
| `user` | `idx_user_email` | `email` | Login lookup |
| `job_listing` | `idx_job_status` | `status, published_at` | Feed queries |
| `application` | `idx_app_candidate_job` | `candidate_id, job_listing_id` | Unique constraint + lookup |

## Notes

<!-- Any constraints, migration considerations, or design decisions not obvious from the diagram -->
