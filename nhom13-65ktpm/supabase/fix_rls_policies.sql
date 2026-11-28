-- ============================================================================
-- Fix RLS Policies cho toàn bộ các bảng ck_* (chạy 1 lần trên SQL Editor)
-- ============================================================================

DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'ck_generated_sets',
        'ck_generated_set_documents',
        'ck_questions',
        'ck_flashcards',
        'ck_quizzes',
        'ck_quiz_attempts',
        'ck_room_documents',
        'ck_tutoring_sessions',
        'ck_session_attendances',
        'ck_session_evidences'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        IF to_regclass('public.' || tbl) IS NOT NULL THEN
            EXECUTE format('DROP POLICY IF EXISTS "authenticated_all_%s" ON public.%I;', tbl, tbl);
            EXECUTE format(
                'CREATE POLICY "authenticated_all_%s" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true);',
                tbl, tbl
            );
        END IF;
    END LOOP;
END $$;

