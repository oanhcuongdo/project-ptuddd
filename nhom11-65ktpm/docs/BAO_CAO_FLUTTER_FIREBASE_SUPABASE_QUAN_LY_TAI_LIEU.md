# BÁO CÁO BÀI TẬP LỚN
## PHÁT TRIỂN HỆ THỐNG QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG VỚI FLUTTER, FIREBASE VÀ SUPABASE

**Nhóm thực hiện:** Nhóm 11  
**Dự án Flutter:** `study_material_manager` (Package ID: `vn.nhom11.studydocs.study_material_manager`)  
**Firebase Project ID:** `study-material-nhom11` (Project Number: `693074823537`)  
**Supabase Storage Bucket & PostgreSQL Schema:** `study-documents`, `profiles`, `documents`, `document_permissions`

---

## MỤC LỤC ĐỐI CHIẾU CHECKLIST (6 MỤC)

| STT | Nội dung yêu cầu trong Checklist | Trạng thái & Giải pháp triển khai thực tế |
| :--- | :--- | :--- |
| **1** | Thiết lập dự án Firebase và tích hợp chức năng đăng nhập bằng tài khoản Google cho ứng dụng Flutter. | **Đã hoàn thành** trên project `study-material-nhom11` (`google-services.json`, `firebase_options.dart`, `AuthService`, `AuthProvider`). |
| **2** | Xây dựng cấu trúc lưu trữ file và kết nối với bảng quản lý thông tin tài liệu trên Supabase. | **Đã hoàn thành** (Sử dụng **Supabase Storage Bucket** `study-documents` miễn phí thay thế Firebase Storage trả phí Blaze Plan, liên kết trực tiếp qua trường `file_url` của bảng `documents`). |
| **3** | Thiết kế cơ sở dữ liệu trên Supabase bao gồm các bảng: Người dùng (`profiles`), Tài liệu (`documents`), và Quyền chia sẻ (`document_permissions`). | **Đã hoàn thành** trong tệp `supabase_schema_and_rls.sql` và tầng Domain Models của ứng dụng. |
| **4** | Triển khai chức năng tìm kiếm, cập nhật thông tin tài liệu và tính năng chia sẻ tài liệu cho người dùng khác. | **Đã hoàn thành** trong `SupabaseDocumentService`, `SupabaseProvider`, `CloudSharingScreen` và `ShareDocumentDialog`. |
| **5** | Thiết lập chính sách bảo mật (**Row Level Security - RLS**) trên Supabase để phân quyền truy cập tài liệu. | **Đã hoàn thành** với 11 chính sách RLS cho `SELECT`, `INSERT`, `UPDATE`, `DELETE` dựa trên vai trò `OWNER`, `EDIT`, `VIEW`. |
| **6** | Tiến hành kiểm thử (**Testing**) luồng hoạt động của ứng dụng bằng ít nhất **3 tài khoản người dùng khác nhau** để xác minh quyền hạn. | **Đã hoàn thành** kiểm thử tự động & trực quan với 3 tài khoản: **Alice** (`alice@nhom11.edu.vn`), **Bob** (`bob@nhom11.edu.vn`), **Charlie** (`charlie@nhom11.edu.vn`). |

---

## PHẦN 1. THIẾT LẬP FIREBASE & ĐĂNG NHẬP GOOGLE (CHECKLIST 1)

### 1.1. Cấu hình dự án Firebase chính chủ của Nhóm 11
Hệ thống đã được kết nối trực tiếp với dự án Firebase **`study-material-nhom11`** thông qua tệp cấu hình `android/app/google-services.json` và `lib/firebase_options.dart`:
- **Project ID:** `study-material-nhom11`
- **Project Number:** `693074823537`
- **Android Application ID:** `vn.nhom11.studydocs.study_material_manager`
- **Mobile SDK App ID:** `1:693074823537:android:cc5e21aa4b1f4c7036ff22`

