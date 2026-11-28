# Quy Trình Làm Việc Git/GitHub, Issue, Project Board Và CSDL – Nhóm 14

Tài liệu này là **bộ hướng dẫn thống nhất duy nhất** áp dụng cho toàn bộ 5 thành viên Nhóm 14 (65KTPM) khi làm việc trên dự án **Hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp cho sinh viên**.

---

## 1. Thông Tin Repository Và Vai Trò Các Nhánh

- **Repository làm việc của nhóm:** `Maya0612/project-ptuddd`
- **Nhánh tích hợp chung của nhóm:** `nhom14-65ktpm`
- **Nhánh `main`:** **Không sử dụng** làm nhánh phát triển trực tiếp của nhóm. Nhánh `main` luôn được giữ nguyên đồng bộ với kho gốc của giảng viên (`oanhcuongdo/project-ptuddd`).

```text
nhom14-65ktpm  (Nhánh tích hợp chung của nhóm — Base branch cho mọi PR nội bộ)
   ├── feature/nhom14/foundation-auth       (TV1 – Đào Hà Thu)
   ├── feature/nhom14/project-repository    (TV2 – Phạm Kim Anh)
   ├── feature/nhom14/ai-suggestions        (TV3 – Trần Đức Trung)
   ├── feature/nhom14/personal-topics       (TV4 – Trịnh Mạnh Đức)
   └── feature/nhom14/planning-progress     (TV5 – Vương Tiến Dũng)
```

---

## 2. Quy Ước Branch Cá Nhân Chính Thức

Mỗi thành viên sử dụng **duy nhất 01 branch cá nhân cố định** được tách ra từ nhánh `nhom14-65ktpm`:

| Thành Viên | Mã TV | Branch Cá Nhân Cố Định | Module Phụ Trách |
| --- | :---: | --- | --- |
| Đào Hà Thu (Trưởng nhóm) | TV1 | `feature/nhom14/foundation-auth` | Kiến trúc, Flutter & Supabase, Auth, `profiles`, RLS nền tảng, tích hợp |
| Phạm Kim Anh | TV2 | `feature/nhom14/project-repository` | Kho đồ án (`projects`, `fields`, `favorites`), tìm kiếm/lọc, yêu thích, đề xuất & duyệt |
| Trần Đức Trung | TV3 | `feature/nhom14/ai-suggestions` | AI gợi ý (3–5 đề tài) & đối chiếu kho đã duyệt qua backend/Edge Function |
| Trịnh Mạnh Đức | TV4 | `feature/nhom14/personal-topics` | Quản lý đề tài cá nhân (`personal_topics`), CRUD, lưu từ ý tưởng/AI, phân quyền |
| Vương Tiến Dũng | TV5 | `feature/nhom14/planning-progress` | Lập kế hoạch & theo dõi tiến độ (`plans`, `tasks`), liên kết đề tài cá nhân |

### Quy định branch

- Chỉ làm việc trên branch được phân công.
- Không commit trực tiếp lên `main` hoặc `nhom14-65ktpm`.
- Không tự ý đổi tên branch, dùng chung branch hoặc xóa branch cá nhân cố định sau khi merge.
- Mỗi người commit/push bằng tài khoản GitHub cá nhân.
- Mọi PR nội bộ phải có base repository `Maya0612/project-ptuddd` và base branch `nhom14-65ktpm`.
- Branch cá nhân là branch dài hạn. Sau mỗi lần PR được merge, phải đồng bộ lại branch cá nhân từ nhánh tích hợp trước khi tiếp tục công việc.

## 3. Chuẩn bị Git lần đầu

Thực hiện một lần trên máy cá nhân. Thay thông tin mẫu bằng tên và email gắn với tài khoản GitHub của chính bạn.

```bash
git config --global user.name "Ho Va Ten"
git config --global user.email "email-github@example.com"

git clone https://github.com/Maya0612/project-ptuddd.git
cd project-ptuddd
```

Kiểm tra remote:

```bash
git remote -v
```

`origin` phải trỏ tới `https://github.com/Maya0612/project-ptuddd.git`.

