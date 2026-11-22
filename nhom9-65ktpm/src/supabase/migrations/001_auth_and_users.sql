-- ============================================================================
-- MIGRATION 001: TÀI KHOẢN, ĐA PHƯƠNG THỨC ĐĂNG NHẬP & HỒ SƠ (AUTH & USERS)
-- Kiến trúc:
--   - Firebase Auth xử lý đăng nhập (Google, SĐT, Email...)
--   - 1 users (gốc)  -- 1:N --> user_accounts (nhiều phương thức đăng nhập)
--   - 1 users (gốc)  -- 1:1 --> profiles (hồ sơ hiển thị công khai)
--   - 1 users (gốc)  -- 1:N --> user_reports (báo cáo người dùng vi phạm)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. BẢNG USERS: Thực thể người dùng gốc bất biến
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. BẢNG USER_ACCOUNTS: Lưu nhiều phương thức đăng nhập (Google, SĐT, Email...)
--    Quan hệ: 1 users -> N user_accounts
CREATE TABLE IF NOT EXISTS public.user_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('google', 'phone', 'email', 'apple', 'facebook')),
  provider_account_id TEXT NOT NULL, -- Firebase UID hoặc định danh từ nhà cung cấp
  firebase_uid TEXT,                 -- Lưu Firebase Auth UID để tra cứu nhanh
  email TEXT,
  phone_number TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  last_login_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_provider_account UNIQUE (provider, provider_account_id)
);

-- 3. BẢNG PROFILES: Thông tin hiển thị công khai & ngôn ngữ học tập
--    Quan hệ: 1 users <-> 1 profiles (user_id vừa là PK vừa là FK)
CREATE TABLE IF NOT EXISTS public.profiles (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  native_lang TEXT NOT NULL DEFAULT 'vi',       -- vi, en, zh
  target_lang TEXT NOT NULL DEFAULT 'en',       -- en, zh, vi
  proficiency_level TEXT NOT NULL DEFAULT 'A1', -- A1, A2, B1, B2
  daily_goal_minutes INTEGER NOT NULL DEFAULT 15,
  streak_count INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  is_online BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. BẢNG USER_REPORTS: Báo cáo người dùng vi phạm
--    Quan hệ: 1 users -> N user_reports
CREATE TABLE IF NOT EXISTS public.user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reported_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT report_no_self CHECK (reporter_id <> reported_user_id)
);
