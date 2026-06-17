from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from db_utils import execute_returning, fetch_one
from dependencies import CurrentUser, get_current_user
from models import RepairNoteCreate, RepairNoteResponse

router = APIRouter(prefix="/repairs", tags=["Repairs"])


@router.post(
    "/{repair_id}/notes",
    response_model=RepairNoteResponse,
    summary="Add a note to a repair",
    description="Adds a note. Technicians must hold the baton on the repair.",
)
async def create_repair_note(
    repair_id: int,
    note: RepairNoteCreate,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
):
    repair = fetch_one(
        current_user,
        """
        SELECT id, baton_technician_id, status
        FROM tech.repair_order
        WHERE id = %s
        """,
        (repair_id,),
    )
    if not repair:
        raise HTTPException(
            status_code=404,
            detail=f"Repair order {repair_id} was not found or you do not have access to it.",
        )

    if current_user.role == "tech":
        if repair["baton_technician_id"] != current_user.technician_id:
            raise HTTPException(
                status_code=403,
                detail="You must hold the baton on this repair before adding notes.",
            )
        technician_id = current_user.technician_id
    else:
        technician_id = None

    return execute_returning(
        current_user,
        """
        INSERT INTO tech.repair_notes (
            repair_order_id, technician_id, note_text, note_type, created_by
        )
        VALUES (%s, %s, %s, %s, %s)
        RETURNING note_id, repair_order_id, technician_id, note_text, note_type,
                  created_at, created_by
        """,
        (repair_id, technician_id, note.note_text, note.note_type, current_user.username),
    )