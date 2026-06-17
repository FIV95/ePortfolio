from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from auth import decode_access_token

security = HTTPBearer(auto_error=False)


@dataclass
class CurrentUser:
    username: str
    role: str
    db_role: str
    technician_id: int | None = None


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> CurrentUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Sign in and include a Bearer token.",
        )

    payload = decode_access_token(credentials.credentials)
    return CurrentUser(
        username=payload["sub"],
        role=payload["role"],
        db_role=payload["db_role"],
        technician_id=payload.get("technician_id"),
    )


def require_roles(*allowed_roles: str):
    def checker(user: Annotated[CurrentUser, Depends(get_current_user)]) -> CurrentUser:
        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this resource.",
            )
        return user

    return checker