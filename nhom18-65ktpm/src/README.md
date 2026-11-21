# Ứng dụng Kết nối & Tình nguyện xe máy — Nhóm 18

Flutter + Supabase (Auth, Postgres/PostGIS, Storage, Realtime) + Google Maps. Chỉ hỗ trợ Android trong môn học.

## Trạng thái bàn giao

Đã có:

- Schema 5 bảng, RLS, RPC PostGIS, seed (`../supabase/`).
- 5 model + hợp đồng repository.
- UC-01: đăng nhập / đăng ký / chặn tài khoản bị khóa / điều hướng theo vai trò.
- 4 shell rỗng để từng người thay nội dung.

Chưa có (đúng phân công): bản đồ & tìm kiếm, gọi điện/chỉ đường, SOS, đánh giá, chủ tiệm, tình nguyện viên, admin, FCM.

## Chạy lần đầu

```bash
flutter pub get
# Windows
Copy-Item env.json.example env.json
# macOS/Linux
cp env.json.example env.json
```

1. Điền `SUPABASE_URL` + anon/publishable key vào `env.json`.
2. Chạy SQL trong `../supabase/` theo hướng dẫn ở `../supabase/README.md`.
3. Thay `YOUR_GOOGLE_MAPS_API_KEY` trong `android/app/src/main/AndroidManifest.xml`.
4. Chạy app:

```bash
flutter run --dart-define-from-file=env.json
```

Không có `env.json` app vẫn mở nhưng hiện màn hình hướng dẫn cấu hình.

Kiểm tra trước khi mở PR:

```bash
flutter analyze   # phải 0 issue
flutter test      # phải pass
```

## Cấu trúc & người sở hữu

```
lib/
  core/
    env.dart, supabase_client.dart, theme.dart, validators.dart
    auth_gate.dart            # Thuận
    shells/                   # mỗi người sửa shell của mình
  models/                     # Thuận (đã chốt, không tự đổi tên cột)
  repositories/               # hợp đồng dùng chung
  features/
    auth/                     # Thuận (UC-01)
    map/ shop/                # Hiếu (UC-02, 03, 04)
    call/ navigation/ sos/ review/   # Quân (UC-05 → UC-08)
    owner/                    # Hiếu (UC-09, 10, 11 phần chủ tiệm)
    volunteer/                # Tùng (UC-11 phần TNV, 13)
    admin/                    # Hiếu (UC-14, 15)
```

Quy ước trong mỗi module: `screens/` + `widgets/`; phần gọi Supabase đặt cạnh module (ví dụ `features/sos/data/supabase_sos_repository.dart`).

## Hợp đồng module

| Repository | Ai làm | Ghi chú |
|---|---|---|
| `AuthRepository` | Thuận | đã chạy được, dùng luôn |
| `ShopRepository` | Thuận (đọc) + Hiếu (CRUD) | `nearby()` gọi RPC `get_nearby_shops` |
| `ReviewRepository` | Quân | mỗi rider 1 review/tiệm → dùng `upsert` |
| `SosRepository` | Quân: `create/watchPending/cancel`; Tùng: `accept/complete/contact` | nhận ca **bắt buộc** qua RPC `accept_sos` |
| `VolunteerRepository` | Tùng | `updateLocation` ghi EWKT: `SRID=4326;POINT(lng lat)` |

Ba điểm giáp ranh, không tự đổi:

1. **UC-07**: Quân tạo SOS, Tùng nhận. Payload FCM (khi làm): `{sos_id, issue_type, lat, lng}`.
2. **UC-11**: chủ tiệm dùng `shops.is_open`, TNV dùng `volunteer_profiles.is_available` — hai hàm riêng, không gộp.
3. **Khóa ca**: chỉ `accept_sos` được đổi `status` sang `accepted`; không update trực tiếp bảng `sos_requests`.

## Git

- Nhánh của mỗi người: `feat/quan-rider`, `feat/tung-sos-volunteer`, `feat/hieu-owner-admin`.
- Mở PR vào `nhom/nhom18-65ktpm`, chỉ Thuận merge.
- Commit: `feat(scope): ...`, `fix(scope): ...`, `docs(scope): ...`.
- Definition of Done: chạy máy thật → `flutter analyze` 0 issue → `flutter test` pass → có ảnh/video demo trong PR.

## Tài khoản test

Xem bảng trong `../supabase/README.md`. Mật khẩu gợi ý `123456`.

## Lỗi thường gặp

- `st_dwithin does not exist` → PostGIS chưa bật hoặc function thiếu `extensions` trong `search_path` (đã xử lý trong `03_functions.sql`).
- Đăng nhập xong quay lại form → chưa có dòng trong `public.users`; kiểm tra trigger `on_auth_user_created` đã chạy.
- Bản đồ trắng → chưa thay Google Maps API key hoặc chưa bật billing.
- `permission denied for table ...` → thiếu policy RLS tương ứng, không phải thiếu key.
