# Design System & Luật UI/UX – SmartNote (Nhóm 03, 65KTPM)

> **Mẫu Ghi chú duyệt ngày 27/11/2026.** Dùng [ảnh bảng chủ đề](SmartNote_UI_Reference_Assets/approved-notes.png) với nút tạo cạnh tiêu đề, tìm kiếm dạng pill, lưới thẻ cùng kích thước theo điều chỉnh đã thống nhất. Nhấn **Theo chủ đề** để mở bộ lọc và công cụ hiện có. Token màu và chữ riêng của màn nằm trong `AppTheme.notes` và `NotesTopicColors`.

- **Ban hành:** 22/11/2026, trong phạm vi issue **#4** (Thiết kế UI/UX nền tảng) — người phụ trách: Nguyễn Minh.
- **Áp dụng cho:** mọi màn hình, widget và PR có thay đổi giao diện trong `nhom03-65ktpm/src`.
- **Tài liệu đi kèm:** [báo cáo khảo sát + nguồn tham chiếu](bao_cao_ui_ux.md), [bộ ảnh tham chiếu SmartNote](SmartNote_UI_Reference_Assets/HOW_TO_USE_WITH_AGENT.md), [rules/AGENTS.md](../rules/AGENTS.md) (§9 kiến trúc, §10 quy chuẩn code), [kế hoạch công việc](ke_hoach_cong_viec.md).
- **Mục đích:** mọi người và mọi agent AI dựng UI bằng **cùng một hệ thống**, không tự pha màu, tự đặt cỡ chữ hay tự nghĩ layout mới.

## 0. Nguyên tắc gốc

Phong cách đã chốt: **Friendly Learning Productivity** — hiện đại, thân thiện, trực quan, có yếu tố gamification nhẹ, phù hợp học sinh/sinh viên nhưng vẫn nghiêm túc khi cần.

Thứ tự quyết định khi làm giao diện (không được đảo):

1. **Nguồn tham chiếu** quyết định giao diện trông như thế nào (mục 9).
2. **Design system** quyết định tính nhất quán (mục 2–7).
3. **Nghiệp vụ SmartNote** quyết định màn hình hoạt động ra sao.
4. **Flutter/Material 3** chỉ là cách triển khai.

| Hạng mục | Quyết định |
| --- | --- |
| Design system nền | **Material 3** trong Flutter `3.47.5` (`useMaterial3: true`) |
| Thư viện component ngoài | **Không dùng** `forui`, `shadcn_flutter` hay UI kit khác |
| Nguồn sự thật của token | `src/lib/core/theme/app_theme.dart`, `app_spacing.dart`, `app_colors.dart` |
| Widget dùng chung | `src/lib/core/widgets/` (xem mục 5) |
| Nguồn tham chiếu bố cục | `docs/SmartNote_UI_Reference_Assets/01_mockups_ai_generated/` (13 design system, 14 style guide, 15 brand visual, 01 home, 02 notes) + app thật: Duolingo, Google Keep, Notion, Adobe Scan, Quizlet — chi tiết ở mục 9 |

Vì sao không dùng `forui` (đã kiểm tra 22/11/2026):

- `forui 0.28.0` yêu cầu Flutter `>=3.50.0`, Dart `>=3.14.0`; nhóm ghim `3.47.5` trong `src/.fvmrc` → không cài được.
- `forui 0.27.7` cài được nhưng viết lại API (`FThemeData`/`FColors`, `FScaffold`/`FHeader` thay `Scaffold`/`AppBar`) → phải port toàn bộ màn và test, không kịp tiến độ.
- Không mở lại trong đồ án này; sau khi nộp bài có thể xem lại.

## 1. Màu sắc (Color System)

- **Palette chốt theo `13_design_system.png`**, khai báo trực tiếp thành `ColorScheme` trong `core/theme/app_theme.dart` (không dùng `ColorScheme.fromSeed`) để giữ đúng sắc thương hiệu thay vì màu M3 tự làm nhạt.
  | Role | Sáng | Tối |
  | --- | --- | --- |
  | `primary` | `#2F6BFF` | `#7FA5FF` |
  | `primaryContainer` | `#E3ECFF` | `#1C3566` |
  | `secondary` | `#0E9F7E` | `#4FD1B0` |
  | `secondaryContainer` | `#DCF6EC` | `#0E4538` |
  | `tertiary` | `#7C5CFF` | `#B39CFF` |
  | `surface` (nền màn) | `#F5F8FF` | `#0E1420` |
  | `surfaceContainerLowest/Low` (card) | `#FFFFFF` | `#161E2C` |
  | `surfaceContainerHigh` (ô nhấn) | `#F0F3FB` | `#202A3B` |
  | `error` | `#D92D36` | `#FF8A8E` |
  | `outlineVariant` (viền) | `#E3E9F4` | `#2A3548` |
