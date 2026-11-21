-- ============================================================================
-- Seed Data: 2 tài khoản Sinh viên + 1 tài khoản Admin (Mật khẩu chung: 123456)
-- ============================================================================

-- Xóa user seed cũ (nếu trước đó insert thiếu cột token/identities)
DELETE FROM auth.users
WHERE email IN ('mentor01.tlu@gmail.com', 'mentee01.tlu@gmail.com', 'admin.tlu@gmail.com');

INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_token, recovery_token,
    email_change_token_new, email_change,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
        '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'mentor01.tlu@gmail.com',
        extensions.crypt('123456', extensions.gen_salt('bf')),
        NOW(), '', '', '', '',
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Phùng Minh Anh"}',
        NOW(), NOW()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
        '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'mentee01.tlu@gmail.com',
        extensions.crypt('123456', extensions.gen_salt('bf')),
        NOW(), '', '', '', '',
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Phạm Văn Phước"}',
        NOW(), NOW()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
        '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'admin.tlu@gmail.com',
        extensions.crypt('123456', extensions.gen_salt('bf')),
        NOW(), '', '', '', '',
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Quản trị viên TLU"}',
        NOW(), NOW()
    );

INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
        '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1","email":"mentor01.tlu@gmail.com"}',
        'email', NOW(), NOW(), NOW()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
        '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2","email":"mentee01.tlu@gmail.com"}',
        'email', NOW(), NOW(), NOW()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
        '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3","email":"admin.tlu@gmail.com"}',
        'email', NOW(), NOW(), NOW()
    );

INSERT INTO public.ck_profiles (id, email, full_name, student_id, faculty, class_name, role)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'mentor01.tlu@gmail.com', 'Nguyễn A', '2351170574', 'CNTT', '65KTPM', 'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'mentee01.tlu@gmail.com', 'PNguyễn B', '2251172456', 'CNTT', '65KTPM', 'student'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'admin.tlu@gmail.com', 'Quản trị viên TLU', NULL, 'Phòng Đào tạo', NULL, 'admin')
ON CONFLICT (id) DO NOTHING;
