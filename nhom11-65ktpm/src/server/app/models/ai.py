"""Trợ lý ôn bài AI: phiên trò chuyện, từng lượt tin nhắn và phân tích ngữ pháp."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, CreatedAtMixin, JSONType, TimestampMixin


class AiConversation(TimestampMixin, Base):
    __tablename__ = "ai_conversations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    lesson_id: Mapped[int | None] = mapped_column(
        ForeignKey("lessons.id", ondelete="SET NULL"), index=True
    )
    # anthropic | openai
    provider: Mapped[str] = mapped_column(
        String(20), default="anthropic", server_default="anthropic"
    )
    model: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(20), default="active")  # active | completed
    max_turns: Mapped[int] = mapped_column(Integer, default=8)
    turn_count: Mapped[int] = mapped_column(Integer, default=0)
    # Tổng kết cuối phiên (điểm, lỗi cần lưu ý, gợi ý ôn tập).
    summary: Mapped[dict | None] = mapped_column(JSONType)
    overall_score: Mapped[float | None] = mapped_column(Float)
    total_input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    total_output_tokens: Mapped[int] = mapped_column(Integer, default=0)
    total_cost_usd: Mapped[float] = mapped_column(Numeric(10, 6), default=0)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    messages: Mapped[list["AiMessage"]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="AiMessage.created_at",
    )


class AiMessage(CreatedAtMixin, Base):
    __tablename__ = "ai_messages"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("ai_conversations.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(16))  # user | assistant
    content: Mapped[str] = mapped_column(Text)  # Hán tự
    pinyin: Mapped[str | None] = mapped_column(Text)
    translation_vi: Mapped[str | None] = mapped_column(Text)
    # Câu trả lời mẫu AI gợi ý cho lượt tiếp theo của người học.
    suggested_replies: Mapped[list | None] = mapped_column(JSONType)
    input_method: Mapped[str | None] = mapped_column(String(10))  # text | voice
    input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    output_tokens: Mapped[int] = mapped_column(Integer, default=0)
    cache_read_tokens: Mapped[int] = mapped_column(Integer, default=0)
    cache_write_tokens: Mapped[int] = mapped_column(Integer, default=0)

    conversation: Mapped[AiConversation] = relationship(back_populates="messages")
    grammar_feedback: Mapped["GrammarFeedback | None"] = relationship(
        back_populates="message", cascade="all, delete-orphan", uselist=False
    )


class GrammarFeedback(CreatedAtMixin, Base):
    """Kết quả phân tích ngữ pháp một câu trả lời của người học."""

    __tablename__ = "grammar_feedback"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("ai_messages.id", ondelete="CASCADE"), unique=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    original_sentence: Mapped[str] = mapped_column(Text)
    corrected_sentence: Mapped[str | None] = mapped_column(Text)
    corrected_pinyin: Mapped[str | None] = mapped_column(Text)
    # [{"text":"我","role":"subject","pinyin":"wǒ"}, ...]
    components: Mapped[list | None] = mapped_column(JSONType)
    # [{"span","correction","errorType","explanationVi","grammarPointId"}]
    errors: Mapped[list | None] = mapped_column(JSONType)
    error_types: Mapped[list | None] = mapped_column(JSONType)  # để thống kê lỗi hay gặp
    grammar_point_ids: Mapped[list | None] = mapped_column(JSONType)
    score: Mapped[int] = mapped_column(Integer)  # 0..100
    overall_comment_vi: Mapped[str | None] = mapped_column(Text)

    message: Mapped[AiMessage] = relationship(back_populates="grammar_feedback")
