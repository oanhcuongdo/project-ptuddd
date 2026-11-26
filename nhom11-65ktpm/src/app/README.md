# ChaiLish – Ứng dụng Flutter

Ứng dụng di động học tiếng Trung của Nhóm 11 – 65KTPM. Tổng quan dự án xem [README của nhóm](../../README.md).

## Chạy nhanh

```bash
flutter pub get
flutter run                                                     # Android Emulator
adb reverse tcp:8000 tcp:8000 && \
  flutter run --dart-define=API_BASE_URL=http://localhost:8000/api  # Điện thoại thật qua USB
flutter analyze && flutter test
```

Chi tiết cài đặt và lỗi hay gặp: [docs/huong-dan-setup.md](../../docs/huong-dan-setup.md).

## Cấu trúc

```text
lib/
├── main.dart              # Khởi tạo, nạp shader kính (GlassLens.init)
├── core/
│   ├── constants/         # Tên route, hằng số
│   ├── motion/            # AppMotion, Pressable, EntranceAnimation, MorphSwitcher
│   ├── network/           # ApiClient (JWT, tự refresh), SSE
│   ├── routing/           # GoRouter
│   ├── storage/           # Secure storage
│   ├── theme/             # AppColors, GlassTheme, AppTheme (sáng/tối)
│   └── widgets/           # Widget kính, shader khúc xạ, CookieIcon
└── features/<tính năng>/  # presentation (+ data, application khi cần) cho từng module
shaders/glass_lens.frag    # Shader khúc xạ mép kính (Impeller)
test/                      # Unit test và widget test
```

## Giao diện

Ứng dụng dùng hình khối Material 3 Expressive và vật liệu Liquid Glass. Trước khi làm màn hình mới, đọc [docs/huong-dan-thiet-ke-ui.md](../../docs/huong-dan-thiet-ke-ui.md).

Lưu ý: hiệu ứng khúc xạ của kính chỉ chạy trên Impeller (điện thoại thật). Trên Skia, web và trong `flutter test`, kính tự chuyển về kính mờ thường.
