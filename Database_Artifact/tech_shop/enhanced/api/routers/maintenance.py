from typing import Annotated

from fastapi import APIRouter, Depends

from db_utils import fetch_all, fetch_one
from dependencies import CurrentUser, require_roles
from models import MaintenanceStatusResponse

router = APIRouter(prefix="/maintenance", tags=["Maintenance"])


@router.get("/status", response_model=MaintenanceStatusResponse)
async def maintenance_status(
    current_user: Annotated[CurrentUser, Depends(require_roles("admin", "auditor"))],
):
    """Database maintenance health — used to demonstrate sysadmin automation in the DB layer."""
    needed_row = fetch_one(
        current_user,
        "SELECT tech.should_run_maintenance() AS maintenance_needed",
    )
    plan = fetch_all(current_user, "SELECT * FROM tech.get_maintenance_plan()")
    summary = fetch_one(
        current_user,
        """
        SELECT total_indexes, unused_indexes, tables_needing_attention,
               tables_high_seq_scan, total_schema_size, snapshot_at
        FROM tech.v_schema_performance_summary
        """,
    )
    return {
        "maintenance_needed": bool(needed_row and needed_row["maintenance_needed"]),
        "tables_needing_attention": summary["tables_needing_attention"] if summary else 0,
        "recommended_actions": plan,
        "performance_summary": summary,
    }