# Báo cáo khảo sát UI/UX – SmartNote

> **Mẫu Ghi chú duyệt ngày 27/11/2026.** Dùng [ảnh bảng chủ đề](SmartNote_UI_Reference_Assets/approved-notes.png) với nút tạo cạnh tiêu đề, tìm kiếm dạng pill, lưới thẻ cùng kích thước theo điều chỉnh đã thống nhất. Nhấn **Theo chủ đề** để mở bộ lọc và công cụ hiện có. Token màu và chữ riêng của màn nằm trong `AppTheme.notes` và `NotesTopicColors`.

- **Ngày khảo sát:** 22/11/2026
- **Phạm vi:** `nhom03-65ktpm/src` (Flutter 3.47.5, package `smart_note`)
- **Người thực hiện:** Nguyễn Minh (issue #4)
- **Tài liệu liên quan:** [Luật UI/UX](ui_ux.md), [Kế hoạch công việc](ke_hoach_cong_viec.md), [rules/AGENTS.md](../rules/AGENTS.md)

## 1. Kiến trúc và hạ tầng hiện có

| Hạng mục | Hiện trạng |
| --- | --- |
| Kiến trúc | Feature-first Clean Architecture: `lib/features/<feature>/{domain,data,presentation}` + `lib/core/` (database, di, error, services, theme, utils, widgets) |
| State management | `flutter_bloc` 9.1.1 (Cubit), không dùng provider/getx |
| Local DB | Drift 2.35.4 (`notes`), cache offline |
| Auth | Firebase Auth 7.1.0, có `AuthCubit` (`unknown/authenticated/unauthenticated`) |
| Dữ liệu chung | Supabase (theo kế hoạch, chưa nối ở tầng UI) |
| Assets | **Chưa có** thư mục `assets/`; app dùng icon Material và token màu |
| Điều hướng | `AuthGate` chọn màn theo phiên → `AppShell` (bottom navigation 4 tab: Ghi chú, Nhật ký, Thống kê, Cài đặt, giữ trạng thái bằng `IndexedStack`); màn phụ mở bằng `Navigator.push` |

## 2. Danh sách màn hình hiện có

| # | Màn hình | File | Chức năng | Đánh giá UI/UX (trước khi chuẩn hoá) |
| --- | --- | --- | --- | --- |
| 1 | Đăng nhập | `features/auth/presentation/pages/login_page.dart` | Email + mật khẩu, báo lỗi | Đã dựng lại theo chuẩn mới: tiêu đề lớn, nhãn trên field, CTA 3D, có trạng thái chờ |
| 2 | Đăng ký | `features/auth/presentation/pages/register_page.dart` | Email + mật khẩu + nhập lại | Cùng ngôn ngữ thiết kế với đăng nhập |
| 3 | Chờ khôi phục phiên | `features/auth/presentation/pages/auth_gate.dart` (`_SplashPage`) | Spinner khi Firebase đang khôi phục | Còn thô: spinner + chữ, chưa dùng `AppLogo`/`LoadingView` |
| 4 | Danh sách ghi chú | `features/notes/presentation/pages/notes_page.dart` | Đọc ghi chú từ Drift | Chỉ `ListView` + `Divider`, chưa có tìm kiếm/lưới/empty state chuẩn |
| 5 | Lỗi cấu hình Firebase | `.../firebase_config_error_page.dart` | Hướng dẫn khi thiếu `google-services.json` | Nội dung rõ nhưng trình bày chưa đồng bộ token |

## 3. Vấn đề UI/UX đã phát hiện

1. **Chưa có design system:** màu/khoảng cách/bo góc nằm rải trong widget; chưa có token ngữ nghĩa (success/warning).
2. **Trạng thái dữ liệu không đồng nhất:** `CircularProgressIndicator` xuất hiện ở 4 nơi (`notes_page.dart`, `auth_gate.dart` và trước đó là 2 màn auth), mỗi nơi một kiểu.
3. **Empty state tự chế:** lớp `_Message` riêng trong `notes_page.dart`, không tái sử dụng, không có hành động gợi ý.
4. **Danh sách ghi chú nghèo thông tin:** chỉ `ListTile` một cột, không có lưới, không tìm kiếm, không hiển thị tag/màu.
5. **Thiếu component chuẩn:** dialog xác nhận đang viết trực tiếp trong `LogoutButton`; chưa có `ConfirmDialog` dùng chung.
6. **Điều hướng:** đã có `AppShell` với bottom navigation 4 tab; ba tab chưa có tính năng hiển thị `ComingSoonPage` thay vì tab rỗng.
7. **Lỗi kiến trúc đã sửa:** `AuthCubit` từng được provide bên trong `home:` khiến route mới (đăng ký) không đọc được provider — đã đưa lên trên `MaterialApp` kèm test hồi quy.

## 4. Component có thể tái sử dụng (sau khi chuẩn hoá)

| Component | File | Dùng ở |
| --- | --- | --- |
| `AppPrimaryButton` | `core/widgets/app_primary_button.dart` | CTA chính mọi form |
| `AppFieldLabel` | `core/widgets/app_field_label.dart` | Nhãn trên ô nhập |
| `AppLogo` | `core/widgets/app_logo.dart` | Đăng nhập, đăng ký, splash |
| `AppLoadingIndicator` | `core/widgets/app_loading_indicator.dart` | Trong nút, trong danh sách |
| `AppErrorBanner` | `core/widgets/app_error_banner.dart` | Lỗi từ tầng dữ liệu |
| `EmptyState` | `core/widgets/empty_state.dart` | Danh sách trống |
| `LoadingView` | `core/widgets/loading_view.dart` | Màn đang tải |
| `ErrorView` | `core/widgets/error_view.dart` | Màn lỗi + thử lại |
| `ConfirmDialog` | `core/widgets/confirm_dialog.dart` | Đăng xuất, xoá ghi chú |
| `AppSearchBar` | `core/widgets/app_search_bar.dart` | Tìm kiếm ghi chú |
| `AppTextField` | `core/widgets/app_text_field.dart` | Mọi ô nhập liệu trong form |
| `AppPasswordField` | `core/widgets/app_password_field.dart` | Ô mật khẩu + nút hiện/ẩn |
| `NoteCard` | `features/notes/presentation/widgets/note_card.dart` | Lưới/danh sách ghi chú |
| `TagChip` | `core/widgets/tag_chip.dart` | Tag, môn học, bộ lọc |

## 5. Nguồn tham chiếu đã dùng

### 5.1 Bộ ảnh thiết kế SmartNote — đã mở từng PNG bằng Vision

Thư mục [`SmartNote_UI_Reference_Assets/01_mockups_ai_generated`](SmartNote_UI_Reference_Assets/01_mockups_ai_generated/) là **định hướng thiết kế** (không phải giao diện chuẩn tuyệt đối). Từng ảnh đã được xem, ghi lại bố cục/component rồi mới đối chiếu với app thật.

| Ảnh | Nội dung nhìn thấy | Áp dụng / ghi chú |
| --- | --- | --- |
| `SmartNote_UI_Reference_Overview.png` | 15 nhóm màn, palette xanh dương, nền trắng/xanh rất nhạt, card bo góc, CTA xanh đặc | Khung tổng thể của design system |
| `01_home_duolingo_inspired.png` | Lời chào + thẻ streak/level, lưới 2×2 ô pastel, CTA teal "Continue", bottom nav | Định hướng Trang chủ khi có issue (chưa dựng vì chưa có tính năng) |
| `02_notes_google_keep_inspired.png` | Tiêu đề lớn, ô tìm kiếm, hàng chip lọc, lưới 2 cột thẻ pastel (title, 2–3 dòng preview, nhãn pill + ngày), bottom nav | **Đã áp dụng** cho màn Ghi chú: lời chào + title, search, chip lọc môn, lưới/danh sách, `NoteCard` pastel |
| `03_note_editor_notion_inspired.png` | Editor tối giản, tiêu đề tách nội dung, thanh công cụ định dạng theo block | Dành cho #3 (soạn ghi chú) — chưa code |
| `04_subjects.png` | Danh sách môn dạng hàng: ô icon pastel bo góc + tên + chevron; FAB "+"; đầu trang chi tiết có vòng tiến độ | Dành cho #6 (môn học/tag) |
| `05_document_scanner_adobe_scan_inspired.png` | Camera toàn màn, khung nhận biên, thanh hành động đáy (Retake/Crop/Adjust/Done) | Dành cho #8 (quét vở) |
| `06_ocr_preview.png` | Văn bản OCR trên nền trắng, CTA "Copy text" full-width; màn kết quả có chip Chụp lại/Sao chép/Lưu | Dành cho #9 (OCR) |
| `07_ai_summary.png` | Danh sách lựa chọn kiểu Notion (Summarize page, Key points…), kết quả dạng mục gạch đầu dòng | Dành cho #12 (tóm tắt AI) |
| `08_ai_quiz_quizlet_inspired.png` | Quiz: câu hỏi một màn, đáp án radio, đáp án đúng tô xanh; màn kết quả có điểm + Next | Dành cho #13 (trắc nghiệm AI) |
| `09_flashcards_quizlet_inspired.png` | Thẻ lật giữa màn hình, tiến độ chấm tròn, màn kết quả xanh | Dành cho flashcard |
| `10_learning_statistics_duolingo_inspired.png` | Hàng số liệu, biểu đồ cột, segmented Week/Month/Year, tỷ lệ theo môn | Dành cho #17 (thống kê/streak) |
| `11_profile.png` | Avatar tròn giữa trang, tên + email, hàng 3 số liệu, thanh level, danh sách dòng | Dành cho màn Tài khoản (chưa có issue riêng) |
| `12_settings.png` | Nhóm dòng cài đặt, màn Giao diện với radio Light/Dark/System | Dành cho màn Cài đặt tương lai |
| `13_design_system.png` | Palette Primary/Secondary/Background/Surface/Success/Warning/Error/Border; thang chữ 32/24/16/14/12; Primary–Secondary button, Text Field, Search, Chip, Note card | **Đã áp dụng**: `ColorScheme` viết tay, thang `textTheme`, radius 16, input/button/card theme |
| `14_ui_style_guide.png` | 5 nguyên tắc: Đơn giản, Dễ sử dụng, Thân thiện, Hiện đại, Nhất quán | Mục 0 của [ui_ux.md](ui_ux.md) |
| `15_brand_visual.png` | Nền gradient xanh, ô logo, tên SmartNote + khẩu hiệu "Học tốt hơn mỗi ngày", minh hoạ đồi/mascot | **Đã áp dụng** thành `AuthBrandHero` (logo + tên + khẩu hiệu + hoạ tiết mờ); **không** dùng mascot/logo lạ của app khác |

### 5.2 Screenshot app thật — đã mở và đối chiếu

Ảnh mockup chỉ là định hướng; screenshot thật là căn cứ kiểm chứng. Hai nguồn dưới đây đã được mở bằng trình duyệt và chụp lại trong phiên này:

| Nguồn | Ảnh thật đã xem | Điều chỉnh theo ảnh thật |
| --- | --- | --- |
| [Duolingo Blog – "Elevating craft: How we refreshed our core tabs"](https://blog.duolingo.com/core-tabs-redesign) (04/02/2026) | 3 màn thật (Video Call, Profile, Feed) với nền trắng, tiêu đề đậm, đường phân cách mảnh, nút outline bo tròn, tab bar icon-only nhiều màu | Giữ nền sáng gần trắng, tiêu đề đậm phân tầng, viền mảnh thay vì đổ bóng dày; **không** sao chép tab bar nhiều màu của Duolingo |
| [Android Authority – Google Keep screenshots](https://www.androidauthority.com/google-keep-notetaking-tools-3492984/) | Màn ghi chú Keep: nền giấy kem, thanh công cụ dạng pill ở đáy, FAB tròn màu olive, card phẳng gần như không đổ bóng | Xác nhận thẻ ghi chú nên **phẳng, bo 12–16**, màu là tín hiệu nội dung; FAB để dành cho #3 (tạo ghi chú). Đã giảm `AppRadius.card` 20 → 16 và giữ bóng mềm 6% |

Ảnh thật của Notion, Adobe Scan và Quizlet **chưa chụp được** (trang sản phẩm/login-gated, không có screenshot công khai đầy đủ); các màn #3/#8/#9/#13 khi bắt đầu phải mở app thật và dán ảnh vào PR trước khi code.

### 5.3 Nguyên tắc sử dụng nguồn

1. **Mockup SmartNote = định hướng** bố cục/màu/component; không coi là chuẩn tuyệt đối.
2. **Screenshot app thật = kiểm chứng**: mật độ, kích thước chạm, độ phẳng của card, nhịp whitespace.
3. Không sao chép logo, mascot, màu thương hiệu, nội dung hay asset có bản quyền của app tham chiếu.
4. **Không mô tả một giao diện là "đã tham khảo" nếu chưa thực sự xem ảnh**; khi làm màn mới, dán link/ảnh đã xem vào PR.

## 6. Bảng mapping màn hình → nguồn tham chiếu

| Màn hình SmartNote | Trạng thái code | Nguồn tham chiếu | Điểm áp dụng cụ thể |
| --- | --- | --- | --- |
| Đăng nhập / Đăng ký | **Đã có** | Mockup 15 + 13, Duolingo (ảnh thật) + M3 | Hero gradient + logo + khẩu hiệu, tiêu đề 32 đậm, nhãn trên field, một CTA phẳng có bóng màu, nền sáng gần trắng |
| Danh sách ghi chú | **Đã có** | Mockup 02 + Google Keep (ảnh thật) | Lời chào + tiêu đề lớn, search, chip lọc môn, lưới/danh sách, thẻ pastel bo 16, nhãn pill + ngày |
| Chờ khôi phục phiên | **Đã có** | Mockup 15 + M3 | Nền gradient nhạt, `AppLogo` mới, tên app + khẩu hiệu, loading nhỏ |
| Cài đặt / Tài khoản | Chưa có | M3 | Danh sách nhóm, dòng ≥56dp |
| Soạn ghi chú (#3) | Chưa có | Notion | Vùng soạn rộng, tiêu đề tách nội dung, thanh công cụ đáy |
| Môn học / Tag (#6) | Chưa có | Google Keep | Màu + nhãn, chip lọc |
| Tìm kiếm (#7) | Chưa có | Google Keep | Ô tìm kiếm cố định trên đầu |
| Scan / OCR (#8, #9) | Chưa có | Adobe Scan | Camera toàn màn, khung nhận biên, xem trước nhiều trang |
| Nhật ký (#5 – Đạt) | Chưa có | Notion + M3 | Danh sách theo ngày, trình soạn tối giản |
| Tóm tắt AI (#12) | Chưa có | Notion | Khối kết quả dạng tài liệu, chọn độ dài |
| Quiz AI (#13) | Chưa có | Quizlet | Thẻ câu hỏi, đáp án dạng nút lớn, phản hồi đúng/sai |
| Thống kê / Streak (#17) | Chưa có | Duolingo | Chuỗi ngày, thanh tiến độ, thẻ thành tích |

## 7. Trạng thái thực hiện (cập nhật 22/11/2026)

Chỉ làm trên **màn hình đã tồn tại**, không dựng màn giả cho tính năng chưa có.

Đã xong:

1. Design system **v2 theo bộ ảnh tham chiếu**: `ColorScheme` viết tay (Primary `#2F6BFF`, background `#F5F8FF`, surface trắng, success/warning/error), thang chữ 32/26/22/20/16/16/14/12/11, radius card 16, bóng mềm `AppShadows`, palette pastel `AppNoteTones` cho thẻ ghi chú.
2. Component dùng chung: `AppScaffold` (thêm `eyebrow`), `AuthScaffold`, **`AuthBrandHero`**, `AppLogo` kiểu ô gradient, `AppPrimaryButton` phẳng có bóng màu, `AppSearchBar`, `TagChip` nhận `tone`, `NoteCard` pastel, `EmptyState`, `LoadingView`, `ErrorView`, `ConfirmDialog`, `AppTextField`, `AppPasswordField`, `AppLoadingIndicator`, `AppErrorBanner`.
3. Màn **Ghi chú** theo mockup 02 + ảnh thật Keep: lời chào theo buổi, tiêu đề 32, tìm kiếm, **chip lọc theo môn**, lưới 2–4 cột thẻ pastel, chuyển lưới/danh sách, 3 trạng thái tải/rỗng/lỗi; dữ liệu vẫn qua `NotesCubit` + Drift.
4. Màn **đăng nhập/đăng ký**: hero thương hiệu, tiêu đề 32, nhãn trên ô, một CTA, link phụ; bỏ viền "3D" cứng, dùng bóng màu nhẹ.
5. Splash: nền gradient nhạt + logo + khẩu hiệu + loading.
6. Đã chạy `dart format` + `flutter analyze` (0 issue) + `flutter test` (22 test pass).
7. Đã build debug và chụp thực tế trên Waydroid `600×1067` — sáng và tối: `~/smartnote/screenshots/ui_login_new.png`, `ui_register_new.png`, `ui_notes_new.png`, `ui_{login,register,notes}_dark.png`. Ảnh nằm ngoài repo, dán vào PR khi mở.

Hạn chế khi kiểm chứng:

- Máy chưa có `android/app/google-services.json` → `lib/main.dart` dừng ở màn lỗi cấu hình Firebase. Ảnh được chụp bằng entrypoint `lib/main_preview.dart` (auth giả + 6 ghi chú mẫu seed vào Drift của bản preview), **không ảnh hưởng code app thật**.
- Đổi Dark/Light trên Waydroid làm Activity khởi động lại, nên phải đăng nhập lại để chụp màn Ghi chú ở chế độ tối.

Chưa làm (có lý do, không phải bỏ sót):

- **Nội dung 3 tab còn lại**: bottom navigation 4 tab đã dựng (`core/navigation/app_shell.dart`), nhưng Nhật ký/Thống kê/Cài đặt đang là `ComingSoonPage`; nội dung thật làm ở #5/#17 và màn cài đặt.
- **SubjectCard / ProgressCard / StatCard / BottomSheet helper**: chưa màn nào dùng; quy định cấm để code chết nên sẽ bổ sung khi #6/#17 bắt đầu.
- **Ảnh thật Notion / Adobe Scan / Quizlet**: chưa chụp được trong phiên này; người làm #3/#8/#9/#13 phải mở app thật và dán ảnh vào PR.

Các màn còn lại triển khai khi issue tương ứng bắt đầu, theo bảng mapping mục 6.
