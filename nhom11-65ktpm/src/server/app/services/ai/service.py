"""Nghiệp vụ trợ lý ôn bài: giới hạn lượt dùng, lịch sử hội thoại, lưu kết quả, tổng kết."""

from collections import Counter
from datetime import UTC, datetime, time
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import AiConversation, AiMessage, GrammarFeedback, Lesson, User
from app.services.ai.pricing import Usage, estimate_cost_usd
from app.services.ai.prompts import START_MARKER, LessonContext, build_lesson_context
from app.services.ai.providers import ChatMessage
from app.services.ai.schemas import ChatTurn, GrammarAnalysis

ERROR_TYPE_LABELS_VI = {
    "word_order": "Sai trật tự từ",
    "measure_word": "Sai / thiếu lượng từ",
    "missing_le": "Thiếu 了",
    "bu_mei_confusion": "Nhầm 不 / 没",
    "missing_particle": "Thiếu trợ từ",
    "wrong_word": "Dùng sai từ",
    "verb_usage": "Dùng sai động từ",
    "adverb_usage": "Dùng sai phó từ",
    "missing_component": "Thiếu thành phần câu",
    "redundant_word": "Thừa từ",
    "other": "Lỗi khác",
}


class AiLimitError(Exception):
    def __init__(self, message: str, status_code: int = 429) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


# ---------------------------------------------------------------- Giới hạn mỗi ngày
def _start_of_today_utc() -> datetime:
    tz = ZoneInfo(settings.AI_LIMIT_TIMEZONE)
    local_midnight = datetime.combine(datetime.now(tz).date(), time.min, tzinfo=tz)
    return local_midnight.astimezone(UTC)


def messages_used_today(db: Session, user: User) -> int:
    return db.scalar(
        select(func.count(AiMessage.id))
        .join(AiConversation, AiMessage.conversation_id == AiConversation.id)
        .where(
            AiConversation.user_id == user.id,
            AiMessage.role == "user",
            AiMessage.created_at >= _start_of_today_utc(),
        )
    ) or 0


def conversations_started_today(db: Session, user: User) -> int:
    return db.scalar(
        select(func.count(AiConversation.id)).where(
            AiConversation.user_id == user.id,
            AiConversation.created_at >= _start_of_today_utc(),
        )
    ) or 0


def ensure_can_start(db: Session, user: User) -> None:
    if conversations_started_today(db, user) >= settings.AI_DAILY_CONVERSATION_LIMIT:
        raise AiLimitError(
            f"Bạn đã dùng hết {settings.AI_DAILY_CONVERSATION_LIMIT} phiên trò chuyện AI hôm nay. "
            "Hãy quay lại vào ngày mai nhé!"
        )
    ensure_can_send(db, user)


def ensure_can_send(db: Session, user: User) -> None:
    if messages_used_today(db, user) >= settings.AI_DAILY_MESSAGE_LIMIT:
        raise AiLimitError(
            f"Bạn đã dùng hết {settings.AI_DAILY_MESSAGE_LIMIT} lượt trả lời AI hôm nay. "
            "Hãy quay lại vào ngày mai nhé!"
        )


def ensure_conversation_open(conv: AiConversation) -> None:
    if conv.status != "active":
        raise AiLimitError("Phiên trò chuyện đã kết thúc.", status_code=409)
    if conv.turn_count >= conv.max_turns:
        raise AiLimitError(
            "Phiên trò chuyện đã đủ số lượt, hãy xem tổng kết.", status_code=409
        )


# ---------------------------------------------------------------- Ngữ cảnh & lịch sử
def lesson_context_for(db: Session, lesson_id: int | None) -> LessonContext:
    lesson = db.get(Lesson, lesson_id) if lesson_id is not None else None
    if lesson is None:
        raise LookupError("Không tìm thấy bài học")
    return build_lesson_context(db, lesson)


def cache_key_for(conv: AiConversation) -> str:
    return f"chailish-lesson-{conv.lesson_id}"


def history_for(conv: AiConversation) -> list[ChatMessage]:
    """Lịch sử gửi cho model: luôn bắt đầu bằng lượt user [BẮT ĐẦU]."""
    history = [ChatMessage("user", START_MARKER)]
    for m in conv.messages:
        history.append(ChatMessage("assistant" if m.role == "assistant" else "user", m.content))
    return history


def last_assistant_question(conv: AiConversation) -> str | None:
    for m in reversed(conv.messages):
        if m.role == "assistant":
            return m.content
    return None


# ---------------------------------------------------------------- Ghi kết quả
def create_conversation(db: Session, user: User, lesson_id: int, provider: str, model: str):
    conv = AiConversation(
        user_id=user.id,
        lesson_id=lesson_id,
        provider=provider,
        model=model,
        max_turns=settings.AI_MAX_TURNS,
    )
    db.add(conv)
    db.flush()
    return conv


def add_usage(conv: AiConversation, model: str, usage: Usage) -> None:
    conv.total_input_tokens = (conv.total_input_tokens or 0) + usage.input_tokens + (
        usage.cache_read_tokens + usage.cache_write_tokens
    )
    conv.total_output_tokens = (conv.total_output_tokens or 0) + usage.output_tokens
    conv.total_cost_usd = float(conv.total_cost_usd or 0) + estimate_cost_usd(model, usage)


