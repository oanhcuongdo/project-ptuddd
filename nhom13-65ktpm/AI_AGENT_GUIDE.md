# Hướng Dẫn Dành Cho AI Agent — Nhóm 13 (65KTPM)

> **Mục đích:** Tài liệu này là kim chỉ nam bắt buộc cho AI Agent (Cursor, Copilot, Antigravity, Claude Code...) của từng thành viên khi hỗ trợ code dự án **TLU PeerLearn**. Mọi AI Agent phải đọc và tuân thủ nghiêm ngặt để đảm bảo **4 thành viên làm việc song song, độc lập, không xung đột code (merge conflict)** và **đúng quy chuẩn nộp bài của giảng viên**.

---

## 1. Quy Chuẩn Thư Mục & Git Workflow (Bắt Buộc)

- **Thư mục gốc của nhóm:** `nhom13-65ktpm/` (nằm tại root của repo `project-ptuddd`).
  - Toàn bộ mã nguồn Flutter (`nhom13-65ktpm/tlu_peerlearn/`), Supabase (`nhom13-65ktpm/supabase/`), và tài liệu đều **chỉ được phép nằm bên trong `nhom13-65ktpm/`**.
  - **Nghiêm cấm** tạo hoặc sửa file ở thư mục gốc `project-ptuddd/` (như `README.md`, `.gitignore`) hoặc thư mục của nhóm khác.
- **Nhánh tích hợp chính của nhóm:** `nhom/nhom13-65ktpm` (trên repo đã fork của nhóm).
  - **Nghiêm cấm** commit/push trực tiếp lên nhánh `main`.
- **Quy trình làm việc của từng thành viên:**
  1. **Luôn `git fetch origin` và `git pull --rebase origin nhom/nhom13-65ktpm`** trước khi bắt đầu làm việc và trước mỗi lần `git push` để tránh lỗi `rejected (fetch first)`.
  2. Tạo nhánh con riêng cho tính năng của mình:
     - `feat/minhanh-acc-adm` (Phùng Minh Anh)
     - `feat/phuoc-rom` (Phạm Văn Phước)
     - `feat/tuananh-doc-ai` (Ngô Tuấn Anh)
     - `feat/tuanson-pra-ses` (Nguyễn Đình Tuấn Sơn)
  3. Commit theo chuẩn Conventional Commits:
     - `feat(<module>): <mô tả ngắn>` (VD: `feat(rom): implement compatibility scoring`)
     - `fix(<module>): <mô tả ngắn>`
     - `chore(<module>): <mô tả ngắn>`
  4. **Bắt buộc** push nhánh con lên `origin` và tạo **Pull Request (PR) vào nhánh `nhom/nhom13-65ktpm`**. **Nghiêm cấm** push trực tiếp lên nhánh chung `nhom/nhom13-65ktpm` (trừ Trưởng nhóm khi hợp nhất PR).
  5. Khi hoàn thiện, **Trưởng nhóm** sẽ tạo Pull Request từ nhánh `nhom/nhom13-65ktpm` lên nhánh `main` của repo giảng viên (`upstream`).

---

## 2. Tech Stack & Kiến Trúc Chung

- **Frontend:** Flutter + Dart
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** GoRouter (`go_router`)
- **Backend / DB / Auth / Storage / Realtime:** Supabase (`supabase_flutter`)
- **AI:** Supabase Edge Functions + Gemini API (`gemini-2.5-flash` với JSON Schema)
- **Kiến trúc thư mục trong `nhom13-65ktpm/tlu_peerlearn/lib/`:**
  ```text
  lib/
  ├── core/                  # Theme, constants, utils, supabase_client, shared widgets (Trưởng nhóm quản lý)
  ├── router/                # app_router.dart (GoRouter + auth guard) (Trưởng nhóm quản lý)
  └── features/
      ├── auth_profile/      # Module 1 (ACC) - Phùng Minh Anh
      ├── admin/             # Module 7 (ADM) - Phùng Minh Anh
      ├── room_matching/     # Module 2 (ROM) - Phạm Văn Phước
      ├── documents/         # Module 3 (DOC) - Ngô Tuấn Anh
      ├── ai_generator/      # Module 4 (AI)  - Ngô Tuấn Anh
      ├── practice_stats/    # Module 5 (PRA) - Nguyễn Đình Tuấn Sơn
      └── sessions/          # Module 6 (SES) - Nguyễn Đình Tuấn Sơn
  ```