### 1.2. Luồng xác thực Google Sign-In và đồng bộ hồ sơ sang Supabase
1. Người dùng nhấn nút **"Đăng nhập bằng Google"** trên giao diện ứng dụng Flutter.
2. Dịch vụ `AuthService` (`lib/domain/services/auth_service.dart`) gọi `GoogleSignIn` và `FirebaseAuth.instance.signInWithCredential()` để xác thực OAuth 2.0.
3. Ngay sau khi đăng nhập Google thành công, `SupabaseProvider.syncFromAuthUser()` tự động đồng bộ thông tin người dùng (`uid`, `email`, `displayName`, `photoURL`) vào bảng `public.profiles` trên Supabase thông qua phương thức `upsertUserProfile()`.

---

## PHẦN 2. CẤU TRÚC LƯU TRỮ FILE & KẾT NỐI VỚI BẢNG TÀI LIỆU SUPABASE (CHECKLIST 2)

### 2.1. Lý do chuyển đổi từ Firebase Storage sang Supabase Storage
Do chính sách mới của Google Cloud yêu cầu nâng cấp lên gói trả phí **Blaze Plan** (thẻ tín dụng quốc tế) mới cho phép khởi tạo Firebase Storage, nhóm đã triển khai giải pháp kiến trúc **Multi-Cloud / Hybrid BaaS hoàn toàn miễn phí**:
- **Xác thực người dùng:** Firebase Authentication (Google Sign-In).
- **Lưu trữ tệp vật lý (Object Storage):** **Supabase Storage** với Bucket định danh là `study-documents`.
- **Cơ sở dữ liệu quan hệ & Phân quyền:** **Supabase PostgreSQL** (`documents`, `document_permissions`).

### 2.2. Cấu trúc thư mục lưu trữ file và cơ chế liên kết dữ liệu
Tệp tin vật lý (PDF, DOCX, PPTX) khi tải lên bucket `study-documents` được tổ chức phân tách theo định danh chủ sở hữu (`userId`) và nhãn thời gian (`timestamp`) nhằm chống trùng lặp tên tệp:

```text
study-documents (Supabase Storage Bucket)
 ├── user-alice-uid-001/
 │    ├── 1712300100_giai_tich_1.pdf
 │    └── 1712300250_dsa_private.pdf
 └── user-bob-uid-002/
      └── 1712305900_flutter_supabase_lab.pdf
```

**Cơ chế kết nối với bảng `documents` trên Supabase (`lib/domain/services/supabase_document_service.dart`):**
1. Phương thức `uploadFileToSupabaseStorage(userId, fileName, fileBytes)` tải mảng byte của tệp lên bucket `study-documents` theo đường dẫn `$userId/${timestamp}_$fileName`.
2. Supabase Storage trả về đường dẫn định danh tĩnh (`Public/Signed URL`) thông qua `client.storage.from('study-documents').getPublicUrl(storagePath)`.
3. Đường dẫn này được lưu trực tiếp vào cột `file_url` của bảng `public.documents` khi gọi `createDocument()` hoặc `updateDocument()`.

---

## PHẦN 3. THIẾT KẾ CƠ SỞ DỮ LIỆU QUAN HỆ TRÊN SUPABASE (CHECKLIST 3)

Cơ sở dữ liệu PostgreSQL trên Supabase được thiết kế chuẩn hóa 3NF gồm **3 bảng cốt lõi** (được định nghĩa đầy đủ trong tệp `supabase_schema_and_rls.sql`):

### 3.1. Bảng 1: Người dùng (`public.profiles`)
Lưu trữ thông tin định danh người dùng đồng bộ từ Firebase Google Auth.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UID người dùng từ Firebase Auth / Supabase Auth |
| `email` | `TEXT` | `UNIQUE NOT NULL` | Địa chỉ email Google (dùng để định danh khi chia sẻ) |
| `display_name` | `TEXT` | `NOT NULL` | Họ và tên hiển thị của người dùng |
| `avatar_url` | `TEXT` | `NULL` | Đường dẫn ảnh đại diện Google |
| `role` | `TEXT` | `DEFAULT 'STUDENT'` | Vai trò hệ thống (`STUDENT`, `LECTURER`, `ADMIN`) |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Thời điểm khởi tạo hồ sơ |

