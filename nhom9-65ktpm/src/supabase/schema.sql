-- ============================================================================
-- BUDDYTALK DATABASE SCHEMA (SUPABASE POSTGRESQL + REALTIME)
-- Nhóm 09 - Lớp 65KTPM - Học phần Phát Triển Ứng Dụng Di Động (PTUDDD)
-- Hướng dẫn: Copy toàn bộ nội dung dán vào Supabase Dashboard -> SQL Editor -> Run
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. BẢNG PROFILES: Hồ sơ người dùng, ngôn ngữ mẹ đẻ / mục tiêu & chuỗi Streak
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id TEXT PRIMARY KEY, -- UID từ Firebase Authentication
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  native_lang TEXT NOT NULL DEFAULT 'vi',       -- vi, en, zh
  target_lang TEXT NOT NULL DEFAULT 'en',       -- en, zh, vi
  proficiency_level TEXT NOT NULL DEFAULT 'A1', -- A1, A2, B1, B2
  daily_goal_minutes INTEGER NOT NULL DEFAULT 15,
  streak_count INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  is_online BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. BẢNG BUDDY_MATCHES: Quản lý ghép cặp & lời mời kết nối bạn đồng hành
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.buddy_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  matched_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT buddy_no_self_match CHECK (requester_id <> receiver_id),
  CONSTRAINT buddy_unique_pair UNIQUE (requester_id, receiver_id)
);

-- ----------------------------------------------------------------------------
-- 3. BẢNG STUDY_GROUPS: Các phòng Chat Nhóm học tập đa người dùng theo chủ đề
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  topic_category TEXT NOT NULL DEFAULT 'Daily Life',
  level TEXT NOT NULL DEFAULT 'A1',
  target_lang TEXT NOT NULL DEFAULT 'en',
  created_by TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  max_members INTEGER NOT NULL DEFAULT 20,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. BẢNG GROUP_MEMBERS: Thành viên tham gia phòng học nhóm
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.group_members (
  group_id UUID NOT NULL REFERENCES public.study_groups(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

-- ----------------------------------------------------------------------------
-- 5. BẢNG MESSAGES: Tin nhắn Realtime (hỗ trợ cả Chat 1-1 & Chat Nhóm)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.study_groups(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  translated_content TEXT,
  source_lang TEXT,
  target_lang TEXT,
  image_url TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Tin nhắn phải thuộc 1 phòng chat 1-1 HOẶC 1 phòng nhóm học tập
  CONSTRAINT message_target_check CHECK (
    (receiver_id IS NOT NULL AND group_id IS NULL) OR
    (receiver_id IS NULL AND group_id IS NOT NULL)
  )
);

-- ----------------------------------------------------------------------------
-- 6. BẢNG CONVERSATION_TOPICS: Kho chủ đề & kịch bản hội thoại mẫu (A1-B2)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversation_topics (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  title_en TEXT NOT NULL,
  level TEXT NOT NULL DEFAULT 'A1',
  category TEXT NOT NULL DEFAULT 'Daily Life',
  description TEXT DEFAULT '',
  description_en TEXT DEFAULT '',
  thumbnail_icon TEXT DEFAULT '💬',
  estimated_minutes INTEGER NOT NULL DEFAULT 15,
  conversation_starters JSONB NOT NULL DEFAULT '[]'::jsonb,
  sample_dialogues JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. BẢNG PRACTICE_SESSIONS: Quản lý buổi học, thời lượng (Timer) & đánh giá
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  buddy_id TEXT REFERENCES public.profiles(id) ON DELETE SET NULL,
  group_id UUID REFERENCES public.study_groups(id) ON DELETE SET NULL,
  topic_id TEXT REFERENCES public.conversation_topics(id) ON DELETE SET NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 15,
  notes TEXT DEFAULT '',
  rating INTEGER CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. BẢNG USER_QUEST_LOGS: Lịch sử check-in kỷ luật & dữ liệu Ma trận Heatmap
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_quest_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  goal_minutes INTEGER NOT NULL DEFAULT 15,
  completed_minutes INTEGER NOT NULL DEFAULT 0,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  emotion_note TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_quest_per_day UNIQUE (user_id, log_date)
);

-- ----------------------------------------------------------------------------
-- 9. BẢNG PHỤ TRỢ: Sổ tay từ vựng (vocab_notebook) & Báo cáo vi phạm
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vocab_notebook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  translated_meaning TEXT NOT NULL,
  source_lang TEXT NOT NULL DEFAULT 'en',
  target_lang TEXT NOT NULL DEFAULT 'vi',
  example_sentence TEXT DEFAULT '',
  is_mastered BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reported_user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- CHỈ MỤC (INDEXES) TỐI ƯU HIỆU NĂNG TRUY VẤN
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_messages_direct ON public.messages (sender_id, receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_group ON public.messages (group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_quest_logs_user_date ON public.user_quest_logs (user_id, log_date DESC);
CREATE INDEX IF NOT EXISTS idx_buddy_matches_users ON public.buddy_matches (requester_id, receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON public.practice_sessions (user_id, completed_at DESC);

-- ----------------------------------------------------------------------------
-- BẬT ROW LEVEL SECURITY (RLS) & CHÍNH SÁCH MẪU CHO ĐỒ ÁN
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buddy_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quest_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vocab_notebook ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

-- Policy phát triển (cho phép đọc/ghi trong quá trình tích hợp với Firebase Auth UID)
-- Lưu ý: Khi chuyển sang production có thể siết chặt bằng JWT custom claim.
CREATE POLICY "Allow all during dev - profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - buddy_matches" ON public.buddy_matches FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - study_groups" ON public.study_groups FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - group_members" ON public.group_members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - messages" ON public.messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - topics" ON public.conversation_topics FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - sessions" ON public.practice_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - quest_logs" ON public.user_quest_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - vocab" ON public.vocab_notebook FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all during dev - reports" ON public.user_reports FOR ALL USING (true) WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- BẬT SUPABASE REALTIME CHO PHÒNG CHAT & GHÉP ĐÔI (<100ms)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'study_groups'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.study_groups;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'buddy_matches'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.buddy_matches;
  END IF;
END $$;