Nếu chưa có nhánh tích hợp trên máy, lấy branch từ GitHub:

```bash
git fetch origin
git switch --track origin/nhom14-65ktpm
```

Nếu Git báo branch đã tồn tại ở local thì không chạy lại lệnh tạo tracking; chỉ chuyển branch:

```bash
git switch nhom14-65ktpm
```

Sau đó lấy cập nhật mới nhất:

```bash
git pull --ff-only origin nhom14-65ktpm
```

## 4. Quy trình làm việc hằng ngày

### Bước 1 – Cập nhật nhánh tích hợp

Trước khi bắt đầu một phiên làm việc:

```bash
git fetch origin
git switch nhom14-65ktpm
git pull --ff-only origin nhom14-65ktpm
```

### Bước 2 – Chuyển sang branch cá nhân

Ví dụ TV2:

```bash
# Ví dụ cho TV2 (thay bằng đúng tên branch của bạn tại Mục 2)
git checkout feature/nhom14/project-repository
```

Nếu branch cá nhân đã có trên GitHub nhưng chưa có ở máy:

```bash
git fetch origin
git checkout --track origin/feature/nhom14/project-repository
```

Nếu branch cá nhân chưa tồn tại ở cả local và GitHub, tạo từ nhánh tích hợp mới nhất. Ví dụ TV2:

```bash
git checkout nhom14-65ktpm
git pull origin nhom14-65ktpm
git checkout -b feature/nhom14/project-repository
git push -u origin feature/nhom14/project-repository
```

Mỗi thành viên thay tên branch trong ví dụ bằng branch đã được chỉ định ở Mục 2.

### Bước 3 – Code, kiểm tra và commit

Trước khi commit:

```bash
git status
```

Kiểm tra:
- Đang đứng trên đúng branch cá nhân.
- Chỉ có file liên quan đến Issue/module được giao.
- Không có `.env`, khóa bí mật, file build hoặc file cá nhân.
- Không vô tình sửa tài liệu gốc do giảng viên quản lý.

Từ thư mục gốc repository, stage đúng phạm vi. Ví dụ nếu làm trong thư mục nhóm:

```bash
git add nhom14-65ktpm/
git status
git commit -m "feat(nhom14): add project search and filter"
git push origin feature/nhom14/project-repository
```

Không dùng `git add .` một cách máy móc khi chưa kiểm tra `git status`. Nếu repository có thay đổi ngoài thư mục nhóm, chỉ stage các file thực sự thuộc nhiệm vụ.

#### Quy ước commit message

Dùng tiền tố và nội dung cụ thể:

| Prefix | Dùng khi | Ví dụ |
|---|---|---|
| `feat:` | Thêm chức năng | `feat: add project search and filter` |
| `fix:` | Sửa lỗi | `fix: handle empty AI response` |
| `docs:` | Cập nhật tài liệu | `docs: update database workflow` |
| `refactor:` | Tái cấu trúc không đổi hành vi | `refactor: extract project card widget` |
| `test:` | Thêm/sửa kiểm thử | `test: add profile repository tests` |
| `chore:` | Cấu hình/công việc phụ trợ | `chore: configure supabase cli` |

Không dùng message chung chung như `update`, `done`, `fix bug`, `test` hoặc `abc`.

### Bước 4 – Tạo Pull Request

Khi hoàn thành một phần việc đủ rõ ràng để review:

1. Mở repository `Maya0612/project-ptuddd` → **Pull requests** → **New pull request**.
2. Chọn đúng:
   - **Base repository:** `Maya0612/project-ptuddd`
   - **Base branch:** `nhom14-65ktpm` *(⚠️ Không chọn `main`)*
   - **Compare branch:** Branch cá nhân của bạn (VD: `feature/nhom14/project-repository`).
3. Điền đầy đủ nội dung mô tả PR theo mẫu sau:

```markdown
## 1. Nội dung thay đổi
- Mô tả chức năng hoặc phần sửa đổi.

## 2. Phạm vi file
- Liệt kê các file chính đã thay đổi.

## 3. Cách kiểm thử
1. Các bước kiểm thử.
2. Kết quả mong đợi.
3. Kết quả thực tế.

## 4. Issue liên quan
Refs #<issue_number>

## 5. Lưu ý cho reviewer
- Các điểm cần chú ý, phụ thuộc hoặc phần chưa hoàn thiện (nếu có).
```

