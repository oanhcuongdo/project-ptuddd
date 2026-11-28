
-- ============================================================
-- MIGRATION 02: PROJECT REPOSITORY
-- Du an: PTUDDD - Nhom 14 - 65KTPM
-- ============================================================

BEGIN;

-- ============================================================
-- 1. BANG LINH VUC
-- ============================================================

CREATE TABLE public.fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL UNIQUE
        CHECK (btrim(name) <> '')
);

-- ============================================================
-- 2. BANG KHO DO AN
-- ============================================================

CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    student_code TEXT,
    student_name TEXT,
    class_name TEXT,

    title TEXT NOT NULL
        CHECK (btrim(title) <> ''),

    supervisor_name TEXT,
    department_name TEXT,

    field_id UUID
        REFERENCES public.fields(id)
        ON DELETE SET NULL,

    year INTEGER
        CHECK (year BETWEEN 1900 AND 2200),

    description TEXT,
    approach TEXT,

    technologies TEXT[] NOT NULL DEFAULT '{}',

    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'published',
                'rejected'
            )
        ),

    submitted_by UUID
        REFERENCES auth.users(id)
        ON DELETE SET NULL,

    reviewed_by UUID
        REFERENCES auth.users(id)
        ON DELETE SET NULL,

    reviewed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. BANG DO AN YEU THICH
-- ============================================================

CREATE TABLE public.favorites (
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    project_id UUID NOT NULL
        REFERENCES public.projects(id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, project_id)
);

-- ============================================================
-- 4. INDEX HO TRO TRUY VAN
-- ============================================================

CREATE INDEX idx_projects_field_id
ON public.projects(field_id);

CREATE INDEX idx_projects_status
ON public.projects(status);

CREATE INDEX idx_projects_submitted_by
ON public.projects(submitted_by);

CREATE INDEX idx_projects_reviewed_by
ON public.projects(reviewed_by);

CREATE INDEX idx_favorites_project_id
ON public.favorites(project_id);

-- ============================================================
-- 5. TU DONG CAP NHAT UPDATED_AT
-- Su dung function cua migration 01
-- ============================================================

CREATE TRIGGER projects_set_updated_at
BEFORE UPDATE ON public.projects
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 6. FUNCTION KIEM TRA QUYEN QUAN LY KHO
-- ============================================================

CREATE FUNCTION public.can_manage_projects()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    SELECT COALESCE(
        public.get_my_role()
            IN ('lecturer', 'admin'),
        FALSE
    );
$$;

REVOKE ALL
ON FUNCTION public.can_manage_projects()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.can_manage_projects()
TO authenticated;

-- ============================================================
-- 7. BAT ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.fields
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.projects
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.favorites
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 8. GRANT VA REVOKE
-- ============================================================

REVOKE ALL ON TABLE
    public.fields,
    public.projects,
    public.favorites
FROM PUBLIC, anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.fields
TO authenticated;

-- Chi cap quyen doc cac cot khong chua
-- thong tin dinh danh sinh vien lich su.

GRANT SELECT (
    id,
    title,
    field_id,
    year,
    description,
    approach,
    technologies,
    status,
    submitted_by,
    reviewed_at,
    created_at,
    updated_at
)
ON public.projects
TO authenticated;

GRANT INSERT (
    title,
    field_id,
    year,
    description,
    approach,
    technologies,
    submitted_by
)
ON public.projects
TO authenticated;

GRANT SELECT, DELETE
ON public.favorites
TO authenticated;

GRANT INSERT (user_id, project_id)
ON public.favorites
TO authenticated;

GRANT ALL ON TABLE
    public.fields,
    public.projects,
    public.favorites
TO service_role;

-- ============================================================
-- 9. RLS CHO FIELDS
-- ============================================================

CREATE POLICY fields_select
ON public.fields
FOR SELECT
TO authenticated
USING (TRUE);

CREATE POLICY fields_insert
ON public.fields
FOR INSERT
TO authenticated
WITH CHECK (
    (SELECT public.can_manage_projects())
);