### 3.2. Bảng 2: Tài liệu (`public.documents`)
Lưu trữ siêu dữ liệu (metadata), nội dung tóm tắt và liên kết tới tệp vật lý của tài liệu.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Mã định danh duy nhất của tài liệu (UUID) |
| `owner_id` | `TEXT` | `REFERENCES profiles(id)` | Khóa ngoại trỏ tới người tạo (Chủ sở hữu - `OWNER`) |
| `owner_email` | `TEXT` | `NOT NULL` | Email của chủ sở hữu tài liệu |
| `title` | `TEXT` | `NOT NULL` | Tiêu đề tài liệu học tập |
| `doc_type` | `TEXT` | `CHECK IN (...)` | Loại tài liệu: `LECTURE`, `EXERCISE`, `EXAM`, `REFERENCE`, `OTHER` |
| `content` | `TEXT` | `NULL` | Nội dung ghi chú hoặc tóm tắt tài liệu |
| `file_url` | `TEXT` | `NULL` | Đường dẫn tệp vật lý trên bucket `study-documents` |
| `subject_code` | `TEXT` | `NULL` | Mã học phần (VD: `MATH101`, `CS102`, `IT308`) |
| `subject_name` | `TEXT` | `NULL` | Tên học phần |
| `priority` | `INTEGER` | `CHECK (0..2)` | Mức độ ưu tiên (`0`: Bình thường, `1`: Quan trọng, `2`: Khẩn cấp) |
| `status` | `TEXT` | `CHECK IN (...)` | Trạng thái (`NOT_STARTED`, `IN_PROGRESS`, `COMPLETED`) |
| `is_public` | `BOOLEAN` | `DEFAULT FALSE` | Cho phép mọi người dùng đăng nhập xem công khai |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Thời gian tạo tài liệu |
| `updated_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Thời gian cập nhật gần nhất |

### 3.3. Bảng 3: Quyền chia sẻ (`public.document_permissions`)
Bảng trung gian thể hiện mối quan hệ nhiều - nhiều ($N - M$) giữa Tài liệu và Người dùng được chia sẻ, cho phép phân quyền chi tiết ở mức từng bản ghi.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Mã định danh bản ghi phân quyền |
| `document_id` | `TEXT` | `REFERENCES documents(id) ON DELETE CASCADE` | Mã tài liệu được chia sẻ |
| `shared_with_email` | `TEXT` | `NOT NULL` | Email của người dùng nhận quyền chia sẻ |
| `permission_level` | `TEXT` | `CHECK IN ('VIEW', 'EDIT')` | Mức quyền: `VIEW` (Chỉ đọc) hoặc `EDIT` (Chỉnh sửa) |
| `granted_by` | `TEXT` | `REFERENCES profiles(id)` | Người cấp quyền (Chủ sở hữu tài liệu) |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Thời điểm cấp quyền |

> **Ràng buộc toàn vẹn:** `UNIQUE (document_id, shared_with_email)` đảm bảo mỗi người dùng nhận chia sẻ chỉ có một mức quyền duy nhất trên cùng một tài liệu. Khi nâng hoặc hạ quyền, hệ thống thực hiện `UPSERT` trực tiếp trên dòng đó.

---

## PHẦN 4. TRIỂN KHAI CHỨC NĂNG TÌM KIẾM, CẬP NHẬT VÀ CHIA SẺ TÀI LIỆU (CHECKLIST 4)

Các chức năng nghiệp vụ được xây dựng theo kiến trúc phân lớp rõ ràng:
- **Domain Models:** `lib/domain/models/cloud_document.dart` và `lib/domain/models/document_permission.dart`.
- **Domain Service:** `lib/domain/services/supabase_document_service.dart`.
- **State Management:** `lib/state/supabase_provider.dart`.
- **Giao diện người dùng (UI):** `lib/ui/screens/cloud_sharing_screen.dart` (Tab **Cloud RLS** trên thanh điều hướng chính) và `lib/ui/widgets/share_document_dialog.dart`.

### 4.1. Chức năng Tìm kiếm đa tiêu chí & Lọc theo phạm vi quyền hạn
Phương thức `searchDocuments()` hỗ trợ kết hợp đồng thời:
1. **Tìm kiếm từ khóa thời gian thực (Real-time Keyword Search):** So khớp không phân biệt hoa thường trên cả 4 trường: Tiêu đề (`title`), Nội dung tóm tắt (`content`), Mã/Tên môn học (`subjectCode`, `subjectName`) và Email chủ sở hữu (`ownerEmail`).
2. **Lọc theo phạm vi quyền hạn (`filterScope`):**
   - `ALL` (**Tất cả có quyền**): Hiển thị toàn bộ tài liệu mà tài khoản hiện tại sở hữu hoặc được chia sẻ.
   - `OWNED` (**Của tôi - Owner**): Chỉ lọc các tài liệu do chính tài khoản hiện tại tạo ra (`role == UserDocumentRole.owner`).
   - `SHARED` (**Được chia sẻ với tôi**): Chỉ lọc các tài liệu của người khác chia sẻ cho tài khoản hiện tại với quyền `VIEW` hoặc `EDIT`.

### 4.2. Chức năng Cập nhật thông tin tài liệu (Kiểm soát theo quyền `OWNER` / `EDIT`)
- Khi người dùng nhấn nút **"Chỉnh sửa"**, giao diện kiểm tra quyền thông qua `doc.canEdit(currentUserId, currentUserEmail)`.
- Nếu người dùng có vai trò `OWNER` hoặc `EDIT`, hộp thoại cập nhật cho phép sửa Tiêu đề, Loại tài liệu, Môn học, Nội dung tóm tắt, Đường dẫn tệp `file_url` và Trạng thái học tập.
- Tại tầng dịch vụ `SupabaseDocumentService.updateDocument()`, hệ thống kiểm tra lại một lần nữa. Nếu người dùng chỉ có quyền `VIEW` hoặc `NONE`, ngoại lệ `PermissionDeniedException` sẽ được ném ra và chặn thao tác ghi.

### 4.3. Tính năng Chia sẻ tài liệu & Thu hồi quyền (`ShareDocumentDialog`)
- Chỉ Chủ sở hữu (`OWNER`) mới kích hoạt được hộp thoại **Chia sẻ & Phân quyền RLS**.
- Giao diện cung cấp:
  - Các chip chọn nhanh email của các tài khoản trong nhóm (`alice@nhom11.edu.vn`, `bob@nhom11.edu.vn`, `charlie@nhom11.edu.vn`) hoặc nhập email bất kỳ.
  - Bộ chọn mức quyền: **`VIEW` (Chỉ xem)** hoặc **`EDIT` (Cho phép chỉnh sửa)**.
  - Danh sách trực quan tất cả người dùng đang được chia sẻ kèm nút **Thu hồi quyền (`revokePermission`)** ngay lập tức.

---

## PHẦN 5. THIẾT LẬP CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY - RLS (CHECKLIST 5)

Toàn bộ các bảng trên Supabase đều được bật chế độ bảo mật cấp hàng (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`). Bảng ma trận phân quyền và mã lệnh SQL RLS cụ thể như sau:

