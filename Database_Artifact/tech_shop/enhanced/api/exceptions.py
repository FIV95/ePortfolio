from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from models import ErrorResponse


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(HTTPException)
    async def http_exception_handler(_request: Request, exc: HTTPException) -> JSONResponse:
        message = exc.detail if isinstance(exc.detail, str) else "Request could not be completed."
        return JSONResponse(
            status_code=exc.status_code,
            content=ErrorResponse(
                error=_status_label(exc.status_code),
                message=message,
            ).model_dump(),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        _request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        first_error = exc.errors()[0] if exc.errors() else {}
        field = " -> ".join(str(part) for part in first_error.get("loc", []) if part != "body")
        message = "Please check your request and try again."
        if field:
            message = f"Invalid value for '{field}'. Please check your request and try again."

        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=ErrorResponse(
                error="Validation Error",
                message=message,
            ).model_dump(),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        _request: Request, _exc: Exception
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=ErrorResponse(
                error="Server Error",
                message="Something went wrong on our end. Please try again in a moment.",
            ).model_dump(),
        )


def _status_label(status_code: int) -> str:
    labels = {
        401: "Authentication Required",
        403: "Access Denied",
        404: "Not Found",
        422: "Validation Error",
        500: "Server Error",
    }
    return labels.get(status_code, "Request Error")