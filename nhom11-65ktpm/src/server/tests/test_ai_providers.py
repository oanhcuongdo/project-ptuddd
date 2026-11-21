"""Kiểm thử provider Claude / OpenAI bằng client giả (không gọi mạng)."""

import asyncio
import json
from types import SimpleNamespace

import pytest

from app.services.ai.providers import AIProviderError, AIRefusalError, ChatMessage
from app.services.ai.providers.anthropic_provider import FALLBACK_BETA, AnthropicProvider
from app.services.ai.providers.base import ReplyDelta, ReplyResult
from app.services.ai.providers.openai_provider import OpenAIProvider
from app.services.ai.schemas import ChatTurn, GrammarAnalysis

TURN = ChatTurn(
    reply_hanzi="你好！你叫什么名字？",
    reply_pinyin="nǐ hǎo! nǐ jiào shénme míngzi?",
    reply_translation_vi="Xin chào! Bạn tên là gì?",
    suggested_replies=[{"hanzi": "我叫小明。", "pinyin": "wǒ jiào xiǎo míng.", "translation_vi": "Tôi tên Tiểu Minh."}],
    conversation_should_end=False,
)
ANALYSIS = GrammarAnalysis(
    is_correct=True,
    corrected_sentence="我是学生。",
    corrected_pinyin="wǒ shì xuésheng.",
    components=[],
    errors=[],
    score=100,
    overall_comment_vi="Tốt lắm!",
    grammar_point_ids=[],
)
HISTORY = [ChatMessage("user", "[BẮT ĐẦU]"), ChatMessage("assistant", "你好！"), ChatMessage("user", "你好！")]


def _chunks(text: str, size: int = 4) -> list[str]:
    return [text[i : i + size] for i in range(0, len(text), size)]


async def _collect(agen):
    return [item async for item in agen]


# ---------------------------------------------------------------- Claude
class _FakeAnthropicStream:
    def __init__(self, chunks, final):
        self._chunks, self._final = chunks, final

    async def __aenter__(self):
        async def gen():
            for c in self._chunks:
                yield c

        self.text_stream = gen()
        return self

    async def __aexit__(self, *exc):
        return False

    async def get_final_message(self):
        return self._final


class FakeAnthropicClient:
    def __init__(self, final, parsed_final=None):
        self.calls: list[tuple[str, dict]] = []
        self._final = final
        self._parsed_final = parsed_final
        outer = self

        class Messages:
            def stream(self, **kwargs):
                outer.calls.append(("stream", kwargs))
                return _FakeAnthropicStream(_chunks(TURN.model_dump_json()), outer._final)

            async def parse(self, **kwargs):
                outer.calls.append(("parse", kwargs))
                return outer._parsed_final

        self.beta = SimpleNamespace(messages=Messages())


def _anthropic_message(parsed, stop_reason="end_turn"):
    usage = SimpleNamespace(
        input_tokens=50, output_tokens=40, cache_read_input_tokens=900, cache_creation_input_tokens=0
    )
    return SimpleNamespace(
        stop_reason=stop_reason, parsed_output=parsed, usage=usage, model="claude-opus-5-5"
    )


def test_anthropic_stream_reply_streams_hanzi_and_uses_caching_and_fallback():
    client = FakeAnthropicClient(_anthropic_message(TURN))
    provider = AnthropicProvider(client=client, model="claude-opus-5-5")
    items = asyncio.run(_collect(provider.stream_reply(lesson_context="CTX", history=HISTORY, cache_key="k")))

    deltas = "".join(i.text for i in items if isinstance(i, ReplyDelta))
    assert deltas == TURN.reply_hanzi
    result = items[-1]
    assert isinstance(result, ReplyResult) and result.turn == TURN
    assert result.usage.cache_read_tokens == 900

    _, kwargs = client.calls[0]
    assert kwargs["model"] == "claude-opus-5-5"
    assert kwargs["output_format"] is ChatTurn
    assert kwargs["output_config"] == {"effort": "low"}
    assert "thinking" not in kwargs  # Opus 5.5: thinking luôn bật (adaptive)
    # Khối ngữ cảnh bài học được cache, hướng dẫn chung đứng trước.
    assert kwargs["system"][1] == {"type": "text", "text": "CTX", "cache_control": {"type": "ephemeral"}}
    assert kwargs["messages"][-1]["content"][0]["cache_control"] == {"type": "ephemeral"}
    assert [m["role"] for m in kwargs["messages"]] == ["user", "assistant", "user"]
    assert kwargs["betas"] == [FALLBACK_BETA] and kwargs["fallbacks"] == "default"


def test_anthropic_haiku_has_no_server_side_fallback():
    client = FakeAnthropicClient(_anthropic_message(TURN))
    provider = AnthropicProvider(client=client, model="claude-haiku-5-5")
    asyncio.run(_collect(provider.stream_reply(lesson_context="CTX", history=HISTORY, cache_key="k")))
    kwargs = client.calls[0][1]
    assert "fallbacks" not in kwargs and "betas" not in kwargs


