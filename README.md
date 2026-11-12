# Hướng Dẫn Nộp Mã Nguồn Và Báo Cáo Đồ Án (Phát Triển Ứng Dụng Di Động)

Kho lưu trữ này được thiết lập để quản lý và thu thập mã nguồn, báo cáo đồ án của các nhóm sinh viên học phần Phát Triển Ứng Dụng Di Động (PTUDDD). Sinh viên thực hiện tham gia, phát triển và nộp bài thông qua hệ thống Git và GitHub theo đúng các quy chuẩn kỹ thuật được mô tả dưới đây.

---

## 1. Quy Chuẩn Đặt Tên Thư Mục Nhóm

Mỗi nhóm sinh viên bắt buộc phải tạo duy nhất một thư mục riêng biệt tại cấp cao nhất (root) của kho lưu trữ.

### 1.1. Cấu trúc định danh thư mục
- **Cú pháp quy định:** `<ten-nhom>-<ten-lop>`
- **Ví dụ chuẩn:**
  - Nhóm 01 lớp DHTI15A1HN: `nhom01-dhti15a1hn`
  - Nhóm 02 lớp DHTI15A2HN: `nhom02-dhti15a2hn`
  - Nhóm 05 lớp CNTT1: `nhom05-cntt1`

### 1.2. Ràng buộc kỹ thuật về tên thư mục
- Toàn bộ ký tự viết thường (lowercase).
- Không sử dụng ký tự tiếng Việt có dấu.
- Không sử dụng dấu khoảng trắng (space).
- Các thành phần được phân tách duy nhất bằng dấu gạch ngang (`-`).
- Không sử dụng các ký tự đặc biệt khác (`@`, `#`, `$`, `%`, `&`, `_`, `/`, `\`).

---

## 2. Quy Chuẩn Tạo Và Quản Lý Nhánh Riêng Biệt Cho Từng Nhóm (Branching Strategy)

Để đảm bảo tính độc lập và tránh xung đột mã nguồn giữa các nhóm, quy định về phân nhánh (branching) được áp dụng bắt buộc như sau:

### 2.1. Quy tắc phân nhánh cốt lõi
- **Tuyệt đối cấm commit hoặc push trực tiếp vào nhánh `main`:** Nhánh `main` là nhánh tích hợp cuối cùng của học phần, chỉ được cập nhật thông qua Pull Request sau khi giảng viên kiểm duyệt và nghiệm thu.
- **Mỗi nhóm bắt buộc phải có một nhánh làm việc riêng:** Toàn bộ quá trình phát triển mã nguồn, tải tài liệu và cập nhật tiến độ của nhóm phải được thực hiện trên nhánh riêng của nhóm đó.
- **Cơ chế bảo vệ nhánh (Branch Protection Rule)** đã được kích hoạt trên GitHub. Mọi thao tác `git push origin main` sẽ bị từ chối tự động với lỗi:
  ```text
  remote: error: GH006: Protected branch update failed for refs/heads/main.
  remote: error: Changes must be made through a pull request.
  To https://github.com/oanhcuongdo/project-ptuddd.git
   ! [remote rejected] main -> main (protected branch hook declined)
  ```

### 2.2. Cú pháp định danh nhánh nhóm
- **Cú pháp chuẩn:** `<ten-nhom>-<ten-lop>` (trùng khớp với tên thư mục của nhóm để đồng bộ quản lý).
- **Ví dụ chuẩn:**
  - Nhóm 01 lớp DHTI15A1HN: `nhom01-dhti15a1hn`
  - Nhóm 02 lớp DHTI15A2HN: `nhom02-dhti15a2hn`
  - Nhóm 05 lớp CNTT1: `nhom05-cntt1`

### 2.3. Quy trình Fork và tạo nhánh nhóm
Sinh viên không có quyền ghi (Write) trực tiếp vào kho lưu trữ gốc. Mỗi nhóm thực hiện theo mô hình Fork và Pull Request:
1. Nhóm trưởng thực hiện **Fork** kho lưu trữ gốc `https://github.com/oanhcuongdo/project-ptuddd` về tài khoản GitHub cá nhân (nút **Fork** trên giao diện GitHub).
2. Nhóm trưởng thêm các thành viên làm Collaborator của kho Fork (Settings → Collaborators) để cùng đẩy mã nguồn lên nhánh nhóm.
3. Nhóm trưởng clone kho Fork, khai báo kho gốc là `upstream` và tạo nhánh riêng của nhóm:
```bash
# 1. Clone kho Fork của nhóm trưởng
git clone https://github.com/<github-nhom-truong>/project-ptuddd.git
cd project-ptuddd

# 2. Khai báo kho gốc là upstream
git remote add upstream https://github.com/oanhcuongdo/project-ptuddd.git

# 3. Tạo và chuyển sang nhánh riêng của nhóm từ main mới nhất
git checkout main
git pull upstream main
git checkout -b <ten-nhom>-<ten-lop>

# 4. Đẩy nhánh riêng của nhóm lên kho Fork
git push -u origin <ten-nhom>-<ten-lop>
```
*Ví dụ cụ thể:*
```bash
git checkout -b nhom01-dhti15a1hn
git push -u origin nhom01-dhti15a1hn
```
*Lưu ý:* Trong mô hình này, `origin` là kho Fork của nhóm, `upstream` là kho gốc của giảng viên. Lệnh `git push` tới `upstream` bị từ chối (403) và không được sử dụng.

### 2.4. Quy trình đồng bộ giữa các thành viên trong cùng một nhóm
Các thành viên trong cùng một nhóm cộng tác trên nhánh của nhóm mình theo các bước:
1. Lấy danh sách nhánh mới nhất từ GitHub:
   ```bash
   git fetch origin
   ```
2. Chuyển sang làm việc trên nhánh của nhóm:
   ```bash
   git checkout --track origin/<ten-nhom>-<ten-lop>
   ```
   *(Trường hợp đã có nhánh cục bộ, chỉ cần chạy: `git checkout <ten-nhom>-<ten-lop>`)*
3. Trước khi bắt đầu viết mã hoặc thêm tệp, luôn kéo dữ liệu mới nhất của nhóm về:
   ```bash
   git pull origin <ten-nhom>-<ten-lop>
   ```
4. Đẩy kết quả công việc sau khi commit lên nhánh nhóm:
   ```bash
   git push origin <ten-nhom>-<ten-lop>
   ```

---

## 3. Quy Chuẩn Cấu Trúc Thư Mục Của Nhóm

Toàn bộ tài liệu, thông tin thành viên và mã nguồn của nhóm phải nằm trọn vẹn bên trong thư mục của nhóm mình. Cấu trúc tổ chức tệp tin yêu cầu như sau:

```text
project-ptuddd/
├── .gitignore
├── README.md
└── <tennhom-tenlop>/
    ├── danhsachnhom.md        # Tệp bắt buộc: Thông tin thành viên và phân công
    ├── README.md              # (Tùy chọn) Hướng dẫn cài đặt, chạy ứng dụng của nhóm
    ├── docs/                  # Thư mục chứa tài liệu đặc tả, báo cáo đồ án (PDF/DOCX)
    │   └── baocao_doan.pdf
    └── src/                   # Thư mục chứa toàn bộ mã nguồn của dự án
        ├── android/
        ├── ios/
        ├── lib/               # Mã nguồn chính (Flutter/Dart hoặc tương đương)
        └── assets/
```

### Yêu cầu bắt buộc đối với tệp tin `danhsachnhom.md`:
- Tệp tin phải được đặt trực tiếp tại cấp cao nhất của thư mục nhóm: `<tennhom-tenlop>/danhsachnhom.md`.
- Nội dung tệp tin phải bao gồm đầy đủ:
  - Thông tin tên đề tài, lớp học phần.
  - Bảng danh sách thành viên: Số thứ tự, Họ và tên, Mã sinh viên, Lớp sinh hoạt, Vai trò (Nhóm trưởng / Thành viên), Nhiệm vụ phân công, Tỷ lệ đóng góp (%), Email.
  - Hướng dẫn thiết lập môi trường và các bước khởi chạy ứng dụng di động của nhóm.

**Mẫu nội dung `danhsachnhom.md`:**
```markdown
# Danh Sách Thành Viên - Nhóm [Tên Nhóm]

- **Lớp học phần / Lớp sinh hoạt:** [Tên Lớp]
- **Tên đề tài / Ứng dụng:** [Tên dự án]
- **Giảng viên hướng dẫn:** [Tên Giảng viên]

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| --- | --------- | ------------ | ------------- | ------- | ------------------- | ------------- | ----- |
| 1   | Nguyễn Văn A | 20210001 | DHTI15A1HN | Trưởng nhóm | Thiết kế kiến trúc, backend | 100% | a@example.com |
| 2   | Trần Thị B   | 20210002 | DHTI15A1HN | Thành viên  | Giao diện người dùng (UI/UX) | 100% | b@example.com |
```

---

## 4. Quy Định Về Quản Lý Mã Nguồn Và Tệp Tin

1. **Phạm vi thao tác:**
   - Mỗi nhóm chỉ được phép thêm mới, chỉnh sửa các tệp tin nằm trong thư mục của nhóm mình (`<tennhom-tenlop>/`).
   - Nghiêm cấm chỉnh sửa, đổi tên hoặc xóa các tệp tin, thư mục của các nhóm khác.
   - Không chỉnh sửa tệp tin gốc của kho lưu trữ (`README.md`, `.gitignore`), trừ trường hợp có thông báo từ giảng viên.

2. **Các tệp tin tuyệt đối không đưa lên kho lưu trữ (đã được cấu hình trong `.gitignore`):**
   - Thư mục biên dịch và thư viện: `node_modules/`, `build/`, `dist/`, `bin/`, `obj/`, `out/`.
   - Thư mục phụ thuộc nền tảng di động: `.gradle/`, `app/build/`, `Pods/`, `.dart_tool/`, `.pub-cache/`, `.pub/`, `.packages`.
   - Tệp nhị phân ứng dụng: `*.apk`, `*.aab`, `*.ipa`, `*.dSYM`.
   - Tệp cấu hình bảo mật cục bộ: `.env`, `.env.*` (ngoại trừ `.env.example`), `*.keystore`, `*.jks`.
   - Tệp bộ nhớ tạm của IDE/OS: `.vscode/`, `.idea/`, `*.swp`, `*.swo`, `.DS_Store`, `Thumbs.db`.

---

## 5. Hướng Dẫn Cấu Hình Và Tham Gia Dự Án Dành Cho Sinh Viên

Mọi sinh viên trước khi thực hiện thao tác mã nguồn cần hoàn tất các bước chuẩn bị sau:

### 5.1. Chuẩn bị tài khoản GitHub
- Mỗi sinh viên cần có một tài khoản GitHub cá nhân đang hoạt động.
- Gửi tài khoản GitHub (Username) cho nhóm trưởng để được thêm làm Collaborator của kho Fork nhóm (xem mục 2.3).

### 5.2. Cấu hình định danh tác giả trên máy cục bộ
Để lịch sử commit ghi nhận chính xác danh tính sinh viên, mở Terminal / Git Bash và thiết lập:
```bash
git config --global user.name "Họ và Tên Sinh Viên"
git config --global user.email "email_sinh_vien@example.com"
```
*Lưu ý:* `email_sinh_vien@example.com` phải trùng khớp với email đã đăng ký trên tài khoản GitHub.

### 5.3. Lấy mã nguồn dự án về máy cục bộ
- **Nhóm trưởng:** thực hiện theo mục 2.3 (Fork, clone kho Fork, thêm `upstream`).
- **Thành viên:** clone kho Fork của nhóm trưởng sau khi chấp nhận lời mời Collaborator:
```bash
git clone https://github.com/<github-nhom-truong>/project-ptuddd.git
cd project-ptuddd
git checkout --track origin/<ten-nhom>-<ten-lop>
```

---

## 6. Quy Chuẩn Commit Và Push Mã Nguồn Vào Đúng Thư Mục Nhóm

Để đảm bảo không ảnh hưởng đến mã nguồn của nhóm khác và giữ cấu trúc kho lưu trữ chuẩn xác, sinh viên phải tuân thủ nghiêm ngặt quy trình dưới đây.

### 6.1. Quy tắc an toàn bắt buộc khi thao tác tệp
- **Chỉ làm việc bên trong thư mục nhóm:** Mọi tệp tin mới tạo hoặc sửa đổi bắt buộc phải nằm trong đường dẫn `<tennhom-tenlop>/`.
- **Không sử dụng lệnh `git add .` ở thư mục gốc:** Thao tác này dễ vô tình đưa cả các tệp ngoài ý muốn hoặc tệp của nhóm khác vào commit.
- **Luôn chỉ định cụ thể thư mục nhóm khi `git add`:**
  ```bash
  git add <tennhom-tenlop>/
  ```

### 6.2. Trình tự các bước thực hiện commit và push

#### Bước 1: Chuyển sang nhánh riêng của nhóm và đồng bộ mới nhất
```bash
git checkout <ten-nhom>-<ten-lop>
git pull origin <ten-nhom>-<ten-lop>   # origin = kho Fork của nhóm
```

#### Bước 2: Tạo thư mục nhóm (nếu chưa có)
Nếu nhóm chưa có thư mục trên kho lưu trữ:
1. Tạo thư mục:
   ```bash
   mkdir nhom01-dhti15a1hn
   ```
2. Tạo tệp `danhsachnhom.md` bên trong thư mục, điền đầy đủ và chính xác thông tin các thành viên theo mẫu tại Mục 3.

#### Bước 3: Thêm mã nguồn và tài liệu vào thư mục nhóm
Đặt toàn bộ thư mục `src/`, `docs/` vào đúng vị trí:
```text
nhom01-dhti15a1hn/
├── danhsachnhom.md
├── docs/
└── src/
```

#### Bước 4: Kiểm tra trạng thái tệp tin bằng `git status`
Trước khi đưa tệp vào staging, chạy lệnh kiểm tra:
```bash
git status
```
*Yêu cầu kiểm tra:* Danh sách tệp hiển thị ở mục `Untracked files` hoặc `Changes not staged for commit` bắt buộc chỉ bắt đầu bằng `<tennhom-tenlop>/`. Nếu xuất hiện tệp ở ngoài thư mục nhóm, phải di chuyển tệp về đúng vị trí trước khi tiếp tục.

#### Bước 5: Đưa tệp vào khu vực theo dõi (Staging Area)
Chỉ định rõ ràng thư mục nhóm:
```bash
git add nhom01-dhti15a1hn/
```

Kiểm tra lại lần nữa để đảm bảo chỉ có tệp của nhóm được stage:
```bash
git status
```

Trường hợp vô tình đánh dấu nhầm tệp nằm ngoài thư mục nhóm, hủy đánh dấu bằng lệnh:
```bash
git restore --staged <duong-dan-tep-bi-nham>
```

#### Bước 6: Thực hiện commit
Commit với thông điệp rõ ràng, tuân thủ cấu trúc chuẩn:
```bash
git commit -m "feat(nhom01-dhti15a1hn): nop ma nguon man hinh dang nhap va danh sach nhom"
```
Cú pháp thông điệp commit: `<loại-thay-đổi>(<tennhom-tenlop>): <mô-tả-ngắn-gọn>`
- `feat`: Thêm chức năng mới, mã nguồn mới.
- `fix`: Sửa lỗi mã nguồn.
- `docs`: Cập nhật tài liệu, tệp danhsachnhom.md.

#### Bước 7: Đẩy nhánh lên GitHub (Push)
Đẩy nhánh lên kho Fork của nhóm (`origin`):
```bash
git push origin <ten-nhom>-<ten-lop>
```
*Ví dụ:* `git push origin nhom01-dhti15a1hn`

#### Bước 8: Mở Pull Request (PR) từ kho Fork về nhánh `main` của kho gốc khi nộp bài
1. Truy cập kho Fork của nhóm trên GitHub, chọn nhánh `<ten-nhom>-<ten-lop>`.
2. Chọn **Contribute** rồi **Open pull request** (hoặc **Compare & pull request**). Thiết lập:
   - base repository: `oanhcuongdo/project-ptuddd`, base: `main`.
   - head repository: kho Fork của nhóm, compare: `<ten-nhom>-<ten-lop>`.
3. Kiểm tra mục **Files changed** (Các tệp thay đổi): Đảm bảo 100% đường dẫn tệp đều có tiền tố `<tennhom-tenlop>/...`.
4. Đặt tiêu đề Pull Request:
   ```text
   [Nộp bài] <tennhom-tenlop> - <Tên đề tài>
   ```
5. Phần nội dung (Description): Mô tả tóm tắt các tính năng đã thực hiện và liệt kê các thành viên nộp bài.
6. Nhấn **Create pull request** để giảng viên đánh giá và phê duyệt.

---

## 7. Phối Hợp Làm Việc Nội Bộ Trong Nhóm

Đối với các nhóm có nhiều thành viên cùng phát triển đồng thời:

1. **Phân chia nhánh nội bộ:**
   - Các thành viên có thể tạo nhánh phụ từ nhánh nhóm theo định dạng: `feature/<tennhom>/<tinh-nang>` xuất phát từ nhánh `<ten-nhom>-<ten-lop>`.
   - Khi hoàn thành tính năng, merge vào nhánh chính của nhóm trước khi gửi Pull Request về kho gốc của giảng viên.
2. **Quy tắc giải quyết xung đột (Conflict Resolution):**
   - Không được ghi đè mã nguồn của thành viên khác mà không trao đổi nội bộ.
   - Luôn chạy kiểm thử ứng dụng sau khi giải quyết xung đột mã nguồn.

---

## 8. Xử Lý Các Sự Cố Kỹ Thuật Thường Gặp

### 8.1. Xử lý khi lỡ thêm (add) tệp nhầm ngoài thư mục nhóm
Nếu chạy `git status` và thấy có tệp nằm ngoài thư mục nhóm đã bị đưa vào Staging:
```bash
# Hủy staging tệp bị nhầm
git restore --staged <duong-dan-tep-bi-nham>

# Di chuyển tệp về đúng thư mục nhóm
mv <duong-dan-tep> <tennhom-tenlop>/
```

### 8.2. Xử lý khi bị từ chối push (rejected - non-fast-forward)
Khi có thành viên khác trong nhóm đã đẩy commit lên nhánh trước bạn:
```bash
git pull --rebase origin <ten-nhom>-<ten-lop>
git push origin <ten-nhom>-<ten-lop>
```

### 8.3. Giữ nhánh nhóm luôn cập nhật với nhánh `main` của kho gốc
```bash
git checkout <ten-nhom>-<ten-lop>
git fetch upstream
git merge upstream/main
git push origin <ten-nhom>-<ten-lop>
```

---

## 9. Danh Sách Kiểm Tra Trước Khi Nộp Bài (Checklist)

| STT | Tiêu chí kiểm tra | Yêu cầu kỹ thuật | Trạng thái |
| :-: | :--- | :--- | :-: |
| 1 | Nhánh làm việc riêng | Làm việc 100% trên nhánh riêng `<ten-nhom>-<ten-lop>` của kho Fork, không commit trực tiếp vào `main`. | Bắt buộc |
| 2 | Cú pháp tên thư mục | Đúng định dạng `<tennhom-tenlop>`, toàn bộ chữ thường, không dấu, không khoảng trắng. | Bắt buộc |
| 3 | Vị trí tệp tin | 100% tệp tin của nhóm nằm trọn vẹn trong thư mục `<tennhom-tenlop>/`. | Bắt buộc |
| 4 | Tệp `danhsachnhom.md` | Có mặt tại thư mục gốc của nhóm, điền đầy đủ thông tin thành viên và phân công. | Bắt buộc |
| 5 | Kiểm soát tệp tin rác | Không commit `node_modules/`, `.gradle/`, `Pods/`, `.dart_tool/`, `.env`, tệp tạm IDE, tệp nhị phân (`*.apk`, `*.ipa`). | Bắt buộc |
| 6 | Lệnh `git add` | Luôn sử dụng `git add <tennhom-tenlop>/`, không `git add .` tại thư mục gốc. | Bắt buộc |
| 7 | Tính toàn vẹn nhánh chung | Không sửa đổi, không xóa thư mục hoặc mã nguồn của các nhóm khác. | Bắt buộc |
| 8 | Tiêu đề Pull Request | Đúng định dạng `[Nộp bài] <tennhom-tenlop> - <Tên đề tài>`. | Bắt buộc |
