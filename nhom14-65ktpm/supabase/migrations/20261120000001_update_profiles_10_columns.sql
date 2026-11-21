-- ==============================================================================
-- Migration: Cập nhật bảng profiles bổ sung đủ 10 thuộc tính
-- Dự án: Hệ Thống Hỗ Trợ Định Hướng Và Chuẩn Bị Đồ Án Tốt Nghiệp Cho Sinh Viên
-- ==============================================================================

-- 1. Bổ sung các cột mới nếu chưa tồn tại
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS student_code TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS class_name TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS major TEXT DEFAULT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';

-- 2. Cập nhật thuộc tính của full_name (cho phép null, không có default)
ALTER TABLE public.profiles ALTER COLUMN full_name DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN full_name DROP DEFAULT;

-- 3. Cập nhật chú thích các cột mới
COMMENT ON COLUMN public.profiles.id IS 'Mã định danh người dùng, khóa ngoại tham chiếu auth.users(id)';
COMMENT ON COLUMN public.profiles.full_name IS 'Họ và tên người dùng';
COMMENT ON COLUMN public.profiles.avatar_url IS 'Đường dẫn ảnh đại diện';
COMMENT ON COLUMN public.profiles.role IS 'Vai trò: student (mặc định), lecturer hoặc admin';
COMMENT ON COLUMN public.profiles.student_code IS 'Mã sinh viên';
COMMENT ON COLUMN public.profiles.class_name IS 'Lớp sinh hoạt';
COMMENT ON COLUMN public.profiles.major IS 'Chuyên ngành';
COMMENT ON COLUMN public.profiles.skills IS 'Danh sách kỹ năng của người dùng';
COMMENT ON COLUMN public.profiles.created_at IS 'Thời điểm tạo hồ sơ';
COMMENT ON COLUMN public.profiles.updated_at IS 'Thời điểm cập nhật hồ sơ gần nhất';

-- 4. Cập nhật lại trigger function handle_new_user để tự động điền các cột mới khi có tài khoản mới
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    full_name,
    avatar_url,
    role,
    student_code,
    class_name,
    major,
    skills,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    'student',
    NEW.raw_user_meta_data->>'student_code',
    NEW.raw_user_meta_data->>'class_name',
    NEW.raw_user_meta_data->>'major',
    '{}'::TEXT[],
    now(),
    now()
  );
  RETURN NEW;
END;
$$;
