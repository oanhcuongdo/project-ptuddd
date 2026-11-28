"""Mixin cho các bản ghi học tập được đồng bộ từ app (offline-first).

`id` do ứng dụng sinh (UUID) khi ghi vào SQLite, nhờ đó `POST /api/sync/push`
gửi lại nhiều lần vẫn không tạo bản ghi trùng (idempotent).
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, declared_attr, mapped_column


class UserOwnedSyncMixin:
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)

    @declared_attr
    def user_id(cls) -> Mapped[uuid.UUID]:
        return mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)

    # Thời điểm sự kiện xảy ra trên thiết bị và thời điểm server nhận được.
    client_created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
