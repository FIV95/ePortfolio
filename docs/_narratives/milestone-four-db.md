## Milestone Four Narrative — Databases

*CS 499 · Enhancement Three · June 2026*

### 1. Describe the artifact

This artifact is a **PostgreSQL database** for a fictional tech repair shop. I built the original version in an earlier database course: six core tables, seed data, basic roles, indexes, triggers, and twelve reporting queries. It was a solid academic foundation, but it behaved like a classroom exercise rather than something a real shop could run.

For Milestone Four, I extended that baseline into a fuller database system. The shop still repairs customer devices and tracks parts and technicians, but now it also supports:

- Audit history on critical tables
- Encrypted customer addresses (pgcrypto)
- Four staff roles with row-level security
- **Baton workflow** — only one technician actively works a ticket at a time
- Backup, restore, migration, and verification shell scripts
- Automated security and maintenance tests
- A simple web page at `/app` so front-desk staff and technicians can use the system without writing SQL

The database is still the main deliverable; the FastAPI layer is a thin interface on top. The submission includes original SQL scripts, twelve enhancement migration files, operations scripts, automated tests, an updated ERD, and the small API layer.

### 2. Justify inclusion

I chose this artifact because it shows something I want employers to see: I can take existing database work and improve it with **security, operations, and real workflow rules** — not just design tables on paper.

**This project demonstrates:**

| Area | Evidence |
|------|----------|
| Database design | Ten tables, FKs, constraints, repair notes, baton history, materialized reporting views |
| Security | bcrypt passwords, encrypted addresses, RLS, four PostgreSQL login roles, JSON audit trails |
| Operations | migrate, verify, backup, restore, scheduled maintenance — all scripted with logged results |
| Business logic in SQL | `claim_baton` / `drop_baton` functions, auto-drop on close, role-scoped visibility policies |
| Usability | Role-aware `/app` authenticating through database login roles — not bypassing them |

Compared to the original: three roles and ten seed tickets → four app roles, ~35 customers, ~42 repairs, maintenance logging, disaster recovery scripts, and automated test suites.

### 3. Course outcomes and coverage plan

| Program Outcome | How this work shows progress |
|-----------------|------------------------------|
| Outcome 4 — Techniques & tools | PostgreSQL RLS, triggers, materialized views, migration scripts, backup tooling, role-scoped API |
| Outcome 5 — Security mindset | Least-privilege roles, encrypted PII, masked contact views, audit logging, baton-scoped tech access |
| Outcome 3 — Design solutions | Baton workflow enforced in DB functions/policies — not application-only rules |
| Outcome 2 — Communication | README, ERD, ops docs, this narrative, code review video |
| Outcome 1 — Collaborative environments | Separate experiences for CS, tech, admin, and auditor on shared controlled data |

I do not need to change my overall outcome plan. The database category was the right choice, and this milestone covers design, security, and administration — not just queries.

### 4. Reflect on the enhancement process

The biggest takeaway: improving a database is not only about adding tables. Most of the real work was deciding **where a rule should live** — SQL, ops script, or the thin web layer.

**What I learned:**

- Row-level security is powerful but must be designed carefully. Early baton policies caused recursion when helper functions queried protected tables in ways PostgreSQL rejected. Refactoring those helpers fixed it.
- PostgreSQL does not allow `VACUUM` inside SQL functions. I removed VACUUM from the in-database maintenance path and kept it as an optional admin step via `run_maintenance.sh --vacuum`.
- Baton claim/drop needed `SECURITY DEFINER` functions because strict RLS correctly blocked direct technician updates.
- Automation scripts only stay useful if they match the live system. Security tests still expected the original ten-ticket dataset until I updated them after baton RLS replaced assignment-only access.
- A simple `/app` page made the database approachable for non-technical roles without turning the milestone into a large application project.

**Challenges:**

- Matching `pg_dump` and `psql` client versions to PostgreSQL 17
- Fixing the audit trigger to use the correct primary key on `repair_notes`
- Keeping setup and migration scripts aligned as new enhancement files were added
- Trimming unused API endpoints so the milestone stayed focused on the database

Near the end I ran the full verification suite: `verify_environment.sh`, `test_security.sh`, `test_maintenance.sh`, and `test_api.sh` all passed.

Stepping back, I am proud of what this became. I started with a repair-shop schema from coursework and ended with something closer to a system a small business could operate — secure, auditable, maintainable, and understandable to the people who would use it every day.