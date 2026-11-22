-- ============================================================================
-- MIGRATION 004: KHO CHỦ ĐỀ, BUỔI LUYỆN TẬP & SỔ TAY TỪ VỰNG
-- Phụ trách:
--   - Cao Đức Đạo: conversation_topics, user_topic_progress
--   - Trịnh Trung Kiên: practice_sessions
--   - Trương Tuấn Hải: vocab_notebook
-- ============================================================================

-- 11. BẢNG CONVERSATION_TOPICS: Kho chủ đề & kịch bản hội thoại mẫu (A1-B2)
CREATE TABLE IF NOT EXISTS public.conversation_topics (
  id TEXT PRIMARY KEY, -- Ví dụ: 'topic_001' khớp với assets/data/topics.json
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

-- 12. BẢNG USER_TOPIC_PROGRESS: Tiến độ hoàn thành chủ đề (N-N giữa users & topics)
CREATE TABLE IF NOT EXISTS public.user_topic_progress (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  topic_id TEXT NOT NULL REFERENCES public.conversation_topics(id) ON DELETE CASCADE,
  is_completed BOOLEAN NOT NULL DEFAULT TRUE,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, topic_id)
);

-- 13. BẢNG PRACTICE_SESSIONS: Đặt lịch, bấm giờ buổi luyện tập & đánh giá sao
CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
  topic_id TEXT REFERENCES public.conversation_topics(id) ON DELETE SET NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 15 CHECK (duration_minutes > 0),
  scheduled_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  notes TEXT DEFAULT '',
  rating INTEGER CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. BẢNG VOCAB_NOTEBOOK: Sổ tay lưu từ mới đã dịch trong phòng chat
CREATE TABLE IF NOT EXISTS public.vocab_notebook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  translated_meaning TEXT NOT NULL,
  source_lang TEXT NOT NULL DEFAULT 'en',
  target_lang TEXT NOT NULL DEFAULT 'vi',
  example_sentence TEXT DEFAULT '',
  is_mastered BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