- **Tông pastel cho thẻ ghi chú/nhãn môn** nằm trong extension `AppNoteTones` (`core/theme/app_colors.dart`), 5 tông mint/sky/lilac/peach/lemon, có bản sáng/tối. Chọn tông ổn định theo id ghi chú qua `toneAt(index)`.
- Widget chỉ được dùng **role** của `Theme.of(context).colorScheme`, extension `AppSemanticColors.of(context)` hoặc `AppNoteTones.of(context)`.
- Màu ngữ nghĩa: `success #12855F`, `warning #9A5B00` (kèm container tương ứng) trong `AppSemanticColors`.

| Nhu cầu | Role / token | Ghi chú dùng |
| --- | --- | --- |
| Hành động chính | `primary` / `onPrimary` | CTA, FAB, tab đang chọn |
| Nền nhấn nhẹ | `primaryContainer` / `onPrimaryContainer` | chip chọn, avatar, gradient nền form |
| Phân loại phụ | `secondaryContainer` / `onSecondaryContainer` | tag môn học, nhãn lọc |
| Nền màn hình (Background) | `surface` | `scaffoldBackgroundColor` |
| Nền khối nổi (Surface) | `surfaceContainerLow` | card ghi chú, bottom sheet |
| Nền ô nhập / khối nhấn | `surfaceContainerHigh` | input filled, skeleton, dialog |
| Chữ chính (Text Primary) | `onSurface` | tiêu đề, nội dung |
| Chữ phụ (Text Secondary) | `onSurfaceVariant` | mô tả, metadata, icon phụ |
| Viền / divider (Border) | `outlineVariant` | viền card, divider thay cho shadow |
| Viền mờ / gợi ý | `outline` | hint text, icon mờ |
| Lỗi | `error` / `errorContainer` / `onErrorContainer` | lỗi form, hành động xoá |
| Thành công | `AppSemanticColors.success` / `onSuccess` | kết quả đúng, lưu thành công |
| Cảnh báo | `AppSemanticColors.warning` / `onWarning` | sắp hết streak, dữ liệu chưa đồng bộ |

`AppSemanticColors` là `ThemeExtension` có sẵn bản `light`/`dark`; M3 không có role success/warning nên nhóm khai báo tại `core/theme/app_colors.dart`.

Luật màu:

- **Cấm** `Color(0x...)`, `Colors.*` ngoài `core/theme/`. Màu tag/ghi chú chỉ lấy role hoặc `AppNoteTone` (`container`/`onContainer`/`accent`).
- Không đổi màu theo màn. Gradient chỉ dùng ở nền form auth (`primaryContainer` → `surface`) và hero thương hiệu (`primary` → tối hơn 28%).
- Chế độ tối dùng cùng role, không tự đảo màu; tương phản chữ ≥ 4.5:1 (kiểm bằng mắt trên Waydroid + đối chiếu M3).

## 2. Typography

- Font: **Roboto** (mặc định Flutter, hỗ trợ tiếng Việt đầy đủ, không tải font ngoài). Không thêm font/asset khi chưa được duyệt.
- Chỉ dùng `Theme.of(context).textTheme.<role>`; **cấm** `fontSize:` / `fontWeight:` trong widget.
- Số style tối thiểu (bài học từ Duolingo): một role cho một mục đích, không tạo style mới.

