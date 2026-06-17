from typing import Literal

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(..., examples=["cs_jordan"])
    password: str = Field(..., examples=["cs123"])


class UserInfo(BaseModel):
    username: str
    role: str
    technician_id: int | None = None
    db_role: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_minutes: int
    user: UserInfo


class QuickQueryResponse(BaseModel):
    title: str
    description: str
    count: int
    results: list[dict]
    bucket: str | None = None


class RepairNoteCreate(BaseModel):
    note_text: str = Field(..., min_length=1)
    note_type: Literal["GENERAL", "PROGRESS", "CUSTOMER", "PARTS", "RESOLUTION"] = "GENERAL"


class RepairNoteResponse(BaseModel):
    note_id: int
    repair_order_id: int
    technician_id: int | None = None
    note_text: str
    note_type: str
    created_at: str | None = None
    created_by: str | None = None


class AuditLogResponse(BaseModel):
    count: int
    results: list[dict]


class ErrorResponse(BaseModel):
    error: str
    message: str


class MaintenanceStatusResponse(BaseModel):
    maintenance_needed: bool
    tables_needing_attention: int
    recommended_actions: list[dict]
    performance_summary: dict | None = None