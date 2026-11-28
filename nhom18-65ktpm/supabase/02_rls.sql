-- 02_rls.sql
-- Row Level Security: mọi bảng đều bật RLS, client chỉ thấy dữ liệu được phép.
-- Chạy sau 01_schema.sql.

-- Hàm phụ: tránh đệ quy RLS khi policy của users cần biết "tôi có phải admin?".
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
      and role = 'admin'
      and status = 'active'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- Cấp quyền mức bảng cho role authenticated (Postgres kiểm tra GRANT trước khi kiểm tra RLS).
grant usage on schema public to authenticated;
grant select, update, delete on public.users to authenticated;
grant select, insert, update, delete on public.shops to authenticated;
grant select, insert, update, delete on public.volunteer_profiles to authenticated;
grant select, insert, update on public.sos_requests to authenticated;
grant select, insert, update, delete on public.reviews to authenticated;

alter table public.users enable row level security;
alter table public.shops enable row level security;
alter table public.volunteer_profiles enable row level security;
alter table public.sos_requests enable row level security;
alter table public.reviews enable row level security;

-- ===== users =====
drop policy if exists users_select on public.users;
create policy users_select on public.users
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists users_update on public.users;
create policy users_update on public.users
  for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

drop policy if exists users_delete on public.users;
create policy users_delete on public.users
  for delete to authenticated
  using (public.is_admin());

-- ===== shops =====
drop policy if exists shops_select on public.shops;
create policy shops_select on public.shops
  for select to authenticated
  using (status = 'approved' or owner_id = auth.uid() or public.is_admin());

drop policy if exists shops_insert on public.shops;
create policy shops_insert on public.shops
  for insert to authenticated
  with check (owner_id = auth.uid() and status = 'pending');

drop policy if exists shops_update on public.shops;
create policy shops_update on public.shops
  for update to authenticated
  using (owner_id = auth.uid() or public.is_admin())
  with check (owner_id = auth.uid() or public.is_admin());

drop policy if exists shops_delete on public.shops;
create policy shops_delete on public.shops
  for delete to authenticated
  using (public.is_admin());

-- ===== volunteer_profiles =====
-- Chỉ chủ hồ sơ và admin đọc được (id_card_url là giấy tờ riêng tư).
drop policy if exists volunteer_select on public.volunteer_profiles;
create policy volunteer_select on public.volunteer_profiles
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists volunteer_insert on public.volunteer_profiles;
create policy volunteer_insert on public.volunteer_profiles
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and is_available = false
    and completed_count = 0
  );

drop policy if exists volunteer_update on public.volunteer_profiles;
create policy volunteer_update on public.volunteer_profiles
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists volunteer_delete on public.volunteer_profiles;
create policy volunteer_delete on public.volunteer_profiles
  for delete to authenticated
  using (public.is_admin());

-- ===== sos_requests =====
-- Rider tạo ca của mình; ca pending hiển thị cho mọi người để nhận (giống phát sóng).
drop policy if exists sos_insert on public.sos_requests;
create policy sos_insert on public.sos_requests
  for insert to authenticated
  with check (
    rider_id = auth.uid()
    and status = 'pending'
    and accepted_shop_id is null
    and accepted_volunteer_id is null
  );

drop policy if exists sos_select on public.sos_requests;
create policy sos_select on public.sos_requests
  for select to authenticated
  using (
    rider_id = auth.uid()
    or status = 'pending'
    or public.is_admin()
    or accepted_shop_id in (select id from public.shops where owner_id = auth.uid())
    or accepted_volunteer_id in (
      select id from public.volunteer_profiles where user_id = auth.uid()
    )
  );

-- Rider chỉ được hủy ca đang chờ; nhận/hoàn thành ca phải đi qua RPC (03_functions.sql).
drop policy if exists sos_cancel on public.sos_requests;
create policy sos_cancel on public.sos_requests
  for update to authenticated
  using (rider_id = auth.uid() and status = 'pending')
  with check (rider_id = auth.uid() and status = 'cancelled');

-- ===== reviews =====
drop policy if exists reviews_select on public.reviews;
create policy reviews_select on public.reviews
  for select to authenticated
  using (true);

drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews
  for insert to authenticated
  with check (rider_id = auth.uid());

drop policy if exists reviews_update on public.reviews;
create policy reviews_update on public.reviews
  for update to authenticated
  using (rider_id = auth.uid())
  with check (rider_id = auth.uid());

drop policy if exists reviews_delete on public.reviews;
create policy reviews_delete on public.reviews
  for delete to authenticated
  using (rider_id = auth.uid());
