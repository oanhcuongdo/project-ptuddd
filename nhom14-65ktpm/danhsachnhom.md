# Danh Sách Thành Viên - Nhóm 14

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Xây dựng hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp cho sinh viên
- **Mục tiêu tổng quát:** Xây dựng một hệ thống đa nền tảng (Flutter + Supabase) hỗ trợ sinh viên chủ động định hướng và chuẩn bị thực hiện đồ án tốt nghiệp thông qua việc tra cứu dữ liệu đồ án các khóa trước, sử dụng AI để tham khảo và đối chiếu hướng đề tài, quản lý đề tài cá nhân và lập kế hoạch học tập, thực hiện.
- **Giảng viên hướng dẫn:** ThS. Đỗ Oanh Cường
- **Repository nhóm:** `Maya0612/project-ptuddd` (nhánh tích hợp chung: `nhom14-65ktpm`)

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :---: | --------- | :----------: | :-----------: | ------- | ------------------- | :----------: | ----- |
| 1 | Đào Hà Thu | 2351170623 | 65KTPM | Trưởng nhóm | Kiến trúc tổng thể, thiết lập Flutter & Supabase, Supabase Auth, bảng `profiles`, RLS nền tảng, thống nhất CSDL, cấu trúc UI chung & tích hợp | 100% | 2351170623@e.tlu.edu.vn |
| 2 | Phạm Kim Anh | 2351170572 | 65KTPM | Thành viên | Kho đồ án (`projects`, `fields`, `favorites`), tìm kiếm/lọc/chi tiết, yêu thích, đề xuất bổ sung đồ án & cơ chế Admin/GV duyệt đề xuất | 100% | 2351170572@e.tlu.edu.vn |
| 3 | Trần Đức Trung | 2251162191 | 64... | Thành viên | AI gợi ý (3–5 đề tài) & đối chiếu kho đồ án đã duyệt qua backend/Edge Function, thiết kế I/O AI, xử lý lỗi API & dữ liệu không hợp lệ | 100% | 2251162191@e.tlu.edu.vn |
| 4 | Trịnh Mạnh Đức | 2251243284 | 64... | Thành viên | Quản lý đề tài cá nhân (`personal_topics`), CRUD đề tài từ ý tưởng cá nhân/gợi ý AI, quản lý trạng thái, phân quyền theo tài khoản sinh viên | 100% | 2251243284@e.tlu.edu.vn |
| 5 | Vương Tiến Dũng | 2351170586 | 65KTPM | Thành viên | Lập kế hoạch & theo dõi tiến độ (`plans`, `tasks`), quản lý đầu việc/thời hạn/trạng thái, hiển thị tiến độ & liên kết đề tài cá nhân | 100% | 2351170586@e.tlu.edu.vn |

## Phân Công Chi Tiết Và Quy Ước Branch Cá Nhân

> **Nguyên tắc phối hợp:** Mỗi thành viên chịu trách nhiệm chính về module được giao. TV1 phụ trách kiến trúc, nền tảng và tích hợp tổng thể, không có nghĩa là phải tự viết lại toàn bộ chức năng của các thành viên khác.

