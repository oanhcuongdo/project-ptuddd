# AI ghi chú (#12, #13) — tóm tắt và trắc nghiệm

Tài liệu cho tính năng **tóm tắt ghi chú** và **tạo câu hỏi trắc nghiệm** từ
nội dung ghi chú. API key Gemini chỉ nằm trên máy chủ.

## 1. Nguyên tắc bảo mật

- **API key Gemini chỉ nằm ở máy chủ trung gian**, không có trong app, asset hay
  log. App chỉ biết một địa chỉ endpoint.
- App gửi **Firebase ID token** qua HTTPS. Edge Function xác thực chữ ký RS256,
  issuer và audience bằng chứng chỉ của Firebase, sau đó dùng UID đã xác thực
  để áp dụng giới hạn 10 lượt mỗi giờ theo UTC trong Postgres.
- Test `test/security/no_api_key_test.dart` quét toàn bộ `lib/` và fail nếu phát
  hiện chuỗi giống khoá Google (`AIza…`), header `x-goog-api-key`, URL
  `generativelanguage.googleapis.com` hoặc `service_role`.

## 2. Kiến trúc

```text
lib/
├── core/
│   ├── error/failure.dart              # AiFailure + AiFailureKind
│   └── services/
│       ├── ai_client.dart              # HTTP client gọi endpoint AI
│       └── demo_ai_transport.dart      # tóm tắt cục bộ để demo (không phải AI)
└── features/summary/
    ├── domain/
    │   ├── entities/summary_mode.dart  # short / long / bullets
    │   ├── entities/note_summary.dart
    │   ├── repositories/summary_repository.dart
    │   └── usecases/summarize_note.dart
    ├── data/
    │   ├── datasources/remote/ai_summary_remote_data_source.dart
    │   └── repositories/summary_repository_impl.dart
    └── presentation/
        ├── bloc/summary_cubit.dart, summary_state.dart
        ├── pages/summary_page.dart
        └── widgets/…
```

Luồng: `SummaryPage → SummaryCubit → SummarizeNote → SummaryRepository →
SummaryRepositoryImpl → AiSummaryRemoteDataSource → AiClient`.

Feature `summary` **không** import `features/notes`: nhận `noteId`, `noteTitle`,
`noteContent` dạng chuỗi.

## 3. Cấu hình

```bash
# Gọi máy chủ trung gian thật
flutter run --dart-define=AI_SUMMARY_ENDPOINT=https://api.example.com/v1/summarize

# Xem trước giao diện khi chưa có máy chủ: tóm tắt ngay trên máy (trích câu)
flutter run --dart-define=AI_SUMMARY_ENDPOINT=mock
```

- Không truyền `AI_SUMMARY_ENDPOINT`: màn tóm tắt hiển thị lỗi
  *“Chưa cấu hình máy chủ tóm tắt AI…”* kèm hướng dẫn, không crash.
- `lib/main_preview.dart` luôn dùng chế độ `mock` để review UI không cần
  Firebase/mạng.
- Chế độ `mock` chỉ trích câu đầu và gạch đầu dòng — **không phải AI**, không
  dùng cho bản phát hành.

## 4. Hợp đồng API với máy chủ trung gian

### Request

```http
POST {AI_SUMMARY_ENDPOINT}
Content-Type: application/json; charset=utf-8
Accept: application/json
Authorization: Bearer <Firebase ID token>   # có khi đã đăng nhập
```

```json
{
  "noteId": "note-uuid",
  "title": "Giải tích – Chương 3",
  "text": "Nội dung ghi chú…",
  "mode": "short"          // short | long | bullets | quiz
}
```

Với `mode: "quiz"`, app chỉ gửi nội dung khi ghi chú có ít nhất 20 từ. Máy chủ
trả từ 5 đến 10 câu; mỗi câu phải có bốn phương án khác nhau, `correctIndex`
trong khoảng 0–3 và lời giải thích.

### Response tóm tắt

HTTP 200, chấp nhận một trong các dạng sau (client đọc linh hoạt):

```json
{ "summary": "…", "model": "gemini-3.5-flash-lite" }
```

```json
{ "content": "…" }
```

```json
{ "data": { "summary": "…" } }
```

Hoặc văn bản thuần (không phải JSON).

### Response trắc nghiệm

```json
{
  "quiz": [
    {
      "question": "Định luật nào mô tả hiện tượng cảm ứng điện từ?",
      "options": ["Faraday", "Newton", "Ohm", "Hooke"],
      "correctIndex": 0,
      "explanation": "Định luật Faraday mô tả suất điện động cảm ứng."
    }
  ],
  "model": "gemini-3.5-flash-lite"
}
```

