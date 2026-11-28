import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.models import DailyStat, Streak, User


def _event(type_="srs_review", days_ago=0, **kw):
    return {
        "id": str(uuid.uuid4()),
        "type": type_,
        "occurred_at": (datetime.now(UTC) - timedelta(days=days_ago)).isoformat(),
        **kw,
    }


def test_post_events_updates_xp_daily_stats_and_streak(client, auth_headers, db_session):
    events = [
        _event("srs_review", xp=1, duration_sec=60),
        _event("pronunciation_scored", xp=5, duration_sec=120, score=92, ref_id="你好"),
        _event("lesson_completed", days_ago=1, xp=20, duration_sec=600, score=80, ref_id="hsk1-greetings-01"),
        _event("character_written", days_ago=2, xp=2, score=70, ref_id="好"),
    ]
    res = client.post("/api/events", json={"events": events}, headers=auth_headers)
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["accepted"] == 4 and body["duplicates"] == 0
    assert body["xp_total"] == 28
    assert body["current_streak"] == 3 and body["longest_streak"] == 3

    user = db_session.scalar(select(User))
    stats = {s.stat_date: s for s in db_session.scalars(select(DailyStat).where(DailyStat.user_id == user.id))}
    assert len(stats) == 3
    today = max(stats)
    assert stats[today].reviews_count == 1
    assert stats[today].pronunciation_count == 1
    assert stats[today].minutes_studied == 3
    assert stats[today].xp_earned == 6
    assert stats[today].avg_score == 92


def test_resending_same_ids_is_idempotent(client, auth_headers):
    events = [_event(xp=3), _event(xp=4)]
    first = client.post("/api/events", json={"events": events}, headers=auth_headers).json()
    again = client.post("/api/events", json={"events": events}, headers=auth_headers).json()
    assert first["accepted"] == 2
    assert again["accepted"] == 0 and again["duplicates"] == 2
    assert again["xp_total"] == 7


def test_streak_breaks_after_a_gap(client, auth_headers, db_session):
    events = [_event(days_ago=d, xp=1) for d in (0, 1, 4, 5, 6, 7)]
    body = client.post("/api/events", json={"events": events}, headers=auth_headers).json()
    assert body["current_streak"] == 2
    assert body["longest_streak"] == 4
    assert db_session.scalar(select(Streak)).current_streak == 2


def test_rejects_unknown_type_future_time_and_missing_token(client, auth_headers):
    bad_type = client.post("/api/events", json={"events": [_event("hack_xp")]}, headers=auth_headers)
    assert bad_type.status_code == 422
    future = _event()
    future["occurred_at"] = (datetime.now(UTC) + timedelta(days=1)).isoformat()
    assert client.post("/api/events", json={"events": [future]}, headers=auth_headers).status_code == 422
    too_much_xp = _event(xp=10_000)
    assert client.post("/api/events", json={"events": [too_much_xp]}, headers=auth_headers).status_code == 422
    assert client.post("/api/events", json={"events": [_event()]}).status_code == 401


def test_list_events_only_returns_my_events(client, auth_headers, register_user):
    client.post("/api/events", json={"events": [_event(xp=1), _event("srs_review", days_ago=3)]}, headers=auth_headers)
    other = register_user(email="khac@chailish.vn")
    client.post(
        "/api/events",
        json={"events": [_event()]},
        headers={"Authorization": f"Bearer {other['access_token']}"},
    )

    mine = client.get("/api/events", headers=auth_headers).json()
    assert len(mine) == 2
    recent = client.get(
        "/api/events",
        params={"since": (datetime.now(UTC) - timedelta(days=1)).isoformat()},
        headers=auth_headers,
    ).json()
    assert len(recent) == 1
    filtered = client.get("/api/events", params={"type": "pronunciation_scored"}, headers=auth_headers).json()
    assert filtered == []
