# Danh Sách Thành Viên & Phân Công Nhiệm Vụ - Nhóm 11

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** ChaiLish - Ứng dụng học tiếng Trung tích hợp AI chấm phát âm, luyện viết Hán tự
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường
- **Kho lưu trữ nội bộ (Fork):** [https://github.com/LoudlyDawn2108/project-ptuddd](https://github.com/LoudlyDawn2108/project-ptuddd)
- **Nhánh phát triển chính:** `nhom/nhom11-65ktpm`

---

## 1. Bảng Thông Tin Thành Viên & Phân Công Nhiệm Vụ

| STT | Họ và Tên | Mã Sinh Viên | GitHub Username | Vai Trò | Nhiệm Vụ Phân Công Chi Tiết | Đóng Góp (%) | Issues Đảm Nhiệm |
| :---: | :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| 1 | **Nguyễn Hồng Phúc** | 2351170611 | `@LoudlyDawn2108` | **Trưởng nhóm** | - Thiết kế UI/UX Figma, dựng khung Clean Architecture Flutter (Riverpod, GoRouter, Theme).<br>- Khởi tạo FastAPI Backend, PostgreSQL schema, Alembic migration.<br>- Xây dựng hệ thống Auth JWT, bảo mật phân quyền.<br>- Đóng gói Docker Compose & cấu hình GitHub Actions CI/CD.<br>- Module AI trợ lý ôn bài (Claude API, prompt caching, streaming, structured JSON ngữ pháp).<br>- Màn hình chat AI và màn hình phân tích ngữ pháp. | 100% | #4, #5, #6, #7, #8, #9, #10 |
| 2 | **Lê Tuấn Khanh** | 2351170601 | `@khanhx419` | Thành viên | - Service thu âm WAV & nhận dạng giọng nói zh-CN trên Flutter.<br>- Tích hợp TTS tiếng Trung (1.0x & 0.7x), engine tra Pinyin CC-CEDICT (xử lý đa âm, biến điệu).<br>- Thuật toán chấm phát âm Offline (Levenshtein trọng số, phân tích Thanh - Vần - Điệu, ma trận phạt lỗi người Việt).<br>- API chấm phát âm Online qua Azure AI Speech & cơ chế tự động Fallback Offline.<br>- Màn hình Luyện phát âm & Màn hình Phản hồi kết quả chấm chi tiết.<br>- Unit test & Widget test module giọng nói. | 100% | #11, #12, #13, #14, #15, #16 |
| 3 | **Đinh Thị Hoa** | 2351170593 | `@dinhhoa65ktpm` | Thành viên | - Soạn thảo và chuẩn hóa bộ dữ liệu từ vựng HSK 1-2 (~300 từ kèm âm Hán Việt, ví dụ).<br>- Thiết kế cấu trúc JSON bài học & script nạp dữ liệu vào PostgreSQL.<br>- Màn hình Danh sách bài học, Chi tiết bài học, Chi tiết từ vựng HSK.<br>- Module Flashcard ôn tập & thuật toán lặp lại ngắt quãng SM-2.<br>- Hệ thống Gamification / Huy hiệu thành tích.<br>- Soạn mẹo khẩu hình phát âm & bộ test case thực nghiệm cho engine chấm âm. | 100% | #17, #18, #19, #20, #21, #22 |
| 4 | **Chu Hữu Đệ** | 2251172273 | `@chuhuude` | Thành viên | - Thiết kế CSDL SQLite cục bộ trên Flutter (sqflite, repositories, migrations).<br>- Luồng màn hình Đăng ký, Đăng nhập, Quên mật khẩu (OTP), Hồ sơ & Cài đặt.<br>- Cơ chế đồng bộ Offline-First hai chiều (Sync Outbox, retry, push/pull).<br>- Màn hình Luyện viết Hán tự bằng CustomPainter (chế độ Xem nét mẫu, Tô nét mờ, Viết tự do).<br>- Thuật toán kiểm tra nét viết chữ Hán theo thời gian thực (vị trí, hướng, thứ tự nét).<br>- Thông báo nhắc học hằng ngày & Màn hình Bảng xếp hạng tuần. | 100% | #23, #24, #25, #26, #27, #28 |
| 5 | **Phạm Vũ Ngọc Bảo** | 2251172249 | `@ngxcbao` | Thành viên | - Màn hình Bản đồ Lộ trình học tương tác (Learning Path Map, mở khóa khi đạt 70đ).<br>- Bài kiểm tra đầu vào (Placement Test) phân cấp trình độ.<br>- Màn hình Trang chủ (Dashboard tổng quan: Daily Plan, Streak, XP, bài tiếp theo).<br>- Module Bài kiểm tra ngắn cuối chặng theo format đề thi HSK.<br>- Màn hình Thống kê tiến độ học tập (biểu đồ phút học fl_chart, độ chính xác thanh điệu).<br>- Điều phối kiểm thử hệ thống E2E, chuẩn bị Slide thuyết trình & kịch bản demo nghiệm thu. | 100% | #29, #30, #31, #32, #33, #34 |

---

## 2. Quy Trình Phối Hợp Làm Việc & Kiểm Tra Chéo (Git Flow & PR Review)

Toàn bộ các thành viên tuân thủ nghiêm ngặt quy tắc:
1. **Kho lưu trữ:** Chỉ thao tác trên kho Fork `https://github.com/LoudlyDawn2108/project-ptuddd`, **không đẩy trực tiếp lên kho của giảng viên**.
2. **Nhánh gốc nội bộ:** Mọi tính năng đều rẽ nhánh từ `nhom/nhom11-65ktpm` và mở Pull Request hợp nhất về lại `nhom/nhom11-65ktpm`.
3. **Quy tắc tạo nhánh:**
   ```bash
   git checkout nhom/nhom11-65ktpm
   git pull origin nhom/nhom11-65ktpm
   git checkout -b <loai-thay-doi>/<ten-thanh-vien>/<ten-tinh-nang>
   # Ví dụ: git checkout -b feat/khanh/voice-recording-stt
   ```
4. **Quy tắc Commit:** Chỉ commit file trong thư mục `nhom11-65ktpm/`:
   ```bash
   git add nhom11-65ktpm/
   git commit -m "feat(nhom11-65ktpm): <noi-dung-thay-doi> (#<so-issue>)"
   git push origin <ten-nhanh-tinh-nang>
   ```
5. **Mở Pull Request & Review chéo:**
   - Mở PR trên GitHub với Base branch là `nhom/nhom11-65ktpm`.
   - Gắn Reviewer là thành viên phụ trách mảng liên quan (đã được ghi chú cụ thể trong từng Issue).
   - Tối thiểu 1 thành viên review, để lại phản hồi (comment) và phê duyệt (Approve) trước khi gộp (Merge).

---

## 3. Hướng Dẫn Cài Đặt & Khởi Chạy Dự Án

### 3.1. Khởi chạy Ứng dụng Di động (Flutter App)
```bash
cd nhom11-65ktpm/src/app
flutter pub get
flutter run
```

### 3.2. Khởi chạy Máy chủ API (FastAPI Backend)
```bash
cd nhom11-65ktpm/src/server
python -m venv .venv
source .venv/bin/activate   # Trên Windows: .venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --port 8000
```
Tài liệu API Swagger tự động: `http://localhost:8000/docs`
