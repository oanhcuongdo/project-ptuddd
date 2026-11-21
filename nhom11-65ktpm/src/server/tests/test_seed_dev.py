from sqlalchemy import func, select

from app.models.content import Lesson
from app.models.practice import SrsCard
from app.models.user import User
from scripts.seed_dev import DEMO_USERS, seed_content, seed_path, seed_users


def _seed(db, reset=False):
    lessons = seed_content(db)
    nodes = seed_path(db, lessons)
    seed_users(db, lessons, nodes, reset)
    db.commit()


def test_seed_is_idempotent_and_demo_user_can_log_in(db_session, client):
    _seed(db_session)
    _seed(db_session)

    assert db_session.scalar(select(func.count()).select_from(Lesson)) == 3
    assert db_session.scalar(select(func.count()).select_from(User)) == len(DEMO_USERS)
    first = db_session.scalar(select(Lesson).order_by(Lesson.order_index))
    assert first.ai_scenario["openingLine"] and first.grammar_points and first.words

    res = client.post("/api/auth/login", json={"email": "demo@chailish.dev", "password": "Demo12345"})
    assert res.status_code == 200


def test_seed_reset_recreates_learning_data(db_session):
    _seed(db_session)
    _seed(db_session, reset=True)
    assert db_session.scalar(select(func.count()).select_from(SrsCard)) == 14
