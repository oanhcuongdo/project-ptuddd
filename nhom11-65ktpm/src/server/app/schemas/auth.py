import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.config import settings


def _check_password_strength(value: str) -> str:
    if len(value) < settings.PASSWORD_MIN_LENGTH:
        raise ValueError(f"Mật khẩu phải có ít nhất {settings.PASSWORD_MIN_LENGTH} ký tự")
    if not any(c.isalpha() for c in value) or not any(c.isdigit() for c in value):
        raise ValueError("Mật khẩu phải gồm cả chữ và số")
    return value


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(max_length=128)
    full_name: str = Field(min_length=1, max_length=120)
    device_name: str | None = Field(default=None, max_length=120)

    _password = field_validator("password")(_check_password_strength)

    @field_validator("full_name")
    @classmethod
    def _strip_name(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Họ tên không được để trống")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
    device_name: str | None = Field(default=None, max_length=120)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=10, max_length=255)


class LogoutRequest(RefreshRequest):
    pass


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(pattern=r"^\d{6}$")
    new_password: str = Field(max_length=128)

    _password = field_validator("new_password")(_check_password_strength)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    display_name: str | None
    avatar_url: str | None
    level: str
    daily_goal_minutes: int
    xp_total: int
    placement_done: bool
    created_at: datetime


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(description="Số giây access token còn hiệu lực")


class AuthResponse(TokenPair):
    user: UserOut


class MessageResponse(BaseModel):
    message: str
