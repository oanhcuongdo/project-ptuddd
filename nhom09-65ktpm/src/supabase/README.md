# Hướng Dẫn Thiết Lập Cơ Sở Dữ Liệu Supabase (BuddyTalk — Nhóm 09)

Toàn bộ dữ liệu của BuddyTalk được lưu trữ **100% trực tuyến** trên **Supabase (PostgreSQL + Realtime WebSocket)** kết hợp với **Firebase Authentication** (xử lý đăng nhập Email & Google).

## Thứ tự chạy các file Migration trên Supabase Dashboard

Mở **Supabase Dashboard → SQL Editor → New query**, dán và bấm **Run** lần lượt theo đúng thứ tự đánh số:

1. `migrations/001_auth_and_users.sql` — Tạo `users`, `user_accounts` (1-N đa phương thức đăng nhập), `profiles` (1-1), `user_reports`.
2. `migrations/002_discipline.sql` — Tạo `daily_goals`, `user_quest_logs`.
3. `migrations/003_social_and_chat.sql` — Tạo `buddy_matches`, `conversations` (Chat 1-1 & Phòng học nhóm), `conversation_members`, `messages`.
4. `migrations/004_topics_sessions.sql` — Tạo `conversation_topics`, `user_topic_progress`, `practice_sessions`, `vocab_notebook`.
5. `migrations/005_indexes_triggers.sql` — Tạo Index tối ưu truy vấn & Trigger tự cập nhật `updated_at`, `last_message_text`.
6. `migrations/006_rls_and_realtime.sql` — Bật Row Level Security (RLS) & Supabase Realtime cho `messages`, `conversations`, `buddy_matches`.
7. `migrations/007_seed_data.sql` — *(Tùy chọn)* Nạp dữ liệu mẫu ban đầu.
8. `migrations/008_languages_and_onboarding.sql` — Tạo bảng `languages` (danh mục ngôn ngữ cấp phép) & cột `profiles.onboarding_completed`.
9. `migrations/009_conversations_flexible_rules.sql` — Cho phép phòng học chọn linh hoạt trình độ (`NULL` = không yêu cầu) & giới hạn thành viên (`NULL` = không giới hạn).
10. `migrations/010_room_join_approval.sql` — Thêm chế độ kiểm duyệt thành viên vào phòng (`conversations.require_approval`, `conversation_members.status` `'pending'/'approved'`).
11. `migrations/011_notifications_realtime.sql` — Tạo bảng `notifications` & bật Supabase Realtime cho `notifications`, `conversation_members`.
12. `migrations/012_room_streak.sql` — Thêm chuỗi lửa kỷ luật riêng từng thành viên theo từng phòng (`conversation_members.streak_count`, `best_streak`, `last_chat_date`).
13. `migrations/013_room_cover_and_focus.sql` — Thêm ảnh bìa phòng học (`cover_url`) & định hướng kỹ năng dài hạn (`room_focus`) cho bảng `conversations`.

## Lưu ý bảo mật
- Tạo file `.env` cục bộ từ `../.env.example` và chạy ứng dụng với `--dart-define-from-file=.env`.
- Tuyệt đối không commit file `.env` chứa khóa thật lên GitHub.
