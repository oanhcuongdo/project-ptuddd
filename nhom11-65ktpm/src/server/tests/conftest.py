"""Fixture dùng chung: CSDL SQLite in-memory, mỗi test một CSDL sạch."""

import os

os.environ.setdefault("ENVIRONMENT", "test")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.rate_limit import auth_requests, login_failures
from app.db.session import get_db, get_session_factory
from app.main import app
from app.models import Base


@pytest.fixture()
def engine():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def _enable_fk(dbapi_conn, _):
        dbapi_conn.execute("PRAGMA foreign_keys=ON")

    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture()
def db_session(engine):
    session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(db_session):
    factory = sessionmaker(bind=db_session.get_bind(), autoflush=False, expire_on_commit=False)

    def _override_get_db():
        # Mỗi request một phiên riêng giống môi trường thật.
        session = factory()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = _override_get_db
    app.dependency_overrides[get_session_factory] = lambda: factory
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def _reset_rate_limiters():
    login_failures.clear()
    auth_requests.clear()
    yield


@pytest.fixture()
def register_user(client):
    """Đăng ký nhanh một tài khoản, trả về JSON (token + user)."""

    def _register(email="hoc@chailish.vn", password="matkhau123", full_name="Người Học"):
        res = client.post(
            "/api/auth/register",
            json={"email": email, "password": password, "full_name": full_name},
        )
        assert res.status_code == 201, res.text
        return res.json()

    return _register


@pytest.fixture()
def auth_headers(register_user):
    data = register_user()
    return {"Authorization": f"Bearer {data['access_token']}"}
