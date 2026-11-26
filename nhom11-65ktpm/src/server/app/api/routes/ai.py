"""API trợ lý ôn bài AI.

`POST /api/ai/conversations/{id}/messages` trả về luồng Server-Sent Events:

    event: user_message   data: {"id": "..."}                    # đã lưu câu của người học
    event: delta          data: {"text": "你好"}                 # từng đoạn Hán tự của AI (gõ chữ)
    event: grammar        data: {GrammarFeedbackOut}             # phân tích ngữ pháp câu người học
    event: grammar_error  data: {"message": "..."}               # (nếu phân tích lỗi, hội thoại vẫn tiếp tục)
    event: message        data: {AiMessageOut}                   # câu AI hoàn chỉnh: pinyin, nghĩa, gợi ý
    event: done           data: {"turn_count", "max_turns", "should_finish", ...}
    event: error          data: {"message", "retryable"}         # lỗi: câu của người học không được tính lượt
"""

import asyncio
import json
import logging
import uuid
from collections.abc import AsyncIterator
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.api.deps import CurrentUser, DbSession, get_owned_or_404
from app.core.config import settings
from app.db.session import get_session_factory
from app.models import AiConversation, AiMessage, User
from app.schemas.ai import (
    AiMessageOut,
    AiUsageOut,
    ConversationCreate,
    ConversationListItem,
    ConversationOut,
    GrammarFeedbackOut,
    MessageCreate,
)
from app.services.ai import service
from app.services.ai.providers import (
    AIProvider,
    AIProviderError,
    GrammarResult,
    ReplyDelta,
    ReplyResult,
    build_provider,
    provider_configured,
)
from app.services.ai.service import AiLimitError

logger = logging.getLogger("chailish.ai")

router = APIRouter(prefix="/ai", tags=["ai-assistant"])

SessionFactory = Annotated[sessionmaker[Session], Depends(get_session_factory)]


def get_ai_provider() -> AIProvider:
    if not provider_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trợ lý AI chưa được cấu hình trên máy chủ.",
        )
    return build_provider(settings.AI_PROVIDER)


Provider = Annotated[AIProvider, Depends(get_ai_provider)]


def _sse(event: str, data: Any) -> str:
    payload = json.dumps(data, ensure_ascii=False, default=str)
    return f"event: {event}\ndata: {payload}\n\n"


def _limit_error(exc: AiLimitError) -> HTTPException:
    return HTTPException(status_code=exc.status_code, detail=exc.message)


def _lesson_context(db: Session, lesson_id: int | None):
    try:
        return service.lesson_context_for(db, lesson_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài học") from exc


# ---------------------------------------------------------------- Bắt đầu phiên
@router.post(
    "/conversations",
    response_model=ConversationOut,
    status_code=status.HTTP_201_CREATED,
    summary="Bắt đầu phiên trò chuyện ôn bài cho một bài học (AI mở đầu hội thoại)",
)
async def start_conversation(
    body: ConversationCreate, user: CurrentUser, db: DbSession, provider: Provider
) -> ConversationOut:
    try:
        service.ensure_can_start(db, user)
    except AiLimitError as exc:
        raise _limit_error(exc) from exc
    ctx = _lesson_context(db, body.lesson_id)

    result: ReplyResult | None = None
    try:
        async for item in provider.stream_reply(
            lesson_context=ctx.render(),
            history=[service.ChatMessage("user", service.START_MARKER)],
            cache_key=f"chailish-lesson-{body.lesson_id}",
        ):
            if isinstance(item, ReplyResult):
                result = item
    except AIProviderError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=exc.message) from exc
    if result is None:
        raise HTTPException(status_code=502, detail="AI không phản hồi, vui lòng thử lại.")

    # Chỉ tạo phiên khi AI đã mở đầu thành công -> lỗi AI không bị tính vào giới hạn.
    conv = service.create_conversation(db, user, body.lesson_id, provider.name, provider.model)
    service.save_assistant_turn(db, conv, result.turn, result.model, result.usage)
    db.commit()
    db.refresh(conv)
    return ConversationOut.model_validate(conv)


