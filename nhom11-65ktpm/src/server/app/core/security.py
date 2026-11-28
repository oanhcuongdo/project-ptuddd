"""Băm mật khẩu (bcrypt), phát hành / kiểm tra JWT và refresh token."""

import hashlib
import hmac
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import bcrypt
import jwt

from app.core.config import settings

ACCESS_TOKEN_TYPE = "access"


# ---------------------------------------------------------------- Mật khẩu
def _to_bcrypt_bytes(password: str) -> bytes:
    # bcrypt chỉ dùng 72 byte đầu; cắt rõ ràng để bcrypt>=4.1 không báo lỗi.
    return password.encode("utf-8")[:72]


def hash_password(password: str) -> str:
    return bcrypt.hashpw(_to_bcrypt_bytes(password), bcrypt.gensalt()).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(_to_bcrypt_bytes(password), password_hash.encode("ascii"))
    except ValueError:
        return False


# Hash giả để so sánh khi email không tồn tại -> thời gian phản hồi như nhau,
# tránh lộ email nào đã đăng ký (user enumeration qua timing).
DUMMY_PASSWORD_HASH = hash_password(secrets.token_urlsafe(16))


# ---------------------------------------------------------------- Access token (JWT)
class TokenError(Exception):
    """Token không hợp lệ hoặc đã hết hạn."""


def create_access_token(user_id: uuid.UUID, expires_delta: timedelta | None = None) -> str:
    now = datetime.now(UTC)
    expire = now + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    payload = {
        "sub": str(user_id),
        "type": ACCESS_TOKEN_TYPE,
        "iat": now,
        "exp": expire,
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> uuid.UUID:
    """Trả về user_id trong token, ném `TokenError` nếu token sai/hết hạn."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"require": ["exp", "sub", "type"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise TokenError("Access token đã hết hạn") from exc
    except jwt.PyJWTError as exc:
        raise TokenError("Access token không hợp lệ") from exc

    if payload.get("type") != ACCESS_TOKEN_TYPE:
        raise TokenError("Sai loại token")
    try:
        return uuid.UUID(payload["sub"])
    except (ValueError, TypeError) as exc:
        raise TokenError("Access token không hợp lệ") from exc


# ---------------------------------------------------------------- Refresh token / OTP
def generate_refresh_token() -> str:
    """Refresh token là chuỗi ngẫu nhiên (opaque); server chỉ lưu SHA-256 của nó."""
    return secrets.token_urlsafe(48)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def generate_otp(length: int = 6) -> str:
    return "".join(secrets.choice("0123456789") for _ in range(length))


def hash_otp(otp: str, email: str) -> str:
    # Gắn với email + SECRET_KEY để không dò ngược được OTP 6 số từ CSDL.
    msg = f"{email.lower()}:{otp}".encode()
    return hmac.new(settings.SECRET_KEY.encode(), msg, hashlib.sha256).hexdigest()


def otp_matches(otp: str, email: str, otp_hash: str) -> bool:
    return hmac.compare_digest(hash_otp(otp, email), otp_hash)
