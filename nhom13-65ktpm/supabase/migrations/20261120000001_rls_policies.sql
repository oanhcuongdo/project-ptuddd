-- ============================================================================
-- RLS Policies cho các bảng nghiệp vụ (tránh lỗi 42501 khi thao tác từ client)
-- ============================================================================

-- 1. ck_program_registrations: Sinh viên tự xem/thêm/sửa/xóa đăng ký của mình, hoặc đọc danh sách để ghép cặp
CREATE POLICY "Authenticated can read registrations" ON public.ck_program_registrations
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert own registration" ON public.ck_program_registrations
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own registration" ON public.ck_program_registrations
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own registration" ON public.ck_program_registrations
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 2. ck_study_rooms, ck_room_members, ck_room_invitations (ROM)
CREATE POLICY "Authenticated can read rooms" ON public.ck_study_rooms
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "Mentor can create room" ON public.ck_study_rooms
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = mentor_id);
CREATE POLICY "Mentor can update own room" ON public.ck_study_rooms
    FOR UPDATE TO authenticated USING (auth.uid() = mentor_id);

CREATE POLICY "Authenticated can read room_members" ON public.ck_room_members
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert room_members" ON public.ck_room_members
    FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated can delete room_members" ON public.ck_room_members
    FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated can manage room_invitations" ON public.ck_room_invitations
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 3. ck_documents, ck_generated_sets, ck_flashcards, ck_quizzes, ck_questions (DOC & AI)
CREATE POLICY "Authenticated can manage documents" ON public.ck_documents
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage generated_sets" ON public.ck_generated_sets
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage flashcards" ON public.ck_flashcards
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage quizzes" ON public.ck_quizzes
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage questions" ON public.ck_questions
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4. ck_quiz_attempts, ck_attempt_answers, ck_flashcard_progress (PRA)
CREATE POLICY "Authenticated can manage quiz_attempts" ON public.ck_quiz_attempts
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage attempt_answers" ON public.ck_attempt_answers
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage flashcard_progress" ON public.ck_flashcard_progress
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 5. ck_learning_plans, ck_tutoring_sessions, ck_session_attendances, ck_session_evidences (SES)
CREATE POLICY "Authenticated can manage learning_plans" ON public.ck_learning_plans
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage tutoring_sessions" ON public.ck_tutoring_sessions
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage session_attendances" ON public.ck_session_attendances
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated can manage session_evidences" ON public.ck_session_evidences
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

