#!/usr/bin/env bash
# Tech Repair Shop API — Smoke Test Suite
# Author: Frank Lawrence

set -euo pipefail

BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
PASS=0
FAIL=0

log() { echo "[$(date '+%H:%M:%S')] $*"; }
ok() { PASS=$((PASS + 1)); log "PASS: $1"; }
bad() { FAIL=$((FAIL + 1)); log "FAIL: $1"; }

login() {
    curl -s -X POST "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$1\",\"password\":\"$2\"}" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])"
}

log "=== API smoke tests (${BASE_URL}) ==="

if curl -sf "${BASE_URL}/health" >/dev/null; then
    ok "GET /health"
else
    bad "GET /health"
    echo "Is the server running? Try: uvicorn main:app --reload"
    exit 1
fi

if curl -sf "${BASE_URL}/app" | grep -q "Tech Repair Shop"; then
    ok "GET /app"
else
    bad "GET /app"
fi

if curl -sL -o /dev/null -w "%{url_effective}" "${BASE_URL}/start" | grep -q "/app$"; then
    ok "GET /start redirects to /app"
else
    bad "GET /start redirects to /app"
fi

if curl -sf "${BASE_URL}/auth/demo-accounts" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if len(d.get('accounts',[]))==6 and len(d.get('role_groups',[]))==4 else 1)"; then
    ok "GET /auth/demo-accounts"
else
    bad "GET /auth/demo-accounts"
fi

CS_TOKEN="$(login cs_jordan cs123)"
TECH_TOKEN="$(login tech_tom pass123)"
ADMIN_TOKEN="$(login admin_mary admin123)"

if curl -sf "${BASE_URL}/quick/role-overview" -H "Authorization: Bearer ${CS_TOKEN}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('role')=='customer_service' else 1)"; then
    ok "GET /quick/role-overview (customer service)"
else
    bad "GET /quick/role-overview (customer service)"
fi

if curl -sf "${BASE_URL}/quick/repairs?bucket=queue" -H "Authorization: Bearer ${TECH_TOKEN}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('bucket')=='queue' and d.get('count',0)>0 else 1)"; then
    ok "GET /quick/repairs?bucket=queue (tech)"
else
    bad "GET /quick/repairs?bucket=queue (tech)"
fi

if curl -sf "${BASE_URL}/quick/repairs" -H "Authorization: Bearer ${CS_TOKEN}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('count',0)>0 else 1)"; then
    ok "GET /quick/repairs (customer service)"
else
    bad "GET /quick/repairs (customer service)"
fi

if curl -s "${BASE_URL}/audit" -H "Authorization: Bearer ${TECH_TOKEN}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('error')=='Access Denied' else 1)"; then
    ok "GET /audit blocked for tech"
else
    bad "GET /audit blocked for tech"
fi

if curl -sf "${BASE_URL}/maintenance/status" -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'maintenance_needed' in d else 1)"; then
    ok "GET /maintenance/status (admin)"
else
    bad "GET /maintenance/status (admin)"
fi

if curl -s "${BASE_URL}/auth/me" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('error')=='Authentication Required' else 1)"; then
    ok "GET /auth/me requires token"
else
    bad "GET /auth/me requires token"
fi

log "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ "$FAIL" -eq 0 ]]