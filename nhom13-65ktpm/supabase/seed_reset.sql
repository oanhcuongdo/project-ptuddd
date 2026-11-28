-- ============================================================================
-- Seed Reset: 1 Admin, 3 Mentors, 5 Mentees, Học phần & 2 Phòng học mẫu
-- Mật khẩu chung cho tất cả tài khoản: 123456
-- Có thể chạy lại nhiều lần để reset dữ liệu test.
-- ============================================================================

-- 1. Xóa dữ liệu phòng học & tài khoản seed cũ
DELETE FROM public.ck_study_rooms
WHERE id IN ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2');

DELETE FROM auth.users
WHERE email IN (
    'admin.tlu@gmail.com',
    'mentor01.tlu@gmail.com', 'mentor02.tlu@gmail.com', 'mentor03.tlu@gmail.com',
    'mentee01.tlu@gmail.com', 'mentee02.tlu@gmail.com', 'mentee03.tlu@gmail.com',
    'mentee04.tlu@gmail.com', 'mentee05.tlu@gmail.com'
);

-- 2. Tạo 9 tài khoản (1 Admin, 3 Mentor, 5 Mentee)
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_token, recovery_token,
    email_change_token_new, email_change,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa0', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin.tlu@gmail.com',    extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Quản trị viên TLU"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentor01.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Phùng Minh Anh"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentor02.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Ngô Tuấn Anh"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentor03.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Nguyễn Đình Tuấn Sơn"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentee01.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Phạm Văn Phước"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentee02.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Trần Thị Bích"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentee03.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Lê Hoàng Nam"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentee04.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Nguyễn Thu Hà"}', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa8', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mentee05.tlu@gmail.com', extensions.crypt('123456', extensions.gen_salt('bf')), NOW(), '', '', '', '', '{"provider":"email","providers":["email"]}', '{"full_name":"Đỗ Quang Minh"}', NOW(), NOW());

INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT id, id, id::text, jsonb_build_object('sub', id::text, 'email', email), 'email', NOW(), NOW(), NOW()
FROM auth.users
WHERE email IN (
    'admin.tlu@gmail.com',
    'mentor01.tlu@gmail.com', 'mentor02.tlu@gmail.com', 'mentor03.tlu@gmail.com',
    'mentee01.tlu@gmail.com', 'mentee02.tlu@gmail.com', 'mentee03.tlu@gmail.com',
    'mentee04.tlu@gmail.com', 'mentee05.tlu@gmail.com'
);

-- 3. Cập nhật hồ sơ ck_profiles
INSERT INTO public.ck_profiles (id, email, full_name, student_id, faculty, class_name, role)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa0', 'admin.tlu@gmail.com',    'Quản trị viên TLU',    NULL,         'Khoa CNTT', 'Admin',    'admin'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'mentor01.tlu@gmail.com', 'Phùng Minh Anh',       '2351170574', 'Khoa CNTT', '65KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'mentor02.tlu@gmail.com', 'Ngô Tuấn Anh',         '2351170570', 'Khoa CNTT', '65KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'mentor03.tlu@gmail.com', 'Nguyễn Đình Tuấn Sơn', '2351170616', 'Khoa CNTT', '65KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', 'mentee01.tlu@gmail.com', 'Phạm Văn Phước',       '2251172456', 'Khoa CNTT', '64KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5', 'mentee02.tlu@gmail.com', 'Trần Thị Bích',        '2351170601', 'Khoa CNTT', '65KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6', 'mentee03.tlu@gmail.com', 'Lê Hoàng Nam',         '2351170602', 'Khoa CNTT', '65KTPM',   'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7', 'mentee04.tlu@gmail.com', 'Nguyễn Thu Hà',        '2351170603', 'Khoa CNTT', '65CNTT1',  'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa8', 'mentee05.tlu@gmail.com', 'Đỗ Quang Minh',        '2351170604', 'Khoa CNTT', '65CNTT2',  'student')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    student_id = EXCLUDED.student_id,
    faculty = EXCLUDED.faculty,
    class_name = EXCLUDED.class_name,
    role = EXCLUDED.role;

-- 4. Đăng ký học phần & lịch rảnh (lấy 2 học phần đầu tiên trong ck_courses)
INSERT INTO public.ck_program_registrations (user_id, course_id, role, course_grade, max_mentees, available_slots)
WITH c AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY code) AS rn FROM public.ck_courses LIMIT 2
)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1'::uuid, id, 'mentor', 9.2, 4, ARRAY[0,1,3,4,6,7] FROM c WHERE rn = 1
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2'::uuid, id, 'mentor', 8.9, 3, ARRAY[0,2,4,6,8,10] FROM c WHERE rn = 2
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3'::uuid, id, 'mentor', 8.7, 3, ARRAY[1,3,5,7,9] FROM c WHERE rn = 1
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4'::uuid, id, 'mentee', NULL::numeric, 1, ARRAY[0,1,3,6,7] FROM c WHERE rn = 1
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5'::uuid, id, 'mentee', NULL::numeric, 1, ARRAY[0,1,4,6] FROM c WHERE rn = 1
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6'::uuid, id, 'mentee', NULL::numeric, 1, ARRAY[0,2,4,8] FROM c WHERE rn = 2
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7'::uuid, id, 'mentee', NULL::numeric, 1, ARRAY[1,3,5,7] FROM c WHERE rn = 1
UNION ALL
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa8'::uuid, id, 'mentee', NULL::numeric, 1, ARRAY[0,2,6,10] FROM c WHERE rn = 2;

-- 5. Tạo sẵn 2 phòng học mẫu
INSERT INTO public.ck_study_rooms (id, course_id, mentor_id, name, description, room_code, is_open)
WITH c AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY code) AS rn FROM public.ck_courses LIMIT 2
)
SELECT 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1'::uuid, id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1'::uuid, 'Nhóm Ôn Tập 01', 'Phòng học mẫu môn 1', 'TLU001', true FROM c WHERE rn = 1
UNION ALL
SELECT 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2'::uuid, id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2'::uuid, 'Nhóm Ôn Tập 02', 'Phòng học mẫu môn 2', 'TLU002', true FROM c WHERE rn = 2;

INSERT INTO public.ck_room_members (room_id, user_id, role)
VALUES
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'mentor'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', 'mentee'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5', 'mentee'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'mentor'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6', 'mentee');

