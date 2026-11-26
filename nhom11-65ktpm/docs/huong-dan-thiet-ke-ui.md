# Hướng dẫn thiết kế giao diện ChaiLish

Tài liệu này dành cho mọi thành viên khi làm màn hình mới hoặc sửa giao diện. Mục tiêu là để các màn hình do 5 người làm trông như cùng một ứng dụng.

> Ý tưởng chung: **hình khối lấy từ Material 3 Expressive** (bo góc lớn, nút viên thuốc, icon nền hình "bánh quy", chữ tiêu đề đậm), còn **cách hiển thị bề mặt lấy từ Liquid Glass của iOS 26** (kính trong, mép kính bẻ cong nền phía sau, viền phản quang, chuyển động lò xo). Bảng màu là tông giấy ấm, điểm nhấn cam đất sét.

Toàn bộ code giao diện dùng chung nằm trong `src/app/lib/core/`:

| File | Nội dung |
|:--|:--|
| `theme/app_colors.dart` | Bảng màu gốc và màu theo vai trò. |
| `theme/glass_theme.dart` | Token của vật liệu kính (`GlassTheme.light` / `.dark`). |
| `theme/app_theme.dart` | `ThemeData` sáng/tối, kiểu chữ, bo góc, theme cho widget Material. |
| `widgets/glass.dart` | Các widget kính: `GlassScaffold`, `GlassAppBar`, `GlassCard`, `GlassButton`, `GlassIconButton`, `GlassSurface`, `ComingSoonView`. |
| `widgets/glass_lens.dart` + `shaders/glass_lens.frag` | Shader khúc xạ mép kính. |
| `widgets/expressive_shapes.dart` | `CookieBorder`, `CookieIcon`. |
| `motion/motion.dart` | `AppMotion`, `Pressable`, `EntranceAnimation`, `MorphSwitcher`, `SpringCurve`. |

---

## 1. Nguyên tắc

1. **Dùng widget có sẵn trước, tự vẽ sau.** Cần thẻ thì dùng `GlassCard`, cần nút thì dùng `GlassButton`. Không tự ghép `BackdropFilter` + `Container` + `BoxShadow`.
2. **Không viết màu cứng cho chữ và nền.** Lấy từ `Theme.of(context).colorScheme` hoặc `GlassTheme.of(context)` để chế độ tối tự đúng. Màu cứng chỉ dùng cho màu nhấn của icon/tính năng (`AppColors.sky`, `AppColors.fig`...).
3. **Kính đặt trên nền có màu.** Kính trong suốt nên cần có gì đó phía sau để khúc xạ. Mọi màn hình phải dùng `GlassScaffold` (đã có nền loang `LiquidBackground`).
4. **Chạm phải có phản hồi lò xo.** Phần tử bấm được bọc `Pressable` (hoặc dùng widget kính có `onTap`/`onPressed`, vốn đã bọc sẵn). Theme đã tắt hiệu ứng gợn sóng của Material.
5. **Ít lớp kính chồng nhau.** Kính trên kính làm nền rối và tốn hiệu năng. Bên trong một `GlassCard` chỉ nên có tối đa một lớp kính nhỏ (vd. nút "Bắt đầu").
6. **Giao diện tiếng Việt, chữ Hán và Pinyin hiển thị đúng font.** Theme đã có font dự phòng `Noto Sans SC` cho chữ Hán, không cần tự đặt.

---

## 2. Màu sắc

### 2.1. Bảng màu gốc (`AppColors`)

| Token | Mã màu | Dùng cho |
|:--|:--|:--|
| `clay` | `#D97757` | Điểm nhấn chính (chế độ tối), icon AI. |
| `clayDeep` | `#C15F3C` | Màu `primary` ở chế độ sáng: nút chính, chữ nhấn. |
| `kraft` | `#D4A27F` | Màu `secondary`. |
| `manilla` | `#EBDBBC` | Nhấn nhẹ trên nền clay (icon lửa streak). |
| `olive` | `#788C5D` | Thành công (`jadeGreen`), `tertiary`. |
| `sky` | `#6A9BCC` | Lộ trình học, thông tin (`infoBlue`). |
| `heather` | `#8B7FB8` | Luyện viết Hán tự. |
| `fig` | `#C46686` | Chấm phát âm. |
| `cactus` | `#5E8C7E` | Thống kê. |
| `ivory` / `pampas` / `oat` | `#FAF9F5` / `#F0EEE6` / `#E3DACC` | Nền giấy, nền đậm hơn, đường kẻ (chế độ sáng). |
| `slate` / `slateMid` / `slateLight` | `#141413` / `#262624` / `#3D3D3A` | Chữ chính, bề mặt tối. |
| `errorRed` / `warningOrange` | `#BF4D43` / `#CC8A2E` | Lỗi, cảnh báo. |

