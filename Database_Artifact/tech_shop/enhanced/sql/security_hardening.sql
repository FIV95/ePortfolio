-- Database Enhancement: Security Hardening
-- Author: Frank Lawrence
-- Date: 2026-06-06
-- Purpose: Expanded RLS, pgcrypto encryption, and role hardening

SET search_path TO tech;

-- ============================================================
-- 1. Extensions & Session Context Helpers
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION tech.get_session_technician_id()
RETURNS INTEGER AS $$
DECLARE
    tech_id TEXT;
BEGIN
    tech_id := current_setting('app.technician_id', true);
    IF tech_id IS NULL OR tech_id = '' THEN
        RETURN NULL;
    END IF;
    RETURN tech_id::INTEGER;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user = 'admin_login';
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.is_auditor()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user = 'auditor_login';
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.set_technician_context(tech_id INTEGER)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.technician_id', tech_id::TEXT, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION tech.encryption_key()
RETURNS TEXT AS $$
BEGIN
    RETURN COALESCE(
        NULLIF(current_setting('app.encryption_key', true), ''),
        'tech_shop_demo_key_v1'
    );
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.encrypt_text(plain TEXT)
RETURNS BYTEA AS $$
BEGIN
    IF plain IS NULL OR plain = '' THEN
        RETURN NULL;
    END IF;
    RETURN pgp_sym_encrypt(plain, tech.encryption_key());
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.decrypt_text(cipher BYTEA)
RETURNS TEXT AS $$
BEGIN
    IF cipher IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN pgp_sym_decrypt(cipher, tech.encryption_key());
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION tech.set_technician_context(INTEGER) IS
    'Sets app.technician_id for RLS-aware technician sessions (used by API/login layer)';

-- ============================================================
-- 2. Password Encryption (user_role)
-- ============================================================

ALTER TABLE tech.user_role
    ADD COLUMN IF NOT EXISTS password_hash TEXT;

UPDATE tech.user_role
SET password_hash = crypt(password, gen_salt('bf'))
WHERE password_hash IS NULL
  AND password IS NOT NULL;

ALTER TABLE tech.user_role DROP COLUMN IF EXISTS password;

CREATE OR REPLACE FUNCTION tech.verify_user_password(p_username TEXT, p_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    stored_hash TEXT;
BEGIN
    SELECT password_hash
    INTO stored_hash
    FROM tech.user_role
    WHERE username = p_username;

    IF stored_hash IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN stored_hash = crypt(p_password, stored_hash);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO tech, public;

COMMENT ON FUNCTION tech.verify_user_password(TEXT, TEXT) IS
    'Verifies a username/password pair against the bcrypt hash in user_role';

-- ============================================================
-- 3. Customer PII Encryption (address at rest)
-- ============================================================

ALTER TABLE tech.customer
    ADD COLUMN IF NOT EXISTS address_encrypted BYTEA;

UPDATE tech.customer
SET address_encrypted = tech.encrypt_text(address)
WHERE address IS NOT NULL
  AND address_encrypted IS NULL;

CREATE OR REPLACE VIEW tech.v_customer_contact AS
SELECT
    id,
    first_name,
    last_name,
    CASE
        WHEN tech.is_admin() OR tech.is_auditor() THEN email
        ELSE regexp_replace(email, '(?<=.).(?=[^@]*@)', '*', 'g')
    END AS email,
    CASE
        WHEN tech.is_admin() OR tech.is_auditor() THEN phone
        ELSE regexp_replace(phone, '\d', '*', 'g')
    END AS phone,
    CASE
        WHEN tech.is_admin() THEN tech.decrypt_text(address_encrypted)
        ELSE '*** encrypted ***'
    END AS address,
    loyalty_points,
    created_at,
    updated_at
FROM tech.customer;

COMMENT ON VIEW tech.v_customer_contact IS
    'Role-aware customer view with masked contact info for technicians';

-- ============================================================
-- 4. Row-Level Security Policies
-- ============================================================

-- repair_order: technicians see only assigned repairs
ALTER TABLE tech.repair_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE tech.repair_order FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_repair_order_all ON tech.repair_order;
DROP POLICY IF EXISTS auditor_repair_order_read ON tech.repair_order;
DROP POLICY IF EXISTS tech_repair_order_access ON tech.repair_order;

CREATE POLICY admin_repair_order_all ON tech.repair_order
    FOR ALL TO admin_login
    USING (true) WITH CHECK (true);

CREATE POLICY auditor_repair_order_read ON tech.repair_order
    FOR SELECT TO auditor_login
    USING (true);

CREATE POLICY tech_repair_order_access ON tech.repair_order
    FOR ALL TO tech_login
    USING (technician_id = tech.get_session_technician_id())
    WITH CHECK (technician_id = tech.get_session_technician_id());

-- repair_notes: technicians see notes on their repairs
ALTER TABLE tech.repair_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tech.repair_notes FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_repair_notes_all ON tech.repair_notes;
DROP POLICY IF EXISTS auditor_repair_notes_read ON tech.repair_notes;
DROP POLICY IF EXISTS tech_repair_notes_access ON tech.repair_notes;

CREATE POLICY admin_repair_notes_all ON tech.repair_notes
    FOR ALL TO admin_login
    USING (true) WITH CHECK (true);

CREATE POLICY auditor_repair_notes_read ON tech.repair_notes
    FOR SELECT TO auditor_login
    USING (true);

CREATE POLICY tech_repair_notes_access ON tech.repair_notes
    FOR ALL TO tech_login
    USING (
        technician_id = tech.get_session_technician_id()
        OR repair_order_id IN (
            SELECT id
            FROM tech.repair_order
            WHERE technician_id = tech.get_session_technician_id()
        )
    )
    WITH CHECK (technician_id = tech.get_session_technician_id());

-- audit_log: auditors read-only; technicians blocked
ALTER TABLE tech.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE tech.audit_log FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_audit_log_all ON tech.audit_log;
DROP POLICY IF EXISTS auditor_audit_log_read ON tech.audit_log;

CREATE POLICY admin_audit_log_all ON tech.audit_log
    FOR ALL TO admin_login
    USING (true) WITH CHECK (true);

CREATE POLICY auditor_audit_log_read ON tech.audit_log
    FOR SELECT TO auditor_login
    USING (true);

-- user_role: replace legacy policy with session-aware rules
ALTER TABLE tech.user_role FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tech_own_record ON tech.user_role;
DROP POLICY IF EXISTS admin_user_role_all ON tech.user_role;
DROP POLICY IF EXISTS auditor_user_role_read ON tech.user_role;
DROP POLICY IF EXISTS tech_user_role_access ON tech.user_role;

CREATE POLICY admin_user_role_all ON tech.user_role
    FOR ALL TO admin_login
    USING (true) WITH CHECK (true);

CREATE POLICY auditor_user_role_read ON tech.user_role
    FOR SELECT TO auditor_login
    USING (true);

CREATE POLICY tech_user_role_access ON tech.user_role
    FOR SELECT TO tech_login
    USING (technician_id::INTEGER = tech.get_session_technician_id());

CREATE POLICY tech_user_role_update ON tech.user_role
    FOR UPDATE TO tech_login
    USING (technician_id::INTEGER = tech.get_session_technician_id())
    WITH CHECK (technician_id::INTEGER = tech.get_session_technician_id());

-- ============================================================
-- 5. Role Hardening & Explicit Grants
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech_login') THEN
        CREATE ROLE tech_login WITH LOGIN PASSWORD 'tech_pass';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_login') THEN
        CREATE ROLE admin_login WITH LOGIN PASSWORD 'admin_pass';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'auditor_login') THEN
        CREATE ROLE auditor_login WITH LOGIN PASSWORD 'auditor_pass';
    END IF;
