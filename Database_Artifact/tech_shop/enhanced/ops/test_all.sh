#!/usr/bin/env bash
# Tech Repair Shop — Full Test Suite (Steps 1.1–1.3)
# Author: Frank Lawrence
# Purpose: Run all verification checks in one command for portfolio demos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/env_config.env"

# shellcheck source=env_config.env
source "$CONFIG_FILE"

STAGING_DB="${STAGING_DB_NAME}"

echo "=== Tech Repair Shop — Full Test Suite ==="
echo ""

echo "--- Step 1.3: Provision staging environment ---"
"${SCRIPT_DIR}/setup_environment.sh" --db "$STAGING_DB" --fresh --skip-roles

echo ""
echo "--- Step 1.3: Verify staging environment ---"
"${SCRIPT_DIR}/verify_environment.sh" --db "$STAGING_DB"

echo ""
echo "--- Step 1.1/1.2: Verify production dev database (${DB_NAME}) ---"
"${SCRIPT_DIR}/verify_environment.sh" --db "$DB_NAME"

echo ""
echo "--- Step 1.4: Security tests (staging) ---"
"${SCRIPT_DIR}/test_security.sh" --db "$STAGING_DB"

echo ""
echo "--- Step 1.4: Security tests (dev) ---"
"${SCRIPT_DIR}/test_security.sh" --db "$DB_NAME"

echo ""
echo "--- Step 1.5: Maintenance tests (staging) ---"
"${SCRIPT_DIR}/test_maintenance.sh" --db "$STAGING_DB"

echo ""
echo "--- Step 1.5: Maintenance tests (dev) ---"
"${SCRIPT_DIR}/test_maintenance.sh" --db "$DB_NAME"

echo ""
echo "=== All tests passed ==="