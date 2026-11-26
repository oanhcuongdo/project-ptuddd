"""Tài khoản người dùng và phiên đăng nhập (refresh token)."""

import uuid
from datetime import datetime, time

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, CreatedAtMixin, TimestampMixin


class UserStatus:
    ACTIVE = "active"
    LOCKED = "locked"
    DELETED = "deleted"


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str] = mapped_column(String(120))
    # Tên hiển thị công khai trên bảng xếp hạng (không lộ email).
    display_name: Mapped[str | None] = mapped_column(String(60))
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(20), default=UserStatus.ACTIVE)

    # Hồ sơ học tập
    level: Mapped[str] = mapped_column(String(20), default="beginner")  # beginner|HSK1|HSK2
    daily_goal_minutes: Mapped[int] = mapped_column(Integer, default=15)
    reminder_time: Mapped[time | None] = mapped_column(Time)
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Ho_Chi_Minh")
    xp_total: Mapped[int] = mapped_column(Integer, default=0)
    placement_done: Mapped[bool] = mapped_column(Boolean, default=False)

    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class RefreshToken(CreatedAtMixin, Base):
    """Mỗi bản ghi là một phiên đăng nhập trên một thiết bị.

    Chỉ lưu hash SHA-256 của refresh token, không lưu token gốc.
    """

    __tablename__ = "refresh_tokens"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    device_name: Mapped[str | None] = mapped_column(String(120))
    user_agent: Mapped[str | None] = mapped_column(String(255))
    ip_address: Mapped[str | None] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(back_populates="refresh_tokens")


class PasswordResetOtp(CreatedAtMixin, Base):
    """Mã OTP đặt lại mật khẩu gửi qua email (chỉ lưu HMAC của mã)."""

    __tablename__ = "password_reset_otps"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    otp_hash: Mapped[str] = mapped_column(String(128))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
