-- ============================================================================
-- MIGRATION 005: CHỈ MỤC (INDEXES) & TRIGGER TỰ ĐỘNG HÓA
-- ============================================================================

-- 1. Chỉ mục tối ưu truy vấn cho cả 5 phân hệ
CREATE INDEX IF NOT EXISTS idx_user_accounts_firebase_uid
  ON public.user_accounts (firebase_uid);

CREATE INDEX IF NOT EXISTS idx_user_accounts_user_id
  ON public.user_accounts (user_id);

CREATE INDEX IF NOT EXISTS idx_profiles_matching
  ON public.profiles (native_lang, target_lang, proficiency_level);

CREATE INDEX IF NOT EXISTS idx_buddy_matches_users
  ON public.buddy_matches (requester_id, receiver_id, status);

CREATE INDEX IF NOT EXISTS idx_conversation_members_user
  ON public.conversation_members (user_id, conversation_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation
  ON public.messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_quest_logs_user_date
  ON public.user_quest_logs (user_id, log_date DESC);

CREATE INDEX IF NOT EXISTS idx_sessions_user
  ON public.practice_sessions (user_id, completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_vocab_user
  ON public.vocab_notebook (user_id, created_at DESC);

-- 2. Trigger tự động cập nhật cột updated_at trên users và profiles
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3. Trigger tự động cập nhật tin nhắn cuối cùng vào bảng conversations
--    Giúp màn hình danh sách phòng Chat tải siêu nhanh mà không cần JOIN nặng
CREATE OR REPLACE FUNCTION public.sync_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET
    last_message_text = LEFT(NEW.content, 120),
    last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_messages_sync_last ON public.messages;
CREATE TRIGGER trg_messages_sync_last
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.sync_conversation_last_message();
