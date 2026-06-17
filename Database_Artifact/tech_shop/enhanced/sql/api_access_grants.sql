-- Database Enhancement: API Access Grants
-- Author: Frank Lawrence
-- Date: 2026-06-07
-- Purpose: Allow admin/auditor API roles to read analytics used by Quick Query endpoints

SET search_path TO tech;

GRANT SELECT ON tech.technician_performance TO admin_login, auditor_login;
GRANT SELECT ON tech.repair_aging TO admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.get_monthly_revenue_summary() TO admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.decrypt_text(BYTEA) TO tech_login, admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.should_run_maintenance(INTEGER) TO admin_login, auditor_login;
GRANT EXECUTE ON FUNCTION tech.get_maintenance_plan() TO admin_login, auditor_login;

\echo 'API access grants applied successfully.'