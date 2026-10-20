# ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP (CASHEW ARCHITECTURE)
> **Đồ án Thực hành TH1 - Kiến trúc Phần mềm & Hệ thống Thông tin**  
> **Sinh viên thực hiện: Nhóm 11**

---

## 1. Giới thiệu Tổng quan

Ứng dụng **Quản lý Tài liệu Học tập (Study Material Manager)** được thiết kế và triển khai nhằm giải quyết bài toán quản lý, phân loại và tra cứu bài giảng, bài tập, đề cương và tài liệu tham khảo cho sinh viên đại học. 

Đặc biệt, hệ thống áp dụng triệt để các nguyên lý cốt lõi của **Kiến trúc Cashew** (Mô hình Local-First Reactive Architecture), đồng thời cải tiến khắc phục hạn chế lớn nhất của mã nguồn Cashew gốc (xóa bỏ phản mẫu *God-file* `tables.dart` > 7.600 dòng bằng cách phân tách độc lập các Table và Data Access Objects theo Clean Architecture).

### Các nguyên lý Cashew cốt lõi được áp dụng:
1. **Cục bộ Ưu tiên (Local-First / Offline-First)**: Toàn bộ dữ liệu nằm trực tiếp trong cơ sở dữ liệu SQLite nhúng tại máy khách, hoạt động 100% khi mất kết nối mạng và đạt thời gian phản hồi không độ trễ (<16ms, Zero Latency).
2. **Luồng dữ liệu phản ứng thời gian thực (Reactive Streams / Watchers)**: Thay vì truy vấn thụ động, tầng UI lắng nghe luồng dữ liệu `Stream<List<T>>` phát ra từ Drift/SQLite. Mọi thay đổi ghi/xóa ở tầng dưới tự động kích hoạt cập nhật giao diện mà không cần reload trang.
3. **Cơ chế Nhật ký Xóa (Tombstone Pattern - `DeleteLogs`)**: Bản ghi khi bị xóa sẽ được ghi nhận vết vào bảng `DeleteLogs` (lưu `entryPk`, `itemType`, `dateTimeModified`), ngăn chặn hiện tượng phục hồi bản ghi (Zombie resurrection) khi đồng bộ vi sai đa thiết bị.
4. **Quy tắc giải quyết xung đột Last-Write-Wins (LWW)**: Dựa trên dấu thời gian `dateTimeModified` để phân xử phiên bản dữ liệu mới nhất.
5. **Sao lưu Snapshot JSON & Sẵn sàng Đồng bộ Đám mây (Cloud Sync Ready)**: Cho phép xuất/nhập toàn bộ dữ liệu kèm Tombstones để sao lưu an toàn hoặc đồng bộ giữa các máy khách.

---

## 2. Cấu trúc Thư mục và Phân lớp Hệ thống

Hệ thống được tổ chức phân tầng rõ ràng, đảm bảo nguyên lý Đơn trách nhiệm (Single Responsibility Principle) và khả năng kiểm thử độc lập:

```text
study_material_manager/
├── lib/
│   ├── main.dart                      # Điểm vào ứng dụng, khởi tạo DB & Seeding mẫu
│   ├── core/
│   │   └── app_theme.dart             # Cấu hình giao diện Material 3 (Material You, Light/Dark)
│   ├── database/                      # TẦNG PERSISTENCE & DATA ACCESS
│   │   ├── app_database.dart          # Lớp cơ sở dữ liệu Drift (@DriftDatabase)
│   │   ├── app_database.g.dart        # Mã nguồn sinh tự động bởi build_runner
│   │   ├── connection/
│   │   │   └── connection.dart        # Trừu tượng hóa kết nối SQLite Native / In-Memory
│   │   ├── tables/                    # ĐỊNH NGHĨA CÁC BẢNG DỮ LIỆU ĐỘC LẬP
│   │   │   ├── documents_table.dart   # Bảng Documents (UUID PK, FK môn học, loại, ưu tiên)
│   │   │   ├── subjects_table.dart    # Bảng Subjects (Môn học, mã môn, giảng viên, màu sắc)
│   │   │   ├── delete_logs_table.dart # Bảng DeleteLogs (Tombstones phục vụ đồng bộ)
│   │   │   └── app_settings_table.dart# Bảng AppSettings (Cấu hình người dùng)
│   │   └── daos/                      # CÁC DATA ACCESS OBJECTS RIÊNG BIỆT
│   │       ├── document_dao.dart      # DAO thao tác bảng Documents & Reactive Watcher
│   │       ├── subject_dao.dart       # DAO thao tác bảng Subjects
│   │       ├── delete_log_dao.dart    # DAO quản lý Tombstones & truy vấn thời gian
│   │       └── settings_dao.dart      # DAO lưu trữ cài đặt ứng dụng
│   ├── domain/                        # TẦNG LOGIC NGHIỆP VỤ & BUSINESS RULES
│   │   ├── models/
│   │   │   ├── document_type.dart     # Enum phân loại tài liệu (Bài giảng, Bài tập, Tham khảo)
│   │   │   └── document_filter.dart   # Đối tượng lọc dữ liệu & quy tắc sắp xếp
│   │   └── services/
│   │       ├── document_service.dart  # Nghiệp vụ CRUD, Validation, Last-Write-Wins, Tombstone
│   │       ├── subject_service.dart   # Nghiệp vụ Môn học
│   │       ├── search_filter_engine.dart # Động cơ tìm kiếm & lọc đa tiêu chí (Pure Logic)
│   │       └── backup_restore_service.dart # Động cơ xuất/nhập Snapshot JSON & merge LWW
│   ├── state/                         # TẦNG QUẢN LÝ TRẠNG THÁI PHẢN ỨNG
│   │   ├── document_provider.dart     # Kết nối Reactive Stream từ DB lên UI Widgets
│   │   └── settings_provider.dart     # Quản lý cấu hình Dark/Light Mode
│   └── ui/                            # TẦNG GIAO DIỆN NGƯỜI DÙNG (PRESENTATION LAYER)
│       ├── screens/
│       │   ├── home_screen.dart       # Màn hình chính Dashboard, điều hướng 4 Tab
│       │   ├── add_edit_document_screen.dart # Form thêm / sửa tài liệu có validation
│       │   ├── document_detail_screen.dart   # Xem chi tiết tài liệu & siêu dữ liệu LWW
│       │   ├── subjects_screen.dart   # Quản lý danh mục môn học
│       │   ├── statistics_screen.dart # Trực quan hóa tiến độ học tập & phân bố tài liệu
│       │   └── settings_screen.dart   # Cài đặt Theme, Export/Import Snapshot, Xem Tombstones
│       └── widgets/
│           ├── document_card.dart     # Thẻ hiển thị tài liệu với nhãn phân loại & mức ưu tiên
│           ├── search_filter_bar.dart # Thanh tìm kiếm tức thời & chip lọc đa tiêu chuẩn
│           └── empty_state_view.dart  # Giao diện hiển thị trạng thái rỗng
└── test/                              # BỘ KIỂM THỬ ĐỘC LẬP THEO PHÂN TẦNG (21 TEST CASES)
    ├── unit/
    │   ├── daos/                      # Kiểm thử tầng Data Layer (In-memory SQLite)
    │   │   ├── document_dao_test.dart
    │   │   ├── subject_dao_test.dart
    │   │   └── delete_log_dao_test.dart
    │   ├── services/                  # Kiểm thử tầng Domain / Logic
    │   │   ├── document_service_test.dart
    │   │   ├── search_filter_engine_test.dart
    │   │   └── backup_restore_service_test.dart
    │   └── architecture/              # Kiểm thử tính độc lập của phân tầng
    │       └── layer_separation_test.dart
    └── widget_test.dart               # Kiểm thử cây Widget giao diện
```

