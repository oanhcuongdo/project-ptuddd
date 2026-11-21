from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, Response, status

from app.api.deps import DbSession
from app.core.config import settings
from app.core.rate_limit import client_ip, limit_auth_requests, login_failures, raise_too_many
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    MessageResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenPair,
    UserOut,
)
from app.services import auth_service
from app.services.auth_service import AuthError
from app.services.email import send_password_reset_otp

router = APIRouter(prefix="/auth", tags=["auth"])

EXPIRES_IN = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60


def _http_error(exc: AuthError) -> HTTPException:
    headers = {"WWW-Authenticate": "Bearer"} if exc.status_code == 401 else None
    return HTTPException(status_code=exc.status_code, detail=exc.message, headers=headers)


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản (băm mật khẩu bằng bcrypt)",
    dependencies=[Depends(limit_auth_requests)],
)
def register(body: RegisterRequest, request: Request, db: DbSession) -> AuthResponse:
    try:
        user = auth_service.register_user(
            db, email=body.email, password=body.password, full_name=body.full_name
        )
    except AuthError as exc:
        raise _http_error(exc) from exc
    access, refresh = auth_service.issue_token_pair(
        db,
        user,
        device_name=body.device_name,
        user_agent=request.headers.get("user-agent"),
        ip_address=client_ip(request),
    )
    db.commit()
    db.refresh(user)
    return AuthResponse(
        access_token=access,
        refresh_token=refresh,
        expires_in=EXPIRES_IN,
        user=UserOut.model_validate(user),
    )


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Đăng nhập, trả về access token và refresh token",
    responses={429: {"description": "Đăng nhập sai quá nhiều lần"}},
)
def login(body: LoginRequest, request: Request, db: DbSession) -> AuthResponse:
    ip = client_ip(request)
    key = f"{ip}:{auth_service.normalize_email(body.email)}"
    if settings.RATE_LIMIT_ENABLED:
        wait = login_failures.retry_after(key)
        if wait:
            raise_too_many(wait, f"Đăng nhập sai quá nhiều lần. Thử lại sau {wait} giây.")

    try:
        user = auth_service.authenticate(db, body.email, body.password)
    except AuthError as exc:
        if exc.status_code == 401:
            login_failures.hit(key)
        raise _http_error(exc) from exc

    login_failures.reset(key)
    access, refresh = auth_service.issue_token_pair(
        db,
        user,
        device_name=body.device_name,
        user_agent=request.headers.get("user-agent"),
        ip_address=ip,
    )
    db.commit()
    return AuthResponse(
        access_token=access,
        refresh_token=refresh,
        expires_in=EXPIRES_IN,
        user=UserOut.model_validate(user),
    )


@router.post(
    "/refresh",
    response_model=TokenPair,
    summary="Cấp access token mới (refresh token cũ bị thu hồi, trả refresh token mới)",
    dependencies=[Depends(limit_auth_requests)],
)
def refresh(body: RefreshRequest, request: Request, db: DbSession) -> TokenPair:
    try:
        access, new_refresh = auth_service.rotate_refresh_token(
            db,
            body.refresh_token,
            user_agent=request.headers.get("user-agent"),
            ip_address=client_ip(request),
        )
    except AuthError as exc:
        db.rollback()
        raise _http_error(exc) from exc
    db.commit()
    return TokenPair(access_token=access, refresh_token=new_refresh, expires_in=EXPIRES_IN)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Đăng xuất: thu hồi refresh token của thiết bị hiện tại",
)
def logout(body: LogoutRequest, db: DbSession) -> Response:
    auth_service.revoke_refresh_token(db, body.refresh_token)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Gửi mã OTP đặt lại mật khẩu qua email",
    dependencies=[Depends(limit_auth_requests)],
)
def forgot_password(
    body: ForgotPasswordRequest, background: BackgroundTasks, db: DbSession
) -> MessageResponse:
    user = auth_service.get_user_by_email(db, body.email)
    if user is not None and user.status == "active":
        otp = auth_service.create_password_reset_otp(db, user)
        db.commit()
        background.add_task(send_password_reset_otp, user.email, user.full_name, otp)
    # Luôn trả cùng một thông báo để không lộ email nào đã đăng ký.
    return MessageResponse(
        message="Nếu email tồn tại trong hệ thống, mã OTP đã được gửi tới hộp thư của bạn."
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Đặt lại mật khẩu bằng mã OTP (đăng xuất mọi thiết bị)",
    dependencies=[Depends(limit_auth_requests)],
)
def reset_password(body: ResetPasswordRequest, db: DbSession) -> MessageResponse:
    try:
        auth_service.reset_password_with_otp(
            db, email=body.email, otp=body.otp, new_password=body.new_password
        )
    except AuthError as exc:
        db.commit()  # lưu số lần nhập sai OTP
        raise _http_error(exc) from exc
    db.commit()
    return MessageResponse(message="Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.")
