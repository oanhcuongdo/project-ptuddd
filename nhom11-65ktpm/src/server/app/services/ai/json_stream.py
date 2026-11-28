"""Tách dần giá trị một trường chuỗi JSON khi model đang stream structured output.

Model trả về JSON như `{"reply_hanzi": "你好！你叫什么名字？", "reply_pinyin": ...}`
theo từng mảnh nhỏ. `JsonStringFieldStreamer` nhận từng mảnh và trả ra phần chữ
mới của trường cần theo dõi, để app hiển thị hiệu ứng gõ chữ ngay lập tức.
"""

import json

_SIMPLE_ESCAPES = {
    '"': '"',
    "\\": "\\",
    "/": "/",
    "b": "\b",
    "f": "\f",
    "n": "\n",
    "r": "\r",
    "t": "\t",
}


class JsonStringFieldStreamer:
    def __init__(self, field: str) -> None:
        self._key = json.dumps(field)  # '"reply_hanzi"'
        self._buffer = ""
        self._pos = 0  # vị trí đã xử lý trong buffer
        self._state = "seek_key"  # seek_key -> seek_colon -> seek_quote -> in_string -> done
        self._pending_high_surrogate: int | None = None

    @property
    def done(self) -> bool:
        return self._state == "done"

    def feed(self, chunk: str) -> str:
        """Nạp thêm một mảnh JSON, trả về phần ký tự mới giải mã được của trường."""
        if self._state == "done":
            return ""
        self._buffer += chunk
        out: list[str] = []
        buf = self._buffer

        while self._pos < len(buf) and self._state != "done":
            if self._state == "seek_key":
                idx = buf.find(self._key, self._pos)
                if idx < 0:
                    # Giữ lại đuôi có thể là phần đầu của key bị cắt giữa 2 mảnh.
                    self._pos = max(self._pos, len(buf) - len(self._key) + 1)
                    break
                self._pos = idx + len(self._key)
                self._state = "seek_colon"
            elif self._state in ("seek_colon", "seek_quote"):
                ch = buf[self._pos]
                if ch.isspace():
                    self._pos += 1
                elif self._state == "seek_colon" and ch == ":":
                    self._pos += 1
                    self._state = "seek_quote"
                elif self._state == "seek_quote" and ch == '"':
                    self._pos += 1
                    self._state = "in_string"
                else:
                    # Không phải dạng "key": "..." -> có thể key nằm trong một chuỗi khác.
                    self._state = "seek_key"
            else:  # in_string
                ch = buf[self._pos]
                if ch == '"':
                    self._pos += 1
                    self._state = "done"
                elif ch == "\\":
                    if self._pos + 1 >= len(buf):
                        break  # chờ ký tự escape ở mảnh sau
                    esc = buf[self._pos + 1]
                    if esc == "u":
                        if self._pos + 6 > len(buf):
                            break  # chờ đủ 4 chữ số hex
                        code = int(buf[self._pos + 2 : self._pos + 6], 16)
                        self._pos += 6
                        out.append(self._decode_codepoint(code))
                    else:
                        out.append(_SIMPLE_ESCAPES.get(esc, esc))
                        self._pos += 2
                else:
                    out.append(ch)
                    self._pos += 1

        return "".join(out)

    def _decode_codepoint(self, code: int) -> str:
        # Ký tự ngoài BMP được mã hóa thành cặp surrogate \\uD8xx\\uDCxx.
        if 0xD800 <= code <= 0xDBFF:
            self._pending_high_surrogate = code
            return ""
        if 0xDC00 <= code <= 0xDFFF and self._pending_high_surrogate is not None:
            high = self._pending_high_surrogate
            self._pending_high_surrogate = None
            return chr(0x10000 + ((high - 0xD800) << 10) + (code - 0xDC00))
        return chr(code)
