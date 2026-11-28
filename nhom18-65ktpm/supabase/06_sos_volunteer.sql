-- 06_sos_volunteer.sql
-- Bổ sung cho SOS (UC-07, UC-12), tình nguyện viên (UC-11, UC-13) và thông báo FCM.
-- Chạy sau 05_seed.sql. Chạy lại nhiều lần không lỗi.

-- ============================================================
-- 1. Realtime cho sos_requests
-- Rider theo dõi ca của mình, người nhận theo dõi ca mới / ca đang xử lý.
-- ============================================================
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1
         from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'sos_requests'
     ) then
    alter publication supabase_realtime add table public.sos_requests;
  end if;
end $$;

-- ============================================================
-- 2. Sửa trigger bảo vệ cột trong 03_functions.sql
-- Hàm security definer luôn thấy current_user = postgres nên điều kiện
-- "current_user in (authenticated, anon)" không bao giờ đúng: client tự đổi
-- được role/status/rating. Chạy với quyền người gọi thì trigger mới có tác dụng.
-- ============================================================
alter function public.protect_user_columns() security invoker;
alter function public.protect_shop_columns() security invoker;

-- ============================================================
-- 3. Quy tắc hồ sơ tình nguyện viên (UC-11, UC-13)
-- Thay hàm cùng tên trong 03_functions.sql (trigger cũ tự dùng bản mới),
-- giữ các quy tắc rejection_reason / banned của 03, chạy với quyền người gọi giống mục 2.
-- - Hồ sơ bị khóa thì không được tự sửa.
-- - Đổi SĐT / giấy tờ khi đã duyệt -> chờ duyệt lại.
-- - Hồ sơ bị từ chối mà sửa nội dung -> gửi duyệt lại (chỉ cập nhật vị trí / công tắc thì không).
-- - Gửi duyệt lại thì xóa lý do từ chối cũ; Admin duyệt thì cũng xóa.
-- - Không tắt "sẵn sàng" khi đang có ca SOS chưa hoàn thành.
-- - Hồ sơ chưa duyệt / bị khóa thì không được ở trạng thái sẵn sàng.
-- ============================================================
create or replace function public.protect_volunteer_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_client boolean := current_user::text in ('authenticated', 'anon');
begin
  if v_client and public.is_admin() then
    if new.status = 'approved' then
      new.rejection_reason := null;
    end if;
  elsif v_client then
    if old.status = 'banned' then
      raise exception 'Hồ sơ tình nguyện viên đã bị khóa, không thể chỉnh sửa';
    end if;

    new.user_id := old.user_id;
    new.status := old.status;
    new.rejection_reason := old.rejection_reason;
    new.completed_count := old.completed_count;
    new.created_at := old.created_at;

    if old.status = 'rejected'
       and (new.phone, new.skills, new.tools, new.id_card_url, new.service_radius_km)
           is distinct from
           (old.phone, old.skills, old.tools, old.id_card_url, old.service_radius_km) then
      -- UC-13 A2: sửa hồ sơ bị từ chối thì gửi lại về chờ duyệt.
      new.status := 'pending';
      new.rejection_reason := null;
    elsif old.status = 'approved'
       and (new.phone is distinct from old.phone
            or new.id_card_url is distinct from old.id_card_url) then
      -- UC-13 A1: sửa SĐT hoặc giấy tờ của hồ sơ đã duyệt cần duyệt lại.
      new.status := 'pending';
    end if;
  end if;

  if new.status <> 'approved' then
    new.is_available := false;
  end if;

  if v_client and not public.is_admin()
     and old.is_available and not new.is_available and exists (
    select 1
      from public.sos_requests
     where accepted_volunteer_id = old.id
       and status = 'accepted'
  ) then
    raise exception 'Vui lòng hoàn thành ca cứu hộ đang xử lý trước khi tạm nghỉ';
  end if;

  return new;
end;
$$;

