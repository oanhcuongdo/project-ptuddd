-- 05_seed.sql
-- Dữ liệu mẫu để 3 bạn còn lại code song song.
-- Chạy SAU KHI đã tạo tài khoản test trên Supabase Dashboard > Authentication > Users
-- (nhớ bật "Auto Confirm User"):
--   owner1@test.local, owner2@test.local  (bắt buộc)
--   volunteer1@test.local, volunteer2@test.local, rider1@test.local, admin@test.local (tùy chọn)
-- Sau đó chạy file này: nó tự gán role và tạo tiệm/TNV quanh Hồ Gươm.

do $$
declare
  v_owner1 uuid;
  v_owner2 uuid;
  v_vol1 uuid;
  v_vol2 uuid;
  v_rider1 uuid;
  v_admin uuid;
begin
  select id into v_owner1 from public.users where email = 'owner1@test.local';
  select id into v_owner2 from public.users where email = 'owner2@test.local';
  select id into v_vol1 from public.users where email = 'volunteer1@test.local';
  select id into v_vol2 from public.users where email = 'volunteer2@test.local';
  select id into v_rider1 from public.users where email = 'rider1@test.local';
  select id into v_admin from public.users where email = 'admin@test.local';

  if v_owner1 is null or v_owner2 is null then
    raise exception
      'Chưa có owner1@test.local / owner2@test.local. Tạo 2 tài khoản này trên Supabase Dashboard trước rồi chạy lại.';
  end if;

  -- Gán role cho tài khoản test (tài khoản tạo trên Dashboard mặc định là rider).
  update public.users set role = 'owner' where id = v_owner1;
  update public.users set role = 'owner' where id = v_owner2;
  if v_vol1 is not null then
    update public.users set role = 'volunteer' where id = v_vol1;
  end if;
  if v_vol2 is not null then
    update public.users set role = 'volunteer' where id = v_vol2;
  end if;
  if v_admin is not null then
    update public.users set role = 'admin', status = 'active' where id = v_admin;
  end if;

  -- ===== Tiệm sửa xe / cây xăng quanh Hà Nội =====
  insert into public.shops
    (id, owner_id, name, category, phone, address, latitude, longitude,
     open_time, close_time, is_open, rating, review_count, status)
  values
    ('11111111-1111-4111-8111-000000000001', v_owner1,
     'Tiệm sửa xe Hùng Cường', 'repair_shop', '0912345601',
     '12 Hàng Bông, Hoàn Kiếm, Hà Nội', 21.0290, 105.8480,
     '07:00', '21:00', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000002', v_owner1,
     'Cây xăng Petrolimex Trần Quang Khải', 'gas_station', '0912345602',
     '88 Trần Quang Khải, Hoàn Kiếm, Hà Nội', 21.0248, 105.8590,
     '00:00', '23:59', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000003', v_owner1,
     'Sửa xe Minh Anh', 'repair_shop', '0912345603',
     '45 Nguyễn Lương Bằng, Đống Đa, Hà Nội', 21.0180, 105.8290,
     '08:00', '20:00', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000004', v_owner1,
     'Cây xăng Quân Đội', 'gas_station', '0912345604',
     '1 Lê Duẩn, Đống Đa, Hà Nội', 21.0170, 105.8350,
     '06:00', '22:00', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000005', v_owner1,
     'Tiệm sửa xe Thành Đạt', 'repair_shop', '0912345605',
     '102 Cầu Giấy, Cầu Giấy, Hà Nội', 21.0310, 105.8010,
     '07:30', '21:30', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000006', v_owner2,
     'Sửa xe Phú Quý', 'repair_shop', '0912345606',
     '15 Xuân Thủy, Cầu Giấy, Hà Nội', 21.0370, 105.7830,
     '08:00', '20:00', true, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000007', v_owner2,
     'Cây xăng Dầu khí Hà Nội', 'gas_station', '0912345607',
     '230 Đê La Thành, Ba Đình, Hà Nội', 21.0300, 105.8120,
     '00:00', '23:59', true, 0, 0, 'approved'),
    -- Tiệm đang đóng: dùng để test bộ lọc "chỉ hiện đang mở".
    ('11111111-1111-4111-8111-000000000008', v_owner2,
     'Tiệm sửa xe Bình Minh', 'repair_shop', '0912345608',
     '77 Bạch Mai, Hai Bà Trưng, Hà Nội', 21.0010, 105.8430,
     '07:00', '22:00', false, 0, 0, 'approved'),
    ('11111111-1111-4111-8111-000000000009', v_owner2,
     'Sửa xe Long Biên', 'repair_shop', '0912345609',
     '5 Ngọc Lâm, Long Biên, Hà Nội', 21.0450, 105.8720,
     '08:00', '19:00', true, 0, 0, 'approved'),
    -- Tiệm chờ duyệt: dùng để test màn Admin (UC-14).
    ('11111111-1111-4111-8111-000000000010', v_owner2,
     'Tiệm sửa xe Hoàng Gia', 'repair_shop', '0912345610',
     '3 Tây Sơn, Đống Đa, Hà Nội', 21.0080, 105.8250,
     '07:00', '21:00', true, 0, 0, 'pending')
  on conflict (id) do nothing;

  -- ===== Hồ sơ tình nguyện viên =====
  if v_vol1 is not null then
    insert into public.volunteer_profiles
      (id, user_id, phone, skills, tools, id_card_url, service_radius_km,
       location, is_available, status, completed_count)
    values
      ('22222222-2222-4222-8222-000000000001', v_vol1, '0987000001',
       array['Vá xe', 'Kích bình'], 'Bộ vá, bơm điện', 'seed/cccd-1.jpg', 10,
       st_setsrid(st_makepoint(105.8520, 21.0280), 4326)::geography,
       true, 'approved', 0)
    on conflict do nothing;
  else
    raise notice 'Bỏ qua volunteer1: chưa có tài khoản volunteer1@test.local';
  end if;

  if v_vol2 is not null then
    insert into public.volunteer_profiles
      (id, user_id, phone, skills, tools, id_card_url, service_radius_km,
       location, is_available, status, completed_count)
    values
      ('22222222-2222-4222-8222-000000000002', v_vol2, '0987000002',
       array['Tiếp xăng', 'Kéo xe'], 'Can xăng 5L, dây kéo', 'seed/cccd-2.jpg', 8,
       st_setsrid(st_makepoint(105.8100, 21.0200), 4326)::geography,
       true, 'approved', 0)
    on conflict do nothing;
  else
    raise notice 'Bỏ qua volunteer2: chưa có tài khoản volunteer2@test.local';
  end if;

  -- ===== Đánh giá mẫu (trigger tự tính lại rating/review_count) =====
  if v_rider1 is not null then
    insert into public.reviews (id, shop_id, rider_id, rating, comment)
    values
      ('33333333-3333-4333-8333-000000000001',
       '11111111-1111-4111-8111-000000000001', v_rider1, 5,
       'Vá lốp nhanh, giá hợp lý.'),
      ('33333333-3333-4333-8333-000000000002',
       '11111111-1111-4111-8111-000000000001', v_rider1, 4,
       'Thợ nhiệt tình, hơi đông khách.'),
      ('33333333-3333-4333-8333-000000000003',
       '11111111-1111-4111-8111-000000000002', v_rider1, 5,
       'Cây xăng sạch, nhân viên vui vẻ.')
    on conflict do nothing;
  else
    raise notice 'Bỏ qua reviews: chưa có tài khoản rider1@test.local';
  end if;

  raise notice 'Seed xong: 10 tiệm, 2 TNV (nếu có tài khoản), review mẫu (nếu có rider1).';
end $$;
