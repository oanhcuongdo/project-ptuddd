
-- ============================================================
-- MIGRATION 01: FOUNDATION AUTH
-- Du an: PTUDDD - Nhom 14 - 65KTPM
-- Phu trach: TV1
-- ============================================================

BEGIN;

-- ============================================================
-- 1. TAO BANG PROFILES
-- ============================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    full_name TEXT NOT NULL DEFAULT '',
    student_code TEXT,
    class_name TEXT,

    role TEXT NOT NULL DEFAULT 'student'
        CHECK (role IN ('student', 'lecturer', 'admin')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. FUNCTION TU DONG CAP NHAT UPDATED_AT
-- ============================================================

CREATE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 3. TU DONG TAO PROFILE KHI DANG KY
-- ============================================================

CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        full_name,
        student_code,
        class_name,
        role
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.raw_user_meta_data ->> 'name',
            ''
        ),
        NULLIF(
            NEW.raw_user_meta_data ->> 'student_code',
            ''
        ),
        NULLIF(
            NEW.raw_user_meta_data ->> 'class_name',
            ''
        ),
        'student'
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 4. TAO LAI PROFILE CHO CAC TAI KHOAN DA TON TAI
-- ============================================================

INSERT INTO public.profiles (
    id,
    full_name,
    student_code,
    class_name,
    role,
    created_at
)
SELECT
    id,
    COALESCE(
        raw_user_meta_data ->> 'full_name',
        raw_user_meta_data ->> 'name',
        ''
    ),
    NULLIF(
        raw_user_meta_data ->> 'student_code',
        ''
    ),
    NULLIF(
        raw_user_meta_data ->> 'class_name',
        ''
    ),
    'student',
    COALESCE(created_at, NOW())
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. FUNCTION KIEM TRA ROLE
-- Tranh truy van RLS de quy vao profiles
-- ============================================================

CREATE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT role
    FROM public.profiles
    WHERE id = auth.uid();
$$;

-- ============================================================
-- 6. FUNCTION CAP ROLE PHIA SERVER
-- Chi service_role duoc goi tu API
-- ============================================================

CREATE FUNCTION public.set_user_role(
    p_user_id UUID,
    p_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF p_role IS NULL OR
       p_role NOT IN ('student', 'lecturer', 'admin')
    THEN
        RAISE EXCEPTION 'Invalid role';
    END IF;

    UPDATE public.profiles
    SET role = p_role
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;
END;
$$;

-- ============================================================
-- 7. GIOI HAN QUYEN THUC THI FUNCTION
-- ============================================================

REVOKE ALL ON FUNCTION public.handle_new_user()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.set_updated_at()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.get_my_role()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.get_my_role()
TO authenticated;

REVOKE ALL ON FUNCTION public.set_user_role(UUID, TEXT)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.set_user_role(UUID, TEXT)
TO service_role;

-- ============================================================
-- 8. BAT ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 9. THIET LAP QUYEN TRUY CAP BANG
-- ============================================================

REVOKE ALL ON TABLE public.profiles
FROM PUBLIC, anon, authenticated;

GRANT USAGE ON SCHEMA public
TO authenticated;

GRANT SELECT ON TABLE public.profiles
TO authenticated;

GRANT UPDATE (
    full_name,
    student_code,
    class_name
)
ON public.profiles
TO authenticated;

GRANT ALL ON TABLE public.profiles
TO service_role;

-- ============================================================
-- 10. RLS: CHI XEM PROFILE CUA MINH
-- ============================================================

CREATE POLICY profiles_select_own
ON public.profiles
FOR SELECT
TO authenticated
USING (
    id = (SELECT auth.uid())
);

-- ============================================================
-- 11. RLS: CHI CAP NHAT PROFILE CUA MINH
-- ============================================================

CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    id = (SELECT auth.uid())
)
WITH CHECK (
    id = (SELECT auth.uid())
);

COMMIT;
