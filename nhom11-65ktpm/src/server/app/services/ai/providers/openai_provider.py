"""Trợ lý AI dùng OpenAI API (openai Python SDK, Chat Completions).

- Structured output: `response_format=<Pydantic model>` (strict JSON schema).
- Streaming: `chat.completions.stream(...)`, tách dần `reply_hanzi` từ các sự kiện
  `content.delta`.
- Prompt caching của OpenAI là tự động theo tiền tố; `prompt_cache_key` theo bài
  học giúp các yêu cầu cùng bài được định tuyến vào cùng bộ đệm.
- Dùng được với dịch vụ tương thích OpenAI qua `OPENAI_BASE_URL`.
"""

from collections.abc import AsyncIterator
from typing import Any

import openai

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


def _usage(completion: Any) -> Usage:
    u = completion.usage
    if u is None:
        return Usage()
    details = getattr(u, "prompt_tokens_details", None)
    cached = (getattr(details, "cached_tokens", None) or 0) if details else 0
    return Usage(
        input_tokens=max((u.prompt_tokens or 0) - cached, 0),
        output_tokens=u.completion_tokens or 0,
        cache_read_tokens=cached,
    )


def _api_error(exc: openai.APIError) -> AIProviderError:
    if isinstance(exc, openai.RateLimitError):
        return AIProviderError("Trợ lý AI đang quá tải, vui lòng thử lại sau ít phút.")
    if isinstance(exc, (openai.AuthenticationError, openai.PermissionDeniedError)):
        return AIProviderError("Máy chủ chưa cấu hình đúng khóa OpenAI API.", retryable=False)
    if isinstance(exc, openai.BadRequestError):
        return AIProviderError("Yêu cầu gửi tới AI không hợp lệ.", retryable=False)
    if isinstance(exc, openai.APIStatusError):
        return AIProviderError(f"Dịch vụ AI gặp lỗi ({exc.status_code}), vui lòng thử lại.")
    return AIProviderError("Không kết nối được tới dịch vụ AI, vui lòng thử lại.")


def _check_choice(completion: Any) -> Any:
    choice = completion.choices[0]
    if getattr(choice.message, "refusal", None):
        raise AIRefusalError()
    if choice.finish_reason == "length":
        raise AIProviderError("Câu trả lời của AI quá dài, vui lòng thử lại.")
    return choice.message.parsed


class OpenAIProvider:
    name = "openai"

    def __init__(self, client: openai.AsyncOpenAI | None = None, model: str | None = None):
        self.model = model or settings.OPENAI_MODEL
        self._client = client or openai.AsyncOpenAI(
            api_key=settings.OPENAI_API_KEY or None,
            base_url=settings.OPENAI_BASE_URL or None,
            timeout=settings.AI_REQUEST_TIMEOUT_SECONDS,
            max_retries=2,
        )

    def _common_kwargs(self, effort: str, cache_key: str) -> dict[str, Any]:
        kwargs: dict[str, Any] = {
            "model": self.model,
            "max_completion_tokens": settings.AI_MAX_OUTPUT_TOKENS,
            "prompt_cache_key": cache_key,
        }
        if settings.OPENAI_REASONING_EFFORT_ENABLED:
            kwargs["reasoning_effort"] = effort
        return kwargs

    @staticmethod
    def _system(instructions: str, lesson_context: str) -> dict:
        return {"role": "system", "content": f"{instructions}\n\n{lesson_context}"}

    async def stream_reply(
        self, *, lesson_context: str, history: list[ChatMessage], cache_key: str
    ) -> AsyncIterator[ReplyDelta | ReplyResult]:
        streamer = reply_field_streamer()
        messages = [self._system(CHAT_INSTRUCTIONS, lesson_context)] + [
            {"role": m.role, "content": m.content} for m in history
        ]
        try:
            async with self._client.chat.completions.stream(
                **self._common_kwargs(settings.AI_CHAT_EFFORT, f"{cache_key}:chat"),
                messages=messages,
                response_format=ChatTurn,
                stream_options={"include_usage": True},
            ) as stream:
                async for event in stream:
                    if event.type == "content.delta":
                        piece = streamer.feed(event.delta)
                        if piece:
                            yield ReplyDelta(piece)
                completion = await stream.get_final_completion()
        except openai.LengthFinishReasonError as exc:
            raise AIProviderError("Câu trả lời của AI quá dài, vui lòng thử lại.") from exc
        except openai.APIError as exc:
            raise _api_error(exc) from exc

        turn = _check_choice(completion)
        if turn is None:
            raise AIProviderError("AI trả về dữ liệu không đúng định dạng, vui lòng thử lại.")
        yield ReplyResult(turn=turn, usage=_usage(completion), model=completion.model or self.model)

    async def analyze_grammar(
        self, *, lesson_context: str, question: str | None, answer: str, cache_key: str
    ) -> GrammarResult:
        try:
            completion = await self._client.chat.completions.parse(
                **self._common_kwargs(settings.AI_GRAMMAR_EFFORT, f"{cache_key}:grammar"),
                messages=[
                    self._system(GRAMMAR_INSTRUCTIONS, lesson_context),
                    {"role": "user", "content": grammar_user_prompt(question, answer)},
                ],
                response_format=GrammarAnalysis,
            )
        except openai.LengthFinishReasonError as exc:
            raise AIProviderError("Không phân tích được ngữ pháp, vui lòng thử lại.") from exc
        except openai.APIError as exc:
            raise _api_error(exc) from exc

        analysis = _check_choice(completion)
        if analysis is None:
            raise AIProviderError("Không phân tích được ngữ pháp, vui lòng thử lại.")
        return GrammarResult(
            analysis=analysis, usage=_usage(completion), model=completion.model or self.model
        )