| Role | Cỡ/độ đậm hiệu dụng trong theme | Dùng cho |
| --- | --- | --- |
| `displaySmall` | 32, w800, height 1.18 | Tiêu đề màn hình, câu chào lớn ở form (thang Display 32 của style guide) |
| `headlineMedium` | 26, w800, height 1.2 | Tiêu đề khối lớn (dùng cho splash, dialog lớn) |
| `headlineSmall` | 22, w800 | Tiêu đề empty state / khối phụ (thang Headline 24) |
| `titleLarge` | 20, w700 | Tên app, tiêu đề dialog |
| `titleMedium` | 16, w700 | Tiêu đề card, AppBar thường, nhãn nút chính (thang Title 16) |
| `bodyLarge` | 16, w400 | Nội dung ghi chú, phụ đề form |
| `bodyMedium` | 14, w400 | Mô tả, metadata, banner lỗi (thang Body 14) |
| `labelLarge` | 14, w700 | Nhãn ô nhập (`AppFieldLabel`) |
| `labelMedium` | 12, w600 | Tag, chip, nhãn điều hướng (thang Label 12) |
| `labelSmall` | 11, w500 | Thời gian, số ký tự, chân trang |

Câu chữ: tiếng Việt có dấu, ngắn, không viết hoa toàn bộ, không dùng từ kỹ thuật với người dùng cuối.

## 3. Spacing, bán kính, độ nổi

Thang 4-based trong `core/theme/app_spacing.dart`:

| Token | Giá trị | Dùng cho |
| --- | --- | --- |
| `xs` | 4 | icon ↔ nhãn, khoảng rất nhỏ trong cụm |
| `sm` | 8 | trong cùng một cụm (nhãn ↔ ô nhập) |
| `md` | 12 | giữa các card trong danh sách |
| `lg` | 16 | **padding mặc định** của màn và card |
| `xl` | 24 | giữa các nhóm/section |
| `xxl` | 32 | đầu/cuối màn, khoảng trước CTA |
| `xxxl` | 48 | khoảng lớn trước khối CTA toàn màn |

- **Cấm** số ngoài thang (10, 14, 18, 20, 25…) trong `EdgeInsets`/`SizedBox`.
- `ListView`/`GridView` dùng padding ngang `AppSpacing.lg`; card cách nhau `AppSpacing.md`.

| Thành phần | Bán kính | Token |
| --- | --- | --- |
| Ô nhập, chip, ảnh nhỏ | 14 | `AppRadius.input` |
| Card, khối nội dung, hero | 16 | `AppRadius.card` |
| Nút hành động | 16 | `AppRadius.button` |
| Dialog, bottom sheet | 28 | `AppRadius.sheet` |
| Logo | 30% cạnh | `AppRadius.mark` |

Độ nổi (theo style guide + mockup notes): card trắng/pastel trên nền `surface` dùng **bóng mềm** `AppShadows.soft(shadow)`; CTA chính dùng `AppShadows.primary(primary)`; hero dùng `AppShadows.hero(primary)`. `elevation` của M3 vẫn giữ 0 để không cộng thêm bóng thứ hai. Input dùng viền `outlineVariant` thay cho bóng.

## 4. Icon

- Chỉ `Icons.*` của Material; trạng thái thường dùng bản `_outlined`, trạng thái đang chọn dùng bản đặc.
- Kích thước: **20** trong dòng chữ/banner, **24** trên AppBar/nút, **32–40** trong empty state.
- Không tự vẽ icon, không tải icon từ mạng. Không dùng emoji làm icon chức năng.

## 5. Component bắt buộc

Màn mới **chỉ được lắp** từ các widget dưới đây. Thiếu thì bổ sung vào `core/widgets/` kèm test **trong cùng PR**, không viết lại riêng trong feature.

