
-- ============================================================
-- MIGRATION 04: PLANNING PROGRESS
-- Du an: PTUDDD - Nhom 14 - 65KTPM
-- ============================================================

BEGIN;

-- ============================================================
-- 1. BANG KE HOACH
-- ============================================================

CREATE TABLE public.plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    personal_topic_id UUID NOT NULL
        REFERENCES public.personal_topics(id)
        ON DELETE RESTRICT,

    title TEXT NOT NULL
        CHECK (btrim(title) <> ''),

    description TEXT,

    start_date DATE,

    end_date DATE,

    status TEXT NOT NULL DEFAULT 'active'
        CHECK (
            status IN (
                'active',
                'completed',
                'archived'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT plans_valid_dates
        CHECK (
            start_date IS NULL
            OR end_date IS NULL
            OR end_date >= start_date
        )
);

-- ============================================================
-- 2. BANG CONG VIEC
-- ============================================================

CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    plan_id UUID NOT NULL
        REFERENCES public.plans(id)
        ON DELETE CASCADE,

    phase TEXT,

    title TEXT NOT NULL
        CHECK (btrim(title) <> ''),

    description TEXT,

    due_date DATE,

    status TEXT NOT NULL DEFAULT 'todo'
        CHECK (
            status IN (
                'todo',
                'in_progress',
                'done'
            )
        ),

    order_index INTEGER NOT NULL DEFAULT 0
        CHECK (order_index >= 0),

    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT tasks_completion_consistency
        CHECK (
            (
                status = 'done'
                AND completed_at IS NOT NULL
            )
            OR
            (
                status <> 'done'
                AND completed_at IS NULL
            )
        )
);

-- ============================================================
-- 3. INDEX HO TRO TRUY VAN
-- ============================================================

CREATE INDEX idx_plans_personal_topic_id
ON public.plans(personal_topic_id);

CREATE INDEX idx_plans_topic_status
ON public.plans(personal_topic_id, status);

CREATE INDEX idx_tasks_plan_id
ON public.tasks(plan_id);

CREATE INDEX idx_tasks_plan_status
ON public.tasks(plan_id, status);

CREATE INDEX idx_tasks_plan_order
ON public.tasks(plan_id, order_index);

-- ============================================================
-- 4. TU DONG CAP NHAT UPDATED_AT
-- ============================================================

CREATE TRIGGER plans_set_updated_at
BEFORE UPDATE ON public.plans
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER tasks_set_updated_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 5. TU DONG CAP NHAT COMPLETED_AT
-- ============================================================

CREATE FUNCTION public.sync_task_completed_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.status = 'done' THEN

        IF TG_OP = 'INSERT' THEN
            NEW.completed_at := NOW();

        ELSIF OLD.status IS DISTINCT FROM 'done' THEN
            NEW.completed_at := NOW();

        ELSE
            NEW.completed_at := COALESCE(
                OLD.completed_at,
                NOW()
            );
        END IF;

    ELSE
        NEW.completed_at := NULL;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tasks_sync_completed_at
BEFORE INSERT OR UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.sync_task_completed_at();

REVOKE ALL
ON FUNCTION public.sync_task_completed_at()
FROM PUBLIC, anon, authenticated;

-- ============================================================
-- 6. FUNCTION KIEM TRA QUYEN SO HUU DE TAI
-- ============================================================

CREATE FUNCTION public.owns_personal_topic(
    p_topic_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.personal_topics AS pt
        WHERE pt.id = p_topic_id
          AND pt.user_id = auth.uid()
          AND public.get_my_role() = 'student'
    );
$$;

REVOKE ALL
ON FUNCTION public.owns_personal_topic(UUID)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.owns_personal_topic(UUID)
TO authenticated;

-- ============================================================
-- 7. FUNCTION KIEM TRA QUYEN SO HUU KE HOACH
-- ============================================================

CREATE FUNCTION public.owns_plan(
    p_plan_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.plans AS p
        WHERE p.id = p_plan_id
          AND public.owns_personal_topic(
              p.personal_topic_id
          )
    );
