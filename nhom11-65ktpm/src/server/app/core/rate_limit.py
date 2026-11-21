"""Rate limiting đơn giản theo cửa sổ trượt, lưu trong bộ nhớ tiến trình.

Đủ cho một instance uvicorn (đồ án). Khi chạy nhiều worker/instance cần chuyển
sang Redis để các tiến trình dùng chung bộ đếm.
"""

import math
import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request, status

from app.core.config import settings


class SlidingWindowLimiter:
    def __init__(self, limit: int, window_seconds: int) -> None:
        self.limit = limit
        self.window = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def _prune(self, key: str, now: float) -> deque[float]:
        hits = self._hits[key]
        while hits and hits[0] <= now - self.window:
            hits.popleft()
        return hits

    def retry_after(self, key: str) -> int:
        """Số giây phải chờ nếu `key` đã vượt giới hạn, 0 nếu còn được phép."""
        now = time.monotonic()
        with self._lock:
            hits = self._prune(key, now)
            if len(hits) < self.limit:
                return 0
            return max(1, math.ceil(hits[0] + self.window - now))

    def hit(self, key: str) -> None:
        with self._lock:
            self._hits[key].append(time.monotonic())

    def reset(self, key: str) -> None:
        with self._lock:
            self._hits.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._hits.clear()


# Số lần đăng nhập SAI theo (IP, email) — đăng nhập đúng sẽ xóa bộ đếm.
login_failures = SlidingWindowLimiter(
    settings.LOGIN_MAX_FAILURES, settings.LOGIN_FAILURE_WINDOW_SECONDS
)
# Tổng số request tới các API xác thực công khai theo IP.
auth_requests = SlidingWindowLimiter(settings.AUTH_REQUESTS_PER_MINUTE, 60)


def client_ip(request: Request) -> str:
    # Sau Nginx, X-Real-IP luôn được ghi đè bằng $remote_addr nên tin được.
    # KHÔNG lấy phần tử đầu của X-Forwarded-For vì client tự gửi header đó được
    # (giả mạo IP để né rate limit).
    real_ip = request.headers.get("x-real-ip")
    if real_ip:
        return real_ip.strip()
    return request.client.host if request.client else "?"


def raise_too_many(retry_after: int, detail: str) -> None:
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail=detail,
        headers={"Retry-After": str(retry_after)},
    )


def limit_auth_requests(request: Request) -> None:
    """Dependency gắn vào các route auth công khai."""
    if not settings.RATE_LIMIT_ENABLED:
        return
    key = f"{client_ip(request)}:{request.url.path}"
    wait = auth_requests.retry_after(key)
    if wait:
        raise_too_many(wait, "Bạn thao tác quá nhanh, vui lòng thử lại sau.")
    auth_requests.hit(key)
