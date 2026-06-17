#!/usr/bin/env bash
# Tech Repair Shop — Environment Verification / Test Harness
# Author: Frank Lawrence
# Purpose: Assert that backup, monitoring, and schema objects are present and working

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"
LOG_FILE="${SCRIPT_DIR}/backups/verify.log"

TARGET_DB=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [--db NAME]

Runs automated checks for Steps 1.1–1.3:
  - Required tables, views, materialized views, and functions exist
  - Seed data thresholds are met
  - Performance monitoring views return data
  - Performance report function executes
  - Backup script succeeds (dry run against target DB via config override)

Exit code 0 = all tests passed, 1 = one or more failures.
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

pass() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log "PASS: $1"
}

fail() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log "FAIL: $1"
}

query() {
    "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" -tAc "$1"
}

assert_object_exists() {
    local type="$1"
    local name="$2"
    local sql=""

    case "$type" in
        table)
            sql="SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='${SCHEMA_NAME}' AND table_name='${name}');"
            ;;
        view)
            sql="SELECT EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema='${SCHEMA_NAME}' AND table_name='${name}');"
            ;;
        matview)
            sql="SELECT EXISTS (SELECT 1 FROM pg_matviews WHERE schemaname='${SCHEMA_NAME}' AND matviewname='${name}');"
            ;;
        function)
            sql="SELECT EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='${SCHEMA_NAME}' AND p.proname='${name}');"
            ;;
    esac

    if [[ "$(query "$sql")" == "t" ]]; then
        pass "${type} ${SCHEMA_NAME}.${name} exists"
    else
        fail "${type} ${SCHEMA_NAME}.${name} missing"
    fi
}

assert_min_count() {
    local table="$1"
    local min="$2"
    local count
    count="$(query "SELECT COUNT(*) FROM ${SCHEMA_NAME}.${table};")"
    if [[ "$count" -ge "$min" ]]; then
        pass "${table} row count ${count} >= ${min}"
    else
        fail "${table} row count ${count} < ${min}"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db) TARGET_DB="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# shellcheck source=env_config.env
source "$CONFIG_FILE"

TARGET_DB="${TARGET_DB:-$DB_NAME}"
PSQL_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}psql"

mkdir -p "${SCRIPT_DIR}/backups"
export PGPASSWORD="${DB_PASSWORD:-}"

log "=== Verification started for database: ${TARGET_DB} ==="

# --- Schema objects (Step 1.2 + enhancements) ---
for table in customer device technician repair_order part_used user_role audit_log repair_notes repair_baton_log maintenance_log; do
    assert_object_exists table "$table"
done

for view in v_index_usage v_unused_indexes v_table_scan_summary v_table_health v_schema_performance_summary; do
    assert_object_exists view "$view"
done

for matview in technician_performance repair_aging; do
    assert_object_exists matview "$matview"
done

for func in perform_database_maintenance get_performance_report get_monthly_revenue_summary log_audit_changes claim_baton drop_baton should_run_maintenance run_scheduled_maintenance; do
    assert_object_exists function "$func"
done

if [[ "$(query "SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cs_login');")" == "t" ]]; then
    pass "PostgreSQL role cs_login exists"
else
    fail "PostgreSQL role cs_login missing"
fi

# --- Seed data sanity (rich sample data after full migration) ---
assert_min_count customer 30
assert_min_count repair_order 35

# --- Performance monitoring queries (Step 1.2) ---
index_count="$(query "SELECT COUNT(*) FROM ${SCHEMA_NAME}.v_index_usage;")"
if [[ "$index_count" -gt 0 ]]; then
    pass "v_index_usage returned ${index_count} rows"
else
    fail "v_index_usage returned no rows"
fi

summary_count="$(query "SELECT COUNT(*) FROM ${SCHEMA_NAME}.v_schema_performance_summary;")"
if [[ "$summary_count" -eq 1 ]]; then
    pass "v_schema_performance_summary returned dashboard row"
else
    fail "v_schema_performance_summary expected 1 row, got ${summary_count}"
fi

report_count="$(query "SELECT COUNT(*) FROM ${SCHEMA_NAME}.get_performance_report();")"
if [[ "$report_count" -gt 0 ]]; then
    pass "get_performance_report() returned ${report_count} rows"
else
    fail "get_performance_report() returned no rows"
fi

# --- Backup script smoke test (Step 1.1) ---
if "${SCRIPT_DIR}/backup_db.sh" --schema-only --db "$TARGET_DB" >>"$LOG_FILE" 2>&1; then
    pass "backup_db.sh --schema-only succeeded for ${TARGET_DB}"
else
    fail "backup_db.sh --schema-only failed for ${TARGET_DB}"
fi

log "=== Verification complete: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed ==="

echo ""
echo "Results: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
    exit 1
fi

exit 0