# Hướng dẫn cấu hình F1, F7, F10

## Phần đã có trong mã nguồn

- F1: đăng ký email/mật khẩu và đăng nhập Firebase Auth; tài khoản tự đăng ký luôn mang role `learner`. Luồng mentor chỉ xuất hiện khi quản trị viên cấp role `mentor` trong Firestore.
- F10: learner tiếp tục luyện bằng hồ sơ SQLite hiện có. Sau tối thiểu 10 lượt, rate gần nhất được đồng bộ lên hồ sơ Firebase. Mentor ghép học viên chưa có nhóm cùng band thành nhóm 4–6 người; thành viên lẻ dưới 4 người nằm trong danh sách chờ.
- F7: nhắc luyện hằng ngày vẫn dùng local notification; FCM token lưu riêng theo tài khoản. Cloud Functions gửi push khi có submission/comment mới trong Firestore.
- Firestore Rules chặn người dùng tự cấp quyền mentor, chặn sửa role và bảo vệ FCM token riêng tư. Rate được đồng bộ từ ứng dụng của learner; đây là dữ liệu tự khai báo từ SQLite phía thiết bị, chưa phải dữ liệu được xác thực bởi backend scoring.

## Thiết lập Firebase do nhóm trưởng/quản trị viên thực hiện

1. Chọn Firebase project của nhóm; bật Email/Password trong Authentication và tạo Firestore database.
2. Tại thư mục `src`, chạy `dart pub global activate flutterfire_cli`, đăng nhập Firebase CLI rồi chạy `flutterfire configure`. Chọn Android (application id `com.group05.english_pronunciation_app`). Không tự tạo project Firebase cá nhân thay cho project nhóm.
3. Deploy security rules, index và Cloud Functions: `firebase deploy --only firestore:rules,firestore:indexes,functions`.
4. Cấp mentor bằng tài khoản quản trị Firebase: trong `users/{uid}` đổi `role` từ `learner` thành `mentor`. App không cung cấp chức năng tự nâng quyền.
5. Mở app bằng `flutter run --dart-define=FIREBASE_ENABLED=true`. Nếu không truyền cờ, ứng dụng giữ chế độ local SQLite hiện tại.
6. Tạo learner qua màn hình đăng ký. Để ghép nhóm trong demo, ít nhất 4 tài khoản cần rate thuộc cùng band; mỗi learner đăng nhập, chọn tiếp tục luyện trên thiết bị và hoàn tất tối thiểu 10 lượt. Sau đó mentor đăng nhập và bấm “Match unassigned learners by rate”.
7. Để kiểm thử FCM, đăng nhập các learner/mentor trên thiết bị Android có Google Play Services, cấp quyền notification, rồi tạo document trong `submissions` theo schema bên dưới. Không đặt server key trong ứng dụng Flutter.

## Firestore schema chính

`users/{uid}`: `displayName`, `email`, `role`, `rate`, `rateLevel`, `attemptCount`, `groupId`, `createdAt`.

`users/{uid}/private/device`: `tokens` (FCM registration tokens; chỉ chính tài khoản được đọc/ghi).

`study_groups/{groupId}`: `level`, `mentorUid`, `memberUids` (4–6 UID), `createdAt`.

`submissions/{submissionId}`: `groupId`, `learnerUid`, `title`, `createdAt`.

`submissions/{submissionId}/comments/{commentId}`: `authorUid`, `text`, `createdAt`.

App này chưa có màn hình gửi bài/bình luận; Cloud Functions đã cung cấp trigger gửi notification khi các document trên được tạo bởi client hoặc module khác của nhóm.

## Kiểm thử thủ công — điền sau khi chạy trên thiết bị thật

Không điền kết quả thay cho người kiểm thử. Dùng ít nhất ba giọng nói thật, có khác biệt giới tính/vùng miền như đề cương yêu cầu.

| Mã | Tình huống | Thiết bị/tài khoản/giọng | Kết quả mong đợi | Kết quả thực tế | Đạt? |
|---|---|---|---|---|---|
| A1 | Đăng ký learner mới |  | Profile Firestore có role learner |  |  |
| A2 | Đăng nhập sai mật khẩu |  | Báo lỗi, không crash |  |  |
| A3 | Đăng nhập mentor đã được cấp role |  | Mở màn hình mentor |  |  |
| G1 | Ghép 4–6 learner cùng rate band |  | Một nhóm đúng band, có mentor |  |  |
| G2 | Có 3 learner cùng band |  | Không tạo nhóm thiếu người; giữ chờ |  |  |
| P1 | Luyện ≥10 lượt và refresh |  | Rate cập nhật theo user đăng nhập |  |  |
| N1 | Tắt quyền notification Android |  | App không crash; token không lưu |  |  |
| N2 | Tạo submission/comment khi app nền |  | Thiết bị khác nhận FCM |  |  |
| V1 | Luyện một câu với giọng thật số 1 |  | Ghi nhận rõ; không chấm thay người |  |  |
| V2 | Luyện cùng câu với giọng thật số 2 |  | Ghi nhận rõ; không chấm thay người |  |  |
| V3 | Luyện cùng câu với giọng thật số 3 |  | Ghi nhận rõ; không chấm thay người |  |  |

## Gợi ý video demo (5–7 phút)

1. (0:00–0:40) Giới thiệu mục tiêu Speak Up và đăng nhập learner.
2. (0:40–1:30) Hiển thị hồ sơ/rate và vào luyện phát âm; trình bày streak/tiến độ đã có.
3. (1:30–2:30) Cho xem cách rate theo 10–20 lượt gần nhất được dùng để phân nhóm.
4. (2:30–3:40) Đăng nhập mentor, tạo nhóm từ các learner cùng band, chỉ ra thành viên chờ nếu chưa đủ bốn người.
5. (3:40–4:30) Mở màn hình learner để xác nhận nhóm và mentor.
6. (4:30–5:30) Minh họa nhắc local; tạo submission/comment kiểm thử để thấy FCM trên thiết bị nhận.
7. (5:30–6:30) Thử với ba giọng thật, nêu kết quả thực tế đã điền trong bảng.

Không dựng video hay điền kết quả giọng nói giả; các bước đó cần thiết bị, tài khoản và người kiểm thử thật.
