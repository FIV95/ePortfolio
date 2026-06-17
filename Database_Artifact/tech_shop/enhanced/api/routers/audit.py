from typing import Annotated

from fastapi import APIRouter, Depends, Query

from db_utils import fetch_all
from dependencies import CurrentUser, require_roles
from models import AuditLogResponse

router = APIRouter(prefix="/audit", tags=["Admin & Audit"])


@router.get(
    "",
    response_model=AuditLogResponse,
    summary="View audit trail",
    description=(
        "Shows a history of database changes (inserts, updates, deletes). "
        "Available to administrators and auditors only."
    ),
)
async def list_audit_logs(
    current_user: Annotated[CurrentUser, Depends(require_roles("admin", "auditor"))],
    limit: Annotated[int, Query(ge=1, le=200, description="Maximum records to return")] = 50,
    offset: Annotated[int, Query(ge=0, description="Skip this many records")] = 0,
    table_name: Annotated[str | None, Query(description="Filter by table name")] = None,
):
    if table_name:
        rows = fetch_all(
            current_user,
            """
            SELECT audit_id, table_name, record_id, action_type, changed_by,
                   changed_at, old_values, new_values, notes
            FROM tech.audit_log
            WHERE table_name = %s
            ORDER BY changed_at DESC
            LIMIT %s OFFSET %s
            """,
            (table_name, limit, offset),
        )
    else:
        rows = fetch_all(
            current_user,
            """
            SELECT audit_id, table_name, record_id, action_type, changed_by,
                   changed_at, old_values, new_values, notes
            FROM tech.audit_log
            ORDER BY changed_at DESC
            LIMIT %s OFFSET %s
            """,
            (limit, offset),
        )

    return {"count": len(rows), "results": rows}