-- Database Enhancement: Maintenance Automation
-- Author: Frank Lawrence
-- Date: 2026-06-06
-- Purpose: Scheduled analyze/refresh in-database; vacuum via ops script

SET search_path TO tech;

DROP FUNCTION IF EXISTS tech.test_analyze();
DROP FUNCTION IF EXISTS tech.test_reindex();

-- ============================================================
-- 1. Maintenance Job Log
-- ============================================================

CREATE TABLE IF NOT EXISTS tech.maintenance_log (
    log_id SERIAL PRIMARY KEY,
    job_type TEXT NOT NULL CHECK (job_type IN ('ANALYZE', 'VACUUM', 'REINDEX', 'REFRESH_MV', 'FULL', 'SCHEDULED')),
    status TEXT NOT NULL CHECK (status IN ('STARTED', 'COMPLETED', 'FAILED', 'SKIPPED')),
    tables_processed INTEGER DEFAULT 0,
    started_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITHOUT TIME ZONE,
    details JSONB,
    triggered_by TEXT DEFAULT current_user,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_maintenance_log_started ON tech.maintenance_log(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_maintenance_log_type_status ON tech.maintenance_log(job_type, status);

COMMENT ON TABLE tech.maintenance_log IS
    'Audit trail for automated and manual database maintenance jobs';

-- ============================================================
-- 2. Maintenance Planning & Scheduling Helpers
-- ============================================================

CREATE OR REPLACE FUNCTION tech.should_run_maintenance(p_stale_days INTEGER DEFAULT 7)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM tech.v_table_health
        WHERE maintenance_status IN ('NEVER_ANALYZED', 'STALE_STATS', 'NEEDS_VACUUM')
    );
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION tech.get_maintenance_plan()
RETURNS TABLE (
    table_name TEXT,
    maintenance_status TEXT,
    recommended_action TEXT,
    dead_rows BIGINT,
    total_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.table_name::TEXT,
        h.maintenance_status::TEXT,
        CASE h.maintenance_status
            WHEN 'NEEDS_VACUUM' THEN 'VACUUM ANALYZE (run_maintenance.sh --vacuum)'
            WHEN 'STALE_STATS' THEN 'ANALYZE (run_analyze_maintenance)'
            WHEN 'NEVER_ANALYZED' THEN 'ANALYZE (run_analyze_maintenance)'
            ELSE 'NONE'
        END::TEXT,
        h.dead_rows,
        h.total_size::TEXT
    FROM tech.v_table_health h
    WHERE h.maintenance_status <> 'HEALTHY'
    ORDER BY h.dead_rows DESC, h.table_name;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION tech.should_run_maintenance(INTEGER) IS
    'Returns true when one or more tables need analyze or vacuum per v_table_health';

-- ============================================================
-- 3. In-Database Maintenance (ANALYZE + materialized view refresh)
-- ============================================================

CREATE OR REPLACE FUNCTION tech.refresh_analytics_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW tech.technician_performance;
    REFRESH MATERIALIZED VIEW tech.repair_aging;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tech.run_analyze_maintenance()
RETURNS TABLE (
    object_name TEXT,
    object_type TEXT,
    status TEXT
) AS $$
DECLARE
    r RECORD;
    v_log_id INTEGER;
    v_count INTEGER := 0;
BEGIN
    INSERT INTO tech.maintenance_log (job_type, status, triggered_by, notes)
    VALUES ('ANALYZE', 'STARTED', current_user, 'run_analyze_maintenance')
    RETURNING log_id INTO v_log_id;

    FOR r IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'tech'
        ORDER BY tablename
    LOOP
        EXECUTE format('ANALYZE tech.%I', r.tablename);
        v_count := v_count + 1;

        object_name := r.tablename;
        object_type := 'table';
        status := 'ANALYZED';
        RETURN NEXT;
    END LOOP;

    PERFORM tech.refresh_analytics_views();

    object_name := 'technician_performance';
    object_type := 'materialized_view';
    status := 'REFRESHED';
    RETURN NEXT;

    object_name := 'repair_aging';
    object_type := 'materialized_view';
    status := 'REFRESHED';
    RETURN NEXT;

    UPDATE tech.maintenance_log
    SET status = 'COMPLETED',
        completed_at = CURRENT_TIMESTAMP,
        tables_processed = v_count,
        details = jsonb_build_object(
            'tables_analyzed', v_count,
            'materialized_views_refreshed', 2
        )
    WHERE log_id = v_log_id;

EXCEPTION
    WHEN OTHERS THEN
        UPDATE tech.maintenance_log
        SET status = 'FAILED',
            completed_at = CURRENT_TIMESTAMP,
            details = jsonb_build_object('error', SQLERRM)
        WHERE log_id = v_log_id;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 4. Scheduled Entry Point (analyze-only; vacuum via shell script)
-- ============================================================

CREATE OR REPLACE FUNCTION tech.run_scheduled_maintenance(p_force BOOLEAN DEFAULT FALSE)
RETURNS JSONB AS $$
DECLARE
    v_needed BOOLEAN;
    v_result JSONB;
BEGIN
    v_needed := tech.should_run_maintenance();

    IF NOT p_force AND NOT v_needed THEN
        INSERT INTO tech.maintenance_log (job_type, status, triggered_by, notes, details)
        VALUES (
            'SCHEDULED', 'SKIPPED', current_user,
            'No maintenance required',
            jsonb_build_object('should_run', false)
        );

        RETURN jsonb_build_object(
            'status', 'SKIPPED',
            'message', 'All tables healthy; no maintenance needed',
            'should_run_maintenance', false
        );
    END IF;

    PERFORM tech.run_analyze_maintenance();

    v_result := jsonb_build_object(
        'status', 'COMPLETED',
        'message', 'Analyze maintenance completed',
        'should_run_maintenance', v_needed,
        'vacuum_note', 'Run enhanced/ops/run_maintenance.sh --vacuum for VACUUM operations',
        'plan', (
            SELECT COALESCE(jsonb_agg(row_to_json(p)), '[]'::JSONB)
            FROM tech.get_maintenance_plan() p
        )
    );

    INSERT INTO tech.maintenance_log (job_type, status, triggered_by, notes, details)
    VALUES ('SCHEDULED', 'COMPLETED', current_user, 'run_scheduled_maintenance', v_result);

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 5. Replace legacy maintenance function (VACUUM removed — not allowed in functions)
-- ============================================================

DROP FUNCTION IF EXISTS tech.perform_database_maintenance();

CREATE OR REPLACE FUNCTION tech.perform_database_maintenance()
RETURNS JSONB AS $$
DECLARE
    v_log_id INTEGER;
    v_analyze_count INTEGER;
BEGIN
    INSERT INTO tech.maintenance_log (job_type, status, triggered_by, notes)
    VALUES ('FULL', 'STARTED', current_user, 'perform_database_maintenance')
    RETURNING log_id INTO v_log_id;

    SELECT COUNT(*) INTO v_analyze_count
    FROM tech.run_analyze_maintenance();

    -- REINDEX is permitted inside functions (PostgreSQL 17)
    REINDEX TABLE tech.customer;
    REINDEX TABLE tech.device;
    REINDEX TABLE tech.repair_order;
    REINDEX TABLE tech.technician;
    REINDEX TABLE tech.part_used;
    REINDEX TABLE tech.user_role;
    REINDEX TABLE tech.audit_log;
    REINDEX TABLE tech.repair_notes;

    UPDATE tech.maintenance_log
    SET status = 'COMPLETED',
        completed_at = CURRENT_TIMESTAMP,
        tables_processed = v_analyze_count,
        details = jsonb_build_object(
            'tables_analyzed', v_analyze_count,
            'tables_reindexed', 8,
            'vacuum_deferred', true,
            'vacuum_script', 'enhanced/ops/run_maintenance.sh --vacuum'
        )
    WHERE log_id = v_log_id;

    RETURN jsonb_build_object(
        'status', 'COMPLETED',
        'tables_analyzed', v_analyze_count,
        'tables_reindexed', 8,
        'vacuum_note', 'VACUUM must be run via enhanced/ops/run_maintenance.sh --vacuum'
    );

EXCEPTION
    WHEN OTHERS THEN
        UPDATE tech.maintenance_log
        SET status = 'FAILED',
            completed_at = CURRENT_TIMESTAMP,
            details = jsonb_build_object('error', SQLERRM)
        WHERE log_id = v_log_id;
        RAISE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION tech.perform_database_maintenance() IS
    'Runs ANALYZE, refreshes materialized views, and REINDEXes tech tables. VACUUM is handled by run_maintenance.sh.';

-- ============================================================
-- 6. Grants
-- ============================================================

GRANT SELECT ON tech.maintenance_log TO admin_login, auditor_login;
GRANT INSERT, UPDATE ON tech.maintenance_log TO admin_login;

GRANT EXECUTE ON FUNCTION tech.should_run_maintenance(INTEGER) TO admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.get_maintenance_plan() TO admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.run_analyze_maintenance() TO admin_login;
GRANT EXECUTE ON FUNCTION tech.run_scheduled_maintenance(BOOLEAN) TO admin_login;
GRANT EXECUTE ON FUNCTION tech.refresh_analytics_views() TO admin_login;
GRANT EXECUTE ON FUNCTION tech.perform_database_maintenance() TO admin_login;

\echo 'Maintenance automation applied successfully.'