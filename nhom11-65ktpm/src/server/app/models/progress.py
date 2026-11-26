"""Sự kiện học tập: nguồn dữ liệu chung cho trang chủ, thống kê, streak, XP, huy hiệu.

Mỗi tính năng (bài học, flashcard, phát âm, viết chữ, trợ lý AI, bài kiểm tra) chỉ
cần ghi sự kiện qua `POST /api/events` (từ app) hoặc `record_events()` (trên server).
Các màn tổng hợp đọc `daily_stats`, `streaks`, `users.xp_total` hoặc bảng này,
nên không ai phải gọi thẳng vào module của người khác.

Định dạng và danh sách loại sự kiện: docs/hop-dong-du-lieu.md.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Index, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, JSONType


class EventType:
    LESSON_COMPLETED = "lesson_completed"
    SRS_REVIEW = "srs_review"
    PRONUNCIATION_SCORED = "pronunciation_scored"
    CHARACTER_WRITTEN = "character_written"
    AI_SESSION_FINISHED = "ai_session_finished"
    QUIZ_COMPLETED = "quiz_completed"
    PLACEMENT_COMPLETED = "placement_completed"
    STUDY_SESSION = "study_session"

    ALL = (
        LESSON_COMPLETED,
        SRS_REVIEW,
        PRONUNCIATION_SCORED,
        CHARACTER_WRITTEN,
        AI_SESSION_FINISHED,
        QUIZ_COMPLETED,
        PLACEMENT_COMPLETED,
        STUDY_SESSION,
    )


class LearningEvent(Base):
    __tablename__ = "learning_events"
    __table_args__ = (Index("ix_learning_events_user_occurred", "user_id", "occurred_at"),)

    # Do app sinh (UUID v4) nên gửi lại nhiều lần vẫn không bị ghi trùng.
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    type: Mapped[str] = mapped_column(String(32), index=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    xp: Mapped[int] = mapped_column(Integer, default=0)
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    score: Mapped[float | None] = mapped_column(Float)  # 0..100
    # Đối tượng liên quan: mã bài học, id từ, chữ Hán, id phiên AI...
    ref_id: Mapped[str | None] = mapped_column(String(64))
    data: Mapped[dict | None] = mapped_column(JSONType)
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