$$;

REVOKE ALL
ON FUNCTION public.owns_plan(UUID)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.owns_plan(UUID)
TO authenticated;

-- ============================================================
-- 8. BAT ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.plans
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.tasks
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 9. THIET LAP QUYEN TRUY CAP
-- ============================================================

REVOKE ALL ON TABLE
    public.plans,
    public.tasks
FROM PUBLIC, anon, authenticated;

-- Quyen doc va xoa ke hoach

GRANT SELECT, DELETE
ON public.plans
TO authenticated;

-- Quyen tao ke hoach

GRANT INSERT (
    personal_topic_id,
    title,
    description,
    start_date,
    end_date,
    status
)
ON public.plans
TO authenticated;

-- Quyen cap nhat ke hoach

GRANT UPDATE (
    personal_topic_id,
    title,
    description,
    start_date,
    end_date,
    status
)
ON public.plans
TO authenticated;

-- Quyen doc va xoa cong viec

GRANT SELECT, DELETE
ON public.tasks
TO authenticated;

-- Quyen tao cong viec

GRANT INSERT (
    plan_id,
    phase,
    title,
    description,
    due_date,
    status,
    order_index
)
ON public.tasks
TO authenticated;

-- Quyen cap nhat cong viec

GRANT UPDATE (
    plan_id,
    phase,
    title,
    description,
    due_date,
    status,
    order_index
)
ON public.tasks
TO authenticated;

GRANT ALL ON TABLE
    public.plans,
    public.tasks
TO service_role;

-- ============================================================
-- 10. RLS CHO BANG PLANS
-- ============================================================

CREATE POLICY plans_select_own
ON public.plans
FOR SELECT
TO authenticated
USING (
    public.owns_personal_topic(personal_topic_id)
);

CREATE POLICY plans_insert_own
ON public.plans
FOR INSERT
TO authenticated
WITH CHECK (
    public.owns_personal_topic(personal_topic_id)
);

CREATE POLICY plans_update_own
ON public.plans
FOR UPDATE
TO authenticated
USING (
    public.owns_personal_topic(personal_topic_id)
)
WITH CHECK (
    public.owns_personal_topic(personal_topic_id)
);

CREATE POLICY plans_delete_own
ON public.plans
FOR DELETE
TO authenticated
USING (
    public.owns_personal_topic(personal_topic_id)
);

-- ============================================================
-- 11. RLS CHO BANG TASKS
-- ============================================================

CREATE POLICY tasks_select_own
ON public.tasks
FOR SELECT
TO authenticated
USING (
    public.owns_plan(plan_id)
);

CREATE POLICY tasks_insert_own
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
    public.owns_plan(plan_id)
);

CREATE POLICY tasks_update_own
ON public.tasks
FOR UPDATE
TO authenticated
USING (
    public.owns_plan(plan_id)
)
WITH CHECK (
    public.owns_plan(plan_id)
);

CREATE POLICY tasks_delete_own
ON public.tasks
FOR DELETE
TO authenticated
USING (
    public.owns_plan(plan_id)
);

-- ============================================================
-- 12. VIEW TINH TIEN DO KE HOACH
-- ============================================================

CREATE VIEW public.plan_progress
WITH (security_invoker = TRUE)
AS
SELECT
    p.id AS plan_id,

    COUNT(t.id) AS total_tasks,

    COUNT(t.id) FILTER (
        WHERE t.status = 'done'
    ) AS completed_tasks,

    CASE
        WHEN COUNT(t.id) = 0 THEN 0::NUMERIC

        ELSE ROUND(
            100.0 *
            COUNT(t.id) FILTER (
                WHERE t.status = 'done'
            )
            / COUNT(t.id),
            2
        )
    END AS progress_percent

FROM public.plans AS p

LEFT JOIN public.tasks AS t
    ON t.plan_id = p.id

GROUP BY p.id;

REVOKE ALL ON public.plan_progress
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.plan_progress
TO authenticated, service_role;

COMMIT;
