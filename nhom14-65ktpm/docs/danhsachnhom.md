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
| **TV1** | Đào Hà Thu (Trưởng nhóm) | `feature/tv1-foundation-auth` | `profiles` (và tổng hợp toàn schema) | - Kiến trúc tổng thể và cấu trúc dự án.<br>- Thiết lập môi trường Flutter và kết nối Supabase.<br>- Supabase Auth: đăng ký, đăng nhập, đăng xuất.<br>- Thiết kế & quản lý bảng `profiles`, thiết lập quy tắc phân quyền và RLS nền tảng.<br>- Tổng hợp, rà soát và thống nhất thiết kế CSDL của các module.<br>- Xây dựng cấu trúc giao diện chung, điều phối và hỗ trợ tích hợp các module. |
| **TV2** | Phạm Kim Anh | `feature/tv2-project-repository` | `projects`, `fields`, `favorites` | - Phụ trách kho đồ án.<br>- Thiết kế các bảng `projects`, `fields`, `favorites`.<br>- Xây dựng chức năng quản lý đồ án.<br>- Xây dựng tìm kiếm, lọc và xem chi tiết đồ án.<br>- Xây dựng chức năng yêu thích.<br>- Xây dựng chức năng sinh viên đề xuất bổ sung đồ án và cơ chế Admin/Giảng viên duyệt trước khi đưa vào kho chính thức. |
| **TV3** | Trần Đức Trung | `feature/tv3-ai-suggestions` | Đối chiếu `projects` (đã duyệt) | - Phụ trách chức năng AI gợi ý và đối chiếu đề tài.<br>- Thiết kế dữ liệu đầu vào và đầu ra của AI.<br>- Tích hợp AI API thông qua backend/Edge Function phù hợp.<br>- Đề xuất khoảng 3–5 đề tài dựa trên thông tin sinh viên cung cấp và đối chiếu với dữ liệu đồ án đã được duyệt trong kho.<br>- Xử lý lỗi API và các trường hợp dữ liệu không hợp lệ.<br>- *Giới hạn phạm vi:* Không xây dựng chatbot đa năng hoặc huấn luyện mô hình AI riêng. |
| **TV4** | Trịnh Mạnh Đức | `feature/tv4-personal-topics` | `personal_topics` | - Phụ trách quản lý đề tài cá nhân.<br>- Thiết kế bảng `personal_topics`.<br>- Xây dựng chức năng thêm, xem, sửa, xóa đề tài cá nhân.<br>- Cho phép tạo đề tài từ ý tưởng cá nhân hoặc lưu từ gợi ý AI.<br>- Quản lý trạng thái và thông tin của từng đề tài.<br>- Đảm bảo dữ liệu được phân quyền theo tài khoản sinh viên. |
| **TV5** | Vương Tiến Dũng | `feature/tv5-planning-progress` | `plans`, `tasks` | - Phụ trách lập kế hoạch và theo dõi tiến độ.<br>- Thiết kế các bảng `plans`, `tasks`.<br>- Xây dựng chức năng tạo và quản lý kế hoạch.<br>- Xây dựng các đầu việc, thời hạn và trạng thái công việc.<br>- Hiển thị tiến độ thực hiện.<br>- Liên kết kế hoạch với đề tài cá nhân của sinh viên. |

> **Tài liệu quy trình bắt buộc:** Toàn bộ thành viên đọc kỹ hướng dẫn Git/GitHub, Pull Request, Review, Merge, Issue/Project Board và quy ước thiết kế CSDL tại [`docs/GIT_WORKFLOW.md`](./docs/GIT_WORKFLOW.md) trước khi bắt đầu code.

## Hướng Dẫn Thiết Lập Môi Trường Và Khởi Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- Flutter SDK (khuyến nghị bản ổn định mới nhất, tương thích Dart SDK theo `src/pubspec.yaml`).
- Android Studio hoặc VS Code (đã cài đặt extension **Flutter** và **Dart**).
- Thiết bị giả lập Android (AVD) hoặc thiết bị thật đã bật **USB Debugging** (hoặc trình duyệt Chrome/Windows desktop để kiểm thử nhanh).
- Tài khoản Git đã cấu hình trùng với tài khoản GitHub cá nhân (xem [`docs/GIT_WORKFLOW.md`](./docs/GIT_WORKFLOW.md)).

### 2. Các bước cài đặt và khởi chạy
1. Mở Terminal và chuyển vào thư mục chứa mã nguồn của nhóm:
   ```bash
   cd nhom14-65ktpm/src
   ```
2. Cài đặt các gói phụ thuộc (dependencies):
   ```bash
   flutter pub get
   ```
3. Cấu hình biến môi trường cục bộ (khi TV1 hoàn tất tích hợp Supabase):
   - Tạo file `.env` theo mẫu `.env.example` (không commit file `.env`, API Key hay mật khẩu lên GitHub).
4. Kiểm tra thiết bị đang kết nối:
   ```bash
   flutter devices
   ```
5. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```
