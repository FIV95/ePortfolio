#!/usr/bin/env bash
# Tech Repair Shop — Maintenance Verification (Step 1.5)
# Author: Frank Lawrence

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"

TARGET_DB=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
pass() { TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1)); log "PASS: $1"; }
fail() { TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1)); log "FAIL: $1"; }

query() {
    "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" -tAc "$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db) TARGET_DB="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# shellcheck source=env_config.env
source "$CONFIG_FILE"

TARGET_DB="${TARGET_DB:-$DB_NAME}"
PSQL_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}psql"
export PGPASSWORD="${DB_PASSWORD:-}"

log "=== Maintenance tests started for database: ${TARGET_DB} ==="

if [[ "$(query "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='tech' AND table_name='maintenance_log');")" == "t" ]]; then
    pass "maintenance_log table exists"
else
    fail "maintenance_log table missing"
fi

if [[ "$(query "SELECT tech.should_run_maintenance();")" == "t" ]]; then
    pass "should_run_maintenance() returns true on dev/staging data"
else
    fail "should_run_maintenance() expected true before maintenance"
fi

plan_count="$(query "SELECT COUNT(*) FROM tech.get_maintenance_plan();")"
if [[ "$plan_count" -gt 0 ]]; then
    pass "get_maintenance_plan() returned ${plan_count} recommended actions"
else
    fail "get_maintenance_plan() returned no actions"
fi

analyze_count="$(query "SELECT COUNT(*) FROM tech.run_analyze_maintenance();")"
expected_analyze=$(( $(query "SELECT COUNT(*) FROM pg_tables WHERE schemaname='tech';") + 2 ))
if [[ "$analyze_count" -eq "$expected_analyze" ]]; then
    pass "run_analyze_maintenance() processed ${analyze_count} objects"
else
    fail "run_analyze_maintenance() expected ${expected_analyze} objects, got ${analyze_count}"
fi

log_rows="$(query "SELECT COUNT(*) FROM tech.maintenance_log WHERE job_type='ANALYZE' AND status='COMPLETED';")"
if [[ "$log_rows" -ge 1 ]]; then
    pass "maintenance_log recorded completed ANALYZE job"
else
    fail "maintenance_log missing completed ANALYZE entry"
fi

if "${SCRIPT_DIR}/run_maintenance.sh" --vacuum --db "$TARGET_DB" >>"${SCRIPT_DIR}/backups/maintenance.log" 2>&1; then
    pass "run_maintenance.sh --vacuum succeeded"
else
    fail "run_maintenance.sh --vacuum failed"
fi

vacuum_logs="$(query "SELECT COUNT(*) FROM tech.maintenance_log WHERE job_type='VACUUM' AND status='COMPLETED';")"
if [[ "$vacuum_logs" -ge 1 ]]; then
    pass "maintenance_log recorded completed VACUUM job"
else
    fail "maintenance_log missing completed VACUUM entry"
fi

maint_result="$(query "SELECT tech.perform_database_maintenance();")"
if [[ "$maint_result" == *"COMPLETED"* ]]; then
    pass "perform_database_maintenance() returns COMPLETED"
else
    fail "perform_database_maintenance() failed: ${maint_result}"
fi

healthy_count="$(query "SELECT COUNT(*) FROM tech.v_table_health WHERE maintenance_status='HEALTHY';")"
table_count="$(query "SELECT COUNT(*) FROM pg_tables WHERE schemaname='tech';")"
if [[ "$healthy_count" -eq "$table_count" ]]; then
    pass "all ${table_count} tables report HEALTHY after maintenance"
else
    fail "expected ${table_count} HEALTHY tables, got ${healthy_count}"
fi

log "=== Maintenance tests complete: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed ==="
echo "Results: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed"

[[ "$TESTS_FAILED" -eq 0 ]]