from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Query

from db_utils import fetch_all, fetch_one
from dependencies import CurrentUser, get_current_user, require_roles
from models import QuickQueryResponse

router = APIRouter(
    prefix="/quick",
    tags=["Quick Queries"],
)

TechBucket = Literal["queue", "holding", "available", "my_open", "my_closed"]

TECH_BUCKET_META = {
    "queue": {
        "title": "Work Queue",
        "description": "Repairs you are holding plus open tickets available to claim.",
    },
    "holding": {
        "title": "Holding Baton",
        "description": "Repairs you are actively working (you hold the baton).",
    },
    "available": {
        "title": "Available to Claim",
        "description": "Open repairs with no baton holder — grab one to start working.",
    },
    "my_open": {
        "title": "My Open History",
        "description": "Open repairs you have previously worked on (claimed or noted).",
    },
    "my_closed": {
        "title": "My Closed History",
        "description": "Closed repairs you have previously worked on.",
    },
}

REPAIR_LIST_BASE = """
    SELECT
        ro.id AS repair_id,
        ro.status,
        ro.priority,
        ro.issue_description,
        ro.total_cost,
        ro.created_at,
        ro.baton_technician_id,
        ro.baton_claimed_at,
        bt.first_name || ' ' || bt.last_name AS baton_holder,
        (ro.baton_technician_id IS NULL AND ro.status <> 'Closed') AS baton_available,
        t.first_name || ' ' || t.last_name AS technician,
        c.first_name || ' ' || c.last_name AS customer_name,
        COALESCE(d.device_type || ' ' || d.model, 'Unknown device') AS device,
        (SELECT COUNT(*)::int FROM tech.repair_notes n WHERE n.repair_order_id = ro.id) AS note_count
    FROM tech.repair_order ro
    LEFT JOIN tech.device d ON d.id = ro.device_id
    LEFT JOIN tech.customer c ON c.id = d.customer_id
    LEFT JOIN tech.technician t ON t.id = ro.technician_id
    LEFT JOIN tech.technician bt ON bt.id = ro.baton_technician_id
"""

REPAIR_LIST_ORDER = """
    ORDER BY
        CASE WHEN ro.status = 'Closed' THEN 2 ELSE 1 END,
        CASE WHEN ro.baton_technician_id IS NULL THEN 0 ELSE 1 END,
        ro.priority DESC,
        ro.id ASC
"""

REPAIR_LIST_SQL = REPAIR_LIST_BASE + REPAIR_LIST_ORDER


def _tech_bucket_clause(bucket: TechBucket, technician_id: int) -> tuple[str, tuple]:
    clauses = {
        "queue": (
            "(ro.baton_technician_id = %s "
            "OR (ro.baton_technician_id IS NULL AND ro.status <> 'Closed'))",
            (technician_id,),
        ),
        "holding": ("ro.baton_technician_id = %s", (technician_id,)),
        "available": (
            "ro.baton_technician_id IS NULL AND ro.status <> 'Closed'",
            (),
        ),
        "my_open": (
            "ro.status <> 'Closed' "
            "AND tech.tech_interacted_with_repair(ro.id, %s)",
            (technician_id,),
        ),
        "my_closed": (
            "ro.status = 'Closed' "
            "AND tech.tech_interacted_with_repair(ro.id, %s)",
            (technician_id,),
        ),
    }
    return clauses[bucket]