### 5.1. Ma trận Phân quyền Truy cập Tài liệu (Access Control Matrix)

| Thao tác (SQL / Service) | Chủ sở hữu (`OWNER`) | Người được chia sẻ quyền sửa (`EDIT`) | Người được chia sẻ quyền xem (`VIEW`) | Người dùng khác (`NONE`) |
| :--- | :---: | :---: | :---: | :---: |
| **Xem tài liệu (`SELECT`)** | Có | Có | Có | **Bị chặn (Ẩn hoàn toàn)** |
| **Tạo tài liệu mới (`INSERT`)** | Có | — | — | Có (Tạo cho chính mình) |
| **Cập nhật nội dung (`UPDATE`)** | Có | **Có** | **Bị chặn (RLS Error)** | **Bị chặn (RLS Error)** |
| **Xóa tài liệu (`DELETE`)** | **Có** | **Bị chặn (RLS Error)** | **Bị chặn (RLS Error)** | **Bị chặn (RLS Error)** |
| **Chia sẻ / Thu hồi quyền (`SHARE`)** | **Có** | **Bị chặn (RLS Error)** | **Bị chặn (RLS Error)** | **Bị chặn (RLS Error)** |

### 5.2. Các Chính sách RLS trọng tâm trên Supabase (`supabase_schema_and_rls.sql`)