**Mỗi tính năng có một màu nhận diện** (đã dùng ở trang chủ). Màn hình của tính năng nào thì icon, thanh tiến độ, điểm nhấn dùng màu đó:

| Tính năng | Màu |
|:--|:--|
| Trợ lý AI | `clay` |
| Lộ trình học | `sky` |
| Chấm phát âm | `fig` |
| Luyện viết Hán tự | `heather` |
| Flashcard | `secondaryDark` |
| Thống kê | `cactus` |

### 2.2. Màu theo vai trò (lấy từ `colorScheme`)

| Cần | Dùng |
|:--|:--|
| Chữ chính | `colorScheme.onSurface` (mặc định của `textTheme`, không cần đặt). |
| Chữ phụ, mô tả | `colorScheme.onSurfaceVariant`. |
| Nút chính, liên kết, trạng thái đang chọn | `colorScheme.primary`, chữ trên nó là `onPrimary`. |
| Đường kẻ | `colorScheme.outlineVariant` hoặc `Divider()`. |
| Lỗi | `colorScheme.error`. |

```dart
final theme = Theme.of(context);
Text('Hội thoại & Ngữ pháp',
    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
```

### 2.3. Độ tương phản

- Chữ trên kính trong phải đạt tương phản tối thiểu 4.5:1 với nền phía sau. Nếu kính đặt trên vùng nền sặc sỡ, dùng `thick: true` (kính dày, có làm mờ).
- Chữ trên nền `clay`/`clayDeep` dùng `onPrimary` (trắng ở chế độ sáng, than chì ở chế độ tối).
- Không dùng màu làm tín hiệu duy nhất (đúng/sai phải có thêm icon hoặc chữ).

---

## 3. Kiểu chữ

Tiêu đề dùng chữ có chân (serif) kiểu biên tập; thân chữ dùng sans để dễ đọc. Luôn lấy kiểu từ `Theme.of(context).textTheme`, không tự đặt `fontSize` trừ khi chỉnh nhỏ.

| Kiểu | Font | Độ đậm | Dùng cho |
|:--|:--|:--|:--|
| `displaySmall` | Serif | 600 | Tên ứng dụng trên trang chủ. |
| `headlineSmall` … `headlineLarge` | Serif | 600 | Tiêu đề màn hình lớn, tiêu đề hộp thoại trống. |
| `titleLarge` | Serif | 600 | Tiêu đề nhóm nội dung ("Tính Năng Cốt Lõi"). |
| `titleMedium` / `titleSmall` | Sans | 700 | Tiêu đề thẻ, tiêu đề thanh AppBar (17 px). |
| `bodyLarge` / `bodyMedium` / `bodySmall` | Sans | 400 | Nội dung, mô tả. |
| `labelLarge` | Sans | 700 | Chữ trên nút. |

- Chữ Hán trong bài học nên to hơn chữ Việt xung quanh ít nhất 1.5 lần; Pinyin đặt trên hoặc dưới chữ Hán, dùng `bodySmall` màu `onSurfaceVariant`.
- Viết hoa chữ cái đầu mỗi từ cho tiêu đề thẻ và tiêu đề nhóm (theo trang chủ: "Bản Đồ Lộ Trình"), câu mô tả viết như câu thường.

---

## 4. Hình khối và bố cục

### 4.1. Bo góc

Mọi góc bo dùng **squircle** (`RoundedSuperellipseBorder` / `ClipRSuperellipse`), không dùng `RoundedRectangleBorder` cho bề mặt chính.

| Hằng số | Giá trị | Dùng cho |
|:--|:--|:--|
| `AppTheme.radiusSmall` | 14 | Ô nhỏ, nhãn, thumbnail. |
| `AppTheme.radiusMedium` | 22 | `GlassSurface` mặc định, ô nhập, snackbar. |
| `AppTheme.radiusLarge` | 30 | `GlassCard` mặc định, hộp thoại, bottom sheet. |
| `StadiumBorder` / `circular(100)` | viên thuốc | Mọi nút, chip, nhãn trạng thái. |
| `circular(size / 2)` | tròn | Nút icon (`GlassIconButton`). |