@router.get(
    "/repairs",
    response_model=QuickQueryResponse,
    summary="List all repairs (with IDs)",
    description=(
        "**Start here after login.** Shows every repair you can access with repair_id, "
        "customer, device, and status. Technicians: use **bucket** to filter by baton state."
    ),
)
async def list_repairs(
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    bucket: Annotated[
        TechBucket | None,
        Query(description="Technician baton filter: queue, holding, available, my_open, my_closed"),
    ] = None,
):
    if current_user.role == "tech":
        if current_user.technician_id is None:
            raise HTTPException(
                status_code=500,
                detail="Technician account is missing a valid technician ID.",
            )
        active_bucket: TechBucket = bucket or "queue"
        clause, params = _tech_bucket_clause(active_bucket, current_user.technician_id)
        sql = REPAIR_LIST_BASE + f" WHERE {clause} " + REPAIR_LIST_ORDER
        rows = fetch_all(current_user, sql, params)
        meta = TECH_BUCKET_META[active_bucket]
        return {
            "title": meta["title"],
            "description": meta["description"],
            "count": len(rows),
            "bucket": active_bucket,
            "results": rows,
        }

    rows = fetch_all(current_user, REPAIR_LIST_SQL)
    return {
        "title": "Repair List",
        "description": "Every repair in the shop you can access.",
        "count": len(rows),
        "results": rows,
    }


@router.get(
    "/repairs/{repair_id}",
    summary="Repair detail (includes notes)",
    description="Full detail for one repair — issue, customer, device, cost, and all notes in one response.",
)
async def repair_detail(
    repair_id: int,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
):
    repair = fetch_all(
        current_user,
        REPAIR_LIST_BASE + " WHERE ro.id = %s",
        (repair_id,),
    )
    if not repair:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=404,
            detail=f"Repair #{repair_id} not found or not visible to your account.",
        )
    notes = fetch_all(
        current_user,
        """
        SELECT note_id, note_text, note_type, created_at, created_by
        FROM tech.repair_notes
        WHERE repair_order_id = %s
        ORDER BY created_at DESC
        """,
        (repair_id,),
    )
    repair_row = repair[0]
    i_hold_baton = (
        current_user.role == "tech"
        and current_user.technician_id is not None
        and repair_row.get("baton_technician_id") == current_user.technician_id
    )
    baton_available = bool(repair_row.get("baton_available"))
    return {
        "title": f"Repair #{repair_id}",
        "description": "Full repair detail with notes attached.",
        "repair": repair_row,
        "notes": notes,
        "note_count": len(notes),
        "baton": {
            "holder": repair_row.get("baton_holder"),
            "claimed_at": repair_row.get("baton_claimed_at"),
            "available": baton_available,
            "i_hold_baton": i_hold_baton,
            "can_claim": current_user.role == "tech" and baton_available,
            "can_drop": i_hold_baton,
            "can_add_note": current_user.role != "tech" or i_hold_baton,
        },
    }


@router.get(
    "/open-repairs",
    response_model=QuickQueryResponse,
    summary="Show open repairs",
    description=(
        "Returns repairs that are not closed yet. "
        "Technicians see baton-filtered open repairs. "
        "Customer service and managers see all open repairs."
    ),
)
async def open_repairs(
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
):
    rows = fetch_all(
        current_user,
        REPAIR_LIST_BASE
        + """
        WHERE ro.status <> 'Closed'
        ORDER BY ro.priority DESC, ro.created_at ASC
        """,
    )
    scope = (
        "your active repairs"
        if current_user.role == "tech"
        else "all open repairs in the shop"
    )
    return {
        "title": "Open Repairs",
        "description": f"Repairs that still need attention (not marked Closed) — {scope}.",
        "count": len(rows),
        "results": rows,
    }


@router.get(
    "/customers",
    response_model=QuickQueryResponse,
    summary="Customer contact list",
    description=(
        "Customer names and contact details. "
        "Sensitive fields are automatically masked for technician accounts."
    ),
)
async def customer_list(
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
):
    rows = fetch_all(
        current_user,
        """
        SELECT id, first_name, last_name, email, phone, address, loyalty_points
        FROM tech.v_customer_contact
        ORDER BY last_name, first_name
        """,
    )
    return {
        "title": "Customer List",
        "description": "Customer contact information (masked when required by your role).",
        "count": len(rows),
        "results": rows,
    }


