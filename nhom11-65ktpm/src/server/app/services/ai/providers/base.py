"""Giao diện chung cho các nhà cung cấp AI (Claude, OpenAI).

Phần nghiệp vụ (`app.services.ai.service`) chỉ làm việc với `AIProvider`, nên
đổi nhà cung cấp chỉ cần đổi biến môi trường `AI_PROVIDER`.
"""

from collections.abc import AsyncIterator
from dataclasses import dataclass
from typing import Literal, Protocol

from app.services.ai.json_stream import JsonStringFieldStreamer
from app.services.ai.pricing import Usage
from app.services.ai.schemas import ChatTurn, GrammarAnalysis

STREAMED_FIELD = "reply_hanzi"


@dataclass
class ChatMessage:
    role: Literal["user", "assistant"]
    content: str


@dataclass
class ReplyDelta:
    """Một đoạn Hán tự mới của câu trả lời (dùng cho hiệu ứng gõ chữ)."""

    text: str


@dataclass
class ReplyResult:
    turn: ChatTurn
    usage: Usage
    model: str


@dataclass
class GrammarResult:
    analysis: GrammarAnalysis
    usage: Usage
    model: str


class AIProviderError(Exception):
    """Lỗi khi gọi AI (mạng, quá tải, hết hạn mức...). `message` hiển thị được cho người dùng."""

    def __init__(self, message: str, *, retryable: bool = True) -> None:
        super().__init__(message)
        self.message = message
        self.retryable = retryable


class AIRefusalError(AIProviderError):
    def __init__(self) -> None:
        super().__init__(
            "Trợ lý AI không thể trả lời nội dung này. Hãy thử nói về chủ đề bài học nhé.",
            retryable=False,
        )


class AIProvider(Protocol):
    name: str
    model: str

    def stream_reply(
        self, *, lesson_context: str, history: list[ChatMessage], cache_key: str
    ) -> AsyncIterator[ReplyDelta | ReplyResult]:
        """Stream câu trả lời: nhiều `ReplyDelta`, kết thúc bằng đúng một `ReplyResult`."""
        ...

    async def analyze_grammar(
        self, *, lesson_context: str, question: str | None, answer: str, cache_key: str
    ) -> GrammarResult: ...


def reply_field_streamer() -> JsonStringFieldStreamer:
    return JsonStringFieldStreamer(STREAMED_FIELD)
