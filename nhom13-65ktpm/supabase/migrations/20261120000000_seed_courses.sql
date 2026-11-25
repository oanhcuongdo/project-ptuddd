-- ============================================================================
-- Seed Data: Chương trình & Học phần phổ biến (Đại học Thủy Lợi - CNTT/KTPM)
-- ============================================================================

INSERT INTO public.ck_programs (id, name, description, is_active)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'TLU Đồng hành học tập – Sinh viên hỗ trợ sinh viên',
    'Chương trình kết nối Mentor – Mentee hỗ trợ học tập theo từng học phần tại Trường Đại học Thủy Lợi.',
    TRUE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.ck_courses (program_id, code, name, credits) VALUES
    ('11111111-1111-1111-1111-111111111111', 'CSE101', 'Nhập môn lập trình', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE102', 'Toán rời rạc', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE202', 'Cấu trúc dữ liệu và Giải thuật', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE204', 'Cơ sở dữ liệu', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE301', 'Lập trình hướng đối tượng (Java)', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE302', 'Hệ điều hành', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE305', 'Mạng máy tính', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE401', 'Công nghệ phần mềm', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE412', 'An toàn và bảo mật thông tin', 3),
    ('11111111-1111-1111-1111-111111111111', 'CSE441', 'Phát triển ứng dụng di động', 3)
ON CONFLICT (code) DO NOTHING;

