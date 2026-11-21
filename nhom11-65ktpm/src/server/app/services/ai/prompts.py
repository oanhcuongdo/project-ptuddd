"""Dựng prompt cho trợ lý ôn bài: hướng dẫn vai trò + ngữ cảnh bài học.

Thứ tự prompt được giữ CỐ ĐỊNH (hướng dẫn chung -> ngữ cảnh bài học -> lịch sử
hội thoại) và ngữ cảnh được sinh tất định (sắp xếp ổn định, không chèn thời gian)
để prompt caching của Claude / OpenAI dùng lại được phần đầu giữa các lượt.
"""

from dataclasses import dataclass, field

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Lesson, Word

CHAT_INSTRUCTIONS = """\
You are a friendly Chinese conversation partner inside ChaiLish, an app that teaches \
Mandarin Chinese to Vietnamese beginners (HSK 1-2). After each lesson the learner \
practises with you in a short role-play about the lesson topic.

How to talk:
- Stay in the role and situation described in the lesson context. Talk only about the \
lesson topic; if the learner goes off-topic, steer back politely in Chinese.
- Use only vocabulary and grammar the learner has studied up to this lesson (listed in \
the lesson context), plus the most basic function words. Keep each reply to one or two \
short sentences and end with a simple question or prompt so the learner can answer.
- Write Chinese in simplified characters. Pinyin uses tone marks (nǐ hǎo), split by word.
- Translations and any explanation are in natural Vietnamese.
- Do not correct the learner's grammar in your reply; a separate grammar checker \
handles that. Just respond naturally to the meaning.
- suggested_replies: 2-3 short example answers the learner could give next, using the \
lesson vocabulary, from simplest to slightly richer.
- Set conversation_should_end to true only when the role-play has reached a natural \
ending (for example the purchase is done and you said goodbye).

The first user turn is the system marker [BẮT ĐẦU]: open the conversation in role \
with a greeting and a first easy question.
"""

GRAMMAR_INSTRUCTIONS = """\
You are a Chinese grammar checker for Vietnamese beginners (HSK 1-2) in the ChaiLish app. \
You receive the question the learner was answering and the learner's answer. Analyse \
only the learner's answer.

- Judge grammar and word choice, not content: an answer that is grammatical and fits \
the question is correct even if it is short. Ignore missing or different punctuation.
- corrected_sentence: the minimal correction that keeps the learner's meaning and level. \
If the sentence is already correct, repeat it unchanged and return no errors.
- components: split the corrected sentence, in order, into sentence components \
(subject, predicate, object, adverbial, attributive, complement, measure_word, \
particle, other) with pinyin and a Vietnamese label such as "Chủ ngữ", "Vị ngữ", \
"Tân ngữ", "Trạng ngữ", "Định ngữ", "Bổ ngữ", "Lượng từ", "Trợ từ".
- errors: one entry per mistake with the wrong span, its correction, the error type, \
and a short explanation in Vietnamese that a beginner understands. Typical Vietnamese \
learner mistakes: time/place words placed after the verb (word_order), missing or \
wrong measure word, missing 了, 不 vs 没, missing 的/吗, using 是 before adjectives.
- grammar_point_id / grammar_point_ids: use the ids from the lesson grammar points when \
the sentence uses or should have used that point; otherwise null / empty list.
- score: 0-100. 100 = correct and natural; deduct roughly 15-30 per real error \
depending on severity; minor unnaturalness costs at most 10.
- overall_comment_vi: one or two encouraging sentences in Vietnamese.
"""

START_MARKER = "[BẮT ĐẦU]"


@dataclass
class LessonContext:
    lesson_id: int | None
    title: str
    topic: str | None
    description: str | None
    scenario: dict | None
    current_words: list[str] = field(default_factory=list)
    previous_words: list[str] = field(default_factory=list)
    grammar_points: list[dict] = field(default_factory=list)

    def render(self) -> str:
        lines = [f"# Lesson: {self.title}"]
        if self.topic:
            lines.append(f"Topic: {self.topic}")
        if self.description:
            lines.append(f"Description: {self.description}")

        scenario = self.scenario or {}
        lines.append("\n## Role-play")
        lines.append(f"AI role: {scenario.get('aiRole') or 'a friendly Chinese friend'}")
        lines.append(f"Learner role: {scenario.get('learnerRole') or 'themselves'}")
        if scenario.get("situation"):
            lines.append(f"Situation: {scenario['situation']}")
        if scenario.get("openingLine"):
            lines.append(f"Suggested opening line: {scenario['openingLine']}")

        lines.append("\n## Vocabulary of this lesson")
        lines.extend(self.current_words or ["(none)"])
        lines.append("\n## Vocabulary from earlier lessons")
        lines.extend(self.previous_words or ["(none)"])

        lines.append("\n## Grammar points (id: pattern - explanation)")
        if self.grammar_points:
            for gp in self.grammar_points:
                examples = "; ".join(gp.get("examples") or [])
                lines.append(
                    f"- {gp.get('id', '?')}: {gp.get('pattern', '')} - "
                    f"{gp.get('explanationVi', '')}" + (f" (vd: {examples})" if examples else "")
                )
        else:
            lines.append("(no explicit grammar points; use basic HSK 1 sentence patterns)")
        return "\n".join(lines)


def _word_line(word: Word) -> str:
    return f"- {word.hanzi} ({word.pinyin}): {word.meaning_vi}"


def build_lesson_context(db: Session, lesson: Lesson) -> LessonContext:
    """Ngữ cảnh gồm từ vựng + điểm ngữ pháp của bài hiện tại và các bài trước trong khóa."""
    earlier_lessons = db.scalars(
        select(Lesson)
        .where(Lesson.course_id == lesson.course_id, Lesson.order_index < lesson.order_index)
        .order_by(Lesson.order_index, Lesson.id)
    ).all()

    previous_words: list[str] = []
    seen = {w.hanzi for w in lesson.words}
    grammar_points: list[dict] = []
    for earlier in earlier_lessons:
        for w in earlier.words:
            if w.hanzi not in seen:
                seen.add(w.hanzi)
                previous_words.append(_word_line(w))
        grammar_points.extend(earlier.grammar_points or [])
    grammar_points.extend(lesson.grammar_points or [])

    return LessonContext(
        lesson_id=lesson.id,
        title=lesson.title,
        topic=lesson.topic,
        description=lesson.description,
        scenario=lesson.ai_scenario,
        current_words=[_word_line(w) for w in lesson.words],
        previous_words=previous_words,
        grammar_points=grammar_points,
    )


def grammar_user_prompt(question_hanzi: str | None, answer: str) -> str:
    question = question_hanzi or "(learner started the topic)"
    return f"Question the learner was answering: {question}\nLearner's answer: {answer}"
