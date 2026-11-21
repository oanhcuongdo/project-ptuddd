"""Nạp dữ liệu mẫu cho môi trường DEV để cả nhóm test nhanh.

    cd nhom11-65ktpm/src/server
    python -m scripts.seed_dev            # tạo/cập nhật dữ liệu mẫu (chạy lại nhiều lần vẫn an toàn)
    python -m scripts.seed_dev --reset    # xóa tài khoản demo rồi tạo lại dữ liệu học tập từ đầu

Dữ liệu tạo ra:
- Khóa HSK1 với 3 bài: bài 1 đọc từ `data/lessons/hsk1/lesson-01.json`, bài 2 và 3
  định nghĩa ngay trong file này. Bài nào cũng có điểm ngữ pháp và kịch bản cho Trợ lý AI.
- Lộ trình: chặng "HSK 1 - Khởi động" gồm 3 bài và bài kiểm tra cuối chặng.
- Tài khoản demo (xem DEMO_USERS) kèm tiến độ lộ trình, thẻ flashcard đến hạn hôm nay,
  thống kê 7 ngày gần nhất và chuỗi ngày học.

Đây KHÔNG phải script nạp nội dung chính thức (issue #18). Khi script đó xong, nội dung
bài học sẽ lấy từ đó; script này chỉ để có dữ liệu test và luôn từ chối chạy ở production.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import get_session_factory
from app.models.content import Course, Lesson, Word
from app.models.path import PathNode, PathStage, UserPathProgress
from app.models.practice import DailyStat, SrsCard, Streak
from app.models.user import User

DATA_DIR = Path(__file__).resolve().parents[3] / "data" / "lessons"

DEMO_USERS = [
    # Tài khoản chính: đã học xong bài 1, đang học bài 2.
    {"email": "demo@chailish.dev", "password": "Demo12345", "full_name": "Học viên Demo",
     "display_name": "Demo", "level": "HSK1", "xp_total": 120, "with_progress": True},
    # Tài khoản mới tinh để test luồng người dùng lần đầu.
    {"email": "new@chailish.dev", "password": "Demo12345", "full_name": "Người dùng mới",
     "display_name": "Newbie", "level": "beginner", "xp_total": 0, "with_progress": False},
]

# Phần bổ sung cho bài 1 (file JSON hiện chưa có điểm ngữ pháp và kịch bản AI).
LESSON_01_EXTRA = {
    "topic": "chào hỏi",
    "grammarPoints": [
        {"id": "gp-shi", "pattern": "A 是 B", "explanationVi": "Câu khẳng định với 是 (là).",
         "examples": ["我是学生。", "他是老师。"]},
        {"id": "gp-ma", "pattern": "Câu + 吗？", "explanationVi": "Thêm 吗 cuối câu để hỏi có/không.",
         "examples": ["你是学生吗？", "你好吗？"]},
        {"id": "gp-hen-adj", "pattern": "S + 很 + Tính từ", "explanationVi": "Tính từ làm vị ngữ thường đi với 很.",
         "examples": ["我很好。"]},
    ],
    "aiScenario": {
        "aiRole": "một bạn sinh viên Trung Quốc tên 小明 mới gặp lần đầu",
        "learnerRole": "sinh viên Việt Nam mới đến lớp",
        "situation": "Hai người gặp nhau ở cổng trường ngày đầu nhập học và chào hỏi, giới thiệu bản thân.",
        "openingLine": "你好！你是学生吗？",
    },
}

EXTRA_LESSONS = [
    {
        "id": "hsk1-family-02", "order": 2, "title": "Gia đình tôi", "topic": "gia đình",
        "description": "Giới thiệu các thành viên trong gia đình và hỏi nhà có mấy người.",
        "vocabulary": [
            ("jia", "家", "jiā", "gia", "nhà; gia đình", "我家有四口人。", "Wǒ jiā yǒu sì kǒu rén.", "Nhà tôi có bốn người."),
            ("you", "有", "yǒu", "hữu", "có", "我有一个哥哥。", "Wǒ yǒu yí ge gēge.", "Tôi có một người anh."),
            ("ba-ba", "爸爸", "bàba", "ba ba", "bố", "我爸爸是老师。", "Wǒ bàba shì lǎoshī.", "Bố tôi là giáo viên."),
            ("ma-ma", "妈妈", "māma", "ma ma", "mẹ", "妈妈好！", "Māma hǎo!", "Con chào mẹ!"),
            ("ge-ge", "哥哥", "gēge", "ca ca", "anh trai", "我哥哥很高。", "Wǒ gēge hěn gāo.", "Anh trai tôi rất cao."),
            ("mei-mei", "妹妹", "mèimei", "muội muội", "em gái", "这是我妹妹。", "Zhè shì wǒ mèimei.", "Đây là em gái tôi."),
            ("ji", "几", "jǐ", "kỷ", "mấy", "你家有几口人？", "Nǐ jiā yǒu jǐ kǒu rén?", "Nhà bạn có mấy người?"),
            ("kou", "口", "kǒu", "khẩu", "(lượng từ đếm người trong nhà)", "三口人", "sān kǒu rén", "ba người"),
            ("ren", "人", "rén", "nhân", "người", "他是中国人。", "Tā shì Zhōngguó rén.", "Anh ấy là người Trung Quốc."),
        ],
        "grammarPoints": [
            {"id": "gp-you", "pattern": "S + 有 + O", "explanationVi": "有 diễn tả sở hữu; phủ định dùng 没有, không dùng 不有.",
             "examples": ["我有一个妹妹。", "我没有哥哥。"]},
            {"id": "gp-ji-kou", "pattern": "你家有几口人？", "explanationVi": "几 hỏi số lượng nhỏ (dưới 10), đi kèm lượng từ.",
             "examples": ["你家有几口人？", "我家有三口人。"]},
            {"id": "gp-de", "pattern": "Đại từ + (的) + người thân", "explanationVi": "Với người thân có thể bỏ 的: 我妈妈 = 我的妈妈.",
             "examples": ["我妈妈", "我的老师"]},
        ],
        "aiScenario": {
            "aiRole": "bạn cùng phòng ký túc xá người Bắc Kinh",
            "learnerRole": "sinh viên Việt Nam đang cho bạn xem ảnh gia đình",
            "situation": "Buổi tối ở ký túc xá, hai người xem ảnh gia đình và hỏi nhau về người thân.",
            "openingLine": "这是你家人吗？你家有几口人？",
        },
    },
    {
        "id": "hsk1-numbers-03", "order": 3, "title": "Số đếm và tuổi", "topic": "số đếm",
        "description": "Đếm từ 1 đến 10, hỏi và trả lời về tuổi.",
        "vocabulary": [
            ("yi", "一", "yī", "nhất", "một", "一个人", "yí ge rén", "một người"),
            ("er", "二", "èr", "nhị", "hai", "二月", "èr yuè", "tháng hai"),
            ("san", "三", "sān", "tam", "ba", "三口人", "sān kǒu rén", "ba người"),
            ("si", "四", "sì", "tứ", "bốn", "四个学生", "sì ge xuésheng", "bốn học sinh"),
            ("wu", "五", "wǔ", "ngũ", "năm", "五岁", "wǔ suì", "năm tuổi"),
            ("shi-ten", "十", "shí", "thập", "mười", "十个人", "shí ge rén", "mười người"),
            ("sui", "岁", "suì", "tuế", "tuổi", "我二十岁。", "Wǒ èrshí suì.", "Tôi hai mươi tuổi."),
            ("duo-da", "多大", "duō dà", "đa đại", "bao nhiêu tuổi", "你多大？", "Nǐ duō dà?", "Bạn bao nhiêu tuổi?"),
            ("ge", "个", "gè", "cá", "(lượng từ chung)", "一个朋友", "yí ge péngyou", "một người bạn"),
        ],
        "grammarPoints": [
            {"id": "gp-age", "pattern": "S + (今年) + số + 岁", "explanationVi": "Nói tuổi không cần 是: 我二十岁, không nói 我是二十岁 trong câu thông thường.",
             "examples": ["我今年二十岁。", "你多大？"]},
            {"id": "gp-measure-ge", "pattern": "Số + 个 + Danh từ", "explanationVi": "Giữa số và danh từ phải có lượng từ, 个 là lượng từ chung.",
             "examples": ["三个学生", "一个老师"]},
            {"id": "gp-liang", "pattern": "两 + lượng từ", "explanationVi": "Đếm 'hai cái' dùng 两, không dùng 二: 两个人.",
             "examples": ["两个人", "两口人"]},
        ],
        "aiScenario": {
            "aiRole": "nhân viên đăng ký câu lạc bộ tiếng Trung, thân thiện",
            "learnerRole": "sinh viên muốn đăng ký tham gia câu lạc bộ",
            "situation": "Nhân viên hỏi thông tin để điền phiếu: tên, tuổi, nhà có mấy người.",
            "openingLine": "你好！请问你叫什么名字？你多大？",
        },
    },
]


def _words_from_json(vocab: list[dict]) -> list[dict]:
    return [
        {"code": v["id"], "hanzi": v["hanzi"], "pinyin": v["pinyin"], "han_viet": v.get("hanViet"),
         "meaning_vi": v["meaningVi"], "example": v.get("example")}
        for v in vocab
    ]


def _words_from_tuples(vocab: list[tuple]) -> list[dict]:
    return [
        {"code": c, "hanzi": h, "pinyin": p, "han_viet": hv, "meaning_vi": m,
         "example": {"hanzi": eh, "pinyin": ep, "meaningVi": em}}
        for c, h, p, hv, m, eh, ep, em in vocab
    ]


def _lesson_specs() -> list[dict]:
    raw = json.loads((DATA_DIR / "hsk1" / "lesson-01.json").read_text(encoding="utf-8"))
    specs = [{
        "code": raw["id"], "order": raw["order"], "title": raw["title"], "description": raw.get("description"),
        "topic": LESSON_01_EXTRA["topic"], "grammar_points": LESSON_01_EXTRA["grammarPoints"],
        "ai_scenario": LESSON_01_EXTRA["aiScenario"], "content_version": raw.get("contentVersion", 1),
        "words": _words_from_json(raw["vocabulary"]),
    }]
    for lesson in EXTRA_LESSONS:
        specs.append({
            "code": lesson["id"], "order": lesson["order"], "title": lesson["title"],
            "description": lesson["description"], "topic": lesson["topic"],
            "grammar_points": lesson["grammarPoints"], "ai_scenario": lesson["aiScenario"],
            "content_version": 1, "words": _words_from_tuples(lesson["vocabulary"]),
        })
    return specs


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

    for back in range(7):
        studied = back != 4  # bỏ một ngày để biểu đồ có chỗ trống
        db.add(DailyStat(
            user_id=user.id, stat_date=today - timedelta(days=back),
            minutes_studied=10 + back * 3 if studied else 0,
            pronunciation_count=4 if studied else 0, writing_count=3 if studied else 0,
            reviews_count=12 if studied else 0, lessons_completed=1 if back == 3 else 0,
            avg_score=80.0 + back if studied else None, xp_earned=20 if studied else 0,
        ))
    db.add(Streak(user_id=user.id, current_streak=4, longest_streak=6, last_active_date=today))


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
