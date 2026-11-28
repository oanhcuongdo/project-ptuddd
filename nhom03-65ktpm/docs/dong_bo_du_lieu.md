# Đồng bộ dữ liệu đa thiết bị (#21)

> Đọc cùng [co_so_du_lieu.md](co_so_du_lieu.md) (schema + RLS) và
> [ui_ux.md](ui_ux.md) §5 (`SyncStatusIndicator`).
> Cập nhật ngày **27/11/2026**.

## 1. Kiến trúc

| Thành phần | Vai trò |
|---|---|
| Drift (SQLite trên máy) | **Cache offline theo Firebase UID** cho chế độ đồng bộ |
| Supabase `public.notes` | **Nguồn dùng chung** — REST để đọc, RPC `save_note_revision` để ghi và lưu phiên bản, Realtime để nhận thay đổi |
| Firebase Auth | Danh tính; ID token được gửi làm JWT cho Supabase |

Luồng:

- **Đọc**: `NotesPage` → `NotesCubit` → `NoteRepository.watchNotes()` → `NotesDao.watchAll()`.
- **Ghi**: ghi Drift trước (luôn thành công kể cả khi mất mạng) → đẩy Supabase (best effort).
  Lỗi mạng giữ thay đổi ở cache, hiện lỗi đồng bộ và tự thử lại sau 5 giây.
- **Nhận**: `.stream()` trên bảng `notes` (lọc `user_id`) → hợp nhất → ghi Drift → UI tự cập nhật.

Mã nguồn:

| File | Nội dung |
|---|---|
| `core/services/supabase_bootstrap.dart` | Khởi tạo Supabase từ `--dart-define`, gắn ID token Firebase |
| `core/sync/sync_status.dart` | `SyncStatus` + `SyncMonitor` (nguồn phát trạng thái) |
| `features/notes/data/sync/note_sync_rules.dart` | Quy tắc hợp nhất (hàm thuần, có test) |
| `features/notes/data/datasources/remote/` | Interface + hiện thực Supabase |
| `features/notes/data/repositories/synced_note_repository.dart` | Gộp Drift + Supabase |
| `features/notes/presentation/widgets/sync_status_indicator.dart` | Chỉ báo trên AppBar |

## 2. Quy tắc hợp nhất

1. **Bản có `updated_at` mới hơn thắng** — áp dụng cho cả hai chiều.
2. **Hoà mốc thời gian mà nội dung khác nhau → bản trên máy chủ thắng** để mọi thiết bị
   hội tụ về cùng một kết quả (nếu cho máy thắng, hai máy sẽ đẩy qua đẩy lại vô hạn).
3. **Xoá mềm**: `deleted_at` là một thay đổi như mọi thay đổi khác. Máy nhận tombstone sẽ
   ẩn ghi chú (`deleted_at IS NULL` khi đọc) nhưng **vẫn giữ dòng** để không bị hồi sinh.
4. RPC khóa bản ghi trên Postgres trước khi so thời gian. Nếu nội dung khác,
   phiên bản thua được giữ trong `note_versions` trước khi bản thắng thay thế.
   Ghi chú phía máy cũng được gửi để lưu phiên bản trước khi bị thay trong cache.
5. Bản sửa cục bộ trong lúc request đang chờ được giữ để đồng bộ lượt tiếp theo.
   Các lần lưu liên tiếp trên cùng máy dùng thời gian tăng đơn điệu theo độ chính
   xác giây của Drift.

## 3. Quy ước id

- Bảng `notes.id` là `uuid`. Vì vậy **id ghi chú được sinh ngay trên máy** bằng UUID v4
  (`NotesCubit.createNote`) để ghi được khi offline rồi mới đẩy lên.
- Ghi chú tạo bằng id cũ (`microsecondsSinceEpoch-…`) sẽ không đẩy được; app hiện thông báo
  "có mã cũ nên chưa đồng bộ được" thay vì lỗi im lặng.

## 4. Cấu hình để chạy thật

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://hxzimpvamyzyqdhkxexl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon/publishable key>
```

Thiếu biến → app chạy chế độ **chỉ lưu trên máy** (`SyncStatus.disabled`, không hiện chỉ báo).

Trước khi chạy thật, áp dụng [SQL phiên bản và Realtime](sql/20261127_dong_bo_phien_ban_ghi_chu.sql).
SDK sẽ dùng RPC mới cho tất cả lần ghi đồng bộ.

Điều kiện phía Supabase (Dashboard):

1. **Authentication → Third-party auth → Firebase**: nhập Firebase Project ID.
2. Người dùng Firebase phải có custom claim `role = "authenticated"`; nếu không, request chạy
   như `anon` và RLS từ chối toàn bộ (bảng rỗng, không lỗi rõ ràng).
3. RLS đã đúng: `notes_owner` dùng `user_id = (select auth.jwt() ->> 'sub')`.

Chỉ dùng **anon/publishable key** trong app. Không nhúng khoá quản trị cấp server —
`test/security/no_api_key_test.dart` sẽ chặn nếu ai đó làm vậy.

## 5. Cách kiểm thử 2 thiết bị (tiêu chí 1 & 2)

1. Bật rồi chạy hai máy/emulator cùng tài khoản với lệnh trên.
2. Máy A tạo ghi chú → trong vài giây máy B phải thấy (icon chuyển **Đã đồng bộ**).
3. Máy A sửa, máy B sửa cùng ghi chú khi **tắt mạng một máy** → bật lại, bản có `updated_at`
   mới hơn thắng. Truy vấn `note_versions` với đúng UID và ID ghi chú để xác nhận bản còn lại được giữ.
4. Máy A xoá → máy B ẩn ghi chú; mở lại app trên B vẫn không "hồi sinh".
5. Tắt mạng cả hai: tạo/sửa vẫn hoạt động, chỉ báo đổi sang **Lỗi đồng bộ**; có mạng lại thì
   lần đồng bộ kế tiếp đẩy thay đổi lên.

## 6. Giới hạn hiện tại

- Đồng bộ hiện áp dụng cho ghi chú và nhật ký lưu trong bảng `notes`.
- Lịch sử phiên bản đọc được qua bảng `note_versions` với RLS theo UID.
  Ứng dụng hiện chưa có màn phục hồi lịch sử.
- Cache dùng tệp SQLite riêng cho từng Firebase UID khi bật đồng bộ. Tệp
  `smart_note` từ chế độ chỉ lưu trên máy vẫn được giữ. Nó không tự nhập sang
  tài khoản cloud vì các bản ghi cũ không chứa UID chủ sở hữu.
- Xác minh trên Supabase thật cần Third-party auth Firebase, claim
  `authenticated`, publishable key và hai phiên thử đã đăng nhập cùng UID.
