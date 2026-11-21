-- 04_storage.sql
-- Bucket + policy cho ảnh mặt tiền tiệm, avatar và giấy tờ xác minh TNV.
-- Chạy sau 03_functions.sql.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('shop-images', 'shop-images', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 2097152,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('id-cards', 'id-cards', false, 5242880,
    array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Quy ước đường dẫn: <bucket>/<user_id>/<ten_file>. Mỗi người chỉ ghi vào thư mục của mình.

-- ===== shop-images: ai cũng xem, chủ tiệm ghi vào thư mục của mình =====
drop policy if exists shop_images_read on storage.objects;
create policy shop_images_read on storage.objects
  for select
  using (bucket_id = 'shop-images');

drop policy if exists shop_images_insert on storage.objects;
create policy shop_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'shop-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists shop_images_update on storage.objects;
create policy shop_images_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'shop-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists shop_images_delete on storage.objects;
create policy shop_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'shop-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===== avatars: ai cũng xem, mỗi người ghi thư mục của mình =====
drop policy if exists avatars_read on storage.objects;
create policy avatars_read on storage.objects
  for select
  using (bucket_id = 'avatars');

drop policy if exists avatars_insert on storage.objects;
create policy avatars_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_delete on storage.objects;
create policy avatars_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===== id-cards: riêng tư, chỉ chủ hồ sơ và admin đọc =====
drop policy if exists id_cards_read on storage.objects;
create policy id_cards_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'id-cards'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists id_cards_insert on storage.objects;
create policy id_cards_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'id-cards'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists id_cards_delete on storage.objects;
create policy id_cards_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'id-cards'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );
