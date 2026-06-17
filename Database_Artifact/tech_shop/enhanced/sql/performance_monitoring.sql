-- Database Enhancement: Performance Monitoring & Index Analysis
-- Author: Frank Lawrence
-- Date: 2026-06-06
-- Purpose: Observability views for index usage, table health, and query tuning

SET search_path TO tech;

-- ============================================================
-- 1. Index Usage Analysis
-- ============================================================

CREATE OR REPLACE VIEW tech.v_index_usage AS
SELECT
    s.schemaname,
    s.relname AS table_name,
    s.indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
    s.idx_scan AS times_used,
    s.idx_tup_read AS tuples_read,
    s.idx_tup_fetch AS tuples_fetched,
    i.indexdef AS index_definition,
    CASE
        WHEN s.idx_scan = 0 THEN 'UNUSED'
        WHEN s.idx_scan < 10 THEN 'LOW'
        WHEN s.idx_scan < 100 THEN 'MODERATE'
        ELSE 'ACTIVE'
    END AS usage_level
FROM pg_stat_user_indexes s
JOIN pg_indexes i
    ON i.schemaname = s.schemaname
   AND i.tablename = s.relname
   AND i.indexname = s.indexrelname
WHERE s.schemaname = 'tech'
ORDER BY s.idx_scan ASC, pg_relation_size(s.indexrelid) DESC;

COMMENT ON VIEW tech.v_index_usage IS
    'Index scan counts and sizes for the tech schema; highlights unused or low-activity indexes';

-- ============================================================
-- 2. Unused Index Candidates
-- ============================================================

CREATE OR REPLACE VIEW tech.v_unused_indexes AS
SELECT
    schemaname,
    table_name,
    index_name,
    index_size,
    index_definition
FROM tech.v_index_usage
WHERE times_used = 0
  AND index_name NOT LIKE '%_pkey'
ORDER BY pg_relation_size((schemaname || '.' || index_name)::regclass) DESC;

COMMENT ON VIEW tech.v_unused_indexes IS
    'Non-primary-key indexes with zero scans; candidates for review before removal';

-- ============================================================
-- 3. Table Scan Behavior (sequential vs index)
-- ============================================================

CREATE OR REPLACE VIEW tech.v_table_scan_summary AS
SELECT
    schemaname,
    relname AS table_name,
    seq_scan AS sequential_scans,
    idx_scan AS index_scans,
    seq_tup_read AS rows_read_via_seq_scan,
    idx_tup_fetch AS rows_fetched_via_index,
    n_live_tup AS estimated_live_rows,
    n_dead_tup AS dead_rows,
    CASE
        WHEN (seq_scan + idx_scan) = 0 THEN 0
        ELSE ROUND(100.0 * idx_scan / (seq_scan + idx_scan), 1)
    END AS index_scan_pct,
    CASE
        WHEN seq_scan > idx_scan AND n_live_tup > 1000 THEN 'REVIEW'
        WHEN n_dead_tup > n_live_tup * 0.2 AND n_live_tup > 0 THEN 'VACUUM'
        ELSE 'OK'
    END AS health_flag
FROM pg_stat_user_tables
WHERE schemaname = 'tech'
ORDER BY seq_scan DESC, n_dead_tup DESC;

COMMENT ON VIEW tech.v_table_scan_summary IS
    'Sequential vs index scan ratios and dead-row flags per table';

-- ============================================================
-- 4. Table Health & Maintenance Timestamps
-- ============================================================

