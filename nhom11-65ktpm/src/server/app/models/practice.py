"""Luyện viết, thẻ ôn tập SRS, thống kê ngày và streak."""

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, JSONType
from app.models._mixins import UserOwnedSyncMixin


class WritingAttempt(UserOwnedSyncMixin, Base):
    __tablename__ = "writing_attempts"

    character_id: Mapped[int | None] = mapped_column(
        ForeignKey("characters.id", ondelete="SET NULL"), index=True
    )
    hanzi: Mapped[str] = mapped_column(String(4))
    mode: Mapped[str] = mapped_column(String(10))  # watch | trace | free
    wrong_strokes: Mapped[int] = mapped_column(Integer, default=0)
    hints_used: Mapped[int] = mapped_column(Integer, default=0)
    score: Mapped[float] = mapped_column(Float)
    duration_ms: Mapped[int | None] = mapped_column(Integer)
    # Chi tiết lỗi từng nét: [{"stroke":2,"error":"wrong_direction"}]
    stroke_errors: Mapped[list | None] = mapped_column(JSONType)


class SrsCard(UserOwnedSyncMixin, Base):
    """Thẻ ôn tập theo thuật toán SM-2."""

    __tablename__ = "srs_cards"
    __table_args__ = (
        UniqueConstraint("user_id", "word_id", "card_type", name="uq_srs_cards_user_word_type"),
    )

    word_id: Mapped[int] = mapped_column(ForeignKey("words.id", ondelete="CASCADE"), index=True)
    card_type: Mapped[str] = mapped_column(String(20), default="hanzi_meaning")
    # hanzi_meaning | audio_hanzi | pinyin_write
    ease_factor: Mapped[float] = mapped_column(Float, default=2.5)
    interval_days: Mapped[int] = mapped_column(Integer, default=0)
    repetitions: Mapped[int] = mapped_column(Integer, default=0)
    lapses: Mapped[int] = mapped_column(Integer, default=0)
    due_date: Mapped[date] = mapped_column(Date, index=True)
    last_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class DailyStat(Base):
    __tablename__ = "daily_stats"
    __table_args__ = (UniqueConstraint("user_id", "stat_date", name="uq_daily_stats_user_date"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    stat_date: Mapped[date] = mapped_column(Date, index=True)
    minutes_studied: Mapped[int] = mapped_column(Integer, default=0)
    pronunciation_count: Mapped[int] = mapped_column(Integer, default=0)
    writing_count: Mapped[int] = mapped_column(Integer, default=0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)
    lessons_completed: Mapped[int] = mapped_column(Integer, default=0)
    avg_score: Mapped[float | None] = mapped_column(Float)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Streak(Base):
    __tablename__ = "streaks"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0)
    last_active_date: Mapped[date | None] = mapped_column(Date)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