| Widget | File | Thay cho | Trạng thái |
| --- | --- | --- | --- |
| `AppPrimaryButton` | `core/widgets/app_primary_button.dart` | `FilledButton` cấu hình tay | **đã có** |
| `AppTextField` | `core/widgets/app_text_field.dart` | `TextFormField` + `InputDecoration` tự dựng | **đã có** (22/11) |
| `AppPasswordField` | `core/widgets/app_password_field.dart` | ô mật khẩu + nút hiện/ẩn tự viết | **đã có** |
| `AuthScaffold` | `core/widgets/auth_scaffold.dart` | `Scaffold` + gradient + `SingleChildScrollView` tự dựng ở mỗi màn auth | **đã có** (22/11) |
| `AuthBrandHero` | `core/widgets/auth_brand_hero.dart` | khối thương hiệu tự dựng ở màn đăng nhập | **đã có** (22/11) |
| `AppFieldLabel` | `core/widgets/app_field_label.dart` | `labelText` trong ô | **đã có** (dùng nội bộ `AppTextField`) |
| `AppLogo` | `core/widgets/app_logo.dart` | khối logo tự dựng | **đã có** |
| `AppLoadingIndicator` | `core/widgets/app_loading_indicator.dart` | `CircularProgressIndicator` trong nút | **đã có** |
| `AppErrorBanner` | `core/widgets/app_error_banner.dart` | `Text` đỏ rời rạc | **đã có** |
| `AppScaffold` | `core/widgets/app_scaffold.dart` | `Scaffold` + header rời rạc | **đã có** |
| `AppSearchBar` | `core/widgets/app_search_bar.dart` | `TextField` trong AppBar | **đã có** |
| `EmptyState` | `core/widgets/empty_state.dart` | `_Message` tự chế | **đã có** |
| `LoadingView` | `core/widgets/loading_view.dart` | spinner rải rác | **đã có** |
| `ErrorView` | `core/widgets/error_view.dart` | thông báo lỗi tự chế | **đã có** |
| `ConfirmDialog` | `core/widgets/confirm_dialog.dart` | `showDialog` mỗi nơi một kiểu | **đã có** |
| `NoteCard` | `features/notes/presentation/widgets/note_card.dart` | `ListTile` | **đã có** |
| `AppShell` | `core/navigation/app_shell.dart` | `Scaffold` + bottom navigation tự dựng | **đã có** (22/11) |
| `ComingSoonPage` | `core/navigation/coming_soon_page.dart` | màn giữ chỗ cho tab chưa có tính năng | **đã có** (22/11) |
| `TagChip` | `core/widgets/tag_chip.dart` | `Chip` cấu hình thủ công | **đã có** |
| `SyncStatusIndicator` | `features/notes/presentation/widgets/sync_status_indicator.dart` | icon trạng thái đồng bộ tự dựng ở mỗi màn | **đã có** (25/11, #21) — dùng icon + `Tooltip` + `Semantics`, không chỉ dựa vào màu |
| Nút phụ (`AppSecondaryButton`) | — | `OutlinedButton` cấu hình tay | sẽ thêm khi có màn cần (#6) |
| `SubjectCard`, `ProgressCard`, `StatCard` | — | — | sẽ thêm cùng #6/#17 (chưa có màn dùng, tránh code chết) |
| `BottomSheet` helper | — | — | sẽ thêm cùng #3 (soạn ghi chú) |

Quy ước component:

- Thuần hiển thị: nhận dữ liệu + callback, **không** đọc Cubit/Repository, không gọi API.
- Tham số đặt tên rõ nghĩa (`title`, `message`, `onRetry`, `onConfirm`), `const` constructor khi có thể.
- Mỗi component có **ít nhất 1 widget test** (hiển thị + hành động chính) trong `src/test/core/widgets/`.

## 6. Interaction System

| Trạng thái | Quy định |
| --- | --- |
| Nhấn (touch feedback) | Ripple/overlay của M3; card dùng `InkWell` bên trong `Material` để có gợn sóng đúng bo góc |
| Nút — disabled | `onPressed: null`, nền/ chữ tự giảm theo theme; **không** tự đổi màu |
| Nút — loading | `AppPrimaryButton(isLoading: true)`, khoá bấm, giữ nguyên kích thước |
| Ô nhập — focus | Viền `primary` 2px (đã cấu hình `inputDecorationTheme`) |
| Ô nhập — lỗi | `errorText` của ô; lỗi từ tầng dữ liệu dùng `AppErrorBanner` |
| Chọn / đang bật | `primaryContainer` hoặc `secondaryContainer` + icon đặc |
| Hành động phá huỷ | `ConfirmDialog(isDestructive: true)`, nút xác nhận màu `error` |
| Thành công | `SnackBar` ngắn (≤ 3 giây) hoặc đổi trạng thái tại chỗ; không bật dialog chúc mừng cho việc nhỏ |
| Chuyển màn | `MaterialPageRoute` mặc định (M3); không tự viết animation trang |
| Thời lượng | 150 ms cho nút/chip, 200 ms cho chuyển trạng thái, tối đa 300 ms khi chuyển màn; `Curves.easeInOutCubic` |
| Khoảng chờ | < 300 ms: không hiện loading; ≥ 300 ms: `LoadingView`/`AppLoadingIndicator` |

Không thêm package animation. Không dùng hiệu ứng nảy/lắc trừ khi có lý do nghiệp vụ (ví dụ trả lời sai ở quiz).

## 7. Bố cục chuẩn và trạng thái dữ liệu

Chọn **một** trong sáu mẫu, không tự nghĩ bố cục khác:

1. **Màn danh sách** — `AppScaffold` (tiêu đề lớn + phụ đề + search) → `ListView.separated`/`GridView` card cách `md` → FAB extended cho hành động tạo mới.
2. **Màn soạn thảo** — `showModalBottomSheet` toàn màn (radius 28), ô tiêu đề `titleMedium`, nội dung `bodyLarge`, thanh công cụ dưới đáy.
3. **Màn form** — hero thương hiệu (`AuthBrandHero`, giống `15_brand_visual.png`) hoặc hàng logo nhỏ, tiêu đề `displaySmall` căn trái, phụ đề `bodyLarge`, `AppTextField`/`AppPasswordField` (nhãn trên ô), **một** `AppPrimaryButton` full-width, link phụ `TextButton`; không bọc form trong card.
4. **Ba trạng thái dữ liệu** — mọi màn đọc dữ liệu phải đủ: `LoadingView` → `EmptyState` (icon + tiêu đề + mô tả, CTA khi có hành động) → `ErrorView` (thông báo + "Thử lại").
5. **Xác nhận hành động phá huỷ** — luôn qua `ConfirmDialog`.
6. **Cài đặt / thống kê** — danh sách nhóm nền `surfaceContainerLow`, mỗi dòng ≥ 56dp, icon trái 24, chevron phải.

## 8. Responsive, accessibility, dark mode

- **Breakpoint:** `< 600dp` một cột; `600–839dp` lưới 2–3 cột; `≥ 840dp` nội dung giới hạn `AppSizes.formMaxWidth` (440) với form, lưới 3–4 cột với danh sách. Không cần package responsive.
- **Touch target** ≥ 48×48dp; icon 20 vẫn phải nằm trong vùng bấm 48.
- **Text scale:** kiểm ở 1.0 và 1.3; không đặt `maxLines` cứng cho tiêu đề màn/nút; nội dung dài dùng `overflow: TextOverflow.ellipsis`.
- **Ngữ nghĩa:** icon-only phải có `tooltip`/`semanticLabel`; ảnh có nội dung phải có mô tả.
- **Dark mode:** kiểm cả `ThemeMode.dark` trước khi mở PR; thanh trạng thái đặt `SystemUiOverlayStyle` theo brightness (đã cấu hình trong `appBarTheme`).
- **Bàn phím:** form dùng `textInputAction` hợp lý (`next`/`done`), nút cuối form nhận `onFieldSubmitted`.

## 9. Mapping màn hình → nguồn tham chiếu

Bảng đầy đủ (mục đích, bố cục, trạng thái, điểm áp dụng) nằm ở [báo cáo khảo sát §6](bao_cao_ui_ux.md#6-bảng-mapping-màn-hình--nguồn-tham-chiếu). Tóm tắt:

| Màn SmartNote | Nguồn | Điểm lấy |
| --- | --- | --- |
| Đăng nhập / Đăng ký | **Duolingo** + mockup **15 brand visual / 13 design system** | Khối hero gradient + logo, tiêu đề lớn, nhãn trên ô, một CTA phẳng có bóng màu, nhịp thở rộng |
| Danh sách / thư viện ghi chú | **Google Keep** + mockup **02 notes** | Lời chào + tiêu đề lớn, ô tìm kiếm, hàng chip lọc, lưới thẻ pastel, nhãn ở cuối thẻ |
| Trang chủ (khi có #6) | mockup **01 home** | Thẻ tiến độ/streak, lưới hành động nhanh pastel, CTA "Tiếp tục" |
| Soạn ghi chú, AI Summary | **Notion** | Vùng soạn rộng, tiêu đề tách nội dung, phân cấp thông tin |
| Scan / OCR | **Adobe Scan** | Camera toàn màn, tự nhận biên, xem trước nhiều trang |
| Quiz AI / Flashcard | **Quizlet** | Một câu hỏi mỗi màn, đáp án nút lớn, phản hồi đúng/sai, điểm cuối bài |
| Thống kê / Streak | **Duolingo** | Chuỗi ngày, thanh tiến độ, thẻ thành tích |
| Cài đặt / Tài khoản | **Material 3** | Danh sách nhóm, dòng ≥56dp, chevron |

Nguyên tắc: lấy **cách sắp xếp, phân cấp và nhịp điệu**; **không** sao chép logo, màu thương hiệu, minh hoạ, mascot hay nội dung của các app đó. Không mô tả một màn là "đã tham khảo" khi chưa thực sự xem nguồn — dán link/ảnh vào PR.

## 10. Luật cấm / bắt buộc

1. **Cấm** mã màu trực tiếp (`Color(0x...)`, `Colors.blue`) ngoài `core/theme/`.
2. **Cấm** `fontSize:`/`fontWeight:` trong widget — dùng `textTheme`.
3. **Cấm** dùng `FilledButton` trực tiếp cho CTA chính — dùng `AppPrimaryButton`; cấm hai nút đặc cạnh nhau.
4. **Cấm** bọc form trong `Card`; nhãn phải nằm trên ô nhập (`AppTextField`).
5. **Cấm** số spacing ngoài thang 4-based; **cấm** bo góc tự đặt ngoài `AppRadius`.
6. **Cấm** widget tự dựng progress/empty/error/dialog riêng — dùng component mục 5.
7. **Bắt buộc** mọi màn đọc dữ liệu có đủ 3 trạng thái loading/empty/error.
8. **Bắt buộc** chữ tiếng Việt có dấu, câu ngắn; **bắt buộc** kiểm tra sáng + tối trước khi mở PR.
9. **Bắt buộc** lấy bố cục từ bảng mapping (mục 9); layout mới phải được thống nhất trong issue/PR trước khi code.
10. Nếu cần thành phần chưa có: bổ sung vào `core/widgets/` + test + cập nhật bảng mục 5 **trong cùng PR**.

## 11. Kiểm tra trước khi mở PR giao diện

```bash
cd nhom03-65ktpm/src

# 1. Không có mã màu ngoài theme (kết quả phải rỗng)
grep -rn "Color(0x" lib --include=*.dart | grep -v "core/theme/"
grep -rn "Colors\." lib --include=*.dart | grep -v "core/theme/"

# 2. Không đặt cỡ chữ trong widget (kết quả phải rỗng)
grep -rn "fontSize:" lib --include=*.dart | grep -v "core/theme/"

# 3. Không còn progress/empty tự chế (kết quả phải rỗng)
grep -rn "CircularProgressIndicator" lib --include=*.dart | grep -v "core/widgets/"

# 4. Chất lượng chung
dart format lib test && flutter analyze && flutter test
```

Quy trình bắt buộc cho mỗi màn (không được bỏ bước):

1. Đọc mapping + nguồn tham chiếu của màn đó, xác định bố cục/trạng thái **trước khi code**.
2. Lắp từ component mục 5; thiếu thì bổ sung component + test.
3. Chạy app thật (Waydroid/máy thật), chụp **sáng + tối**, so với ảnh tham chiếu về alignment, spacing, typography, màu.
4. Kiểm tra ở 2 kích thước màn (hẹp và ≥600dp) và text scale 1.3.
5. Dán ảnh chụp + link tham chiếu vào PR.

## 12. Trạng thái triển khai

- [x] Token: màu (+ success/warning), typography, spacing, bán kính, theme component.
- [x] Component dùng chung mục 5 (trừ các mục ghi "sẽ thêm").
- [x] Màn đăng nhập/đăng ký theo brand visual + design system trong bộ tham chiếu.
- [x] Màn danh sách ghi chú theo mockup 02 (lời chào, chip lọc môn, lưới thẻ pastel, lưới/danh sách, 3 trạng thái).
- [x] Widget test cho component chung.
- [x] Bottom navigation 4 tab (`AppShell`, mặc định tab Ghi chú) — 3 tab Nhật ký/Thống kê/Cài đặt dùng `ComingSoonPage` tới khi #5/#17 và màn cài đặt được merge. **Chỉ một** thanh điều hướng trong toàn app: trắc nghiệm, đổi lưới/danh sách và đăng xuất là hành động trên AppBar, không lồng `NavigationBar` trong tab.
- [ ] `SubjectCard`/`ProgressCard`/`StatCard`/BottomSheet helper — chờ #3/#6/#17.
- [ ] Ảnh màn hình thật của app tham chiếu — cần mở app trên máy thật (xem báo cáo §5.2).