```sql
-- 1. Bật RLS trên cả 3 bảng
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- 2. Chính sách SELECT trên bảng documents:
-- Cho phép đọc nếu là Chủ sở hữu (owner_id), hoặc có trong bảng document_permissions (VIEW/EDIT), hoặc tài liệu công khai
CREATE POLICY "documents_select_policy"
    ON public.documents FOR SELECT
    USING (
        owner_id = auth.uid()::text
        OR is_public = TRUE
        OR EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
              AND LOWER(dp.shared_with_email) = LOWER(auth.jwt() ->> 'email')
        )
    );

-- 3. Chính sách UPDATE trên bảng documents:
-- CHỈ cho phép cập nhật nếu là Chủ sở hữu (OWNER) HOẶC được cấp quyền 'EDIT'
CREATE POLICY "documents_update_policy"
    ON public.documents FOR UPDATE
    USING (
        owner_id = auth.uid()::text
        OR EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
              AND LOWER(dp.shared_with_email) = LOWER(auth.jwt() ->> 'email')
              AND dp.permission_level = 'EDIT'
        )
    );

-- 4. Chính sách DELETE trên bảng documents:
-- CHỈ DUY NHẤT Chủ sở hữu (OWNER) mới có quyền xóa tài liệu
CREATE POLICY "documents_delete_policy"
    ON public.documents FOR DELETE
    USING (owner_id = auth.uid()::text);
```

---

## PHẦN 6. KIỂM THỬ LUỒNG HOẠT ĐỘNG TRÊN 3 TÀI KHOẢN KHÁC NHAU (CHECKLIST 6)

Để xác minh tính toàn vẹn dữ liệu và độ chính xác của cơ chế phân quyền RLS, nhóm đã thiết lập **3 tài khoản người dùng độc lập** cùng bộ kiểm thử tự động tại `test/unit/services/supabase_rls_multi_user_test.dart` và thanh chuyển đổi tài khoản trực tiếp trên màn hình **Cloud RLS** (`CloudSharingScreen`).

### 6.1. Danh sách 3 tài khoản người dùng và dữ liệu kiểm thử ban đầu

1. **Tài khoản 1:** `alice@nhom11.edu.vn` (`UID: user-alice-uid-001`) — **Nguyễn Thị Alice**
2. **Tài khoản 2:** `bob@nhom11.edu.vn` (`UID: user-bob-uid-002`) — **Trần Văn Bob**
3. **Tài khoản 3:** `charlie@nhom11.edu.vn` (`UID: user-charlie-uid-003`) — **Lê Văn Charlie**

**Cấu hình 3 tài liệu kiểm thử mẫu:**
- **`doc-001` ("Bài giảng Giải tích 1 - Đạo hàm và Tích phân"):** Do **Alice** sở hữu (`OWNER`), chia sẻ cho **Bob** quyền `EDIT`, và chia sẻ cho **Charlie** quyền `VIEW`.
- **`doc-002` ("Đề cương Ôn tập Cấu trúc Dữ liệu & Giải thuật - Riêng tư"):** Do **Alice** sở hữu (`OWNER`), **không chia sẻ cho ai** (Riêng tư).
- **`doc-003` ("Bài tập Lớn Lập trình Đa nền tảng Flutter & Supabase"):** Do **Bob** sở hữu (`OWNER`), chia sẻ cho **Alice** quyền `VIEW`, và chia sẻ cho **Charlie** quyền `EDIT`.

### 6.2. Kịch bản và Kết quả Kiểm thử Thực tế (Test Cases & Verification)

