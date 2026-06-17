#!/usr/bin/env bash
# Tech Repair Shop — Maintenance Runner (VACUUM + scheduled jobs)
# Author: Frank Lawrence
# Purpose: Run VACUUM outside SQL functions; orchestrate scheduled maintenance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"
LOG_FILE="${SCRIPT_DIR}/backups/maintenance.log"

MODE="scheduled"
TARGET_DB=""
FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [--scheduled | --analyze | --vacuum | --full] [--db NAME] [--force]

Modes:
  --scheduled   Run analyze if should_run_maintenance() is true (default)
  --analyze     Run in-database ANALYZE + refresh materialized views
  --vacuum      Run VACUUM ANALYZE on all tech schema tables
  --full        Run analyze, vacuum, and full maintenance function

Options:
  --db NAME     Target database (default: DB_NAME from config)
  --force       Run scheduled maintenance even if not required
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

psql_cmd() {
    "$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TARGET_DB" \
        -v ON_ERROR_STOP=1 "$@"
}

log_vacuum_job() {
    local status="$1"
    local tables="$2"
    local notes="$3"
    psql_cmd -c "
        INSERT INTO tech.maintenance_log (job_type, status, tables_processed, completed_at, notes, details)
        VALUES (
            'VACUUM', '${status}', ${tables}, CURRENT_TIMESTAMP,
            '${notes}',
            jsonb_build_object('runner', 'run_maintenance.sh', 'mode', '${MODE}')
        );"
}

run_vacuum() {
    local table count=0
    log "Starting VACUUM ANALYZE on schema ${SCHEMA_NAME}"

    while IFS= read -r table; do
        [[ -z "$table" ]] && continue
        log "VACUUM ANALYZE ${SCHEMA_NAME}.${table}"
        psql_cmd -c "VACUUM ANALYZE ${SCHEMA_NAME}.${table};"
        count=$((count + 1))
    done < <(psql_cmd -tAc \
        "SELECT tablename FROM pg_tables WHERE schemaname = '${SCHEMA_NAME}' ORDER BY tablename;")

    log_vacuum_job "COMPLETED" "$count" "VACUUM ANALYZE via shell runner"
    log "VACUUM complete (${count} tables)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scheduled) MODE="scheduled"; shift ;;
        --analyze) MODE="analyze"; shift ;;
        --vacuum) MODE="vacuum"; shift ;;
        --full) MODE="full"; shift ;;
        --db) TARGET_DB="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
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

mkdir -p "${SCRIPT_DIR}/backups"
export PGPASSWORD="${DB_PASSWORD:-}"

log "=== Maintenance run started (mode: ${MODE}, db: ${TARGET_DB}) ==="

case "$MODE" in
    scheduled)
        if [[ "$FORCE" == true ]]; then
            result="$(psql_cmd -tAc "SELECT tech.run_scheduled_maintenance(true);")"
        else
            result="$(psql_cmd -tAc "SELECT tech.run_scheduled_maintenance(false);")"
        fi
        log "Scheduled result: ${result}"
        ;;
    analyze)
        count="$(psql_cmd -tAc "SELECT COUNT(*) FROM tech.run_analyze_maintenance();")"
        log "Analyze maintenance complete (${count} objects processed)"
        ;;
    vacuum)
        run_vacuum
        ;;
    full)
        psql_cmd -c "SELECT tech.perform_database_maintenance();" >/dev/null
        run_vacuum
        log "Full maintenance complete"
        ;;
esac

log "=== Maintenance run finished ==="