"""Router gốc `/api`: mỗi module tính năng đăng ký router con tại đây."""

from fastapi import APIRouter

from app.api.routes import ai, auth, events, health, me, path, pronunciation

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(me.router)
api_router.include_router(ai.router)
api_router.include_router(events.router)
api_router.include_router(path.router)
api_router.include_router(pronunciation.router)
