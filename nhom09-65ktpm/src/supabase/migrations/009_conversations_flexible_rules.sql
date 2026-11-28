-- ============================================================================
-- MIGRATION 009: CHO PHÉP PHÒNG HỌC KHÔNG GIỚI HẠN THÀNH VIÊN & KHÔNG YÊU CẦU TRÌNH ĐỘ
-- Cập nhật bảng public.conversations:
--   - max_members NULL  => Phòng không giới hạn số lượng thành viên
--   - level NULL        => Phòng không yêu cầu trình độ (mọi trình độ đều tham gia được)
--   - created_by        => Người quản lý phòng (liên kết profiles.display_name)
-- ============================================================================

ALTER TABLE public.conversations
  ALTER COLUMN max_members DROP NOT NULL,
  ALTER COLUMN max_members DROP DEFAULT,
  ALTER COLUMN level DROP DEFAULT,
  ALTER COLUMN topic_category DROP DEFAULT;
