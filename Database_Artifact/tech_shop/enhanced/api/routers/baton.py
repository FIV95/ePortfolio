from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from db_utils import execute_returning, fetch_one
from dependencies import CurrentUser, get_current_user, require_roles

router = APIRouter(prefix="/repairs", tags=["Repairs"])


@router.post(
    "/{repair_id}/baton/claim",
    summary="Claim the baton on a repair",
    description=(
        "Pick up an available repair ticket. Only one technician can hold the baton at a time. "
        "Technicians only."
    ),
)
async def claim_baton(
    repair_id: int,
    current_user: Annotated[CurrentUser, Depends(require_roles("tech"))],
):
    visible = fetch_one(
        current_user,
        """
        SELECT id, baton_technician_id, status
        FROM tech.repair_order
        WHERE id = %s
        """,
        (repair_id,),
    )
    if not visible:
        raise HTTPException(
            status_code=404,
            detail=f"Repair #{repair_id} was not found or you cannot access it.",
        )
    if visible["status"] == "Closed":
        raise HTTPException(
            status_code=400,
            detail="Closed repairs cannot be claimed.",
        )
    if visible["baton_technician_id"] is not None:
        raise HTTPException(
            status_code=409,
            detail="Another technician already holds the baton on this repair.",
        )

    try:
        result = execute_returning(
            current_user,
            "SELECT * FROM tech.claim_baton(%s)",
            (repair_id,),
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=409,
            detail="Could not claim the baton. It may have just been picked up by someone else.",
        ) from exc

    return {
        "repair_id": result["repair_id"],
        "baton_technician_id": result["baton_technician_id"],
        "baton_claimed_at": result["baton_claimed_at"],
        "message": result["message"],
    }


@router.post(
    "/{repair_id}/baton/drop",
    summary="Drop the baton on a repair",
    description=(
        "Release your active hold on a repair so another technician can pick it up. "
        "Technicians only."
    ),
)
async def drop_baton(
    repair_id: int,
    current_user: Annotated[CurrentUser, Depends(require_roles("tech"))],
):
    try:
        result = execute_returning(
            current_user,
            "SELECT * FROM tech.drop_baton(%s)",
            (repair_id,),
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=403,
            detail="You can only drop the baton on repairs you are actively holding.",
        ) from exc

    return {
        "repair_id": result["repair_id"],
        "baton_technician_id": result["baton_technician_id"],
        "baton_claimed_at": result["baton_claimed_at"],
        "message": result["message"],
    }