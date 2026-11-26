"""API Lộ trình học.

GET  /api/path                        bản đồ + trạng thái + sao của người dùng
POST /api/path/nodes/{id}/complete    báo hoàn thành node KHÔNG phải bài học

Tiến độ bài học được cập nhật tự động khi nhận sự kiện lesson_completed /
quiz_completed (hook trong record_events), không qua endpoint này.
"""

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.models import EventType, PathNode
from app.schemas.path import NodeCompleteIn, PathOut
from app.services.path import build_path_out
from app.services.path_logic import STATUS_COMPLETED, STATUS_LOCKED, is_passed
from app.services.progress import NewEvent, record_events

router = APIRouter(prefix="/path", tags=["learning-path"])


@router.get("", response_model=PathOut, summary="Bản đồ lộ trình học của tôi")
def get_path(user: CurrentUser, db: DbSession) -> PathOut:
    return build_path_out(db, user)


@router.post(
    "/nodes/{node_id}/complete",
    response_model=PathOut,
    summary="Báo hoàn thành node không phải bài học (mốc, bài kiểm tra...)",
)
def complete_node(
    node_id: int, body: NodeCompleteIn, user: CurrentUser, db: DbSession
) -> PathOut:
    node = db.get(PathNode, node_id)
    if node is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy node")
    if node.lesson_id is not None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Node bài học được tính từ sự kiện lesson_completed, không dùng endpoint này.",
        )

    current = build_path_out(db, user)
    node_out = next(n for s in current.stages for n in s.nodes if n.id == node_id)
    if node_out.status == STATUS_LOCKED:
        raise HTTPException(status.HTTP_409_CONFLICT, "Cần hoàn thành bài trước để mở khóa.")

    # Ghi qua record_events để cộng XP/streak đúng một lần; hook sẽ cập nhật lộ trình.
    record_events(
        db,
        user,
        [
            NewEvent(
                type=EventType.QUIZ_COMPLETED,
                xp=(
                    node.xp_reward
                    if node_out.status != STATUS_COMPLETED and is_passed(body.score)
                    else 0
                ),
                score=body.score,
                ref_id=str(node.id),
            )
        ],
    )
    db.commit()
    return build_path_out(db, user)