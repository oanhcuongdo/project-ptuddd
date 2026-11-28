# Cơ Sở Dữ Liệu – Nhóm 03 (SmartNote)

> **Đọc file này trước khi thêm/sửa bảng, cột hay policy.** Áp dụng cho mọi thành viên và mọi agent AI (xem [rules/AGENTS.md](../rules/AGENTS.md)).
> Cập nhật: **21/11/2026**.

## 1. Hạ tầng dữ liệu

| Thành phần | Vai trò | Ghi chú |
|---|---|---|
| **Firebase Authentication** | Xác thực (đăng ký / đăng nhập / đăng xuất) | Chỉ dùng Auth, **không** dùng Firestore |
| **Supabase (PostgreSQL)** | **Nguồn dữ liệu chính** dùng chung cả nhóm | Bật RLS cho **mọi** bảng |
| **Supabase Storage** | Ảnh quét vở, tệp đính kèm | Bucket riêng, phân quyền theo `user_id` |
| **Drift (SQLite)** | Cache offline trên máy | Chỉ là bản sao, không phải nơi lưu chính |

**Project Supabase của nhóm:** `NoteSmart` — ref `hxzimpvamyzyqdhkxexl`, vùng `ap-northeast-1`, Postgres 17. Đã tạo đủ 11 bảng ở mục 4 bằng [sql/20261121_tao_bang_co_ban.sql](sql/20261121_tao_bang_co_ban.sql).

**Xác thực với Supabase:** bật *Authentication → Third-party auth → Firebase* (nhập Firebase Project ID). Firebase UID **không phải UUID**, nên:

- `user_id` kiểu **`text`** (chứa Firebase UID), không dùng `uuid`.
- Policy dùng `(select auth.jwt() ->> 'sub')`, **không** dùng `auth.uid()`.
- User Firebase phải có custom claim `role = "authenticated"`, nếu không request chạy như `anon` và RLS từ chối toàn bộ.
- App chỉ dùng **publishable/anon key**; **không** nhúng `service_role`.

## 2. Quy ước chung (bắt buộc)

| Quy ước | Giá trị |
|---|---|
| Tên bảng / cột | `snake_case`, số nhiều cho bảng (`notes`, `quiz_attempts`) |
| Khoá chính | `id uuid primary key default gen_random_uuid()` |
| Chủ sở hữu dữ liệu | `user_id text not null` = Firebase UID |
| Thời gian | `created_at`, `updated_at timestamptz not null default now()` |
| Xoá | **Xoá mềm**: `deleted_at timestamptz` (null = còn hiệu lực) |
| Bảo mật | Mọi bảng bật `row level security` + policy theo `user_id` |
| Quyền | `grant ... to authenticated` (không cấp cho `anon`) |
| Đặt tên ràng buộc | `<bảng>_<cột>_<loại>` khi cần unique/foreign key |
| Thay đổi schema | Có file SQL trong `docs/sql/` + cập nhật file này + báo nhóm |

## 3. Danh sách bảng

| Bảng | Mô tả | Issue |
|---|---|---|
| `profiles` | Hồ sơ người dùng | #2 |
| `subjects` | Môn học / chủ đề phân loại ghi chú | #6 |
| `notes` | Ghi chú thường và nhật ký | #3 |
| `note_attachments` | Ảnh quét vở, tệp đính kèm | #8, #9 |
| `reminders` | Nhắc hẹn theo ghi chú | #10 |
| `summaries` | Kết quả tóm tắt AI | #12 |
| `quizzes` / `quiz_questions` / `quiz_attempts` | Bài kiểm tra trắc nghiệm và điểm | #13 |
| `note_shares` | Chia sẻ ghi chú chỉ xem | #14 |
| `study_stats` | Thống kê học tập / streak | #17 |

Dưới đây là **cấu trúc cơ bản** để cả nhóm code khớp nhau. Trong quá trình làm, người làm issue được **tự bổ sung cột** (ví dụ `updated_at`, `deleted_at`, cờ trạng thái, metadata) miễn giữ đúng quy ước ở mục 2 và cập nhật lại file này.