| Mã TV | Thành Viên | Branch Cá Nhân Cố Định | Bảng CSDL Chính | Phạm Vi Nhiệm Vụ Chi Tiết |
| :---: | ---------- | ---------------------- | --------------- | ------------------------- |
| **TV1** | Đào Hà Thu (Trưởng nhóm) | `feature/nhom14/foundation-auth` | `profiles` (và tổng hợp toàn schema) | - Kiến trúc tổng thể và cấu trúc dự án.<br>- Thiết lập môi trường Flutter và kết nối Supabase.<br>- Supabase Auth: đăng ký, đăng nhập, đăng xuất.<br>- Thiết kế & quản lý bảng `profiles`, thiết lập quy tắc phân quyền và RLS nền tảng.<br>- Tổng hợp, rà soát và thống nhất thiết kế CSDL của các module.<br>- Xây dựng cấu trúc giao diện chung, điều phối và hỗ trợ tích hợp các module. |
| **TV2** | Phạm Kim Anh | `feature/nhom14/project-repository` | `projects`, `fields`, `favorites` | - Phụ trách kho đồ án.<br>- Thiết kế các bảng `projects`, `fields`, `favorites`.<br>- Xây dựng chức năng quản lý đồ án.<br>- Xây dựng tìm kiếm, lọc và xem chi tiết đồ án.<br>- Xây dựng chức năng yêu thích.<br>- Xây dựng chức năng sinh viên đề xuất bổ sung đồ án và cơ chế Admin/Giảng viên duyệt trước khi đưa vào kho chính thức. |
| **TV3** | Trần Đức Trung | `feature/nhom14/ai-suggestions` | Đối chiếu `projects` (đã duyệt) | - Phụ trách chức năng AI gợi ý và đối chiếu đề tài.<br>- Thiết kế dữ liệu đầu vào và đầu ra của AI.<br>- Tích hợp AI API thông qua backend/Edge Function phù hợp.<br>- Đề xuất khoảng 3–5 đề tài dựa trên thông tin sinh viên cung cấp và đối chiếu với dữ liệu đồ án đã được duyệt trong kho.<br>- Xử lý lỗi API và các trường hợp dữ liệu không hợp lệ.<br>- *Giới hạn phạm vi:* Không xây dựng chatbot đa năng hoặc huấn luyện mô hình AI riêng. |
| **TV4** | Trịnh Mạnh Đức | `feature/nhom14/personal-topics` | `personal_topics` | - Phụ trách quản lý đề tài cá nhân.<br>- Thiết kế bảng `personal_topics`.<br>- Xây dựng chức năng thêm, xem, sửa, xóa đề tài cá nhân.<br>- Cho phép tạo đề tài từ ý tưởng cá nhân hoặc lưu từ gợi ý AI.<br>- Quản lý trạng thái và thông tin của từng đề tài.<br>- Đảm bảo dữ liệu được phân quyền theo tài khoản sinh viên. |
| **TV5** | Vương Tiến Dũng | `feature/nhom14/planning-progress` | `plans`, `tasks` | - Phụ trách lập kế hoạch và theo dõi tiến độ.<br>- Thiết kế các bảng `plans`, `tasks`.<br>- Xây dựng chức năng tạo và quản lý kế hoạch.<br>- Xây dựng các đầu việc, thời hạn và trạng thái công việc.<br>- Hiển thị tiến độ thực hiện.<br>- Liên kết kế hoạch với đề tài cá nhân của sinh viên. |

> **Tài liệu quy trình bắt buộc:** Toàn bộ thành viên đọc kỹ hướng dẫn Git/GitHub, Pull Request, Review, Merge, Issue/Project Board và quy ước thiết kế CSDL tại [`docs/GIT_WORKFLOW.md`](./docs/GIT_WORKFLOW.md) trước khi bắt đầu code.

## Hướng Dẫn Thiết Lập Môi Trường Và Khởi Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- **Flutter SDK:** Phiên bản 3.24 trở lên (khuyến nghị Flutter 3.47+ tương thích Dart SDK `^3.13.5` theo `src/pubspec.yaml`). Kiểm tra bằng `flutter --version`.
- **IDE:** Android Studio hoặc VS Code (đã cài đặt tiện ích mở rộng **Flutter** và **Dart**).
- **Môi trường chạy/kiểm thử:**
  - Thiết bị Android thật (đã bật USB Debugging) hoặc máy ảo Android Emulator (AVD).
  - Hoặc Windows Desktop (đã cài *Desktop development with C++* qua Visual Studio Build Tools).
- **Git:** Đã cấu hình danh tính trùng khớp GitHub cá nhân (`git config --global user.name` và `git config --global user.email`).

---

### 2. Các bước thiết lập và khởi chạy ứng dụng

#### Bước 1: Di chuyển vào thư mục mã nguồn
Mở Terminal/Command Prompt tại thư mục gốc repository và di chuyển vào `nhom14-65ktpm/src`:
```bash
cd nhom14-65ktpm/src
```

#### Bước 2: Cài đặt các gói phụ thuộc (Dependencies)
```bash
flutter pub get
```

#### Bước 3: Cấu hình biến môi trường kết nối Supabase (`env.json`)
Ứng dụng sử dụng cơ chế nạp biến môi trường an toàn tại thời điểm biên dịch qua cờ `--dart-define-from-file=env.json`:
1. Trong thư mục `nhom14-65ktpm/src/`, tạo một tệp mới tên là `env.json` dựa theo mẫu `env.json.example`:
   ```bash
   # Windows PowerShell:
   Copy-Item env.json.example env.json

   # Linux / macOS / Git Bash:
   cp env.json.example env.json
   ```
