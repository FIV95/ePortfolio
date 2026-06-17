-- Database Enhancement: Repair Baton (single active technician per ticket)
-- Author: Frank Lawrence
-- Date: 2026-06-07
-- Purpose: Only one tech holds the baton at a time; dropped batons are open for anyone.

SET search_path TO tech;

-- ============================================================
-- 1. Schema
-- ============================================================
ALTER TABLE tech.repair_order
    ADD COLUMN IF NOT EXISTS baton_technician_id INTEGER
        REFERENCES tech.technician(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS baton_claimed_at TIMESTAMP WITHOUT TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_repair_order_baton
    ON tech.repair_order (baton_technician_id)
    WHERE baton_technician_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS tech.repair_baton_log (
    log_id SERIAL PRIMARY KEY,
    repair_order_id INTEGER NOT NULL REFERENCES tech.repair_order(id) ON DELETE CASCADE,
    technician_id INTEGER NOT NULL REFERENCES tech.technician(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('CLAIM', 'DROP', 'AUTO_DROP')),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT DEFAULT current_user
);

CREATE INDEX IF NOT EXISTS idx_baton_log_repair ON tech.repair_baton_log(repair_order_id);
CREATE INDEX IF NOT EXISTS idx_baton_log_technician ON tech.repair_baton_log(technician_id);

COMMENT ON COLUMN tech.repair_order.baton_technician_id IS
    'Technician actively working this ticket. NULL means baton is available to claim.';
COMMENT ON TABLE tech.repair_baton_log IS
    'History of baton claims and drops for accountability.';

-- ============================================================
-- 2. Helpers
-- ============================================================
CREATE OR REPLACE FUNCTION tech.tech_interacted_with_repair(
    p_repair_id INTEGER,
    p_technician_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM tech.repair_baton_log
        WHERE repair_order_id = p_repair_id AND technician_id = p_technician_id
    )
    OR EXISTS (
        SELECT 1 FROM tech.repair_notes
        WHERE repair_order_id = p_repair_id AND technician_id = p_technician_id
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO tech;

CREATE OR REPLACE FUNCTION tech.tech_can_view_repair(p_repair_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    tech_id INTEGER := tech.get_session_technician_id();
    row_status TEXT;
    row_baton INTEGER;
BEGIN
    IF tech_id IS NULL THEN
        RETURN false;
    END IF;

    SELECT ro.status, ro.baton_technician_id
    INTO row_status, row_baton
    FROM tech.repair_order ro
    WHERE ro.id = p_repair_id;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    RETURN row_baton = tech_id
        OR (row_baton IS NULL AND row_status <> 'Closed')
        OR tech.tech_interacted_with_repair(p_repair_id, tech_id);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO tech;

CREATE OR REPLACE FUNCTION tech.clear_baton_on_close()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Closed' AND (OLD.status IS DISTINCT FROM 'Closed') THEN
        IF OLD.baton_technician_id IS NOT NULL THEN
            INSERT INTO tech.repair_baton_log (
                repair_order_id, technician_id, action, created_by
            )
            VALUES (
                OLD.id, OLD.baton_technician_id, 'AUTO_DROP', current_user
            );
        END IF;
        NEW.baton_technician_id := NULL;
        NEW.baton_claimed_at := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path TO tech;

DROP TRIGGER IF EXISTS trigger_clear_baton_on_close ON tech.repair_order;
CREATE TRIGGER trigger_clear_baton_on_close
    BEFORE UPDATE ON tech.repair_order
    FOR EACH ROW EXECUTE FUNCTION tech.clear_baton_on_close();

-- ============================================================
-- 3. Claim / drop (atomic, session-aware)
-- ============================================================
CREATE OR REPLACE FUNCTION tech.claim_baton(p_repair_id INTEGER)
RETURNS TABLE (
    repair_id INTEGER,
    baton_technician_id INTEGER,
    baton_claimed_at TIMESTAMP WITHOUT TIME ZONE,
    message TEXT
) AS $$
DECLARE
    tech_id INTEGER := tech.get_session_technician_id();
    updated_row tech.repair_order%ROWTYPE;
BEGIN
    IF tech_id IS NULL THEN
        RAISE EXCEPTION 'Technician session is not set.';
    END IF;

    UPDATE tech.repair_order ro
    SET
        baton_technician_id = tech_id,
        baton_claimed_at = CURRENT_TIMESTAMP,
        technician_id = COALESCE(ro.technician_id, tech_id),
        status = CASE
            WHEN ro.status = 'Open' THEN 'In Progress'
            ELSE ro.status
        END
    WHERE ro.id = p_repair_id
      AND ro.status <> 'Closed'
      AND ro.baton_technician_id IS NULL
    RETURNING ro.* INTO updated_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Baton is not available on repair #%.', p_repair_id;
    END IF;

    INSERT INTO tech.repair_baton_log (
        repair_order_id, technician_id, action, created_by
    )
    VALUES (p_repair_id, tech_id, 'CLAIM', current_user);

    RETURN QUERY
    SELECT
        updated_row.id,
        updated_row.baton_technician_id,
        updated_row.baton_claimed_at,
        'Baton claimed successfully.'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO tech;

CREATE OR REPLACE FUNCTION tech.drop_baton(p_repair_id INTEGER)
RETURNS TABLE (
    repair_id INTEGER,
    baton_technician_id INTEGER,
    baton_claimed_at TIMESTAMP WITHOUT TIME ZONE,
    message TEXT
) AS $$
DECLARE
    tech_id INTEGER := tech.get_session_technician_id();
    updated_row tech.repair_order%ROWTYPE;
BEGIN
    IF tech_id IS NULL THEN
        RAISE EXCEPTION 'Technician session is not set.';
    END IF;

    UPDATE tech.repair_order ro
    SET
        baton_technician_id = NULL,
        baton_claimed_at = NULL
    WHERE ro.id = p_repair_id
      AND ro.baton_technician_id = tech_id
      AND ro.status <> 'Closed'
    RETURNING ro.* INTO updated_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'You do not hold the baton on repair #%.', p_repair_id;
    END IF;

    INSERT INTO tech.repair_baton_log (
        repair_order_id, technician_id, action, created_by
    )
    VALUES (p_repair_id, tech_id, 'DROP', current_user);

    RETURN QUERY
    SELECT
        updated_row.id,
        updated_row.baton_technician_id,
        updated_row.baton_claimed_at,
        'Baton dropped — ticket is open for another technician.'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO tech;

-- ============================================================
-- 4. Row-level security (replace assignment-only tech access)
-- ============================================================
DROP POLICY IF EXISTS tech_repair_order_access ON tech.repair_order;
DROP POLICY IF EXISTS tech_repair_order_select ON tech.repair_order;

CREATE POLICY tech_repair_order_select ON tech.repair_order
    FOR SELECT TO tech_login
    USING (tech.tech_can_view_repair(id));

DROP POLICY IF EXISTS tech_repair_notes_access ON tech.repair_notes;

CREATE POLICY tech_repair_notes_select ON tech.repair_notes
    FOR SELECT TO tech_login
    USING (tech.tech_can_view_repair(repair_order_id));

CREATE POLICY tech_repair_notes_insert ON tech.repair_notes
    FOR INSERT TO tech_login
    WITH CHECK (
        technician_id = tech.get_session_technician_id()
        AND EXISTS (
            SELECT 1
            FROM tech.repair_order ro
            WHERE ro.id = repair_order_id
              AND ro.baton_technician_id = tech.get_session_technician_id()
        )
    );

ALTER TABLE tech.repair_baton_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE tech.repair_baton_log FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_baton_log_all ON tech.repair_baton_log;
DROP POLICY IF EXISTS auditor_baton_log_read ON tech.repair_baton_log;
DROP POLICY IF EXISTS tech_baton_log_read ON tech.repair_baton_log;

CREATE POLICY admin_baton_log_all ON tech.repair_baton_log
    FOR ALL TO admin_login
    USING (true) WITH CHECK (true);

CREATE POLICY auditor_baton_log_read ON tech.repair_baton_log
    FOR SELECT TO auditor_login
    USING (true);

CREATE POLICY tech_baton_log_read ON tech.repair_baton_log
    FOR SELECT TO tech_login
    USING (tech.tech_can_view_repair(repair_order_id));

-- ============================================================
-- 5. Grants
-- ============================================================
GRANT SELECT ON tech.repair_baton_log TO tech_login, admin_login, auditor_login, cs_login;
GRANT EXECUTE ON FUNCTION tech.tech_interacted_with_repair(INTEGER, INTEGER)
    TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.tech_can_view_repair(INTEGER)
    TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.claim_baton(INTEGER) TO tech_login;
GRANT EXECUTE ON FUNCTION tech.drop_baton(INTEGER) TO tech_login;

-- ============================================================
-- 6. Seed baton state on existing repairs
-- ============================================================
UPDATE tech.repair_order
SET
    baton_technician_id = technician_id,
    baton_claimed_at = COALESCE(created_at, CURRENT_TIMESTAMP)
WHERE status IN ('Open', 'In Progress')
  AND technician_id IS NOT NULL
  AND baton_technician_id IS NULL;

-- Drop baton on a slice of active tickets so the shop has a grab pool
UPDATE tech.repair_order
SET baton_technician_id = NULL, baton_claimed_at = NULL
WHERE status IN ('Open', 'In Progress')
  AND id % 3 = 0;

INSERT INTO tech.repair_baton_log (repair_order_id, technician_id, action, created_by)
SELECT ro.id, ro.baton_technician_id, 'CLAIM', 'system_seed'
FROM tech.repair_order ro
WHERE ro.baton_technician_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM tech.repair_baton_log l
      WHERE l.repair_order_id = ro.id AND l.action = 'CLAIM'
  );

REFRESH MATERIALIZED VIEW tech.technician_performance;
REFRESH MATERIALIZED VIEW tech.repair_aging;

\echo 'Baton system applied successfully.'