-- ============================================================
-- 4. Khóa ca: mỗi tiệm / TNV chỉ xử lý một ca tại một thời điểm (UC-12)
-- Thay accept_sos trong 03_functions.sql (giữ nguyên chữ ký hàm).
-- Ca chờ quá 5 phút coi như hết hạn (UC-07 E2): không nhận được nữa,
-- app rider tự chuyển ca sang cancelled.
-- ============================================================
create unique index if not exists sos_one_active_shop
  on public.sos_requests (accepted_shop_id)
  where status = 'accepted';

create unique index if not exists sos_one_active_volunteer
  on public.sos_requests (accepted_volunteer_id)
  where status = 'accepted';

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

  if exists (
    select 1 from public.users where id = auth.uid() and status = 'banned'
  ) then
    raise exception 'Tài khoản của bạn đã bị khóa';
  end if;

  if p_shop_id is not null and not exists (
    select 1 from public.shops
     where id = p_shop_id
       and owner_id = auth.uid()
       and status = 'approved'
       and is_open
  ) then
    raise exception 'Bạn không sở hữu tiệm này, tiệm chưa được duyệt hoặc đang đóng cửa';
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

  if exists (
    select 1 from public.sos_requests
     where status = 'accepted'
       and (accepted_shop_id = p_shop_id or accepted_volunteer_id = p_volunteer_id)
  ) then
    raise exception 'Bạn đang xử lý một ca cứu hộ khác, hãy hoàn thành ca đó trước';
  end if;

  begin
    -- Câu lệnh có điều kiện status = 'pending': người thứ hai UPDATE sẽ không khớp dòng nào.
    update public.sos_requests
       set status = 'accepted',
           accepted_shop_id = p_shop_id,
           accepted_volunteer_id = p_volunteer_id
     where id = p_sos_id
       and status = 'pending'
       and created_at > now() - interval '5 minutes'
       and rider_id <> auth.uid()
    returning * into v_row;
  exception
    -- Hai lần nhận gần như đồng thời của cùng một người: index unique chặn lại.
    when unique_violation then
      raise exception 'Bạn đang xử lý một ca cứu hộ khác, hãy hoàn thành ca đó trước';
  end;

  if v_row.id is null then
    raise exception 'Ca cứu hộ này đã được người khác tiếp nhận hoặc không còn hiệu lực';
  end if;

  return v_row;
end;
$$;

