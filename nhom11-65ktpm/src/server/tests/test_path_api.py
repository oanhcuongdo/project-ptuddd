
import uuid
from datetime import UTC, datetime

from app.models import Course, Lesson, PathNode, PathStage


def _create_path(db_session):
    """Tạo một chặng gồm hai bài học liên tiếp."""
    course = Course(
        code="TEST_HSK1",
        title="HSK 1",
        order_index=1,
    )
    db_session.add(course)
    db_session.flush()

    lesson1 = Lesson(
        course_id=course.id,
        code="test-lesson-01",
        order_index=1,
        title="Bài học 1",
    )
    lesson2 = Lesson(
        course_id=course.id,
        code="test-lesson-02",
        order_index=2,
        title="Bài học 2",
    )
    db_session.add_all([lesson1, lesson2])
    db_session.flush()

    stage = PathStage(
        code="TEST_STAGE",
        order_index=1,
        title="Chặng kiểm thử",
        level="HSK1",
    )
    db_session.add(stage)
    db_session.flush()

    node1 = PathNode(
        stage_id=stage.id,
        lesson_id=lesson1.id,
        order_index=1,
        node_type="lesson",
        title="Bài học 1",
    )
    node2 = PathNode(
        stage_id=stage.id,
        lesson_id=lesson2.id,
        order_index=2,
        node_type="lesson",
        title="Bài học 2",
    )
    db_session.add_all([node1, node2])
    db_session.commit()

    return node1, node2


def test_lesson_completed_unlocks_next_node(
    client, db_session, auth_headers
):
    node1, node2 = _create_path(db_session)

    response = client.post(
        "/api/events",
        headers=auth_headers,
        json={
            "events": [
                {
                    "id": str(uuid.uuid4()),
                    "type": "lesson_completed",
                    "occurred_at": datetime.now(UTC).isoformat(),
                    "score": 80,
                    "ref_id": "test-lesson-01",
                }
            ]
        },
    )

    assert response.status_code == 200, response.text
    assert response.json()["accepted"] == 1

    path_response = client.get("/api/path", headers=auth_headers)

    assert path_response.status_code == 200, path_response.text

    nodes = [
        node
        for stage in path_response.json()["stages"]
        for node in stage["nodes"]
    ]
    nodes_by_id = {node["id"]: node for node in nodes}

    assert nodes_by_id[node1.id]["status"] == "completed"
    assert nodes_by_id[node1.id]["stars"] == 1
    assert nodes_by_id[node2.id]["status"] == "available"


def test_complete_locked_node_returns_409(
    client, db_session, auth_headers
):
    node1, node2 = _create_path(db_session)

    # Chuyển node thứ hai thành node kiểm tra, không gắn với bài học.
    node2.lesson_id = None
    node2.node_type = "quiz"
    db_session.commit()

    response = client.post(
        f"/api/path/nodes/{node2.id}/complete",
        headers=auth_headers,
        json={"score": 80},
    )

    assert response.status_code == 409


def test_complete_lesson_node_returns_400(
    client, db_session, auth_headers
):
    node1, node2 = _create_path(db_session)

    response = client.post(
        f"/api/path/nodes/{node1.id}/complete",
        headers=auth_headers,
        json={"score": 80},
    )

    assert response.status_code == 400