### 4.2. Icon nền "bánh quy" (`CookieIcon`)

Icon đại diện cho tính năng hoặc mục trong danh sách đặt trên nền hình bánh quy của Material Expressive:

```dart
const CookieIcon(icon: Icons.insights_outlined, color: AppColors.cactus);          // 48 px, 9 múi
const CookieIcon(icon: Icons.smart_toy_outlined, color: AppColors.clay, size: 60, lobes: 12);
```

- `size` mặc định 48 cho thẻ thường, 60 cho thẻ nổi bật, 88 cho màn hình trống.
- Đổi `lobes` (6, 9, 12) để các icon cạnh nhau không giống hệt nhau.
- Dùng icon dạng nét (`*_outlined`) hoặc `CupertinoIcons`.

### 4.3. Khoảng cách

Dùng bội số của 4. Các giá trị đang dùng:

| Khoảng | Giá trị |
|:--|:--|
| Lề trái/phải của màn hình | 16 |
| Giữa các thẻ cùng nhóm | 12 |
| Giữa tiêu đề nhóm và nội dung | 12 |
| Giữa các nhóm nội dung | 20–28 |
| Padding trong thẻ | 16 (mặc định), 18–20 cho thẻ lớn |
| Giữa tiêu đề và mô tả trong thẻ | 2–4 |

Vùng chạm tối thiểu **44 × 44** (mặc định của `GlassIconButton`), nút chữ cao tối thiểu 48–52.

### 4.4. Khung màn hình

```dart
@override
Widget build(BuildContext context) {
  final pad = MediaQuery.paddingOf(context);
  return GlassScaffold(
    appBar: GlassAppBar(
      title: const Text('Luyện Viết Hán Tự'),
      actions: [GlassIconButton(icon: CupertinoIcons.info, tooltip: 'Hướng dẫn', onPressed: () {})],
    ),
    body: ListView(
      // Nội dung cuộn xuyên dưới AppBar kính → chừa pad.top.
      padding: EdgeInsets.fromLTRB(16, pad.top + 4, 16, pad.bottom + 24),
      children: [...],
    ),
  );
}
```

- `GlassAppBar` tự hiện nút quay lại dạng kính tròn khi màn hình có thể pop.
- Muốn thanh tiêu đề trong suốt lúc chưa cuộn (như iOS) thì truyền `backgroundOpacity` theo vị trí cuộn (0 → 1).
- Thanh dưới (nếu có) truyền vào `bottomBar` và bọc trong `GlassSurface(thick: true)`.

---

## 5. Vật liệu kính (Liquid Glass)

### 5.1. Hai loại kính

| Loại | Cách gọi | Hiển thị | Dùng cho |
|:--|:--|:--|:--|
| **Kính thường** | mặc định | Trong suốt, không làm mờ. Nền phía sau nhìn rõ, mép kính bẻ cong nền xung quanh vào trong, có tán sắc màu nhẹ. | Thẻ, nút, nút tròn, nhãn. |
| **Kính dày** | `thick: true` | Làm mờ + tăng bão hoà nền, lớp phủ đặc hơn (~40%). | Thanh điều hướng, ô nhập, bottom sheet, thẻ có nhiều chữ đặt trên nền sặc sỡ. |
| **Kính nhuộm màu** | `tint: màu.withValues(alpha: 0.88–0.92)` | Như kính thường nhưng phủ màu. | Nút chính (`GlassButton(prominent: true)` đã làm sẵn), nhãn nhấn. |

### 5.2. Các widget

```dart
// Thẻ bấm được (co lại + rung nhẹ khi nhấn).
GlassCard(
  onTap: () => context.push(AppConstants.writingRoute),
  child: Row(children: [
    const CookieIcon(icon: Icons.brush_outlined, color: AppColors.heather),
    const SizedBox(width: 14),
    Expanded(child: Text('Luyện Viết Hán Tự', style: theme.textTheme.titleMedium)),
  ]),
);

// Nút.
GlassButton(label: 'Bắt đầu học', icon: Icons.play_arrow_rounded, prominent: true, expand: true, onPressed: _start);
GlassButton(label: 'Để sau', onPressed: () => context.pop());

// Nút tròn.
GlassIconButton(icon: CupertinoIcons.mic, tooltip: 'Ghi âm', onPressed: _record);

// Lớp kính trần (nhãn, khung tuỳ biến).
GlassSurface(
  borderRadius: BorderRadius.circular(100),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  child: const Text('3 ngày liên tiếp'),
);
```

