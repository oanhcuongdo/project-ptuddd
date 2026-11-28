-- 01_schema.sql
-- Chạy trong Supabase SQL Editor theo thứ tự 01 -> 05.
-- Nguồn: mục 5.3 báo cáo "Ứng dụng Kết nối & Tình nguyện xe máy".
-- Lưu ý: file này chỉ tạo cấu trúc, KHÔNG chứa dữ liệu mẫu (xem 05_seed.sql).

create extension if not exists postgis;

-- 1. users: hồ sơ 1-1 với auth.users, giữ vai trò và trạng thái tài khoản.
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name varchar(100) not null,
  email varchar(150) not null unique,
  phone varchar(20) not null default '',
  role varchar(20) not null default 'rider'
    check (role in ('rider', 'owner', 'volunteer', 'admin')),
  status varchar(20) not null default 'active'
    check (status in ('active', 'banned')),
  ban_reason text,
  fcm_token text,
  created_at timestamptz not null default now()
);

-- 2. shops: tiệm sửa xe / cây xăng, location sinh tự động từ lat/lng cho PostGIS.
create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  name varchar(150) not null,
  category varchar(30) not null
    check (category in ('repair_shop', 'gas_station')),
  phone varchar(20) not null,
  address text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  location geography(point, 4326) generated always as (
    st_setsrid(st_makepoint(longitude, latitude), 4326)::geography
  ) stored,
  open_time time not null,
  close_time time not null,
  is_open boolean not null default true,
  image_url text,
  rating numeric(2, 1) not null default 0.0 check (rating between 0 and 5),
  review_count integer not null default 0,
  status varchar(20) not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'banned')),
  rejection_reason text,
  created_at timestamptz not null default now()
);

-- 3. volunteer_profiles: hồ sơ tình nguyện viên, 1-1 với users.
create table if not exists public.volunteer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  phone varchar(20) not null,
  skills text[] not null default '{}',
  tools text,
  id_card_url text not null,
  service_radius_km smallint not null default 5
    check (service_radius_km between 1 and 20),
  location geography(point, 4326),
  is_available boolean not null default false,
  status varchar(20) not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'banned')),
  rejection_reason text,
  completed_count integer not null default 0,
  created_at timestamptz not null default now()
);

-- 4. sos_requests: ca cứu hộ. Chỉ được có tối đa 1 bên nhận ca.
create table if not exists public.sos_requests (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references public.users (id) on delete cascade,
  accepted_shop_id uuid references public.shops (id) on delete set null,
  accepted_volunteer_id uuid references public.volunteer_profiles (id) on delete set null,
  issue_type varchar(50) not null
    check (issue_type in ('Hết xăng', 'Thủng lốp', 'Hỏng động cơ', 'Khác')),
  note text,
  contact_phone varchar(20) not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  status varchar(20) not null default 'pending'
    check (status in ('pending', 'accepted', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint sos_one_acceptor check (
    num_nonnulls(accepted_shop_id, accepted_volunteer_id) <= 1
  )
);

-- 5. reviews: mỗi rider đánh giá 1 lần/tiệm, sửa lại thì cập nhật bản ghi cũ.
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  rider_id uuid not null references public.users (id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  constraint reviews_one_per_rider unique (shop_id, rider_id)
);

-- Bổ sung cột lý do từ chối / lý do khóa cho CSDL đã khởi tạo trước đó (UC-09 A2, UC-13 A2, UC-14 A1/A2).
alter table public.users add column if not exists ban_reason text;
alter table public.shops add column if not exists rejection_reason text;
alter table public.volunteer_profiles add column if not exists rejection_reason text;

-- Index phục vụ truy vấn bán kính (RPC) và lọc trạng thái.
create index if not exists shops_location_gix on public.shops using gist (location);
create index if not exists shops_status_idx on public.shops (status);
create index if not exists volunteer_location_gix on public.volunteer_profiles using gist (location);
create index if not exists volunteer_available_idx on public.volunteer_profiles (status, is_available);
create index if not exists sos_status_idx on public.sos_requests (status);
create index if not exists sos_rider_idx on public.sos_requests (rider_id);