### Bước 5 – Review Pull Request

- Người tạo PR không tự approve PR của chính mình.
- Tối thiểu một thành viên khác phải review. Nếu repository có branch protection/ruleset yêu cầu approval, phải đáp ứng đúng điều kiện đó; reviewer cần có quyền phù hợp trên repository.
- Reviewer kiểm tra nghiệp vụ, chất lượng code, khả năng chạy, xử lý lỗi, phạm vi thay đổi, bảo mật và tương thích với module/schema khác.
- Nếu có yêu cầu chỉnh sửa, tác giả sửa ngay trên branch cá nhân đang mở PR, sau đó commit và push lại. PR tự cập nhật.
- Chỉ approve khi thay đổi đã được kiểm tra. Không approve hình thức.

### Bước 6 – Merge và cập nhật Issue/Project Board

Chỉ merge khi:
- Đã có approval theo yêu cầu repository.
- Không còn conflict chưa xử lý.
- Các kiểm tra cần thiết đã đạt.
- Nội dung PR đúng Issue và phạm vi được giao.

Sau khi merge vào `nhom14-65ktpm`:
- Không xóa branch cá nhân cố định.
- Cập nhật Issue và Project Board sang `Done` sau khi xác nhận công việc thực sự hoàn tất.
- Không chuyển sang `Done` chỉ vì đã push code hoặc mới mở PR.

Dùng `Refs #<issue_number>` trong PR để liên kết Issue. Không mặc định dùng `Closes #...` vì PR merge vào branch không phải default branch có thể không tự đóng Issue theo cấu hình GitHub. Nếu Issue chưa tự đóng, người phụ trách đóng thủ công sau khi xác nhận.

### Bước 7 – Đồng bộ branch cá nhân sau khi có merge mới

Sau khi nhánh tích hợp có thay đổi mới, mỗi thành viên cập nhật branch của mình:

```bash
git fetch origin
git switch feature/nhom14/project-repository
git merge origin/nhom14-65ktpm
git push origin feature/<branch-cua-minh>
```

*Giải thích lệnh:*
- `git fetch origin`: Lấy các commit mới nhất trên GitHub về (bao gồm `origin/nhom14-65ktpm`).
- `git checkout feature/<branch-cua-minh>`: Đảm bảo đang đứng đúng trên branch cá nhân.
- `git merge origin/nhom14-65ktpm`: Gộp toàn bộ cập nhật mới từ nhánh tích hợp vào branch cá nhân của bạn.
- `git push origin feature/<branch-cua-minh>`: Đẩy trạng thái đã đồng bộ lên GitHub.

#### Xử lý khi xảy ra Conflict (Xung đột code)
1. Bình tĩnh mở các file bị đánh dấu xung đột (`<<<<<<<`, `=======`, `>>>>>>>`), trao đổi với thành viên liên quan để chọn phần code đúng.
2. Lưu file, chạy kiểm thử ứng dụng (`flutter analyze` / `flutter run`) để chắc chắn không lỗi.
3. Thực hiện `git add nhom14-65ktpm/` → `git commit` → `git push origin feature/<branch-cua-minh>`.
4. **NGHIÊM CẤM:** Không tự ý dùng `git push --force` (`-f`), `git reset --hard` hoặc xóa lịch sử commit để xử lý conflict. Nếu không chắc chắn, hãy dừng lại và báo TV1 hỗ trợ.

---

## 5. Quy Tắc Issue Và Project Board

- Mỗi thành viên được giao các **Issue** tương ứng với phạm vi nhiệm vụ của mình.
- Mỗi Issue bắt buộc có đầy đủ:
  - **Tiêu đề** rõ ràng, ngắn gọn.
  - **Mô tả** mục tiêu và phạm vi công việc.
  - **Checklist** các đầu việc nhỏ (`- [ ] ...`).
  - **Labels** phù hợp (VD: `feature`, `bug`, `database`, `ui`, `ai`, `docs`).
  - **Assignee** (người chịu trách nhiệm chính).