Tham số hay dùng của `GlassSurface`: `thick`, `tint`, `shadow` (tắt bóng khi kính nằm trong kính), `shadowScale` (< 1 cho kính nhỏ), `optics` (thông số khúc xạ, xem 5.4).

### 5.3. Widget Material

`Card`, `OutlinedButton`, `Chip`, `TextField` của Material **không** có hiệu ứng kính; theme cho chúng nền "kính đặc" (nửa kính thường, nửa kính dày) để hợp màu. Chúng dùng được ở chỗ cần hiệu năng (danh sách dài hàng trăm dòng) hoặc trong form. `ElevatedButton`/`FilledButton` đã được đổi sang dạng viên thuốc màu `primary`.

### 5.4. Cách kính hoạt động (để không vô tình làm hỏng)

- Hiệu ứng khúc xạ là shader `shaders/glass_lens.frag`, nạp ở `main.dart` bằng `GlassLens.init()`. Shader **chỉ chạy trên Impeller** (Android/iOS). Trên web, Skia và trong `flutter test`, `GlassLens.available == false` và kính tự chuyển về kính mờ thường, nên test widget vẫn chạy bình thường.
- Kính thường lấy mẫu nền **ở phía ngoài mép** rồi nén vào dải mép (bezel ~24 px). Vì vậy kính thường **không được làm mờ trước**: kết quả làm mờ chỉ có trong khung kính, lấy mẫu ra ngoài sẽ lộ đường nối.
- Kính dày (có làm mờ) và kính nhỏ (cạnh ngắn < 64 px, vd. nút tròn) kéo mẫu **vào trong** để không hút viền thanh tiêu đề hay nút bên cạnh vào mép.
- Độ sáng của nền lấy từ ngoài mép được cân về bằng nền ngay dưới kính, để bóng đổ của chính kính không tạo dải tối ở mép.
- Bóng đổ chỉ vẽ phía ngoài kính (`_OuterShadowPainter`), phần dưới kính được xoá với mép mềm.
- **Kính lồng trong kính** (nút trong thẻ, viên trong banner...) tự tắt khúc xạ và chỉ vẽ lớp phủ đặc hơn + viền trên nền kính cha. Lý do: Impeller đưa cho `BackdropFilter` lồng nhau một texture nền nhỏ có gốc toạ độ khác màn hình, shader sẽ lấy mẫu sai chỗ (lòng nút trắng loá, dải lệch ở mép). Việc này tự động qua `_GlassScope`, không cần làm gì thêm.
- Toàn app cuộn kiểu iOS (`AppScrollBehavior` trong `main.dart`: nảy ở mép, không kéo giãn kiểu Android). Hiệu ứng kéo giãn biến đổi nội dung mà không đổi vị trí cuộn nên kính không được vẽ lại và bị lệch. Đừng đặt lại `ClampingScrollPhysics` hay `StretchingOverscrollIndicator` cho danh sách có kính.
- Shader cần biết vị trí kính trên màn hình, nên `LensBackdrop` tự vẽ lại khi cuộn và khi chuyển trang. Nếu kính nằm trong animation tự viết (không phải cuộn/route) mà mép bị "trễ" so với nền, gọi `setState` theo animation đó.

Thông số trong `LensOptics` (mặc định `bezel: 24, refraction: 11, dispersion: 0.3, specular: 0.55`). Chỉ đổi khi thật cần, vd. thẻ rất lớn có thể tăng `bezel`. Ở chế độ tối, độ sáng viền tự giảm còn 55%.

### 5.5. Không nên

- Đặt kính trực tiếp trên nền trắng/đen phẳng (không thấy hiệu ứng). Luôn dùng `GlassScaffold`.
- Bọc `GlassSurface` trong `Opacity` khi đang animation dài: dùng `AnimatedOpacity` ngắn như các widget có sẵn.
- Đặt hàng chục `GlassCard` trong một danh sách dài: mỗi thẻ là một lớp backdrop. Với danh sách > 30 dòng, dùng `Card` Material hoặc gom nhiều dòng vào một thẻ kính.
- Tự thêm `BoxShadow` quanh kính (bóng sẽ lộ qua lòng kính trong suốt).