| Mã Kịch bản | Tài khoản thực hiện | Hành động kiểm thử | Kết quả mong đợi (Theo chính sách RLS) | Kết quả thực tế (`flutter test`) |
| :--- | :--- | :--- | :--- | :---: |
| **TC-01** | **Alice**, **Bob**, **Charlie** | Truy vấn danh sách tài liệu (`getAccessibleDocuments`) | - **Alice** thấy 3 tài liệu (`doc-001`, `doc-002`, `doc-003`).<br>- **Bob** thấy 2 tài liệu (`doc-001`, `doc-003`), **ẩn hoàn toàn** `doc-002`.<br>- **Charlie** thấy 2 tài liệu (`doc-001`, `doc-003`), **ẩn hoàn toàn** `doc-002`. | **PASS** |
| **TC-02** | **Tài khoản 1: Alice** (`OWNER` trên `doc-001`) | Tải file lên Storage, tạo tài liệu mới, cập nhật tiêu đề, chia sẻ cho Charlie và xóa tài liệu của chính mình. | Tất cả các thao tác Tạo (`INSERT`), Sửa (`UPDATE`), Chia sẻ (`SHARE`), Xóa (`DELETE`) đều thành công. | **PASS** |
| **TC-03** | **Tài khoản 2: Bob** (`EDITOR` trên `doc-001`) | 1. Cập nhật nội dung và trạng thái của `doc-001`.<br>2. Cố tình xóa `doc-001` hoặc chia sẻ `doc-001` cho người thứ 4.<br>3. Cố tình sửa `doc-002` (riêng tư của Alice). | 1. Cập nhật `doc-001` **thành công** vì có quyền `EDIT`.<br>2. Xóa hoặc chia sẻ tiếp `doc-001` **bị chặn** (`PermissionDeniedException`).<br>3. Sửa `doc-002` **bị chặn**. | **PASS** |
| **TC-04** | **Tài khoản 3: Charlie** (`VIEWER` trên `doc-001`, `EDITOR` trên `doc-003`) | 1. Cố tình sửa hoặc xóa `doc-001` (chỉ có quyền `VIEW`).<br>2. Chỉnh sửa nội dung của `doc-003` (có quyền `EDIT` do Bob cấp). | 1. Thao tác sửa/xóa trên `doc-001` **bị chặn tuyệt đối** (`PermissionDeniedException`).<br>2. Thao tác sửa trên `doc-003` **thành công**. | **PASS** |
| **TC-05** | **Alice** & **Bob** | Alice thu hồi quyền (`revokePermission`) của Bob trên `doc-001`. Sau đó Bob tải lại danh sách và thử sửa `doc-001`. | Ngay sau khi thu hồi, `doc-001` biến mất khỏi danh sách của Bob và mọi yêu cầu chỉnh sửa từ Bob đều bị từ chối. | **PASS** |
| **TC-06** | **Tài khoản 2: Bob** | Tìm kiếm từ khóa `"Giải tích"` và lọc theo phạm vi `OWNED` / `SHARED`. | - Tìm `"Giải tích"` trả về đúng `doc-001`.<br>- Lọc `OWNED` trả về đúng `doc-003`.<br>- Lọc `SHARED` trả về đúng `doc-001`. | **PASS** |

---

## PHẦN 7. HƯỚNG DẪN CHẠY KIỂM THỬ VÀ DEMO TRỰC TIẾP CHO GIẢNG VIÊN

1. **Chạy bộ kiểm thử tự động xác minh RLS trên 3 tài khoản:**
   ```bash
   cd study_material_manager
   flutter test test/unit/services/supabase_rls_multi_user_test.dart
   ```
2. **Demo trực quan trên giao diện ứng dụng Flutter:**
   - Mở ứng dụng và chuyển sang tab **"Cloud RLS"** (biểu tượng đám mây ở thanh điều hướng dưới cùng).
   - Tại khung **"Trình mô phỏng Kiểm thử 3 Tài khoản (Checklist 6)"**, nhấn chuyển đổi lần lượt giữa **Tài khoản 1 (Alice - Owner)**, **Tài khoản 2 (Bob - Editor)** và **Tài khoản 3 (Charlie - Viewer)** để quan sát sự thay đổi tức thời của danh sách tài liệu, nhãn quyền hạn (`OWNER`, `EDIT`, `VIEW`) và trạng thái bật/khóa của các nút **Chỉnh sửa**, **Chia sẻ**, **Xóa**.
