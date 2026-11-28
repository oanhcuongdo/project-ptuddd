"""Lộ trình học: đọc bản đồ của người dùng và ghi điểm node từ sự kiện học tập.

Nguồn ghi DUY NHẤT là `apply_events_to_path()`, được gọi từ `record_events()`
(app/services/progress.py) cho các sự kiện MỚI. Nhờ vậy lộ trình không tự cộng XP
và không ghi `lesson_completed` (việc của màn Bài học #19).
"""

import re
from collections.abc import Iterable
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import EventType, Lesson, PathNode, PathStage, User, UserPathProgress
from app.schemas.path import PathNodeOut, PathOut, PathStageOut
from app.services.path_logic import (
    STATUS_AVAILABLE,
    STATUS_COMPLETED,
    compute_statuses,
    is_passed,
    next_node_id,
    stars_for_score,
)


def build_path_out(db: Session, user: User) -> PathOut:
    stages = list(db.scalars(select(PathStage).order_by(PathStage.order_index)))
    nodes = list(
        db.scalars(
            select(PathNode)
            .join(PathStage, PathNode.stage_id == PathStage.id)
            .order_by(PathStage.order_index, PathNode.order_index)
        )
    )
    progress = {
        p.node_id: p
        for p in db.scalars(
            select(UserPathProgress).where(UserPathProgress.user_id == user.id)
        )
    }
    order = [n.id for n in nodes]
    statuses = compute_statuses(order, {nid: p.best_score for nid, p in progress.items()})

    by_stage: dict[int, list[PathNodeOut]] = {}
    for n in nodes:
        p = progress.get(n.id)
        score = p.best_score if p else None
        by_stage.setdefault(n.stage_id, []).append(
            PathNodeOut(
                id=n.id,
                title=n.title,
                order_index=n.order_index,
                node_type=n.node_type,
                lesson_id=n.lesson_id,
                status=statuses[n.id],
                best_score=score,
                stars=stars_for_score(score),
                xp_reward=n.xp_reward,
                attempts_count=p.attempts_count if p else 0,
            )
        )

    return PathOut(
        stages=[
            PathStageOut(
                id=s.id,
                code=s.code,
                title=s.title,
                description=s.description,
                level=s.level,
                order_index=s.order_index,
                nodes=by_stage.get(s.id, []),
            )
            for s in stages
        ],
        next_node_id=next_node_id(order, statuses),
        total_nodes=len(order),
        completed_nodes=sum(1 for s in statuses.values() if s == STATUS_COMPLETED),
    )


def record_node_score(
    db: Session,
    user: User,
    node: PathNode,
    score: float,
    *,
    now: datetime | None = None,
) -> UserPathProgress:
    """Ghi một lượt làm node: giữ điểm cao nhất, tính lại sao, đánh dấu hoàn thành."""
    now = now or datetime.now(timezone.utc)
    row = db.scalar(
        select(UserPathProgress).where(
            UserPathProgress.user_id == user.id, UserPathProgress.node_id == node.id
        )
    )
    if row is None:
        row = UserPathProgress(
            user_id=user.id,
            node_id=node.id,
            status=STATUS_AVAILABLE,
            best_score=None,
            stars=0,
            attempts_count=0,
            unlocked_at=now,
        )
        db.add(row)

    row.attempts_count = (row.attempts_count or 0) + 1
    if row.best_score is None or score > row.best_score:
        row.best_score = score
    row.stars = stars_for_score(row.best_score)
    if is_passed(row.best_score):
        row.status = STATUS_COMPLETED
        if row.completed_at is None:
            row.completed_at = now
    return row


def _resolve_node(db: Session, event_type: str, ref_id: str | None) -> PathNode | None:
    ref = (ref_id or "").strip()
    if not ref:
        return None
    if event_type == EventType.QUIZ_COMPLETED:
        # ref_id là id node ("4" hoặc "node-4").
        match = re.search(r"(\d+)$", ref)
        return db.get(PathNode, int(match.group(1))) if match else None
    # lesson_completed: ref_id là mã bài (Lesson.code), cũng chấp nhận id số.
    lesson = db.scalar(select(Lesson).where(Lesson.code == ref))
    if lesson is None and ref.isdigit():
        lesson = db.get(Lesson, int(ref))
    if lesson is None:
        return None
    return db.scalar(select(PathNode).where(PathNode.lesson_id == lesson.id))


def apply_events_to_path(db: Session, user: User, events: Iterable) -> None:
    """Hook gọi từ record_events() với các sự kiện MỚI (không phải bản trùng)."""
    for ev in events:
        if ev.type not in (EventType.LESSON_COMPLETED, EventType.QUIZ_COMPLETED):
            continue
        if ev.score is None:
            continue
        node = _resolve_node(db, ev.type, ev.ref_id)
        if node is not None:
            score = max(0.0, min(float(ev.score), 100.0))
            record_node_score(db, user, node, score)