"""Cấu hình ứng dụng đọc từ biến môi trường / file .env (pydantic-settings)."""

from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # --- Ứng dụng ---
    PROJECT_NAME: str = "ChaiLish API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api"
    ENVIRONMENT: str = "development"  # development | test | production
    DEBUG: bool = False
    CORS_ORIGINS: list[str] = ["*"]

    # --- Cơ sở dữ liệu ---
    DATABASE_URL: str = "postgresql+psycopg2://postgres:postgres@localhost:5432/chailish_db"
    DB_ECHO: bool = False

    # --- Bảo mật / JWT ---
    SECRET_KEY: str = "chailish_secret_key_development_only_2026"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    PASSWORD_MIN_LENGTH: int = 8

    # --- Quên mật khẩu (OTP qua email) ---
    OTP_EXPIRE_MINUTES: int = 10
    OTP_MAX_ATTEMPTS: int = 5
    SMTP_HOST: str = ""  # để trống: OTP chỉ được ghi ra log (môi trường dev)
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "ChaiLish <no-reply@chailish.app>"
    SMTP_USE_TLS: bool = True

    # --- Rate limiting chống dò mật khẩu ---
    RATE_LIMIT_ENABLED: bool = True
    LOGIN_MAX_FAILURES: int = 5  # số lần sai tối đa / cửa sổ
    LOGIN_FAILURE_WINDOW_SECONDS: int = 15 * 60
    AUTH_REQUESTS_PER_MINUTE: int = 20  # register / refresh / forgot-password theo IP

    # --- Trợ lý ôn bài AI ---
    AI_PROVIDER: str = "anthropic"  # anthropic | openai
    # Claude: mặc định Opus 5.5 (chất lượng phân tích ngữ pháp tốt nhất),
    # đổi sang "claude-haiku-5-5" để giảm chi phí chỉ bằng cấu hình.
    ANTHROPIC_API_KEY: str = ""
    ANTHROPIC_MODEL: str = "claude-opus-5-5"
    # Server-side fallback khi model từ chối (refusal) — chỉ hỗ trợ Opus 5.5 / Sonnet 5.5 / Fable.
    ANTHROPIC_REFUSAL_FALLBACK: bool = True
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-5-mini"
    OPENAI_BASE_URL: str = ""  # để trống = API chính thức của OpenAI
    # Gửi reasoning_effort (chỉ model suy luận hỗ trợ). Tắt nếu dùng model không hỗ trợ.
    OPENAI_REASONING_EFFORT_ENABLED: bool = True
    # Múi giờ tính "mỗi ngày" cho giới hạn lượt dùng AI.
    AI_LIMIT_TIMEZONE: str = "Asia/Ho_Chi_Minh"
    # Độ sâu suy luận: hội thoại cần nhanh, phân tích ngữ pháp cần kỹ hơn.
    AI_CHAT_EFFORT: str = "low"
    AI_GRAMMAR_EFFORT: str = "medium"
    AI_MAX_OUTPUT_TOKENS: int = 4096
    AI_REQUEST_TIMEOUT_SECONDS: float = 90.0
    # Giới hạn chống lạm dụng / kiểm soát chi phí
    AI_DAILY_MESSAGE_LIMIT: int = 40  # số câu trả lời gửi AI mỗi người mỗi ngày
    AI_DAILY_CONVERSATION_LIMIT: int = 10
    AI_MAX_TURNS: int = 8  # 5-8 lượt mỗi phiên theo đề cương
    AI_MAX_MESSAGE_CHARS: int = 120
    # Giá USD / 1 triệu token cho model không có trong bảng giá mặc định (vd. OpenAI).
    AI_PRICE_INPUT_PER_MTOK: float | None = None
    AI_PRICE_OUTPUT_PER_MTOK: float | None = None

    # --- Dịch vụ bên ngoài khác ---
    AZURE_SPEECH_KEY: str = ""
    AZURE_SPEECH_REGION: str = "southeastasia"

    @model_validator(mode="after")
    def _check_production_secret(self) -> "Settings":
        if self.ENVIRONMENT == "production" and (
            self.SECRET_KEY.endswith("development_only_2026") or len(self.SECRET_KEY) < 32
        ):
            raise ValueError("SECRET_KEY phải được đặt (>= 32 ký tự) khi ENVIRONMENT=production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
