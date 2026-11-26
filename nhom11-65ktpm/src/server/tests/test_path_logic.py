
from app.services.path_logic import (
    STATUS_AVAILABLE,
    STATUS_COMPLETED,
    STATUS_LOCKED,
    compute_statuses,
    is_passed,
    next_node_id,
    stars_for_score,
)


def test_score_boundaries():
    assert is_passed(69) is False
    assert is_passed(70) is True

    assert stars_for_score(69) == 0
    assert stars_for_score(70) == 1
    assert stars_for_score(84) == 1
    assert stars_for_score(85) == 2
    assert stars_for_score(94) == 2
    assert stars_for_score(95) == 3


def test_first_node_is_available():
    statuses = compute_statuses([1, 2, 3], {})

    assert statuses == {
        1: STATUS_AVAILABLE,
        2: STATUS_LOCKED,
        3: STATUS_LOCKED,
    }


def test_next_node_unlocks_after_previous_passed():
    statuses = compute_statuses(
        [1, 2, 3],
        {1: 80},
    )

    assert statuses == {
        1: STATUS_COMPLETED,
        2: STATUS_AVAILABLE,
        3: STATUS_LOCKED,
    }


def test_failed_node_keeps_following_nodes_locked():
    statuses = compute_statuses(
        [1, 2, 3],
        {1: 69},
    )

    assert statuses == {
        1: STATUS_AVAILABLE,
        2: STATUS_LOCKED,
        3: STATUS_LOCKED,
    }


def test_unlock_order_across_stages():
    # Chặng 1: node 1, 2
    # Chặng 2: node 3, 4
    statuses = compute_statuses(
        [1, 2, 3, 4],
        {
            1: 80,
            2: 90,
            3: 69,
        },
    )

    assert statuses == {
        1: STATUS_COMPLETED,
        2: STATUS_COMPLETED,
        3: STATUS_AVAILABLE,
        4: STATUS_LOCKED,
    }


def test_next_node_id():
    statuses = {
        1: STATUS_COMPLETED,
        2: STATUS_COMPLETED,
        3: STATUS_AVAILABLE,
        4: STATUS_LOCKED,
    }

    assert next_node_id([1, 2, 3, 4], statuses) == 3


def test_next_node_id_returns_none_when_all_completed():
    statuses = {
        1: STATUS_COMPLETED,
        2: STATUS_COMPLETED,
    }

    assert next_node_id([1, 2], statuses) is None
