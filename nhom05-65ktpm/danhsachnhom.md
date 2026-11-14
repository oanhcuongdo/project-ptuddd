# Danh Sách Thành Viên - Nhóm 05

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Speak Up – Ứng dụng hỗ trợ giao tiếp tiếng Anh: chấm điểm luyện tập bằng AI, xếp hạng trình độ (rate), ghép nhóm theo rate và mentor hướng dẫn thuyết trình
- **Giảng viên hướng dẫn:** [Tên giảng viên]

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| --- | --------- | ------------ | ------------- | ------- | ------------------- | ------------- | ----- |
| 1 | Phạm Quang Anh | 2351170573 | 65KTPM | Trưởng nhóm | F4 – Phân tích phát âm AI (Azure Pronunciation Assessment, chấm offline dự phòng); F9 – Xếp hạng trình độ (rate); quản lý repo, review, báo cáo, slide | 25% | [email] |
| 2 | Nguyễn Phúc Bình An | 2051063858 | 65KTPM | Thành viên | F3 – Ghi âm, nhận dạng giọng nói, màn hình luyện tập; F11 – Thuyết trình và nhận xét của mentor; F8 – Nghe lại bản ghi | 25% | [email] |
| 3 | Ngô Đức Nam Khánh | 2351060452 | 65KTPM | Thành viên | F2 – Bài học; F5 – Phản hồi, ánh xạ lỗi âm vị, Needleman–Wunsch; F6 – Tiến độ, streak, biểu đồ | 25% | [email] |
| 4 | Dương Văn Hưng | 2351170597 | 65KTPM | Thành viên | F1 – Tài khoản Firebase, vai trò học viên/mentor; F10 – Ghép nhóm theo rate; F7 – Nhắc nhở, thông báo; kiểm thử thủ công, video demo | 25% | [email] |

## Hướng Dẫn Thiết Lập Và Chạy Ứng Dụng

### Yêu cầu môi trường
- Flutter SDK 3.x (Dart 3.x), Android Studio + Android SDK.
- Điện thoại Android thật hoặc emulator có micro và Google speech service.
- Project Firebase (Auth, Firestore, Storage, Cloud Messaging); tải `google-services.json` vào `src/android/app/`. Không commit tệp này lên repo.
- (Khi dùng AI chấm điểm) Khóa Azure Speech và vùng (region). Không commit khóa lên repo.

### Các bước chạy
```bash
cd nhom05-65ktpm/src
flutter pub get
flutter run --dart-define=AZURE_SPEECH_KEY=<khoa> --dart-define=AZURE_SPEECH_REGION=<vung>
flutter test
```

Không truyền khóa Azure thì ứng dụng chấm điểm bằng thuật toán offline.
