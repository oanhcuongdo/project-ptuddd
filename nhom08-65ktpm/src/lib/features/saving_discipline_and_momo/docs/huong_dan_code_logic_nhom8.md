# Hướng dẫn Hiểu Cấu trúc Hiện tại & Code Logic — Travel Buddy (Nhóm 8)

Tài liệu này dành cho các thành viên Nhóm 8 (Lớp K65 KTPM) để nắm nhanh hiện trạng mã nguồn Flutter sau khi đã dựng xong bộ khung giao diện (UI) đồng bộ từ Google Stitch, từ đó tập trung viết logic (`models`, `providers`, `repository`) cho module mình phụ trách mà không gây xung đột Git hay lệch giao diện.

## 1. Hiện trạng dự án trong `src/lib/`

- **Giao diện đồng bộ toàn app đã có sẵn:** Toàn bộ bảng màu, font chữ và widget lặp lại được khóa chuẩn trong `src/lib/core/theme/` và `src/lib/core/widgets/`. Các màn hình của từng tính năng đã được đặt sẵn trong `src/lib/features/<tên_module>/presentation/` với dữ liệu mẫu lấy từ `src/lib/core/data/mock_trip_data.dart`.
- **Chạy xem trước toàn bộ UI ngay lập tức:** Từ thư mục `src/`, chạy lệnh sau để bấm thử toàn bộ 4 tab và các modal/sheet mà chưa cần backend:
  ```bash
  flutter pub get
  flutter run -t lib/main_ui_preview.dart
  ```
- **Code cũ được giữ nguyên:** `main.dart`, `firebase_options.dart`, `router/app_router.dart` và toàn bộ code đã viết sẵn trong `features/saving_discipline_and_momo/` (`models/`, `providers/`, `repository/`, `utils/`) không bị ghi đè.

## 2. Quy tắc làm việc để không lệch UI & không xung đột Git

| Phạm vi thư mục | Quyền chỉnh sửa | Ghi chú |
| :--- | :--- | :--- |
| `lib/features/<module_của_bạn>/` | **Toàn quyền** | Code `models/`, `providers/`, `repository/`, `utils/` và nối dữ liệu thật vào `presentation/` |
| `lib/core/theme/`, `lib/core/widgets/` | **Không tự ý sửa** | Chỉ dùng lại `AppColors`, `AppTheme`, `AppInsetCard`, `AppStatusBadge`... Nếu cần sửa, nhắn Nhóm trưởng |
| `lib/main.dart`, `lib/firebase_options.dart` | **Không tự ý sửa** | Nhóm trưởng quản lý cấu hình khởi tạo chung |
| `lib/router/app_router.dart` | **Hạn chế sửa chéo** | Nếu cần thêm màn hình/route mới, báo Nhóm trưởng hoặc ghi rõ trong Pull Request |

**Quy trình Git bắt buộc:**
1. Kéo code mới nhất từ nhánh chung của nhóm (`git pull origin nhom08-65ktpm`).
2. Tạo nhánh riêng cho module của bạn: `feature/module1-checklist`, `feature/module2-momo`, `feature/module3-maps`, hoặc `feature/module4-cashew-ocr`.
3. Chỉ commit các file nằm trong module của mình và tạo Pull Request để Nhóm trưởng review trước khi gộp.

## 3. Phân công nối logic chi tiết theo từng Module

Mọi vị trí cần gắn logic trong các file UI đều đã được đánh dấu sẵn bằng chú thích `// TODO(Module X):`. Bạn có thể dùng **Ctrl + Shift + F** trong VS Code tìm `TODO(Module` để nhảy thẳng tới từng chỗ cần làm.

### Module 1 — `auth_and_group/` & `goal_and_checklist/` (Đỗ Đình An)
- **`login_screen.dart`:** Nối `FirebaseAuth` cho nút Đăng nhập (Email/Password), Google Sign-In (`google_sign_in`), Quên mật khẩu và luồng Đăng ký tài khoản.
- **`trip_list_screen.dart` & `create_trip_qr_screen.dart`:** Đọc/tạo `TripGoal` trên Firestore, thay khung QR mẫu bằng `QrImageView` (`qr_flutter`) và gắn `mobile_scanner` cho nút quét QR tham gia nhóm.
- **`checklist_screen.dart`:** Đồng bộ Checklist theo mốc thời gian (30/14/3 ngày) và Hành lý theo thời gian thực trên Firestore; gắn Camera chụp ảnh xác thực hoàn thành lưu lên Firebase Storage; cài đặt Local Notifications nhắc việc sắp đến hạn.
- **`router/app_router.dart`:** Gộp các route từ `app_router_preview.dart` vào `app_router.dart` chính kèm Auth Guard lắng nghe `FirebaseAuth.instance.authStateChanges()`.

