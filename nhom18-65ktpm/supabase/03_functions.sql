-- 03_functions.sql
-- Trigger + RPC dùng chung cho cả 4 phân hệ.
-- Chạy sau 02_rls.sql.

-- ============================================================
-- 1. Tự tạo hồ sơ public.users khi có tài khoản Supabase Auth mới
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'rider');
begin
  -- Không cho client tự đăng ký admin.
  if v_role not in ('rider', 'owner', 'volunteer') then
    v_role := 'rider';
  end if;

  insert into public.users (id, full_name, email, phone, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    coalesce(new.email, new.id::text || '@no-email.local'),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    v_role
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill cho tài khoản đã tạo trước khi chạy file này (tạo tay trên Dashboard).
insert into public.users (id, full_name, email, phone, role)
select
  au.id,
  coalesce(
    nullif(au.raw_user_meta_data ->> 'full_name', ''),
    split_part(coalesce(au.email, ''), '@', 1)
  ),
  coalesce(au.email, au.id::text || '@no-email.local'),
  coalesce(au.raw_user_meta_data ->> 'phone', ''),
  'rider'
from auth.users au
on conflict (id) do nothing;

-- ============================================================
-- 2. Trigger bảo vệ cột nhạy cảm
-- Client (role authenticated/anon) không được tự đổi role/status/rating...
-- SQL Editor và hàm security definer chạy với current_user = postgres nên được bỏ qua.
-- ============================================================
create or replace function public.protect_user_columns()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if current_user::text not in ('authenticated', 'anon') then
    return new;
  end if;
  if public.is_admin() then
    return new;
  end if;

  new.role := old.role;
  new.status := old.status;
  new.email := old.email;
  new.created_at := old.created_at;
  return new;
end;
$$;

drop trigger if exists trg_protect_user_columns on public.users;
create trigger trg_protect_user_columns
  before update on public.users
  for each row execute function public.protect_user_columns();

create or replace function public.protect_shop_columns()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if current_user::text not in ('authenticated', 'anon') then
    return new;
  end if;
  if public.is_admin() then
    return new;
  end if;

  new.owner_id := old.owner_id;
  new.status := old.status;
  new.rating := old.rating;
  new.review_count := old.review_count;
  new.created_at := old.created_at;
  return new;
end;
$$;

drop trigger if exists trg_protect_shop_columns on public.shops;
create trigger trg_protect_shop_columns
  before update on public.shops
  for each row execute function public.protect_shop_columns();

create or replace function public.protect_volunteer_columns()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if current_user::text not in ('authenticated', 'anon') then
    return new;
  end if;
  if public.is_admin() then
    return new;
  end if;

  new.user_id := old.user_id;
  new.status := old.status;
  new.completed_count := old.completed_count;
  new.created_at := old.created_at;
  return new;
end;
$$;

drop trigger if exists trg_protect_volunteer_columns on public.volunteer_profiles;
create trigger trg_protect_volunteer_columns
  before update on public.volunteer_profiles
  for each row execute function public.protect_volunteer_columns();

-- ============================================================
-- 3. Cập nhật rating/review_count của tiệm sau mỗi review
-- ============================================================
create or replace function public.refresh_shop_rating()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_shop uuid := coalesce(new.shop_id, old.shop_id);
begin
  update public.shops s
     set rating = coalesce(
           (select round(avg(r.rating)::numeric, 1)
              from public.reviews r
             where r.shop_id = v_shop),
           0
         ),
         review_count = (
           select count(*) from public.reviews r where r.shop_id = v_shop
         )
   where s.id = v_shop;

  return null;
end;
$$;

drop trigger if exists trg_refresh_shop_rating on public.reviews;
create trigger trg_refresh_shop_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_shop_rating();

-- ============================================================
-- 4. RPC tìm kiếm theo bán kính (PostGIS)
-- ============================================================
create or replace function public.get_nearby_shops(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer default 3000,
  p_category text default null,
  p_open_only boolean default false
)
returns table (
  id uuid,
  owner_id uuid,
  name varchar,
  category varchar,
  phone varchar,
  address text,
  latitude double precision,
  longitude double precision,
  open_time time,
  close_time time,
  is_open boolean,
  image_url text,
  rating numeric,
  review_count integer,
  distance_m double precision
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    s.id,
    s.owner_id,
    s.name,
    s.category,
    s.phone,
    s.address,
    s.latitude,
    s.longitude,
    s.open_time,
    s.close_time,
    s.is_open,
    s.image_url,
    s.rating,
    s.review_count,
    st_distance(
      s.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
    ) as distance_m
  from public.shops s
  where s.status = 'approved'
    and (p_category is null or s.category = p_category)
    and (coalesce(p_open_only, false) = false or s.is_open)
    and st_dwithin(
      s.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  order by distance_m;
$$;

create or replace function public.get_nearby_volunteers(
  p_lat double precision,
  p_lng double precision
)
returns table (
  id uuid,
  user_id uuid,
  full_name varchar,
  phone varchar,
  skills text[],
  completed_count integer,
  distance_m double precision
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select
    vp.id,
    vp.user_id,
    u.full_name,
    vp.phone,
    vp.skills,
    vp.completed_count,
    st_distance(
      vp.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
    ) as distance_m
  from public.volunteer_profiles vp
  join public.users u on u.id = vp.user_id
  where vp.status = 'approved'
    and vp.is_available
    and vp.location is not null
    -- Chỉ lấy TNV có bán kính hỗ trợ bao phủ vị trí sự cố.
    and st_dwithin(
      vp.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      vp.service_radius_km * 1000
    )
  order by distance_m;
$$;

-- ============================================================
-- 5. RPC nhận ca / hoàn thành ca (khóa ca, chống 2 người nhận trùng)
-- ============================================================
create or replace function public.accept_sos(
  p_sos_id uuid,
  p_shop_id uuid default null,
  p_volunteer_id uuid default null
)
returns public.sos_requests
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.sos_requests;
begin
  if (p_shop_id is null) = (p_volunteer_id is null) then
    raise exception 'Phải truyền đúng một trong p_shop_id hoặc p_volunteer_id';
  end if;

  if p_shop_id is not null and not exists (
    select 1 from public.shops
     where id = p_shop_id
       and owner_id = auth.uid()
       and status = 'approved'
  ) then
    raise exception 'Bạn không sở hữu tiệm này hoặc tiệm chưa được duyệt';
  end if;

  if p_volunteer_id is not null and not exists (
    select 1 from public.volunteer_profiles
     where id = p_volunteer_id
       and user_id = auth.uid()
       and status = 'approved'
       and is_available
  ) then
    raise exception 'Hồ sơ tình nguyện viên chưa được duyệt hoặc chưa sẵn sàng';
  end if;

  -- Câu lệnh có điều kiện status = 'pending': người thứ hai UPDATE sẽ không khớp dòng nào.
  update public.sos_requests
     set status = 'accepted',
         accepted_shop_id = p_shop_id,
         accepted_volunteer_id = p_volunteer_id
   where id = p_sos_id
     and status = 'pending'
  returning * into v_row;

  if v_row.id is null then
    raise exception 'Ca cứu hộ đã được người khác nhận hoặc không còn hiệu lực';
  end if;

  return v_row;
end;
$$;

create or replace function public.complete_sos(p_sos_id uuid)
returns public.sos_requests
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_row public.sos_requests;
begin
  update public.sos_requests
     set status = 'completed',
         completed_at = now()
   where id = p_sos_id
     and status = 'accepted'
     and (
       accepted_shop_id in (
         select id from public.shops where owner_id = auth.uid()
       )
       or accepted_volunteer_id in (
         select id from public.volunteer_profiles where user_id = auth.uid()
       )
     )
  returning * into v_row;

  if v_row.id is null then
    raise exception 'Không tìm thấy ca đang xử lý của bạn';
  end if;

  if v_row.accepted_volunteer_id is not null then
    update public.volunteer_profiles
       set completed_count = completed_count + 1
     where id = v_row.accepted_volunteer_id;
  end if;

  return v_row;
end;
$$;

-- Rider cần biết ai đã nhận ca (tên + SĐT) nhưng bảng users bị RLS chặn đọc người khác.
create or replace function public.get_sos_contact(p_sos_id uuid)
returns table (provider_name text, provider_phone text)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_sos public.sos_requests;
  v_name text;
  v_phone text;
begin
  select * into v_sos from public.sos_requests where id = p_sos_id;
  if not found then
    raise exception 'Không tìm thấy ca cứu hộ';
  end if;

  if not (
    v_sos.rider_id = auth.uid()
    or public.is_admin()
    or v_sos.accepted_shop_id in (
      select id from public.shops where owner_id = auth.uid()
    )
    or v_sos.accepted_volunteer_id in (
      select id from public.volunteer_profiles where user_id = auth.uid()
    )
  ) then
    raise exception 'Bạn không có quyền xem thông tin ca này';
  end if;

  if v_sos.accepted_shop_id is not null then
    select u.full_name, s.phone
      into v_name, v_phone
      from public.shops s
      join public.users u on u.id = s.owner_id
     where s.id = v_sos.accepted_shop_id;
  elsif v_sos.accepted_volunteer_id is not null then
    select u.full_name, vp.phone
      into v_name, v_phone
      from public.volunteer_profiles vp
      join public.users u on u.id = vp.user_id
     where vp.id = v_sos.accepted_volunteer_id;
  else
    return;
  end if;

  return query select v_name, v_phone;
end;
$$;

-- ============================================================
-- 6. Phân quyền gọi RPC
-- ============================================================
revoke all on function public.get_nearby_shops(double precision, double precision, integer, text, boolean) from public, anon;
grant execute on function public.get_nearby_shops(double precision, double precision, integer, text, boolean) to authenticated;

revoke all on function public.get_nearby_volunteers(double precision, double precision) from public, anon;
grant execute on function public.get_nearby_volunteers(double precision, double precision) to authenticated;

revoke all on function public.accept_sos(uuid, uuid, uuid) from public, anon;
grant execute on function public.accept_sos(uuid, uuid, uuid) to authenticated;

revoke all on function public.complete_sos(uuid) from public, anon;
grant execute on function public.complete_sos(uuid) to authenticated;

revoke all on function public.get_sos_contact(uuid) from public, anon;
grant execute on function public.get_sos_contact(uuid) to authenticated;
