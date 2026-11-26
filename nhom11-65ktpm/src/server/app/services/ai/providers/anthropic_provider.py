"""Trợ lý AI dùng Claude API (Anthropic Python SDK).

- Structured output: `output_format=<Pydantic model>` -> JSON đúng khuôn, SDK tự parse.
- Streaming: `messages.stream(...)`, tách dần trường `reply_hanzi` để app gõ chữ.
- Prompt caching: `cache_control` trên khối ngữ cảnh bài học (system) và trên
  lượt cuối của lịch sử hội thoại -> các lượt sau chỉ trả giá đọc cache.
- Refusal: bật server-side fallback (`fallbacks="default"`) với model hỗ trợ,
  và luôn kiểm tra `stop_reason == "refusal"` trước khi đọc kết quả.
"""

from collections.abc import AsyncIterator
from typing import Any

import anthropic

from app.core.config import settings
from app.services.ai.pricing import Usage
from app.services.ai.prompts import CHAT_INSTRUCTIONS, GRAMMAR_INSTRUCTIONS, grammar_user_prompt
from app.services.ai.providers.base import (
    AIProviderError,
    AIRefusalError,
    ChatMessage,
    GrammarResult,
    ReplyDelta,
    ReplyResult,
    reply_field_streamer,
)
from app.services.ai.schemas import ChatTurn, GrammarAnalysis

FALLBACK_BETA = "server-side-fallback-2026-07-01"
# Model hỗ trợ server-side fallback khi bị từ chối (Haiku không hỗ trợ).
FALLBACK_MODELS = ("claude-opus-5-5", "claude-sonnet-5-5", "claude-fable-5-2")


def _usage(message: Any) -> Usage:
    u = message.usage
    return Usage(
        input_tokens=u.input_tokens or 0,
        output_tokens=u.output_tokens or 0,
        cache_read_tokens=getattr(u, "cache_read_input_tokens", None) or 0,
        cache_write_tokens=getattr(u, "cache_creation_input_tokens", None) or 0,
    )


def _check_stop(message: Any) -> None:
    if message.stop_reason == "refusal":
        raise AIRefusalError()
    if message.stop_reason == "max_tokens":
        raise AIProviderError("Câu trả lời của AI quá dài, vui lòng thử lại.")


def _api_error(exc: anthropic.APIError) -> AIProviderError:
    # Thứ tự cụ thể -> tổng quát để phân biệt lỗi thử lại được và không.
    if isinstance(exc, anthropic.RateLimitError):
        return AIProviderError("Trợ lý AI đang quá tải, vui lòng thử lại sau ít phút.")
    if isinstance(exc, (anthropic.AuthenticationError, anthropic.PermissionDeniedError)):
        return AIProviderError("Máy chủ chưa cấu hình đúng khóa Claude API.", retryable=False)
    if isinstance(exc, anthropic.BadRequestError):
        return AIProviderError("Yêu cầu gửi tới AI không hợp lệ.", retryable=False)
    if isinstance(exc, anthropic.APIStatusError):
        return AIProviderError(f"Dịch vụ AI gặp lỗi ({exc.status_code}), vui lòng thử lại.")
    return AIProviderError("Không kết nối được tới dịch vụ AI, vui lòng thử lại.")


class AnthropicProvider:
    name = "anthropic"

    def __init__(self, client: anthropic.AsyncAnthropic | None = None, model: str | None = None):
        self.model = model or settings.ANTHROPIC_MODEL
        self._client = client or anthropic.AsyncAnthropic(
            api_key=settings.ANTHROPIC_API_KEY or None,
            timeout=settings.AI_REQUEST_TIMEOUT_SECONDS,
            max_retries=2,
        )

    # ------------------------------------------------------------ helpers
    def _system(self, instructions: str, lesson_context: str) -> list[dict]:
        # Khối hướng dẫn chung đứng trước, khối ngữ cảnh bài học có breakpoint cache:
        # mọi lượt trong cùng một bài dùng lại được toàn bộ phần system.
        return [
            {"type": "text", "text": instructions},
            {"type": "text", "text": lesson_context, "cache_control": {"type": "ephemeral"}},
        ]

    def _common_kwargs(self, effort: str) -> dict[str, Any]:
        kwargs: dict[str, Any] = {
            "model": self.model,
            "max_tokens": settings.AI_MAX_OUTPUT_TOKENS,
            "output_config": {"effort": effort},
        }
        if settings.ANTHROPIC_REFUSAL_FALLBACK and self.model in FALLBACK_MODELS:
            kwargs["betas"] = [FALLBACK_BETA]
            kwargs["fallbacks"] = "default"
        return kwargs

    @staticmethod
    def _messages(history: list[ChatMessage]) -> list[dict]:
        messages: list[dict] = [{"role": m.role, "content": m.content} for m in history]
        # Breakpoint cache thứ hai ở lượt cuối: lượt sau đọc lại cả lịch sử từ cache.
        last = messages[-1]
        last["content"] = [
            {"type": "text", "text": last["content"], "cache_control": {"type": "ephemeral"}}
        ]
        return messages

    # ------------------------------------------------------------ API
    async def stream_reply(
        self, *, lesson_context: str, history: list[ChatMessage], cache_key: str
    ) -> AsyncIterator[ReplyDelta | ReplyResult]:
        streamer = reply_field_streamer()
        try:
            async with self._client.beta.messages.stream(
                **self._common_kwargs(settings.AI_CHAT_EFFORT),
                system=self._system(CHAT_INSTRUCTIONS, lesson_context),
                messages=self._messages(history),
                output_format=ChatTurn,
            ) as stream:
                async for chunk in stream.text_stream:
                    piece = streamer.feed(chunk)
                    if piece:
                        yield ReplyDelta(piece)
                final = await stream.get_final_message()
        except anthropic.APIError as exc:
            raise _api_error(exc) from exc

        _check_stop(final)
        turn = final.parsed_output
        if turn is None:
            raise AIProviderError("AI trả về dữ liệu không đúng định dạng, vui lòng thử lại.")
        yield ReplyResult(turn=turn, usage=_usage(final), model=final.model or self.model)

    async def analyze_grammar(
        self, *, lesson_context: str, question: str | None, answer: str, cache_key: str
    ) -> GrammarResult:
        try:
            response = await self._client.beta.messages.parse(
                **self._common_kwargs(settings.AI_GRAMMAR_EFFORT),
                system=self._system(GRAMMAR_INSTRUCTIONS, lesson_context),
                messages=[{"role": "user", "content": grammar_user_prompt(question, answer)}],
                output_format=GrammarAnalysis,
            )
        except anthropic.APIError as exc:
            raise _api_error(exc) from exc

        _check_stop(response)
        analysis = response.parsed_output
        if analysis is None:
            raise AIProviderError("Không phân tích được ngữ pháp, vui lòng thử lại.")
        return GrammarResult(
            analysis=analysis, usage=_usage(response), model=response.model or self.model
        )
