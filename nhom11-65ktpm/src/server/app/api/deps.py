"""Dependency dùng chung: phiên CSDL và người dùng hiện tại lấy từ Bearer token.

Cách dùng trong router của các thành viên:

    from app.api.deps import CurrentUser, DbSession

    @router.get("/srs/cards")
    def list_cards(user: CurrentUser, db: DbSession):
        # Luôn lọc theo user.id lấy từ token, KHÔNG tin user_id app gửi lên.
        return db.query(SrsCard).filter(SrsCard.user_id == user.id).all()
"""

import uuid
from typing import Annotated, TypeVar

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import TokenError, decode_access_token
from app.db.session import get_db
from app.models import User, UserStatus

bearer_scheme = HTTPBearer(auto_error=False, description="Access token (JWT)")

DbSession = Annotated[Session, Depends(get_db)]


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    db: DbSession,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("Thiếu access token")
    try:
        user_id = decode_access_token(credentials.credentials)
    except TokenError as exc:
        raise _unauthorized(str(exc)) from exc

    user = db.get(User, user_id)
    if user is None or user.status != UserStatus.ACTIVE:
        raise _unauthorized("Tài khoản không tồn tại hoặc đã bị khóa")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]

ModelT = TypeVar("ModelT")


def get_owned_or_404(db: Session, model: type[ModelT], obj_id: uuid.UUID | int, user: User) -> ModelT:
    """Lấy bản ghi theo id và đảm bảo thuộc về `user`.

    Trả 404 (không phải 403) khi bản ghi của người khác để không lộ sự tồn tại.
    """
    obj = db.get(model, obj_id)
    if obj is None or getattr(obj, "user_id", None) != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy dữ liệu")
    return obj