### Module 2 — `saving_discipline_and_momo/` (Quỹ tích lũy & Liên kết MoMo)
- **Tận dụng code đã có:** Thư mục này đã có sẵn `models/` (`saving_plan.dart`, `momo_fund_config.dart`, `deposit_record.dart`, `member_streak.dart`), `providers/saving_plan_provider.dart`, `repository/saving_repository_impl.dart` và `utils/saving_calculator.dart`. Hãy nối trực tiếp các provider này vào 4 file UI mới trong `presentation/`.
- **`setup_momo_sheet.dart` (Trưởng nhóm):** Dùng `saving_calculator.dart` tự tính mức đóng/người/kỳ; gắn `mobile_scanner` cho nút *Quét QR MoMo*, `image_picker` cho *Tải ảnh QR* và lưu `MomoFundConfig` lên Firestore.
- **`deposit_receipt_sheet.dart` (Thành viên):** Gắn `url_launcher` vào nút *Mở ứng dụng MoMo ngay* để kích hoạt Deeplink Quỹ nhóm MoMo; giữ nút *Hiện mã QR* và *Sao chép* làm phương án dự phòng; upload ảnh biên lai giao dịch MoMo lên Firebase Storage và tạo bản ghi `DepositRecord` ở trạng thái `pending` (chờ duyệt).
- **`approve_receipt_screen.dart` & `momo_fund_screen.dart` (Trưởng nhóm & Tiến độ):** Chỉ hiển thị banner duyệt biên lai cho Trưởng nhóm (`isHost == true`). Khi bấm **Xác nhận hợp lệ**, cập nhật Firestore để cộng tiền vào tiến độ quỹ và tăng chuỗi `Saving Streak` trên lưới lịch; khi **Từ chối**, lưu lý do để thành viên gửi lại biên lai.

### Module 3 — `place_and_itinerary_planner/` (Lịch trình & Bản đồ)
- **`itinerary_screen.dart` & `add_activity_screen.dart`:** Đọc/thêm/sửa/xóa `PlacePlan` theo từng ngày trên Firestore; viết hàm kiểm tra trùng khung giờ để tự động bật/tắt banner cảnh báo màu vàng; cộng dồn chi phí dự kiến của các điểm đến để đồng bộ sang ngân sách.
- **`route_map_screen.dart`:** Thay khung bản đồ mô phỏng bằng `GoogleMap` (`google_maps_flutter`); kết nối Places / Overpass API cho thanh tìm kiếm và chip lọc (*Tham quan, Ăn uống, Lưu trú*); vẽ `Polyline` nối các điểm trong ngày kèm tổng quãng đường/thời gian di chuyển; gắn `geolocator` + Camera cho nút *GPS & Camera Check-in*.

### Module 4 — `budget_and_expense_cashew/` (Ngân sách Cashew & Camera OCR)
- **`budget_screen.dart`:** Nối 5 Hũ ngân sách (`BudgetEnvelope`) với dữ liệu thực chi trên Firestore và tổng quỹ đã tích lũy từ Module 2; có thể nâng cấp biểu đồ đối chiếu (Kế hoạch vs. Quỹ MoMo vs. Thực chi) bằng `fl_chart`; cài đặt thuật toán **Tối giản hóa công nợ (Debt Simplification)** và lưu trạng thái đã thanh toán khi người dùng xác nhận trong hộp thoại.
- **`add_expense_ocr_screen.dart` & `expense_detail_screen.dart`:** Gắn Camera + `google_mlkit_text_recognition` cho nút *Quét hóa đơn tự động (Camera OCR)* để tự nhận diện và điền tổng tiền; hoàn thiện phép tính cộng/trừ/nhân/chia trên thanh phím Cashew; lưu, sửa, xóa `Expense` kèm ảnh hóa đơn lên Firestore/Storage.

## 4. Quy trình 4 bước chuyển 1 màn hình từ Mock sang Logic thật

1. **Hoàn thiện Repository (`repository/`):** Viết hàm đọc/ghi Firestore, Storage hoặc gọi API (Maps/MoMo/OCR), tách biệt hoàn toàn khỏi giao diện.
2. **Tạo Riverpod Provider (`providers/`):** Bọc Repository bằng `StreamProvider` (dữ liệu realtime từ Firestore) hoặc `AsyncNotifierProvider` (các thao tác thêm/sửa/duyệt).
3. **Nối dữ liệu vào màn hình (`presentation/`):** Đổi `StatefulWidget` thành `ConsumerStatefulWidget` (hoặc `StatelessWidget` thành `ConsumerWidget`), sau đó thay `MockTripData.*` bằng `ref.watch(...)`:
   ```dart
   // Trước (UI mẫu):
   final items = MockTripData.receiptRequests;

   // Sau (Nối Riverpod + Firestore):
   final receiptsAsync = ref.watch(receiptRequestsProvider(tripId));
   return receiptsAsync.when(
     loading: () => const Center(child: CircularProgressIndicator()),
     error: (err, _) => Center(child: Text('Lỗi tải dữ liệu: $err')),
     data: (items) => ListView(...), // Giữ nguyên toàn bộ cây Widget giao diện cũ
   );
   ```
4. **Thay các dòng `// TODO(Module X):`:** Gắn lời gọi hàm xử lý thật (`ref.read(...notifier).submitReceipt(...)`) kèm trạng thái loading để tránh người dùng bấm đúp, không xóa hay đổi các widget nền từ `core/widgets/`.

## 5. Checklist tự kiểm tra trước khi tạo Pull Request

- Đã xóa sạch phụ thuộc vào `MockTripData` trong các màn hình đã hoàn thiện logic.
- Không sửa ngoài phạm vi thư mục module của mình, không hardcode màu lạ thay cho `AppColors`.
- Chạy `flutter analyze` trong thư mục `src/` báo **0 lỗi**.
- Đã test chạy thật trên máy ảo Android / điện thoại thật với dữ liệu Firestore thật (không crash khi danh sách rỗng hoặc mạng chậm).
