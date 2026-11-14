# Hướng dẫn viết báo cáo TH3 – Speak Up

Tài liệu này giúp nhóm viết báo cáo cho từng mục checklist: **làm gì**, **code ở đâu**, **chụp gì**, **viết gì**. Ảnh chụp có sẵn trong `docs/screenshots/`.

## Tình trạng checklist

| # | Mục | Trạng thái |
|---|-----|-----------|
| 1 | Cơ sở dữ liệu | ✅ Xong |
| 2 | Streak, thời gian học, mục tiêu ngày | ✅ Xong |
| 3 | API nhận dạng giọng nói | ✅ Xong |
| 4 | So sánh âm vị, chấm điểm | ✅ Xong |
| 5 | Module phản hồi | ✅ Xong (cần chụp màn hình kết quả trên điện thoại thật) |
| 6 | Thông báo nhắc nhở + giao diện tiến độ | ✅ Xong |
| 7 | Kiểm thử nhiều người dùng, nhiều giọng | ⚠️ Phần tự động xong. **Nhóm phải tự kiểm thử bằng giọng thật** (xem mục 7) |

**Việc nhóm còn phải làm trước khi nộp:**
1. Cài app lên điện thoại Android thật: `flutter run` hoặc cài file `build/app/outputs/flutter-apk/app-debug.apk`.
2. Chụp màn hình kết quả chấm điểm: một lần đọc đúng, một lần cố ý đọc sai (dùng cho mục 4 và 5).
3. Mỗi thành viên đọc thử, rồi điền bảng kiểm thử ở mục 7.
4. Chụp thông báo nhắc nhở: đặt giờ nhắc sớm 2–3 phút rồi chờ (dùng cho mục 6).

---

## Khung báo cáo (giống TH2)

```
BÁO CÁO BÀI TẬP THỰC HÀNH 3 (TH3)
Học phần: Phát triển Ứng dụng Di động - Lớp: 65KTPM
Nhóm thực hiện: Group 5 (danh sách thành viên)
Đề tài: Ứng dụng học tiếng Anh với tính năng phân tích phát âm AI (Speak Up)

1. TỔNG QUAN KIẾN TRÚC
2. KẾT QUẢ ĐẠT ĐƯỢC (7 MỤC CHECKLIST)  ← mỗi mục 1 tiểu mục, theo hướng dẫn bên dưới
3. KIỂM THỬ
4. HẠN CHẾ VÀ HƯỚNG PHÁT TRIỂN
```

### 1. Tổng quan kiến trúc (gợi ý nội dung)

- Flutter (Dart 3.13), chạy trên Android và iOS.
- Quản lý trạng thái: `provider` (`AppState` trong `lib/app_state.dart`).
- Lưu trữ cục bộ: SQLite qua `sqflite`.
- Nhận dạng giọng nói: `speech_to_text`. Đọc mẫu: `flutter_tts`. Nhắc nhở: `flutter_local_notifications`.
- Chấm điểm: thuật toán so sánh âm vị tự cài đặt (ARPAbet + Needleman–Wunsch có trọng số), chạy offline trên máy.

Cấu trúc thư mục:
```
lib/
  main.dart                     khởi tạo DB, thông báo, Provider
  app_state.dart                người dùng hiện tại, thống kê, lịch nhắc
  data/app_database.dart        schema + truy vấn (mục 1, 2)
  data/lessons.dart             7 bài học theo nhóm âm khó
  scoring/phonemes.dart         từ điển âm vị, IPA, độ giống nhau (mục 4)
  scoring/pronunciation_scorer.dart  thuật toán căn chỉnh và chấm điểm (mục 4)
  scoring/feedback.dart         mẹo và bài tập cải thiện (mục 5)
  services/notification_service.dart  nhắc nhở hằng ngày (mục 6)
  ui/profile_screen.dart        chọn / tạo / xóa người học
  ui/home_screen.dart           tab Luyện tập, Tiến độ, Cài đặt (mục 2, 6)
  ui/practice_screen.dart       thu âm + FeedbackView (mục 3, 5)
test/                           unit test (mục 7)
```

---

## Mục 1 – Thiết kế cơ sở dữ liệu

**Code:** `lib/data/app_database.dart` (các câu `CREATE TABLE` ở dòng 87–120).

**Viết vào báo cáo:**
- SQLite cục bộ, 4 bảng, có khóa ngoại `ON DELETE CASCADE`:

| Bảng | Vai trò | Cột chính |
|------|---------|-----------|
| `users` | Thông tin người học và cài đặt | `name` (UNIQUE), `daily_goal_minutes`, `reminder_enabled`, `reminder_hour`, `reminder_minute` |
| `practice_sessions` | Lịch sử phiên luyện tập | `user_id`, `lesson_id`, `day` (YYYY-MM-DD), `duration_seconds` |
| `attempts` | Mỗi lần nói | `session_id`, `expected_text`, `recognized_text`, `score`, `confidence` |
| `phoneme_errors` | Kết quả phân tích từng âm sai | `attempt_id`, `word`, `expected_phoneme`, `actual_phoneme`, `error_type` |

- Quan hệ: users 1–n practice_sessions 1–n attempts 1–n phoneme_errors.
- Có index `(user_id, day)` để tính streak và thống kê nhanh.
- Ghi một lượt nói và các lỗi âm vị của nó trong cùng một transaction (`saveAttempt`), nên không thể chỉ lưu được một nửa.

**Hình nên có:** sơ đồ ERD 4 bảng (vẽ bằng draw.io hoặc dbdiagram.io từ bảng trên).

---

## Mục 2 – Theo dõi tiến độ: streak, thời gian, mục tiêu

**Code:**
- `computeStreak()`, `lib/data/app_database.dart:54`: tính chuỗi hiện tại và chuỗi dài nhất.
- `startSession` / `endSession` (dòng 157–171) và `openLesson()` trong `lib/ui/home_screen.dart`: đo thời gian bằng `Stopwatch`.
- `stats()` (dòng 195): tổng phút, phút hôm nay, 7 ngày gần nhất, điểm trung bình, các âm hay sai.

**Viết vào báo cáo:**
- **Streak:** một ngày chỉ được tính khi có ít nhất một lượt nói (không tính việc chỉ mở app). Streak đếm lùi từ hôm nay. Nếu hôm nay chưa học, đếm từ hôm qua, vì chuỗi vẫn còn đến hết ngày. App lưu cả chuỗi dài nhất.
- **Thời gian học:** bắt đầu đếm khi vào bài, dừng khi thoát. Sau mỗi lượt nói, thời gian đã học cũng được lưu, để không mất dữ liệu nếu app bị tắt đột ngột.
- **Mục tiêu ngày:** chỉnh từ 5 đến 60 phút bằng slider. Thanh tiến độ ở trang chủ hiện "Hôm nay: x / y phút".

**Hình:** `02_bai_hoc_streak.png` (thẻ streak + mục tiêu), `06_tien_do.png` (thống kê), `07_cai_dat.png` (slider mục tiêu).

---

## Mục 3 – Tích hợp API nhận dạng giọng nói

**Code:** `lib/ui/practice_screen.dart`: hàm `_initStt()`, `_listen()` (dòng 83), `_onResult()`.

**Viết vào báo cáo:**
- Dùng package `speech_to_text`. Trên Android, package này gọi Google Speech Recognizer; trên iOS là `SFSpeechRecognizer` của Apple.
- Cấu hình: ngôn ngữ `en_US`, hiện kết quả tạm thời (partial results) khi đang nói, nghe tối đa 15 giây, tự dừng sau 3 giây im lặng.
- Lấy kết quả cuối (`finalResult`), gồm câu nhận dạng được và độ tin cậy (`confidence`).
- **Quyết định thiết kế quan trọng:** app *không* gửi câu mẫu cho engine (`contextualPhrases`). Nếu gửi, engine sẽ "đoán" theo câu đúng và che mất lỗi phát âm của người học.
- Quyền: `RECORD_AUDIO` (Android); `NSMicrophoneUsageDescription` và `NSSpeechRecognitionUsageDescription` (iOS).
- Xử lý lỗi bằng tiếng Việt: không nghe rõ, lỗi mạng, không có quyền micro.

**Hình:** `03_luyen_tap.png` (màn luyện tập), `04_dang_nghe.png` (đang thu âm), `05_loi_nhan_dang.png` (xử lý lỗi).

---

## Mục 4 – So sánh âm vị và chấm điểm

**Code:** `lib/scoring/phonemes.dart`, `lib/scoring/pronunciation_scorer.dart:54` (`scorePronunciation`).

**Viết vào báo cáo (phần trọng tâm, nên viết kỹ):**

