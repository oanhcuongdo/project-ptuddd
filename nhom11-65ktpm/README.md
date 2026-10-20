# BÀI TẬP LỚN PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG (PTUDDĐ)
## HỆ THỐNG QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG VỚI FLUTTER, FIREBASE VÀ SUPABASE

- **Nhóm thực hiện:** Nhóm 11
- **Lớp học phần:** 65KTPM
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường
- **Chi tiết thành viên:** Xem tệp [danhsachnhom.md](danhsachnhom.md)

---

## 1. Tổng Quan Dự Án

Ứng dụng **Quản Lý Tài Liệu Học Tập (Study Material Manager)** được phát triển bằng Flutter theo mô hình đa nền tảng (Web, Mobile, Desktop), kết hợp với hệ sinh thái Cloud hiện đại:
- **Xác thực người dùng:** Google Sign-In qua **Firebase Authentication** (Project: `study-material-nhom11`).
- **Lưu trữ tệp tin:** **Supabase Storage** (Bucket: `study-documents`).
- **Cơ sở dữ liệu quan hệ & Phân quyền bảo mật:** **Supabase PostgreSQL** với cơ chế bảo mật cấp dòng (**Row Level Security - RLS**).
- **Lưu trữ ngoại tuyến (Local-First):** SQLite / Drift database cho phép truy cập và phản ứng dữ liệu tức thời.

---

## 2. Cấu Trúc Thư Mục Nhóm

```text
nhom11-65ktpm/
├── danhsachnhom.md                       # Danh sách và bảng phân công công việc các thành viên
├── README.md                             # Hướng dẫn cài đặt, chạy ứng dụng và kiến trúc hệ thống
├── docs/                                 # Tài liệu kỹ thuật, báo cáo và slide thuyết trình
│   ├── danhsachnhom.md
│   ├── supabase_schema_and_rls.sql       # Script khởi tạo 3 bảng và 11 chính sách RLS trên Supabase
│   ├── BAO_CAO_FLUTTER_FIREBASE_SUPABASE_QUAN_LY_TAI_LIEU.docx # Báo cáo nộp bài định dạng Word (.docx)
│   ├── BAO_CAO_FLUTTER_FIREBASE_SUPABASE_QUAN_LY_TAI_LIEU.md   # Báo cáo kỹ thuật chi tiết (.md)
│   ├── SLIDE_TIM_HIEU_VA_SETUP_FIREBASE.pptx                   # Slide thuyết trình nhóm (.pptx)
│   └── SLIDE_TIM_HIEU_VA_SETUP_FIREBASE.html                   # Slide thuyết trình định dạng HTML
└── src/                                  # Toàn bộ mã nguồn ứng dụng Flutter
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── core/                         # Cấu hình Supabase & App Theme
    │   ├── database/                     # SQLite Drift Database & DAOs
    │   ├── domain/                       # Models, Services (Auth, Sync, Supabase RLS)
    │   ├── state/                        # State Providers (Document, Supabase, Auth)
    │   └── ui/                           # Màn hình giao diện (HomeScreen, CloudSharingScreen, ...)
    └── test/                             # 27 bài kiểm thử tự động (Unit test, RLS 3 tài khoản, Widget test)
```

---

## 3. Đáp Ứng 6 Mục Checklist Yêu Cầu

1. **Thiết lập dự án Firebase & Đăng nhập Google:** Tích hợp `google-services.json` vào Android, cấu hình `firebase_options.dart`, hỗ trợ Google Sign-In và tự động đồng bộ hồ sơ sang Supabase.
2. **Cấu trúc lưu trữ file & Kết nối Supabase:** Sử dụng Supabase Storage bucket `study-documents` tổ chức theo cấu trúc `$userId/${timestamp}_$fileName`, liên kết URL vào bảng `documents`.
3. **Thiết kế CSDL 3 bảng:** `profiles` (Người dùng), `documents` (Tài liệu), `document_permissions` (Quyền chia sẻ `VIEW`/`EDIT`).
4. **Tìm kiếm, cập nhật & chia sẻ tài liệu:** Tìm kiếm đa tiêu chí thời gian thực, lọc phạm vi (`Tất cả` / `Của tôi` / `Được chia sẻ`), cập nhật metadata tài liệu và hộp thoại chia sẻ/thu hồi quyền trực quan.
5. **Chính sách Row Level Security (RLS):** Bật RLS trên toàn bộ các bảng, áp dụng nghiêm ngặt các quyền `OWNER` (toàn quyền), `EDIT` (chỉ đọc & sửa), `VIEW` (chỉ đọc) và chặn hoàn toàn người ngoài.
6. **Kiểm thử 3 tài khoản:** Xây dựng bộ test tự động và trình mô phỏng UI với 3 tài khoản:
   - `alice@nhom11.edu.vn` (Owner)
   - `bob@nhom11.edu.vn` (Editor)
   - `charlie@nhom11.edu.vn` (Viewer)

---

## 4. Hướng Dẫn Cài Đặt Và Khởi Chạy

### 4.1. Cài đặt các gói phụ thuộc (Dependencies)
```bash
cd nhom11-65ktpm/src
flutter pub get
```

### 4.2. Chạy bộ kiểm thử tự động (Unit & RLS Test)
```bash
flutter test
```
*Kết quả:* Vượt qua 100% 27 bài kiểm thử (`All tests passed!`).

### 4.3. Chạy ứng dụng trên Trình duyệt Web (Chrome)
```bash
flutter run -d chrome
```

### 4.4. Chạy ứng dụng trên Linux / Desktop
```bash
flutter run -d linux
```
