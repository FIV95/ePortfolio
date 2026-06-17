from datetime import date, datetime
from typing import Any

import psycopg
import psycopg.rows
from fastapi import HTTPException
from fastapi.encoders import jsonable_encoder

from database import role_connection
from dependencies import CurrentUser

DATETIME_DISPLAY_FMT = "%b %d, %Y, %I:%M %p"
DATE_DISPLAY_FMT = "%b %d, %Y"


def _format_display_value(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.strftime(DATETIME_DISPLAY_FMT)
    if isinstance(value, date):
        return value.strftime(DATE_DISPLAY_FMT)
    return value


def encode_row(row: dict[str, Any]) -> dict[str, Any]:
    return jsonable_encoder({key: _format_display_value(val) for key, val in row.items()})


def fetch_all(
    user: CurrentUser,
    sql: str,
    params: tuple = (),
) -> list[dict[str, Any]]:
    try:
        with role_connection(user.db_role, user.technician_id) as conn:
            with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                cur.execute(sql, params)
                return [encode_row(row) for row in cur.fetchall()]
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=500,
            detail="We could not load this data right now. Please try again later.",
        ) from exc


def fetch_one(
    user: CurrentUser,
    sql: str,
    params: tuple = (),
) -> dict[str, Any] | None:
    rows = fetch_all(user, sql, params)
    return rows[0] if rows else None


def execute_returning(
    user: CurrentUser,
    sql: str,
    params: tuple = (),
) -> dict[str, Any]:
    try:
        with role_connection(user.db_role, user.technician_id) as conn:
            with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                cur.execute(sql, params)
                row = cur.fetchone()
                conn.commit()
                if not row:
                    raise HTTPException(
                        status_code=500,
                        detail="The operation completed but no record was returned.",
                    )
                return encode_row(row)
    except HTTPException:
        raise
    except psycopg.Error as exc:
        message = getattr(getattr(exc, "diag", None), "message_primary", None) or str(exc)
        raise HTTPException(status_code=400, detail=message) from exc