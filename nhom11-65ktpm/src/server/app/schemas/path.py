"""Schema API Lộ trình học."""

from typing import Literal

from pydantic import BaseModel, Field


class PathNodeOut(BaseModel):
    id: int
    title: str
    order_index: int
    node_type: str
    lesson_id: int | None
    status: Literal["locked", "available", "completed"]
    best_score: float | None
    stars: int  # 0..3
    xp_reward: int
    attempts_count: int


class PathStageOut(BaseModel):
    id: int
    code: str
    title: str
    description: str | None
    level: str
    order_index: int
    nodes: list[PathNodeOut]


class PathOut(BaseModel):
    stages: list[PathStageOut]
    next_node_id: int | None
    total_nodes: int
    completed_nodes: int


class NodeCompleteIn(BaseModel):
    # Node không phải bài học (mốc, bài kiểm tra...) báo điểm 0..100.
    score: float = Field(default=100, ge=0, le=100)