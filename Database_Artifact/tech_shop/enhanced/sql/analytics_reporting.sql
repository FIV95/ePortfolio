-- Database Enhancement: Advanced Analytics & Reporting (Fixed)
-- Author: Frank Lawrence
-- Date: 2026-06-06

SET search_path TO tech;

-- Drop old function to fix type conflict
DROP FUNCTION IF EXISTS tech.get_monthly_revenue_summary();

-- Materialized Views (skip if already exist)
CREATE MATERIALIZED VIEW IF NOT EXISTS tech.technician_performance AS
SELECT 
    t.id AS technician_id,
    t.first_name || ' ' || t.last_name AS full_name,
    t.specialty,
    t.hourly_rate,
    COUNT(ro.id) AS total_repairs,
    ROUND(AVG(ro.total_cost), 2) AS avg_repair_cost,
    ROUND(SUM(ro.total_cost), 2) AS total_revenue,
    COUNT(CASE WHEN ro.status = 'CLOSED' THEN 1 END) AS closed_repairs
FROM technician t
LEFT JOIN repair_order ro ON ro.technician_id = t.id
WHERE t.is_active = true
GROUP BY t.id, t.first_name, t.last_name, t.specialty, t.hourly_rate;

CREATE MATERIALIZED VIEW IF NOT EXISTS tech.repair_aging AS
SELECT 
    status,
    priority,
    COUNT(*) AS repair_count,
    ROUND(AVG(EXTRACT(DAY FROM CURRENT_DATE - created_at)), 1) AS avg_days_open,
    SUM(total_cost) AS total_value
FROM repair_order
GROUP BY status, priority;

-- Fixed Function
CREATE OR REPLACE FUNCTION tech.get_monthly_revenue_summary()
RETURNS TABLE (
    month TEXT,
    repair_count BIGINT,
    total_revenue NUMERIC,
    avg_cost NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(created_at, 'YYYY-MM') AS month,
        COUNT(*) AS repair_count,
        ROUND(SUM(total_cost), 2) AS total_revenue,
        ROUND(AVG(total_cost), 2) AS avg_cost
    FROM tech.repair_order
    GROUP BY TO_CHAR(created_at, 'YYYY-MM')
    ORDER BY month DESC;
END;
$$ LANGUAGE plpgsql STABLE
SET search_path TO tech;

-- Refresh views
REFRESH MATERIALIZED VIEW tech.technician_performance;
REFRESH MATERIALIZED VIEW tech.repair_aging;

COMMENT ON MATERIALIZED VIEW tech.technician_performance IS 'Pre-computed performance metrics using enhanced schema';
COMMENT ON MATERIALIZED VIEW tech.repair_aging IS 'Aging analysis by status and priority';

\echo "Advanced analytics and reporting enhancement (fixed) applied successfully."
