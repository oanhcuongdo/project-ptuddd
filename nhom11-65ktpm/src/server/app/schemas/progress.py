import uuid
from datetime import UTC, datetime, timedelta
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.progress import EventType

EventTypeName = Literal[EventType.ALL]  # type: ignore[valid-type]


class EventIn(BaseModel):
    id: uuid.UUID = Field(description="UUID do app sinh, dùng để chống ghi trùng khi gửi lại")
    type: EventTypeName
    occurred_at: datetime
    xp: int = Field(default=0, ge=0, le=500)
    duration_sec: int = Field(default=0, ge=0, le=4 * 3600)
    score: float | None = Field(default=None, ge=0, le=100)
    ref_id: str | None = Field(default=None, max_length=64)
    data: dict | None = None

    @field_validator("occurred_at")
    @classmethod
    def _not_in_future(cls, v: datetime) -> datetime:
        aware = v if v.tzinfo else v.replace(tzinfo=UTC)
        if aware > datetime.now(UTC) + timedelta(minutes=5):
            raise ValueError("occurred_at không được ở tương lai")
        return aware


class EventBatchIn(BaseModel):
    events: list[EventIn] = Field(min_length=1, max_length=200)


class EventBatchOut(BaseModel):
    accepted: int
    duplicates: int
    xp_total: int
    current_streak: int
    longest_streak: int


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    type: str
    occurred_at: datetime
    xp: int
    duration_sec: int
    score: float | None
    ref_id: str | None
    data: dict | None
