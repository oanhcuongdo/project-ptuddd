-- ============================================================================
-- MIGRATION 006: ROW LEVEL SECURITY (RLS) & BẬT SUPABASE REALTIME
-- Lưu ý: Nhóm sử dụng Firebase Authentication để đăng nhập nên chính sách dev
--        mở quyền truy cập để client kết nối linh hoạt theo Firebase UID.
-- ============================================================================

-- 1. Bật RLS trên toàn bộ 14 bảng
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quest_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buddy_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_topic_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vocab_notebook ENABLE ROW LEVEL SECURITY;

-- 2. Policy phát triển (an toàn khi chạy lại nhiều lần nhờ DROP POLICY IF EXISTS)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'users', 'user_accounts', 'profiles', 'user_reports',
    'daily_goals', 'user_quest_logs', 'buddy_matches',
    'conversations', 'conversation_members', 'messages',
    'conversation_topics', 'user_topic_progress',
    'practice_sessions', 'vocab_notebook'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "dev_allow_all_%s" ON public.%I;', tbl, tbl);
    EXECUTE format('CREATE POLICY "dev_allow_all_%s" ON public.%I FOR ALL USING (true) WITH CHECK (true);', tbl, tbl);
  END LOOP;
END $$;

-- 3. Bật Supabase Realtime cho các bảng cần cập nhật tức thì (<100ms)
DO $$
DECLARE
  rt_tbl TEXT;
BEGIN
  FOREACH rt_tbl IN ARRAY ARRAY['messages', 'conversations', 'buddy_matches']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = rt_tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;', rt_tbl);
    END IF;
  END LOOP;
END $$;