-- ============================================================
-- 5. Hộp thư SOS của người nhận (UC-12)
-- Trả các ca đang chờ mà người gọi được phép nhận, kèm khoảng cách và
-- id tiệm / hồ sơ TNV để truyền thẳng vào accept_sos.
-- Quy tắc trùng với get_sos_recipients (người nhận FCM, mục 6):
-- - TNV: đã duyệt, đang sẵn sàng, ca nằm trong service_radius_km.
-- - Tiệm: đã duyệt, đang mở cửa, trong 5 km; cây xăng chỉ nhận ca "Hết xăng".
-- ============================================================
create or replace function public.get_my_pending_sos()
returns table (
  id uuid,
  rider_id uuid,
  issue_type varchar,
  note text,
  contact_phone varchar,
  latitude double precision,
  longitude double precision,
  status varchar,
  created_at timestamptz,
  distance_m double precision,
  shop_id uuid,
  volunteer_id uuid
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with me as (
    select u.id from public.users u where u.id = auth.uid() and u.status = 'active'
  ),
  pending as (
    select r.*,
           st_setsrid(st_makepoint(r.longitude, r.latitude), 4326)::geography as point
      from public.sos_requests r
     where r.status = 'pending'
       and r.created_at > now() - interval '5 minutes'
       and r.rider_id <> auth.uid()
  ),
  candidates as (
    select p.id, st_distance(vp.location, p.point) as distance_m,
           null::uuid as shop_id, vp.id as volunteer_id
      from pending p
      join public.volunteer_profiles vp on vp.user_id = (select id from me)
     where vp.status = 'approved'
       and vp.is_available
       and vp.location is not null
       and st_dwithin(vp.location, p.point, vp.service_radius_km * 1000)
    union all
    select p.id, st_distance(s.location, p.point),
           s.id, null::uuid
      from pending p
      join public.shops s on s.owner_id = (select id from me)
     where s.status = 'approved'
       and s.is_open
       and (s.category = 'repair_shop' or p.issue_type = 'Hết xăng')
       and st_dwithin(s.location, p.point, 5000)
  ),
  nearest as (
    -- Chủ có nhiều tiệm: lấy tiệm gần ca nhất.
    select distinct on (c.id) c.*
      from candidates c
     order by c.id, c.distance_m
  )
  select p.id, p.rider_id, p.issue_type, p.note, p.contact_phone,
         p.latitude, p.longitude, p.status, p.created_at,
         n.distance_m, n.shop_id, n.volunteer_id
    from nearest n
    join pending p on p.id = n.id
   order by p.created_at desc;
$$;

revoke all on function public.get_my_pending_sos() from public, anon;
grant execute on function public.get_my_pending_sos() to authenticated;

-- ============================================================
-- 6. FCM: lưu token thiết bị và lấy danh sách người cần báo
-- ============================================================
-- Một thiết bị chỉ thuộc một tài khoản: gỡ token khỏi tài khoản cũ trên cùng máy.
-- Truyền null khi đăng xuất để thiết bị ngừng nhận SOS.
create or replace function public.set_fcm_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if auth.uid() is null then
    raise exception 'Chưa đăng nhập';
  end if;

  if nullif(p_token, '') is not null then
    update public.users
       set fcm_token = null
     where fcm_token = p_token
       and id <> auth.uid();
  end if;

  update public.users
     set fcm_token = nullif(p_token, '')
   where id = auth.uid();
end;
$$;

revoke all on function public.set_fcm_token(text) from public, anon;
grant execute on function public.set_fcm_token(text) to authenticated;

-- Người được báo cho một ca SOS (dùng chung cho FCM và UC-07 E1).
create or replace function public.sos_helpers(p_sos_id uuid)
returns table (user_id uuid)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with sos as (
    select r.*,
           st_setsrid(st_makepoint(r.longitude, r.latitude), 4326)::geography as point
      from public.sos_requests r
     where r.id = p_sos_id
       and r.status = 'pending'
  )
  select u.id
    from sos
    join public.volunteer_profiles vp
      on vp.status = 'approved'
     and vp.is_available
     and vp.location is not null
     and st_dwithin(vp.location, sos.point, vp.service_radius_km * 1000)
    join public.users u on u.id = vp.user_id
   where u.id <> sos.rider_id
     and u.status = 'active'
  union
  select u.id
    from sos
    join public.shops s
      on s.status = 'approved'
     and s.is_open
     and (s.category = 'repair_shop' or sos.issue_type = 'Hết xăng')
     and st_dwithin(s.location, sos.point, 5000)
    join public.users u on u.id = s.owner_id
   where u.id <> sos.rider_id
     and u.status = 'active';
$$;

revoke all on function public.sos_helpers(uuid) from public, anon, authenticated;

-- Edge Function notify-sos gọi bằng service_role khi có ca mới.
create or replace function public.get_sos_recipients(p_sos_id uuid)
returns table (user_id uuid, fcm_token text)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select distinct on (u.fcm_token) u.id, u.fcm_token
    from public.sos_helpers(p_sos_id) h
    join public.users u on u.id = h.user_id
   where coalesce(u.fcm_token, '') <> ''
   order by u.fcm_token;
$$;

revoke all on function public.get_sos_recipients(uuid) from public, anon, authenticated;
grant execute on function public.get_sos_recipients(uuid) to service_role;

-- ============================================================
-- 7. UC-07 E1: rider biết quanh mình có ai nhận được ca không
-- Chỉ chủ ca gọi được; ca của người khác trả 0.
-- ============================================================
create or replace function public.count_sos_helpers(p_sos_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, extensions
as $$
  select count(*)::integer
    from public.sos_helpers(p_sos_id)
   where exists (
     select 1 from public.sos_requests
      where id = p_sos_id and rider_id = auth.uid()
   );
$$;

revoke all on function public.count_sos_helpers(uuid) from public, anon;
grant execute on function public.count_sos_helpers(uuid) to authenticated;
