"""Logic thuần của Lộ trình học (không đụng DB, dễ test).

Luật (issue #29):
- Hoàn thành node khi điểm tốt nhất >= 70.
- Sao: >= 70: 1, >= 85: 2, >= 95: 3.
- Node đầu tiên luôn mở; node kế tiếp mở khi node ngay trước đã hoàn thành.
- Thứ tự tính xuyên các chặng (chặng 1 hết mới tới chặng 2).
"""

from collections.abc import Iterable, Mapping

PASS_SCORE = 70.0

STATUS_LOCKED = "locked"
STATUS_AVAILABLE = "available"
STATUS_COMPLETED = "completed"


def is_passed(score: float | None) -> bool:
    return score is not None and score >= PASS_SCORE


def stars_for_score(score: float | None) -> int:
    if not is_passed(score):
        return 0
    if score >= 95:
        return 3
    if score >= 85:
        return 2
    return 1


def compute_statuses(
    node_ids_in_order: Iterable[int],
    best_scores: Mapping[int, float | None],
) -> dict[int, str]:
    """Trạng thái từng node. `node_ids_in_order` đã sắp theo (chặng, thứ tự)."""
    result: dict[int, str] = {}
    previous_done = True  # node đầu tiên luôn được mở
    for node_id in node_ids_in_order:
        if is_passed(best_scores.get(node_id)):
            status = STATUS_COMPLETED
        elif previous_done:
            status = STATUS_AVAILABLE
        else:
            status = STATUS_LOCKED
        result[node_id] = status
        previous_done = status == STATUS_COMPLETED
    return result


def next_node_id(node_ids_in_order: Iterable[int], statuses: Mapping[int, str]) -> int | None:
    """Node nên học tiếp (node `available` đầu tiên); None nếu đã xong hết."""
    for node_id in node_ids_in_order:
        if statuses.get(node_id) == STATUS_AVAILABLE:
            return node_id
    return None