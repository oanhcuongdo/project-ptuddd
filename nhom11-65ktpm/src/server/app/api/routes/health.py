from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.services.ai.providers import provider_configured

router = APIRouter(tags=["health"])


@router.get("/health", summary="Kiểm tra trạng thái server và kết nối CSDL")
def health_check(db: Session = Depends(get_db)) -> dict:
    try:
        db.execute(text("SELECT 1"))
        database = "connected"
    except SQLAlchemyError:
        database = "unavailable"

    return {
        "status": "healthy" if database == "connected" else "degraded",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "database": database,
        "services": {
            "ai_assistant": {
                "provider": settings.AI_PROVIDER,
                "status": "configured" if provider_configured() else "not_configured",
            },
            "pronunciation_online": "configured" if settings.AZURE_SPEECH_KEY else "not_configured",
        },
    }
