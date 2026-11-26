"""Import toàn bộ model để Alembic (target_metadata) nhận diện được các bảng."""

from app.db.base import Base
from app.models.ai import AiConversation, AiMessage, GrammarFeedback
from app.models.content import Character, Course, Lesson, Word
from app.models.path import PathNode, PathStage, UserPathProgress
from app.models.progress import EventType, LearningEvent
from app.models.practice import DailyStat, SrsCard, Streak, WritingAttempt
from app.models.pronunciation import Attempt, PronunciationRequest, SyllableResult
from app.models.user import PasswordResetOtp, RefreshToken, User, UserStatus

__all__ = [
    "AiConversation",
    "AiMessage",
    "Attempt",
    "Base",
    "Character",
    "Course",
    "DailyStat",
    "EventType",
    "GrammarFeedback",
    "LearningEvent",
    "Lesson",
    "PathNode",
    "PasswordResetOtp",
    "PathStage",
    "PronunciationRequest",
    "RefreshToken",
    "SrsCard",
    "Streak",
    "SyllableResult",
    "User",
    "UserPathProgress",
    "UserStatus",
    "Word",
    "WritingAttempt",
]
