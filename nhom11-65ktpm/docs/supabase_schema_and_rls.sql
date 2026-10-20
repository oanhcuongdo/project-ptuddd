-- ============================================================================
-- HỆ THỐNG QUẢN LÝ TÀI LIỆU HỌC TẬP (FLUTTER + FIREBASE + SUPABASE)
-- SQL SCHEMA VÀ CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- Nhóm thực hiện: Nhóm 11
-- ============================================================================

-- 1. BẢNG HỒ SƠ NGƯỜI DÙNG (PROFILES)
-- Liên kết định danh người dùng từ Firebase Auth / Supabase Auth
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,                       -- User UID (từ Firebase Auth hoặc Supabase Auth)
    email TEXT NOT NULL UNIQUE,                -- Email người dùng (vd: sinhvien@gmail.com)
    display_name TEXT,                         -- Tên hiển thị / Họ tên sinh viên
    avatar_url TEXT,                           -- Ảnh đại diện Google
    role TEXT DEFAULT 'STUDENT',               -- Vai trò: STUDENT, LECTURER, ADMIN
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index tìm kiếm người dùng nhanh theo email khi chia sẻ tài liệu
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ----------------------------------------------------------------------------
-- 2. BẢNG TÀI LIỆU HỌC TẬP (DOCUMENTS)
-- Lưu trữ metadata và thông tin tài liệu học tập
CREATE TABLE IF NOT EXISTS public.documents (
    id TEXT PRIMARY KEY,                       -- UUID tài liệu
    owner_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,                       -- Tiêu đề tài liệu
    doc_type TEXT NOT NULL DEFAULT 'LECTURE',  -- LECTURE (Bài giảng), EXERCISE (Bài tập), REFERENCE (Tham khảo), EXAM (Đề thi)
    content TEXT,                              -- Nội dung ghi chú, tóm tắt tài liệu
    file_url TEXT,                             -- Đường dẫn tệp tải về (Supabase Storage / URL tài liệu)
    subject_code TEXT,                         -- Mã môn học (vd: IT001, CS101)
    subject_name TEXT,                         -- Tên môn học (vd: Cấu trúc Dữ liệu & Giải thuật)
    priority INTEGER DEFAULT 0,                -- Độ ưu tiên (0: Bình thường, 1: Cao, 2: Khẩn cấp)
    status TEXT DEFAULT 'NOT_STARTED',         -- NOT_STARTED, IN_PROGRESS, COMPLETED
    is_public BOOLEAN DEFAULT FALSE,           -- Tài liệu công khai toàn trường hay không
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes tối ưu truy vấn danh sách và tìm kiếm
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_subject ON public.documents(subject_code);
CREATE INDEX IF NOT EXISTS idx_documents_title ON public.documents(title);

-- ----------------------------------------------------------------------------
-- 3. BẢNG PHÂN QUYỀN CHIA SẺ TÀI LIỆU (DOCUMENT_PERMISSIONS)
-- Lưu quyền truy cập của người dùng khác đối với tài liệu
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id TEXT PRIMARY KEY,                       -- UUID quyền
    document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_with_email TEXT NOT NULL,           -- Email người được chia sẻ
    permission_level TEXT NOT NULL CHECK (permission_level IN ('VIEW', 'EDIT')),
                                               -- VIEW: Chỉ xem tài liệu
                                               -- EDIT: Được sửa tiêu đề, nội dung, file_url
    granted_by TEXT NOT NULL REFERENCES public.profiles(id), -- Người cấp quyền (Owner)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_doc_user_permission UNIQUE (document_id, shared_with_email)
);

CREATE INDEX IF NOT EXISTS idx_permissions_doc ON public.document_permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_permissions_email ON public.document_permissions(shared_with_email);

-- ============================================================================
-- 4. KÍCH HOẠT CHÍNH SÁCH BẢO MẬT CẤP HÀNG (ROW LEVEL SECURITY - RLS)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- A. CHÍNH SÁCH RLS CHO BẢNG PROFILES
-- ----------------------------------------------------------------------------

-- Mọi người dùng đã đăng nhập đều có thể đọc profiles (để tìm kiếm email khi chia sẻ)
DROP POLICY IF EXISTS "Authenticated users can read profiles" ON public.profiles;
CREATE POLICY "Authenticated users can read profiles" ON public.profiles
    FOR SELECT
    USING (true);

-- Người dùng chỉ được sửa thông tin hồ sơ của chính mình
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE
    USING (auth.uid()::text = id OR auth.jwt()->>'email' = email);

-- Tự động thêm hồ sơ khi đăng nhập
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid()::text = id OR auth.jwt()->>'email' = email);

-- ----------------------------------------------------------------------------
-- B. CHÍNH SÁCH RLS CHO BẢNG DOCUMENTS
-- ----------------------------------------------------------------------------

-- 1. SELECT (Đọc tài liệu):
-- Sinh viên đọc được nếu:
-- (a) Là chủ sở hữu (Owner) của tài liệu
-- (b) HOẶC tài liệu là công khai (is_public = true)
-- (c) HOẶC tài liệu đã được cấp quyền chia sẻ trong bảng document_permissions (dù là VIEW hay EDIT)
DROP POLICY IF EXISTS "Users can view accessible documents" ON public.documents;
CREATE POLICY "Users can view accessible documents" ON public.documents
    FOR SELECT
    USING (
        owner_id = auth.uid()::text
        OR is_public = true
        OR EXISTS (
            SELECT 1 FROM public.document_permissions p
            WHERE p.document_id = documents.id
            AND (
                p.shared_with_email = auth.jwt()->>'email'
                OR p.shared_with_email = (SELECT email FROM public.profiles WHERE id = auth.uid()::text)
            )
        )
    );

-- 2. INSERT (Tạo tài liệu mới):
-- Người dùng chỉ được tạo tài liệu mà chính mình là Owner
DROP POLICY IF EXISTS "Users can insert own documents" ON public.documents;
CREATE POLICY "Users can insert own documents" ON public.documents
    FOR INSERT
    WITH CHECK (owner_id = auth.uid()::text);

-- 3. UPDATE (Cập nhật tài liệu):
-- Sinh viên chỉ được sửa tài liệu nếu:
-- (a) Là chủ sở hữu (Owner)
-- (b) HOẶC có quyền 'EDIT' trong bảng document_permissions
DROP POLICY IF EXISTS "Owners and editors can update documents" ON public.documents;
CREATE POLICY "Owners and editors can update documents" ON public.documents
    FOR UPDATE
    USING (
        owner_id = auth.uid()::text
        OR EXISTS (
            SELECT 1 FROM public.document_permissions p
            WHERE p.document_id = documents.id
            AND (
                p.shared_with_email = auth.jwt()->>'email'
                OR p.shared_with_email = (SELECT email FROM public.profiles WHERE id = auth.uid()::text)
            )
            AND p.permission_level = 'EDIT'
        )
    );

-- 4. DELETE (Xóa tài liệu):
-- CHỈ DUY NHẤT chủ sở hữu (Owner) mới có quyền xóa tài liệu
DROP POLICY IF EXISTS "Only owners can delete documents" ON public.documents;
CREATE POLICY "Only owners can delete documents" ON public.documents
    FOR DELETE
    USING (owner_id = auth.uid()::text);

-- ----------------------------------------------------------------------------
-- C. CHÍNH SÁCH RLS CHO BẢNG DOCUMENT_PERMISSIONS
-- ----------------------------------------------------------------------------

-- 1. SELECT (Xem danh sách quyền):
-- Chỉ xem được quyền nếu là Owner của tài liệu HOẶC là người được nhận quyền
DROP POLICY IF EXISTS "View permissions for owners and grantees" ON public.document_permissions;
CREATE POLICY "View permissions for owners and grantees" ON public.document_permissions
    FOR SELECT
    USING (
        granted_by = auth.uid()::text
        OR shared_with_email = auth.jwt()->>'email'
        OR EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = document_id AND d.owner_id = auth.uid()::text
        )
    );

-- 2. INSERT / UPDATE / DELETE (Cấp, sửa, thu hồi quyền):
-- CHỈ DUY NHẤT chủ sở hữu (Owner) của tài liệu mới có quyền quản lý chia sẻ
DROP POLICY IF EXISTS "Only document owners can manage permissions" ON public.document_permissions;
CREATE POLICY "Only document owners can manage permissions" ON public.document_permissions
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = document_id AND d.owner_id = auth.uid()::text
        )
    );

-- ============================================================================
-- 5. DỮ LIỆU MẪU KIỂM THỬ CHO 3 TÀI KHOẢN NGƯỜI DÙNG (TEST DATA)
-- ============================================================================

-- Thêm 3 tài khoản người dùng mẫu:
INSERT INTO public.profiles (id, email, display_name, role)
VALUES
    ('user-alice-uid-001', 'alice@nhom11.edu.vn', 'Nguyễn Thị Alice (Chủ sở hữu)', 'STUDENT'),
    ('user-bob-uid-002',   'bob@nhom11.edu.vn',   'Trần Văn Bob (Người sửa - Editor)', 'STUDENT'),
    ('user-charlie-uid-003','charlie@nhom11.edu.vn','Lê Văn Charlie (Người xem - Viewer)', 'STUDENT')
ON CONFLICT (id) DO NOTHING;

-- Alice tạo 2 tài liệu:
INSERT INTO public.documents (id, owner_id, title, doc_type, content, file_url, subject_code, subject_name, priority, status)
VALUES
    ('doc-001', 'user-alice-uid-001', 'Bài giảng Giải tích 1 - Đạo hàm và Tích phân', 'LECTURE', 'Tóm tắt công thức vi phân, tích phân suy rộng và chuỗi số.', 'https://nhom11.supabase.co/storage/v1/object/public/study-documents/giai_tich_1.pdf', 'MATH101', 'Giải tích 1', 2, 'IN_PROGRESS'),
    ('doc-002', 'user-alice-uid-001', 'Đề cương Cấu trúc Dữ liệu & Giải thuật', 'REFERENCE', 'Cây nhị phân tìm kiếm, Đồ thị BFS/DFS, Quy hoạch động.', 'https://nhom11.supabase.co/storage/v1/object/public/study-documents/dsa_review.pdf', 'CS102', 'Cấu trúc dữ liệu & Giải thuật', 1, 'NOT_STARTED')
ON CONFLICT (id) DO NOTHING;

-- Alice cấp quyền:
-- 1. Chia sẻ doc-001 cho Bob với quyền EDIT (Bob được xem và sửa nội dung)
-- 2. Chia sẻ doc-001 cho Charlie với quyền VIEW (Charlie chỉ được xem, không được sửa)
-- 3. doc-002 Alice giữ bí mật cá nhân (không chia sẻ cho ai)
INSERT INTO public.document_permissions (id, document_id, shared_with_email, permission_level, granted_by)
VALUES
    ('perm-001', 'doc-001', 'bob@nhom11.edu.vn', 'EDIT', 'user-alice-uid-001'),
    ('perm-002', 'doc-001', 'charlie@nhom11.edu.vn', 'VIEW', 'user-alice-uid-001')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- KẾT THÚC SCRIPT SCHEMA VÀ RLS POLICIES
-- ============================================================================