CREATE OR REPLACE VIEW tech.v_table_health AS
SELECT
    t.schemaname,
    t.relname AS table_name,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(c.oid) - pg_relation_size(c.oid)) AS index_size,
    t.n_live_tup AS live_rows,
    t.n_dead_tup AS dead_rows,
    t.n_tup_ins AS inserts,
    t.n_tup_upd AS updates,
    t.n_tup_del AS deletes,
    t.last_vacuum,
    t.last_autovacuum,
    t.last_analyze,
    t.last_autoanalyze,
    CASE
        WHEN t.last_analyze IS NULL AND t.last_autoanalyze IS NULL THEN 'NEVER_ANALYZED'
        WHEN COALESCE(t.last_analyze, t.last_autoanalyze) < NOW() - INTERVAL '7 days' THEN 'STALE_STATS'
        WHEN t.n_dead_tup > GREATEST(t.n_live_tup * 0.1, 100) THEN 'NEEDS_VACUUM'
        ELSE 'HEALTHY'
    END AS maintenance_status
FROM pg_stat_user_tables t
JOIN pg_class c
    ON c.relname = t.relname
JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname = t.schemaname
WHERE t.schemaname = 'tech'
ORDER BY pg_total_relation_size(c.oid) DESC;

COMMENT ON VIEW tech.v_table_health IS
    'Table sizes, row activity, and vacuum/analyze freshness for the tech schema';

-- ============================================================
-- 5. Schema Performance Dashboard
-- ============================================================

CREATE OR REPLACE VIEW tech.v_schema_performance_summary AS
SELECT
    'tech' AS schema_name,
    (SELECT COUNT(*) FROM tech.v_index_usage) AS total_indexes,
    (SELECT COUNT(*) FROM tech.v_unused_indexes) AS unused_indexes,
    (SELECT COUNT(*) FROM tech.v_table_health WHERE maintenance_status <> 'HEALTHY') AS tables_needing_attention,
    (SELECT COUNT(*) FROM tech.v_table_scan_summary WHERE health_flag = 'REVIEW') AS tables_high_seq_scan,
    (SELECT pg_size_pretty(SUM(pg_total_relation_size((schemaname || '.' || relname)::regclass)))
     FROM pg_stat_user_tables
     WHERE schemaname = 'tech') AS total_schema_size,
    NOW() AS snapshot_at;

COMMENT ON VIEW tech.v_schema_performance_summary IS
    'High-level performance dashboard for the tech schema';

-- ============================================================
-- 6. Report Function (callable from psql or future API)
-- ============================================================

CREATE OR REPLACE FUNCTION tech.get_performance_report()
RETURNS TABLE (
    section TEXT,
    item TEXT,
    metric TEXT,
    detail TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        'SUMMARY'::TEXT,
        s.schema_name::TEXT,
        (s.unused_indexes::TEXT || ' unused indexes'),
        (s.tables_needing_attention::TEXT || ' tables need attention; size ' || s.total_schema_size::TEXT)
    FROM tech.v_schema_performance_summary s;

    RETURN QUERY
    SELECT
        'UNUSED_INDEX'::TEXT,
        u.table_name::TEXT,
        u.index_name::TEXT,
        (u.index_size::TEXT || ' — ' || LEFT(u.index_definition, 80))
    FROM tech.v_unused_indexes u
    LIMIT 10;

    RETURN QUERY
    SELECT
        'TABLE_HEALTH'::TEXT,
        h.table_name::TEXT,
        h.maintenance_status::TEXT,
        (h.total_size::TEXT || '; dead rows: ' || h.dead_rows::TEXT)
    FROM tech.v_table_health h
    WHERE h.maintenance_status <> 'HEALTHY'
    ORDER BY h.dead_rows DESC
    LIMIT 10;

    RETURN QUERY
    SELECT
        'SEQ_SCAN'::TEXT,
        ts.table_name::TEXT,
        ts.health_flag::TEXT,
        ('seq=' || ts.sequential_scans::TEXT || ' idx=' || ts.index_scans::TEXT
            || ' (' || ts.index_scan_pct::TEXT || '% index)')
    FROM tech.v_table_scan_summary ts
    WHERE ts.health_flag = 'REVIEW'
    LIMIT 10;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION tech.get_performance_report() IS
    'Human-readable performance snapshot for ops review or API exposure';

\echo 'Performance monitoring views and report function applied successfully.'