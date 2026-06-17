from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from dotenv import load_dotenv
import os

from auth import authenticate_user, create_access_token
from database import service_connection
from demo_accounts import DEMO_ACCOUNTS, DEMO_ROLE_GROUPS
from dependencies import CurrentUser, get_current_user
from exceptions import register_exception_handlers
from models import LoginRequest, TokenResponse, UserInfo
from routers.audit import router as audit_router
from routers.maintenance import router as maintenance_router
from routers.quick import router as quick_router
from routers.baton import router as baton_router
from routers.repairs import router as repairs_router
from app_page import render_app_page

load_dotenv()

app = FastAPI(
    title="Tech Repair Shop",
    description=(
        "Use **/app** in your browser — a simple repair shop dashboard backed by "
        "PostgreSQL roles, row-level security, audit logging, and the baton workflow."
    ),
    version="1.0.0",
    docs_url=None,
    redoc_url=None,
)

register_exception_handlers(app)

app.include_router(quick_router)
app.include_router(repairs_router)
app.include_router(baton_router)
app.include_router(audit_router)
app.include_router(maintenance_router)

DB_NAME = os.getenv("DB_NAME")


@app.get("/")
async def root():
    """Primary entry point — the repair shop web app."""
    return RedirectResponse(url="/app")


@app.get("/start")
async def start_redirect():
    """Legacy bookmark — sends users to /app."""
    return RedirectResponse(url="/app")


@app.get("/app")
async def repair_shop_app():
    """Simple web app for all roles — sign in, view repairs, claim batons, add notes."""
    return render_app_page()


@app.get("/health")
async def health_check():
    try:
        with service_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version();")
                version = cur.fetchone()[0]
        return {
            "status": "healthy",
            "database": "connected",
            "postgres_version": version,
            "db_name": DB_NAME,
        }
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="The API is running but the database is not reachable.",
        ) from exc


@app.get("/auth/demo-accounts")
async def list_demo_accounts():
    """Lists demo users grouped by role — used by the /app login screen."""
    return {
        "message": "Pick a role type, then a user.",
        "role_groups": DEMO_ROLE_GROUPS,
        "accounts": DEMO_ACCOUNTS,
    }


@app.post("/auth/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """Sign in with a demo shop account."""
    user = authenticate_user(request.username, request.password)
    token, expires_minutes = create_access_token(user)
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in_minutes": expires_minutes,
        "user": user,
    }


@app.get("/auth/me", response_model=UserInfo)
async def get_me(current_user: CurrentUser = Depends(get_current_user)):
    """Returns the signed-in user's role and technician assignment."""
    return {
        "username": current_user.username,
        "role": current_user.role,
        "technician_id": current_user.technician_id,
        "db_role": current_user.db_role,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("API_PORT", 8000)),
    )