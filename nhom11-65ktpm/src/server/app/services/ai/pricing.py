"""Ước tính chi phí gọi AI để ghi nhận theo từng phiên / tin nhắn."""

from dataclasses import dataclass

from app.core.config import settings


@dataclass(frozen=True)
class ModelPrice:
    input_per_mtok: float
    output_per_mtok: float
    cache_read_per_mtok: float
    cache_write_per_mtok: float


# Bảng giá Claude (USD / 1 triệu token). Ghi cache = 1.25x giá input (TTL 5 phút).
KNOWN_PRICES: dict[str, ModelPrice] = {
    "claude-opus-5-5": ModelPrice(4.00, 20.00, 0.20, 5.00),
    "claude-sonnet-5-5": ModelPrice(2.00, 10.00, 0.10, 2.50),
    "claude-haiku-5-5": ModelPrice(0.10, 0.50, 0.01, 0.125),
}


@dataclass
class Usage:
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_write_tokens: int = 0

    def __add__(self, other: "Usage") -> "Usage":
        return Usage(
            self.input_tokens + other.input_tokens,
            self.output_tokens + other.output_tokens,
            self.cache_read_tokens + other.cache_read_tokens,
            self.cache_write_tokens + other.cache_write_tokens,
        )


def price_for(model: str) -> ModelPrice | None:
    if settings.AI_PRICE_INPUT_PER_MTOK is not None and settings.AI_PRICE_OUTPUT_PER_MTOK is not None:
        inp, out = settings.AI_PRICE_INPUT_PER_MTOK, settings.AI_PRICE_OUTPUT_PER_MTOK
        return ModelPrice(inp, out, inp, inp)
    return KNOWN_PRICES.get(model)


def estimate_cost_usd(model: str, usage: Usage) -> float:
    price = price_for(model)
    if price is None:
        return 0.0
    total = (
        usage.input_tokens * price.input_per_mtok
        + usage.output_tokens * price.output_per_mtok
        + usage.cache_read_tokens * price.cache_read_per_mtok
        + usage.cache_write_tokens * price.cache_write_per_mtok
    )
    return round(total / 1_000_000, 6)