Máy chủ từ chối phản hồi không phải JSON hoặc không đáp ứng số lượng/cấu trúc
câu hỏi, thay vì hiển thị đề sai. Điểm và lịch sử làm bài được lưu cục bộ.

### Mã lỗi

| HTTP | `AiFailureKind` | Thông báo trên UI |
|---|---|---|
| 401 / 403 | `unauthorized` | Phiên đăng nhập không hợp lệ hoặc đã hết hạn |
| 429 | `quotaExceeded` | Đã hết lượt gọi AI |
| 413 | `badResponse` | Chia ghi chú dài thành các phần ngắn hơn |
| 504 | `timeout` | Máy chủ phản hồi quá lâu |
| 5xx khác | `server` | Máy chủ tóm tắt đang gặp lỗi |
| khác | `badResponse` | Máy chủ trả về lỗi (HTTP …) |

Lỗi phía client:

| Tình huống | `AiFailureKind` |
|---|---|
| Mất mạng / DNS / TLS | `network` |
| Quá 15 giây | `timeout` |
| Ghi chú rỗng | `emptyContent` |
| Thiếu `AI_SUMMARY_ENDPOINT` | `notConfigured` |
| Response 200 nhưng rỗng | `badResponse` |

Mọi thông báo đã là tiếng Việt có dấu; UI không phải map lại mã lỗi.

## 5. Giao diện

- Nút **Tóm tắt AI** (biểu tượng `auto_awesome`) trên AppBar màn soạn ghi chú.
  Bấm sẽ lưu nội dung trước rồi mở màn kết quả.
- Màn kết quả theo bố cục Notion (`docs/ui_ux.md` mục 9): tiêu đề ghi chú lớn,
  hàng chip chọn kiểu, vùng đọc rộng, nút chính **Tóm tắt / Tóm tắt lại**.
- Đủ trạng thái: chờ (skeleton + “thường dưới 15 giây”), rỗng (ghi chú chưa có
  nội dung), lỗi (kèm **Thử lại**), thành công (số từ, thời gian chờ, **Sao chép**).
- Đổi kiểu khi đã có kết quả sẽ tự tóm tắt lại theo kiểu mới.

## 6. Kiểm thử

```bash
cd nhom03-65ktpm/src
flutter test test/core/services/ai_client_test.dart
flutter test test/features/summary
flutter test test/security/no_api_key_test.dart
flutter test
```

Đã chạy 25/11/2026: `flutter analyze` 0 lỗi, `flutter test` 62/62 pass.

## 7. Triển khai máy chủ trung gian

Mã nguồn nằm ở [supabase/functions/summarize-note](../supabase/functions/summarize-note).
Function nhận đúng hợp đồng của app, giới hạn nội dung 30.000 ký tự và dừng
các yêu cầu ra ngoài sau 12,5 giây. Lỗi hết hạn mức ở máy chủ hoặc Gemini
đều trả HTTP 429. Máy chủ giữ UID và bộ đếm, không ghi nội dung ghi chú vào quota.

1. Trên project NoteSmart, chạy [SQL quota](sql/20261127_gioi_han_tom_tat.sql).
2. Đăng nhập Supabase CLI và đặt `FIREBASE_PROJECT_ID` cùng `GEMINI_API_KEY`
   trong Edge Function Secrets. Hàm cũng đọc `GEMINI_KEY` nếu chưa đặt
   `GEMINI_API_KEY`. Nếu dùng tên khác, đặt `GEMINI_SECRET_NAME` thành tên
   secret chứa khóa (ví dụ `gemini` trên NoteSmart). `GEMINI_MODEL` là tùy chọn, mặc định
   `gemini-3.5-flash-lite`. Supabase cấp `SUPABASE_URL` và
   `SUPABASE_SERVICE_ROLE_KEY` cho runtime máy chủ.
3. Từ thư mục `nhom03-65ktpm/`, chạy:

   ```sh
   supabase functions deploy summarize-note --project-ref hxzimpvamyzyqdhkxexl
   ```

4. Chạy Flutter với `AI_SUMMARY_ENDPOINT=https://hxzimpvamyzyqdhkxexl.supabase.co/functions/v1/summarize-note`.
   Kiểm tra ba chế độ tóm tắt và `quiz` bằng tài khoản thử đã đăng nhập Firebase.
   Kiểm tra 429 bằng môi trường thử hoặc test tự động, tránh tiêu hết quota của
   nhóm trên môi trường dùng chung.

Chạy `deno check supabase/functions/summarize-note/index.ts` và
`deno test supabase/functions/summarize-note/handler_test.ts` để kiểm tra hợp đồng
trước khi phát hành. Bản demo trên máy dùng trích câu và được gắn nhãn demo.
