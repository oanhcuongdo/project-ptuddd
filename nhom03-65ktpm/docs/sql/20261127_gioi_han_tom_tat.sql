begin;

create table if not exists public.summary_quota (
  user_id text primary key,
  window_start timestamptz not null,
  requests integer not null check (requests > 0)
);
alter table public.summary_quota enable row level security;
revoke all on public.summary_quota from public, anon, authenticated;

create or replace function public.consume_summary_quota(p_user_id text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  bucket timestamptz := date_trunc('hour', now(), 'UTC');
begin
  insert into public.summary_quota as quota (user_id, window_start, requests)
  values (p_user_id, bucket, 1)
  on conflict (user_id) do update
  set window_start = greatest(quota.window_start, excluded.window_start),
      requests = case when quota.window_start < excluded.window_start
                      then 1 else quota.requests + 1 end
  where quota.window_start < excluded.window_start or quota.requests < 10;

  return found;
end;
$$;

revoke all on function public.consume_summary_quota(text) from public, anon, authenticated;
grant execute on function public.consume_summary_quota(text) to service_role;

commit;
