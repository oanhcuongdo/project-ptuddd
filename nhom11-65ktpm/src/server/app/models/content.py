"""Nội dung giáo trình: khóa học HSK, bài học, từ vựng, dữ liệu chữ Hán.

Nội dung được nạp bằng script từ file JSON (`nhom11-65ktpm/data/lessons`),
mỗi lần cập nhật sẽ tăng `content_version` để app chỉ tải phần thay đổi
(`GET /api/lessons?since_version=`).
"""

from sqlalchemy import ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, JSONType, TimestampMixin


class Course(TimestampMixin, Base):
    __tablename__ = "courses"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(32), unique=True)  # "HSK1", "HSK2", "PINYIN"
    title: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(Text)
    order_index: Mapped[int] = mapped_column(Integer, default=0)

    lessons: Mapped[list["Lesson"]] = relationship(
        back_populates="course", order_by="Lesson.order_index"
    )


class Lesson(TimestampMixin, Base):
    __tablename__ = "lessons"

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id", ondelete="CASCADE"), index=True)
    # Mã ổn định từ file dữ liệu, ví dụ "hsk1-greetings-01".
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    order_index: Mapped[int] = mapped_column(Integer, default=0)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text)
    topic: Mapped[str | None] = mapped_column(String(100))  # chào hỏi, gia đình, mua sắm...
    # Danh sách điểm ngữ pháp: [{"id","pattern","explanationVi","examples":[...]}]
    grammar_points: Mapped[list | None] = mapped_column(JSONType)
    # Kịch bản đóng vai cho trợ lý AI: {"aiRole","learnerRole","situation","openingLine"}
    ai_scenario: Mapped[dict | None] = mapped_column(JSONType)
    schema_version: Mapped[int] = mapped_column(Integer, default=1)
    content_version: Mapped[int] = mapped_column(Integer, default=1, index=True)

    course: Mapped[Course] = relationship(back_populates="lessons")
    words: Mapped[list["Word"]] = relationship(
        back_populates="lesson", order_by="Word.order_index", cascade="all, delete-orphan"
    )


class Word(TimestampMixin, Base):
    __tablename__ = "words"
    __table_args__ = (UniqueConstraint("lesson_id", "code", name="uq_words_lesson_code"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    lesson_id: Mapped[int] = mapped_column(ForeignKey("lessons.id", ondelete="CASCADE"), index=True)
    code: Mapped[str] = mapped_column(String(64))  # "ni-hao"
    order_index: Mapped[int] = mapped_column(Integer, default=0)
    hanzi: Mapped[str] = mapped_column(String(32), index=True)
    pinyin: Mapped[str] = mapped_column(String(100))
    han_viet: Mapped[str | None] = mapped_column(String(100))
    meaning_vi: Mapped[str] = mapped_column(String(255))
    part_of_speech: Mapped[str | None] = mapped_column(String(32))
    hsk_level: Mapped[int | None] = mapped_column(Integer)
    # {"hanzi","pinyin","meaningVi"}
    example: Mapped[dict | None] = mapped_column(JSONType)
    audio_url: Mapped[str | None] = mapped_column(String(500))
    content_version: Mapped[int] = mapped_column(Integer, default=1)

    lesson: Mapped[Lesson] = relationship(back_populates="words")


class Character(TimestampMixin, Base):
    """Dữ liệu một chữ Hán (nguồn Make Me a Hanzi)."""

    __tablename__ = "characters"

    id: Mapped[int] = mapped_column(primary_key=True)
    hanzi: Mapped[str] = mapped_column(String(4), unique=True, index=True)
    pinyin: Mapped[str | None] = mapped_column(String(64))
    han_viet: Mapped[str | None] = mapped_column(String(64))
    meaning_vi: Mapped[str | None] = mapped_column(String(255))
    radical: Mapped[str | None] = mapped_column(String(8))
    stroke_count: Mapped[int] = mapped_column(Integer, default=0)
    # SVG path của từng nét (hiển thị) và đường trung tâm (kiểm tra nét viết).
    strokes: Mapped[list | None] = mapped_column(JSONType)
    medians: Mapped[list | None] = mapped_column(JSONType)
    decomposition: Mapped[str | None] = mapped_column(String(64))
    content_version: Mapped[int] = mapped_column(Integer, default=1)
