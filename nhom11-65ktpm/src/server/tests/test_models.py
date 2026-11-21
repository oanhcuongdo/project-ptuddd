"""Kiểm tra schema ORM: đủ bảng theo đặc tả và quan hệ hoạt động đúng."""

import uuid
from datetime import date

from app.models import (
    AiConversation,
    AiMessage,
    Base,
    Course,
    GrammarFeedback,
    Lesson,
    SrsCard,
    User,
    Word,
)

EXPECTED_TABLES = {
    "users", "refresh_tokens",
    "courses", "lessons", "words", "characters",
    "attempts", "pronunciation_requests", "syllable_results",
    "writing_attempts", "srs_cards", "daily_stats", "streaks",
    "path_stages", "path_nodes", "user_path_progress",
    "ai_conversations", "ai_messages", "grammar_feedback",
}  # fmt: skip


def test_all_spec_tables_are_defined():
    assert EXPECTED_TABLES <= set(Base.metadata.tables)


def _make_user(db) -> User:
    user = User(email="hoc@chailish.vn", password_hash="x", full_name="Người Học")
    db.add(user)
    db.flush()
    return user


def test_lesson_content_relationships(db_session):
    course = Course(code="HSK1", title="HSK 1")
    lesson = Lesson(code="hsk1-greetings-01", title="Chào hỏi cơ bản", course=course)
    lesson.words.append(Word(code="ni-hao", hanzi="你好", pinyin="nǐ hǎo", meaning_vi="xin chào"))
    db_session.add(course)
    db_session.commit()

    loaded = db_session.query(Lesson).filter_by(code="hsk1-greetings-01").one()
    assert loaded.course.code == "HSK1"
    assert [w.hanzi for w in loaded.words] == ["你好"]
    assert loaded.content_version == 1


def test_user_defaults_and_srs_card(db_session):
    user = _make_user(db_session)
    course = Course(code="HSK1", title="HSK 1")
    word = Word(code="wo", hanzi="我", pinyin="wǒ", meaning_vi="tôi")
    Lesson(code="l1", title="L1", course=course, words=[word])
    db_session.add(course)
    db_session.flush()

    card_id = uuid.uuid4()  # id do app sinh khi offline
    db_session.add(SrsCard(id=card_id, user_id=user.id, word_id=word.id, due_date=date.today()))
    db_session.commit()

    assert user.status == "active"
    assert user.daily_goal_minutes == 15
    card = db_session.get(SrsCard, card_id)
    assert card.ease_factor == 2.5 and card.repetitions == 0


def test_ai_conversation_with_grammar_feedback(db_session):
    user = _make_user(db_session)
    conv = AiConversation(user_id=user.id, model="claude-haiku-5-5")
    msg = AiMessage(role="user", content="我是学生。", input_method="text")
    msg.grammar_feedback = GrammarFeedback(
        user_id=user.id,
        original_sentence="我是学生。",
        components=[{"text": "我", "role": "subject"}],
        errors=[],
        score=100,
    )
    conv.messages.append(msg)
    db_session.add(conv)
    db_session.commit()

    db_session.expire_all()
    loaded = db_session.get(AiConversation, conv.id)
    assert loaded.messages[0].grammar_feedback.score == 100
    assert loaded.messages[0].grammar_feedback.components[0]["role"] == "subject"

    # Xóa người dùng -> dữ liệu AI bị xóa theo (ON DELETE CASCADE).
    db_session.delete(db_session.get(User, user.id))
    db_session.commit()
    assert db_session.query(AiConversation).count() == 0
