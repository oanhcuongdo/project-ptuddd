-- ============================================================================
-- MIGRATION 012: CHUỖI LỬA RIÊNG CỦA TỪNG THÀNH VIÊN TRONG TỪNG PHÒNG CHAT
-- Cơ chế giống chuỗi TikTok (lưu theo khóa chính conversation_id + user_id):
--   - Mỗi phòng có nhiều người, mỗi người giữ 1 chuỗi lửa riêng với phòng đó.
--   - Ban đầu = 0; nhắn ít nhất 1 tin trong ngày -> +1 ngày chuỗi.
--   - Quên trọn 1 ngày không nhắn -> chuỗi tự mất về 0.
-- ============================================================================

ALTER TABLE public.conversation_members
  ADD COLUMN IF NOT EXISTS streak_count INTEGER NOT NULL DEFAULT 0 CHECK (streak_count >= 0),
  ADD COLUMN IF NOT EXISTS best_streak INTEGER NOT NULL DEFAULT 0 CHECK (best_streak >= 0),
  ADD COLUMN IF NOT EXISTS last_chat_date DATE;
