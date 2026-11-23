-- ============================================================================
-- MIGRATION 002: PHÂN HỆ QUẢN LÝ KỶ LUẬT CÁ NHÂN (PERSONAL DISCIPLINE)
-- Phụ trách: Phạm Văn Hưng
--   - 1 users -- 1:N --> daily_goals (nhiều mục tiêu nhỏ hàng ngày)
--   - 1 users -- 1:N --> user_quest_logs (check-in tổng hợp theo ngày cho Streak & Heatmap)
-- ============================================================================

-- 5. BẢNG DAILY_GOALS: Danh sách mục tiêu rèn luyện hàng ngày của người dùng
CREATE TABLE IF NOT EXISTS public.daily_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_minutes INTEGER NOT NULL DEFAULT 15 CHECK (target_minutes > 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. BẢNG USER_QUEST_LOGS: Lịch sử check-in kỷ luật theo từng ngày (Streak & Heatmap)
CREATE TABLE IF NOT EXISTS public.user_quest_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  goal_minutes INTEGER NOT NULL DEFAULT 15,
  completed_minutes INTEGER NOT NULL DEFAULT 0,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  emotion_note TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_quest_per_day UNIQUE (user_id, log_date)
);
