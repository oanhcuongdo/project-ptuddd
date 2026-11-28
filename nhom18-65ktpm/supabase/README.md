# Supabase – thứ tự chạy

Chạy lần lượt trong **Supabase Dashboard → SQL Editor**:

| File | Nội dung |
|---|---|
| `01_schema.sql` | Bật PostGIS, tạo 5 bảng + index |
| `02_rls.sql` | Bật RLS và policy cho từng vai trò |
| `03_functions.sql` | Trigger tạo hồ sơ, trigger bảo vệ cột, RPC tìm quanh đây / nhận ca |
| `04_storage.sql` | Bucket ảnh tiệm, avatar, giấy tờ TNV + policy |
| `05_seed.sql` | Dữ liệu mẫu (10 tiệm quanh Hà Nội, 2 TNV, review) |
| `06_sos_volunteer.sql` | Realtime SOS, quy tắc hồ sơ TNV, khóa ca, ca hết hạn sau 5 phút, hộp thư SOS, FCM |

DB đã chạy 01–05 từ trước thì chỉ cần chạy thêm `06_sos_volunteer.sql`.

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

## Thông báo SOS qua FCM (Edge Function `notify-sos`)

Không làm phần này app vẫn chạy: chủ tiệm / TNV nhận ca qua realtime khi đang mở app.
Làm để nhận cảnh báo cả khi app ở nền hoặc đã tắt.

1. **Firebase Console** → tạo project → *Add app* Android với package `com.example.ketnoitinhnguyenvienxemay`.
   Mở *Project settings* → *General* → ứng dụng Android, chép 4 giá trị vào `src/env.json`:
   `FIREBASE_API_KEY` (Web API Key), `FIREBASE_APP_ID` (App ID), `FIREBASE_MESSAGING_SENDER_ID` (Project number), `FIREBASE_PROJECT_ID`.
   Không cần `google-services.json`.
2. *Project settings* → *Service accounts* → *Generate new private key* → tải file JSON (không commit file này).
3. Deploy function (cần [Supabase CLI](https://supabase.com/docs/guides/cli)), chạy trong thư mục `nhom18-65ktpm/`:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat duong-dan/service-account.json)" SOS_WEBHOOK_SECRET=<chuoi-bi-mat-tu-dat>
   supabase functions deploy notify-sos --no-verify-jwt
   ```

   `--no-verify-jwt` vì webhook không gửi JWT; function tự kiểm tra header `x-webhook-secret`.
4. **Dashboard → Database → Webhooks → Create**: table `sos_requests`, event **Insert**,
   type *Supabase Edge Functions* → `notify-sos`, method POST, thêm HTTP header
   `x-webhook-secret: <chuoi-bi-mat-tu-dat>`.

Kiểm tra: đăng nhập `volunteer1@test.local` trên máy thật, bật *Sẵn sàng*, thoát ra màn hình chính;
dùng máy khác đăng nhập `rider1@test.local` gửi SOS gần đó → máy TNV hiện thông báo.
Xem log: **Dashboard → Edge Functions → notify-sos → Logs** (kết quả dạng `{"sent":1,"failed":0,"cleared":0}`).

Ai được báo (RPC `get_sos_recipients` dựa trên `sos_helpers`, trùng logic hộp thư `get_my_pending_sos`; app rider dùng `count_sos_helpers` để biết quanh mình có ai không):
TNV đã duyệt + đang sẵn sàng + ca nằm trong bán kính hỗ trợ; tiệm đã duyệt + đang mở cửa + trong 5 km
(cây xăng chỉ nhận ca "Hết xăng"); không gửi cho chính rider và tài khoản bị khóa.

## Lấy key cho app

**Project Settings → API**: dùng `Project URL` + `anon public key`.
Không bao giờ đưa `service_role key` vào app.

## Lỗi thường gặp

- `type "geography" does not exist` → chưa chạy `create extension postgis` (đầu file 01).
- Seed báo thiếu `owner1@test.local` → tạo tài khoản trên Dashboard rồi chạy lại 05.
- RPC trả 0 dòng → kiểm tra tiệm có `status = 'approved'` và `is_open` đúng.
