#!/usr/bin/env bash
# Tech Repair Shop — Security Verification (Step 1.4)
# Author: Frank Lawrence
# Purpose: Test RLS, encryption, and role hardening with role switching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"

TARGET_DB=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [--db NAME]

Tests Step 1.4 security controls:
  - bcrypt password hashing
  - RLS on repair_order, repair_notes, audit_log, user_role, repair_baton_log
  - Baton-scoped technician access and customer service shop-wide read
  - Role-based grants (tech blocked from audit_log)
  - Masked customer contact view
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
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

query_as_role() {
    local role="$1"
    local tech_id="${2:-}"
    local sql="$3"
    local script="SET ROLE ${role};"
    if [[ -n "$tech_id" ]]; then
        script+=" SELECT tech.set_technician_context(${tech_id});"
    fi
    script+=" ${sql};"
    "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" -tAc "$script" | tail -1 | tr -d '[:space:]'
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

# shellcheck source=env_config.env
source "$CONFIG_FILE"

TARGET_DB="${TARGET_DB:-$DB_NAME}"
PSQL_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}psql"
export PGPASSWORD="${DB_PASSWORD:-}"

log "=== Security tests started for database: ${TARGET_DB} ==="

# --- Password encryption ---
if [[ "$(query "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='tech' AND table_name='user_role' AND column_name='password';")" -eq 0 ]]; then
    pass "plaintext password column removed from user_role"
else
    fail "plaintext password column still exists on user_role"
fi

if [[ "$(query "SELECT COUNT(*) FROM tech.user_role WHERE password_hash IS NOT NULL;")" -ge 3 ]]; then
    pass "user_role rows have bcrypt password_hash values"
else
    fail "user_role password_hash not populated"
fi

if [[ "$(query "SELECT tech.verify_user_password('tech_tom', 'pass123');")" == "t" ]]; then
    pass "verify_user_password accepts valid credentials"
else
    fail "verify_user_password rejected valid credentials"
fi

if [[ "$(query "SELECT tech.verify_user_password('tech_tom', 'wrong');")" == "f" ]]; then
    pass "verify_user_password rejects invalid credentials"
else
    fail "verify_user_password accepted invalid credentials"
fi

# --- RLS policies exist ---
policy_count="$(query "SELECT COUNT(*) FROM pg_policies WHERE schemaname='tech';")"
if [[ "$policy_count" -ge 10 ]]; then
    pass "RLS policies present (${policy_count})"
else
    fail "expected >= 10 RLS policies, found ${policy_count}"
fi

# --- repair_order RLS: baton workflow + role separation ---
total_repairs="$(query "SELECT COUNT(*) FROM tech.repair_order")"
tech1_count="$(query_as_role tech_login 1 "SELECT COUNT(*) FROM tech.repair_order")"
tech2_count="$(query_as_role tech_login 2 "SELECT COUNT(*) FROM tech.repair_order")"
admin_count="$(query_as_role admin_login "" "SELECT COUNT(*) FROM tech.repair_order")"
cs_count="$(query_as_role cs_login "" "SELECT COUNT(*) FROM tech.repair_order")"

if [[ "$admin_count" -eq "$total_repairs" ]]; then
    pass "admin_login sees all ${total_repairs} repair orders"
else
    fail "admin_login expected ${total_repairs} repair orders, got ${admin_count}"
fi

if [[ "$cs_count" -eq "$total_repairs" ]]; then
    pass "cs_login sees all ${total_repairs} repair orders"
else
    fail "cs_login expected ${total_repairs} repair orders, got ${cs_count}"
fi

if [[ "$tech1_count" -ge 1 && "$tech1_count" -lt "$total_repairs" ]]; then
    pass "tech_login (tech 1) sees baton-scoped subset (${tech1_count} of ${total_repairs})"
else
    fail "tech_login (tech 1) expected 1..$((total_repairs - 1)) repair orders, got ${tech1_count}"
fi

if [[ "$tech2_count" -ge 1 && "$tech2_count" -lt "$total_repairs" ]]; then
    pass "tech_login (tech 2) sees baton-scoped subset (${tech2_count} of ${total_repairs})"
else
    fail "tech_login (tech 2) expected 1..$((total_repairs - 1)) repair orders, got ${tech2_count}"
fi

if [[ "$(query "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='tech' AND table_name='repair_baton_log');")" == "t" ]]; then
    pass "repair_baton_log table exists"
else
    fail "repair_baton_log table missing"
fi

if [[ "$(query "SELECT EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='tech' AND p.proname='claim_baton');")" == "t" ]]; then
    pass "claim_baton() function exists"
else
    fail "claim_baton() function missing"
fi

# --- audit_log access ---
tech_audit="$(query_as_role tech_login 1 "SELECT COUNT(*) FROM tech.audit_log" 2>/dev/null || echo "DENIED")"
auditor_audit="$(query_as_role auditor_login "" "SELECT COUNT(*) FROM tech.audit_log")"

if [[ "$tech_audit" == "0" || "$tech_audit" == "DENIED" ]]; then
    pass "tech_login cannot read audit_log (${tech_audit})"
else
    fail "tech_login unexpectedly read audit_log (${tech_audit} rows)"
fi

if [[ "$auditor_audit" -ge 0 ]]; then
    pass "auditor_login can read audit_log (${auditor_audit} rows)"
else
    fail "auditor_login blocked from audit_log"
fi

# --- Masked customer view for technician ---
masked_email="$(query_as_role tech_login 1 "SELECT email FROM tech.v_customer_contact ORDER BY id LIMIT 1")"
if [[ "$masked_email" == *"*"* ]]; then
    pass "v_customer_contact masks email for tech_login"
else
    fail "v_customer_contact did not mask email for tech_login (${masked_email})"
fi

plain_email="$(query_as_role admin_login "" "SELECT email FROM tech.v_customer_contact ORDER BY id LIMIT 1")"
if [[ "$plain_email" != *"*"* ]]; then
    pass "v_customer_contact shows full email for admin_login"
else
    fail "v_customer_contact incorrectly masked email for admin_login"
fi

# --- Role hardening: connection limits ---
tech_limit="$(query "SELECT rolconnlimit FROM pg_roles WHERE rolname='tech_login';")"
if [[ "$tech_limit" == "10" ]]; then
    pass "tech_login connection limit set to 10"
else
    fail "tech_login connection limit expected 10, got ${tech_limit}"
fi

log "=== Security tests complete: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed ==="
echo ""
echo "Results: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
    exit 1
fi

exit 0