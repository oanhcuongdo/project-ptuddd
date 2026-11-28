begin;

create table if not exists public.note_versions (
  note_id uuid not null references public.notes(id) on delete cascade,
  user_id text not null,
  updated_at timestamptz not null,
  fingerprint text not null,
  snapshot jsonb not null,
  primary key (note_id, updated_at, fingerprint)
);
alter table public.note_versions enable row level security;
revoke all on public.note_versions from public, anon, authenticated;
grant select on public.note_versions to authenticated;
drop policy if exists note_versions_owner on public.note_versions;
create policy note_versions_owner on public.note_versions for select
  to authenticated using (user_id = (select auth.jwt() ->> 'sub'));

create or replace function public.save_note_revision(p_note jsonb)
returns void
language plpgsql
security definer
set search_path = ''
set timezone = 'UTC'
as $$
declare
  uid text := auth.jwt() ->> 'sub';
  incoming public.notes;
  saved public.notes;
  archived public.notes;
  payload jsonb;
begin
  if uid is null or uid = '' or (auth.jwt() ->> 'role') is distinct from 'authenticated' then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  incoming := jsonb_populate_record(null::public.notes, p_note);
  if incoming.user_id is distinct from uid then
    raise exception 'Note owner does not match session' using errcode = '42501';
  end if;

  if incoming.subject_id is not null and not exists (
    select from public.subjects where id = incoming.subject_id and user_id = uid
  ) then
    raise exception 'Cannot use this subject' using errcode = '42501';
  end if;

  insert into public.notes
    (id, user_id, title, content, subject_id, tags, kind, created_at, updated_at, deleted_at)
  values
    (incoming.id, uid, incoming.title, incoming.content, incoming.subject_id,
     incoming.tags, incoming.kind, incoming.created_at, incoming.updated_at, incoming.deleted_at)
  on conflict (id) do nothing;
  if found then return; end if;

  select * into saved from public.notes
  where id = incoming.id and user_id = uid for update;
  if not found then
    raise exception 'Cannot write this note' using errcode = '42501';
  end if;

  if (incoming.title, incoming.content, incoming.subject_id, incoming.tags, incoming.kind, incoming.deleted_at)
     is distinct from
     (saved.title, saved.content, saved.subject_id, saved.tags, saved.kind, saved.deleted_at) then
    archived := case when incoming.updated_at > saved.updated_at then saved else incoming end;
    payload := to_jsonb(archived);
    insert into public.note_versions (note_id, user_id, updated_at, fingerprint, snapshot)
    values (archived.id, uid, archived.updated_at, md5(payload::text), payload)
    on conflict do nothing;
  end if;

  if incoming.updated_at > saved.updated_at then
    update public.notes
    set title = incoming.title, content = incoming.content, subject_id = incoming.subject_id,
        tags = incoming.tags, kind = incoming.kind, updated_at = incoming.updated_at,
        deleted_at = incoming.deleted_at
    where id = saved.id and user_id = uid;
  end if;
end;
$$;
revoke all on function public.save_note_revision(jsonb) from public, anon, authenticated;
grant execute on function public.save_note_revision(jsonb) to authenticated;

do $$
begin
  if exists (select from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notes'
     ) then
    alter publication supabase_realtime add table public.notes;
  end if;
end;
$$;

commit;
