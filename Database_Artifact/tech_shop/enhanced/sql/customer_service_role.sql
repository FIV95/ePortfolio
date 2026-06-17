-- Database Enhancement: Customer Service Role
-- Author: Frank Lawrence
-- Date: 2026-06-07
-- Purpose: Front-desk / customer service access — see all repairs & customers, add notes, no admin powers

SET search_path TO tech;

-- Expand app role options
ALTER TABLE tech.user_role DROP CONSTRAINT IF EXISTS user_role_role_check;
ALTER TABLE tech.user_role ADD CONSTRAINT user_role_role_check
    CHECK (role IN ('admin', 'tech', 'auditor', 'customer_service'));

-- Login role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cs_login') THEN
        CREATE ROLE cs_login WITH LOGIN PASSWORD 'cs_pass';
    END IF;
END $$;

ALTER ROLE cs_login NOCREATEDB NOCREATEROLE NOSUPERUSER NOINHERIT CONNECTION LIMIT 10;

CREATE OR REPLACE FUNCTION tech.is_customer_service()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user = 'cs_login';
END;
$$ LANGUAGE plpgsql STABLE;

-- Customer service sees full contact info (like admin)
CREATE OR REPLACE VIEW tech.v_customer_contact AS
SELECT
    id,
    first_name,
    last_name,
    CASE
        WHEN tech.is_admin() OR tech.is_auditor() OR tech.is_customer_service() THEN email
        ELSE regexp_replace(email, '(?<=.).(?=[^@]*@)', '*', 'g')
    END AS email,
    CASE
        WHEN tech.is_admin() OR tech.is_auditor() OR tech.is_customer_service() THEN phone
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

-- RLS: customer service reads all repairs, adds/reads notes
DROP POLICY IF EXISTS cs_repair_order_read ON tech.repair_order;
CREATE POLICY cs_repair_order_read ON tech.repair_order
    FOR SELECT TO cs_login
    USING (true);

DROP POLICY IF EXISTS cs_repair_notes_read ON tech.repair_notes;
DROP POLICY IF EXISTS cs_repair_notes_write ON tech.repair_notes;
CREATE POLICY cs_repair_notes_read ON tech.repair_notes
    FOR SELECT TO cs_login
    USING (true);
CREATE POLICY cs_repair_notes_write ON tech.repair_notes
    FOR INSERT TO cs_login
    WITH CHECK (true);

-- Grants
GRANT USAGE ON SCHEMA tech TO cs_login;
GRANT SELECT ON tech.customer TO cs_login;
GRANT SELECT ON tech.device TO cs_login;
GRANT SELECT ON tech.repair_order TO cs_login;
GRANT SELECT ON tech.technician TO cs_login;
GRANT SELECT, INSERT ON tech.repair_notes TO cs_login;
GRANT USAGE, SELECT ON SEQUENCE tech.repair_notes_note_id_seq TO cs_login;
GRANT SELECT ON tech.v_customer_contact TO cs_login;
GRANT EXECUTE ON FUNCTION tech.is_customer_service() TO cs_login;
GRANT EXECUTE ON FUNCTION tech.is_admin() TO cs_login;
GRANT EXECUTE ON FUNCTION tech.is_auditor() TO cs_login;
GRANT EXECUTE ON FUNCTION tech.decrypt_text(BYTEA) TO cs_login;

-- Demo customer service user
INSERT INTO tech.user_role (username, password_hash, technician_id, role, created_at, updated_at)
SELECT
    'cs_jordan',
    crypt('cs123', gen_salt('bf')),
    '9997',
    'customer_service',
    CURRENT_DATE,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM tech.user_role WHERE username = 'cs_jordan'
);

DO $$
BEGIN
    EXECUTE format('GRANT cs_login TO %I', current_user);
END $$;

\echo 'Customer service role applied successfully.'