def _set_usage(message: AiMessage, usage: Usage) -> None:
    message.input_tokens = usage.input_tokens
    message.output_tokens = usage.output_tokens
    message.cache_read_tokens = usage.cache_read_tokens
    message.cache_write_tokens = usage.cache_write_tokens


def save_assistant_turn(
    db: Session, conv: AiConversation, turn: ChatTurn, model: str, usage: Usage
) -> AiMessage:
    message = AiMessage(
        conversation_id=conv.id,
        role="assistant",
        # Gán thời điểm bằng Python (không dùng now() của transaction) để thứ tự
        # tin nhắn luôn đúng kể cả khi nhiều tin được ghi trong cùng transaction.
        created_at=datetime.now(UTC),
        content=turn.reply_hanzi.strip(),
        pinyin=turn.reply_pinyin.strip(),
        translation_vi=turn.reply_translation_vi.strip(),
        suggested_replies=[s.model_dump() for s in turn.suggested_replies][:3],
    )
    _set_usage(message, usage)
    db.add(message)
    conv.messages.append(message)
    add_usage(conv, model, usage)
    db.flush()
    return message


def add_user_message(db: Session, conv: AiConversation, content: str, input_method: str):
    message = AiMessage(
        conversation_id=conv.id,
        role="user",
        created_at=datetime.now(UTC),
        content=content,
        input_method=input_method,
    )
    db.add(message)
    conv.messages.append(message)
    db.flush()
    return message


def save_grammar_feedback(
    db: Session,
    conv: AiConversation,
    user_message: AiMessage,
    analysis: GrammarAnalysis,
    model: str,
    usage: Usage,
) -> GrammarFeedback:
    errors = [e.model_dump() for e in analysis.errors]
    feedback = GrammarFeedback(
        message_id=user_message.id,
        user_id=conv.user_id,
        original_sentence=user_message.content,
        corrected_sentence=analysis.corrected_sentence.strip(),
        corrected_pinyin=analysis.corrected_pinyin.strip(),
        components=[c.model_dump() for c in analysis.components],
        errors=errors,
        error_types=sorted({e["error_type"] for e in errors}),
        grammar_point_ids=sorted(set(analysis.grammar_point_ids)),
        score=max(0, min(100, int(analysis.score))),
        overall_comment_vi=analysis.overall_comment_vi.strip(),
    )
    db.add(feedback)
    user_message.grammar_feedback = feedback
    _set_usage(user_message, usage)
    add_usage(conv, model, usage)
    db.flush()
    return feedback


# ---------------------------------------------------------------- Tổng kết phiên
def build_summary(conv: AiConversation) -> dict:
    feedbacks = [
        m.grammar_feedback for m in conv.messages if m.role == "user" and m.grammar_feedback
    ]
    turns = sum(1 for m in conv.messages if m.role == "user")
    scores = [f.score for f in feedbacks]
    overall = round(sum(scores) / len(scores), 1) if scores else None
    correct = sum(1 for f in feedbacks if not f.errors)

    counter: Counter[str] = Counter()
    top_errors: list[dict] = []
    review_points: list[str] = []
    for f in feedbacks:
        for e in f.errors or []:
            counter[e.get("error_type", "other")] += 1
            if len(top_errors) < 5:
                top_errors.append(
                    {
                        "sentence": f.original_sentence,
                        "span": e.get("span"),
                        "correction": e.get("correction"),
                        "error_type": e.get("error_type"),
                        "label_vi": ERROR_TYPE_LABELS_VI.get(e.get("error_type", "other")),
                        "explanation_vi": e.get("explanation_vi"),
                    }
                )
            gp = e.get("grammar_point_id")
            if gp and gp not in review_points:
                review_points.append(gp)

    if overall is None:
        comment = "Bạn chưa trả lời câu nào trong phiên này. Hãy thử lại nhé!"
    elif overall >= 85:
        comment = "Xuất sắc! Bạn dùng câu rất chuẩn, hãy thử trả lời dài hơn ở phiên sau."
    elif overall >= 70:
        comment = "Làm tốt lắm! Xem lại vài lỗi bên dưới để câu nói tự nhiên hơn."
    else:
        comment = "Cố lên! Hãy ôn lại các điểm ngữ pháp được gợi ý rồi luyện thêm một phiên nữa."

    return {
        "overall_score": overall,
        "turns": turns,
        "correct_sentences": correct,
        "error_counts": {ERROR_TYPE_LABELS_VI.get(k, k): v for k, v in counter.most_common()},
        "top_errors": top_errors,
        "grammar_points_to_review": review_points,
        "comment_vi": comment,
    }


def finish_conversation(db: Session, conv: AiConversation) -> AiConversation:
    if conv.status != "completed":
        summary = build_summary(conv)
        conv.summary = summary
        conv.overall_score = summary["overall_score"]
        conv.status = "completed"
        conv.ended_at = datetime.now(UTC)
        db.flush()
    return conv


__all__ = [
    "AiLimitError",
    "add_user_message",
    "build_summary",
    "cache_key_for",
    "conversations_started_today",
    "create_conversation",
    "ensure_can_send",
    "ensure_can_start",
    "ensure_conversation_open",
    "finish_conversation",
    "history_for",
    "last_assistant_question",
    "lesson_context_for",
    "messages_used_today",
    "save_assistant_turn",
    "save_grammar_feedback",
]
