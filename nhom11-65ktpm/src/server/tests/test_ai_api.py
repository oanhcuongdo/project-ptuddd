"""Kiểm thử API trợ lý AI với provider giả (không gọi Claude/OpenAI thật)."""

import json

import pytest

from app.api.routes.ai import get_ai_provider
from app.core.config import settings
from app.main import app
from app.models import AiConversation, AiMessage, Course, GrammarFeedback, Lesson, Word
from app.services.ai.pricing import Usage
from app.services.ai.providers import AIProviderError, GrammarResult, ReplyDelta, ReplyResult
from app.services.ai.schemas import ChatTurn, GrammarAnalysis


def make_turn(hanzi="你好！你是学生吗？", should_end=False) -> ChatTurn:
    return ChatTurn(
        reply_hanzi=hanzi,
        reply_pinyin="nǐ hǎo! nǐ shì xuésheng ma?",
        reply_translation_vi="Xin chào! Bạn là học sinh à?",
        suggested_replies=[
            {"hanzi": "我是学生。", "pinyin": "wǒ shì xuésheng.", "translation_vi": "Tôi là học sinh."}
        ],
        conversation_should_end=should_end,
    )


def make_analysis(answer: str, with_error: bool) -> GrammarAnalysis:
    errors = (
        [
            {
                "span": "我学生",
                "correction": "我是学生",
                "error_type": "verb_usage",
                "explanation_vi": "Thiếu động từ 是 giữa chủ ngữ và danh từ.",
                "grammar_point_id": "gp-shi",
            }
        ]
        if with_error
        else []
    )
    return GrammarAnalysis(
        is_correct=not with_error,
        corrected_sentence="我是学生。",
        corrected_pinyin="wǒ shì xuésheng.",
        components=[
            {"text": "我", "pinyin": "wǒ", "role": "subject", "label_vi": "Chủ ngữ"},
            {"text": "是", "pinyin": "shì", "role": "predicate", "label_vi": "Vị ngữ"},
            {"text": "学生", "pinyin": "xuésheng", "role": "object", "label_vi": "Tân ngữ"},
        ],
        errors=errors,
        score=70 if with_error else 100,
        overall_comment_vi="Cố gắng tốt!",
        grammar_point_ids=["gp-shi"],
    )


class FakeProvider:
    name = "anthropic"
    model = "claude-opus-5-5"

    def __init__(self):
        self.reply_histories: list[list] = []
        self.grammar_calls: list[dict] = []
        self.fail_reply = False
        self.fail_grammar = False
        self.end_conversation = False

    async def stream_reply(self, *, lesson_context, history, cache_key):
        self.reply_histories.append([(m.role, m.content) for m in history])
        self.lesson_context = lesson_context
        turn = make_turn(should_end=self.end_conversation)
        for ch in turn.reply_hanzi[:3]:
            yield ReplyDelta(ch)
        if self.fail_reply:
            raise AIProviderError("AI lỗi giả lập")
        yield ReplyDelta(turn.reply_hanzi[3:])
        yield ReplyResult(turn=turn, usage=Usage(100, 50, 2000, 0), model=self.model)

    async def analyze_grammar(self, *, lesson_context, question, answer, cache_key):
        self.grammar_calls.append({"question": question, "answer": answer})
        if self.fail_grammar:
            raise AIProviderError("Phân tích lỗi giả lập")
        return GrammarResult(
            analysis=make_analysis(answer, with_error=answer.startswith("我学生")),
            usage=Usage(80, 120, 1500, 0),
            model=self.model,
        )


@pytest.fixture()
def fake_provider():
    provider = FakeProvider()
    app.dependency_overrides[get_ai_provider] = lambda: provider
    yield provider
    app.dependency_overrides.pop(get_ai_provider, None)


@pytest.fixture()
def lessons(db_session):
    course = Course(code="HSK1", title="HSK 1")
    l1 = Lesson(
        code="hsk1-01", title="Chào hỏi", order_index=1, course=course,
        grammar_points=[{"id": "gp-shi", "pattern": "A 是 B", "explanationVi": "A là B"}],
        ai_scenario={"aiRole": "bạn cùng lớp", "situation": "Gặp nhau ở trường"},
    )  # fmt: skip
    l1.words = [Word(code="ni-hao", hanzi="你好", pinyin="nǐ hǎo", meaning_vi="xin chào")]
    l2 = Lesson(code="hsk1-02", title="Gia đình", order_index=2, course=course)
    l2.words = [Word(code="ba-ba", hanzi="爸爸", pinyin="bàba", meaning_vi="bố")]
    db_session.add(course)
    db_session.commit()
    return l1, l2


def parse_sse(text: str) -> list[tuple[str, dict]]:
    events = []
    for block in text.strip().split("\n\n"):
        lines = dict(line.split(": ", 1) for line in block.splitlines())
        events.append((lines["event"], json.loads(lines["data"])))
    return events


