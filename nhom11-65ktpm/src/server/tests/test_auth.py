"""Kiểm thử API xác thực: đăng ký, đăng nhập, refresh, OTP, phân quyền, rate limit."""

import re
import uuid
from datetime import timedelta

import pytest

from app.core import security
from app.core.config import settings
from app.models import RefreshToken, User


# ---------------------------------------------------------------- Đăng ký
def test_register_returns_tokens_and_hashes_password(client, db_session):
    res = client.post(
        "/api/auth/register",
        json={"email": "An@Example.com", "password": "matkhau123", "full_name": " Nguyễn An "},
    )
    assert res.status_code == 201
    data = res.json()
    assert data["token_type"] == "bearer"
    assert data["access_token"] and data["refresh_token"]
    assert data["user"]["email"] == "an@example.com"
    assert data["user"]["full_name"] == "Nguyễn An"
    assert "password_hash" not in data["user"]

    user = db_session.query(User).one()
    assert user.password_hash.startswith("$2")  # bcrypt
    assert user.password_hash != "matkhau123"
    # Refresh token chỉ lưu dạng hash.
    stored = db_session.query(RefreshToken).one()
    assert stored.token_hash == security.hash_token(data["refresh_token"])


def test_register_duplicate_email_conflict(client, register_user):
    register_user(email="dup@example.com")
    res = client.post(
        "/api/auth/register",
        json={"email": "DUP@example.com", "password": "matkhau123", "full_name": "B"},
    )
    assert res.status_code == 409


@pytest.mark.parametrize("password", ["short1", "onlyletters", "12345678"])
def test_register_rejects_weak_password(client, password):
    res = client.post(
        "/api/auth/register",
        json={"email": "a@example.com", "password": password, "full_name": "A"},
    )
    assert res.status_code == 422


# ---------------------------------------------------------------- Đăng nhập
def test_login_success(client, register_user):
    register_user()
    res = client.post(
        "/api/auth/login", json={"email": "hoc@chailish.vn", "password": "matkhau123"}
    )
    assert res.status_code == 200
    assert res.json()["user"]["email"] == "hoc@chailish.vn"


@pytest.mark.parametrize(
    "email,password", [("hoc@chailish.vn", "saimatkhau1"), ("khong@tontai.vn", "matkhau123")]
)
def test_login_wrong_credentials_same_message(client, register_user, email, password):
    register_user()
    res = client.post("/api/auth/login", json={"email": email, "password": password})
    assert res.status_code == 401
    assert res.json()["detail"] == "Email hoặc mật khẩu không đúng"


def test_login_locked_account_forbidden(client, register_user, db_session):
    register_user()
    db_session.query(User).update({"status": "locked"})
    db_session.commit()
    res = client.post(
        "/api/auth/login", json={"email": "hoc@chailish.vn", "password": "matkhau123"}
    )
    assert res.status_code == 403


def test_login_brute_force_is_rate_limited(client, register_user):
    register_user()
    wrong = {"email": "hoc@chailish.vn", "password": "saimatkhau1"}
    for _ in range(settings.LOGIN_MAX_FAILURES):
        assert client.post("/api/auth/login", json=wrong).status_code == 401

    res = client.post("/api/auth/login", json=wrong)
    assert res.status_code == 429
    assert int(res.headers["Retry-After"]) > 0
    # Kể cả mật khẩu đúng cũng bị chặn cho tới khi hết cửa sổ thời gian.
    ok = {"email": "hoc@chailish.vn", "password": "matkhau123"}
    assert client.post("/api/auth/login", json=ok).status_code == 429


def test_successful_login_resets_failure_counter(client, register_user):
    register_user()
    wrong = {"email": "hoc@chailish.vn", "password": "saimatkhau1"}
    ok = {"email": "hoc@chailish.vn", "password": "matkhau123"}
    for _ in range(settings.LOGIN_MAX_FAILURES - 1):
        client.post("/api/auth/login", json=wrong)
    assert client.post("/api/auth/login", json=ok).status_code == 200
    assert client.post("/api/auth/login", json=wrong).status_code == 401


