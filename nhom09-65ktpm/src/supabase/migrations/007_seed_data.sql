-- ============================================================================
-- MIGRATION 007: DỮ LIỆU MẪU (SEED DATA) ĐỂ CẢ 5 THÀNH VIÊN TEST NGAY
-- An toàn khi chạy lại nhiều lần (ON CONFLICT DO NOTHING)
-- ============================================================================

-- 1. Tạo 2 người dùng mẫu (Hưng học Tiếng Anh & Alex học Tiếng Việt)
INSERT INTO public.users (id, status, role) VALUES
  ('11111111-1111-1111-1111-111111111111', 'active', 'admin'),
  ('22222222-2222-2222-2222-222222222222', 'active', 'user')
ON CONFLICT (id) DO NOTHING;

-- Minh họa 1 user có nhiều tài khoản đăng nhập (Google + SĐT)
INSERT INTO public.user_accounts (user_id, provider, provider_account_id, firebase_uid, email, phone_number, is_verified) VALUES
  ('11111111-1111-1111-1111-111111111111', 'google', 'demo_firebase_uid_hung', 'demo_firebase_uid_hung', 'phamvanhung21122004@gmail.com', NULL, TRUE),
  ('11111111-1111-1111-1111-111111111111', 'phone', '+84900000001', 'demo_firebase_uid_hung', NULL, '+84900000001', TRUE),
  ('22222222-2222-2222-2222-222222222222', 'google', 'demo_firebase_uid_alex', 'demo_firebase_uid_alex', 'alex.buddy@example.com', NULL, TRUE)
ON CONFLICT (provider, provider_account_id) DO NOTHING;

INSERT INTO public.profiles (user_id, display_name, bio, native_lang, target_lang, proficiency_level, daily_goal_minutes, streak_count, best_streak, is_online) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Phạm Văn Hưng', 'Sinh viên 65KTPM luyện giao tiếp tiếng Anh mỗi ngày.', 'vi', 'en', 'A2', 20, 5, 12, TRUE),
  ('22222222-2222-2222-2222-222222222222', 'Alex Carter', 'Native English speaker learning Vietnamese.', 'en', 'vi', 'A1', 15, 3, 7, TRUE)
ON CONFLICT (user_id) DO NOTHING;

-- 2. Tạo 1 phòng Chat Nhóm học tập mẫu + 1 phòng Chat 1-1 mẫu
INSERT INTO public.conversations (id, type, name, description, topic_category, level, target_lang, created_by) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'group', 'CLB Luyện Nói Tiếng Anh A1-A2', 'Phòng học nhóm cho sinh viên thực hành giao tiếp mỗi tối.', 'Daily Life', 'A1', 'en', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'direct', NULL, '', 'Daily Life', 'A2', 'en', '11111111-1111-1111-1111-111111111111')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.conversation_members (conversation_id, user_id, role) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'owner'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'member'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'owner'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'member')
ON CONFLICT (conversation_id, user_id) DO NOTHING;

-- 3. Tạo 3 chủ đề hội thoại mẫu (khớp ID với assets/data/topics.json)
INSERT INTO public.conversation_topics (id, title, title_en, level, category, description, thumbnail_icon, estimated_minutes) VALUES
  ('topic_001', 'Giới thiệu bản thân', 'Self Introduction', 'A1', 'Daily Life', 'Học cách giới thiệu tên, tuổi, quê quán và nghề nghiệp cơ bản.', '👋', 15),
  ('topic_002', 'Sở thích và thời gian rảnh', 'Hobbies & Free Time', 'A1', 'Daily Life', 'Chia sẻ về sở thích cá nhân và các hoạt động cuối tuần.', '🎨', 15),
  ('topic_003', 'Du lịch và hỏi đường', 'Travel & Directions', 'A2', 'Travel', 'Thực hành đặt phòng, gọi món và hỏi đường khi đi du lịch.', '✈️', 20)
ON CONFLICT (id) DO NOTHING;