def start(client, headers, lesson_id):
    res = client.post("/api/ai/conversations", json={"lesson_id": lesson_id}, headers=headers)
    assert res.status_code == 201, res.text
    return res.json()


def send(client, headers, conv_id, content="我是学生。"):
    res = client.post(
        f"/api/ai/conversations/{conv_id}/messages",
        json={"content": content, "input_method": "text"},
        headers=headers,
    )
    return res


# ---------------------------------------------------------------- Bắt đầu phiên
def test_start_conversation_ai_opens(client, auth_headers, fake_provider, lessons):
    data = start(client, auth_headers, lessons[1].id)
    assert data["status"] == "active" and data["turn_count"] == 0
    assert data["provider"] == "anthropic" and data["model"] == "claude-opus-5-5"
    assert data["max_turns"] == settings.AI_MAX_TURNS
    [opening] = data["messages"]
    assert opening["role"] == "assistant"
    assert opening["content"] == "你好！你是学生吗？"
    assert opening["pinyin"] and opening["translation_vi"]
    assert opening["suggested_replies"][0]["hanzi"] == "我是学生。"
    assert "chưa hoàn toàn chính xác" in data["disclaimer_vi"]

    # Ngữ cảnh gồm từ vựng bài hiện tại + bài trước, kịch bản, điểm ngữ pháp.
    ctx = fake_provider.lesson_context
    assert "爸爸" in ctx and "你好" in ctx and "gp-shi" in ctx
    assert fake_provider.reply_histories[0] == [("user", "[BẮT ĐẦU]")]


def test_start_conversation_unknown_lesson(client, auth_headers, fake_provider):
    res = client.post("/api/ai/conversations", json={"lesson_id": 999}, headers=auth_headers)
    assert res.status_code == 404


def test_ai_requires_auth_and_configured_provider(client, auth_headers, lessons, monkeypatch):
    assert client.post("/api/ai/conversations", json={"lesson_id": 1}).status_code == 401
    monkeypatch.setattr(settings, "ANTHROPIC_API_KEY", "")
    monkeypatch.setattr(settings, "AI_PROVIDER", "anthropic")
    res = client.post("/api/ai/conversations", json={"lesson_id": lessons[0].id}, headers=auth_headers)
    assert res.status_code == 503


def test_start_failure_does_not_create_conversation(client, auth_headers, fake_provider, lessons, db_session):
    fake_provider.fail_reply = True
    res = client.post("/api/ai/conversations", json={"lesson_id": lessons[0].id}, headers=auth_headers)
    assert res.status_code == 502
    assert db_session.query(AiConversation).count() == 0


# ---------------------------------------------------------------- Gửi câu trả lời (SSE)
def test_send_message_streams_reply_and_grammar(client, auth_headers, fake_provider, lessons, db_session):
    conv = start(client, auth_headers, lessons[0].id)
    res = send(client, auth_headers, conv["id"], "我学生。")
    assert res.status_code == 200
    assert res.headers["content-type"].startswith("text/event-stream")
    events = parse_sse(res.text)
    names = [e for e, _ in events]

    assert names[0] == "user_message"
    assert names[-2:] == ["message", "done"]
    assert "grammar" in names
    streamed = "".join(d["text"] for e, d in events if e == "delta")
    assert streamed == "你好！你是学生吗？"

    grammar = next(d for e, d in events if e == "grammar")
    assert grammar["original_sentence"] == "我学生。"
    assert grammar["corrected_sentence"] == "我是学生。"
    assert grammar["score"] == 70 and grammar["error_types"] == ["verb_usage"]
    assert grammar["components"][0]["role"] == "subject"

    done = dict(events)["done"]
    assert done["turn_count"] == 1 and done["should_finish"] is False
    assert done["messages_used_today"] == 1

    # Lịch sử gửi AI xen kẽ đúng thứ tự; câu hỏi gần nhất được dùng để phân tích.
    assert fake_provider.reply_histories[-1] == [
        ("user", "[BẮT ĐẦU]"),
        ("assistant", "你好！你是学生吗？"),
        ("user", "我学生。"),
    ]
    assert fake_provider.grammar_calls[-1] == {"question": "你好！你是学生吗？", "answer": "我学生。"}

    # Dữ liệu đã lưu: tin nhắn, phân tích, token & chi phí.
    db_session.expire_all()
    saved = db_session.get(AiConversation, __import__("uuid").UUID(conv["id"]))
    assert [m.role for m in saved.messages] == ["assistant", "user", "assistant"]
    assert saved.messages[1].grammar_feedback.score == 70
    assert saved.total_output_tokens == 50 * 2 + 120
    assert float(saved.total_cost_usd) > 0


