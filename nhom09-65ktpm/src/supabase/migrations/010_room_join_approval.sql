-- ============================================================================
-- MIGRATION 010: CHẾ ĐỘ KIỂM DUYỆT THÀNH VIÊN PHÒNG HỌC (KIỂU NHÓM FACEBOOK / ZALO)
-- - conversations.require_approval:
--     FALSE => Phòng mở (bấm Tham gia vào thẳng phòng)
--     TRUE  => Phòng kiểm duyệt (bấm Xin tham gia -> chờ Quản lý phòng duyệt)
-- - conversation_members.status:
--     'approved' => Đã là thành viên chính thức
--     'pending'  => Đang chờ người quản lý phòng phê duyệt
-- ============================================================================

ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS require_approval BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.conversation_members
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved'
  CHECK (status IN ('pending', 'approved'));
