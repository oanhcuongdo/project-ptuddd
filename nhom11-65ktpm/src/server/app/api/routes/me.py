from fastapi import APIRouter

from app.api.deps import CurrentUser
from app.schemas.auth import UserOut

router = APIRouter(prefix="/me", tags=["users"])


@router.get("", response_model=UserOut, summary="Thông tin người dùng hiện tại (yêu cầu Bearer token)")
def read_me(user: CurrentUser) -> UserOut:
    return UserOut.model_validate(user)
