-- ============================================================================
-- MIGRATION 011: HỆ THỐNG THÔNG BÁO REALTIME (WEBSOCKET VIA SUPABASE REALTIME)
-- Bảng mới: public.notifications (bảng thứ 16) — dùng chung cho toàn ứng dụng:
--   - room_join_request  : Có người xin tham gia phòng cần kiểm duyệt
--   - room_join_approved : Quản lý phòng đã duyệt yêu cầu tham gia
--   - room_join_rejected : Quản lý phòng từ chối yêu cầu tham gia
--   - buddy_request      : Lời mời ghép cặp bạn đồng hành
--   - system             : Thông báo kỷ luật / hệ thống
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  type TEXT NOT NULL DEFAULT 'system',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  reference_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);

-- Bật RLS & Policy
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dev_allow_all_notifications" ON public.notifications;
CREATE POLICY "dev_allow_all_notifications"
  ON public.notifications
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Bật Supabase Realtime (WebSocket) cho bảng notifications & conversation_members
DO $$
DECLARE
  rt_tbl TEXT;
BEGIN
  FOREACH rt_tbl IN ARRAY ARRAY['notifications', 'conversation_members']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = rt_tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;', rt_tbl);
    END IF;
  END LOOP;
END $$;
