#!/usr/bin/env bash
# Tech Repair Shop — Database Restore Script
# Author: Frank Lawrence
# Purpose: Safe restore from pg_dump SQL files with confirmation checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup_config.env"
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="${BACKUP_DIR}/restore.log"

FORCE=false
BACKUP_FILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") <backup_file> [--force]

Arguments:
  backup_file     Path to a .sql backup (absolute, relative, or filename in backups/)

Options:
  --force         Skip interactive confirmation (for automation/CI)

Examples:
  $(basename "$0") backups/tech_shop_full_20260606_120000.sql
  $(basename "$0") tech_shop_schema_20260606_120000.sql --force
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

resolve_backup_path() {
    local candidate="$1"

    if [[ -f "$candidate" ]]; then
        echo "$candidate"
        return 0
    fi

    if [[ -f "${SCRIPT_DIR}/${candidate}" ]]; then
        echo "${SCRIPT_DIR}/${candidate}"
        return 0
    fi

    if [[ -f "${BACKUP_DIR}/${candidate}" ]]; then
        echo "${BACKUP_DIR}/${candidate}"
        return 0
    fi

    return 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *)
            if [[ -z "$BACKUP_FILE" ]]; then
                BACKUP_FILE="$1"
            else
                echo "Unexpected argument: $1" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Error: backup file is required." >&2
    usage >&2
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# shellcheck source=backup_config.env
source "$CONFIG_FILE"

PSQL_BIN="${PG_BIN_DIR:+$PG_BIN_DIR/}psql"
if ! command -v "$PSQL_BIN" >/dev/null 2>&1; then
    echo "psql not found: $PSQL_BIN" >&2
    exit 1
fi

RESOLVED_BACKUP=""
if ! RESOLVED_BACKUP="$(resolve_backup_path "$BACKUP_FILE")"; then
    echo "Error: backup file not found: $BACKUP_FILE" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

if [[ "$FORCE" != true ]]; then
    echo "Restore target:"
    echo "  Database : ${DB_NAME}@${DB_HOST}:${DB_PORT}"
    echo "  Schema   : ${SCHEMA_NAME}"
    echo "  Backup   : ${RESOLVED_BACKUP}"
    echo
    read -r -p "This will overwrite objects in schema '${SCHEMA_NAME}'. Continue? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
fi

export PGPASSWORD="${DB_PASSWORD:-}"

PSQL=("$PSQL_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1)

log "Starting restore"
log "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
log "Schema:   ${SCHEMA_NAME}"
log "Source:   ${RESOLVED_BACKUP}"

# Data-only backups assume the schema already exists.
if [[ "$(basename "$RESOLVED_BACKUP")" == *"_data_"* ]]; then
    SCHEMA_EXISTS="$("${PSQL[@]}" -tAc "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = '${SCHEMA_NAME}');")"
    if [[ "$SCHEMA_EXISTS" != "t" ]]; then
        log "FAILED: data-only restore requires existing schema '${SCHEMA_NAME}'"
        exit 1
    fi
    log "Data-only restore detected; existing schema preserved"
else
    log "Full/schema restore: dropping and recreating schema '${SCHEMA_NAME}'"
    "${PSQL[@]}" -c "DROP SCHEMA IF EXISTS ${SCHEMA_NAME} CASCADE;"
    "${PSQL[@]}" -c "CREATE SCHEMA ${SCHEMA_NAME};"
fi

if "${PSQL[@]}" -f "$RESOLVED_BACKUP"; then
    TABLE_COUNT="$("${PSQL[@]}" -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = '${SCHEMA_NAME}';")"
    log "SUCCESS: Restore completed (${TABLE_COUNT} tables in schema '${SCHEMA_NAME}')"
    exit 0
else
    log "FAILED: psql restore exited with an error"
    exit 1
fi