- **Project Board** sử dụng cố định 4 cột trạng thái:
  1. **Todo:** Công việc đã lên kế hoạch, chưa bắt đầu.
  2. **In Progress:** Thành viên đã bắt đầu thực hiện.
  3. **In Review:** Đã hoàn thành code, đã tạo Pull Request (có gắn `Refs #<issue_number>`) và đang chờ Review.
  4. **Done:** Pull Request đã được **Merge** vào `nhom14-65ktpm` và công việc đã được xác nhận hoàn thành.
- **Quy tắc nghiêm ngặt:** Không tự ý kéo thẻ sang **Done** chỉ vì đã `git push` code hoặc mới mở PR.

---

## 6. Quy Ước Thiết Kế Cơ Sở Dữ Liệu (Supabase)

Mỗi thành viên chịu trách nhiệm đề xuất thiết kế cấu trúc bảng thuộc module của mình:
- **TV1:** `profiles` (và tổng hợp, rà soát toàn bộ schema + RLS nền tảng).
- **TV2:** `projects`, `fields`, `favorites`.
- **TV3:** Đối chiếu trên dữ liệu `projects` đã được duyệt (và thiết kế cấu trúc dữ liệu I/O cho AI Edge Function).
- **TV4:** `personal_topics`.
- **TV5:** `plans`, `tasks`.

### Quy trình thống nhất trước khi thao tác trên Supabase thật
Trước khi tạo mới hoặc chỉnh sửa bất kỳ bảng nào trên Supabase thật, thành viên **bắt buộc** đề xuất và thống nhất trước với **TV1** đầy đủ 7 nội dung sau:
1. **Tên bảng** (thống nhất đặt tên `snake_case`, số nhiều theo chuẩn PostgreSQL/Supabase).
2. **Tên cột và kiểu dữ liệu**.
3. **Primary Key (PK) và Foreign Key (FK)**.
4. **Quan hệ giữa các bảng** (1-1, 1-N, N-N).
5. **Ràng buộc dữ liệu** (`NOT NULL`, `UNIQUE`, `CHECK`, giá trị mặc định, `ON DELETE`).
6. **Quyền truy cập và chính sách RLS (Row Level Security)** theo từng vai trò (Sinh viên, Admin).
7. **Các thao tác CRUD** cần hỗ trợ từ phía ứng dụng.

- **TV1** chịu trách nhiệm tổng hợp và kiểm tra tính nhất quán của toàn bộ schema trước khi áp dụng.
- **Nghiêm cấm** từng thành viên tự ý tạo bảng hoặc viết chính sách RLS khác nhau trực tiếp trên Supabase gây xung đột khi tích hợp.

---

## 7. Nguyên Tắc Bảo Mật Và Tệp Tin Không Được Commit

- **Tuyệt đối không commit** API Key (AI API Key, Supabase Service Role Key), mật khẩu, thông tin bí mật hoặc file `.env` vào mã nguồn hay tài liệu.
- Không commit các thư mục/tệp tạm và build artifacts: `.dart_tool/`, `build/`, `.gradle/`, `Pods/`, `.idea/`, `.vscode/`, `*.iml`, `*.apk`, `*.aab`, `*.ipa`.
- Không chỉnh sửa các tệp gốc ngoài thư mục nhóm (`README.md`, `.gitignore` ở thư mục gốc `project-ptuddd/`).

---

## 8. Quy Định Nộp Bài Về Kho Giảng Viên

- Trong suốt quá trình phát triển, mọi PR của thành viên chỉ gửi vào `Maya0612/project-ptuddd` nhánh `nhom14-65ktpm`.
- Việc đồng bộ từ `upstream/main` và mở Pull Request nộp bài sang kho gốc của giảng viên (`oanhcuongdo/project-ptuddd`, nhánh `main`) do **Trưởng nhóm (TV1)** đại diện thực hiện từ nhánh `nhom14-65ktpm` theo đúng hướng dẫn tại tệp `README.md` ở thư mục gốc của kho lưu trữ.
