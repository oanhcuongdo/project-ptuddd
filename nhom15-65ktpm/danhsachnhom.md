# Danh Sách Thành Viên - Nhóm 15

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Finger Math Kids App - Ứng dụng học toán ngón tay Finger Math tương tác hai bàn tay kết hợp AI trợ lý giọng nói cho trẻ 4–6 tuổi
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường

---

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :---: | :--- | :---: | :---: | :--- | :--- | :---: | :--- |
| 1 | **Dương Nguyên Anh** | 2351170569 | 65KTPM | **Trưởng nhóm** | **Tech Lead & Module 1 (Finger Math Engine):**<br>- Thiết kế quy ước toán ngón tay Tay Phải ($0 \to 9$) và Tay Trái ($10 \to 90$).<br>- Bóc tách và hiển thị bộ thẻ bài Flashcard 1D RH/LH.<br>- Xây dựng thuật toán công thức Anh Bạn Nhỏ & Anh Bạn Lớn.<br>- Quản trị Git, kiến trúc Clean Architecture, 10 Unit Tests. | 100% | duongnguyenanh.2351170569@gmail.com |
| 2 | **Phạm Duy Thái** | 2351060487 | 65KTPM | **Thành viên** | **Module 2 (Zero-Text UI & Gamification):**<br>- Thiết kế giao diện không chữ (Zero-Text UI) chuẩn trẻ mầm non.<br>- Xây dựng thuật toán tính chuỗi ngày học liên tiếp (Streak).<br>- Hiện thực Cổng phụ huynh (Parental Gate) và biểu đồ tuần `fl_chart`.<br>- Viết 3 Unit Tests quản lý thói quen. | 100% | phamduythai.2351060487@gmail.com |
| 3 | **Nguyễn Thị Thu Hoài** | 2351170594 | 65KTPM | **Thành viên** | **Module 3 (Bộ Sinh Đề & Flash Anzan):**<br>- Xây dựng bộ sinh đề toán học độc quyền phép cộng trừ không âm ($0 \to 99$).<br>- Thiết kế màn hình luyện tập theo 4 cấp độ bài học.<br>- Hiện thực chế độ tính nhẩm siêu tốc Flash Anzan chớp số.<br>- Viết 1 Unit Test tương tác giao diện. | 100% | nguyenthithuhoai.2351170594@gmail.com |
| 4 | **Nguyễn Thị Cẩm Ly** | 2351170605 | 65KTPM | **Thành viên** | **Module 4 (AI Giọng Nói & Gia Sư Thích Ứng):**<br>- Tích hợp nhận diện giọng nói tiếng Việt trẻ em (`speech_to_text`).<br>- Thuật toán bóc tách số tiếng Việt (NLP) lọc từ đệm dạ thưa.<br>- Thuật toán Gia sư thích ứng (Adaptive Learning) tự động tăng giảm tốc độ.<br>- Viết 7 Unit Tests kiểm thử NLP và AI. | 100% | nguyenthicamly.2351170605@gmail.com |

---

## Hướng Dẫn Thiết Lập Môi Trường Và Các Bước Khởi Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- **Flutter SDK:** Phiên bản $\ge 3.20.0$ (kèm theo Dart SDK $\ge 3.3.0$).
- **Môi trường chạy:**
  - Trình duyệt **Google Chrome** (chạy nền tảng Web).
  - Hoặc hệ điều hành **Windows 10/11** (chạy Windows Desktop Native qua Visual Studio C++).

### 2. Các bước cài đặt và khởi chạy
Mở Terminal / PowerShell và thực hiện lần lượt các lệnh:

```bash
# Bước 1: Di chuyển vào thư mục mã nguồn của Nhóm 15
cd nhom15-65ktpm/src

# Bước 2: Tải và cài đặt các thư viện phụ thuộc
flutter pub get

# Bước 3: Chạy toàn bộ 21 ca kiểm thử tự động (Unit Tests)
flutter test

# Bước 4: Kiểm tra phân tích tĩnh chất lượng mã nguồn (0 Errors, 0 Warnings)
dart analyze lib test

# Bước 5: Khởi chạy ứng dụng trên trình duyệt Chrome
flutter run -d chrome

# Hoặc khởi chạy ứng dụng Windows Desktop Native
flutter run -d windows
```

---

## Cam Kết Chất Lượng Nộp Bài (Checklist)
- [x] 100% mã nguồn và tài liệu nằm trọn trong thư mục `nhom15-65ktpm/`.
- [x] Làm việc hoàn toàn trên nhánh riêng `nhom15-65ktpm` và 4 nhánh tính năng độc lập, không commit trực tiếp vào `main`.
- [x] Không chỉnh sửa, không làm ảnh hưởng đến mã nguồn của các nhóm khác.
- [x] Đã cấu hình `.gitignore`, không đưa thư mục biên dịch (`build/`, `.dart_tool/`) lên kho lưu trữ.
- [x] Toàn bộ 21/21 ca kiểm thử tự động passed 100%.
- [x] Mã nguồn sạch sẽ, không có lỗi biên dịch (`0 Errors, 0 Warnings`).
- [x] Đã tạo Pull Request nộp bài chuẩn quy cách về kho lưu trữ gốc của giảng viên.
