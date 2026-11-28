from functools import lru_cache

from app.core.config import settings
from app.services.ai.providers.base import (
    AIProvider,
    AIProviderError,
    AIRefusalError,
    ChatMessage,
    GrammarResult,
    ReplyDelta,
    ReplyResult,
)

SUPPORTED_PROVIDERS = ("anthropic", "openai")


def provider_configured(name: str | None = None) -> bool:
    name = name or settings.AI_PROVIDER
    if name == "anthropic":
        return bool(settings.ANTHROPIC_API_KEY)
    if name == "openai":
        return bool(settings.OPENAI_API_KEY)
    return False


@lru_cache
def build_provider(name: str) -> AIProvider:
    """Tạo (một lần) client của nhà cung cấp AI theo tên."""
    if name == "anthropic":
        from app.services.ai.providers.anthropic_provider import AnthropicProvider

        return AnthropicProvider()
    if name == "openai":
        from app.services.ai.providers.openai_provider import OpenAIProvider

        return OpenAIProvider()
    raise ValueError(f"AI_PROVIDER không hợp lệ: {name!r} (hỗ trợ: {SUPPORTED_PROVIDERS})")


__all__ = [
    "AIProvider",
    "AIProviderError",
    "AIRefusalError",
    "ChatMessage",
    "GrammarResult",
    "ReplyDelta",
    "ReplyResult",
    "SUPPORTED_PROVIDERS",
    "build_provider",
    "provider_configured",
]