2. Mở file `env.json` vừa tạo và điền thông tin dự án Supabase dùng chung của nhóm (lấy từ Trưởng nhóm TV1, **tuyệt đối không chia sẻ công khai**):
   ```json
   {
     "SUPABASE_URL": "https://<your-project-id>.supabase.co",
     "SUPABASE_ANON_KEY": "<your-publishable-or-anon-key>"
   }
   ```
   > ⚠️ **Quy tắc bảo mật bắt buộc:** Tệp `env.json` đã được đưa vào `.gitignore`. Tuyệt đối **KHÔNG** commit `env.json`, API key bí mật (`service_role`), mật khẩu Database lên Git.

#### Bước 4: Kiểm tra thiết bị sẵn sàng
```bash
flutter devices
```

#### Bước 5: Khởi chạy ứng dụng
Chạy ứng dụng kèm cờ nạp cấu hình `env.json`:
```bash
# Khởi chạy mặc định (chọn thiết bị đang kết nối):
flutter run --dart-define-from-file=env.json

# Hoặc khởi chạy trên Windows Desktop:
flutter run -d windows --dart-define-from-file=env.json
```

#### Bước 6: Chạy kiểm thử tự động (Unit & Widget Tests)
Trước khi tạo commit hoặc mở Pull Request, chạy kiểm thử để đảm bảo không làm gãy mã nguồn nền tảng:
```bash
flutter test --dart-define-from-file=env.json
```

---

### 3. Quy trình làm việc với Git cho từng thành viên

1. **Đồng bộ nhánh nhóm trước khi làm việc:**
   ```bash
   git checkout nhom14-65ktpm
   git pull origin nhom14-65ktpm
   ```
2. **Chuyển sang nhánh tính năng cá nhân:**
   Mỗi thành viên làm việc trên nhánh chuẩn `feature/nhom14/<ten-tinh-nang>`:
   ```bash
   # Nếu nhánh chưa tồn tại ở local:
   git checkout -b feature/nhom14/<ten-tinh-nang>
   git push -u origin feature/nhom14/<ten-tinh-nang>

   # Nếu nhánh đã có:
   git checkout feature/nhom14/<ten-tinh-nang>
   git merge nhom14-65ktpm
   ```
3. **Commit đúng quy chuẩn:**
   Chỉ stage thư mục nhóm:
   ```bash
   git status
   git add nhom14-65ktpm/
   git commit -m "feat(nhom14): <mô tả công việc đã làm>"
   git push origin feature/nhom14/<ten-tinh-nang>
   ```
4. **Mở Pull Request (PR):**
   - Base branch: `nhom14-65ktpm`
   - Compare branch: `feature/nhom14/<ten-tinh-nang>`
   - Nhờ thành viên khác review trước khi merge. Không xóa các nhánh feature cố định.

---

### 4. Xử lý các lỗi thiết lập thường gặp

- **Lỗi: `⚠️ CẢNH BÁO: Chưa tìm thấy SUPABASE_URL hoặc SUPABASE_ANON_KEY`:**
  - *Nguyên nhân:* Bạn quên truyền cờ `--dart-define-from-file=env.json` khi chạy lệnh `flutter run`.
  - *Khắc phục:* Đảm bảo file `nhom14-65ktpm/src/env.json` đã được tạo và luôn chạy kèm tham số: `flutter run --dart-define-from-file=env.json`.
- **Lỗi: `CocoaPods not installed` hoặc thiếu Visual Studio C++ Build Tools:**
  - *Khắc phục:* Nếu chạy trên Windows Desktop, cần cài đặt Visual Studio Community (tích chọn *Desktop development with C++*). Nếu chạy trên Android, mở Android Studio và chạy máy ảo Android Emulator để thay thế.
- **Lỗi: `Target of URI doesn't exist` hoặc xung đột package:**
  - *Khắc phục:* Chạy `flutter clean` rồi chạy lại `flutter pub get`.
- **Lỗi: Git báo `non-fast-forward` khi push:**
  - *Khắc phục:* Chạy `git pull --rebase origin feature/nhom14/<ten-tinh-nang>` rồi mới `git push`.
