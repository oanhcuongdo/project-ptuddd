# Supabase – thứ tự chạy

Chạy lần lượt trong **Supabase Dashboard → SQL Editor**:

| File | Nội dung |
|---|---|
| `01_schema.sql` | Bật PostGIS, tạo 5 bảng + index |
| `02_rls.sql` | Bật RLS và policy cho từng vai trò |
| `03_functions.sql` | Trigger tạo hồ sơ, trigger bảo vệ cột, RPC tìm quanh đây / nhận ca |
| `04_storage.sql` | Bucket ảnh tiệm, avatar, giấy tờ TNV + policy |
| `05_seed.sql` | Dữ liệu mẫu (10 tiệm quanh Hà Nội, 2 TNV, review) |

## Trước khi chạy `05_seed.sql`

Vào **Authentication → Users → Add user** (bật *Auto Confirm User*), tạo:

| Email | Vai trò sau seed | Bắt buộc |
|---|---|---|
| `owner1@test.local` | owner | có |
| `owner2@test.local` | owner | có |
| `volunteer1@test.local` | volunteer | không |
| `volunteer2@test.local` | volunteer | không |
| `rider1@test.local` | rider | không |
| `admin@test.local` | admin | không |

Mật khẩu gợi ý: `123456` (Supabase yêu cầu tối thiểu 6 ký tự).

## Kiểm tra nhanh sau khi chạy

1. `select count(*) from public.shops;` → 10.
2. Đăng nhập bằng `owner1@test.local`, sửa tiệm của `owner2` → phải bị RLS chặn.
3. `select * from public.get_nearby_shops(21.0285, 105.8542, 3000);` → danh sách tiệm gần Hồ Gươm, có `distance_m`.
4. `select * from public.get_nearby_volunteers(21.0285, 105.8542);` → 2 TNV đang sẵn sàng.

## Lấy key cho app

**Project Settings → API**: dùng `Project URL` + `anon public key`.
Không bao giờ đưa `service_role key` vào app.

## Lỗi thường gặp

- `type "geography" does not exist` → chưa chạy `create extension postgis` (đầu file 01).
- Seed báo thiếu `owner1@test.local` → tạo tài khoản trên Dashboard rồi chạy lại 05.
- RPC trả 0 dòng → kiểm tra tiệm có `status = 'approved'` và `is_open` đúng.