# ---------------------------------------------------------------- Refresh / logout
def test_refresh_rotates_token(client, register_user):
    tokens = register_user()
    res = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert res.status_code == 200
    new = res.json()
    assert new["access_token"] and new["refresh_token"] != tokens["refresh_token"]

    # Refresh token cũ đã bị thu hồi.
    again = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert again.status_code == 401
    # Token mới dùng được.
    assert (
        client.post("/api/auth/refresh", json={"refresh_token": new["refresh_token"]}).status_code
        == 200
    )


def test_refresh_expired_token(client, register_user, db_session):
    tokens = register_user()
    db_session.query(RefreshToken).update(
        {"expires_at": security.datetime.now(security.UTC) - timedelta(seconds=1)}
    )
    db_session.commit()
    res = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert res.status_code == 401


def test_refresh_invalid_token(client):
    res = client.post("/api/auth/refresh", json={"refresh_token": "khong-phai-token-that"})
    assert res.status_code == 401


def test_logout_revokes_refresh_token(client, register_user):
    tokens = register_user()
    assert (
        client.post("/api/auth/logout", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 204
    )
    res = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert res.status_code == 401


# ---------------------------------------------------------------- Bảo vệ API bằng Bearer token
def test_me_requires_token(client):
    res = client.get("/api/me")
    assert res.status_code == 401
    assert res.headers["WWW-Authenticate"] == "Bearer"


def test_me_with_valid_token(client, auth_headers):
    res = client.get("/api/me", headers=auth_headers)
    assert res.status_code == 200
    assert res.json()["email"] == "hoc@chailish.vn"


def test_me_rejects_expired_and_forged_tokens(client, register_user, db_session):
    register_user()
    user = db_session.query(User).one()
    expired = security.create_access_token(user.id, expires_delta=timedelta(seconds=-1))
    res = client.get("/api/me", headers={"Authorization": f"Bearer {expired}"})
    assert res.status_code == 401 and "hết hạn" in res.json()["detail"]

    import jwt

    forged = jwt.encode(
        {"sub": str(user.id), "type": "access", "exp": 9999999999}, "khoa-gia-mao-dai-du-32-byte-cho-hs256!", algorithm="HS256"
    )
    assert client.get("/api/me", headers={"Authorization": f"Bearer {forged}"}).status_code == 401


def test_token_of_deleted_user_rejected(client):
    token = security.create_access_token(uuid.uuid4())
    assert client.get("/api/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401


def test_get_owned_or_404_blocks_other_users_data(client, register_user, db_session):
    from fastapi import HTTPException

    from app.api.deps import get_owned_or_404
    from app.models import AiConversation

    register_user(email="a@example.com")
    register_user(email="b@example.com")
    a, b = db_session.query(User).order_by(User.email).all()
    conv = AiConversation(user_id=a.id, model="test")
    db_session.add(conv)
    db_session.commit()

    assert get_owned_or_404(db_session, AiConversation, conv.id, a) is conv
    with pytest.raises(HTTPException) as exc:
        get_owned_or_404(db_session, AiConversation, conv.id, b)
    assert exc.value.status_code == 404


# ---------------------------------------------------------------- Quên mật khẩu (OTP)
@pytest.fixture()
def captured_otp(monkeypatch):
    sent: dict[str, str] = {}

    def fake_send(to, full_name, otp):
        sent[to] = otp

    monkeypatch.setattr("app.api.routes.auth.send_password_reset_otp", fake_send)
    return sent


def test_forgot_password_same_response_for_unknown_email(client, register_user, captured_otp):
    register_user()
    known = client.post("/api/auth/forgot-password", json={"email": "hoc@chailish.vn"})
    unknown = client.post("/api/auth/forgot-password", json={"email": "ai@do.vn"})
    assert known.status_code == unknown.status_code == 202
    assert known.json() == unknown.json()
    assert re.fullmatch(r"\d{6}", captured_otp["hoc@chailish.vn"])
    assert "ai@do.vn" not in captured_otp


def test_reset_password_with_otp_flow(client, register_user, captured_otp):
    tokens = register_user()
    client.post("/api/auth/forgot-password", json={"email": "hoc@chailish.vn"})
    otp = captured_otp["hoc@chailish.vn"]

    res = client.post(
        "/api/auth/reset-password",
        json={"email": "hoc@chailish.vn", "otp": otp, "new_password": "matkhaumoi456"},
    )
    assert res.status_code == 200

    # Mật khẩu cũ hết hiệu lực, mật khẩu mới đăng nhập được.
    old = {"email": "hoc@chailish.vn", "password": "matkhau123"}
    new = {"email": "hoc@chailish.vn", "password": "matkhaumoi456"}
    assert client.post("/api/auth/login", json=old).status_code == 401
    assert client.post("/api/auth/login", json=new).status_code == 200
    # Mọi phiên cũ bị đăng xuất.
    res = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert res.status_code == 401
    # OTP chỉ dùng được một lần.
    reuse = client.post(
        "/api/auth/reset-password",
        json={"email": "hoc@chailish.vn", "otp": otp, "new_password": "matkhaukhac789"},
    )
    assert reuse.status_code == 400


def test_reset_password_otp_locked_after_max_attempts(client, register_user, captured_otp):
    register_user()
    client.post("/api/auth/forgot-password", json={"email": "hoc@chailish.vn"})
    otp = captured_otp["hoc@chailish.vn"]
    wrong_otp = "000000" if otp != "000000" else "111111"

    for _ in range(settings.OTP_MAX_ATTEMPTS):
        res = client.post(
            "/api/auth/reset-password",
            json={"email": "hoc@chailish.vn", "otp": wrong_otp, "new_password": "matkhaumoi456"},
        )
        assert res.status_code == 400

    # Hết lượt thử: OTP đúng cũng không dùng được nữa.
    res = client.post(
        "/api/auth/reset-password",
        json={"email": "hoc@chailish.vn", "otp": otp, "new_password": "matkhaumoi456"},
    )
    assert res.status_code == 400


def test_new_otp_invalidates_previous(client, register_user, captured_otp):
    register_user()
    client.post("/api/auth/forgot-password", json={"email": "hoc@chailish.vn"})
    first = captured_otp["hoc@chailish.vn"]
    client.post("/api/auth/forgot-password", json={"email": "hoc@chailish.vn"})
    second = captured_otp["hoc@chailish.vn"]
    if first == second:
        pytest.skip("Trùng OTP ngẫu nhiên (xác suất 1/10^6)")
    res = client.post(
        "/api/auth/reset-password",
        json={"email": "hoc@chailish.vn", "otp": first, "new_password": "matkhaumoi456"},
    )
    assert res.status_code == 400


def test_public_auth_endpoints_rate_limited_per_ip(client):
    body = {"email": "spam@example.com"}
    for _ in range(settings.AUTH_REQUESTS_PER_MINUTE):
        assert client.post("/api/auth/forgot-password", json=body).status_code == 202
    assert client.post("/api/auth/forgot-password", json=body).status_code == 429


def test_spoofed_forwarded_for_does_not_bypass_login_limit(client, register_user):
    register_user()
    wrong = {"email": "hoc@chailish.vn", "password": "saimatkhau1"}
    for i in range(settings.LOGIN_MAX_FAILURES):
        client.post("/api/auth/login", json=wrong, headers={"X-Forwarded-For": f"10.0.0.{i}"})
    res = client.post("/api/auth/login", json=wrong, headers={"X-Forwarded-For": "10.9.9.9"})
    assert res.status_code == 429