1. **Chuẩn hóa:** chuyển về chữ thường, bỏ dấu câu, đổi số thành chữ ("3" → "three").
2. **Chuyển văn bản sang âm vị:** dùng bộ âm vị ARPAbet theo từ điển CMUdict (rút gọn, bao phủ 100% từ trong bài học). Từ ngoài từ điển dùng luật chữ → âm. Ví dụ: `think` → `TH IH NG K` → IPA `/θɪŋk/`.
3. **Căn chỉnh chuỗi:** dùng thuật toán Needleman–Wunsch (quy hoạch động, giống khoảng cách Levenshtein) giữa âm vị mẫu và âm vị nghe được. Chi phí:
   - Giống nhau: 0
   - Âm gần nhau (/θ/–/t/–/s/, /v/–/w/–/b/, /r/–/l/, /iː/–/ɪ/, /s/–/ʃ/…): 0.5
   - Khác hẳn, thiếu âm hoặc thừa âm: 1
4. **Truy vết (backtrace):** xác định từng âm đúng/sai, loại lỗi (thay thế / thiếu / thừa), thuộc từ nào và có nằm ở cuối từ không.
5. **Điểm:** `score = (1 − tổng chi phí / số âm vị mẫu) × 100`. Nếu engine có trả độ tin cậy thì trộn thêm 10% độ tin cậy. Mỗi từ cũng có điểm riêng.

**Ví dụ minh họa (lấy từ unit test):**

| Câu mẫu | Nghe được | Lỗi phát hiện | Điểm |
|---------|-----------|---------------|------|
| I think three is enough | I think three is enough | không | 100 |
| I think three is enough | I sink tree is enough | /θ/→/s/, /θ/→/t/ | ~93 |
| cats | cat | thiếu /s/ cuối | 75 |
| very | berry | /v/→/b/ | ~88 |
| sheep | ship | /iː/→/ɪ/ | ~83 |

> Tip: chạy `flutter test` để chụp kết quả thật đưa vào báo cáo.

**Vì sao gọi là "AI":** đây là kết hợp mô hình nhận dạng giọng nói (deep learning của Google/Apple) với thuật toán so sánh âm vị. Nên viết đúng như vậy, không nên nói app tự train mô hình.

---

## Mục 5 – Module phản hồi

**Code:** `FeedbackView` trong `lib/ui/practice_screen.dart:192`, `lib/scoring/feedback.dart` (`suggestionsFor`, dòng 54).

**Viết vào báo cáo:**
- **Điểm số:** vòng tròn màu (xanh ≥75, cam ≥50, đỏ <50) kèm nhận xét ("Xuất sắc!", "Tốt, gần chuẩn rồi"…).
- **Đánh dấu âm sai:** mỗi từ hiện phiên âm IPA; âm sai được tô đỏ và gạch chân. Danh sách lỗi dạng `think: /θ/ → /s/`.
- **Đề xuất cải thiện:** tối đa 3 gợi ý, lấy theo âm bị sai. Mỗi gợi ý gồm:
  - mẹo đặt lưỡi, môi bằng tiếng Việt;
  - cặp từ tối thiểu (minimal pairs), nhấn để nghe TTS, ví dụ "think – sink";
  - nút chuyển sang bài luyện tương ứng.
- Gợi ý được thiết kế cho lỗi phổ biến của người Việt: TH, V/W, R/L, /iː/–/ɪ/, S/SH, nuốt phụ âm cuối.

**Hình (nhóm tự chụp trên điện thoại thật):** một lần đọc đúng (điểm cao) và một lần cố ý đọc sai "sink" (thấy âm đỏ + thẻ gợi ý).

---

## Mục 6 – Thông báo nhắc nhở và giao diện tiến độ

**Code:** `lib/services/notification_service.dart:38` (`scheduleDaily`), `lib/app_state.dart` (`refresh`), tab Tiến độ trong `lib/ui/home_screen.dart`.

**Viết vào báo cáo:**
- Thông báo cục bộ lặp lại hằng ngày (`zonedSchedule` + `DateTimeComponents.time`). Không cần server.
- Nội dung thay đổi theo streak: "Giữ chuỗi 5 ngày của bạn…".
- Người dùng bật/tắt nhắc nhở và chọn giờ nhắc. Lịch nhắc được đặt lại sau mỗi buổi học và tự khôi phục sau khi khởi động lại máy (`ScheduledNotificationBootReceiver`).
- Đã kiểm tra trên emulator: lịch nhắc được hệ thống ghi nhận lúc 20:00 ngày hôm sau (`adb shell dumpsys alarm`).
- Giao diện tiến độ gồm: chuỗi hiện tại và dài nhất, tổng phút, số lượt nói, điểm trung bình, biểu đồ cột 7 ngày (cột đậm khi đạt mục tiêu), top 5 âm hay sai, 10 lượt nói gần nhất.