# ---------------------------------------------------------------- Gửi câu trả lời (streaming)
@router.post(
    "/conversations/{conversation_id}/messages",
    summary="Gửi câu trả lời, nhận câu AI tiếp theo (streaming SSE) và phân tích ngữ pháp",
    response_class=StreamingResponse,
    responses={200: {"content": {"text/event-stream": {}}}},
)
async def send_message(
    conversation_id: uuid.UUID,
    body: MessageCreate,
    user: CurrentUser,
    db: DbSession,
    provider: Provider,
    session_factory: SessionFactory,
) -> StreamingResponse:
    conv = get_owned_or_404(db, AiConversation, conversation_id, user)
    try:
        service.ensure_conversation_open(conv)
        service.ensure_can_send(db, user)
    except AiLimitError as exc:
        raise _limit_error(exc) from exc
    ctx = _lesson_context(db, conv.lesson_id)

    question = service.last_assistant_question(conv)
    user_msg = service.add_user_message(db, conv, body.content, body.input_method)
    db.commit()

    stream = _stream_turn(
        provider=provider,
        session_factory=session_factory,
        user_id=user.id,
        conversation_id=conv.id,
        user_message_id=user_msg.id,
        lesson_context=ctx.render(),
        history=service.history_for(conv),
        cache_key=service.cache_key_for(conv),
        question=question,
        answer=body.content,
    )
    return StreamingResponse(
        stream,
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


async def _stream_turn(
    *,
    provider: AIProvider,
    session_factory: sessionmaker[Session],
    user_id: uuid.UUID,
    conversation_id: uuid.UUID,
    user_message_id: uuid.UUID,
    lesson_context: str,
    history: list,
    cache_key: str,
    question: str | None,
    answer: str,
) -> AsyncIterator[str]:
    # Phân tích ngữ pháp chạy song song với việc stream câu trả lời của AI.
    grammar_task: asyncio.Task[GrammarResult] = asyncio.create_task(
        provider.analyze_grammar(
            lesson_context=lesson_context, question=question, answer=answer, cache_key=cache_key
        )
    )
    grammar_handled = False
    completed = False

    def persist_grammar() -> list[str]:
        """Lưu kết quả phân tích (nếu có) và trả về các sự kiện SSE tương ứng."""
        try:
            result = grammar_task.result()
        except AIProviderError as exc:
            return [_sse("grammar_error", {"message": exc.message})]
        except Exception:  # noqa: BLE001 - phân tích lỗi không được làm hỏng hội thoại
            logger.exception("Phân tích ngữ pháp thất bại")
            return [_sse("grammar_error", {"message": "Không phân tích được ngữ pháp câu này."})]
        with session_factory() as s:
            conv = s.get(AiConversation, conversation_id)
            msg = s.get(AiMessage, user_message_id)
            feedback = service.save_grammar_feedback(
                s, conv, msg, result.analysis, result.model, result.usage
            )
            s.commit()
            return [_sse("grammar", GrammarFeedbackOut.model_validate(feedback).model_dump())]

    try:
        yield _sse("user_message", {"id": user_message_id})
        reply: ReplyResult | None = None
        try:
            async for item in provider.stream_reply(
                lesson_context=lesson_context, history=history, cache_key=cache_key
            ):
                if isinstance(item, ReplyDelta):
                    yield _sse("delta", {"text": item.text})
                else:
                    reply = item
                if not grammar_handled and grammar_task.done():
                    grammar_handled = True
                    for event in persist_grammar():
                        yield event
            if reply is None:
                raise AIProviderError("AI không phản hồi, vui lòng thử lại.")
        except AIProviderError as exc:
            yield _sse("error", {"message": exc.message, "retryable": exc.retryable})
            return

        if not grammar_handled:
            await asyncio.wait({grammar_task})
            grammar_handled = True
            for event in persist_grammar():
                yield event

        with session_factory() as s:
            conv = s.get(AiConversation, conversation_id)
            assistant = service.save_assistant_turn(s, conv, reply.turn, reply.model, reply.usage)
            conv.turn_count += 1
            s.commit()
            message_payload = AiMessageOut.model_validate(assistant).model_dump()
            user = s.get(User, user_id)
            done_payload = {
                "turn_count": conv.turn_count,
                "max_turns": conv.max_turns,
                "should_finish": conv.turn_count >= conv.max_turns
                or reply.turn.conversation_should_end,
                "messages_used_today": service.messages_used_today(s, user),
                "messages_limit": settings.AI_DAILY_MESSAGE_LIMIT,
            }
        completed = True
        yield _sse("message", message_payload)
        yield _sse("done", done_payload)
    except Exception:
        logger.exception("Lỗi khi stream câu trả lời AI")
        yield _sse("error", {"message": "Đã có lỗi xảy ra, vui lòng thử lại.", "retryable": True})
    finally:
        if not grammar_task.done():
            grammar_task.cancel()
        if not completed:
            # Lượt lỗi / client ngắt kết nối: xóa câu của người học để không tính lượt
            # và để lịch sử gửi AI lần sau luôn xen kẽ user/assistant.
            with session_factory() as s:
                msg = s.get(AiMessage, user_message_id)
                if msg is not None:
                    s.delete(msg)
                    s.commit()


# ---------------------------------------------------------------- Xem lại / tổng kết
@router.get(
    "/conversations",
    response_model=list[ConversationListItem],
    summary="Danh sách phiên trò chuyện AI của tôi",
)
def list_conversations(
    user: CurrentUser, db: DbSession, lesson_id: int | None = None, limit: int = 20
) -> list[AiConversation]:
    query = select(AiConversation).where(AiConversation.user_id == user.id)
    if lesson_id is not None:
        query = query.where(AiConversation.lesson_id == lesson_id)
    query = query.order_by(AiConversation.created_at.desc()).limit(min(max(limit, 1), 100))
    return list(db.scalars(query))


@router.get(
    "/conversations/{conversation_id}",
    response_model=ConversationOut,
    summary="Xem lại phiên trò chuyện và các lỗi ngữ pháp đã được chỉ ra",
)
def get_conversation(conversation_id: uuid.UUID, user: CurrentUser, db: DbSession):
    return get_owned_or_404(db, AiConversation, conversation_id, user)


@router.post(
    "/conversations/{conversation_id}/finish",
    response_model=ConversationOut,
    summary="Kết thúc phiên và tổng kết điểm, lỗi cần lưu ý, điểm ngữ pháp cần ôn",
)
def finish_conversation(conversation_id: uuid.UUID, user: CurrentUser, db: DbSession):
    conv = get_owned_or_404(db, AiConversation, conversation_id, user)
    service.finish_conversation(db, conv)
    db.commit()
    db.refresh(conv)
    return conv


@router.get("/usage", response_model=AiUsageOut, summary="Số lượt dùng AI hôm nay")
def ai_usage(user: CurrentUser, db: DbSession) -> AiUsageOut:
    provider = settings.AI_PROVIDER
    model = settings.ANTHROPIC_MODEL if provider == "anthropic" else settings.OPENAI_MODEL
    return AiUsageOut(
        provider=provider,
        model=model,
        available=provider_configured(),
        messages_used_today=service.messages_used_today(db, user),
        messages_limit=settings.AI_DAILY_MESSAGE_LIMIT,
        conversations_started_today=service.conversations_started_today(db, user),
        conversations_limit=settings.AI_DAILY_CONVERSATION_LIMIT,
    )
