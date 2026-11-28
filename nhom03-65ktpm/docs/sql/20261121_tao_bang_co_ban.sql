-- =============================================================
-- SmartNote – Nhóm 03 (65KTPM)
-- Tạo 11 bảng cơ bản + index + RLS cho Supabase
-- Ngày: 2026-11-21
-- Chạy trong: Supabase Dashboard → SQL Editor (một lần cho project mới)
-- Xem tài liệu: ../co_so_du_lieu.md
-- =============================================================

-- ---------- BẢNG ----------

create table if not exists profiles (
  user_id      text primary key,               -- Firebase UID
  display_name text,
  email        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists subjects (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  name       text not null,
  color      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  title      text not null default '',
  content    text not null default '',
  subject_id uuid references subjects(id) on delete set null,
  tags       text[] not null default '{}',
  kind       text not null default 'note' check (kind in ('note', 'diary')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists note_attachments (
  id           uuid primary key default gen_random_uuid(),
  note_id      uuid not null references notes(id) on delete cascade,
  user_id      text not null,
  storage_path text not null,
  page_order   int not null default 0,
  ocr_text     text,
  created_at   timestamptz not null default now()
);

create table if not exists reminders (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  note_id    uuid references notes(id) on delete cascade,
  remind_at  timestamptz not null,
  is_done    boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists summaries (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid not null references notes(id) on delete cascade,
  user_id    text not null,
  mode       text not null check (mode in ('short', 'long', 'bullets')),
  content    text not null,
  model      text,
  created_at timestamptz not null default now()
);

create table if not exists quizzes (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid references notes(id) on delete set null,
  user_id    text not null,
  title      text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists quiz_questions (
  id         uuid primary key default gen_random_uuid(),
  quiz_id    uuid not null references quizzes(id) on delete cascade,
  question   text not null,
  options    jsonb not null,
  answer_idx int not null,
  order_idx  int not null default 0
);

create table if not exists quiz_attempts (
  id         uuid primary key default gen_random_uuid(),
  quiz_id    uuid not null references quizzes(id) on delete cascade,
  user_id    text not null,
  score      int not null,
  total      int not null,
  answers    jsonb,
  created_at timestamptz not null default now()
);

create table if not exists note_shares (
  id          uuid primary key default gen_random_uuid(),
  note_id     uuid not null references notes(id) on delete cascade,
  owner_id    text not null,
  shared_with text not null,
  permission  text not null default 'view' check (permission in ('view')),
  created_at  timestamptz not null default now(),
  unique (note_id, shared_with)
);

create table if not exists study_stats (
  user_id    text not null,
  day        date not null,
  note_count int not null default 0,
  diary_done boolean not null default false,
  primary key (user_id, day)
);

-- ---------- INDEX ----------

create index if not exists notes_user_updated_idx
  on notes (user_id, updated_at desc);

create unique index if not exists notes_one_diary_per_day
  on notes (user_id, ((created_at at time zone 'Asia/Ho_Chi_Minh')::date))
  where kind = 'diary' and deleted_at is null;

create index if not exists subjects_user_idx       on subjects (user_id);
create index if not exists attachments_note_idx    on note_attachments (note_id);
create index if not exists attachments_user_idx    on note_attachments (user_id);
create index if not exists reminders_user_time_idx on reminders (user_id, remind_at);
create index if not exists summaries_note_idx      on summaries (note_id);
create index if not exists quizzes_user_idx        on quizzes (user_id);
create index if not exists questions_quiz_idx      on quiz_questions (quiz_id, order_idx);
create index if not exists attempts_quiz_idx       on quiz_attempts (quiz_id);
create index if not exists attempts_user_idx       on quiz_attempts (user_id);
create index if not exists shares_shared_with_idx  on note_shares (shared_with);

-- ---------- RLS ----------

alter table profiles         enable row level security;
alter table subjects         enable row level security;
alter table notes            enable row level security;
alter table note_attachments enable row level security;
alter table reminders        enable row level security;
alter table summaries        enable row level security;
alter table quizzes          enable row level security;
alter table quiz_questions   enable row level security;
alter table quiz_attempts    enable row level security;
alter table note_shares      enable row level security;
alter table study_stats      enable row level security;

grant select, insert, update, delete on
  profiles, subjects, notes, note_attachments, reminders, summaries,
  quizzes, quiz_questions, quiz_attempts, note_shares, study_stats
  to authenticated;

-- Bảng có cột user_id: chủ sở hữu toàn quyền
create policy "profiles_owner" on profiles
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "subjects_owner" on subjects
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "notes_owner" on notes
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "attachments_owner" on note_attachments
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "reminders_owner" on reminders
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "summaries_owner" on summaries
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "quizzes_owner" on quizzes
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "attempts_owner" on quiz_attempts
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "stats_owner" on study_stats
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

-- quiz_questions không có user_id: kiểm quyền qua quizzes
create policy "questions_owner" on quiz_questions
  for all to authenticated
  using (exists (
    select 1 from quizzes q
    where q.id = quiz_id and q.user_id = (select auth.jwt() ->> 'sub')
  ))
  with check (exists (
    select 1 from quizzes q
    where q.id = quiz_id and q.user_id = (select auth.jwt() ->> 'sub')
  ));

-- note_shares: chủ ghi chú quản lý, người được chia sẻ chỉ đọc
create policy "shares_owner_manage" on note_shares
  for all to authenticated
  using (owner_id = (select auth.jwt() ->> 'sub'))
  with check (owner_id = (select auth.jwt() ->> 'sub'));

create policy "shares_shared_read" on note_shares
  for select to authenticated
  using (shared_with = (select auth.jwt() ->> 'sub'));

-- người được chia sẻ đọc được ghi chú tương ứng
create policy "notes_shared_read" on notes
  for select to authenticated
  using (exists (
    select 1 from note_shares s
    where s.note_id = notes.id
      and s.shared_with = (select auth.jwt() ->> 'sub')
  ));
