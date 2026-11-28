import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.config import settings


class ConversationCreate(BaseModel):
    lesson_id: int = Field(description="id bài học vừa học xong")


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, description="Câu trả lời của người học (Hán tự)")
    input_method: Literal["text", "voice"] = "text"

    @field_validator("content")
    @classmethod
    def _limit_length(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Câu trả lời không được để trống")
        if len(v) > settings.AI_MAX_MESSAGE_CHARS:
            raise ValueError(f"Câu trả lời tối đa {settings.AI_MAX_MESSAGE_CHARS} ký tự")
        return v


class GrammarFeedbackOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    original_sentence: str
    corrected_sentence: str | None
    corrected_pinyin: str | None
    components: list[dict] | None
    errors: list[dict] | None
    error_types: list[str] | None
    grammar_point_ids: list[str] | None
    score: int
    overall_comment_vi: str | None


class AiMessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    role: Literal["user", "assistant"]
    content: str
    pinyin: str | None
    translation_vi: str | None
    suggested_replies: list[dict] | None
    input_method: str | None
    created_at: datetime
    grammar_feedback: GrammarFeedbackOut | None = None


class ConversationSummaryOut(BaseModel):
    overall_score: float | None
    turns: int
    correct_sentences: int
    error_counts: dict[str, int]
    top_errors: list[dict]
    grammar_points_to_review: list[str]
    comment_vi: str


class ConversationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    lesson_id: int | None
    provider: str
    model: str
    status: str
    turn_count: int
    max_turns: int
    overall_score: float | None
    summary: ConversationSummaryOut | None
    created_at: datetime
    ended_at: datetime | None
    messages: list[AiMessageOut]
    disclaimer_vi: str = (
        "Phân tích do AI tạo ra và có thể chưa hoàn toàn chính xác. "
        "Hãy đối chiếu với nội dung bài học."
    )


class ConversationListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    lesson_id: int | None
    status: str
    turn_count: int
    max_turns: int
    overall_score: float | None
    created_at: datetime
    ended_at: datetime | None


class AiUsageOut(BaseModel):
    provider: str
    model: str
    available: bool
    messages_used_today: int
    messages_limit: int
    conversations_started_today: int
    conversations_limit: int
