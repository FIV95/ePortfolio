#!/usr/bin/env bash
# Tech Repair Shop — Database Backup Script
# Author: Frank Lawrence
# Purpose: Production-ready pg_dump wrapper for the tech schema

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup_config.env"
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="${BACKUP_DIR}/backup.log"

MODE="full"
DB_OVERRIDE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--full | --schema-only | --data-only] [--db NAME]

Options:
  --full          Schema + data (default)
  --schema-only   DDL only (tables, indexes, functions, triggers)
  --data-only     Data only (requires existing schema)
  --db NAME       Override database name from config

Backups are written to: ${BACKUP_DIR}/
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full) MODE="full"; shift ;;
        --schema-only) MODE="schema-only"; shift ;;
        --data-only) MODE="data-only"; shift ;;
        --db) DB_OVERRIDE="$2"; shift 2 ;;
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

# shellcheck source=backup_config.env
source "$CONFIG_FILE"

if [[ -n "$DB_OVERRIDE" ]]; then
    DB_NAME="$DB_OVERRIDE"
fi

PG_DUMP="${PG_BIN_DIR:+$PG_BIN_DIR/}pg_dump"
if ! command -v "$PG_DUMP" >/dev/null 2>&1; then
    echo "pg_dump not found: $PG_DUMP" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DUMP_FLAGS=(--no-owner --no-acl -n "$SCHEMA_NAME" -F p)

case "$MODE" in
    full)
        SUFFIX="full"
        DUMP_FLAGS+=(--clean --if-exists)
        ;;
    schema-only)
        SUFFIX="schema"
        DUMP_FLAGS+=(--schema-only --clean --if-exists)
        ;;
    data-only)
        SUFFIX="data"
        DUMP_FLAGS+=(--data-only)
        ;;
esac

BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${SUFFIX}_${TIMESTAMP}.sql"

export PGPASSWORD="${DB_PASSWORD:-}"

log "Starting ${MODE} backup"
log "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
log "Schema:   ${SCHEMA_NAME}"

if "$PG_DUMP" \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    "${DUMP_FLAGS[@]}" \
    -f "$BACKUP_FILE"; then
    FILE_SIZE="$(du -h "$BACKUP_FILE" | awk '{print $1}')"
    log "SUCCESS: Backup written to ${BACKUP_FILE} (${FILE_SIZE})"
    exit 0
else
    log "FAILED: pg_dump exited with an error"
    exit 1
fi