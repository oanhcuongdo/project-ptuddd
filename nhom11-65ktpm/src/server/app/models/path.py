"""Lộ trình học: chặng (stage) -> bài trên lộ trình (node) và tiến độ người học."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin

# Điểm tối thiểu để hoàn thành một bài và mở khóa bài tiếp theo.
DEFAULT_UNLOCK_SCORE = 70


class PathStage(TimestampMixin, Base):
    __tablename__ = "path_stages"  

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(64), unique=True)
    order_index: Mapped[int] = mapped_column(Integer, index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text)
    level: Mapped[str] = mapped_column(String(20))  # PINYIN | HSK1 | HSK2
    # Điểm bài kiểm tra cuối chặng cần đạt để sang chặng mới.
    pass_score: Mapped[int] = mapped_column(Integer, default=DEFAULT_UNLOCK_SCORE)

    nodes: Mapped[list["PathNode"]] = relationship(
        back_populates="stage", order_by="PathNode.order_index", cascade="all, delete-orphan"
    )


class PathNode(TimestampMixin, Base):
    __tablename__ = "path_nodes"

    id: Mapped[int] = mapped_column(primary_key=True)
    stage_id: Mapped[int] = mapped_column(
        ForeignKey("path_stages.id", ondelete="CASCADE"), index=True
    )
    lesson_id: Mapped[int | None] = mapped_column(ForeignKey("lessons.id", ondelete="SET NULL"))
    order_index: Mapped[int] = mapped_column(Integer)
    node_type: Mapped[str] = mapped_column(String(20), default="lesson")  # lesson | stage_test
    title: Mapped[str] = mapped_column(String(200))
    min_score_to_unlock: Mapped[int] = mapped_column(Integer, default=DEFAULT_UNLOCK_SCORE)
    xp_reward: Mapped[int] = mapped_column(Integer, default=20)

    stage: Mapped[PathStage] = relationship(back_populates="nodes")


class UserPathProgress(Base):
    __tablename__ = "user_path_progress"
    __table_args__ = (UniqueConstraint("user_id", "node_id", name="uq_user_path_progress_user_node"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    node_id: Mapped[int] = mapped_column(ForeignKey("path_nodes.id", ondelete="CASCADE"))
    status: Mapped[str] = mapped_column(String(20), default="locked")
    # locked | unlocked | in_progress | completed
    best_score: Mapped[float | None] = mapped_column(Float)
    stars: Mapped[int] = mapped_column(Integer, default=0)  # 0..3
    attempts_count: Mapped[int] = mapped_column(Integer, default=0)
    unlocked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