CREATE POLICY fields_update
ON public.fields
FOR UPDATE
TO authenticated
USING (
    (SELECT public.can_manage_projects())
)
WITH CHECK (
    (SELECT public.can_manage_projects())
);

CREATE POLICY fields_delete
ON public.fields
FOR DELETE
TO authenticated
USING (
    (SELECT public.can_manage_projects())
);

-- ============================================================
-- 10. RLS CHO PROJECTS
-- ============================================================

CREATE POLICY projects_select
ON public.projects
FOR SELECT
TO authenticated
USING (
    status = 'published'
    OR submitted_by = (SELECT auth.uid())
    OR (SELECT public.can_manage_projects())
);

-- Sinh vien chi gui de xuat cua minh.
-- Khong duoc tu cong bo hoac ghi thong tin duyet.

CREATE POLICY projects_student_insert
ON public.projects
FOR INSERT
TO authenticated
WITH CHECK (
    (SELECT public.get_my_role()) = 'student'
    AND submitted_by = (SELECT auth.uid())
    AND status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
);

-- ============================================================
-- 11. RPC NHAP VA CAP NHAT DO AN
-- Chi lecturer/admin duoc su dung.
-- ============================================================

CREATE FUNCTION public.save_repository_project(
    p_data JSONB,
    p_project_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_id UUID;
    v_status TEXT;
BEGIN
    IF NOT public.can_manage_projects() THEN
        RAISE EXCEPTION 'Permission denied'
            USING ERRCODE = '42501';
    END IF;

    IF p_data IS NULL
       OR jsonb_typeof(p_data) <> 'object'
    THEN
        RAISE EXCEPTION 'Invalid project data';
    END IF;

    IF p_project_id IS NULL THEN

        v_status := COALESCE(
            p_data ->> 'status',
            'pending'
        );

        INSERT INTO public.projects (
            student_code,
            student_name,
            class_name,
            title,
            supervisor_name,
            department_name,
            field_id,
            year,
            description,
            approach,
            technologies,
            status,
            submitted_by,
            reviewed_by,
            reviewed_at
        )
        VALUES (
            p_data ->> 'student_code',
            p_data ->> 'student_name',
            p_data ->> 'class_name',
            p_data ->> 'title',
            p_data ->> 'supervisor_name',
            p_data ->> 'department_name',
            NULLIF(p_data ->> 'field_id', '')::UUID,
            NULLIF(p_data ->> 'year', '')::INTEGER,
            p_data ->> 'description',
            p_data ->> 'approach',
            ARRAY(
                SELECT jsonb_array_elements_text(
                    COALESCE(
                        p_data -> 'technologies',
                        '[]'::JSONB
                    )
                )
            ),
            v_status,
            auth.uid(),
            CASE
                WHEN v_status <> 'pending'
                THEN auth.uid()
                ELSE NULL
            END,
            CASE
                WHEN v_status <> 'pending'
                THEN NOW()
                ELSE NULL
            END
        )
        RETURNING id INTO v_id;

    ELSE

        UPDATE public.projects
        SET
            student_code = CASE
                WHEN p_data ? 'student_code'
                THEN p_data ->> 'student_code'
                ELSE student_code
            END,

            student_name = CASE
                WHEN p_data ? 'student_name'
                THEN p_data ->> 'student_name'
                ELSE student_name
            END,

            class_name = CASE
                WHEN p_data ? 'class_name'
                THEN p_data ->> 'class_name'
                ELSE class_name
            END,

            title = CASE
                WHEN p_data ? 'title'
                THEN p_data ->> 'title'
                ELSE title
            END,

            supervisor_name = CASE
                WHEN p_data ? 'supervisor_name'
                THEN p_data ->> 'supervisor_name'
                ELSE supervisor_name
            END,

            department_name = CASE
                WHEN p_data ? 'department_name'
                THEN p_data ->> 'department_name'
                ELSE department_name
            END,

            field_id = CASE
                WHEN p_data ? 'field_id'
                THEN NULLIF(
                    p_data ->> 'field_id', ''
                )::UUID
                ELSE field_id
            END,

            year = CASE
                WHEN p_data ? 'year'
                THEN NULLIF(
                    p_data ->> 'year', ''
                )::INTEGER
                ELSE year
            END,

            description = CASE
                WHEN p_data ? 'description'
                THEN p_data ->> 'description'
                ELSE description
            END,

            approach = CASE
                WHEN p_data ? 'approach'
                THEN p_data ->> 'approach'
                ELSE approach
            END,

            technologies = CASE
                WHEN p_data ? 'technologies'
                THEN ARRAY(
                    SELECT jsonb_array_elements_text(
                        p_data -> 'technologies'
                    )
                )
                ELSE technologies
            END

        WHERE id = p_project_id
        RETURNING id INTO v_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Project not found';
        END IF;

    END IF;

    RETURN v_id;
END;
$$;

REVOKE ALL
ON FUNCTION public.save_repository_project(JSONB, UUID)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.save_repository_project(JSONB, UUID)
TO authenticated;

-- ============================================================
-- 12. RPC DUYET VA CONG BO DO AN
-- ============================================================

CREATE FUNCTION public.review_project(
    p_project_id UUID,
    p_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.can_manage_projects() THEN
        RAISE EXCEPTION 'Permission denied'
            USING ERRCODE = '42501';
    END IF;

    IF p_status IS NULL OR
       p_status NOT IN (
           'pending',
           'published',
           'rejected'
       )
    THEN
        RAISE EXCEPTION 'Invalid project status';
    END IF;

    UPDATE public.projects
    SET
        status = p_status,

        reviewed_by = CASE
            WHEN p_status = 'pending' THEN NULL
            ELSE auth.uid()
        END,

        reviewed_at = CASE
            WHEN p_status = 'pending' THEN NULL
            ELSE NOW()
        END

    WHERE id = p_project_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Project not found';
    END IF;
END;
$$;

REVOKE ALL
ON FUNCTION public.review_project(UUID, TEXT)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.review_project(UUID, TEXT)
TO authenticated;

-- ============================================================
-- 13. RPC DOC DAY DU DU LIEU KHO
-- Chi lecturer/admin duoc xem thong tin lich su.
-- ============================================================

CREATE FUNCTION public.get_repository_projects()
RETURNS SETOF public.projects
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.can_manage_projects() THEN
        RAISE EXCEPTION 'Permission denied'
            USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT p.*
    FROM public.projects AS p
    ORDER BY p.created_at DESC;
END;
$$;

REVOKE ALL
ON FUNCTION public.get_repository_projects()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.get_repository_projects()
TO authenticated;

-- ============================================================
-- 14. RLS CHO FAVORITES
-- ============================================================

CREATE POLICY favorites_select_own
ON public.favorites
FOR SELECT
TO authenticated
USING (
    user_id = (SELECT auth.uid())
);

CREATE POLICY favorites_insert_own
ON public.favorites
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = (SELECT auth.uid())
    AND (SELECT public.get_my_role()) = 'student'
    AND EXISTS (
        SELECT 1
        FROM public.projects AS p
        WHERE p.id = project_id
          AND p.status = 'published'
    )
);

CREATE POLICY favorites_delete_own
ON public.favorites
FOR DELETE
TO authenticated
USING (
    user_id = (SELECT auth.uid())
);

-- ============================================================
-- 15. VIEW DU LIEU DANH CHO AI
-- Chi lay do an da cong bo.
-- Khong lay thong tin ca nhan.
-- ============================================================

CREATE VIEW public.ai_published_projects
WITH (security_invoker = TRUE)
AS
SELECT
    p.id,
    p.title,
    p.description,
    p.approach,
    p.technologies,
    p.field_id,
    f.name AS field_name
FROM public.projects AS p
LEFT JOIN public.fields AS f
    ON f.id = p.field_id
WHERE p.status = 'published';

REVOKE ALL ON public.ai_published_projects
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.ai_published_projects
TO authenticated, service_role;

COMMIT;
