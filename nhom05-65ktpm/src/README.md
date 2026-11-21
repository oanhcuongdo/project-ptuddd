# Speak Up – Ứng dụng học phát âm tiếng Anh (TH3)

Flutter app (Android/iOS) luyện phát âm tiếng Anh, chấm điểm bằng so sánh âm vị (phoneme), theo dõi streak, mục tiêu hằng ngày và nhắc nhở.

## Chạy

```bash
flutter pub get
flutter run          # cần thiết bị thật hoặc emulator có Google speech service + micro
flutter test         # unit test thuật toán chấm điểm và streak
```

## Đối chiếu checklist

| # | Yêu cầu | Nơi thực hiện |
|---|---------|---------------|
| 1 | CSDL người dùng, lịch sử, kết quả phân tích | `lib/data/app_database.dart` (SQLite – sqflite) |
| 2 | Streak, thời gian học, mục tiêu ngày | `computeStreak`, `AppDatabase.stats`, tab **Tiến độ**, slider mục tiêu ở tab **Cài đặt** |
| 3 | API nhận dạng giọng nói | `speech_to_text` (Google Speech trên Android, SFSpeechRecognizer trên iOS) trong `lib/ui/practice_screen.dart` |
| 4 | So sánh âm vị, chấm điểm | `lib/scoring/phonemes.dart`, `lib/scoring/pronunciation_scorer.dart` |
| 5 | Phản hồi: điểm, âm sai, bài tập | `FeedbackView` + `lib/scoring/feedback.dart` |
| 6 | Thông báo nhắc nhở + giao diện tiến độ | `lib/services/notification_service.dart`, tab **Tiến độ** |
| 7 | Kiểm thử nhiều người dùng / giọng | `test/` + kịch bản thủ công bên dưới |

## Thiết kế CSDL

```
users(id, name UNIQUE, daily_goal_minutes, reminder_enabled, reminder_hour, reminder_minute, created_at)
practice_sessions(id, user_id→users, lesson_id, day 'YYYY-MM-DD', started_at, duration_seconds)
attempts(id, session_id→practice_sessions, user_id→users, expected_text, recognized_text, score, confidence, created_at)
phoneme_errors(id, attempt_id→attempts, word, expected_phoneme, actual_phoneme, error_type)
```

Khóa ngoại `ON DELETE CASCADE`: xóa người học sẽ xóa toàn bộ lịch sử của họ. Một ngày chỉ tính vào streak khi có ít nhất một lượt nói (attempt).

## Thuật toán chấm điểm

1. Nhận dạng giọng nói trả về văn bản (`recognizedWords`) và độ tin cậy (`confidence`).
2. Câu mẫu và câu nghe được được chuẩn hóa (chữ thường, bỏ dấu câu, "3" → "three") rồi chuyển sang chuỗi âm vị ARPAbet bằng từ điển CMUdict rút gọn. Từ ngoài từ điển dùng luật chữ → âm.
3. Hai chuỗi âm vị được căn chỉnh bằng Needleman–Wunsch có trọng số: âm giống nhau = 0, âm gần nhau (vd. /θ/–/t/, /v/–/w/, /r/–/l/, /iː/–/ɪ/) = 0.5, khác hẳn hoặc thiếu/thừa = 1.
4. Điểm = `(1 − tổng chi phí / số âm vị mẫu) × 100`, trộn 10% độ tin cậy của engine nếu có. Mỗi từ có điểm riêng; mỗi âm sai được tô đỏ.
5. Lỗi được ánh xạ sang mẹo phát âm tiếng Việt, cặp từ tối thiểu (nhấn để nghe TTS) và nút chuyển sang bài luyện tương ứng. Mất âm ở cuối từ → bài "Phụ âm cuối".

Ứng dụng cố ý **không** truyền câu mẫu cho engine nhận dạng (`contextualPhrases`), vì làm vậy sẽ kéo kết quả về câu đúng và che lỗi của người học.

**Giới hạn:** engine nhận dạng luôn trả về từ có thật, nên lỗi chỉ phát hiện được khi phát âm sai đủ để thành từ khác (think → sink). Muốn chấm ở mức âm thanh thực sự cần mô hình nhận dạng âm vị (vd. wav2vec2-phoneme) hoặc API chấm phát âm (Azure Pronunciation Assessment).

## Kiểm thử (mục 7)

### Tự động – `flutter test`
- `test/pronunciation_scorer_test.dart`: mô phỏng giọng có lỗi đặc trưng: người Việt (TH → T/S, nuốt âm cuối), V → B/W, R ↔ L, /iː/ ↔ /ɪ/. Kiểm tra phát hiện đúng âm sai, đúng bài gợi ý, câu khác hẳn bị điểm thấp hơn hẳn, xử lý chữ số, câu rỗng.
- `test/streak_test.dart`: streak qua ranh giới tháng, giữ streak đến hết ngày, đứt chuỗi nhưng giữ kỷ lục.

### Thủ công – kịch bản đề xuất
Tạo ít nhất 3 hồ sơ người học (nam/nữ, giọng Bắc/Nam, trình độ khác nhau). Mỗi người đọc toàn bộ 7 bài và ghi vào bảng:

| Người | Câu | Đọc chuẩn (điểm) | Cố ý đọc sai (điểm) | Âm sai app báo | Đúng/Sai |
|-------|-----|------------------|---------------------|----------------|----------|
| … | I think three is enough | | "I sink tree…" | /θ/→/s/, /θ/→/t/ | |

Kiểm tra thêm: môi trường ồn, nói nhanh/chậm, mất mạng (Android cần mạng nếu không có gói offline), từ chối quyền micro, đổi giờ nhắc và chờ thông báo, chuyển người học (dữ liệu tách biệt).
