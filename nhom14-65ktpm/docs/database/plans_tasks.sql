-- Schema proposal for the planning module.
-- Review with TV1 before applying to the shared Supabase project.
-- Assumes public.personal_topics.id is a UUID.

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  personal_topic_id uuid not null
    references public.personal_topics (id) on delete cascade,
  user_id uuid not null
    references auth.users (id) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null
    references public.plans (id) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  phase text not null check (length(btrim(phase)) > 0),
  description text,
  due_date date,
  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),
  created_at timestamptz not null default now()
);

create index if not exists plans_personal_topic_id_idx
  on public.plans (personal_topic_id);
create index if not exists plans_user_id_idx
  on public.plans (user_id);
create index if not exists tasks_plan_id_idx
  on public.tasks (plan_id);

alter table public.plans enable row level security;
alter table public.tasks enable row level security;

grant select, insert, update, delete on public.plans to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;

drop policy if exists plans_select_own on public.plans;
create policy plans_select_own
  on public.plans for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists plans_insert_own on public.plans;
create policy plans_insert_own
  on public.plans for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists plans_update_own on public.plans;
create policy plans_update_own
  on public.plans for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists plans_delete_own on public.plans;
create policy plans_delete_own
  on public.plans for delete to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists tasks_select_own_plan on public.tasks;
create policy tasks_select_own_plan
  on public.tasks for select to authenticated
  using (
    exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_insert_own_plan on public.tasks;
create policy tasks_insert_own_plan
  on public.tasks for insert to authenticated
  with check (
    exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_update_own_plan on public.tasks;
create policy tasks_update_own_plan
  on public.tasks for update to authenticated
  using (
    exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_delete_own_plan on public.tasks;
create policy tasks_delete_own_plan
  on public.tasks for delete to authenticated
  using (
    exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );
