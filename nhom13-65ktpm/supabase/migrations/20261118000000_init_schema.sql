-- ============================================================================
-- TLU PeerLearn - Initial Database Schema (PostgreSQL / Supabase)
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. Tài khoản & Học phần (ACC)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    student_id TEXT UNIQUE,
    faculty TEXT,
    class_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID REFERENCES public.ck_programs(id) ON DELETE SET NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    credits INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. Đăng ký tham gia chương trình (ACC-04, ACC-05, ACC-06)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_program_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES public.ck_courses(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('mentor', 'mentee')),
    course_grade NUMERIC(4,2), -- Điểm tổng kết môn (cho Mentor, thang 10)
    strengths_or_needs TEXT,   -- Thế mạnh (Mentor) hoặc khó khăn (Mentee)
    max_mentees INTEGER DEFAULT 5,
    available_slots INTEGER[] NOT NULL DEFAULT '{}', -- Mảng 0..20 (7 ngày x 3 buổi)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, course_id) -- BR-01: Mỗi học phần chỉ giữ 1 vai trò
);

-- ----------------------------------------------------------------------------
-- 3. Phòng học & Kết nối (ROM)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_study_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES public.ck_courses(id) ON DELETE CASCADE,
    mentor_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    room_code TEXT UNIQUE NOT NULL,
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_room_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('mentor', 'mentee')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.ck_room_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('invite', 'request')), -- Mentor mời hoặc Mentee xin vào
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. Kho học liệu (DOC)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('pdf', 'docx')),
    file_size BIGINT NOT NULL CHECK (file_size <= 5242880), -- BR-04: <= 5MB
    topic TEXT,
    uploaded_by UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 5. Nội dung AI tạo ra (AI)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_generated_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('flashcard', 'quiz')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('basic', 'medium', 'advanced')),
    topic TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')), -- BR-06
    version INTEGER NOT NULL DEFAULT 1, -- BR-07
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.ck_generated_set_documents (
    set_id UUID NOT NULL REFERENCES public.ck_generated_sets(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES public.ck_documents(id) ON DELETE CASCADE,
    PRIMARY KEY (set_id, document_id)
);

CREATE TABLE IF NOT EXISTS public.ck_flashcards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID NOT NULL REFERENCES public.ck_generated_sets(id) ON DELETE CASCADE,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    explanation TEXT,
    topic TEXT,
    difficulty TEXT,
    order_index INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.ck_quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID UNIQUE NOT NULL REFERENCES public.ck_generated_sets(id) ON DELETE CASCADE,
    time_limit_minutes INTEGER DEFAULT 15,
    total_questions INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.ck_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.ck_quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL, -- Mảng 4 phương án ["A...", "B...", "C...", "D..."]
    correct_index INTEGER NOT NULL CHECK (correct_index >= 0 AND correct_index <= 3),
    explanation TEXT,
    topic TEXT,
    difficulty TEXT,
    order_index INTEGER NOT NULL DEFAULT 0
);

-- ----------------------------------------------------------------------------
-- 6. Ôn tập & Thống kê (PRA)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.ck_quizzes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    score NUMERIC(4,2) NOT NULL, -- Thang điểm 10
    correct_count INTEGER NOT NULL,
    total_count INTEGER NOT NULL,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_attempt_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES public.ck_quiz_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.ck_questions(id) ON DELETE CASCADE,
    selected_index INTEGER NOT NULL,
    is_correct BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS public.ck_flashcard_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES public.ck_flashcards(id) ON DELETE CASCADE,
    is_remembered BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, flashcard_id)
);

-- ----------------------------------------------------------------------------
-- 7. Buổi học & Minh chứng (SES)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ck_learning_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    planned_sessions INTEGER NOT NULL DEFAULT 1,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_tutoring_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.ck_study_rooms(id) ON DELETE CASCADE,
    mentor_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    mode TEXT NOT NULL CHECK (mode IN ('offline', 'online')),
    location_or_link TEXT,
    planned_content TEXT,
    actual_duration_minutes INTEGER,
    guided_content TEXT,
    outcomes TEXT,
    issues TEXT,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ck_session_attendances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.ck_tutoring_sessions(id) ON DELETE CASCADE,
    mentee_id UUID NOT NULL REFERENCES public.ck_profiles(id) ON DELETE CASCADE,
    mentor_marked_status TEXT NOT NULL DEFAULT 'absent' CHECK (mentor_marked_status IN ('present', 'absent')),
    mentee_confirmed BOOLEAN NOT NULL DEFAULT FALSE, -- BR-09, BR-10: Độc lập
    mentee_confirmed_at TIMESTAMPTZ,
    UNIQUE (session_id, mentee_id)
);

CREATE TABLE IF NOT EXISTS public.ck_session_evidences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.ck_tutoring_sessions(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. Storage Buckets
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) VALUES ('room-ck_documents', 'room-ck_documents', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('session-evidences', 'session-evidences', true) ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 9. Basic Row Level Security (RLS)
-- ----------------------------------------------------------------------------
ALTER TABLE public.ck_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_program_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_study_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_room_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_generated_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_flashcard_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_learning_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_tutoring_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_session_attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ck_session_evidences ENABLE ROW LEVEL SECURITY;

-- Policies cơ bản cho phép người dùng đã đăng nhập thao tác trong giai đoạn phát triển
-- (Sẽ siết chặt chi tiết theo từng module nếu cần)
CREATE POLICY "Authenticated users can read ck_profiles" ON public.ck_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own profile" ON public.ck_profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.ck_profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Anyone authenticated can read ck_programs" ON public.ck_programs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anyone authenticated can read ck_courses" ON public.ck_courses FOR SELECT TO authenticated USING (true);