## 4. Cấu trúc cơ bản các bảng

```sql
-- =========================================================
-- profiles: hồ sơ người dùng (1 dòng / tài khoản Firebase)
-- =========================================================
create table if not exists profiles (
  user_id      text primary key,               -- Firebase UID
  display_name text,
  email        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- =========================================================
-- subjects: môn học / chủ đề để phân loại ghi chú
-- =========================================================
create table if not exists subjects (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  name       text not null,
  color      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- =========================================================
-- notes: ghi chú thường (kind = 'note') và nhật ký (kind = 'diary')
-- =========================================================
create table if not exists notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,                    -- Firebase UID
  title      text not null default '',
  content    text not null default '',
  subject_id uuid references subjects(id) on delete set null,
  tags       text[] not null default '{}',
  kind       text not null default 'note' check (kind in ('note', 'diary')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists notes_user_updated_idx
  on notes (user_id, updated_at desc);

-- Mỗi người chỉ có một nhật ký mỗi ngày (theo giờ Việt Nam)
create unique index if not exists notes_one_diary_per_day
  on notes (user_id, ((created_at at time zone 'Asia/Ho_Chi_Minh')::date))
  where kind = 'diary' and deleted_at is null;

-- =========================================================
-- note_attachments: ảnh quét vở / tệp đính kèm của ghi chú
-- =========================================================
create table if not exists note_attachments (
  id           uuid primary key default gen_random_uuid(),
  note_id      uuid not null references notes(id) on delete cascade,
  user_id      text not null,
  storage_path text not null,                  -- đường dẫn trong bucket
  page_order   int not null default 0,
  ocr_text     text,
  created_at   timestamptz not null default now()
);

-- =========================================================
-- reminders: nhắc hẹn theo ghi chú
-- =========================================================
create table if not exists reminders (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  note_id    uuid references notes(id) on delete cascade,
  remind_at  timestamptz not null,
  is_done    boolean not null default false,
  created_at timestamptz not null default now()
);

-- =========================================================
-- summaries: kết quả tóm tắt AI (không ghi đè notes.content)
-- =========================================================
create table if not exists summaries (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid not null references notes(id) on delete cascade,
  user_id    text not null,
  mode       text not null check (mode in ('short', 'long', 'bullets')),
  content    text not null,
  model      text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- quizzes / quiz_questions / quiz_attempts: bài kiểm tra trắc nghiệm
-- =========================================================
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
  options    jsonb not null,                   -- ["A", "B", ...]
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

-- =========================================================
-- note_shares: chia sẻ ghi chú chỉ xem
-- =========================================================
create table if not exists note_shares (
  id          uuid primary key default gen_random_uuid(),
  note_id     uuid not null references notes(id) on delete cascade,
  owner_id    text not null,
  shared_with text not null,                   -- Firebase UID người được xem
  permission  text not null default 'view' check (permission in ('view')),
  created_at  timestamptz not null default now(),
  unique (note_id, shared_with)
);

-- =========================================================
-- study_stats: thống kê học tập / streak theo ngày
-- =========================================================
create table if not exists study_stats (
  user_id    text not null,
  day        date not null,
  note_count int not null default 0,
  diary_done boolean not null default false,
  primary key (user_id, day)
);
```

Ghi chú:
- `study_stats` có thể tính trực tiếp từ `notes` thay vì lưu bảng riêng — chốt lại khi làm #17.
- `note_shares` cần thêm nhánh policy: người được chia sẻ `select` được `notes` khi có dòng trong `note_shares`.

## 5. RLS cho toàn bộ bảng

```sql
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

create policy "notes_owner" on notes
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "subjects_owner" on subjects
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));
```

