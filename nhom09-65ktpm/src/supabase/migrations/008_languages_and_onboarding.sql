-- ============================================================================
-- MIGRATION 008: DANH MỤC NGÔN NGỮ ĐƯỢC CẤP PHÉP (ADMIN) & TRẠNG THÁI ONBOARDING
-- Bảng mới: public.languages (bảng thứ 15) — Admin quản lý các ngôn ngữ được phép học.
-- Cập nhật: public.profiles thêm cột onboarding_completed và khóa ngoại sang languages.
-- ============================================================================

-- 1. BẢNG LANGUAGES: Danh mục ngôn ngữ do Admin cấp phép trên toàn hệ thống
CREATE TABLE IF NOT EXISTS public.languages (
  code TEXT PRIMARY KEY,                          -- Mã ISO: vi, en, zh, ja, ko, fr...
  name TEXT NOT NULL,                             -- Tên đầy đủ: Tiếng Việt, English...
  short_label TEXT NOT NULL,                      -- Tên ngắn hiển thị trên chip: Việt, Anh...
  flag_code TEXT NOT NULL,                        -- Mã vùng/cờ: VN, GB, CN, JP, KR...
  is_active BOOLEAN NOT NULL DEFAULT TRUE,        -- Admin bật/tắt ngôn ngữ cấp phép
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed ngôn ngữ cấp phép ban đầu (Admin có thể thêm/sửa/tắt trực tiếp trên Supabase)
INSERT INTO public.languages (code, name, short_label, flag_code, is_active, sort_order)
VALUES
  ('vi', 'Tiếng Việt', 'Việt', 'VN', TRUE, 1),
  ('en', 'English (Tiếng Anh)', 'Anh', 'GB', TRUE, 2),
  ('zh', '中文 (Tiếng Trung)', 'Trung', 'CN', TRUE, 3),
  ('ja', '日本語 (Tiếng Nhật)', 'Nhật', 'JP', TRUE, 4),
  ('ko', '한국어 (Tiếng Hàn)', 'Hàn', 'KR', TRUE, 5)
ON CONFLICT (code) DO NOTHING;

-- 2. CẬP NHẬT BẢNG PROFILES: Thêm cờ kiểm tra đã thiết lập hồ sơ (Duolingo Onboarding)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE;

-- Gắn khóa ngoại chuẩn 3NF từ profiles.native_lang & target_lang -> languages(code)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_native_lang_fkey'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_native_lang_fkey
      FOREIGN KEY (native_lang) REFERENCES public.languages(code);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_target_lang_fkey'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_target_lang_fkey
      FOREIGN KEY (target_lang) REFERENCES public.languages(code);
  END IF;
END $$;

-- 3. BẬT RLS & POLICY CHO BẢNG LANGUAGES
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dev_allow_all_languages" ON public.languages;
CREATE POLICY "dev_allow_all_languages"
  ON public.languages
  FOR ALL
  USING (true)
  WITH CHECK (true);
