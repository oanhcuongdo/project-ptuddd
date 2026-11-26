"""Nghiệp vụ xác thực: đăng ký, đăng nhập, cấp/xoay vòng refresh token, OTP."""

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core import security
from app.core.config import settings
from app.models import PasswordResetOtp, RefreshToken, User, UserStatus


class AuthError(Exception):
    def __init__(self, message: str, status_code: int = 401) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


def utcnow() -> datetime:
    return datetime.now(UTC)


def as_aware(dt: datetime) -> datetime:
    # SQLite (dùng khi test) trả datetime không có múi giờ -> coi là UTC.
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)


def normalize_email(email: str) -> str:
    return email.strip().lower()


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(User.email == normalize_email(email)))


# ---------------------------------------------------------------- Token
def issue_token_pair(
    db: Session,
    user: User,
    *,
    device_name: str | None = None,
    user_agent: str | None = None,
    ip_address: str | None = None,
) -> tuple[str, str]:
    """Tạo access token + refresh token mới (một phiên đăng nhập)."""
    raw_refresh = security.generate_refresh_token()
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=security.hash_token(raw_refresh),
            device_name=device_name,
            user_agent=(user_agent or "")[:255] or None,
            ip_address=ip_address,
            expires_at=utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        )
    )
    return security.create_access_token(user.id), raw_refresh


def _find_refresh_token(db: Session, raw_token: str) -> RefreshToken | None:
    return db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == security.hash_token(raw_token))
    )


def rotate_refresh_token(
    db: Session, raw_token: str, *, user_agent: str | None, ip_address: str | None
) -> tuple[str, str]:
    """Đổi refresh token cũ lấy cặp token mới; token cũ bị thu hồi ngay (rotation)."""
    stored = _find_refresh_token(db, raw_token)
    now = utcnow()
    if stored is None or stored.revoked_at is not None:
        raise AuthError("Refresh token không hợp lệ hoặc đã bị thu hồi")
    if as_aware(stored.expires_at) <= now:
        raise AuthError("Refresh token đã hết hạn, vui lòng đăng nhập lại")

    user = db.get(User, stored.user_id)
    if user is None or user.status != UserStatus.ACTIVE:
        raise AuthError("Tài khoản không tồn tại hoặc đã bị khóa")

    stored.revoked_at = now
    stored.last_used_at = now
    return issue_token_pair(
        db, user, device_name=stored.device_name, user_agent=user_agent, ip_address=ip_address
    )


def revoke_refresh_token(db: Session, raw_token: str) -> None:
    stored = _find_refresh_token(db, raw_token)
    if stored is not None and stored.revoked_at is None:
        stored.revoked_at = utcnow()


def revoke_all_sessions(db: Session, user_id: uuid.UUID) -> None:
    db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=utcnow())
    )


# ---------------------------------------------------------------- Đăng ký / đăng nhập
def register_user(db: Session, *, email: str, password: str, full_name: str) -> User:
    if get_user_by_email(db, email) is not None:
        raise AuthError("Email đã được sử dụng", status_code=409)
    user = User(
        email=normalize_email(email),
        password_hash=security.hash_password(password),
        full_name=full_name,
        display_name=full_name[:60],
    )
    db.add(user)
    db.flush()
    return user


def authenticate(db: Session, email: str, password: str) -> User:
    user = get_user_by_email(db, email)
    if user is None:
        security.verify_password(password, security.DUMMY_PASSWORD_HASH)
        raise AuthError("Email hoặc mật khẩu không đúng")
    if not security.verify_password(password, user.password_hash):
        raise AuthError("Email hoặc mật khẩu không đúng")
    if user.status != UserStatus.ACTIVE:
        raise AuthError("Tài khoản đã bị khóa", status_code=403)
    user.last_login_at = utcnow()
    return user


# ---------------------------------------------------------------- Quên mật khẩu
def create_password_reset_otp(db: Session, user: User) -> str:
    # Vô hiệu hóa các OTP cũ chưa dùng, chỉ OTP mới nhất có hiệu lực.
    db.execute(
        update(PasswordResetOtp)
        .where(PasswordResetOtp.user_id == user.id, PasswordResetOtp.used_at.is_(None))
        .values(used_at=utcnow())
    )
    otp = security.generate_otp()
    db.add(
        PasswordResetOtp(
            user_id=user.id,
            otp_hash=security.hash_otp(otp, user.email),
            expires_at=utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES),
        )
    )
    return otp


def reset_password_with_otp(db: Session, *, email: str, otp: str, new_password: str) -> None:
    invalid = AuthError("Mã OTP không đúng hoặc đã hết hạn", status_code=400)
    user = get_user_by_email(db, email)
    if user is None:
        raise invalid

    record = db.scalar(
        select(PasswordResetOtp)
        .where(PasswordResetOtp.user_id == user.id, PasswordResetOtp.used_at.is_(None))
        .order_by(PasswordResetOtp.created_at.desc())
    )
    now = utcnow()
    if record is None or as_aware(record.expires_at) <= now:
        raise invalid
    if record.attempts >= settings.OTP_MAX_ATTEMPTS:
        record.used_at = now
        raise invalid

    if not security.otp_matches(otp, user.email, record.otp_hash):
        record.attempts += 1
        if record.attempts >= settings.OTP_MAX_ATTEMPTS:
            record.used_at = now
        raise invalid

    record.used_at = now
    user.password_hash = security.hash_password(new_password)
    # Đổi mật khẩu -> đăng xuất mọi thiết bị.
    revoke_all_sessions(db, user.id)