@router.get(
    "/monthly-revenue",
    response_model=QuickQueryResponse,
    summary="Monthly revenue summary",
    description=(
        "Revenue totals by month. "
        "Available to administrators and auditors."
    ),
)
async def monthly_revenue(
    current_user: Annotated[CurrentUser, Depends(require_roles("admin", "auditor"))],
):
    rows = fetch_all(
        current_user,
        "SELECT month, repair_count, total_revenue, avg_cost FROM tech.get_monthly_revenue_summary()",
    )
    return {
        "title": "Monthly Revenue",
        "description": "Repair revenue summarized by month.",
        "count": len(rows),
        "results": rows,
    }


@router.get(
    "/role-overview",
    summary="Role-specific snapshot",
    description="Small dashboard cards tailored to your role — used by /app.",
)
async def role_overview(
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
):
    if current_user.role == "admin":
        open_count = fetch_one(
            current_user,
            "SELECT COUNT(*)::int AS n FROM tech.repair_order WHERE status <> 'Closed'",
        )
        revenue = fetch_all(
            current_user,
            "SELECT month, total_revenue FROM tech.get_monthly_revenue_summary() LIMIT 1",
        )
        top_tech = fetch_one(
            current_user,
            """
            SELECT full_name, total_repairs FROM tech.technician_performance
            ORDER BY total_repairs DESC LIMIT 1
            """,
        )
        return {
            "role": "admin",
            "title": "Shop Overview",
            "cards": [
                {"label": "Open repairs", "value": open_count["n"] if open_count else 0},
                {
                    "label": "Latest month revenue",
                    "value": f"${revenue[0]['total_revenue']}" if revenue else "$0",
                },
                {
                    "label": "Busiest technician",
                    "value": top_tech["full_name"] if top_tech else "—",
                },
            ],
        }

    if current_user.role == "auditor":
        recent = fetch_all(
            current_user,
            """
            SELECT changed_at, table_name, action_type, changed_by
            FROM tech.audit_log
            ORDER BY changed_at DESC
            LIMIT 5
            """,
        )
        return {
            "role": "auditor",
            "title": "Recent Database Changes",
            "items": recent,
        }

    if current_user.role == "customer_service":
        open_count = fetch_one(
            current_user,
            "SELECT COUNT(*)::int AS n FROM tech.repair_order WHERE status <> 'Closed'",
        )
        customer_count = fetch_one(
            current_user,
            "SELECT COUNT(*)::int AS n FROM tech.customer",
        )
        return {
            "role": "customer_service",
            "title": "Customer Service Desk",
            "message": "View all repairs and customers, and add notes for callers.",
            "cards": [
                {"label": "Open repairs (shop-wide)", "value": open_count["n"] if open_count else 0},
                {"label": "Customers on file", "value": customer_count["n"] if customer_count else 0},
            ],
        }

    tech_id = current_user.technician_id
    holding = fetch_one(
        current_user,
        """
        SELECT COUNT(*)::int AS n FROM tech.repair_order
        WHERE baton_technician_id = %s
        """,
        (tech_id,),
    )
    available = fetch_one(
        current_user,
        """
        SELECT COUNT(*)::int AS n FROM tech.repair_order
        WHERE baton_technician_id IS NULL AND status <> 'Closed'
        """,
    )
    my_open = fetch_one(
        current_user,
        """
        SELECT COUNT(*)::int AS n FROM tech.repair_order ro
        WHERE ro.status <> 'Closed'
          AND tech.tech_interacted_with_repair(ro.id, %s)
        """,
        (tech_id,),
    )
    return {
        "role": "tech",
        "title": "Your Workbench",
        "message": "Grab the baton to work a ticket. Drop it when you are done so another tech can pick it up.",
        "cards": [
            {"label": "Holding baton", "value": holding["n"] if holding else 0},
            {"label": "Available to claim", "value": available["n"] if available else 0},
            {"label": "My open history", "value": my_open["n"] if my_open else 0},
        ],
    }