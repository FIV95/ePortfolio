-- Database Enhancement: Security & Audit Logging
-- Author: Frank Lawrence
-- Date: 2026-06-04
-- Purpose: Implement comprehensive audit trail for all major changes
-- This supports security mindset and systems administration best practices

SET search_path TO tech;

-- 1. Create Audit Log Table
CREATE TABLE IF NOT EXISTS audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_by TEXT NOT NULL DEFAULT current_user,
    changed_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    ip_address TEXT,
    notes TEXT
);

-- 2. Create Audit Function (to be called by triggers)
CREATE OR REPLACE FUNCTION tech.log_audit_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id INTEGER;
    v_new_json JSONB;
    v_old_json JSONB;
BEGIN
    v_new_json := CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END;
    v_old_json := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END;

    v_record_id := COALESCE(
        (v_new_json ->> 'note_id')::INTEGER,
        (v_old_json ->> 'note_id')::INTEGER,
        (v_new_json ->> 'id')::INTEGER,
        (v_old_json ->> 'id')::INTEGER
    );

    INSERT INTO tech.audit_log (
        table_name,
        record_id,
        action_type,
        old_values,
        new_values
    )
    VALUES (
        TG_TABLE_NAME,
        v_record_id,
        TG_OP,
        v_old_json,
        v_new_json
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO tech;

-- 3. Apply Audit Triggers to Key Tables
CREATE TRIGGER audit_customer_changes
    AFTER INSERT OR UPDATE OR DELETE ON customer
    FOR EACH ROW EXECUTE FUNCTION tech.log_audit_changes();

CREATE TRIGGER audit_repair_order_changes
    AFTER INSERT OR UPDATE OR DELETE ON repair_order
    FOR EACH ROW EXECUTE FUNCTION tech.log_audit_changes();

CREATE TRIGGER audit_technician_changes
    AFTER INSERT OR UPDATE OR DELETE ON technician
    FOR EACH ROW EXECUTE FUNCTION tech.log_audit_changes();

-- Add helpful comments
COMMENT ON TABLE audit_log IS 'Comprehensive audit trail for security and compliance';
COMMENT ON FUNCTION tech.log_audit_changes() IS 'Trigger function to automatically log database changes';

\echo "Audit logging enhancement applied successfully."