END $$;

ALTER ROLE tech_login NOCREATEDB NOCREATEROLE NOSUPERUSER NOINHERIT CONNECTION LIMIT 10;
ALTER ROLE admin_login NOCREATEDB NOCREATEROLE NOSUPERUSER NOINHERIT CONNECTION LIMIT 5;
ALTER ROLE auditor_login NOCREATEDB NOCREATEROLE NOSUPERUSER NOINHERIT CONNECTION LIMIT 5;

REVOKE ALL ON SCHEMA tech FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA tech FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA tech FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA tech FROM PUBLIC;

GRANT USAGE ON SCHEMA tech TO tech_login, admin_login, auditor_login;

-- Core tables
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.customer TO tech_login, admin_login;
GRANT SELECT ON tech.customer TO auditor_login;

GRANT SELECT, INSERT, UPDATE, DELETE ON tech.device TO tech_login, admin_login;
GRANT SELECT ON tech.device TO auditor_login;

GRANT SELECT ON tech.technician TO tech_login, auditor_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.technician TO admin_login;

GRANT SELECT, INSERT, UPDATE, DELETE ON tech.repair_order TO tech_login, admin_login;
GRANT SELECT ON tech.repair_order TO auditor_login;

GRANT SELECT, INSERT, UPDATE, DELETE ON tech.part_used TO tech_login, admin_login;
GRANT SELECT ON tech.part_used TO auditor_login;

GRANT SELECT, INSERT, UPDATE ON tech.repair_notes TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.repair_notes TO admin_login;
GRANT SELECT ON tech.repair_notes TO auditor_login;

GRANT SELECT ON tech.audit_log TO auditor_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.audit_log TO admin_login;

GRANT SELECT, UPDATE ON tech.user_role TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.user_role TO admin_login;
GRANT SELECT ON tech.user_role TO auditor_login;

-- Sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tech TO tech_login, admin_login;

-- Views & monitoring (admin/auditor only)
GRANT SELECT ON tech.v_customer_contact TO tech_login, admin_login, auditor_login;
GRANT SELECT ON tech.v_index_usage TO admin_login, auditor_login;
GRANT SELECT ON tech.v_unused_indexes TO admin_login, auditor_login;
GRANT SELECT ON tech.v_table_scan_summary TO admin_login, auditor_login;
GRANT SELECT ON tech.v_table_health TO admin_login, auditor_login;
GRANT SELECT ON tech.v_schema_performance_summary TO admin_login, auditor_login;

-- Security-sensitive functions
REVOKE ALL ON FUNCTION tech.verify_user_password(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION tech.set_technician_context(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION tech.decrypt_text(BYTEA) FROM PUBLIC;
REVOKE ALL ON FUNCTION tech.encrypt_text(TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION tech.get_session_technician_id() TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.is_admin() TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.is_auditor() TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.set_technician_context(INTEGER) TO tech_login, admin_login;
GRANT EXECUTE ON FUNCTION tech.verify_user_password(TEXT, TEXT) TO admin_login;
GRANT EXECUTE ON FUNCTION tech.get_performance_report() TO admin_login, auditor_login;

-- Allow the database owner to SET ROLE for testing and administration
DO $$
BEGIN
    EXECUTE format('GRANT tech_login TO %I', current_user);
    EXECUTE format('GRANT admin_login TO %I', current_user);
    EXECUTE format('GRANT auditor_login TO %I', current_user);
END $$;

ALTER DEFAULT PRIVILEGES IN SCHEMA tech
    GRANT USAGE, SELECT ON SEQUENCES TO tech_login, admin_login;

\echo 'Security hardening applied successfully.'