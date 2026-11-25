-- ============================================================================
-- MIGRATION 014: PHÂN QUYỀN PHÓ PHÒNG / TRỢ GIẢNG (CO_OWNER) TRONG PHÒNG HỌC
-- Phụ trách: Phạm Văn Hưng
--   - owner    : Chủ phòng (toàn quyền, bổ nhiệm/gỡ Phó phòng)
--   - co_owner : Phó phòng / Trợ giảng (duyệt thành viên, sửa nội quy, mời thành viên vi phạm)
--   - member   : Thành viên
-- ============================================================================

DO $$
DECLARE
  con_name TEXT;
BEGIN
  SELECT c.conname INTO con_name
  FROM pg_constraint c
  JOIN pg_class t ON c.conrelid = t.oid
  JOIN pg_namespace n ON t.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND t.relname = 'conversation_members'
    AND c.contype = 'c'
    AND pg_get_constraintdef(c.oid) ILIKE '%role%';

  IF con_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.conversation_members DROP CONSTRAINT %I;', con_name);
  END IF;
END $$;

ALTER TABLE public.conversation_members
  ADD CONSTRAINT conversation_members_role_check
  CHECK (role IN ('owner', 'co_owner', 'member'));
