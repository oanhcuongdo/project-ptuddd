-- ============================================================================
-- MIGRATION 013: ẢNH BÌA PHÒNG HỌC (COVER_URL) & ĐỊNH HƯỚNG KỸ NĂNG (ROOM_FOCUS)
-- Phụ trách: Phạm Văn Hưng
--   - cover_url  : Link ảnh bìa (https://...) hoặc mã nền gradient (preset:teal...)
--   - room_focus : Định hướng dài hạn của CLB (Giao tiếp tự do, IELTS, Phát âm...)
-- ============================================================================

ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS cover_url TEXT,
  ADD COLUMN IF NOT EXISTS room_focus TEXT;
