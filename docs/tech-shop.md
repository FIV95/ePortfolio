---
layout: default
title: Tech Repair Shop
permalink: /tech-shop/
description: "Database artifact — secure PostgreSQL repair shop with baton workflow and ops automation"
---

<div class="container">

# Tech Repair Shop — PostgreSQL Database System

<div class="tag-row">
  <span class="tag">Databases</span>
</div>

A normalized **PostgreSQL** database for a fictional tech repair business — extended from an academic baseline into a secure, auditable, operations-ready system with role-based access, baton workflow, and shell-script automation.

<p>
  <a href="{{ site.repo_url }}/tree/main/Database_Artifact/tech_shop">View source in repository</a>
  ·
  <a href="{{ site.baseurl }}/code-review/">Code review video</a>
</p>

## Entity relationship diagram

<figure class="figure">
  <img src="{{ site.baseurl }}/assets/img/erd.png" alt="Tech Repair Shop entity relationship diagram">
  <figcaption>Ten tables in the <code>tech</code> schema — customers, devices, repairs, parts, notes, baton history, audit log, and app roles.</figcaption>
</figure>

## Architecture

<div class="arch-diagram">
Staff (CS · Tech · Admin · Auditor)
        │
        ▼
  FastAPI /app  ──JWT + role-scoped DB login──►  PostgreSQL (tech_shop)
        │                                              │
        │                                    ┌─────────┴─────────┐
        │                                    ▼                   ▼
        │                              RLS policies        audit triggers
        │                              baton functions    maintenance_log
        ▼
  enhanced/ops scripts (migrate · verify · backup · restore · test)
</div>

The database enforces workflow and security rules. The `/app` layer stays intentionally thin so the milestone stays focused on database competence.

## Role matrix

| Login role | Who | Capabilities |
|------------|-----|--------------|
| `cs_login` | Customer service | All customers and repairs; add notes |
| `tech_login` | Technician | Claim/drop batons; notes while holding; scoped repair visibility |
| `admin_login` | Administrator | Full CRUD; decrypt addresses; run maintenance |
| `auditor_login` | Auditor | Read-only operations; full audit trail |

Demo accounts and setup instructions are in the [repository README]({{ site.repo_url }}/blob/main/Database_Artifact/tech_shop/README.md).

## Before → After

| Dimension | Original baseline | Enhanced system |
|-----------|-------------------|-----------------|
| Tables | 6 core tables | 10 tables + audit + baton log |
| Roles | 3 basic roles | 4 app login roles with RLS |
| Security | Simple grants | bcrypt, pgcrypto encryption, RLS policies |
| Workflow | Static assignment | Baton claim/drop — one active tech per ticket |
| Operations | Manual SQL | migrate, verify, backup, restore, maintenance scripts |
| UI | SQL only | Role-aware `/app` page |
| Sample data | 10 repairs | ~42 repairs, notes, baton history |

## SQL spotlight — Baton workflow

Only one technician actively holds a repair at a time. Claiming starts work; dropping returns the ticket to the shared pool.