def test_anthropic_refusal_raises():
    client = FakeAnthropicClient(_anthropic_message(None, stop_reason="refusal"))
    provider = AnthropicProvider(client=client, model="claude-opus-5-5")
    with pytest.raises(AIRefusalError):
        asyncio.run(_collect(provider.stream_reply(lesson_context="C", history=HISTORY, cache_key="k")))


def test_anthropic_max_tokens_raises():
    client = FakeAnthropicClient(_anthropic_message(None, stop_reason="max_tokens"))
    provider = AnthropicProvider(client=client, model="claude-opus-5-5")
    with pytest.raises(AIProviderError):
        asyncio.run(_collect(provider.stream_reply(lesson_context="C", history=HISTORY, cache_key="k")))


def test_anthropic_grammar_uses_structured_output():
    client = FakeAnthropicClient(None, parsed_final=_anthropic_message(ANALYSIS))
    provider = AnthropicProvider(client=client, model="claude-opus-5-5")
    result = asyncio.run(
        provider.analyze_grammar(lesson_context="CTX", question="你是学生吗？", answer="我是学生。", cache_key="k")
    )
    assert result.analysis.score == 100
    kind, kwargs = client.calls[0]
    assert kind == "parse"
    assert kwargs["output_format"] is GrammarAnalysis
    assert kwargs["output_config"] == {"effort": "medium"}
    assert "我是学生。" in kwargs["messages"][0]["content"]


# ---------------------------------------------------------------- OpenAI
class _FakeOpenAIStream:
    def __init__(self, chunks, final):
        self._chunks, self._final = chunks, final

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    def __aiter__(self):
        async def gen():
            yield SimpleNamespace(type="chunk")
            for c in self._chunks:
                yield SimpleNamespace(type="content.delta", delta=c)

        return gen()

    async def get_final_completion(self):
        return self._final


def _openai_completion(parsed, refusal=None, finish_reason="stop"):
    message = SimpleNamespace(parsed=parsed, refusal=refusal)
    usage = SimpleNamespace(
        prompt_tokens=1000,
        completion_tokens=60,
        prompt_tokens_details=SimpleNamespace(cached_tokens=800),
    )
    return SimpleNamespace(
        choices=[SimpleNamespace(message=message, finish_reason=finish_reason)],
        usage=usage,
        model="gpt-5-mini",
    )


class FakeOpenAIClient:
    def __init__(self, final=None, parsed_final=None):
        self.calls: list[tuple[str, dict]] = []
        outer = self

        class Completions:
            def stream(self, **kwargs):
                outer.calls.append(("stream", kwargs))
                return _FakeOpenAIStream(_chunks(json.dumps(TURN.model_dump(), ensure_ascii=False)), final)

            async def parse(self, **kwargs):
                outer.calls.append(("parse", kwargs))
                return parsed_final

        self.chat = SimpleNamespace(completions=Completions())


def test_openai_stream_reply():
    client = FakeOpenAIClient(final=_openai_completion(TURN))
    provider = OpenAIProvider(client=client, model="gpt-5-mini")
    items = asyncio.run(_collect(provider.stream_reply(lesson_context="CTX", history=HISTORY, cache_key="k")))

    assert "".join(i.text for i in items if isinstance(i, ReplyDelta)) == TURN.reply_hanzi
    result = items[-1]
    assert result.turn == TURN
    assert result.usage.input_tokens == 200 and result.usage.cache_read_tokens == 800

    _, kwargs = client.calls[0]
    assert kwargs["response_format"] is ChatTurn
    assert kwargs["messages"][0]["role"] == "system" and kwargs["messages"][0]["content"].endswith("CTX")
    assert kwargs["prompt_cache_key"] == "k:chat"
    assert kwargs["stream_options"] == {"include_usage": True}
    assert kwargs["reasoning_effort"] == "low"


def test_openai_refusal_and_grammar():
    client = FakeOpenAIClient(
        final=_openai_completion(None, refusal="I can't"), parsed_final=_openai_completion(ANALYSIS)
    )
    provider = OpenAIProvider(client=client, model="gpt-5-mini")
    with pytest.raises(AIRefusalError):
        asyncio.run(_collect(provider.stream_reply(lesson_context="C", history=HISTORY, cache_key="k")))

    result = asyncio.run(
        provider.analyze_grammar(lesson_context="C", question=None, answer="我是学生。", cache_key="k")
    )
    assert result.analysis.corrected_sentence == "我是学生。"
    assert client.calls[-1][1]["response_format"] is GrammarAnalysis
    assert client.calls[-1][1]["reasoning_effort"] == "medium"