---

## 3. Phân Chia Phạm Vi Độc Lập Cho Từng Thành Viên

> **Quy tắc vàng cho AI Agent:** Chỉ tạo, sửa, xóa file bên trong **thư mục được giao** của thành viên mình. Không tự ý sửa `lib/core/`, `lib/router/`, `pubspec.yaml` hay thư mục của thành viên khác nếu chưa thống nhất với Trưởng nhóm.

### 1. Phùng Minh Anh (Trưởng nhóm - 2351170574)
- **Nhiệm vụ:** Setup nền tảng (Phase 0) + **Module 1 (`ACC`)** + **Module 7 (`ADM`)**.
- **Thư mục sở hữu:** `lib/core/`, `lib/router/`, `lib/features/auth_profile/`, `lib/features/admin/`, `supabase/migrations/`.
- **Đầu việc chính:**
  - Khởi tạo project Flutter, cấu hình Supabase (SQL schema, RLS, Storage buckets `room-documents` & `session-evidences`, Seed Data).
  - `ACC`: Đăng ký, đăng nhập (Student/Admin), hồ sơ sinh viên, đăng ký vai trò Mentor/Mentee theo học phần (kèm 21 khung lịch rảnh).
  - `ADM`: Dashboard tổng quan trên Mobile, danh sách phòng học, kiểm tra nhật ký & ảnh minh chứng buổi học.

### 2. Phạm Văn Phước (Thành viên 1 - 2251172456)
- **Nhiệm vụ:** **Module 2 (`ROM` - Gợi ý kết nối & Quản lý Phòng học tập)**.
- **Thư mục sở hữu:** `lib/features/room_matching/`.
- **Đầu việc chính:**
  - Thuật toán gợi ý kết nối **Weighted Compatibility Scoring** ($S = 0.50 S_{time} + 0.30 S_{academic} + 0.20 S_{capacity}$).
  - Màn hình danh sách gợi ý Mentor/Mentee kèm `%` độ phù hợp.
  - Tạo phòng học (`study_rooms`), sinh mã phòng (`Room Code`), gửi/nhận/chấp nhận lời mời (`room_invitations`), tham gia bằng mã phòng, quản lý thành viên (`room_members`).
  - Xây dựng **Màn hình Chi tiết Phòng học (`StudyRoomDetailScreen`)** dạng TabBar/Shell gồm 4 tab: *Tổng quan/Thành viên* (của Phước), *Tài liệu* (nhúng `RoomDocumentsTab`), *Ôn tập* (nhúng `RoomPracticeTab`), *Buổi học* (nhúng `RoomSessionsTab`).

### 3. Ngô Tuấn Anh (Thành viên 2 - 2351170570)
- **Nhiệm vụ:** **Module 3 (`DOC` - Kho học liệu)** + **Module 4 (`AI` - Tạo nội dung ôn tập)**.
- **Thư mục sở hữu:** `lib/features/documents/`, `lib/features/ai_generator/`, `supabase/functions/generate-learning-content/`.
- **Đầu việc chính:**
  - `DOC`: Upload/tải về/xóa/tìm kiếm file `.pdf` và `.docx` ($\le 5\text{MB}$) trên Supabase Storage (`room-documents`).
  - Trích xuất văn bản trên Flutter Client bằng `syncfusion_flutter_pdf` và `archive` + `xml` (cắt tối đa **15.000 ký tự đầu tiên**).
  - `AI`: Viết Supabase Edge Function gọi Gemini API (`gemini-2.5-flash`) với Structured Outputs (JSON Schema) để sinh Flashcard (5–20 thẻ) và Quiz 4 lựa chọn (5–20 câu).
  - Màn hình kiểm duyệt bản nháp (`Draft`), chỉnh sửa/xóa câu hỏi/thẻ và nhấn **Phát hành (`Published`)**.
- **Widget xuất ra để tích hợp:** `RoomDocumentsTab(roomId: String)` (dùng cho tab *Tài liệu* trong `StudyRoomDetailScreen`).