def test_get_conversation_includes_grammar(client, auth_headers, fake_provider, lessons):
    conv = start(client, auth_headers, lessons[0].id)
    send(client, auth_headers, conv["id"], "我学生。")
    data = client.get(f"/api/ai/conversations/{conv['id']}", headers=auth_headers).json()
    user_msg = data["messages"][1]
    assert user_msg["role"] == "user"
    assert user_msg["grammar_feedback"]["errors"][0]["correction"] == "我是学生"


def test_reply_failure_rolls_back_user_message(client, auth_headers, fake_provider, lessons, db_session):
    conv = start(client, auth_headers, lessons[0].id)
    fake_provider.fail_reply = True
    events = parse_sse(send(client, auth_headers, conv["id"]).text)
    assert events[-1][0] == "error"
    assert events[-1][1]["message"] == "AI lỗi giả lập"

    db_session.expire_all()
    assert db_session.query(AiMessage).filter_by(role="user").count() == 0
    assert db_session.query(GrammarFeedback).count() == 0
    assert db_session.query(AiConversation).one().turn_count == 0


def test_grammar_failure_keeps_conversation_going(client, auth_headers, fake_provider, lessons):
    conv = start(client, auth_headers, lessons[0].id)
    fake_provider.fail_grammar = True
    events = parse_sse(send(client, auth_headers, conv["id"]).text)
    names = [e for e, _ in events]
    assert "grammar_error" in names and "grammar" not in names
    assert names[-1] == "done"


def test_message_validation(client, auth_headers, fake_provider, lessons):
    conv = start(client, auth_headers, lessons[0].id)
    too_long = "我" * (settings.AI_MAX_MESSAGE_CHARS + 1)
    assert send(client, auth_headers, conv["id"], too_long).status_code == 422
    assert send(client, auth_headers, conv["id"], "   ").status_code == 422


def test_cannot_access_other_users_conversation(client, register_user, fake_provider, lessons):
    a = {"Authorization": f"Bearer {register_user(email='a@x.vn')['access_token']}"}
    b = {"Authorization": f"Bearer {register_user(email='b@x.vn')['access_token']}"}
    conv = start(client, a, lessons[0].id)
    assert client.get(f"/api/ai/conversations/{conv['id']}", headers=b).status_code == 404
    assert send(client, b, conv["id"]).status_code == 404
    assert client.get("/api/ai/conversations", headers=b).json() == []


# ---------------------------------------------------------------- Giới hạn
def test_max_turns_then_finish_summary(client, auth_headers, fake_provider, lessons, monkeypatch):
    monkeypatch.setattr(settings, "AI_MAX_TURNS", 2)
    conv = start(client, auth_headers, lessons[0].id)
    send(client, auth_headers, conv["id"], "我学生。")
    done = dict(parse_sse(send(client, auth_headers, conv["id"], "我是学生。").text))["done"]
    assert done["turn_count"] == 2 and done["should_finish"] is True

    assert send(client, auth_headers, conv["id"]).status_code == 409

    res = client.post(f"/api/ai/conversations/{conv['id']}/finish", headers=auth_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "completed" and data["ended_at"]
    summary = data["summary"]
    assert summary["overall_score"] == 85.0
    assert summary["turns"] == 2 and summary["correct_sentences"] == 1
    assert summary["error_counts"] == {"Dùng sai động từ": 1}
    assert summary["grammar_points_to_review"] == ["gp-shi"]
    assert summary["top_errors"][0]["label_vi"] == "Dùng sai động từ"

    # Phiên đã kết thúc thì không gửi thêm được.
    assert send(client, auth_headers, conv["id"]).status_code == 409

    # Kết thúc phiên ghi một sự kiện học tập (gọi finish lần nữa không ghi trùng).
    client.post(f"/api/ai/conversations/{conv['id']}/finish", headers=auth_headers)
    events = client.get("/api/events", params={"type": "ai_session_finished"}, headers=auth_headers).json()
    assert len(events) == 1
    assert events[0]["ref_id"] == conv["id"] and events[0]["xp"] == 10 and events[0]["score"] == 85.0


def test_daily_message_limit(client, auth_headers, fake_provider, lessons, monkeypatch):
    monkeypatch.setattr(settings, "AI_DAILY_MESSAGE_LIMIT", 1)
    conv = start(client, auth_headers, lessons[0].id)
    assert send(client, auth_headers, conv["id"]).status_code == 200
    res = send(client, auth_headers, conv["id"])
    assert res.status_code == 429
    assert "hết" in res.json()["detail"]

    usage = client.get("/api/ai/usage", headers=auth_headers).json()
    assert usage["messages_used_today"] == 1 and usage["messages_limit"] == 1


def test_daily_conversation_limit(client, auth_headers, fake_provider, lessons, monkeypatch):
    monkeypatch.setattr(settings, "AI_DAILY_CONVERSATION_LIMIT", 1)
    start(client, auth_headers, lessons[0].id)
    res = client.post("/api/ai/conversations", json={"lesson_id": lessons[0].id}, headers=auth_headers)
    assert res.status_code == 429
