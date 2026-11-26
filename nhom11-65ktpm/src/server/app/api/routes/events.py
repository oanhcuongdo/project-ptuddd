"""Sự kiện học tập: app gửi lên sau mỗi hoạt động, các màn tổng hợp đọc lại."""

from datetime import datetime

from fastapi import APIRouter, Query
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.models import LearningEvent
from app.schemas.progress import EventBatchIn, EventBatchOut, EventOut
from app.services.progress import NewEvent, record_events

router = APIRouter(prefix="/events", tags=["progress"])


@router.post(
    "",
    response_model=EventBatchOut,
    summary="Ghi một lô sự kiện học tập (gửi lại cùng id sẽ được bỏ qua)",
)
def post_events(body: EventBatchIn, user: CurrentUser, db: DbSession) -> EventBatchOut:
    result = record_events(
        db,
        user,
        [
            NewEvent(
                id=e.id, type=e.type, occurred_at=e.occurred_at, xp=e.xp,
                duration_sec=e.duration_sec, score=e.score, ref_id=e.ref_id, data=e.data,
            )
            for e in body.events
        ],
    )
    db.commit()
    return EventBatchOut(**result.__dict__)


@router.get("", response_model=list[EventOut], summary="Sự kiện học tập của tôi, mới nhất trước")
def list_events(
    user: CurrentUser,
    db: DbSession,
    since: datetime | None = None,
    type: list[str] | None = Query(default=None, description="Lọc theo loại, có thể lặp lại"),
    limit: int = Query(default=200, ge=1, le=1000),
) -> list[LearningEvent]:
    query = select(LearningEvent).where(LearningEvent.user_id == user.id)
    if since is not None:
        query = query.where(LearningEvent.occurred_at >= since)
    if type:
        query = query.where(LearningEvent.type.in_(type))
    return list(db.scalars(query.order_by(LearningEvent.occurred_at.desc()).limit(limit)))
