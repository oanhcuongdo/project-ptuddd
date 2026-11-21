def test_root(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "ChaiLish API"
    assert data["status"] == "online"


def test_health_check_reports_database(client):
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"


def test_swagger_docs_available(client):
    assert client.get("/docs").status_code == 200
    schema = client.get("/api/openapi.json").json()
    assert schema["info"]["title"] == "ChaiLish API"
    assert "/api/health" in schema["paths"]
