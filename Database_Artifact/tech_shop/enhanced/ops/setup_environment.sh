#!/usr/bin/env bash
# Tech Repair Shop — Full Environment Setup
# Author: Frank Lawrence
# Purpose: Provision a fresh database from original + enhanced SQL (dev/staging/cloud simulation)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"
LOG_FILE="${SCRIPT_DIR}/backups/setup.log"

TARGET_DB=""
FRESH=false
SKIP_ROLES=false
SKIP_SEED=false

ORIGINAL_SQL=(
    "original/table_creation.sql"
    "original/trigger_creation.sql"
    "original/indexes.sql"
    "original/seed_data.sql"
    "original/roles.sql"
)

ENHANCED_SQL=(
    "enhanced/sql/schema_enhancements.sql"
    "enhanced/sql/audit_logging.sql"
    "enhanced/sql/add_repair_notes.sql"
    "enhanced/sql/analytics_reporting.sql"
    "enhanced/sql/performance_monitoring.sql"
    "enhanced/sql/security_hardening.sql"
    "enhanced/sql/maintenance_automation.sql"
    "enhanced/sql/api_access_grants.sql"
    "enhanced/sql/demo_data_boost.sql"
    "enhanced/sql/rich_sample_data.sql"
    "enhanced/sql/customer_service_role.sql"
    "enhanced/sql/baton_system.sql"
)

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --db NAME        Target database (default: STAGING_DB_NAME from env_config.env)
  --fresh          Drop and recreate the target database before setup
  --skip-roles     Skip roles.sql (use when login roles already exist cluster-wide)
  --skip-seed      Skip seed_data.sql
  -h, --help       Show this help

Example:
  $(basename "$0") --db tech_shop_staging --fresh --skip-roles
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

run_sql_file() {
    local relative_path="$1"
    local absolute_path="${PROJECT_ROOT}/${relative_path}"

    if [[ ! -f "$absolute_path" ]]; then
        log "FAILED: SQL file not found: ${absolute_path}"
        exit 1
    fi

    log "Applying ${relative_path}"
    if "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" \
        -v ON_ERROR_STOP=1 -f "$absolute_path" >>"$LOG_FILE" 2>&1; then
        log "OK: ${relative_path}"
    else
        log "FAILED: ${relative_path}"
        exit 1
    fi
}

roles_already_exist() {
    local role_count
    role_count="$("$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc \
        "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('tech_login', 'admin_login', 'auditor_login', 'cs_login');")"
    [[ "$role_count" -eq 3 ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db) TARGET_DB="$2"; shift 2 ;;
        --fresh) FRESH=true; shift ;;
        --skip-roles) SKIP_ROLES=true; shift ;;
        --skip-seed) SKIP_SEED=true; shift ;;
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

TARGET_DB="${TARGET_DB:-$STAGING_DB_NAME}"
PSQL_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}psql"
CREATEDB_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}createdb"
DROPDB_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}dropdb"

mkdir -p "${SCRIPT_DIR}/backups"
export PGPASSWORD="${DB_PASSWORD:-}"

log "=== Environment setup started ==="
log "Target database: ${TARGET_DB}"

if [[ "$FRESH" == true ]]; then
    log "Fresh mode: dropping database if it exists"
    "$DROPDB_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --if-exists "$TARGET_DB" >>"$LOG_FILE" 2>&1 || true
fi

if ! "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname = '${TARGET_DB}';" | grep -q 1; then
    log "Creating database: ${TARGET_DB}"
    "$CREATEDB_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TARGET_DB" >>"$LOG_FILE" 2>&1
else
    log "Database already exists: ${TARGET_DB}"
fi

for sql_file in "${ORIGINAL_SQL[@]}"; do
    if [[ "$sql_file" == "original/seed_data.sql" && "$SKIP_SEED" == true ]]; then
        log "Skipping seed_data.sql"
        continue
    fi
    if [[ "$sql_file" == "original/roles.sql" ]]; then
        if [[ "$SKIP_ROLES" == true ]]; then
            log "Skipping roles.sql (--skip-roles)"
            continue
        fi
        if roles_already_exist; then
            log "Skipping roles.sql (cluster login roles already exist)"
            continue
        fi
    fi
    run_sql_file "$sql_file"
done

for sql_file in "${ENHANCED_SQL[@]}"; do
    run_sql_file "$sql_file"
done

log "=== Environment setup completed successfully ==="
echo "Setup complete: ${TARGET_DB}"
echo "Run ./verify_environment.sh --db ${TARGET_DB} to test."