**Hình:** `06_tien_do.png`, `07_cai_dat.png`, ảnh thông báo trên điện thoại (nhóm tự chụp).

---

## Mục 7 – Kiểm thử

### 7.1 Kiểm thử tự động (đã có, 18 test pass)

Chạy `flutter test` rồi chụp màn hình kết quả.

- `test/pronunciation_scorer_test.dart` (13 test): mô phỏng các giọng có lỗi đặc trưng:
  - Người Việt: TH → T/S, nuốt phụ âm cuối.
  - Lẫn V với B/W (thường gặp ở người Ấn, người Việt).
  - Lẫn R/L (thường gặp ở người Trung Quốc, Nhật).
  - Lẫn nguyên âm dài/ngắn /iː/–/ɪ/.
  - Câu khác hẳn phải có điểm thấp hơn nhiều so với câu gần đúng; câu rỗng được 0 điểm; xử lý chữ số; mọi từ trong bài học đều có trong từ điển.
- `test/streak_test.dart` (5 test): streak qua ranh giới tháng, chuỗi vẫn giữ khi hôm nay chưa học, đứt chuỗi nhưng vẫn giữ kỷ lục.

### 7.2 Kiểm thử trên thiết bị (đã làm trên emulator)

App chạy ổn, không crash, trên emulator Pixel 7 Pro. Đã kiểm tra: tạo người học, xin quyền micro, thu âm, xử lý lỗi khi không có giọng, tab tiến độ ghi nhận thời gian, đặt lịch nhắc. Emulator không có giọng nói thật nên không chấm điểm được, xem 7.3.

### 7.3 Kiểm thử với nhiều người dùng và nhiều giọng (NHÓM PHẢI TỰ LÀM)

1. Mỗi thành viên tạo một hồ sơ riêng trên cùng điện thoại.
2. Mỗi người đọc ít nhất 5 câu (khác bài), mỗi câu 2 lần: lần 1 đọc chuẩn nhất có thể, lần 2 cố ý đọc sai theo lỗi của bài.
3. Ghi kết quả vào bảng:

| Người (giới, vùng miền) | Câu mẫu | Đọc chuẩn – điểm | Đọc sai cố ý (đọc gì) – điểm | Âm sai app báo | App báo đúng? |
|---|---|---|---|---|---|
| Anh (nam, Bắc) | I think three is enough | | "I sink tree…" | | |
| An (…) | very | | "berry" | | |
| … | | | | | |

4. Thêm các tình huống: phòng ồn, nói nhanh/chậm, tắt mạng, từ chối quyền micro, chuyển người học (kiểm tra dữ liệu tách biệt).
5. Tính **tỉ lệ phát hiện đúng** = số lần "App báo đúng" / tổng số lần đọc sai cố ý, rồi đưa con số này vào báo cáo.

---

## Hạn chế và hướng phát triển (nên có, để thể hiện hiểu bài)

- Engine nhận dạng luôn trả về từ có thật. Vì vậy app chỉ phát hiện lỗi khi phát âm sai đến mức thành từ khác (think → sink), chưa bắt được lỗi nhỏ như trọng âm hay ngữ điệu.
- Hướng phát triển:
  - dùng mô hình nhận dạng âm vị trực tiếp từ âm thanh (wav2vec2-phoneme), hoặc API chuyên chấm phát âm (Azure Pronunciation Assessment);
  - dùng từ điển CMUdict đầy đủ;
  - đồng bộ dữ liệu lên cloud (Firebase/Supabase như TH2).
- Android cần mạng để nhận dạng, trừ khi máy đã tải gói ngôn ngữ offline.
- Giờ nhắc lưu theo UTC cố định nên sẽ lệch 1 giờ ở nước có giờ mùa hè (Việt Nam không bị ảnh hưởng). Android có thể giao thông báo trễ tối đa 1 giờ (chế độ hẹn giờ không chính xác, giúp tiết kiệm pin).
