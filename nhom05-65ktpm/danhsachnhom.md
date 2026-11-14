# Danh Sách Thành Viên - Nhóm 05

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Speak Up – Ứng dụng học tiếng Anh với tính năng phân tích phát âm AI
- **Giảng viên hướng dẫn:** [Tên giảng viên]

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| --- | --------- | ------------ | ------------- | ------- | ------------------- | ------------- | ----- |
| 1 | Phạm Quang Anh | 2351170573 | 65KTPM | Trưởng nhóm | F4 – Phân tích phát âm AI (Azure Pronunciation Assessment, chấm offline dự phòng); quản lý repo, review, báo cáo, slide | 25% | [email] |
| 2 | Nguyễn Phúc Bình An | 2051063858 | 65KTPM | Thành viên | F3 – Ghi âm, nhận dạng giọng nói, màn hình luyện tập; F8 – Nghe lại và so sánh bản ghi | 25% | [email] |
| 3 | Ngô Đức Nam Khánh | 2351060452 | 65KTPM | Thành viên | F2 – Bài học; F5 – Phản hồi, ánh xạ lỗi âm vị, thuật toán Needleman–Wunsch | 25% | [email] |
| 4 | Dương Văn Hưng | 2351170597 | 65KTPM | Thành viên | F1 – Hồ sơ người học; F6 – Tiến độ, streak, biểu đồ; F7 – Nhắc nhở; kiểm thử thủ công, video demo | 25% | [email] |

## Hướng Dẫn Thiết Lập Và Chạy Ứng Dụng

### Yêu cầu môi trường
- Flutter SDK 3.x (Dart 3.x), Android Studio + Android SDK.
- Điện thoại Android thật hoặc emulator có micro và Google speech service.
- (Khi dùng AI chấm điểm) Khóa Azure Speech và vùng (region). Không commit khóa lên repo.

### Các bước chạy
```bash
cd nhom05-65ktpm/src
flutter pub get
flutter run --dart-define=AZURE_SPEECH_KEY=<khoa> --dart-define=AZURE_SPEECH_REGION=<vung>
flutter test
```

Không truyền khóa Azure thì ứng dụng chấm điểm bằng thuật toán offline.