Các bảng còn lại viết policy theo cùng mẫu khi làm issue tương ứng. Bảng có cha (`note_attachments`, `reminders`, `summaries`, `quiz_questions`, `quiz_attempts`, `note_shares`) phải kiểm tra quyền qua bảng cha nếu không có cột `user_id` trực tiếp.

## 6. Storage

| Bucket | Dùng cho | Quy ước đường dẫn | Issue |
|---|---|---|---|
| `note-images` | Ảnh chụp vở đã cắt | `{user_id}/{note_id}/{page}.jpg` | #8, #9 |

- Bucket **private**; truy cập bằng signed URL.
- Policy Storage cũng so sánh `auth.jwt() ->> 'sub'` với thư mục đầu tiên của đường dẫn.

## 7. Ánh xạ xuống Drift (cache offline)

| Supabase | Drift | Ghi chú |
|---|---|---|
| `notes` | `Notes` (`lib/core/database/tables.dart`) | Thiếu `user_id`, `tags` lưu dạng text phân tách bằng dấu phẩy |
| `subjects` | `Subjects` (`lib/core/database/tables.dart`) | Thiếu `user_id`; id là UUID; xoá mềm bằng `deletedAt`; mỗi lần thêm/sửa/xoá đẩy lên Supabase, mở màn phân loại thì đối chiếu (bản `updated_at` mới hơn thắng); xoá môn thì gỡ `subjectId` khỏi ghi chú qua `NoteRepository` để ghi chú cũng được đồng bộ |
| — | `synced_at` (dự kiến) | Thời điểm đồng bộ gần nhất để biết bản nào mới |

Quy tắc đồng bộ: ghi Supabase trước → cập nhật Drift; khi mất mạng thì ghi Drift và đánh dấu chờ đồng bộ.

## 8. Cách thêm/sửa schema (checklist)

1. Đọc file này và [rules/AGENTS.md](../rules/AGENTS.md).
2. Tạo file SQL trong `docs/sql/<YYYYMMDD>_<mô-tả>.sql` (không sửa file SQL cũ).
3. Thêm bảng vào mục **3. Danh sách bảng** và SQL vào mục **4**.
4. Luôn: `user_id`, `created_at`, `updated_at`, `deleted_at`, `enable row level security`, `grant ... to authenticated`, policy.
5. Cập nhật tầng Drift + `data/datasources/remote` tương ứng.
6. Ghi vào **mục 9. Lịch sử thay đổi**.
7. Báo nhóm trước khi merge; agent **không** tự tạo bảng ngoài file này.

## 9. Bổ sung cho #12 và #21

- [SQL quota tóm tắt](sql/20261127_gioi_han_tom_tat.sql) tạo `summary_quota` và
  RPC `consume_summary_quota`. Chỉ runtime máy chủ được gọi RPC.
- [SQL đồng bộ phiên bản](sql/20261127_dong_bo_phien_ban_ghi_chu.sql) tạo
  `note_versions`, RPC `save_note_revision` và đưa `notes` vào publication
  Realtime. Quyền đọc lịch sử giới hạn theo Firebase UID.

## 10. Lịch sử thay đổi

| Ngày | Nội dung |
|---|---|
| 21/11/2026 | Tạo file; chốt `notes`, `subjects`, RLS theo Firebase UID; đề xuất các bảng còn lại |
| 21/11/2026 | Bỏ cột trạng thái và phân công; viết cấu trúc field cơ bản cho toàn bộ bảng, thành viên tự bổ sung khi làm |
| 21/11/2026 | Tạo project Supabase `NoteSmart` (`hxzimpvamyzyqdhkxexl`); chạy `docs/sql/20261121_tao_bang_co_ban.sql` — 11 bảng, 12 index, RLS + policy cho tất cả bảng |
| 28/11/2026 | #6: thêm bảng Drift `Subjects` (schema version 3, migration tạo bảng khi nâng cấp), đồng bộ với bảng `subjects` có sẵn trên Supabase; tag vẫn lưu trong `notes.tags`, không thêm bảng mới |
