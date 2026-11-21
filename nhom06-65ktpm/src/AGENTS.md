# HealthyLife — hướng dẫn cho AI làm việc trong src

## Đọc trước khi làm

1. Đọc README.md tại đây: trạng thái cấu hình, cách chạy, nhiệm vụ và ranh giới các module.
2. Đọc issue được thành viên giao trên kho Fork `trggg2185/project-ptdudd`, nhất là checklist, phụ thuộc và reviewer. Nếu chưa truy cập được GitHub, yêu cầu nội dung issue; không đoán rằng việc đã xong.
3. Đọc ../docs/GITHUB_PROJECT.md và ../docs/HealthyLife_Nhom06_De_cuong.md khi cần nghiệp vụ, đầu vào và tiêu chí nghiệm thu.
4. Đọc ../../README.md để tuân thủ quy trình của giảng viên.

## Phạm vi và hiện trạng

- Chỉ sửa bên trong `nhom06-65ktpm/`. Không sửa root README/.gitignore, thư mục nhóm khác hay kho giảng viên.
- Đây là khung Flutter và cấu hình cloud dùng chung; `main.dart` chỉ có Hello World. Không xem việc có Firebase config hoặc package là đã làm xong đăng nhập, schema, RLS hay chức năng.
- Chỉ làm issue được giao; không tự thực hiện cả 12 issues. Không đánh dấu hoàn thành, cập nhật board hoặc đóng issue khi chưa có kiểm chứng và chưa được thành viên yêu cầu.
- Người dùng phải cho phép trước khi push, mở/merge PR, đổi cấu hình cloud hay deploy. Quyền đã được người dùng cho trong cùng phiên được áp dụng, không hỏi lại vô ích.

## Cấu hình và kiến trúc phải giữ

- Firebase project: `healthy-life-group-6`. Supabase ref: `vspyxavkdqqlpxodvqvb`. Android ID: `vn.edu.nhom06.healthylife`.
- Đọc `lib/firebase_options.dart` và `lib/core/backend_config.dart`. Chỉ chứa cấu hình client, không thêm khóa quản trị hoặc bí mật.
- Không tạo Firebase/Supabase project mới cho mỗi người; không tự chạy lại FlutterFire hoặc đổi app ID trên nhánh tính năng. Nếu phải thay cấu hình dùng chung, trao đổi nhóm trưởng trước.
- Firebase Authentication là nguồn danh tính duy nhất. Supabase Database/Storage nhận Firebase JWT bằng callback `accessToken`; không tạo thêm hệ đăng nhập Supabase/Firestore thay cho thiết kế.
- Firebase UID là chuỗi: cột owner_uid/user_uid dùng TEXT; RLS lấy `auth.jwt()->>'sub'`, không ép UID Firebase sang UUID bằng `auth.uid()`.
- Claim `role: authenticated` chỉ được cấp bởi bên quản trị tin cậy; không giả lập token hoặc tắt RLS để khắc phục lỗi quyền.
- Mỗi feature có data/domain/presentation, tái sử dụng thành phần sẵn có. Chỉ thêm thư viện khi issue thực sự cần và cập nhật lockfile.
- Chỉ Trưởng tích hợp khởi tạo, main và điều hướng chung; người khác đề xuất giao diện kết nối và mock để làm độc lập. Hà review migration/RLS/Storage. Không chạy migration hoặc deploy cloud khi chưa được phép.
- iOS mới có khung, chưa có Firebase config. Android/Web là hai nền tảng đang chuẩn bị cấu hình.

## Git và nghiệm thu

- Chạy `git status`, kiểm tra thay đổi sẵn có; không xóa/ghi đè công việc người khác hoặc rewrite lịch sử.
- Nhánh tính năng bắt đầu từ `nhom06-65ktpm`; PR nội bộ base cùng tên trên Fork. Không commit/push main, không push upstream hoặc mở PR sang thầy khi chưa được yêu cầu riêng.
- Khi được yêu cầu commit: từ root dùng `git add nhom06-65ktpm/` hoặc chỉ định chính xác file; kiểm tra staged diff trước commit. Không dùng git add . ở root.
- Kiểm tra phù hợp với thay đổi: phân tích tĩnh, kiểm thử nghiệp vụ, máy thật cho cảm biến. Ghi chính xác đã chạy gì và chưa chạy gì; không báo đã kiểm thử đăng nhập/RLS chỉ vì build thành công.
- Không lưu mật khẩu, service-account private key, service_role, secret API key, Firebase CLI token hoặc dữ liệu sức khỏe thật trong repository/log/chat. Không gửi token ra ngoài hai dự án đã xác định.
