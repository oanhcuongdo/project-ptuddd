import json

import pytest

from app.services.ai.json_stream import JsonStringFieldStreamer


def _feed_all(text: str, chunk_size: int, field: str = "reply_hanzi") -> str:
    streamer = JsonStringFieldStreamer(field)
    out = "".join(streamer.feed(text[i : i + chunk_size]) for i in range(0, len(text), chunk_size))
    assert streamer.done
    return out


@pytest.mark.parametrize("ensure_ascii", [False, True])
@pytest.mark.parametrize("chunk_size", [1, 2, 3, 5, 7, 1000])
def test_extracts_field_for_any_chunking(chunk_size, ensure_ascii):
    value = '你好！你叫"小明"吗？\n😀 tab\there \\ /'
    payload = json.dumps(
        {"reply_hanzi": value, "reply_pinyin": "nǐ hǎo", "suggested_replies": []},
        ensure_ascii=ensure_ascii,
    )
    assert _feed_all(payload, chunk_size) == value


def test_whitespace_around_colon_and_later_field_order():
    payload = '{ "other": "reply_hanzi", "reply_hanzi" :\n  "我是学生。" }'
    assert _feed_all(payload, 2) == "我是学生。"


def test_stops_after_field_and_ignores_rest():
    streamer = JsonStringFieldStreamer("reply_hanzi")
    assert streamer.feed('{"reply_hanzi": "好"') == "好"
    assert streamer.done
    assert streamer.feed(', "reply_pinyin": "hǎo"}') == ""


def test_emits_incrementally():
    streamer = JsonStringFieldStreamer("reply_hanzi")
    assert streamer.feed('{"reply_') == ""
    assert streamer.feed('hanzi": "你') == "你"
    assert streamer.feed("好") == "好"
    assert streamer.feed("\\") == ""  # escape bị cắt giữa 2 mảnh
    assert streamer.feed('n"') == "\n"
    assert streamer.done