### 4. Nguyễn Đình Tuấn Sơn (Thành viên 3 - 2351170616)
- **Nhiệm vụ:** **Module 5 (`PRA` - Ôn tập & Thống kê)** + **Module 6 (`SES` - Quản lý buổi học & Minh chứng)**.
- **Thư mục sở hữu:** `lib/features/practice_stats/`, `lib/features/sessions/`.
- **Đầu việc chính:**
  - `PRA`: Học Flashcard lật 2 mặt (đánh dấu *"Đã nhớ"* / *"Chưa nhớ"*, lọc thẻ chưa nhớ), làm bài Quiz & chấm điểm tự động (thang 10), xem giải thích chi tiết, thống kê theo từng bài Quiz (tỷ lệ đúng từng câu) và thống kê tổng hợp cá nhân/phòng học.
  - `SES`: Lập kế hoạch buổi học, tạo lịch học, điểm danh (`Có mặt` / `Vắng mặt`), nén ảnh (`flutter_image_compress` < 500KB) và upload minh chứng lên bucket `session-evidences`, nút **"Xác nhận tham gia"** độc lập cho Mentee (không chặn báo cáo của Mentor).
- **Widget xuất ra để tích hợp:** `RoomPracticeTab(roomId: String)` và `RoomSessionsTab(roomId: String)` (dùng cho tab *Ôn tập* và *Buổi học* trong `StudyRoomDetailScreen`).

---

## 4. Lưu Ý Khi Kiểm Thử (Test) Độc Lập

- Mỗi nhiệm vụ/chức năng hoàn thành đều tạo 1 commit riêng thay vì làm tất cả module rồi mới commit 1 lần
- Trước khi merge vào `nhom/nhom13-65ktpm`, mỗi thành viên tự chạy `flutter analyze` để đảm bảo **0 errors, 0 warnings** trong phần code của mình.
- Sử dụng **Seed Data** trên Supabase (do Trưởng nhóm tạo sẵn ở Phase 0) để test độc lập từng module mà không cần chờ thành viên khác hoàn thành UI.

---

## 5. Bảo Mật & Lưu Ý Quan Trọng Cho AI Agent

- **Tuyệt đối không commit bí mật (Secrets):**
  - Không bao giờ commit file `.env`, `google-services.json` chứa key nhạy cảm, `GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, hoặc bất kỳ token/mật khẩu nào lên Git.
  - Luôn kiểm tra `.gitignore` và chỉ commit `.env.example` (chỉ chứa tên biến, không chứa giá trị thật).
- **Không hardcode key & Không tự ý fake cấu hình:**
  - Mọi cấu hình nhạy cảm trên Flutter phải đọc qua `flutter_dotenv` (`dotenv.maybeGet(...)`).
  - `GEMINI_API_KEY` chỉ được lưu trong **Supabase Edge Function Secrets**, tuyệt đối không đặt trong code Flutter Client.
  - Khi một tính năng cần thông tin/cấu hình từ phía người dùng để chạy thật (như `.env` chứa `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GEMINI_API_KEY`, hoặc tài khoản đăng nhập), **Agent phải yêu cầu thành viên tự điền/cung cấp**, tuyệt đối không tự ý fake dữ liệu hay bypass luồng thật.
- **Thao tác Git an toàn:**
  - Không dùng `git add -A` hoặc `git add .` một cách mù quáng ở thư mục gốc; luôn kiểm tra `git status` trước khi commit để chắc chắn không dính file rác hoặc file `.env`.
  - Không dùng `git push --force` lên nhánh chung `nhom/nhom13-65ktpm`.
- **Chất lượng code & Kiểm thử:**
  - **Bắt buộc đọc [BUSINESS_RULES.md](./BUSINESS_RULES.md) và [ERROR_NOTES.md](./ERROR_NOTES.md)** trước khi code để đảm bảo đúng nghiệp vụ và không lặp lại lỗi cũ.
  - **Bắt buộc viết Unit/Widget Test** cho mỗi tính năng/luồng mới và chạy `flutter analyze` + `flutter test` đạt 0 lỗi trước khi commit.
  - Khi phát hiện lỗi mới trong quá trình làm việc, ghi ngắn gọn vào `ERROR_NOTES.md`.
  - Không tự ý xóa hoặc làm yếu (relax) test/assertion chỉ để pass.


