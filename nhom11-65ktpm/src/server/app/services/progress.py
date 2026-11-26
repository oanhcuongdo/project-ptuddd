"""Ghi sự kiện học tập và cập nhật số liệu tổng hợp (daily_stats, streaks, xp_total).

Dùng trên server:

    from app.services.progress import NewEvent, record_events

    record_events(db, user, [NewEvent(type=EventType.QUIZ_COMPLETED, xp=50, score=85, ref_id="node-4")])
    db.commit()

Từ app thì gửi `POST /api/events` (xem app/api/routes/events.py).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import DailyStat, EventType, LearningEvent, Streak, User

MAX_XP_PER_EVENT = 500
MAX_DURATION_SEC = 4 * 3600


@dataclass
class NewEvent:
    type: str
    occurred_at: datetime | None = None
    xp: int = 0
    duration_sec: int = 0
    score: float | None = None
    ref_id: str | None = None
    data: dict | None = None
    id: uuid.UUID = field(default_factory=uuid.uuid4)


@dataclass
class RecordResult:
    accepted: int
    duplicates: int
    xp_total: int
    current_streak: int
    longest_streak: int


def _tz(user: User) -> ZoneInfo:
    try:
        return ZoneInfo(user.timezone or "Asia/Ho_Chi_Minh")
    except ZoneInfoNotFoundError:
        return ZoneInfo("Asia/Ho_Chi_Minh")


def _aware(dt: datetime) -> datetime:
    # SQLite trả datetime không múi giờ: coi là UTC.
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)


def local_date(user: User, dt: datetime) -> date:
    return _aware(dt).astimezone(_tz(user)).date()


def _day_bounds(user: User, day: date) -> tuple[datetime, datetime]:
    start = datetime.combine(day, time.min, tzinfo=_tz(user)).astimezone(UTC)
    return start, start + timedelta(days=1)


def _recompute_day(db: Session, user: User, day: date) -> None:
    start, end = _day_bounds(user, day)
    events = db.scalars(
        select(LearningEvent).where(
            LearningEvent.user_id == user.id,
            LearningEvent.occurred_at >= start,
            LearningEvent.occurred_at < end,
        )
    ).all()
    stat = db.scalar(select(DailyStat).where(DailyStat.user_id == user.id, DailyStat.stat_date == day))
    if stat is None:
        stat = DailyStat(user_id=user.id, stat_date=day)
        db.add(stat)

    def count(t: str) -> int:
        return sum(1 for e in events if e.type == t)

    scores = [e.score for e in events if e.score is not None]
    stat.minutes_studied = sum(e.duration_sec for e in events) // 60
    stat.pronunciation_count = count(EventType.PRONUNCIATION_SCORED)
    stat.writing_count = count(EventType.CHARACTER_WRITTEN)
    stat.reviews_count = count(EventType.SRS_REVIEW)
    stat.lessons_completed = count(EventType.LESSON_COMPLETED)
    stat.avg_score = round(sum(scores) / len(scores), 1) if scores else None
    stat.xp_earned = sum(e.xp for e in events)


def _recompute_streak(db: Session, user: User) -> Streak:
    active = sorted(
        db.scalars(
            select(DailyStat.stat_date).where(
                DailyStat.user_id == user.id,
                (DailyStat.xp_earned > 0) | (DailyStat.minutes_studied > 0)
                | (DailyStat.reviews_count > 0) | (DailyStat.lessons_completed > 0)
                | (DailyStat.pronunciation_count > 0) | (DailyStat.writing_count > 0),
            )
        ).all()
    )
    longest = run = 0
    prev: date | None = None
    for d in active:
        run = run + 1 if prev is not None and d - prev == timedelta(days=1) else 1
        longest = max(longest, run)
        prev = d

    today = datetime.now(_tz(user)).date()
    current = 0
    if active and active[-1] >= today - timedelta(days=1):
        current = run  # chuỗi cuối cùng còn "sống" nếu học hôm nay hoặc hôm qua

    streak = db.get(Streak, user.id)
    if streak is None:
        streak = Streak(user_id=user.id, current_streak=0, longest_streak=0)
        db.add(streak)
    streak.current_streak = current
    streak.longest_streak = max(longest, streak.longest_streak or 0)
    streak.last_active_date = active[-1] if active else None
    return streak


def record_events(db: Session, user: User, events: list[NewEvent]) -> RecordResult:
    """Lưu các sự kiện mới (bỏ qua id đã có) rồi cập nhật thống kê ngày, streak và XP.

    Các sự kiện mới cũng được chuyển cho Lộ trình học (`apply_events_to_path`) để
    cập nhật `user_path_progress`.

    Không commit: người gọi tự `db.commit()`.
    """
    now = datetime.now(UTC)
    ids = [e.id for e in events]
    existing = set(db.scalars(select(LearningEvent.id).where(LearningEvent.id.in_(ids))).all()) if ids else set()

    touched: set[date] = set()
    accepted = 0
    xp_added = 0
    seen: set[uuid.UUID] = set()
    new_events: list[NewEvent] = []  # chỉ các sự kiện thật sự được ghi (không tính bản trùng)
    for e in events:
        if e.id in existing or e.id in seen:
            continue
        seen.add(e.id)
        occurred = _aware(e.occurred_at).astimezone(UTC) if e.occurred_at else now
        xp = max(0, min(int(e.xp), MAX_XP_PER_EVENT))
        db.add(LearningEvent(
            id=e.id, user_id=user.id, type=e.type, occurred_at=occurred, xp=xp,
            duration_sec=max(0, min(int(e.duration_sec), MAX_DURATION_SEC)),
            score=None if e.score is None else max(0.0, min(float(e.score), 100.0)),
            ref_id=e.ref_id, data=e.data,
        ))
        touched.add(local_date(user, occurred))
        accepted += 1
        xp_added += xp
        new_events.append(e)

    if accepted:
        db.flush()
        for day in touched:
            _recompute_day(db, user, day)
        db.flush()
        user.xp_total = (user.xp_total or 0) + xp_added
        from app.services.path import apply_events_to_path
        apply_events_to_path(db, user, new_events)
    streak = _recompute_streak(db, user) if accepted else db.get(Streak, user.id)
    db.flush()
    return RecordResult(
        accepted=accepted,
        duplicates=len(events) - accepted,
        xp_total=user.xp_total or 0,
        current_streak=streak.current_streak if streak else 0,
        longest_streak=streak.longest_streak if streak else 0,
    )


def count_events(db: Session, user: User, type_: str | None = None) -> int:
    query = select(func.count()).select_from(LearningEvent).where(LearningEvent.user_id == user.id)
    if type_:
        query = query.where(LearningEvent.type == type_)
    return db.scalar(query) or 0


__all__ = ["NewEvent", "RecordResult", "count_events", "local_date", "record_events"]