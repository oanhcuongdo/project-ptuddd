# API trợ lý ôn bài AI

Server làm trung gian gọi AI (Claude mặc định, hoặc OpenAI). Khóa API chỉ nằm trên server. Mọi endpoint cần `Authorization: Bearer <access_token>`.

## Chọn nhà cung cấp AI (`.env` của server)

| Biến | Mặc định | Ý nghĩa |
|:--|:--|:--|
| `AI_PROVIDER` | `anthropic` | `anthropic` (Claude) hoặc `openai` |
| `ANTHROPIC_API_KEY` / `ANTHROPIC_MODEL` | — / `claude-opus-5-5` | Đổi `claude-haiku-5-5` để giảm chi phí |
| `OPENAI_API_KEY` / `OPENAI_MODEL` | — / `gpt-5-mini` | `OPENAI_BASE_URL` cho dịch vụ tương thích OpenAI |
| `OPENAI_REASONING_EFFORT_ENABLED` | `true` | Tắt nếu model OpenAI không hỗ trợ `reasoning_effort` |
| `AI_DAILY_MESSAGE_LIMIT` / `AI_DAILY_CONVERSATION_LIMIT` | 40 / 10 | Giới hạn mỗi người mỗi ngày (giờ Việt Nam) |
| `AI_MAX_TURNS` / `AI_MAX_MESSAGE_CHARS` | 8 / 120 | Số lượt mỗi phiên, độ dài tối đa một câu trả lời |

## Luồng sử dụng trên app

1. `POST /api/ai/conversations` `{"lesson_id": 1}` → `201` phiên mới, `messages[0]` là câu mở đầu của AI (`content` Hán tự, `pinyin`, `translation_vi`, `suggested_replies`).
2. `POST /api/ai/conversations/{id}/messages` `{"content": "我是学生。", "input_method": "text" | "voice"}` → luồng **Server-Sent Events**:

   | event | data | App làm gì |
   |:--|:--|:--|
   | `user_message` | `{id}` | Gắn id cho bong bóng của người học |
   | `delta` | `{text}` | Nối vào bong bóng AI (hiệu ứng gõ chữ) |
   | `grammar` | phân tích ngữ pháp (xem dưới) | Hiện điểm/lỗi dưới câu của người học |
   | `grammar_error` | `{message}` | Phân tích lỗi, hội thoại vẫn tiếp tục |
   | `message` | tin nhắn AI hoàn chỉnh | Thay bong bóng tạm bằng bản đầy đủ (pinyin, nghĩa, gợi ý) |
   | `done` | `{turn_count, max_turns, should_finish, messages_used_today, messages_limit}` | `should_finish = true` → mời người học xem tổng kết |
   | `error` | `{message, retryable}` | Bỏ bong bóng AI tạm; câu của người học không bị tính lượt, có thể gửi lại |

3. `POST /api/ai/conversations/{id}/finish` → tổng kết: `summary.overall_score`, `turns`, `correct_sentences`, `error_counts`, `top_errors`, `grammar_points_to_review`, `comment_vi`.
4. `GET /api/ai/conversations?lesson_id=` (lịch sử), `GET /api/ai/conversations/{id}` (xem lại kèm phân tích từng câu), `GET /api/ai/usage` (lượt còn lại hôm nay).

Mã lỗi: `404` bài học/phiên không tồn tại hoặc không phải của bạn · `409` phiên đã kết thúc hoặc đủ lượt · `422` câu trống/quá dài · `429` hết lượt hôm nay · `502` AI lỗi khi mở đầu phiên · `503` server chưa cấu hình AI.

## Khuôn phân tích ngữ pháp (`grammar`)

```json
{
  "original_sentence": "我学生。",
  "corrected_sentence": "我是学生。",
  "corrected_pinyin": "wǒ shì xuésheng.",
  "components": [{"text": "我", "pinyin": "wǒ", "role": "subject", "label_vi": "Chủ ngữ"}],
  "errors": [{"span": "我学生", "correction": "我是学生", "error_type": "verb_usage",
              "explanation_vi": "Thiếu động từ 是 ...", "grammar_point_id": "gp-shi"}],
  "error_types": ["verb_usage"],
  "grammar_point_ids": ["gp-shi"],
  "score": 70,
  "overall_comment_vi": "Cố gắng tốt!"
}
```

`role`: `subject` · `predicate` · `object` · `adverbial` · `attributive` · `complement` · `measure_word` · `particle` · `other`.
`error_type`: `word_order` · `measure_word` · `missing_le` · `bu_mei_confusion` · `missing_particle` · `wrong_word` · `verb_usage` · `adverb_usage` · `missing_component` · `redundant_word` · `other`.

## Ngữ cảnh bài học

AI dùng `lessons.title/topic/description`, `lessons.ai_scenario` (`aiRole`, `learnerRole`, `situation`, `openingLine`), `lessons.grammar_points` (`id`, `pattern`, `explanationVi`, `examples`) và từ vựng của bài hiện tại cùng các bài trước trong cùng khóa. Khi nạp dữ liệu bài học (#18) nên điền đủ hai trường `ai_scenario` và `grammar_points` để AI đóng vai đúng chủ đề.

## Đánh giá chất lượng phân tích

`tests/data/grammar_eval_cases.json` chứa câu đúng và các lỗi điển hình của người Việt (thiếu 是, sai trật tự trạng ngữ thời gian/địa điểm, thiếu lượng từ, nhầm 不/没, thiếu 了/吗/的, sai vị trí 也). Chạy thủ công (gọi API thật, tốn phí): `python -m scripts.eval_grammar`.