```sql
CREATE OR REPLACE FUNCTION tech.claim_baton(p_repair_id INTEGER)
RETURNS TABLE (...) AS $$
DECLARE
    tech_id INTEGER := tech.get_session_technician_id();
BEGIN
    IF tech_id IS NULL THEN
        RAISE EXCEPTION 'Technician session is not set.';
    END IF;

    UPDATE tech.repair_order ro
    SET baton_technician_id = tech_id,
        baton_claimed_at = CURRENT_TIMESTAMP,
        status = CASE WHEN ro.status = 'Open' THEN 'In Progress' ELSE ro.status END
    WHERE ro.id = p_repair_id
      AND ro.status <> 'Closed'
      AND ro.baton_technician_id IS NULL;

    INSERT INTO tech.repair_baton_log (repair_order_id, technician_id, action)
    VALUES (p_repair_id, tech_id, 'CLAIM');
    ...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

<div class="callout">
<strong>Design decision:</strong> baton enforcement lives in the database — functions, triggers, and RLS — not only in application code. That guarantee survives multiple clients, scripts, and future maintainers.
</div>

## Schema overview

| Table | Purpose |
|-------|---------|
| `customer` | Contact info, loyalty points, encrypted `address_encrypted` |
| `device` | Customer-owned hardware with serial and status |
| `technician` | Staff profiles with specialty, hourly rate, active flag |
| `repair_order` | Ticket — status, priority, cost, assignee, **baton holder** |
| `part_used` | Parts and unit cost per repair |
| `repair_notes` | Timestamped notes per ticket |
| `repair_baton_log` | CLAIM / DROP / AUTO_DROP history |
| `user_role` | App logins with bcrypt `password_hash` |
| `audit_log` | JSONB snapshots on INSERT/UPDATE/DELETE |
| `maintenance_log` | ANALYZE, reindex, MV refresh job results |

### Reporting views

- `technician_performance` — repairs, revenue, averages per technician
- `repair_aging` — open-ticket counts and age by status and priority

## Security highlights

- **bcrypt** password hashes in `user_role` (plaintext column removed)
- **pgcrypto** encryption for customer addresses at rest
- **Row-level security** on repairs, notes, baton log, audit log, and user roles
- **Audit triggers** with JSONB snapshots on critical tables
- **Masked contact view** for technicians (`v_customer_contact`)

### Encryption and session context

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION tech.encrypt_text(plain TEXT)
RETURNS BYTEA AS $$
BEGIN
    IF plain IS NULL OR plain = '' THEN RETURN NULL; END IF;
    RETURN pgp_sym_encrypt(plain, tech.encryption_key());
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.set_technician_context(tech_id INTEGER)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.technician_id', tech_id::TEXT, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Technician visibility is tied to session context set at login — RLS policies call `tech.get_session_technician_id()` and `tech.tech_can_view_repair()` rather than trusting the API alone.

## Original vs. enhanced source

| Layer | Location |
|-------|----------|
| Baseline schema | [`original/table_creation.sql`]({{ site.repo_url }}/tree/main/Database_Artifact/tech_shop/original) |
| Enhancement migrations | [`enhanced/sql/`]({{ site.repo_url }}/tree/main/Database_Artifact/tech_shop/enhanced/sql) (12 files) |
| Ops scripts | [`enhanced/ops/`]({{ site.repo_url }}/tree/main/Database_Artifact/tech_shop/enhanced/ops) |
| FastAPI /app | [`enhanced/api/`]({{ site.repo_url }}/tree/main/Database_Artifact/tech_shop/enhanced/api) |

## Operations tooling

| Script | Purpose |
|--------|---------|
| `migrate_enhanced.sh` | Apply all enhancement SQL to baseline DB |
| `verify_environment.sh` | Schema, seed data, views, backup dry-run |
| `backup_db.sh` / `restore_db.sh` | Disaster recovery |
| `run_maintenance.sh` | ANALYZE, materialized view refresh, optional VACUUM |
| `test_all.sh` | Full suite: provision, verify, security + maintenance |

{% capture techshop_run %}cd Database_Artifact/tech_shop/enhanced/ops
./migrate_enhanced.sh --db tech_shop
./verify_environment.sh --db tech_shop

cd ../api
uvicorn main:app --reload
# Open http://127.0.0.1:8000/app{% endcapture %}
{% include terminal-frame.html title="quick start" content=techshop_run %}

## Verification suite

Before final submission I ran the full ops test path:

```bash
cd Database_Artifact/tech_shop/enhanced/ops
./verify_environment.sh --db tech_shop
./test_security.sh --db tech_shop
./test_maintenance.sh --db tech_shop
# With API running:
cd ../api && ./test_api.sh
# Or all at once:
./test_all.sh
```

These scripts confirm schema objects, role boundaries, maintenance logging, and API smoke behavior against the live database — not just static SQL review.

## Enhancement SQL files

| File | Adds |
|------|------|
| `security_hardening.sql` | bcrypt, encryption, RLS, role grants |
| `baton_system.sql` | Baton columns, claim/drop functions, tech policies |
| `audit_logging.sql` | `audit_log` table and change triggers |
| `maintenance_automation.sql` | `maintenance_log` and scheduled jobs |
| `analytics_reporting.sql` | Materialized views and revenue function |

---

## Narrative

{% include_relative _narratives/milestone-four-db.md %}

</div>