
-- ============================================================
-- MIGRATION 03: PERSONAL TOPICS
-- Du an: PTUDDD - Nhom 14 - 65KTPM
-- ============================================================

BEGIN;

-- ============================================================
-- 1. TAO BANG DE TAI CA NHAN
-- ============================================================

CREATE TABLE public.personal_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES auth.users(id)
        ON DELETE RESTRICT,

    title TEXT NOT NULL
        CHECK (btrim(title) <> ''),

    field_id UUID
        REFERENCES public.fields(id)
        ON DELETE SET NULL,

    objective TEXT,

    approach TEXT,

    technologies TEXT[] NOT NULL DEFAULT '{}',

    source TEXT NOT NULL DEFAULT 'manual'
        CHECK (
            source IN ('manual', 'ai')
        ),

    status TEXT NOT NULL DEFAULT 'exploring'
        CHECK (
            status IN (
                'exploring',
                'preparing',
                'in_progress',
                'completed'
            )
        ),

    archived_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. INDEX HO TRO TRUY VAN
-- ============================================================

CREATE INDEX idx_personal_topics_user_id
ON public.personal_topics(user_id);

CREATE INDEX idx_personal_topics_field_id
ON public.personal_topics(field_id);

CREATE INDEX idx_personal_topics_user_status
ON public.personal_topics(user_id, status);

CREATE INDEX idx_personal_topics_active
ON public.personal_topics(user_id)
WHERE archived_at IS NULL;

-- ============================================================
-- 3. TU DONG CAP NHAT UPDATED_AT
-- Su dung function tu migration 01
-- ============================================================

CREATE TRIGGER personal_topics_set_updated_at
BEFORE UPDATE ON public.personal_topics
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 4. BAT ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.personal_topics
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. THIET LAP QUYEN TRUY CAP
-- ============================================================

REVOKE ALL ON TABLE public.personal_topics
FROM PUBLIC, anon, authenticated;

GRANT SELECT, DELETE
ON public.personal_topics
TO authenticated;

-- Chi cho phep ghi cac cot nghiep vu.

GRANT INSERT (
    user_id,
    title,
    field_id,
    objective,
    approach,
    technologies,
    source,
    status
)
ON public.personal_topics
TO authenticated;

-- Khong cho phep thay doi user_id, id,
-- source va cac cot thoi gian he thong.

GRANT UPDATE (
    title,
    field_id,
    objective,
    approach,
    technologies,
    status,
    archived_at
)
ON public.personal_topics
TO authenticated;

GRANT ALL ON TABLE public.personal_topics
TO service_role;

-- ============================================================
-- 6. RLS: SINH VIEN CHI XEM DE TAI CUA MINH
-- ============================================================

CREATE POLICY personal_topics_select_own
ON public.personal_topics
FOR SELECT
TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
);

-- ============================================================
-- 7. RLS: SINH VIEN CHI TAO DE TAI CHO MINH
-- ============================================================

CREATE POLICY personal_topics_insert_own
ON public.personal_topics
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
);

-- ============================================================
-- 8. RLS: SINH VIEN CHI SUA DE TAI CUA MINH
-- ============================================================

CREATE POLICY personal_topics_update_own
ON public.personal_topics
FOR UPDATE
TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
)
WITH CHECK (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
);

-- ============================================================
-- 9. RLS: SINH VIEN CHI XOA DE TAI CUA MINH
-- Migration 04 se chan xoa neu con ke hoach.
-- ============================================================

CREATE POLICY personal_topics_delete_own
ON public.personal_topics
FOR DELETE
TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
);

COMMIT;
