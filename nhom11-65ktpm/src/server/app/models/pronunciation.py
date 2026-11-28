"""Lượt luyện phát âm, nhật ký gọi Azure và kết quả từng âm tiết."""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, CreatedAtMixin, JSONType
from app.models._mixins import UserOwnedSyncMixin


class Attempt(UserOwnedSyncMixin, Base):
    __tablename__ = "attempts"

    word_id: Mapped[int | None] = mapped_column(ForeignKey("words.id", ondelete="SET NULL"))
    lesson_id: Mapped[int | None] = mapped_column(ForeignKey("lessons.id", ondelete="SET NULL"))
    reference_text: Mapped[str] = mapped_column(String(255))  # câu/từ mẫu (Hán tự)
    reference_pinyin: Mapped[str | None] = mapped_column(String(255))
    recognized_text: Mapped[str | None] = mapped_column(String(255))
    mode: Mapped[str] = mapped_column(String(10))  # offline | online
    overall_score: Mapped[float] = mapped_column(Float)
    accuracy_score: Mapped[float | None] = mapped_column(Float)
    tone_score: Mapped[float | None] = mapped_column(Float)
    completeness_score: Mapped[float | None] = mapped_column(Float)
    fluency_score: Mapped[float | None] = mapped_column(Float)
    duration_ms: Mapped[int | None] = mapped_column(Integer)

    syllables: Mapped[list["SyllableResult"]] = relationship(
        back_populates="attempt", cascade="all, delete-orphan", order_by="SyllableResult.position"
    )


class SyllableResult(Base):
    __tablename__ = "syllable_results"

    id: Mapped[int] = mapped_column(primary_key=True)
    attempt_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("attempts.id", ondelete="CASCADE"), index=True
    )
    position: Mapped[int] = mapped_column(Integer)
    hanzi: Mapped[str | None] = mapped_column(String(4))
    expected_initial: Mapped[str | None] = mapped_column(String(8))
    expected_final: Mapped[str | None] = mapped_column(String(8))
    expected_tone: Mapped[int | None] = mapped_column(Integer)
    actual_initial: Mapped[str | None] = mapped_column(String(8))
    actual_final: Mapped[str | None] = mapped_column(String(8))
    actual_tone: Mapped[int | None] = mapped_column(Integer)
    initial_correct: Mapped[bool] = mapped_column(Boolean, default=False)
    final_correct: Mapped[bool] = mapped_column(Boolean, default=False)
    tone_correct: Mapped[bool] = mapped_column(Boolean, default=False)
    score: Mapped[float | None] = mapped_column(Float)

    attempt: Mapped[Attempt] = relationship(back_populates="syllables")


class PronunciationRequest(CreatedAtMixin, Base):
    """Nhật ký mỗi lần server gọi dịch vụ chấm online (Azure)."""

    __tablename__ = "pronunciation_requests"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    attempt_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("attempts.id", ondelete="SET NULL")
    )
    provider: Mapped[str] = mapped_column(String(20), default="azure")
    reference_text: Mapped[str] = mapped_column(String(255))
    audio_duration_ms: Mapped[int | None] = mapped_column(Integer)
    processing_ms: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20))  # success | failed | timeout | rejected
    error_message: Mapped[str | None] = mapped_column(Text)
    estimated_cost_usd: Mapped[float | None] = mapped_column(Numeric(10, 6))
    raw_result: Mapped[dict | None] = mapped_column(JSONType)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
