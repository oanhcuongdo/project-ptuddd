from sqlalchemy import func, select

from app.models.content import Lesson
from app.models.path import PathNode, UserPathProgress
from app.models.practice import SrsCard, Streak
from app.models.progress import LearningEvent
from app.models.user import User
from scripts.seed_dev import DEMO_USERS, _lesson_specs, seed_content, seed_path, seed_users


def _seed(db, reset=False):
    lessons = seed_content(db)
    nodes = seed_path(db, lessons)
    seed_users(db, lessons, nodes, reset)
    db.commit()


def test_seed_is_idempotent_and_demo_user_can_log_in(db_session, client):
    _seed(db_session)
    _seed(db_session)

    assert db_session.scalar(select(func.count()).select_from(Lesson)) == len(_lesson_specs())
    assert db_session.scalar(select(func.count()).select_from(User)) == len(DEMO_USERS)
    first = db_session.scalar(select(Lesson).order_by(Lesson.order_index))
    assert first.ai_scenario["openingLine"] and first.grammar_points and first.words

    res = client.post("/api/auth/login", json={"email": "demo@chailish.dev", "password": "Demo12345"})
    assert res.status_code == 200


def test_seed_reset_recreates_learning_data(db_session):
    _seed(db_session)
    _seed(db_session, reset=True)
    assert db_session.scalar(select(func.count()).select_from(SrsCard)) == 14


def test_seed_keeps_hsk2_level_and_out_of_hsk1_path(db_session):
    lessons = seed_content(db_session)
    hsk2 = next(lesson for lesson in lessons if lesson.code == "hsk2-family-01")
    assert hsk2.course.code == "HSK2"
    assert all(word.hsk_level == 2 for word in hsk2.words)

    nodes = seed_path(db_session, lessons)
    path_lessons = [db_session.get(Lesson, node.lesson_id) for node in nodes if node.lesson_id is not None]
    assert path_lessons
    assert all(lesson.course.code == "HSK1" for lesson in path_lessons)


def test_seed_course_descriptions_reflect_each_groups_topics(db_session):
    lessons = seed_content(db_session)
    descriptions = {}
    for level in ("HSK1", "HSK2"):
        level_lessons = [lesson for lesson in lessons if lesson.course.code == level]
        description = level_lessons[0].course.description
        assert description.startswith("Từ vựng sơ cấp theo chủ đề:")
        assert all(lesson.topic in description for lesson in level_lessons if lesson.topic)
        descriptions[level] = description

    assert descriptions["HSK1"] != descriptions["HSK2"]


def test_seed_creates_progress_for_every_path_node(db_session):
    _seed(db_session, reset=True)
    demo = db_session.scalar(select(User).where(User.email == "demo@chailish.dev"))
    nodes = db_session.scalars(select(PathNode).order_by(PathNode.order_index)).all()
    progress = db_session.scalars(
        select(UserPathProgress).where(UserPathProgress.user_id == demo.id)
    ).all()
    progress_by_node = {item.node_id: item for item in progress}

    assert len(progress_by_node) == len(nodes) == 16
    assert progress_by_node[nodes[0].id].status == "completed"
    assert all(progress_by_node[node.id].status == "locked" for node in nodes[2:])


def test_seed_generates_30_days_of_events_once(db_session):
    _seed(db_session)
    count = db_session.scalar(select(func.count()).select_from(LearningEvent))
    _seed(db_session)
    assert count > 100
    assert db_session.scalar(select(func.count()).select_from(LearningEvent)) == count
    demo = db_session.scalar(select(User).where(User.email == "demo@chailish.dev"))
    assert demo.xp_total > 0
    assert db_session.get(Streak, demo.id).current_streak >= 5
