import os
from contextlib import contextmanager
from typing import Iterator

import psycopg

APP_ROLE_TO_DB_ROLE = {
    "tech": "tech_login",
    "admin": "admin_login",
    "auditor": "auditor_login",
    "customer_service": "cs_login",
}


def _base_db_kwargs() -> dict:
    return {
        "dbname": os.getenv("DB_NAME"),
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", "5432"),
    }


def get_service_db_kwargs() -> dict:
    """Owner/service connection for login verification."""
    return {
        **_base_db_kwargs(),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD", ""),
    }


def get_role_db_kwargs(db_role: str) -> dict:
    env_key = db_role.upper().replace("_LOGIN", "")
    return {
        **_base_db_kwargs(),
        "user": os.getenv(f"DB_{env_key}_USER", db_role),
        "password": os.getenv(f"DB_{env_key}_PASSWORD", ""),
    }


@contextmanager
def service_connection() -> Iterator[psycopg.Connection]:
    with psycopg.connect(**get_service_db_kwargs()) as conn:
        yield conn


@contextmanager
def role_connection(
    db_role: str,
    technician_id: int | None = None,
) -> Iterator[psycopg.Connection]:
    with psycopg.connect(**get_role_db_kwargs(db_role)) as conn:
        if technician_id is not None:
            with conn.cursor() as cur:
                cur.execute("SELECT tech.set_technician_context(%s)", (technician_id,))
        yield conn