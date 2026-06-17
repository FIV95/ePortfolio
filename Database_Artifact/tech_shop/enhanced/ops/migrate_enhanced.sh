#!/usr/bin/env bash
# Tech Repair Shop — Migrate Existing Database to Enhanced Schema
# Author: Frank Lawrence
# Purpose: Apply enhancement SQL to an existing original-schema database

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"
LOG_FILE="${SCRIPT_DIR}/backups/migrate.log"

TARGET_DB=""

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
Usage: $(basename "$0") [--db NAME]

Options:
  --db NAME   Target database (default: DB_NAME from backup_config.env)

Example:
  $(basename "$0") --db tech_shop
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
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

log "=== Enhanced migration started ==="
log "Target database: ${TARGET_DB}"

schema_exists="$("$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" -tAc \
    "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = '${SCHEMA_NAME}');")"

if [[ "$schema_exists" != "t" ]]; then
    log "FAILED: schema '${SCHEMA_NAME}' not found in ${TARGET_DB}"
    exit 1
fi

for sql_file in "${ENHANCED_SQL[@]}"; do
    absolute_path="${PROJECT_ROOT}/${sql_file}"
    if [[ ! -f "$absolute_path" ]]; then
        log "FAILED: SQL file not found: ${absolute_path}"
        exit 1
    fi
    log "Applying ${sql_file}"
    if "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" \
        -v ON_ERROR_STOP=1 -f "$absolute_path" >>"$LOG_FILE" 2>&1; then
        log "OK: ${sql_file}"
    else
        log "FAILED: ${sql_file}"
        exit 1
    fi
done

log "=== Enhanced migration completed successfully ==="
echo "Migration complete: ${TARGET_DB}"
echo "Run ./verify_environment.sh --db ${TARGET_DB} to test."