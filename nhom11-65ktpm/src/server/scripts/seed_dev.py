"""Nạp dữ liệu mẫu cho môi trường DEV để cả nhóm test nhanh.

    cd nhom11-65ktpm/src/server
    python -m scripts.seed_dev            # tạo/cập nhật dữ liệu mẫu (chạy lại nhiều lần vẫn an toàn)
    python -m scripts.seed_dev --reset    # xóa tài khoản demo rồi tạo lại dữ liệu học tập từ đầu

Dữ liệu tạo ra:
- Khóa HSK1 với các bài mẫu đọc từ `data/lessons/hsk1/lesson-*.json` (hiện 3 bài).
  Bài nào cũng có điểm ngữ pháp và kịch bản cho Trợ lý AI.
- Lộ trình: chặng "HSK 1 - Khởi động" gồm 3 bài và bài kiểm tra cuối chặng.
- Tài khoản demo (xem DEMO_USERS) kèm tiến độ lộ trình, thẻ flashcard đến hạn hôm nay
  và 30 ngày sự kiện học tập giả (`learning_events`), từ đó tự tính thống kê ngày,
  streak và XP như dữ liệu thật.

Đây KHÔNG phải script nạp nội dung chính thức (issue #18). Khi script đó xong, nội dung
bài học sẽ lấy từ đó; script này chỉ để có dữ liệu test và luôn từ chối chạy ở production.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import get_session_factory
from app.models.content import Course, Lesson, Word
from app.models.path import PathNode, PathStage, UserPathProgress
from app.models.practice import SrsCard
from app.models.progress import EventType
from app.models.user import User
from app.services.progress import NewEvent, record_events

DATA_DIR = Path(__file__).resolve().parents[3] / "data" / "lessons"

DEMO_USERS = [
    # Tài khoản chính: đã học xong bài 1, đang học bài 2.
    {"email": "demo@chailish.dev", "password": "Demo12345", "full_name": "Học viên Demo",
     "display_name": "Demo", "level": "HSK1", "xp_total": 0, "with_progress": True},
    # Tài khoản mới tinh để test luồng người dùng lần đầu.
    {"email": "new@chailish.dev", "password": "Demo12345", "full_name": "Người dùng mới",
     "display_name": "Newbie", "level": "beginner", "xp_total": 0, "with_progress": False},
]

def _lesson_specs() -> list[dict]:
    """Đọc mọi bài trong `data/lessons/<cấp>/lesson-*.json` (định dạng: docs/hop-dong-du-lieu.md)."""
    specs = []
    for path in sorted(DATA_DIR.glob("*/lesson-*.json")):
        raw = json.loads(path.read_text(encoding="utf-8"))
        specs.append({
            "code": raw["id"], "order": raw["order"], "title": raw["title"],
            "description": raw.get("description"), "topic": raw.get("topic"),
            "level": raw.get("level", "HSK1"),
            "grammar_points": raw.get("grammarPoints"), "ai_scenario": raw.get("aiScenario"),
            "content_version": raw.get("contentVersion", 1),
            "words": [
                {"code": v["id"], "hanzi": v["hanzi"], "pinyin": v["pinyin"], "han_viet": v.get("hanViet"),
                 "meaning_vi": v["meaningVi"], "example": v.get("example")}
                for v in raw["vocabulary"]
            ],
        })
    return sorted(specs, key=lambda s: (s["level"], s["order"]))


def seed_content(db: Session) -> list[Lesson]:
    course = db.scalar(select(Course).where(Course.code == "HSK1"))
    if course is None:
        course = Course(code="HSK1")
        db.add(course)
    course.title = "HSK 1"
    course.description = "Giáo trình HSK cấp 1: khoảng 150 từ vựng và các mẫu câu cơ bản."
    course.order_index = 1
    db.flush()

    lessons: list[Lesson] = []
    for spec in _lesson_specs():
        lesson = db.scalar(select(Lesson).where(Lesson.code == spec["code"]))
        if lesson is None:
            lesson = Lesson(code=spec["code"], course_id=course.id)
            db.add(lesson)
        lesson.course_id = course.id
        lesson.order_index = spec["order"]
        lesson.title = spec["title"]
        lesson.description = spec["description"]
        lesson.topic = spec["topic"]
        lesson.grammar_points = spec["grammar_points"]
        lesson.ai_scenario = spec["ai_scenario"]
        lesson.content_version = spec["content_version"]
        db.flush()

        existing = {w.code: w for w in lesson.words}
        for idx, w in enumerate(spec["words"]):
            word = existing.get(w["code"])
            if word is None:
                word = Word(lesson_id=lesson.id, code=w["code"])
                lesson.words.append(word)
            word.order_index = idx
            word.hanzi = w["hanzi"]
            word.pinyin = w["pinyin"]
            word.han_viet = w["han_viet"]
            word.meaning_vi = w["meaning_vi"]
            word.example = w["example"]
            word.hsk_level = 1
        lessons.append(lesson)
    db.flush()
    return lessons


def seed_path(db: Session, lessons: list[Lesson]) -> list[PathNode]:
    stage = db.scalar(select(PathStage).where(PathStage.code == "hsk1-stage-1"))
    if stage is None:
        stage = PathStage(code="hsk1-stage-1")
        db.add(stage)
    stage.order_index = 1
    stage.title = "HSK 1 - Khởi động"
    stage.description = "Chào hỏi, gia đình và số đếm."
    stage.level = "HSK1"
    stage.pass_score = 70
    db.flush()

    wanted = [(i + 1, "lesson", lesson.title, lesson.id) for i, lesson in enumerate(lessons)]
    wanted.append((len(lessons) + 1, "stage_test", "Kiểm tra cuối chặng", None))
    by_order = {n.order_index: n for n in stage.nodes}
    nodes: list[PathNode] = []
    for order, node_type, title, lesson_id in wanted:
        node = by_order.get(order)
        if node is None:
            node = PathNode(order_index=order)
            stage.nodes.append(node)
        node.node_type = node_type
        node.title = title
        node.lesson_id = lesson_id
        node.xp_reward = 50 if node_type == "stage_test" else 20
        nodes.append(node)
    db.flush()
    return nodes


def _seed_learning_data(db: Session, user: User, lessons: list[Lesson], nodes: list[PathNode]) -> None:
    now = datetime.now(timezone.utc)
    today = date.today()

    statuses = [("completed", 92.0, 3), ("in_progress", 65.0, 1), ("locked", None, 0), ("locked", None, 0)]
    for node, (status, score, stars) in zip(nodes, statuses):
        db.add(UserPathProgress(
            user_id=user.id, node_id=node.id, status=status, best_score=score, stars=stars,
            attempts_count=1 if score is not None else 0,
            unlocked_at=now - timedelta(days=6) if status != "locked" else None,
            completed_at=now - timedelta(days=3) if status == "completed" else None,
        ))

    # Bài 1: thẻ đã ôn vài lần, một nửa đến hạn hôm nay. Bài 2: thẻ mới đến hạn hôm nay.
    for i, word in enumerate(lessons[0].words):
        due = today if i % 2 == 0 else today + timedelta(days=i)
        db.add(SrsCard(user_id=user.id, word_id=word.id, ease_factor=2.5, interval_days=3,
                       repetitions=2, due_date=due, last_reviewed_at=now - timedelta(days=3)))
    for word in lessons[1].words[:5]:
        db.add(SrsCard(user_id=user.id, word_id=word.id, due_date=today))

    record_events(db, user, demo_events(user.id, lessons, days=30))


def demo_events(user_id, lessons: list[Lesson], days: int = 30) -> list[NewEvent]:
    """Sinh sự kiện học tập giả cho `days` ngày gần nhất (có vài ngày nghỉ).

    Id sinh cố định theo (user, ngày, thứ tự) nên chạy lại không bị nhân đôi.
    """
    tz = ZoneInfo("Asia/Ho_Chi_Minh")
    today = datetime.now(tz).date()
    rnd = random.Random(f"chailish-demo-{user_id}")
    words = [w for lesson in lessons for w in lesson.words]
    events: list[NewEvent] = []
    for back in range(days - 1, -1, -1):
        day = today - timedelta(days=back)
        # Nghỉ một số ngày cũ để heatmap có chỗ trống; 5 ngày gần nhất luôn học (streak).
        if back > 4 and rnd.random() < 0.25:
            continue
        clock = datetime.combine(day, datetime.min.time(), tz) + timedelta(hours=19, minutes=rnd.randint(0, 90))
        if back == 0:
            clock = min(clock, datetime.now(tz) - timedelta(minutes=30))
        seq = 0

        def add(type_: str, **kw) -> None:
            nonlocal clock, seq
            seq += 1
            events.append(NewEvent(
                id=uuid.uuid5(uuid.NAMESPACE_URL, f"chailish:demo:{user_id}:{day}:{seq}"),
                type=type_, occurred_at=clock, **kw,
            ))
            clock += timedelta(seconds=kw.get("duration_sec", 30))

        for _ in range(rnd.randint(4, 12)):
            w = rnd.choice(words)
            q = rnd.choice([3, 4, 4, 5, 5, 2])
            add(EventType.SRS_REVIEW, xp=1, duration_sec=12, ref_id=str(w.id), data={"quality": q})
        for _ in range(rnd.randint(1, 5)):
            w = rnd.choice(words)
            tones = {str(t): rnd.randint(55, 100) for t in (1, 2, 3, 4)}
            score = rnd.randint(60, 98)
            add(EventType.PRONUNCIATION_SCORED, xp=5 if score >= 90 else 2, duration_sec=40, score=score,
                ref_id=w.hanzi, data={"tones": tones})
        for _ in range(rnd.randint(0, 4)):
            ch = rnd.choice([c for w in words for c in w.hanzi])
            add(EventType.CHARACTER_WRITTEN, xp=2, duration_sec=60, score=rnd.randint(50, 100), ref_id=ch,
                data={"mode": rnd.choice(["trace", "free"]), "wrong_strokes": rnd.randint(0, 3)})
        if back in (20, 12, 3):
            lesson = lessons[min(len(lessons) - 1, {20: 0, 12: 0, 3: 1}[back])]
            add(EventType.LESSON_COMPLETED, xp=20, duration_sec=600, score=rnd.randint(75, 98), ref_id=lesson.code)
        if back % 6 == 1:
            add(EventType.AI_SESSION_FINISHED, xp=10, duration_sec=420, score=rnd.randint(60, 95),
                ref_id=f"demo-{day}", data={"lesson_id": lessons[0].id})
    return events


def seed_users(db: Session, lessons: list[Lesson], nodes: list[PathNode], reset: bool) -> list[str]:
    created: list[str] = []
    for spec in DEMO_USERS:
        user = db.scalar(select(User).where(User.email == spec["email"]))
        if user is not None and reset:
            db.execute(delete(User).where(User.id == user.id))
            db.flush()
            user = None
        if user is not None:
            continue  # giữ nguyên dữ liệu người dùng đã tạo từ lần chạy trước
        user = User(
            email=spec["email"], password_hash=hash_password(spec["password"]),
            full_name=spec["full_name"], display_name=spec["display_name"], level=spec["level"],
            xp_total=spec["xp_total"], placement_done=spec["with_progress"],
        )
        db.add(user)
        db.flush()
        if spec["with_progress"]:
            _seed_learning_data(db, user, lessons, nodes)
        created.append(spec["email"])
    return created


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Nạp dữ liệu mẫu cho môi trường dev.")
    parser.add_argument("--reset", action="store_true", help="xóa và tạo lại các tài khoản demo")
    args = parser.parse_args(argv)

    if settings.ENVIRONMENT == "production":
        print("Từ chối chạy: ENVIRONMENT=production. Script này chỉ dành cho dev.", file=sys.stderr)
        return 1

    with get_session_factory()() as db:
        lessons = seed_content(db)
        nodes = seed_path(db, lessons)
        created = seed_users(db, lessons, nodes, args.reset)
        db.commit()

        print("Đã nạp dữ liệu mẫu:")
        for lesson in lessons:
            print(f"  - Bài id={lesson.id} [{lesson.code}] {lesson.title}: {len(lesson.words)} từ")
        print(f"  - Lộ trình: {len(nodes)} mục trong chặng 'HSK 1 - Khởi động'")
        print("Tài khoản demo (mật khẩu chung: Demo12345):")
        for spec in DEMO_USERS:
            note = "mới tạo" if spec["email"] in created else "đã có, giữ nguyên (dùng --reset để tạo lại)"
            print(f"  - {spec['email']} ({note})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