---

## 3. Các Chức năng Cốt lõi Đã Triển khai

| STT | Chức năng | Mô tả chi tiết & Cách áp dụng Kiến trúc Cashew |
| :---: | :--- | :--- |
| **1** | **Thêm Tài liệu Học tập** | Nhập tiêu đề, môn học, phân loại (Bài giảng, Bài tập, Tham khảo), ghi chú tóm tắt, URL tệp đính kèm, độ ưu tiên. Tự động sinh UUID v4, thiết lập dấu thời gian `dateTimeCreated` và `dateTimeModified`. Kích hoạt luồng phản ứng `watchAllDocuments()` vẽ lại UI tức thời. |
| **2** | **Chỉnh sửa Tài liệu** | Kiểm tra bản ghi tồn tại, áp dụng cơ chế Last-Write-Wins (LWW) cập nhật `dateTimeModified = now`. UI phản ứng tự động cập nhật ngay trên danh sách và màn hình chi tiết. |
| **3** | **Xóa Tài liệu kèm Tombstone** | Khi người dùng xóa tài liệu, hệ thống xóa bản ghi trong bảng `Documents` VÀ đồng thời ghi nhận một bản ghi vào bảng `DeleteLogs` (Tombstone). Ngăn ngừa việc hồi sinh bản ghi khi đồng bộ snapshot với thiết bị khác. |
| **4** | **Tìm kiếm & Lọc Đa Tiêu chuẩn** | Tìm kiếm tức thời theo từ khóa tiêu đề, ghi chú nội dung, giảng viên; lọc theo Môn học; lọc theo Loại tài liệu; lọc theo Trạng thái học tập; sắp xếp linh hoạt (Mới nhất, Cũ nhất, Tiêu đề A-Z, Ưu tiên cao nhất). |
| **5** | **Quản lý Danh mục Môn học** | Thêm, sửa, xóa môn học kèm mã môn, tên môn, giảng viên, học kỳ và mã màu hiển thị trực quan. |
| **6** | **Trực quan hóa Thống kê** | Tổng hợp tỷ lệ hoàn thành học tập, biểu đồ thanh phân bố bài giảng/bài tập/tham khảo, số lượng tài liệu chi tiết theo từng môn học. |
| **7** | **Sao lưu Snapshot JSON & Khôi phục** | Xuất toàn bộ cơ sở dữ liệu (Documents, Subjects, DeleteLogs) ra file JSON; khôi phục dữ liệu có kiểm tra Tombstone và giải quyết xung đột Last-Write-Wins. |

---

## 4. Hướng dẫn Cài đặt và Vận hành

### Yêu cầu Môi trường:
- Flutter SDK `>= 3.24.0`
- Dart SDK `>= 3.5.0`
- Nền tảng hỗ trợ: Linux, macOS, Windows, Android, iOS, Web.

### Các bước chạy Ứng dụng:

1. **Di chuyển vào thư mục dự án**:
   ```bash
   cd study_material_manager
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Sinh mã tự động cho tầng Database Drift (nếu cần cập nhật schema)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Chạy ứng dụng**:
   - Trên Linux Desktop:
     ```bash
     flutter run -d linux
     ```
   - Trên Trình duyệt Web:
     ```bash
     flutter run -d chrome
     ```

5. **Thực thi bộ kiểm thử tự động (Unit & Architecture Tests)**:
   ```bash
   flutter test
   ```
   *Kết quả mong đợi: `All tests passed!` (21/21 test cases vượt qua thành công).*