---

## 6. Chuyển động

| API | Dùng khi |
|:--|:--|
| `Pressable(onTap: ..., child: ...)` | Mọi phần tử bấm được tự làm. Co lại (mặc định 0.95) khi nhấn, bật lại bằng lò xo, rung nhẹ. Thẻ dùng 0.96, nút tròn 0.86. |
| `EntranceAnimation(index: i, child: ...)` | Phần tử xuất hiện lần lượt khi vào màn hình (mỗi phần tử trễ 45 ms). Đánh `index` tăng dần từ trên xuống. |
| `MorphSwitcher(child: Icon(x, key: ValueKey(x)))` | Đổi icon mượt (mic ↔ stop, play ↔ pause). |
| `AppMotion.springSnappy` / `springBouncy` / `springSmooth` | `Curve` lò xo cho `AnimatedScale`, `AnimatedContainer`, `TweenAnimationBuilder`. Snappy cho phản hồi chạm, bouncy cho phần tử xuất hiện, smooth cho thay đổi kích thước/bố cục. |
| `AppMotion.emphasized` | Đường cong Material 3 cho chuyển động không cần nảy. |
| `AppMotion.short` / `medium` / `long` | 220 / 380 / 560 ms. |

Chuyển trang dùng kiểu Cupertino (trượt ngang, vuốt mép để quay lại) trên mọi nền tảng, đã đặt trong theme.

---

## 7. Chế độ tối

- Ứng dụng theo cài đặt hệ thống. Theme tối có sẵn: nền than chì ấm, các đốm màu nền trầm hơn, viền kính dịu hơn.
- Kiểm tra mỗi màn hình ở cả hai chế độ trước khi mở PR. Lỗi hay gặp: chữ viết màu cứng `Colors.black`, icon màu `AppColors.slate`.
- Màu nhận diện tính năng giữ nguyên ở cả hai chế độ.

---

## 8. Trạng thái màn hình

| Trạng thái | Cách hiển thị |
|:--|:--|
| Đang tải | `CircularProgressIndicator` (theme đã bo đầu và tô màu `primary`) giữa màn hình, hoặc khung thẻ kính rỗng. |
| Trống | `ComingSoonView`-style: `GlassCard` giữa màn hình gồm `CookieIcon` 88 px, tiêu đề `headlineSmall`, mô tả `bodyMedium` màu `onSurfaceVariant`. |
| Lỗi mạng | `SnackBar` (đã nổi, bo góc) kèm nút "Thử lại"; nếu cả màn hình lỗi thì dùng mẫu trạng thái trống với icon `CupertinoIcons.wifi_slash` và `GlassButton` "Thử lại". |
| Chưa làm xong | `ComingSoonView(icon:, color:, title:, message:)`. |

---

## 9. Kiểm tra trước khi mở PR

- [ ] Màn hình dùng `GlassScaffold` + `GlassAppBar`, nội dung chừa `MediaQuery.paddingOf(context).top`.
- [ ] Không có màu cứng cho chữ/nền; chữ phụ dùng `onSurfaceVariant`.
- [ ] Bo góc dùng hằng số `AppTheme.radius*`, nút dạng viên thuốc.
- [ ] Phần tử bấm được có `Pressable` hoặc là widget kính có `onTap`/`onPressed`; nút icon có `tooltip`.
- [ ] Vùng chạm ≥ 44 × 44.
- [ ] Đã xem ở chế độ sáng và tối, trên **máy thật** (máy ảo và `flutter test` không chạy shader kính).
- [ ] `flutter analyze` sạch, `flutter test` qua.

### Mẹo khi chỉnh giao diện kính trên máy thật

- Hot reload có cập nhật shader, nhưng **chỉ trong phiên `flutter run` đang chạy**. Nếu tắt `flutter run` rồi mở lại app từ màn hình chính, máy chạy bản APK đã cài lần trước. Sau khi sửa shader hoặc theme, chạy lại `flutter run` để cài bản mới trước khi chụp ảnh gửi nhóm.
- Chụp màn hình để so sánh: `adb exec-out screencap -p > shot.png`.
