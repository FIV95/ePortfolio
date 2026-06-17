import os
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from fastapi import HTTPException, status

from database import APP_ROLE_TO_DB_ROLE, service_connection

JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))


def authenticate_user(username: str, password: str) -> dict[str, Any]:
    with service_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT tech.verify_user_password(%s, %s)",
                (username, password),
            )
            valid = cur.fetchone()[0]
            if not valid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid username or password.",
                )

            cur.execute(
                """
                SELECT username, role, technician_id
                FROM tech.user_role
                WHERE username = %s
                """,
                (username,),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User account not found.",
                )

    app_role = row[1]
    db_role = APP_ROLE_TO_DB_ROLE.get(app_role)
    if not db_role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account role is not permitted to use the API.",
        )

    technician_id: int | None = None
    if app_role == "tech":
        try:
            technician_id = int(row[2])
        except (TypeError, ValueError) as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Technician account is missing a valid technician ID.",
            ) from exc

    return {
        "username": row[0],
        "role": app_role,
        "technician_id": technician_id,
        "db_role": db_role,
    }


def create_access_token(user: dict[str, Any]) -> tuple[str, int]:
    expires_minutes = JWT_EXPIRE_MINUTES
    expire = datetime.now(timezone.utc) + timedelta(minutes=expires_minutes)
    payload = {
        "sub": user["username"],
        "role": user["role"],
        "db_role": user["db_role"],
        "technician_id": user["technician_id"],
        "exp": expire,
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token, expires_minutes


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your session has expired. Please sign in again.",
        ) from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        ) from exc