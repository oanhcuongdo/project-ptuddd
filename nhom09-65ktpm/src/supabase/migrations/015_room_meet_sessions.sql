-- ============================================================================
-- MIGRATION 015: LỊCH HỌC VIDEO CALL MEET & ĐIỂM DANH LÊN CHUỖI 2 TẦNG
-- Phụ trách: Phạm Văn Hưng
--   - room_meet_sessions   : Lịch / buổi Video Call Jitsi Meet do Chủ phòng hoặc Trợ giảng tạo
--   - room_meet_attendance : Ghi nhận số giây học thật từng thành viên & chống cộng chuỗi trùng
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.room_meet_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  meet_room_code TEXT NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  min_minutes INTEGER NOT NULL DEFAULT 15 CHECK (min_minutes > 0),
  status TEXT NOT NULL DEFAULT 'live' CHECK (status IN ('scheduled', 'live', 'ended')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_room_meet_sessions_conv
  ON public.room_meet_sessions (conversation_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.room_meet_attendance (
  session_id UUID NOT NULL REFERENCES public.room_meet_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  attended_seconds INTEGER NOT NULL DEFAULT 0 CHECK (attended_seconds >= 0),
  streak_awarded BOOLEAN NOT NULL DEFAULT FALSE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (session_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_room_meet_attendance_user_updated
  ON public.room_meet_attendance (user_id, updated_at DESC);

-- Bật RLS & Policy
ALTER TABLE public.room_meet_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_meet_attendance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dev_allow_all_room_meet_sessions" ON public.room_meet_sessions;
CREATE POLICY "dev_allow_all_room_meet_sessions"
  ON public.room_meet_sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "dev_allow_all_room_meet_attendance" ON public.room_meet_attendance;
CREATE POLICY "dev_allow_all_room_meet_attendance"
  ON public.room_meet_attendance FOR ALL USING (true) WITH CHECK (true);

-- Bật Supabase Realtime cho lịch học Meet & điểm danh
DO $$
DECLARE
  rt_tbl TEXT;
BEGIN
  FOREACH rt_tbl IN ARRAY ARRAY['room_meet_sessions', 'room_meet_attendance']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = rt_tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;', rt_tbl);
    END IF;
  END LOOP;
END $$;
