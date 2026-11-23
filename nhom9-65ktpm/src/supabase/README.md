# Hướng Dẫn Thiết Lập Cơ Sở Dữ Liệu Supabase (BuddyTalk — Nhóm 09)

Toàn bộ dữ liệu của BuddyTalk được lưu trữ **100% trực tuyến** trên **Supabase (PostgreSQL + Realtime)** kết hợp với **Firebase Authentication** (xử lý đăng nhập Google / SĐT / Email).

## Thứ tự chạy các file Migration trên Supabase Dashboard

Mở **Supabase Dashboard $\rightarrow$ SQL Editor $\rightarrow$ New query**, dán và bấm **Run** lần lượt theo đúng thứ tự đánh số:

1. `migrations/001_auth_and_users.sql` — Tạo `users`, `user_accounts` (1-N đa phương thức đăng nhập), `profiles` (1-1), `user_reports`.
2. `migrations/002_discipline.sql` — Tạo `daily_goals`, `user_quest_logs` (Streak & Heatmap).
3. `migrations/003_social_and_chat.sql` — Tạo `buddy_matches`, `conversations` (Chat 1-1 & Chat Nhóm), `conversation_members`, `messages`.
4. `migrations/004_topics_sessions.sql` — Tạo `conversation_topics`, `user_topic_progress`, `practice_sessions`, `vocab_notebook`.
5. `migrations/005_indexes_triggers.sql` — Tạo Index tối ưu tìm kiếm & Trigger tự cập nhật `updated_at`, `last_message`.
6. `migrations/006_rls_and_realtime.sql` — Bật Row Level Security (RLS) & Realtime cho phòng Chat / Ghép cặp.
7. `migrations/007_seed_data.sql` — *(Tùy chọn)* Nạp dữ liệu mẫu ban đầu.

## Lưu ý bảo mật
- Tạo file `.env` cục bộ từ `../.env.example` và chạy ứng dụng với `--dart-define-from-file=.env`.
- Tuyệt đối không commit file `.env` chứa khóa thật lên GitHub.
