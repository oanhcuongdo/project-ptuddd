"""Khuôn JSON (structured output) mà model AI bắt buộc phải trả về.

Dùng chung cho mọi provider (Claude / OpenAI). Không đặt giá trị mặc định hay
ràng buộc min/max trong các model này: structured output ở chế độ strict yêu cầu
mọi trường đều `required`; việc giới hạn giá trị (vd. điểm 0-100) làm ở code.
"""

from typing import Literal

from pydantic import BaseModel, Field

SentenceRole = Literal[
    "subject",  # chủ ngữ
    "predicate",  # vị ngữ (động từ / tính từ làm vị ngữ)
    "object",  # tân ngữ
    "adverbial",  # trạng ngữ (thời gian, địa điểm, phó từ...)
    "attributive",  # định ngữ
    "complement",  # bổ ngữ
    "measure_word",  # lượng từ
    "particle",  # trợ từ (了, 的, 吗, 呢...)
    "other",
]

GrammarErrorType = Literal[
    "word_order",  # sai trật tự từ
    "measure_word",  # sai / thiếu lượng từ
    "missing_le",  # thiếu 了
    "bu_mei_confusion",  # nhầm 不 / 没
    "missing_particle",  # thiếu trợ từ khác (的, 吗...)
    "wrong_word",  # dùng sai từ
    "verb_usage",  # dùng sai động từ (是, 有, 在...)
    "adverb_usage",  # nhầm phó từ (也, 都, 很...)
    "missing_component",  # thiếu thành phần câu
    "redundant_word",  # thừa từ
    "other",
]


class ChineseLine(BaseModel):
    hanzi: str = Field(description="Câu tiếng Trung giản thể")
    pinyin: str = Field(description="Pinyin có dấu thanh điệu, tách theo từ")
    translation_vi: str = Field(description="Nghĩa tiếng Việt tự nhiên")


class ChatTurn(BaseModel):
    """Một lượt nói của trợ lý AI.

    `reply_hanzi` phải là trường ĐẦU TIÊN để server tách và stream từng chữ cho app
    trước khi cả JSON hoàn tất.
    """

    reply_hanzi: str = Field(description="Câu trả lời / câu hỏi tiếp theo của AI, chỉ Hán tự")
    reply_pinyin: str = Field(description="Pinyin có dấu của reply_hanzi")
    reply_translation_vi: str = Field(description="Nghĩa tiếng Việt của reply_hanzi")
    suggested_replies: list[ChineseLine] = Field(
        description="2-3 câu trả lời mẫu ngắn để người học tham khảo"
    )
    conversation_should_end: bool = Field(
        description="true nếu cuộc hội thoại đã tự nhiên đi đến hồi kết"
    )


class SentenceComponent(BaseModel):
    text: str = Field(description="Đoạn Hán tự của thành phần (giữ nguyên thứ tự trong câu)")
    pinyin: str
    role: SentenceRole
    label_vi: str = Field(description="Tên thành phần bằng tiếng Việt, vd. 'Chủ ngữ'")


class GrammarError(BaseModel):
    span: str = Field(description="Đoạn sai trong câu của người học")
    correction: str = Field(description="Cách sửa đúng cho đoạn đó")
    error_type: GrammarErrorType
    explanation_vi: str = Field(description="Giải thích ngắn gọn bằng tiếng Việt")
    grammar_point_id: str | None = Field(
        description="id điểm ngữ pháp trong bài liên quan tới lỗi, null nếu không có"
    )


class GrammarAnalysis(BaseModel):
    is_correct: bool
    corrected_sentence: str = Field(description="Câu đã sửa; giữ nguyên nếu câu đúng")
    corrected_pinyin: str
    components: list[SentenceComponent] = Field(
        description="Bóc tách câu ĐÃ SỬA thành các thành phần theo đúng thứ tự"
    )
    errors: list[GrammarError]
    score: int = Field(description="Điểm 0-100 cho câu trả lời")
    overall_comment_vi: str = Field(description="Nhận xét 1-2 câu bằng tiếng Việt, động viên")
    grammar_point_ids: list[str] = Field(description="Các id điểm ngữ pháp trong bài mà câu sử dụng")
